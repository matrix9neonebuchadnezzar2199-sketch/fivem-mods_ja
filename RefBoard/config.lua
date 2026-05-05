Config = {}

-- 審判（試合編集）に付与する ACE 権限名（server.cfg 例: add_ace group.admin refboard.referee allow）
Config.RefereePermission = 'refboard.referee'

-- ロック: クライアントが送るハートビート間隔（ミリ秒）
Config.HeartbeatIntervalMs = 10000

-- ロック: ハートビート途絶え何秒で自動解放するか
Config.LockTimeoutSec = 30

-- オートセーブ: 連続操作をまとめて DB へ書く待ち時間（ミリ秒）
Config.AutosaveDebounceMs = 500

-- 時計: DB 同期の目安間隔（ミリ秒・将来拡張用）
Config.ClockSyncIntervalMs = 1000

-- NUI を開くキー（キーマッピング名と一致）
Config.OpenKey = 'F6'

-- 既定ロケール（クライアントで上書き可）
Config.DefaultLocale = 'ja'

-- サーバー上のトランザクション検証コマンド（本番では false 推奨）
Config.EnableTestCommands = false

-- 前半の目安時間（ミリ秒）— UI 表示用。実際の試合時間は運用で操作
Config.HalfDurationMs = 45 * 60 * 1000
