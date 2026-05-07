# 【作業指示書】jp-renewedbanking2 — Renewed-Banking 完全日本語化プロジェクト

**サーバーで ensure する名前は `Renewed-Banking`（モノレポ上のフォルダ名 `jp-renewedbanking2` ではありません）。`server.cfg` に `ensure jp-renewedbanking2` と書かないこと。**

## 0. プロジェクト概要

本プロジェクトは、FiveM 用のバンキングリソース **Renewed-Banking**（uShifty / Renewed-Scripts 製、CC BY-NC-SA 4.0 ライセンス）の **完全日本語化派生版** を作成し、初心者ユーザーでも扱いやすいよう UI に使い方ヘルプ機能を追加することを目的とする。

- **作業ディレクトリ**: `F:\Cursor\fivem-mods_ja\jp-renewedbanking2`（本リポジトリ `fivem-mods_ja` のサブディレクトリ）
- **公開先**: https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja （`jp-renewedbanking2/` サブディレクトリ）
- **派生元**: https://github.com/Renewed-Scripts/Renewed-Banking （main ブランチ最新）
- **ライセンス**: 本家を継承し **CC BY-NC-SA 4.0**（変更不可）

---

## 1. 必須遵守事項（最優先）

1. **ライセンス継承**: ルートに `LICENSE`（本家からそのままコピー、CC BY-NC-SA 4.0）を必ず配置する。改変してはならない。
2. **クレジット表記**: `README.md` の冒頭と `fxmanifest.lua` のメタデータ両方に、原作者・原リポジトリ・ライセンスを明記する。
3. **非営利**: 本プロジェクトは無償公開のみ。Tebex 等の有償販売、Patreon 限定配布などは行わない旨を README に明記。
4. **継承（ShareAlike）**: 派生物も同一ライセンスで公開。README にライセンスバッジを表示。
5. **リソース名**: `fxmanifest.lua` のメタや SQL 内テーブル名、`exports['Renewed-Banking']` の参照名は **絶対に変更しない**（本家の export を使う他リソースとの互換維持のため）。フォルダ名のみ `Renewed-Banking-JP` でも可だが、サーバー設定ファイル（`server.cfg`）で `ensure Renewed-Banking` できるよう、resource 名は `Renewed-Banking` を維持することを推奨（README に注意書き）。
6. **i18n の作法**: 文字列は基本的に `locales/ja.json` に集約し、ハードコードの和訳は最小限。本家の `locales` 構造を尊重する。

---

## 2. 事前準備（Cursor が最初に行う作業）

### 2-0. モノレポで既に `jp-renewedbanking2/` がある場合（本リポジトリ）

`fivem-mods_ja` 直下に本フォルダが存在し **親リポジトリの一部**として管理されている場合、**サブディレクトリで `git init` しない**（二重リポジトリになる）。作業はこのディレクトリ内のファイル編集のみ行い、コミットはリポジトリルートから `jp-renewedbanking2/` を `git add` する。

### 2-1. 作業ディレクトリ初期化（独立クローンとして扱う場合のみ）

```powershell
cd F:\Cursor\fivem-mods_ja
mkdir jp-renewedbanking2 -ErrorAction SilentlyContinue
cd jp-renewedbanking2
git init
git remote add origin https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja.git
```

### 2-2. 本家リポジトリを取得（クローン or zip）

```powershell
git clone --depth=1 https://github.com/Renewed-Scripts/Renewed-Banking.git ..\_upstream_renewed-banking
```

### 2-3. 必要ファイルを作業ディレクトリにコピー

`_upstream_renewed-banking` から以下を `jp-renewedbanking2/` 配下に丸ごとコピー（`.git` は除外）：

`.gitattributes`、`.gitignore`、`.github/`、`LICENSE`、`FUNDING.yml`、`README.md`、`Renewed-Banking.sql`、`client/`、`config.lua`、`fxmanifest.lua`、`locales/`、`server/`、`web/`

---

## 3. ファイル構成（最終形）

```
jp-renewedbanking2/
├─ LICENSE
├─ LICENSE.ja.md                 # 【新規】ライセンス日本語要約（参考用）
├─ README.md                     # 【全面書き換え】日本語版 README
├─ README.en.md                  # 【新規】英語版 README
├─ CHANGELOG.ja.md               # 【新規】日本語版変更履歴
├─ CREDITS.md                    # 【新規】原作者・貢献者クレジット
├─ fxmanifest.lua                # 【編集】メタ情報（resource 名・exports 互換は維持）
├─ config.lua                    # 【編集】コメント全和訳、デフォルト Locale を 'ja' に
├─ Renewed-Banking.sql
├─ client/ …
├─ server/ …
├─ locales/
│   ├─ en.json                   # 本家テンプレート（キー基準）
│   ├─ ja.json                   # 【新規】完全日本語訳 + _help_* 
│   └─ … 他言語 .json は全て保持
└─ web/
    ├─ src/
    │   ├─ components/
    │   │   ├─ HelpModal.svelte           # 【新規】
    │   │   └─ HelpButton.svelte          # 【新規】
    │   └─ …
    └─ public/index.html             # lang="ja"、title 和訳
```

---

## 4. 詳細作業（順番に実行）

### Step 1: ライセンス・README・クレジット類の整備

#### 1-1. `LICENSE` の確認

本家からコピーした `LICENSE` に **一切手を加えないこと**。

#### 1-2. `LICENSE.ja.md` を新規作成（参考訳）

```markdown
# ライセンス（参考訳）

本リソースは **Creative Commons 表示-非営利-継承 4.0 国際 (CC BY-NC-SA 4.0)** のもとで公開されています。法的拘束力を持つのは英語原文（`LICENSE` ファイル）のみです。本文書は日本語話者の理解を助けるための参考訳です。

## あなたができること

- **共有** — 形式や媒体を問わず、本資料を複製・再配布すること。
- **翻案** — 本資料をリミックス、変形、加工すること。

ライセンサーは、あなたが以下のライセンス条件に従う限り、これらを取り消すことができません。

## 条件

- **表示 (BY)** — 適切なクレジット（原作者名・原作品へのリンク・ライセンス情報）を表示し、変更を加えた場合はその旨を明記してください。
- **非営利 (NC)** — 本資料を商用目的に利用してはなりません。
- **継承 (SA)** — 本資料をリミックス・変形・加工した場合、改変後の資料を **同一のライセンス** で頒布する必要があります。
- **追加の制限** — ライセンスが許諾している行為を制限する法的・技術的手段を加えてはなりません。

詳細: https://creativecommons.org/licenses/by-nc-sa/4.0/deed.ja
```

#### 1-3. `README.md`（日本語版、全面書き換え）

冒頭に以下を含めること：

- ライセンスバッジ（CC BY-NC-SA 4.0）
- **非公式派生**である旨、原作者・原リポジトリ・日本語化担当のクレジット
- 主な変更点（`ja.json`、コメント和訳、ヘルプ UI、デフォルト `ja`）
- 依存（oxmysql、ox_lib、ox_target、QBCore / ESX）
- **インストール手順**（本家 README を和訳して具体化）
- **resource 名 `Renewed-Banking` 維持**の注意
- **商用利用禁止**の明記
- 貢献の案内

#### 1-4. `CREDITS.md` 新規作成

```markdown
# クレジット

## 原作 (Original Work)

**Renewed-Banking** by **uShifty** (Discord: uShifty#1733)
- GitHub: https://github.com/Renewed-Scripts/Renewed-Banking
- Discord: https://discord.gg/P3RMrbwA8n
- Ko-fi: https://ko-fi.com/ushifty

UI 2.0 デザイン: **qwadebot** (https://github.com/qw-scripts)

レガシー UI は No Pixel 3.0 のバンキング UI からインスパイアされています。

## 本派生版 (This Derivative)

- 日本語化・ヘルプ機能追加: **matrix9neonebuchadnezzar2199-sketch**
- ライセンス: CC BY-NC-SA 4.0（原作継承）

## 翻訳貢献者

（必要に応じて追記）
```

#### 1-5. `CHANGELOG.ja.md` 新規作成

```markdown
# 変更履歴（日本語版）

本ファイルは原作 Renewed-Banking からの派生版独自の変更履歴を記録します。原作の変更履歴は [本家 README](https://github.com/Renewed-Scripts/Renewed-Banking) を参照してください。

## [1.0.0] - YYYY-MM-DD

### 追加
- 完全日本語ロケール `locales/ja.json` を追加
- UI ヘルプボタン (`HelpButton.svelte`)
- 使い方モーダル (`HelpModal.svelte`) — 入金・出金・送金・口座作成の手順解説
- 日本語 README、CREDITS、CHANGELOG

### 変更
- `config.lua`: デフォルト Locale を `'ja'` に
- 全 Lua / TypeScript / Svelte ファイルのコメントを日本語化
- `web/public/index.html`: `lang="ja"`、タイトル和訳

### 維持
- リソース名・export 名は本家互換のため `Renewed-Banking` を維持
- ライセンスは本家継承 (CC BY-NC-SA 4.0)
```

#### 1-6. `README.en.md`（新規）

本家からのフォーク経緯、ライセンス、クレジット、インストール概要を **英語**でも記載する。

---

### Step 2: `fxmanifest.lua` の編集

- **リソース名・`ui_page`・scripts リストは本家互換のまま**。
- `author` / `description` / `version` を日本語化版用に更新。`version` は本家のバージョンに **`-ja.N`** サフィックス等で派生を明示（例: 本家 `2.1.4` → `2.1.4-ja.1`）。本家の重複 `version` 行がある場合は整理して **1 つに**。
- ファイル先頭付近にコメントで **原作 URL・派生説明・CC BY-NC-SA** を記載。

---

### Step 3: `config.lua` の編集

- **全コメントを日本語化**。`Config.X` の **キー名・値の型・ロジックは変更しない**。
- `Config.Locale = 'ja'` をデフォルトに（本家構造を維持）。

---

### Step 4: `client/` `server/` の Lua コメント全和訳

対象: `client/framework.lua`、`client/main.lua`、`client/menus.lua`、`server/framework.lua`、`server/main.lua`

**ルール**:

1. `--` / `--[[ ]]` コメントを日本語化。
2. 関数名・変数名・export 名は変更しない。
3. 技術用語は原語＋括弧書き補足可。
4. ファイル先頭にライセンス継承ヘッダーを追加。
5. **ロジックは変更しない**（バグ修正は別 Issue）。

---

### Step 5: `locales/ja.json` の新規作成（完全日本語化）

**必須**: `locales/en.json` の **キー集合と完全一致**（キー漏れは英語フォールバックになる）。本リポジトリの現行 `en.json` は **93 キー**（末尾 `account_not_found` まで）。本家更新後は再比較すること。

**追加キー**: ヘルプ用 `_help_*` は本家にないため **`en.json` には追加しない**。`ja.json`（および将来他言語がヘルプを持つ場合のみ）に追加し、検証スクリプトでは `_help_*` を **除外**して `en` と比較するか、**別スクリプト**で「`en` の全キーが `ja` に存在するか」だけを検証する。

**プレースホルダ**: `en.json` の各 `%s` の **個数・順序**を崩さない（特に `comp_transaction` 等）。

**翻訳テンプレート（`ja.json`）** — 実装時は `en.json` と突き合わせてキー不足がないか確認すること：

```json
{
    "weeks": "%s週間前",
    "aweek": "1週間前",
    "days": "%s日前",
    "aday": "1日前",
    "hours": "%s時間前",
    "ahour": "1時間前",
    "mins": "%s分前",
    "amin": "1分前",
    "secs": "数秒前",
    "renewed_banking": "^6[^4Renewed-Banking^6]^0",
    "invalid_account": "${renewed_banking} 口座が見つかりません (%s)",
    "broke_account": "${renewed_banking} 口座(%s) の残高不足: $%s",
    "illegal_action": "${renewed_banking} %s が作成していない口座への不正操作を試みました。",
    "existing_account": "${renewed_banking} 口座 %s は既に存在します",
    "invalid_amount": "%s に対する金額が不正です",
    "not_enough_money": "口座の残高が不足しています！",
    "comp_transaction": "%s が $%s を %s しました",
    "fail_transfer": "不明な口座への送金に失敗しました！",
    "account_taken": "この口座IDは既に使用されています",
    "unknown_player": "ID '%s' のプレイヤーが見つかりませんでした。",
    "loading_failed": "バンキングデータの読み込みに失敗しました！",
    "dead": "操作失敗：あなたは死亡しています",
    "too_far_away": "操作失敗：距離が離れすぎています",
    "give_cash": "ID %s に $%s を渡しました",
    "received_cash": "ID %s から $%s を受け取りました",
    "missing_params": "必要なパラメータが揃っていません！",
    "bank_name": "ロスサントス銀行",
    "view_members": "口座メンバーを全員表示",
    "no_account": "口座が見つかりません",
    "no_account_txt": "あなたは作成者である必要があります",
    "manage_members": "口座メンバーの管理",
    "manage_members_txt": "既存メンバーの確認・追加",
    "edit_acc_name": "口座名を変更",
    "edit_acc_name_txt": "過去の取引履歴の名称は更新されません",
    "remove_member_txt": "口座メンバーを削除！",
    "add_member": "市民を口座に追加",
    "add_member_txt": "追加相手は慎重に選んでください（Citizen ID 必須）",
    "remove_member": "本当にこの市民を削除しますか？",
    "remove_member_txt2": "Citizen ID: %s。この操作は取り消せません。",
    "back": "戻る",
    "view_bank": "銀行口座を見る",
    "manage_bank": "銀行口座を管理",
    "create_account": "新しい口座を作成",
    "create_account_txt": "新しいサブ銀行口座を作成します",
    "manage_account": "既存口座を管理",
    "manage_account_txt": "既存の口座を確認します",
    "account_id": "口座ID（スペース不可）",
    "change_account_name": "口座名を変更",
    "citizen_id": "Citizen ID / State ID",
    "add_account_member": "口座メンバーを追加",
    "givecash": "使い方: /givecash [ID] [金額]",
    "account_title": " 口座 / ",
    "account": " 口座 ",
    "amount": "金額",
    "comment": "コメント",
    "transfer": "事業所名 または Citizen ID",
    "cancel": "キャンセル",
    "confirm": "送信",
    "cash": "所持金: $",
    "transactions": "取引履歴",
    "select_account": "口座を選択してください",
    "message": "メッセージ",
    "accounts": "口座一覧",
    "balance": "利用可能残高",
    "frozen": "口座状態：凍結中",
    "org": "組織",
    "personal": "個人",
    "personal_acc": "個人口座 / ",
    "deposit_but": "入金",
    "withdraw_but": "出金",
    "transfer_but": "送金",
    "open_bank": "銀行を開いています",
    "open_atm": "ATM を開いています",
    "canceled": "キャンセルしました...",
    "ui_not_built": "UI を読み込めません。Renewed-Banking をビルドするか、最新リリースをダウンロードしてください。\n   ^https://github.com/Renewed-Scripts/Renewed-Banking/releases/latest/download/Renewed-Banking.zip^0\n    カスタムビルドの UI を使用している場合、リソース名は必ず Renewed-Banking のままにしてください（変更不可）。",
    "cmd_plyr_id": "対象プレイヤーのサーバーID",
    "cmd_amount": "渡す金額",
    "delete_account": "口座を削除",
    "delete_account_txt": "作成した口座を削除します",
    "err_trans_account": "${renewed_banking} handleTransaction に不正な Account が渡されました！ Account=%s",
    "err_trans_title": "${renewed_banking} handleTransaction に不正な Title が渡されました！ Title=%s",
    "err_trans_amount": "${renewed_banking} handleTransaction に不正な Amount が渡されました！ Amount=%s",
    "err_trans_message": "${renewed_banking} handleTransaction に不正な Message が渡されました！ Message=%s",
    "err_trans_issuer": "${renewed_banking} handleTransaction に不正な Issuer が渡されました！ Issuer=%s",
    "err_trans_receiver": "${renewed_banking} handleTransaction に不正な Receiver が渡されました！ Receiver=%s",
    "err_trans_type": "${renewed_banking} handleTransaction に不正な Type が渡されました！ Type=%s",
    "err_trans_transID": "${renewed_banking} handleTransaction に不正な TransID が渡されました！ TransID=%s",
    "trans_search": "取引を検索（メッセージ・取引ID・送金先で検索）...",
    "trans_not_found": "取引が見つかりません",
    "export_data": "取引データをエクスポート",
    "account_search": "口座を検索...",
    "account_not_found": "口座が見つかりません",
    "_help_title": "使い方ガイド",
    "_help_intro": "ここでは銀行画面の使い方を説明します。",
    "_help_deposit_title": "入金の手順",
    "_help_deposit_body": "1. 「入金」ボタンを押す\n2. 金額を入力\n3. 「送信」で確定。所持金から銀行口座へ移動します。",
    "_help_withdraw_title": "出金の手順",
    "_help_withdraw_body": "1. 「出金」ボタンを押す\n2. 金額を入力\n3. 「送信」で確定。銀行口座から所持金へ移動します。",
    "_help_transfer_title": "送金の手順",
    "_help_transfer_body": "1. 「送金」ボタンを押す\n2. 相手の Citizen ID または事業所名を入力\n3. 金額・コメントを入力して「送信」。",
    "_help_create_title": "新規口座作成",
    "_help_create_body": "「新しい口座を作成」から、共有用のサブ口座を作成できます。作成後はメンバーを追加して共同管理が可能です。",
    "_help_close": "閉じる"
}
```

> **実装メモ**: 現行 `web/src/store/stores.ts` は **`export const translations = writable<any>()`** にロケール JSON を載せている。`HelpModal` の `t(key)` は **`$translations[key]`**（未ロード時はキーまたは空のフォールバック）で **他コンポーネントと同じパターン**に合わせること。`locale` というストア名は本コードベースでは使わない。

---

### Step 6: 既存 Svelte / TS のコメント和訳

対象: `web/src/App.svelte`、`components/*`、`providers/*`、`store/stores.ts`、`utils/*.ts`、`main.ts`

**ルール**: 英語コメントを和訳。ロジック・型・props は無変更。ファイル先頭にライセンス継承コメントを追加。

---

### Step 7: ヘルプボタン & ヘルプモーダル

#### 7-1. `web/src/components/HelpButton.svelte`（新規）

```svelte
<!--
  HelpButton.svelte — 各画面に配置する「？」ヘルプボタン
  jp-renewedbanking2 独自追加コンポーネント
  ライセンス: CC BY-NC-SA 4.0（原作 Renewed-Banking 継承）
-->
<script lang="ts">
  import { showHelp } from '../store/stores';

  export let topic: 'deposit' | 'withdraw' | 'transfer' | 'create' | 'general' = 'general';

  function open() {
    showHelp.set(topic);
  }
</script>

<button class="help-btn" on:click={open} title="使い方を表示" aria-label="使い方を表示">
  ？
</button>

<style>
  .help-btn {
    position: relative;
    width: 24px;
    height: 24px;
    border-radius: 50%;
    border: 1px solid rgba(255, 255, 255, 0.4);
    background: rgba(255, 255, 255, 0.08);
    color: #fff;
    font-size: 13px;
    font-weight: bold;
    cursor: pointer;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    transition: background 0.15s, transform 0.15s;
    margin-left: 8px;
  }
  .help-btn:hover {
    background: rgba(255, 165, 0, 0.4);
    transform: scale(1.1);
  }
</style>
```

#### 7-2. `web/src/components/HelpModal.svelte`（新規）

`showHelp` ストア（`null | topic`）を購読し、オーバーレイでトピック別タイトル・本文を表示。本文は `ja.json` の `_help_*` を参照。**既存の locale / 翻訳取得方法**（`stores.ts`・NUI からのロード）に合わせて `t(key)` を実装する。`svelte/transition` の `fade` / `scale` を使用可。

`general` 選択時は入金・出金・送金・作成へのショートカットボタンを表示し、`_help_close` で閉じる。

#### 7-3. `web/src/store/stores.ts` に `showHelp` を追加

```ts
import { writable } from 'svelte/store';

/** jp-renewedbanking2 追加: ヘルプモーダル。null = 非表示 */
export const showHelp = writable<null | 'general' | 'deposit' | 'withdraw' | 'transfer' | 'create'>(null);
```

※ 既に `import { writable } from 'svelte/store'` がある場合は **重複 import せず**、`showHelp` の export だけ追加。

#### 7-4. `App.svelte` に `<HelpModal />` をマウント

#### 7-5. 配置

| 配置先 | topic |
|--------|--------|
| `AccountsContainer.svelte` ヘッダ付近 | `general` |
| `Popup.svelte` の入金/出金/送金ダイアログ | `deposit` / `withdraw` / `transfer` |
| 新規口座作成フロー付近 | `create` |

---

### Step 8: `web/public/index.html`

- `lang="ja"`
- `<title>` を和訳（例: ロスサントス銀行 — Renewed-Banking 日本語版）

---

### Step 9: ビルド & 動作確認

```powershell
cd web
pnpm install   # または npm install
pnpm run build
```

チェックリスト:

- [ ] `web/public/build/bundle.js` が生成される
- [ ] サーバー上のフォルダ名は **`Renewed-Banking`**（README 記載どおり）
- [ ] `ensure Renewed-Banking`
- [ ] DB: `Renewed-Banking.sql`
- [ ] ゲーム内 UI が日本語
- [ ] ヘルプ「？」が動作
- [ ] 入金・出金・送金が動作

---

### Step 10: Git コミット & プッシュ

親リポジトリ `fivem-mods_ja` から:

```powershell
git add jp-renewedbanking2
git commit -m "feat: Renewed-Banking 日本語化版 (jp-renewedbanking2) …"
git push origin main
```

---

## 5. テスト用チェックリスト

| 項目 | 確認方法 |
|------|----------|
| LICENSE 無改変 | 本家と diff |
| README クレジット・ライセンス | 目視 |
| exports 互換 | `Renewed-Banking` 名維持 |
| `ja.json` に `en.json` の全キー | `tools/check-locale-keys.ps1`（下記） |
| UI 日本語 | ゲーム内 |
| ヘルプ UI | 各「？」 |
| 商用不可の記載 | README |

---

## 6. キー差分検証スクリプト

`tools/check-locale-keys.ps1` を **リポジトリルートまたは `jp-renewedbanking2/tools/`** に作成し、`locales/en.json` の全キーが `locales/ja.json` に存在するか検証する。`_help_*` は `ja` 側のみ存在してよい旨をスクリプト内コメントで明記。

```powershell
$root = Split-Path -Parent $PSScriptRoot
if (Test-Path (Join-Path $root 'locales\en.json')) { $loc = $root } else { $loc = Join-Path $root 'jp-renewedbanking2' }
$en = Get-Content -Raw (Join-Path $loc 'locales\en.json') | ConvertFrom-Json
$ja = Get-Content -Raw (Join-Path $loc 'locales\ja.json') | ConvertFrom-Json
$enKeys = @($en.PSObject.Properties.Name)
$jaKeys = @($ja.PSObject.Properties.Name)
$missing = $enKeys | Where-Object { $jaKeys -notcontains $_ }
$extra = $jaKeys | Where-Object { $enKeys -notcontains $_ -and $_ -notlike '_help_*' }
if ($missing) { Write-Host "ja に不足:" -ForegroundColor Red; $missing | ForEach-Object { Write-Host "  - $_" } }
if ($extra) { Write-Host "ja のみ (_help 以外):" -ForegroundColor Yellow; $extra | ForEach-Object { Write-Host "  - $_" } }
if (-not $missing -and -not $extra) { Write-Host "OK: en と整合（_help は ja のみ可）" -ForegroundColor Green }
```

---

## 7. やってはいけないこと

- `LICENSE` 改変
- resource / exports / SQL 識別子の改名
- ロジックの無断変更（コメント和訳のみを原則）
- 商用配布・有料化
- 原作者クレジット削除
- ライセンスの付け替え

---

## 8. 完了条件 (Definition of Done)

1. チェックリストを満たす
2. `git push` 完了
3. README にスクリーンショット（メイン・ヘルプ）を **可能なら** 追加
4. GitHub Releases はプロジェクト方針に従い任意（必須とする場合は `Renewed-Banking.zip` 形式で `web/public/build/` を含める）
5. 原作への連絡状況は README または CHANGELOG に明記（連絡済み / 予定 / 不要方針など）

---

**Cursor への依頼**: 本ファイルを上から順に実行し、各 Step 完了時に進捗を報告すること。`HelpModal` の `t()` は **`translations` ストアと NUI からのロード箇所**（例: `App.svelte` / `fetchNui` 周辺）を読んでから実装すること。
