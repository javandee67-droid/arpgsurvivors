extends CanvasLayer
class_name FloatingDamage
## Hasar numaraları ve level-up efektleri gösterir.
## EventBus üzerinden gelen olayları dinler ve ekranda gösterir.

var player: Node = null

func _ready() -> void:
	layer = 60  # Her şeyin üstünde
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_damage_dealt(payload: Dictionary) -> void:
	# Only show numbers when the player hits enemies, NOT when enemies hit the player
	var target: Node = payload.get("target", null)
	if target and target.is_in_group("player"):
		return
	var pos: Vector2 = payload.get("position", Vector2.ZERO)
	if pos == Vector2.ZERO:
		return
	var amount: float = payload.get("amount", 0.0)
	if amount <= 0.0:
		return
	var is_crit: bool = payload.get("is_crit", false)
	
	# Düşmana hit flash efekti uygula
	if target and target.has_method("do_hit_flash"):
		var damage_types: Array = payload.get("damage_types", ["physical"])
		var dmg_type: String = damage_types[0] if damage_types.size() > 0 else "physical"
		target.do_hit_flash(dmg_type)
	
	_spawn_number(pos, amount, is_crit)

func _on_enemy_killed(_enemy: Node) -> void:
	pass

func _spawn_number(pos: Vector2, amount: float, is_crit: bool) -> void:
	var lbl := Label.new()
	
	# 0 hasar gösterme — eğer hasar 1'den küçükse en az "1" göster
	var display_amount: int = maxi(1, int(amount))
	
	var cam := get_viewport().get_camera_2d()
	
	# Normal hasar
	var font_size := 18
	var text_color := Color(1.0, 0.75, 0.2)  # Sıcak turuncu-altın
	var outline_size := 1
	var outline_color := Color(0.0, 0.0, 0.0, 0.7)
	var float_distance := 45.0
	var start_scale := 0.6
	
	if is_crit:
		lbl.text = str(display_amount) + "!"
		font_size = 28
		text_color = Color(1.0, 0.9, 0.1)       # Parlak altın
		outline_size = 3
		outline_color = Color(0.0, 0.0, 0.0, 0.85)
		float_distance = 55.0
		start_scale = 0.4
	else:
		lbl.text = str(display_amount)
	
	lbl.add_theme_color_override("font_color", text_color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_constant_override("outline_size", outline_size)
	lbl.add_theme_color_override("font_outline_color", outline_color)
	
	# Konum: dünya koordinatını ekran koordinatına çevir
	var final_pos: Vector2 = pos
	if cam and is_instance_valid(cam):
		final_pos = cam.get_canvas_transform() * pos
	final_pos += Vector2(randf_range(-25, 25), randf_range(-15, -5))
	
	lbl.position = final_pos
	lbl.size = Vector2(60, 24)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.pivot_offset = Vector2(30, 12)  # Merkezden scale/büyüme için
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Tıklanabilir alan oluşturmasın
	
	lbl.scale = Vector2(start_scale, start_scale)
	
	add_child(lbl)
	
	# Rastgele hafif yatay sürüklenme
	var drift_x := randf_range(-12.0, 12.0)
	
	# Animasyon: pop-in + yukarı çık + kaybol
	var tw := create_tween()
	tw.set_parallel(true)
	
	# Scale bounce (pop-in efekti)
	var target_scale := 1.15 if is_crit else 1.08
	tw.tween_property(lbl, "scale", Vector2(target_scale, target_scale), 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.12).set_ease(Tween.EASE_IN)
	
	# Yukarı çık + hafif yana sürüklen
	tw.tween_property(lbl, "position:y", final_pos.y - float_distance, 0.9).set_delay(0.05).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "position:x", final_pos.x + drift_x, 0.9).set_delay(0.05).set_ease(Tween.EASE_OUT)
	
	# Kaybolma (crit'te daha geç)
	var fade_delay := 0.4 if is_crit else 0.3
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(fade_delay)
	
	tw.tween_callback(lbl.queue_free).set_delay(1.3)

## Level-up efekti
func show_level_up(new_level: int) -> void:
	var lbl := Label.new()
	lbl.text = "SEVİYE ATLADIN! (%d)" % new_level
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	
	var vp := get_viewport().get_visible_rect().size
	lbl.position = Vector2(vp.x / 2 - 150, vp.y / 2 - 60)
	lbl.size = Vector2(300, 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	add_child(lbl)
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", lbl.position.y - 30, 1.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.8)
	tw.tween_callback(lbl.queue_free).set_delay(2.0)
