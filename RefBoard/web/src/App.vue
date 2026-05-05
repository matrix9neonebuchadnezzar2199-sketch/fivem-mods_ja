<script setup lang="ts">
import { onMounted } from 'vue'
import { useSessionStore } from './stores/session'

const session = useSessionStore()

onMounted(() => {
  session.bindServerMessages()
})
</script>

<template>
  <router-view />
</template>
