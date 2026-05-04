Locales = Locales or {}

Locales.ja = {
    -- HUD UI（NUI 側でも参照する辞書）
    ui = {
        cash         = '現金',
        bank         = '銀行',
        black_money  = '裏金',
        unemployed   = '無職',
        no_grade     = '階級なし',
        grade_prefix = '階級',
        speed_unit   = 'KM/H',
        cruise       = 'クルーズコントロール',
    },

    -- ログ／コンソール
    log = {
        loaded            = '[jp-mch] 読み込み完了（FW=%s）',
        fw_detected       = '[jp-mch] フレームワーク検出: %s',
        fw_not_found      = '[jp-mch] フレームワーク未検出。standalone モードで起動します。',
        esx_status_ok     = '[jp-mch] esx_status を検出しました',
        esx_status_none   = '[jp-mch] esx_status が無いため簡易シミュレーションを使用します',
        layout_reset      = '[jp-mch] HUD レイアウトを初期値に戻しました',
        bridge_money_evt  = '[jp-mch] 外部金銭イベント受信: cash=%s bank=%s black=%s',
    },
}

-- 既定言語
Locale = Locales.ja
