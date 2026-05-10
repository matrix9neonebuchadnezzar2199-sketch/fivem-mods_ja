Config = Config or {}

-- ===================================================================
-- jp-pola（ps-camera 日本語版）— サーバー運営者向け設定
-- ===================================================================
-- 原作: https://github.com/Project-Sloth/ps-camera
-- ライセンス: CC BY-NC-SA 4.0
-- ===================================================================

-- 写真アップロード方式
--   true  : Fivemerr（推奨。https://fivemerr.com/ で発行した API トークンを使う）
--   false : Discord Webhook（チャンネルに直接アップロード）
-- どちらを使う場合でも、トークン／URL は server/sv_main.lua の
-- SvConfig（旧来の直書き）か、server.cfg 側の convar で渡す。
Config.UseFivemerr = true

-- デバッグログ（true で client/server の print を有効化）
-- 本番では必ず false にする（常時 print はパフォーマンス低下とログ汚染の原因）。
Config.Debug = false
