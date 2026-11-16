#!/usr/bin/env python3
"""Repair an XcodeGen watch embed phase for Xcode 26+ without touching other phases.
https://github.com/yonaskolb/XcodeGen/issues/1613
"""
import pathlib
import re
import sys

p = pathlib.Path(sys.argv[1])
s = p.read_text(encoding='utf-8')
pattern = re.compile(r'(\b[A-F0-9]{24} /\* Embed Watch Content \*/ = \{[^}]*\};)', re.S)
count = 0

def patch(match):
    global count
    block = match.group(1)
    if 'isa = PBXCopyFilesBuildPhase;' not in block or 'dstSubfolderSpec = 16;' not in block:
        return block
    count += 1
    block = block.replace('dstSubfolderSpec = 16;', 'dstSubfolderSpec = 13;')
    block = re.sub(r'dstPath = [^;]+;', 'dstPath = "";', block)
    return block

s = pattern.sub(patch, s)
if count:
    p.write_text(s, encoding='utf-8')
    print(f'Patched {count} XcodeGen Watch embedding phase(s): PlugIns destination')
else:
    print('No Watch embedding phase patch needed; verify archive contents after build')
