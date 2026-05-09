<script setup lang="ts">
import { computed, ref, shallowRef, watch } from 'vue'
import { storeToRefs } from 'pinia'
import { useI18n } from 'vue-i18n'
import { useSettingsStore } from '../../stores/settings'
import type { BackupFile } from '../../utils/exporters'
import { buildPreview, buildPreviewDetail, parseBackupText, type ImportPreview, type ImportPreviewDetail } from '../../utils/exporters'
import {
  buildAllSelected,
  buildEmptySelection,
  importBackup,
  validateSelection,
  type ImportResult,
  type ImportSelection,
} from '../../utils/localImport'

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
const previewDetail = ref<ImportPreviewDetail | null>(null)
const importMode = ref<'replace' | 'merge'>('merge')
const selection = shallowRef<ImportSelection>(buildEmptySelection())
const importResult = ref<ImportResult | null>(null)
const byLabel = ref('')
const replaceConfirmVisible = ref(false)
const fileInputRef = ref<HTMLInputElement | null>(null)

function cloneSel(base: ImportSelection): ImportSelection {
  return {
    teamIds: new Set(base.teamIds),
    rosterMemberIds: new Set(base.rosterMemberIds),
    matchIds: new Set(base.matchIds),
    autoIncludeRelated: base.autoIncludeRelated,
  }
}

function setSelection(next: ImportSelection) {
  selection.value = cloneSel(next)
}

function close() {
  emit('update:open', false)
}

function resetState() {
  step.value = 'file'
  fileErrorKey.value = null
  fileErrorBadSchema.value = undefined
  parsedFile.value = null
  preview.value = null
  previewDetail.value = null
  importMode.value = 'merge'
  setSelection(buildEmptySelection())
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

const teamNameById = computed(() => {
  const d = previewDetail.value
  if (!d) return new Map<number, string>()
  return new Map(d.teams.map((x) => [x.id, x.name]))
})

const validation = computed(() => {
  const d = previewDetail.value
  if (!d) return { ok: true as const, errors: [] as ReturnType<typeof validateSelection>['errors'] }
  return validateSelection(d, selection.value)
})

const selectedCounts = computed(() => ({
  teams: selection.value.teamIds.size,
  rosterMembers: selection.value.rosterMemberIds.size,
  matches: selection.value.matchIds.size,
}))

const mergeConfirmDisabled = computed(() => {
  if (importMode.value !== 'merge') return false
  if (!validation.value.ok) return true
  const c = selectedCounts.value
  return c.teams + c.rosterMembers + c.matches === 0
})

const mergeConfirmLabel = computed(() =>
  t('data.import.merge_confirm_button', {
    teams: selectedCounts.value.teams,
    rosterMembers: selectedCounts.value.rosterMembers,
    matches: selectedCounts.value.matches,
  }),
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
  const detail = buildPreviewDetail(r.file)
  previewDetail.value = detail
  setSelection(buildAllSelected(detail))
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

function runMergeConfirmed() {
  if (!parsedFile.value || mergeConfirmDisabled.value) return
  const by = (settings.value.selfName || '').trim() || '(unset)'
  byLabel.value = by
  importResult.value = importBackup(parsedFile.value, 'merge', by, selection.value)
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

function selectAllTeams() {
  const d = previewDetail.value
  if (!d) return
  const s = cloneSel(selection.value)
  for (const t of d.teams) s.teamIds.add(t.id)
  setSelection(s)
}

function selectNoTeams() {
  const d = previewDetail.value
  if (!d) return
  const s = cloneSel(selection.value)
  for (const t of d.teams) s.teamIds.delete(t.id)
  setSelection(s)
}

function selectAllRosters() {
  const d = previewDetail.value
  if (!d) return
  const s = cloneSel(selection.value)
  for (const r of d.rosterMembers) {
    if (s.teamIds.has(r.teamId)) s.rosterMemberIds.add(r.id)
  }
  setSelection(s)
}

function selectNoRosters() {
  const d = previewDetail.value
  if (!d) return
  const s = cloneSel(selection.value)
  for (const r of d.rosterMembers) s.rosterMemberIds.delete(r.id)
  setSelection(s)
}

function selectAllMatches() {
  const d = previewDetail.value
  if (!d) return
  const s = cloneSel(selection.value)
  for (const m of d.matches) {
    applyMatchWithState(s, m.id, true)
  }
  setSelection(s)
}

function applyMatchWithState(s: ImportSelection, matchId: number, checked: boolean) {
  const d = previewDetail.value
  if (!d) return
  if (checked) {
    s.matchIds.add(matchId)
    if (s.autoIncludeRelated) {
      const m = d.matches.find((x) => x.id === matchId)
      if (m) {
        s.teamIds.add(m.homeTeamId)
        s.teamIds.add(m.awayTeamId)
        for (const rid of m.playerRosterIds) s.rosterMemberIds.add(rid)
      }
    }
  } else {
    s.matchIds.delete(matchId)
  }
}

function selectNoMatches() {
  const d = previewDetail.value
  if (!d) return
  const s = cloneSel(selection.value)
  s.matchIds.clear()
  setSelection(s)
}

function toggleTeam(id: number, checked: boolean) {
  const s = cloneSel(selection.value)
  if (checked) s.teamIds.add(id)
  else s.teamIds.delete(id)
  setSelection(s)
}

function toggleRoster(id: number, checked: boolean) {
  const s = cloneSel(selection.value)
  if (checked) s.rosterMemberIds.add(id)
  else s.rosterMemberIds.delete(id)
  setSelection(s)
}

function toggleMatchRow(id: number, checked: boolean) {
  const d = previewDetail.value
  if (!d) return
  const s = cloneSel(selection.value)
  applyMatchWithState(s, id, checked)
  setSelection(s)
}

function toggleAutoInclude(v: boolean) {
  const s = cloneSel(selection.value)
  s.autoIncludeRelated = v
  setSelection(s)
  if (v) {
    const d = previewDetail.value
    if (!d) return
    for (const mid of s.matchIds) {
      const m = d.matches.find((x) => x.id === mid)
      if (!m) continue
      s.teamIds.add(m.homeTeamId)
      s.teamIds.add(m.awayTeamId)
      for (const rid of m.playerRosterIds) s.rosterMemberIds.add(rid)
    }
    setSelection(s)
  }
}

function rosterRowDimmed(teamId: number): boolean {
  return !selection.value.teamIds.has(teamId)
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
    <div class="max-h-[90vh] w-full max-w-2xl overflow-y-auto rounded-xl border border-slate-700 bg-slate-900 p-5 shadow-2xl">
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

      <div v-else-if="step === 'preview' && preview?.ok && parsedFile && previewDetail" class="space-y-4 text-sm">
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

        <fieldset class="space-y-2 rounded-lg border border-slate-700 p-3">
          <legend class="px-1 text-xs font-medium text-slate-400">{{ t('data.import.mode_legend') }}</legend>
          <label class="flex cursor-pointer items-center gap-2 text-slate-200">
            <input v-model="importMode" type="radio" value="merge" class="text-primary" />
            {{ t('data.import.mode_merge') }}
          </label>
          <label class="flex cursor-pointer items-center gap-2 text-slate-200">
            <input v-model="importMode" type="radio" value="replace" class="text-red-400" />
            {{ t('data.import.mode_replace') }}
          </label>
        </fieldset>

        <div v-if="importMode === 'merge'" class="space-y-4 rounded-lg border border-slate-700/80 bg-slate-950/40 p-3">
          <section class="space-y-2">
            <div class="flex flex-wrap items-center justify-between gap-2">
              <h3 class="text-xs font-semibold uppercase tracking-wide text-slate-400">{{ t('data.import.select_section_teams') }}</h3>
              <div class="flex gap-2">
                <button type="button" class="text-xs text-primary hover:underline" @click="selectAllTeams">{{ t('data.import.select_all') }}</button>
                <button type="button" class="text-xs text-slate-500 hover:underline" @click="selectNoTeams">{{ t('data.import.select_none') }}</button>
              </div>
            </div>
            <p class="text-xs text-slate-500">
              {{ t('data.import.selected_of_total', { selected: selectedCounts.teams, total: previewDetail.teams.length }) }}
            </p>
            <ul class="max-h-36 space-y-1 overflow-y-auto rounded border border-slate-800 p-2">
              <li v-for="team in previewDetail.teams" :key="team.id" class="flex items-center gap-2 text-slate-200">
                <input
                  type="checkbox"
                  class="rounded border-slate-600"
                  :checked="selection.teamIds.has(team.id)"
                  @change="toggleTeam(team.id, ($event.target as HTMLInputElement).checked)"
                />
                <span>{{ team.name }} <span v-if="team.shortName" class="text-slate-500">({{ team.shortName }})</span></span>
              </li>
            </ul>
          </section>

          <section class="space-y-2">
            <div class="flex flex-wrap items-center justify-between gap-2">
              <h3 class="text-xs font-semibold uppercase tracking-wide text-slate-400">{{ t('data.import.select_section_rosters') }}</h3>
              <div class="flex gap-2">
                <button type="button" class="text-xs text-primary hover:underline" @click="selectAllRosters">{{ t('data.import.select_all') }}</button>
                <button type="button" class="text-xs text-slate-500 hover:underline" @click="selectNoRosters">{{ t('data.import.select_none') }}</button>
              </div>
            </div>
            <p class="text-xs text-slate-500">
              {{ t('data.import.selected_of_total', { selected: selectedCounts.rosterMembers, total: previewDetail.rosterMembers.length }) }}
            </p>
            <ul class="max-h-36 space-y-1 overflow-y-auto rounded border border-slate-800 p-2">
              <li
                v-for="r in previewDetail.rosterMembers"
                :key="r.id"
                class="flex items-center gap-2"
                :class="rosterRowDimmed(r.teamId) ? 'text-slate-600' : 'text-slate-200'"
              >
                <input
                  type="checkbox"
                  class="rounded border-slate-600"
                  :disabled="rosterRowDimmed(r.teamId)"
                  :checked="selection.rosterMemberIds.has(r.id)"
                  @change="toggleRoster(r.id, ($event.target as HTMLInputElement).checked)"
                />
                <span
                  >{{ r.name }}
                  <span class="text-slate-500">#{{ r.number ?? '—' }} · {{ teamNameById.get(r.teamId) ?? r.teamId }}</span></span
                >
              </li>
            </ul>
          </section>

          <section class="space-y-2">
            <label class="flex cursor-pointer items-start gap-2 text-xs text-slate-300">
              <input
                type="checkbox"
                class="mt-0.5 rounded border-slate-600"
                :checked="selection.autoIncludeRelated"
                @change="toggleAutoInclude(($event.target as HTMLInputElement).checked)"
              />
              <span>{{ t('data.import.auto_include_related') }}</span>
            </label>
            <div class="flex flex-wrap items-center justify-between gap-2">
              <h3 class="text-xs font-semibold uppercase tracking-wide text-slate-400">{{ t('data.import.select_section_matches') }}</h3>
              <div class="flex gap-2">
                <button type="button" class="text-xs text-primary hover:underline" @click="selectAllMatches">{{ t('data.import.select_all') }}</button>
                <button type="button" class="text-xs text-slate-500 hover:underline" @click="selectNoMatches">{{ t('data.import.select_none') }}</button>
              </div>
            </div>
            <p class="text-xs text-slate-500">
              {{ t('data.import.selected_of_total', { selected: selectedCounts.matches, total: previewDetail.matches.length }) }}
            </p>
            <ul class="max-h-40 space-y-2 overflow-y-auto rounded border border-slate-800 p-2">
              <li v-for="m in previewDetail.matches" :key="m.id" class="flex items-start gap-2 text-slate-200">
                <input
                  type="checkbox"
                  class="mt-1 rounded border-slate-600"
                  :checked="selection.matchIds.has(m.id)"
                  @change="toggleMatchRow(m.id, ($event.target as HTMLInputElement).checked)"
                />
                <div class="min-w-0 flex-1">
                  <div class="font-medium">{{ m.title }}</div>
                  <div class="text-xs text-slate-400">{{ m.homeName }} vs {{ m.awayName }} · {{ m.status }}</div>
                  <div v-if="m.scheduledAt" class="text-xs text-slate-500">{{ m.scheduledAt.slice(0, 10) }}</div>
                </div>
              </li>
            </ul>
          </section>
        </div>

        <div v-if="importMode === 'merge' && validation.errors.length" class="rounded-lg border border-amber-600/40 bg-amber-950/30 p-3 text-xs text-amber-100">
          <p v-for="(err, idx) in validation.errors" :key="idx" class="mb-1 last:mb-0">
            <template v-if="err.kind === 'match_missing_team'">
              {{ t('data.import.validation_match_missing_team', { title: err.matchTitle, missingTeamId: err.missingTeamId }) }}
            </template>
            <template v-else>
              {{ t('data.import.validation_match_missing_roster', { title: err.matchTitle, missingRosterMemberId: err.missingRosterMemberId }) }}
            </template>
          </p>
        </div>

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
          <template v-if="importMode === 'replace'">
            <button
              type="button"
              class="rounded-lg border border-red-500/60 bg-red-500/15 px-3 py-2 text-sm font-semibold text-red-200 hover:bg-red-500/25"
              @click="beginReplace"
            >
              {{ t('data.import.mode_replace') }}
            </button>
          </template>
          <template v-else>
            <button
              type="button"
              class="rounded-lg border border-emerald-500/50 bg-emerald-500/10 px-3 py-2 text-sm font-semibold text-emerald-100 disabled:opacity-40"
              :disabled="mergeConfirmDisabled"
              @click="runMergeConfirmed"
            >
              {{ mergeConfirmLabel }}
            </button>
          </template>
          <button type="button" class="rounded-lg border border-slate-600 px-3 py-2 text-sm text-slate-300" @click="cancelPreview">
            {{ t('data.import.cancel') }}
          </button>
        </div>
      </div>

      <div v-else-if="step === 'done' && importResult" class="space-y-3 text-sm">
        <p class="font-medium text-emerald-200">
          <template v-if="importResult.mode === 'replace'">{{ t('data.import.result_replace') }}</template>
          <template v-else-if="importResult.partial">{{ t('data.import.result_merge_partial') }}</template>
          <template v-else>{{ t('data.import.result_merge') }}</template>
        </p>
        <p class="text-slate-300">
          {{ t('data.import.preview_summary', importResult.counts) }}
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
