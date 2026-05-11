import { describe, expect, it } from 'vitest'
import { HELP_ALLOWED_URI_REGEXP } from './sanitizeHelpHtml'

/** DOMPurify が属性値全体に `ALLOWED_URI_REGEXP` を適用する前提で、同じ文字列を検証する */
function allowsUri(value: string): boolean {
  return HELP_ALLOWED_URI_REGEXP.test(value)
}

describe('sanitizeHelpHtml URI allow/forbid (T-06)', () => {
  it('allows relative img src', () => {
    expect(allowsUri('./a.png')).toBe(true)
  })

  it('allows https a href', () => {
    expect(allowsUri('https://example.com')).toBe(true)
  })

  it('forbids data: img src', () => {
    expect(allowsUri('data:image/svg+xml;base64,PHN2Zz48L3N2Zz4=')).toBe(false)
  })

  it('forbids javascript: href', () => {
    expect(allowsUri('javascript:alert(1)')).toBe(false)
  })

  it('allows anchor #', () => {
    expect(allowsUri('#sec')).toBe(true)
  })
})
