#!/usr/bin/env python3
"""
Remove barrack building blocks from Victoria 3 building history files.

Usage:
    python remove_barracks_from_buildings.py /path/to/input_folder /path/to/output_folder

This removes full create_building = { ... } blocks containing:
    building = "building_barrack"
or:
    building = "building_barracks"

It preserves all non-barrack building blocks.
"""
from pathlib import Path
import re
import sys
import shutil

CREATE_PAT = re.compile(r'\bcreate_building\s*=')
BARRACK_PAT = re.compile(r'building\s*=\s*"?building_barracks?"?\b')

def find_matching_brace(s: str, open_idx: int) -> int:
    depth = 0
    in_quote = False
    i = open_idx
    while i < len(s):
        ch = s[i]
        if in_quote:
            if ch == '"':
                in_quote = False
        else:
            if ch == '"':
                in_quote = True
            elif ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    return -1

def remove_barracks(text: str) -> tuple[str, int]:
    out = []
    last = 0
    removed = 0

    for m in CREATE_PAT.finditer(text):
        start = m.start()
        open_idx = text.find('{', m.end())
        if open_idx == -1:
            continue
        close_idx = find_matching_brace(text, open_idx)
        if close_idx == -1:
            continue

        block = text[start:close_idx + 1]
        if not BARRACK_PAT.search(block):
            continue

        line_start = text.rfind('\n', 0, start) + 1
        actual_start = line_start if text[line_start:start].strip() == '' else start
        actual_end = close_idx + 1
        if actual_end < len(text) and text[actual_end] == '\r':
            actual_end += 1
        if actual_end < len(text) and text[actual_end] == '\n':
            actual_end += 1

        out.append(text[last:actual_start])
        last = actual_end
        removed += 1

    out.append(text[last:])
    return ''.join(out), removed

def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python remove_barracks_from_buildings.py <input_folder> <output_folder>")
        return 2

    input_dir = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    if not input_dir.is_dir():
        print(f"Input folder not found: {input_dir}")
        return 1

    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)

    total_removed = 0
    for path in sorted(input_dir.glob("*.txt")):
        text = path.read_text(encoding="utf-8-sig")
        cleaned, removed = remove_barracks(text)
        (output_dir / path.name).write_text(cleaned, encoding="utf-8-sig")
        total_removed += removed
        print(f"{path.name}: removed {removed}")

    print(f"Total barrack blocks removed: {total_removed}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
