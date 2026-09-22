#!/usr/bin/env python3
"""Build the transparent Bitcoin-miner NPC atlas from its Library source sheet.

The source is a presentation sheet, so only the four-by-four miner cells are
used. Background removal is a border-connected flood fill; it never recolors
or regenerates character pixels.
"""

from collections import deque
import hashlib
from pathlib import Path
import sys

from PIL import Image


FRAME_SIZE = 128
FOOT_Y = 120
SOURCE_SHA256 = "dd05cec14e90d974b0a20feca6b94a3c0528eb28e7f5478e5159ad213e4c1e76"
COLUMN_CENTERS = (190, 326, 462, 598)
SOURCE_ROWS = {
    "down": (46, 149),
    "up": (151, 257),
    "left": (259, 371),
    "right": (376, 510),
}
OUTPUT_ROWS = ("down", "left", "right", "up")


def is_background(pixel: tuple[int, int, int], reference: tuple[int, int, int]) -> bool:
    return max(abs(pixel[channel] - reference[channel]) for channel in range(3)) <= 28


def remove_connected_background(crop: Image.Image) -> Image.Image:
    rgb = crop.convert("RGB")
    width, height = rgb.size
    border = []
    for x in range(width):
        border.extend((rgb.getpixel((x, 0)), rgb.getpixel((x, height - 1))))
    for y in range(height):
        border.extend((rgb.getpixel((0, y)), rgb.getpixel((width - 1, y))))
    reference = tuple(sorted(pixel[channel] for pixel in border)[len(border) // 2] for channel in range(3))

    transparent = set()
    queue = deque()
    for x in range(width):
        queue.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        queue.extend(((0, y), (width - 1, y)))
    while queue:
        point = queue.popleft()
        if point in transparent:
            continue
        if not is_background(rgb.getpixel(point), reference):
            continue
        transparent.add(point)
        x, y = point
        if x:
            queue.append((x - 1, y))
        if x + 1 < width:
            queue.append((x + 1, y))
        if y:
            queue.append((x, y - 1))
        if y + 1 < height:
            queue.append((x, y + 1))

    rgba = rgb.convert("RGBA")
    alpha = rgba.getchannel("A")
    for point in transparent:
        alpha.putpixel(point, 0)
    rgba.putalpha(alpha)
    return rgba


def build(source_path: Path, output_path: Path) -> None:
    source_digest = hashlib.sha256(source_path.read_bytes()).hexdigest()
    if source_digest != SOURCE_SHA256:
        raise ValueError(f"unexpected Library source SHA-256: {source_digest}")
    source = Image.open(source_path)
    source.load()
    if source.size != (1536, 1024):
        raise ValueError(f"unexpected source dimensions: {source.size}")

    atlas = Image.new("RGBA", (FRAME_SIZE * 4, FRAME_SIZE * 4), (0, 0, 0, 0))
    for output_row, facing in enumerate(OUTPUT_ROWS):
        top, bottom = SOURCE_ROWS[facing]
        for column, center_x in enumerate(COLUMN_CENTERS):
            crop = source.crop((center_x - 58, top, center_x + 58, bottom))
            isolated = remove_connected_background(crop)
            bbox = isolated.getbbox()
            if bbox is None:
                raise ValueError(f"empty frame: {facing} {column}")
            isolated = isolated.crop(bbox)
            if isolated.width > FRAME_SIZE or isolated.height > FOOT_Y:
                raise ValueError(f"oversized frame: {facing} {column} {isolated.size}")
            destination = (
                column * FRAME_SIZE + (FRAME_SIZE - isolated.width) // 2,
                output_row * FRAME_SIZE + FOOT_Y - isolated.height,
            )
            atlas.alpha_composite(isolated, destination)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output_path, format="PNG", optimize=False)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: build_npc_miner_sheet.py SOURCE OUTPUT")
    build(Path(sys.argv[1]), Path(sys.argv[2]))
