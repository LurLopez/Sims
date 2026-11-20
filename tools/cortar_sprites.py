#!/usr/bin/env python3
"""Cut sprite sheets with a transparent OR magenta background into named PNGs.

Usage:
  python3 tools/cortar_sprites.py <sheet.png> <out-dir> --names a,b,c [--rows 2]
      [--pad 6] [--min-area 400] [--join 40] [--scale 1.0] [--preview preview.png]
      [--no-trim-white]

- If the image already has an alpha channel with a meaningful transparent area, it is used as is.
- Otherwise the flat magenta background is keyed out (same maths as the game-asset-pipeline
  cut_sheet.py), including despill.
- Sprites are found as connected blobs (small fragments near a big blob are merged into it),
  grouped into rows by vertical gaps, then sorted left to right.
- --trim-white removes leftover white sticker halo: pixels near pure white that sit within
  --halo px of the transparent edge and are not part of a large opaque area.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

try:
    import cv2
except ImportError:  # pragma: no cover
    cv2 = None
    from scipy import ndimage


def key_magenta(img):
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    m = np.clip((np.minimum(r, b) - g) / 255.0, 0, 1)
    alpha = np.clip(1.0 - (m - 0.35) / 0.4, 0, 1)
    spill = np.clip(np.minimum(r, b) - g, 0, None) * (1 - alpha)
    rgb[..., 0] -= spill
    rgb[..., 2] -= spill
    out = np.dstack([np.clip(rgb, 0, 255), alpha * 255]).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def has_alpha(img):
    if img.mode not in ("RGBA", "LA"):
        return False
    a = np.asarray(img.convert("RGBA"))[..., 3]
    return (a < 16).mean() > 0.02


def trim_white_halo(im: Image.Image, halo_px: int = 18) -> Image.Image:
    """Remove the wispy near-white sticker shadow left outside the subject."""
    arr = np.asarray(im.convert("RGBA")).copy()
    rgb = arr[..., :3].astype(np.int16)
    a = arr[..., 3]
    solid = a > 8
    if not solid.any() or cv2 is None:
        return im
    # Distance from the transparent outside, inside the solid silhouette.
    dist_out = cv2.distanceTransform(solid.astype(np.uint8), cv2.DIST_L2, 5)
    # Near-white / light grey with almost no colour: typical shadow or sticker fringe.
    near_white = (rgb.min(axis=2) > 232) & ((rgb.max(axis=2) - rgb.min(axis=2)) < 18)
    # The subject can be white too (plates), so only erase it near the outer silhouette
    # and only when it is thin: check how much solid area survives inside a local window.
    erasing = near_white & (dist_out <= halo_px)
    if not erasing.any():
        return im
    # Keep white pixels that belong to a wide region (plates, cups): erode the near-white mask.
    kernel = np.ones((7, 7), np.uint8)
    wide_white = cv2.erode(near_white.astype(np.uint8), kernel).astype(bool)
    erasing &= ~wide_white
    arr[erasing, 3] = 0
    return Image.fromarray(arr, "RGBA")


def clean_specks(im: Image.Image) -> Image.Image:
    """Drop tiny opaque specks that float far from the main silhouette of one sprite."""
    if cv2 is None:
        return im
    arr = np.asarray(im.convert("RGBA")).copy()
    mask = (arr[..., 3] > 8).astype(np.uint8)
    if mask.sum() == 0:
        return im
    num, labels, stats, _ = cv2.connectedComponentsWithStats(mask, connectivity=8)
    if num <= 2:
        return im
    main = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    main_area = float(stats[main, cv2.CC_STAT_AREA])
    mx0, my0 = stats[main, cv2.CC_STAT_LEFT], stats[main, cv2.CC_STAT_TOP]
    mx1 = mx0 + stats[main, cv2.CC_STAT_WIDTH]
    my1 = my0 + stats[main, cv2.CC_STAT_HEIGHT]
    for i in range(1, num):
        if i == main:
            continue
        x0, y0 = stats[i, cv2.CC_STAT_LEFT], stats[i, cv2.CC_STAT_TOP]
        x1 = x0 + stats[i, cv2.CC_STAT_WIDTH]
        y1 = y0 + stats[i, cv2.CC_STAT_HEIGHT]
        gap = max(mx0 - x1, 0, x0 - mx1) + max(my0 - y1, 0, y0 - my1)
        area = float(stats[i, cv2.CC_STAT_AREA])
        if area < max(64.0, main_area * 0.01) and gap > 12:
            arr[labels == i, 3] = 0
    return Image.fromarray(arr, "RGBA")


def find_sprites(alpha, min_area, join):
    solid = alpha > 8
    if cv2 is not None:
        kernel = np.array([[0, 1, 0], [1, 1, 1], [0, 1, 0]], np.uint8)
        mask = cv2.dilate(solid.astype(np.uint8), kernel, iterations=2)
        num, labels, stats, _ = cv2.connectedComponentsWithStats(mask, connectivity=8)
        count = num - 1
        boxes = [
            (slice(stats[i, cv2.CC_STAT_TOP], stats[i, cv2.CC_STAT_TOP] + stats[i, cv2.CC_STAT_HEIGHT]),
             slice(stats[i, cv2.CC_STAT_LEFT], stats[i, cv2.CC_STAT_LEFT] + stats[i, cv2.CC_STAT_WIDTH]))
            for i in range(1, num)
        ]
        areas = np.bincount(labels[solid], minlength=num)[1:]
    else:
        labels, count = ndimage.label(ndimage.binary_dilation(solid, iterations=2))
        boxes = ndimage.find_objects(labels)
        areas = ndimage.sum(solid, labels, range(1, count + 1))
    big = [i for i in range(count) if areas[i] >= min_area]
    small = [i for i in range(count) if areas[i] < min_area]
    rects = {i: [boxes[i][1].start, boxes[i][0].start, boxes[i][1].stop, boxes[i][0].stop] for i in big}
    for i in small:
        s = boxes[i]
        cx, cy = (s[1].start + s[1].stop) / 2, (s[0].start + s[0].stop) / 2
        best, dist = None, join
        for j, (x0, y0, x1, y1) in rects.items():
            d = max(x0 - cx, 0, cx - x1) + max(y0 - cy, 0, cy - y1)
            if d <= dist:
                best, dist = j, d
        if best is not None:
            x0, y0, x1, y1 = rects[best]
            rects[best] = [min(x0, s[1].start), min(y0, s[0].start), max(x1, s[1].stop), max(y1, s[0].stop)]
    return list(rects.values())


def reading_order(rects, rows):
    rects = sorted(rects, key=lambda r: (r[1] + r[3]) / 2)
    centres = [(r[1] + r[3]) / 2 for r in rects]
    gaps = sorted(range(1, len(rects)), key=lambda i: centres[i] - centres[i - 1], reverse=True)
    cuts = sorted(gaps[:max(0, rows - 1)])
    ordered, start = [], 0
    for end in cuts + [len(rects)]:
        ordered += sorted(rects[start:end], key=lambda r: r[0])
        start = end
    return ordered


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet")
    ap.add_argument("out")
    ap.add_argument("--names")
    ap.add_argument("--rows", type=int, default=2)
    ap.add_argument("--grid", default="", help="cut equal cells, e.g. 4x3 (cols x rows)")
    ap.add_argument("--pad", type=int, default=6)
    ap.add_argument("--min-area", type=int, default=400)
    ap.add_argument("--join", type=int, default=40)
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--preview")
    ap.add_argument("--erode", type=int, default=0,
                    help="erode alpha by N px to remove a white keying fringe")
    ap.add_argument("--alpha-cutoff", type=int, default=0,
                    help="drop pixels below this alpha (removes a baked checkerboard)")
    ap.add_argument("--trim-white", action="store_true")
    ap.add_argument("--no-clean", action="store_true",
                    help="keep tiny detached specks (use for effects sheets)")
    a = ap.parse_args()

    out = Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    src = Image.open(a.sheet)
    keyed = src.convert("RGBA") if has_alpha(src) else key_magenta(src)
    if a.trim_white:
        keyed = trim_white_halo(keyed)
    if a.alpha_cutoff > 0:
        arr = np.asarray(keyed).copy()
        arr[..., 3] = np.where(arr[..., 3] >= a.alpha_cutoff, arr[..., 3], 0)
        keyed = Image.fromarray(arr, "RGBA")
    if a.erode > 0:
        arr = np.asarray(keyed).copy()
        n = a.erode
        kernel = np.ones((2 * n + 1, 2 * n + 1), np.uint8)
        if cv2 is None:
            raise SystemExit("--erode needs OpenCV")
        mask = cv2.erode((arr[..., 3] > 8).astype(np.uint8), kernel)
        arr[..., 3] = np.where(mask > 0, arr[..., 3], 0)
        keyed = Image.fromarray(arr, "RGBA")
    alpha = np.asarray(keyed)[..., 3]
    if a.grid:
        cols_s, rows_s = a.grid.lower().split("x")
        cols, grid_rows = int(cols_s), int(rows_s)
        rects = []
        for gy in range(grid_rows):
            for gx in range(cols):
                x0 = int(gx * keyed.width / cols)
                x1 = int((gx + 1) * keyed.width / cols)
                y0 = int(gy * keyed.height / grid_rows)
                y1 = int((gy + 1) * keyed.height / grid_rows)
                cell_a = alpha[y0:y1, x0:x1]
                ys, xs = np.where(cell_a > 8)
                if len(xs) == 0:
                    continue
                rects.append([x0 + int(xs.min()), y0 + int(ys.min()),
                              x0 + int(xs.max()) + 1, y0 + int(ys.max()) + 1])
    else:
        rects = reading_order(find_sprites(alpha, a.min_area, a.join), a.rows)
    names = a.names.split(",") if a.names else [f"f{i + 1}" for i in range(len(rects))]
    if len(names) != len(rects):
        print(f"warning: found {len(rects)} sprites but {len(names)} names; check --preview")
    if a.preview:
        prev = Image.new("RGB", keyed.size, (190, 190, 190))
        prev.paste(keyed, (0, 0), keyed)
        d = ImageDraw.Draw(prev)
        for i, (x0, y0, x1, y1) in enumerate(rects):
            d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], outline=(255, 0, 0), width=3)
            if i < len(names):
                d.text((x0 + 4, max(0, y0 - 16)), names[i], fill=(0, 0, 0))
        prev.save(a.preview)

    manifest = []
    for name, (x0, y0, x1, y1) in zip(names, rects):
        if name in ("", "-", "none"):
            continue
        box = (max(0, x0 - a.pad), max(0, y0 - a.pad), min(keyed.width, x1 + a.pad), min(keyed.height, y1 + a.pad))
        im = keyed.crop(box)
        if not a.no_clean:
            im = clean_specks(im)
        if a.scale != 1.0:
            im = im.resize((max(1, round(im.width * a.scale)), max(1, round(im.height * a.scale))), Image.LANCZOS)
        im.save(out / f"{name}.png")
        manifest.append({"name": name, "w": int(im.width), "h": int(im.height), "x": int(box[0]), "y": int(box[1])})
    (out / "_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"{len(manifest)} sprites -> {out}")


if __name__ == "__main__":
    main()
