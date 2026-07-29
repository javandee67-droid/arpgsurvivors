extends Node2D
class_name DungeonGenerator
## PoE tarzi acik arena zone generator - v6: 10 farkli biyom destegi

const TILE_SIZE := 32

enum CellType { FLOOR, WALL, ENTRANCE, EXIT, BOSS_AREA }

var grid: Array
var grid_width: int
var grid_height: int
var half: float = TILE_SIZE / 2.0
var spawn_points: Array = []
var current_biome: int = 0

# Önbelleğe alınmış Lit alıcı materyali (performans için)
var _lit_receiver_mat: ShaderMaterial = null

## Lit alıcı materyalini oluşturur (yoksa) ve döndürür.
func _get_lit_material() -> ShaderMaterial:
	if _lit_receiver_mat == null:
		var shader: Shader = load("res://addons/lit/shaders/lit_receiver.gdshader") as Shader
		if shader:
			_lit_receiver_mat = ShaderMaterial.new()
			_lit_receiver_mat.shader = shader
			_lit_receiver_mat.set_shader_parameter("emissive_strength", 0.0)
			_lit_receiver_mat.set_shader_parameter("receiver_mask", 1)
	return _lit_receiver_mat

## === BİYOM TANIMLARI ===
enum Biome {
	FOREST,     # 0: Yeşillik orman (varsayılan)
	SNOW,       # 1: Karlı dağ
	DESERT,     # 2: Çöl
	SWAMP,      # 3: Bataklık
	VOLCANIC,   # 4: Volkanik
	CRYSTAL,    # 5: Kristal mağarası
	DUNGEON,    # 6: Karanlık zindan
	HELL,       # 7: Cehennem
	GOLDEN,     # 8: Altın saray
	DEAD_REALM, # 9: Ölü diyar
}

const BIOME_NAMES: Array[String] = [
	"Yeşil Orman", "Karlı Dağ", "Kavurucu Çöl", "Zehireli Bataklık",
	"Alevli Volkan", "Kristal Mağarası", "Karanlık Zindan",
	"Cehennem Çukuru", "Altın Saray", "Ölü Diyar"
]

## Her biyomun harita oluşturma parametreleri (layout varyasyonu)
const BIOME_LAYOUT: Dictionary = {
	Biome.FOREST:       {"obstacle_density": 0.15, "room_attempts": 3, "min_room_size": 3, "max_room_size": 6, "corridor_chance": 0.0, "clusters": 2},
	Biome.SNOW:         {"obstacle_density": 0.12, "room_attempts": 4, "min_room_size": 4, "max_room_size": 8, "corridor_chance": 0.0, "clusters": 3},
	Biome.DESERT:       {"obstacle_density": 0.08, "room_attempts": 2, "min_room_size": 3, "max_room_size": 5, "corridor_chance": 0.3, "clusters": 1},
	Biome.SWAMP:        {"obstacle_density": 0.20, "room_attempts": 2, "min_room_size": 3, "max_room_size": 5, "corridor_chance": 0.0, "clusters": 4},
	Biome.VOLCANIC:     {"obstacle_density": 0.18, "room_attempts": 1, "min_room_size": 3, "max_room_size": 4, "corridor_chance": 0.2, "clusters": 3},
	Biome.CRYSTAL:      {"obstacle_density": 0.10, "room_attempts": 5, "min_room_size": 4, "max_room_size": 7, "corridor_chance": 0.1, "clusters": 2},
	Biome.DUNGEON:      {"obstacle_density": 0.25, "room_attempts": 6, "min_room_size": 5, "max_room_size": 9, "corridor_chance": 0.4, "clusters": 5},
	Biome.HELL:         {"obstacle_density": 0.22, "room_attempts": 2, "min_room_size": 3, "max_room_size": 5, "corridor_chance": 0.0, "clusters": 3},
	Biome.GOLDEN:       {"obstacle_density": 0.10, "room_attempts": 4, "min_room_size": 5, "max_room_size": 8, "corridor_chance": 0.0, "clusters": 2},
	Biome.DEAD_REALM:   {"obstacle_density": 0.20, "room_attempts": 3, "min_room_size": 3, "max_room_size": 6, "corridor_chance": 0.0, "clusters": 4},
}

## Her biyom için: zemin desenleri, duvar dekorları, renk paleti
const BIOME_DATA: Dictionary = {
	# === 0: ORMAN (FOREST) — yeşillik, ağaçlık, doğal ===
	Biome.FOREST: {
		"floors": {
			"main1": "res://assets/generated/tile_forest_floor.png",
			"main2": "res://assets/generated/tile_forest_moss.png",
			"sec1": "res://assets/generated/tile_grass_green.png",
			"sec2": "res://assets/generated/tile_dirt_frame_0.png",
		},
		"floor_weights": [40, 25, 20, 15],
		"floor_tint": Color(0.82, 0.88, 0.78),
		"floor_var": 0.25,
		"entrance_floor": "res://assets/generated/tile_stone_frame_0.png",
		"boss_floor": "res://assets/generated/tile_ash.png",
		"boss_tint": Color(1.0, 0.85, 0.75),
		"exit_floor": "res://assets/generated/tile_stone_frame_0.png",
		"wall_decor": [
			["res://assets/generated/decor_forest_pine.png", 30],
			["res://assets/generated/decor_oak_tree_frame_0.png", 25],
			["res://assets/generated/decor_bush_frame_0.png", 20],
			["res://assets/generated/decor_stone_statue.png", 15],
			["res://assets/generated/decor_runestone.png", 10],
		],
		"floor_decor_chance": 0.035,
		"floor_decor": [
			"res://assets/generated/decor_autumn_leaves.png",
			"res://assets/generated/decor_flowers_frame_0.png",
			"res://assets/generated/decor_mushrooms_frame_0.png",
			"res://assets/generated/decor_rocks_group_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_forest_floor.png", 50],
			["res://assets/generated/tile_forest_moss.png", 50],
		],
		"outside_ground_tint": Color(0.55, 0.65, 0.45),
		"outside_trees": [
			"res://assets/generated/spr_forest_oak.png",
			"res://assets/generated/decor_pine_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.75, 0.85, 0.65),
	},
	# === 1: KARLI DAĞ (SNOW) — buz, kar, soğuk ===
	Biome.SNOW: {
		"floors": {
			"main1": "res://assets/generated/tile_snow_ground.png",
			"main2": "res://assets/generated/tile_snow_permafrost.png",
			"sec1": "res://assets/generated/tile_ice.png",
			"sec2": "res://assets/generated/tile_gravel.png",
		},
		"floor_weights": [40, 30, 20, 10],
		"floor_tint": Color(0.92, 0.96, 1.0),
		"floor_var": 0.12,
		"entrance_floor": "res://assets/generated/tile_stone_frame_0.png",
		"boss_floor": "res://assets/generated/tile_ice.png",
		"boss_tint": Color(0.75, 0.85, 1.0),
		"exit_floor": "res://assets/generated/tile_stone_frame_0.png",
		"wall_decor": [
			["res://assets/generated/decor_snow_pine.png", 35],
			["res://assets/generated/decor_ice_crystals.png", 25],
			["res://assets/generated/decor_crystal_frame_0.png", 20],
			["res://assets/generated/decor_rocks_group_frame_0.png", 20],
		],
		"floor_decor_chance": 0.025,
		"floor_decor": [
			"res://assets/generated/decor_ice_crystals.png",
			"res://assets/generated/decor_rocks_group_frame_0.png",
			"res://assets/generated/decor_crystal_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_snow_ground.png", 60],
			["res://assets/generated/tile_snow_permafrost.png", 40],
		],
		"outside_ground_tint": Color(0.78, 0.82, 1.0),
		"outside_trees": [
			"res://assets/generated/spr_snow_pine.png",
			"res://assets/generated/decor_pine_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.78, 0.85, 1.0),
	},
	# === 2: KAVURUCU ÇÖL (DESERT) — kum, taş, kurak ===
	Biome.DESERT: {
		"floors": {
			"main1": "res://assets/generated/tile_desert_sand.png",
			"main2": "res://assets/generated/tile_desert_cracked.png",
			"sec1": "res://assets/generated/tile_sand.png",
			"sec2": "res://assets/generated/tile_gravel.png",
		},
		"floor_weights": [45, 25, 20, 10],
		"floor_tint": Color(1.0, 0.90, 0.72),
		"floor_var": 0.18,
		"entrance_floor": "res://assets/generated/tile_stone_frame_0.png",
		"boss_floor": "res://assets/generated/tile_desert_cracked.png",
		"boss_tint": Color(1.0, 0.82, 0.55),
		"exit_floor": "res://assets/generated/tile_stone_frame_0.png",
		"wall_decor": [
			["res://assets/generated/decor_desert_cactus.png", 30],
			["res://assets/generated/decor_rocks_group_frame_0.png", 25],
			["res://assets/generated/decor_boulder_frame_0.png", 20],
			["res://assets/generated/decor_skeleton_frame_0.png", 15],
			["res://assets/generated/decor_skull_bones.png", 10],
		],
		"floor_decor_chance": 0.02,
		"floor_decor": [
			"res://assets/generated/decor_skull_bones.png",
			"res://assets/generated/decor_rocks_group_frame_0.png",
			"res://assets/generated/decor_skeleton_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_desert_sand.png", 70],
			["res://assets/generated/tile_desert_cracked.png", 30],
		],
		"outside_ground_tint": Color(0.92, 0.82, 0.60),
		"outside_trees": [
			"res://assets/generated/spr_desert_palm.png",
			"res://assets/generated/decor_dead_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.88, 0.78, 0.55),
	},
	# === 3: ZEHİRLİ BATAKLIK (SWAMP) — çamur, zehir, sis ===
	Biome.SWAMP: {
		"floors": {
			"main1": "res://assets/generated/tile_swamp_muck.png",
			"main2": "res://assets/generated/tile_swamp_peat.png",
			"sec1": "res://assets/generated/tile_swamp.png",
			"sec2": "res://assets/generated/tile_mud.png",
		},
		"floor_weights": [40, 25, 20, 15],
		"floor_tint": Color(0.70, 0.82, 0.60),
		"floor_var": 0.25,
		"entrance_floor": "res://assets/generated/tile_mossy_stone.png",
		"boss_floor": "res://assets/generated/tile_swamp_muck.png",
		"boss_tint": Color(0.65, 0.88, 0.55),
		"exit_floor": "res://assets/generated/tile_mossy_stone.png",
		"wall_decor": [
			["res://assets/generated/decor_swamp_skeletal_tree.png", 30],
			["res://assets/generated/decor_roots_frame_0.png", 25],
			["res://assets/generated/decor_giant_mushroom.png", 20],
			["res://assets/generated/decor_web_frame_0.png", 15],
			["res://assets/generated/decor_grave_frame_0.png", 10],
		],
		"floor_decor_chance": 0.04,
		"floor_decor": [
			"res://assets/generated/decor_glow_shroom.png",
			"res://assets/generated/decor_mushrooms_frame_0.png",
			"res://assets/generated/decor_rocks_group_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_swamp_muck.png", 50],
			["res://assets/generated/tile_swamp_peat.png", 50],
		],
		"outside_ground_tint": Color(0.50, 0.60, 0.40),
		"outside_trees": [
			"res://assets/generated/spr_swamp_willow.png",
			"res://assets/generated/decor_dead_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.55, 0.65, 0.45),
	},
	# === 4: ALEVLİ VOLKAN (VOLCANIC) — lav, kül, ateş ===
	Biome.VOLCANIC: {
		"floors": {
			"main1": "res://assets/generated/tile_volcanic_cracked.png",
			"main2": "res://assets/generated/tile_volcanic_basalt.png",
			"sec1": "res://assets/generated/tile_volcanic.png",
			"sec2": "res://assets/generated/tile_lava.png",
		},
		"floor_weights": [35, 25, 20, 20],
		"floor_tint": Color(1.0, 0.72, 0.50),
		"floor_var": 0.18,
		"entrance_floor": "res://assets/generated/tile_stone_frame_0.png",
		"boss_floor": "res://assets/generated/tile_volcanic_cracked.png",
		"boss_tint": Color(1.0, 0.60, 0.35),
		"exit_floor": "res://assets/generated/tile_stone_frame_0.png",
		"wall_decor": [
			["res://assets/generated/decor_volcanic_pillar.png", 30],
			["res://assets/generated/decor_boulder_frame_0.png", 25],
			["res://assets/generated/decor_rocks_group_frame_0.png", 20],
			["res://assets/generated/decor_skeleton_frame_0.png", 15],
			["res://assets/generated/decor_barrel_frame_0.png", 10],
		],
		"floor_decor_chance": 0.02,
		"floor_decor": [
			"res://assets/generated/decor_rocks_group_frame_0.png",
			"res://assets/generated/decor_skeleton_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_volcanic_cracked.png", 50],
			["res://assets/generated/tile_volcanic_basalt.png", 50],
		],
		"outside_ground_tint": Color(0.85, 0.55, 0.35),
		"outside_trees": [
			"res://assets/generated/spr_volcanic_scorched.png",
			"res://assets/generated/decor_dead_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.75, 0.45, 0.25),
	},
	# === 5: KRİSTAL MAĞARASI (CRYSTAL) — kristal, mor ışık, büyülü ===
	Biome.CRYSTAL: {
		"floors": {
			"main1": "res://assets/generated/tile_crystal_purple.png",
			"main2": "res://assets/generated/tile_crystal_floor.png",
			"sec1": "res://assets/generated/tile_marble.png",
			"sec2": "res://assets/generated/tile_ice.png",
		},
		"floor_weights": [40, 25, 20, 15],
		"floor_tint": Color(0.82, 0.78, 1.0),
		"floor_var": 0.18,
		"entrance_floor": "res://assets/generated/tile_marble.png",
		"boss_floor": "res://assets/generated/tile_crystal_purple.png",
		"boss_tint": Color(0.70, 0.55, 1.0),
		"exit_floor": "res://assets/generated/tile_marble.png",
		"wall_decor": [
			["res://assets/generated/decor_crystal_shard.png", 35],
			["res://assets/generated/decor_crystal_frame_0.png", 25],
			["res://assets/generated/decor_magic_portal.png", 20],
			["res://assets/generated/decor_rocks_group_frame_0.png", 20],
		],
		"floor_decor_chance": 0.03,
		"floor_decor": [
			"res://assets/generated/decor_crystal_shard.png",
			"res://assets/generated/decor_crystal_frame_0.png",
			"res://assets/generated/decor_glow_shroom.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_crystal_purple.png", 50],
			["res://assets/generated/tile_crystal_floor.png", 50],
		],
		"outside_ground_tint": Color(0.65, 0.60, 0.85),
		"outside_trees": [
			"res://assets/generated/spr_crystal_tree.png",
		],
		"outside_tree_tint": Color(0.65, 0.62, 0.88),
	},
	# === 6: KARANLIK ZİNDAN (DUNGEON) — taş, loş, dar ===
	Biome.DUNGEON: {
		"floors": {
			"main1": "res://assets/generated/tile_dungeon_flagstone.png",
			"main2": "res://assets/generated/tile_dark_abyss.png",
			"sec1": "res://assets/generated/tile_cobblestone.png",
			"sec2": "res://assets/generated/tile_mossy_stone.png",
		},
		"floor_weights": [45, 25, 20, 10],
		"floor_tint": Color(0.50, 0.48, 0.60),
		"floor_var": 0.12,
		"entrance_floor": "res://assets/generated/tile_cobblestone.png",
		"boss_floor": "res://assets/generated/tile_dungeon_flagstone.png",
		"boss_tint": Color(0.60, 0.38, 0.55),
		"exit_floor": "res://assets/generated/tile_cobblestone.png",
		"wall_decor": [
			["res://assets/generated/decor_wall_torch_frame_0.png", 30],
			["res://assets/generated/decor_barrel_frame_0.png", 20],
			["res://assets/generated/decor_crate_frame_0.png", 20],
			["res://assets/generated/decor_web_frame_0.png", 15],
			["res://assets/generated/decor_skeleton_frame_0.png", 15],
		],
		"floor_decor_chance": 0.02,
		"floor_decor": [
			"res://assets/generated/decor_rocks_group_frame_0.png",
			"res://assets/generated/decor_skeleton_frame_0.png",
			"res://assets/generated/decor_barrel_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_dungeon_flagstone.png", 50],
			["res://assets/generated/tile_dark_abyss.png", 50],
		],
		"outside_ground_tint": Color(0.4, 0.35, 0.5),
		"outside_trees": [
			"res://assets/generated/spr_dungeon_withered.png",
			"res://assets/generated/decor_dead_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.35, 0.3, 0.4),
	},
	# === 7: CEHENNEM ÇUKURU (HELL) — kan, ateş, kıyamet ===
	Biome.HELL: {
		"floors": {
			"main1": "res://assets/generated/tile_hell_brimstone.png",
			"main2": "res://assets/generated/tile_blood_stone.png",
			"sec1": "res://assets/generated/tile_lava.png",
			"sec2": "res://assets/generated/tile_ash.png",
		},
		"floor_weights": [40, 25, 20, 15],
		"floor_tint": Color(1.0, 0.52, 0.42),
		"floor_var": 0.15,
		"entrance_floor": "res://assets/generated/tile_stone_frame_0.png",
		"boss_floor": "res://assets/generated/tile_hell_brimstone.png",
		"boss_tint": Color(1.0, 0.30, 0.20),
		"exit_floor": "res://assets/generated/tile_stone_frame_0.png",
		"wall_decor": [
			["res://assets/generated/decor_hell_flame.png", 30],
			["res://assets/generated/decor_skeleton_frame_0.png", 25],
			["res://assets/generated/decor_wall_torch_frame_0.png", 20],
			["res://assets/generated/decor_barrel_frame_0.png", 15],
			["res://assets/generated/decor_boulder_frame_0.png", 10],
		],
		"floor_decor_chance": 0.025,
		"floor_decor": [
			"res://assets/generated/decor_skull_bones.png",
			"res://assets/generated/decor_rocks_group_frame_0.png",
			"res://assets/generated/decor_skeleton_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_hell_brimstone.png", 50],
			["res://assets/generated/tile_blood_stone.png", 50],
		],
		"outside_ground_tint": Color(0.85, 0.38, 0.28),
		"outside_trees": [
			"res://assets/generated/decor_dead_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.75, 0.30, 0.20),
	},
	# === 8: ALTIN SARAY (GOLDEN) — altın, mermer, zenginlik ===
	Biome.GOLDEN: {
		"floors": {
			"main1": "res://assets/generated/tile_gold_palace.png",
			"main2": "res://assets/generated/tile_gold_floor.png",
			"sec1": "res://assets/generated/tile_marble.png",
			"sec2": "res://assets/generated/tile_cobblestone.png",
		},
		"floor_weights": [40, 30, 20, 10],
		"floor_tint": Color(1.0, 0.90, 0.62),
		"floor_var": 0.12,
		"entrance_floor": "res://assets/generated/tile_marble.png",
		"boss_floor": "res://assets/generated/tile_gold_palace.png",
		"boss_tint": Color(1.0, 0.88, 0.38),
		"exit_floor": "res://assets/generated/tile_marble.png",
		"wall_decor": [
			["res://assets/generated/decor_golden_pillar.png", 30],
			["res://assets/generated/decor_wall_torch_frame_0.png", 25],
			["res://assets/generated/decor_crate_frame_0.png", 20],
			["res://assets/generated/decor_stone_statue.png", 15],
			["res://assets/generated/decor_bush_frame_0.png", 10],
		],
		"floor_decor_chance": 0.03,
		"floor_decor": [
			"res://assets/generated/decor_treasure_coins.png",
			"res://assets/generated/decor_rocks_group_frame_0.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_gold_palace.png", 40],
			["res://assets/generated/tile_marble.png", 30],
			["res://assets/generated/tile_cobblestone.png", 30],
		],
		"outside_ground_tint": Color(0.88, 0.75, 0.48),
		"outside_trees": [
			"res://assets/generated/decor_oak_tree_frame_0.png",
		],
		"outside_tree_tint": Color(0.88, 0.82, 0.60),
	},
	# === 9: ÖLÜ DİYAR (DEAD_REALM) — kemik, karanlık, ölüm ===
	Biome.DEAD_REALM: {
		"floors": {
			"main1": "res://assets/generated/tile_dead_bone.png",
			"main2": "res://assets/generated/tile_dark_abyss.png",
			"sec1": "res://assets/generated/tile_dungeon_flagstone.png",
			"sec2": "res://assets/generated/tile_gravel.png",
		},
		"floor_weights": [40, 30, 20, 10],
		"floor_tint": Color(0.60, 0.50, 0.68),
		"floor_var": 0.15,
		"entrance_floor": "res://assets/generated/tile_cobblestone.png",
		"boss_floor": "res://assets/generated/tile_dead_bone.png",
		"boss_tint": Color(0.68, 0.40, 0.78),
		"exit_floor": "res://assets/generated/tile_cobblestone.png",
		"wall_decor": [
			["res://assets/generated/decor_dead_realm_tree.png", 25],
			["res://assets/generated/decor_skeleton_frame_0.png", 20],
			["res://assets/generated/decor_grave_frame_0.png", 20],
			["res://assets/generated/decor_roots_frame_0.png", 20],
			["res://assets/generated/decor_web_frame_0.png", 15],
		],
		"floor_decor_chance": 0.035,
		"floor_decor": [
			"res://assets/generated/decor_skull_bones.png",
			"res://assets/generated/decor_rocks_group_frame_0.png",
			"res://assets/generated/decor_glow_shroom.png",
		],
		"outside_ground": [
			["res://assets/generated/tile_dead_bone.png", 60],
			["res://assets/generated/tile_dark_abyss.png", 40],
		],
		"outside_ground_tint": Color(0.45, 0.38, 0.52),
		"outside_trees": [
			"res://assets/generated/spr_dungeon_withered.png",
		],
		"outside_tree_tint": Color(0.45, 0.38, 0.52),
	},
}


var is_arena: bool = false

func generate(zone_tier: int, biome_idx: int = Biome.FOREST) -> void:
	current_biome = biome_idx
	is_arena = false
	randomize()
	grid_width = 64 + zone_tier * 8
	grid_height = 64 + zone_tier * 8
	grid = []
	for x in range(grid_width):
		grid.append([])
		for y in range(grid_height):
			grid[x].append(CellType.FLOOR)
	_generate_border_walls()
	_generate_obstacles()
	_clear_boss_path()
	_generate_boss_area()
	_generate_entrance_path()
	_build_visuals()
	_populate_spawn_points()

func generate_arena(biome_idx: int = Biome.FOREST) -> void:
	"""Boss zone'lari icin kucuk, dairesel arena haritasi olusturur."""
	current_biome = biome_idx
	is_arena = true
	randomize()
	const ARENA_SIZE := 30
	grid_width = ARENA_SIZE
	grid_height = ARENA_SIZE
	grid = []

	# Tum gridi once FLOOR yap
	for x in range(grid_width):
		grid.append([])
		for y in range(grid_height):
			grid[x].append(CellType.FLOOR)

	# Dairesel arena duvarlari (merkezden uzaklik > yaricap ise WALL)
	var cx: float = grid_width / 2.0
	var cy: float = grid_height / 2.0
	var radius: float = grid_width / 2.0 - 1.5
	var cx_int: int = int(cx)
	var cy_int: int = int(cy)
	for x in range(grid_width):
		for y in range(grid_height):
			var dist := sqrt(pow(x - cx, 2) + pow(y - cy, 2))
			if dist > radius:
				grid[x][y] = CellType.WALL
			elif dist > radius - 1.5:
				# Ic duvar halkasi - BOSS_AREA olarak isaretle (ozel zemin)
				grid[x][y] = CellType.BOSS_AREA

	# Giris: sol tarafta — 3x3 genis alan ac, hicbir dekor/carpisma girmesin
	var entrance_y: int = grid_height / 2
	for ey in range(entrance_y - 1, entrance_y + 2):
		for ex in range(0, 4):
			if ex >= 0 and ex < grid_width and ey >= 0 and ey < grid_height:
				grid[ex][ey] = CellType.ENTRANCE

	# Boss: arena merkezinde cikisla ayni yerde
	if cx_int >= 0 and cx_int < grid_width and cy_int >= 0 and cy_int < grid_height:
		grid[cx_int][cy_int] = CellType.BOSS_AREA

	# Icine boss floor dokusu dok
	for x in range(1, grid_width - 1):
		for y in range(1, grid_height - 1):
			if grid[x][y] == CellType.FLOOR:
				grid[x][y] = CellType.BOSS_AREA

	_build_arena_visuals()

func _generate_border_walls() -> void:
	for x in range(grid_width):
		_set_wall(x, 0)
		_set_wall(x, grid_height - 1)
	for y in range(grid_height):
		_set_wall(0, y)
		_set_wall(grid_width - 1, y)

func _set_wall(x: int, y: int) -> void:
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		return
	grid[x][y] = CellType.WALL

func _generate_boss_area() -> void:
	var bx := grid_width - 6
	var by := grid_height / 2 - 3
	for dx in range(6):
		for dy in range(6):
			var cx := bx + dx
			var cy := by + dy
			if cx >= 0 and cx < grid_width and cy >= 0 and cy < grid_height:
				if dx == 0 or dx == 5 or dy == 0 or dy == 5:
					# Sol duvarin ortasinda giris kapisi birak
					if dx == 0 and (dy == 2 or dy == 3):
						grid[cx][cy] = CellType.BOSS_AREA  # Gecit
					else:
						grid[cx][cy] = CellType.WALL
				else:
					grid[cx][cy] = CellType.BOSS_AREA
	var ex := grid_width - 2
	var ey := grid_height / 2
	if ex >= 0 and ex < grid_width and ey >= 0 and ey < grid_height:
		grid[ex][ey] = CellType.EXIT

func _clear_boss_path() -> void:
	"""Boss odasina giden yolu ac: sag taraftaki engelleri kaldir."""
	var ey_center := grid_height / 2
	# Haritanin ortasindan boss odasina kadar olan 2-3 satirlik koridoru ac
	for y in range(ey_center - 2, ey_center + 3):
		for x in range(grid_width / 2, grid_width - 7):
			if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
				if grid[x][y] == CellType.WALL:
					grid[x][y] = CellType.FLOOR

func _generate_entrance_path() -> void:
	# Genis giris alani (5 genislik x 3 yukseklik) - tum hucreleri zorla ENTRANCE yap
	for y in range(grid_height / 2 - 1, grid_height / 2 + 2):
		for x in range(0, 5):
			if x >= 0 and x < grid_width and y >= 0 and y < grid_height:
				grid[x][y] = CellType.ENTRANCE

func _generate_obstacles() -> void:
	"""Biyom'a özel engel yoğunluğu ve deseni ile duvarlar oluştur."""
	var layout: Dictionary = BIOME_LAYOUT.get(current_biome, BIOME_LAYOUT[Biome.FOREST])
	var density: float = layout.get("obstacle_density", 0.15)
	var clusters: int = layout.get("clusters", 2)
	var corridor_chance: float = layout.get("corridor_chance", 0.0)

	# 1. Temel rastgele engeller (yoğunluk biyoma göre değişir)
	var base_count: int = int(grid_width * grid_height * density / 10.0)
	for i in range(base_count):
		var wx: int = randi() % grid_width
		var wy: int = randi() % grid_height
		# Giris alanini koru (x<5, borderlar)
		if wx <= 4 or wx >= grid_width - 2 or wy <= 1 or wy >= grid_height - 2:
			continue
		if grid[wx][wy] == CellType.FLOOR and randf() < density:
			grid[wx][wy] = CellType.WALL

	# 2. Biyom-spesifik kümeler (ör: bataklıkta yoğun kümeler, çölde seyrek)
	for c in range(clusters):
		var cx: int = randi() % (grid_width - 10) + 5
		var cy: int = randi() % (grid_height - 10) + 5
		var cluster_size: int = 3 + randi() % 5  # 3-7 hucrelik kume
		for j in range(cluster_size):
			var dx: int = cx + (randi() % 5 - 2)
			var dy: int = cy + (randi() % 5 - 2)
			if dx >= 5 and dx < grid_width - 2 and dy >= 2 and dy < grid_height - 2:
				if grid[dx][dy] == CellType.FLOOR:
					grid[dx][dy] = CellType.WALL

	# 3. Koridor engelleri (çöl, volkan, zindan gibi biyomlarda)
	if corridor_chance > 0.0:
		for ci in range(grid_width * grid_height / 30):
			var wx2: int = randi() % grid_width
			var wy2: int = randi() % grid_height
			if wx2 <= 4 or wx2 >= grid_width - 2 or wy2 <= 1 or wy2 >= grid_height - 2:
				continue
			if grid[wx2][wy2] == CellType.FLOOR and randf() < corridor_chance:
				# 2-4 hucrelik yatay veya dikey duvar seridi
				var length: int = 2 + randi() % 3
				var horiz: bool = randi() % 2 == 0
				for l in range(length):
					var nx: int = wx2 + (l if horiz else 0)
					var ny: int = wy2 + (0 if horiz else l)
					if nx >= 5 and nx < grid_width - 2 and ny >= 2 and ny < grid_height - 2:
						if grid[nx][ny] == CellType.FLOOR:
							grid[nx][ny] = CellType.WALL

func _build_arena_visuals() -> void:
	"""Arena icin ozel goruntu olusturucu: dis orman yok, duvar dekorasyonlari, isiltili zemin."""
	var biome_data: Dictionary = BIOME_DATA.get(current_biome, BIOME_DATA[Biome.FOREST])

	# Boss zemin dokusunu yukle (arena'nin her yeri boss floor)
	var boss_tex: Texture2D = _load_tex(biome_data.get("boss_floor", ""))
	var boss_tint: Color = biome_data.get("boss_tint", Color(1.0, 0.85, 0.75))
	var entrance_tex: Texture2D = _load_tex(biome_data.get("entrance_floor", ""))

	# Duvar dekorasyonlari
	var wall_decor_list: Array = biome_data.get("wall_decor", [])
	var wall_tex_arr: Array = []
	for entry in wall_decor_list:
		var tex := _load_tex(entry[0] as String)
		if tex:
			wall_tex_arr.append([tex, entry[1] as int])

	# === FLOOR TILES ===
	for x in range(grid_width):
		for y in range(grid_height):
			var world_pos := Vector2(x, y) * TILE_SIZE + Vector2(half, half)
			var cell: CellType = grid[x][y]

			if cell == CellType.WALL:
				continue

			var floor_tex: Texture2D
			var floor_mod := Color.WHITE

			match cell:
				CellType.ENTRANCE:
					floor_tex = entrance_tex if entrance_tex else boss_tex
					floor_mod = Color(0.8, 0.8, 0.8)
				CellType.BOSS_AREA:
					floor_tex = boss_tex
					# Hafif renk degisimi ile canli bir arena zemini
					var r_offset: float = randf() * 0.15 - 0.075
					var g_offset: float = randf() * 0.1 - 0.05
					var b_offset: float = randf() * 0.1 - 0.05
					floor_mod = Color(
						clampf(boss_tint.r + r_offset, 0.0, 1.0),
						clampf(boss_tint.g + g_offset, 0.0, 1.0),
						clampf(boss_tint.b + b_offset, 0.0, 1.0)
					)
				_:
					floor_tex = boss_tex
					floor_mod = boss_tint

			if not floor_tex:
				continue

			var gnd := Sprite2D.new()
			gnd.texture = floor_tex
			gnd.position = world_pos
			gnd.z_index = 0
			gnd.modulate = floor_mod
			var lm_arena_floor := _get_lit_material()
			if lm_arena_floor:
				gnd.material = lm_arena_floor
			add_child(gnd)

	# === WALL TILES (decor) ===
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != CellType.WALL:
				continue
			var world_pos := Vector2(x, y) * TILE_SIZE + Vector2(half, half)

			if wall_tex_arr.is_empty():
				continue
			var total_w: int = 0
			for wt in wall_tex_arr:
				total_w += wt[1]
			var rw: int = randi() % max(total_w, 1)
			var acc: int = 0
			var decor_tex: Texture2D = wall_tex_arr[0][0]
			for wt in wall_tex_arr:
				acc += wt[1]
				if rw < acc:
					decor_tex = wt[0]
					break

			# Duvara bakan tarafa gore yon ver (arena ici tarafa bakmali)
			# Basit: x=0 veya x=max sol/sag duvar, y=0 veya y=max ust/alt duvar
			var mirror_x: bool = x >= grid_width - 2
			var spr := Sprite2D.new()
			spr.texture = decor_tex
			spr.position = world_pos
			spr.z_index = 2
			var lm_arena_wall := _get_lit_material()
			if lm_arena_wall:
				spr.material = lm_arena_wall
			if mirror_x:
				spr.flip_h = true
			add_child(spr)

	# === ARENA COLLISION (cevre duvari) ===
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != CellType.WALL:
				continue
			var world_pos := Vector2(x, y) * TILE_SIZE + Vector2(half, half)
			var wall_body := RapierStaticBody2D.new()
			wall_body.position = world_pos
			wall_body.collision_layer = 1
			wall_body.collision_mask = 0
			wall_body.body_skin = 0.01
			var wall_col := CollisionShape2D.new()
			var wall_shape := RectangleShape2D.new()
			wall_shape.size = Vector2(TILE_SIZE, TILE_SIZE)
			wall_col.shape = wall_shape
			wall_body.add_child(wall_col)
			add_child(wall_body)

	# === IC HALKADA DEKORATIF TORCH/YILDIZ ISIGI ===
	# Ic halkadaki BOSS_AREA hucresine kucuk dekor ekle
	var deco_chance: float = biome_data.get("floor_decor_chance", 0.03) * 3.0
	var floor_decor_list: Array = biome_data.get("floor_decor", [])
	var floor_decor_tex_arr: Array = []
	for path in floor_decor_list:
		var tex := _load_tex(path)
		if tex:
			floor_decor_tex_arr.append(tex)

	for x in range(1, grid_width - 1):
		for y in range(1, grid_height - 1):
			var world_pos := Vector2(x, y) * TILE_SIZE + Vector2(half, half)
			if grid[x][y] != CellType.BOSS_AREA:
				continue
			if randf() < deco_chance and not floor_decor_tex_arr.is_empty():
				var small_decor: Texture2D = floor_decor_tex_arr[randi() % floor_decor_tex_arr.size()]
				if small_decor:
					var d_spr := Sprite2D.new()
					d_spr.texture = small_decor
					d_spr.position = world_pos
					d_spr.z_index = 1
					d_spr.modulate = Color(1.0, 1.0, 0.9, 0.5 + randf() * 0.3)
					var lm_arena_decor := _get_lit_material()
					if lm_arena_decor:
						d_spr.material = lm_arena_decor
					add_child(d_spr)


func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _build_visuals() -> void:
	var biome_data: Dictionary = BIOME_DATA.get(current_biome, BIOME_DATA[Biome.FOREST])

	# Load floor textures
	var fl: Dictionary = biome_data.get("floors", {}) as Dictionary
	var floor_tex_map: Array = [
		_load_tex(fl.get("main1", "")),
		_load_tex(fl.get("main2", "")),
		_load_tex(fl.get("sec1", "")),
		_load_tex(fl.get("sec2", "")),
	]
	var floor_weights: Array = biome_data.get("floor_weights", [25, 25, 25, 25])
	var floor_tint_base: Color = biome_data.get("floor_tint", Color.WHITE)
	var floor_var: float = biome_data.get("floor_var", 0.2)

	var entrance_tex: Texture2D = _load_tex(biome_data.get("entrance_floor", ""))
	var boss_tex: Texture2D = _load_tex(biome_data.get("boss_floor", ""))
	var boss_tint: Color = biome_data.get("boss_tint", Color.WHITE)
	var exit_tex: Texture2D = _load_tex(biome_data.get("exit_floor", ""))

	# Load wall decor textures
	var wall_decor_list: Array = biome_data.get("wall_decor", [])

	# Load floor decor textures
	var floor_decor_list: Array = biome_data.get("floor_decor", [])
	var floor_decor_chance: float = biome_data.get("floor_decor_chance", 0.03)

	# Build wall decor weight table
	var wall_tex_arr: Array = []
	for entry in wall_decor_list:
		var tex := _load_tex(entry[0] as String)
		if tex:
			wall_tex_arr.append([tex, entry[1] as int])

	# Build floor decor texture array
	var floor_decor_tex_arr: Array = []
	for path in floor_decor_list:
		var tex := _load_tex(path)
		if tex:
			floor_decor_tex_arr.append(tex)

	# === FLOOR TILES ===
	for x in range(grid_width):
		for y in range(grid_height):
			var world_pos := Vector2(x, y) * TILE_SIZE + Vector2(half, half)
			var cell: CellType = grid[x][y]

			if cell == CellType.WALL:
				continue

			var floor_tex: Texture2D
			var floor_mod := Color.WHITE

			match cell:
				CellType.ENTRANCE:
					floor_tex = entrance_tex
				CellType.BOSS_AREA:
					floor_tex = boss_tex
					floor_mod = boss_tint
				CellType.EXIT:
					floor_tex = exit_tex
				_:
					# Weighted random floor from biome palette
					var total_w: int = 0
					for w in floor_weights:
						total_w += w
					var rw: int = randi() % max(total_w, 1)
					var acc: int = 0
					for fi in range(floor_tex_map.size()):
						acc += floor_weights[fi]
						if rw < acc:
							floor_tex = floor_tex_map[fi]
							break
					if not floor_tex:
						continue
					floor_mod = Color(
						floor_tint_base.r + randf() * floor_var - floor_var * 0.5,
						floor_tint_base.g + randf() * floor_var - floor_var * 0.5,
						floor_tint_base.b + randf() * floor_var - floor_var * 0.5,
					)

			if not floor_tex:
				continue

			var gnd := Sprite2D.new()
			gnd.texture = floor_tex
			gnd.position = world_pos
			gnd.z_index = 0
			gnd.modulate = floor_mod
			var lm_floor := _get_lit_material()
			if lm_floor:
				gnd.material = lm_floor
			add_child(gnd)

			# === GIRIS NOKTASI DEKORU ===
			# Doğduğumuz yerde (entrance merkezi) özel bir spawn stone göster
			# get_entrance_world() = (TILE_SIZE * 2, TILE_SIZE * (grid_height / 2))
			# Bu pozisyon grid'de (2, grid_height/2)'ye denk gelir
			if cell == CellType.ENTRANCE:
				var ey := grid_height / 2
				# Sadece spawn noktasındaki hücreye koy — get_entrance_world() ile aynı pozisyon
				# Normal map: x=2, arena: x=1
				var spawn_x := 1 if is_arena else 2
				if x == spawn_x and y == ey:
					var spawn_stone_tex: Texture2D = _load_tex("res://assets/generated/decor_spawn_stone.png")
					if spawn_stone_tex:
						var stone_spr := Sprite2D.new()
						stone_spr.texture = spawn_stone_tex
						stone_spr.position = world_pos
						stone_spr.z_index = 3
						stone_spr.modulate = Color(1.0, 1.0, 1.0, 1.0)
						var lm_stone := _get_lit_material()
						if lm_stone:
							stone_spr.material = lm_stone
						add_child(stone_spr)

			# Occasional small decor on FLOOR cells
			if cell == CellType.FLOOR and randf() < floor_decor_chance and not floor_decor_tex_arr.is_empty():
				var small_decor: Texture2D = floor_decor_tex_arr[randi() % floor_decor_tex_arr.size()]
				if small_decor:
					var d_spr := Sprite2D.new()
					d_spr.texture = small_decor
					d_spr.position = world_pos
					d_spr.z_index = 1
					d_spr.modulate = Color(0.9, 0.9, 0.8, 0.7 + randf() * 0.3)
					var lm_decor := _get_lit_material()
					if lm_decor:
						d_spr.material = lm_decor
					add_child(d_spr)

	# === WALL TILES (decor) ===
	for x in range(grid_width):
		for y in range(grid_height):
			var world_pos := Vector2(x, y) * TILE_SIZE + Vector2(half, half)
			var cell: CellType = grid[x][y]

			if cell != CellType.WALL:
				continue

			# Weighted random wall decor
			if wall_tex_arr.is_empty():
				continue
			var total_w: int = 0
			for wt in wall_tex_arr:
				total_w += wt[1]
			var rw: int = randi() % max(total_w, 1)
			var acc: int = 0
			var decor_tex: Texture2D = wall_tex_arr[0][0]
			for wt in wall_tex_arr:
				acc += wt[1]
				if rw < acc:
					decor_tex = wt[0]
					break

			var spr := Sprite2D.new()
			spr.texture = decor_tex
			spr.position = world_pos
			spr.z_index = 2
			var lm_wall := _get_lit_material()
			if lm_wall:
				spr.material = lm_wall
			add_child(spr)

	# === TUM DUVARLAR ICIN COLLISION (ic duvarlar dahil) ===
	for x in range(grid_width):
		for y in range(grid_height):
			if grid[x][y] != CellType.WALL:
				continue
			var world_pos := Vector2(x, y) * TILE_SIZE + Vector2(half, half)
			var wall_body := RapierStaticBody2D.new()
			wall_body.position = world_pos
			wall_body.collision_layer = 1
			wall_body.collision_mask = 0
			wall_body.body_skin = 0.01
			var wall_col := CollisionShape2D.new()
			var wall_shape := RectangleShape2D.new()
			wall_shape.size = Vector2(TILE_SIZE, TILE_SIZE)
			wall_col.shape = wall_shape
			wall_body.add_child(wall_col)
			add_child(wall_body)

	# === OUTSIDE FOREST (biyom renkleriyle) ===
	var forest_ring := 16
	var outside_ground_list: Array = biome_data.get("outside_ground", [])
	var outside_ground_tint_base: Color = biome_data.get("outside_ground_tint", Color(0.6, 0.7, 0.5))
	var outside_trees_list: Array = biome_data.get("outside_trees", [])
	var outside_tree_tint_base: Color = biome_data.get("outside_tree_tint", Color(0.8, 0.9, 0.7))

	# Load outside ground textures
	var og_tex_arr: Array = []
	for entry in outside_ground_list:
		var tex := _load_tex(entry[0])
		if tex:
			og_tex_arr.append([tex, entry[1]])

	# Load outside tree textures
	var ot_tex_arr: Array = []
	for path in outside_trees_list:
		var tex := _load_tex(path)
		if tex:
			ot_tex_arr.append(tex)

	for ox in range(-forest_ring, grid_width + forest_ring):
		for oy in range(-forest_ring, grid_height + forest_ring):
			if ox >= 0 and ox < grid_width and oy >= 0 and oy < grid_height:
				continue
			var dist_to_edge := mini(
				mini(abs(ox), abs(ox - grid_width + 1)),
				mini(abs(oy), abs(oy - grid_height + 1))
			)
			if dist_to_edge > forest_ring:
				continue

			# Ground tile
			if not og_tex_arr.is_empty() and randf() < 0.95:
				var chosen_entry: Array = og_tex_arr[0]
				var total_ow: int = 0
				for e in og_tex_arr: total_ow += e[1]
				var row: int = randi() % max(total_ow, 1)
				var oacc: int = 0
				for e in og_tex_arr:
					oacc += e[1]
					if row < oacc:
						chosen_entry = e
						break
				var gnd := Sprite2D.new()
				gnd.texture = chosen_entry[0]
				gnd.position = Vector2(ox, oy) * TILE_SIZE + Vector2(half, half)
				gnd.z_index = 0
				gnd.modulate = outside_ground_tint_base
				var lm_og := _get_lit_material()
				if lm_og:
					gnd.material = lm_og
				add_child(gnd)

			# Trees with deterministic position hash
			if ot_tex_arr.is_empty():
				continue
			var tree_hash: int = abs(ox * 73856093 + oy * 19349663 + ox * oy * 83492791)
			var density_val := 0.995 if dist_to_edge <= 4 else 0.95 if dist_to_edge <= 10 else 0.80
			if float(tree_hash % 1000) / 1000.0 > density_val:
				continue
			var tree_tex: Texture2D = ot_tex_arr[(tree_hash / 7) % ot_tex_arr.size()]
			if not tree_tex:
				continue
			var t_spr := Sprite2D.new()
			t_spr.texture = tree_tex
			t_spr.position = Vector2(ox, oy) * TILE_SIZE + Vector2(half, half)
			t_spr.z_index = 2
			t_spr.modulate = outside_tree_tint_base
			var lm_tree := _get_lit_material()
			if lm_tree:
				t_spr.material = lm_tree
			t_spr.scale = Vector2(0.9, 0.9) + Vector2(
				float((tree_hash / 3) % 30) / 100.0,
				float((tree_hash / 5) % 30) / 100.0
			)
			add_child(t_spr)

func _populate_spawn_points() -> void:
	spawn_points.clear()
	var entrance_y: int = grid_height / 2
	for x in range(grid_width):
		for y in range(grid_height):
			var cell: CellType = grid[x][y]
			if cell == CellType.FLOOR or cell == CellType.BOSS_AREA:
				if x <= 4 and abs(y - entrance_y) <= 3:
					continue
				if cell == CellType.BOSS_AREA:
					continue
				spawn_points.append(Vector2i(x, y))
	spawn_points.shuffle()

func get_enemy_count() -> int:
	if is_arena:
		return 0
	# %15 azaltma: /40 yerine *17/800 (0.85/40 ile aynı, tam sayı aritmetiği)
	return grid_width * grid_height * 17 / 800

func get_spawn_points() -> Array:
	return spawn_points

func get_entrance_world() -> Vector2:
	if is_arena:
		return Vector2(TILE_SIZE * 1, TILE_SIZE * (grid_height / 2))
	return Vector2(TILE_SIZE * 2, TILE_SIZE * (grid_height / 2))

func get_boss_room_world() -> Vector2:
	if is_arena:
		# Boss arena merkezinde spawnlanir
		return Vector2(TILE_SIZE * (grid_width / 2), TILE_SIZE * (grid_height / 2))
	return Vector2(TILE_SIZE * (grid_width - 3), TILE_SIZE * (grid_height / 2))

func get_exit_world() -> Vector2:
	if is_arena:
		# Arena'da cikis boss ile ayni yerde (boss olunce merdiven acilir)
		return Vector2(TILE_SIZE * (grid_width / 2), TILE_SIZE * (grid_height / 2))
	return Vector2(TILE_SIZE * (grid_width - 2), TILE_SIZE * (grid_height / 2))

func _has_floor_neighbor(x: int, y: int) -> bool:
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx >= 0 and nx < grid_width and ny >= 0 and ny < grid_height:
				if grid[nx][ny] != CellType.WALL:
					return true
	return false

## Bulunduğumuz biyomun ekran adını döndürür
func get_biome_name() -> String:
	return BIOME_NAMES[current_biome] if current_biome >= 0 and current_biome < BIOME_NAMES.size() else "Bilinmeyen"
