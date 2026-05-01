# -*- coding: utf-8 -*-
"""html/assets/cards 以下の PNG を列挙して asset_manifest.json を生成する（管理者 UI 用）。

自動化の目安（ゲーム内ではフォルダ列挙できないため、外部で実行する）:
  - Windows: scripts/update_asset_manifest.bat を PNG 追加後に実行
  - CI / deploy パイプラインの jp-tcgbook コピー前に本スクリプトを実行してもよい
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "html" / "assets" / "cards"
OUT = CARDS / "asset_manifest.json"


def main() -> None:
    paths: list[str] = []
    if CARDS.is_dir():
        for p in sorted(CARDS.rglob("*.png")):
            rel = p.relative_to(ROOT / "html")
            posix = rel.as_posix()
            paths.append(posix)
    data = {"paths": paths, "_note": "jp-tcgbook admin: image_path は html からの相対（例 assets/cards/monster/x.png）"}
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(paths)} paths to {OUT}")


if __name__ == "__main__":
    main()
