# jp-UnderworldBounty 開発指示書

## 0. プロジェクト概要

**名称**: jp-UnderworldBounty（闇の指名手配）

**コンセプト**: ヤクザの賭場（裏カジノ）を襲撃し、強盗成功後にヤクザ側からの報復NPCに襲われる、日本のRPサーバー向けFiveM犯罪スクリプト

**開発形態**: ソロ開発、スクリプト主体、3Dアセットはバニラ流用、UI画像のみ自作

**対象フレームワーク**: ESX / QBCore / Qbox（3対応）+ Standaloneモード

**開発環境**: Cursor (Windows)、開発ディレクトリ `H:\CURSOR\Dev\jp-UnderworldBounty`

**配布**: GitHub `matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja`、Cfx.re Releasesフォーラム

**ライセンス**: MIT想定（要決定）

---

## 1. 設計思想（最重要）

### 1.1 「運営が柔軟にストーリーを提供できる」を実現する4つの原則

これがこのスクリプトの**最大の差別化ポイント**であり、設計の背骨です。

第一に、**ハードコードを禁止**します。賭場のロケーション、NPCの種類、武器、報酬、報復のシナリオ、すべてConfig/JSONで定義し、Luaコード本体には一切の固有値を書かない。サーバー運営者が `config/locations.lua` を編集するだけで「新しい賭場」を追加できる構造にする。

第二に、**シナリオ駆動型（Scenario-driven）**にします。1つの賭場 = 1つのシナリオオブジェクトとして定義し、「侵入条件」「敵構成」「報酬テーブル」「報復パターン」をシナリオ単位で全て指定可能にする。これにより運営は「歌舞伎町ヤクザの賭場（高難度）」「町中華系の小規模賭場（初心者向け）」「韓国系マフィアの賭場（中級）」などを自由に追加できる。

第三に、**イベントフック（Event Hook）を全主要アクションに公開**します。`UnderworldBounty:onHeistStart`、`onHeistComplete`、`onBountyTriggered`、`onRetaliationSpawn`、`onPlayerKilled`、`onBountyCleared`などのカスタムイベントを発火させ、他のスクリプト（Discord Bot、独自経済、独自評判システム）と連携できるようにする。これがあると「上級運営者」が独自RPに組み込みやすくなり、評価が爆上がりします。

第四に、**ロケール（多言語対応）を最初から組み込む**。`locales/ja.lua` `locales/en.lua` を最初から用意し、すべてのプレイヤー向け文字列はキー参照（`_L('heist_start_message')`）にする。日本語デフォルトでありながら海外サーバーでも使える設計にすることで、リーチが2倍になります。

### 1.2 やってはいけないこと

NPCの座標やモデル名をLuaファイルにハードコードしないこと。「`Citizen.Wait(2000)`」のようなマジックナンバーをコード中にばらまかないこと（Configから引く）。クライアント側にお金関連のロジックを書かないこと（必ずサーバーサイドで処理、チート対策）。フレームワーク依存コード（`ESX.GetPlayerData()`等）を直接書かず、必ず `bridge/` ディレクトリの抽象化レイヤー経由で呼ぶこと。

---

## 2. ディレクトリ構成

```
jp-UnderworldBounty/
├── fxmanifest.lua              # FiveMリソースマニフェスト
├── fxmanifest.full.lua.template # Greenfield向けマニフェスト参照（実ロードは fxmanifest.lua）
├── README.md                   # 日本語+英語のREADME
├── LICENSE
├── CHANGELOG.md
│
├── docs/
│   ├── DESIGN.md               # この指示書（あなたが今読んでるもの）
│   ├── CONFIG_GUIDE.md         # 運営者向けConfig設定ガイド
│   ├── SCENARIO_GUIDE.md       # シナリオ追加方法のガイド
│   ├── EVENT_HOOKS.md          # 開発者向けイベントフック仕様
│   ├── SEQUENCE_DIAGRAMS.md    # サーバー↔クライアントシーケンス・payload
│   ├── INSTRUCTIONS_PHASE_1A.md # PHASE 1a: Bridge API スナップショット化作業指示（Cursor）
│   ├── BRIDGE_API.md           # Bridge / ClientBridge API リファレンス（スナップショット）
│   ├── INSTRUCTIONS_PHASE_1A_FOLLOWUP.md # PHASE 1a フォローアップ（要確認確定・保留コメント）
│   ├── INSTRUCTIONS_PHASE_1B.md # PHASE 1b: §9 改善候補の優先付け・BRIDGE_API_IMPROVEMENTS 作成（Cursor）
│   └── images/                 # ドキュメント用画像
│
├── config/
│   ├── config.lua              # グローバル設定
│   ├── locations.lua           # 賭場ロケーション定義
│   ├── scenarios.lua           # シナリオ定義（敵構成、報酬等）
│   ├── retaliation.lua         # 報復NPC設定
│   ├── rewards.lua             # 報酬テーブル
│   └── blacklist.lua           # 除外プレイヤー/ジョブ設定
│
├── locales/
│   ├── ja.lua                  # 日本語（デフォルト）
│   ├── en.lua                  # 英語
│   └── _template.lua           # 翻訳者向けテンプレート
│
├── bridge/                     # フレームワーク抽象化レイヤー
│   ├── _init.lua               # フレームワーク自動検出・共通初期化
│   ├── sv_bridge.lua           # サーバー側 Bridge 実装
│   └── cl_bridge.lua           # クライアント側 Bridge 実装
│
├── client/
│   ├── main.lua                # エントリーポイント
│   ├── heist.lua               # 強盗ロジック（クライアント側）
│   ├── npc_manager.lua         # NPCスポーン管理
│   ├── retaliation.lua         # 報復NPC生成
│   ├── ui.lua                  # NUI制御
│   ├── notifications.lua       # 通知システム
│   ├── minigames.lua           # ミニゲーム呼び出し
│   ├── _stub.lua               # 開発用スタブ（Config.DebugUseClientStub）
│   └── utils.lua
│
├── server/
│   ├── main.lua
│   ├── scenario_loader.lua     # シナリオ／ロケーション参照整合
│   ├── heist.lua               # 強盗ロジック（サーバー側、報酬付与）
│   ├── bounty.lua              # 闇の指名手配状態管理
│   ├── rewards.lua             # 報酬計算
│   ├── persistence.lua         # DB永続化（任意）
│   ├── events.lua              # 公開イベントフック
│   └── utils.lua
│
├── shared/
│   ├── constants.lua           # 共通定数・UbEvent
│   ├── locale.lua              # _L() ヘルパ
│   └── version.lua
│
├── ui/                         # NUI（HTML/CSS/JS）
│   ├── index.html
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── app.js
│   └── assets/
│       ├── bounty_icon.png     # 闇の指名手配アイコン（自作）
│       ├── notification_bg.png # 通知背景（自作）
│       └── fonts/
│           └── NotoSansJP.woff2
│
└── sql/
    └── install.sql             # DBスキーマ（任意機能用）
```

---

## 3. Config設計（運営者が触る部分）

### 3.1 `config/config.lua`（グローバル設定）

グローバル設定には、フレームワーク選択（auto / esx / qbcore / qbox / standalone）、デバッグモード切替、警察通報の有効/無効と通報確率、最低必要警官数、賭場のクールダウン時間、強盗中のプレイヤー死亡時の挙動、対応言語、データベース永続化の有無、を持たせます。すべてコメント付きで、運営者が読んだだけで意味が分かるようにする。

### 3.2 `config/locations.lua`（賭場ロケーション）

各ロケーションは以下の構造を持つテーブル配列。識別子、表示名、座標、進入トリガー位置、退出ポイント、関連シナリオID、有効フラグ、出現時間帯（深夜のみ等）、必要レベル/評判（任意）。新しい賭場の追加は、このファイルに1ブロック追加するだけで完結する設計。

### 3.3 `config/scenarios.lua`（シナリオ定義 - 最重要）

シナリオは「賭場を襲ってから報酬を受け取るまでの一連の流れ」を定義する単位。各シナリオに、識別子、難易度（easy/normal/hard/extreme）、敵NPC構成（モデル名・人数・武器・配置座標・AI挙動）、ボスNPCの有無と挙動、進入ミニゲームの種類（lockpick / hacking / brute / none）、制限時間、必要アイテム（ロックピック等）、成功条件、失敗条件、報酬テーブル参照ID、報復パターン参照ID、フレーバーテキスト（プレイヤーに表示される導入文）を持たせる。

シナリオは **JSON形式** でも読めるようにオプション提供すると、運営者がGUIツール等で編集しやすくなる。

### 3.4 `config/retaliation.lua`（闇の指名手配）

報復システムの設定。指名手配の継続時間（デフォルト2時間）、襲撃発生回数の上限（デフォルト1回、最大設定可能数）、襲撃間隔の最小〜最大（ランダム範囲）、襲撃NPC構成パターン（複数定義可能で、シナリオごとにどのパターンを使うか参照）、襲撃車両モデル、襲撃時の演出（遠距離からの接近 / 即時スポーン）、プレイヤー死亡時の指名手配解除フラグ、警察介入の無効化フラグ、襲撃NPCを倒した際のドロップアイテム、襲撃失敗時の追加ペナルティ。

### 3.5 `config/rewards.lua`（報酬テーブル）

報酬は「アイテムドロップ」「現金」「ブラックマネー」「経験値（任意）」「カスタムイベント発火」の組み合わせで構成。各報酬テーブルにminmax値、確率、必要条件を持たせ、シナリオごとに参照する。報酬は**サーバーサイドのみで決定・付与**する（チート対策で死活的に重要）。

---

## 4. シナリオ駆動アーキテクチャ詳細

シナリオエンジンが動作の中核です。クライアントの`heist.lua`はシナリオIDを受け取り、シナリオオブジェクトの定義に従って動的にNPCを配置・敵を生成・ミニゲームを呼び出す。コード本体に「敵を3人スポーンする」のような具体的記述は一切なく、「シナリオが指定する敵構成をループでスポーンする」汎用ロジックのみ書く。

これにより、新しいシナリオの追加は**Configファイルへの追記のみで完結**し、コード変更ゼロで運営が独自ストーリーを増やせます。これがこのスクリプトの最大の売りになります。

シナリオ実行のフローは、(1)プレイヤーがロケーションのトリガーゾーンに入る、(2)該当シナリオが取得される、(3)前提条件チェック（クールダウン、必要アイテム、警官数等）、(4)サーバーに開始リクエスト送信、(5)サーバーが承認しシナリオ状態を生成、(6)クライアントがNPC・プロップ・ミニゲームを順次実行、(7)成功/失敗判定、(8)サーバーが報酬付与と指名手配フラグ設定、(9)クリーンアップとイベントフック発火、という流れ。

---

## 5. 闇の指名手配システム詳細

サーバー側の `bounty.lua` がプレイヤーごとの指名手配状態をメモリ（必要ならDB）に保持。状態オブジェクトには、プレイヤーID、指名手配開始時刻、有効期限、残り襲撃回数、襲撃パターンID、最後の襲撃時刻、を持たせる。

サーバーは定期的（例：30秒ごと）に全プレイヤーの指名手配状態をスキャンし、襲撃発生条件（経過時間がランダム間隔を超えた、残り回数あり、プレイヤーがオンライン）が満たされたプレイヤーに対してクライアントへ襲撃トリガーイベントを送信。

クライアントは襲撃トリガーを受けると、(1)プレイヤーの現在地から一定距離離れた視界外座標を計算、(2)襲撃NPCと車両を生成、(3)車両でプレイヤー方向へ走行、(4)一定距離内で停車し降車、(5)攻撃開始、(6)全滅または逃走条件で襲撃終了、という演出を実行する。

NPCの関係性グループ設定で警察を介入させない設計が重要。`SET_RELATIONSHIP_BETWEEN_GROUPS`を使い、襲撃NPCグループとPLAYERグループは敵対、襲撃NPCグループとCOPグループは中立に設定する。

---

## 6. フレームワーク抽象化（Bridge）

ESX/QBCore/Qboxは関数名・データ構造・イベント名がすべて違うので、`bridge/` 内で抽象化する。`_init.lua`で起動時にフレームワーク自動検出、対応するbridgeをロード。

抽象化すべき主要API：プレイヤーデータ取得、所持金確認、所持金加算/減算、アイテム所持確認、アイテム付与/削除、ジョブ取得、警察人数取得、通知表示、ロケール取得。これらすべてを `Bridge.GetPlayerData()` `Bridge.AddMoney()` のような統一インターフェースで呼べるようにする。

クライアント側コードからはフレームワーク固有のグローバル変数（ESX, QBCore等）を**絶対に直接呼ばない**。全てBridge経由。これでメンテ性が劇的に向上する。

**現行 API のスナップショット**: **`docs/BRIDGE_API.md`** に実装観察ベースで一覧（コード変更なしの記録）。更新手順・再スナップショットは **`docs/INSTRUCTIONS_PHASE_1A.md`** を参照。

---

## 7. 注意すべきポイント（実装中に必ず意識すること）

### 7.1 セキュリティ

クライアントから送られるイベントは**全て改ざんされうる**前提で書く。報酬額、シナリオID、対象プレイヤーIDなどをクライアントから受け取ってサーバーがそのまま処理するのは絶対NG。サーバーは必ず「このプレイヤーは本当にトリガーゾーンにいるか」「このシナリオは本当にクールダウンが空いているか」「必要アイテムを実際に持っているか」を**サーバー側のソース・オブ・トゥルース**で検証する。

クライアントには金額や報酬の具体的な値を送信しない（演出に必要な最低限の情報のみ）。お金の計算は100%サーバー側で行う。

### 7.2 パフォーマンス

NPC管理は最重要パフォーマンス課題です。スポーンしたNPC・プロップ・車両は必ずハンドルを保持し、シナリオ終了時/プレイヤー切断時/リソース停止時に確実に削除する。漏れるとサーバーがNPCで埋まる。

`Citizen.CreateThread`の中の `while true do` ループでは必ず `Citizen.Wait()` を入れる。Wait値はループの目的に応じて適切に設定（プレイヤー位置監視は500ms、UI状態監視は1000ms、低頻度処理は5000ms）。常時1msループは絶対作らない。

距離チェックは`#(coord1 - coord2)`（vector3減算+`#`演算子）が最速。`GetDistanceBetweenCoords`より速い。

### 7.3 同期とOneSync

OneSync前提で開発する（FiveMの現在の標準）。NPCをサーバーサイドでスポーンするか、クライアントサイドでローカルNPCとしてスポーンするかの判断が重要。報復NPCは**スポーンしたプレイヤー本人にのみ見える「ローカルNPC」**として扱うのが正解（他プレイヤーに見えると混乱する）。

### 7.4 リソース停止時のクリーンアップ

`onResourceStop`イベントで、進行中の全シナリオ強制終了、全スポーンNPC削除、全プレイヤーの強盗状態クリア、UI閉鎖、を必ず行う。これがないと開発中のリロードのたびにNPCが残ってカオスになる。

### 7.5 互換性とバージョニング

`fxmanifest.lua` の `fx_version 'cerulean'`、`game 'gta5'`、`lua54 'yes'` を明示。依存リソース（ox_lib、ox_target、qb-target等を使うなら）は `dependencies` に明記し、未インストール時は明確なエラーメッセージで起動失敗させる。

### 7.6 ローカライズ

文字列をコードに直書きしないこと。`_L('key_name', param1, param2)` のように関数経由で取得。`locales/ja.lua` と `locales/en.lua` を**同時にメンテ**する。

### 7.7 テスト容易性

デバッグモード（`Config.Debug = true`）で、クールダウン無視、無条件成功、座標可視化、NPCスポーン位置の可視化マーカー、ログ出力強化、を有効化。本番では必ず`false`。

### 7.8 GitHubとCursor運用

`.gitignore`で`*.log`、`.cursor/`内の不要キャッシュ、ローカル設定ファイルを除外。Cursorで作業する場合、`.cursorrules`ファイルをルートに置いて、コーディング規約・命名規則・このDESIGN.mdへの参照を明記しておくと、Cursorの提案精度が上がる。

コミットは機能単位で細かく。「PHASE 1完了」のような大粒度ではなく、「Add bridge layer for ESX」「Implement scenario loader」のような単位で。

---

## 8. PHASE別開発指示

各PHASEを順番に実施。各PHASE完了時にgit tagを切る（`v0.1.0-phase1`等）。

### PHASE 0: プロジェクト初期化（所要1〜2日）

リポジトリのセットアップとベースファイル作成。`fxmanifest.lua`、`README.md`、`LICENSE`、`.gitignore`、`.cursorrules`、`docs/DESIGN.md`（この文書）、`CHANGELOG.md`を作成。ディレクトリ構造を全て先に作っておき、各ディレクトリに`.gitkeep`または最低限のスケルトンファイルを置く。

`.cursorrules`にはコーディング規約（インデント2スペース、命名規則：関数はCamelCase、変数はsnake_case、定数はSCREAMING_SNAKE_CASE）、必ずDESIGN.mdを参照、ハードコード禁止、Bridge経由必須、を明記。

完了基準：FiveMサーバーで`ensure jp-UnderworldBounty`して何もエラーなくロードされる。コンソールに「[jp-UnderworldBounty] Loaded vX.X.X」と表示される。

### PHASE 1: Bridge層とConfig基盤（所要3〜5日）

フレームワーク抽象化レイヤーを最初に作る。`bridge/_init.lua`でフレームワーク自動検出（リソース存在チェック）、`bridge/esx.lua` `bridge/qbcore.lua` `bridge/qbox.lua` `bridge/standalone.lua`に統一インターフェース実装。

最初に実装するBridge API：`Bridge.GetPlayerData(source)`、`Bridge.AddMoney(source, type, amount)`、`Bridge.RemoveMoney`、`Bridge.HasItem(source, item, count)`、`Bridge.AddItem`、`Bridge.RemoveItem`、`Bridge.GetJob(source)`、`Bridge.GetCopCount()`、`Bridge.Notify(source, message, type)`。

`config/config.lua`を完成させ、ロケール読み込みシステム（`_L()`関数）を実装。

完了基準：3つのフレームワーク全てで`/ub_test`コマンドを実行すると、それぞれ正しい方法でプレイヤー名・所持金・ジョブを取得して表示できる。日本語/英語の切替が`Config.Locale`変更で動作する。

### PHASE 2: シナリオエンジンとロケーション管理（所要5〜7日）

シナリオ定義スキーマを確定し、`config/scenarios.lua` `config/locations.lua`に最低3つのサンプルシナリオを定義。シナリオローダー（`server/scenario_loader.lua`）を実装し、起動時に全シナリオをバリデーション（必須フィールドチェック、参照整合性チェック）。

ロケーションのトリガーゾーン検出をクライアントに実装。プレイヤーがゾーンに入るとUIプロンプト「Eキーで賭場に侵入」を表示。

シナリオ開始リクエストをサーバーに送信し、サーバー側で前提条件チェック（クールダウン、必要アイテム、警官数、ブラックリスト）。承認されればシナリオ状態をサーバー側に生成し、クライアントに開始通知。

この段階ではまだNPCはスポーンしない。「シナリオが開始した/終了した」というフレームワークのみ動けばOK。

完了基準：3つのテストシナリオで「ゾーン進入 → プロンプト → 開始リクエスト → 承認 → 5秒後に自動成功 → 報酬付与」のフローが動く。クールダウンが正しく機能する。

### PHASE 3: NPCマネージャと敵スポーン（所要5〜7日）

`client/npc_manager.lua`を実装。シナリオ定義から敵構成を読み取り、指定座標に指定モデル・武器・AI挙動でNPCをスポーン。NPCハンドルを全て管理リストに追加し、シナリオ終了時に確実に削除。

NPCのAI挙動パターン（passive / alert / aggressive / boss）を実装。aggressiveなら即時攻撃、alertなら音/視認で攻撃開始、bossは特殊行動（仲間呼び寄せ、退避等）。

敵を全滅させると「シナリオ目標達成」フラグが立つロジックを実装。報酬計算をサーバー側で実行。

完了基準：賭場に入ると敵NPCが配置され、戦闘して全滅させると報酬がもらえる。シナリオ強制終了（`/ub_cancel`コマンド）で全NPCが綺麗に消える。リソース再起動でも残骸が残らない。

### PHASE 4: 闇の指名手配システム（所要7〜10日）

**状態遷移の厳密仕様**: `docs/RETALIATION_FSM.md`（8 状態 FSM、遷移マトリクス、Mermaid、Config 紐付け、エラーハンドリング、実装チェックリスト）。プレイヤー視点の対応シーンは `docs/PLAYER_FLOW.md` の #21〜#28。

このプロジェクトの最大の差別化機能なので時間をかける。

`server/bounty.lua`でプレイヤーごとの指名手配状態を管理。強盗成功時に`SetBounty(playerId, scenarioId, retaliationPatternId)`を呼び、有効期限・残り回数・襲撃間隔を設定。

サーバー側で定期スキャン（30秒間隔）し、襲撃発生条件を満たすプレイヤーにクライアントイベント送信。

クライアントの`retaliation.lua`で襲撃演出を実装。視界外座標計算、車両+NPCスポーン、車両走行、停車、降車、攻撃開始、戦闘終了判定、クリーンアップ。

NPCの関係性設定で警察非介入を実現。襲撃NPCのドロップアイテム実装。

UI表示：強盗成功時の「闇の指名手配」通知、HUD上の常駐アイコン、襲撃直前のフレーバー通知（「視線を感じる…」）。

完了基準：賭場強盗成功 → 通知 → HUDアイコン点灯 → 数分後（テスト用に短く設定）に黒SUVが接近 → 武装NPC降車 → 戦闘 → 全滅または死亡で襲撃終了 → 残り回数があれば再度発生、なければ指名手配解除。

### PHASE 5: ミニゲーム統合とインタラクション（所要3〜5日）

賭場侵入時のミニゲーム（鍵開け/ハッキング）を実装。既存ライブラリ（ox_lib のskillcheck等）を使うか、シンプルなNUIミニゲームを自作。シナリオ定義でミニゲームの種類と難易度を指定可能に。

ボスNPCを「制圧」して情報を取るインタラクション、金庫を開けるインタラクション、現金袋を持ち運ぶインタラクション（移動速度低下＋武器使用不可）。

完了基準：シナリオに定義されたミニゲームが順次発動し、成功/失敗で分岐する。

### PHASE 6: UI/UXとローカライズ完成（所要3〜5日）

NUI（HTML/CSS/JS）で、闇の指名手配通知、HUDアイコン、シナリオ進行状況表示、報酬獲得画面、を完成。Noto Sans JPフォント埋め込み。和風デザイン（赤黒ベース、家紋風アイコン）を採用。画像素材を自作（FigmaかPhotoshop）。

`locales/ja.lua` `locales/en.lua` を完成。全プレイヤー向け文字列が両言語で網羅されているか監査。

完了基準：日本語/英語切替で全UIが正しく表示。和風デザインが完成。

### PHASE 7: イベントフック公開とドキュメント整備（所要3〜5日）

`server/events.lua`でカスタムイベントを公開。`UnderworldBounty:onHeistStart`、`onHeistComplete`、`onHeistFail`、`onBountyTriggered`、`onRetaliationStart`、`onRetaliationEnd`、`onBountyCleared`を全主要アクションで発火。

`docs/EVENT_HOOKS.md`に各イベントのペイロード仕様を完全記述。サンプルコード（Discord通知連携、独自経済連携）を添付。

`docs/CONFIG_GUIDE.md` `docs/SCENARIO_GUIDE.md`を完成。「新しい賭場の追加方法」をステップバイステップで解説。

`README.md`を日本語+英語で完成。スクリーンショット、動画リンク、インストール手順、クイックスタート、対応フレームワーク、ライセンス情報を含む。

完了基準：第三者が`README.md`と`docs/`だけ読んでインストール・新シナリオ追加・他スクリプト連携ができる。

### PHASE 8: テスト・バランス調整・リリース準備（所要5〜7日）

3フレームワーク全てで全機能テスト。長時間プレイテスト（NPC残骸チェック、メモリリークチェック）。バランス調整（報酬額、敵強さ、襲撃頻度）。

既知バグ一覧と回避策を`CHANGELOG.md`に記載。デモ動画撮影（OBS、30秒〜2分）。Cfx.re Releasesフォーラムの投稿テンプレート作成。

`v1.0.0`タグ付与。GitHub Releaseページに動画・スクリーンショット・zipダウンロード添付。Cfx.reフォーラムに投稿。

完了基準：v1.0.0が公開され、Cfx.reフォーラムに投稿済み、GitHubリポジトリのREADMEが完成、3フレームワークで動作確認済み。

### PHASE 9（任意）: 拡張機能と継続メンテ

公開後のフィードバックを元にv1.1、v1.2と継続改善。候補機能：情報屋NPCシステム（賭場の場所を購入）、上納金システム（指名手配を消せる裏取引）、ヤクザ抗争システム（複数組織の関係性）、評判システム連携、新シナリオパック追加、Discord Bot連携サンプル。

---

## 9. 開発開始時の最初のアクション

PHASE 0を開始する前に、以下を実施してください。

このDESIGN.mdをそのまま `H:\CURSOR\Dev\jp-UnderworldBounty\docs\DESIGN.md` として保存。GitHubに新規リポジトリ（または既存`fivem-mods_ja`内のサブディレクトリ）として初期化。`.cursorrules`ファイルをルートに作成し、「すべての実装で `docs/DESIGN.md` を参照すること」「ハードコード禁止」「Bridge経由必須」「日本語コメント可、英語コメントも可」を明記。

その上でCursorに「PHASE 0を実施して」と指示すれば、DESIGN.mdを読んで適切に進めてくれるはずです。

---

## 10. 想定スケジュール総括

PHASE 0〜8を全て完遂すると、ソロ開発で**約6〜10週間**（週10〜20時間ペース）が現実的な見積もり。最初の動くデモ（PHASE 4完了時点）までは**3〜4週間**。

途中で詰まるであろうポイントとしては、Bridge層の3フレームワーク対応（PHASE 1）、NPCのライフサイクル管理（PHASE 3）、報復NPCの演出調整（PHASE 4）が経験上ハマりやすいので、ここで時間がかかっても焦らない。

---

## 付録: 運営・開発ドキュメント

- **プレイヤー体験フロー（時系列 + 開発者設置項目）**: `docs/PLAYER_FLOW.md`  
- **報復システム FSM（PHASE 4 実装の正本）**: `docs/RETALIATION_FSM.md`  
- **サーバー↔クライアントシーケンス（payload・Mermaid）**: `docs/SEQUENCE_DIAGRAMS.md`  
- **シナリオ設計テンプレ（運営が空欄埋め）**: `docs/SCENARIO_TEMPLATE.md`  
- **設定・シナリオ追加・イベント**: `docs/CONFIG_GUIDE.md`、`docs/SCENARIO_GUIDE.md`、`docs/EVENT_HOOKS.md`  
- **PHASE 1a（Bridge API スナップショット・Cursor 向け手順）**: `docs/INSTRUCTIONS_PHASE_1A.md` / 成果物 `docs/BRIDGE_API.md`  
- **PHASE 1a フォローアップ（要確認確定・保留コメント・§9 整理）**: `docs/INSTRUCTIONS_PHASE_1A_FOLLOWUP.md`  
- **PHASE 1b（§9 改善候補の優先付け・Issue 化ドキュメント）**: `docs/INSTRUCTIONS_PHASE_1B.md`（成果物 `docs/BRIDGE_API_IMPROVEMENTS.md` は PHASE 1b 実行後）
