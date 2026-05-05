-- ============================================================
-- it-drugs 日本語ローカライズ (jp-it-drugs)
-- 文字コード: UTF-8（BOM なし）
-- 原作: it-scripts/it-drugs（GPL-3.0）
-- 日本語化: eiho_tsukuyomi
-- ============================================================

Locales['ja'] = {

    ['MENU__DEALER'] = '売人: %s',
    ['MENU__DEALER__DESC'] = '1個 $%g で購入',

    ['MENU__PLANT'] = '%s',
    ['MENU__DEAD__PLANT'] = '枯れた植物',

    ['MENU__PLANT__LIFE'] = '体力',
    ['MENU__PLANT__LIFE__META'] = '植物の体力です。0になると枯れます',

    ['MENU__PLANT__STAGE'] = '生育段階',
    ['MENU__PLANT__STAGE__META'] = '植物の成長度です。100に達すると収穫できます',

    ['MENU__PLANT__FERTILIZER'] = '肥料',
    ['MENU__PLANT__FERTILIZER__META'] = '植物には栄養が必要です。忘れず施肥しましょう',

    ['MENU__PLANT__WATER'] = '水分',
    ['MENU__PLANT__WATER__META'] = '植物には常に水分が必要です',

    ['MENU__PLANT__DESTROY'] = '破棄',
    ['MENU__PLANT__DESTROY__DESC'] = 'この植物を破棄します',

    ['MENU__PLANT__HARVEST'] = '収穫',
    ['MENU__PLANT__HARVEST__DESC'] = 'この植物を収穫します',

    ['MENU__ITEM'] = 'アイテム',
    ['MENU__ITEM__DESC'] = 'このアイテムを使って植物の世話をします',

    ['MENU__PROCESSING'] = '精製',
    ['MENU__RECIPE__DESC'] = 'このレシピでドラッグを精製します',

    ['MENU__UNKNOWN__INGREDIANT'] = '不明な材料',
    ['MENU__INGREDIANT__DESC'] = 'この材料が %g 個必要です',

    ['MENU__TABLE__PROCESS'] = 'ドラッグを精製',
    ['MENU__TABLE__PROCESS__DESC'] = '精製作業を開始します',

    ['MENU__TABLE__REMOVE'] = '作業台を撤去',
    ['MENU__TABLE__REMOVE__DESC'] = 'この作業台を回収します',

    ['MENU__DEALER__ACTION'] = "何をしますか？",

    ['MENU__DEALER__BUY'] = '購入',
    ['MENU__DEALER__BUY__DESC'] = '売人からアイテムを購入します',
    ['MENU__DEALER_BUY_ITEM__DESC'] = '%s を1個 $%g で購入',

    ['MENU__DEALER_SELL'] = '売却',
    ['MENU__DEALER__SELL_DESC'] = '売人にアイテムを売却します',
    ['MENU__DEALER_SELL_ITEM__DESC'] = '%s を1個 $%g で売却',

    ['MENU__SELL'] = '売却',
    ['MENU__SELL__DEAL'] = '取引',
    ['MENU__SELL__DESC'] = '%s (x%g) を $%g で売却',
    ['MENU__SEEL__DESC__ZERO'] = '%s (x%g) を売って次を入手:',

    ['MENU__SELL__REWARD'] = '入手アイテム:',
    ['MENU__SELL_REWARD_DESC'] = 'x%g 入手します',

    ['MENU__SELL__ACCEPT'] = '取引を承諾',
    ['MENU__SELL__ACCEPT__DESC'] = '現在の取引内容を承諾します',

    ['MENU__SELL__REJECT'] = '取引を拒否',
    ['MENU__SELL__REJECT__DESC'] = '現在の取引内容を拒否します',

    ['MENU__ADMIN__PLANT__MAIN'] = '植物の管理',
    ['MENU__ADMIN__TABLE__MAIN'] = '作業台の管理',

    ['MENU__PLANT__COUNT'] = '植物の総数',
    ['MENU__PLANT__COUNT__DESC'] = '現在 %g 件の植物があります',

    ['MENU__TABLE__COUNT'] = '作業台の総数',
    ['MENU__TABLE__COUNT__DESC'] = '現在 %g 台の作業台があります',

    ['MENU__LIST__PLANTS'] = '植物を距離順に表示',
    ['MENU__LIST__PLANTS__DESC'] = '各植物の詳細情報を表示します',

    ['MENU__LIST__TABLES'] = '作業台を距離順に表示',
    ['MENU__LIST__TABLES__DESC'] = '各作業台の詳細情報を表示します',

    ['MENU__ADD__BLIPS'] = 'マップに目印を追加',
    ['MENU__ADD__PLANT__BLIPS__DESC'] = 'すべての植物の位置をマップに表示します',
    ['MENU__ADD_TABLE__BLIPS__DESC'] = 'すべての作業台の位置をマップに表示します',

    ['MENU__REMOVE__BLIPS'] = 'マップから目印を削除',
    ['MENU__REMOVE__PLANT__BLIPS__DESC'] = 'すべての植物の目印をマップから削除します',
    ['MENU__REMOVE__TABLE__BLIPS__DESC'] = 'すべての作業台の目印をマップから削除します',

    ['MENU__PLANT__LIST'] = '植物一覧',
    ['MENU__TABLE__LIST'] = '作業台一覧',

    ['MENU__DIST'] = '距離: %gm',

    ['MENU__PLANT__ID'] = '植物: %s',
    ['MENU__TABLE__ID'] = '作業台: %s',

    ['MENU__OWNER'] = '所有者',
    ['MENU__OWNER__META'] = 'クリックで所有者IDをコピー',

    ['MENU__PLANT__LOCATION'] = '位置',
    ['MENU__LOCATION__DESC'] = '通り: %s | 座標: (%g, %g, %g)',
    ['MENU__LOCATION__META'] = 'クリックで座標をコピー',

    ['MENU__PLANT__TELEPORT'] = '植物の場所へテレポート',
    ['MENU__PLANT__TELEPORT__DESC'] = '植物の位置へテレポートします',

    ['MENU__TABLE__TELEPORT'] = '作業台の場所へテレポート',
    ['MENU__TABLE__TELEPORT__DESC'] = '作業台の位置へテレポートします',

    ['MENU__ADD__BLIP'] = 'マップに追加',
    ['MENU__ADD__PLANT__BLIP__DESC'] = 'この植物の目印をマップに作成します',
    ['MENU__ADD__TABLE__BLIP__DESC'] = 'この作業台の目印をマップに作成します',

    ['MENU__TABLE__DESTROY'] = '作業台を破壊',
    ['MENU__TABLE__DESTROY__DESC'] = 'この作業台を破壊します',

    ['NOTIFICATION__DEALER__SELL__SUCCESS'] = '%gx %s を $%g で売却しました',
    ['NOTIFICATION__DEALER__BUY__SUCCESS'] = '%gx %s を $%g で購入しました',
    ['NOTIFICATION__NO__MONEY'] = '所持金が足りません',
    ['NOTIFICATION__BUY__SUCCESS'] = '%s を購入しました',
    ['NOTIFICATION__DEALER__NO__ITEM'] = '売却するアイテムが足りません',

    ['NOTIFICATION__IN__VEHICLE'] = '車両内ではこの操作はできません',
    ['NOTIFICATION__CANT__PLACE'] = 'ここでは設置できません',
    ['NOTIFICATION__TO__NEAR'] = '他の植物に近すぎる場所には植えられません',
    ['NOTIFICATION__CANCELED'] = 'キャンセルしました...',
    ['NOTIFICATION__NO__ITEMS'] = 'この植物の世話に必要なアイテムを持っていません',

    ['NOTIFICATION__NO__AMOUNT'] = '数量を入力してください',

    ['NOTIFICATION__MISSING__INGIDIANT'] = '必要な材料が揃っていません',
    ['NOTIFICATION__SKILL__SUCCESS'] = 'ドラッグを1つ精製しました',
    ['NOTIFICATION__SKILL__ERROR'] = '誤ったキーを押しました',
    ['NOTIFICATION__PROCESS__FAIL'] = '精製に失敗しました',

    ['NOTIFICATION__CALLING__COPS'] = '買い手が警察に通報しています！',
    ['NOTIFICATION__MAX__PLANTS'] = 'まずは現在育てている植物の世話をしてください',
    ['NOTIFICATION__NOT__INTERESTED'] = '買い手は今は興味がないようです',
    ['NOTIFICATION__ALLREADY__SPOKE'] = 'この人物とは既に話しています',
    ['NOTIFICATION__NO__DRUGS'] = '相手が欲しがっている物を持っていません',
    ['NOTIFICATION__TO__LONG'] = '時間をかけすぎたため相手は去ってしまいました',
    ['NOTIFICATION__OFFER__REJECTED'] = '取引を拒否しました',
    ['NOTIFICATION__SOLD__DRUG'] = "$%g を受け取りました",
    ['NOTIFICATION__SELL__FAIL'] = '%g の売却に失敗しました',
    ['NOTIFICATION__NO__ITEM__LEFT'] = '売却できる %g がありません',
    ['NOTIFICATION__STOLEN__DRUG'] = '強奪されたため代金を受け取れませんでした',

    ['NOTIFICATION__DRUG__NO__EFFECT'] = 'このドラッグには効果がありません',
    ['NOTIFICATION__DRUG__ALREADY'] = '既にドラッグの効果中です',
    ['NOTIFICATION__DRUG__COOLDOWN'] = 'このドラッグを再使用するにはまだ時間が必要です',

    ['NOTIFICATION__NO__PERMISSION'] = 'この操作を行う権限がありません',
    ['NOTIFICATION__ADMINMENU__USAGE'] = '使用方法: /%s [plants/tables]',

    ['NOTIFICATION__COPY__CLIPBOARD'] = '情報をクリップボードにコピーしました: %s',

    ['NOTIFICATION__TELEPORTED'] = '対象の位置へテレポートしました',

    ['NOTIFICATION__PLANT__DESTROYED'] = '植物を破棄しました',
    ['NOTIFICATION__TABLE__DESTROYED'] = '作業台を破壊しました',

    ['NOTIFICATION__ADD__BLIP'] = 'マップに目印を追加しました',
    ['NOTIFICATION__REMOVE__BLIP'] = 'マップから目印を削除しました',

    ['NOTIFICATION__NEED_LIGHTER'] = '植物を破棄するにはライターが必要です',

    ['PROGRESSBAR__SPAWN__PLANT'] = '植え付け中...',
    ['PROGRESSBAR__HARVEST__PLANT'] = '収穫中...',
    ['PROGRESSBAR__SOAK__PLANT'] = '水やり中...',
    ['PROGRESSBAR__FERTILIZE__PLANT'] = '施肥中...',
    ['PROGRESSBAR__DESTROY__PLANT'] = '破棄中...',

    ['PROGRESSBAR__PLACE__TABLE'] = '作業台を設置中...',
    ['PROGRESSBAR__REMOVE__TABLE'] = '作業台を撤去中...',
    ['PROGRESSBAR__PROCESS__DRUG'] = '精製中...',

    ['INTERACTION__PLACING__TEXT'] = '[E] - 植え付け / [G] - キャンセル',
    ['INTERACTION__PLACING_TABLE__TEXT'] = '[E] - 作業台を設置 / [G] - キャンセル',

    ['INTERACTION__INTERACT_TEXT'] = '[E] - 操作する',

    ['INPUT__AMOUNT__HEADER'] = '精製',
    ['INPUT__AMOUNT__TEXT'] = '数量',
    ['INPUT__AMOUNT__DESCRIPTION'] = 'いくつ精製しますか？',

    ['INPUT__BUY__HEADER'] = '購入',
    ['INPUT__BUY__TEXT'] = '数量',
    ['INPUT__BUY__DESCRIPTION'] = '%s をいくつ購入しますか？',
    ['INPUT__SELL__DESCRIPTION'] = '%s をいくつ売却しますか？',

    ['TARGET__DEALER__LABLE'] = '売人を確認',
    ['TARGET__PLANT__LABEL'] = '植物を確認',
    ['TARGET__TABLE__LABEL'] = '作業台を使う',
    ['TARGET__SELL__LABEL'] = '話しかける',

    ['COMMAND__ADMINMENU'] = 'drugadmin',
    ['COMMAND__GROUNDHASH'] = 'getGroundHash',

    ['COMMAND__GROUNDHASH__HELP'] = '現在の地面のハッシュ値を取得します',

    ['3DTEXT__PLANT__LABLE'] = '~g~E~w~ キーで植物を操作',
    ['3DTEXT__TABLE__LABLE'] = '~g~E~w~ キーで作業台を操作',
    ['3DTEXT__DEALER__LABLE'] = '~g~E~w~ キーで売人と取引',
}
