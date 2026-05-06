import { defineStore } from 'pinia'
import { ref } from 'vue'

/**
 * 試合詳細の「小窓モード」中のみ true。
 * シェル（MainLayout）と App 背景を透過し、背面のゲームを見ながら操作できるようにする。
 */
export const useMatchCompactDockStore = defineStore('matchCompactDock', () => {
  const transparentChrome = ref(false)

  function setTransparentChrome(v: boolean) {
    transparentChrome.value = v
  }

  return { transparentChrome, setTransparentChrome }
})
