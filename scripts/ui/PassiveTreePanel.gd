extends CanvasLayer
class_name PassiveTreePanel
## Pasif ağaç paneli - Tab sistemli modern UI

signal node_selected(node_id: String)
signal closed()

const PASSIVE_TREE_SCRIPT := "res://scripts/core/SimplifiedPassiveTree.gd"

var _passive_tree_node: Node = null
var _node_buttons: Dictionary = {}
var _tab_buttons: Dictionary = {}
var _current_tab: int = 0

# UI sabitleri
const TAB_BAR_HEIGHT := 40.0
const CONTENT_MARGIN := 10.0
const NODE_BUTTON_HEIGHT := 44.0
const SCROLL_STEP := 60.0

# Renkler (kategori renkleri)
const _CAT_COLORS: Dictionary = {
	"offense": Color(0.85, 0.3, 0.2),
	"defense": Color(0.3, 0.6, 0.9),
	"speed": Color(0.3, 0.85, 0.4),
	"critical": Color(0.9, 0.7, 0.2),
	"utility": Color(0.7, 0.4, 0.9)
}

func _get_passive_tree() -> Node:
	return _passive_tree_node

func _call_tree_func(func_name: String, args: Array = []) -> Variant:
	var tree := _get_passive_tree()
	if not tree:
		return null
	var method: Callable = Callable(tree, func_name)
	return method.callv(args)

func _get_tree_prop(prop_name: String) -> Variant:
	var tree := _get_passive_tree()
	if not tree:
		return null
	return tree.get(prop_name)

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 100

	var tree_script: Script = load(PASSIVE_TREE_SCRIPT)
	_passive_tree_node = tree_script.new()
	add_child(_passive_tree_node)

	var points_changed: Signal = _passive_tree_node.get("passive_points_changed") as Signal
	var unlocked: Signal = _passive_tree_node.get("passive_unlocked") as Signal
	points_changed.connect(_on_points_changed)
	unlocked.connect(_on_node_unlocked)

	_build_ui()
	_update_all_nodes()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close()

func close() -> void:
	visible = false
	closed.emit()


func _build_ui() -> void:
	# Ana panel
	var main_panel := Panel.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	main_panel.offset_left = -320.0
	main_panel.offset_right = -10.0
	main_panel.offset_top = -350.0
	main_panel.offset_bottom = -10.0

	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	bg.border_color = Color(0.3, 0.3, 0.4, 0.5)
	bg.border_width_left = 1
	bg.border_width_top = 1
	bg.border_width_right = 1
	bg.border_width_bottom = 1
	bg.set_corner_radius_all(8)
	main_panel.add_theme_stylebox_override("panel", bg)
	add_child(main_panel)

	# Başlık
	var header := Label.new()
	header.name = "Header"
	header.text = "PASİF AĞAÇ"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.position = Vector2(0, 5)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	header.add_theme_font_size_override("font_size", 14)
	main_panel.add_child(header)

	# Puan
	var points_lbl := Label.new()
	points_lbl.name = "PointsLabel"
	points_lbl.text = "Kalan: 0 / 20"
	points_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	points_lbl.position = Vector2(0, 22)
	points_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	points_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	points_lbl.add_theme_font_size_override("font_size", 11)
	main_panel.add_child(points_lbl)

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.name = "TabBar"
	tab_bar.position = Vector2(5, 42)
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bar.size_flags_vertical = 0
	tab_bar.custom_minimum_size = Vector2(0, TAB_BAR_HEIGHT)
	main_panel.add_child(tab_bar)

	# Tab butonları
	var tree_data: Dictionary = _get_tree_prop("tree_data")
	var categories: Array = tree_data.get("categories", [])

	for i in range(categories.size()):
		var cat: Dictionary = categories[i]
		var tab_btn := _create_tab_button(cat, i)
		tab_bar.add_child(tab_btn)
		_tab_buttons[i] = tab_btn

	# İçerik alanı (ScrollContainer + Grid)
	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.position = Vector2(5, 50)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 250.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_panel.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "NodeGrid"
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	# Tüm node butonlarını oluştur
	for cat_idx in range(categories.size()):
		var cat: Dictionary = categories[cat_idx]
		var nodes: Array = cat.get("nodes", [])
		for node: Dictionary in nodes:
			var btn := _create_node_button(node, cat, cat_idx)
			grid.add_child(btn)
			_node_buttons[node["id"]] = btn

	# İlk tab'ı seçili göster
	_update_tabs()

func _create_tab_button(category: Dictionary, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(58, 30)
	btn.text = _get_short_name(category["id"])
	btn.pressed.connect(_on_tab_clicked.bind(index))

	var cat_color: Color = _CAT_COLORS.get(category["id"], Color.WHITE)
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	style_normal.border_color = Color(cat_color, 0.3)
	style_normal.border_width_bottom = 2
	style_normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_selected := StyleBoxFlat.new()
	style_selected.bg_color = Color(cat_color, 0.2)
	style_selected.border_color = cat_color
	style_selected.border_width_bottom = 2
	style_selected.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", style_selected)
	btn.add_theme_stylebox_override("pressed", style_selected)
	btn.add_theme_stylebox_override("disabled", style_selected)

	btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	btn.add_theme_color_override("font_hover_color", Color(0.9, 0.9, 0.95))
	return btn

func _get_short_name(cat_id: String) -> String:
	match cat_id:
		"offense": return "SALDIRI"
		"defense": return "SAVUNMA"
		"speed": return "HIZ"
		"critical": return "KRITIK"
		"utility": return "Fayda"
	return cat_id.to_upper()

func _on_tab_clicked(tab_index: int) -> void:
	_current_tab = tab_index
	_update_tabs()

func _update_tabs() -> void:
	var tree_data: Dictionary = _get_tree_prop("tree_data")
	var categories: Array = tree_data.get("categories", [])

	# Tab butonlarını güncelle
	for tab_idx in _tab_buttons:
		var btn: Button = _tab_buttons[tab_idx]
		var is_selected: bool = tab_idx == _current_tab
		var cat_color: Color = _CAT_COLORS.get(categories[tab_idx]["id"], Color.WHITE)

		var style := StyleBoxFlat.new()
		if is_selected:
			style.bg_color = Color(cat_color, 0.25)
			style.border_color = cat_color
			style.border_width_bottom = 2
		else:
			style.bg_color = Color(0.12, 0.12, 0.18, 0.8)
			style.border_color = Color(cat_color, 0.2)
			style.border_width_bottom = 1
		style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", style)

	# Grid'deki butonları göster/gizle
	var grid: GridContainer = get_node_or_null("MainPanel/ContentScroll/NodeGrid")
	if not grid:
		return

	for node_id in _node_buttons:
		var btn: Button = _node_buttons[node_id]
		var cat_idx: int = btn.get_meta("cat_index", -1) as int
		btn.visible = cat_idx == _current_tab

func _create_node_button(node: Dictionary, category: Dictionary, cat_index: int) -> Button:
	var btn := Button.new()
	btn.set_meta("cat_index", cat_index)
	btn.set_meta("node_id", node["id"])
	btn.custom_minimum_size = Vector2(140, NODE_BUTTON_HEIGHT)

	var node_id: String = node["id"]
	var display_name: String = node.get("name", node_id)
	var cat_color: Color = _CAT_COLORS.get(category["id"], Color.WHITE)

	# İkon
	var icon := Label.new()
	icon.position = Vector2(8, 8)
	icon.text = _get_node_icon(category["id"])
	icon.add_theme_color_override("font_color", cat_color)
	icon.add_theme_font_size_override("font_size", 16)
	btn.add_child(icon)

	# İsim
	var name_lbl := Label.new()
	name_lbl.position = Vector2(28, 6)
	name_lbl.text = display_name
	name_lbl.add_theme_font_size_override("font_size", 11)
	btn.add_child(name_lbl)

	# Maliyet
	var cost_lbl := Label.new()
	cost_lbl.name = "Cost"
	cost_lbl.position = Vector2(28, 24)
	cost_lbl.add_theme_font_size_override("font_size", 9)
	btn.add_child(cost_lbl)

	btn.pressed.connect(_on_node_clicked.bind(node_id))
	btn.mouse_entered.connect(_on_node_hover.bind(node_id))
	btn.mouse_exited.connect(_on_node_unhover)

	_update_button_style(btn, false, false, cat_color)
	return btn

func _get_node_icon(category_id: String) -> String:
	match category_id:
		"offense": return "⚔"
		"defense": return "🛡"
		"speed": return "⚡"
		"critical": return "💥"
		"utility": return "◆"
	return "●"

func _update_button_style(btn: Button, unlocked: bool, can_unlock: bool, color) -> void:
	var cat_color: Color
	if color is String:
		cat_color = _CAT_COLORS.get(color, Color.WHITE)
	else:
		cat_color = color as Color

	var bg_color: Color
	var border_color: Color

	if unlocked:
		bg_color = Color(cat_color, 0.35)
		border_color = Color(cat_color, 0.8)
	elif can_unlock:
		bg_color = Color(0.18, 0.18, 0.25, 0.9)
		border_color = Color(cat_color, 0.5)
	else:
		bg_color = Color(0.1, 0.1, 0.15, 0.7)
		border_color = Color(0.25, 0.25, 0.3, 0.4)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)
	btn.disabled = unlocked or not can_unlock

func _update_all_nodes() -> void:
	var tree_data: Dictionary = _get_tree_prop("tree_data")
	var categories: Array = tree_data.get("categories", [])

	for node_id in _node_buttons:
		var btn: Button = _node_buttons[node_id]
		var cat_color: Color = Color.WHITE
		var cost: int = 1

		# Kategori rengini bul
		for cat_idx in range(categories.size()):
			var cat: Dictionary = categories[cat_idx]
			for n: Dictionary in cat.get("nodes", []):
				if n.get("id") == node_id:
					cat_color = _CAT_COLORS.get(cat["id"], Color.WHITE)
					cost = n.get("cost", 1) as int
					break

		var unlocked_nodes: Array = _get_tree_prop("unlocked_nodes")
		var unlocked: bool = node_id in unlocked_nodes
		var can_unlock: bool = _call_tree_func("can_unlock_node", [node_id])
		_update_button_style(btn, unlocked, can_unlock, cat_color)

		# Maliyet etiketini güncelle
		var cost_label: Label = btn.get_node_or_null("Cost")
		if cost_label:
			if unlocked:
				cost_label.text = "Acik ✓"
				cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			elif can_unlock:
				cost_label.text = "%d puan" % cost
				cost_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			else:
				cost_label.text = "Kilitli"
				cost_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))

func _on_node_clicked(node_id: String) -> void:
	var result = _call_tree_func("unlock_node", [node_id])
	if result:
		_update_all_nodes()
		_show_node_tooltip(node_id, true)

func _on_node_hover(node_id: String) -> void:
	_show_node_tooltip(node_id, false)

func _on_node_unhover() -> void:
	_hide_tooltip()

func _show_node_tooltip(node_id: String, just_unlocked: bool) -> void:
	var node_info: Dictionary = _call_tree_func("get_node_info", [node_id])
	if node_info.is_empty():
		return

	var tooltip := get_node_or_null("TooltipPanel") as Panel
	if not tooltip:
		tooltip = Panel.new()
		tooltip.name = "TooltipPanel"
		tooltip.z_index = 1000

		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.1, 0.1, 0.15, 0.98)
		bg.border_color = Color(0.4, 0.4, 0.5, 0.8)
		bg.border_width_left = 1
		bg.border_width_right = 1
		bg.border_width_top = 1
		bg.border_width_bottom = 1
		bg.set_corner_radius_all(6)
		tooltip.add_theme_stylebox_override("panel", bg)
		add_child(tooltip)

	var content := ""
	if just_unlocked:
		content += "[color=#88ff88]✓ %s açıldı![/color]\n\n" % node_info.get("name", node_id)
	else:
		content += "[b]%s[/b]\n" % node_info.get("name", node_id)

	content += "[color=#aaaaaa]Maliyet:[/color] %d puan\n\n" % node_info.get("cost", 1)
	content += "[color=#dddddd]%s[/color]" % _call_tree_func("get_stat_display", [node_id])

	if node_info.has("requires"):
		var req_id: String = node_info["requires"]
		var req_info: Dictionary = _call_tree_func("get_node_info", [req_id])
		var req_name: String = req_info.get("name", req_id)
		content += "\n\n[color=#888888]Gereken: %s[/color]" % req_name

	var label := tooltip.get_node_or_null("Label") as RichTextLabel
	if not label:
		label = RichTextLabel.new()
		label.name = "Label"
		label.bbcode_enabled = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.position = Vector2(8, 5)
		tooltip.add_child(label)

	label.bbcode_text = content
	label.size = Vector2(220, 0)
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	tooltip.size = label.size + Vector2(16, 10)

	# Fareye göre pozisyon
	var mouse_pos := get_viewport().get_mouse_position()
	var viewport_size: Vector2 = get_viewport().size
	tooltip.position = mouse_pos + Vector2(10, 10)
	if tooltip.position.x + tooltip.size.x > viewport_size.x:
		tooltip.position.x = mouse_pos.x - tooltip.size.x - 10
	if tooltip.position.y + tooltip.size.y > viewport_size.y:
		tooltip.position.y = viewport_size.y - tooltip.size.y - 5
	tooltip.visible = true

func _hide_tooltip() -> void:
	var tooltip := get_node_or_null("TooltipPanel") as Panel
	if tooltip:
		tooltip.visible = false

func _on_points_changed(points: int) -> void:
	var label := get_node_or_null("MainPanel/PointsLabel") as Label
	if not label:
		label = get_node_or_null("PointsLabel") as Label
	if label:
		label.text = "Kalan: %d / 20" % points

func _on_node_unlocked(node_id: String) -> void:
	_update_all_nodes()

func _show_summary() -> void:
	var summary: String = _call_tree_func("get_summary", [])

	# Özet dialog
	var dialog := AcceptDialog.new()
	dialog.title = "Pasif Ağaç Özeti"
	dialog.dialog_text = summary
	dialog.ok_button_text = "Tamam"
	add_child(dialog)
	dialog.popup_centered(Vector2(400, 300))
	dialog.confirmed.connect(func(): dialog.queue_free())

## Test için: Belirli miktarda puan ver
func give_points(amount: int) -> void:
	var current_points: int = _call_tree_func("get_remaining_points", [])
	_call_tree_func("set_passive_points", [current_points + amount])
