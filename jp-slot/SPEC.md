# jp-slot 開発指示書 — 追補（最終確定事項）

本文書は **仕様書本体（チャット・別紙の長文仕様）** とあわせて読むこと。実装のソースオブトゥルースはリポジトリ内の **`config_shared.lua`** / **`config_server.lua`** / `fxmanifest.lua` / `README.md` である。

---

## 確定事項1：フレームワーク両対応

`server/framework.lua` で **ESX / QBCore / standalone を自動判定して全対応**。`Config.Framework = 'auto'` をデフォルトとし、起動時に検出して内部的に `impl`（同一インターフェース）を切替する。

公開APIは次の形に統一する（上位ロジックは口座種別を `Config.MoneyAccount` に合わせて渡す）。

- `Framework.getMoney(source, account)`
- `Framework.removeMoney(source, account, amount)`
- `Framework.addMoney(source, account, amount)`

standalone モードは KVS に **`jp-slot:wallet:{identifier}`**（プライマリ識別子、通常は `license:`）で仮想残高を保存する。旧キー `jp-slot:balance:*` は初回読込時に移行する。

---

## 確定事項2：既存プロップモデル流用（カジノDLC）

**`config_shared.lua`** の **`Config.PropModels`** に GTA5 カジノDLCの定番モデル名を名前付きで集約し、各台は `prop = Config.PropModels.cherry_theme` のように参照する。モデル文字列の修正は **PropModels の1箇所**で済むようにする。

詳細な運用手順は **`README.md`** の「スロット台の見た目（3Dモデル）を変える方法」を参照。

---

## 確定事項3：仮素材プレースホルダー

**`tools/generate_placeholders.sh`**（ImageMagick + FFmpeg）で `html/assets/` 以下に仮PNG/WebMを一括生成できる。リポジトリには **生成済みを同梱する方針も可**（クローン直後から動作確認可能にする）。

差し替え手順は **`README.md`** の「演出素材を本物に差し替える方法」を参照。

---

## 確定事項4：動的台設置（パターンC）

管理者コマンドで設置した台は **KVS `jp-slot:dynamic_machines`** に保存され、**`Config.Machines` の静的台と併存**する。設置・撤去・編集は **`IsPlayerAceAllowed(..., Config.AdminAce)`** でサーバー側検証し、クライアントからのイベントはすべて **`source` で再チェック**する（なりすまし対策）。占有中に撤去すると **`JpSlotForceLeaveOccupant`** で着席解除する。

詳細は **`README.md`** の「動的に台を設置する（推奨）」を参照。

---

## 確定事項5：UI サイズ

デフォルトは **`Config.UISize`**（幅・高さとも画面に対する **90%**、`maxWidthPx = 0` で無制限）。表示は CSS 変数 **`--ui-width`**, **`--ui-height`**, **`--ui-max-width`**（`html/css/base.css` の `:root`）で制御する。

運営は **`/jpslotadmin`** の **「表示」タブ**で 30〜100% の範囲にスライダー調整できる（ローカルプレビュー）。**「保存して全員に適用」**でサーバー **KVS `jp-slot:ui_size`** に JSON 保存し、**`TriggerClientEvent('jp-slot:applyUISize', -1, size)`** で接続中プレイヤー全員の NUI に即時反映する。着席時の **`jp-slot:seatGranted`** の payload にも **`uiSize`** を含める。

---

## 開発スタート時の状態（目標）

- クローン → （任意で）`tools/generate_placeholders.sh` 実行 → `jp-slot/` をサーバーに配置 → `ensure jp-slot`
- ESX / QBCore / standalone 自動判定で起動
- 指定座標にスロット台プロップ → **[E]** で NUI → 仮素材で動作確認 → 本素材はファイル差し替えで対応

---

## 落とし穴対策

長文仕様書の「現金トランザクション」「リールと結果の一致」「連打防止」「JP二重支払い防止」などは **`server/main.lua` / `server/rng.lua`** の実装コメントとログで担保する。変更時は必ずサーバー権威の検証を崩さないこと。

**追加（確率の秘匿）**: 旧来の `shared_script 'config.lua'` では `Config.Paytables` がクライアントに配信されうる。**`config_shared.lua`（公開してよい項目）と `config_server.lua`（抽選・重み・デバッグのみ）に分離**した。表示用の倍率だけは `Config.PaytableDisplay` に重複定義する。

**追加（サーバー側 KVS の書き込み関数名）**: FiveM では **`SetResourceKvpString` はクライアント専用**で、サーバー側には無い（`nil` 呼び出しになる）。サーバーで文字列を保存するときは **`SetResourceKvp(key, string)`** を使う。`GetResourceKvpString` はサーバーでも使えるため、**読み込みは通るのに書き込みだけ落ちる**という取り違えが起きやすい。`server/` で KVS を書くコードレビューでは必ず `SetResourceKvp` を確認すること。

**追加（NUI JavaScript の構文エラー）**: **`html/js/*.js` に構文エラーが 1 つでもあると、そのファイルは実行されず NUI 全体が機能不全**になる（初期化・イベント・後続スクリプトまで止まる）。文字列連結のクォート誤り（例: `"url('" + path + 'file.png')"` でクォートが早期終了する）は典型的。**`node --check html/js/app.js`** をコミット前に必ず通す（`tools/check_syntax.sh`）。**`index.html` 先頭のインライン ESC**で `app.js` が壊れていても `exit` を POST して脱出できるようにしておく。

**追加（NUI と body 背景）**: FiveM の NUI は **常にゲーム画面に重なる**。**`body` / `html` に `background` で色を付けると、スロットを開いていないときも全面がその色で隠れる**（ensure しただけで真っ黒に見える）。**`body` と `html` は `transparent` に固定**し、見せたいパネル（`#root` 等）にだけ背景色を付ける。**`SetNuiFocus` は着席・管理 UI 表示時のみ true** とし、起動時は `onClientResourceStart` で **明示的に false** を推奨。
