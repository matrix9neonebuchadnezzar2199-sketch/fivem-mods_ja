# MERIDIAN-9 / Project JANUS（jp-meridian9）

**MERIDIAN-9** は、FiveM 上で動作する **次元探査・エクストラクション型ミッション** の骨格リソースです。  
現段階（v0.1.0-jp）は **設定・FW 検出・NUI・oxmysql（契約/統計/ログ）・セッション・契約キャッシュ／運営コマンド** までを含む **M0〜M1 スキャフォールド** であり、任務ロジック本体はロードマップ（`docs/milestones.md`）に従い順次実装します。

**ESX / QBCore / Qbox は必須にしません。** 未導入環境では Standalone として起動し、報酬は `Config.Reward.standaloneMoneyEvent` または手動付与案内にフォールバックします。  
**永続化のため oxmysql は必須**です。対話 UI と NPC ターゲットのため **ox_lib / ox_target も必須**です（`fxmanifest.lua` の `dependencies` に記載）。MySQL / MariaDB に `sql/install.sql` を手動適用してください。

---

## 前提条件

- FiveM サーバー（`fx_version` `cerulean` 以上）
- **oxmysql**（必須）：DB 接続に使用。未導入の場合は [overextended/oxmysql](https://github.com/overextended/oxmysql) を `resources` に配置し、`server.cfg` で `ensure oxmysql` を **jp-meridian9 より前**に記述すること。
- **ox_lib**（必須）：通知・コンテキストメニュー・`lib.callback`。 [overextended/ox_lib](https://github.com/overextended/ox_lib) を配置し、`ensure ox_lib` を **jp-meridian9 より前**に記述。
- **ox_target**（必須）：NPC への視線ターゲット。 [overextended/ox_target](https://github.com/overextended/ox_target) を配置し、`ensure ox_target` を **jp-meridian9 より前**に記述（`ox_lib` の後が無難）。
- MySQL 5.7.8+ または MariaDB 10.3+（`JSON` 型利用のため）
- 初回導入時に **`sql/install.sql`** を対象データベースに流し込むこと。

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
2. **oxmysql / ox_lib / ox_target** を導入済みであること（各公式リポジトリを参照）。`server.cfg` の例（順序重要）:

   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure ox_target
   ensure jp-meridian9
   ```

3. `server.cfg` に `ensure jp-meridian9` を上記の **後**に追加（未記載なら追記）。
4. サーバーで `refresh` のあと `ensure jp-meridian9`（またはサーバー再起動）。
5. クライアント接続後、F8 に `[jp-meridian9] resource loaded` が出ることを確認。

**フレームワーク依存はありません。** ヴェガ対話は **ox_lib**（通知・メニュー）、NPC 操作は **ox_target** を使用。

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
| `Config.NPC` | ヴェガ NPC のモデル・座標・シナリオ |
| `Config.Gate` / `Config.SiteNine` | 転送・天候・時刻演出 |
| `Config.Party` / `Config.Mission` | 人数・時間・バケット帯・**spawnPoint / returnPoint**（セッション転送） |
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
