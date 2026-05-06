/** サーバー MakeError / 既存 { ok:false, error } と整合 */
export interface RefBoardError {
  ok: false
  error: string
  code: string
  detail?: string
  context?: Record<string, unknown>
  timestamp?: number
}

export const ERROR_CODES = {
  E1001: 'no_permission',
  E1002: 'not_editor',
  E1003: 'lock_held',
  E1004: 'session_expired',
  E1005: 'no_lock',
  E2001: 'bad_payload',
  E2002: 'missing_field',
  E2003: 'invalid_team_id',
  E2004: 'invalid_score',
  E2005: 'reason_too_short',
  E2006: 'duplicate_license',
  E2007: 'bad_args',
  E3001: 'no_match',
  E3002: 'not_found',
  E3003: 'team_not_found',
  E3004: 'bad_status',
  E3005: 'player_not_active',
  E4001: 'db_connection_lost',
  E4002: 'db_query_failed',
  E4003: 'tx_failed',
  E5001: 'internal_error',
  E5002: 'unhandled_exception',
} as const
