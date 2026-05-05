# RefBoard 設計書 3/3：フロントエンド設計書（NUI / Vue 3 Specification）

## 3.1 技術スタック

Vue 3（Composition API + `<script setup>`）、TypeScript、Vite、Vue Router、Pinia、Tailwind CSS v3、vue-i18n v9、VueUse。UI は Headless UI + Heroicons を想定。

## 3.2 ディレクトリ（`web/src`）

- `router/index.ts`
- `stores/session.ts`, `match.ts`, …
- `views/Launcher.vue`, `MainLayout.vue`, `tabs/*`
- `composables/useNui.ts`, `useHeartbeat.ts`, `useAutosave.ts`, `useLockGuard.ts`
- `i18n/index.ts`, `ja.json`, `en.json`

## 3.3 レイアウト

`MainLayout.vue`: グリッド `20% | 30% | 50%`（右はゲーム視界・透過・`pointer-events: none`）。サイドバー折りたたみ時 `48px | 30% | calc(70%-48px)`。

カラー（Tailwind extend）: primary `#3B82F6`, accent `#10B981`, warning `#F59E0B`, bg `#0F172A`。

## 3.4 NUI ブリッジ

`fetch(\`https://${GetParentResourceName()}/<callback>\`, { method: 'POST', body: JSON.stringify(data) })`

開発時は `GetParentResourceName` 不在時にモック返却。

## 3.5 ハートビート / 再開

編集者のみ `refboard:lock:heartbeat` を NUI→クライアント→サーバーへ定期送信。起動時 `match:checkResume` 相当の NUI コールバックで `ResumeDialog` を表示。

## 3.6 ビルド

`cd web && npm install && npm run build` → `web/dist`。`vite.config.ts` の `base: './'` 必須。

## 3.7 i18n

`ja.json` / `en.json` 同一キー構造。`localStorage` キー例: `refboard-locale`。
