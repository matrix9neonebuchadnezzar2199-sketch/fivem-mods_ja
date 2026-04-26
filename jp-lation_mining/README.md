# jp-lation_mining（採掘・精錬ジョブ）

[オリジナル **lation_mining**](https://github.com/IamLation/lation_mining)（作者: iamlation / Lation Scripts）の **Qbox 等フレームワーク＋ox 系**向け採掘スクリプトに、**日本語ロケール**と**設定ラベル日本語化**、リソース名 **`jp-lation_mining`** 変更を行った**派生版**です。ゲーム性・設定の中身の基本はオリジナルと同じ考え方です。

---

## このスクリプトでできること（ざっくり）

- **採掘 XP**／レベル、ツルハシ段階と耐久
- エリアごとの**鉱石出現・ドロップ・再出現**の調整
- **精錬所**で鉱石 → インゴット
- 鉱山 NPC **ショップ**（道具購入）・**買取**・**ランキング**
- マップ **ブリップ**（拠点・精錬所）・**ox_target** による干渉

**サーバー運営向けの前提:** データベース（oxmysql）と UI・ロケール（ox_lib）とインタラクション（ox_target 等）が**既に導入済み**である想定です。**単体の CFX デフォルト＋ox だけ**の構成では、プレイヤー・在庫・ジョブと**つながる枠**（下記）が入っていないと、表示やデータが揃いません。

---

## 必須・推奨の依存（わかる範囲で）

### 技術的に**必須**のリソース

| リソース | 役割 |
|----------|------|
| [**oxmysql**](https://github.com/overextended/oxmysql) | MySQL 接続。採掘データ（レベル・累計等）の保存 |
| [**ox_lib**](https://github.com/overextended/ox_lib) | メニュー、通知、ロケール、プログレス等 |
| [**ox_target**](https://github.com/overextended/ox_target) | デフォルト設定は NPC・鉱石等への **ox_target**（`config.shared` で変更可） |

### いずれか 1 つの**フレーム**（採掘がプレイヤーを認識するため）

採掘クライアントの `bridge/client.lua` は、**次のいずれか**が**起動している**ことを期待します（フォルダ名の例。実装は導入した枠に合わせる）。

- **ESX** — リソース例: `es_extended`
- **QBCore**（旧来）— 例: `qb-core`
- **Qbox** — 例: **`qbx_core`**
- **ox_core** — 例: `ox_core`

**Qbox や ESX などを 1 つも入れていない**（CFX デフォ＋`ox_lib` だけ等）のサーバーでは、`qbx_core` や `es_extended` が**存在せず** `ensure` しても**見つかりません**。その場合、採掘用の**ブリップ（マップ）やメニューが出ない**ことが多いです。**先に**フレーム一式を公式手順に沿って入れ、`server.cfg` の **`ensure` 順**を揃えてから採掘を有効化してください。

### インベントリ

**ox_inventory** を扱う前提の説明がオリジナル README に多いです。`install/items/ox_inventory.txt` を参照し、アイテム定義をインベントリに追加してください。別インベントリ向けの例も `install/items/` 内にあります。

### 元作者が言及するオプション

- 通知・プログレスを **Lation 製 UI** 等に切り替え可能（`config` の `setup`）
- サーバーログを **Fivemanage / Fivemerr / Discord** 等に送れる（`config.server.lua` 周り。設定は導入ドキュメントを参照）

本 README では**運営の最初の一歩**に必要な分を中心に書いています。

---

## フォルダ名と `ensure` 名

FiveM では**リソース名 ＝ `resources/.../ここのフォルダ名**です。

- 本派生は **`jp-lation_mining`** というフォルダ名・マニフェスト名を想定しています。  
- `server.cfg` には次の 1 行を追加します（依存より**後**）。

```cfg
ensure jp-lation_mining
```

オリジナル ZIP のまま `lation_mining` フォルダで入れるなら、行は `ensure lation_mining` に合わせます。**名前が違うとリソースは見つかりません。**

**推奨 `ensure` 順（例・フレームは導入した物に合わせる）:**

```cfg
# 言語: 日本語 UI（ox 側に locales/ja.json がある事が望ましい）
# setr ox:locale ja

ensure oxmysql
ensure ox_lib
ensure ox_target
# ここに、使用するフレーム（例: qbx_core や es_extended 等）
ensure jp-lation_mining
```

`setr ox:locale ja` を付けるなら、**各 `ox_lib` / `ox_target` リソース**内に `locales/ja.json` が**無い**とコンソールに**警告**が出ます。警告は**採掘専用の `locales/ja.json` とは別**です。  
対処: **ox 系を最新化**する／**`ja.json` を公式またはコミュニティ手順で追加**する／一時的に `setr ox:locale en`（採掘部分は本リソースの `locales/ja.json` でも日本語化できます。ox のメニュー文言は英語のまま等）。

---

## 導入手順（初めての人向け）

### 1) 依頼関係（depends）の確認

- **oxmysql**、**ox_lib** を、採掘より**先**に `ensure` できる位置へ。
- マニフェストの `dependencies` に **ox_target は書いていない**例がありますが、**実運用で ox_target を使う**なら **ox_target も有効化**し、**採掘より前**に起動させてください。

### 2) 採掘リソースの配置

ZIP を展開し、次のように置きます（`[jp-mods]` は任意のカテゴリ名で構いません）。

`resources / [jp-mods] / jp-lation_mining /`

`fxmanifest.lua` がこの直下にあることを確認してください。

### 3) `server.cfg` に 1 行追記

上の **`ensure jp-lation_mining`**。フレームがあれば、**必ず**その**後**か、採掘が**依存物の後**になるように。

### 4) データベース

- **`install/lation_mining.sql`**  
  オリジナル同様、**初回起動時にスクリプトから読み込み・実行**される想定のため、**手で SQL を流さなくても**テーブルができることが多いです（環境差あり）。
- **`install` フォルダ**や `.sql` を**消さない**でください。起動失敗の原因になります。  
- MySQL 側の**テーブル名**はオリジナル名の **`lation_mining`** のまま、という構成です（**フォルダ名** `jp-lation_mining` とは**別**です。混乱しやすい点です）。

### 5) インベントリのアイテム

`install/images/`（画像）と、使用している在庫向けの **`install/items/*.txt` の内容**を、使っている**インベントリの手順**に従い登録します。`ox_inventory` 利用時は**アイテム定義＋画像パス**がよく出る論点です。

### 6) 再起動

- 大きい変更のあとは **停止 → 起動**か、**`refresh` 後** `ensure jp-lation_mining`。
- オリジナル同様、採掘だけ**頻繁に** `restart` すると不具合を誘発する、という**注意**があります。**止める → 少し待つ → `ensure`**の方が安全とされています（同梱 `config.shared` 先頭の英語注釈参照）。

### 7) 日本語表示

- 本派生: **`locales/ja.json`** あり。  
- **`setr ox:locale ja`** とあわせ、**ox 本体の ja 有無**は上記を参照。  
- 地図上の**ショップ／精錬**ラベルは、**`config.shared.lua` の blip/名称**等も日本語化してあります。

---

## 主な設定ファイル（触る人向け）

| ファイル | 内容の例 |
|----------|----------|
| `config/shared.lua` | デバッグ、ox_target 等、ショップ・採掘・精錬の**座標・価格・ゾーン・ブリップ**、インゴット名（表示用）等 |
| `config/client.lua` | アニメ・進捗表示、統計表示、**`ui`**（`scale=2.0` でメニュー精錬 TextUI 等を約2倍。コンテキストは `#` 見出し併用） 等 |
| `config/server.lua` | ログ、Webhook、経済 等（詳細はオリジナル同様 `config` 内のコメント・公式 README を参照） |
| `config/icons.lua` | アイコン |  

バランスや座標の調整は主に上記。本派生の**注意**: **GitHub からオリジナルだけ**を上書きすると、**`jp-lation_mining` 名の変更と日本語 3 ファイル**が戻るので、**上書き後は**改めて **ロケールとラベル**、必要なら**リネーム方針**を揃えてください。

---

## トラブルシュート（よくある）

| 現象 | 確認 |
|------|------|
| **`Couldn't find resource qbx_core` 等** | その**名前**のフォルダが `resources` に**無い**。**入れたフレーム**に合わせて `ensure`（QBCore なら `qb-core` 等）。**採掘専用ではフレームは付いていません。** |
| マップに**鉱山／精錬**が**出ない** | 上記**フレーム有無**と**起動順**。**`qbx_core` より採掘が先**に立ち上がると一瞬失敗しうる、という対策を `bridge` に**遅延再試行**で入れています。それでもダメなら、**`ensure` 順**を見直し、**F8 クライアント**のエラー、**txAdmin コンソール**の採掘・ox のエラーを確認。 |
| コンソール: **`could not load 'locales/ja.json'`**（**ox_lib / ox_target**） | `setr ox:locale ja` なのに、**各 `ox_lib` / `ox_target` 内**の `ja` ファイルが**無い**。`en` にするか、**ox を更新**するか、**`ja` を手で追加**（本リソースの `locales/ja.json` では**直りません**）。 |
| 採掘のメニューは日本語、**ox だけ**英語 | 上のとおり。採掘は自前 `locales/ja.json`、**ox の汎用 UI**は **ox 側**のロケール。 |
| SQL・画像エラー | `install` を消していないか、MySQL 接続・権限。 |

---

## サポート（オリジナル作者）

- [Discord](https://discord.gg/9EbY4nM5uu)（Lation 公式。英語想定）  
- [オリジナル GitHub Issues](https://github.com/IamLation/lation_mining)  

**本派生（日本語化・`jp-lation_mining` 名）**のバグや要望は、**利用中の配布元・リポジトリ**の案内に従ってください。

---

## ライセンス

リポジトリ同梱の `LICENSE` を参照してください。オリジナルのライセンス条項に従います。

---

## 参考: 元スクリプト紹介・動画（英語・販促）

オリジナル README にあった**機能一覧・YouTube・他スクリプト**へのリンクは、**作者の製品紹介**用です。ここでは**公式情報**の参照先だけ示します。

- オリジナルリリース: [Releases (IamLation/lation_mining)](https://github.com/IamLation/lation_mining/releases)  
- 紹介動画（同 README）: リポジトリ上の `README` 元画像のリンク先

---

**まとめ:** この派生版は**オリジナル採掘**＋**日本語**＋**リソース名 `jp-lation_mining` に合わせた変更**です。運営では **oxmysql / ox_lib / ターゲット枠、および ESX か QBCore 系か Qbox か ox_core か、のいずれか**を先に**安定起動**させ、**`ensure` 名はフォルダ名と同じ**に揃えて利用してください。
