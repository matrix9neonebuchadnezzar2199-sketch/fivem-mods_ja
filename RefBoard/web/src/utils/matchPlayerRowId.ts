/**
 * 試合メンバー（match_players 行）の ID を NUI から送るときに正規化する。
 * - DB 由来の数値文字列
 * - モックの複合 ID `m{matchId}-t{teamId}-r{rosterId}`
 * - その他の非空文字列は安定ハッシュ（モックの一時 ID 用）
 */
export function resolveMatchPlayerRowId(playerId: string | number | null | undefined): number | null {
  const s = String(playerId ?? '').trim()
  if (!s) return null
  const c = /^m(\d+)-t(\d+)-r(\d+)$/i.exec(s)
  if (c) {
    const mid = Number(c[1])
    const rid = Number(c[3])
    if (Number.isFinite(mid) && mid > 0 && Number.isFinite(rid) && rid > 0) {
      return mid * 1_000_000 + rid
    }
  }
  const n = Number(s)
  if (Number.isFinite(n) && n > 0) return Math.trunc(n)
  let h = 0
  for (let i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) >>> 0
  const v = h >>> 0
  return v > 0 ? v : 1
}
