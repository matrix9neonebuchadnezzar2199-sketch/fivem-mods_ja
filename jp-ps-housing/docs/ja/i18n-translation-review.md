# 翻訳レビュー記録（ja）

## 用語統一表（採用）

| English | 日本語 |
|---------|--------|
| Property | 物件 |
| Apartment | アパート |
| Furniture | 家具 |
| Realtor / Client | 不動産担当／クライアント（文脈により「お客様」可） |
| Stash | 保管庫 |
| Wardrobe | ワードローブ |
| Shell | シェル（ゲーム用語として暫定） |
| Storage | 保管庫（ターゲットラベル） |
| Cart | カート |
| Raid | レイド |
| Showcase | 内覧 |
| Doorbell | インターホン |
| Garage | ガレージ |

## 未確定・要レビュー（優先度高い順）

1. **`dialog.property_info.line_shell` / `notify.framework` 周辺** — 「シェル」をプレイヤー向けに **「建物タイプ」「間取りテンプレ」** とするか。運営のサーバー方針に依存。
2. **`notify.raid.*` 一式** — 「レイド」を **「強制捜査」** など RP 用語に寄せるか。警察サーバー向けなら現状のまま可。
3. **`notify.raid.need_stormram`** — アイテム名 **ストームラム** のままか、説明文で **「破門槌が必要」** と一般化するか（`ja.lua` に `-- TODO: review`）。
4. **`dialog.raid.content`** — 同上（レイドのニュアンス）。
5. **`notify.realtor.client_*`** — 「クライアント」を **「お客様」** に統一するか（不動産 RP のトーン）。
6. **`notify.spawn.furniture_radial_hint`** — 文が長い。チュートリアル用に **分割通知** するかはコード側の別検討。
7. **`log.property.*`（Discord ログ）** — 運営が英語のまま欲しい場合は **ja を使わず en 固定**も検討（現状は ja に翻訳済み）。
8. **`menu.access.give_description` vs `give_title`** — 英語は同語。日本語も同一だが、将来 UI で区別するなら表記を分けられる余地あり。

## `locales/ja.lua` インライン TODO

`-- TODO: review` を付与した行数: **3**（`dialog.property_info.line_shell`, `dialog.raid.content`, `notify.raid.need_stormram`）

## 要レビュー件数サマリ

- **明示 TODO コメント**: 3  
- **本文で要検討として挙げた項目**: 上記 8 のうち、コード変更が絡むものを除き **5〜6** が訳語・トーンの最終判断向け
