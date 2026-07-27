#!/usr/bin/env python3
"""
PoE-style Skill Tree Layout Generator v2
Creates a tree with:
- Main branches (roads) radiating from center
- Themed clusters (wheels) at branch ends
- Clear visual organization like Path of Exile

Algorithm:
1. Analyze each notable node's theme from modifier keys + name keywords
2. BFS from center to assign depth layers
3. Create 12 main branches at 30° intervals, each with a primary theme
4. Place themed notables in tight clusters at branch ends (like PoE wheels)
5. Spread filler notables along branch paths
6. Position small/attribute nodes along connection paths
"""

import json
import math
import random
from collections import defaultdict, deque

random.seed(42)

# ─── Theme detection ───────────────────────────────────────────────────

# Modifier key → branch index mapping
MODIFIER_THEMES = {
    "physical_damage": 0,
    "bleed": 0,
    "armour": 1,
    "block_chance": 1,
    "evasion": 2,
    "movement_speed": 2,
    "base_energy_shield": 3,
    "energy_shield_regen": 3,
    "energy_shield": 3,
    "life_regen": 4,
    "life_on_kill": 4,
    "life_leech": 4,
    "base_life": 4,
    "life_gain_on_hit": 4,
    "mana_regen": 5,
    "base_mana": 5,
    "mana_on_kill": 5,
    "mana_leech": 5,
    "fire_damage": 6,
    "lightning_damage": 7,
    "cold_damage": 8,
    "chaos_damage": 9,
    "critical_chance": 10,
    "critical_multiplier": 10,
    "attack_speed": 11,
    "projectile_damage": 11,
    "spell_damage": 11,
    "cast_speed": 11,
    "area_damage": 11,
    "elemental_damage": 11,
}

NAME_THEMES = {
    # Physical
    "brutal": 0, "crush": 0, "heavy": 0, "impact": 0, "wound": 0, "fracture": 0,
    "shatter": 0, "bone": 0, "beast": 0, "flesh": 0, "blood": 0, "blade": 0,
    # Defence / Armour
    "armour": 1, "plate": 1, "fortify": 1, "shield": 1, "wall": 1, "guard": 1,
    "barrier": 1, "defender": 1, "protector": 1, "unyielding": 1, "steadfast": 1,
    "iron": 1, "stone": 1,
    # Evasion
    "evasion": 2, "dodge": 2, "elusive": 2, "wind": 2, "mist": 2, "flow": 2,
    "blur": 2, "swift": 2, "dancer": 2, "step": 2, "acrobatics": 2,
    # Energy Shield
    "energy": 3, "es": 3, "ward": 3, "arcane": 3, "sorcery": 3, "essence": 3,
    "chakra": 3, "soul": 3, "mind": 3, "spirit": 3, "nullification": 3,
    # Life
    "life": 4, "vitality": 4, "recovery": 4, "health": 4, "hearty": 4,
    "vigor": 4, "guts": 4, "veteran": 4,
    # Mana
    "mana": 5, "reservation": 5, "efficient": 5, "reserv": 5, "deep": 5,
    "wellspring": 5, "font": 5,
    # Fire
    "fire": 6, "flame": 6, "burn": 6, "scorch": 6, "ignite": 6, "blaze": 6,
    "ember": 6, "volcano": 6, "inferno": 6, "ash": 6, "sear": 6,
    # Lightning
    "lightning": 7, "storm": 7, "thunder": 7, "shock": 7, "voltaic": 7,
    "surge": 7, "discharge": 7, "spark": 7, "tempest": 7,
    # Cold
    "cold": 8, "ice": 8, "frost": 8, "chill": 8, "freeze": 8, "shatter": 8,
    "glacier": 8, "winter": 8, "snow": 8, "hail": 8, "rime": 8,
    # Chaos
    "chaos": 9, "poison": 9, "venom": 9, "toxic": 9, "decay": 9, "corrupt": 9,
    "blight": 9, "plague": 9, "pestilence": 9, "void": 9, "toxin": 9,
    # Crit
    "critic": 10, "deadly": 10, "precision": 10, "devastation": 10,
    "heartseeker": 10, "assassin": 10, "executioner": 10,
    # Attack / Speed / General
    "attack": 11, "strike": 11, "warcry": 11, "exert": 11, "onslaught": 11,
    "fury": 11, "haste": 11, "speed": 11,
    "spell": 11, "cast": 11, "area": 11, "radius": 11,
    "projectile": 11, "arrow": 11, "shot": 11, "volley": 11,
    "herald": 11, "aura": 11, "curse": 11, "hex": 11,
    "trap": 11, "mine": 11, "totem": 11,
}

BRANCH_NAMES = [
    "Physical",      # 0: 0°
    "Defence",       # 1: 30°
    "Evasion",       # 2: 60°
    "Energy Shield", # 3: 90°
    "Life",          # 4: 120°
    "Mana",          # 5: 150°
    "Fire",          # 6: 180°
    "Lightning",     # 7: 210°
    "Cold",          # 8: 240°
    "Chaos",         # 9: 270°
    "Critical",      # 10: 300°
    "Utility",       # 11: 330°
]

NUM_BRANCHES = 12


def detect_node_theme(node):
    """Detect the primary theme branch for a node. Returns branch index or -1."""
    # Score each branch based on modifiers
    scores = [0] * NUM_BRANCHES
    for mod in node.get("modifiers", []):
        mk = mod.get("key", "")
        if mk in MODIFIER_THEMES:
            scores[MODIFIER_THEMES[mk]] += 2

    # Score from name keywords
    name = node.get("name", "").lower()
    for kw, branch in NAME_THEMES.items():
        if kw in name:
            scores[branch] += 1

    # Score from effects_raw text
    effects = node.get("effects_raw", "").lower()
    for kw, branch in NAME_THEMES.items():
        if kw in effects:
            scores[branch] += 0.5

    best = max(scores)
    if best >= 1.0:
        return scores.index(best)
    return -1  # Filler node, no clear theme


def find_center_nodes(nodes, adj):
    """Find the most central nodes by degree for each connectivity cluster."""
    # Build connectivity clusters
    visited = set()
    clusters = []
    for n in nodes:
        nid = int(n['id'])
        if nid in visited:
            continue
        # BFS to find cluster
        cluster = []
        q = deque([nid])
        visited.add(nid)
        while q:
            cur = q.popleft()
            cluster.append(cur)
            for nb in adj.get(cur, []):
                if nb not in visited:
                    visited.add(nb)
                    q.append(nb)
        clusters.append(cluster)

    # For each cluster, find the node with highest degree (most connections)
    centers = []
    for cluster in clusters:
        if not cluster:
            continue
        best = max(cluster, key=lambda x: len(adj.get(x, [])))
        centers.append(best)
    return centers


def analyze_nodes(nodes, adj):
    """Analyze notable nodes: detect themes, build per-theme lists."""
    notable_info = {}
    for n in nodes:
        if n.get("size") != "notable":
            continue
        nid = int(n["id"])
        theme = detect_node_theme(n)
        notable_info[nid] = {
            "name": n.get("name", ""),
            "theme": theme,
            "connects": [int(c) for c in n.get("connects", []) if c is not None],
        }
    return notable_info


def bfs_depths(nodes, adj, centers):
    """BFS from centers to assign depth to each node."""
    depth_of = {}
    q = deque()
    for c in centers:
        depth_of[c] = 0
        q.append(c)

    while q:
        cur = q.popleft()
        d = depth_of[cur]
        for nb in adj.get(cur, []):
            if nb not in depth_of:
                depth_of[nb] = d + 1
                q.append(nb)

    # Fill missing depths
    max_depth = max(depth_of.values()) if depth_of else 0
    for n in nodes:
        nid = int(n['id'])
        if nid not in depth_of:
            depth_of[nid] = max_depth + 1
    return depth_of


def assign_nodes_to_branches(nodes, notable_info, depth_of, centers):
    """
    Assign each node to a branch (0-11) based on theme.
    Returns (branch_notables, branch_fillers) - dicts of {branch_idx: [node_id, ...]}
    """
    branch_notables = defaultdict(list)
    branch_fillers = defaultdict(list)

    # For themed notables, assign to their theme branch
    for nid, info in notable_info.items():
        if info["theme"] >= 0:
            branch_notables[info["theme"]].append(nid)

    # Fillers go to branch with fewest nodes overall
    filler_nds = [nid for nid, info in notable_info.items() if info["theme"] < 0]
    filler_nds.sort(key=lambda x: depth_of.get(x, 99))

    for nid in filler_nds:
        info = notable_info[nid]
        assigned = False
        for conn in info["connects"]:
            if conn in notable_info and notable_info[conn]["theme"] >= 0:
                br = notable_info[conn]["theme"]
                branch_fillers[br].append(nid)
                assigned = True
                break
        if not assigned:
            br_counts = {i: len(branch_notables[i]) + len(branch_fillers[i])
                         for i in range(12)}
            best_br = min(br_counts, key=br_counts.get)
            branch_fillers[best_br].append(nid)

    return branch_notables, branch_fillers

# v6 compute_positions — "multiple balanced clusters" layout
# Each direction = multiple circular clusters, all with same max extent

def compute_positions(nodes, adj, depth_of, branch_notables, branch_fillers, notable_info, centers):
    """
    Generate col/row for ALL nodes - BALANCED MULTI-CLUSTER layout v6.
    
    Architecture:
    - Each direction's nodes divided into small clusters
    - Cluster size varies per direction so ALL have ~same max extent
    - 2 sub-branches per direction (±12 degrees)
    - Each cluster is a tight circle (radius 1.3)
    - Center area: clean concentric rings (depth-0, depth-1)
    - Small/attribute nodes placed by interpolation
    """
    positions = {}
    random.seed(42)

    center_node_id = int(centers[0]) if centers else 21755

    NUM_DIRS = 8
    DIR_ANGLES_DEG = [22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5]

    THEME_TO_DIR = {
        0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 4,
        6: 5, 7: 6, 8: 7, 9: 3, 10: 2, 11: 1,
    }

    dir_notables = defaultdict(list)
    dir_fillers = defaultdict(list)
    for br in range(12):
        nd = THEME_TO_DIR.get(br, br % NUM_DIRS)
        for nid in branch_notables.get(br, []):
            dir_notables[nd].append(nid)
        for nid in branch_fillers.get(br, []):
            dir_fillers[nd].append(nid)

    dir_all_nodes = {}
    for d in range(NUM_DIRS):
        combined = list(dir_notables.get(d, [])) + list(dir_fillers.get(d, []))
        random.shuffle(combined)
        dir_all_nodes[d] = combined

    print("\\n8 directions clustering plan:")
    for br in range(NUM_DIRS):
        total = len(dir_all_nodes.get(br, []))
        n = len(dir_notables.get(br, []))
        f = len(dir_fillers.get(br, []))
        print(f"  Dir {br} ({DIR_ANGLES_DEG[br]}deg): {total} nodes ({n}+{f})")

    node_connects = {}
    for n in nodes:
        nid = int(n['id'])
        conns = [int(c) for c in n.get("connects", []) if c is not None]
        node_connects[nid] = conns

    node_sizes = {int(n['id']): n.get('size', '') for n in nodes}

    # --- STEP 1: Center rings ---
    positions[center_node_id] = (0.0, 0.0)
    placed = {center_node_id}

    cnt = 0
    for n in nodes:
        nid = int(n['id'])
        if nid in placed:
            continue
        if nid in depth_of and depth_of[nid] == 0:
            a = 2 * math.pi * cnt / len(centers)
            r = 2.5 + random.uniform(-0.1, 0.1)
            positions[nid] = (round(r * math.cos(a), 2), round(r * math.sin(a), 2))
            placed.add(nid)
            cnt += 1

    ring1 = [(int(n['id']), n) for n in nodes
             if int(n['id']) not in placed
             and depth_of.get(int(n['id']), 99) == 1]
    random.shuffle(ring1)
    for idx, (nid, _) in enumerate(ring1):
        a = 2 * math.pi * idx / max(len(ring1), 1)
        r = 3.8 + random.uniform(-0.2, 0.2)
        positions[nid] = (round(r * math.cos(a), 2), round(r * math.sin(a), 2))
        placed.add(nid)

    # --- PARAMETERS ---
    CLUSTER_RADIUS = 1.3   # Radius of each circular cluster
    MIN_DIST = 10.0        # First cluster distance from center
    MAX_EXTENT = 30.0      # Target max distance from center (for balance)
    NUM_SUBS = 2           # Sub-branches per direction
    SUB_SPREAD_DEG = 24    # Total angular spread of sub-branches (degrees)
    SUB_SPREAD = math.radians(SUB_SPREAD_DEG)
    MIN_CLUSTER_SIZE = 8   # Minimum nodes per cluster
    MAX_CLUSTERS = 12      # Maximum clusters per direction

    half_spread = SUB_SPREAD / 2

    # --- STEP 2: Multi-cluster placement with balanced extents ---
    for dir_idx in range(NUM_DIRS):
        all_nodes = dir_all_nodes.get(dir_idx, [])
        if not all_nodes:
            continue

        total = len(all_nodes)
        dir_angle_rad = math.radians(DIR_ANGLES_DEG[dir_idx])

        # Calculate cluster size so all directions have similar max clusters
        cluster_size = max(MIN_CLUSTER_SIZE, (total + MAX_CLUSTERS - 1) // MAX_CLUSTERS)
        n_clusters = (total + cluster_size - 1) // cluster_size

        # Sub-branches: 2 per direction, spaced within the sector
        # Sub A at dir_angle - half_spread, Sub B at dir_angle + half_spread
        sub_angles = [dir_angle_rad - half_spread, dir_angle_rad + half_spread]

        # Distribute clusters evenly across sub-branches
        clusters_per_sub = [n_clusters // NUM_SUBS] * NUM_SUBS
        for i in range(n_clusters % NUM_SUBS):
            clusters_per_sub[i] += 1

        # Calculate step so max extent = MAX_EXTENT
        max_c_per_sub = max(clusters_per_sub)
        if max_c_per_sub <= 1:
            step = 5.0
        else:
            step = (MAX_EXTENT - MIN_DIST) / (max_c_per_sub - 1)
            step = max(step, 3.0)  # Minimum step to prevent overlap (radius 1.3 * 2 = 2.6, need > 2.6)

        print(f"  Dir {dir_idx}: {total} nodes -> {n_clusters} clusters (size={cluster_size}, step={step:.1f})")

        # Stagger start distances: sub A starts at MIN_DIST, sub B starts at MIN_DIST + 2.5
        start_dists = [MIN_DIST, MIN_DIST + 2.5]

        cluster_idx = 0
        for sub_idx in range(NUM_SUBS):
            n_in_sub = clusters_per_sub[sub_idx]
            if n_in_sub <= 0:
                continue

            angle = sub_angles[sub_idx]
            start_dist = start_dists[sub_idx]

            for c in range(n_in_sub):
                if cluster_idx >= total:
                    break

                dist = start_dist + c * step
                cx = dist * math.cos(angle)
                cy = dist * math.sin(angle)

                # Take cluster_size nodes for this cluster
                cluster_nodes = []
                for _ in range(cluster_size):
                    if cluster_idx < total:
                        cluster_nodes.append(all_nodes[cluster_idx])
                        cluster_idx += 1

                # Place nodes in a tight circle
                n_in_cluster = len(cluster_nodes)
                for ni, nid in enumerate(cluster_nodes):
                    if nid in placed:
                        continue
                    t = ni / max(n_in_cluster, 1)
                    wheel_angle = 2 * math.pi * t
                    jitter = random.uniform(-0.1, 0.1)
                    nx = cx + (CLUSTER_RADIUS + jitter) * math.cos(wheel_angle)
                    ny = cy + (CLUSTER_RADIUS + jitter) * math.sin(wheel_angle)
                    positions[nid] = (round(nx, 2), round(ny, 2))
                    placed.add(nid)

    # --- STEP 3: Place remaining small/attribute nodes by interpolation ---
    for pass_num in range(20):
        new_placed = 0
        for n in nodes:
            nid = int(n['id'])
            if nid in placed:
                continue
            sz = node_sizes.get(nid, '')
            if sz not in ('small', 'attribute'):
                continue

            conns = node_connects.get(nid, [])
    # --- STEP 4: Fallback ---
    for n in nodes:
        nid = int(n['id'])
        if nid not in positions:
            conns = node_connects.get(nid, [])
            valid = [c for c in conns if c in positions]
            if valid:
                avg_x = sum(positions[c][0] for c in valid) / len(valid)
                avg_y = sum(positions[c][1] for c in valid) / len(valid)
                positions[nid] = (round(avg_x + random.uniform(-0.3, 0.3), 2),
                                 round(avg_y + random.uniform(-0.3, 0.3), 2))
            else:
                positions[nid] = (round(random.uniform(-5, 5), 2),
                                 round(random.uniform(-5, 5), 2))

    return positions



def main():
    import os
    
    input_path = "data/passive_skill_tree.json"
    
    print("Loading JSON...")
    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    nodes = data['nodes']
    print("Loaded", len(nodes), "nodes total")
    
    adj = defaultdict(set)
    for n in nodes:
        nid = int(n['id'])
        for c in n.get('connects', []):
            if c is not None:
                adj[nid].add(int(c))
                adj[int(c)].add(nid)
    
    print("Graph built:", len(adj), "nodes with connections")
    
    centers = find_center_nodes(nodes, adj)
    print("Found", len(centers), "center nodes, primary:", centers[0] if centers else "none")
    
    depth_of = bfs_depths(nodes, adj, centers)
    print("Depth assigned to", len(depth_of), "nodes")
    
    notable_info = analyze_nodes(nodes, adj)
    print("Analyzed", len(notable_info), "notable nodes")
    
    branch_notables, branch_fillers = assign_nodes_to_branches(
        nodes, notable_info, depth_of, centers
    )
    
    total_assigned = sum(len(v) for v in branch_notables.values())
    total_fillers = sum(len(v) for v in branch_fillers.values())
    print("Assigned", total_assigned, "themed +", total_fillers, "filler notables to branches")
    
    positions = compute_positions(
        nodes, adj, depth_of, branch_notables, branch_fillers, 
        notable_info, centers
    )
    print("Computed positions for", len(positions), "nodes")
    
    updated = 0
    for n in nodes:
        nid = int(n['id'])
        if nid in positions:
            n['col'] = positions[nid][0]
            n['row'] = positions[nid][1]
            updated += 1
    
    print("Updated", updated, "/", len(nodes), "node positions")
    
    N_DIRS = 8
    DIR_MAP = {0:0, 1:1, 2:2, 3:3, 4:4, 5:4, 6:5, 7:6, 8:7, 9:3, 10:2, 11:1}
    nid_to_dir = {}
    for br in range(12):
        direction = DIR_MAP.get(br, br % N_DIRS)
        for nid in branch_notables.get(br, []):
            nid_to_dir[nid] = direction
        for nid in branch_fillers.get(br, []):
            nid_to_dir[nid] = direction
    for n in nodes:
        nid = int(n['id'])
        if nid in nid_to_dir:
            n['dir'] = nid_to_dir[nid]
    
    print("Assigned direction to", len(nid_to_dir), "nodes")
    
    all_cols = [n.get('col', 0) for n in nodes]
    all_rows = [n.get('row', 0) for n in nodes]
    print("Bounds: col [", min(all_cols), ",", max(all_cols), "], row [", min(all_rows), ",", max(all_rows),"]")
    
    backup_path = "data/passive_skill_tree_backup.json"
    import shutil
    shutil.copy2(input_path, backup_path)
    print("Backup saved to", backup_path)
    
    with open(input_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    
    import os as os_mod
    file_size = os_mod.path.getsize(input_path) / 1024 / 1024
    print("Saved:", input_path, "(", round(file_size, 2), "MB)")
    print("Done!")


if __name__ == "__main__":
    main()
