import { getSupabaseClient } from '../lib/supabase.js'

export async function signUpWithEmail({ email, password, fullName }) {
  const { data, error } = await getSupabaseClient().auth.signUp({
    email,
    password,
    options: {
      data: { full_name: fullName },
      emailRedirectTo: `${window.location.origin}/auth/callback`,
    },
  })

  if (error) throw error
  return data
}

export async function signInWithEmail({ email, password }) {
  const { data, error } = await getSupabaseClient().auth.signInWithPassword({ email, password })

  if (error) throw error
  return data
}

export async function signInAsAdminWithEmail({ email, password }) {
  const client = getSupabaseClient()
  const { data, error } = await client.auth.signInWithPassword({ email, password })

  if (error) throw error

  const { data: profile, error: profileError } = await client
    .from('profiles')
    .select('role')
    .eq('id', data.user.id)
    .single()

  if (profileError) {
    const { error: signOutError } = await client.auth.signOut()
    if (signOutError) {
      throw new Error(`Không thể xác minh quyền quản trị hoặc đăng xuất: ${profileError.message}; ${signOutError.message}`)
    }
    throw profileError
  }

  if (profile.role !== 'admin') {
    const { error: signOutError } = await client.auth.signOut()
    if (signOutError) {
      throw new Error(`Tài khoản chưa có quyền quản trị và không thể đăng xuất: ${signOutError.message}`)
    }
    throw new Error('Tài khoản này chưa được cấp quyền quản trị.')
  }

  return data
}

export async function signInWithGoogle() {
  const { data, error } = await getSupabaseClient().auth.signInWithOAuth({
    provider: 'google',
    options: { redirectTo: `${window.location.origin}/auth/callback` },
  })

  if (error) throw error
  return data
}

export async function signOut() {
  const { error } = await getSupabaseClient().auth.signOut()

  if (error) throw error
}

export async function sendPasswordReset(email) {
  const { data, error } = await getSupabaseClient().auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/reset-password`,
  })

  if (error) throw error
  return data
}
