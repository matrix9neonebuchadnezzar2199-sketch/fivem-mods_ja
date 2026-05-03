# プレイヤー体験フロー シミュレーション

時系列でプレイヤー体験を追いながら、各シーンで **開発者が設置・設定すべきもの** を併記する。実装漏れ防止と Config スキーマ設計のたたき台として使う。

**関連**: `docs/DESIGN.md`（全体設計）、`docs/SCENARIO_TEMPLATE.md`（運営向けテンプレ）、`docs/EVENT_HOOKS.md`（イベント名は実装上 `jp-UnderworldBounty:on*` プレフィックス）。

---

## ストーリー設定（サンプルシナリオ）

**シナリオ名**: 「歌舞伎町の闇賭場」  
**プレイヤー**: 田中（仮名）、犯罪 RP 系プレイヤー、所持武器：拳銃、現在地：ロスサントス市街地  
**難易度**: Normal  
**想定プレイ時間**: 受注〜強盗完了で 20〜30 分、報復イベント込みで 2 時間  

---

## フロー全体表

| # | シーン | プレイヤー視点の体験 | 開発者が設置/設定するもの | 関連ファイル | 関連PHASE |
|---|--------|----------------------|---------------------------|--------------|-----------|
| 1 | 情報入手 | チャイナタウンの裏路地で「情報屋」NPC を発見、近づくと頭上にマーカー表示 | 情報屋 NPC の座標・モデル・スポーン条件 | `config/locations.lua` の `informants` セクション（設計案） | PHASE 2 |
| 2 | 接触 | NPC に近づき `E` キーで会話開始、ターゲット表示 | インタラクション距離、プロンプトテキスト、ターゲット UI 連携 | `client/main.lua`、`locales/ja.lua` | PHASE 2 |
| 3 | 情報取引 | 「賭場の情報を買う：¥50,000」「やめる」のメニュー表示 | 情報の価格、メニュー UI、購入条件（所持金チェックは Bridge） | `config/scenarios.lua` の `intel_cost`（設計案）、`bridge/` | PHASE 2 |
| 4 | 情報取得 | 支払い後、マップに賭場の場所がマーカー表示、有効期限 24 時間 | マップマーカー設定、期限管理ロジック | `config/locations.lua`、`server/` のタイマー状態（設計案） | PHASE 2 |
| 5 | 移動 | 田中が車で歌舞伎町風雑居ビルへ移動 | 賭場外観の建物選定（バニラ MLO 流用） | `config/locations.lua` の `heist_location.coords`（設計案） | PHASE 2 |
| 6 | 入口検知 | 雑居ビルの裏口に到着、ゾーン進入で画面下に「E キーで侵入」プロンプト | トリガーゾーン座標・半径、進入条件（武器・時間帯など） | `config/locations.lua` の `trigger`、`client/heist.lua` | PHASE 2 |
| 7 | 進入条件チェック | 「警察人数：3 人以上必要」「クールダウン：あと 0 分」表示後、進入可能 | 必要警官数、クールダウン、ブラックリストジョブ | `config/config.lua`、`config/blacklist.lua` | PHASE 2 |
| 8 | 鍵開けミニゲーム | 裏口のロックピックミニゲーム、成功で開錠 | ミニゲーム種類・難易度・制限時間、必要アイテム（ロックピック） | `config/scenarios.lua` の `entry_minigame` | PHASE 5 |
| 9 | 内部侵入 | 扉が開き賭場内部へ。BGM が緊張感ある和風に（任意） | サウンドキュー（任意）、内部いんちき座標 | `client/heist.lua`、サウンドはオプション | PHASE 3 |
| 10 | 偵察フェーズ | 見張り NPC 2 人、遠くにボス風 NPC | 敵 NPC 配置（座標・モデル・武器・AI） | `config/scenarios.lua` の `enemies[]` | PHASE 3 |
| 11 | 戦闘または潜入 | 排除またはステルス | NPC AI（passive / alert / aggressive）、視認・警報（設計案） | `config/scenarios.lua` の各 NPC の `behavior` | PHASE 3 |
| 12 | 警報発動 | 戦闘音で全員警戒、ボス退避 | 警報伝播、ボス退避 AI（設計案） | `client/npc_manager.lua` 拡張 | PHASE 3 |
| 13 | 賭場メインルーム | ポーカー卓・現金の山など | プロップ配置 | `config/scenarios.lua` の `props[]`（設計案） | PHASE 3 |
| 14 | ボス戦 | 親分風 NPC と用心棒との戦闘 | ボス HP・武器・特殊行動 | `config/scenarios.lua` の `boss` オブジェクト（設計案） | PHASE 3 |
| 15 | ボス制圧 | 全員撃破で「金庫の場所を発見」通知 | 制圧条件、通知キー | `client/heist.lua`、`locales/ja.lua` | PHASE 3 |
| 16 | 金庫ハッキング | 金庫前でハッキング、60 秒制限など | ミニゲーム種類・制限時間 | `config/scenarios.lua` の `vault_minigame`（設計案） | PHASE 5 |
| 17 | 戦利品入手 | 現金袋・帳簿など、移動速度 50% 低下（設計案） | 報酬テーブル、運搬デバフ | `config/rewards.lua`、`client/heist.lua` | PHASE 5 |
| 18 | 退出フェーズ | 退出ポイントへ向かう道中、追加用心棒 | 退出時追加敵 | `config/scenarios.lua` の `escape_enemies[]`（設計案） | PHASE 3 |
| 19 | 退出成功 | 退出ゾーン到達で成功、「闇の指名手配」通知 | 退出ゾーン、成功演出、報酬トリガー | `config/locations.lua` の `exit_zone`（設計案）、`server/heist.lua` | PHASE 3,4 |
| 20 | 報酬付与 | 現金・ブラックマネー・アイテム | サーバー側のみで抽選・付与 | `server/rewards.lua`、`config/rewards.lua` | PHASE 3 |
| 21 | 指名手配開始 | HUD にアイコン、残り時間表示（設計案） | アイコン画像、HUD、`server/bounty.lua` | `ui/assets/`、`server/bounty.lua` | PHASE 4,6 |
| 22 | 通常 RP 継続 | 自由行動 | （システムなし） | - | - |
| 23 | 不穏な気配 | 「視線を感じる…」フレーバー | 事前警告タイミング・文言 | `config/retaliation.lua` の `pre_warning_seconds`（設計案） | PHASE 4 |
| 24 | 報復隊接近 | 黒い SUV が接近 | 車両モデル、スポーン距離、走行 AI | `config/retaliation.lua` の `vehicle_model`、`spawn_distance`（設計案） | PHASE 4 |
| 25 | 降車・襲撃 | 武装 NPC が降車 | 人数・武器・モデル | `config/retaliation.lua` のパターン定義 | PHASE 4 |
| 26 | 戦闘 | 警察は介入しない | 関係性グループ | `client/retaliation.lua` | PHASE 4 |
| 27 | 撃退成功 | ドロップ入手（設計案） | `drops[]` 確率 | `config/retaliation.lua` | PHASE 4 |
| 28 | 残り回数チェック | 0 なら指名解除、HUD 消灯 | 回数・解除・通知 | `server/bounty.lua` | PHASE 4 |
| 29 | RP 継続 | クールダウン後に再挑戦 | CD 管理 | `config/config.lua` の `LocationCooldownSec`、シナリオ単位 CD は設計案 | PHASE 2 |
| 30 | イベントフック | 他リソースへ通知 | `TriggerEvent` による公開フック | `server/events.lua`（実装名は `jp-UnderworldBounty:onHeistComplete` 等） | PHASE 7 |

---

## 分岐シナリオ表（失敗・例外パターン）

| 分岐ケース | 発生条件 | 結果 | 開発者設定項目 |
|------------|----------|------|----------------|
| 警官不足で開始不可 | オンライン警察が必要数未満 | 開始不可・通知 | `config/config.lua` の `MinOnDutyCops` |
| クールダウン中 | ロケーション CD 残り | 開始不可・通知 | `config/config.lua` の `LocationCooldownSec`（シナリオ単位 `cooldown_seconds` は設計案） |
| 強盗中に死亡 | 戦闘で HP0 | 強制終了・報酬なし（指名付与は現状成功時のみ） | `config/config.lua` の `OnPlayerDeathDuringHeist`（`fail` / `cancel`） |
| 強盗中に切断 | 切断 | サーバーで状態クリア | `playerDropped` / `onResourceStop` |
| 報復中に死亡 | 報復で死亡 | `clear_bounty_on_player_death` が true なら解除など | `config/retaliation.lua` の各パターン内（現キー名） |
| 報復 NPC から逃走 | 一定距離離脱 | NPC 消滅・回数消費可否 | `despawn_distance`、`flee_consumes_count`（設計案） |
| 退出前タイムアウト | 制限時間オーバー | 失敗・通報など | `time_limit_sec`（サーバー判定あり）、通報は設計案 |
| ブラックリストジョブ | LEO 等 | 開始不可 | `config/blacklist.lua` |

---

## 開発者の設置/設定アセット一覧

シナリオ追加が **可能な限り Config のみ** で完結することを目標とする。

| 種別 | 内容 | 設定方法 | バニラ流用可否 |
|------|------|----------|----------------|
| 情報屋 NPC | 裏路地の NPC | `config/locations.lua` に座標・モデル（設計案：`informants`） | 可 |
| 賭場の場所 | 建物・外観 | `locations` / マーカー（設計案） | 可 |
| 入口トリガーゾーン | 進入判定 | `trigger.coords` + `radius` | 座標のみ |
| 賭場内装プロップ | ポーカー台等 | `props[]`（設計案） | `prop_*` 流用可 |
| 敵 NPC | 見張り・用心棒 | `enemies[]` | 可 |
| ボス NPC | 幹部 | `boss`（設計案）／現状は `enemies` に統合も可 | 可 |
| 金庫オブジェクト | 金庫 prop | `vault`（設計案） | 可 |
| 報酬アイテム | 現金・帳簿等 | `config/rewards.lua` | アイテム名は FW 依存 |
| 退出ゾーン | 脱出判定 | `exit_zone`（設計案） | 座標のみ |
| 報復構成 | 襲撃隊 | `config/retaliation.lua` のパターン | 可 |
| 報復車両 | SUV 等 | 同上 `vehicle_model` 等 | 可 |
| ミニゲーム | 鍵開け・ハッキング | `entry_minigame`、将来 `vault_minigame` | 現状 NUI 内製 |
| UI 画像 | 指名アイコン等 | `ui/assets/` | 自作推奨 |
| ローカライズ | 全プレイヤー向け文言 | `locales/ja.lua` `locales/en.lua` | テキスト |
| サウンド（任意） | BGM・警報 | `client/` + Config（設計案） | バニラ or 省略 |

---

## 設計論点（この表から拾い上げた優先事項）

1. **情報屋**: PHASE 9 に置きがちだが、RP 深度のため **PHASE 2 相当の簡易版**（固定 NPC・固定価格・マーカー付与）をコアに含める価値が高い。  
2. **運搬ペナルティ**（#17）: 演出・緊張感に効く。**コアで Config 化** を検討。  
3. **死亡時挙動**: 強盗中／報復中それぞれ **必ず Config で選択可能** にする（ハードコア／ライト両対応）。  
4. **テンプレ化**: 本表を `docs/SCENARIO_TEMPLATE.md` に落とし込み、運営が「空欄を埋めるだけ」でシナリオ設計できるようにする。

---

## 実装コードベースとの対応（v1.0.0 時点）

本ドキュメントの表は **目標フロー + Config スキーマ案** を含む。現リポジトリとの主な差分は以下。

| 項目 | 現状 |
|------|------|
| 情報屋・intel 購入・期限付きマーカー | 未実装 |
| 入口 `trigger` + E プロンプト + 警官・CD・ブラックリスト | 実装済み |
| `entry_minigame`（シナリオ先頭の 1 種） | 実装済み |
| `vault_minigame`・`props[]`・`escape_enemies[]`・`exit_zone`・警報伝播 | 未実装（拡張ポイント） |
| 成功条件 | 敵全滅で完了（退出ゾーン未使用） |
| 報復 `pre_warning_seconds`・`spawn_distance`・`drops` 実処理・逃走離脱 | 一部のみ（襲撃直前フレーバー・車両接近は実装、drops 抽選はスタブ寄り） |
| HUD 残り時間 | NUI はアイコン中心、カウントダウンは設計案 |
| 公開イベント | `jp-UnderworldBounty:on*`（詳細は `EVENT_HOOKS.md`） |

実装を進めるときは **本表の「設計案」列を Config スキーマに落とし、`scenario_loader` で検証** すると漏れが減る。
