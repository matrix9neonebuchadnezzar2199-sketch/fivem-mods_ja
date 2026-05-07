<script setup lang="ts">
import { ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useSessionStore } from '../stores/session'
import { useToast } from '../composables/useToast'
import { REFBOARD_UI_VERSION } from '../constants/version'

const { t } = useI18n()
const router = useRouter()
const session = useSessionStore()
const { editPassword } = storeToRefs(session)
const { push: toastPush } = useToast()

const showLockDialog = ref(false)
const lockPeerName = ref('')

async function goEdit() {
  const r = await session.enterEdit()
  if (r.ok) {
    await router.push({ name: 'matches' })
    return
  }
  if (r.error === 'bad_password') {
    toastPush(t('launcher.bad_password'), 'error', 4000)
    return
  }
  if (r.error === 'session_timeout' || r.error === 'session_failed') {
    toastPush(t('launcher.session_failed'), 'error', 4000)
    return
  }
  if (r.holder?.name) {
    lockPeerName.value = r.holder.name
  } else {
    lockPeerName.value = t('launcher.unknown_editor')
  }
  showLockDialog.value = true
}

async function goView() {
  await session.enterView()
  await router.push({ name: 'matches' })
}

async function openAsViewFromDialog() {
  showLockDialog.value = false
  await session.enterView()
  await router.push({ name: 'matches' })
}

function closeDialog() {
  showLockDialog.value = false
}

function enableDebugTrace() {
  try {
    localStorage.setItem('refboard_trace', '1')
    window.location.reload()
  } catch {
    /* ignore */
  }
}
</script>

<template>
  <div class="flex min-h-full flex-col items-center justify-center gap-6 p-8">
    <div class="text-center">
      <h1 class="text-2xl font-bold text-slate-50">{{ t('app.title') }}</h1>
      <p class="mt-2 text-sm text-slate-400">RefBoard v{{ REFBOARD_UI_VERSION }}</p>
    </div>
    <div class="flex w-full max-w-md flex-col gap-3">
      <label class="block w-full text-left text-xs text-slate-400">
        {{ t('launcher.edit_password_hint') }}
        <input
          v-model="editPassword"
          type="password"
          autocomplete="off"
          class="mt-1 w-full rounded-lg border border-slate-600 bg-slate-950 px-3 py-2 text-sm text-slate-100"
        />
      </label>
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

    <div
      v-if="showLockDialog"
      class="fixed inset-0 z-[200] flex items-center justify-center bg-black/55 p-4"
      @click.self="closeDialog"
    >
      <div class="max-w-md rounded-xl border border-slate-700 bg-slate-900 p-6 shadow-2xl">
        <h2 class="mb-2 text-lg font-semibold text-slate-50">{{ t('launcher.lock_title') }}</h2>
        <p class="mb-4 text-sm text-slate-400">{{ t('launcher.lock_body', { name: lockPeerName }) }}</p>
        <div class="flex justify-end gap-2">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-300" @click="closeDialog">
            {{ t('launcher.lock_back') }}
          </button>
          <button type="button" class="rounded-lg bg-warning/90 px-3 py-2 text-sm font-semibold text-white drop-shadow-sm" @click="openAsViewFromDialog">
            {{ t('launcher.lock_open_view') }}
          </button>
        </div>
      </div>
    </div>

    <button type="button" class="text-xs text-slate-500 underline decoration-dotted hover:text-slate-400" @click="enableDebugTrace">
      {{ t('launcher.debug_trace') }}
    </button>
  </div>
</template>
