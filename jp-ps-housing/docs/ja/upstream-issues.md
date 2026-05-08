# 上流由来の疑義・記録（jp-ps-housing）

本フォークでは **記録のみ**。修正は別タスク（または upstream archived 向け issue 文案）。

---

## 1. `server/server.lua` — 同一 `targetSrc` への連続 `Notify`（L387–388）

### コード抜粋（前後コンテキスト）

```lua
    for _, v in pairs(PropertiesTable) do
        local propertyData = v.propertyData
        if propertyData.owner == targetCitizenid then
            if propertyData.apartment == apartment then
                Framework[Config.Notify].Notify(targetSrc, "You are already in this apartment", "error")
                if realtorSrc then
                    Framework[Config.Notify].Notify(realtorSrc, "This person is already in this apartment", "error")
                end

                return
```

### 意図の推測

| 案 | 説明 |
|----|------|
| **A** | 意図的に2通知（不自然なので可能性低い） |
| **B** | **コピペミス**。2行目は `realtorSrc` 向け「対象プレイヤーは既にこのアパートにいます」の誤配置の可能性が高い |
| **C** | 条件分岐欠落（テナント用 / リアルター用で分けるべきだった） |

### 本フォークの方針

- **i18n では 2 文を別キー**として投入する（`notify.apartment.already_in_tenant` / `notify.apartment.peer_already_in`）。  
- **ロジック修正**: 2026-05-08 **案 B** を採用し、`realtorSrc` 宛に 2 行目を送る（詳細は §3「採用案と修正記録」）。

---

## 2. 他ファイルの「同一宛先への連続 Notify」grep 結果

`client/`・`server/` 全体で `Framework[Config.Notify].Notify` を列挙し、**同一ブロック内で同じ第1引数（宛先）に異なる文言が連続**している箇所を目視確認した。

| ファイル | 結果 |
|----------|------|
| `client/apartment.lua` | 同一メッセージが別行（L59 / L85）のみ。連続の矛盾なし |
| `client/cl_property.lua` | 各 `Notify` は単発 |
| `client/modeler.lua` | 単発（L697 は動的 `data.message`） |
| `server/sv_property.lua` | L338–339 / L347–348 / L353–354 / L399–400 / L516–518 / L906–907 等は **第1引数がテナントとリアルターで別**であり正常 |
| `server/server.lua` | **L387–388 のみ**、同一 `targetSrc` に矛盾する2文が連続 |

**重複 Notify 問題として記録する件数: 1 箇所（上記 L387–388）。**

---

## upstream への issue 文案（参考）

> **Title:** `addTenantToApartment` notifies wrong player twice with conflicting messages  
> **Body:** In `server/server.lua` inside `ps-housing:server:addTenantToApartment`, when the tenant already has the same apartment, two notifications are sent to `targetSrc`: first "You are already in this apartment" (correct for tenant), second "This person is already in this apartment" (reads like a realtor message). Likely the second call should target `realtorSrc` or be removed.

（リポジトリ archived のため merge は期待しないが記録用。）

---

## 3. 8A-next-1.5 — コード精査（判定軸と修正案）

**対象**: `server/server.lua` `AddEventHandler("ps-housing:server:addTenantToApartment", …)` 内、**現在 L387–388**（行番号はコミット時点でずれる可能性あり）。

### 前後 30 行の要約

- `data`: `apartment`, `targetSrc`（入居予定のプレイヤー）, `realtorSrc`（不動産側）
- `GetCitizenid(targetSrc, realtorSrc)` で対象の `citizenid` を取得
- `PropertiesTable` を走査し、**既に同じ `apartment` を所有している**場合に早期 `return`
- 成功パス（L416–417）では **`targetSrc` と `realtorSrc` に別々の通知**を送っており、ここが正常パターン

### 判定軸へのマッピング

| 軸 | 該当 |
|----|------|
| **A** 片方が誤り（コピペ） | **あり**。1 行目は `targetSrc` 向けで妥当。2 行目の英文は **三人称**で不動産視点の文面だが **同一 `targetSrc` に送信**されている。 |
| **B** 両方必要だが条件順が誤り | **該当しにくい**。同一条件で連続しているのみ。 |
| **C** 送信先が誤り | **主因**。2 行目は **`realtorSrc` に送る**のが自然。 |
| **D** 成功/失敗の矛盾 | **該当しない**（どちらも error）。ただし **受取人と人称が矛盾**している。 |

### 修正案候補（採用はユーザ確認後）

#### 案 A: 2 行目を削除

- **変更内容**: L388 の `Notify` を削除し、テナント向け 1 通知のみ。
- **(a) 他コードへの影響**: なし（分岐内のみ）。
- **(b) プレイヤー体験**: テナントには明確。不動産側は **フィードバックなし**（誤操作に気づきにくい）。
- **(c) 保守性**: 最も単純。

#### 案 B: 2 行目の宛先のみ `realtorSrc` に変更（文言は現状維持）

- **変更内容**: `Notify(realtorSrc, "This person is already in this apartment", "error")`。`realtorSrc` が **nil のときは送らない**（`if realtorSrc then … end`）。
- **(a) 他コードへの影響**: 外部リソースが `realtorSrc` なしでイベントを飛ばす場合、不動産側通知はスキップされるのみ。
- **(b) プレイヤー体験**: テナント・不動産の両方に合理的な通知。
- **(c) 保守性**: 差分が小さく、既存の `notify.apartment.peer_already_in` キーとも整合。

#### 案 C: 案 B に加え英文を役割別に最適化（i18n 前でも可）

- **変更内容**: 例 — テナント: 現状のまま / 不動産: `"The client is already assigned to this apartment."` 等。
- **(a) 他コードへの影響**: `locales/en.lua` / `ja.lua` / `i18n-keys-master.md` を後続で更新する必要あり。
- **(b) プレイヤー体験**: 最も分かりやすい。
- **(c) 保守性**: 文言変更分の追跡コストあり。

### Cursor の推奨（参考）

- **案 B**（必要なら `realtorSrc` nil ガード）— 差分が最小で、成功パス（L416–417）と **「テナント / 不動産で別 Notify」** のパターンと一致するため。
- 文言まで磨くなら **案 C** を **bugfix コミットの直後**または **8A-next-2** でまとめるとレビューが追いやすい。

### 採用案と修正記録

- **採用**: 案 B（2026-05-08 ユーザ承認）
- **理由**: 差分最小、成功パス（テナント + 不動産の別 Notify）との対称性回復、i18n 同期負担なし（英文据え置き）
- **修正コミット**: メッセージ `fix(server): nil-guard duplicate notify on apartment double-entry (upstream issue)` で検索（`git log -1 --grep='nil-guard duplicate notify'` 等）。コミットオブジェクトの SHA を同一コミットの本文に自己参照で埋め込むと amend のたびに破綻するため、確定 SHA は履歴ツールで確認する。
- **`realtorSrc` の扱い**: ハンドラ先頭で `local realtorSrc = data.realtorSrc`。成功パスと同様に `Framework[Config.Notify].Notify` を使用。**nil 時は不動産向け通知を送らない**（`if realtorSrc then`）。`targetSrc` は `tonumber` 済みだが `realtorSrc` は未変換のため、呼び出し元が常に数値ソースを渡す前提（成功パス L417 と同じ）。
- **修正前後の diff**（実コードは `Framework[Config.Notify].Notify` 形式）:

  ```lua
  -- before
  Framework[Config.Notify].Notify(targetSrc, "You are already in this apartment", "error")
  Framework[Config.Notify].Notify(targetSrc, "This person is already in this apartment", "error")

  -- after
  Framework[Config.Notify].Notify(targetSrc, "You are already in this apartment", "error")
  if realtorSrc then
      Framework[Config.Notify].Notify(realtorSrc, "This person is already in this apartment", "error")
  end
  ```

- **動作確認方法**: コードレビューで完結。実機テストは不要（成功パスと同一 Notify 呼び出し構造のため、論理整合の確認で十分）。
- **将来の改善（8A-next-2-2）**: 不動産向け英文を案 C 相当に改訂する。例: `notify.apartment.peer_already_in` を *"The client is already assigned to this apartment."* 等へ。キーは既存（`i18n-keys-master.md` / `locales/en.lua` / `locales/ja.lua` に `notify.apartment.already_in_tenant` / `notify.apartment.peer_already_in` あり）。
