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
                Framework[Config.Notify].Notify(targetSrc, "This person is already in this apartment", "error")

                return
```

### 意図の推測

| 案 | 説明 |
|----|------|
| **A** | 意図的に2通知（不自然なので可能性低い） |
| **B** | **コピペミス**。2行目は `realtorSrc` 向け「対象プレイヤーは既にこのアパートにいます」の誤配置の可能性が高い |
| **C** | 条件分岐欠落（テナント用 / リアルター用で分けるべきだった） |

### 本フォークの暫定方針

- **i18n では 2 文を別キー**として投入する（`notify.apartment.already_in_tenant` / `notify.apartment.peer_already_in`）。  
- **ロジック修正は 8A-next-2 以降の別タスク**とし、必要なら `realtorSrc` へ送るよう変更を検討する。

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
