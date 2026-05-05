-- jp-v-farming 日本語ロケール
-- v1.0.0-ja.1 / 原作: Virgildev/v-farming (MIT)

Locales = Locales or {}

Locales['ja'] = {
    ['SELLER_BLIP_LABEL'] = '青果店',
    ['PICK_LABEL'] = '%s を収穫する',
    ['SELL_FRUITS_LABEL'] = '果物を売る',
    ['PICKING_PROGRESS'] = '%s を収穫中…',
    ['SELLING_PROGRESS'] = '%s を販売中…',
    ['MENU_TITLE'] = '青果商人',
    ['MENU_SEARCH_TITLE'] = '検索',
    ['MENU_SEARCH_DESC'] = '果物を検索する',
    ['MENU_SEARCH_DIALOG'] = '果物検索',
    ['MENU_SEARCH_INPUT'] = '果物名を入力',
    ['MENU_ITEM_DESC'] = '%s を販売する',
    ['SELL_DIALOG_TITLE'] = '%s を売却',
    ['SELL_DIALOG_AMOUNT'] = '販売数量',
    ['SELL_SUBMIT'] = '売る',
    ['NTF_INVALID_AMOUNT_T'] = '数量が不正です',
    ['NTF_INVALID_AMOUNT_D'] = '1以上の数値を入力してください',
    ['NTF_SALE_CANCELED_T'] = '販売をキャンセルしました',
    ['NTF_SALE_CANCELED_D'] = '販売数量を入力してください',
    ['NTF_NOT_NEAR_TARGET'] = '対象地点に近づいてください',
    ['NTF_NOT_NEAR_SELLER'] = '青果店から離れすぎています',
    ['NTF_NOT_ENOUGH_ITEM'] = '所持数が不足しています',
    ['NTF_HARVESTED'] = '%s を %s 個 収穫しました',
    ['NTF_SOLD'] = '%s を %s 個 販売し $%s を得ました',
    ['NTF_EXPLOIT_DETECTED'] = '不正検知: 強制切断されました',
    ['ITEM_APPLE'] = 'リンゴ',
    ['ITEM_ORANGE'] = 'オレンジ',
    ['ITEM_PEAR'] = '洋ナシ',
    ['ITEM_CHERRY'] = 'サクランボ',
    ['ITEM_PEACH'] = '桃',
    ['ITEM_BANANA'] = 'バナナ',
    ['ITEM_STRAWBERRY'] = 'イチゴ',
    ['ITEM_BLUEBERRY'] = 'ブルーベリー',
    ['ITEM_GRAPE'] = 'ブドウ',
    ['ITEM_KIWI'] = 'キウイ',
    ['ITEM_LEMON'] = 'レモン',
    ['ITEM_MANGO'] = 'マンゴー',
    ['ITEM_WATERMELON'] = 'スイカ',
    ['ITEM_MILK'] = '牛乳',
    ['FARM_APPLE'] = 'リンゴ農園',
    ['FARM_ORANGE'] = 'オレンジ農園',
    ['FARM_PEAR'] = '洋ナシ農園',
    ['FARM_CHERRY'] = 'サクランボ農園',
    ['FARM_PEACH'] = '桃農園',
    ['FARM_BANANA'] = 'バナナ農園',
    ['FARM_STRAWBERRY'] = 'イチゴ農園',
    ['FARM_BLUEBERRY'] = 'ブルーベリー農園',
    ['FARM_GRAPE'] = 'ブドウ園',
    ['FARM_KIWI'] = 'キウイ農園',
    ['FARM_LEMON'] = 'レモン農園',
    ['FARM_MANGO'] = 'マンゴー農園',
    ['FARM_WATERMELON'] = 'スイカ畑',
    ['FARM_MILK'] = '牧場（搾乳）',
}

function _U(key, ...)
    local lang = (Config and Config.Locale) or 'ja'
    local str = (Locales[lang] and Locales[lang][key]) or (Locales['en'] and Locales['en'][key]) or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
