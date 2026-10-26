// vnpay-create — tạo URL thanh toán VNPay đã ký cho đơn của chính người dùng
import { createHmac } from 'node:crypto';
import { corsHeaders, json, fail } from '../_shared/http.ts';
import { admin, asUser } from '../_shared/clients.ts';

const enc = (v: string) => encodeURIComponent(v).replace(/%20/g, '+');
const sign = (params: Record<string, string>, secret: string) => {
  const q = Object.keys(params).sort().map((k) => `${k}=${enc(params[k])}`).join('&');
  return { q, hash: createHmac('sha512', secret).update(Buffer.from(q, 'utf-8')).digest('hex') };
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'Chỉ hỗ trợ POST', 405);

  const { data: auth } = await asUser(req).auth.getUser();
  if (!auth.user) return fail('UNAUTHENTICATED', 'Bạn cần đăng nhập', 401);

  const { data: paymentsLive, error: settingError } = await admin.rpc('app_setting_bool', {
    p_key: 'payments_live',
    p_default: false,
  });
  if (settingError) {
    console.error('Failed to check live payment setting:', settingError);
    return fail('PAYMENT_SETTING_CHECK_FAILED', 'Không thể xác minh trạng thái thanh toán', 500);
  }
  if (!paymentsLive) return fail('PAYMENTS_DISABLED', 'Thanh toán trực tuyến hiện chưa được bật', 503);

  const { orderId } = await req.json().catch(() => ({}));
  if (typeof orderId !== 'string') return fail('INVALID_INPUT', 'Thiếu orderId');

  // CHỈ đơn của chính người dùng, đang chờ thanh toán VNPay
  const { data: order } = await admin.from('orders')
    .select('id, code, total_vnd, status, payment_status, payment_method, user_id')
    .eq('id', orderId).single();
  if (!order || order.user_id !== auth.user.id) return fail('ORDER_NOT_FOUND', 'Không tìm thấy đơn', 404);
  if (order.payment_method !== 'vnpay' || order.status !== 'pending' || order.payment_status === 'paid')
    return fail('INVALID_STATE', 'Đơn không thể thanh toán');

  const ip = req.headers.get('x-forwarded-for')?.split(',')[0].trim() ?? '127.0.0.1';
  const now = new Date(Date.now() + 7 * 3600 * 1000).toISOString().replace(/[-:T]/g, '').slice(0, 14);  // GMT+7
  const params: Record<string, string> = {
    vnp_Version: '2.1.0', vnp_Command: 'pay', vnp_TmnCode: Deno.env.get('VNP_TMN_CODE')!,
    vnp_Amount: String(order.total_vnd * 100), vnp_CurrCode: 'VND', vnp_TxnRef: order.code,
    vnp_OrderInfo: `Thanh toan don ${order.code}`, vnp_OrderType: 'other', vnp_Locale: 'vn',
    vnp_ReturnUrl: `${Deno.env.get('SITE_URL')}/orders/${order.id}`, vnp_IpAddr: ip, vnp_CreateDate: now,
  };
  const { q, hash } = sign(params, Deno.env.get('VNP_HASH_SECRET')!);
  return json({ payUrl: `${Deno.env.get('VNP_URL')}?${q}&vnp_SecureHash=${hash}` });
});
