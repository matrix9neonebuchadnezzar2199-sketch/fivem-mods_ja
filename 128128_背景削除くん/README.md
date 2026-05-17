# 背景削除くん

複数画像をまとめて **背景削除 → リサイズ → PNG 保存** できるローカル Web アプリです。

- UI: Gradio（ブラウザで操作）
- 背景削除: [`rembg`](https://github.com/danielgatis/rembg)（U²-Net、ローカルで動作）
- リサイズ: 幅・高さ指定（アスペクト比維持オプション付き）
- 出力: PNG（透過）＋ ZIP 一括ダウンロード

## 動作環境

- Windows / macOS / Linux
- **Python 3.10 〜 3.13**（rembg / gradio の制約。3.14 は未対応）

## セットアップ

```powershell
# 仮想環境を作成（Python 3.13 を推奨）
py -3.13 -m venv .venv

# 有効化
.\.venv\Scripts\Activate.ps1

# 依存パッケージをインストール
pip install -r requirements.txt
```

> 初回の実行時に背景削除モデル（u2net、約 170MB）が自動ダウンロードされます。

## 起動

```powershell
.\.venv\Scripts\python.exe app.py
```

ブラウザで `http://127.0.0.1:7860` が自動で開きます。

## 使い方

1. 画像を選択（複数可・ドラッグ&ドロップ対応）
2. 「リサイズする」を ON にして 幅 / 高さ を入力（任意）
   - 幅または高さの片方だけ + アスペクト比維持 → もう一方は自動計算
   - 両方 + アスペクト比維持 → 指定範囲に収まるよう縮小
3. 「背景削除を実行」をクリック
4. プレビュー右側の **ZIP 一括ダウンロード** から取得
