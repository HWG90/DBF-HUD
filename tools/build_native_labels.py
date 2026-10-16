"""Copy bounded Split labels from owned native font pixels; never rasterize a font.

Only integral native metrics are supported. Unsupported fonts/strings keep their
original per-glyph renderer. No game files, runtime uploads or shader edits.
"""
from pathlib import Path
import argparse
import hashlib
import json
import math
import re
import struct
import zipfile

from build_native_font_depth import hash64
from build_scene_depth_probe import archive_rows

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'assets/native-labels'
FONTS = ('hack', 'bigblue')
MATERIAL = 'mods/dbf_hud/materials/adjudicator_tall_v1'
STATIC = '''ROUNDS|SHELLS|LOADED|HEAT|ENERGY|FUEL|GAS|CHARGE|COOLDOWN|CHARGE LEVEL|
MAGS|BELTS|SINKS|SHOTS|TANKS|PACK|CANISTERS|RES|ONE SHOT|CONTINUOUS|NO DATA|
RELOADING|SPENT|EMPTY|VENTING|HOT|LOW FUEL|LOW GAS|LOW AMMO|RELOAD ADVISED|
LIMIT|RELEASE|SAFE READY|CHARGED|CHARGING|COOLING|GET SOME!!!|FIRE SELECT|
FIRE RATE|AMMUNITION|SAFETY|SUPPLY|AUTO|SEMI|BURST|ALT|VOLLEY|SAFE|UNSAFE|
SINGLE USE|HE|HEAT|FLAK|AP|APHE|AIRBURST|CLUSTER|WEAPON'''


def vocabulary():
    words = {s.strip() for s in STATIC.replace('\n', '').split('|') if s.strip()}
    words.update(re.findall(r"code='([^']+)'", (ROOT / 'src/segmented_primary_specs.lua').read_text()))
    words.update(s.split()[0] for s in re.findall(r'=\s*"([^"]+)"', (ROOT / 'src/weapon_names.lua').read_text()))
    assert len(words) <= 256 and all(1 < len(s) <= 24 and s.isascii() for s in words)
    return sorted(words)


def source_rows():
    """Read only the two donor atlases, not the complete 1 GB native GPU file."""
    folder = ROOT / 'assets/native-runtime'
    info = json.loads((folder / 'provenance.json').read_text())
    path = folder / 'hud-native.zip'
    assert hashlib.sha256(path.read_bytes()).hexdigest() == info['archive_sha256']
    with zipfile.ZipFile(path) as z:
        stem = 'ee6b1ba7e22d71ed.patch_0'
        body = z.read(stem)
        assert hashlib.sha256(body).hexdigest() == info['files'][stem]['sha256']
        _, nt, n = struct.unpack_from('<III', body)
        rows = list(struct.iter_unpack('<7Q6I', body[72 + nt * 32:72 + nt * 32 + n * 80]))
        wanted = {hash64('mods/dbf_hud/fonts/native_' + font): font for font in FONTS}
        fonts, textures = {}, {}
        for r in rows:
            if r[0] in wanted and r[1] == hash64('font'):
                fonts[wanted[r[0]]] = body[r[2]:r[2] + r[7]]
        with z.open(stem + '.gpu_resources') as gpu:
            for r in sorted(rows, key=lambda row: row[4]):
                if r[0] not in wanted or r[1] != hash64('texture'):
                    continue
                tex = body[r[2]:r[2] + r[7]]
                h, w = struct.unpack_from('<II', tex, 204)
                gpu.seek(r[4]); pixels = gpu.read(w * h * 4)
                assert len(pixels) == w * h * 4
                textures[wanted[r[0]]] = (tex, w, h, pixels)
    return fonts, textures, info['archive_sha256']


def metrics(data):
    ids = struct.unpack_from('<193I', data, 88)
    out = {}
    baseline = struct.unpack_from('<f', data, 16)[0]
    for i, cp in enumerate(ids):
        if 32 <= cp <= 126:
            x, y, w, h, left, offset, advance = struct.unpack_from('<7f', data, 860 + i * 28)
            top = baseline - offset
            # Pixel addresses and advances must be exact; never round another font.
            values = (x, y, w, h, left, top, advance)
            assert all(v == int(v) for v in values), 'Non-integral donor metrics'
            # Native font records reserve a 1x1 empty cell for space. The
            # maintained metrics give its full advance and zero ink height.
            if cp == 32:
                w, h, left, top = advance, 0, 0, 0
            out[chr(cp)] = tuple(int(v) for v in (x, y, w, h, left, top, advance))
    return out


def render_label(source, glyphs, text):
    from PIL import Image
    left = min(sum(glyphs[c][6] for c in text[:i]) + glyphs[ch][4] for i, ch in enumerate(text))
    right = max(sum(glyphs[c][6] for c in text[:i]) + glyphs[ch][4] + glyphs[ch][2] for i, ch in enumerate(text))
    top = max(glyphs[ch][5] for ch in text)
    bottom = min(glyphs[ch][5] - glyphs[ch][3] for ch in text)
    result = Image.new('RGBA', (right - left, top - bottom), (255, 255, 255, 0))
    advance = 0
    for ch in text:
        x, y, w, h, bearing, ascent, step = glyphs[ch]
        if w and h:
            glyph = source.crop((x, y, x + w, y + h))
            at = (advance + bearing - left, top - ascent)
            # Same-color glyphs have exact source-over alpha if their boxes overlap.
            result.alpha_composite(glyph, at)
        advance += step
    return result, (left, bottom, right, top)


def build():
    from PIL import Image
    fonts, textures, donor = source_rows()
    words = vocabulary(); resource_rows, metadata, proofs = [], {}, {}
    FOLDER.mkdir(parents=True, exist_ok=True)
    for name in FONTS:
        template, sw, sh, pixels = textures[name]
        source = Image.frombytes('RGBA', (sw, sh), pixels)
        glyphs = metrics(fonts[name]); labels = []
        for word in words:
            image, box = render_label(source, glyphs, word)
            labels.append((word, image, box))
        # Sixteen transparent texels on each side isolate normal minification
        # from neighboring labels, including the LANCZOS mip filter support.
        width, gap, x, y, shelf = 2048, 32, 16, 16, 0
        placements = []
        for word, image, box in labels:
            if x + image.width + gap > width:
                x, y, shelf = gap // 2, y + shelf + gap, 0
            placements.append((word, image, box, x, y))
            x += image.width + gap; shelf = max(shelf, image.height)
        height = 1 << math.ceil(math.log2(y + shelf + gap))
        assert height <= 4096, 'Static label atlas exceeded bound'
        atlas = Image.new('RGBA', (width, height), (255, 255, 255, 0))
        entries = {}
        for word, image, box, x, y in placements:
            atlas.paste(image, (x, y))
            assert atlas.crop((x, y, x + image.width, y + image.height)).tobytes() == image.tobytes()
            entries[word] = {'box': list(box), 'uv': [x / width, y / height, image.width / width, image.height / height]}
        resource = 'mods/dbf_hud/textures/native_labels_' + name + '_v1'
        tex = bytearray(template)
        struct.pack_into('<II', tex, 204, height, width)
        struct.pack_into('<I', tex, 212, width * 4)
        mip_count = int(math.log2(max(width, height))) + 1
        struct.pack_into('<I', tex, 220, mip_count)
        gpu = bytearray(); mip = atlas
        while True:
            gpu.extend(mip.tobytes())
            if mip.width == 1 and mip.height == 1:
                break
            # The source native-font builder uses this same straight-alpha filter.
            mip = mip.resize((max(1, mip.width // 2), max(1, mip.height // 2)), Image.Resampling.LANCZOS)
        resource_rows.append((hash64(resource), hash64('texture'), bytes(tex), bytes(gpu)))
        metadata[name] = {'resource': resource, 'labels': entries}
        proofs[name] = {'labels': len(entries), 'width': width, 'height': height, 'mips': mip_count,
                        'source_rgba_sha256': hashlib.sha256(pixels).hexdigest(),
                        'rgba_sha256': hashlib.sha256(atlas.tobytes()).hexdigest(),
                        'native_em': 48, 'integral_metrics': True, 'new_font_rasterization': False}
    body, gpu = archive_rows(resource_rows)
    target = FOLDER / 'native-labels.zip'
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, data in (('labels.patch_0', body), ('labels.patch_0.gpu_resources', gpu)):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0)); info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, data)
    lines = ['-- Generated by tools/build_native_labels.py; copied native pixels, no new font rasterization.',
             'local M={material=' + json.dumps(MATERIAL) + ',faces={}}']
    for name, entry in metadata.items():
        lines.append('M.faces[' + json.dumps(name) + ']={resource=' + json.dumps(entry['resource']) + ',em=48,labels={')
        for word, label in entry['labels'].items():
            numbers = lambda values: ','.join(format(v, '.12g') for v in values)
            lines.append('[' + json.dumps(word) + ']={box={' + numbers(label['box']) + '},uv={' + numbers(label['uv']) + '}},')
        lines.append('}}')
    lines.append('return M')
    (ROOT / 'src/native_label_data.lua').write_text('\n'.join(lines) + '\n')
    proof = {'source_archive_sha256': donor, 'fonts': proofs, 'archive_sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
             'files': {'labels.patch_0': hashlib.sha256(body).hexdigest(), 'labels.patch_0.gpu_resources': hashlib.sha256(gpu).hexdigest()},
             'live_visual_verified': False, 'dynamic_labels': 'original native glyph path', 'shader_changes': False}
    (FOLDER / 'provenance.json').write_text(json.dumps(proof, indent=2) + '\n')
    print('Copied', len(words), 'static labels for', ', '.join(FONTS), 'from owned native atlas pixels:', target)


def resources():
    """Release builders read the small, verified source-owned texture artifact."""
    info = json.loads((FOLDER / 'provenance.json').read_text())
    path = FOLDER / 'native-labels.zip'
    assert hashlib.sha256(path.read_bytes()).hexdigest() == info['archive_sha256'], 'Native label archive changed'
    with zipfile.ZipFile(path) as z:
        body, gpu = z.read('labels.patch_0'), z.read('labels.patch_0.gpu_resources')
    assert hashlib.sha256(body).hexdigest() == info['files']['labels.patch_0']
    assert hashlib.sha256(gpu).hexdigest() == info['files']['labels.patch_0.gpu_resources']
    _, nt, n = struct.unpack_from('<III', body)
    rows = [(r[0], r[1], body[r[2]:r[2] + r[7]], gpu[r[4]:r[4] + r[9]])
            for r in struct.iter_unpack('<7Q6I', body[72 + nt * 32:72 + nt * 32 + n * 80])]
    assert len(rows) == len(FONTS) and all(r[1] == hash64('texture') for r in rows)
    for row in rows:
        h, w, pitch = struct.unpack_from('<III', row[2], 204)
        mips = struct.unpack_from('<I', row[2], 220)[0]
        assert w == 2048 and 1 <= h <= 4096 and h & (h - 1) == 0 and pitch == w * 4
        assert mips == max(w, h).bit_length()
        expected = sum(max(1, w >> i) * max(1, h >> i) * 4 for i in range(mips))
        assert len(row[3]) == expected, 'Native label mip chain size changed'
    return rows


if __name__ == '__main__':
    parser = argparse.ArgumentParser(); parser.add_argument('--check', action='store_true'); args = parser.parse_args()
    if args.check:
        print('PASS verified source-owned native label texture rows:', len(resources()))
    else:
        build()
