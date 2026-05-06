export type HealthRow = {
  category: string
  name: string
  status: 'ok' | 'warning' | 'error' | 'checking'
  detail: string
  timestamp?: number
}
