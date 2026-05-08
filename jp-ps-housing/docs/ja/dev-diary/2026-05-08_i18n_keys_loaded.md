# 開発日記 — 2026-05-08 本番ロケールキー投入

## 実施内容

- `locales/en.lua` に本番キー **129** + テスト **3** = **132** エントリを投入。
- `locales/ja.lua` に **131** エントリ（`_test.fallback` 除外で en と整合）。
- `docs/ja/upstream-issues.md` — `server/server.lua` L387–388 の重複 Notify を記録。他ファイルは目視で同種パターンなし。
- `docs/ja/i18n-keys-master.md` — カテゴリ別件数と正規化方針。
- `docs/ja/i18n-translation-review.md` — 用語表・要レビュー項目。
- `tools/verify-locale-keys.mjs` — en/ja キー差分の自動チェック。

## 自動検証（リポジトリ内）

```text
$ node tools/verify-locale-keys.mjs
en: 132 ja: 131
missing in ja (except _test.fallback): []
extra in ja: []
```

## ゲーム内動作確認（手順・未実施ならここまで）

`Config.Locale = 'ja'` のまま `ensure jp-ps-housing` 後、`server/server.lua` の i18n テスト用コメントを一時的に外し:

```lua
print(Locale('notify.property.owner_only'))
print(Locale('notify.realtor.added_tenant', 'Test User', 'Test Apt'))
print(Locale('_test.fallback'))  -- ja 未定義 → en にフォールバック
```

`Config.Locale = 'en'` に変更して再起動し、同キーが英語になることを確認。  
**本記録作成時点**: 上記は開発者のローカル txAdmin / コンソールで実施する想定（CI では未自動化）。

## 次タスク

- **8A-next-2**: Lua 実置換（client → server → shared の順を推奨）。重複 Notify は **別 PR** で `realtorSrc` 修正を検討。
