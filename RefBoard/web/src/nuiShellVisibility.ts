import { ref } from 'vue'

/** Lua の refboard:setOpen と同期。false のときは NUI を描画しない（ログイン画面等の背後を覆わない） */
export const nuiShellOpenRef = ref(false)

export function setNuiShellOpenFromLua(open: boolean): void {
  nuiShellOpenRef.value = open
}
