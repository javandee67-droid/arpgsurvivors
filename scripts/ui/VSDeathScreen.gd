extends CanvasLayer
class_name VSDeathScreen
## Vampire Survivors tarzi olum ekrani.
## Karakter olunce "Respawn" yazisi gosterir, tiklayinca oyun en bastan baslar.

signal respawn_requested

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	# Karartma
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	var vp_size := get_viewport().get_visible_rect().size
	
	# "Öldün!" yazisi
	var death_label := Label.new()
	death_label.text = "ÖLDÜN!"
	death_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15))
	death_label.add_theme_font_size_override("font_size", 48)
	death_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	death_label.add_theme_constant_override("shadow_outline_size", 3)
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	death_label.position = Vector2(0, vp_size.y * 0.3)
	death_label.size = Vector2(vp_size.x, 60)
	add_child(death_label)
	
	# Stats
	var stats_label := Label.new()
	stats_label.name = "StatsLabel"
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.position = Vector2(0, vp_size.y * 0.3 + 70)
	stats_label.size = Vector2(vp_size.x, 80)
	add_child(stats_label)
	
	# Respawn butonu
	var respawn_btn := Button.new()
	respawn_btn.name = "RespawnButton"
	respawn_btn.text = "TEKRAR DENE"
	respawn_btn.size = Vector2(240, 50)
	respawn_btn.position = Vector2(vp_size.x / 2 - 120, vp_size.y * 0.6)
	
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.05, 0.05, 0.9)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.8, 0.2, 0.2, 0.8)
	respawn_btn.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.25, 0.08, 0.08, 0.95)
	style_hover.border_color = Color(1.0, 0.3, 0.3, 1.0)
	respawn_btn.add_theme_stylebox_override("hover", style_hover)
	
	respawn_btn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.6))
	respawn_btn.add_theme_font_size_override("font_size", 18)
	
	respawn_btn.pressed.connect(func(): respawn_requested.emit())
	add_child(respawn_btn)

func set_stats(level: int, kills: int, time_survived: float) -> void:
	var stats_label := get_node_or_null("StatsLabel") as Label
	if stats_label:
		var minutes: int = int(time_survived) / 60
		var seconds: int = int(time_survived) % 60
		stats_label.text = "Seviye: %d | Öldürülen: %d\nHayatta Kalma: %d:%02d" % [level, kills, minutes, seconds]
