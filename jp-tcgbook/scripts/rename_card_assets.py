# -*- coding: utf-8 -*-
"""カード素材PNGの一括リネーム（character / monster）。
- ファイル名に英字 [A-Za-z] を含む → 先頭に連番 id（001_原ファイル名）
- それ以外（日本語のみ・数字のみなど）→ tcg_ch_NNN.png / tcg_m_NNN.png
二段階リネームで衝突を避ける。UTF-8 BOM なしで保存。
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CARDS = ROOT / "html" / "assets" / "cards"


def has_ascii_letter(stem: str) -> bool:
    return bool(re.search(r"[A-Za-z]", stem))


def character_sort_key(p: Path) -> tuple:
    stem = p.stem
    m = re.match(r"^(\d+)", stem)
    n = int(m.group(1)) if m else 10**9
    return (n, stem)


def plan_folder(sub: str, tcg_prefix: str) -> list[tuple[Path, Path]]:
    """Return list of (src, dst) for PNG files in cards/{sub}/."""
    d = CARDS / sub
    if not d.is_dir():
        print(f"skip missing: {d}", file=sys.stderr)
        return []

    files = sorted(d.glob("*.png"))
    english: list[Path] = []
    ascii_id: list[Path] = []
    for p in files:
        if has_ascii_letter(p.stem):
            english.append(p)
        else:
            ascii_id.append(p)

    english.sort(key=lambda x: x.name.lower())
    ascii_id.sort(key=character_sort_key if sub == "character" else lambda x: x.name)

    moves: list[tuple[Path, Path]] = []
    ei = 1
    for p in english:
        dst = d / f"{ei:03d}_{p.name}"
        moves.append((p, dst))
        ei += 1

    ai = 1
    for p in ascii_id:
        dst = d / f"{tcg_prefix}_{ai:03d}.png"
        moves.append((p, dst))
        ai += 1

    return moves


def run_moves(moves: list[tuple[Path, Path]], label: str) -> None:
    if not moves:
        return
    dstdirs = {dst.parent for _, dst in moves}
    assert len(dstdirs) == 1
    folder = next(iter(dstdirs))

    # 衝突チェック（今の名前同士）
    dsts = [dst for _, dst in moves]
    if len(dsts) != len(set(dsts)):
        raise SystemExit(f"{label}: duplicate target names")

    # src が他の dst と一致していないか（不要だが念のため）
    srcs = {s for s, _ in moves}
    for _, dst in moves:
        if dst in srcs:
            raise SystemExit(f"{label}: target overwrites unmoved source {dst.name}")

    tmp_tag = ".__ren_tmp__."
    # Phase 1 → 一時名
    temps: list[tuple[Path, Path]] = []
    for i, (src, dst) in enumerate(moves):
        tmp = folder / f"{tmp_tag}{i:04d}.png"
        if tmp.exists():
            raise SystemExit(f"{label}: temp exists {tmp}")
        temps.append((src, tmp))

    for src, tmp in temps:
        src.rename(tmp)

    # Phase 2 → 最終名（temps の順で dst）
    for (_, tmp), (_, dst) in zip(temps, moves):
        if dst.exists():
            raise SystemExit(f"{label}: destination already exists {dst}")
        tmp.rename(dst)

    print(f"{label}: renamed {len(moves)} files")


def main() -> None:
    all_moves: list[tuple[str, list[tuple[Path, Path]]]] = [
        ("character", plan_folder("character", "tcg_ch")),
        ("monster", plan_folder("monster", "tcg_m")),
    ]

    for label, moves in all_moves:
        # プレビュー
        for src, dst in moves[:5]:
            print(f"  {src.name} -> {dst.name}")
        if len(moves) > 5:
            print(f"  ... ({len(moves) - 5} more)")
        run_moves(moves, label)


if __name__ == "__main__":
    main()
