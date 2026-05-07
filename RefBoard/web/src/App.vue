<script setup lang="ts">
import { computed, onMounted, provide } from 'vue'
import { storeToRefs } from 'pinia'
import { useMatchCompactDockStore } from './stores/matchCompactDock'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from './stores/settings'
import { useSessionStore } from './stores/session'
import { usePresenceStore, type PresenceUser } from './stores/presence'
import { useAutosaveStore } from './stores/autosave'
import { useNui, isInFiveM } from './composables/useNui'
import { useToast } from './composables/useToast'
import Toast from './components/Toast.vue'
import appBackgroundUrl from '../image/back.jpg'
import { nuiShellOpenRef } from './nuiShellVisibility'

const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)
const { transparentChrome } = storeToRefs(useMatchCompactDockStore())
const marqueeMode = computed(() => settings.value.marqueeMode)
const showBackgroundImage = computed(() => settings.value.showBackgroundImage)

const appRootBgClass = computed(() => {
  if (transparentChrome.value) return 'bg-transparent'
  if (showBackgroundImage.value) return 'bg-cover bg-center bg-no-repeat'
  return 'bg-[rgb(15_23_42/0.88)] backdrop-blur-[1px]'
})

provide('marqueeMode', marqueeMode)

/** FiveM では Lua が開いたときだけシェル描画。閉じている間は CEF がログイン UI を覆わない */
const showNuiChrome = computed(() => {
  if (import.meta.env.DEV && !isInFiveM()) return true
  return nuiShellOpenRef.value
})

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
    v-if="showNuiChrome"
    class="relative flex h-full min-h-0 flex-col"
    :class="appRootBgClass"
    :style="showBackgroundImage && !transparentChrome ? { backgroundImage: `url(${appBackgroundUrl})` } : {}"
    :data-marquee-mode="marqueeMode"
  >
    <div
      v-if="showBackgroundImage && !transparentChrome"
      class="pointer-events-none absolute inset-0 z-0 bg-slate-950/78 backdrop-blur-[1px]"
      aria-hidden="true"
    />
    <div
      class="relative z-10 flex min-h-0 flex-1 flex-col"
      :class="{ 'pointer-events-none': transparentChrome }"
    >
      <router-view />
    </div>
    <Toast />
  </div>
</template>
