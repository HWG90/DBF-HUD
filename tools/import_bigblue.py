"""Convert BigBlue's printable ASCII at its native 8x12 grid to lossless rectangles.

Usage: python tools/import_bigblue.py path/to/BigBlueTerminal.zip
Requires Pillow. Does not install fonts or modify the game.
"""
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
NAME = 'BigBlueTerm437NerdFontMono-Regular.ttf'

def rectangles(mask):
    result, active = [], {}
    for y in range(mask.height):
        spans, x = [], 0
        while x < mask.width:
            if not mask.getpixel((x, y)):
                x += 1
                continue
            start = x
            while x < mask.width and mask.getpixel((x, y)):
                x += 1
            spans.append((start, x-start))
        current = {}
        for key in spans:
            if key in active:
                rect = active[key]
                rect[3] += 1
            else:
                rect = [key[0], y, key[1], 1]
                result.append(rect)
            current[key] = rect
        active = current
    return [[x, 12-y-h, w, h] for x, y, w, h in result]

def main(path):
    with zipfile.ZipFile(path) as archive:
        font_bytes = archive.read(NAME)
        font = ImageFont.truetype(io.BytesIO(font_bytes), 12)
        license_dir = ROOT / 'licenses' / 'BigBlueTerminal'
        license_dir.mkdir(parents=True, exist_ok=True)
        for name in ['LICENSE.TXT', 'README.md']:
            (license_dir / name).write_bytes(archive.read(name))
    glyphs = {}
    for code in range(32, 127):
        assert font.getlength(chr(code)) == 8, 'unexpected advance'
        mask = Image.new('L', (8, 16))
        ImageDraw.Draw(mask).text((0, 12), chr(code), font=font, fill=255, anchor='ls')
        assert set(mask.getdata()) <= {0, 255}, 'not a native pixel raster'
        runs = rectangles(mask)
        rebuilt = Image.new('L', mask.size)
        draw = ImageDraw.Draw(rebuilt)
        for x, y, w, h in runs:
            top = 12-y-h
            draw.rectangle((x, top, x+w-1, top+h-1), fill=255)
        assert rebuilt.tobytes() == mask.tobytes(), 'lossy rectangle conversion'
        bbox = mask.getbbox()
        bounds = [bbox[0], 12-bbox[3], bbox[2], 12-bbox[1]] if bbox else [0, 0, 0, 0]
        glyphs[code] = {'bounds': bounds, 'runs': runs}
    header = '-- Generated from BigBlue Terminal (c) 2015 VileR / Nerd Fonts 3.5.1.\n-- Glyph data: CC BY-SA 4.0; see licenses/BigBlueTerminal.\n'
    lines = [header, 'return {']
    for code, g in glyphs.items():
        b = ','.join(map(str, g['bounds']))
        runs = ','.join('{' + ','.join(map(str, r)) + '}' for r in g['runs'])
        lines.append(f'    [{code}]={{bounds={{{b}}},runs={{{runs}}}}},')
    lines.append('}\n')
    (ROOT / 'src' / 'font_data.lua').write_text('\n'.join(lines), encoding='utf-8')
    (ROOT / 'preview' / 'font-data.js').write_text(
        '// BigBlue Terminal (c) 2015 VileR. Glyph data CC BY-SA 4.0. See ../licenses/BigBlueTerminal.\n'
        'const BIGBLUE=' + json.dumps(glyphs, separators=(',', ':')) + ';\n', encoding='utf-8')
    (license_dir / 'IMPORT.txt').write_text(
        'BigBlue Terminal by VileR, copyright 2015.\n'
        'Source: https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/BigBlueTerminal.zip\n'
        f'Font: {NAME}\nSHA256: {hashlib.sha256(font_bytes).hexdigest()}\n'
        'Astra Ammo conversion: printable ASCII rasterized at native 12px height,\n'
        'then losslessly merged into rectangles. No added Nerd Font icons are included.\n'
        'Generated glyph data remains CC BY-SA 4.0. Original license and README accompany it.\n'
        'https://creativecommons.org/licenses/by-sa/4.0/\n', encoding='utf-8')
    print(f'Imported {len(glyphs)} glyphs; exact raster reconstruction verified for every glyph; '
          f'maximum {max(len(g["runs"]) for g in glyphs.values())} rectangles per glyph.')

if __name__ == '__main__':
    main(sys.argv[1])
