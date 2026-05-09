<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useNui } from '../composables/useNui'
import { REFBOARD_UI_VERSION } from '../constants/version'

const { t } = useI18n()
const router = useRouter()
const { send } = useNui()

async function enter() {
  await router.push({ name: 'matches' })
}

async function backToGame() {
  await send('close')
}
</script>

<template>
  <div class="flex min-h-full flex-col items-center justify-center gap-6 p-8">
    <div class="text-center">
      <h1 class="text-2xl font-bold text-slate-50">{{ t('app.title') }}</h1>
      <p class="mt-2 text-sm text-slate-400">RefBoard v{{ REFBOARD_UI_VERSION }}</p>
      <p class="mt-4 max-w-md text-sm text-slate-400">{{ t('launcher.local_intro') }}</p>
    </div>
    <button
      type="button"
      class="rounded-xl bg-primary px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-primary/25 transition hover:brightness-110"
      @click="enter"
    >
      {{ t('launcher.enter') }}
    </button>
    <p class="text-xs text-slate-500">{{ t('launcher.self_name_hint') }}</p>
    <router-link to="/workspace/settings" class="text-sm text-primary underline">
      {{ t('launcher.go_to_settings') }}
    </router-link>
    <button
      type="button"
      class="rounded-xl border border-slate-600 bg-slate-950/80 px-4 py-3 text-sm text-slate-300 transition hover:border-slate-500 hover:text-slate-100"
      @click="backToGame"
    >
      {{ t('launcher.back_to_game') }}
    </button>
  </div>
</template>
