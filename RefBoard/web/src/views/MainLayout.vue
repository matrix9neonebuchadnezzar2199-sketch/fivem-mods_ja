<script setup lang="ts">
import { onMounted } from 'vue'
import { storeToRefs } from 'pinia'
import { useI18n } from 'vue-i18n'
import { RouterLink, RouterView, useRouter } from 'vue-router'
import { REFBOARD_UI_VERSION } from '../constants/version'
import { useSettingsStore } from '../stores/settings'
import { useMatchCompactDockStore } from '../stores/matchCompactDock'
import { useNui } from '../composables/useNui'
import ContextHelpPanel from '../components/help/ContextHelpPanel.vue'

const { t, locale } = useI18n()
const settingsStore = useSettingsStore()
const { send } = useNui()
const { transparentChrome } = storeToRefs(useMatchCompactDockStore())
const router = useRouter()

onMounted(() => {
  settingsStore.load()
  locale.value = settingsStore.settings.locale
})

function toggleLocale() {
  const next = locale.value === 'ja' ? 'en' : 'ja'
  locale.value = next
  settingsStore.patch({ locale: next })
  localStorage.setItem('refboard-locale', next)
}

async function closeApp() {
  await send('close')
  await router.push({ name: 'launcher' })
}
</script>

<template>
  <div class="layout grid h-full w-full" :class="{ 'layout--stadium-compact': transparentChrome }">
    <aside class="sidebar flex min-w-0 flex-col overflow-hidden border-r border-slate-700/80 bg-slate-900/90 p-3 text-sm">
      <div class="mb-3 shrink-0 font-semibold text-primary">RefBoard</div>
      <nav class="flex min-w-0 flex-1 flex-col gap-1 overflow-hidden">
        <RouterLink
          :to="{ name: 'teams' }"
          class="block min-w-0 overflow-hidden rounded-lg px-2 py-2 text-slate-400 hover:bg-slate-800 hover:text-slate-200"
          active-class="!bg-slate-800 !text-slate-100"
        >
          <span class="block min-w-0 w-full overflow-hidden" v-marquee="{ variant: 'subtle', text: t('sidebar.team_manage') }" />
        </RouterLink>
        <RouterLink
          :to="{ name: 'matches' }"
          class="block min-w-0 overflow-hidden rounded-lg px-2 py-2 text-slate-400 hover:bg-slate-800 hover:text-slate-200"
          active-class="!bg-slate-800 !text-slate-100"
        >
          <span class="block min-w-0 w-full overflow-hidden" v-marquee="{ variant: 'subtle', text: t('sidebar.match_manage') }" />
        </RouterLink>
        <RouterLink
          :to="{ name: 'help' }"
          class="block min-w-0 overflow-hidden rounded-lg px-2 py-2 text-slate-400 hover:bg-slate-800 hover:text-slate-200"
          active-class="!bg-slate-800 !text-slate-100"
        >
          <span class="block min-w-0 w-full overflow-hidden" v-marquee="{ variant: 'subtle', text: t('sidebar.help') }" />
        </RouterLink>
        <RouterLink
          :to="{ name: 'settings' }"
          class="block min-w-0 overflow-hidden rounded-lg px-2 py-2 text-slate-400 hover:bg-slate-800 hover:text-slate-200"
          active-class="!bg-slate-800 !text-slate-100"
        >
          <span class="block min-w-0 w-full overflow-hidden" v-marquee="{ variant: 'subtle', text: t('sidebar.settings') }" />
        </RouterLink>
      </nav>
      <div class="mt-auto shrink-0 space-y-2 border-t border-slate-700/80 pt-3 text-xs text-slate-400">
        <div>v{{ REFBOARD_UI_VERSION }}</div>
      </div>
      <button type="button" class="mt-2 shrink-0 rounded-lg border border-slate-600 px-2 py-1 text-xs" @click="toggleLocale">
        {{ locale === 'ja' ? 'EN' : 'JA' }}
      </button>
    </aside>
    <div class="main flex min-h-0 min-w-0 flex-col border-r border-slate-700/80 bg-slate-900/90">
      <header
        v-if="!transparentChrome"
        class="main-header flex shrink-0 flex-wrap items-center justify-between gap-2 border-b border-slate-700/80 px-4 py-2"
      >
        <div class="text-xs text-slate-500">{{ t('shell.local_mode') }}</div>
        <button type="button" class="rounded-lg bg-slate-800 px-3 py-1.5 text-xs text-slate-200" @click="closeApp">
          {{ t('shell.close') }}
        </button>
      </header>
      <div class="flex min-h-0 flex-1 flex-col overflow-hidden">
        <RouterView v-slot="{ Component }">
          <component :is="Component" class="flex min-h-0 flex-1 flex-col overflow-hidden" />
        </RouterView>
      </div>
    </div>
    <ContextHelpPanel />
  </div>
</template>

<style scoped>
.layout {
  display: grid;
  grid-template-columns: minmax(11rem, 14rem) minmax(0, 1fr);
  height: 100vh;
  width: 100vw;
}
.layout--stadium-compact {
  grid-template-columns: 1fr;
}
.layout--stadium-compact .sidebar {
  display: none;
}
.layout--stadium-compact .main {
  background-color: transparent;
  border-color: transparent;
  pointer-events: none;
}
</style>
