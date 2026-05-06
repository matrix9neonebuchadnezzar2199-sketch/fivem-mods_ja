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
    class="flex h-full min-h-0 flex-col bg-[rgb(15_23_42/0.88)] backdrop-blur-[1px]"
    :data-marquee-mode="marqueeMode"
  >
    <router-view />
    <Toast />
  </div>
</template>
