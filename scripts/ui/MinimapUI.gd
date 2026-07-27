extends CanvasLayer
class_name MinimapUI
## Mini harita sistemi. Sağ üst köşede küçük harita gösterilir.
## M tuşuna basınca ekranı kaplayan detaylı versiyon açılır.

const MINIMAP_SIZE := 160          ## Küçük harita piksel boyutu
const FULLSCREEN_SIZE := 600       ## Tam ekran harita piksel boyutu
const TILE_SIZE := 32
const GRID_W := 160
const GRID_H := 160

var _is_fullscreen := false
var _map_tex: ImageTexture = null
var _dirty := true
var _refresh_timer: float = 0.0
var _mapgen: Node = null
var _dungeongen: Node = null
var _viewport_size := Vector2(1280, 720)

# UI bileşenleri
var _mini_rect: TextureRect = null
var _fullscreen_panel: Panel = null
var _fullscreen_rect: TextureRect = null
var _player_marker: ColorRect = null

func _ready() -> void:
	layer = 50  # UI'nin üstünde
	process_mode = PROCESS_MODE_ALWAYS
	# Viewport boyutunu güncelle (ready'de doğru olmayabilir)
	var vp := get_viewport()
	if vp:
		_viewport_size = vp.get_visible_rect().size
	
	# Ana harita erişimi
	_mapgen = get_tree().current_scene.get_node_or_null("MapGenerator")
	_dungeongen = get_tree().current_scene.get_node_or_null("DungeonGenerator")
	
	# Küçük harita (sağ üst köşe)
	_mini_rect = TextureRect.new()
	_mini_rect.size = Vector2(MINIMAP_SIZE, MINIMAP_SIZE * GRID_H / GRID_W)
	_mini_rect.position = Vector2(
		_viewport_size.x - MINIMAP_SIZE - 8,
		8
	)
	_mini_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mini_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_mini_rect)
	
	# Minimal border
	# Minimap border with style
	var border_panel := Panel.new()
	border_panel.position = _mini_rect.position - Vector2(3, 3)
	border_panel.size = _mini_rect.size + Vector2(6, 6)
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0.05, 0.05, 0.08, 0.95)
	border_style.border_width_left = 2; border_style.border_width_right = 2
	border_style.border_width_top = 2; border_style.border_width_bottom = 2
	border_style.border_color = Color(0.4, 0.35, 0.5, 0.8)
	border_style.set_corner_radius_all(4)
	border_style.shadow_color = Color(0, 0, 0, 0.5)
	border_style.shadow_size = 4
	border_style.shadow_offset = Vector2(0, 2)
	border_panel.add_theme_stylebox_override("panel", border_style)
	add_child(border_panel)
	move_child(border_panel, 0)  # Arkaya
	# Player marker
	_player_marker = ColorRect.new()
	_player_marker.size = Vector2(4, 4)
	_player_marker.color = Color(0.3, 1.0, 0.3)
	_player_marker.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_player_marker)
	
	# Fullscreen için arka plan (gizli)
	_fullscreen_panel = Panel.new()
	_fullscreen_panel.size = _viewport_size
	_fullscreen_panel.add_theme_stylebox_override("panel", _make_fullscreen_style())
	_fullscreen_panel.visible = false
	add_child(_fullscreen_panel)
	
	# Fullscreen başlık
	var fs_title := Label.new()
	fs_title.text = "HARİTA [ESC kapat]"
	fs_title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3))
	fs_title.add_theme_font_size_override("font_size", 18)
	fs_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fs_title.position = Vector2(0, 10)
	fs_title.size = Vector2(_viewport_size.x, 30)
	_fullscreen_panel.add_child(fs_title)
	
	# Fullscreen harita
	_fullscreen_rect = TextureRect.new()
	var fs_size := mini(FULLSCREEN_SIZE, int(_viewport_size.y * 0.85))
	_fullscreen_rect.size = Vector2(fs_size * GRID_W / GRID_H, fs_size)
	_fullscreen_rect.position = Vector2(
		(_viewport_size.x - _fullscreen_rect.size.x) / 2,
		(_viewport_size.y - _fullscreen_rect.size.y) / 2 + 15
	)
	_fullscreen_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_fullscreen_panel.add_child(_fullscreen_rect)

func _make_fullscreen_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.02, 0.02, 0.05, 0.92)
	return s

func _process(_delta: float) -> void:
	_refresh_timer += _delta
	if _refresh_timer > 0.5:
		_refresh_timer = 0.0
		_dirty = true
	
	if _dirty:
		_render_minimap()
		_dirty = false
	
	# Player pozisyonunu güncelle
	_update_player_marker()

func _update_player_marker() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		_player_marker.visible = false
		return
	
	# Harita grid boyutlarını al
	var grid_w := GRID_W
	var grid_h := GRID_H
	if _dungeongen and is_instance_valid(_dungeongen):
		var dg = _dungeongen
		if dg.grid is Array and dg.grid.size() > 0:
			grid_w = dg.grid.size()
			grid_h = dg.grid[0].size() if dg.grid[0] is Array and dg.grid[0].size() > 0 else GRID_H
	
	if _is_fullscreen:
		var rect: TextureRect = _fullscreen_rect
		var ratio_x: float = rect.size.x / (grid_w * TILE_SIZE)
		var ratio_y: float = rect.size.y / (grid_h * TILE_SIZE)
		var px: float = rect.position.x + player.global_position.x * ratio_x - 2.0
		var py: float = rect.position.y + player.global_position.y * ratio_y - 2.0
		_player_marker.position = Vector2(clampf(px, rect.position.x, rect.position.x + rect.size.x - 4.0),
										  clampf(py, rect.position.y, rect.position.y + rect.size.y - 4.0))
		_player_marker.visible = true
		return
	
	var rect: TextureRect = _mini_rect
	var ratio_x: float = rect.size.x / (grid_w * TILE_SIZE)
	var ratio_y: float = rect.size.y / (grid_h * TILE_SIZE)
	var px: float = rect.position.x + player.global_position.x * ratio_x - 2.0
	var py: float = rect.position.y + player.global_position.y * ratio_y - 2.0
	_player_marker.position = Vector2(clampf(px, rect.position.x, rect.position.x + rect.size.x - 4.0),
									  clampf(py, rect.position.y, rect.position.y + rect.size.y - 4.0))
	_player_marker.visible = true

func _render_minimap() -> void:
	# Dungeon boyutunu al (dinamik)
	var map_w := GRID_W
	var map_h := GRID_H
	if _dungeongen and is_instance_valid(_dungeongen):
		var dg = _dungeongen
		if dg.grid is Array and dg.grid.size() > 0:
			map_w = dg.grid.size()
			map_h = dg.grid[0].size() if dg.grid[0] is Array and dg.grid[0].size() > 0 else GRID_H
	var img := Image.create(map_w, map_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.1, 0.08, 0.05))
	
	# DungeonGenerator grid verisi
	if _dungeongen and is_instance_valid(_dungeongen):
		var dg = _dungeongen
		if dg.grid is Array and dg.grid.size() > 0:
			for x in range(map_w):
				for y in range(map_h):
					var cell = dg.grid[x][y]
					# CellType enum: WALL=0, FLOOR=1, ENTRANCE=2, BOSS_AREA=3, EXIT=4
					match cell:
						dg.CellType.WALL: img.set_pixel(x, y, Color(0.15, 0.1, 0.08))
						dg.CellType.FLOOR: img.set_pixel(x, y, Color(0.2, 0.18, 0.14))
						dg.CellType.ENTRANCE: img.set_pixel(x, y, Color(0.15, 0.25, 0.45))
						dg.CellType.BOSS_AREA: img.set_pixel(x, y, Color(0.45, 0.12, 0.12))
						dg.CellType.EXIT: img.set_pixel(x, y, Color(0.15, 0.45, 0.15))
	# MapGenerator grid verisi (fallback)
	elif _mapgen:
		# Zemin tipleri (floor_grid[x][y])
		if _mapgen.floor_grid is Array and _mapgen.floor_grid.size() > 0:
			for x in range(mini(GRID_W, _mapgen.floor_grid.size())):
				var col = _mapgen.floor_grid[x]
				if col is Array:
					for y in range(mini(GRID_H, col.size())):
						var ft = col[y]
						match ft:
							0: img.set_pixel(x, y, Color(0.12, 0.18, 0.08))  # GRASS
							1: img.set_pixel(x, y, Color(0.2, 0.15, 0.08))   # DIRT
							2: img.set_pixel(x, y, Color(0.25, 0.22, 0.18))  # STONE
							3: img.set_pixel(x, y, Color(0.2, 0.17, 0.1))   # SAND
		# Duvarlar (wall_grid)
		if _mapgen.wall_grid is Dictionary:
			for key in _mapgen.wall_grid.keys():
				# key formatı: "x,y" veya başka
				var parts := String(key).split(",")
				if parts.size() == 2:
					var wx := int(parts[0])
					var wy := int(parts[1])
					if wx >= 0 and wx < GRID_W and wy >= 0 and wy < GRID_H:
						img.set_pixel(wx, wy, Color(0.4, 0.3, 0.15))
	
	# Border walls (dinamik boyut)
	for x in range(map_w):
		img.set_pixel(x, 0, Color(0.4, 0.3, 0.2))
		img.set_pixel(x, map_h - 1, Color(0.4, 0.3, 0.2))
	for y in range(map_h):
		img.set_pixel(0, y, Color(0.4, 0.3, 0.2))
		img.set_pixel(map_w - 1, y, Color(0.4, 0.3, 0.2))
	
	# Entity tracking
	var world := get_tree().current_scene
	if world:
		# Enemies (red) — Node2D'lerin global_position'ı vardır
		for ch in world.get_children():
			if ch.is_in_group("enemy") and "global_position" in ch:
				var pos: Vector2 = ch.global_position
				var gx := int(pos.x / TILE_SIZE)
				var gy := int(pos.y / TILE_SIZE)
				if gx >= 0 and gx < map_w and gy >= 0 and gy < map_h:
					img.set_pixel(gx, gy, Color(0.9, 0.15, 0.1))
					if gx + 1 < map_w: img.set_pixel(gx+1, gy, Color(0.9, 0.15, 0.1))
					if gx > 0: img.set_pixel(gx-1, gy, Color(0.9, 0.15, 0.1))
					if gy + 1 < map_h: img.set_pixel(gx, gy+1, Color(0.9, 0.15, 0.1))
					if gy > 0: img.set_pixel(gx, gy-1, Color(0.9, 0.15, 0.1))
		
		# Chests (yellow)
		for ch in world.get_children():
			if ch.name.begins_with("Chest") and "global_position" in ch:
				var pos: Vector2 = ch.global_position
				var gx := int(pos.x / TILE_SIZE)
				var gy := int(pos.y / TILE_SIZE)
				if gx >= 0 and gx < map_w and gy >= 0 and gy < map_h:
					img.set_pixel(gx, gy, Color(1.0, 0.8, 0.2))
		
		# Waypoint (cyan)
		var wp := world.get_node_or_null("Waypoint")
		if wp and "global_position" in wp:
			var pos: Vector2 = wp.global_position
			var gx := int(pos.x / TILE_SIZE)
			var gy := int(pos.y / TILE_SIZE)
			if gx >= 0 and gx < map_w and gy >= 0 and gy < map_h:
				img.set_pixel(gx, gy, Color(0.3, 0.9, 0.7))
				if gx + 1 < map_w: img.set_pixel(gx+1, gy, Color(0.3, 0.9, 0.7))
				if gy + 1 < map_h: img.set_pixel(gx, gy+1, Color(0.3, 0.9, 0.7))
		
		# Stairs (white)
		var stairs := world.get_node_or_null("Stairs")
		if stairs and "global_position" in stairs:
			var pos: Vector2 = stairs.global_position
			var gx := int(pos.x / TILE_SIZE)
			var gy := int(pos.y / TILE_SIZE)
			if gx >= 0 and gx < map_w and gy >= 0 and gy < map_h:
				img.set_pixel(gx, gy, Color(1, 1, 1))
				if gx + 1 < map_w: img.set_pixel(gx+1, gy, Color(1, 1, 1))
				if gx > 0: img.set_pixel(gx-1, gy, Color(1, 1, 1))
				if gy + 1 < map_h: img.set_pixel(gx, gy+1, Color(1, 1, 1))
				if gy > 0: img.set_pixel(gx, gy-1, Color(1, 1, 1))
		
		# NPCs (purple) — demirci, vb.
		for ch in world.get_children():
			if ch.is_in_group("npc") and "global_position" in ch:
				var pos: Vector2 = ch.global_position
				var gx := int(pos.x / TILE_SIZE)
				var gy := int(pos.y / TILE_SIZE)
				if gx >= 0 and gx < map_w and gy >= 0 and gy < map_h:
					img.set_pixel(gx, gy, Color(0.7, 0.3, 0.9))
					if gx + 1 < map_w: img.set_pixel(gx+1, gy, Color(0.7, 0.3, 0.9))
					if gx > 0: img.set_pixel(gx-1, gy, Color(0.7, 0.3, 0.9))
	
	_map_tex = ImageTexture.create_from_image(img)
	
	_mini_rect.texture = _map_tex
	if _is_fullscreen and _fullscreen_rect:
		_fullscreen_rect.texture = _map_tex

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_toggle_fullscreen()

func _toggle_fullscreen() -> void:
	_is_fullscreen = not _is_fullscreen
	if _fullscreen_panel:
		_fullscreen_panel.visible = _is_fullscreen
		if _is_fullscreen:
			if _map_tex:
				_fullscreen_rect.texture = _map_tex
		_dirty = true
