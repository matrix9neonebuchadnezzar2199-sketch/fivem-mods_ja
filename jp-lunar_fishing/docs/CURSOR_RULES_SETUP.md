# Cursor コード品質チェックルール — セットアップ概要

## ファイル構成

| ファイル | 役割 |
|---|---|
| `.cursor/rules/code-review.mdc` | メインルール（description ベース自動発動） |
| `.cursor/rules/code-review-flow.mdc` | 操作トレース用サブルール |
| `jp-lunar_fishing/docs/CODE_REVIEW_PROMPT.md` | 完全版仕様（AI が読む参照元） |

## 発動トリガー

**対象（URL / パス）+ レビュー依頼** の両方が必要。

| 言語 | トリガーフレーズ例 |
|---|---|
| 日本語 | コード品質チェック / コードレビュー / セキュリティチェック |
| 英語 | code review / code quality check / security audit |

操作トレース追加時: `操作: ○○` または `操作トレース` / `フロー解析`

## 確実に発動させる方法

1. **新しい Chat セッション**で依頼（古いコンテキストを避ける）
2. 明示参照: `@code-review` をメッセージに含める
3. 厳守を明示: 「ルール厳守で分析してください」

## 動作テスト例

```
https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/tree/main/jp-lunar_fishing
コード品質チェックお願いします（L1のみ）
```

期待: §0 確認ファイル一覧 → サマリ表 → 重大度別指摘（`[確認済]` ラベル付き）

## Cursor 設定

`settings.json` に以下を設定済み（MDC 専用エディタ回避）:

```json
"workbench.editorAssociations": {
  "*.mdc": "default"
}
```

## トラブルシューティング

| 症状 | 対処 |
|---|---|
| ルールが Project Rules に出ない | `.cursor/rules/*.mdc` のパス・拡張子・frontmatter `---` を確認 |
| 発動しない | `@code-review` を明示 / description トリガーフレーズを含める |
| 推測ばかり | モデルを高性能版に / 「ルール厳守」を明示 |
| git に含まれない | `.gitignore` の `!.cursor/rules/**` 例外を確認 |

## 関連

- 完全版プロンプト: [`CODE_REVIEW_PROMPT.md`](CODE_REVIEW_PROMPT.md)
- プロンプトバージョン: 1.0.0（2026-05-25）
