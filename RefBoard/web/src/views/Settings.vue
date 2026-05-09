<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from '../stores/settings'
import { useNui, getResourceName, isInFiveM } from '../composables/useNui'
import { useToast } from '../composables/useToast'
import MarqueeText from '../components/common/MarqueeText.vue'
import HelpTriggerButton from '../components/help/HelpTriggerButton.vue'

const { t, locale } = useI18n()
const settings = useSettingsStore()
/** ローカル版では常に編集相当（サーバー側の閲覧モードなし） */
const isEditor = true
const { send, on } = useNui()
const { push: toast } = useToast()

const dbMeta = ref<{ schemaVersion?: string; resourceVersion?: string } | null>(null)
const devBusy = ref(false)
const devModal = ref<'fixture' | 'wipe' | null>(null)
const devConfirmInput = ref('')

/** 「テスト用DB操作パネル」チェック時のみ。FiveM 実機でも config.lua は不要。ブラウザ DEV はモック動作 */
const showDevDataPanel = computed(
  () =>
    settings.settings.showTestCommandsHint === true && (isInFiveM() === true || import.meta.env.DEV === true),
)

function openDevModal(kind: 'fixture' | 'wipe') {
  devModal.value = kind
  devConfirmInput.value = ''
}

function closeDevModal() {
  devModal.value = null
  devConfirmInput.value = ''
}

const canSubmitDevConfirm = computed(() => devConfirmInput.value.trim() === 'YES')

let unDevAck: (() => void) | null = null

function handleDevAck(p: {
  ok?: boolean
  error?: string
  action?: string
  detail?: string
}) {
  if (!devBusy.value) {
    return
  }
  devBusy.value = false
  closeDevModal()
  if (p?.ok) {
    if (p.action === 'apply_fixture') {
      toast(t('settings.dev_data.toast_fixture_ok'), 'success', { ms: 6000 })
    } else if (p.action === 'wipe_all') {
      toast(t('settings.dev_data.toast_wipe_ok'), 'success', { ms: 6000 })
    } else {
      toast(t('settings.dev_data.toast_ok'), 'success', { ms: 4000 })
    }
    return
  }
  const err = p?.error ?? 'unknown'
  if (err === 'test_commands_disabled') {
    toast(t('settings.dev_data.err_test_commands'), 'error', { ms: 8000 })
  } else if (err === 'no_permission') {
    toast(t('settings.dev_data.err_no_edit'), 'error', { ms: 8000 })
  } else if (err === 'bad_confirm') {
    toast(t('settings.dev_data.err_bad_confirm'), 'error')
  } else {
    toast(t('settings.dev_data.err_sql', { detail: p?.detail ? String(p.detail) : err }), 'error', { ms: 10000 })
  }
}

async function submitDevAction() {
  if (!canSubmitDevConfirm.value || !devModal.value || devBusy.value) {
    return
  }
  if (!isEditor) {
    toast(t('settings.dev_data.err_no_edit'), 'error')
    return
  }
  devBusy.value = true
  const path = devModal.value === 'fixture' ? 'dev_apply_fixture' : 'dev_wipe_all'
  try {
    await send(path, { confirm: 'YES' })
  } catch {
    devBusy.value = false
    toast(t('settings.dev_data.err_network'), 'error')
    return
  }
  devBusy.value = false
  closeDevModal()
}

onMounted(() => {
  settings.load()
  locale.value = settings.settings.locale
  dbMeta.value = { schemaVersion: 'local', resourceVersion: '0.1.0' }
  unDevAck = on('refboard:dev:data_action:ack', handleDevAck)
})

onUnmounted(() => {
  unDevAck?.()
})

function syncLocale() {
  locale.value = settings.settings.locale
  localStorage.setItem('refboard-locale', settings.settings.locale)
}
</script>

<template>
  <div class="h-full min-w-0 overflow-y-auto p-4 text-sm text-slate-200">
    <div class="mb-4 flex items-center gap-2">
      <h1 class="min-w-0 flex-1 overflow-hidden text-lg font-bold text-slate-50">
        <MarqueeText :text="t('settings.title')" variant="default" />
      </h1>
      <HelpTriggerButton context-id="settings" />
    </div>

    <section class="mb-6 rounded-lg border border-slate-700 bg-slate-900/70 p-4">
      <h2 class="mb-3 min-w-0 overflow-hidden text-sm font-semibold text-primary">
        <MarqueeText :text="t('settings.section_general')" variant="subtle" />
      </h2>
      <div class="grid gap-3 md:grid-cols-2">
        <label class="block text-slate-400 md:col-span-2">
          {{ t('settings.self_name') }}
          <input
            v-model="settings.settings.selfName"
            type="text"
            class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
            :placeholder="t('launcher.self_name_placeholder')"
          />
          <span class="mt-1 block text-xs text-slate-500">{{ t('settings.self_name_hint') }}</span>
          <p class="mt-1 text-xs text-slate-400">{{ t('settings.self_name_header_hint') }}</p>
        </label>
        <label class="block text-slate-400">
          {{ t('settings.locale') }}
          <select
            v-model="settings.settings.locale"
            class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
            @change="syncLocale"
          >
            <option value="ja">日本語</option>
            <option value="en">English</option>
          </select>
        </label>
        <label class="block text-slate-400">
          {{ t('settings.time_format') }}
          <select v-model="settings.settings.timeFormat" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100">
            <option value="mm:ss">mm:ss</option>
            <option value="mm.ss">mm.ss</option>
          </select>
        </label>
        <label class="block text-slate-400 md:col-span-2">
          {{ t('settings.timezone') }}
          <input v-model="settings.settings.timezone" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
      </div>
    </section>

    <section class="mb-6 rounded-lg border border-slate-700 bg-slate-900/70 p-4">
      <h2 class="mb-3 min-w-0 overflow-hidden text-sm font-semibold text-primary">
        <MarqueeText :text="t('settings.section_match')" variant="subtle" />
      </h2>
      <div class="grid gap-3 md:grid-cols-2">
        <label class="block text-slate-400">
          {{ t('settings.default_half_min') }}
          <input v-model.number="settings.settings.defaultHalfMinutes" type="number" min="1" max="120" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2" />
        </label>
        <label class="block text-slate-400">
          {{ t('settings.score_edit_min') }}
          <input v-model.number="settings.settings.scoreEditReasonMin" type="number" min="1" max="50" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2" />
        </label>
        <label class="flex items-center gap-2 text-slate-300">
          <input v-model="settings.settings.showStoppageHint" type="checkbox" class="rounded border-slate-500" />
          {{ t('settings.show_stoppage') }}
        </label>
        <label class="flex items-center gap-2 text-slate-300">
          <input v-model="settings.settings.goalConfirmDialog" type="checkbox" class="rounded border-slate-500" />
          {{ t('settings.goal_confirm') }}
        </label>
      </div>
    </section>

    <section class="mb-6 rounded-lg border border-slate-700 bg-slate-900/70 p-4">
      <h2 class="mb-3 min-w-0 overflow-hidden text-sm font-semibold text-primary">
        <MarqueeText :text="t('settings.section_display')" variant="subtle" />
      </h2>
      <fieldset class="mb-4 space-y-2 border-0 p-0">
        <legend class="mb-1 block min-w-0 overflow-hidden text-slate-400">
          <MarqueeText :text="t('settings.font_scale.label')" variant="subtle" />
        </legend>
        <p class="mb-2 min-w-0 overflow-hidden text-xs text-slate-500">
          <MarqueeText :text="t('settings.font_scale.description')" variant="subtle" />
        </p>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model.number="settings.settings.rootFontScale" type="radio" :value="100" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.font_scale.s100') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.font_scale.s100_desc') }}</span>
          </span>
        </label>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model.number="settings.settings.rootFontScale" type="radio" :value="150" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.font_scale.s150') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.font_scale.s150_desc') }}</span>
          </span>
        </label>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model.number="settings.settings.rootFontScale" type="radio" :value="200" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.font_scale.s200') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.font_scale.s200_desc') }}</span>
          </span>
        </label>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model.number="settings.settings.rootFontScale" type="radio" :value="250" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.font_scale.s250') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.font_scale.s250_desc') }}</span>
          </span>
        </label>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model.number="settings.settings.rootFontScale" type="radio" :value="300" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.font_scale.s300') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.font_scale.s300_desc') }}</span>
          </span>
        </label>
      </fieldset>
      <fieldset class="mb-4 space-y-2 border-0 p-0">
        <legend class="mb-1 block min-w-0 overflow-hidden text-slate-400">
          <MarqueeText :text="t('settings.marquee_mode.label')" variant="subtle" />
        </legend>
        <p class="mb-2 min-w-0 overflow-hidden text-xs text-slate-500">
          <MarqueeText :text="t('settings.marquee_mode.description')" variant="subtle" />
        </p>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model="settings.settings.marqueeMode" type="radio" value="always" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.marquee_mode.always') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.marquee_mode.always_desc') }}</span>
          </span>
        </label>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model="settings.settings.marqueeMode" type="radio" value="hover-only" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.marquee_mode.hover_only') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.marquee_mode.hover_only_desc') }}</span>
          </span>
        </label>
        <label class="flex cursor-pointer items-start gap-2 rounded border border-transparent px-1 py-1 hover:border-slate-600">
          <input v-model="settings.settings.marqueeMode" type="radio" value="off" class="mt-1 shrink-0 rounded border-slate-500" />
          <span>
            <span class="block text-slate-200">{{ t('settings.marquee_mode.off') }}</span>
            <span class="block text-xs text-slate-500">{{ t('settings.marquee_mode.off_desc') }}</span>
          </span>
        </label>
      </fieldset>
      <label class="flex items-center gap-2 text-slate-300">
        <input v-model="settings.settings.showHero" type="checkbox" class="rounded border-slate-500" />
        {{ t('settings.show_hero') }}
      </label>
      <label class="mt-3 flex items-center gap-2 text-slate-300">
        <input v-model="settings.settings.showBackgroundImage" type="checkbox" class="rounded border-slate-500" />
        {{ t('settings.show_background_image') }}
      </label>
      <p class="mt-1 text-xs text-slate-500">{{ t('settings.show_background_image_note') }}</p>
      <label class="mt-3 block text-slate-400">
        {{ t('settings.card_opacity') }} ({{ settings.settings.cardOpacity }}%)
        <input v-model.number="settings.settings.cardOpacity" type="range" min="70" max="100" class="mt-1 w-full" />
      </label>
      <label class="mt-3 block text-slate-400">
        {{ t('settings.avatar_hue') }}
        <input v-model.number="settings.settings.avatarHue" type="range" min="0" max="360" class="mt-1 w-full" />
      </label>
    </section>

    <section class="mb-6 rounded-lg border border-slate-700 bg-slate-900/70 p-4">
      <h2 class="mb-3 min-w-0 overflow-hidden text-sm font-semibold text-primary">
        <MarqueeText :text="t('settings.section_dev')" variant="subtle" />
      </h2>
      <label class="flex items-center gap-2 text-slate-300">
        <input v-model="settings.settings.nuiMock" type="checkbox" class="rounded border-slate-500" disabled />
        {{ t('settings.nui_mock') }}
      </label>
      <p class="mt-2 text-xs text-slate-500">{{ t('settings.nui_mock_note') }}</p>
      <label class="mt-3 flex items-center gap-2 text-slate-300">
        <input v-model="settings.settings.showTestCommandsHint" type="checkbox" class="rounded border-slate-500" />
        {{ t('settings.show_test_commands') }}
      </label>
      <div class="mt-3 rounded border border-slate-700 bg-slate-950/60 p-2 text-xs text-slate-400">
        <div>DB: {{ dbMeta?.schemaVersion || '—' }}</div>
        <div>Resource: {{ dbMeta?.resourceVersion || '—' }}</div>
        <div>getResourceName: {{ getResourceName() }}</div>
      </div>
      <div v-if="showDevDataPanel" class="mt-4 rounded-lg border border-amber-700/60 bg-amber-950/20 p-3">
        <h3 class="text-xs font-semibold text-amber-200">{{ t('settings.dev_data.title') }}</h3>
        <p class="mt-1 text-xs text-amber-100/90">{{ t('settings.dev_data.intro') }}</p>
        <p v-if="!isEditor" class="mt-2 text-xs font-medium text-amber-300">{{ t('settings.dev_data.need_edit') }}</p>
        <div class="mt-3 flex flex-col gap-2 sm:flex-row sm:flex-wrap">
          <button
            type="button"
            class="rounded-lg border border-red-700/70 bg-red-950/30 px-3 py-2 text-left text-xs font-medium text-red-100 hover:bg-red-950/50 disabled:cursor-not-allowed disabled:opacity-50"
            :disabled="!isEditor || devBusy"
            @click="openDevModal('wipe')"
          >
            {{ t('settings.dev_data.btn_wipe') }}
          </button>
          <button
            type="button"
            class="rounded-lg border border-amber-600/80 bg-amber-900/40 px-3 py-2 text-left text-xs font-medium text-amber-50 hover:bg-amber-900/60 disabled:cursor-not-allowed disabled:opacity-50"
            :disabled="!isEditor || devBusy"
            @click="openDevModal('fixture')"
          >
            {{ t('settings.dev_data.btn_fixture') }}
          </button>
        </div>
      </div>
    </section>

    <!-- 破壊的操作の確認（YES 入力） -->
    <Teleport to="body">
      <div
        v-if="devModal"
        class="fixed inset-0 z-[200] flex items-center justify-center bg-black/70 p-4"
        role="dialog"
        aria-modal="true"
      >
        <div class="max-h-[90vh] w-full max-w-md overflow-y-auto rounded-xl border border-slate-600 bg-slate-900 p-4 shadow-xl">
          <h3 class="text-base font-semibold text-slate-50">
            {{ devModal === 'fixture' ? t('settings.dev_data.modal_fixture_title') : t('settings.dev_data.modal_wipe_title') }}
          </h3>
          <p class="mt-2 text-sm leading-relaxed text-amber-100/95">
            {{ devModal === 'fixture' ? t('settings.dev_data.modal_fixture_body') : t('settings.dev_data.modal_wipe_body') }}
          </p>
          <p class="mt-3 text-xs text-slate-400">{{ t('settings.dev_data.type_yes') }}</p>
          <input
            v-model="devConfirmInput"
            type="text"
            autocomplete="off"
            class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
            :placeholder="t('settings.dev_data.yes_placeholder')"
          />
          <div class="mt-4 flex justify-end gap-2">
            <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-200" @click="closeDevModal">
              {{ t('settings.dev_data.cancel') }}
            </button>
            <button
              type="button"
              class="rounded-lg px-3 py-2 text-sm font-semibold text-white"
              :class="devModal === 'wipe' ? 'bg-red-700 hover:bg-red-600' : 'bg-amber-700 hover:bg-amber-600'"
              :disabled="!canSubmitDevConfirm || devBusy"
              @click="submitDevAction"
            >
              {{ t('settings.dev_data.execute') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
