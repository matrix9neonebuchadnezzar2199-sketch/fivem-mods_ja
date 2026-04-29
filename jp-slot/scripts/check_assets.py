# -*- coding: utf-8 -*-
"""jp-slot: html/assets の参照パスが実在するか確認する。

使い方（リポジトリルートまたは jp-slot から）:
  python scripts/check_assets.py

終了コード: 初期ルナ参照が欠けるとき 1、それ以外 0。
"""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "html" / "assets"

# studioReferenceEffects + manifest が参照する初期セット（キャラルート基準の実ファイル）
LUNA_REQUIRED = [
    "characters/luna/idle/portrait.png",
    "characters/luna/win/win.webm",
    "characters/luna/win/bigwin.webm",
    "characters/luna/cutins/cutin_bonus_01.png",
    "characters/luna/cutins/cutin_win_01.png",
    "characters/luna/cutins/cutin_big_01.png",
    "characters/luna/manifest.json",
]

# config_server.lua Config.Cutins.videos（実ファイルは未同梱でもよいが一覧は報告）
CUTIN_VIDEOS_OPTIONAL = [f"characters/luna/cutins/vid_{i:02d}.webm" for i in range(1, 6)]


def main() -> int:
    if not ASSETS.is_dir():
        print(f"ERROR: assets dir missing: {ASSETS}", file=sys.stderr)
        return 1

    bad = False
    print("=== Luna / studio reference (must exist) ===")
    for rel in LUNA_REQUIRED:
        p = ASSETS / rel
        ok = p.is_file()
        if not ok:
            bad = True
        print(("OK   " if ok else "MISS ") + rel)

    print()
    print("=== Config.Cutins videos (paths reserved; optional files) ===")
    for rel in CUTIN_VIDEOS_OPTIONAL:
        p = ASSETS / rel
        ok = p.is_file()
        print(("OK   " if ok else "skip ") + rel)

    print()
    print("=== characters/luna/sounds/ (create when adding BGM/SE/voice) ===")
    for sub in (
        "characters/luna/sounds/bgm",
        "characters/luna/sounds/se",
        "characters/luna/sounds/voice",
    ):
        d = ASSETS / sub
        exists = d.is_dir()
        print(("OK   " if exists else "n/a  ") + sub + (" (add when using BGM/SE/voice)" if not exists else ""))

    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
