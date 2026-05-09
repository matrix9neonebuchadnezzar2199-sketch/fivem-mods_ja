import { computed, type ComputedRef } from 'vue'
import { storeToRefs } from 'pinia'
import { useMatchCompactDockStore } from '../stores/matchCompactDock'

/**
 * コンパクト小窓（transparentChrome）時はモーダル背後を透過し、ゲーム画面が見えるようにする。
 * Teleport で body 直下に出るオーバーレイは App.vue の背景設定の外にあるため、ここで背景色を切り替える。
 */
export function useDialogOverlay() {
  const { transparentChrome } = storeToRefs(useMatchCompactDockStore())

  /** 標準: flex 中央、padding p-4 */
  function overlayRootClass(zIndexClass: string, whenNormalTailwind: string): ComputedRef<string> {
    return computed(() =>
      transparentChrome.value
        ? `fixed inset-0 ${zIndexClass} flex items-center justify-center bg-transparent p-4 pointer-events-auto`
        : `fixed inset-0 ${zIndexClass} flex items-center justify-center p-4 pointer-events-auto ${whenNormalTailwind}`,
    )
  }

  /** PK 勝者表示など flex-col */
  function overlayRootClassFlexCol(zIndexClass: string, whenNormalTailwind: string): ComputedRef<string> {
    return computed(() =>
      transparentChrome.value
        ? `fixed inset-0 ${zIndexClass} flex flex-col items-center justify-center bg-transparent p-6 text-center pointer-events-auto`
        : `fixed inset-0 ${zIndexClass} flex flex-col items-center justify-center p-6 text-center pointer-events-auto ${whenNormalTailwind}`,
    )
  }

  /** ヘルプパネル背後の全画面スクリム（flex なし） */
  function overlayScrimClass(zIndexClass: string, whenNormalTailwind: string): ComputedRef<string> {
    return computed(() =>
      transparentChrome.value
        ? `fixed inset-0 ${zIndexClass} bg-transparent pointer-events-auto`
        : `fixed inset-0 ${zIndexClass} pointer-events-auto ${whenNormalTailwind}`,
    )
  }

  /** ゴールウィザード内の二重オーバーレイ（absolute） */
  function overlayInnerClass(zIndexClass: string, whenNormalTailwind: string): ComputedRef<string> {
    return computed(() =>
      transparentChrome.value
        ? `absolute inset-0 ${zIndexClass} flex items-center justify-center bg-transparent p-4 pointer-events-auto`
        : `absolute inset-0 ${zIndexClass} flex items-center justify-center p-4 pointer-events-auto ${whenNormalTailwind}`,
    )
  }

  return { transparentChrome, overlayRootClass, overlayRootClassFlexCol, overlayScrimClass, overlayInnerClass }
}
