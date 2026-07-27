@tool
extends SceneTree

func _init():
		var json_path = ProjectSettings.globalize_path("res://data/passive_skill_tree.json")
		var file = FileAccess.open(json_path, FileAccess.READ)
		if not file:
				print("ERROR: Cannot open JSON")
				quit()
		var text = file.get_as_text()
		file.close()
		var json = JSON.parse_string(text)
		if not json or typeof(json) != TYPE_DICTIONARY:
				print("ERROR: Invalid JSON")
				quit()
				var nodes = json.get("nodes", [])
		print("Total nodes in JSON: ", nodes.size())
				var by_size = {}
		for n in nodes:
				if not (n is Dictionary): continue
				var sz = n.get("size", "unknown")
				by_size[sz] = by_size.get(sz, 0) + 1
				print("\n=== Node sizes ===")
		for k in by_size.keys():
				print("  %s: %d" % [k, by_size[k]])
				# Simple filter
		var filtered_keywords = ["endurance", "frenzy", "power", "charge", "shapeshift", "charm", "glory",
				"banner", "stun", "dodge roll", "support gem", "socketed", "warcry", "herald",
				"rage", "archon", "infusion", "remnant", "crystal", "volatility", "trigger",
				"meta skill", "ballista", "turret", "immobil", "hazard", "sprint", "offering",
				"combo", "invocat", "knockback", "knock back", "parry", "presence", "curse",
				"undead", "demons", "hinder", "with sword", "with swords", "with spear", "with spears",
				"with flail", "with flails", "with dagger", "with daggers", "with axe", "with axes",
				"with mace", "with maces", "with staff", "with staves", "quarterstaff", "crossbow",
				"with bow", "with bows", "with one handed", "with two handed",
				"fissure", "seal", "orb skill", "corpse", "grenade",
				"thaumaturgical", "cascade", "incision", "aftershock", "slam", "arcane surge",
				"debilitate", "impale", "surpass", "echoed", "ancestrally", "close range",
				"detonator", " ground", "corrupted blood", "flammability", "plant", "overgrow"]
				var filtered_mark = ["unsight", "the noble wolf", "marked agility", "marked for death", "marked for sickness"]
				var all_filtered = []
		var keystones = []
		for n in nodes:
				if not (n is Dictionary): continue
				var name_lower = n.get("name", "").to_lower()
				var effects_lower = n.get("effects_raw", "").to_lower()
				if name_lower in filtered_mark: continue
				var skip = false
				for kw in filtered_keywords:
						if kw in name_lower or kw in effects_lower:
								skip = true
								break
				if skip: continue
				var sz = n.get("size", "")
				if sz == "keystone": keystones.append(n)
				all_filtered.append(n)
				print("\n=== After filtering ===")
		print("  Total: %d  Keystones: %d" % [all_filtered.size(), keystones.size()])
				# Build adjacency
		var filtered_ids = {}
		for n in all_filtered:
				filtered_ids[int(n.get("id", 0))] = true
				var connections = {} # id -> [out_ids]
		for n in all_filtered:
				var nid = int(n.get("id", 0))
				var conns = n.get("connects", [])
				var out = []
				for c in conns:
						var cid = int(c)
						if filtered_ids.has(cid):
								out.append(cid)
				connections[nid] = out
				# Find BFS depth from 5 start points
		var start_ids = [20499, 2653, 18441, 2955, 42452]
		var visited = {}
		var depth = {}
		var queue = []
		for sid in start_ids:
				if filtered_ids.has(sid):
						queue.push_back(sid)
						visited[sid] = true
						depth[sid] = 0
				var max_depth = 0
		var front = 0
		while front < queue.size():
				var nid = queue[front]
				front += 1
				var d = depth[nid]
				max_depth = max(max_depth, d)
				for cid in connections.get(nid, []):
						if not visited.has(cid):
								visited[cid] = true
								depth[cid] = d + 1
								queue.push_back(cid)
				var unvisited = 0
		for n in all_filtered:
				if not visited.has(int(n.get("id", 0))):
						unvisited += 1
				print("  Visited: %d / %d" % [visited.size(), all_filtered.size()])
		print("  Unvisited (disconnected): %d" % unvisited)
		print("  Max depth: %d" % max_depth)
				# Count per depth
		var depth_counts = {}
		var depth_type_counts = {}
		for nid in depth:
				var d = depth[nid]
				depth_counts[d] = depth_counts.get(d, 0) + 1
				if not depth_type_counts.has(d):
						depth_type_counts[d] = {"keystone": 0, "notable": 0, "other": 0}
				for n in all_filtered:
				var nid = int(n.get("id", 0))
				var d = depth.get(nid, -1)
				if d >= 0:
						var sz = n.get("size", "")
						if sz == "keystone": depth_type_counts[d]["keystone"] += 1
						elif sz == "notable": depth_type_counts[d]["notable"] += 1
						else: depth_type_counts[d]["other"] += 1
				print("\n=== Nodes per depth level ===")
		for d in range(0, max_depth + 1):
				var c = depth_counts.get(d, 0)
				if c == 0: continue
				var tc = depth_type_counts.get(d, {})
				print("  Depth %d: %d nodes (keystone=%d notable=%d other=%d)" % [d, c, tc.get("keystone",0), tc.get("notable",0), tc.get("other",0)])
				print("\n=== Max width (branching) ===")
		var max_width = 0
		for d in range(0, max_depth + 1):
				max_width = max(max_width, depth_counts.get(d, 0))
		print("  Max nodes at a single depth: %d" % max_width)
				print("\nDone")
		quit()
