#!/usr/bin/env python3
"""
Rewrite Victoria 3 building ownership so that every building NOT in the
exclusion list becomes solely owned by a financial district in the SAME state,
owned by the country that runs that state (the region_state).

- Sole owner: the whole add_ownership block is replaced with one
  building={ type="building_financial_district" ... } owner.
- levels: the sum of all levels the building previously had (country + building owners).
- financial district country/region: the region_state country + the enclosing s:STATE.
"""

import re
import sys

# Buildings that should KEEP their existing ownership untouched.
EXCLUDE = {
    "building_government_administration",
    "building_university",
    "building_port",
    "building_railway",
    # wonders / monuments (bg_monuments) e.g. statue of liberty, eiffel tower, etc.
    "building_statue_of_liberty",
    "building_world_trade_center",
    "building_central_park",
    "building_white_house",
    "building_capitol_hill",
    "building_eiffel_tower",
    "building_angkor_wat",
    "building_airport",
    "building_spaceport",
    "building_nuclear_plant",
    "building_nuclear_silo",
    "building_naval_base",            # naval fortification
    "building_naval_administration",
    "building_canal",
    "building_army_logistics_center",
    "building_naval_logistics_center",
    "building_urban_center",
    "building_barracks",
    "building_conscription_center",
    "building_subsistence_farm",      # any subsistence_* handled below too
    "building_construction_sector",
}

# Prefixes whose buildings are always excluded (covers subsistence variants,
# and all monuments/wonders which share the bg_monuments group).
EXCLUDE_PREFIXES = (
    "building_subsistence_",
)

# Building groups treated as wonders/monuments -> excluded.
# (We can't see building_group here, so we exclude by known monument names above.
#  Add more monument building keys here if your save has others.)


def is_excluded(building_type: str) -> bool:
    if building_type in EXCLUDE:
        return True
    for p in EXCLUDE_PREFIXES:
        if building_type.startswith(p):
            return True
    return False


def find_block_end(text: str, open_brace_idx: int) -> int:
    """Given index of an opening '{', return index just past its matching '}'."""
    depth = 0
    i = open_brace_idx
    n = len(text)
    while i < n:
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1
    raise ValueError("Unbalanced braces starting at %d" % open_brace_idx)


def indent_of_line(text: str, idx: int) -> str:
    """Return the leading-whitespace of the line containing position idx."""
    line_start = text.rfind("\n", 0, idx) + 1
    j = line_start
    while j < len(text) and text[j] in " \t":
        j += 1
    return text[line_start:j]


def process(text: str) -> tuple[str, int]:
    out = []
    pos = 0
    n = len(text)
    changes = 0

    # Stack of (kind, value) context frames as we walk top-to-bottom is hard with
    # regex alone, so instead we resolve state/country by scanning backwards from
    # each create_building for the nearest enclosing `s:STATE_...=` and
    # `region_state:CCC=`.
    state_pat = re.compile(r's:(STATE_[A-Z0-9_]+)\s*=')
    region_pat = re.compile(r'region_state:([A-Z0-9_]+)\s*=')

    cb_pat = re.compile(r'create_building\s*=\s*\{')

    while True:
        m = cb_pat.search(text, pos)
        if not m:
            out.append(text[pos:])
            break

        brace_idx = text.index("{", m.start())
        block_end = find_block_end(text, brace_idx)
        block = text[brace_idx:block_end]  # includes { ... }

        # emit everything up to and including the "create_building=" keyword+space
        out.append(text[pos:m.end() - 1])  # up to the '{' (m.end() points past '{')
        # Actually m.end() is just past '{'. We want to re-emit block ourselves.
        # Re-slice: emit text[pos:brace_idx] then handle block.
        out[-1] = text[pos:brace_idx]

        # Determine building type inside this block
        bt = re.search(r'building\s*=\s*"([^"]+)"', block)
        building_type = bt.group(1) if bt else None

        if building_type is None or is_excluded(building_type):
            out.append(block)
            pos = block_end
            continue

        # Skip entirely if this building already has ANY financial district owner,
        # regardless of which state/country that financial district is in.
        if 'type="building_financial_district"' in block:
            out.append(block)
            pos = block_end
            continue

        # Resolve enclosing state and region_state country by nearest-preceding match.
        prefix = text[:brace_idx]
        sm = None
        for sm in state_pat.finditer(prefix):
            pass
        rm = None
        for rm in region_pat.finditer(prefix):
            pass
        if sm is None or rm is None:
            # can't resolve context; leave untouched
            out.append(block)
            pos = block_end
            continue
        state = sm.group(1)
        country = rm.group(1)

        # Sum all existing owned levels (from every `levels=N`).
        total_levels = sum(int(x) for x in re.findall(r'levels\s*=\s*(\d+)', block))
        if total_levels == 0:
            total_levels = 1

        # Preserve activate_production_methods and reserves lines if present.
        apm = re.search(r'activate_production_methods\s*=\s*\{[^}]*\}', block)
        apm_line = apm.group(0) if apm else None
        reserves = re.search(r'reserves\s*=\s*\d+', block)
        reserves_line = reserves.group(0) if reserves else None

        # Build replacement block using tab indentation matching the file style.
        base = indent_of_line(text, brace_idx)   # indent of the create_building line
        i1 = base + "\t"
        i2 = base + "\t\t"
        i3 = base + "\t\t\t"

        lines = [
            "{",
            i1 + 'building="%s"' % building_type,
            i1 + "add_ownership={",
            i2 + "building={",
            i3 + 'type="building_financial_district"',
            i3 + 'country="c:%s"' % country,
            i3 + 'levels=%d' % total_levels,
            i3 + 'region="%s"' % state,
            i2 + "}",
            i1 + "}",
        ]
        if reserves_line:
            lines.append(i1 + reserves_line)
        if apm_line:
            lines.append(i1 + apm_line)
        lines.append(base + "}")

        out.append("\n".join(lines))
        changes += 1
        pos = block_end

    return "".join(out), changes


def main():
    if len(sys.argv) < 3:
        print("usage: fd_ownership.py <input> <output>")
        sys.exit(1)
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, "r", encoding="utf-8-sig") as f:
        text = f.read()
    result, changes = process(text)
    with open(dst, "w", encoding="utf-8") as f:
        f.write(result)
    print("Rewrote %d building(s) -> financial district ownership." % changes)


if __name__ == "__main__":
    main()
