<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useNui } from '../composables/useNui'
import { REFBOARD_UI_VERSION } from '../constants/version'
import HealthCard from '../components/health/HealthCard.vue'
import type { HealthRow } from '../types/health'
import { useToast } from '../composables/useToast'

const { t } = useI18n()
const { send, on } = useNui()
const { push: toast } = useToast()

const results = ref<HealthRow[]>([])
const meta = ref<{ serverVersion?: string; clientVersion?: string; logLevel?: string; enableTestCommands?: boolean }>({})
const loading = ref(false)

let unAck: (() => void) | null = null

function groupByCategory(rows: HealthRow[]) {
  const m = new Map<string, HealthRow[]>()
  for (const r of rows) {
    const list = m.get(r.category) ?? []
    list.push(r)
    m.set(r.category, list)
  }
  return m
}

const grouped = computed(() => groupByCategory(results.value))

const categoryOrder = ['server', 'db', 'auth', 'presence', 'lock', 'config']

const cards = computed(() => {
  const g = grouped.value
  const out: { key: string; title: string; rows: HealthRow[] }[] = []
  for (const key of categoryOrder) {
    const rows = g.get(key)
    if (rows?.length) {
      out.push({
        key,
        title: t(`health.categories.${key}`),
        rows,
      })
    }
  }
  for (const [key, rows] of g) {
    if (!categoryOrder.includes(key) && rows.length) {
      out.push({ key, title: key, rows })
    }
  }
  return out
})

function buildMarkdownReport(): string {
  const lines: string[] = []
  lines.push('## RefBoard Health Check Report')
  lines.push(`- 日時: ${new Date().toISOString()}`)
  lines.push(`- クライアントUI: ${REFBOARD_UI_VERSION}`)
  lines.push(`- サーバー resource: ${meta.value.serverVersion ?? '—'}`)
  lines.push(`- LogLevel: ${meta.value.logLevel ?? '—'}`)
  lines.push(`- EnableTestCommands: ${meta.value.enableTestCommands === true ? 'true' : 'false'}`)
  lines.push('')
  const issues = results.value.filter((r) => r.status === 'warning' || r.status === 'error')
  lines.push('### Issues')
  if (!issues.length) {
    lines.push('- (なし)')
  } else {
    for (const r of issues) {
      const icon = r.status === 'error' ? '🔴' : '🟡'
      lines.push(`- ${icon} **${r.category}** / ${r.name}: ${r.detail}`)
    }
  }
  lines.push('')
  lines.push('### All rows')
  for (const r of results.value) {
    lines.push(`- ${r.status} — ${r.category}/${r.name}: ${r.detail}`)
  }
  return lines.join('\n')
}

async function runCheck() {
  loading.value = true
  results.value = []
  await send('health_check', { clientVersion: REFBOARD_UI_VERSION })
}

async function copyReport() {
  const md = buildMarkdownReport()
  try {
    await navigator.clipboard.writeText(md)
    toast(t('health.copied'), 'success')
  } catch {
    toast(t('health.copy_failed'), 'error')
  }
}

onMounted(() => {
  unAck = on(
    'refboard:health:check:ack',
    (p: { results?: HealthRow[]; serverVersion?: string; clientVersion?: string; logLevel?: string; enableTestCommands?: boolean }) => {
      loading.value = false
      results.value = (p.results ?? []) as HealthRow[]
      meta.value = {
        serverVersion: p.serverVersion,
        clientVersion: p.clientVersion,
        logLevel: p.logLevel,
        enableTestCommands: p.enableTestCommands,
      }
    },
  )
  void runCheck()
})

onUnmounted(() => {
  unAck?.()
})
</script>

<template>
  <div class="h-full overflow-y-auto p-4 text-sm text-slate-200">
    <h1 class="mb-2 text-lg font-bold text-slate-50">{{ t('health.title') }}</h1>
    <p class="mb-4 text-xs text-slate-400">{{ t('health.subtitle') }}</p>

    <div class="mb-4 flex flex-wrap gap-2">
      <button
        type="button"
        class="rounded-lg bg-primary px-3 py-2 text-xs font-semibold text-white"
        :disabled="loading"
        @click="runCheck"
      >
        {{ t('health.recheck') }}
      </button>
      <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-xs text-slate-200" @click="copyReport">
        {{ t('health.copy_markdown') }}
      </button>
    </div>

    <div v-if="loading && !results.length" class="text-slate-400">{{ t('health.checking') }}</div>

    <div v-else class="grid gap-4 md:grid-cols-2">
      <HealthCard v-for="c in cards" :key="c.key" :title="c.title" :rows="c.rows" />
    </div>
  </div>
</template>
