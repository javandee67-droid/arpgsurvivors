extends Node
class_name GameSettings
## Game Settings Manager - Handles audio, graphics, and gameplay settings.
## Persists settings to file.

const SETTINGS_FILE := "user://settings.save"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = true
var vsync: bool = true
var show_fps: bool = false
var damage_numbers: bool = true
var screen_shake: bool = true
var auto_pickup: bool = true
var show_tips: bool = true

static var _instance: GameSettings = null
static func get_instance() -> GameSettings:
	if _instance == null:
		_instance = GameSettings.new()
		_instance.load_settings()
	return _instance

func _init() -> void:
	pass

func _ready() -> void:
	_instance = self
	load_settings()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE):
		_set_defaults()
		return
	
	var save_file := FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if save_file == null:
		_set_defaults()
		return
	
	var json_str := save_file.get_as_text()
	save_file.close()
	
	var json := JSON.new()
	if json.parse(json_str) != OK:
		_set_defaults()
		return
	
	var data: Dictionary = json.data
	if data.is_empty():
		_set_defaults()
		return
	
	master_volume = data.get("master_volume", 1.0)
	music_volume = data.get("music_volume", 0.8)
	sfx_volume = data.get("sfx_volume", 1.0)
	fullscreen = data.get("fullscreen", true)
	vsync = data.get("vsync", true)
	show_fps = data.get("show_fps", false)
	damage_numbers = data.get("damage_numbers", true)
	screen_shake = data.get("screen_shake", true)
	auto_pickup = data.get("auto_pickup", true)
	show_tips = data.get("show_tips", true)
	
	_apply_settings()
	print("Settings loaded!")

func save_settings() -> void:
	var save_data := {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"vsync": vsync,
		"show_fps": show_fps,
		"damage_numbers": damage_numbers,
		"screen_shake": screen_shake,
		"auto_pickup": auto_pickup,
		"show_tips": show_tips,
	}
	
	var save_file := FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if save_file == null:
		push_error("Cannot save settings: " + str(FileAccess.get_open_error()))
		return
	
	var json_str := JSON.stringify(save_data, "\t")
	save_file.store_line(json_str)
	save_file.close()
	print("Settings saved!")

func _set_defaults() -> void:
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 1.0
	fullscreen = true
	vsync = true
	show_fps = false
	damage_numbers = true
	screen_shake = true
	auto_pickup = true
	show_tips = true
	_apply_settings()

func _apply_settings() -> void:
	# Apply audio
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_volume)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_volume)
	)
	
	# Apply graphics
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_VSYNC, vsync)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func set_master_volume(value: float) -> void:
	master_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume)
	)
	save_settings()

func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_volume)
	)
	save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_volume)
	)
	save_settings()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	save_settings()

func set_vsync(value: bool) -> void:
	vsync = value
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_VSYNC, vsync)
	save_settings()

func set_show_fps(value: bool) -> void:
	show_fps = value
	save_settings()

func set_damage_numbers(value: bool) -> void:
	damage_numbers = value
	save_settings()

func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()

func set_auto_pickup(value: bool) -> void:
	auto_pickup = value
	save_settings()

func set_show_tips(value: bool) -> void:
	show_tips = value
	save_settings()
