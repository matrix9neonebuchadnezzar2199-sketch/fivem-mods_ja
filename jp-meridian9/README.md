# MERIDIAN-9 / Project JANUS（jp-meridian9）

**MERIDIAN-9** は、FiveM 上で動作する **次元探査・エクストラクション型ミッション** の骨格リソースです。  
現段階（v0.1.0-jp）は **設定・FW 検出・NUI・oxmysql（契約/統計/ログ）・セッション・契約キャッシュ／運営コマンド・ヴェガ対話・パーティ編成（ゲート〜セッション転送）** までを含む **M0〜M3 入口** であり、任務内の戦闘・ルート等はロードマップ（`docs/milestones.md`）に従い順次実装します。

**ESX / QBCore / Qbox は必須にしません。** 未導入環境では Standalone として起動し、報酬は `Config.Reward.standaloneMoneyEvent` または手動付与案内にフォールバックします。  
**永続化のため oxmysql は必須**です。**ox_lib**（`lib.alertDialog` で台詞、`lib.notify` / `lib.callback`）、任務中ルート等の **ox_target** も必須です（`fxmanifest.lua` の `dependencies` に記載）。**ヴェガの選択肢メニューは本リソースの NUI**（`html/vega_context.*`・拡大率は `Config.NPC.contextMenuScale`）。**会話開始は E キー＋`lib.showTextUI`**（INSTRUCTION-022）で、ヴェガへの `ox_target` は使用しません。MySQL / MariaDB には **`sql/install.sql` を手動適用を推奨**（下記のとおり、契約テーブル未作成時は起動時に自動適用も試みます）。

---

## 前提条件

- FiveM サーバー（`fx_version` `cerulean` 以上）
- **oxmysql**（必須）：DB 接続に使用。未導入の場合は [overextended/oxmysql](https://github.com/overextended/oxmysql) を `resources` に配置し、`server.cfg` で `ensure oxmysql` を **jp-meridian9 より前**に記述すること。
- **ox_lib**（必須）：通知・`lib.alertDialog`・`lib.callback`、パーティ編成などの **`lib.registerContext` / `lib.showContext`**（ヴェガの選択肢は自前 NUI のためここには含まれない）。 [overextended/ox_lib](https://github.com/overextended/ox_lib) を配置し、`ensure ox_lib` を **jp-meridian9 より前**に記述。
- **ox_target**（必須）：任務中ルート等のインタラクション。 [overextended/ox_target](https://github.com/overextended/ox_target) を配置し、`ensure ox_target` を **jp-meridian9 より前**に記述（`ox_lib` の後が無難）。NPC 受注は E キー方式のため **ヴェガへの ox_target は不要**。
- **mnr_cayo**（サイト・ナイン Cayo 運用で必須）：Cayo Perico IPL 常時ロード。 [Monarch-Devs/mnr_cayo](https://github.com/Monarch-Devs/mnr_cayo) を配置し、`ensure mnr_cayo` を **jp-meridian9 より前**に記述。`jp-meridian9` の `dependencies` には含めない（起動順は `server.cfg` で担保）。
- **bob74_ipl**（**不要**）：INSTRUCTION-020 v7 以降、`jp-meridian9` は **`bob74_ipl` を依存に含めない**（`mnr_cayo` と重複ロードでクライアントクラッシュする前例のため）。北ヤンクトン検証用に別途入れる場合は自己責任で起動順を調整すること。
- MySQL 5.7.8+ または MariaDB 10.3+（`JSON` 型利用のため）
- 初回導入時に **`sql/install.sql`** を対象データベースに流し込むことを推奨。`mrd9_contracts` が無い状態で起動した場合、サーバが **`sql/install.sql` 全文を自動実行**してスキーマ作成を試みます（失敗時は手動適用）。

### DB スキーマ初期化

```bash
mysql -u <ユーザー> -p <DB名> < sql/install.sql
```

実行後、`mrd9_contracts` / `mrd9_stats` / `mrd9_mission_logs` / `mrd9_loot_logs` / `mrd9_fiction_events` / `mrd9_result_logs` など `install.sql` 内のテーブルが作成されます。

---

## 特徴

- **Standalone（フレームワーク）** … ESX / QB / Qbox は **必須にしない**。`dependencies` にフレームワークは書かない。
- **oxmysql 必須** … 契約・統計・ミッション履歴の永続化のため **`dependencies { 'oxmysql', 'ox_lib', 'ox_target' }`** を採用する（フレームワークではなく **Overextended ライブラリ群**）。NPC 受注は E キー、ルート等は `ox_target`。
- **ox_lib / ox_target 必須** … ヴェガ台詞は `lib.alertDialog`、**選択肢メニューは自前 NUI**（`Config.NPC.contextMenuScale` で拡大率。ox_lib の `registerContext` はサイズ指定不可のため）。通知は `lib.notify`、任務中ルートは `ox_target`。NPC への会話開始は **E キー**（`Config.NPC.interact`）。方針は `docs/FORMAL_POLICIES.md`（INSTRUCTION-009）および `docs/INSTRUCTION-022.1（NPC会話Eキー化＆ポータル演出化）.md`（ファイル名は履歴のためそのまま。**ポータル演出は撤去済み**）を参照。
- **ソフト検出** … `server/framework.lua` が ESX / QB / Qbox を検出し、通貨付与を切り替え
- **運営者向け `config.lua` 集約** … 座標・難易度・報酬方式を 1 ファイルで調整可能（各項目に日本語コメント）
- **イベント命名** … `jp-meridian9:アクション名`
- **コマンド接頭辞** … `/m9_` 系（`config.lua` の `Config.Commands` で名前変更可）

---

## 導入

1. 本フォルダを `resources` 配下に配置する（例: `resources/[jp-mods]/jp-meridian9/`）。
2. **oxmysql / ox_lib / ox_target / mnr_cayo** を導入済みであること（サイト・ナインを Cayo で運用する前提）。`server.cfg` の例（順序重要）:

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure ox_target
   ensure mnr_cayo
   ensure jp-meridian9
   ```

3. `server.cfg` に `ensure jp-meridian9` を上記の **後**に追加（未記載なら追記）。
4. サーバーで `refresh` のあと `ensure jp-meridian9`（またはサーバー再起動）。
5. クライアント接続後、F8 に `[jp-meridian9] resource loaded` が出ることを確認。

### NPC受注

NPC に近づき、画面下部に表示される `[E] 話しかける` のプロンプトが出た状態で **E キー**を押すと任務受注メニューが開きます。

**フレームワーク依存はありません。** ヴェガ台詞は **ox_lib** の `lib.alertDialog`、選択肢は **本リソース NUI**（`vega_context`）、通知は **`lib.notify`**。NPC に近づき **E キー**で会話を開始します。任務中のルート取得などは引き続き **ox_target** を使用します。

---

## サイト・ナイン MAP 導入手順（INSTRUCTION-020 v7 / Cayo Perico）

任務地「サイト・ナイン」は **GTA V バニラ同梱の Cayo Perico**（GTA Online Heist DLC ステージ）を、**専用 MAP ローダー `mnr_cayo`** で常時表示する設計です。`jp-meridian9` 側では MAP 切替系ネイティブ（`SetIslandEnabled` / `EnableMpDlcMaps`）は **一切呼びません**（v3 でクライアント環境破壊の前例があったため）。

### 仕組み

- `mnr_cayo` がクライアントログイン時に Cayo Perico の IPL を一度だけロード
- 海上に Cayo Perico が **常時遠景表示**（地続きアクセス不可、海上独立島）
- ヴェガ事務所周辺の LS は **正常表示**、ESC マップも崩壊しない
- 任務 bucket に転送されたメンバーは Cayo Perico へワープして戦闘（演出: 雷雨・夜・青みフィルター）
- bucket 0 のプレイヤーも海上に島を視認できるが、ゲート転送以外で物理アクセス不可

### 必須リソースの取得

```powershell
cd "<server_resources>\[gamemodes]\[maps]"
# Cayo Perico IPL ローダー（必須・サイト・ナイン MAP の本体）
git clone https://github.com/Monarch-Devs/mnr_cayo.git mnr_cayo
```

`server.cfg` に **`ensure jp-meridian9` より前**に追加（`oxmysql` / `ox_lib` / `ox_target` の後で可）：

```
ensure mnr_cayo
ensure jp-meridian9
```

北ヤンクトン（`island = 'northYankton'`）検証用に `bob74_ipl` を入れる場合は **jp-meridian9 と同時 ensure しない**こと（重複 IPL でクラッシュする前例あり）。

`sv_enforceGameBuild` は **2189 以上**（推奨 3258 以上）。Cayo Perico DLC を含むビルド要件。

### サイト・ナイン演出のカスタマイズ

`config.lua` の `Config.SiteNine`:

| キー | 既定 | 説明 |
|---|---|---|
| `weather` | `'THUNDER'` | 天候（雷雨・熱帯ホラー） |
| `timeHour` | `22` | 時刻固定（夜 10 時） |
| `timeFreeze` | `true` | 時間進行停止 |
| `timecycleModifier` | `'phone_cam11'` | 青み・コントラストポストエフェクト |
| `timecycleStrength` | `0.85` | 強度 |
| `blackout` | `false` | 街灯消灯（Cayo Perico は元から街灯少ないので不要） |
| `island` | `'cayoperico'` | `'cayoperico'` / `'northYankton'` / `'none'` で MAP 切替 |
| `iplLoadWaitMs` | `1500` | 島ロード後の待機（ms） |

### デバッグコマンド（F8）

| コマンド | 動作 |
|---|---|
| `m9_cayo on` | Cayo Perico を有効化（北ヤンクトン排他 OFF） |
| `m9_cayo off` | 無効化 |
| `m9_cayo tp` | メインビーチへテレポート（フェード + ロード待ち） |
| `m9_cayo tp <x> <y> <z>` | 任意座標へテレポート |
| `m9_cayo coords` | 現在座標を `vector4(...)` 形式で chat / F8 に表示 |
| `m9_cayo back` | ヴェガ事務所へ戻る |
| `m9_ny *` | 同様の北ヤンクトン用（検証期間中残置） |

詳細は `docs/INSTRUCTION-020（サイト・ナイン MAP 導入）.md` を参照。

---

## パーティ編成

契約済みプレイヤーがヴェガの「ゲートを起動してくれ」から **ソロ** または **パーティ（最大 5 人）** でサイト・ナインへ入るためのフローです。

### 流れ

1. リーダーがゲートメニューで「パーティを編成する」を選ぶと `partyCreate` が走り、パーティ編成メニューが開きます。
2. リーダーが **10m 以内**の契約済みプレイヤーを招待（サーバー側で距離・契約・セッション未所属を再検証）。
3. 被招待者に `lib.alertDialog`（承諾／拒否）。**30 秒**でタイムアウト。
4. リーダーが **未処理の招待がない状態**で「ゲートを開いて出発」→ `MRD9.Session.Create` → `TransferIn` で全員同一バケットへ転送。
5. ソロはゲートメニュー「ソロで行く」（`Config.Party.allowSoloMission == true` のときのみ表示）で `partyCreate` の直後に `partyConfirm` を連続実行。

### `Config.Party`

| キー | 既定 | 説明 |
|------|------|------|
| `maxMembers` | `5` | 最大人数 |
| `minMembers` | `1` | 最小人数（ソロ可） |
| `inviteRange` | `10.0` | 招待可能距離（m） |
| `inviteTimeoutSeconds` | `30` | 招待の有効秒数 |
| `allowSoloMission` | `true` | ソロでゲート確定を許可 |
| `autoPromoteOnLeaderLeave` | `true` | 編成中にリーダーが落ちた場合、先頭メンバーへ自動譲渡 |

### デバッグ（`Config.Debug = true`）

| コマンド | 内容 |
| -------- | ---- |
| `/m9_party_status` | 自分の所属パーティをチャットに表示 |
| `/m9_party_list` | 全パーティ一覧（**ACE `jp-meridian9.admin` 必須**。無権限時は無反応） |

---

## サードパーティライセンス

このリソースは以下のサードパーティコード／ライブラリを含みます。

| プロジェクト | ライセンス | 用途 |
|-------------|------------|------|
| TP-Advanced-Zombies | Apache 2.0 | ゾンビ AI・スポーン制御の**派生実装**（`server/arena/spawn.lua`, `client/arena.lua`） |
| ox_lib | MIT | UI（`lib.alertDialog` / `lib.notify` / `lib.callback` / パーティ等の `registerContext`）。ヴェガ選択肢は本 MOD NUI |
| ox_target | MIT | 任務中ルート等のインタラクション（NPC 受注は E キー方式） |
| oxmysql | MIT | データベース |

詳細は **`LICENSE-APACHE-2.0`** および **`NOTICE`** を参照してください。派生ファイルの改変内容は各ファイル先頭のヘッダーに記載しています。

### OneSync（推奨）

ゾンビのネットワーク同期・ルーティングバケット連携は **OneSync** 前提です。`server.cfg` で `set onesync on`（または環境に応じた OneSync 有効化）を推奨します。

---

## コマンド

| コマンド | 内容 |
| -------- | ---- |
| `/m9_stats` | 自分の統計（未実装・プレースホルダ。`Config.Commands.stats` で変更可） |
| `/m9_test_bucket` | デバッグ用バケット転送（**`Config.Debug == true` のときのみ**登録） |
| `/m9_sign_me` | DB 契約テスト（**`Config.Debug == true` のみ**。`MRD9.Contract.Sign`） |
| `/m9_check_contract` | 契約行の表示（**Debug のみ**） |
| `/m9_my_stats` | `mrd9_stats` の表示（**Debug のみ**） |

### デバッグコマンド（`Config.Debug = true` 時のみ）

| コマンド | 内容 |
| -------- | ---- |
| `/m9_test_session` | 1 人パーティのテストセッション作成 → 約 1 秒後にバケット転送＋スポーン |
| `/m9_test_extract` | 現在のセッションから脱出（バケット 0・帰還座標） |
| `/m9_list_sessions` | アクティブセッション一覧（**restricted**・コンソール `source=0` からも可） |
| `/m9_party_status` | 自分のパーティ状態（チャット表示） |
| `/m9_party_list` | 全パーティ一覧（**ACE 必須**・無反応可） |

### 運営者向けコマンド（要 ACE: `jp-meridian9.admin`）

| コマンド | 用途 |
| -------- | ---- |
| `/m9_admin_sign <playerId>` | 対象プレイヤーを強制契約 |
| `/m9_admin_suspend <playerId> <reason>` | 契約サスペンド |
| `/m9_admin_terminate <playerId> <reason>` | 契約解除 |
| `/m9_admin_check <playerId>` | 契約・統計の確認 |
| `/m9_admin_list [active\|suspended\|terminated]` | 契約者一覧（件数上限は `Config.Admin.contractListLimit`） |

予定（README 追記予定）:

- `/m9_call` … 任務呼び出し・ゲート連携（実装後に表を更新）

---

## 設定

主な項目は `config.lua` 内のセクション見出しに従ってください。

| セクション | 内容 |
| ---------- | ---- |
| `Config.NPC` | ヴェガ NPC のモデル・座標・シナリオ・**ブリップ**（`blip.*`）、**E キー会話**（`interact`）、**選択肢メニュー拡大**（`contextMenuScale`）、サーバ検証用（`points`） |
| `Config.Gate` / `Config.SiteNine` | 転送・天候・時刻演出 |
| `Config.Party` | 招待距離・タイムアウト・ソロ可否・リーダー自動譲渡（**ゲート／パーティ編成**） |
| `Config.Mission` | 時間・バケット帯・**spawnPoint / returnPoint**（セッション転送） |
| `Config.Zombies` / `Config.Items` | 敵ウェーブと回収アイテム定義 |
| `Config.Reward` | `paymentType` / `standaloneMoneyEvent` |
| `Config.HUD` / `Config.Commands` | HUD 周期・コマンド名 |
| `Config.Admin` | 運営 ACE 名・`/m9_admin_list` 件数上限 |

---

## 運営権限の設定

運営向けコマンド（`/m9_admin_*`）は **`Config.Admin.aceName`（既定: `jp-meridian9.admin`）** が必要です。`server.cfg` の例:

```cfg
# MERIDIAN-9 運営権限の付与例（license は実値に置換）
add_ace identifier.license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx jp-meridian9.admin allow
```

複数人にまとめて付与する例:

```cfg
add_principal identifier.license:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa group.m9admin
add_principal identifier.license:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb group.m9admin
add_ace group.m9admin jp-meridian9.admin allow
```

---

## プロジェクト構成

```
jp-meridian9/
├── fxmanifest.lua
├── README.md
├── LICENSE
├── config.lua
├── locales/ja.lua
├── shared/utils.lua
├── client/          … クライアント各モジュール（HUD・ヴェガ `vega_context`・任務クライアント等）
├── server/          … サーバー（framework.lua で FW 検出）
├── html/            … NUI（Phase-C HUD・リザルト・`vega_context` 選択肢 UI）
├── sql/install.sql  … DB スキーマ（手動適用）
├── image/           … 素材保管（ビルド用コピー元）
└── docs/            … 設計・マイルストーン・台本・`FORMAL_POLICIES.md`・`CREDITS.md`
```

---

## トラブルシューティング

| 現象 | 確認 |
| ---- | ---- |
| NUI が真っ白 | `fxmanifest.lua` の `files` に `html/*`（`vega_context.css` / `vega_context.js` 含む）と `html/assets/*` が含まれているか |
| ヴェガメニュー後にマウスが残る | `restart jp-meridian9` で `SetNuiFocus` が外れるか確認。ESC／背景クリックで閉じる実装あり |
| Linux 本番で画像が出ない | パス・拡張子の大文字小文字、`files` 列挙漏れ |
| Standalone で報酬が入らない | 想定どおり。`Config.Reward.standaloneMoneyEvent` を設定するか手動付与 |
| フレームワーク検出が想定と違う | 起動順・リソース名（`es_extended` / `qb-core` / `qbx_core`）を確認 |

---

## 開発運用（本 MOD 専用）

- **開発日記**：リポジトリ既定に従い **`jp-meridian9/docs/YYYY-MM-DD_開発日記.html`**（UTF-8・BOM なし）。MOD 直下の旧 `.md` 日記は履歴として残置。
- **正式方針・例外規約・INSTRUCTION 前提**：`docs/FORMAL_POLICIES.md` を参照（日記配置、グローバル許容、`fxmanifest` 補足、画像暫定、INSTRUCTION-006/019 メモ）。
- **任務リザルト（サブフェーズ A）**：DB に `mrd9_result_logs` を適用（`sql/install.sql`）。`ox_inventory` 運用では小切手アイテム `mrd9_credit` を `data/items.lua` 等に定義する。定義しない・standalone のみの場合は `config.lua` の `Config.Result.directCashout = true` で即現金のみ。小切手換金はゲーム内 `/m9_cashout`（暫定、ox_inventory 時のみ有効）。

---

## 作者・バージョン

- **作者:** JP-Mods  
- **バージョン:** `fxmanifest.lua` の `version` フィールドと同期（現在 `0.1.0-jp`）  
- **ライセンス:** MIT（`LICENSE` 参照）
