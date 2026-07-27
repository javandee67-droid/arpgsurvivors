#!/usr/bin/env python3
"""
PoE2 Passive Tree Layout Generator
Computes (col, row) coordinates for each node using BFS-based graph layout.
Outputs updated JSON with positions.
"""

import json
import math
import random
from collections import deque, defaultdict

INPUT_PATH = "C:/Users/javan/Desktop/poelike/poelike/data/passive_skill_tree.json"
OUTPUT_PATH = "C:/Users/javan/Desktop/poelike/poelike/data/passive_skill_tree.json"

def generate_layout(nodes, max_width=120, spacing=1.0):
    """
    Generate (col, row) positions for nodes using BFS from center-most nodes.
    Uses a multiple-pass approach:
    1. Find highly-connected nodes as anchors
    2. BFS to assign depth layers
    3. Use angular/fan-out positioning within each depth
    """
    # Build adjacency list
    adj = defaultdict(set)
    node_map = {}
    for n in nodes:
        nid = n['id']
        node_map[nid] = n
        for conn in n['connects']:
            if conn in node_map or any(other['id'] == conn for other in nodes):
                adj[nid].add(conn)
                adj[conn].add(nid)
    
    # Also add reverse connections from our dataset
    for n in nodes:
        for conn in n['connects']:
            adj[conn].add(n['id'])
    
    # Find the most connected nodes as potential "centers"
    degree = {nid: len(adj[nid]) for nid in adj}
    # Top 10 most connected
    centers = sorted(degree.keys(), key=lambda x: -degree[x])[:10]
    
    if not centers:
        return {n['id']: {"col": 0, "row": 0} for n in nodes}
    
    # Find the true center (node with highest degree that connects to most other centers)
    center = centers[0]
    
    # BFS from center
    pos = {}
    visited = set()
    queue = deque()
    
    # Use center as root
    queue.append((center, 0, 0.0))  # (node_id, depth, angle)
    visited.add(center)
    
    depth_counts = defaultdict(int)
    depth_max_width = {}
    
    # First pass: assign depths via BFS
    depth_of = {}
    q = deque([(center, 0)])
    visited2 = {center}
    while q:
        nid, depth = q.popleft()
        depth_of[nid] = depth
        depth_counts[depth] += 1
        for neighbor in adj[nid]:
            if neighbor not in visited2:
                visited2.add(neighbor)
                q.append((neighbor, depth + 1))
    
    # Calculate max width per depth
    max_in_depth = max(depth_counts.values()) if depth_counts else 1
    for d in depth_counts:
        depth_max_width[d] = min(max_width, depth_counts[d])
    
    # Second pass: assign positions with fan-out
    # Group by depth, then assign positions with even spacing
    nodes_by_depth = defaultdict(list)
    for nid, depth in depth_of.items():
        nodes_by_depth[depth].append(nid)
    
    # For each depth, sort by their connection to the previous depth
    for depth in sorted(nodes_by_depth.keys()):
        nds = nodes_by_depth[depth]
        if depth == 0:
            # Center node at (0, 0)
            pos[center] = (0.0, 0.0)
            continue
        
        # Previous depth nodes
        prev_nodes = nodes_by_depth.get(depth - 1, [])
        
        # For each node at this depth, find its "parent" connections
        # Then position it near those parents
        unpositioned = list(nds)
        random.shuffle(unpositioned)  # Avoid deterministic ordering issues
        
        child_positions = {}  # nid -> angle
        
        for nid in unpositioned:
            # Find connected nodes at previous depth
            parents = [p for p in prev_nodes if p in adj[nid] or nid in adj[p]]
            
            if parents:
                # Position near the average angle of parents
                parent_angles = []
                for p in parents:
                    if p in pos:
                        px, py = pos[p]
                        parent_angles.append(math.atan2(py, px))
                
                if parent_angles:
                    avg_angle = sum(parent_angles) / len(parent_angles)
                else:
                    avg_angle = random.uniform(-math.pi, math.pi)
            else:
                # No parent at previous depth - fan out from center
                idx = unpositioned.index(nid)
                count_at_depth = len(nds)
                angle_step = 2.0 * math.pi / max(count_at_depth, 1)
                avg_angle = angle_step * idx
            
            # Add small random offset for visual variety
            avg_angle += random.uniform(-0.05, 0.05)
            child_positions[nid] = avg_angle
        
        # Normalize angles within this depth for even spacing
        angles = list(child_positions.values())
        if angles:
            # Sort by angle
            sorted_pairs = sorted(child_positions.items(), key=lambda x: x[1])
            
            # Redistribute evenly around circle
            count = len(sorted_pairs)
            for i, (nid, _) in enumerate(sorted_pairs):
                angle = (2.0 * math.pi * i / max(count, 1)) - math.pi
                # Add some natural-looking variation
                angle += random.uniform(-0.1, 0.1)
                
                # Position at this depth with radial spacing
                radius = (depth + 0.5) * spacing * 75.0  # pixels
                x = radius * math.cos(angle)
                y = radius * math.sin(angle)
                pos[nid] = (x, y)
    
    # Convert to col/row format (75px per unit)
    result = {}
    for nid, (x, y) in pos.items():
        result[nid] = {
            "col": round(x / 75.0, 2),
            "row": round(y / 75.0, 2)
        }
    
    # For any unpositioned nodes, place them at depth-based positions
    for n in nodes:
        nid = n['id']
        if nid not in result:
            d = depth_of.get(nid, 0)
            result[nid] = {"col": (d + 1) * 2.0, "row": 0.0}
    
    return result


def assign_ascendancy_layout(asc_nodes):
    """Assign positions for ascendancy nodes - simple top-to-bottom per subclass."""
    # Group by class → subclass
    groups = defaultdict(lambda: defaultdict(list))
    for n in asc_nodes:
        cls = n.get('class', 'Unknown')
        sub = n.get('subclass', 'Unknown')
        groups[cls][sub].append(n)
    
    result = {}
    x_offset = 0
    
    for cls in sorted(groups.keys()):
        subclasses = groups[cls]
        for sub_idx, (sub, nodes) in enumerate(sorted(subclasses.items())):
            # Each subclass gets its own column
            for i, n in enumerate(nodes):
                result[n['id']] = {
                    "col": x_offset + sub_idx * 8.0 + 1.0,
                    "row": i * 2.0 + 1.0
                }
        x_offset += len(subclasses) * 8.0 + 4.0
    
    return result


def main():
    print("Loading JSON...")
    with open(INPUT_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print("Generating main tree layout...")
    positions = generate_layout(data['nodes'])
    
    # Assign positions to nodes
    positioned = 0
    for n in data['nodes']:
        nid = n['id']
        if nid in positions:
            n['col'] = positions[nid]['col']
            n['row'] = positions[nid]['row']
            positioned += 1
        else:
            n['col'] = 0.0
            n['row'] = 0.0
    
    print(f"  Positioned {positioned}/{len(data['nodes'])} nodes")
    
    print("Generating ascendancy layout...")
    asc_positions = assign_ascendancy_layout(data['ascendancy_nodes'])
    
    asc_positioned = 0
    for n in data['ascendancy_nodes']:
        nid = n['id']
        if nid in asc_positions:
            n['col'] = asc_positions[nid]['col']
            n['row'] = asc_positions[nid]['row']
            asc_positioned += 1
        else:
            n['col'] = 0.0
            n['row'] = 0.0
    
    print(f"  Positioned {asc_positioned}/{len(data['ascendancy_nodes'])} nodes")
    
    # Calculate bounds
    all_cols = [n.get('col', 0) for n in data['nodes']]
    all_rows = [n.get('row', 0) for n in data['nodes']]
    print(f"\nBounds: col [{min(all_cols):.1f}, {max(all_cols):.1f}], row [{min(all_rows):.1f}, {max(all_rows):.1f}]")
    print(f"Tree spans ~{max(all_cols) - min(all_cols):.0f} cols x {max(all_rows) - min(all_rows):.0f} rows")
    
    # Save
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    
    file_size = __import__('os').path.getsize(OUTPUT_PATH) / 1024 / 1024
    print(f"\nSaved: {OUTPUT_PATH} ({file_size:.2f} MB)")
    print("Done!")


if __name__ == "__main__":
    main()
