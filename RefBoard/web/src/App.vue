<script setup lang="ts">
import { onMounted } from 'vue'
import { useSessionStore } from './stores/session'
import { usePresenceStore, type PresenceUser } from './stores/presence'
import { useAutosaveStore } from './stores/autosave'
import { useNui } from './composables/useNui'

const session = useSessionStore()
const presence = usePresenceStore()
const autosave = useAutosaveStore()
const { on } = useNui()

onMounted(() => {
  session.bindServerMessages()
  on('refboard:presence:update', (p) => {
    presence.applyUpdate(p as { users?: PresenceUser[] })
  })
  on('refboard:presence:list:ack', (p) => {
    presence.applyUpdate(p as { users?: PresenceUser[] })
  })
  on('refboard:autosave:saved', (p: { savedAt?: number; error?: string }) => {
    if (p?.error) {
      autosave.markError()
    } else if (p?.savedAt) {
      autosave.markSaved(p.savedAt)
    }
  })
})
</script>

<template>
  <router-view />
</template>
