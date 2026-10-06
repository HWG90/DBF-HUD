"""Prepare a separate linear RGBA8 upload from the approved sRGB atlas.

Alpha repair removes the generated matte, independently of RGB decoding.
Never run this on an already prepared linear payload.
"""
from PIL import Image, ImageChops

def linear_byte(value):
    v = value / 255.0
    return round(255 * (v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4))

def foreground_alpha(value):
    t = max(0.0, min(1.0, (value - 225) / 25.0))
    return round(255 * t * t * (3 - 2 * t))

def prepare(source):
    image = Image.open(source).convert('RGBA')
    red, green, blue, alpha = image.split()
    rgb_lut = [linear_byte(i) for i in range(256)]
    alpha_lut = [foreground_alpha(i) for i in range(256)]
    repaired_alpha = alpha.point(alpha_lut)
    visible = repaired_alpha.point([0] + [255] * 255)
    # Empty texels carry no residual RGB, avoiding matte leakage and filter bleed.
    channels = [ImageChops.multiply(c.point(rgb_lut), visible) for c in (red, green, blue)]
    corrected = Image.merge('RGBA', (*channels, repaired_alpha))
    return corrected.size, corrected.tobytes()
