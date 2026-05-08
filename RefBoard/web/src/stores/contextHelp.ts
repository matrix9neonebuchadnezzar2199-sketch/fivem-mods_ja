import { defineStore } from 'pinia'
import { ref } from 'vue'

/**
 * コンテキストヘルプパネルの開閉状態を管理する小さな store。
 * 各画面の `HelpTriggerButton` が `open(contextId)` を呼ぶと、
 * `ContextHelpPanel` が `MainLayout` でグローバルに描画されているので即座に開く。
 */
export const useContextHelpStore = defineStore('contextHelp', () => {
  const isOpen = ref(false)
  const contextId = ref<string | null>(null)

  function open(id: string) {
    contextId.value = id
    isOpen.value = true
  }

  function close() {
    isOpen.value = false
    // contextId は次回開く時まで残しても害はないので保持。
  }

  return { isOpen, contextId, open, close }
})
