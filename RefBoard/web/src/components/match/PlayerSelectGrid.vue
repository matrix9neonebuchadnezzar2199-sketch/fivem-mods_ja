<script setup lang="ts">
import type { MatchPlayer } from '../../types/match'

defineProps<{
  players: MatchPlayer[]
  modelValue: string | null
}>()

const emit = defineEmits<{ 'update:modelValue': [string | null] }>()

function pick(id: string) {
  emit('update:modelValue', id)
}
</script>

<template>
  <div class="grid max-h-64 grid-cols-2 gap-2 overflow-y-auto sm:grid-cols-3">
    <button
      v-for="p in players"
      :key="p.id"
      type="button"
      class="rounded-lg border px-3 py-2 text-left text-sm transition"
      :class="
        modelValue === p.id
          ? 'border-primary bg-primary/20 text-slate-50'
          : 'border-slate-600 bg-slate-900/80 text-slate-200 hover:border-slate-500'
      "
      @click="pick(p.id)"
    >
      <span class="font-mono text-primary">{{ p.number }}</span>
      <span class="ml-2">{{ p.name }}</span>
    </button>
  </div>
</template>
