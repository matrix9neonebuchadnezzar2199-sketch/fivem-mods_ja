Config = {}

-- UI・通知で使う言語キー（'ja' / 'en'）。locales と対応
Config.Locale = 'ja'

-- ============================================================
-- 内部ブリッジ・状態参照（運営者は通常編集不要）
-- ============================================================
Config._JpSentinel = Config._JpSentinel or {}

-- ============================================================
-- 基本設定
-- ============================================================

-- 対応ジョブ（このジョブのみ投擲・マップ表示可）
Config.PoliceJobs = { 'police', 'sheriff' }

-- 使用するフレームワーク：'esx' | 'qb' | 'qbox' | 'standalone'
Config.Framework = 'qbox'

-- standalone のとき、警察として扱う ACE（いずれかが許可されていれば可）
Config.StandalonePoliceAce = 'jp-sentinel.police'

-- アイテム名（インベントリ使用フック用）
Config.ItemName = 'sentinel_ball'

-- コマンドからも起動可能にするか
Config.EnableCommand = true
Config.CommandName = 'sentinel'

-- ============================================================
-- 投擲・命中
-- ============================================================

Config.Throw = {
    WeaponHash = `WEAPON_BALL`,
    MaxFlightTime = 5000, -- ボール飛行追跡の最大時間（ms）
    HitRadius = 2.0, -- 命中判定半径（m）：ボール周辺に Ped がいればヒット候補
    SearchRadius = 3.0, -- タイムアウト時の最終探索半径（m）
}

-- ============================================================
-- 追尾
-- ============================================================

Config.TrackDuration = 600 -- 秒
Config.DronePropHash = `prop_police_drone`
Config.DroneOffsetZ = 3.5 -- 通常時の対象頭上／車両直上からの高さ（m）
Config.DroneIndoorZ = 1.5 -- 屋内時の高さ（m）
Config.LerpFactor = 0.15 -- 追従補間係数

-- 高速車両ロスト判定（対象が乗車中の車両速度）
Config.LostSpeedKmh = 180.0 -- これを超えるとロスト

-- ============================================================
-- マップ共有
-- ============================================================

Config.Blip = {
    UpdateInterval = 2000, -- サーバー側座標配信間隔（ms）
    Sprite = 303,
    Color = 1, -- 赤
    Scale = 1.0,
    Alpha = 255,
    ShortRange = false,
    NamePrefix = 'Sentinel追尾',
}

-- ============================================================
-- クールダウン
-- ============================================================

Config.Cooldown = {
    Enabled = true, -- false で無制限使用可
    Seconds = 1800, -- 30 分
    Persist = false, -- true のとき oxmysql で永続化（サーバーに oxmysql が必要）
}

-- ============================================================
-- 通常自爆（時間切れ）
-- ============================================================

Config.SelfDestruct = {
    RiseHeight = 10.0,
    RiseDuration = 2000,
    HoverTime = 1000,
    ParticleDict = 'core',
    ParticleName = 'exp_grd_grenade',
    ParticleScale = 1.5,
    SoundName = 'Explosion',
    SoundSet = 'DLC_HEIST_HACKING_SNAKE_SOUNDS',
}

-- ============================================================
-- 撃墜自爆
-- ============================================================

Config.ShotDown = {
    Enabled = true,
    DroneHealth = 200,
    ParticleDict = 'core',
    ParticleName = 'exp_grd_grenade_smoke',
    ParticleScale = 0.8,
    SoundName = 'Explosion',
    SoundSet = 'DLC_HEIST_HACKING_SNAKE_SOUNDS',
    LostBlipTime = 5000,
    LostBlipSprite = 303,
    LostBlipColor = 1,
    LostBlipAlpha = 128,
}

-- ============================================================
-- スポーン演出
-- ============================================================

Config.Spawn = {
    ParticleDict = 'core',
    ParticleName = 'exp_air_blimp',
    ParticleScale = 0.5,
    SoundName = 'Hack_Success',
    SoundSet = 'DLC_HEIST_HACKING_SNAKE_SOUNDS',
}

---翻訳ヘルパー（サーバー／クライアント共通）
---@param key string
---@param ... any format args
---@return string
function Config.Lang(key, ...)
    local pack = Locales[Config.Locale or 'ja'] or Locales.ja
    local fmt = pack[key] or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then
        return string.format(fmt, ...)
    end
    return fmt
end

-- type: 'success' | 'error' | 'info'（サーバー側のみ有効。共有読み込みのため client では何もしない）
Config.Notify = function(source, msg, type)
    if IsDuplicityVersion() and source then
        TriggerClientEvent('jp-sentinel:client:notify', source, msg, type or 'info')
    end
end
