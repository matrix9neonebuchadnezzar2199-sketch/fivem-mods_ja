<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from '../stores/settings'
import { useNui, getResourceName } from '../composables/useNui'
import MarqueeText from '../components/common/MarqueeText.vue'

const { t, locale } = useI18n()
const settings = useSettingsStore()
const { send, on } = useNui()

const dbMeta = ref<{ schemaVersion?: string; resourceVersion?: string } | null>(null)

onMounted(() => {
  settings.load()
  locale.value = settings.settings.locale
  const un = on('refboard:data:db_meta:ack', (p: { schemaVersion?: string; resourceVersion?: string }) => {
    un()
    dbMeta.value = p
  })
  void send('data_db_meta', {})
})

function syncLocale() {
  locale.value = settings.settings.locale
  localStorage.setItem('refboard-locale', settings.settings.locale)
}
</script>

<template>
  <div class="h-full min-w-0 overflow-y-auto p-4 text-sm text-slate-200">
    <h1 class="mb-4 min-w-0 overflow-hidden text-lg font-bold text-slate-50">
      <MarqueeText :text="t('settings.title')" variant="default" />
    </h1>

    <section class="mb-6 rounded-lg border border-slate-700 bg-slate-900/70 p-4">
      <h2 class="mb-3 min-w-0 overflow-hidden text-sm font-semibold text-primary">
        <MarqueeText :text="t('settings.section_general')" variant="subtle" />
      </h2>
      <div class="grid gap-3 md:grid-cols-2">
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
      <router-link
        :to="{ name: 'health' }"
        class="mt-3 inline-block text-xs font-medium text-primary underline decoration-primary/40 hover:decoration-primary"
      >
        {{ t('settings.health_link') }} →
      </router-link>
    </section>
  </div>
</template>
