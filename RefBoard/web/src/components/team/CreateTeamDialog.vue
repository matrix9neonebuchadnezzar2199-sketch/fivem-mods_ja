<script setup lang="ts">
import { reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToast } from '../../composables/useToast'
import { useTeamsStore } from '../../stores/teams'

const props = defineProps<{ open: boolean }>()
const emit = defineEmits<{ 'update:open': [boolean]; created: [number] }>()

const { t } = useI18n()
const { push: toastPush } = useToast()
const teamsStore = useTeamsStore()

const form = reactive({
  name: '',
  shortName: '',
  color: '#3b82f6',
  emblemEmoji: '⚽',
})

watch(
  () => props.open,
  (v) => {
    if (v) {
      form.name = ''
      form.shortName = ''
      form.color = '#3b82f6'
      form.emblemEmoji = '⚽'
    }
  },
)

function close() {
  emit('update:open', false)
}

function submit() {
  if (!form.name.trim()) {
    toastPush(t('team_manage.create_error_name'), 'error')
    return
  }
  const created = teamsStore.createTeam({
    name: form.name.trim(),
    shortName: form.shortName.trim() || undefined,
    colorHex: form.color || undefined,
  })
  emit('created', created.id)
  close()
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[200] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
  >
    <div class="w-full max-w-md rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('team_manage.create_title') }}</h2>
      <div class="space-y-2 text-sm">
        <label class="block text-slate-400">
          {{ t('team.name') }}*
          <input v-model="form.name" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
        <label class="block text-slate-400">
          {{ t('team.short_name') }}
          <input v-model="form.shortName" class="mt-1 w-full rounded border border-slate-600 bg-slate-950 px-2 py-2 text-slate-100" />
        </label>
        <label class="block text-slate-400">
          {{ t('team.color') }}
          <input v-model="form.color" type="color" class="mt-1 h-10 w-full rounded border border-slate-600 bg-slate-950" />
        </label>
      </div>
      <div class="mt-5 flex justify-end gap-2">
        <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm" @click="close">{{ t('dialog.no') }}</button>
        <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="submit">
          {{ t('dialog.yes') }}
        </button>
      </div>
    </div>
  </div>
</template>
