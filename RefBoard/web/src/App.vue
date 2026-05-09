<script setup lang="ts">
import { computed, onMounted, provide, watchEffect } from 'vue'
import { storeToRefs } from 'pinia'
import { useMatchCompactDockStore } from './stores/matchCompactDock'
import { useSettingsStore } from './stores/settings'
import { isInFiveM } from './composables/useNui'
import Toast from './components/Toast.vue'
import appBackgroundUrl from '../image/back.jpg'
import { nuiShellOpenRef } from './nuiShellVisibility'

const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)
const { transparentChrome } = storeToRefs(useMatchCompactDockStore())
const marqueeMode = computed(() => settings.value.marqueeMode)
const showBackgroundImage = computed(() => settings.value.showBackgroundImage)
const rootFontScale = computed(() => settings.value.rootFontScale)

const appRootBgClass = computed(() => {
  if (transparentChrome.value) return 'bg-transparent'
  if (showBackgroundImage.value) return 'bg-cover bg-center bg-no-repeat'
  return 'bg-[rgb(15_23_42/0.88)] backdrop-blur-[1px]'
})

provide('marqueeMode', marqueeMode)

watchEffect(() => {
  if (typeof document !== 'undefined') {
    document.documentElement.style.fontSize = `${rootFontScale.value}%`
  }
})

/** FiveM では Lua が開いたときだけシェル描画。閉じている間は CEF がログイン UI を覆わない */
const showNuiChrome = computed(() => {
  if (import.meta.env.DEV && !isInFiveM()) return true
  return nuiShellOpenRef.value
})

onMounted(() => {
  settingsStore.load()
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
