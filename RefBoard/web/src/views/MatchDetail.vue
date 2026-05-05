<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

defineProps<{
  id?: string
}>()
import { useSessionStore } from '../stores/session'
import { useAutosaveStore } from '../stores/autosave'
import { useNui } from '../composables/useNui'
import { useHeartbeat } from '../composables/useHeartbeat'
import { mockMatchDetail } from '../mocks/matchDetail'
import type { MatchDetailModel } from '../types/match'
import BasicInfoCard from '../components/match/BasicInfoCard.vue'
import ScoreBoardCard from '../components/match/ScoreBoardCard.vue'
import MatchStatusCard from '../components/match/MatchStatusCard.vue'
import PlayerListCard from '../components/match/PlayerListCard.vue'
import EventTimelineCard from '../components/match/EventTimelineCard.vue'
import AutosaveIndicator from '../components/AutosaveIndicator.vue'

const route = useRoute()
const router = useRouter()
const session = useSessionStore()
const autosave = useAutosaveStore()
const { send } = useNui()

const readonly = computed(() => !session.isEditor)

const detail = reactive<MatchDetailModel>(JSON.parse(JSON.stringify(mockMatchDetail)) as MatchDetailModel)

watch(
  () => route.params.id,
  (id) => {
    const n = Number(id)
    if (n) {
      detail.id = n
    }
  },
  { immediate: true },
)

useHeartbeat()

let deb: ReturnType<typeof setTimeout> | null = null
watch(
  () => detail,
  () => {
    if (readonly.value) {
      return
    }
    if (deb) {
      clearTimeout(deb)
    }
    deb = setTimeout(() => {
      deb = null
      autosave.markSaving()
      void send('autosave_draft', { matchId: detail.id, state: detail })
    }, 600)
  },
  { deep: true },
)

async function toViewMode() {
  await session.downgradeToView()
}

async function onCancel() {
  await send('lock_release', {})
  await router.push({ name: 'matches' })
}

async function onSave() {
  await send('lock_release', {})
  await router.push({ name: 'matches' })
}
</script>

<template>
  <div class="flex h-full min-h-0 flex-col overflow-hidden bg-bg">
    <div
      class="relative shrink-0 border-b border-slate-700 bg-gradient-to-b from-slate-900 via-slate-900/95 to-slate-950 px-6 py-10 text-center"
    >
      <div class="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top,rgba(59,130,246,0.15),transparent_55%)]" />
      <div class="relative mx-auto flex max-w-xl flex-col items-center gap-3">
        <div class="flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/20 text-4xl shadow-lg">⚽</div>
        <div class="text-2xl font-bold tracking-tight text-slate-50">サッカー試合管理ツール</div>
        <div class="text-sm text-slate-400">RefBoard — スタジアムモード</div>
      </div>
    </div>

    <div class="min-h-0 flex-1 overflow-y-auto px-4 py-4">
      <header class="mb-4 flex flex-wrap items-center gap-3 border-b border-slate-700/80 pb-3">
        <div class="flex flex-1 flex-wrap items-center gap-2 text-sm text-slate-200">
          <span class="font-semibold">試合詳細の編集</span>
          <span v-if="session.isEditor" class="rounded bg-emerald-500/20 px-2 py-0.5 text-xs font-medium text-emerald-300">[編集中]</span>
          <span v-else class="rounded bg-amber-500/20 px-2 py-0.5 text-xs font-medium text-amber-300">[閲覧モード]</span>
        </div>
        <div class="flex flex-1 justify-center">
          <AutosaveIndicator />
        </div>
        <div class="flex flex-1 flex-wrap items-center justify-end gap-2">
          <button
            type="button"
            class="rounded-lg border border-amber-500/40 bg-amber-500/10 px-3 py-1.5 text-xs font-semibold text-amber-300 hover:bg-amber-500/20"
            @click="toViewMode"
          >
            [閲覧モード]
          </button>
          <button type="button" class="rounded-lg border border-slate-600 bg-slate-800 px-3 py-1.5 text-xs text-slate-200" @click="onCancel">
            [キャンセル]
          </button>
          <button type="button" class="rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-white hover:brightness-110" @click="onSave">
            [保存する]
          </button>
        </div>
      </header>

      <div class="mb-4 grid grid-cols-1 gap-4 lg:grid-cols-[30%_40%_30%]">
        <BasicInfoCard :model="detail" :readonly="readonly" />
        <ScoreBoardCard :model="detail" :readonly="readonly" />
        <MatchStatusCard :model="detail" :readonly="readonly" />
      </div>

      <div class="grid grid-cols-1 gap-4 lg:grid-cols-[65%_35%]">
        <div class="grid grid-cols-1 gap-4 xl:grid-cols-2">
          <PlayerListCard title="Los Santos FC — 選手" :players="detail.homePlayers" :readonly="readonly" />
          <PlayerListCard title="Vinewood United — 選手" :players="detail.awayPlayers" :readonly="readonly" />
        </div>
        <EventTimelineCard :events="detail.events" :readonly="readonly" />
      </div>
    </div>
  </div>
</template>
