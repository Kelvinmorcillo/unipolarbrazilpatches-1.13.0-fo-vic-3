"""
Remove all create_building blocks that contain building_military_shipyard.

Usage:
    python remove_military_shipyards.py <input_file> [output_file]
"""

import sys

def patch_file(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8-sig') as f:
        lines = f.readlines()

    result = []
    removed = 0
    i = 0

    while i < len(lines):
        stripped = lines[i].strip()

        if stripped == 'create_building = {':
            # Buffer the entire block
            block_lines = [lines[i]]
            depth = lines[i].count('{') - lines[i].count('}')
            i += 1

            while depth > 0 and i < len(lines):
                block_lines.append(lines[i])
                depth += lines[i].count('{') - lines[i].count('}')
                i += 1

            # Check if this block contains building_military_shipyard
            block_text = ''.join(block_lines)
            if 'building_military_shipyard' in block_text:
                # Also remove a comment line right before if it exists
                if result and result[-1].strip().startswith('#'):
                    result.pop()
                removed += 1
                continue
            else:
                result.extend(block_lines)
                continue

        result.append(lines[i])
        i += 1

    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(result)

    print(f"Done: {removed} military shipyard blocks removed")
    print(f"Output: {output_path}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python remove_military_shipyards.py <input_file> [output_file]")
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else input_path.replace('.txt', '_patched.txt')
    patch_file(input_path, output_path)
