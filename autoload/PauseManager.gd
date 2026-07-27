extends Node
class_name PauseManager

# Pause manager: handles pause input and shows a simple pause UI.

# Input action name
const PAUSE_ACTION := "ui_pause"

# Reference to our pause UI (CanvasLayer)
var pause_ui: CanvasLayer = null
var is_paused_by_me: bool = false

func _ready() -> void:
	# Ensure we are added to the scene tree (autoload ensures this)
	# Connect to input? We'll use _unhandled_input.
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not get_tree():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed(PAUSE_ACTION):
			_toggle_pause()
			event.set_handled(true)

func _toggle_pause() -> void:
	var tree = get_tree()
	if not tree:
		return
	if tree.paused:
		# Game is already paused (by some other system). We do not toggle.
		return
	# Toggle our own pause state
	if is_paused_by_me:
		# We were paused, now unpause
		_pause_ui_hide()
	else:
		# We were not paused, now pause
		_pause_ui_show()
		
func _pause_ui_show() -> void:
	var tree = get_tree()
	if not tree:
		return
	if tree.paused:
		# Already paused by something else, do not show our UI
		return
	# Create pause UI if not already created
	if not pause_ui:
		pause_ui = _create_pause_ui()
		# Add to root (ensure we are above everything)
		tree.root.add_child(pause_ui)
		pause_ui.visible = true
		is_paused_by_me = true
		tree.paused = true
		# Optional: set pause_ui to a specific layer
		pause_ui.layer = 100  # high layer

func _pause_ui_hide() -> void:
	if not pause_ui:
		return
	pause_ui.visible = false
	is_paused_by_me = false
	get_tree().paused = false
	# Optionally remove from tree? We'll keep it hidden for reuse.
	# pause_ui.queue_free()  # if we want to create fresh each time
	# pause_ui = null

func _create_pause_ui() -> CanvasLayer:
	var ui := CanvasLayer.new()
	ui.name = "PauseUI"
	ui.layer = 100
	ui.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Background panel
	var bg := Panel.new()
	bg.name = "Background"
	bg.size = Vector2(400, 300)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_bottom = -100  # adjust to center later
	bg.offset_right = -200
	bg.margin_left = 100
	bg.margin_top = 100
	bg.margin_right = 100
	bg.margin_bottom = 100
	# Center it
	bg.anchor_left = 0.5
	bg.anchor_top = 0.5
	bg.offset_left = -200
	bg.offset_top = -150
	bg.margin_left = 0
	bg.margin_top = 0
	bg.margin_right = 0
	bg.margin_bottom = 0
	# Actually simpler: set rect_min_size and center via anchors
	# Let's do a simpler approach: set size and align center
	bg.size = Vector2(400, 300)
	bg.anchor_left = 0.5
	bg.anchor_top = 0.5
	bg.anchor_right = 0.5
	bg.anchor_bottom = 0.5
	bg.offset_left = -200
	bg.offset_top = -150
	bg.offset_right = 200
	bg.offset_bottom = 150
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.0, 0.0, 0.0, 0.8)
	bg_style.border_width_all = 2
	bg_style.border_color = Color(0.8, 0.8, 0.8)
	bg_style.set_corner_radius_all(8)
	bg.add_theme_stylebox_override("panel", bg_style)
	
	ui.add_child(bg)
	
	# Title label
	var title := Label.new()
	title.name = "Title"
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	title.anchor_left = 0.5
	title.anchor_top = 0.5
	title.offset_left = 0
	title.offset_top = -100
	title.anchor_right = 0.5
	title.anchor_bottom = 0.5
	title.add_theme_constant_override("alignment", 2)  # center
	ui.add_child(title)
	
	# Resume button
	var btn_resume := Button.new()
	btn_resume.name = "ResumeButton"
	btn_resume.text = "Resume"
	btn_resume.anchor_left = 0.5
	btn_resume.anchor_top = 0.5
	btn_resume.offset_left = -100
	btn_resume.offset_top = -20
	btn_resume.anchor_right = 0.5
	btn_resume.anchor_bottom = 0.5
	btn_resume.offset_right = 100
	btn_resume.offset_bottom = 80
	btn_resume.size = Vector2(200, 50)
	btn_resume.add_theme_font_size_override("font_size", 20)
	btn_resume.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.3, 0.4, 0.8)
	btn_style.border_width_all = 2
	btn_style.border_color = Color(0.6, 0.7, 0.8)
	btn_style.set_corner_radius_all(4)
	btn_resume.add_theme_stylebox_override("normal", btn_style)
	btn_resume.pressed.connect(_on_resume_pressed)
	ui.add_child(btn_resume)
	
	# Settings button
	var btn_settings := Button.new()
	btn_settings.name = "SettingsButton"
	btn_settings.text = "Settings"
	btn_settings.anchor_left = 0.5
	btn_settings.anchor_top = 0.5
	btn_settings.offset_left = -100
	btn_settings.offset_top = 60
	btn_settings.anchor_right = 0.5
	btn_settings.anchor_bottom = 0.5
	btn_settings.offset_right = 100
	btn_settings.offset_bottom = 140
	btn_settings.size = Vector2(200, 50)
	btn_settings.add_theme_font_size_override("font_size", 20)
	btn_settings.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	btn_settings.add_theme_stylebox_override("normal", btn_style.duplicate())
	btn_settings.pressed.connect(_on_settings_pressed)
	ui.add_child(btn_settings)
	
	# Quit button
	var btn_quit := Button.new()
	btn_quit.name = "QuitButton"
	btn_quit.text = "Quit"
	btn_quit.anchor_left = 0.5
	btn_quit.anchor_top = 0.5
	btn_quit.offset_left = -100
	btn_quit.offset_top = 140
	btn_quit.anchor_right = 0.5
	btn_quit.anchor_bottom = 0.5
	btn_quit.offset_right = 100
	btn_quit.offset_bottom = 220
	btn_quit.size = Vector2(200, 50)
	btn_quit.add_theme_font_size_override("font_size", 20)
	btn_quit.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	btn_quit.add_theme_stylebox_override("normal", btn_style.duplicate())
	btn_quit.pressed.connect(_on_quit_pressed)
	ui.add_child(btn_quit)
	
	return ui

func _on_resume_pressed() -> void:
	_pause_ui_hide()

func _on_settings_pressed() -> void:
	# TODO: open settings UI
	print("Settings button pressed (not implemented)")
	# For now, just close pause and maybe open settings later
	_pause_ui_hide()

func _on_quit_pressed() -> void:
	get_tree().quit()
