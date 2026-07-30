extends Area2D
class_name Projectile
## Advanced projectile with pierce, chain, fork, and area damage support.
## SkillController tarafından oluşturulur; mermi sprite'ı ve çarpma efekti
## skill tipine göre dinamik olarak atanır.

@export var speed: float = 400.0
@export var lifetime: float = 2.0
@export var pierce_count: int = 0        ## Number of enemies pierced before destruction
@export var chain_count: int = 0         ## Number of chains (to nearest enemy)
@export var fork_count: int = 0          ## Number of forks (split on hit)
@export var area_damage_radius: float = 0.0  ## If > 0, deals area damage on hit

## Hangi skill'den geldiği (sprite/efekt seçimi için)
var skill_id: String = ""
## Çarpınca spawnlanacak hit efektinin texture yolu
var hit_effect_texture: String = ""
## Hit efektinin frame bilgileri (vfx animasyonu için)
var hit_effect_fw: int = 48
var hit_effect_fh: int = 48
var hit_effect_cols: int = 4
var hit_effect_count: int = 16

var _velocity: Vector2 = Vector2.ZERO
var _damage: float = 0.0
var _tags: Array[String] = []
var _source: Node = null
var _remaining_pierce: int = 0
var _remaining_chain: int = 0
var _remaining_fork: int = 0
var _hit_bodies: Array[Node] = []  ## Track hit bodies to avoid double-hitting
var _is_crit: bool = false
var _ailment_power_override: float = 0.0
var _damage_type: String = "physical"

## Pulse/time for breathing visual effect
var _pulse_time: float = 0.0
## Breathing effect is ENABLED
var _breathing_enabled: bool = false

## Breathing & trail parametreleri (skill tipine göre _setup_skill_effects'te doldurulur)
var _breathing_speed: float = 8.0
var _breathing_amp: float = 0.08
var _wobble_speed: float = 3.0
var _wobble_amp: float = 0.05
var _trail_color: Color = Color(1.0, 0.6, 0.2, 0.5)
var _trail_scale_min: float = 0.1
var _trail_scale_max: float = 0.25
var _trail_vel_min: float = 10.0
var _trail_vel_max: float = 30.0
var _trail_lifetime: float = 0.3
var _trail_amount: int = 8

## Animasyonlu mermi sprite'ı için frame bilgileri
var proj_anim_tex: String = ""       ## Spritesheet texture yolu
var proj_anim_fw: int = 32           ## Her frame genişliği
var proj_anim_fh: int = 32           ## Her frame yüksekliği
var proj_anim_cols: int = 4          ## Spritesheet'teki sütun sayısı
var proj_anim_count: int = 8         ## Toplam frame sayısı
var proj_anim_fps: float = 10.0      ## Animasyon hızı

@onready var _anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _trail_particles: GPUParticles2D = $GPUParticles2D

func setup(target_position: Vector2, damage: float, tags: Array[String], source: Node = null,
		texture_path: String = "", hit_effect_path: String = "", skill: String = "",
		is_crit: bool = false, ailment_power: float = 0.0, damage_type: String = "physical") -> void:
	_damage = damage
	_tags = tags
	_source = source
	skill_id = skill
	_is_crit = is_crit
	_ailment_power_override = ailment_power
	_damage_type = damage_type
	_remaining_pierce = pierce_count
	_remaining_chain = chain_count
	_remaining_fork = fork_count
	_velocity = (target_position - global_position).normalized() * speed
	rotation = _velocity.angle()
	_hit_bodies.clear()

	# Mermi sprite'ını değiştir (eğer verilmişse)
	if texture_path != "":
		_setup_projectile_sprite(texture_path)
	# Çarpma efekti
	if hit_effect_path != "" and ResourceLoader.exists(hit_effect_path):
		hit_effect_texture = hit_effect_path

	# HER skill için breath efekti + trail partikülleri (skill_id'ye göre özelleştirilmiş)
	_breathing_enabled = true
	_setup_skill_effects(skill)

## Skill ID'sine göre breathing ve trail efektlerini ayarla
func _setup_skill_effects(skill: String) -> void:
	match skill:
		"fire_bolt":
			# Ateş oku: kırmızı-turuncu trail, hızlı nefes (8x)
			_breathing_speed = 8.0
			_breathing_amp = 0.08
			_wobble_speed = 3.0
			_wobble_amp = 0.05
			_trail_color = Color(1.0, 0.6, 0.2, 0.5)
			_trail_scale_min = 0.1
			_trail_scale_max = 0.25
			_trail_vel_min = 10.0
			_trail_vel_max = 30.0
			_trail_lifetime = 0.3
			_trail_amount = 8
		"fireball":
			# Fireball: daha küçük boyut, daha yavaş nefes
			_breathing_speed = 6.0
			_breathing_amp = 0.03
			_wobble_speed = 2.0
			_wobble_amp = 0.03
			_trail_color = Color(1.0, 0.6, 0.2, 0.4)
			_trail_scale_min = 0.06
			_trail_scale_max = 0.15
			_trail_vel_min = 8.0
			_trail_vel_max = 20.0
			_trail_lifetime = 0.2
			_trail_amount = 6
		"ice_shard":
			# Buz: mavi-beyaz trail, yavaş nefes, dönüş
			_breathing_speed = 5.0
			_breathing_amp = 0.05
			_wobble_speed = 2.0
			_wobble_amp = 0.03
			_trail_color = Color(0.5, 0.8, 1.0, 0.4)
			_trail_scale_min = 0.08
			_trail_scale_max = 0.2
			_trail_vel_min = 8.0
			_trail_vel_max = 25.0
			_trail_lifetime = 0.4
			_trail_amount = 6
		"slice_wave", "whirlwind":
			# Rüzgar/Kesme: soluk mavi-beyaz trail, hızlı
			_breathing_speed = 10.0
			_breathing_amp = 0.06
			_wobble_speed = 4.0
			_wobble_amp = 0.04
			_trail_color = Color(0.6, 0.9, 1.0, 0.3)
			_trail_scale_min = 0.05
			_trail_scale_max = 0.15
			_trail_vel_min = 15.0
			_trail_vel_max = 35.0
			_trail_lifetime = 0.2
			_trail_amount = 5
		"arcane_orb":
			# Gizem: mor trail, yavaş nefes
			_breathing_speed = 6.0
			_breathing_amp = 0.07
			_wobble_speed = 2.5
			_wobble_amp = 0.04
			_trail_color = Color(0.7, 0.3, 1.0, 0.4)
			_trail_scale_min = 0.1
			_trail_scale_max = 0.2
			_trail_vel_min = 5.0
			_trail_vel_max = 20.0
			_trail_lifetime = 0.5
			_trail_amount = 7
		"toxic_circle":
			# Zehir: yeşil trail
			_breathing_speed = 7.0
			_breathing_amp = 0.06
			_wobble_speed = 3.0
			_wobble_amp = 0.03
			_trail_color = Color(0.3, 0.8, 0.2, 0.4)
			_trail_scale_min = 0.08
			_trail_scale_max = 0.2
			_trail_vel_min = 8.0
			_trail_vel_max = 22.0
			_trail_lifetime = 0.35
			_trail_amount = 6
		"dark_beam":
			# Karanlık: mor-siyah trail
			_breathing_speed = 6.0
			_breathing_amp = 0.05
			_wobble_speed = 2.5
			_wobble_amp = 0.02
			_trail_color = Color(0.4, 0.1, 0.6, 0.4)
			_trail_scale_min = 0.1
			_trail_scale_max = 0.25
			_trail_vel_min = 6.0
			_trail_vel_max = 18.0
			_trail_lifetime = 0.4
			_trail_amount = 6
		"lightning_chain", "thunder_strike":
			# Yıldırım: parlak sarı trail
			_breathing_speed = 12.0
			_breathing_amp = 0.1
			_wobble_speed = 5.0
			_wobble_amp = 0.06
			_trail_color = Color(1.0, 0.9, 0.3, 0.5)
			_trail_scale_min = 0.1
			_trail_scale_max = 0.25
			_trail_vel_min = 12.0
			_trail_vel_max = 30.0
			_trail_lifetime = 0.25
			_trail_amount = 8
		"ice_nova", "frost_explosion":
			# Buz patlaması: buz mavisi trail, yavaş
			_breathing_speed = 5.0
			_breathing_amp = 0.06
			_wobble_speed = 2.0
			_wobble_amp = 0.03
			_trail_color = Color(0.3, 0.7, 1.0, 0.4)
			_trail_scale_min = 0.08
			_trail_scale_max = 0.2
			_trail_vel_min = 6.0
			_trail_vel_max = 20.0
			_trail_lifetime = 0.35
			_trail_amount = 6
		"holy_nova":
			# Kutsal: altın-sarı trail
			_breathing_speed = 7.0
			_breathing_amp = 0.07
			_wobble_speed = 3.0
			_wobble_amp = 0.04
			_trail_color = Color(1.0, 0.85, 0.3, 0.4)
			_trail_scale_min = 0.1
			_trail_scale_max = 0.2
			_trail_vel_min = 8.0
			_trail_vel_max = 22.0
			_trail_lifetime = 0.3
			_trail_amount = 6
		_:
			# Varsayılan: yumuşak beyaz trail, orta nefes
			_breathing_speed = 6.0
			_breathing_amp = 0.05
			_wobble_speed = 3.0
			_wobble_amp = 0.03
			_trail_color = Color(1.0, 1.0, 1.0, 0.3)
			_trail_scale_min = 0.08
			_trail_scale_max = 0.15
			_trail_vel_min = 8.0
			_trail_vel_max = 20.0
			_trail_lifetime = 0.3
			_trail_amount = 5
	
	_setup_trail_from_params()

## Trail partiküllerini _setup_skill_effects'te atanan parametrelerle oluştur
func _setup_trail_from_params() -> void:
	if not _trail_particles or not _anim_sprite or not _anim_sprite.sprite_frames:
		return
	var first_tex: Texture2D = _anim_sprite.sprite_frames.get_frame_texture("default", 0)
	if not first_tex:
		return

	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3.ZERO
	pm.initial_velocity_min = _trail_vel_min
	pm.initial_velocity_max = _trail_vel_max
	pm.scale_min = _trail_scale_min
	pm.scale_max = _trail_scale_max
	pm.color = _trail_color

	_trail_particles.process_material = pm
	_trail_particles.texture = first_tex
	_trail_particles.emitting = true
	_trail_particles.one_shot = false
	_trail_particles.lifetime = _trail_lifetime
	_trail_particles.amount = _trail_amount

## Mermi sprite'ını ayarla — animasyonlu spritesheet varsa AnimatedSprite2D kullan, yoksa statik texture ata
func _setup_projectile_sprite(texture_path: String) -> void:
	# Önce animasyon metadata'sını dene (aynı dizinde aynı isimde .metadata.json)
	var meta_path: String = texture_path.get_basename() + ".metadata.json"
	if ResourceLoader.exists(meta_path):
		# Animasyonlu spritesheet — metadata'dan frame bilgilerini al
		var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
		if file:
			var json_str: String = file.get_as_text()
			file.close()
			var json: Variant = JSON.parse_string(json_str)
			if json is Dictionary:
				var fw: int = json.get("frame_width", proj_anim_fw)
				var fh: int = json.get("frame_height", proj_anim_fh)
				var cols: int = json.get("columns", proj_anim_cols)
				var cnt: int = json.get("frame_count", proj_anim_count)
				var fps: float = json.get("fps", proj_anim_fps)
				_apply_anim_frames(texture_path, fw, fh, cols, cnt, fps)
				return

	# Animasyon yoksa veya metadata yoksa — statik AnimatedSprite2D olarak ayarla
	if ResourceLoader.exists(texture_path):
		var tex: Texture2D = load(texture_path)
		if tex:
			# Tek frame'li basit bir animasyon oluştur
			var frames := SpriteFrames.new()
			if not frames.has_animation("default"):
				frames.add_animation("default")
			frames.set_animation_loop("default", false)
			frames.add_frame("default", tex)
			_anim_sprite.sprite_frames = frames
			_anim_sprite.animation = "default"
			_anim_sprite.play()

## Spritesheet'i frame'lere böl ve AnimatedSprite2D'ye uygula
func _apply_anim_frames(tex_path: String, fw: int, fh: int, cols: int, count: int, fps: float) -> void:
	var tex: Texture2D = ResourceLoader.load(tex_path)
	if not tex:
		return
	var frames := SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_loop("default", true)
	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame("default", at, 1.0 / fps)
	_anim_sprite.sprite_frames = frames
	_anim_sprite.animation = "default"
	_anim_sprite.play()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta

func _process(delta: float) -> void:
	if not _breathing_enabled:
		return
	_pulse_time += delta
	# Skill'e özel nefes efekti (büyüyüp küçülme)
	var breathe: float = 1.0 + sin(_pulse_time * _breathing_speed) * _breathing_amp
	_anim_sprite.scale = Vector2.ONE * breathe
	# Skill'e özel sallanma efekti
	_anim_sprite.rotation = sin(_pulse_time * _wobble_speed) * _wobble_amp

func _on_body_entered(body: Node) -> void:
	if body == _source or _hit_bodies.has(body):
		return

	# If source is enemy, projectile hits player; if source is player, hits enemy
	if _source and _source.is_in_group("enemy"):
		if not body.is_in_group("player") and not body.is_in_group("enemy"):
			return
	elif _source and _source.is_in_group("player"):
		if not body.is_in_group("enemy"):
			return
	else:
		# Fallback: hit anything with Health
		if not body.has_node("Health"):
			return

	if body.has_node("Health"):
		var health: Health = body.get_node("Health")
		# Accuracy check for player projectiles (not spells)
		var final_damage: float = _damage
		var is_miss: bool = false
		var attacker_stats: CharacterStats = get_meta("attacker_stats") as CharacterStats if has_meta("attacker_stats") else null
		if attacker_stats and body.has_node("CharacterStats"):
			var defender_stats: CharacterStats = body.get_node("CharacterStats") as CharacterStats
			var is_spell: bool = _tags.has("spell")
			if not is_spell:
				var dmg_type: String = _damage_type if _damage_type != "" else "physical"
				var hit_result: Dictionary = CombatEngine.calculate_hit(attacker_stats, defender_stats, _damage, dmg_type, _tags, is_spell)
				if not hit_result.hit:
					is_miss = true
				else:
					final_damage = hit_result.damage
		if is_miss:
			_spawn_miss_effect(body.global_position)
			_hit_bodies.append(body)
			# Destroy projectile on miss unless it has pierce
			if _remaining_pierce <= 0:
				queue_free()
			else:
				_remaining_pierce -= 1
			return
		# Source ölmüş/çözülmüş olabilir (player ölüp doğunca). Freed node'u argüman geçmek crash yapar.
		var valid_source: Node = _source if (is_instance_valid(_source)) else null
		# Penetration varsa CombatEngine'den gelen hit_result'u kullanarak hesapla
		var pen: float = 0.0
		if attacker_stats:
			match _damage_type:
				"fire": pen = attacker_stats.penetration_fire
				"cold": pen = attacker_stats.penetration_cold
				"lightning": pen = attacker_stats.penetration_lightning
				"chaos": pen = attacker_stats.penetration_chaos
			if _damage_type in ["fire", "cold", "lightning"] and attacker_stats.penetration_elemental > pen:
				pen = attacker_stats.penetration_elemental
		health.take_damage(final_damage, valid_source, _tags, false, pen)
		# DPS takibi
		if valid_source and valid_source is Player and skill_id != "":
			EventBus.skill_damage.emit(skill_id, final_damage, _tags)
		_hit_bodies.append(body)

		# Vuruş anında player affix'lerini uygula (life_gain_on_hit, leech)
		if valid_source:
			Health.apply_on_hit_effects_to_attacker(valid_source, final_damage)

		# Çarpma efekti spawnla
		_spawn_hit_effect(body.global_position)

		# Apply ailments from tags
		_apply_ailments(body)

		# Area damage on hit
		if area_damage_radius > 0.0:
			_deal_area_damage(body.global_position)

		# Handle chain — oncelik: en yakin dusmana yon degistir
		if _remaining_chain > 0:
			_remaining_chain -= 1
			if _chain_to_nearest(body):
				print("CHAIN: ", skill_id, " -> ", body.name)
				return  # Hedef bulundu, yon degistir
			# Hedef bulunamadi — pierce/fork'a dus

		# Handle pierce — sadece chain kalmadiysa
		if _remaining_pierce > 0:
			_remaining_pierce -= 1
			return  ## Continue flying

		# Handle fork
		if _remaining_fork > 0:
			_remaining_fork -= 1
			_fork_projectiles()
			queue_free()
			return

	queue_free()

func _spawn_hit_effect(_pos: Vector2) -> void:
	# Yıldırım/hit_effect_texture varsa onu animasyonlu oynat
	if hit_effect_texture != "" and ResourceLoader.exists(hit_effect_texture):
		_spawn_texture_vfx(_pos, hit_effect_texture)
	# Kan efekti her vuruşta
	_spawn_blood_vfx(_pos)

func _spawn_texture_vfx(pos: Vector2, tex_path: String) -> void:
	"""Verilen texture path'indeki animasyonlu sprite'ı (metadata.json ile) çarpma noktasında oynat."""
	var tex: Texture2D = ResourceLoader.load(tex_path)
	if not tex:
		return
	# Metadata'dan frame bilgilerini oku
	var meta_path: String = tex_path.get_basename() + ".metadata.json"
	var fw: int = 64; var fh: int = 64; var cols: int = 6; var count: int = 6; var fps: float = 12.0
	if ResourceLoader.exists(meta_path):
		var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
		if file:
			var json_str: String = file.get_as_text()
			file.close()
			var json: Variant = JSON.parse_string(json_str)
			if json is Dictionary:
				fw = json.get("frame_width", fw)
				fh = json.get("frame_height", fh)
				cols = json.get("columns", cols)
				count = json.get("frame_count", count)
				fps = json.get("fps", fps)
	var frames := SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_loop("default", false)
	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame("default", at, 1.0 / fps)
	var vfx := AnimatedSprite2D.new()
	vfx.sprite_frames = frames
	vfx.animation = "default"
	vfx.play()
	vfx.global_position = pos
	vfx.z_index = 10
	get_tree().current_scene.add_child(vfx)
	vfx.animation_finished.connect(func(): if is_instance_valid(vfx): vfx.queue_free())

func _spawn_blood_vfx(pos: Vector2) -> void:
	"""Kucuk kan sıçraması efekti."""
	var blood_path: String = "res://assets/generated/hit_blood_splatter.png"
	if not ResourceLoader.exists(blood_path):
		return
	var meta_path: String = blood_path.get_basename() + ".metadata.json"
	var fw: int = 48; var fh: int = 48; var cols: int = 4; var count: int = 16; var fps: float = 12.0
	if ResourceLoader.exists(meta_path):
		var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
		if file:
			var json_str: String = file.get_as_text()
			file.close()
			var json: Variant = JSON.parse_string(json_str)
			if json is Dictionary:
				fw = json.get("frame_width", fw)
				fh = json.get("frame_height", fh)
				cols = json.get("columns", cols)
				count = json.get("frame_count", count)
				fps = json.get("fps", fps)
	var tex: Texture2D = ResourceLoader.load(blood_path)
	if not tex:
		return
	var frames := SpriteFrames.new()
	if not frames.has_animation("default"):
		frames.add_animation("default")
	frames.set_animation_loop("default", false)
	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame("default", at, 1.0 / fps)
	var blood := AnimatedSprite2D.new()
	blood.sprite_frames = frames
	blood.animation = "default"
	blood.play()
	blood.global_position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
	blood.z_index = 9
	blood.scale = Vector2(0.7, 0.7)
	get_tree().current_scene.add_child(blood)
	blood.animation_finished.connect(func(): if is_instance_valid(blood): blood.queue_free())

func _spawn_miss_effect(pos: Vector2) -> void:
	"""'Iska!' yazısı spawnla."""
	var label := Label.new()
	label.text = "Iska!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(0.8, 0.8, 0.8, 1.0)
	label.global_position = pos - Vector2(30, 10)
	label.z_index = 50
	get_tree().current_scene.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "position:y", label.position.y - 20, 0.8)
	tw.tween_property(label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func(): if is_instance_valid(label): label.queue_free())

func _deal_area_damage(center: Vector2) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not is_instance_valid(e) or not e.has_node("Health"):
			continue
		if _hit_bodies.has(e):
			continue
		var h: Health = e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		var dist: float = center.distance_to(e.global_position)
		if dist > area_damage_radius:
			continue
		var valid_source: Node = _source if (is_instance_valid(_source)) else null
		var pen: float = 0.0
		h.take_damage(_damage * 0.5, valid_source, _tags, false, pen)

func _chain_to_nearest(exclude_body: Node) -> bool:
	"""En yakin canli dusmana yon degistir. Basariliysa true."""
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var nearest: Node = null
	var nearest_dist: float = 999999.0
	for e in enemies:
		if not is_instance_valid(e) or e == exclude_body:
			continue
		if not e.has_node("Health"):
			continue
		var h: Health = e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		if _hit_bodies.has(e):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest:
		_velocity = (nearest.global_position - global_position).normalized() * speed
		rotation = _velocity.angle()
		return true
	return false

func _fork_projectiles() -> void:
	"""2 adet fork mermisi olustur, ±25 derece acili."""
	for angle_offset in [-25.0, 25.0]:
		var proj := _clone_self()
		if not proj:
			continue
		var dir: Vector2 = _velocity.rotated(deg_to_rad(angle_offset)).normalized()
		proj._velocity = dir * speed
		get_tree().current_scene.add_child(proj)

## Bumerang/arcane_orb için: hızı ters çevir (geri dönüş)
func reverse_velocity(speed_mult: float = 0.8) -> void:
	_velocity = -_velocity.normalized() * speed * speed_mult
	speed = speed * speed_mult
	lifetime = lifetime + 999.0  # Geri dönene kadar yaşa

func _clone_self() -> Projectile:
	"""Kendini clone'la (fork icin)"""
	if not ResourceLoader.exists("res://scripts/projectile.tscn"):
		return null
	var scene := load("res://scripts/projectile.tscn") as PackedScene
	if not scene:
		return null
	var clone := scene.instantiate() as Projectile
	if not clone:
		return null
	clone.global_position = global_position
	clone._damage = _damage
	clone._tags = _tags.duplicate()
	clone._source = _source
	clone.skill_id = skill_id
	clone._is_crit = _is_crit
	clone._ailment_power_override = _ailment_power_override
	clone._damage_type = _damage_type
	clone.pierce_count = pierce_count
	clone.chain_count = chain_count
	clone.area_damage_radius = area_damage_radius
	clone._remaining_pierce = _remaining_pierce
	clone._remaining_chain = _remaining_chain
	clone.speed = speed
	clone.lifetime = lifetime
	clone.hit_effect_texture = hit_effect_texture
	return clone

func _apply_ailments(body: Node) -> void:
	if not body.has_node("CharacterStats"):
		return
	var target_stats: CharacterStats = body.get_node("CharacterStats") as CharacterStats
	var ailment_power: float = _ailment_power_override if _ailment_power_override > 0.0 else _damage * 0.25
	if _tags.has("fire") and _tags.has("spell"):
		if _is_crit:
			target_stats.apply_ailment("ignite", ailment_power * 1.5, _source)
		else:
			target_stats.apply_ailment("ignite", ailment_power, _source)
	if _tags.has("cold") and _tags.has("spell"):
		target_stats.apply_ailment("chill", ailment_power * 0.5, _source)
	if _tags.has("lightning") and _tags.has("spell"):
		target_stats.apply_ailment("shock", ailment_power * 0.3, _source)
	if _tags.has("chaos") and _tags.has("spell"):
		target_stats.apply_ailment("poison", ailment_power, _source)
