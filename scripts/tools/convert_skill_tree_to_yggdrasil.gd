@tool
extends SceneTree

const RING_PADDING := 80.0      # Extra padding around content

const TEXTURE_DIR := "res://yggdrasil_data/textures/"

const FILTERED_KEYWORDS := [
	"endurance", "frenzy", "power", "charge", "shapeshift", "charm", "glory",
	"banner", "stun", "dodge roll", "support gem", "socketed", "warcry", "herald",
	"rage", "archon", "infusion", "remnant", "crystal", "volatility", "volatile",
	"trigger", "triggered", "meta skill", "ballista", "turret", "pin", "pinned",
	"immobil", "hazard", "jagged ground", "sprint", "offering", "combo",
	"invocation", "invocate", "invoked", "knockback", "knock back", "parry",
	"presence", "curse", "undead", "demons", "hinder", "hindered",
	"cast speed while chilled", "cast speed while ignited", "cast speed while on full mana",
	"with sword", "with swords", "with spear", "with spears", "with flail", "with flails",
	"with dagger", "with daggers", "with axe", "with axes", "with mace", "with maces",
	"with staff", "with staves", "quarterstaff", "crossbow", "with bow", "with bows",
	"with one handed", "with two handed", "two handed weapon", "one handed weapon",
	"fissure", "seal", "orb skill", "corpse", "grenade", "puppet master",
	"thaumaturgical", "cascade", "incision", "aftershock", "slam", "arcane surge",
	"debilitate", "impale", "surpass", "echoed", "ancestrally", "close range",
	"detonator", " ground", "corrupted blood", "flammability", "plant", "overgrow"
]

const FILTERED_MARK_NAMES := [
	"unsight", "the noble wolf", "marked agility", "marked for death", "marked for sickness"
]

# --- Texture Generation ---

var _texture_paths: Dictionary = {}

func _generate_all_textures() -> void:
	# Also save PNGs to disk for editor use, but trees will embed ImageTextures
	var da := DirAccess.open("res://")
	if da:
		da.make_dir_recursive("yggdrasil_data/textures")
	var abs_dir := ProjectSettings.globalize_path(TEXTURE_DIR)

	print("Generating textures...")

	var save_png := func(img: Image, name: String):
		img.save_png(abs_dir + name)
		_texture_paths[name] = TEXTURE_DIR + name
		print("  Created ", name)

	# Keystone (LARGE) - gold
	save_png.call(_make_icon_texture(48, Color(0.85, 0.65, 0.2)).get_image(), "keystone_icon.png")
	save_png.call(_make_border_texture(64, Color(0.6, 0.45, 0.15), 3.0).get_image(), "keystone_border_normal.png")
	save_png.call(_make_border_texture(64, Color(0.85, 0.65, 0.2), 3.0).get_image(), "keystone_border_intermediate.png")
	save_png.call(_make_border_texture(64, Color(1.0, 0.85, 0.35), 4.0).get_image(), "keystone_border_active.png")

	# Notable (MEDIUM) - purple
	save_png.call(_make_icon_texture(48, Color(0.4, 0.37, 0.6)).get_image(), "notable_icon.png")
	save_png.call(_make_border_texture(64, Color(0.32, 0.28, 0.5), 3.0).get_image(), "notable_border_normal.png")
	save_png.call(_make_border_texture(64, Color(0.5, 0.45, 0.75), 3.0).get_image(), "notable_border_intermediate.png")
	save_png.call(_make_border_texture(64, Color(0.7, 0.6, 0.9), 4.0).get_image(), "notable_border_active.png")

	# Small - bronze
	save_png.call(_make_icon_texture(28, Color(0.5, 0.37, 0.22)).get_image(), "small_icon.png")
	save_png.call(_make_border_texture(40, Color(0.35, 0.25, 0.15), 2.0).get_image(), "small_border_normal.png")
	save_png.call(_make_border_texture(40, Color(0.55, 0.4, 0.25), 2.0).get_image(), "small_border_intermediate.png")
	save_png.call(_make_border_texture(40, Color(0.75, 0.55, 0.35), 3.0).get_image(), "small_border_active.png")

	# Lines
	save_png.call(_make_line_texture(16, 4, Color(0.25, 0.25, 0.35, 0.5)).get_image(), "line_normal.png")
	save_png.call(_make_line_texture(16, 5, Color(0.55, 0.5, 0.7, 0.7)).get_image(), "line_intermediate.png")
	save_png.call(_make_line_texture(16, 6, Color(0.85, 0.75, 0.4, 0.9)).get_image(), "line_active.png")

	print("Generated %d texture files." % _texture_paths.size())

# Textures generated inline and embedded directly into .tres as ImageTextures
var _texture_cache: Dictionary = {}  # String -> ImageTexture

func _make_icon_texture(size: int, color: Color) -> ImageTexture:
	var key := "icon_%d_%s" % [size, str(color)]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size * 0.5
	var cy := size * 0.5
	var r := size * 0.40
	for y in range(size):
		for x in range(size):
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			if dx*dx + dy*dy <= r*r:
				img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex

func _make_border_texture(size: int, color: Color, thickness: float) -> ImageTexture:
	var key := "border_%d_%s_%s" % [size, str(color), str(thickness)]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := size * 0.5
	var cy := size * 0.5
	var outer_r := size * 0.45
	var inner_r := outer_r - thickness
	for y in range(size):
		for x in range(size):
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			var d2 := dx*dx + dy*dy
			if d2 <= outer_r * outer_r and d2 >= inner_r * inner_r:
				img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex

func _make_line_texture(w: int, h: int, color: Color) -> ImageTexture:
	var key := "line_%d_%d_%s" % [w, h, str(color)]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex

# Cluster → color mapping for small/notable nodes
const CLUSTER_COLORS := {
	"fire_damage": Color(1.0, 0.35, 0.15),
	"cold_damage": Color(0.3, 0.6, 1.0),
	"lightning_damage": Color(1.0, 0.85, 0.15),
	"chaos_damage": Color(0.7, 0.3, 0.7),
	"physical_damage": Color(0.85, 0.6, 0.4),
	"elemental_damage": Color(1.0, 0.7, 0.3),
	"elemental_damage": Color(0.5, 0.3, 1.0),
	"attack_speed": Color(0.9, 0.5, 0.2),
	"cast_speed": Color(0.4, 0.5, 1.0),
	"critical_chance": Color(0.9, 0.9, 0.3),
	"critical_multiplier": Color(0.95, 0.7, 0.1),
	"block_chance": Color(0.6, 0.8, 0.6),
	"armour": Color(0.7, 0.5, 0.3),
	"evasion": Color(0.3, 0.8, 0.5),
	"base_energy_shield": Color(0.3, 0.7, 0.9),
	"energy_shield_regen": Color(0.2, 0.6, 0.85),
	"life_regen": Color(0.8, 0.2, 0.2),
	"life_on_kill": Color(0.9, 0.3, 0.3),
	"life_gain_on_hit": Color(0.85, 0.15, 0.15),
	"base_life": Color(0.75, 0.15, 0.15),
	"mana_regen": Color(0.3, 0.4, 0.9),
	"mana_on_kill": Color(0.25, 0.35, 0.85),
	"base_mana": Color(0.2, 0.3, 0.8),
	"life_leech": Color(0.8, 0.25, 0.4),
	"mana_leech": Color(0.25, 0.4, 0.85),
	"movement_speed": Color(0.4, 0.9, 0.4),
	"base_accuracy": Color(0.8, 0.75, 0.5),
	"projectile_damage": Color(0.2, 0.8, 0.6),
	"area_damage": Color(0.9, 0.5, 0.5),
	"cooldown_recovery": Color(0.6, 0.6, 0.9),
	"keystone": Color(1.0, 0.8, 0.2),
}

func _get_cluster_color(cluster: String) -> Color:
	return CLUSTER_COLORS.get(cluster, Color(0.5, 0.48, 0.55))

func _get_icon_texture(type: YggdrasilNode.NodeType, cluster: String = "") -> ImageTexture:
	var color = _get_cluster_color(cluster) if not cluster.is_empty() else Color(0.5, 0.48, 0.55)
	match type:
		YggdrasilNode.NodeType.LARGE: return _make_icon_texture(52, Color(1.0, 0.85, 0.25))    # Keystone - bright gold
		YggdrasilNode.NodeType.MEDIUM: return _make_icon_texture(48, color)  # Notable - pure cluster color
		_: return _make_icon_texture(22, color)                                    # Small - unused now

func _get_border_texture(type: YggdrasilNode.NodeType, state: String) -> ImageTexture:
	var size: int = 52
	var thickness: float = 2.0
	var color: Color = Color(0.7, 0.65, 0.9)
	match type:
		YggdrasilNode.NodeType.LARGE:
			size = 56
			thickness = 3.0
			match state:
				"normal": color = Color(0.6, 0.45, 0.15)
				"intermediate": color = Color(0.9, 0.7, 0.2)
				"active": color = Color(1.0, 0.85, 0.35)
				_: color = Color(0.9, 0.7, 0.2)
		YggdrasilNode.NodeType.MEDIUM:
			size = 48
			thickness = 2.5
			match state:
				"normal": color = Color(0.45, 0.35, 0.65)
				"intermediate": color = Color(0.65, 0.5, 0.85)
				"active": color = Color(0.8, 0.65, 1.0)
				_: color = Color(0.65, 0.5, 0.85)
		_:
			size = 30
			thickness = 1.5
			match state:
				"normal": color = Color(0.35, 0.3, 0.2)
				"intermediate": color = Color(0.55, 0.45, 0.3)
				"active": color = Color(0.75, 0.6, 0.45)
				_: color = Color(0.55, 0.45, 0.3)
	return _make_border_texture(size, color, thickness)

func _get_line_texture(state: String) -> ImageTexture:
	match state:
		"normal": return _make_line_texture(10, 2, Color(0.3, 0.3, 0.4, 0.2))      # Almost invisible — reduces visual clutter
		"intermediate": return _make_line_texture(12, 3, Color(0.5, 0.45, 0.65, 0.5))  # Connected path
		"active": return _make_line_texture(14, 4, Color(0.9, 0.8, 0.4, 0.85))     # Allocated - gold
		_: return _make_line_texture(10, 2, Color(0.3, 0.3, 0.4, 0.2))

# --- Tree Building ---

func _init():
	print("=== Passive Skill Tree to Yggdrasil Converter ===\n")

	_generate_all_textures()

	var data = _load_json("res://data/passive_skill_tree.json")
	if data.is_empty():
		quit(1)
		return

	print("Loaded JSON. Building main tree...")
	var main_tree = _build_main_tree(data)
	var save_err = ResourceSaver.save(main_tree, "res://yggdrasil_data/trees/main_tree.tres")
	if save_err != OK:
		printerr("Failed to save main_tree.tres: ", save_err)
	else:
		print("Saved: main_tree.tres (%d nodes)" % main_tree.nodes.size())

	print("Building ascendancy trees...")
	var asc_trees = _build_ascendancy_trees(data)
	for cls_name in asc_trees:
		var asc_tree = asc_trees[cls_name]
		var safe_name = cls_name.to_lower().replace(" ", "_").replace("/", "_")
		var asc_path = "res://yggdrasil_data/trees/asc_%s.tres" % safe_name
		save_err = ResourceSaver.save(asc_tree, asc_path)
		if save_err != OK:
			printerr("Failed to save %s: %d" % [asc_path, save_err])
		else:
			print("Saved: %s (%d nodes)" % [asc_path, asc_tree.nodes.size()])

	print("\n=== Conversion complete! ===")
	quit()

func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		printerr("JSON not found: ", path)
		return {}
	var text = file.get_as_text()
	file.close()
	var p = JSON.new()
	var err = p.parse(text)
	if err != OK:
		printerr("JSON parse error: ", p.get_error_message())
		return {}
	return p.get_data()

func _is_filtered(n: Dictionary) -> bool:
	var name_lower = n.get("name", "").to_lower()
	var effects_lower = n.get("effects_raw", "").to_lower()
	if name_lower in FILTERED_MARK_NAMES:
		return true
	for kw in FILTERED_KEYWORDS:
		if kw in name_lower or kw in effects_lower:
			return true
	if "plant" in effects_lower and "overgrow" in effects_lower:
		return true
	return false

func _make_node(n: Dictionary) -> YggdrasilNode:
	var yn = YggdrasilNode.new()
	yn.id = int(n.get("id", 0))
	yn.name = n.get("name", "Unknown")
	yn.description = n.get("effects_raw", "")
	yn.max_allocations = 1
	yn.locked = false
	var sz = n.get("size", "small")
	match sz:
		"keystone": yn.type = YggdrasilNode.NodeType.LARGE
		"notable": yn.type = YggdrasilNode.NodeType.MEDIUM
		_: yn.type = YggdrasilNode.NodeType.SMALL
	yn.position = Vector2(0, 0)
	var mods = n.get("modifiers", [])
	if mods.size() > 0:
		yn.reference_id = JSON.stringify(mods)

	# Cluster-aware textures
	var cluster = _get_node_cluster_from_raw(n)
	yn.icon = _get_icon_texture(yn.type, cluster)
	yn.border_normal = _get_border_texture(yn.type, "normal")
	yn.border_intermediate = _get_border_texture(yn.type, "intermediate")
	yn.border_active = _get_border_texture(yn.type, "active")

	return yn

func _get_node_cluster_from_raw(raw_node: Dictionary) -> String:
	"""Determine which cluster a node belongs to from raw JSON data."""
	var mods = raw_node.get("modifiers", [])
	if mods.size() == 0: return "generic"

	var keys = []
	for m in mods:
		if m is Dictionary and m.has("key"):
			keys.push_back(str(m["key"]))

	if keys.size() == 0: return "generic"

	if "keystone_special" in keys: return "keystone"
	if "immunity_or_prohibition" in keys: return "keystone"

	var priority = [
		"fire_damage", "cold_damage", "lightning_damage",
		"chaos_damage", "physical_damage",
		"elemental_damage",
		"projectile_damage", "area_damage",
		"attack_speed", "cast_speed",
		"critical_chance", "critical_multiplier",
		"block_chance",
		"armour", "evasion", "base_energy_shield", "energy_shield_regen",
		"life_regen", "life_on_kill", "life_gain_on_hit", "base_life",
		"mana_regen", "mana_on_kill", "base_mana",
		"life_leech", "mana_leech",
		"movement_speed",
		"base_accuracy",
		"cooldown_recovery"
	]
	for p in priority:
		if p in keys: return p
	return "generic"


func _compute_tree_layout(ygg_nodes: Dictionary, cluster_map: Dictionary = {}) -> Dictionary:
	"""Radial flower layout — each cluster is a distinct petal/arm extending from center.
	Only notable and keystone nodes. NO depth-based positioning — everything is radial sector."""

	# 1. Merge tiny clusters (< 8 nodes) into "other"
	var MIN_CLUSTER_SIZE := 8
	var merged_cluster_map = {}
	var tiny_clusters := []
	var real_clusters := []
	for nid in ygg_nodes:
		var cl = cluster_map.get(nid, "generic")
		if cl.is_empty(): cl = "generic"
		merged_cluster_map[nid] = cl

	# Count, merge tiny ones
	var cl_counts := {}
	for nid in ygg_nodes:
		var cl = merged_cluster_map[nid]
		cl_counts[cl] = cl_counts.get(cl, 0) + 1

	# Merge all tiny clusters (< 8 nodes) into "other"
	for nid in ygg_nodes:
		if cl_counts.get(merged_cluster_map[nid], 0) < MIN_CLUSTER_SIZE:
			merged_cluster_map[nid] = "other"

	# Group into clusters using merged map
	var clusters = {}
	for nid in ygg_nodes:
		var cl = merged_cluster_map.get(nid, "generic")
		if cl.is_empty(): cl = "generic"
		if not clusters.has(cl): clusters[cl] = []
		clusters[cl].push_back(nid)

	var cl_list = []
	for cl in clusters:
		cl_list.push_back({"name": cl, "count": clusters[cl].size()})
	cl_list.sort_custom(func(a, b): return a.count > b.count)
	print("Layout clusters: %d" % cl_list.size())

	# 2. Assign angles — each cluster gets a sector
	var positions = {}
	var total_weight := 0.0
	var weights := {}
	for cl in cl_list:
		var w = max(1.0, float(cl.count))
		total_weight += w
		weights[cl.name] = w

	# Draw clusters in a 360° circle, starting from top (-90°) going clockwise
	var arc_start_deg := -90.0
	var arc_range_deg := 360.0
	var current_angle := arc_start_deg

	# Track which angles have been used (for collision avoidance between clusters)
	var used_spots := []  # [{angle, radius}]

	for ci in range(cl_list.size()):
		var cl_name = cl_list[ci].name
		var cl_nodes = clusters[cl_name]
		var wedge_deg = max(18.0, (weights[cl_name] / total_weight) * arc_range_deg)

		# Place center of this cluster's arm at the middle of its wedge
		var wedge_center_deg = current_angle + wedge_deg * 0.5
		current_angle += wedge_deg

		var ba = deg_to_rad(wedge_center_deg)
		var half_spread = deg_to_rad(min(25.0, wedge_deg * 0.35))

		# Separate keystone from notable nodes
		var keystones := []
		var notables := []
		for nid in cl_nodes:
			if ygg_nodes[nid].type == YggdrasilNode.NodeType.LARGE:
				keystones.push_back(nid)
			else:
				notables.push_back(nid)

		# Sort notables for consistent placement
		notables.sort()
		keystones.sort()

		# Base radius for this cluster — clusters with more nodes go slightly farther
		var base_r = 120.0 + min(cl_nodes.size(), 50) * 1.0

		# Place keystones at the TIP of the arm (farthest from center)
		for ki in range(keystones.size()):
			var nid = keystones[ki]
			var k_cnt = keystones.size()
			var rel = (ki - (k_cnt - 1) * 0.5) / max(1.0, k_cnt - 1.0)
			var a = ba + rel * half_spread * 0.5
			var r = base_r + 50.0  # Keystones at tip
			positions[nid] = Vector2(cos(a), sin(a)) * r

		# Place notables spread along the arm — earlier ones closer to center
		# Use multi-ring approach similar to flower petals
		var n_per_ring = 8  # 8 nodes per ring layer = more compact
		var ring_spacing = 48.0
		var angle_per_node = half_spread * 0.7 / max(1.0, n_per_ring - 1)

		for pi in range(notables.size()):
			var nid = notables[pi]
			var ring_idx = pi / n_per_ring  # Which ring layer
			var pos_in_ring = pi % n_per_ring  # Position within ring

			var r = base_r + ring_idx * ring_spacing
			var spread_frac = half_spread * (1.0 - ring_idx * 0.15)
			var rel_pos = (pos_in_ring - (n_per_ring - 1) * 0.5) / max(1.0, n_per_ring - 1)
			var a = ba + rel_pos * spread_frac

			# Collision check — push outward if too close to existing node
			var r_actual = r
			var collision = true
			var safety = 0
			while collision and safety < 10:
				collision = false
				for spot in used_spots:
					var dx = cos(a) * r_actual - cos(spot.angle) * spot.radius
					var dy = sin(a) * r_actual - sin(spot.angle) * spot.radius
					if dx * dx + dy * dy < 1600.0:  # 40px min distance
						collision = true
						r_actual += 30.0
						safety += 1
						break

			used_spots.push_back({"angle": a, "radius": r_actual})
			positions[nid] = Vector2(cos(a), sin(a)) * r_actual

	# Start nodes at exact center
	var start_ids = [20499, 2653, 18441, 2955, 42452]
	for nid in ygg_nodes:
		if nid in start_ids:
			positions[nid] = Vector2(0, 0)

	return positions

func _has_modifier_key(n: Dictionary) -> bool:
	var mods = n.get("modifiers", [])
	for m in mods:
		if m is Dictionary and m.has("key") and str(m["key"]) != "":
			return true
	return false

func _build_main_tree(data: Dictionary) -> YggdrasilTree:
	var raw_nodes = data.get("nodes", [])
	# ONLY notable + keystone nodes for a clean, readable tree
	var all_filtered_nodes = []
	var filtered_keystones = []
	for n in raw_nodes:
		if not (n is Dictionary): continue
		if _is_filtered(n): continue
		var sz = n.get("size", "")
		if sz == "keystone":
			filtered_keystones.append(n)
			all_filtered_nodes.append(n)
		elif sz == "notable":
			all_filtered_nodes.append(n)
		# Skip small and attribute nodes entirely — too many, causes visual chaos
	var notable_count = 0
	for n in all_filtered_nodes:
		if n.get("size", "") == "notable": notable_count += 1
	print("Including: %d notable + %d keystone = %d total" % [notable_count, filtered_keystones.size(), all_filtered_nodes.size()])

	var tree = YggdrasilTree.new()
	tree.id = "main_tree"
	tree.name = "Passive Skill Tree"
	tree.size = Vector2(16000, 12000)
	tree.bg_color = Color(0.04, 0.04, 0.06)
	tree.allocation = true
	tree.preallocation = true
	tree.multiallocation = false
	tree.revealed = true
	tree.version = 1
	tree.border_scale = 1.4
	tree.node_size[YggdrasilNode.NodeType.SMALL] = Vector2(14, 14)
	tree.node_size[YggdrasilNode.NodeType.MEDIUM] = Vector2(44, 44)
	tree.node_size[YggdrasilNode.NodeType.LARGE] = Vector2(64, 64)

	# Assign line textures inline (ImageTexture)
	tree.line_texture_normal = _get_line_texture("normal")
	tree.line_texture_intermediate = _get_line_texture("intermediate")
	tree.line_texture_active = _get_line_texture("active")

	var ygg_nodes = {}
	for n in all_filtered_nodes:
		var yn = _make_node(n)
		ygg_nodes[yn.id] = yn
		var connects = n.get("connects", [])
		var out_ids = []
		for c in connects: out_ids.append(int(c))
		yn.out_nodes = out_ids

	var start_ids = [20499, 2653, 18441, 2955, 42452]
	for nid in ygg_nodes:
		var yn = ygg_nodes[nid]
		if nid in start_ids: yn.is_root = true
		for out_id in yn.out_nodes:
			if ygg_nodes.has(out_id):
				var target = ygg_nodes[out_id]
				if not target.in_nodes.has(nid): target.in_nodes.append(nid)
		yn.out_nodes = yn.out_nodes.filter(func(id): return ygg_nodes.has(id))
		yn.in_nodes = yn.in_nodes.filter(func(id): return ygg_nodes.has(id))

	# Build cluster map from raw data
	var cluster_map = {}
	for n in all_filtered_nodes:
		var nid = int(n.get("id", 0))
		cluster_map[nid] = _get_node_cluster_from_raw(n)

	# NEW: compute tree layout (cluster-based radial)
	var layout_positions = _compute_tree_layout(ygg_nodes, cluster_map)
	for nid in layout_positions:
		if ygg_nodes.has(nid):
			ygg_nodes[nid].position = layout_positions[nid]

	# Normalize positions so min is (0,0)
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for nid in ygg_nodes:
		var p = ygg_nodes[nid].position
		min_pos = Vector2(min(min_pos.x, p.x), min(min_pos.y, p.y))
		max_pos = Vector2(max(max_pos.x, p.x), max(max_pos.y, p.y))
	var pos_offset := -min_pos
	for nid in ygg_nodes:
		ygg_nodes[nid].position += pos_offset
	var content_size := max_pos - min_pos
	tree.size = content_size + Vector2(RING_PADDING * 2, RING_PADDING * 2)
	print("Content bounds: ", min_pos, " to ", max_pos, ", size: ", tree.size)

	for nid in ygg_nodes: tree.nodes.append(ygg_nodes[nid])
	return tree

# Keystone layout is handled by _compute_tree_layout (BFS depth-based)

func _build_ascendancy_trees(data: Dictionary) -> Dictionary:
	var raw_asc_nodes = data.get("ascendancy_nodes", [])
	var by_class = {}
	for n in raw_asc_nodes:
		if not (n is Dictionary): continue
		var cls = n.get("class", "")
		if cls.is_empty(): continue
		var cls_lower = cls.to_lower()
		if not by_class.has(cls_lower):
			by_class[cls_lower] = {"name": cls, "nodes": []}
		by_class[cls_lower]["nodes"].append(n)

	var result = {}
	for cls_key in by_class:
		var cls_info = by_class[cls_key]
		var cls_name = cls_info["name"]
		var class_nodes = cls_info["nodes"]

		var tree = YggdrasilTree.new()
		tree.id = "asc_%s" % cls_key
		tree.name = "%s Ascendancy" % cls_name
		tree.size = Vector2(4000, 4000)
		tree.bg_color = Color(0.04, 0.04, 0.06)
		tree.allocation = true
		tree.preallocation = true
		tree.multiallocation = false
		tree.revealed = true
		tree.version = 1
		tree.border_scale = 1.5
		tree.node_size[YggdrasilNode.NodeType.SMALL] = Vector2(28, 28)
		tree.node_size[YggdrasilNode.NodeType.MEDIUM] = Vector2(48, 48)
		tree.node_size[YggdrasilNode.NodeType.LARGE] = Vector2(64, 64)

		# Assign line textures inline (ImageTexture)
		tree.line_texture_normal = _get_line_texture("normal")
		tree.line_texture_intermediate = _get_line_texture("intermediate")
		tree.line_texture_active = _get_line_texture("active")

		var ygg_nodes = {}
		for n in class_nodes:
			var yn = _make_node(n)
			ygg_nodes[yn.id] = yn
			var connects = n.get("connects", [])
			var out_ids = []
			for c in connects: out_ids.append(int(c))
			yn.out_nodes = out_ids

		for nid in ygg_nodes:
			var yn = ygg_nodes[nid]
			for out_id in yn.out_nodes:
				if ygg_nodes.has(out_id):
					var target = ygg_nodes[out_id]
					if not target.in_nodes.has(nid): target.in_nodes.append(nid)
			yn.out_nodes = yn.out_nodes.filter(func(id): return ygg_nodes.has(id))
			yn.in_nodes = yn.in_nodes.filter(func(id): return ygg_nodes.has(id))

		var found_root = false
		for nid in ygg_nodes:
			if ygg_nodes[nid].in_nodes.size() == 0:
				ygg_nodes[nid].is_root = true
				found_root = true
		if not found_root and ygg_nodes.size() > 0:
			var keys = ygg_nodes.keys()
			ygg_nodes[keys[0]].is_root = true

		for nid in ygg_nodes: tree.nodes.append(ygg_nodes[nid])
		result[cls_name] = tree

	return result
