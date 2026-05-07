# 既知の論点・スコープ外（jp-renewedbanking2）

原作 Renewed-Banking の挙動を変えない方針のため、次の項目は **本ブランチでは修正していません**。ロジック変更が必要な場合は `experimental/jp-renewedbanking2-logic` など別ブランチで検討してください。

## 原作由来（低リスク〜要設計判断）

- **SQL / メッセージサニタイズ**: `sanitizeMessage` はプリペアド文脈前提。二重エスケープの可能性は原作実装に依存。
- **`Citizen.Await` と `lib.callback.await` の混在**: 原作スタイルのまま。
- **NUI `debugData` と本番**: 開発用モックはブラウザ専用。本番は Lua の `SendNUIMessage` が正。
- **HelpModal のトピック一覧**: `topicMeta` はコンポーネント側ハードコード。トピック追加時は HelpModal / HelpButton / locales の同期が必要。

## SQL 自動投入（v1.0.2-ja）の制限

- サーバー起動時に `Renewed-Banking.sql` を読み、**行頭が `--` の行をスキップ**したうえで **`;` で文分割**し、`MySQL.query.await` で順に実行する。現行の `Renewed-Banking.sql` には **`/* */` ブロックコメントや、文字列内の `;` は含まれない**前提。
- 将来 SQL が複雑化した場合は、**パーサの拡張**（ブロックコメント・クォート内セミコロン対応）または **マイグレーションツール／分割 SQL ファイル**への移行を検討すること。いずれも本節と `CHANGELOG.ja.md` を更新してから着手する想定。
- **v1.0.3-ja**: サーバー末尾に残っていた原作由来の `createTables` + `MySQL.transaction.await` による DDL は削除し、**`Renewed-Banking.sql` 読み込み経路のみ**に統一した（ログの二重実行感の解消）。
- **ATM と入金ボタン**: 原作 UI は **`atm == true` のとき入金ボタンを表示しない**実装だった（出金・送金のみ）。**v1.0.4-ja** から `config.lua` の **`allowDepositAtAtm`**（既定 `true`）で ATM でも入金を出せる。原作どおりにするなら `false`。
- **`ensure jp-renewedbanking2` で UI が読めない（v1.0.5-ja より前）**: 旧版は `LoadResourceFile("Renewed-Banking", …)` 固定のため、フォルダ名が違うと `bundle.js` / SQL が見つからなかった。**v1.0.5-ja** で `GetCurrentResourceName()` / `GetParentResourceName()` に修正。他 MOD から `exports['Renewed-Banking']` を使う本番構成では、引き続きフォルダ名 **`Renewed-Banking`** を推奨。

## 環境・運用

- **`server_version` / FX ビルド番号**: `fxmanifest.lua` には `dependencies` のみ記載。自サーバーの ox_lib が要求する `server_version` がある場合は、手元の `ox_lib/fxmanifest.lua` を参照して追記してください。
- **ox_lib の互換バージョン**: 派生版の開発・確認は **ox_lib 3.x 系（コミュニティ標準の現行 major）** を前提としている。最新 major での互換は未検証のため、更新時は本家 Renewed-Banking の issue / release と併せて確認すること。
- **Font Awesome CDN**: `web/public/index.html` で CDN 読み込み。完全オフライン配布では npm 同梱への置換を検討（将来作業）。
- **NUI ビルド成果物（`web/public/build/bundle.js` 等）**: v1.0.1-ja では `web/.gitignore` を `git add -f` で突破し同梱している（pnpm 未導入のテストサーバーへそのまま `ensure` できるようにするため）。**中長期**は「タグごとに Releases で zip 添付のみ」「または CI で成果物を生成しリポジトリからは除外」のいずれかに寄せると diff ノイズが減る。v1.0.2-ja で方針決定する想定。
- **注釈付きタグの付け替え後の fetch**: リモートで `jp-renewedbanking2/v1.0.1-ja` を同じ名前で付け直した場合、既にそのタグを fetch 済みのクローンでは `git fetch --tags --prune` だけでは **ローカルタグが古いコミットのまま残る**ことがある。別マシンで再開するときは `git fetch origin --tags --force`、または `git tag -d jp-renewedbanking2/v1.0.1-ja` のあと `git fetch origin tag jp-renewedbanking2/v1.0.1-ja` で明示的に上書きすること。

## 開発用コード（将来の軽微改善）

- **`useNuiEvent.ts` の短絡評価**: 原作互換のため v1.0.1-ja では未変更。`if (event.data.action === action) handler(event.data);` への if 化は **v1.0.2-ja 以降**で ESLint / 可読性の観点から検討する。

## luacheck（`--std=lua54` 実行時の注意）

v1.0.1-ja 時点で `luacheck client server --no-global --std=lua54` を走らせると、**警告多数・「error」表記が 2 件**出ることがあるが、いずれも原作・FiveM 前提の範囲で **コードロジックの欠陥ではない**。

- **`+=` / `-=`**: FiveM（CfxLua）の拡張構文。Lua 5.4 標準には無いため luacheck が構文エラー相当に扱うが、ゲーム内では正常動作（原作 `server/main.lua` 由来）。
- **`line is too long`**: 原作のスタイル。日本語コメントで伸びた行も含む。原作ロジック非変更スコープでは触らない。
- **`unused argument`（`xPlayer` / `reason` 等）**: ESX / QB / QBX で同一シグネチャを保つための意図的な未使用引数（`framework.lua` 由来）。

**v1.0.2-ja 以降の検討候補**: `jp-renewedbanking2/.luacheckrc` で FiveM グローバル、`std` / `max_line_length`、必要なら CfxLua 向けプラグインやインライン抑止の方針を整理する。

## `/givecash` 通知の種別

原作どおり、成功時の一部通知で `type = 'error'` が使われている箇所があります。表示上の好みを変える場合は原作差分として別検討ください。
