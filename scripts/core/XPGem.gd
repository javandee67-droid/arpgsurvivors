extends Area2D
class_name XPGem## DuskForged XP kristali.i.
## Düşman ölünce düşer, oyuncuya doğru çekilir (magnet), toplanınca XP verir.

var xp_value: float = 10.0
var _magnet_speed: float = 280.0
var _base_magnet_range: float = 60.0
var _player_ref: Node = null
var _being_attracted: bool = false
var _lifetime: float = 15.0
var _alive_time: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)

	var tex_path := "res://assets/generated/icon_gem_frame_0.png"
	var sprite := Sprite2D.new()
	sprite.name = "GemSprite"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path) as Texture2D
		sprite.scale = Vector2(0.8, 0.8)
	else:
		sprite.texture = _create_fallback_texture()
		sprite.scale = Vector2(1.0, 1.0)
	add_child(sprite)

	var glow := Sprite2D.new()
	glow.name = "GlowSprite"
	if ResourceLoader.exists(tex_path):
		glow.texture = load(tex_path) as Texture2D
	else:
		glow.texture = _create_fallback_texture()
	glow.scale = Vector2(2.0, 2.0)
	glow.modulate = Color(0.8, 0.9, 0.4, 0.2)
	add_child(glow)

	_player_ref = get_tree().get_first_node_in_group("player")

func _create_fallback_texture() -> Texture2D:
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	for x in range(12):
		for y in range(12):
			var dx := (x - 5.5) / 5.5
			var dy := (y - 5.5) / 5.5
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, Color(0.3, 1.0, 0.2, 1.0))
			elif dx * dx + dy * dy <= 1.5:
				img.set_pixel(x, y, Color(0.3, 1.0, 0.2, 0.3))
	return ImageTexture.create_from_image(img)

func _get_magnet_range() -> float:
	# Oyuncunun pickup_radius stat'ını kullan
	var base_range := _base_magnet_range
	if is_instance_valid(_player_ref) and _player_ref.has_node("CharacterStats"):
		var stats := _player_ref.get_node("CharacterStats") as CharacterStats
		base_range += stats.pickup_radius
	return base_range

func _process(delta: float) -> void:
	_alive_time += delta

	var sprite := get_node_or_null("GemSprite") as Sprite2D
	if sprite:
		var bob := sin(_alive_time * 3.0) * 2.0
		sprite.position.y = bob

	# 3 saniye kala yanıp sönme
	if _lifetime - _alive_time < 3.0:
		if sprite:
			var flash := sin(_alive_time * 12.0) * 0.3 + 0.7
			sprite.modulate.a = flash
	elif _alive_time > _lifetime:
		if is_instance_valid(self):
			queue_free()
		return

	if not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(_player_ref):
			return

	var dist := global_position.distance_to(_player_ref.global_position)
	var magnet_range := _get_magnet_range()

	# Otomatik çekim - pickup_radius'a göre
	if dist < magnet_range:
		_being_attracted = true

	if _being_attracted:
		var dir: Vector2 = (_player_ref.global_position - global_position).normalized()
		# Yakınlık arttıkça hızlan
		var speed_mult := 1.0 + (magnet_range - minf(dist, magnet_range)) / magnet_range * 2.0
		var speed := _magnet_speed * speed_mult
		global_position += dir * speed * delta

		if dist < 20.0:
			_collect()

func _collect() -> void:
	if not is_instance_valid(_player_ref):
		queue_free()
		return

	var player := _player_ref as Node
	if player.has_node("LevelSystem"):
		var ls := player.get_node("LevelSystem") as LevelSystem
		ls.add_xp(xp_value)

	var sprite := get_node_or_null("GemSprite") as Sprite2D
	if sprite:
		var orig_scale := sprite.scale
		var tw := create_tween().set_parallel(true)
		tw.tween_property(sprite, "scale", orig_scale * 3.0, 0.15)
		tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
		await tw.finished

	if is_instance_valid(self):
		queue_free()

func setup(amount: float, pos: Vector2) -> void:
	xp_value = amount
	global_position = pos + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))

	var scatter_dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var scatter_dist := randf_range(15.0, 35.0)
	var target_pos := global_position + scatter_dir * scatter_dist

	var tw := create_tween()
	tw.tween_property(self, "global_position", target_pos, 0.2).set_ease(Tween.EASE_OUT)
