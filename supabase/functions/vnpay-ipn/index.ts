// vnpay-ipn — webhook VNPay gọi về (verify_jwt = false). KHÔNG tin tham số redirect của trình duyệt.
// Kiểm: chữ ký HMAC-SHA512 → mã đơn → số tiền → idempotent (do rpc_mark_paid).
import { createHmac, timingSafeEqual } from 'node:crypto';
import { admin } from '../_shared/clients.ts';

const reply = (code: string, msg: string) =>
  new Response(JSON.stringify({ RspCode: code, Message: msg }), { headers: { 'Content-Type': 'application/json' } });
const enc = (v: string) => encodeURIComponent(v).replace(/%20/g, '+');

Deno.serve(async (req) => {
  if (req.method !== 'GET') return reply('99', 'Method not allowed');
  const url = new URL(req.url);
  const p: Record<string, string> = {};
  url.searchParams.forEach((v, k) => { if (k.startsWith('vnp_')) p[k] = v; });
  const received = p['vnp_SecureHash'] ?? '';
  delete p['vnp_SecureHash']; delete p['vnp_SecureHashType'];

  const secret = Deno.env.get('VNP_HASH_SECRET');
  if (!secret) {
    console.error('VNP_HASH_SECRET is not configured');
    return reply('99', 'Payment configuration error');
  }
  const terminalCode = Deno.env.get('VNP_TMN_CODE');
  if (!terminalCode) {
    console.error('VNP_TMN_CODE is not configured');
    return reply('99', 'Payment configuration error');
  }
  const q = Object.keys(p).sort().map((k) => `${k}=${enc(p[k])}`).join('&');
  const expected = createHmac('sha512', secret).update(Buffer.from(q, 'utf-8')).digest('hex');
  const a = Buffer.from(expected), b = Buffer.from(received);
  if (!received || a.length !== b.length || !timingSafeEqual(a, b)) return reply('97', 'Invalid signature');

  const code = p['vnp_TxnRef'];
  if (!code || p['vnp_TmnCode'] !== terminalCode) return reply('97', 'Invalid payment reference');
  if (p['vnp_ResponseCode'] !== '00' || p['vnp_TransactionStatus'] !== '00') {
    const { data: o, error: orderError } = await admin.from('orders').select('id').eq('code', code).maybeSingle();
    if (orderError) {
      console.error('Failed to load order for VNPay notification:', orderError);
      return reply('99', 'Database error');
    }
    if (o) {
      const { error: paymentError } = await admin.from('payments').update({ status: 'failed', raw_payload: p })
        .eq('order_id', o.id).eq('provider', 'vnpay').neq('status', 'paid');
      if (paymentError) {
        console.error('Failed to update unsuccessful VNPay payment:', paymentError);
        return reply('99', 'Database error');
      }
    }
    return reply('00', 'Confirm Success');
  }

  const amountText = p['vnp_Amount'] ?? '';
  const amountMinor = Number(amountText);
  const transactionId = p['vnp_TransactionNo'];
  if (!/^\d+$/.test(amountText) || !Number.isSafeInteger(amountMinor) || amountMinor <= 0
    || amountMinor % 100 !== 0 || !transactionId) {
    return reply('04', 'Invalid payment amount or transaction');
  }

  const { data, error } = await admin.rpc('rpc_mark_paid', {
    p_order_code: code, p_provider: 'vnpay', p_txn_id: transactionId,
    p_amount: Math.round(amountMinor / 100), p_raw: p,
  });
  if (error) { console.error(error); return reply('99', 'Unknown error'); }
  if (data === 'ORDER_NOT_FOUND')   return reply('01', 'Order not found');
  if (data === 'AMOUNT_MISMATCH')   return reply('04', 'Invalid amount');
  if (data === 'ALREADY_PROCESSED') return reply('02', 'Order already confirmed');
  if (data === 'INVALID_STATE')     return reply('02', 'Order not payable');

  const { error: emailError } = await admin.functions.invoke('send-email', {
    body: { template: 'order_confirmed', orderCode: code },
  });
  if (emailError) console.error('VNPay order confirmation email failed:', emailError);
  return reply('00', 'Confirm Success');
});
