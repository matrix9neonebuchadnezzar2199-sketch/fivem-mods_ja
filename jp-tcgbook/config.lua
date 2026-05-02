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

-- レーティング（BattleStats: リアル PvP のみ更新。疑似PvP solo / CPU 戦は対象外）
-- Elo・wins/losses/draws は BattlePvp.Finish（reason=normal・盤面埋め終了）経路のみ。投了・切断は OnPlayerLeave で Finish を呼ばないため不更新
-- 敗北時コピー1枚（PHASE 2d）: リアル PvP・normal のみ。勝者の初期手札5枚から1枚を敗者へ Database.AddCardToPlayer。詳細は docs/design/PHASE_2d_defeat_reward.md
Config.InitialRating = 1500
Config.EloKFactor = 32

-- 管理者 UI（/bookadmin）。server.cfg 例: add_ace group.admin command.tcg_book_admin allow
Config.BookAdminAce = 'command.tcg_book_admin'

-- true: 起動時に shared/cards.lua で tcg_cards_master を UPSERT（既存行も上書き）
-- false: **マスタが1件でもある場合**は Lua シードをスキップ（管理者 UI の編集を再起動で消さない）
-- 初回のみ自動シード: テーブルが空ならこの値に関わらず一度だけ Lua から投入する
-- nil 省略時は true（従来どおり毎回 UPSERT）
Config.SeedCardsFromLua = false

-- デバッグ（本番では false 推奨）
Config.Debug = true -- 詳細ログなど
Config.DebugCommands = true -- false のとき /tcg_* は一切実行不可（コンソール含む）。true 時は ACE command.tcg_debug またはコンソール

-- 対戦タブ: NUI↔client↔server の往復ログ（txAdmin server log）。true=常時ON / false=常時OFF / nil=Config.Debug に追随
-- 本番では false を明示推奨（nil のままだと Config.Debug=true の開発構成では Wire が ON になる）
Config.BattleWireLog = nil

-- NUI 自動保存のデバウンス（ミリ秒）
Config.AutoSaveDebounceMs = 500
