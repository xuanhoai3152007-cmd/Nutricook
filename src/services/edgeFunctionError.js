const genericFunctionError = 'Edge Function returned a non-2xx status code'

const statusMessages = {
  401: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Hãy đăng xuất rồi đăng nhập lại.',
  403: 'Tài khoản không được phép gọi chức năng AI này.',
  404: 'Không tìm thấy Edge Function. Hãy triển khai function meal-plan-advice lên đúng project Supabase.',
  429: 'Dịch vụ AI đang giới hạn yêu cầu. Vui lòng đợi một lúc rồi thử lại.',
  500: 'Edge Function gặp lỗi nội bộ. Hãy kiểm tra logs của function meal-plan-advice trong Supabase.',
  502: 'Dịch vụ AI phía máy chủ gặp lỗi. Hãy kiểm tra khóa API, model và logs của function.',
  503: 'Dịch vụ AI chưa được cấu hình trên Supabase. Hãy kiểm tra secrets của project.',
  504: 'Dịch vụ AI phản hồi quá lâu. Vui lòng thử lại sau.',
}

function getResponseMessage(payload) {
  const message = payload?.error?.message ?? payload?.message ?? payload?.msg
  return typeof message === 'string' && message.trim() ? message.trim() : null
}

export async function getEdgeFunctionError(error) {
  const response = typeof Response !== 'undefined' && error?.context instanceof Response
    ? error.context.clone()
    : null
  const status = response?.status
  let payload = null

  if (response) {
    const body = await response.text().catch(() => '')
    if (body) {
      try {
        payload = JSON.parse(body)
      } catch {
        payload = null
      }
    }
  }

  const serverMessage = getResponseMessage(payload)
  const message = serverMessage && serverMessage !== genericFunctionError
    ? serverMessage
    : statusMessages[status] ?? (
      error?.message && error.message !== genericFunctionError
        ? error.message
        : 'Không thể kết nối Edge Function. Hãy kiểm tra cấu hình và trạng thái triển khai Supabase.'
    )

  return {
    message,
    code: payload?.error?.code ?? payload?.code ?? null,
    status: Number.isInteger(status) ? status : null,
  }
}
