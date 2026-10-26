import { createClient } from 'npm:@supabase/supabase-js@2';

const url = Deno.env.get('SUPABASE_URL')!;

/** Quyền service role: CHỈ dùng để ghi ai_runs, xóa tài khoản. Không bao giờ trả dữ liệu thô cho client. */
export const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!, {
  auth: { persistSession: false },
});

/** Client chạy với JWT của người dùng → RLS và auth.uid() trong RPC áp dụng bình thường. */
export const asUser = (req: Request) =>
  createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
    auth: { persistSession: false },
  });

