<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { useMatchesStore } from '../stores/matches'
import { useSettingsStore } from '../stores/settings'
import { downloadFile, exportFullBackup, refboardFilename, toCSV } from '../utils/exporters'
import { loadImportHistory, type ImportRecord } from '../utils/localImport'
import MarqueeText from '../components/common/MarqueeText.vue'
import HelpTriggerButton from '../components/help/HelpTriggerButton.vue'
import ImportBackupDialog from '../components/data/ImportBackupDialog.vue'
import { formatDateJa } from '../utils/formatDate'

const { t } = useI18n()
const router = useRouter()
const matchesStore = useMatchesStore()
const settingsStore = useSettingsStore()

const finished = computed(() => matchesStore.matches.filter((m) => m.status === 'finished'))

const importDialogOpen = ref(false)
const importHistory = ref<ImportRecord[]>([])

function refreshImportHistory() {
  importHistory.value = loadImportHistory()
}

function onImportDialogOpen(v: boolean) {
  importDialogOpen.value = v
  if (!v) refreshImportHistory()
}

onMounted(() => {
  settingsStore.load()
  refreshImportHistory()
})

function openMatch(id: number) {
  void router.push({ name: 'match-detail', params: { id: String(id) } })
}

function exportFinishedCsv() {
  const cols = ['id', 'title', 'homeName', 'awayName', 'homeScore', 'awayScore', 'finishedAt']
  const rows = finished.value.map((m) => ({
    id: m.id,
    title: m.title,
    homeName: m.homeName,
    awayName: m.awayName,
    homeScore: m.homeScore,
    awayScore: m.awayScore,
    finishedAt: m.finishedAt ?? '',
  }))
  downloadFile(toCSV(rows, cols), refboardFilename('refboard_finished_matches', 'csv'), 'text/csv;charset=utf-8')
}

function fullBackup() {
  exportFullBackup()
}

function rowModeLabel(mode: ImportRecord['mode']) {
  return mode === 'replace' ? t('data.import_history.mode_replace') : t('data.import_history.mode_merge')
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col gap-4 overflow-y-auto p-4">
    <div class="flex flex-wrap items-center justify-between gap-2">
      <h2 class="text-lg font-semibold text-slate-50">{{ t('data.title') }}</h2>
      <HelpTriggerButton context-id="data_manage" />
    </div>

    <section class="rounded-lg border border-slate-700 bg-slate-900/70 p-4">
      <h3 class="mb-2 text-sm font-semibold text-slate-200">{{ t('data.finished_section') }}</h3>
      <p class="mb-3 text-xs text-slate-500">{{ t('data.finished_hint') }}</p>
      <div class="mb-3 flex flex-wrap gap-2">
        <button
          type="button"
          class="rounded-lg border border-slate-600 bg-slate-800 px-3 py-2 text-sm text-slate-200"
          :disabled="!finished.length"
          @click="exportFinishedCsv"
        >
          {{ t('data.export_finished_csv') }}
        </button>
        <button type="button" class="rounded-lg bg-primary px-3 py-2 text-sm font-semibold text-white" @click="fullBackup">
          {{ t('data.full_backup') }}
        </button>
        <button
          type="button"
          class="rounded-lg border border-slate-500 bg-slate-800 px-3 py-2 text-sm text-slate-100 hover:bg-slate-800/90"
          @click="importDialogOpen = true"
        >
          {{ t('data.import.open') }}
        </button>
      </div>
      <div class="overflow-x-auto rounded border border-slate-700">
        <table class="w-full min-w-[640px] text-left text-sm">
          <thead class="bg-slate-900/95 text-xs uppercase text-slate-500">
            <tr>
              <th class="px-3 py-2">{{ t('match_list.col_date') }}</th>
              <th class="px-3 py-2">{{ t('match_list.col_match_name') }}</th>
              <th class="px-3 py-2">{{ t('match_list.col_teams') }}</th>
              <th class="px-3 py-2">{{ t('match_list.col_score') }}</th>
              <th class="px-3 py-2">{{ t('match_list.col_actions') }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in finished" :key="m.id" class="border-t border-slate-800">
              <td class="px-3 py-2 text-slate-300">{{ formatDateJa((m.finishedAt || m.updatedAt).slice(0, 10)) }}</td>
              <td class="px-3 py-2 text-slate-100">
                <MarqueeText :text="m.title" variant="default" />
              </td>
              <td class="px-3 py-2 text-slate-200">{{ m.homeName }} vs {{ m.awayName }}</td>
              <td class="px-3 py-2 font-mono">{{ m.homeScore }} - {{ m.awayScore }}</td>
              <td class="px-3 py-2">
                <button type="button" class="text-primary hover:underline" @click="openMatch(m.id)">{{ t('match_list.detail') }}</button>
              </td>
            </tr>
            <tr v-if="!finished.length">
              <td colspan="5" class="px-3 py-6 text-center text-slate-500">{{ t('data.no_finished') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <section class="rounded-lg border border-slate-700 bg-slate-900/70 p-4">
      <h3 class="mb-2 text-sm font-semibold text-slate-200">{{ t('data.import_history.title') }}</h3>
      <p v-if="!importHistory.length" class="text-sm text-slate-500">{{ t('data.import_history.empty') }}</p>
      <ul v-else class="space-y-2 text-xs text-slate-300">
        <li v-for="r in importHistory" :key="r.at + r.mode + r.by" class="rounded border border-slate-800 bg-slate-950/50 px-3 py-2">
          {{
            t('data.import_history.row', {
              at: r.at,
              by: r.by,
              mode: rowModeLabel(r.mode),
              teams: r.counts.teams,
              rosterMembers: r.counts.rosterMembers,
              matches: r.counts.matches,
            })
          }}
        </li>
      </ul>
    </section>

    <ImportBackupDialog :open="importDialogOpen" @update:open="onImportDialogOpen" />
  </div>
</template>
