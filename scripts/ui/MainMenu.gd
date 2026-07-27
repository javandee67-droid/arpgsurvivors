extends CanvasLayer
class_name MainMenu
## Professional Main Menu - PoE/Path of Exile inspired design.
## Features: Animated background, smooth transitions, upgrade shop, settings.

signal start_new_game()
signal continue_game()
signal open_upgrades()
signal open_settings()
signal quit_game()

## UI States
enum State {
	MAIN,
	UPGRADES,
	SETTINGS,
	CONFIRM_NEW_GAME,
}

var current_state: State = State.MAIN
var persistent_upgrades

## Theme colors
const BG_COLOR := Color(0.02, 0.02, 0.04, 1.0)
const ACCENT_COLOR := Color(0.85, 0.65, 0.25, 1.0)
const TEXT_COLOR := Color(0.9, 0.88, 0.82, 1.0)
const HIGHLIGHT_COLOR := Color(1.0, 0.9, 0.6, 1.0)
const DANGER_COLOR := Color(0.9, 0.3, 0.2, 1.0)
const SUCCESS_COLOR := Color(0.4, 0.9, 0.5, 1.0)

## References
var _bg_gradient: GradientTexture2D
var _particle_timer: float = 0.0
var _buttons: Array[Button] = []
var _gold_label: Label
var _title_label: Label

## Animation
var _anim_timer: float = 0.0
var _title_y_offset: float = 0.0
var _button_spacing: float = 60.0
var _target_button_y: float = 0.0
var _current_button_y: float = 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	persistent_upgrades = PersistentUpgrades.get_instance()
	_build_ui()
	_play_intro_animation()

func _process(delta: float) -> void:
	_anim_timer += delta
	_particle_timer += delta
	
	# Animate title
	_title_y_offset = sin(_anim_timer * 1.5) * 3.0
	
	# Update particle effects
	if _particle_timer > 0.05:
		_particle_timer = 0.0
		_update_particles()
	
	# Update gold display
	if _gold_label:
		_gold_label.text = "✦ %d Altin" % _get_player_gold()
	
	# Animate buttons entrance
	_current_button_y = lerpf(_current_button_y, _target_button_y, delta * 4.0)

## Build the main menu UI
func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Animated gradient overlay
	var gradient := ColorRect.new()
	gradient.name = "GradientOverlay"
	gradient.color = Color(0.1, 0.05, 0.15, 0.3)
	gradient.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(gradient)
	
	# Particle container (for floating particles)
	var particles := Node2D.new()
	particles.name = "Particles"
	add_child(particles)
	
	# Create vignette effect
	var vignette := ColorRect.new()
	vignette.name = "Vignette"
	vignette.color = Color(0, 0, 0, 0.5)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vignette)
	
	# Title
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "ARPG SURVIVORS"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.anchor_left = 0.5
	_title_label.anchor_right = 0.5
	_title_label.offset_left = -300
	_title_label.offset_right = 300
	_title_label.offset_top = 80
	_title_label.offset_bottom = 150
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.add_theme_color_override("font_color", ACCENT_COLOR)
	add_child(_title_label)
	
	# Subtitle
	var subtitle := Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Vampire Survivors meets Path of Exile"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.anchor_left = 0.5
	subtitle.anchor_right = 0.5
	subtitle.offset_left = -250
	subtitle.offset_right = 250
	subtitle.offset_top = 155
	subtitle.offset_bottom = 185
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1.0))
	add_child(subtitle)
	
	# Menu container
	var menu_container := VBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.anchor_left = 0.5
	menu_container.anchor_right = 0.5
	menu_container.anchor_top = 0.5
	menu_container.anchor_bottom = 0.7
	menu_container.offset_left = -150
	menu_container.offset_right = 150
	menu_container.custom_minimum_size = Vector2(300, 400)
	menu_container.add_theme_constant_override("separation", 8)
	menu_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(menu_container)
	
	# Create menu buttons
	_create_menu_buttons(menu_container)
	
	# Gold display (top right)
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.text = "✦ %d Altin" % _get_player_gold()
	_gold_label.anchor_left = 1.0
	_gold_label.anchor_right = 1.0
	_gold_label.anchor_top = 0.0
	_gold_label.anchor_bottom = 0.0
	_gold_label.offset_left = -200
	_gold_label.offset_right = -20
	_gold_label.offset_top = 20
	_gold_label.offset_bottom = 50
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	add_child(_gold_label)
	
	# Stats display (bottom)
	_create_stats_display()
	
	# Version text
	var version := Label.new()
	version.name = "Version"
	version.text = "v0.1.0-alpha"
	version.anchor_left = 0.0
	version.anchor_right = 0.0
	version.anchor_top = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = 20
	version.offset_right = 200
	version.offset_top = -40
	version.offset_bottom = -20
	version.add_theme_font_size_override("font_size", 12)
	version.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 1.0))
	add_child(version)

## Create menu buttons with PoE-style design
func _create_menu_buttons(parent: VBoxContainer) -> void:
	var button_configs := [
		{"text": "▶  DEVAM ET", "id": "continue", "color": SUCCESS_COLOR},
		{"text": "✦  YENI OYUN", "id": "new_game", "color": ACCENT_COLOR},
		{"text": "⬆  YÜKSELTİLER", "id": "upgrades", "color": Color(0.5, 0.8, 1.0, 1.0)},
		{"text": "⚙  AYARLAR", "id": "settings", "color": Color(0.7, 0.7, 0.75, 1.0)},
		{"text": "✕  CIKIS", "id": "quit", "color": DANGER_COLOR},
	]
	
	for config in button_configs:
		var btn := Button.new()
		btn.name = "Btn_" + config["id"]
		btn.text = config["text"]
		btn.custom_minimum_size = Vector2(280, 50)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 16)
		
		# Normal style
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.08, 0.08, 0.12, 0.8)
		normal_style.border_color = Color(0.25, 0.25, 0.3, 0.6)
		normal_style.border_width_left = 1
		normal_style.border_width_right = 1
		normal_style.border_width_top = 1
		normal_style.border_width_bottom = 1
		normal_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("normal", normal_style)
		
		# Hover style
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
		hover_style.border_color = config["color"]
		hover_style.border_width_left = 2
		hover_style.border_width_right = 2
		hover_style.border_width_top = 2
		hover_style.border_width_bottom = 2
		hover_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("hover", hover_style)
		
		# Pressed style
		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.15, 0.12, 0.1, 0.95)
		pressed_style.border_color = config["color"]
		pressed_style.border_width_left = 2
		pressed_style.border_width_right = 2
		pressed_style.border_width_top = 2
		pressed_style.border_width_bottom = 2
		pressed_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		
		# Disabled style
		var disabled_style := StyleBoxFlat.new()
		disabled_style.bg_color = Color(0.05, 0.05, 0.08, 0.5)
		disabled_style.border_color = Color(0.15, 0.15, 0.2, 0.3)
		disabled_style.border_width_left = 1
		disabled_style.border_width_right = 1
		disabled_style.border_width_top = 1
		disabled_style.border_width_bottom = 1
		disabled_style.set_corner_radius_all(4)
		btn.add_theme_stylebox_override("disabled", disabled_style)
		
		btn.add_theme_color_override("font_color", config["color"])
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_pressed_color", config["color"])
		
		# Connect signal
		btn.pressed.connect(_on_menu_button_pressed.bind(config["id"]))
		
		parent.add_child(btn)
		_buttons.append(btn)

## Create stats display at bottom
func _create_stats_display() -> void:
	var stats_container := HBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.anchor_left = 0.5
	stats_container.anchor_right = 0.5
	stats_container.anchor_top = 1.0
	stats_container.anchor_bottom = 1.0
	stats_container.offset_left = -300
	stats_container.offset_right = 300
	stats_container.offset_top = -70
	stats_container.offset_bottom = -25
	stats_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(stats_container)
	
	var games_label := Label.new()
	games_label.name = "GamesLabel"
	games_label.text = "Oynanan: %d" % persistent_upgrades.games_played
	games_label.add_theme_font_size_override("font_size", 12)
	games_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	games_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stats_container.add_child(games_label)
	
	var sep1 := Label.new()
	sep1.text = "  •  "
	sep1.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 1.0))
	stats_container.add_child(sep1)
	
	var kills_label := Label.new()
	kills_label.name = "KillsLabel"
	kills_label.text = "Öldürme: %s" % _format_number(persistent_upgrades.total_kills)
	kills_label.add_theme_font_size_override("font_size", 12)
	kills_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	stats_container.add_child(kills_label)
	
	var sep2 := Label.new()
	sep2.text = "  •  "
	sep2.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 1.0))
	stats_container.add_child(sep2)
	
	var upgrades_label := Label.new()
	upgrades_label.name = "UpgradesLabel"
	var total_upgrades: int = 0
	for key in persistent_upgrades.upgrade_levels.keys():
		total_upgrades += persistent_upgrades.upgrade_levels[key]
	upgrades_label.text = "Yükseltme: %d" % total_upgrades
	upgrades_label.add_theme_font_size_override("font_size", 12)
	upgrades_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
	stats_container.add_child(upgrades_label)

## Update floating particles
func _update_particles() -> void:
	var particles_node := get_node_or_null("Particles") as Node2D
	if not particles_node:
		return
	
	# Add new particles occasionally
	if randf() > 0.7:
		var particle := ColorRect.new()
		particle.color = Color(
			0.85 + randf() * 0.15,
			0.65 + randf() * 0.2,
			0.25 + randf() * 0.1,
			0.1 + randf() * 0.2
		)
		particle.size = Vector2(2, 2)
		particle.position = Vector2(randf_range(100, 1180), 700)
		particles_node.add_child(particle)
		
		# Animate upward
		var tween := create_tween()
		tween.tween_property(particle, "position:y", -20, 4.0 + randf() * 2.0)
		tween.tween_callback(particle.queue_free)

## Handle menu button press
func _on_menu_button_pressed(button_id: String) -> void:
	match button_id:
		"continue":
			if _has_save_file():
				_continue_game()
			else:
				_show_message("Kayitli oyun yok!")
		"new_game":
			_show_confirm_dialog()
		"upgrades":
			_show_upgrades_panel()
		"settings":
			_show_settings_panel()
		"quit":
			get_tree().quit()

## Play intro animation
func _play_intro_animation() -> void:
	# Fade in
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Fade background
	var bg := get_node_or_null("Background") as ColorRect
	if bg:
		bg.modulate = Color(1, 1, 1, 0)
		tween.tween_property(bg, "modulate", Color(1, 1, 1, 1), 0.8)
	
	# Slide in title
	if _title_label:
		_title_label.modulate = Color(1, 1, 1, 0)
		_title_label.offset_top = -50
		tween.tween_property(_title_label, "offset_top", 80, 0.6).set_trans(Tween.TRANS_BACK)
		tween.tween_property(_title_label, "modulate", Color(1, 1, 1, 1), 0.4)
	
	# Slide in buttons
	var idx := 0
	for btn in _buttons:
		btn.modulate = Color(1, 1, 1, 0)
		btn.offset_left = -400
		tween.tween_property(btn, "offset_left", 0, 0.5).set_trans(Tween.TRANS_BACK).set_delay(0.3 + idx * 0.08)
		tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.3).set_delay(0.3 + idx * 0.08)
		idx += 1

## Show confirm dialog for new game
func _show_confirm_dialog() -> void:
	var dialog := Panel.new()
	dialog.name = "ConfirmDialog"
	dialog.anchor_left = 0.5
	dialog.anchor_right = 0.5
	dialog.anchor_top = 0.5
	dialog.anchor_bottom = 0.5
	dialog.offset_left = -200
	dialog.offset_right = 200
	dialog.offset_top = -100
	dialog.offset_bottom = 100
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.98)
	style.border_color = ACCENT_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(8)
	dialog.add_theme_stylebox_override("panel", style)
	add_child(dialog)
	
	var label := Label.new()
	label.text = "Yeni oyun baslatmak istediginize\nemin misiniz?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.offset_left = 20
	label.offset_right = -20
	label.offset_top = 10
	label.offset_bottom = 50
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 12)
	dialog.add_child(label)
	
	var btn_container := HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.offset_left = 40
	btn_container.offset_right = -40
	btn_container.offset_top = 65
	btn_container.offset_bottom = 95
	dialog.add_child(btn_container)
	
	var yes_btn := Button.new()
	yes_btn.text = "EVET"
	yes_btn.custom_minimum_size = Vector2(80, 35)
	yes_btn.pressed.connect(_on_confirm_new_game.bind(true, dialog))
	btn_container.add_child(yes_btn)
	
	var no_btn := Button.new()
	no_btn.text = "HAYIR"
	no_btn.custom_minimum_size = Vector2(80, 35)
	no_btn.pressed.connect(_on_confirm_new_game.bind(false, dialog))
	btn_container.add_child(no_btn)

func _on_confirm_new_game(confirmed: bool, dialog: Panel) -> void:
	dialog.queue_free()
	if confirmed:
		_start_new_game()

## Show upgrades panel
func _show_upgrades_panel() -> void:
	var panel := _create_upgrades_panel()
	add_child(panel)

func _create_upgrades_panel() -> Panel:
	var panel := Panel.new()
	panel.name = "UpgradesPanel"
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 0.1
	panel.anchor_bottom = 0.9
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.98)
	style.border_color = Color(0.5, 0.8, 1.0, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	# Title
	var title := Label.new()
	title.text = "⬆ KALICI YÜKSELTİLER"
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -150
	title.offset_right = 150
	title.offset_top = 15
	title.offset_bottom = 50
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0, 1.0))
	panel.add_child(title)
	
	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.offset_left = -50
	close_btn.offset_right = -15
	close_btn.offset_top = 10
	close_btn.offset_bottom = 40
	close_btn.pressed.connect(panel.queue_free)
	panel.add_child(close_btn)
	
	# Scroll container for upgrades
	var scroll := ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.anchor_left = 0.05
	scroll.anchor_right = 0.95
	scroll.anchor_top = 0.12
	scroll.anchor_bottom = 0.9
	panel.add_child(scroll)
	
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(800, 0)
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)
	
	# Add upgrade items
	for upgrade_id in PersistentUpgrades.UPGRADES.keys():
		var upgrade_def: Dictionary = PersistentUpgrades.UPGRADES[upgrade_id]
		var item := _create_upgrade_item(upgrade_id, upgrade_def)
		vbox.add_child(item)
	
	return panel

func _create_upgrade_item(upgrade_id: String, def: Dictionary) -> Panel:
	var item := Panel.new()
	item.custom_minimum_size = Vector2(0, 70)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.06, 0.1, 0.8)
	bg_style.border_color = Color(0.15, 0.15, 0.2, 0.5)
	bg_style.border_width_bottom = 1
	item.add_theme_stylebox_override("panel", bg_style)
	
	# Name
	var name_label := Label.new()
	name_label.text = def.get("icon", "•") + " " + def.get("name", upgrade_id)
	name_label.offset_left = 35
	name_label.offset_right = 250
	name_label.offset_top = 8
	name_label.offset_bottom = 28
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", ACCENT_COLOR)
	item.add_child(name_label)
	
	# Description
	var desc_label := Label.new()
	var current_value: float = persistent_upgrades.get_value(upgrade_id)
	desc_label.text = def.get("description", "").format({"value": "%.1f" % current_value})
	desc_label.offset_left = 15
	desc_label.offset_right = 500
	desc_label.offset_top = 28
	desc_label.offset_bottom = 50
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 1.0))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	item.add_child(desc_label)
	
	# Level indicator
	var level_label := Label.new()
	var current_level: int = persistent_upgrades.get_level(upgrade_id)
	var max_level: int = def.get("max_level", 1)
	level_label.text = "Lv.%d/%d" % [current_level, max_level]
	level_label.anchor_left = 1.0
	level_label.anchor_right = 1.0
	level_label.offset_left = -130
	level_label.offset_right = -15
	level_label.offset_top = 8
	level_label.offset_bottom = 28
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	item.add_child(level_label)
	
	# Buy button
	var buy_btn := Button.new()
	var cost: int = persistent_upgrades.get_upgrade_cost(upgrade_id)
	if cost < 0:
		buy_btn.text = "MAX"
		buy_btn.disabled = true
	else:
		buy_btn.text = "✦ %d" % cost
	buy_btn.anchor_left = 1.0
	buy_btn.anchor_right = 1.0
	buy_btn.offset_left = -130
	buy_btn.offset_right = -15
	buy_btn.offset_top = 32
	buy_btn.offset_bottom = 58
	buy_btn.custom_minimum_size = Vector2(115, 26)
	
	if not buy_btn.disabled:
		buy_btn.pressed.connect(_on_buy_upgrade.bind(upgrade_id))
	
	item.add_child(buy_btn)
	
	return item

func _on_buy_upgrade(upgrade_id: String) -> void:
	var cost: int = persistent_upgrades.get_upgrade_cost(upgrade_id)
	if cost < 0:
		return
	
	var player_gold: int = _get_player_gold()
	if player_gold < cost:
		_show_message("Yetersiz altin!")
		return
	
	if persistent_upgrades.purchase_upgrade(upgrade_id, float(cost)):
		# Refresh the panel
		var upgrades_panel := get_node_or_null("UpgradesPanel") as Panel
		if upgrades_panel:
			upgrades_panel.queue_free()
			add_child(_create_upgrades_panel())
		_show_message("Yükseltme alindi!")
	else:
		_show_message("Yükseltme alinamadi!")

## Show settings panel
func _show_settings_panel() -> void:
	var settings = GameSettings.get_instance()
	
	var panel := Panel.new()
	panel.name = "SettingsPanel"
	panel.anchor_left = 0.3
	panel.anchor_right = 0.7
	panel.anchor_top = 0.3
	panel.anchor_bottom = 0.7
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.98)
	style.border_color = Color(0.7, 0.7, 0.75, 0.8)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	
	# Title
	var title := Label.new()
	title.text = "⚙ AYARLAR"
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -100
	title.offset_right = 100
	title.offset_top = 15
	title.offset_bottom = 50
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1.0))
	panel.add_child(title)
	
	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.offset_left = -50
	close_btn.offset_right = -15
	close_btn.offset_top = 10
	close_btn.offset_bottom = 40
	close_btn.pressed.connect(panel.queue_free)
	panel.add_child(close_btn)
	
	# Settings content
	var content := VBoxContainer.new()
	content.anchor_left = 0.1
	content.anchor_right = 0.9
	content.anchor_top = 0.15
	content.anchor_bottom = 0.9
	content.add_theme_constant_override("separation", 15)
	panel.add_child(content)
	
	# Master volume
	var volume_row := _create_setting_row("Ses Seviyesi", "100%")
	content.add_child(volume_row)
	
	# Music volume
	var music_row := _create_setting_row("Müzik", "80%")
	content.add_child(music_row)
	
	# SFX volume
	var sfx_row := _create_setting_row("Efektler", "100%")
	content.add_child(sfx_row)
	
	# Fullscreen toggle
	var fs_row := _create_setting_toggle("Tam Ekran", settings.fullscreen, func(v): settings.set_fullscreen(v))
	content.add_child(fs_row)
	
	# VSync toggle
	var vsync_row := _create_setting_toggle("VSync", settings.vsync, func(v): settings.set_vsync(v))
	content.add_child(vsync_row)

func _create_setting_row(label_text: String, default_value: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 35)
	
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	row.add_child(label)
	
	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0
	slider.max_value = 100
	slider.value = 80
	row.add_child(slider)
	
	return row

func _create_setting_toggle(label_text: String, default_value: bool, callback: Callable = func(v): pass) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 35)
	
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	row.add_child(label)
	
	var check := CheckButton.new()
	check.button_pressed = default_value
eck.toggled.connect(callback)
	row.add_child(check)
	
	return row

## Show message popup
func _show_message(text: String) -> void:
	var msg := Label.new()
	msg.text = text
	msg.anchor_left = 0.5
	msg.anchor_right = 0.5
	msg.anchor_top = 0.8
	msg.anchor_bottom = 0.8
	msg.offset_left = -150
	msg.offset_right = 150
	msg.offset_top = -20
	msg.offset_bottom = 20
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 18)
	msg.add_theme_color_override("font_color", HIGHLIGHT_COLOR)
	msg.z_index = 100
	add_child(msg)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(msg, "modulate:a", 0.0, 2.0).set_delay(1.5)
	tween.tween_callback(msg.queue_free)

## Helper functions
func _get_player_gold() -> int:
	return persistent_upgrades.get_starting_gold()

func _has_save_file() -> bool:
	return FileAccess.file_exists("user://savegame.save")

func _format_number(num: float) -> String:
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	else:
		return str(int(num))

func _continue_game() -> void:
	persistent_upgrades.increment_games_played()
	continue_game.emit()

func _start_new_game() -> void:
	persistent_upgrades.increment_games_played()
	start_new_game.emit()
