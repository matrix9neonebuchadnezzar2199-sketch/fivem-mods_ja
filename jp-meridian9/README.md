# MERIDIAN-9 / Project JANUS（jp-meridian9）

**MERIDIAN-9** は、FiveM 上で動作する **次元探査・エクストラクション型ミッション** の骨格リソースです。  
現段階（v0.1.0-jp）は **設定・FW 検出・NUI・oxmysql（契約/統計/ログ）・セッション・契約キャッシュ／運営コマンド・ヴェガ対話・パーティ編成（ゲート〜セッション転送）** までを含む **M0〜M3 入口** であり、任務内の戦闘・ルート等はロードマップ（`docs/milestones.md`）に従い順次実装します。

**ESX / QBCore / Qbox は必須にしません。** 未導入環境では Standalone として起動し、報酬は `Config.Reward.standaloneMoneyEvent` または手動付与案内にフォールバックします。  
**永続化のため oxmysql は必須**です。対話 UI と NPC ターゲットのため **ox_lib / ox_target も必須**です（`fxmanifest.lua` の `dependencies` に記載）。MySQL / MariaDB に `sql/install.sql` を手動適用してください。

---

## 前提条件

- FiveM サーバー（`fx_version` `cerulean` 以上）
- **oxmysql**（必須）：DB 接続に使用。未導入の場合は [overextended/oxmysql](https://github.com/overextended/oxmysql) を `resources` に配置し、`server.cfg` で `ensure oxmysql` を **jp-meridian9 より前**に記述すること。
- **ox_lib**（必須）：通知・コンテキストメニュー・`lib.callback`。 [overextended/ox_lib](https://github.com/overextended/ox_lib) を配置し、`ensure ox_lib` を **jp-meridian9 より前**に記述。
- **ox_target**（必須）：NPC への視線ターゲット。 [overextended/ox_target](https://github.com/overextended/ox_target) を配置し、`ensure ox_target` を **jp-meridian9 より前**に記述（`ox_lib` の後が無難）。
- **bob74_ipl**（必須）：北ヤンクトン IPL ロード基盤（INSTRUCTION-020）。 [Bob74/bob74_ipl](https://github.com/Bob74/bob74_ipl) を `resources/[gamemodes]/[maps]/bob74_ipl/` 等に配置し、`ensure bob74_ipl` を **jp-meridian9 より前**に記述。
- MySQL 5.7.8+ または MariaDB 10.3+（`JSON` 型利用のため）
- 初回導入時に **`sql/install.sql`** を対象データベースに流し込むこと（v0.1.0-jp 以降は **`mrd9_contracts` 未作成時に起動時自動適用**）。

### DB スキーマ初期化

```bash
mysql -u <ユーザー> -p <DB名> < sql/install.sql
```

実行後、`mrd9_contracts` / `mrd9_stats` / `mrd9_mission_logs` の 3 テーブルが作成されます。

---

## 特徴

- **Standalone（フレームワーク）** … ESX / QB / Qbox は **必須にしない**。`dependencies` にフレームワークは書かない。
- **oxmysql 必須** … 契約・統計・ミッション履歴の永続化のため **`dependencies { 'oxmysql', 'ox_lib', 'ox_target' }`** を採用する（フレームワークではなく **Overextended ライブラリ群**）。
- **ox_lib / ox_target 必須** … ヴェガ NPC の対話（`lib.notify`・context menu）とターゲット。方針は `docs/FORMAL_POLICIES.md`（INSTRUCTION-009）を参照。
- **ソフト検出** … `server/framework.lua` が ESX / QB / Qbox を検出し、通貨付与を切り替え
- **運営者向け `config.lua` 集約** … 座標・難易度・報酬方式を 1 ファイルで調整可能（各項目に日本語コメント）
- **イベント命名** … `jp-meridian9:アクション名`
- **コマンド接頭辞** … `/m9_` 系（`config.lua` の `Config.Commands` で名前変更可）

---

## 導入

1. 本フォルダを `resources` 配下に配置する（例: `resources/[jp-mods]/jp-meridian9/`）。
2. **oxmysql / ox_lib / ox_target / bob74_ipl** を導入済みであること。`server.cfg` の例（順序重要）:

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure ox_target
   ensure bob74_ipl
   ensure jp-meridian9
   ```

3. `server.cfg` に `ensure jp-meridian9` を上記の **後**に追加（未記載なら追記）。
4. サーバーで `refresh` のあと `ensure jp-meridian9`（またはサーバー再起動）。
5. クライアント接続後、F8 に `[jp-meridian9] resource loaded` が出ることを確認。

**フレームワーク依存はありません。** ヴェガ対話は **ox_lib**（通知・メニュー）、NPC 操作は **ox_target** を使用。

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
# 1. Cayo Perico IPL ローダー（必須・MAP の本体）
git clone https://github.com/Monarch-Devs/mnr_cayo.git mnr_cayo
# 2. bob74_ipl（旧 v2 北ヤンクトン互換用、現運用では未使用だが jp-meridian9 dependencies で参照）
git clone https://github.com/Bob74/bob74_ipl.git bob74_ipl
```

`server.cfg` に **`ensure jp-meridian9` より前**に追加：

```
ensure mnr_cayo
ensure bob74_ipl
ensure jp-meridian9
```

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
| TP-Advanced-Zombies | Apache 2.0 | ゾンビ AI・スポーン制御の**派生実装**（`server/arena/spawn.lua`, `client/arena/zombie_ai.lua`） |
| ox_lib | MIT | UI / `lib.callback` |
| ox_target | MIT | NPC インタラクション |
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
| `Config.NPC` | ヴェガ NPC のモデル・座標・シナリオ・**ブリップ**（`blip.*`） |
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
├── client/          … クライアント各モジュール（プレースホルダ含む）
├── server/          … サーバー（framework.lua で FW 検出）
├── html/            … NUI（ロゴ・将来 HUD）
├── sql/install.sql  … DB スキーマ（手動適用）
├── image/           … 素材保管（ビルド用コピー元）
└── docs/            … 設計・マイルストーン・台本・`FORMAL_POLICIES.md`・`CREDITS.md`
```

---

## トラブルシューティング

| 現象 | 確認 |
| ---- | ---- |
| NUI が真っ白 | `fxmanifest.lua` の `files` に `html/*` と `html/assets/*` が含まれているか |
| Linux 本番で画像が出ない | パス・拡張子の大文字小文字、`files` 列挙漏れ |
| Standalone で報酬が入らない | 想定どおり。`Config.Reward.standaloneMoneyEvent` を設定するか手動付与 |
| フレームワーク検出が想定と違う | 起動順・リソース名（`es_extended` / `qb-core` / `qbx_core`）を確認 |

---

## 開発運用（本 MOD 専用）

- **開発日記**：`jp-meridian9/YYYY-MM-DD_開発日記.md`（MOD 直下・Markdown）。リポジトリ既定の `docs/*.html` 日記は本 MOD では使わない。
- **正式方針・例外規約・INSTRUCTION 前提**：`docs/FORMAL_POLICIES.md` を参照（日記配置、グローバル許容、`fxmanifest` 補足、画像暫定、INSTRUCTION-006/019 メモ）。

---

## 作者・バージョン

- **作者:** JP-Mods  
- **バージョン:** `fxmanifest.lua` の `version` フィールドと同期（現在 `0.1.0-jp`）  
- **ライセンス:** MIT（`LICENSE` 参照）
