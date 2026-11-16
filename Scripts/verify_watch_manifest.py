#!/usr/bin/env python3
"""Strictly verify the Watch screenshot manifest and its PNGs.

This runs in the workflow's Verify step, independent of the capture
script, so a bad manifest or a bad shot fails the job even if the
capture step somehow exited 0. Checks:
  - watch-manifest.json parses as strict JSON.
  - device, runtime, mode, bundleId are present non-empty strings.
  - home/sleep entries: file exists, bytes equals the actual file size,
    pid is a positive integer (not a failure message).
  - each watch PNG decodes, has the size expected for the named device
    (42mm 374x446, 41mm 352x430, 45mm 396x484, 46mm 410x502), shows real
    content (bright pixels >= 1%, so not a loading screen), and carries
    the app's mint accent (>= 100 mint pixels).

Usage: verify_watch_manifest.py <screenshots dir>
Exit 0 only when every check passes.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import png_check

DEVICE_SIZES = {
    "42mm": (374, 446),
    "41mm": (352, 430),
    "45mm": (396, 484),
    "46mm": (410, 502),
}
MINT = (32, 178, 150)


def fail(message):
    print(f"FAIL: {message}")
    sys.exit(1)


def main(argv):
    if len(argv) != 2:
        print("usage: verify_watch_manifest.py <screenshots dir>")
        return 2
    directory = argv[1]
    manifest_path = os.path.join(directory, "watch-manifest.json")
    if not os.path.isfile(manifest_path):
        fail("watch-manifest.json missing")
    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except json.JSONDecodeError as exc:
        fail(f"watch-manifest.json is not valid JSON: {exc}")

    for key in ("device", "runtime", "mode", "bundleId"):
        value = manifest.get(key)
        if not isinstance(value, str) or not value:
            fail(f"watch-manifest.json: {key} missing or empty")
    device = manifest["device"]
    print(f"device: {device}, runtime: {manifest['runtime']}, mode: {manifest['mode']}")

    expected_size = None
    for size_key, size in DEVICE_SIZES.items():
        if size_key in device:
            expected_size = size
            break
    if expected_size is None:
        print(f"WARNING: unknown device size for {device!r}; size check skipped")

    for view in ("home", "sleep"):
        entry = manifest.get(view)
        if not isinstance(entry, dict):
            fail(f"watch-manifest.json: {view} entry missing")
        filename = entry.get("file")
        if not isinstance(filename, str) or not filename:
            fail(f"watch-manifest.json: {view}.file missing")
        path = os.path.join(directory, filename)
        if not os.path.isfile(path):
            fail(f"{view} screenshot missing: {filename}")
        actual_bytes = os.path.getsize(path)
        if entry.get("bytes") != actual_bytes:
            fail(f"{view} bytes mismatch: manifest says {entry.get('bytes')}, "
                 f"file is {actual_bytes}")
        pid = entry.get("pid")
        if not isinstance(pid, int) or pid <= 0:
            fail(f"{view} pid is not a positive integer: {pid!r}")
        print(f"{view}: {filename}, {actual_bytes} bytes, pid {pid}")

        width, height, pixels = png_check.decode(path)
        if expected_size is not None and (width, height) != expected_size:
            fail(f"{view} screenshot is {width}x{height}, expected "
                 f"{expected_size[0]}x{expected_size[1]} for {device}")
        bright = png_check.bright_fraction(pixels)
        if bright < 1.0:
            fail(f"{view} screenshot looks like a loading screen: "
                 f"bright pixels {bright:.2f}%")
        mint = png_check.color_count(pixels, MINT, 60)
        if mint < 100:
            fail(f"{view} screenshot shows no app mint accent "
                 f"({mint} mint pixels): not the app screen")
        print(f"{view}: {width}x{height}, bright {bright:.2f}%, "
              f"mint pixels {mint} OK")

    print("OK: watch manifest and screenshots verified")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
