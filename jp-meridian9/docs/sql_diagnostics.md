# MERIDIAN-9 — SQL 診断クエリ（実機テスト・運用確認用）

`sql/install.sql` で定義されたテーブル（`created_at` 列あり）を前提にしています。

**注意**: `mrd9_result_logs.result` の ENUM は `extracted` / `died` / `disconnect` / `unknown` です（NUI 上の `disconnected` とは表記が異なります）。

---

## リザルト発生数（直近 24 時間、結果別）

```sql
SELECT result, COUNT(*) AS cnt, AVG(total) AS avg_total, MAX(total) AS max_total
FROM mrd9_result_logs
WHERE created_at >= NOW() - INTERVAL 1 DAY
GROUP BY result;
```

---

## tier 分布（`granted` のみ）

```sql
SELECT tier, COUNT(*) AS cnt,
       ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 1) AS pct
FROM mrd9_loot_logs
WHERE result = 'granted'
  AND created_at >= NOW() - INTERVAL 1 DAY
GROUP BY tier
ORDER BY FIELD(tier, 'legendary', 'rare', 'uncommon', 'common');
```

---

## `fail_reason` 内訳（異常検知）

```sql
SELECT result, fail_reason, COUNT(*) AS cnt
FROM mrd9_loot_logs
WHERE result != 'granted'
  AND created_at >= NOW() - INTERVAL 1 DAY
GROUP BY result, fail_reason
ORDER BY cnt DESC;
```

---

## Subject-0 / fiction トリガー頻度

```sql
SELECT event_type, COUNT(*) AS cnt, COUNT(DISTINCT session_id) AS sessions
FROM mrd9_fiction_events
WHERE created_at >= NOW() - INTERVAL 1 DAY
GROUP BY event_type;
```

---

## プレイヤー別収益（直近 7 日・上位 20）

```sql
SELECT player_identifier,
       COUNT(*) AS missions,
       SUM(CASE WHEN result = 'extracted' THEN 1 ELSE 0 END) AS success,
       SUM(total) AS gross_total,
       ROUND(AVG(CASE WHEN result = 'extracted' THEN total END), 0) AS avg_success_total
FROM mrd9_result_logs
WHERE created_at >= NOW() - INTERVAL 7 DAY
GROUP BY player_identifier
ORDER BY gross_total DESC
LIMIT 20;
```

---

## 関連ドキュメント

- 実機テスト項目・手順・ロードマップ（フェーズ C〜G）: `TEST_PLAN_AND_ROADMAP.md`
