"""Convert an image offline to tightly packed RGBA8; never deploy or load the game."""
import argparse
import json
import hashlib
from pathlib import Path
from PIL import Image


def prepare(source, output, red_mask=False):
    if output.suffix.lower() != '.rgba' or source.resolve() == output.resolve():
        raise ValueError('Choose a separate .rgba output file')
    with Image.open(source) as image:
        width, height = image.size
        if not (1 <= width <= 2048 and 1 <= height <= 2048):
            raise ValueError('Runtime images must be between 1 and 2048 pixels per dimension')
        if red_mask:
            red = image.convert('RGBA').getchannel('R')
            zero = Image.new('L', image.size, 0)
            alpha = Image.new('L', image.size, 255)
            rgba = Image.merge('RGBA', (red, zero, zero, alpha)).tobytes()
        else:
            rgba = image.convert('RGBA').tobytes()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(rgba)
    metadata = dict(format='RGBA8', width=width, height=height, row_pitch=width*4,
                    byte_count=len(rgba), channel_policy='red-mask' if red_mask else 'rgba',
                    sha256=hashlib.sha256(rgba).hexdigest())
    output.with_suffix('.json').write_text(json.dumps(metadata, indent=2)+'\n')
    return metadata


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--red-mask', action='store_true', help='Preserve R; set G/B=0 and A=255 for lens masks')
    args = parser.parse_args()
    print(json.dumps(prepare(args.source, args.output, args.red_mask), indent=2))
