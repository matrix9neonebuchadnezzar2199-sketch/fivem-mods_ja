# jp-slot

FiveM カジノ向けスロットマシン MOD（MVP）。台に近づき **[E]** で着席 → NUI でベット・スピン。**抽選・現金・ジャックポット・カットイン種別はすべてサーバー権威**です。

確定仕様の追補は **`SPEC.md`** を参照（仕様書本体と併読）。

## セットアップ

1. `server-data/resources/[jp-mods]/jp-slot/` に配置する。
2. `server.cfg` に `ensure jp-slot` を追加。
3. **`config_shared.lua` の `Config.Machines` の座標・向きを自サーバー用に変更**する（デフォルトは仮座標）。
4. `Config.Framework = 'auto'` で **ESX → QBCore → standalone** を自動検出。standalone は KVS **`jp-slot:wallet:{identifier}`** で仮想残高。
5. 管理者は **`config_server.lua`** の `Config.AdminAce`（既定 `jp-slot.admin`）を ACE で付与し、チャットで `/jpslotadmin`（`Config.AdminCommand`）で **演出設計ツール（管理パネル）** を開く。`Config.AdminAuth` が有効なときは **パスワード認証**が必要。**初回起動時**に管理者パスワードが未設定なら、**サーバーコンソールに初期パスワードが一度だけ表示**されるので控え、ログイン後は 🔑 から必ず変更すること。**デザイン**タブでテーマ色、**表示**タブで NUI の幅・高さ（画面に対する %）をスライダー調整し、保存すると全プレイヤーに反映される（既定・フォールバックは **`config_shared.lua` の `Config.UISize`**、永続は KVS **`jp-slot:ui_size`**）。
6. 管理者パスワードやロックアウト状態をリセットしたいときは、サーバーコンソールまたは ACE 付きプレイヤーで **`/jpslotresetauth`** を実行する（KVP の管理者ハッシュをクリアし、`bootstrapIfMissing` が有効なら新しい初期パスワードがコンソールに出る）。

### jpslot_fix_leftstage（サーバコンソール専用）

汚染された **左ステージ（`effects.<tab>.leftStage.slots`）** プリセットデータを一括クリーンアップする緊急修復コマンドです。

- **実行場所**: **サーバコンソール（txAdmin Live Console）専用**（ゲーム内チャットからは実行できません）。
- **権限**: `RegisterCommand(..., true)` の restricted フラグに加え、ハンドラ先頭の **`if source ~= 0 then return end`** で **コンソール（source=0）以外は即 return** します。本番運用では **ACE 追加なし・コンソール限定のまま** で十分です。
- **動作**: KVP キー `jp-slot:adm:preset:<キャラID>:<プリセット名>` を走査し、各プリセット本文の `effects` に対して `leftStage` を再初期化します。
  - **`idle`**: 第1スロット（Lua の `slots[1]`）のみ **`idle/portrait.png`**（`kind=image`, `enabled=true`）、第2スロットは空・無効。
  - **その他タブ**（`win` / `bonus` / `bonus_streak` / `bonus_big` / `miss_tease`）: 2 スロットとも **`enabled=false`**, **`file=""`**。
- **メタ用 KVP**（`active` / `list` / `migrated_v2` / `migrated_v3` / `index:*` など）は対象外です。
- **使用例**（Live Console にそのまま入力）:

```
jpslot_fix_leftstage
```

- **出力**: 書き換えた各キーを **`[jp-slot][fix] reset leftStage for key=...`** で報告し、最後に **`[jp-slot][fix] done, N presets reset`**（`N` は更新したプリセット件数）。`effects` が無い古いキーは **`[jp-slot][fix] skip ...`** でスキップします。
- **使用ケース**: マイグレーションや過去データの不整合で、左キャラ枠が意図しない動画・画像を参照しているときの **緊急修復**。通常運用では **使わない**でください。実行後は管理パネルで各タブの leftStage を必要に応じて再設定してください。

### 演出プリセット KVP のマイグレーション（v2）

**初回起動時のみ**、旧いプリセット保存形式（`jp-slot:adm:preset:<id>` など）がキャラ別名前空間（例: `jp-slot:adm:preset:luna:<presetName>`）へ自動移行されます。Live Console に **`[jp-slot] preset migration v2 completed (N entries)`** が出れば成功です（`N` は移行したプリセット件数）。**2 回目以降の起動では**マイグレーション済みフラグにより処理がスキップされ、このログは出ません。

### Config.Debug（NUI 冗長ログ）

`config_shared.lua` の **`Config.Debug.nuiVerbose`** を変えたときは **`restart jp-slot` が必須**です（`refresh` のみではクライアントの shared と着席時の `init` が古いままになり、`CLICK_TARGET` / F1 スタックのオンオフがずれることがあります）。オフのときはクリック・F1 の詳細ログは出ません。

### 設定ファイルの分割（重要）

| ファイル | 配信先 | 内容 |
|---------|--------|------|
| **`config_shared.lua`** | クライアントにも届く | 台座標・プロップ・テーマ・表示用配当表（倍率のみ）・キャラ素材パスなど |
| **`config_server.lua`** | **サーバーのみ** | **抽選の重み・`Config.Paytables`**・ジャックポット寄与率・演出割合・`Config.Cutins` の重み・デバッグ・ACE |

**確率や重みは `config_server.lua` にだけ書く**ため、プレイヤーがクライアントから読める shared にノーシーク情報が載りません。配当表UIに出す倍率は **`Config.PaytableDisplay`** で共有しているので、`config_server.lua` の `Config.Paytables` と整合するよう運営で維持してください（倍率・コンボ行は揃える）。

座標をファイルで編集せずに台を置きたい場合は、下記「動的に台を設置する」を読んで **`/jpslotplace`** から試してください。

## 動的に台を設置する（推奨）

管理者だけが使えるコマンドで、**ゲーム内からその場でスロット台を設置・撤去・移動**できます。編集するのは `server.cfg`（権限）だけでよく、`config_shared.lua` を開かなくても運用を始められます。

静的に書いた **`Config.Machines` はそのまま残り**、そこに加えて「動的に置いた台」がワールドに表示されます。動的台のデータはサーバー **KVS キー `jp-slot:dynamic_machines`** に保存されるので、**サーバー再起動後も自動で復元**されます。

### 事前準備（権限）

`server.cfg` に、管理者グループへ ACE を付与します（例）。

```
add_ace group.admin jp-slot.admin allow
add_principal identifier.license:あなたのライセンス group.admin
```

`config_server.lua` の `Config.AdminAce` を変えている場合は、その名前と一致させてください。

### 設置の流れ（初心者向け）

1. ゲームに入り、台を置きたい**床の上**に立つ。
2. **台の正面がどちらを向くか**は「あなたのキャラの向き」で決まります。設置したい方向を向いてください（台はあなたの正面およそ 1.5m に出ます）。
3. チャットでコマンドを入力する。

```
/jpslotplace
```

これだけで、既定のプロップ・キャラ・ペイテーブル（`config_shared.lua` の `Config.DynamicPlacement` で変更可）で 1 台置かれます。

プロップ名・キャラID・ペイテーブルIDを変えたいときは次のようにします。

```
/jpslotplace cherry_theme luna normal
```

第1引数は `Config.PropModels` にあるキー名、第2は **`html/assets/characters/<id>/manifest.json` が存在するキャラ ID**（サーバーがフォルダをスキャンして判定）、第3はサーバー側 `config_server.lua` の `Config.Paytables` にある ID です。

### 撤去

自分の近く（既定で半径 3m）にある **動的台のうち最寄りの 1 台**を消す場合:

```
/jpslotremove
```

ID が分かっている場合（`/jpslotlist` で確認できます）:

```
/jpslotremove machine_dyn_1735123456_1
```

**config に書いた静的台は `/jpslotremove` の対象になりません。** 消したい場合は `config_shared.lua` から該当ブロックを削除して `restart jp-slot` してください。

### 移動・回転

```
/jpslotmove
```

いま立っている位置・向きを基準に、**最寄りの動的台**を再度「正面 1.5m」に置き直します。

```
/jpslotrotate
/jpslotrotate 45
```

最寄りの動的台の向きを、省略時は 90 度ずつ、数字を付けたときはその度数だけ足します。

### 一覧・詳細

```
/jpslotlist
/jpslotinfo
```

### パラメータの編集（ID が必要）

```
/jpslotedit machine_dyn_1735123456_1 minBet 500
/jpslotedit machine_dyn_1735123456_1 paytableId high
```

編集できるフィールド: `propKey`, `charId`, `paytableId`, `minBet`, `maxBet`, `displayName`

### 保存データの再読込・エクスポート

KVS を手で直したあと反映したいとき:

```
/jpslotreload
```

動的台を **将来 `Config.Machines` に書き写して静的化**したいとき:

```
/jpslotsave
```

`jp-slot/server/logs/dynamic_export_<時刻>.lua` に、貼り付け用の Lua 断片が出力されます。`Config.Machines` のテーブルに足すときは **id の重複**に注意してください。

### 補助コマンド（誰でも実行可）

現在位置と向きをチャット表示し、クリップボードへコピーします（座標メモ用）。

```
/getpos
```

### よくあるつまずき

- **「権限がありません」** → `jp-slot.admin` が付いているか、`server.cfg` を修正したあと **サーバー再起動または `exec server.cfg`** をしたか確認する。
- **斜面や段差** → 地面の高さはクライアント側で補正しますが、極端な位置ではズレることがあります。位置を変えて `/jpslotmove` で調整してください。
- **近くに既にある台と重なる** → 既定で半径 1m 以内に別の台があれば設置を拒否します（`Config.DynamicPlacement.DuplicateGuard`）。

---

## 仮素材の生成（任意）

ImageMagick と FFmpeg がある環境では:

```bash
cd jp-slot/tools
chmod +x generate_placeholders.sh
./generate_placeholders.sh
```

`html/assets/` 以下にシンボルPNG・カットイン・キャラ・フレームのプレースホルダが出力されます。**生成済みファイルをリポジトリに同梱してもよい**（クローン直後からそのまま試せる状態にできる）。

## スロット台の見た目（3Dモデル）を変える方法

### かんたんに変える場合

`config_shared.lua` の `Config.Machines` の中にある `prop = ...` の部分を書き換えます。

```lua
{ id = 'machine_01', prop = Config.PropModels.cherry_theme, ... }
                            ↑ここを変える
```

選べるモデル名（`Config.PropModels` に定義済み）:

- `Config.PropModels.standard` — シンプルなスロット台
- `Config.PropModels.cherry_theme` — チェリー柄
- `Config.PropModels.seven_theme` — 7柄
- `Config.PropModels.diamond_theme` — ダイヤ柄

書き換えたら、コンソールで `restart jp-slot` を実行すれば反映されます。

### 自分で GTA5 の他のモデルを使いたい場合

机や箱など任意のプロップも指定できます。

**手順1**: モデル名を調べる（例: [Pleb Masters Forge Objects](https://forge.plebmasters.de/objects) で `casino slot` など）。

**手順2**: `config_shared.lua` の `Config.PropModels` に追加する。

```lua
Config.PropModels = {
    standard      = 'vw_prop_casino_slot_01a',
    cherry_theme  = 'vw_prop_casino_slot_02a',
    my_custom     = 'ここに調べたモデル名',
}
```

**手順3**: 台設定で参照する。

```lua
{ id = 'machine_01', prop = Config.PropModels.my_custom, ... }
```

**手順4**: `restart jp-slot` で反映。

### モデルが表示されないときのチェック

- モデル名の綴り（大文字・小文字を含む）
- DLC プロップでサーバー／クライアントが DLC 未対応
- F8 に `[jp-slot] モデル読込失敗` が出ていないか（`client/machines.lua` のログ）

### 台の位置を変える

`coords = vector3(X, Y, Z)` を書き換えます。将来の管理画面「台の設定」から座標取得ボタンを使う想定（未実装時は開発者コンソールや他リソースで座標を取得）。

## 本物素材への差し替え

プレースホルダーから本物素材に置き換える際の手順です。**同名ファイルで上書き**すればよく、`restart jp-slot` で反映されます（NUI がキャッシュしている場合はハードリロードを試す）。

キャラ依存ファイルは **`html/assets/characters/<キャラID>/manifest.json`** でパスを宣言します（台・プリセットは `characterId` で参照）。共通リール絵柄は `html/assets/symbols/`、フレームは `html/assets/frames/`、共通エフェクトは `html/assets/shared/` です。

### 旧レイアウトからの移行

1. サーバー（またはローカル検証）を停止する。
2. リポジトリの `jp-slot` で PowerShell を開き、`powershell -NoProfile -ExecutionPolicy Bypass -File tools/migrate_assets.ps1` を実行する。
3. `html/assets/characters/luna/` 以下と `manifest.json` が期待どおりか確認する。
4. `fxmanifest.lua` の `files` がキャラ glob を含む新版であることを確認する。
5. `refresh; restart jp-slot` のあと `/jpslotadmin` でプリセットの素材パスが解決するか確認する。

### キャラクター画像（ポートレート）

- **配置先**: `html/assets/characters/<キャラID>/idle/portrait.png`（`manifest.json` の `assets.idle.portrait` と一致）
- **推奨サイズ**: 512×1024（縦長ポートレート）
- **形式**: PNG（透過対応）
- 差し替え後、`html/index.html` の `<img class="char-img">` から **`data-placeholder="true"` を削除**すると、プレースホルダー用の薄い表示が無効になります。

### キャラクター動画

- **配置先**: `manifest.json` の `assets.win.video` / `bigwin_video`（例: `win/win.webm`, `win/bigwin.webm`）
- **推奨**: 1280×720 / VP9 / 3 秒以内 / 2MB 以下目安

### シンボル画像

- **配置先（推奨）**: `html/assets/symbols/luxury/<ID>.png`（例: `wild.png`, `cherry.png`。テーマ名フォルダは `reels.js` の読み込み順に準拠）
- **レガシー**: `html/assets/symbols/<ID>.png` にだけある場合も**自動フォールバック**で読み込みます
- **サイズ**: 144×144 目安（アスペクトは `object-fit: contain` で枠内に収まります）
- **形式**: PNG

### カットイン

- **キャラ依存**: `html/assets/characters/<キャラID>/cutins/`（画像・動画）。**サーバー側のランダムカットインは `config_server.lua` の `Config.Cutins`**（`file` は `html/assets/` からの相対パス、例: `characters/luna/cutins/cutin_win_01.png`）。
- **動画**: 1280×720、VP9、3 秒以内目安。ファイル名を変える場合は **`Config.Cutins` も合わせて変更**してください。

### フレーム・その他

- 例: `html/assets/frames/luxury_frame.png`（テーマ・パスは `applyVisualAssets` / テーマ設定に準拠）

仕様の追補は **`SPEC.md`** も参照してください。

## ログ

`Config.TransactionLog = true` のとき、`server/logs/transactions.jsonl` へ JSON 行を追記します（`io` が使えない環境では黙ってスキップ）。

## 開発メモ

- 実装は **ロジック → 通信 → UI** の順で拡張する。
- `locales/*.json` は FiveM の `shared_scripts` では読めないため、クライアントが `LoadResourceFile` で読み込む。
- 依存 MOD は設けない（standalone 単体でも動作可）。
- **公開 Git に `config_server.lua` を載せる場合**は、寄与率や重みがそのまま公開情報になる点に注意（私有リポジトリや運営のみが触れる運用を推奨）。
- 配当倍率を変えたときは **`config_server.lua` と `config_shared.lua` の `PaytableDisplay` を同じコミットで直す**とよい。起動時に `server/main.lua` が両者の一致を検査し、ずれがあれば **コンソールに `WARN`** を出す。

## セキュリティ（プレイヤーが確率を読めるか）

- 抽選は **`server/rng.lua`** と **`config_server.lua` の `Config.Paytables`** のみで完結。サーバー Lua はクライアントに配信されません。
- **`config_shared.lua` はクライアントに届く**ため、そこには重み・内部確率を書かない設計にしています。
- NUI の JS に確率の数値は埋め込まず、**スピン結果とカットイン指示はサーバーイベントのみ**から渡します。
