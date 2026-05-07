# 既知の論点・スコープ外（jp-renewedbanking2）

原作 Renewed-Banking の挙動を変えない方針のため、次の項目は **本ブランチでは修正していません**。ロジック変更が必要な場合は `experimental/jp-renewedbanking2-logic` など別ブランチで検討してください。

## 原作由来（低リスク〜要設計判断）

- **SQL / メッセージサニタイズ**: `sanitizeMessage` はプリペアド文脈前提。二重エスケープの可能性は原作実装に依存。
- **`Citizen.Await` と `lib.callback.await` の混在**: 原作スタイルのまま。
- **NUI `debugData` と本番**: 開発用モックはブラウザ専用。本番は Lua の `SendNUIMessage` が正。
- **HelpModal のトピック一覧**: `topicMeta` はコンポーネント側ハードコード。トピック追加時は HelpModal / HelpButton / locales の同期が必要。

## 環境・運用

- **`server_version` / FX ビルド番号**: `fxmanifest.lua` には `dependencies` のみ記載。自サーバーの ox_lib が要求する `server_version` がある場合は、手元の `ox_lib/fxmanifest.lua` を参照して追記してください。
- **ox_lib の互換バージョン**: 派生版の開発・確認は **ox_lib 3.x 系（コミュニティ標準の現行 major）** を前提としている。最新 major での互換は未検証のため、更新時は本家 Renewed-Banking の issue / release と併せて確認すること。
- **Font Awesome CDN**: `web/public/index.html` で CDN 読み込み。完全オフライン配布では npm 同梱への置換を検討（将来作業）。
- **NUI ビルド成果物（`web/public/build/bundle.js` 等）**: v1.0.1-ja では `web/.gitignore` を `git add -f` で突破し同梱している（pnpm 未導入のテストサーバーへそのまま `ensure` できるようにするため）。**中長期**は「タグごとに Releases で zip 添付のみ」「または CI で成果物を生成しリポジトリからは除外」のいずれかに寄せると diff ノイズが減る。v1.0.2-ja で方針決定する想定。
- **注釈付きタグの付け替え後の fetch**: リモートで `jp-renewedbanking2/v1.0.1-ja` を同じ名前で付け直した場合、既にそのタグを fetch 済みのクローンでは `git fetch --tags --prune` だけでは **ローカルタグが古いコミットのまま残る**ことがある。別マシンで再開するときは `git fetch origin --tags --force`、または `git tag -d jp-renewedbanking2/v1.0.1-ja` のあと `git fetch origin tag jp-renewedbanking2/v1.0.1-ja` で明示的に上書きすること。

## 開発用コード（将来の軽微改善）

- **`useNuiEvent.ts` の短絡評価**: 原作互換のため v1.0.1-ja では未変更。`if (event.data.action === action) handler(event.data);` への if 化は **v1.0.2-ja 以降**で ESLint / 可読性の観点から検討する。

## `/givecash` 通知の種別

原作どおり、成功時の一部通知で `type = 'error'` が使われている箇所があります。表示上の好みを変える場合は原作差分として別検討ください。
