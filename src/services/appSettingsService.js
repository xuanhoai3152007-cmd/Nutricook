import { getSupabaseClient } from '../lib/supabase.js'

const settingKeys = ['demo_mode', 'payments_live', 'shop_enabled', 'ai_enabled']

export async function getAppSettings() {
  const { data, error } = await getSupabaseClient()
    .from('app_settings')
    .select('key, value')
    .in('key', settingKeys)

  if (error) throw error

  const settings = Object.fromEntries((data ?? []).map(({ key, value }) => [key, value]))
  for (const key of settingKeys) {
    if (typeof settings[key] !== 'boolean') {
      throw new Error(`Cờ cấu hình Supabase "${key}" thiếu hoặc không hợp lệ.`)
    }
  }

  return settings
}
