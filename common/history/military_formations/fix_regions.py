import re
import sys
import os
from collections import Counter


def load_regions(region_files):
    state_to_region = {}
    valid_regions = set()
    
    for filepath in region_files:
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            content = f.read()
        
        for match in re.finditer(r'^(region_\w+)\s*=\s*\{', content, re.MULTILINE):
            region_name = match.group(1)
            start = match.end()
            depth = 1
            pos = start
            while depth > 0 and pos < len(content):
                if content[pos] == '{': depth += 1
                elif content[pos] == '}': depth -= 1
                pos += 1
            block = content[start:pos]
            states = re.findall(r'(STATE_[A-Z_]+)', block)
            
            valid_regions.add(region_name)
            for state in states:
                state_to_region[state] = region_name
    
    return state_to_region, valid_regions


def fix_formations(formations_file, output_file, state_to_region, valid_regions):
    with open(formations_file, 'r', encoding='utf-8-sig') as f:
        content = f.read()
    
    lines = content.split('\n')
    result = []
    changes = 0
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        hq_match = re.search(r'(hq_region\s*=\s*sr:)(region_\w+)', line)
        if hq_match:
            old_region = hq_match.group(2)
            
            if old_region not in valid_regions:
                # Look ahead for states in this formation block
                states_in_formation = []
                depth = 0
                for back in range(i, max(i-5, 0), -1):
                    if 'create_military_formation' in lines[back]:
                        depth = sum(l.count('{') - l.count('}') for l in lines[back:i+1])
                        break
                
                for forward in range(i+1, min(i+200, len(lines))):
                    depth += lines[forward].count('{') - lines[forward].count('}')
                    state_match = re.search(r'(STATE_[A-Z_]+)', lines[forward])
                    if state_match:
                        states_in_formation.append(state_match.group(1))
                    if depth <= 0:
                        break
                
                region_votes = Counter()
                for state in states_in_formation:
                    if state in state_to_region:
                        region_votes[state_to_region[state]] += 1
                
                if region_votes:
                    new_region = region_votes.most_common(1)[0][0]
                else:
                    fallback = {
                        'region_britain': 'region_western_europe',
                        'region_germany': 'region_central_europe',
                        'region_scandinavia': 'region_northern_europe',
                        'region_anatolia': 'region_near_east',
                        'region_baltic': 'region_eastern_europe',
                        'region_north_sea_coast': 'region_northern_europe',
                        'region_france': 'region_western_europe',
                        'region_iberia': 'region_southern_europe',
                        'region_italy': 'region_southern_europe',
                        'region_poland': 'region_eastern_europe',
                        'region_dnieper': 'region_eastern_europe',
                        'region_belarus': 'region_eastern_europe',
                    }
                    new_region = fallback.get(old_region, old_region)
                
                line = line.replace(f'sr:{old_region}', f'sr:{new_region}')
                changes += 1
                print(f"  {old_region} -> {new_region} (from {len(states_in_formation)} states)")
        
        result.append(line)
        i += 1
    
    output = '\n'.join(result)
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(output)
    
    # Verify
    remaining = []
    for match in re.finditer(r'sr:(region_\w+)', output):
        if match.group(1) not in valid_regions:
            remaining.append(match.group(1))
    
    print(f"\n  {changes} hq_region references updated")
    if remaining:
        print(f"  WARNING: {len(remaining)} still invalid: {set(remaining)}")
    else:
        print(f"  All region references are now valid")


if __name__ == '__main__':
    formations_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else formations_file.replace('.txt', '_fixed.txt')
    
    region_files = sys.argv[3:] if len(sys.argv) > 3 else []
    
    if not region_files:
        print("Usage: python fix_regions.py <formations> [output] <region_file1> [region_file2] ...")
        sys.exit(1)
    
    print("Loading regions...")
    state_to_region, valid_regions = load_regions(region_files)
    print(f"  {len(valid_regions)} regions, {len(state_to_region)} states mapped")
    
    print(f"\nFixing {formations_file}...")
    fix_formations(formations_file, output_file, state_to_region, valid_regions)
