# i18n 監査（ja / en）

派生版 v1.0.1-ja 作業時点のキー整合と `locale()` 呼び出し引数の対応表。

## キー集合差分

| 区分 | 内容 |
|------|------|
| ja のみ（v1.0.0-ja 時点） | `_help_*` 11 キー（NUI ヘルプ用）。en に欠落していた → v1.0.1 で en に英訳を追加。 |
| en のみ | なし |

## `locale()` 呼び出しとプレースホルダ引数

| key | en パターン | ja パターン | 呼び出し元 | 引数順 | 備考 |
|-----|-------------|-------------|------------|--------|------|
| `comp_transaction` | `%s has %s $%s` | `%sは%s（$%s）` | `server/main.lua` deposit / withdraw / transfer | `(name, action, amount)` | `action` は `comp_action_*` の `locale()` 結果を渡す（英語動詞の直書き廃止） |
| `comp_action_deposited` | `deposited` | `入金しました` | 同上（第2引数） | なし | 新規キー |
| `comp_action_withdrawn` | `withdrawn` | `出金しました` | 同上 | なし | 原作の withdrawed を en では正拼法に |
| `comp_action_transferred` | `transferred` | `送金しました` | 同上 | なし | 原作の transfered を en では正拼法に |
| `give_cash` | `Successfully gave %s $%s` | `%s に現金 $%s を渡しました` | `server/main.lua` givecash | `(recipientName, amountStr)` | en は Lua 呼び出し `(nameB, amount)` に合わせて修正 |
| `received_cash` | `Successfully received funds from %s ($%s)` | `%s から現金 $%s を受け取りました` | 同上 | `(senderName, amountStr)` | en は Lua 呼び出し `(nameA, amount)` に合わせて修正 |
| `${renewed_banking}` | 各 `invalid_account` 等 | 同左 | JSON 内補間 | ox_lib が置換 | ja/en 両方に `renewed_banking` キーあり |

## NUI 用 `_help_*`（ja / en 同一キー）

ヘルプモーダル・HelpButton 用。v1.0.1 で en.json に追記し、英語 UI でも未定義キーが出ないようにした。

## 未使用キー

本監査では Lua / Svelte から参照がないキーは「将来の UI 用」とみなし、削除は行っていない（原作・派生のキー保全）。
