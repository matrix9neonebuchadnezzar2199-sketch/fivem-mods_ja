# 既知の論点・スコープ外（jp-renewedbanking2）

原作 Renewed-Banking の挙動を変えない方針のため、次の項目は **本ブランチでは修正していません**。ロジック変更が必要な場合は `experimental/jp-renewedbanking2-logic` など別ブランチで検討してください。

## 原作由来（低リスク〜要設計判断）

- **SQL / メッセージサニタイズ**: `sanitizeMessage` はプリペアド文脈前提。二重エスケープの可能性は原作実装に依存。
- **`Citizen.Await` と `lib.callback.await` の混在**: 原作スタイルのまま。
- **NUI `debugData` と本番**: 開発用モックはブラウザ専用。本番は Lua の `SendNUIMessage` が正。
- **HelpModal のトピック一覧**: `topicMeta` はコンポーネント側ハードコード。トピック追加時は HelpModal / HelpButton / locales の同期が必要。

## 環境・運用

- **`server_version` / FX ビルド番号**: `fxmanifest.lua` には `dependencies` のみ記載。自サーバーの ox_lib が要求する `server_version` がある場合は、手元の `ox_lib/fxmanifest.lua` を参照して追記してください。
- **Font Awesome CDN**: `web/public/index.html` で CDN 読み込み。完全オフライン配布では npm 同梱への置換を検討（将来作業）。

## `/givecash` 通知の種別

原作どおり、成功時の一部通知で `type = 'error'` が使われている箇所があります。表示上の好みを変える場合は原作差分として別検討ください。
