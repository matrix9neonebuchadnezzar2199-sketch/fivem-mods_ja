<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

const props = withDefaults(
  defineProps<{
    /** localStorage 用（折りたたみ状態を覚える） */
    storageKey: string
    title: string
    editorHere?: boolean
    defaultOpen?: boolean
  }>(),
  { editorHere: false, defaultOpen: true },
)

const { t } = useI18n()
const open = ref(props.defaultOpen)

onMounted(() => {
  try {
    const v = localStorage.getItem(`refboard:matchSection:${props.storageKey}`)
    if (v === '0') open.value = false
    else if (v === '1') open.value = true
  } catch {
    /* ignore */
  }
})

function toggle() {
  open.value = !open.value
  try {
    localStorage.setItem(`refboard:matchSection:${props.storageKey}`, open.value ? '1' : '0')
  } catch {
    /* ignore */
  }
}
</script>

<template>
  <div
    class="overflow-hidden rounded-lg border border-slate-700/55 bg-slate-900/40 shadow-sm backdrop-blur-md"
  >
    <button
      type="button"
      class="flex w-full items-center justify-between gap-2 px-3 py-2.5 text-left text-slate-200 hover:bg-white/5"
      :aria-expanded="open"
      :aria-label="open ? t('match_detail.section_collapse') : t('match_detail.section_expand')"
      @click="toggle"
    >
      <span class="flex min-w-0 flex-1 items-center gap-2">
        <span class="w-5 shrink-0 select-none text-center text-xs text-slate-400" aria-hidden="true">
          {{ open ? '▲' : '▼' }}
        </span>
        <span class="truncate text-sm font-semibold">{{ title }}</span>
      </span>
      <span class="flex shrink-0 items-center gap-2" @click.stop>
        <slot name="toolbar" />
        <span
          v-if="editorHere"
          class="rounded bg-emerald-500/20 px-2 py-0.5 text-[10px] font-semibold text-emerald-300"
        >
          {{ t('match_status.editing_here') }}
        </span>
      </span>
    </button>
    <div v-show="open" class="border-t border-slate-700/45 px-3 pb-3 pt-1">
      <slot />
    </div>
  </div>
</template>
