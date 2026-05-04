# MBT Emote Menu — 日本語 README（非公式まとめ）

**原作:** [Malibu Tech Team](https://github.com/MalibuTechTeam/mbt_emote_menu) の **mbt_emote_menu**（rpemotes-reborn 向け NUI エモートメニュー）。

本リポジトリの作業ツリーでは、**Lua ロケール（`locales/ja.lua`）**、**`config.lua` の日本語コメントと既定言語 `ja`**、および **NUI 向け `web/ja_patch.js`**（英語のまま残る UI 文言の置換用）を同梱しています。

## ライセンス

原作と同様 **PolyForm Noncommercial License 1.0.0**（`LICENSE.md`）です。**非商用**に限り利用・改変・再配布の条件が定められています。配布時も **`LICENSE.md` を必ず同梱**し、README に原作名を明記してください。

## 要件・導入

英語版 `README.md` の「Requirements」「Installation」と同じです。要点のみ:

- FiveM サーバービルド **6116+**、**OneSync** 有効
- **rpemotes 系リソース**（例: `rpemotes-reborn` や `rpemotes`）を先に `ensure` し、その後に本リソース（フォルダ名が **`jp-mbt_emote_menu`** の場合はその名前で `ensure`）

```cfg
ensure rpemotes-reborn
ensure jp-mbt_emote_menu
```

※ `fxmanifest.lua` の `dependencies` には rpemotes を含めていません（フォルダ名がサーバーごとに異なるため）。未導入・未起動の場合はコンソールにサーバー側の検出エラーが出ます。

## フロントエンドのビルド

`fxmanifest.lua` の `ui_page` は **`web/dist/index.html`** です。`web/dist/` は通常 `.gitignore` されるため、**リソースをサーバーへ置く前に** `web` フォルダでビルドしてください。

```powershell
cd web
npm install
npm run build
```

ビルド後の `web/dist/index.html` は **`../ja_patch.js`** で `web/ja_patch.js` を読み込みます。`fxmanifest.lua` の `files` に `web/ja_patch.js` が含まれていることを確認してください。

## 言語と設定

- **`config.lua`**: `MBT.Language = 'ja'`（他言語に戻す場合は `'en'` などに変更）
- **`locales/ja.lua`**: ゲーム／NUI が参照する翻訳キー（`Translate` / クライアントから NUI へ渡る文字列）
- **`web/ja_patch.js`**: React 側にハードコードされた英語の補正用（必要に応じて `dict` に追記）

## フレームワーク（ジョブ権限・表示名）

`MBT.JobPermissions.Framework = 'auto'` のとき、**ESX → QBox（qbx_core）→ QBCore → standalone** の順で検出します。`modules/bridges/` 配下の各ブリッジは `GetResourceState` でガードされています。

**QBox と qb-core が同時に動く環境**では、`modules/bridges/qbcore.lua` 先頭で **`qbx_core` が started のとき QBCore ブリッジを return** するガードを入れてあります（二重適用の抑止）。

混成サーバー（例: ESX と QBCore を同時起動）では、`Framework` を **`'esx'`** など明示指定するのが安全です。

## 検証の目安

1. サーバー／クライアントの F8 で **`[MBT]`** ログと Lua エラーがないか
2. F4（または `config.lua` のキー）でメニューを開き、検索プレースホルダ・タブ・ボタンが日本語か
3. 英語が残る箇所は `web/ja_patch.js` の辞書にキーを追加

---

詳細な機能一覧・スクリーンショット・英語の設定説明は **`README.md`** を参照してください。
