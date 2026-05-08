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
    searchNoResults: '検索に一致するプロップがありません', // 互換: 新コードは search.noResults を優先
    propGridAria: 'プロップカタログ（サムネイル付きグリッド）',
  },
  search: {
    placeholder: 'モデル名・ラベル・タグで検索（スペースで AND）',
    ariaLabel: 'プロップ検索',
    hint: '例: chair / 椅子 / prop_',
    clear: 'クリア',
    hitCount: '該当 {count} 件',
    noResults: '該当するプロップが見つかりません',
    cameraLookHint: '右ボタンを押したままドラッグで視点を回転',
  },
  tagFilter: {
    title: 'タグで絞り込み',
    clearAll: 'すべて解除',
  },
  placementGuide: {
    line1: '位置と向きを決めたら Enter で確定',
    line2: 'W：移動（位置）　R：回転',
  },
  transform: {
    position: '位置（ワールド）',
    rotation: '回転（度・Euler）',
    apply: '数値を適用',
    applying: '適用中…',
    applyOk: 'トランスフォームを保存しました',
    applyFailed: '保存に失敗しました（権限・通信を確認）',
    invalidNumber: '数値が不正です',
    clearSelection: '選択を解除',
    hint: '「適用」で DB に保存し、ワールド上のオブジェクトにも反映します。',
  },
  panel: {
    selection: '選択中のオブジェクト',
    pendingCameraLook: '右クリックで視点を移動できます。',
    catalogPickHint: '一覧でモデルを選ぶと、下に表示されます。見た目を確認してから「設置」でワールドへ出します（ギズモで位置調整して確定）。',
    placedSelectionHint: '設置直後は右パネルに座標が出ます。ワールドで別オブジェクトを選ぶ操作は今後追加予定です。',
    place: '設置',
    cancelPick: '一覧に戻る',
  },
  toast: {
    placeSuccess: '配置しました（ID: {id}）',
    placeFailed: '配置に失敗しました: {reason}',
  },
} as const

export function tf(template: string, vars: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (_, key: string) => String(vars[key] ?? ''))
}
