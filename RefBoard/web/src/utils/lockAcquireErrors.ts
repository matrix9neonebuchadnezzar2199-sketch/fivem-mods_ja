/** `refboard:lock:acquire:result` の `error`（MakeError の message キー）分類 */

export function isDbOrInfraAcquireError(error?: string): boolean {
  return (
    error === 'db_query_failed' ||
    error === 'db_connection_lost' ||
    error === 'tx_failed' ||
    error === 'internal_error' ||
    error === 'unhandled_exception'
  )
}

export function isPeerLockHeldError(error?: string): boolean {
  return error === 'lock_held'
}
