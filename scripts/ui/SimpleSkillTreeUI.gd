extends Control
class_name SimpleSkillTreeUIl
## Basit, kategorize edilmiş pasif yetenek ağacı UI'ı.
## Yggdrasil'in karmaşık tree view'ı yerine düz scroll list.

const SAVE_PATH: String = "user://simple_skill_tree.save"

## Allocate/deallocate sinyalleri
signal node_allocated(node_id: int, ref_json: String)
signal node_deallocated(node_id: int, ref_json: String)

var player = null  # type: Node (assigned at runtime)
var _embedded_mode: bool = false
var _effect_applier: PassiveEffectApplier = null

# Node data
var _all_nodes: Array[Dictionary] = []       # JSON'daki tüm node'lar
var _allocated_ids: Array[int] = []           # Açılmış node ID'leri
var _category_groups: Dictionary = {}         # category_key -> [node_dict]

# UI
# _main_container kaldirildi — VBoxContainer kullaniliyor
var _scroll_container: ScrollContainer = null
var _category_container: VBoxContainer = null
var _points_label: Label = null
var _search_box: LineEdit = null
var _clear_btn: Button = null
var _close_btn: Button = null
var _node_card_cache: Dictionary = {}  # node_id -> card button ref
var _expanded_category: String = ""     # Su an hangi kategori acik (accordion)
var _category_widgets: Dictionary = {}  # category -> {"header": ColorRect, "list": VBoxContainer}

# Görsel sabitler
const CARD_SIZE: Vector2 = Vector2(240, 60)
const CATEGORY_COLORS: Dictionary = {
	"fire_damage": Color(1.0, 0.4, 0.2),
	"cold_damage": Color(0.3, 0.6, 1.0),
	"lightning_damage": Color(1.0, 0.9, 0.2),
	"chaos_damage": Color(0.8, 0.3, 0.8),
	"physical_damage": Color(0.8, 0.6, 0.4),
	"elemental_damage": Color(1.0, 0.6, 0.1),
	"attack_damage": Color(0.9, 0.5, 0.3),
	"life": Color(0.3, 0.9, 0.3),
	"life_regen": Color(0.2, 0.8, 0.4),
	"mana": Color(0.3, 0.5, 1.0),
	"mana_regen": Color(0.2, 0.4, 0.9),
	"energy_shield": Color(0.6, 0.6, 1.0),
	"armour": Color(0.7, 0.7, 0.5),
	"evasion": Color(0.4, 0.9, 0.4),
	"attack_speed": Color(1.0, 0.6, 0.3),
	"cast_speed": Color(0.5, 0.4, 1.0),
	"critical": Color(1.0, 0.8, 0.0),
	"critical_chance": Color(1.0, 0.7, 0.1),
	"critical_multiplier": Color(1.0, 0.9, 0.2),
	"block": Color(0.6, 0.5, 0.8),
	"resistance": Color(0.4, 0.5, 0.9),
	"accuracy": Color(0.7, 0.5, 0.3),
	"movement_speed": Color(0.3, 0.8, 0.7),
	"area_of_effect": Color(0.8, 0.3, 0.5),
	"projectile": Color(0.3, 0.7, 0.8),
	"cooldown": Color(0.7, 0.3, 0.6),
	"leech": Color(0.8, 0.2, 0.3),
	"generic": Color(0.5, 0.5, 0.5),
	"others": Color(0.5, 0.5, 0.5),
}

# Kategori öncelik sırası
const CATEGORY_ORDER: Array[String] = [
	"fire_damage", "cold_damage", "lightning_damage", "chaos_damage", "physical_damage",
	"elemental_damage", "attack_damage",
	"attack_speed", "cast_speed",
	"critical_chance", "critical_multiplier",
	"block", "resistance",
	"armour", "evasion", "energy_shield",
	"life", "life_regen",
	"mana", "mana_regen",
	"accuracy", "movement_speed",
	"projectile", "area_of_effect",
	"cooldown", "leech",
	"generic",
	"others",
]


func _ready() -> void:
	_effect_applier = PassiveEffectApplier.new()
	add_child(_effect_applier)

	_load_data()
	_load_state()


func _load_data() -> void:
	"""JSON dosyasından tüm node'ları yükle ve kategorize et."""
	var path: String = "res://data/passive_skill_tree.json"
	if not ResourceLoader.exists(path):
		push_error("SimpleSkillTreeUI: JSON not found: ", path)
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SimpleSkillTreeUI: Cannot open file: ", path)
		return

	var text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("SimpleSkillTreeUI: JSON parse error: ", json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	var raw_nodes: Array = data.get("nodes", [])
	if raw_nodes.is_empty():
		push_error("SimpleSkillTreeUI: No nodes in JSON")
		return

	# Node'lari Dictionary olarak sakla (sadece ihtiyacimiz olan alanlar)
	_all_nodes.clear()
	_category_groups.clear()

	for raw in raw_nodes:
		var node: Dictionary = {
			"id": int(raw.get("id", 0)),
			"name": str(raw.get("name", "")),
			"type": str(raw.get("type", "Small")),
			"effects_raw": str(raw.get("effects_raw", "")),
			"modifiers": raw.get("modifiers", []),
			"connects": raw.get("connects", []),
		}
		_all_nodes.append(node)

	# Kategorize et
	for node in _all_nodes:
		var cat: String = _get_node_category(node)
		if not _category_groups.has(cat):
			_category_groups[cat] = []
		_category_groups[cat].append(node)

	# Her kategoriyi id'ye gore sirala
	for cat in _category_groups:
		_category_groups[cat].sort_custom(func(a, b): return a["id"] < b["id"])

	print("SimpleSkillTreeUI: Loaded ", _all_nodes.size(), " nodes in ", _category_groups.size(), " categories")


func _get_node_category(node: Dictionary) -> String:
	"""Node'un modifier'larina gore kategori belirle."""
	var mods: Array = node.get("modifiers", [])
	var keys: Array[String] = []

	for m in mods:
		if not (m is Dictionary):
			continue
		var key: String = str(m.get("key", ""))
		if not key.is_empty():
			keys.append(key)

		# Raw text'ten de tahmin et
		var raw: String = str(m.get("raw", "")).to_lower()
		if "fire" in raw and "damage" in raw and "fire_damage" not in keys:
			keys.append("fire_damage")
		elif "cold" in raw and "damage" in raw and "cold_damage" not in keys:
			keys.append("cold_damage")
		elif "lightning" in raw and "damage" in raw and "lightning_damage" not in keys:
			keys.append("lightning_damage")
		elif "chaos" in raw and "damage" in raw and "chaos_damage" not in keys:
			keys.append("chaos_damage")
		elif "physical" in raw and "damage" in raw and "physical_damage" not in keys:
			keys.append("physical_damage")
		elif "elemental" in raw and "damage" in raw and "elemental_damage" not in keys:
			keys.append("elemental_damage")
		elif "spell" in raw and "damage" in raw and "elemental_damage" not in keys:
			keys.append("elemental_damage")
		elif "attack" in raw and "damage" in raw and "attack_damage" not in keys:
			keys.append("attack_damage")

	# Kategori onceligine gore ilk esleseni don
	for cat in CATEGORY_ORDER:
		for k in keys:
			if k.begins_with(cat) or cat.begins_with(k):
				return cat

	if not keys.is_empty():
		return keys[0]

	# "life" iceren modifierlara bak
	for m in mods:
		if not (m is Dictionary):
			continue
		var raw: String = str(m.get("raw", "")).to_lower()
		if "life" in raw: return "life"
		if "mana" in raw: return "mana"
		if "energy shield" in raw: return "energy_shield"
		if "armour" in raw: return "armour"
		if "evasion" in raw: return "evasion"
		if "accuracy" in raw: return "accuracy"
		if "block" in raw: return "block"
		if "critical" in raw: return "critical"
		if "resistance" in raw: return "resistance"

	return "others"


func open_fullscreen() -> void:
	"""Tam ekran ac, oyunu pause yap."""
	_embedded_mode = false
	if not player:
		player = get_tree().get_first_node_in_group("player")

	# UI'yi temizle ve yeniden build et
	for c in get_children():
		if c == _effect_applier:
			continue
		c.queue_free()

	_build_ui()
	visible = true
	set_process_input(true)
	set_process(true)
	process_mode = PROCESS_MODE_ALWAYS
	_toggle_hud(false)
	get_tree().paused = true


func close() -> void:
	"""Kapat, oyunu devam ettir."""
	visible = false
	set_process_input(false)
	set_process(false)
	_toggle_hud(true)
	get_tree().paused = false


func _toggle_hud(visible_hud: bool) -> void:
	var main := get_tree().current_scene
	if not main:
		return
	var hud := main.get_node_or_null("CanvasLayer2")
	if hud:
		hud.visible = visible_hud
	var skillbar := main.get_node_or_null("CanvasLayer3")
	if skillbar:
		skillbar.visible = visible_hud


func _build_ui() -> void:
	"""Ana UI'yi VBoxContainer ile olustur - temiz layout."""
	mouse_filter = MOUSE_FILTER_STOP

	# Arka plan overlay (tam opak koyu)
	var overlay := ColorRect.new()
	overlay.name = "BgOverlay"
	overlay.color = Color(0.04, 0.04, 0.06, 1.0)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	add_child(overlay)

	# Root VBoxContainer tum control'u doldurur
	var vbox := VBoxContainer.new()
	vbox.name = "RootVBox"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 0)
	vbox.mouse_filter = MOUSE_FILTER_STOP
	add_child(vbox)

	# Header satiri
	var header := _build_header()
	vbox.add_child(header)

	# ScrollContainer (kalan tum alani kaplasin)
	_scroll_container = ScrollContainer.new()
	_scroll_container.name = "ScrollContainer"
	_scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll_container)

	# Ic VBox (kategoriler)
	_category_container = VBoxContainer.new()
	_category_container.name = "CategoryContainer"
	_category_container.size_flags_horizontal = SIZE_EXPAND_FILL
	_scroll_container.add_child(_category_container)

	# Kategorileri doldur
	_build_categories()
	_update_points_label()

	# Yeniden boyutlanma
	resized.connect(func():
		if _points_label:
			_points_label.position = Vector2(size.x - 170, 10)
	)


func _build_header() -> Control:
	"""Header: close, title, search, points. Control doner."""
	var hdr := Control.new()
	hdr.name = "Header"
	hdr.custom_minimum_size = Vector2(0, 70)
	hdr.size_flags_horizontal = SIZE_EXPAND_FILL

	# Close button
	_close_btn = Button.new()
	_close_btn.name = "CloseBtn"
	_close_btn.text = "✕"
	_close_btn.size = Vector2(32, 32)
	_close_btn.position = Vector2(8, 8)
	_close_btn.flat = true
	_close_btn.pressed.connect(close)
	hdr.add_child(_close_btn)

	# Title
	var title := Label.new()
	title.name = "Title"
	title.text = "PASİF YETENEKLER"
	title.position = Vector2(48, 10)
	title.size = Vector2(300, 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	title.add_theme_font_size_override("font_size", 18)
	hdr.add_child(title)

	# Search box
	_search_box = LineEdit.new()
	_search_box.name = "SearchBox"
	_search_box.placeholder_text = "Ara..."
	_search_box.size = Vector2(260, 28)
	_search_box.position = Vector2(8, 40)
	_search_box.caret_blink = true
	_search_box.text_changed.connect(_on_search_changed)
	hdr.add_child(_search_box)

	_clear_btn = Button.new()
	_clear_btn.name = "ClearSearch"
	_clear_btn.text = "X"
	_clear_btn.size = Vector2(22, 22)
	_clear_btn.position = Vector2(246, 42)
	_clear_btn.flat = true
	_clear_btn.pressed.connect(_clear_search)
	_clear_btn.visible = false
	hdr.add_child(_clear_btn)

	# Points label
	_points_label = Label.new()
	_points_label.name = "PointsLabel"
	_points_label.size = Vector2(160, 28)
	_points_label.position = Vector2(size.x - 170, 10)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_points_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	_points_label.add_theme_font_size_override("font_size", 16)
	hdr.add_child(_points_label)

	return hdr


# Resize handled via lambda in _build_ui


func _build_categories(filter_text: String = "") -> void:
	"""Kategorileri ve node kartlarini olustur.
	Varsayilan: sadece Notable + Keystone goster. Ara yapilirsa Small'lar da dahil."""
	# Mevcut kategorileri temizle
	for c in _category_container.get_children():
		c.queue_free()
	_node_card_cache.clear()
	_category_widgets.clear()
	_expanded_category = ""

	var search_lower := filter_text.to_lower().strip_edges()
	var is_searching: bool = not search_lower.is_empty()

	# Kategorileri CATEGORY_ORDER'a gore sirala, bilinmeyenler sona
	var sorted_cats: Array[String] = []
	for cat in CATEGORY_ORDER:
		if _category_groups.has(cat):
			sorted_cats.append(cat)
	for cat in _category_groups:
		if cat not in sorted_cats:
			sorted_cats.append(cat)

	for cat in sorted_cats:
		var nodes_in_cat: Array = _category_groups[cat]
		# Filtrele: arama yoksa sadece Notable+Keystone+Attribute, arama varsa hepsi
		var filtered: Array = []
		for nd in nodes_in_cat:
			var ntype: String = nd.get("type", "Small")
			if not is_searching and ntype == "Small":
				continue
			if is_searching:
				# AND arama: boslukla ayrilan tum kelimeler eslesmeli
				var all_terms_match := true
				for term in search_lower.split(" ", false):
					var name_match: bool = nd["name"].to_lower().find(term) >= 0
					var effect_match: bool = nd["effects_raw"].to_lower().find(term) >= 0
					if not name_match and not effect_match:
						all_terms_match = false
						break
				if not all_terms_match:
					continue
			filtered.append(nd)

		if filtered.is_empty():
			continue

		_build_category_section(cat, filtered)


func _build_category_section(category: String, nodes: Array) -> void:
	"""Tek bir kategori bolumu: tiklanabilir header + collapsible liste."""
	var cat_color: Color = CATEGORY_COLORS.get(category, Color(0.5, 0.5, 0.5))

	# Category header — tıklanabilir
	var hdr := ColorRect.new()
	hdr.name = "CatHdr_" + category
	hdr.color = Color(cat_color.r * 0.15, cat_color.g * 0.15, cat_color.b * 0.15, 0.6)
	hdr.custom_minimum_size = Vector2(0, 26)
	hdr.size_flags_horizontal = SIZE_EXPAND_FILL
	hdr.mouse_filter = MOUSE_FILTER_STOP
	_category_container.add_child(hdr)

	# Açık/kapalı oku
	var arrow_lbl := Label.new()
	arrow_lbl.name = "CatArrow_" + category
	arrow_lbl.text = "▸ "  # kapalı
	arrow_lbl.position = Vector2(4, 3)
	arrow_lbl.size = Vector2(20, 20)
	arrow_lbl.add_theme_color_override("font_color", cat_color)
	arrow_lbl.add_theme_font_size_override("font_size", 12)
	arrow_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	hdr.add_child(arrow_lbl)

	var hdr_lbl := Label.new()
	hdr_lbl.name = "CatLbl_" + category
	hdr_lbl.text = _format_category_name(category) + "  [" + str(nodes.size()) + "]"
	hdr_lbl.position = Vector2(24, 3)
	hdr_lbl.size = Vector2(800, 20)
	hdr_lbl.add_theme_color_override("font_color", cat_color)
	hdr_lbl.add_theme_font_size_override("font_size", 13)
	hdr_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	hdr.add_child(hdr_lbl)

	# Liste container (baslangicta gizli)
	var list_container := VBoxContainer.new()
	list_container.name = "List_" + category
	list_container.size_flags_horizontal = SIZE_EXPAND_FILL
	list_container.visible = false  # kapali basla
	_category_container.add_child(list_container)

	# Node satirlari
	_build_node_grid(list_container, nodes, category)

	# Widget referanslarini sakla
	_category_widgets[category] = {"header": hdr, "list": list_container, "arrow": arrow_lbl}

	# Header'a tikla → toggle
	hdr.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_toggle_category(category)
	)


func _build_node_grid(parent: Container, nodes: Array, _category: String) -> void:
	"""Node'lari liste satirlari olarak yerlestir. Her satir: [TypeBar] [Isim] [Efekt]."""
	for node in nodes:
		var row := _create_node_row(node)
		parent.add_child(row)
		_node_card_cache[node["id"]] = row

	# Alt bosluk
	var bottom_space := Control.new()
	bottom_space.custom_minimum_size = Vector2(0, 4)
	parent.add_child(bottom_space)


func _create_node_row(node: Dictionary) -> Control:
	"""Bir node icin HBoxContainer satiri: [4px bar] [Name] [Effects]"""
	var hbox := HBoxContainer.new()
	hbox.name = "NodeRow_" + str(node["id"])
	hbox.custom_minimum_size = Vector2(0, 28)
	hbox.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.mouse_filter = MOUSE_FILTER_STOP

	var node_id: int = node["id"]
	var is_alloc: bool = _allocated_ids.has(node_id)

	# Arka plan
	var bg_color := Color(0.1, 0.1, 0.14)
	if is_alloc:
		bg_color = Color(0.12, 0.2, 0.12)

	# Type indicator bar
	var type_color: Color = Color(0.4, 0.4, 0.4)
	var ntype: String = node.get("type", "Small")
	match ntype:
		"Notable": type_color = Color(0.8, 0.7, 0.3)
		"Keystone": type_color = Color(0.9, 0.5, 0.2)
		"Attribute": type_color = Color(0.4, 0.6, 0.9)

	var type_bar := ColorRect.new()
	type_bar.name = "TypeBar"
	type_bar.color = type_color
	type_bar.custom_minimum_size = Vector2(4, 0)
	type_bar.size_flags_vertical = SIZE_EXPAND_FILL
	hbox.add_child(type_bar)

	# Name label
	var name_lbl := Label.new()
	name_lbl.name = "Name"
	name_lbl.text = node["name"]
	name_lbl.custom_minimum_size = Vector2(220, 0)
	name_lbl.size_flags_vertical = SIZE_EXPAND_FILL
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_child(name_lbl)

	# Effects label
	var eff_text: String = node.get("effects_raw", "")
	if eff_text.is_empty():
		eff_text = ""
	var eff_lbl := Label.new()
	eff_lbl.name = "Eff"
	eff_lbl.text = eff_text
	eff_lbl.custom_minimum_size = Vector2(400, 0)
	eff_lbl.size_flags_vertical = SIZE_EXPAND_FILL
	eff_lbl.size_flags_horizontal = SIZE_EXPAND_FILL
	eff_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	eff_lbl.add_theme_font_size_override("font_size", 10)
	eff_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	hbox.add_child(eff_lbl)

	# Arka plan icin tum alani kaplayan ColorRect (en altta)
	_bg_for_row(hbox, bg_color, is_alloc)

	# Tıklama
	hbox.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_card_clicked(node)
	)
	hbox.mouse_entered.connect(func():
		hbox.modulate = Color(1.1, 1.1, 1.1)
	)
	hbox.mouse_exited.connect(func():
		hbox.modulate = Color.WHITE
	)

	return hbox


func _bg_for_row(parent: Control, bg_color: Color, allocated: bool) -> void:
	"""Satir arka planini parent'in altina ekle."""
	var bg := ColorRect.new()
	bg.name = "RowBg"
	bg.color = bg_color
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	parent.move_child(bg, 0)

	if allocated:
		var alloc := ColorRect.new()
		alloc.name = "RowAlloc"
		alloc.color = Color(0.2, 0.8, 0.2, 0.2)
		alloc.anchor_right = 1.0
		alloc.anchor_bottom = 1.0
		alloc.mouse_filter = MOUSE_FILTER_IGNORE
		parent.add_child(alloc)
		parent.move_child(alloc, 0)


func _modulate_card(card: Control, _node_id: int, hovered: bool) -> void:
	"""Kart hover efektini guncelle."""
	if not is_instance_valid(card):
		return
	if hovered:
		card.modulate = Color(1.2, 1.2, 1.2)
	else:
		card.modulate = Color.WHITE


func _on_card_clicked(node: Dictionary) -> void:
	"""Node kartina tiklandi: allocate/deallocate."""
	var node_id: int = node["id"]
	var is_allocated: bool = _allocated_ids.has(node_id)

	if is_allocated:
		# Deallocate
		_deallocate_node(node)
	else:
		# Allocate - puan kontrolu
		if not player:
			return
		if player.skill_points <= 0:
			# Puan yok uyarisi
			_flash_message("Yetersiz Puan!", Color(1, 0.3, 0.3))
			return
		_allocate_node(node)


func _allocate_node(node: Dictionary) -> void:
	"""Node'u ac: puan harca, efekt uygula, UI'i guncelle."""
	var node_id: int = node["id"]
	if _allocated_ids.has(node_id):
		return
	if not player:
		return
	if player.skill_points <= 0:
		return
	if not player.stats:
		push_error("SimpleSkillTreeUI: player.stats is null!")
		return

	player.skill_points -= 1
	_allocated_ids.append(node_id)

	# Efekt uygula
	var ref_json: String = _build_reference_json(node)
	if not ref_json.is_empty():
		_effect_applier.apply_modifiers(ref_json, player.stats, false)

	node_allocated.emit(node_id, ref_json)

	# UI guncelle
	_save_state()
	_update_points_label()
	_refresh_card(node_id)

	print("SimpleSkillTreeUI: Allocated node ", node_id, " (", node["name"], ")")


func _deallocate_node(node: Dictionary) -> void:
	"""Node'u kapat: puan iade et, efekt kaldir, UI'i guncelle."""
	var node_id: int = node["id"]
	if not _allocated_ids.has(node_id):
		return
	if not player:
		return

	_allocated_ids.erase(node_id)
	player.skill_points += 1

	# Efekt kaldir
	var ref_json: String = _build_reference_json(node)
	if not ref_json.is_empty():
		_effect_applier.apply_modifiers(ref_json, player.stats, true)

	node_deallocated.emit(node_id, ref_json)

	# UI guncelle
	_save_state()
	_update_points_label()
	_refresh_card(node_id)

	print("SimpleSkillTreeUI: Deallocated node ", node_id, " (", node["name"], ")")


func _refresh_card(node_id: int) -> void:
	"""Bir node kartini yeniden olustur (state degisikligi sonrasi)."""
	if not _node_card_cache.has(node_id):
		return
	var old_card: Control = _node_card_cache[node_id]
	if not is_instance_valid(old_card):
		return

	# Node datayi bul
	var node: Dictionary = _find_node_by_id(node_id)
	if node.is_empty():
		return

	var parent: Container = old_card.get_parent()
	if not parent:
		return

	var idx := old_card.get_index()
	old_card.queue_free()

	var new_row := _create_node_row(node)
	_node_card_cache[node_id] = new_row
	parent.add_child(new_row)
	parent.move_child(new_row, idx)


func _find_node_by_id(node_id: int) -> Dictionary:
	for node in _all_nodes:
		if node["id"] == node_id:
			return node
	return {}


func _build_reference_json(node: Dictionary) -> String:
	"""Node'daki modifier'lardan PassiveEffectApplier'in bekledigi JSON stringini olustur."""
	var mods: Array = node.get("modifiers", [])
	if mods.is_empty():
		return ""

	# Modifier'lari reference_id formatina donustur
	var result: Array = []
	for m in mods:
		if not (m is Dictionary):
			continue
		var entry: Dictionary = {}
		var mtype: String = str(m.get("type", "unknown"))
		var raw: String = str(m.get("raw", ""))
		entry["raw"] = raw
		entry["type"] = mtype

		var key: String = str(m.get("key", ""))
		if not key.is_empty():
			entry["key"] = key
		if "value" in m:
			entry["value"] = m["value"]
		result.append(entry)

	if result.is_empty():
		return ""

	return JSON.stringify(result)


func _update_points_label() -> void:
	"""Puan gostergesini guncelle."""
	if not _points_label:
		return
	if player:
		_points_label.text = "Puan: %d" % player.skill_points
	else:
		_points_label.text = "Puan: -"


func _flash_message(text: String, color: Color) -> void:
	"""Gecici uyari mesaji goster. size yerine direkt rect_size kullan."""
	var msg := Label.new()
	msg.text = text
	msg.add_theme_color_override("font_color", color)
	msg.add_theme_font_size_override("font_size", 14)
	msg.size = Vector2(200, 40)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(msg)
	# Her frame pozisyonu guncelle (deferred, boyut belli olunca)
	msg.set_anchors_preset(PRESET_CENTER)
	msg.set_meta("flash_color", color)

	var tween := create_tween()
	tween.tween_property(msg, "modulate:a", 1.0, 0.5)
	tween.tween_interval(1.0)
	tween.tween_property(msg, "modulate:a", 0.0, 0.5)
	tween.tween_callback(msg.queue_free)


func _on_search_changed(new_text: String) -> void:
	_clear_btn.visible = new_text.length() > 0
	_build_categories(new_text)


func _clear_search() -> void:
	if _search_box:
		_search_box.text = ""
	_clear_btn.visible = false
	_build_categories()


func _toggle_category(category: String) -> void:
	"""Accordion: tiklanan kategoriyi ac/kapat, digerlerini kapat."""
	var w: Dictionary = _category_widgets.get(category, {})
	if w.is_empty():
		return

	var list_vbox: VBoxContainer = w.get("list", null) as VBoxContainer
	var arrow_lbl: Label = w.get("arrow", null) as Label
	if not list_vbox or not arrow_lbl:
		return

	# Eger zaten aciksa, sadece kapat
	if _expanded_category == category:
		list_vbox.visible = false
		arrow_lbl.text = "▸ "
		_expanded_category = ""
		return

	# Once acik olani kapat
	if _expanded_category != "" and _category_widgets.has(_expanded_category):
		var old_w: Dictionary = _category_widgets[_expanded_category]
		var old_list: VBoxContainer = old_w.get("list", null) as VBoxContainer
		var old_arrow: Label = old_w.get("arrow", null) as Label
		if old_list and old_arrow:
			old_list.visible = false
			old_arrow.text = "▸ "

	# Yenisini ac
	list_vbox.visible = true
	arrow_lbl.text = "▾ "
	_expanded_category = category


func _format_category_name(cat: String) -> String:
	"""Kategori anahtarini okunabilir isme cevir."""
	var parts := cat.split("_")
	var result: String = ""
	for p in parts:
		if p.length() > 0:
			result += p.capitalize() + " "
	return result.strip_edges()


# --- Save / Load ---

func _save_state() -> void:
	"""Allocated node ID'lerini kaydet."""
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_var(_allocated_ids)
	file.close()


func _load_state() -> void:
	"""Allocated node ID'lerini yukle."""
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = file.get_var()
	if data is Array:
		_allocated_ids = data
	file.close()
	print("SimpleSkillTreeUI: Loaded ", _allocated_ids.size(), " allocated nodes")


# --- Input ---

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _search_box and _search_box.has_focus():
				_search_box.release_focus()
				get_viewport().set_input_as_handled()
				return
			close()
			get_viewport().set_input_as_handled()
