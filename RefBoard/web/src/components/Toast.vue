<script setup lang="ts">
import { useToast } from '../composables/useToast'

const { items } = useToast()
</script>

<template>
  <div class="pointer-events-none fixed bottom-4 right-4 z-[500] flex flex-col gap-2">
    <div
      v-for="t in items"
      :key="t.id"
      class="pointer-events-auto max-w-sm rounded-lg border px-3 py-2 text-sm shadow-lg"
      :class="
        t.type === 'error'
          ? 'border-red-500/50 bg-red-950/90 text-red-100'
          : t.type === 'success'
            ? 'border-emerald-500/50 bg-emerald-950/90 text-emerald-100'
            : 'border-slate-600 bg-slate-900/95 text-slate-100'
      "
    >
      {{ t.message }}
    </div>
  </div>
</template>
