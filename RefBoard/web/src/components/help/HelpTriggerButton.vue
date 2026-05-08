<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import { useContextHelpStore } from '../../stores/contextHelp'

const props = defineProps<{
  /** context_map.json のキー */
  contextId: string
}>()

const { t } = useI18n()
const store = useContextHelpStore()

function onClick() {
  store.open(props.contextId)
}
</script>

<template>
  <button
    type="button"
    class="inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-full border border-slate-600 bg-slate-800/80 text-slate-200 hover:border-primary hover:text-primary focus:outline-none focus:ring-2 focus:ring-primary"
    :aria-label="t('help.context.open_aria')"
    :title="t('help.context.open_title')"
    @click="onClick"
  >
    <span aria-hidden="true" class="text-sm font-bold">?</span>
  </button>
</template>
