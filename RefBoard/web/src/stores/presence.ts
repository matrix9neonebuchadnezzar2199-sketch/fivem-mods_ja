import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

export type PresenceUser = {
  serverId: number
  license: string
  name: string
  mode: 'edit' | 'view'
  since: number
}

export const usePresenceStore = defineStore('presence', () => {
  const users = ref<PresenceUser[]>([])

  const editorUser = computed(() => users.value.find((u) => u.mode === 'edit') ?? null)
  const totalCount = computed(() => users.value.length)

  function applyUpdate(payload: { users?: PresenceUser[] }) {
    if (!payload?.users) {
      return
    }
    users.value = payload.users.map((u) => ({
      serverId: Number(u.serverId),
      license: String(u.license ?? ''),
      name: String(u.name ?? ''),
      mode: u.mode === 'edit' ? 'edit' : 'view',
      since: Number(u.since ?? 0),
    }))
  }

  return { users, editorUser, totalCount, applyUpdate }
})
