extends Node2D
class_name OrbitalProjectile
## Boss etrafında dönen ateş topları. Oyuncu menzile girince sırayla fırlatılır.

var orbit_radius: float = 80.0       ## Boss etrafındaki dönüş yarıçapı
var orbit_speed: float = 1.5         ## Dönüş hızı (rad/sn)
var angle_offset: float = 0.0        ## Bu orb'un açısal offset'i
var fire_speed: float = 400.0        ## Fırlatılınca hızı
var damage_pct: float = 0.8          ## Boss base damage'in yüzdesi
var damage_type: String = "fire"
var boss: Node = null                ## Bağlı olduğu boss
var is_fired: bool = false           ## Fırlatıldı mı?
var fired_target: Vector2 = Vector2.ZERO
var hit_tex: String = "res://assets/generated/fx_fire_explosion.png"

var _exploded: bool = false
var _lifetime: float = 0.0           ## Fırlatıldıktan sonra geçen süre
const MAX_LIFETIME: float = 15.0     ## 15 saniye sonra otomatik kaybol

func _ready() -> void:
	# Animasyonlu sprite yükle
	$AnimatedSprite2D.visible = true
	$AnimatedSprite2D.play("default")
	# Ateş toplarını daha küçük göster (128px yerine ~40px)
	$AnimatedSprite2D.scale = Vector2(0.3, 0.3)

func _process(delta: float) -> void:
	if is_fired:
		if _exploded:
			return
		# Süre sayacı — 15 saniye sonra kaybol
		_lifetime += delta
		if _lifetime >= MAX_LIFETIME:
			queue_free()
			return
		# Sürekli oyuncuyu kovala (homing)
		var player: Node = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var target_pos: Vector2 = player.global_position
			var dir: Vector2 = (target_pos - global_position).normalized()
			global_position += dir * fire_speed * delta
			var dist: float = global_position.distance_to(target_pos)
			if dist < 20.0:
				_explode(player)
		return
	
	# Dönme hareketi
	if boss and is_instance_valid(boss):
		angle_offset += orbit_speed * delta
		var cx: float = boss.global_position.x
		var cy: float = boss.global_position.y
		global_position = Vector2(
			cx + cos(angle_offset) * orbit_radius,
			cy + sin(angle_offset) * orbit_radius
		)
		
		# Oyuncu menzilde mi kontrol et
		var player: Node = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var dist_to_player: float = boss.global_position.distance_to(player.global_position)
			if dist_to_player < 200.0 and not is_fired:
				pass

func fire_at(target_pos: Vector2) -> void:
	if is_fired:
		return
	is_fired = true
	fired_target = target_pos
	_lifetime = 0.0
	# Dönme animasyonu durup ileri atılma efekti
	$AnimatedSprite2D.speed_scale = 2.0

func _explode(player: Node) -> void:
	if _exploded:
		return
	_exploded = true
	
	# Patlama efekti
	if hit_tex != "" and ResourceLoader.exists(hit_tex):
		var hit_spr := Sprite2D.new()
		hit_spr.texture = load(hit_tex) as Texture2D
		hit_spr.position = Vector2.ZERO
		hit_spr.z_index = 10
		add_child(hit_spr)
		# Kısa sürede kaybol
		var tween := create_tween()
		tween.tween_property(hit_spr, "modulate:a", 0.0, 0.3)
		tween.tween_callback(hit_spr.queue_free)
	
	# Oyuncuya hasar ver
	if player and is_instance_valid(player):
		var health: Health = player.get_node_or_null("Health")
		if health and boss:
			var boss_stats: CharacterStats = boss.get_node_or_null("CharacterStats")
			var base_dmg: float = boss_stats.strength * 3.0 if boss_stats else 50.0
			var final_dmg: float = base_dmg * damage_pct
			health.take_damage(final_dmg, boss, ["attack", "fire", "projectile"], false)
	
	# Görsel olarak kaybol
	$AnimatedSprite2D.visible = false
	var t2 := create_tween()
	t2.tween_interval(0.4)
	t2.tween_callback(queue_free)