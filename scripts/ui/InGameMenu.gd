extends CanvasLayer
class_name InGameMenu
## In-Game Menu - Appears when pressing ESC during gameplay.
## PoE-inspired design with smooth animations.

signal resume_game()
signal return_to_menu()
signal quit_to_desktop()

const BG_COLOR := Color(0.02, 0.02, 0.04, 0.85)
const ACCENT_COLOR := Color(0.85, 0.65, 0.25, 1.0)
const TEXT_COLOR := Color(0.9, 0.88, 0.82, 1.0)
const HIGHLIGHT_COLOR := Color(1.0, 0.9, 0.6, 1.0)
const DANGER_COLOR := Color(0.9, 0.3, 0.2, 1.0)

var _visible_state: bool = false
var _buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	# Background overlay
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Center panel
	var panel := Panel.new()
	panel.name = "Panel"
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -180
	panel.offset_right = 180
	panel.offset_top = -200
	panel.offset_bottom = 200
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.05, 0.1, 0.98)
	panel_style.border_color = ACCENT_COLOR
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	
	# Title
	var title := Label.new()
	title.text = "DURAKLATILDI"
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -120
	title.offset_right = 120
	title.offset_top = 20
	title.offset_bottom = 60
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	panel.add_child(title)
	
	# Menu buttons
	var vbox := VBoxContainer.new()
	vbox.name = "MenuVBox"
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -140
	vbox.offset_right = 140
	vbox.offset_top = -50
	vbox.offset_bottom = 180
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)
	
	# Button configs
	var button_configs := [
		{"text": "▶  DEVAM ET", "id": "resume", "color": Color(0.4, 0.9, 0.5, 1.0)},
		{"text": "⚙  AYARLAR", "id": "settings", "color": Color(0.7, 0.7, 0.75, 1.0)},
		{"text": "🏠  ANA MENÜ", "id": "menu", "color": Color(0.85, 0.65, 0.25, 1.0)},
		{"text": "✕  CIKIS", "id": "quit", "color": DANGER_COLOR},
	]
	
	for config in button_configs:
		var btn := _create_menu_button(config)
		vbox.add_child(btn)
		_buttons.append(btn)

func _create_menu_button(config: Dictionary) -> Button:
	var btn := Button.new()
	btn.text = config["text"]
	btn.custom_minimum_size = Vector2(260, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 15)
	
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	normal.border_color = Color(0.25, 0.25, 0.3, 0.6)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	hover.border_color = config["color"]
	hover.border_width_left = 2
	hover.border_width_right = 2
	hover.border_width_top = 2
	hover.border_width_bottom = 2
	hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", hover)
	
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.15, 0.12, 0.1, 0.98)
	pressed.border_color = config["color"]
	pressed.border_width_left = 2
	pressed.border_width_right = 2
	pressed.border_width_top = 2
	pressed.border_width_bottom = 2
	pressed.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed)
	
	btn.add_theme_color_override("font_color", config["color"])
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	btn.pressed.connect(_on_button_pressed.bind(config["id"]))
	
	return btn

func _on_button_pressed(button_id: String) -> void:
	match button_id:
		"resume":
			hide_menu()
		"settings":
			_show_settings()
		"menu":
			return_to_menu.emit()
			hide_menu()
		"quit":
			quit_to_desktop.emit()

func _show_settings() -> void:
	# For now, just a message
	print("Settings not implemented yet")

func show_menu() -> void:
	if _visible_state:
		return
	_visible_state = true
	visible = true
	get_tree().paused = true
	
	# Animate in
	var panel := get_node_or_null("Panel") as Panel
	if panel:
		panel.modulate = Color(1, 1, 1, 0)
		panel.offset_top = 20
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(panel, "modulate:a", 1.0, 0.2)
		tween.tween_property(panel, "offset_top", 0.0, 0.3).set_trans(Tween.TRANS_BACK)

func hide_menu() -> void:
	if not _visible_state:
		return
	_visible_state = false
	
	var panel := get_node_or_null("Panel") as Panel
	if panel:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(panel, "modulate:a", 0.0, 0.15)
		tween.tween_property(panel, "offset_top", -20.0, 0.2).set_trans(Tween.TRANS_BACK)
		await tween.finished
	
	visible = false
	get_tree().paused = false

func toggle_menu() -> void:
	if _visible_state:
		hide_menu()
	else:
		show_menu()

func is_visible() -> bool:
	return _visible_state

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_menu()
