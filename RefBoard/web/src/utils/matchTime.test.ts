import { describe, it, expect } from 'vitest'
import type { Match } from '../types/local'
import { parseMinuteInput, formatMinute, formatMinuteForCsv, eventMinutePresetFromClock } from './matchTime'

function testMatch(over: Partial<Match> & Pick<Match, 'currentHalf'>): Match {
  return {
    id: 1,
    title: 'Test',
    homeTeamId: 1,
    awayTeamId: 2,
    homeName: 'Home',
    awayName: 'Away',
    homeScore: 0,
    awayScore: 0,
    status: 'live',
    halfMinutes: 45,
    clockStartedAt: null,
    clockAccumulatedMs: 0,
    players: [],
    events: [],
    scoreHistory: [],
    createdAt: '',
    updatedAt: '',
    ...over,
  } as Match
}

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
  it('stoppage が 0 なら規定時刻のみ（+0 は付けない）', () => {
    expect(formatMinute(45, 0)).toBe("45'")
    expect(formatMinute(0, 0)).toBe("0'")
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

describe('eventMinutePresetFromClock', () => {
  it('PK 中は 0 / null', () => {
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: 'PK' }), 120000)).toEqual({ minute: 0, stoppage: null })
  })
  it('前半 23 分経過 → 23, 0', () => {
    const ms = 23 * 60 * 1000 + 45000
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: '1H' }), ms)).toEqual({ minute: 23, stoppage: 0 })
  })
  it('前半 47 分相当 → 45+2', () => {
    const ms = 47 * 60 * 1000
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: '1H' }), ms)).toEqual({ minute: 45, stoppage: 2 })
  })
  it('ハーフタイムでも前半と同様に分離する', () => {
    const ms = 47 * 60 * 1000
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: 'HT' }), ms)).toEqual({ minute: 45, stoppage: 2 })
  })
  it('後半 55 分経過（連続計時）→ 55, 0', () => {
    const ms = 55 * 60 * 1000
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: '2H' }), ms)).toEqual({ minute: 55, stoppage: 0 })
  })
  it('後半 95 分経過 → 90+5', () => {
    const ms = 95 * 60 * 1000
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: '2H' }), ms)).toEqual({ minute: 90, stoppage: 5 })
  })
  it('0 ms は 0, 0', () => {
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: '1H' }), 0)).toEqual({ minute: 0, stoppage: 0 })
  })
  it('120 分を上限として扱う', () => {
    const ms = 200 * 60 * 1000
    expect(eventMinutePresetFromClock(testMatch({ currentHalf: '2H' }), ms)).toEqual({ minute: 90, stoppage: 30 })
  })
})
