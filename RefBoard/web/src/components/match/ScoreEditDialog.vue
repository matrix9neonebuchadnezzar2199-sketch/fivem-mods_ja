<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import type { MatchDetailModel } from '../../types/match'

const props = defineProps<{
  open: boolean
  model: MatchDetailModel
}>()

const emit = defineEmits<{
  'update:open': [boolean]
  saved: []
  'manual-score': [{ homeScore: number; awayScore: number; reason: string }]
}>()

const { t } = useI18n()

const form = reactive({
  s1: 0,
  s2: 0,
  reason: '',
})

watch(
  () => props.open,
  (v) => {
    if (v) {
      form.s1 = props.model.score.home
      form.s2 = props.model.score.away
      form.reason = ''
    }
  },
)

const reasonOk = computed(() => form.reason.trim().length >= 5)

function bump(which: 1 | 2, delta: number) {
  if (which === 1) form.s1 = Math.max(0, form.s1 + delta)
  else form.s2 = Math.max(0, form.s2 + delta)
}

function close() {
  emit('update:open', false)
}

function save() {
  if (!reasonOk.value) return
  emit('manual-score', {
    homeScore: form.s1,
    awayScore: form.s2,
    reason: form.reason.trim(),
  })
  emit('saved')
  close()
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[150] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-2 text-lg font-bold text-slate-50">{{ t('score_manual.title') }}</h2>
      <p class="mb-3 text-sm text-slate-400">
        {{ t('score_manual.current') }}: {{ model.score.home }} - {{ model.score.away }}
      </p>
      <div class="mb-4 flex items-center justify-center gap-3 text-2xl font-bold text-slate-100">
        <div class="flex items-center gap-1">
          <button type="button" class="rounded border border-slate-600 px-2 py-1 text-sm" @click="bump(1, -1)">−</button>
          <input v-model.number="form.s1" type="number" min="0" class="w-16 rounded border border-slate-600 bg-slate-950 px-2 py-1 text-center" />
          <button type="button" class="rounded border border-slate-600 px-2 py-1 text-sm" @click="bump(1, 1)">+</button>
        </div>
        <span>-</span>
        <div class="flex items-center gap-1">
          <button type="button" class="rounded border border-slate-600 px-2 py-1 text-sm" @click="bump(2, -1)">−</button>
          <input v-model.number="form.s2" type="number" min="0" class="w-16 rounded border border-slate-600 bg-slate-950 px-2 py-1 text-center" />
          <button type="button" class="rounded border border-slate-600 px-2 py-1 text-sm" @click="bump(2, 1)">+</button>
        </div>
      </div>
      <label class="mb-2 block text-sm text-slate-400">
        {{ t('score_manual.reason') }} <span class="text-red-400">*</span>
        <textarea
          v-model="form.reason"
          rows="3"
          class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100"
          :placeholder="t('score_manual.reason_ph')"
        />
      </label>
      <p class="mb-3 text-xs text-amber-400">{{ t('score_manual.warn') }}</p>
      <div class="flex justify-end gap-2">
        <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="close">{{ t('dialog.no') }}</button>
        <button
          type="button"
          class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white disabled:opacity-40"
          :disabled="!reasonOk"
          @click="save"
        >
          {{ t('score_manual.confirm') }}
        </button>
      </div>
    </div>
  </div>
</template>
