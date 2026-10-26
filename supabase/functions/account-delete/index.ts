// account-delete — xóa tài khoản & dữ liệu cá nhân. Đơn hàng được GIỮ làm chứng từ nhưng ẩn danh hóa.
import { corsHeaders, json, fail } from '../_shared/http.ts';
import { admin, asUser } from '../_shared/clients.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'Chỉ hỗ trợ POST', 405);

  const { data, error } = await asUser(req).auth.getUser();
  if (error || !data.user) return fail('UNAUTHENTICATED', 'Bạn cần đăng nhập', 401);

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return fail('INVALID_INPUT', 'Dữ liệu yêu cầu không hợp lệ');
  }
  const confirm = typeof body === 'object' && body !== null && 'confirm' in body
    ? body.confirm
    : null;
  if (confirm !== 'XOA TAI KHOAN') return fail('CONFIRM_REQUIRED', 'Cần xác nhận bằng cụm từ "XOA TAI KHOAN"');

  // chặn xóa khi còn đơn đang xử lý
  const { count, error: orderError } = await admin.from('orders').select('id', { count: 'exact', head: true })
    .eq('user_id', data.user.id).in('status', ['pending', 'confirmed', 'preparing', 'shipping']);
  if (orderError) {
    console.error('Failed to check active orders before account deletion:', orderError);
    return fail('ORDER_CHECK_FAILED', 'Không thể kiểm tra trạng thái đơn hàng; tài khoản chưa bị xóa', 500);
  }
  if ((count ?? 0) > 0) return fail('HAS_ACTIVE_ORDERS', 'Bạn còn đơn hàng đang xử lý, vui lòng hoàn tất hoặc hủy trước khi xóa tài khoản', 409);

  const { error: anonymizeError } = await admin.rpc('rpc_anonymize_user_orders', { p_user: data.user.id });
  if (anonymizeError) {
    console.error('Failed to anonymize orders before account deletion:', anonymizeError);
    return fail('ANONYMIZE_FAILED', 'Không thể ẩn danh đơn hàng; tài khoản chưa bị xóa', 500);
  }
  const { error: auditError } = await admin.from('audit_log').insert({
    actor: data.user.id, action: 'account.delete', entity: 'profiles', entity_id: data.user.id,
  });
  if (auditError) {
    console.error('Failed to write account deletion audit record:', auditError);
    return fail('AUDIT_FAILED', 'Không thể ghi nhận yêu cầu; tài khoản chưa bị xóa', 500);
  }
  const { error: delErr } = await admin.auth.admin.deleteUser(data.user.id);   // cascade dữ liệu cá nhân; orders.user_id → NULL
  if (delErr) {
    console.error('Failed to delete user account:', delErr);
    return fail('DELETE_FAILED', 'Không thể xóa tài khoản, vui lòng thử lại', 500);
  }
  return json({ ok: true });
});
