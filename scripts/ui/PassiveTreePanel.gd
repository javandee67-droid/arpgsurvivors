extends CanvasLayer
class_name PassiveTreePanel
## Basitleştirilmiş pasif ağaç paneli
## Kategorilere ayrılmış 50 node, her biri açılabilir

signal node_selected(node_id: String)

# Script dosya yolu (dinamik yükleme için)
const PASSIVE_TREE_SCRIPT := "res://scripts/core/SimplifiedPassiveTree.gd"

var _passive_tree_node: Node = null  # SimplifiedPassiveTree instance
var _category_panels: Array[Panel] = []
var _node_buttons: Dictionary = {}  # node_id -> Button

const PANEL_WIDTH := 200.0
const PANEL_HEIGHT := 300.0
const NODE_HEIGHT := 50.0
const CATEGORY_GAP := 10.0

# Helper fonksiyonlar (passive_tree yerine)
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
	
	# Pasif ağacı oluştur (dinamik yükleme)
	var SimplifiedPassiveTree := load(PASSIVE_TREE_SCRIPT)
	_passive_tree_node = SimplifiedPassiveTree.new()
	add_child(_passive_tree_node)
	
	# Sinyalleri bağla
	var points_changed: Signal = _passive_tree_node.get("passive_points_changed") as Signal
	var unlocked: Signal = _passive_tree_node.get("passive_unlocked") as Signal
	points_changed.connect(_on_points_changed)
	unlocked.connect(_on_node_unlocked)
	
	_build_ui()
	_update_all_nodes()

func _build_ui() -> void:
	# Başlık
	var title := Label.new()
	title.text = "PASİF AĞAÇ"
	title.position = Vector2(20, 20)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 18)
	add_child(title)
	
	# Puan göstergesi
	var points_lbl := Label.new()
	points_lbl.name = "PointsLabel"
	points_lbl.position = Vector2(20, 45)
	points_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	points_lbl.add_theme_font_size_override("font_size", 14)
	add_child(points_lbl)
	
	# Özet butonu
	var summary_btn := Button.new()
	summary_btn.text = "Özet"
	summary_btn.position = Vector2(20, 70)
	summary_btn.pressed.connect(_show_summary)
	add_child(summary_btn)
	
	# Kategori panellerini oluştur
	var tree_data: Dictionary = _get_tree_prop("tree_data")
	var categories: Array = tree_data.get("categories", [])
	var y_offset: float = 110.0
	
	for i in range(categories.size()):
		var cat: Dictionary = categories[i]
		var cat_panel := _create_category_panel(cat, i, y_offset)
		add_child(cat_panel)
		_category_panels.append(cat_panel)
		y_offset += PANEL_HEIGHT + CATEGORY_GAP

func _create_category_panel(category: Dictionary, index: int, y_offset: float) -> Panel:
	var panel := Panel.new()
	panel.name = "Category_" + category["id"]
	panel.position = Vector2(20, y_offset)
	panel.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	
	# Panel arka planı
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.95)
	bg.size = panel.size
	panel.add_child(bg)
	
	# Panel başlığı
	var header := Label.new()
	header.text = category["name"]
	header.position = Vector2(10, 5)
	header.add_theme_color_override("font_color", Color(category["color"]))
	header.add_theme_font_size_override("font_size", 14)
	panel.add_child(header)
	
	# Ayrıntı çizgisi
	var sep := ColorRect.new()
	sep.color = Color(category["color"], 0.5)
	sep.position = Vector2(10, 25)
	sep.size = Vector2(PANEL_WIDTH - 20, 1)
	panel.add_child(sep)
	
	# Node butonları
	var nodes: Array = category.get("nodes", [])
	var node_y: float = 35.0
	
	for j in range(nodes.size()):
		var node: Dictionary = nodes[j]
		var btn := _create_node_button(node, category)
		btn.position = Vector2(10, node_y)
		panel.add_child(btn)
		_node_buttons[node["id"]] = btn
		node_y += NODE_HEIGHT
	
	return panel

func _create_node_button(node: Dictionary, category: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(PANEL_WIDTH - 20, NODE_HEIGHT - 5)
	
	var node_id: String = node["id"]
	var display_name: String = node.get("name", node_id)
	var cost: int = node.get("cost", 1) as int
	
	# İkon ve isim
	var icon_label := Label.new()
	icon_label.name = "Icon"
	icon_label.position = Vector2(5, 5)
	icon_label.text = _get_category_icon(category["id"])
	icon_label.add_theme_color_override("font_color", Color(category["color"]))
	btn.add_child(icon_label)
	
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(25, 5)
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 11)
	btn.add_child(name_label)
	
	# Maliyet
	var cost_label := Label.new()
	cost_label.name = "Cost"
	cost_label.position = Vector2(25, 22)
	cost_label.text = "Maliyet: %d puan" % cost
	cost_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	cost_label.add_theme_font_size_override("font_size", 9)
	btn.add_child(cost_label)
	
	# Buton stili
	_update_button_style(btn, false, false, category["color"])
	
	# Tıklama
	btn.pressed.connect(_on_node_clicked.bind(node_id))
	btn.mouse_entered.connect(_on_node_hover.bind(node_id))
	btn.mouse_exited.connect(_on_node_unhover)
	
	return btn

func _get_category_icon(category_id: String) -> String:
	match category_id:
		"offense": return "⚔"
		"defense": return "🛡"
		"speed": return "⚡"
		"critical": return "💥"
		"utility": return "💎"
	return "●"

func _update_button_style(btn: Button, unlocked: bool, can_unlock: bool, color: String) -> void:
	var bg_color: Color
	var border_color: Color
	
	if unlocked:
		bg_color = Color(color, 0.3)
		border_color = Color(color, 0.9)
	elif can_unlock:
		bg_color = Color(0.2, 0.2, 0.25, 0.9)
		border_color = Color(color, 0.6)
	else:
		bg_color = Color(0.15, 0.15, 0.18, 0.8)
		border_color = Color(0.3, 0.3, 0.35, 0.5)
	
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.disabled = unlocked or not can_unlock

func _update_all_nodes() -> void:
	for node_id in _node_buttons:
		var btn: Button = _node_buttons[node_id]
		var parent: Panel = btn.get_parent() as Panel
		var category_color: String = "#ff4444"
		
		# Kategori rengini bul
		var tree_data: Dictionary = _get_tree_prop("tree_data")
		for cat in tree_data.get("categories", []):
			for n in cat.get("nodes", []):
				if n.get("id") == node_id:
					category_color = cat.get("color", "#ff4444")
					break
		
		var unlocked_nodes: Array = _get_tree_prop("unlocked_nodes")
		var unlocked: bool = node_id in unlocked_nodes
		var can_unlock: bool = _call_tree_func("can_unlock_node", [node_id])
		_update_button_style(btn, unlocked, can_unlock, category_color)
		
		# Durum etiketini güncelle
		var cost_label: Label = btn.get_node_or_null("Cost")
		if cost_label:
			if unlocked:
				cost_label.text = "✓ Açık"
				cost_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			elif can_unlock:
				cost_label.text = "Tıklayarak aç"
				cost_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			else:
				cost_label.text = "Kilitli"
				cost_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

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
	
	# Tooltip paneli
	var tooltip := get_node_or_null("TooltipPanel") as Panel
	if not tooltip:
		tooltip = Panel.new()
		tooltip.name = "TooltipPanel"
		tooltip.z_index = 1000
		add_child(tooltip)
	
	# Tooltip içeriği
	var content := ""
	
	if just_unlocked:
		content += "[color=#88ff88]✓ %s açıldı![/color]\n\n" % node_info.get("name", node_id)
	else:
		content += "[b]%s[/b]\n" % node_info.get("name", node_id)
	
	content += "[color=#aaaaaa]Maliyet:[/color] %d puan\n" % node_info.get("cost", 1)
	content += "\n"
	content += "[color=#dddddd]%s[/color]" % _call_tree_func("get_stat_display", [node_id])
	
	# Gereksinim bilgisi
	if node_info.has("requires"):
		var req_id: String = node_info["requires"]
		var req_info: Dictionary = _call_tree_func("get_node_info", [req_id])
		var req_name: String = req_info.get("name", req_id)
		content += "\n\n[color=#888888]Gereken: %s[/color]" % req_name
	
	# Tooltip göster
	var label := tooltip.get_node_or_null("Label") as RichTextLabel
	if not label:
		label = RichTextLabel.new()
		label.name = "Label"
		label.bbcode_enabled = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tooltip.add_child(label)
	
	label.bbcode_text = content
	label.size = Vector2(250, 150)
	label.position = Vector2(0, 0)
	tooltip.size = label.size + Vector2(10, 10)
	
	# Fare pozisyonunda göster
	var mouse_pos := get_viewport().get_mouse_position()
	tooltip.position = mouse_pos + Vector2(15, 15)
	tooltip.visible = true

func _hide_tooltip() -> void:
	var tooltip := get_node_or_null("TooltipPanel") as Panel
	if tooltip:
		tooltip.visible = false

func _on_points_changed(points: int) -> void:
	var label := get_node_or_null("PointsLabel") as Label
	if label:
		# MAX_PASSIVE_POINTS sabitini doğrudan kullan
		label.text = "Kalan Puan: [color=#ffcc00]%d[/color] / 20" % points

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
