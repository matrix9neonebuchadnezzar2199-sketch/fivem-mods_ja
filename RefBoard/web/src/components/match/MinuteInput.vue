<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { formatMinute, parseMinuteInput, type ParsedMinute } from '../../utils/matchTime'

const props = withDefaults(
  defineProps<{
    modelValue: ParsedMinute | null
    suggested?: ParsedMinute | null
    required?: boolean
    disabled?: boolean
  }>(),
  { required: false, disabled: false, suggested: null },
)

const emit = defineEmits<{
  'update:modelValue': [value: ParsedMinute | null]
  validity: [ok: boolean]
}>()

const { t } = useI18n()
const text = ref('')
const error = ref<string | null>(null)

const placeholder = computed(() => {
  if (!props.suggested) return '45 / 45+2'
  return formatMinute(props.suggested.minute, props.suggested.stoppage).replace(/'$/, '')
})

watch(
  () => props.modelValue,
  (v) => {
    if (!v) {
      text.value = ''
      return
    }
    text.value = v.stoppage == null ? String(v.minute) : `${v.minute}+${v.stoppage}`
  },
  { immediate: true },
)

function commit() {
  const raw = text.value.trim()
  if (!raw) {
    error.value = null
    emit('update:modelValue', null)
    emit('validity', !props.required)
    return
  }
  const r = parseMinuteInput(raw)
  if (!r.ok) {
    error.value = t(`match.minute_input.error_${r.reason}`)
    emit('validity', false)
    return
  }
  error.value = null
  emit('update:modelValue', r.value)
  emit('validity', true)
}
</script>

<template>
  <div class="flex flex-col gap-1">
    <input
      v-model="text"
      type="text"
      inputmode="text"
      autocomplete="off"
      :placeholder="placeholder"
      :disabled="disabled"
      class="rounded border border-slate-600 bg-slate-800 px-2 py-1 text-sm text-slate-100"
      @blur="commit"
      @keyup.enter="commit"
    />
    <p v-if="error" class="text-xs text-rose-400">{{ error }}</p>
    <p v-else class="text-xs text-slate-500">{{ t('match.minute_input.hint') }}</p>
  </div>
</template>
