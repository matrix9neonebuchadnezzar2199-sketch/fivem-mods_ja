// SPDX-License-Identifier: LGPL-3.0-or-later

import { useEffect } from 'react'
import { useBuilderStore } from './store/builderStore'
import { fetchNui, onNuiMessage } from './lib/nui'
import { Builder } from './pages/Builder'
import { BASE_FONT_PX, uiScale } from './theme'

type ReadyPayload = {
  ok?: boolean
  open?: boolean
  scene?: string
  mode?: string
  selected?: number | null
}

export default function App() {
  const open = useBuilderStore((s) => s.open)
  const setOpen = useBuilderStore((s) => s.setOpen)
  const setSceneId = useBuilderStore((s) => s.setSceneId)
  const setMode = useBuilderStore((s) => s.setMode)
  const setSelected = useBuilderStore((s) => s.setSelected)

  useEffect(() => {
    document.documentElement.style.fontSize = `${BASE_FONT_PX * uiScale}px`
  }, [])

  useEffect(() => {
    const unsub = onNuiMessage<{ open?: boolean }>((msg) => {
      if (msg?.action === 'setOpen' && typeof msg.open === 'boolean') {
        setOpen(msg.open)
      }
    })
    return unsub
  }, [setOpen])

  useEffect(() => {
    void (async () => {
      const d = await fetchNui<ReadyPayload>('ready')
      if (d?.scene) {
        setSceneId(d.scene)
      }
      if (d?.mode === 'furniture' || d?.mode === 'door' || d?.mode === 'parking' || d?.mode === 'stash') {
        setMode(d.mode)
      }
      if (d?.selected !== undefined) {
        setSelected(d.selected ?? null)
      }
      if (typeof d?.open === 'boolean') {
        setOpen(d.open)
      }
    })()
  }, [setOpen, setSceneId, setMode, setSelected])

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && useBuilderStore.getState().open) {
        e.preventDefault()
        void fetchNui('close')
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  if (!open) {
    return null
  }

  return <Builder />
}
