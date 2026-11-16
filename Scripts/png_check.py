#!/usr/bin/env python3
"""Pixel checks for simulator screenshots. Pure stdlib: decodes 8-bit
RGB/RGBA PNGs (filters 0-4).

Subcommands:
  bright <png> <min-bright-percent>
      Exit 0 when the fraction of bright pixels (max channel > 40) meets
      the threshold. The watchOS app-launch screen is nearly all black;
      a rendered dashboard is not.
  diff <png1> <png2> <min-diff-percent>
      Exit 0 when the fraction of pixels that differ by more than 20 in
      any channel meets the threshold. Proves the screen actually
      changed: a crashed app leaves the watch face (or the previous
      screen) up, which differs from the new screen by ~0%; a rendered
      app differs from the face by a lot. A clock hand ticking over
      changes far less than 1% of pixels, so it cannot fake a pass.
  size <png> <width> <height>
      Exit 0 when the PNG decodes to exactly the given pixel size.
      Pins the screenshot to the expected device (e.g. 374x446 for a
      42mm watch, 1206x2622 for iPhone 17 Pro).
  color <png> <r> <g> <b> <tolerance> <min-count>
      Exit 0 when at least min-count pixels are within tolerance (per
      channel) of the target color. Used for the app's signature mint
      accent: a rendered dashboard carries thousands of mint pixels,
      a loading screen carries none.

Usage: png_check.py <bright|diff|size|color> ...
"""
import struct
import sys
import zlib


def decode(path):
    """Return (width, height, RGB bytearray) for an 8-bit RGB/RGBA PNG."""
    with open(path, "rb") as f:
        data = f.read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos = 8
    width = height = bit_depth = color_type = None
    idat = b""
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        chunk = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        if chunk == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", payload[:10])
        elif chunk == b"IDAT":
            idat += payload
        elif chunk == b"IEND":
            break
        pos += 12 + length
    assert bit_depth == 8, f"unsupported bit depth {bit_depth}"
    assert color_type in (2, 6), f"unsupported color type {color_type}"
    channels = 3 if color_type == 2 else 4
    raw = zlib.decompress(idat)
    stride = width * channels
    pixels = bytearray(width * height * 3)
    prev = bytearray(stride)
    offset = 0
    out = 0
    for _ in range(height):
        filter_type = raw[offset]
        offset += 1
        line = bytearray(raw[offset:offset + stride])
        offset += stride
        if filter_type == 0:
            pass
        elif filter_type == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 0xFF
        elif filter_type == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif filter_type == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif filter_type == 4:
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 0xFF
        else:
            raise ValueError(f"unknown filter {filter_type}")
        for i in range(0, stride, channels):
            pixels[out:out + 3] = line[i:i + 3]
            out += 3
        prev = line
    return width, height, pixels


def bright_fraction(pixels):
    bright = sampled = 0
    for i in range(0, len(pixels), 6):  # every 2nd pixel
        sampled += 1
        if max(pixels[i], pixels[i + 1], pixels[i + 2]) > 40:
            bright += 1
    return 100.0 * bright / sampled


def diff_fraction(a, b):
    assert len(a) == len(b), "images differ in size"
    changed = sampled = 0
    for i in range(0, len(a), 6):  # every 2nd pixel
        sampled += 1
        if (abs(a[i] - b[i]) > 20 or abs(a[i + 1] - b[i + 1]) > 20
                or abs(a[i + 2] - b[i + 2]) > 20):
            changed += 1
    return 100.0 * changed / sampled


def color_count(pixels, target, tolerance):
    n = 0
    for i in range(0, len(pixels), 3):
        if (abs(pixels[i] - target[0]) <= tolerance
                and abs(pixels[i + 1] - target[1]) <= tolerance
                and abs(pixels[i + 2] - target[2]) <= tolerance):
            n += 1
    return n


def main(argv):
    if len(argv) < 2:
        print("usage: png_check.py <bright|diff> ...")
        return 2
    cmd = argv[1]
    if cmd == "bright":
        _, _, pixels = decode(argv[2])
        minimum = float(argv[3])
        fraction = bright_fraction(pixels)
        print(f"bright pixels: {fraction:.2f}% (threshold {minimum:.2f}%)")
        return 0 if fraction >= minimum else 1
    if cmd == "diff":
        w1, h1, a = decode(argv[2])
        w2, h2, b = decode(argv[3])
        if (w1, h1) != (w2, h2):
            print(f"image sizes differ: {w1}x{h1} vs {w2}x{h2}")
            return 1
        minimum = float(argv[4])
        fraction = diff_fraction(a, b)
        print(f"changed pixels: {fraction:.2f}% (threshold {minimum:.2f}%)")
        return 0 if fraction >= minimum else 1
    if cmd == "size":
        w, h, _ = decode(argv[2])
        ew, eh = int(argv[3]), int(argv[4])
        print(f"size: {w}x{h} (expected {ew}x{eh})")
        return 0 if (w, h) == (ew, eh) else 1
    if cmd == "color":
        _, _, pixels = decode(argv[2])
        target = (int(argv[3]), int(argv[4]), int(argv[5]))
        tolerance = int(argv[6])
        minimum = int(argv[7])
        count = color_count(pixels, target, tolerance)
        print(f"pixels near {target} (±{tolerance}): {count} (minimum {minimum})")
        return 0 if count >= minimum else 1
    print(f"unknown subcommand: {cmd}")
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
