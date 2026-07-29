extends CanvasLayer
class_name VSPassiveSelectionUI## Kart tabanli pasif yetenek secim ekrani.i.
## Her 3. seviyede 3 kart gosterir, 1 tane secilir.

signal passive_selected(node_id: String, node_data: Dictionary)

var _node_options: Array[Dictionary] = []
var _all_nodes: Array[Dictionary] = []
var _already_owned: Array[String] = []
var _cards: Array[Panel] = []

const TYPE_COLORS: Dictionary = {
	"Notable": Color(0.3, 0.6, 1.0),     # Mavi
	"Keystone": Color(1.0, 0.85, 0.2),   # Altin
	"Small": Color(0.5, 0.5, 0.6),       # Gri
}

func show_selection(owned_nodes: Array[String]) -> void:
	_already_owned = owned_nodes.duplicate()
	_load_passive_tree()
	_pick_random_nodes()
	_build_ui()

func _load_passive_tree() -> void:
	if not _all_nodes.is_empty():
		return

	var file_path: String = "res://data/passive_skill_tree.json"
	if not FileAccess.file_exists(file_path):
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()

	var parsed := JSON.new()
	var err := parsed.parse(json_text)
	if err != OK:
		return

	var data: Dictionary = parsed.get_data()
	if data.is_empty() or not data.has("nodes"):
		return

	for node in data.nodes:
		var ntype: String = node.get("type", "")
		if ntype in ["Notable", "Keystone", "Small"]:
			_all_nodes.append(node)

func _pick_random_nodes() -> void:
	var candidates: Array[Dictionary] = []
	for node in _all_nodes:
		var nid: String = str(node.get("id", ""))
		if nid not in _already_owned:
			candidates.append(node)

	if candidates.is_empty():
		candidates = _all_nodes.duplicate()

	candidates.shuffle()
	_node_options = candidates.slice(0, mini(3, candidates.size()))

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size

	# Arkaplan karartma
	var bg := ColorRect.new()
	bg.name = "PassiveBG"
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	# Baslik
	var title := Label.new()
	title.text = "PASİF YETENEK SEÇ!"
	title.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.12)
	title.size = Vector2(vp.x, 50)
	add_child(title)

	var sub := Label.new()
	sub.text = "Geliştirmek istediğin pasifi seç"
	sub.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6, 0.8))
	sub.add_theme_font_size_override("font_size", 14)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, vp.y * 0.12 + 45)
	sub.size = Vector2(vp.x, 25)
	add_child(sub)

	var card_w: float = 280.0
	var card_h: float = 340.0
	var gap: float = 30.0
	var total_w: float = _node_options.size() * card_w + (_node_options.size() - 1) * gap
	var start_x: float = (vp.x - total_w) / 2.0
	var card_y: float = vp.y * 0.25

	for i in range(_node_options.size()):
		var node_data: Dictionary = _node_options[i]
		var node_id: String = str(node_data.get("id", ""))
		var node_name: String = node_data.get("name", "Bilinmeyen Node")
		var node_type: String = node_data.get("type", "Small")
		var effects_raw: String = node_data.get("effects_raw", "")
		var flavor: String = node_data.get("flavor_text", "")
		var stats: Dictionary = node_data.get("stats", {})

		var type_color: Color = TYPE_COLORS.get(node_type, Color(0.5, 0.5, 0.6))

		var card := Panel.new()
		card.name = "PassiveCard_%d" % i
		card.position = Vector2(start_x + i * (card_w + gap), card_y)
		card.size = Vector2(card_w, card_h)
		card.mouse_filter = Control.MOUSE_FILTER_STOP

		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		card_style.border_width_left = 3
		card_style.border_width_right = 3
		card_style.border_width_top = 3
		card_style.border_width_bottom = 3
		card_style.border_color = type_color
		card_style.set_corner_radius_all(12)
		card_style.shadow_color = Color(0, 0, 0, 0.5)
		card_style.shadow_size = 8
		card_style.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("panel", card_style)

		# Node tipi ikon gostergesi (daire)
		var icon_bg := ColorRect.new()
		icon_bg.position = Vector2((card_w - 64) / 2.0, 20)
		icon_bg.size = Vector2(64, 64)
		icon_bg.color = Color(type_color.r, type_color.g, type_color.b, 0.15)
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color(type_color.r, type_color.g, type_color.b, 0.15)
		icon_style.set_corner_radius_all(32)
		icon_bg.add_theme_stylebox_override("panel", icon_style)
		card.add_child(icon_bg)

		var icon_label := Label.new()
		icon_label.text = type_icon(node_type)
		icon_label.add_theme_font_size_override("font_size", 32)
		icon_label.add_theme_color_override("font_color", type_color)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.position = Vector2((card_w - 64) / 2.0, 20)
		icon_label.size = Vector2(64, 64)
		card.add_child(icon_label)

		# Node adi
		var name_lbl := Label.new()
		name_lbl.text = node_name
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_constant_override("shadow_outline_size", 1)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.position = Vector2(0, 100)
		name_lbl.size = Vector2(card_w, 28)
		card.add_child(name_lbl)

		# Tip badge
		var type_badge := Label.new()
		type_badge.text = node_type
		type_badge.add_theme_color_override("font_color", type_color)
		type_badge.add_theme_font_size_override("font_size", 11)
		type_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_badge.position = Vector2(0, 128)
		type_badge.size = Vector2(card_w, 18)
		card.add_child(type_badge)

		# Ayrac
		var line := ColorRect.new()
		line.color = Color(type_color.r, type_color.g, type_color.b, 0.3)
		line.position = Vector2(15, 150)
		line.size = Vector2(card_w - 30, 1)
		card.add_child(line)

		# Efektler
		var effects: Array[String] = parse_effects(effects_raw, stats)
		var effect_start_y: float = 162.0
		for ei in range(mini(effects.size(), 6)):
			var eff_lbl := Label.new()
			eff_lbl.text = effects[ei]
			eff_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 0.9))
			eff_lbl.add_theme_font_size_override("font_size", 12)
			eff_lbl.position = Vector2(20, effect_start_y + ei * 22)
			eff_lbl.size = Vector2(card_w - 40, 20)
			card.add_child(eff_lbl)

		# Ayrac 2
		var line2_pos: float = effect_start_y + min(effects.size(), 6) * 22 + 10
		if line2_pos < 220:
			line2_pos = 220
		var line2 := ColorRect.new()
		line2.color = Color(type_color.r, type_color.g, type_color.b, 0.2)
		line2.position = Vector2(15, line2_pos)
		line2.size = Vector2(card_w - 30, 1)
		card.add_child(line2)

		# Flavor text
		if not flavor.is_empty():
			var flv_lbl := Label.new()
			flv_lbl.text = "\"%s\"" % flavor
			flv_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.7))
			flv_lbl.add_theme_font_size_override("font_size", 11)
			flv_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			flv_lbl.position = Vector2(15, line2_pos + 8)
			flv_lbl.size = Vector2(card_w - 30, 40)
			card.add_child(flv_lbl)

		# SEC butonu
		var btn_y: float = card_h - 55
		var select_btn := Button.new()
		select_btn.name = "PassiveBtn_%d" % i
		select_btn.text = "SEÇ  [%d]" % (i + 1)
		select_btn.position = Vector2(30, btn_y)
		select_btn.size = Vector2(card_w - 60, 40)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(type_color.r, type_color.g, type_color.b, 0.25)
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = type_color
		btn_style.set_corner_radius_all(8)
		select_btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = Color(type_color.r, type_color.g, type_color.b, 0.4)
		btn_hover.border_width_left = 2
		btn_hover.border_width_right = 2
		btn_hover.border_width_top = 2
		btn_hover.border_width_bottom = 2
		btn_hover.border_color = Color(minf(type_color.r + 0.3, 1.0), minf(type_color.g + 0.3, 1.0), minf(type_color.b + 0.3, 1.0), 1.0)
		btn_hover.set_corner_radius_all(8)
		select_btn.add_theme_stylebox_override("hover", btn_hover)

		select_btn.add_theme_color_override("font_color", Color.WHITE)
		select_btn.add_theme_font_size_override("font_size", 15)
		select_btn.pressed.connect(_on_passive_chosen.bind(node_id, node_data))
		card.add_child(select_btn)

		add_child(card)
		_cards.append(card)

func type_icon(type: String) -> String:
	match type:
		"Keystone":
			return "⭐"
		"Notable":
			return "✦"
		_:
			return "●"

func parse_effects(effects_raw: String, stats: Dictionary) -> Array[String]:
	var result: Array[String] = []

	if not effects_raw.is_empty():
		var lines: PackedStringArray = effects_raw.split("\n")
		for line in lines:
			line = line.strip_edges()
			if not line.is_empty():
				result.append(line)

	if result.is_empty() and not stats.is_empty():
		for key in stats:
			var val = stats[key]
			if val is float or val is int:
				result.append("%s: %s" % [key, format_stat(key, float(val))])
			elif val is String:
				result.append("%s: %s" % [key, val])

	if result.is_empty():
		result.append("Güçlü bir pasif yetenek")

	return result

func format_stat(key: String, val: float) -> String:
	if abs(val) < 1.0:
		return "+%.0f%%" % (val * 100.0)
	return "+%.1f" % val

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				if _node_options.size() >= 1:
					var n := _node_options[0]
					_on_passive_chosen(str(n.get("id", "")), n)
			KEY_2:
				if _node_options.size() >= 2:
					var n := _node_options[1]
					_on_passive_chosen(str(n.get("id", "")), n)
			KEY_3:
				if _node_options.size() >= 3:
					var n := _node_options[2]
					_on_passive_chosen(str(n.get("id", "")), n)

func _on_passive_chosen(node_id: String, node_data: Dictionary) -> void:
	passive_selected.emit(node_id, node_data)
	queue_free()
