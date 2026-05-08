// SPDX-License-Identifier: LGPL-3.0-or-later

export const ja = {
  app: {
    title: 'TECTON',
    tagline: "A builder's toolkit for FiveM",
  },
  mode: {
    furniture: '家具',
    door: 'ドア',
    parking: '駐車場',
    stash: 'スタッシュ',
  },
  action: {
    close: '閉じる',
  },
  placeholder: {
    selectFromLeft: '左から家具を選んで配置を開始してください',
  },
  props: {
    loading: 'プロップデータ読み込み中...',
    loadingWithCount: 'プロップデータ読み込み中... ({count} 件)',
    failed: 'プロップデータの読み込みに失敗しました',
    selectCategory: '左のツリーからカテゴリを選択してください',
    emptyCategory: 'このカテゴリにプロップがありません',
    searchNoResults: '検索に一致するプロップがありません',
    propGridAria: 'プロップカタログ（サムネイル付きグリッド）',
  },
  search: {
    placeholder: 'モデル名・名前・タグで検索（空白で AND）',
    ariaLabel: 'プロップ検索',
    hint: '例: chair / 椅子 / prop_',
  },
  panel: {
    selection: '選択中のオブジェクト',
    selectionHint: 'M2-e でトランスフォーム等を表示',
  },
  toast: {
    placeSuccess: '配置しました（ID: {id}）',
    placeFailed: '配置に失敗しました: {reason}',
  },
} as const

export function tf(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, key: string) => String(vars[key] ?? ''))
}
