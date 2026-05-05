<script setup lang="ts">
import { onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter, RouterLink, RouterView } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { getResourceName, useNui } from '../composables/useNui'
import PresenceBadge from '../components/PresenceBadge.vue'

const { t, locale } = useI18n()
const router = useRouter()
const session = useSessionStore()
const { send } = useNui()

onMounted(() => {
  void send('presence_list', {})
})

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
        <span class="rounded-lg px-2 py-2 text-slate-500">{{ t('sidebar.team_manage') }}</span>
        <RouterLink
          :to="{ name: 'matches' }"
          class="rounded-lg px-2 py-2 text-slate-400 hover:bg-slate-800 hover:text-slate-200"
          active-class="!bg-slate-800 !text-slate-100"
        >
          {{ t('sidebar.match_manage') }}
        </RouterLink>
        <span class="rounded-lg px-2 py-2 text-slate-500">{{ t('sidebar.data_manage') }}</span>
      </nav>
      <div class="mt-auto space-y-2 border-t border-slate-700/80 pt-3 text-xs text-slate-400">
        <div class="flex items-center gap-1.5 text-emerald-400">
          <span class="h-2 w-2 rounded-full bg-emerald-400" />
          {{ t('shell.online') }}
        </div>
        <div>v0.2.0</div>
      </div>
      <button type="button" class="mt-2 rounded-lg border border-slate-600 px-2 py-1 text-xs" @click="toggleLocale">
        {{ locale === 'ja' ? 'EN' : 'JA' }}
      </button>
    </aside>
    <div class="main flex min-h-0 min-w-0 flex-col border-r border-slate-700/80 bg-slate-900/90">
      <header class="flex shrink-0 flex-wrap items-center justify-between gap-2 border-b border-slate-700/80 px-4 py-2">
        <PresenceBadge />
        <button type="button" class="rounded-lg bg-slate-800 px-3 py-1.5 text-xs text-slate-200" @click="closeApp">Close</button>
      </header>
      <div class="min-h-0 flex-1 overflow-hidden">
        <RouterView />
      </div>
    </div>
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
