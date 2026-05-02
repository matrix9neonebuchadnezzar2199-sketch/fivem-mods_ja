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

-- レーティング（BattleStats: リアル PvP のみ更新。疑似PvP solo は既定では対象外 → `PvpSoloApplyFullFinishHooks` で検証時のみ本番経路。CPU 戦は対象外）
-- Elo・wins/losses/draws は BattlePvp.Finish（reason=normal・盤面埋め終了）経路のみ。投了・切断は OnPlayerLeave で Finish を呼ばないため不更新
-- 敗北時コピー1枚（PHASE 2d）: リアル PvP・normal のみ。勝者の初期手札5枚から1枚を敗者へ Database.AddCardToPlayer。詳細は docs/design/PHASE_2d_defeat_reward.md
Config.InitialRating = 1500
Config.EloKFactor = 32

-- PHASE C（日次カウンタ `tcg_daily_counters`）: リアル PvP・`BattlePvp.Finish` → `RecordFinish` / `GrantOnFinish` のみ更新（solo / CPU は対象外）
-- 暦日キーは JST（`Database.JstDateStringFromEpoch`・UTC+9 固定）。設計: docs/design/PHASE_C_daily_counters.md

-- PHASE E1（対戦履歴 `tcg_match_history`）: リアル PvP のみ・同一試合は `match_id`（= session_id）で UNIQUE。`BattlePvp.Finish` 内で Grant 後に INSERT。設計: docs/design/PHASE_E_ranking_season_ui.md §6

-- PHASE E2 / M3（対戦履歴タブ）: `openBook` 応答に同梱する最大件数。サーバー側で `MatchHistoryLimitMax` を超えない
Config.MatchHistoryLimitOpenBook = 50 -- BOOK オープン時に返す履歴の既定件数
Config.MatchHistoryLimitMax = 100 -- 履歴クエリのハード上限（チートで巨大 LIMIT を指定されてもこの値で頭打ち）

-- PHASE E3 / M4（PvP EXP・連勝）: `BattleStats.RecordFinish`（リアル PvP のみ）で更新。敗北・引き分けで連勝 0。投了・切断は `OnPlayerLeave` で離脱者の連勝のみ 0（レート・勝敗数は Finish のみの既存方針）
Config.PvpExpWinBase = 25 -- 勝利時に加算する基本 EXP
Config.PvpWinStreakBonusCap = 10 -- 連勝ボーナス計算に使う「試合前連勝」の上限（これ以上はボーナス増えない）
Config.PvpExpPerStreakStep = 2 -- 試合前連勝 1 につき勝利 EXP に加算する値（0 で連勝ボーナス無効）
-- 累積 EXP がこの値以上なら次のレベルへ（昇順・Lv1→2 に必要な累積が最初の要素）
Config.PvpLevelExpThresholds = {
    100,
    300,
    600,
    1000,
    1500,
    2200,
    3000,
    4000,
    5200,
    6600,
}
-- 上記テーブルの最終閾値を超えたあと、レベルを 1 上げるのに必要な追加 EXP（0 ならテーブル外ではレベルは伸びない）
Config.PvpExpPerLevelBeyondTable = 800
Config.PvpLevelCap = 99 -- 表示レベルの上限

-- 1人開発検証（docs/design/DEV_SOLO_VERIFICATION_POLICY.md）: 疑似PvPソロを RecordFinish・履歴・EXP・2d 報酬まで本番と同一経路に載せる
-- 本番サーバーでは false 固定推奨。true でも Config.DebugCommands == true でないと StartSolo・Finish 内のガードが成立しない
Config.PvpSoloApplyFullFinishHooks = false
-- ソロ検証時の仮想相手 citizenid（tcg_players に 1 行。Database.EnsureVerificationDummyPeer で作成）。dryrun コマンドと共用
Config.PvpSoloVerificationDummyCitizenid = 'jp-tcgbook-debug-peer-dummy'

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
