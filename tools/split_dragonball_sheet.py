#!/usr/bin/env python3
"""
Split a 7-ball spritesheet (opaque PNG, checkerboard background) into
orb_full_1.png … orb_full_7.png using HSV orange segmentation + fixed layout map.

Usage:
  python tools/split_dragonball_sheet.py [input.png] [output_dir]
"""
from __future__ import annotations

import sys
from pathlib import Path

import cv2
import numpy as np


def segment_orange_mask(bgr: np.ndarray) -> np.ndarray:
    hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
    lower1 = np.array([0, 80, 80])
    upper1 = np.array([25, 255, 255])
    m1 = cv2.inRange(hsv, lower1, upper1)
    k = np.ones((9, 9), np.uint8)
    m = cv2.morphologyEx(m1, cv2.MORPH_CLOSE, k)
    m = cv2.morphologyEx(m, cv2.MORPH_OPEN, np.ones((5, 5), np.uint8))
    return m


def bbox_key(x: int, y: int) -> tuple[int, int]:
    return (int(round(x / 10.0) * 10), int(round(y / 10.0) * 10))


def main() -> int:
    default_in = Path(
        "/Users/aaron/.cursor/projects/Users-aaron-git-roblox-dragonball/assets/"
        "hd-dragon-ball-z-dbz-seven-crystal-balls-png-701751694862297tx7tltnwqa-f82d9d30-0482-4fc0-b522-3c3614998fb9.png"
    )
    in_path = Path(sys.argv[1]) if len(sys.argv) > 1 else default_in
    out_dir = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("assets-src/orbs")
    out_dir.mkdir(parents=True, exist_ok=True)

    if not in_path.is_file():
        print(f"Missing input: {in_path}", file=sys.stderr)
        return 1

    bgr = cv2.imread(str(in_path))
    if bgr is None:
        print(f"Could not read image: {in_path}", file=sys.stderr)
        return 1

    mask = segment_orange_mask(bgr)
    n, _labels, stats, _centroids = cv2.connectedComponentsWithStats(mask, connectivity=8)
    boxes: list[tuple[int, int, int, int, int]] = []
    for i in range(1, n):
        area = int(stats[i, cv2.CC_STAT_AREA])
        if area < 2000:
            continue
        x = int(stats[i, cv2.CC_STAT_LEFT])
        y = int(stats[i, cv2.CC_STAT_TOP])
        w = int(stats[i, cv2.CC_STAT_WIDTH])
        h = int(stats[i, cv2.CC_STAT_HEIGHT])
        boxes.append((x, y, w, h, area))

    if len(boxes) != 7:
        print(f"Expected 7 orange blobs, got {len(boxes)}: {boxes}", file=sys.stderr)
        return 2

    # Layout from spritesheet (top→bottom, left→right): 1,2 / 6,7,3 / 5,4
    layout_map: dict[tuple[int, int], int] = {
        bbox_key(147, 57): 1,
        bbox_key(451, 64): 2,
        bbox_key(44, 297): 6,
        bbox_key(296, 298): 7,
        bbox_key(553, 298): 3,
        bbox_key(172, 537): 5,
        bbox_key(450, 543): 4,
    }

    def match_star(x: int, y: int) -> int:
        k = bbox_key(x, y)
        if k in layout_map:
            return layout_map[k]
        # nearest layout key (tolerate ±15px drift across exports)
        best = min(layout_map.keys(), key=lambda q: (q[0] - k[0]) ** 2 + (q[1] - k[1]) ** 2)
        if (best[0] - k[0]) ** 2 + (best[1] - k[1]) ** 2 > 40 * 40:
            raise RuntimeError(f"Unmatched bbox ({x},{y}), keys={list(layout_map)}")
        return layout_map[best]

    rgba = cv2.cvtColor(bgr, cv2.COLOR_BGR2BGRA)
    # checker → transparent: dim neutral background
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    bg = gray < 90
    rgba[:, :, 3] = np.where(bg, 0, 255).astype(np.uint8)

    for x, y, w, h, _area in boxes:
        star = match_star(x, y)
        side = max(w, h) + 24
        cx, cy = x + w // 2, y + h // 2
        x0 = max(0, cx - side // 2)
        y0 = max(0, cy - side // 2)
        x1 = min(rgba.shape[1], x0 + side)
        y1 = min(rgba.shape[0], y0 + side)
        crop = rgba[y0:y1, x0:x1].copy()
        # pad to square if near edge
        ch, cw = crop.shape[:2]
        if ch != cw:
            side2 = max(ch, cw)
            pad = np.zeros((side2, side2, 4), dtype=np.uint8)
            pad[:ch, :cw] = crop
            crop = pad

        out_path = out_dir / f"orb_full_{star}.png"
        cv2.imwrite(str(out_path), crop)
        print(f"wrote {out_path} ({crop.shape[1]}x{crop.shape[0]})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
