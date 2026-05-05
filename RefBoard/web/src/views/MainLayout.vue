<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { useMatchStore } from '../stores/match'
import { useHeartbeat } from '../composables/useHeartbeat'
import { getResourceName } from '../composables/useNui'

const { t, locale } = useI18n()
const router = useRouter()
const session = useSessionStore()
const match = useMatchStore()

useHeartbeat()

async function closeApp() {
  await session.leave()
  await fetch(`https://${getResourceName()}/refboard:close`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: '{}',
  }).catch(() => undefined)
  await router.push({ name: 'launcher' })
}

function toggleLocale() {
  locale.value = locale.value === 'ja' ? 'en' : 'ja'
  localStorage.setItem('refboard-locale', locale.value)
}
</script>

<template>
  <div class="layout grid h-full w-full">
    <aside class="sidebar flex flex-col border-r border-slate-700/80 bg-slate-900/90 p-3 text-sm">
      <div class="mb-3 font-semibold text-primary">RefBoard</div>
      <nav class="flex flex-1 flex-col gap-1">
        <span class="rounded-lg bg-slate-800 px-2 py-2 text-slate-200">{{ t('sidebar.team_manage') }}</span>
        <span class="rounded-lg px-2 py-2 text-slate-400">{{ t('sidebar.match_manage') }}</span>
        <span class="rounded-lg px-2 py-2 text-slate-400">{{ t('sidebar.data_manage') }}</span>
      </nav>
      <button type="button" class="mt-2 rounded-lg border border-slate-600 px-2 py-1 text-xs" @click="toggleLocale">
        {{ locale === 'ja' ? 'EN' : 'JA' }}
      </button>
    </aside>
    <main class="main flex flex-col border-r border-slate-700/80 bg-slate-900/90 p-4">
      <header class="mb-3 flex items-center justify-between gap-2">
        <h2 class="text-lg font-semibold text-slate-50">{{ t('match.score_record') }}</h2>
        <button type="button" class="rounded-lg bg-slate-800 px-2 py-1 text-xs" @click="closeApp">Close</button>
      </header>
      <div class="flex flex-1 flex-col gap-4">
        <div class="rounded-xl border border-slate-700 bg-slate-950/60 p-4">
          <div class="text-center text-3xl font-bold tracking-widest text-slate-50">
            {{ match.team1Score }} - {{ match.team2Score }}
          </div>
          <div class="mt-2 text-center text-xs text-slate-400">{{ t('match.first_half') }}</div>
        </div>
        <p class="text-xs text-slate-500">
          {{ session.isEditor ? t('badge.editing_by_you') : t('badge.viewing') }}
        </p>
      </div>
    </main>
    <section class="viewport-spacer" aria-hidden="true" />
  </div>
</template>

<style scoped>
.layout {
  display: grid;
  grid-template-columns: 20% 30% 50%;
  height: 100vh;
  width: 100vw;
}
.viewport-spacer {
  background: transparent;
  pointer-events: none;
}
</style>
