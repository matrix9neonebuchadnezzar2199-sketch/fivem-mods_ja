<script setup lang="ts">
import { computed, onMounted, provide } from 'vue'
import { storeToRefs } from 'pinia'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from './stores/settings'
import { useSessionStore } from './stores/session'
import { usePresenceStore, type PresenceUser } from './stores/presence'
import { useAutosaveStore } from './stores/autosave'
import { useNui } from './composables/useNui'
import { useToast } from './composables/useToast'
import Toast from './components/Toast.vue'
import appBackgroundUrl from '../image/back.jpg'

const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)
const marqueeMode = computed(() => settings.value.marqueeMode)
provide('marqueeMode', marqueeMode)

const session = useSessionStore()
const presence = usePresenceStore()
const autosave = useAutosaveStore()
const { on } = useNui()
const { t } = useI18n()
const { push: toastPush } = useToast()

onMounted(() => {
  session.bindServerMessages()
  on('refboard:presence:update', (p) => {
    presence.applyUpdate(p as { users?: PresenceUser[] })
  })
  on('refboard:presence:list:ack', (p) => {
    presence.applyUpdate(p as { users?: PresenceUser[] })
  })
  on('refboard:autosave:saved', (p: { savedAt?: number; error?: string }) => {
    if (p?.error) {
      autosave.markError()
      toastPush(t('autosave.error'), 'error', {
        ms: 8000,
        errorCode: 'E4003',
        errorKey: 'tx_failed',
      })
    } else if (p?.savedAt) {
      autosave.markSaved(p.savedAt)
    }
  })
})
</script>

<template>
  <div
    class="relative flex h-full min-h-0 flex-col bg-cover bg-center bg-no-repeat"
    :style="{ backgroundImage: `url(${appBackgroundUrl})` }"
    :data-marquee-mode="marqueeMode"
  >
    <div
      class="pointer-events-none absolute inset-0 bg-slate-950/78 backdrop-blur-[1px]"
      aria-hidden="true"
    />
    <div class="relative z-0 flex min-h-0 flex-1 flex-col">
      <router-view />
    </div>
    <Toast />
  </div>
</template>
