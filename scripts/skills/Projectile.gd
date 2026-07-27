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

## Animasyonlu mermi sprite'ı için frame bilgileri
var proj_anim_tex: String = ""       ## Spritesheet texture yolu
var proj_anim_fw: int = 32           ## Her frame genişliği
var proj_anim_fh: int = 32           ## Her frame yüksekliği
var proj_anim_cols: int = 4          ## Spritesheet'teki sütun sayısı
var proj_anim_count: int = 8         ## Toplam frame sayısı
var proj_anim_fps: float = 10.0      ## Animasyon hızı

@onready var _anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

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
	var asp := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("vfx")
	frames.set_animation_loop("vfx", false)
	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame("vfx", at, 1.0 / fps)
	asp.sprite_frames = frames
	asp.animation = "vfx"
	asp.centered = true
	asp.position = pos
	asp.z_index = 15
	asp.scale = Vector2(2.2, 2.2)
	get_tree().current_scene.add_child(asp)
	asp.play()
	asp.animation_finished.connect(func():
		if is_instance_valid(asp):
			asp.queue_free()
	, CONNECT_ONE_SHOT)

func _spawn_blood_vfx(pos: Vector2) -> void:
	var tex_path := "res://assets/generated/hit_blood_splatter.png"
	if not ResourceLoader.exists(tex_path):
		return
	var tex: Texture2D = ResourceLoader.load(tex_path)
	if not tex:
		return
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = _create_vfx_frames(tex, 48, 48, 4, 16)
	asp.animation = "vfx"
	asp.centered = true
	asp.position = pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	asp.z_index = 11  # blood above other effects
	asp.scale = Vector2(0.35, 0.35)
	get_tree().current_scene.add_child(asp)
	asp.play()
	asp.animation_finished.connect(func():
		if is_instance_valid(asp):
			asp.queue_free()
	, CONNECT_ONE_SHOT)

static func _create_vfx_frames(tex: Texture2D, fw: int, fh: int,
		cols: int, count: int) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.add_animation("vfx")
	frames.set_animation_loop("vfx", false)
	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame("vfx", at, 0.22)
	return frames

func _apply_ailments(target: Node) -> void:
	var ac: AilmentController = target.get_node_or_null("AilmentController")
	if not ac:
		return
	var th: Health = target.get_node_or_null("Health")
	var max_life: float = th.max_health if th else 100.0
	var valid_source: Node = _source if (is_instance_valid(_source)) else null
	var caster_stats: CharacterStats = null
	if valid_source and valid_source.has_node("CharacterStats"):
		caster_stats = valid_source.get_node("CharacterStats") as CharacterStats
	
	# Hit result benzeri bir dict olustur
	var ap: float = _ailment_power_override if _ailment_power_override > 0.0 else _damage * 0.5
	var hit_result: Dictionary = {
		"damage": _damage,
		"is_crit": _is_crit,
		"ailment_power": ap,
		"damage_type": _damage_type,
	}
	
	AilmentUtils.apply_ailments_for_tags(ac, hit_result, caster_stats, max_life, _tags, valid_source)

func _spawn_miss_effect(pos: Vector2) -> void:
	# Simple floating miss indicator
	var lbl := Label.new()
	lbl.text = "Iska!"
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = pos - Vector2(16, 0)
	lbl.z_index = 20
	get_tree().current_scene.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -24), 0.6)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tween.finished.connect(func():
		if is_instance_valid(lbl):
			lbl.queue_free()
	)

func _deal_area_damage(center: Vector2) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy) or _hit_bodies.has(enemy):
			continue
		if enemy.global_position.distance_to(center) <= area_damage_radius:
			if enemy.has_node("Health"):
				var valid_source: Node = _source if (is_instance_valid(_source)) else null
				enemy.get_node("Health").take_damage(_damage * 0.5, valid_source, _tags)  ## 50% area damage

func _fork_projectiles() -> void:
	var fork_angles: Array[float] = [-0.5, 0.5]  ## Fork left and right
	for angle_off in fork_angles:
		var forked := duplicate() as Projectile
		get_tree().current_scene.add_child(forked)
		forked.global_position = global_position
		forked._velocity = _velocity.rotated(angle_off)
		forked.rotation = forked._velocity.angle()
		forked._remaining_fork = 0  ## Forked projectiles don't fork again
		forked._remaining_chain = maxi(0, _remaining_chain)
		forked._remaining_pierce = 0
		forked._hit_bodies = _hit_bodies.duplicate()

func _chain_to_nearest(hit_body: Node) -> bool:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var nearest: Node = null
	var nearest_dist: float = 500.0  ## Max chain range
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == hit_body or _hit_bodies.has(enemy):
			continue
		var dist: float = enemy.global_position.distance_to(global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	if nearest:
		# Redirect to nearest enemy
		global_position = hit_body.global_position
		_velocity = (nearest.global_position - global_position).normalized() * speed
		rotation = _velocity.angle()
		return true
	
	# Hedef yok, mermi pierce/fork ile devam etsin
	return false
