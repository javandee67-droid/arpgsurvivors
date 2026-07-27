extends Node2D
class_name MapGenerator
## Path of Exile tarzi acik dunya harita generatoru.
## Labirent yok - genis acik alan, daginik engeller, cesitli zeminler.

const tile_size: int = 32
var map_width: int = 160
var map_height: int = 120

## Zemin tipleri
enum FloorType { GRASS, DIRT, STONE, SAND, WATER, LOAM, SANDY, CLAY }

var floor_grid: Array = []  # 2D array [x][y] -> FloorType
var wall_grid: Dictionary = {}
var decoration_grid: Dictionary = {}
var spawn_points: Array = []  # Vector2i
var room_centers: Array = []    # Vector2 (world coords)
var floor_tiles: Dictionary = {}

var _wall_textures: Array = []
var _floor_textures: Dictionary = {}
var _decor_textures: Dictionary = {}

func generate() -> void:
	spawn_points.clear()
	room_centers.clear()
	decoration_grid.clear()
	wall_grid.clear()
	floor_tiles.clear()
	
	for c in get_children():
		c.queue_free()
	
	_load_textures()
	
	# 1. Zemin grid'ini baslat (tumu GRASS)
	floor_grid.clear()
	for x in range(map_width):
		floor_grid.append([])
		for y in range(map_height):
			floor_grid[x].append(FloorType.GRASS)
	
	# 2. Cevre duvarlari (harita siniri)
	_generate_border_walls()
	
	# (VS mod: Ic duvar kumeleri kaldirildi - canavarlar takilmasin)
	
	# 3. Ozel bolgeler (sadece zemin desenleri, duvar yok)
	_generate_vs_clearings(8)
	_generate_grass_patches(15)
	_generate_dirt_patches(20)
	
	# 4. Zemin desenleri - cok cesitli
	_generate_dirt_paths(4)
	_generate_grass_variation()
	_generate_earth_patches(40)  # çamur, kumlu toprak, çakıl alanlar
	
	# 5. Dekorasyonlar - sadece gorsel, fiziksel engel yok
	_generate_tree_clusters(15)
	_generate_flower_clusters(12)
	_generate_scattered_decor(15)
	
	# 7. Floor goruntuleme
	_build_floor_visuals()
	
	# 8. Spawn noktalari
	_calculate_spawn_points()
	
	# 9. Merkez bolgeler
	_calculate_room_centers()

func _load_textures() -> void:
	_floor_textures[FloorType.GRASS] = _t("res://assets/generated/tile_grass_new.png")
	_floor_textures[FloorType.DIRT] = _t("res://assets/generated/tile_dirt.png")
	_floor_textures[FloorType.STONE] = _t("res://assets/generated/tile_stone.png")
	_floor_textures[FloorType.LOAM] = _t("res://assets/generated/tile_mud.png")
	_floor_textures[FloorType.SANDY] = _t("res://assets/generated/tile_desert_sand.png")
	_floor_textures[FloorType.CLAY] = _t("res://assets/generated/tile_gravel.png")
	var wt := _t("res://assets/generated/tile_wall_frame_0.png")
	if wt: _wall_textures.append(wt)
	var tree := _t("res://assets/generated/spr_tree_frame_0.png")
	if tree: _decor_textures["tree"] = tree
	var rock := _t("res://assets/generated/spr_rocks_frame_0.png")
	if rock: _decor_textures["rocks"] = rock
	var torch := _t("res://assets/generated/spr_torch_poe_frame_0.png")
	if torch: _decor_textures["torch"] = torch
	# Animated grass ornament overlay — kaldirildi (beyaz kare sorunu)

func _t(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func _set_floor(x: int, y: int, ft: FloorType) -> void:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return
	floor_grid[x][y] = ft

func _is_wall(x: int, y: int) -> bool:
	return wall_grid.has(str(x) + "," + str(y))

func _set_wall(x: int, y: int) -> void:
	var key := str(x) + "," + str(y)
	if wall_grid.has(key):
		return
	wall_grid[key] = true
	var half := tile_size / 2.0
	var wall := StaticBody2D.new()
	wall.position = Vector2(x, y) * tile_size + Vector2(half, half)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tile_size, tile_size)
	col.shape = shape
	wall.add_child(col)
	var tex: Texture2D = _wall_textures[0] if not _wall_textures.is_empty() else null
	if tex:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.position = Vector2(-half, -half)
		wall.add_child(spr)
	else:
		var vis := ColorRect.new()
		vis.size = Vector2(tile_size, tile_size)
		vis.color = Color(0.08, 0.06, 0.07)
		vis.position = Vector2(-half, -half)
		wall.add_child(vis)
	add_child(wall)

func _generate_border_walls() -> void:
	for x in range(-1, map_width + 1):
		_set_wall(x, -1)
		_set_wall(x, map_height)
	for y in range(-1, map_height + 1):
		_set_wall(-1, y)
		_set_wall(map_width, y)

# ---- VS mod: engel yok, sadece zemin desenleri ----

func _generate_vs_clearings(count: int) -> void:
	for i in range(count):
		var cx := randi_range(10, map_width - 11)
		var cy := randi_range(10, map_height - 11)
		var radius := randi_range(6, 10)
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var dist := sqrt(float(dx * dx + dy * dy))
				if dist <= radius:
					var tx := cx + dx
					var ty := cy + dy
					if tx >= 0 and tx < map_width and ty >= 0 and ty < map_height:
						_set_floor(tx, ty, FloorType.STONE if dist <= radius - 2 else FloorType.DIRT)

func _generate_grass_patches(count: int) -> void:
	for i in range(count):
		var cx := randi_range(4, map_width - 5)
		var cy := randi_range(4, map_height - 5)
		var radius := randi_range(3, 6)
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var dist := sqrt(float(dx * dx + dy * dy))
				if dist <= radius:
					var tx := cx + dx
					var ty := cy + dy
					if tx >= 0 and tx < map_width and ty >= 0 and ty < map_height:
						_set_floor(tx, ty, FloorType.GRASS)

func _generate_dirt_patches(count: int) -> void:
	"""Kucuk kirli/kumlu alanlar - zemin cesitliligi icin."""
	for i in range(count):
		var cx := randi_range(4, map_width - 5)
		var cy := randi_range(4, map_height - 5)
		var radius := randi_range(2, 4)
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var dist := sqrt(float(dx * dx + dy * dy))
				if dist <= radius:
					var tx := cx + dx
					var ty := cy + dy
					if tx >= 0 and tx < map_width and ty >= 0 and ty < map_height:
						_set_floor(tx, ty, FloorType.DIRT)

func _generate_earth_patches(count: int) -> void:
	"""LOAM, SANDY, CLAY alanlari - kahverengi tonlarinda cesitlilik."""
	var types: Array[FloorType] = [FloorType.LOAM, FloorType.SANDY, FloorType.CLAY]
	for i in range(count):
		var cx := randi_range(5, map_width - 6)
		var cy := randi_range(5, map_height - 6)
		var radius := randi_range(3, 7)
		var chosen: FloorType = types[randi() % types.size()]
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var dist := sqrt(float(dx * dx + dy * dy))
				if dist <= radius:
					var tx := cx + dx
					var ty := cy + dy
					if tx >= 0 and tx < map_width and ty >= 0 and ty < map_height:
						# Merkeze dogru yeni tip, kenarlara dogru mevcut zemin kari$ik
						if dist <= radius * 0.6:
							_set_floor(tx, ty, chosen)
						elif floor_grid[tx][ty] == FloorType.GRASS and randf() < 0.5:
							_set_floor(tx, ty, chosen)

func _generate_flower_clusters(count: int) -> void:
	for i in range(count):
		var cx := randi_range(4, map_width - 5)
		var cy := randi_range(4, map_height - 5)
		for j in range(randi_range(3, 6)):
			var tx := cx + randi_range(-3, 3)
			var ty := cy + randi_range(-3, 3)
			var key := str(tx) + "," + str(ty)
			if tx >= 1 and tx < map_width - 1 and ty >= 1 and ty < map_height - 1 and not decoration_grid.has(key):
				var flower_types: Array[String] = ["flower1", "flower2", "flower3"]
				decoration_grid[key] = {"type": flower_types[randi() % flower_types.size()]}

func _generate_clearings(count: int) -> void:
	for i in range(count):
		var cx := randi_range(10, map_width - 11)
		var cy := randi_range(10, map_height - 11)
		var radius := randi_range(4, 6)
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var dist := sqrt(float(dx * dx + dy * dy))
				if dist <= radius:
					var tx := cx + dx
					var ty := cy + dy
					if tx >= 0 and tx < map_width and ty >= 0 and ty < map_height and not _is_wall(tx, ty):
						_set_floor(tx, ty, FloorType.STONE if dist <= radius - 1 else FloorType.DIRT)
		# Mesale
		if not _is_wall(cx, cy) and not decoration_grid.has(str(cx) + "," + str(cy)):
			decoration_grid[str(cx) + "," + str(cy)] = {"type": "torch"}

func _generate_camp_site() -> void:
	var cx := randi_range(18, map_width - 19)
	var cy := randi_range(18, map_height - 19)
	for dx in range(-5, 6):
		for dy in range(-5, 6):
			var tx := cx + dx
			var ty := cy + dy
			if tx >= 0 and tx < map_width and ty >= 0 and ty < map_height and not _is_wall(tx, ty):
				var dist := absi(dx) + absi(dy)
				_set_floor(tx, ty, FloorType.STONE if dist <= 2 else FloorType.DIRT)
	_generate_tree_cluster(cx - 7, cy - 7, 4)
	_generate_tree_cluster(cx + 6, cy + 6, 4)
	if _decor_textures.has("torch"):
		decoration_grid[str(cx) + "," + str(cy)] = {"type": "torch"}
		decoration_grid[str(cx + 2) + "," + str(cy)] = {"type": "torch"}
	room_centers.append(Vector2(cx, cy) * tile_size)

func _generate_tree_cluster(cx: int, cy: int, count: int) -> void:
	for i in range(count):
		var tx := cx + randi_range(-3, 3)
		var ty := cy + randi_range(-3, 3)
		if tx >= 1 and tx < map_width - 1 and ty >= 1 and ty < map_height - 1:
			if not _is_wall(tx, ty):
				decoration_grid[str(tx) + "," + str(ty)] = {"type": "tree"}

func _generate_tree_clusters(count: int) -> void:
	for i in range(count):
		var cx := randi_range(6, map_width - 7)
		var cy := randi_range(6, map_height - 7)
		var cs := randi_range(4, 8)
		for j in range(cs):
			var tx := cx + randi_range(-4, 4)
			var ty := cy + randi_range(-4, 4)
			if tx >= 1 and tx < map_width - 1 and ty >= 1 and ty < map_height - 1:
				if not _is_wall(tx, ty):
					var key := str(tx) + "," + str(ty)
					if not decoration_grid.has(key):
						decoration_grid[key] = {"type": "tree" if randf() < 0.65 else "rocks"}

func _generate_scattered_decor(count: int) -> void:
	for i in range(count):
		var tx := randi_range(4, map_width - 5)
		var ty := randi_range(4, map_height - 5)
		var key := str(tx) + "," + str(ty)
		if not _is_wall(tx, ty) and not decoration_grid.has(key):
			decoration_grid[key] = {"type": "rocks"}

func _generate_dirt_paths(count: int) -> void:
	var path_types: Array[FloorType] = [FloorType.DIRT, FloorType.SANDY, FloorType.LOAM]
	for i in range(count):
		var sx := randi_range(3, map_width - 4)
		var sy := randi_range(3, map_height - 4)
		var ex := randi_range(3, map_width - 4)
		var ey := randi_range(3, map_height - 4)
		var pt: FloorType = path_types[randi() % path_types.size()]
		var x := sx; var y := sy
		while x != ex:
			if x >= 2 and x < map_width - 2 and y >= 2 and y < map_height - 2 and not _is_wall(x, y):
				_set_floor(x, y, pt)
				_set_floor(x + 1, y, pt)
			x += 1 if ex > x else -1
		while y != ey:
			if x >= 2 and x < map_width - 2 and y >= 2 and y < map_height - 2 and not _is_wall(x, y):
				_set_floor(x, y, pt)
				_set_floor(x, y + 1, pt)
			y += 1 if ey > y else -1

func _generate_grass_variation() -> void:
	"""Rastgele grass tile'larini farkli zemin tiplerine cevir - cesitlilik icin."""
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			if floor_grid[x][y] == FloorType.GRASS:
				var r := randf()
				if r < 0.12:
					floor_grid[x][y] = FloorType.LOAM  # koyu kahverengi orman topragi
				elif r < 0.20:
					floor_grid[x][y] = FloorType.DIRT  # normal kahverengi
				elif r < 0.26:
					floor_grid[x][y] = FloorType.SANDY  # kumlu acik toprak
				elif r < 0.30:
					floor_grid[x][y] = FloorType.CLAY  # kizilimsi cakil

func _build_floor_visuals() -> void:
	var half := tile_size / 2.0
	var colors := {
		FloorType.GRASS: Color(0.18, 0.28, 0.14),
		FloorType.DIRT: Color(0.22, 0.17, 0.1),
		FloorType.STONE: Color(0.2, 0.2, 0.22),
		FloorType.SAND: Color(0.28, 0.26, 0.15),
		FloorType.WATER: Color(0.12, 0.18, 0.3),
		FloorType.LOAM: Color(0.12, 0.08, 0.05),
		FloorType.SANDY: Color(0.26, 0.22, 0.14),
		FloorType.CLAY: Color(0.18, 0.12, 0.08),
	}


	for x in range(map_width):
		for y in range(map_height):
			if _is_wall(x, y):
				continue
			
			var ft: int = floor_grid[x][y]
			var key := str(x) + "," + str(y)
			floor_tiles[key] = true
			
			# Zemin (daha parlak tile)
			var tex: Texture2D = _floor_textures.get(ft, null)
			var base_color: Color = colors.get(ft, Color(0.2, 0.18, 0.15))
			if tex:
				var spr := Sprite2D.new()
				spr.texture = tex
				spr.position = Vector2(x, y) * tile_size + Vector2(half, half)
				add_child(spr)
				# Hafif renk varyasyonu (sadece texture yoksa ColorRect ekle)
			else:
				var vis := ColorRect.new()
				vis.size = Vector2(tile_size, tile_size)
				# Grass tile'lara hafif renk varyasyonu
				var c: Color = base_color
				if ft == FloorType.GRASS:
					c = Color(
						base_color.r + randf_range(-0.03, 0.03),
						base_color.g + randf_range(-0.03, 0.03),
						base_color.b + randf_range(-0.02, 0.02),
						1.0
					)
				vis.color = c
				vis.position = Vector2(x, y) * tile_size
				add_child(vis)
			
			# Animasyonlu çimen overlay kaldirildi — beyaz kare/yari-saydam overlay sorununa sebep oluyordu
			
			# Dekorasyon (statik sprite)
			if decoration_grid.has(key):
				var decor := decoration_grid[key] as Dictionary
				var dtex: Texture2D = _decor_textures.get(decor.type, null)
				if dtex:
					var spr := Sprite2D.new()
					spr.texture = dtex
					spr.position = Vector2(x, y) * tile_size + Vector2(half, half)
					spr.z_index = 2
					add_child(spr)
				elif decor.type.begins_with("flower"):
					# Cicek dekorasyonu - gercek sprite
					var flower_tex: Texture2D = load("res://assets/generated/decor_flowers_frame_0.png") if ResourceLoader.exists("res://assets/generated/decor_flowers_frame_0.png") else null
					if flower_tex:
						var fl := Sprite2D.new()
						fl.texture = flower_tex
						fl.scale = Vector2(0.5, 0.5)
						fl.position = Vector2(x, y) * tile_size + Vector2(half, half)
						fl.z_index = 2
						add_child(fl)
					else:
						# Fallback: renkli kucuk nokta
						var flower_colors: Array[Color] = [Color(1.0, 0.4, 0.7), Color(1.0, 0.9, 0.2), Color(1.0, 0.6, 0.1)]
						var cr := ColorRect.new()
						cr.size = Vector2(6, 6)
						cr.color = flower_colors[randi() % flower_colors.size()]
						cr.position = Vector2(x, y) * tile_size + Vector2(half - 3, half - 3)
						cr.z_index = 2
						add_child(cr)

func _calculate_spawn_points() -> void:
	var margin := 3
	for x in range(margin, map_width - margin):
		for y in range(margin, map_height - margin):
			if _is_wall(x, y):
				continue
			var nearby := 0
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if _is_wall(x + dx, y + dy):
						nearby += 1
			if nearby <= 3:
				spawn_points.append(Vector2i(x, y))

func _is_safe_spawn(tx: int, ty: int, radius: int = 3) -> bool:
	"""Check if a tile position is safe: no walls within `radius` tiles."""
	if _is_wall(tx, ty):
		return false
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx == 0 and dy == 0:
				continue
			if _is_wall(tx + dx, ty + dy):
				return false
	return true

func _calculate_room_centers() -> void:
	if room_centers.is_empty():
		var cx := 15; var cy := 15
		var tries := 0
		while (not _is_safe_spawn(cx, cy, 3)) and tries < 60:
			cx = randi_range(6, map_width - 6)
			cy = randi_range(6, map_height - 6)
			tries += 1
		# Fallback: if no safe tile, just find any open tile
		if tries >= 60:
			cx = 15; cy = 15
			while (_is_wall(cx, cy)) and tries < 80:
				cx = randi_range(6, map_width - 6)
				cy = randi_range(6, map_height - 6)
				tries += 1
		room_centers.append(Vector2(cx, cy) * tile_size)
	
	if room_centers.size() < 2:
		var ex := map_width - 15; var ey := map_height - 15
		var tries := 0
		while (not _is_safe_spawn(ex, ey, 3)) and tries < 60:
			ex = randi_range(6, map_width - 6)
			ey = randi_range(6, map_height - 6)
			tries += 1
		if tries >= 60:
			ex = map_width - 15; ey = map_height - 15
			while (_is_wall(ex, ey)) and tries < 80:
				ex = randi_range(6, map_width - 6)
				ey = randi_range(6, map_height - 6)
				tries += 1
		room_centers.append(Vector2(ex, ey) * tile_size)

func _is_floor_open(x: int, y: int) -> bool:
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return false
	return not _is_wall(x, y)

func get_random_spawn_point() -> Vector2i:
	if spawn_points.is_empty():
		return Vector2i(map_width / 2, map_height / 2)
	return spawn_points[randi() % spawn_points.size()] as Vector2i

func get_spawn_points(count: int) -> Array:
	var result: Array = []
	var shuffled := spawn_points.duplicate()
	shuffled.shuffle()
	for i in range(mini(count, shuffled.size())):
		result.append(shuffled[i] as Vector2i)
	return result

func get_first_room_center() -> Vector2:
	if room_centers.is_empty():
		return Vector2(map_width * tile_size / 2, map_height * tile_size / 2)
	return room_centers[0] as Vector2

func get_last_room_center() -> Vector2:
	if room_centers.size() < 2:
		return get_first_room_center()
	return room_centers[room_centers.size() - 1] as Vector2
