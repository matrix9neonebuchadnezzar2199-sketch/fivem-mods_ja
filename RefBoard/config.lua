Config = {}

-- 編集モード入室時のパスワード（NUI ランチャー「編集モード」と一致させる）
Config.EditPassword = 'ref'

-- ロック: クライアントが送るハートビート間隔（ミリ秒）
Config.HeartbeatIntervalMs = 10000

-- ロック: ハートビート途絶え何秒で自動解放するか
Config.LockTimeoutSec = 30

-- オートセーブ: 連続操作をまとめて DB へ書く待ち時間（ミリ秒）
Config.AutosaveDebounceMs = 500

-- 時計: DB 同期の目安間隔（ミリ秒・将来拡張用）
Config.ClockSyncIntervalMs = 1000

-- NUI を開くキー（キーマッピング名と一致）
-- チャットで /refboard でも同じトグル（client/main.lua の RegisterCommand と同名）
Config.OpenKey = 'F6'

-- 既定ロケール（クライアントで上書き可）
Config.DefaultLocale = 'ja'

-- サーバー上のトランザクション検証コマンド（本番では false 推奨）
Config.EnableTestCommands = false

-- サーバーログレベル（Logger 用）: DEBUG / INFO / WARN / ERROR
Config.LogLevel = 'INFO'

-- 前半の目安時間（ミリ秒）— UI 表示用。実際の試合時間は運用で操作
Config.HalfDurationMs = 45 * 60 * 1000

-- true: 起動時に editor_locks が無ければ sql/install.sql を自動実行（空 DB の即席セットアップ用）
-- 本番で手動マイグレーション運用のみにしたい場合は false
Config.AutoCreateSchema = true

-- true: リソース起動時に sql/seed_test_5teams_15roster.sql を実行（5チーム×ロスター15人・再実行安全）
-- 本番でデモチーム名を入れたくない場合は false（手動で SQL を流す運用でも可）
Config.SeedDemoTeamsOnStart = true
