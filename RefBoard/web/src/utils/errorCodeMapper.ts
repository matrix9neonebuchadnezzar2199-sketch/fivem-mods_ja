/**
 * ローカル版で起き得るエラーからヘルプ記事へ解決する。
 */

/** `error` キー → hash ルータ用の code */
export const ERROR_KEY_TO_CODE: Record<string, string> = {
  bad_payload: 'E2001',
  bad_status: 'E3004',
  player_has_events: 'E3006',
}

/** コード別の専用ヘルプ記事（slug = ファイル名から .md を除いたもの）。未設定は汎用ヘルプへ */
export const ERROR_CODE_TO_HELP_SLUG: Record<string, string> = {
  E3006: 'trouble_e3006_player_has_events',
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
