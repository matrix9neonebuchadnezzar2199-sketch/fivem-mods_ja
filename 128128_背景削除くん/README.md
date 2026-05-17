<div align="center">

# 背景削除くん

**バッチ背景削除 → 任意リサイズ → 透過 PNG / ZIP — すべてローカル推論。**

[![Python](https://img.shields.io/badge/Python-3.10%20%E2%80%93%203.13-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Platform](https://img.shields.io/badge/Platform-Win%20%7C%20macOS%20%7C%20Linux-555555?style=for-the-badge)](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/tree/main/128128_%E8%83%8C%E6%99%AF%E5%89%8A%E9%99%A4%E3%81%8F%E3%82%93)
[![License](https://img.shields.io/badge/License-MIT-ECC423?style=for-the-badge)](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/blob/main/LICENSE)
[![Local inference](https://img.shields.io/badge/inference-100%25%20local-22c55e?style=for-the-badge)](https://github.com/danielgatis/rembg)

<br />

[![Gradio](https://img.shields.io/badge/Gradio-5.x-FF4B4B?style=flat-square)](https://www.gradio.app/)
[![rembg](https://img.shields.io/badge/rembg-u2net-6366f1?style=flat-square)](https://github.com/danielgatis/rembg)
[![ONNX Runtime](https://img.shields.io/badge/ONNX_Runtime-ready-005CED?style=flat-square)](https://onnxruntime.ai/)
[![Pillow](https://img.shields.io/badge/Pillow-resize-8E44AD?style=flat-square)](https://python-pillow.org/)

<br />

**`local-first`** · **`batch`** · **`rgba`** · **`png`** · **`zip`** · **`no-api-key`** · **`u2net`**

</div>

<br />

---

## · 目次

|  |  |
|--|--|
| [Why this exists](#why-this-exists) | 一言で何ができるか |
| [初めてローカルAIを使う方へ](#first-local-ai) | 用語・初回の流れ・よくあるエラー |
| [128×128 などリサイズ](#resize-128) | アイコン／テクスチャ向けの入れ方 |
| [使っている「AI」](#ai-stack) | ONNX / U²-Net / スタック |
| [動作環境](#env) | Python バージョン |
| [セットアップ](#install) | venv / `pip` |
| [起動](#launch) | `app.py` |
| [使い方](#usage) | UI の操作手順 |
| [ライセンス](#license) | MIT と各依存 |

---

<a id="why-this-exists"></a>

## · Why this exists

複数画像をまとめて **背景削除 →（任意で）リサイズ → PNG（透過）保存** できる **ローカル専用**の小さな Web UI です。  
ブラウザで操作し、**画像をクラウドの生成 AI API に送りません**（推論は **ONNX Runtime + rembg** がこの PC 上で実行）。

---

<a id="first-local-ai"></a>

## 初めてローカルAIを使う方へ

### 「ローカルAI」で合っている？

**合っています。** 日常語としての「ローカルAI」＝**インターネット上の他人サーバーではなく、自分のパソコン上で動く AI（機械学習モデル）** を指すことが多いです。

もう少しだけ正確に言うと、本ツールは **チャット GPT のような「会話する生成 AI」ではなく**、**画像のどこを残してどこを透過するかを決める専用の数学モデル（ニューラルネット）** を、**あなたの PC の CPU（環境によっては GPU）** で動かしています。  
学習済みの **重みファイル（ONNX）** を **ONNX Runtime** が読み込み、**rembg** が「背景削除」の窓口になっています。

### 何が「ローカル」か（ここが大事）

| ローカル | 本ツール |
|----------|----------|
| 画像データ | アップロードした画像は **この PC の中** で処理。ChatGPT やクラウド API に **画像を送りません**。 |
| 推論（計算） | **オンラインの AI サービスに「お願い」はしません。** ダウンロード済みのモデルで計算します。 |
| アカウント | **OpenAI 等の API キーは不要**です。 |

> **初回だけ**、学習済みモデル（約 **170MB** 前後）を **インターネット経由でダウンロード**します。2 回目以降はキャッシュが使われ、オフラインに近い状態でも動くことが多いです。

### 初めてのときの流れ（そのまま真似して OK）

1. **Python を入れる**（3.10〜3.13 推奨。下記「動作環境」参照）
2. このフォルダで PowerShell を開く
3. 下の **「セットアップ」** のコマンドで **仮想環境（`.venv`）** を作る  
   → 他の Python アプリとパッケージが混ざらない「専用の部屋」だと思ってください。
4. **`pip install -r requirements.txt`** で部品を入れる
5. **`python app.py`** で起動 → ブラウザが開く
6. 画像を選んで **「背景削除を実行」**  
   → **初回はモデル取得で数十秒〜数分かかる**ことがあります。固まったように見えても、CPU が忙しいだけのことが多いです。

### つまずいたとき（よくあるエラー）

<details>
<summary><strong><code>TypeError: Blocks.launch() got an unexpected keyword argument 'theme'</code></strong></summary>

- **原因**: Gradio **5.x** では、画面の配色（テーマ）は **`launch()` ではなく `gr.Blocks(theme=...)`** に書きます。
- **対処**: このリポジトリの **`app.py` はすでにその形に直してあります。** 古いチュートリアルをコピペしている場合は、`launch(theme=...)` をやめて `Blocks` 側へ移してください。

</details>

<details>
<summary><strong>モデルのダウンロードが失敗する</strong></summary>

- 会社・学校のプロキシ、セキュリティソフト、オフライン環境を疑ってください。別回線や一時的なテザリングで試すのも手です。

</details>

---

## · ざっくり仕様

| 項目 | 内容 |
|------|------|
| UI | [Gradio](https://www.gradio.app/) **5.x**（`http://127.0.0.1:7860`）。**テーマは `gr.Blocks(..., theme=...)`**（`launch(theme=...)` は不可） |
| 背景削除 | [rembg](https://github.com/danielgatis/rembg) · 既定 **`u2net`** |
| 推論 | [ONNX Runtime](https://onnxruntime.ai/)（CPU／環境により GPU） |
| リサイズ | [Pillow](https://python-pillow.org/) · LANCZOS · **128×128 等は数値入力** |
| 出力 | **PNG（透過）** + **ZIP 一括** |

---

<a id="resize-128"></a>

## 128×128 など「アイコンサイズ」への加工

本ツールに **「128」とだけ決め打ちした機能はありません**。代わりに、**リサイズ欄に希望のピクセル数を入れる**ことで、例えば **128×128** の正方形テクスチャやアイコン用画像を一括生成できます。

1. 画像をアップロード（複数可）
2. **「リサイズする」** を ON
3. **幅 `128`・高さ `128`** を入力  
   - **「アスペクト比を維持」ON（推奨）** … 元画像を **128×128 の枠に収まるよう縮小**（余白は透過 PNG では「小さいキャンバス」にはならず、**長辺が 128 に合わせて短辺は比例**）。**厳密な 128×128 の正方形キャンバス**が必要な場合は、別途画像編集でキャンバス拡張／中央配置するか、**アスペクト比を維持 OFF** で **128×128 に強制伸縮**（ゆがみあり）を選ぶ。
4. **「背景削除を実行」** → ZIP またはギャラリーから保存

| やりたいこと | 設定の目安 |
|--------------|------------|
| 長辺を 128 に合わせ、比率はそのまま | 幅 **128** のみ、高さは空、アスペクト比 **ON** |
| 高さ基準で 128 | 高さ **128** のみ、幅は空、アスペクト比 **ON** |
| 必ず 128×128 の画素グリッドに伸ばす | 幅 **128**・高さ **128**、アスペクト比 **OFF**（全体リサイズ） |
| 256×256 や 64×64 など | 同様に数値を変更するだけ |

> **背景削除はアルファマット**です。細い髪・半透明・背景と色が被る被写体では境界が荒れることがあります。その場合は元解像度で削除してからリサイズする、別モデル試験（下記）などを検討してください。

---

<a id="ai-stack"></a>

## 使っている「AI」の説明（技術寄り）

### 全体像

- **クラウドの生成 AI API は使いません。** 学習済み **ニューラルネットの重み（ONNX）** を **ONNX Runtime** でローカル実行しています。
- アプリから見る API は **`rembg`** の `remove()` で、その裏で **顕著性に近い前景推定** → **アルファマット**として背景を抜いています。

### 既定モデル `u2net`（U²-Net）

|  |  |
|--|--|
| **論文** | [U²-Net: Going Deeper with Nested U-Structure for Salient Object Detection](https://arxiv.org/abs/2005.09007)（Qin 他, 2020） |
| **役割** | 前景の「どこが主題か」を強く意識した汎用切り抜き。`app.py` は `new_session("u2net")` 固定 |
| **初回** | ONNX 重み **約 170MB** を自動ダウンロード（回線・キャッシュで変動） |

### 依存スタック

| Layer | Role |
|-------|------|
| **ONNX** | 学習済みモデルのポータブル形式 |
| **onnxruntime** | ONNX の実行エンジン |
| **rembg** | セッション・マット生成の高レベル API |
| **Pillow** | リサイズ・RGBA・PNG 書き出し |

### 限界・注意

- **万能の Photoshop ではない**です。髪・ガラス・網・同色背景などは **欠け・にじみ** が出やすいです。
- **モデルは固定（u2net）** 。差し替えは `app.py` の `new_session(...)` を変更（未検証）。
- **法的・倫理的な利用**（他人の肖像・著作物の無断加工など）は利用者の責任で遵守してください。

---

<a id="env"></a>

## · 動作環境

- **OS**: Windows / macOS / Linux  
- **Python**: **3.10 〜 3.13**（rembg / Gradio の組み合わせ上の目安。3.14 は未検証）

---

<a id="install"></a>

## · セットアップ

```powershell
# 仮想環境を作成（Python 3.13 を推奨）
py -3.13 -m venv .venv

# 有効化
.\.venv\Scripts\Activate.ps1

# 依存パッケージをインストール
pip install -r requirements.txt
```

> 初回の背景削除実行時に、`u2net` 用 ONNX 重みが自動ダウンロードされます（失敗した場合はプロキシ・ファイアウォールを確認）。

---

<a id="launch"></a>

## · 起動

```powershell
.\.venv\Scripts\python.exe app.py
```

ブラウザで **`http://127.0.0.1:7860`** が開きます。  
Gradio 5 では **`launch(inbrowser=True)` のみ** — テーマは **`gr.Blocks(..., theme=gr.themes.Soft())`**（`build_app()` 内）。

---

<a id="usage"></a>

## · 使い方（操作手順）

1. 画像を選択（複数可・ドラッグ&ドロップ対応）
2. **「リサイズする」** を ON にして **幅 / 高さ（px）** を入力（任意。[128×128 の入れ方](#resize-128)参照）
3. **「背景削除を実行」** をクリック
4. **ZIP 一括ダウンロード** またはギャラリーから保存

---

<a id="license"></a>

## · ライセンス・帰属

| 対象 |  |
|------|--|
| **本ディレクトリのスクリプト** | リポジトリルートの [**MIT License**](https://github.com/matrix9neonebuchadnezzar2199-sketch/fivem-mods_ja/blob/main/LICENSE) に従います |
| **rembg / onnxruntime / Gradio / Pillow** | 各プロジェクトのライセンスに従います（商用可否は各公式を確認） |

---

<div align="center">

<sub>Built with Gradio · rembg · ONNX Runtime · Pillow</sub>

</div>
