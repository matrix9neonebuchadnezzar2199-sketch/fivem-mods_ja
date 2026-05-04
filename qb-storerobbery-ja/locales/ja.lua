local Translations = {
    error = {
        minimum_store_robbery_police = "警察官が足りません（%{MinimumStoreRobberyPolice}人以上必要）",
        not_driver = "運転手ではありません",
        demolish_vehicle = "現在、車両を破壊することはできません",
        process_canceled = "中断されました..",
        you_broke_the_lock_pick = "ロックピックが折れました",
    },
    text = {
        the_cash_register_is_empty = "レジは空です",
        try_combination = "~g~E~w~ - 暗証番号を試す",
        safe_opened = "金庫が開いています",
        emptying_the_register = "レジから金を抜き取っています..",
        safe_code = "金庫の暗証番号: "
    },
    email = {
        shop_robbery = "10-31 | 強盗事件",
        someone_is_trying_to_rob_a_store = "%{street} で店舗強盗が発生しています（カメラID: %{cameraId1}）",
        storerobbery_progress = "店舗強盗が進行中"
    },
}

if GetConvar('qb_locale', 'en') == 'ja' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true
    })
end
