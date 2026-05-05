import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

export type MatchDto = {
  id: number
  team1_score: number
  team2_score: number
  status: string
} | null

export const useMatchStore = defineStore('match', () => {
  const current = ref<MatchDto>(null)
  const clockMs = ref(0)

  const team1Score = computed(() => current.value?.team1_score ?? 0)
  const team2Score = computed(() => current.value?.team2_score ?? 0)

  function applyServerState(payload: { match?: MatchDto }) {
    if (payload?.match) {
      current.value = payload.match
    }
  }

  return {
    current,
    clockMs,
    team1Score,
    team2Score,
    applyServerState,
  }
})
