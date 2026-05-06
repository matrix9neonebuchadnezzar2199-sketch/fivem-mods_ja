--[[
  構造化エラーコード（NUI / サーバー共有）
  実機テスト時のトリアージ用: code + error + detail + context
]]

-- message は NUI / 既存ハンドラと同じ error キーに揃え、code で分類する
ErrorCodes = {
  NO_PERMISSION = { code = 'E1001', message = 'no_permission' },
  NOT_EDITOR = { code = 'E1002', message = 'not_editor' },
  LOCK_HELD_BY_OTHER = { code = 'E1003', message = 'lock_held' },
  SESSION_EXPIRED = { code = 'E1004', message = 'session_expired' },
  NO_LOCK = { code = 'E1005', message = 'no_lock' },

  INVALID_PAYLOAD = { code = 'E2001', message = 'bad_payload' },
  MISSING_FIELD = { code = 'E2002', message = 'missing_field' },
  INVALID_TEAM_ID = { code = 'E2003', message = 'invalid_team_id' },
  INVALID_SCORE = { code = 'E2004', message = 'invalid_score' },
  REASON_TOO_SHORT = { code = 'E2005', message = 'reason_too_short' },
  DUPLICATE_LICENSE = { code = 'E2006', message = 'duplicate_license' },
  BAD_ARGS = { code = 'E2007', message = 'bad_args' },

  MATCH_NOT_FOUND = { code = 'E3001', message = 'no_match' },
  PLAYER_NOT_FOUND = { code = 'E3002', message = 'not_found' },
  TEAM_NOT_FOUND = { code = 'E3003', message = 'team_not_found' },
  MATCH_ALREADY_FINISHED = { code = 'E3004', message = 'bad_status' },
  PLAYER_NOT_ACTIVE = { code = 'E3005', message = 'player_not_active' },

  DB_CONNECTION_LOST = { code = 'E4001', message = 'db_connection_lost' },
  DB_QUERY_FAILED = { code = 'E4002', message = 'db_query_failed' },
  DB_TRANSACTION_FAILED = { code = 'E4003', message = 'tx_failed' },

  INTERNAL_ERROR = { code = 'E5001', message = 'internal_error' },
  UNHANDLED_EXCEPTION = { code = 'E5002', message = 'unhandled_exception' },
}

---@param entry table ErrorCodes.* の要素
---@param detail string|nil
---@param context table|nil
function MakeError(entry, detail, context)
  if type(entry) ~= 'table' then
    entry = ErrorCodes.INTERNAL_ERROR
  end
  return {
    ok = false,
    error = entry.message,
    code = entry.code,
    detail = detail,
    context = context,
    timestamp = os.time() * 1000,
  }
end
