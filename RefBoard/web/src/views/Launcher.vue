<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'

const { t } = useI18n()
const router = useRouter()
const session = useSessionStore()

async function goEdit() {
  await session.enterEdit()
  await router.push({ name: 'main' })
}

async function goView() {
  await session.enterView()
  await router.push({ name: 'main' })
}
</script>

<template>
  <div class="flex min-h-full flex-col items-center justify-center gap-6 p-8">
    <div class="text-center">
      <h1 class="text-2xl font-bold text-slate-50">{{ t('app.title') }}</h1>
      <p class="mt-2 text-sm text-slate-400">RefBoard v0.1.1</p>
    </div>
    <div class="flex w-full max-w-md flex-col gap-3">
      <button
        type="button"
        class="rounded-xl bg-primary px-4 py-3 text-left text-sm font-semibold text-white shadow-lg shadow-primary/25 transition hover:brightness-110"
        @click="goEdit"
      >
        {{ t('launcher.edit_mode') }}
      </button>
      <button
        type="button"
        class="rounded-xl border border-slate-600 bg-slate-900/80 px-4 py-3 text-left text-sm font-semibold text-slate-100 transition hover:border-warning hover:text-warning"
        @click="goView"
      >
        {{ t('launcher.view_mode') }}
      </button>
    </div>
  </div>
</template>
