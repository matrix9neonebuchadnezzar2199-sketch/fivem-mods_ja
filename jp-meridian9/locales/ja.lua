-- ============================================================
-- MERIDIAN-9 / Project JANUS  日本語ロケール
-- ============================================================

Locales = Locales or {}
Locales['ja'] = {
    -- ▼ NPC 対話
    ['npc_greeting_first'] = '……いらっしゃい。法律相談ですか？ それとも——別件で？',
    ['npc_greeting_repeat'] = '……お戻りでしたか。ご用件は？',

    -- ▼ パーティ
    ['party_invite_sent'] = '%s に招待を送信しました',
    ['party_invite_received'] = '%s から MERIDIAN-9 任務への招待が届いています',
    ['party_invite_accepted'] = '招待を承諾しました',
    ['party_invite_rejected'] = '招待を拒否しました',
    ['party_full'] = 'パーティが満員です',
    ['party_not_contracted'] = '対象者は契約者ではありません',

    -- ▼ ミッション
    ['mission_starting'] = 'ゲートが起動します……',
    ['mission_started'] = 'サイト・ナインへようこそ',
    ['mission_timeout'] = '制限時間に到達しました。強制撤収します',
    ['mission_wipe'] = '全滅。任務は失敗しました',

    -- ▼ 脱出
    ['extract_available'] = '[E] を長押しで脱出',
    ['extract_in_progress'] = '脱出中……動かないでください',
    ['extract_success'] = '脱出に成功しました',

    -- ▼ 報酬
    ['reward_received'] = '報酬 $%d を受け取りました',
    ['reward_total_value'] = '回収物総額: $%d',

    -- ▼ システム
    ['contract_required'] = '先にヴェガと契約を結ぶ必要があります',
    ['contract_signed'] = '契約が締結されました。JANUS プログラムへようこそ',
    ['debug_only'] = 'このコマンドはデバッグモード時のみ使用可能です',
}

---@param key string
---@param ... any
---@return string
function _(key, ...)
    local locale = Config and Config.Locale or 'ja'
    local pack = Locales[locale] or Locales['ja']
    local str = pack and pack[key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end
