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

-- Discord Webhook（UseFivemerr = false）のとき:
-- true = スクリーンショットを base64 でサーバーに送り、**サーバーから** Discord に multipart POST（40333 / Cloudflare 対策・Webhook URL をクライアントに渡さない）。
-- false = 従来どおり screenshot-basic がクライアント(CEF)から直接 Discord に POST（軽いが 40333 が出る環境がある）。
Config.DiscordUploadViaServer = true

-- Discord サーバー経由（DiscordUploadViaServer = true）のとき、クライアント→サーバーへ送る base64 の最大文字数。
-- 高解像度・ウィンドウ最大化の PNG は 1,500万文字超になることがある。足りない場合だけ値を上げる。
-- 参考: base64 文字数 × 0.75 ≈ デコード後バイト。Discord Webhook の添付上限（多くは 8〜25MB 帯）はサーバー側で弾かれることがある。
Config.DiscordRelayMaxBase64Chars = 45 * 1024 * 1024

-- デバッグログ（true で client/server の print を有効化）
-- 本番では必ず false にする（常時 print はパフォーマンス低下とログ汚染の原因）。
Config.Debug = false
