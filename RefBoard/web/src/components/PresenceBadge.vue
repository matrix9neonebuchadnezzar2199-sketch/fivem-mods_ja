<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { onClickOutside } from '@vueuse/core'
import { usePresenceStore } from '../stores/presence'
import UserAvatar from './UserAvatar.vue'

const { t } = useI18n()
const presence = usePresenceStore()

const pop = ref<HTMLElement | null>(null)
const open = ref(false)

onClickOutside(pop, () => {
  open.value = false
})

const visible = computed(() => presence.users.slice(0, 3))
const overflow = computed(() => Math.max(0, presence.users.length - 3))
</script>

<template>
  <div ref="pop" class="relative flex items-center gap-3 rounded-full border border-slate-700 bg-slate-800/80 px-3 py-1.5 text-sm text-slate-100 shadow-lg backdrop-blur">
    <span class="flex items-center gap-1.5">
      <span class="h-2 w-2 animate-pulse rounded-full bg-emerald-400" />
      <span class="whitespace-nowrap">{{ t('presence.online') }}</span>
    </span>
    <span class="hidden max-w-[220px] truncate text-xs text-slate-400 sm:inline">
      {{ t('presence.users_online', { count: presence.totalCount }) }}
    </span>
    <div class="flex items-center gap-1">
      <div class="flex -space-x-2">
        <UserAvatar v-for="u in visible" :key="u.serverId" :user="u" />
        <button
          v-if="overflow > 0"
          type="button"
          class="z-10 flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-slate-700 text-[10px] font-semibold text-slate-200 ring-2 ring-slate-900 hover:bg-slate-600"
          :title="t('presence.all_users')"
          @click.stop="open = !open"
        >
          +{{ overflow }}
        </button>
      </div>
    </div>

    <div
      v-if="open && presence.users.length"
      class="absolute right-0 top-full z-50 mt-2 w-64 rounded-xl border border-slate-700 bg-slate-900/95 p-2 text-xs shadow-2xl backdrop-blur"
    >
      <div class="mb-1 font-semibold text-slate-300">{{ t('presence.all_users') }}</div>
      <ul class="max-h-48 space-y-1 overflow-y-auto">
        <li v-for="u in presence.users" :key="u.serverId" class="flex items-center justify-between gap-2 rounded-lg bg-slate-800/80 px-2 py-1">
          <span class="truncate">{{ u.name }}</span>
          <span :class="u.mode === 'edit' ? 'text-emerald-400' : 'text-slate-400'">
            {{ u.mode === 'edit' ? t('presence.editing') : t('presence.viewing') }}
          </span>
        </li>
      </ul>
    </div>
  </div>
</template>
