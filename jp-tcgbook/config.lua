Config = {}

-- デッキ関連
Config.MaxDecksPerPlayer = 10 -- 1プレイヤーが持てるデッキ数の上限
Config.DeckSize = 10 -- 1デッキの枚数
Config.HandSize = 5 -- バトル時の手札上限（フェーズ2）
Config.MaxShiteiPerDeck = 2 -- 指定カードをデッキに入れられる合計枚数

-- カード重複ルール（デッキ内の同名カード上限）
Config.CardLimit = {
    shitei = 1, -- 指定（UR/SS）は同名1枚まで
    free = 2, -- フリーは同名2枚まで
}

-- 初回配布（フリーカードのみ）
Config.InitialCards = 10 -- 初回に配る枚数
Config.InitialCardRanks = { 'B', 'B', 'B', 'C', 'C', 'C', 'A', 'A', 'B', 'C' } -- ランクの候補プール（実装で解釈）

-- レーティング（フェーズ2以降で更新ロジックを接続）
Config.InitialRating = 1500
Config.EloKFactor = 32

-- 管理者 UI（/bookadmin）。server.cfg 例: add_ace group.admin command.tcg_book_admin allow
Config.BookAdminAce = 'command.tcg_book_admin'

-- デバッグ（本番では false 推奨）
Config.Debug = true -- 詳細ログなど
Config.DebugCommands = true -- /tcg_* コマンドの前提フラグ（ACEと併用）

-- NUI 自動保存のデバウンス（ミリ秒）
Config.AutoSaveDebounceMs = 500
