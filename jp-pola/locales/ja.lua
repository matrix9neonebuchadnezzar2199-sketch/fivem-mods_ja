-- jp-pola 日本語ロケール
-- ユーザー向け（プレイヤーに見える）／運営向け（コンソールに出る）の文言を一箇所に集約。
-- イベント名・アイテム名は原作互換のため翻訳しない（ps-camera:* / camera / photo）。

Locales = Locales or {}

Locales.ja = {
    -- プレイヤー向け通知
    notify_no_camera        = 'カメラを持っていません',
    notify_cannot_carry     = '写真をこれ以上持てません',
    drop_cheater            = '不正検知のため切断されました',

    -- 運営向けコンソール（^1 = 赤字）
    err_invalid_inv         = '^1[エラー] SvConfig.Inv の値が不正です（typo の可能性）。現在値: SvConfig.Inv = "%s"^7',
    err_webhook_missing     = '^1[エラー] Discord Webhook が未設定です（SvConfig.webhook）。^7',
    err_fivemerr_missing    = '^1[エラー] Fivemerr API トークンが未設定です（SvConfig.FivemerrApiToken）。^7',
    err_fivemerr_disabled   = '^1[エラー] Fivemerr トークンが要求されましたが Config.UseFivemerr = false です。^7',

    -- デバッグ
    debug_cheating          = '[%s] 不正検知: src=%s',
}

-- 取得ヘルパ。キーがなければキー名を返す（フォールバック）。
function L(key, ...)
    local s = Locales.ja[key]
    if not s then return key end
    if select('#', ...) > 0 then
        return s:format(...)
    end
    return s
end
