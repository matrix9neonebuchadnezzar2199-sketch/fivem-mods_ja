Config = {}

-- フレームワーク: 'auto' | 'esx' | 'qbcore' | 'qbox' | 'standalone'
Config.Framework = 'auto'

-- デバッグ（本番では false）
Config.Debug = false

-- UI・通知の言語キー（locales と対応）
Config.Locale = 'ja'

-- 警察へ NPC が通報されるか（強盗中）
Config.PoliceDispatchEnabled = false

-- 通報確率（0.0〜1.0）
Config.PoliceDispatchChance = 0.0

-- 強盗開始に必要な最低オンライン警官数（Standalone では無視）
Config.MinOnDutyCops = 0

-- 警官としてカウントするジョブ名（小文字）
Config.PoliceJobs = {
  police = true,
  sheriff = true,
  leo = true,
}

-- ロケーション単位クールダウン（秒）
Config.LocationCooldownSec = 120

-- 強盗中にプレイヤーが死亡したときの挙動: 'fail' | 'cancel'
Config.OnPlayerDeathDuringHeist = 'fail'

-- DB 永続化（未実装スタブ。true でも現状メモリのみ）
Config.EnableDatabasePersistence = false

-- 指名手配スキャン間隔（ミリ秒）
Config.BountyScanIntervalMs = 30000

-- 強盗：侵入プロンプトの更新間隔（ミリ秒）
Config.ZonePollIntervalMs = 500

-- ミニゲーム：鍵開けの許容時間（ミリ秒）
Config.MinigameLockpickDurationMs = 8000

-- ミニゲーム：ハッキングのターン数
Config.MinigameHackSteps = 5

-- ミニゲーム：力業の連打回数
Config.MinigameBruteHits = 12

-- NUI フォーカス時の入力制御
Config.NuiDisableIdleCamera = true

-- ox_lib 等は使用しない（standalone 配布優先）
