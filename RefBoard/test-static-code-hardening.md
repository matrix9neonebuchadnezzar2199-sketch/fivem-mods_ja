# 実機テスト項目（静的コード健全化 Phase 1 / v0.6.1）

実装計画 §7-3 に基づくチェックリスト。FiveM クライアント上で実施し、結果列に記入する。

> **配置について**: リポジトリルートの `.gitignore` が `docs/` を除外するため、計画書の `RefBoard/docs/test-static-code-hardening.md` ではなく **`RefBoard/` 直下**に置いています。

| ID | タスク | 手順 | 期待結果 | 結果 (ユーザ記入) |
|---|---|---|---|---|
| T-01-M1 | T-01 | (1) FiveM で `ensure RefBoard` (2) F6 で UI 開く (3) 試合作成→PK 開始→5 本ずつ全成功で決着 (4) 「勝者」オーバーレイ表示中の 3 秒内に F6 で UI を閉じ、すぐ別の試合を開く (5) ブラウザ DevTools コンソールに `Vue warning` が出ないこと | コンソールに Vue 警告なし、別試合 UI が正常表示 | ☐ OK / ☐ 軽微 / ☐ NG |
| T-02-M1 | T-02 | (1) DevTools で `Application > Storage > localStorage` を約 5 MB まで埋める (2) UI で試合スコアを変更 (3) Console を確認 | DEV ビルドでは `[RefBoard] saveLocal failed:` が表示、UI は止まらない | ☐ OK / ☐ 軽微 / ☐ NG |
| T-03-M1 | T-03 | (1) UI 試合詳細でスコア手動編集 (2) 「-1」を入力して保存 | UI で拒否（UI 側既存バリデーション）または store で拒否され、スコア表示が変わらない | ☐ OK / ☐ 軽微 / ☐ NG |
| T-04-M1 | T-04 | (1) UI で「新規試合作成」 (2) タイトル空白のみで送信 | エラートーストまたは UI バリデーションで送信不可（現行はチーム選択＋既定タイトルで多くは再現しにくい） | ☐ OK / ☐ 軽微 / ☐ NG |
| T-04-M2 | T-04 | 既存試合 1〜20 件が正しく一覧表示される（既存データ互換性） | 全試合が正常表示、編集も可能 | ☐ OK / ☐ 軽微 / ☐ NG |
| T-06-M1 | T-06 | (1) F1（または UI から）ヘルプ「導入セットアップ」記事を開く (2) スクリーンショット画像が表示される | 4 枚のスクショ画像（`01-launcher.png` 等）が正常表示 | ☐ OK / ☐ 軽微 / ☐ NG |
| T-06-M2 | T-06 | 他のヘルプ記事 16 本を一通り開いて、画像・リンクが正常表示されること（壊れていないこと） | 全 16 記事で表示崩れなし | ☐ OK / ☐ 軽微 / ☐ NG |
| T-07-M1 | T-07 | (1) F6 で UI 開く (2) 試合詳細→「閉じる」ボタン（Lua への `'close'` コールバック） | UI が閉じてカーソルがゲームに戻る（CSP `connect-src` が機能） | ☐ OK / ☐ 軽微 / ☐ NG |
| T-07-M2 | T-07 | DevTools Console に CSP 違反警告が出ていないこと | 警告 0 件 | ☐ OK / ☐ 軽微 / ☐ NG |
| T-COMP-1 | 全体 | UI の主要 7 画面（Launcher / MatchList / MatchDetail / TeamManage / RosterManage / Settings / HelpView）を一通り開く | すべて正常表示 | ☐ OK / ☐ 軽微 / ☐ NG |
| T-COMP-2 | 全体 | `localStorage` のキー `refboard_local_matches` / `refboard_local_teams` の JSON 構造が修正前後で変わっていないこと | JSON diff なし（バージョン番号バンプは除く） | ☐ OK / ☐ 軽微 / ☐ NG |

## 実装ログ（エージェント記入）

| 項目 | 実装日 | 結果 |
|---|---|---|
| T-00 確認結果 | 2026-05-11 | 計画 §4 と実体一致を確認済み |
| T-05a grep（`dumpAllLocal` 呼び出し） | 2026-05-11 | `localPersist.ts` 定義のみ → 削除実施 |
| T-05b | 2026-05-11 | 実施 |
| `npm run test`（修正後） | 2026-05-11 | **70 件すべて pass**（`RefBoard/web` で実行） |
| `halfMinutes` バリデーション | 2026-05-11 | 省略時は `?? 45` の実効値で検証（既存 API 互換） |
