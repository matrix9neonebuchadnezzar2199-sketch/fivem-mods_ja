<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from '../stores/settings'
import { isInFiveM } from '../composables/useNui'
import MarqueeText from '../components/common/MarqueeText.vue'
import HelpTriggerButton from '../components/help/HelpTriggerButton.vue'
import { isSeedInstalled, getSeedInstalledAt, installSeedData, clearMatchData, clearAllData } from '../dev/seedActions'
import { useDialogOverlay } from '../composables/useDialogOverlay'

const { overlayRootClass } = useDialogOverlay()
const settingsSeedConfirmOverlayClass = overlayRootClass('z-[200]', 'bg-black/60')

const { t, locale } = useI18n()
const settings = useSettingsStore()

const seedInstalled = ref(false)
const seedInstalledAt = ref<string | null>(null)
const confirmAction = ref<null | 'install' | 'clear_match' | 'clear_all'>(null)

/** 「テスト用データ操作パネル」チェック時のみ。FiveM 実機でも config.lua は不要。ブラウザ DEV は表示可 */
const showDevDataPanel = computed(
  () =>
    settings.settings.showTestCommandsHint === true && (isInFiveM() === true || import.meta.env.DEV === true),
)

function refreshSeedStatus() {
  seedInstalled.value = isSeedInstalled()
  seedInstalledAt.value = getSeedInstalledAt()
}

onMounted(() => {
  settings.load()
  locale.value = settings.settings.locale
  refreshSeedStatus()
})

function askInstall() {
  confirmAction.value = 'install'
}
function askClearMatch() {
  confirmAction.value = 'clear_match'
}
function askClearAll() {
  confirmAction.value = 'clear_all'
}
function cancelConfirm() {
  confirmAction.value = null
}

function executeConfirmed() {
  const a = confirmAction.value
  if (a === 'install') installSeedData()
  else if (a === 'clear_match') clearMatchData()
  else if (a === 'clear_all') clearAllData()
  confirmAction.value = null
  location.reload()
}

const confirmExecuteClass = computed(() => {
  if (confirmAction.value === 'install') {
    return 'bg-emerald-600 hover:bg-emerald-500'
  }
  return 'bg-rose-600 hover:bg-rose-500'
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

      <div v-if="showDevDataPanel" class="mt-4 rounded-lg border border-amber-700/60 bg-amber-950/20 p-3">
        <fieldset class="border-0 p-0">
          <legend class="text-sm text-amber-100">{{ t('settings.dev_seed.title') }}</legend>
          <p class="mt-2 text-xs text-amber-100/90">{{ t('settings.dev_seed.warning') }}</p>

          <div class="mt-3 flex flex-col gap-2 sm:flex-row sm:flex-wrap">
            <button
              type="button"
              class="rounded bg-emerald-600 px-3 py-1.5 text-sm text-white hover:bg-emerald-500"
              @click="askInstall"
            >
              {{ t('settings.dev_seed.install_button') }}
            </button>
            <button
              type="button"
              class="rounded bg-rose-600 px-3 py-1.5 text-sm text-white hover:bg-rose-500"
              @click="askClearMatch"
            >
              {{ t('settings.dev_seed.clear_match_button') }}
            </button>
            <button
              type="button"
              class="rounded bg-rose-900 px-3 py-1.5 text-sm text-white hover:bg-rose-800"
              @click="askClearAll"
            >
              {{ t('settings.dev_seed.clear_all_button') }}
            </button>
          </div>
          <p v-if="seedInstalled" class="mt-2 text-xs text-slate-400">
            {{ t('settings.dev_seed.installed_at', { at: seedInstalledAt ?? '—' }) }}
          </p>
        </fieldset>
      </div>
    </section>

    <Teleport to="body">
      <div v-if="confirmAction" :class="settingsSeedConfirmOverlayClass" role="dialog" aria-modal="true">
        <div class="max-w-md rounded-lg border border-slate-600 bg-slate-800 p-4 shadow-lg">
          <p class="text-sm text-slate-200">
            {{ t(`settings.dev_seed.confirm_${confirmAction}`) }}
          </p>
          <div class="mt-4 flex justify-end gap-2">
            <button
              type="button"
              class="rounded bg-slate-700 px-3 py-1.5 text-sm text-slate-200 hover:bg-slate-600"
              @click="cancelConfirm"
            >
              {{ t('common.cancel') }}
            </button>
            <button
              type="button"
              class="rounded px-3 py-1.5 text-sm font-medium text-white"
              :class="confirmExecuteClass"
              @click="executeConfirmed"
            >
              {{ t('common.execute') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
