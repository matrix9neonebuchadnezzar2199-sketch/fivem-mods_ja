<script setup lang="ts">
import { ref, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from '../../stores/settings'
import type { BackupFile } from '../../utils/exporters'
import { buildPreview, parseBackupText, type ImportPreview } from '../../utils/exporters'
import { importBackup, type ImportResult } from '../../utils/localImport'

const props = defineProps<{ open: boolean }>()
const emit = defineEmits<{ 'update:open': [boolean] }>()

const { t } = useI18n()
const settingsStore = useSettingsStore()
const { settings } = storeToRefs(settingsStore)

type Step = 'file' | 'preview' | 'done'

const step = ref<Step>('file')
const fileErrorKey = ref<string | null>(null)
const fileErrorBadSchema = ref<number | undefined>(undefined)
const parsedFile = ref<BackupFile | null>(null)
const preview = ref<ImportPreview | null>(null)
const importResult = ref<ImportResult | null>(null)
const byLabel = ref('')
const replaceConfirmVisible = ref(false)
const fileInputRef = ref<HTMLInputElement | null>(null)

function close() {
  emit('update:open', false)
}

function resetState() {
  step.value = 'file'
  fileErrorKey.value = null
  fileErrorBadSchema.value = undefined
  parsedFile.value = null
  preview.value = null
  importResult.value = null
  replaceConfirmVisible.value = false
  if (fileInputRef.value) fileInputRef.value.value = ''
}

watch(
  () => props.open,
  (v) => {
    if (v) {
      resetState()
      settingsStore.load()
    }
  },
)

function onPickFile() {
  fileInputRef.value?.click()
}

async function onFileChange(ev: Event) {
  const input = ev.target as HTMLInputElement
  const f = input.files?.[0]
  fileErrorKey.value = null
  fileErrorBadSchema.value = undefined
  if (!f) return
  const text = await f.text()
  const r = parseBackupText(text)
  if (!r.ok) {
    fileErrorKey.value = `data.import.error_${r.reason}`
    if (r.reason === 'unsupported_schema') fileErrorBadSchema.value = r.badSchemaVersion
    return
  }
  parsedFile.value = r.file
  preview.value = buildPreview(r.file)
  step.value = 'preview'
}

function cancelPreview() {
  close()
}

function beginReplace() {
  replaceConfirmVisible.value = true
}

function abortReplaceConfirm() {
  replaceConfirmVisible.value = false
}

function runMerge() {
  if (!parsedFile.value) return
  const by = (settings.value.selfName || '').trim() || '(unset)'
  byLabel.value = by
  importResult.value = importBackup(parsedFile.value, 'merge', by)
  step.value = 'done'
}

function runReplaceConfirmed() {
  if (!parsedFile.value) return
  const by = (settings.value.selfName || '').trim() || '(unset)'
  byLabel.value = by
  importResult.value = importBackup(parsedFile.value, 'replace', by)
  step.value = 'done'
  replaceConfirmVisible.value = false
}

function doReload() {
  window.location.reload()
}
</script>

<template>
  <div
    v-if="open"
    class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm"
    role="dialog"
    aria-modal="true"
  >
    <div class="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
      <h2 class="mb-3 text-lg font-bold text-slate-50">{{ t('data.import.title') }}</h2>

      <div v-if="step === 'file'" class="space-y-3 text-sm">
        <p class="text-slate-400">{{ t('data.import.step_file') }}</p>
        <input ref="fileInputRef" type="file" accept="application/json,.json" class="hidden" @change="onFileChange" />
        <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="onPickFile">
          {{ t('data.import.pick_file') }}
        </button>
        <p v-if="fileErrorKey" class="text-sm text-red-300">{{ t(fileErrorKey, { version: fileErrorBadSchema }) }}</p>
        <div class="mt-4 flex justify-end">
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-300" @click="close">
            {{ t('data.import.cancel') }}
          </button>
        </div>
      </div>

      <div v-else-if="step === 'preview' && preview?.ok && parsedFile" class="space-y-3 text-sm">
        <p class="font-medium text-slate-200">{{ t('data.import.step_preview') }}</p>
        <ul class="list-inside list-disc space-y-1 text-slate-300">
          <li>
            {{
              t('data.import.preview_summary', {
                teams: preview.counts.teams,
                rosterMembers: preview.counts.rosterMembers,
                matches: preview.counts.matches,
              })
            }}
          </li>
          <li v-if="parsedFile.exportedAt">{{ t('data.import.exported_at') }}: {{ parsedFile.exportedAt }}</li>
          <li v-if="parsedFile.appVersion">{{ t('data.import.app_version') }}: {{ parsedFile.appVersion }}</li>
          <li>{{ t('data.import.schema_version') }}: {{ preview.schemaVersion }}</li>
        </ul>

        <div v-if="replaceConfirmVisible" class="rounded-lg border border-red-500/40 bg-red-950/40 p-3 text-xs text-red-100">
          <p class="mb-2 font-semibold">{{ t('data.import.replace_warn') }}</p>
          <div class="flex flex-wrap gap-2">
            <button
              type="button"
              class="rounded-lg bg-red-600 px-3 py-2 text-xs font-semibold text-white hover:bg-red-500"
              @click="runReplaceConfirmed"
            >
              {{ t('data.import.mode_replace_confirm') }}
            </button>
            <button type="button" class="rounded-lg border border-slate-500 px-3 py-2 text-xs text-slate-200" @click="abortReplaceConfirm">
              {{ t('data.import.replace_abort') }}
            </button>
            <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-xs text-slate-300" @click="cancelPreview">
              {{ t('data.import.cancel') }}
            </button>
          </div>
        </div>

        <div v-else class="mt-4 flex flex-wrap gap-2">
          <button
            type="button"
            class="rounded-lg border border-red-500/60 bg-red-500/15 px-3 py-2 text-sm font-semibold text-red-200 hover:bg-red-500/25"
            @click="beginReplace"
          >
            {{ t('data.import.mode_replace') }}
          </button>
          <button type="button" class="rounded-lg border border-emerald-500/50 bg-emerald-500/10 px-3 py-2 text-sm text-emerald-200" @click="runMerge">
            {{ t('data.import.mode_merge') }}
          </button>
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-300" @click="cancelPreview">
            {{ t('data.import.cancel') }}
          </button>
        </div>
      </div>

      <div v-else-if="step === 'done' && importResult" class="space-y-3 text-sm">
        <p class="font-medium text-emerald-200">
          {{ importResult.mode === 'replace' ? t('data.import.result_replace') : t('data.import.result_merge') }}
        </p>
        <p class="text-slate-300">
          {{ t('data.import.preview_summary', importResult.added) }}
        </p>
        <p class="text-slate-400">
          {{ t('data.import.by') }}: {{ byLabel }}
        </p>
        <p class="text-xs text-amber-200/90">{{ t('data.import.reload_hint') }}</p>
        <div class="mt-4 flex flex-wrap gap-2">
          <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="doReload">
            {{ t('data.import.reload') }}
          </button>
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-300" @click="close">
            {{ t('data.import.close_without_reload') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
