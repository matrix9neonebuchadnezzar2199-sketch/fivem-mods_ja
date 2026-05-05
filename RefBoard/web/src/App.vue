<script setup lang="ts">
import { onMounted } from 'vue'
import { useSessionStore } from './stores/session'
import { usePresenceStore, type PresenceUser } from './stores/presence'
import { useNui } from './composables/useNui'

const session = useSessionStore()
const presence = usePresenceStore()
const { on } = useNui()

onMounted(() => {
  session.bindServerMessages()
  on('refboard:presence:update', (p) => {
    presence.applyUpdate(p as { users?: PresenceUser[] })
  })
  on('refboard:presence:list:ack', (p) => {
    presence.applyUpdate(p as { users?: PresenceUser[] })
  })
})
</script>

<template>
  <router-view />
</template>
