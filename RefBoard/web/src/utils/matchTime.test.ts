import { describe, it, expect } from 'vitest'
import { parseMinuteInput, formatMinute, formatMinuteForCsv } from './matchTime'

describe('parseMinuteInput', () => {
  describe('正常系', () => {
    it('整数のみを受け付ける', () => {
      expect(parseMinuteInput('45')).toEqual({ ok: true, value: { minute: 45, stoppage: null } })
    })
    it('0 分を受け付ける', () => {
      expect(parseMinuteInput('0')).toEqual({ ok: true, value: { minute: 0, stoppage: null } })
    })
    it('上限 120 分を受け付ける', () => {
      expect(parseMinuteInput('120')).toEqual({ ok: true, value: { minute: 120, stoppage: null } })
    })
    it('45+2 形式を受け付ける', () => {
      expect(parseMinuteInput('45+2')).toEqual({ ok: true, value: { minute: 45, stoppage: 2 } })
    })
    it('45+0 形式（明示ロスタイム 0）を受け付ける', () => {
      expect(parseMinuteInput('45+0')).toEqual({ ok: true, value: { minute: 45, stoppage: 0 } })
    })
    it('上限 stoppage 29 を受け付ける', () => {
      expect(parseMinuteInput('90+29')).toEqual({ ok: true, value: { minute: 90, stoppage: 29 } })
    })
  })

  describe('正規化', () => {
    it('全角プラス（＋）を半角に正規化する', () => {
      expect(parseMinuteInput('45＋2')).toEqual({ ok: true, value: { minute: 45, stoppage: 2 } })
    })
    it('前後の半角空白を除去する', () => {
      expect(parseMinuteInput('  45+2  ')).toEqual({ ok: true, value: { minute: 45, stoppage: 2 } })
    })
    it('全角空白を除去する', () => {
      expect(parseMinuteInput('\u300045+2\u3000')).toEqual({ ok: true, value: { minute: 45, stoppage: 2 } })
    })
    it('45 + 2 のような中間空白も除去する', () => {
      expect(parseMinuteInput('45 + 2')).toEqual({ ok: true, value: { minute: 45, stoppage: 2 } })
    })
  })

  describe('異常系', () => {
    it('空文字は empty', () => {
      expect(parseMinuteInput('')).toEqual({ ok: false, reason: 'empty' })
    })
    it('空白のみは empty', () => {
      expect(parseMinuteInput('   ')).toEqual({ ok: false, reason: 'empty' })
    })
    it('文字列は invalid_format', () => {
      expect(parseMinuteInput('abc')).toEqual({ ok: false, reason: 'invalid_format' })
    })
    it('45+abc は invalid_format', () => {
      expect(parseMinuteInput('45+abc')).toEqual({ ok: false, reason: 'invalid_format' })
    })
    it('45.5 は invalid_format（小数は受けない）', () => {
      expect(parseMinuteInput('45.5')).toEqual({ ok: false, reason: 'invalid_format' })
    })
    it('-5 は invalid_format（マイナスは受けない）', () => {
      expect(parseMinuteInput('-5')).toEqual({ ok: false, reason: 'invalid_format' })
    })
    it('45++2 は invalid_format', () => {
      expect(parseMinuteInput('45++2')).toEqual({ ok: false, reason: 'invalid_format' })
    })
    it('121 は minute_out_of_range', () => {
      expect(parseMinuteInput('121')).toEqual({ ok: false, reason: 'minute_out_of_range' })
    })
    it('999 は minute_out_of_range', () => {
      expect(parseMinuteInput('999')).toEqual({ ok: false, reason: 'minute_out_of_range' })
    })
    it('45+30 は stoppage_out_of_range', () => {
      expect(parseMinuteInput('45+30')).toEqual({ ok: false, reason: 'stoppage_out_of_range' })
    })
  })
})

describe('formatMinute', () => {
  it('stoppage が null なら 45 単独表記', () => {
    expect(formatMinute(45, null)).toBe("45'")
  })
  it('stoppage が undefined なら 45 単独表記', () => {
    expect(formatMinute(45, undefined)).toBe("45'")
  })
  it('stoppage が 0 なら 45+0 表記（明示）', () => {
    expect(formatMinute(45, 0)).toBe("45+0'")
  })
  it('stoppage が 2 なら 45+2 表記', () => {
    expect(formatMinute(45, 2)).toBe("45+2'")
  })
})

describe('formatMinuteForCsv', () => {
  it('CSV 用はアポストロフィなし', () => {
    expect(formatMinuteForCsv(45, null)).toBe('45')
    expect(formatMinuteForCsv(45, 2)).toBe('45+2')
    expect(formatMinuteForCsv(45, 0)).toBe('45+0')
  })
})
