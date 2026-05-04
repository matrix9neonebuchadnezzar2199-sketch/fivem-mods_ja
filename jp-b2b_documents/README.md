# jp-b2b_documents

FiveM 向けのドキュメント／メモエディター（**日本語版**）。Quill ベースの NUI です。

原作: [alnd029/b2b_documents](https://github.com/alnd029/b2b_documents)

## アピールポイント（本フォークの改修で前面に出したい点）

README でも拾いやすいよう、**運営・プレイヤー向けの売り**としてまとめています（改修の記録は [開発日記](./2026-05-05%20開発日記.md) / [CHANGELOG](./CHANGELOG.md) にも残します）。

1. **和文 Web フォントをリソース同梱（jp-uv-books2 と同系）**  
   `ui/fonts/*.woff2` と `OFL.txt` を同梱し、`fonts.css` で `@font-face` 登録。Noto Sans/Serif JP に加え、Shippori Mincho・Klee One・Yuji 系など **jp-uv-books2 の和文セットと同じ出自の字形**をそのまま使えるようにしてある。日本語表示を **Google Fonts 依存から切り離し**、オフライン・制限ネットでも崩れにくい（欧文 UI 用に Inter のみ CDN を併用）。

2. **ロック（署名）前に確認モーダル**  
   赤ボタンは即確定ではなく、**「ロックすると編集不可」**の説明付きダイアログで一度止める。誤タップ・RP 上の「うっかり署名」を減らす UX。Esc はモーダルを先に閉じ、複製モーダルも同様。

3. **その他の改修（概要レベル）**  
   ESX / QB-Core / Qbox 自動検出、`ox_inventory` / `qb-inventory` / ESX 標準インベントリ向けブリッジ、多言語（ja/en/fr）、起動時 **`b2b_documents` テーブル自動作成**（手動 SQL 原則不要）、配布拠点のターゲット／[E] フォールバック等。詳細は [CHANGELOG.md](./CHANGELOG.md)。

## 概要

上記アピールに加え、**日本語 UI**、**Quill リッチ編集**、**複製**、**ロック後は編集不可**（原作コンセプト踏襲）を提供します。

## 依存関係

- **必須**: ox_lib, oxmysql
- **インベントリ**: 上記のいずれか（`Config.Inventory = "auto"` 推奨）
- **ターゲット**: ox_target / qb-target または [E] 距離フォールバック

## インストール

[INSTALLATION_JP.txt](./INSTALLATION_JP.txt) を参照してください。

## 変更履歴

[CHANGELOG.md](./CHANGELOG.md) を参照してください。

## 開発日記（本 MOD の作業記録）

日付ごとのメモは本フォルダ直下に置きます（リポジトリ全体の日記と混同しないため）。

- [2026-05-05 開発日記.md](./2026-05-05%20開発日記.md)

## ライセンス・クレジット

- 原作: [alnd029](https://github.com/alnd029/b2b_documents)
- 日本語化・改修: matrix9neonebuchadnezzar2199
- 同梱フォント: SIL Open Font License 1.1（`ui/fonts/OFL.txt` および各フォントのライセンス表記に従う）
- 個別の `LICENSE` に従います
