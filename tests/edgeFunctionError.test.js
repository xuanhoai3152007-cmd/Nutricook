import assert from 'node:assert/strict'
import test from 'node:test'
import { getEdgeFunctionError } from '../src/services/edgeFunctionError.js'

test('preserves a useful error message and code returned by an Edge Function', async () => {
  const error = {
    message: 'Edge Function returned a non-2xx status code',
    context: new Response(JSON.stringify({
      error: { code: 'AI_NOT_CONFIGURED', message: 'AI chưa được cấu hình.' },
    }), { status: 503 }),
  }

  assert.deepEqual(await getEdgeFunctionError(error), {
    message: 'AI chưa được cấu hình.',
    code: 'AI_NOT_CONFIGURED',
    status: 503,
  })
})

test('provides actionable guidance when the deployed function is missing', async () => {
  const error = {
    message: 'Edge Function returned a non-2xx status code',
    context: new Response('Not found', { status: 404 }),
  }

  const result = await getEdgeFunctionError(error)
  assert.equal(result.status, 404)
  assert.match(result.message, /triển khai function meal-plan-advice/u)
})

test('does not replace a specific Edge Function error with generic status text', async () => {
  const error = {
    message: 'Edge Function returned a non-2xx status code',
    context: new Response(JSON.stringify({
      error: { code: 'AI_MODEL_NOT_FOUND', message: 'Model chưa được hỗ trợ.' },
    }), { status: 502 }),
  }

  const result = await getEdgeFunctionError(error)
  assert.equal(result.code, 'AI_MODEL_NOT_FOUND')
  assert.equal(result.message, 'Model chưa được hỗ trợ.')
})

test('maps unavailable response context to a safe connection message', async () => {
  const result = await getEdgeFunctionError({ message: 'Edge Function returned a non-2xx status code' })

  assert.equal(result.status, null)
  assert.match(result.message, /kiểm tra cấu hình và trạng thái triển khai Supabase/u)
})
