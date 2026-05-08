# 開発日記: ランタイム起動確認・第1フェーズ（Lua i18n）区切り

**記録日時**: 2026-05-08  
**リソース**: `jp-ps-housing`（リポジトリ `fivem-mods_ja`）

---

## 1. サーバ起動・ログ解析（2026-05-08）

| 項目 | 結果 |
|------|------|
| `ox_doorlock` | 起動 **OK**。`ja.json` 未配置に関する警告は **ox_doorlock 側の i18n** 由来。本リソースの不具合ではなく、実害なし。 |
| `jp-ps-housing` | 起動 **エラーなし**で完了。 |
| DB | 以前の `Table doesn't exist` は **解消**。**`properties` テーブル**が正常に認識されている。 |

---

## 2. 現状ステータス（実機確認の前提）

第1フェーズ（Lua i18n）の実機確認に必要な依存関係と DB が揃った状態:

- **ox_lib**, **ox_target**, **ox_inventory**, **oxmysql**, **qbx_core**: 既存
- **fivem-freecam**: 導入済み（MIT）
- **ox_doorlock**: 導入済み（LGPL-3.0）
- **`properties` テーブル**: 作成済み・認識 OK
- **`jp-ps-housing`**: エラーなし起動

---

## 3. ここまでの開発作業の要約（コード側）

- **i18n 基盤**: `shared/locale.lua` の `Locale()`、`LocaleEn()`（Discord / 管理ログ英語固定）。
- **ロケール**: `locales/en.lua` / `ja.lua`（`log.*` は en のみ、`debug.*` キーは削除方針）。
- **検証**: `tools/verify-locale-keys.mjs`（`log.*` を ja 欠落許容）。
- **client**: `Locale()` 置換済み（8A-next-2-1、`634c114` 前後）。
- **server / shared**: `Notify` → `Locale`、`SendLog` → `LocaleEn`、ターゲットラベル等（8A-next-2-2、`f83d30d` 前後）。
- **upstream 追随**: `addTenantToApartment` の重複通知は案 B（`realtorSrc` 宛）、文言は案 C（`peer_already_in`）。

詳細は同一ディレクトリの `2026-05-08_i18n_client_replaced.md`、`2026-05-08_i18n_server_replaced.md` を参照。

---

## 4. 次の動作確認手順（ゲーム内・未記入分は随時追記）

実施したら `[x]` にし、スクリーンショットは `docs/ja/dev-diary/screenshots/` 等に保存すると 8B の入力に使いやすい。

- [ ] **`/housing`** で UI が表示される
- [ ] メニュー・通知・ターゲットが **日本語**（`Config.Locale = 'ja'`）
- [ ] アパート入居フロー
- [ ] 家具配置（modeler）
- [ ] **Discord webhook** が **英語**（`LocaleEn` の確認）

### 記録用メモ欄

- 起動成功ログ（コンソール）: （スクリーンショット or 要約を貼付）
- `/housing` UI: 
- Notify 日本語: 
- Discord ログ英語: 
- 不具合・違和感: 

---

## 5. 次フェーズ候補（問題なければ優先度検討）

| ID | 内容 |
|----|------|
| **8B** | Svelte NUI（`web/src/`）の i18n 導入と日本語化 |
| **8C** | Noto Sans JP 等フォント差し替え |
| **8D** | 家具 886 件 CSV 翻訳（`Config.Furnitures` 系） |

ゲーム内の **UI 日本語表示状況** を共有できれば、8B / 8C / 8D の着手順を決めやすい。

---

## 6. 任意・未対応メモ

- **`ps-realtor`**: 不動産売買 UI 用。家具・アパート確認のみなら不要。売買フローを試す段階で導入判定。
- **`ox_doorlock` の `ja.json`**: 日本語ロケール追加は LGPL-3.0 配下の派生物になるが、非商用用途なら後フェーズで対応可能。

---

## 7. 関連コミット（参照用）

- Client i18n: `feat(client): wire Locale() for user-facing strings`
- Server/shared i18n: `feat(server,shared): wire Locale()/LocaleEn(); refine peer_already_in (case C); drop debug locale keys`
- 重複 Notify 修正: `fix(server): nil-guard duplicate notify on apartment double-entry (upstream issue)`

正確な SHA は `git log --oneline -- jp-ps-housing` で確認。
