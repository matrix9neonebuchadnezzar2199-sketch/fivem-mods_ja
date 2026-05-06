# RefBoard — エラーハンドリング設計（v0.5.1〜）

実機テスト・本番運用での **トリアージ（原因の切り分け）** を前提にした設計。機能仕様の変更ではなく、**観測可能性**と**想定外例外の封じ込め**が主目的である。

## 1. 基本方針

- **通信パターン**: サーバーは `RegisterNetEvent` + `TriggerClientEvent('…:ack', src, payload)` が基本。FiveM の RPC 形式 `cb(...)` は NetEvent では使わない。
- **後方互換**: 既存 NUI は多くが `payload.ok === false` と `payload.error`（文字列キー）を見ている。新しい **`code`（例: `E2006`）** を足すが、**`error` の文字列は従来どおり**維持する（`MakeError` の `message` を既存キーに合わせる）。
- **追加フィールド**: `detail`（人間向け短文）・`context`（デバッグ用テーブル）・`timestamp` を任意で付与できる。

## 2. 構造化エラー（共有 Lua）

**ファイル**: `shared/error_codes.lua`（`fxmanifest.lua` の `shared_scripts` で `config.lua` より後に読み込む）

- **`ErrorCodes`**: 各要素は `{ code = 'E1xxx', message = 'legacy_error_key' }`。
  - **帯域の意味**（運用・known_issues 分類用）  
    - `E1xxx`: 認証・権限・ロック・セッション  
    - `E2xxx`: バリデーション  
    - `E3xxx`: データ整合性（試合・チーム・選手の状態）  
    - `E4xxx`: DB / トランザクション  
    - `E5xxx`: 内部・未処理例外  
  - **`message`**: NUI が既に参照している **`error` キーと同一**にする（例: `bad_payload`, `no_lock`, `lock_held`, `duplicate_license`, `tx_failed`）。UI を一括差し替えしなくてよい。
- **`MakeError(entry, detail, context)`**  
  戻り値の形:

  ```lua
  {
    ok = false,
    error = entry.message,  -- レガシー互換キー
    code = entry.code,
    detail = detail,        -- 任意
    context = context,      -- 任意（source, matchId, stack 等）
    timestamp = os.time() * 1000,
  }
  ```

- **レガシー専用フィールド**: 例としてロック競合では `MakeError` の戻りに **`holder`** をマージし、従来の `refboard:lock:acquire:result` の形を壊さない。

## 3. NetEvent の例外封じ込め（`RefboardGuard`）

**ファイル**: `server/util.lua`

- **`RefboardGuard(src, ackEvent, tag, fn)`**
  - ハンドラ本体を `fn` に閉じ、`xpcall` で実行する。
  - 失敗時: `Logger.error(tag, 'unhandled_exception', { src, stack })`。
  - **`ackEvent` が非 nil** のときだけ、`TriggerClientEvent(ackEvent, src, MakeError(UNHANDLED_EXCEPTION, …))` でクライアントへ返す（`context.stack` に traceback）。
  - **`ackEvent` が nil**: ログのみ（例: `refboard:autosave:draft` は単一 ACK イベントがない）。`refboard:session:leave` も例外時に誤った形を `session:left` に送らないため nil を使用。

- **適用範囲（例）**: スコア・イベント・試合 CRUD・選手追加・ロック acquire/release・autosave・session enter など、実機で頻度・影響が大きい NetEvent。

- **権限不足で return するだけの経路**: 従来どおり `refboard:notify` のみで **ACK を送らない**箇所はそのまま（`RefboardGuard` は関与しない）。設計上「クライアントが ACK を待たない」フローと混在しないよう注意する。

## 4. 構造化ログ（`Logger`）

**ファイル**: `server/util.lua`  
**設定**: `config.lua` の `Config.LogLevel`（`DEBUG` / `INFO` / `WARN` / `ERROR`）

- `Logger.debug|info|warn|error(source, message, context?)`
- 時刻・ms・レベル・source・任意 context を1行に整形。FiveM の `^1` 等で色分け。
- **ループ内や高頻度**は `DEBUG` に寄せ、本番デフォルトは `INFO` でノイズを抑える。

## 5. NUI（TypeScript / Vue）

| 領域 | 内容 |
|------|------|
| **型** | `web/src/types/error.ts` — `RefBoardError` と `ERROR_CODES` 定数（ドキュメント・IDE 補助用）。 |
| **表示文言** | `web/src/i18n/ja.json` / `en.json` の `errors.E1001` 形式。`code` があれば `errors[code]` を優先し、無ければ `error` キー従来のトースト等でも可。 |
| **通信トレース** | `useNui.ts`: `import.meta.env.DEV` または `localStorage.refboard_trace === '1'` で `fetch` 前後を `console.groupCollapsed` 出力。 |
| **グローバル例外** | `main.ts`: Vue `errorHandler` に加え、`window` の `error` / `unhandledrejection` で `useToast`（真っ白防止・ユーザーへの一次通知）。 |

## 6. ヘルスチェックとの関係

**ファイル**: `server/health.lua`、`refboard:health:check` / `:ack`

- 環境・DB・権限・プレゼンス・ロック・設定の一覧は **エラー体系とは別チャネル**だが、障害調査では **エラーコード + ヘルスレポート**を併用する想定。
- 詳細は `docs/sprints/sprint_06_pretriage.md` を参照。

## 7. 新規 API / 新規エラー追加時のチェックリスト

1. `ErrorCodes` に `{ code, message }` を追加するか、既存の `message` を流用できるか決める。
2. クライアントへ返す ACK は **`MakeError`** で統一できるか（従来 `{ ok=false, error='…' }` のみでも可だが、トリアージ用には `code` 推奨）。
3. **`ja.json` / `en.json` の `errors` に同じ `code` キー**を追加する（欠けるとキー名が表示される場合がある）。
4. 高リスクハンドラなら **`RefboardGuard`** で包み、`ackEvent` 名を既存 ACK と一致させる。
5. 調査に必要なら **`Logger.info`** を入口、`Logger.warn` をビジネス上の失敗、`Logger.error` を例外に使う。

## 8. アプリ内ヘルプとの連携（v0.6.0〜）

- Toast の「解決方法を見る」や `/help/error/:code` は、本書の **`code`（`E1xxx`…）** と [help_system_design.md](help_system_design.md) のトラブル記事を対応付ける。  
- 記事本文の `error` キー表記は、**`MakeError` の `error`（レガシー文字列）** と一致させる（例: `E1003` ↔ `lock_held`）。

## 9. 関連ソース一覧

| 種別 | パス |
|------|------|
| エラー定義・生成 | `shared/error_codes.lua` |
| Logger / Guard | `server/util.lua` |
| ログレベル | `config.lua`（`Config.LogLevel`） |
| NUI 型 | `web/src/types/error.ts` |
| i18n | `web/src/i18n/ja.json`, `en.json`（`errors`） |
| 通信トレース | `web/src/composables/useNui.ts` |
| グローバルハンドラ | `web/src/main.ts` |
| 前夜スプリント要約 | `docs/sprints/sprint_06_pretriage.md` |
| アプリ内ヘルプ設計 | `docs/help_system_design.md` |
| 変更履歴 | `CHANGELOG.md` |

---

**改版履歴**

- 2026-05-06: v0.5.1 トリアージ強化に合わせ初版作成。
- 2026-05-06: §8 ヘルプ連携・§9 関連一覧に `help_system_design.md` を追加。
