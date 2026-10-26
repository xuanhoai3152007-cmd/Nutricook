// send-email — gửi email đơn hàng qua Resend. CHỈ gọi nội bộ (service role) hoặc nhân viên.
import { corsHeaders, json, fail } from '../_shared/http.ts';
import { admin, asUser } from '../_shared/clients.ts';

const esc = (s: string) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]!));
const vnd = (n: number) => n.toLocaleString('vi-VN') + 'đ';
const SUBJECT: Record<string, string> = {
  order_placed: 'Đã nhận đơn', order_confirmed: 'Đơn đã được xác nhận',
  order_shipping: 'Đơn đang được giao', order_delivered: 'Đơn đã giao', order_cancelled: 'Đơn đã hủy',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'Chỉ hỗ trợ POST', 405);
  const token = req.headers.get('Authorization')?.replace('Bearer ', '') ?? '';
  let allowed = token !== '' && token === Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!allowed) {
    const { data } = await asUser(req).auth.getUser();
    if (data.user) {
      const { data: p } = await admin.from('profiles').select('role').eq('id', data.user.id).single();
      allowed = p?.role === 'admin' || p?.role === 'staff';
    }
  }
  if (!allowed) return fail('FORBIDDEN', 'Không có quyền', 403);

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return fail('INVALID_INPUT', 'Dữ liệu yêu cầu không hợp lệ');
  }
  if (typeof body !== 'object' || body === null || !('template' in body) || !('orderCode' in body)) {
    return fail('INVALID_INPUT', 'Dữ liệu không hợp lệ');
  }
  const { template, orderCode } = body;
  if (typeof template !== 'string' || !SUBJECT[template] || typeof orderCode !== 'string' || !orderCode.trim()) {
    return fail('INVALID_INPUT', 'Dữ liệu không hợp lệ');
  }

  const { data: o, error: orderError } = await admin.from('orders')
    .select('code,total_vnd,status,user_id, order_items(name_snapshot, qty, unit_price_vnd)').eq('code', orderCode).single();
  if (orderError) {
    console.error('Failed to load order for email:', orderError);
    return fail('ORDER_LOOKUP_FAILED', 'Không thể tải thông tin đơn hàng', 500);
  }
  if (!o?.user_id) return fail('ORDER_NOT_FOUND', 'Không tìm thấy đơn', 404);
  const { data: u, error: userError } = await admin.auth.admin.getUserById(o.user_id);
  if (userError) {
    console.error('Failed to load order recipient:', userError);
    return fail('RECIPIENT_LOOKUP_FAILED', 'Không thể tải thông tin người nhận', 500);
  }
  const to = u.user?.email;
  if (!to) return fail('NO_EMAIL', 'Không có email', 422);

  const rows = (o.order_items ?? []).map((i) =>
    `<tr><td>${esc(i.name_snapshot)}</td><td>×${i.qty}</td><td>${vnd(i.unit_price_vnd * i.qty)}</td></tr>`).join('');
  const html = `<p>${SUBJECT[template]}: đơn <b>${esc(o.code)}</b>.</p><table>${rows}</table><p>Tổng: <b>${vnd(o.total_vnd)}</b></p>`;
  const apiKey = Deno.env.get('RESEND_API_KEY');
  const mailFrom = Deno.env.get('MAIL_FROM');
  if (!apiKey || !mailFrom) {
    console.error('RESEND_API_KEY or MAIL_FROM is not configured');
    return fail('EMAIL_CONFIG_ERROR', 'Dịch vụ email chưa được cấu hình', 500);
  }

  let res: Response;
  try {
    res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ from: mailFrom, to, subject: `NutriCook – ${SUBJECT[template]} ${o.code}`, html }),
    });
  } catch (error) {
    console.error('Resend request failed:', error);
    return fail('EMAIL_FAILED', 'Không thể kết nối dịch vụ email', 502);
  }
  if (!res.ok) {
    console.error('Resend rejected email:', res.status);
    return fail('EMAIL_FAILED', 'Không gửi được email', 502);
  }
  return json({ ok: true });
});
