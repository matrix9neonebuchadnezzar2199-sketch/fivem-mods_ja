"""背景削除くん — 画像の背景削除＋リサイズ＋PNG保存ツール（Gradio）"""

from __future__ import annotations

import tempfile
import zipfile
from pathlib import Path

import gradio as gr
from PIL import Image
from rembg import new_session, remove

_SESSION = new_session("u2net")


def _resize(img: Image.Image, width: int | None, height: int | None, keep_aspect: bool) -> Image.Image:
    if not width and not height:
        return img

    orig_w, orig_h = img.size

    if keep_aspect:
        if width and height:
            ratio = min(width / orig_w, height / orig_h)
        elif width:
            ratio = width / orig_w
        else:
            ratio = height / orig_h
        new_w = max(1, round(orig_w * ratio))
        new_h = max(1, round(orig_h * ratio))
    else:
        new_w = int(width) if width else orig_w
        new_h = int(height) if height else orig_h

    return img.resize((new_w, new_h), Image.LANCZOS)


def process_images(
    files: list,
    do_resize: bool,
    width,
    height,
    keep_aspect: bool,
    progress=gr.Progress(),
):
    if not files:
        raise gr.Error("画像を1枚以上アップロードしてください。")

    width_val = int(width) if (do_resize and width) else None
    height_val = int(height) if (do_resize and height) else None
    if do_resize and not width_val and not height_val:
        raise gr.Error("リサイズ ON の場合、幅または高さを指定してください。")

    out_dir = Path(tempfile.mkdtemp(prefix="bg_removed_"))
    out_paths: list[str] = []

    for f in progress.tqdm(files, desc="処理中"):
        src_path = Path(f.name if hasattr(f, "name") else f)
        try:
            with Image.open(src_path) as img:
                img = img.convert("RGBA")
                removed = remove(img, session=_SESSION)
                if do_resize:
                    removed = _resize(removed, width_val, height_val, keep_aspect)
                out_path = out_dir / f"{src_path.stem}.png"
                removed.save(out_path, format="PNG")
                out_paths.append(str(out_path))
        except Exception as e:
            raise gr.Error(f"{src_path.name} の処理に失敗: {e}") from e

    zip_path = out_dir / "results.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for p in out_paths:
            zf.write(p, arcname=Path(p).name)

    return out_paths, str(zip_path)


def build_app() -> gr.Blocks:
    with gr.Blocks(title="背景削除くん") as app:
        gr.Markdown(
            "# 背景削除くん\n"
            "複数画像をアップロードして、背景削除 → リサイズ → PNG保存します。"
        )

        with gr.Row():
            with gr.Column(scale=1):
                files_input = gr.Files(
                    label="画像を選択（複数可・ドラッグ&ドロップ可）",
                    file_types=["image"],
                    file_count="multiple",
                )

                with gr.Group():
                    gr.Markdown("### リサイズ設定")
                    do_resize = gr.Checkbox(label="リサイズする", value=False)
                    with gr.Row():
                        width = gr.Number(label="幅 (px)", value=None, precision=0, minimum=1)
                        height = gr.Number(label="高さ (px)", value=None, precision=0, minimum=1)
                    keep_aspect = gr.Checkbox(label="アスペクト比を維持", value=True)
                    gr.Markdown(
                        "- 幅または高さの片方だけ指定 ＋ アスペクト比維持 ＝ もう一方は自動計算\n"
                        "- 両方指定 ＋ アスペクト比維持 ＝ 指定範囲に収まるよう縮小"
                    )

                run_btn = gr.Button("背景削除を実行", variant="primary")

            with gr.Column(scale=1):
                gallery = gr.Gallery(
                    label="結果プレビュー",
                    columns=3,
                    height=420,
                    show_download_button=True,
                )
                zip_download = gr.File(label="一括ダウンロード (ZIP)")

        run_btn.click(
            fn=process_images,
            inputs=[files_input, do_resize, width, height, keep_aspect],
            outputs=[gallery, zip_download],
        )

    return app


if __name__ == "__main__":
    build_app().launch(inbrowser=True, theme=gr.themes.Soft())
