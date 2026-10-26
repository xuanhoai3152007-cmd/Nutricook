import { useEffect, useState } from 'react'
import { isSupabaseConfigured } from '../lib/supabase.js'
import { getAppSettings } from '../services/appSettingsService.js'

const safeDefaults = {
  demo_mode: true,
  payments_live: false,
  shop_enabled: false,
  ai_enabled: false,
}

export function useAppSettings() {
  const configured = isSupabaseConfigured()
  const [state, setState] = useState({
    settings: safeDefaults,
    loading: configured,
    error: null,
  })

  useEffect(() => {
    if (!configured) return

    let active = true
    const timeoutId = window.setTimeout(() => {
      active = false
      setState({
        settings: safeDefaults,
        loading: false,
        error: new Error('Hết thời gian chờ khi tải cài đặt.'),
      })
    }, 8000)

    getAppSettings()
      .then((settings) => {
        window.clearTimeout(timeoutId)
        if (active) setState({ settings, loading: false, error: null })
      })
      .catch((error) => {
        window.clearTimeout(timeoutId)
        console.error('Could not load Supabase app settings:', error)
        if (active) setState({ settings: safeDefaults, loading: false, error })
      })

    return () => {
      active = false
      window.clearTimeout(timeoutId)
    }
  }, [configured])

  return { ...state, configured }
}
