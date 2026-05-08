/**
 * サーバー ACK の `error`（レガシー文字列）と `code`（E1xxx）の両方から
 * ヘルプ記事・ルートへ解決する。`shared/error_codes.lua` の message と一致させる。
 */

/** `error` キー → HTTP ではなく hash ルータ用の code */
export const ERROR_KEY_TO_CODE: Record<string, string> = {
  no_permission: 'E1001',
  not_editor: 'E1002',
  lock_held: 'E1003',
  session_expired: 'E1004',
  no_lock: 'E1005',
  bad_payload: 'E2001',
  missing_field: 'E2002',
  invalid_team_id: 'E2003',
  invalid_score: 'E2004',
  reason_too_short: 'E2005',
  duplicate_license: 'E2006',
  bad_args: 'E2007',
  no_match: 'E3001',
  not_found: 'E3002',
  team_not_found: 'E3003',
  bad_status: 'E3004',
  player_not_active: 'E3005',
  player_has_events: 'E3006',
  db_connection_lost: 'E4001',
  db_query_failed: 'E4002',
  tx_failed: 'E4003',
  internal_error: 'E5001',
  unhandled_exception: 'E5002',
}

/** コード別の専用ヘルプ記事（slug = ファイル名から .md を除いたもの）。未設定は汎用ヘルプへ */
export const ERROR_CODE_TO_HELP_SLUG: Record<string, string> = {
  E1003: 'trouble_e1003_lock_held',
  E2005: 'match_manual_score_edit',
  E4003: 'trouble_autosave_failed',
}

export function errorKeyToCode(key: string): string | undefined {
  return ERROR_KEY_TO_CODE[key]
}

export function resolveErrorCode(err: { code?: string; error?: string }): string | undefined {
  if (err.code && /^E\d{4}$/.test(err.code)) {
    return err.code
  }
  if (err.error) {
    return ERROR_KEY_TO_CODE[err.error]
  }
  return undefined
}

/** エラー用の専用記事があるときだけ help-error へ */
export function getHelpRouteForError(err: { code?: string; error?: string }):
  | { name: 'help-error'; params: { code: string } }
  | { name: 'help' } {
  const code = resolveErrorCode(err)
  if (code && ERROR_CODE_TO_HELP_SLUG[code]) {
    return { name: 'help-error', params: { code } }
  }
  return { name: 'help' }
}

export function helpSlugForErrorCode(code: string): string | undefined {
  return ERROR_CODE_TO_HELP_SLUG[code]
}
