import { corsHeaders, fail, json } from '../_shared/http.ts';
import { admin, asUser } from '../_shared/clients.ts';

const INDEFINITE_BAN_DURATION = '876000h';

type AdminAction = 'block' | 'unblock' | 'delete';

type RequestBody = {
  action?: unknown;
  userId?: unknown;
  reason?: unknown;
  blockedUntil?: unknown;
};

const banDurationUntil = (blockedUntil: string | null) => {
  if (!blockedUntil) return INDEFINITE_BAN_DURATION;
  const seconds = Math.ceil((new Date(blockedUntil).getTime() - Date.now()) / 1000);
  return `${seconds}s`;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return fail('METHOD_NOT_ALLOWED', 'Chỉ hỗ trợ POST', 405);

  const userClient = asUser(req);
  const { data: authData, error: authError } = await userClient.auth.getUser();
  if (authError || !authData.user) return fail('UNAUTHENTICATED', 'Bạn cần đăng nhập', 401);

  const { data: adminProfile, error: roleError } = await userClient
    .from('profiles')
    .select('role')
    .eq('id', authData.user.id)
    .single();
  if (roleError) {
    console.error('Could not verify admin role for account moderation:', roleError);
    return fail('ROLE_CHECK_FAILED', 'Không thể xác minh quyền quản trị', 500);
  }
  if (adminProfile?.role !== 'admin') {
    return fail('FORBIDDEN', 'Chỉ admin mới được quản lý tài khoản', 403);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return fail('INVALID_INPUT', 'Dữ liệu yêu cầu không hợp lệ');
  }

  const action = body.action as AdminAction;
  const targetUserId = typeof body.userId === 'string' ? body.userId : '';
  if (!['block', 'unblock', 'delete'].includes(action) || !targetUserId) {
    return fail('INVALID_INPUT', 'Thao tác hoặc tài khoản không hợp lệ');
  }
  if (targetUserId === authData.user.id) {
    return fail('SELF_MANAGEMENT_FORBIDDEN', 'Không thể chặn hoặc xóa tài khoản đang đăng nhập', 400);
  }

  const { data: target, error: targetError } = await admin
    .from('profiles')
    .select('role, blocked_at, blocked_until')
    .eq('id', targetUserId)
    .maybeSingle();
  if (targetError) {
    console.error('Could not load target account for admin action:', targetError);
    return fail('ACCOUNT_LOOKUP_FAILED', 'Không thể kiểm tra tài khoản', 500);
  }
  if (!target) return fail('ACCOUNT_NOT_FOUND', 'Không tìm thấy tài khoản', 404);
  if (target.role === 'admin') {
    return fail('ADMIN_ACCOUNT_PROTECTED', 'Không thể chặn hoặc xóa tài khoản admin tại đây', 403);
  }

  if (action === 'delete') {
    const { error: auditError } = await admin.from('audit_log').insert({
      actor: authData.user.id,
      action: 'account.delete',
      entity: 'profiles',
      entity_id: targetUserId,
      meta: { result: 'requested' },
    });
    if (auditError) {
      console.error('Could not record admin account deletion:', auditError);
      return fail('AUDIT_FAILED', 'Không thể ghi nhật ký; tài khoản chưa bị xóa', 500);
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(targetUserId);
    if (deleteError) {
      console.error('Admin account deletion failed:', deleteError);
      const { error: failureAuditError } = await admin.from('audit_log').insert({
        actor: authData.user.id,
        action: 'account.delete.failed',
        entity: 'profiles',
        entity_id: targetUserId,
        meta: { message: deleteError.message },
      });
      if (failureAuditError) console.error('Could not record failed admin account deletion:', failureAuditError);
      return fail('DELETE_FAILED', 'Không thể xóa tài khoản; vui lòng thử lại', 500);
    }
    return json({ ok: true });
  }

  let blockedUntil: string | null = null;
  let reason: string | null = null;
  let banDuration = 'none';

  if (action === 'block') {
    reason = typeof body.reason === 'string' ? body.reason.trim() : '';
    if (!reason || reason.length > 500) {
      return fail('INVALID_REASON', 'Lý do chặn là bắt buộc và tối đa 500 ký tự');
    }
    if (body.blockedUntil !== undefined && body.blockedUntil !== null && body.blockedUntil !== '') {
      if (typeof body.blockedUntil !== 'string' || !Number.isFinite(Date.parse(body.blockedUntil))) {
        return fail('INVALID_EXPIRY', 'Thời điểm hết chặn không hợp lệ');
      }
      blockedUntil = new Date(body.blockedUntil).toISOString();
      if (Date.parse(blockedUntil) <= Date.now()) {
        return fail('INVALID_EXPIRY', 'Thời điểm hết chặn phải ở trong tương lai');
      }
    }
    banDuration = banDurationUntil(blockedUntil);
  }

  const { error: authUpdateError } = await admin.auth.admin.updateUserById(targetUserId, {
    ban_duration: banDuration,
  });
  if (authUpdateError) {
    console.error('Could not update account authentication ban:', authUpdateError);
    return fail('AUTH_UPDATE_FAILED', 'Không thể cập nhật trạng thái đăng nhập', 500);
  }

  const profileUpdate = action === 'block'
    ? { blocked_at: new Date().toISOString(), blocked_until: blockedUntil, block_reason: reason, blocked_by: authData.user.id }
    : { blocked_at: null, blocked_until: null, block_reason: null, blocked_by: null };
  const { error: profileError } = await admin.from('profiles').update(profileUpdate).eq('id', targetUserId);
  if (profileError) {
    console.error('Could not save admin account moderation details:', profileError);
    const previousDuration = target.blocked_at
      ? target.blocked_until && Date.parse(target.blocked_until) > Date.now()
        ? banDurationUntil(target.blocked_until)
        : target.blocked_until
          ? 'none'
          : INDEFINITE_BAN_DURATION
      : 'none';
    const { error: rollbackError } = await admin.auth.admin.updateUserById(targetUserId, { ban_duration: previousDuration });
    if (rollbackError) console.error('Could not roll back the authentication ban:', rollbackError);
    return fail('PROFILE_UPDATE_FAILED', 'Không thể lưu lý do/thời hạn; hãy thử lại', 500);
  }

  const { error: auditError } = await admin.from('audit_log').insert({
    actor: authData.user.id,
    action: action === 'block' ? 'account.block' : 'account.unblock',
    entity: 'profiles',
    entity_id: targetUserId,
    meta: action === 'block' ? { reason, blocked_until: blockedUntil } : null,
  });
  if (auditError) {
    console.error('Could not record account moderation audit:', auditError);
    return fail('AUDIT_FAILED', 'Trạng thái đã được cập nhật nhưng không ghi được nhật ký', 500);
  }

  return json({ ok: true });
});
