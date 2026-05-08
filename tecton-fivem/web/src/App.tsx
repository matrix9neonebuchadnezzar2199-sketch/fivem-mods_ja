// SPDX-License-Identifier: LGPL-3.0-or-later

import { useEffect } from 'react'
import { useBuilderStore } from './store/builderStore'
import { usePropsStore } from './store/propsStore'
import { fetchNui, onNuiMessage } from './lib/nui'
import { Builder } from './pages/Builder'
import { BASE_FONT_PX, uiScale } from './theme'
import type { PropDef, ServerCategoryRaw } from './store/propsStore'

type ReadyPayload = {
  ok?: boolean
  open?: boolean
  scene?: string
  mode?: string
  selected?: number | null
  propsLoaded?: boolean
  propsCount?: number
  propsError?: boolean
}

export default function App() {
  const open = useBuilderStore((s) => s.open)
  const setOpen = useBuilderStore((s) => s.setOpen)
  const setSceneId = useBuilderStore((s) => s.setSceneId)
  const setMode = useBuilderStore((s) => s.setMode)
  const setSelected = useBuilderStore((s) => s.setSelected)
  const setProps = usePropsStore((s) => s.setProps)
  const setLoadFailed = usePropsStore((s) => s.setLoadFailed)

  useEffect(() => {
    document.documentElement.style.fontSize = `${BASE_FONT_PX * uiScale}px`
  }, [])

  useEffect(() => {
    const unsub = onNuiMessage<{
      open?: boolean
      action?: string
      dictionary?: Record<string, PropDef>
      categories?: ServerCategoryRaw[]
      count?: number
    }>((msg) => {
      if (msg?.action === 'setOpen' && typeof msg.open === 'boolean') {
        setOpen(msg.open)
      }
      if (msg?.action === 'setProps' && msg.dictionary && msg.categories) {
        setProps(msg.dictionary, msg.categories)
      }
      if (msg?.action === 'propsLoadFailed') {
        setLoadFailed()
      }
    })
    return unsub
  }, [setOpen, setProps, setLoadFailed])

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
      if (d?.propsError) {
        setLoadFailed()
      }
    })()
  }, [setOpen, setSceneId, setMode, setSelected, setLoadFailed])

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
