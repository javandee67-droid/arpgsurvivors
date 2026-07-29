extends Node
class_name EnemySkillRuntime
## Dusman skill'lerini runtime'da calistiran node.
## Projectile, melee, aoe ve buff skill'lerini yonetir.

signal skill_cast(skill_id: String)

var _parent_enemy: Node = null
var _cooldowns: Dictionary = {}  # skill_id -> remaining time
var _current_skills: Array = []  # skill_id listesi

func _ready() -> void:
	_parent_enemy = get_parent()

## Skill ID listesini ata
func set_skills(skill_ids: Array) -> void:
	_current_skills = skill_ids
	_cooldowns.clear()
	for sid in skill_ids:
		_cooldowns[sid] = 0.0

func _process(delta: float) -> void:
	# Cooldown'lari azalt
	for sid in _cooldowns:
		_cooldowns[sid] = maxf(_cooldowns[sid] - delta, 0.0)

## Uygun bir skill sec ve kullan
func try_cast_skill(target: Node, dist_to_target: float) -> bool:
	if not is_instance_valid(target) or _current_skills.is_empty():
		return false

	# Rastgele bir skill dene (hazir olana kadar)
	var available: Array[String] = []
	for sid in _current_skills:
		if _cooldowns.get(sid, 0.0) <= 0.0:
			var sdata: Dictionary = EnemySkillManager.get_skill_data(sid)
			if not sdata.is_empty():
				var min_r: float = sdata.get("min_range", 0.0)
				var max_r: float = sdata.get("max_range", 300.0)
				if dist_to_target >= min_r and dist_to_target <= max_r:
					available.append(sid)

	if available.is_empty():
		return false

	# Rastgele bir skill sec
	var chosen: String = available[randi() % available.size()]
	_cast_skill(chosen, target)
	return true

## Skill'i calistir
func _cast_skill(skill_id: String, target: Node) -> void:
	var sdata: Dictionary = EnemySkillManager.get_skill_data(skill_id)
	if sdata.is_empty():
		return

	skill_cast.emit(skill_id)

	# Cooldown'a al
	var cd: float = sdata.get("cd", 3.0)
	# Rarity/level scaling: biraz rastgelelik ekle
	cd *= randf_range(0.8, 1.2)
	_cooldowns[skill_id] = cd

	# Skill tipine gore calistir
	var shape: String = sdata.get("shape", "melee")
	match shape:
		"projectile":
			_execute_projectile(sdata, target)
		"melee":
			_execute_melee(sdata, target)
		"aoe":
			_execute_aoe(sdata, target)
		"buff":
			_execute_buff(sdata, target)
		"orbital":
			_execute_orbital(sdata, target)

## Mermi skill'i calistir
func _execute_projectile(sdata: Dictionary, target: Node) -> void:
	if not is_instance_valid(_parent_enemy):
		return

	var dmg_pct: float = sdata.get("dmg_pct", 1.0)
	var dmg_type: String = sdata.get("dmg_type", "physical")
	var tags: Array[String] = _string_tags(sdata.get("tags", ["attack"]))
	var proj_tex: String = sdata.get("proj_tex", "")
	var hit_tex: String = sdata.get("hit_tex", "")
	var proj_speed: float = sdata.get("proj_speed", 300.0)
	var proj_count: int = sdata.get("proj_count", 1)
	var proj_spread: float = sdata.get("proj_spread", 0.15)

	var base_damage: float = _get_base_damage()
	var final_damage: float = base_damage * dmg_pct

	# SkillController varsa bile (player sistemi), dusman kendi mermisini olusturur
	_spawn_basic_projectile(final_damage, dmg_type, tags, target, proj_tex, hit_tex, proj_speed, proj_count, proj_spread)

func _spawn_basic_projectile(damage: float, dmg_type: String, tags: Array, target: Node,
		proj_tex: String, hit_tex: String, speed: float, count: int, spread: float) -> void:
	# Projectile.tscn'den mermi olustur
	var proj_scene: PackedScene = preload("res://scripts/projectile.tscn")
	if not proj_scene:
		return

	# Animasyon bilgilerini sdata'dan al (parent metodu _execute_projectile bize sdata vermiyor,
	# ancak biz zaten proj_tex ile animasyon metadata'sını yükleyeceğiz)
	var start_pos: Vector2 = _parent_enemy.global_position
	var target_pos: Vector2 = target.global_position

	for i in range(count):
		var proj: Projectile = proj_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = start_pos
		proj.speed = speed

		var angle_offset: float = (i - float(count - 1) / 2.0) * spread
		var dir: Vector2 = (target_pos - start_pos).rotated(angle_offset)

		# Mermi sprite'i — animasyonlu spritesheet veya statik texture
		var tex_to_load: String = proj_tex
		if tex_to_load != "" and not ResourceLoader.exists(tex_to_load):
			# _frame_0 sonekini dene (generate_pixel_art bu şekilde kaydediyor)
			var basename: String = proj_tex.get_basename()
			var ext: String = proj_tex.get_extension()
			tex_to_load = basename + "_frame_0." + ext

		# Carpma efekti
		if hit_tex != "" and ResourceLoader.exists(hit_tex):
			proj.hit_effect_texture = hit_tex
			proj.hit_effect_fw = 64
			proj.hit_effect_fh = 64
			proj.hit_effect_cols = 4
			proj.hit_effect_count = 16

		proj.setup(start_pos + dir, damage, tags, _parent_enemy, tex_to_load)

## Yakin dovus skill'i
func _execute_melee(sdata: Dictionary, target: Node) -> void:
	if not is_instance_valid(_parent_enemy) or not is_instance_valid(target):
		return

	var dmg_pct: float = sdata.get("dmg_pct", 1.0)
	var dmg_type: String = sdata.get("dmg_type", "physical")
	var tags: Array[String] = _string_tags(sdata.get("tags", ["attack"]))
	var hit_tex: String = sdata.get("hit_tex", "")
	var melee_range: float = sdata.get("range", 35.0)

	var dist: float = _parent_enemy.global_position.distance_to(target.global_position)
	if dist > melee_range + 10.0:
		return  # Cok uzak

	var base_damage: float = _get_base_damage()
	var final_damage: float = base_damage * dmg_pct

	# Dusmanin kendi CharacterStats'ini kullanarak hesapla
	var target_health: Health = target.get_node_or_null("Health")
	if target_health:
		var enemy_stats: CharacterStats = _parent_enemy.get_node_or_null("CharacterStats")
		var player_stats: CharacterStats = target.get_node_or_null("CharacterStats")

		var hit_result: Dictionary = {"hit": true, "damage": final_damage, "is_crit": false}
		if enemy_stats and player_stats:
			hit_result = CombatEngine.calculate_hit(enemy_stats, player_stats, final_damage, dmg_type, tags, false)

		if hit_result.hit:
			target_health.take_damage(hit_result.damage, _parent_enemy, tags, false)
			# Carpma efekti
			if hit_tex != "":
				_spawn_hit_effect(hit_tex, target.global_position)

			# Ailment uygula (varsa tag'lerde)
			_apply_ailments(target, hit_result, tags)

## AoE skill'i
func _execute_aoe(sdata: Dictionary, target: Node) -> void:
	if not is_instance_valid(_parent_enemy):
		return

	var dmg_pct: float = sdata.get("dmg_pct", 1.0)
	var dmg_type: String = sdata.get("dmg_type", "physical")
	var tags: Array[String] = _string_tags(sdata.get("tags", ["attack"]))
	var hit_tex: String = sdata.get("hit_tex", "")
	var aoe_radius: float = sdata.get("aoe_radius", 80.0)
	var target_type: String = sdata.get("target", "self_aoe")

	var base_damage: float = _get_base_damage()
	var final_damage: float = base_damage * dmg_pct
	var center: Vector2

	match target_type:
		"at_player_aoe":
			if is_instance_valid(target):
				center = target.global_position
		_:
			center = _parent_enemy.global_position

	# Carpma efektini merkeze koy
	if hit_tex != "":
		_spawn_hit_effect(hit_tex, center)

	# AoE icindeki herkese hasar ver
	var enemies: Array[Node] = get_tree().get_nodes_in_group("player")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = enemy.global_position.distance_to(center)
		if dist <= aoe_radius:
			var target_health: Health = enemy.get_node_or_null("Health")
			if target_health:
				var enemy_stats: CharacterStats = _parent_enemy.get_node_or_null("CharacterStats")
				var player_stats: CharacterStats = enemy.get_node_or_null("CharacterStats")

				var hit_result: Dictionary = {"hit": true, "damage": final_damage, "is_crit": false}
				if enemy_stats and player_stats:
					hit_result = CombatEngine.calculate_hit(enemy_stats, player_stats, final_damage, dmg_type, tags, true)

				if hit_result.hit:
					target_health.take_damage(hit_result.damage, _parent_enemy, tags, true)
					_apply_ailments(enemy, hit_result, tags)

## Buff skill'i
func _execute_buff(sdata: Dictionary, target: Node) -> void:
	if not is_instance_valid(_parent_enemy):
		return

	var buff_tags: Array = sdata.get("buff_tags", [])
	var skill_name: String = sdata.get("name", "").to_lower()

	# Ozellestirilmis buff'lar — skill_id kontrolu icin skill_name kullan
	if "çağır" in skill_name:
		# Minion cagir - spawn etrafinda ek dusman
		_summon_minion()
		return

	if "blink" in skill_name or "ışınlanma" in skill_name:
		# Işınlanma - oyuncudan uzaga
		_do_blink(target)
		return

	# Genel buff: hiz, guclenme vs.
	if buff_tags.has("onslaught"):
		var ac: AilmentController = _parent_enemy.get_node_or_null("AilmentController")
		if ac:
			ac.apply_effect(StatusEffect.Type.BUFF_ONSLAUGHT, 0.0, 4.0, _parent_enemy)

func _summon_minion() -> void:
	# etrafta gecici dusman spawnla
	var scene: Node = get_tree().current_scene
	if not scene or not scene.has_method("_spawn_single_enemy"):
		return

	var enemy_id: String = ""
	# Rastgele zayif bir dusman sec
	var pool: Array = ["rat", "bat", "slime", "spider"]
	enemy_id = pool[randi() % pool.size()]

	var spawn_pos: Vector2 = _parent_enemy.global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
	scene._spawn_single_enemy(enemy_id, spawn_pos, 1)

func _do_blink(target: Node) -> void:
	if not is_instance_valid(target):
		return
	# Dusmani oyuncudan 150-250px uzaga isinla
	var dir: Vector2 = (target.global_position - _parent_enemy.global_position).normalized()
	var blink_dist: float = randf_range(150, 250)
	var new_pos: Vector2 = target.global_position - dir * blink_dist
	_parent_enemy.global_position = new_pos

	# Teleport efekti
	var hit_tex: String = "res://assets/generated/hit_dark_explosion.png"
	_spawn_hit_effect(hit_tex, _parent_enemy.global_position)

## Orbital skill (boss etrafinda donen ates toplari)
func _execute_orbital(sdata: Dictionary, _target: Node) -> void:
	if not is_instance_valid(_parent_enemy):
		return

	# Daha once olusturulmus OrbitalController var mi?
	var ctrl: Node = _parent_enemy.get_node_or_null("OrbitalController")
	if not ctrl:
		# Yeni controller olustur
		var oc := OrbitalController.new()
		oc.setup(_parent_enemy, sdata)
		_parent_enemy.add_child(oc)
	else:
		# Zaten var — controller _process'te otomatik fire yapiyor
		pass

## Base hasar (contact_damage uzerinden)
func _get_base_damage() -> float:
	if _parent_enemy and _parent_enemy.has_method("get_contact_damage"):
		return _parent_enemy.get_contact_damage()
	if _parent_enemy and "contact_damage" in _parent_enemy:
		return _parent_enemy.contact_damage
	return 10.0

## Carpma efektini spawnla
func _spawn_hit_effect(tex_path: String, pos: Vector2) -> void:
	if tex_path.is_empty() or not ResourceLoader.exists(tex_path):
		return
	var tex: Texture2D = load(tex_path)
	if not tex:
		return

	# Spritesheet mi yoksa tek kare mi kontrol et
	var asp := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("vfx")
	frames.set_animation_loop("vfx", false)

	# 64x64, 4 cols, 16 frames (standart spritesheet)
	for i in range(16):
		var col: int = i % 4
		var row: int = i / 4
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * 64, row * 64, 64, 64)
		frames.add_frame("vfx", at, 0.15)

	asp.sprite_frames = frames
	asp.animation = "vfx"
	asp.centered = true
	asp.position = pos
	get_tree().current_scene.add_child(asp)
	asp.play()
	asp.animation_finished.connect(func():
		if is_instance_valid(asp):
			asp.queue_free()
	, CONNECT_ONE_SHOT)
	# Kan efekti
	_spawn_blood_at(pos)

func _spawn_blood_at(pos: Vector2) -> void:
	var tex_path := "res://assets/generated/hit_blood_splatter.png"
	if not ResourceLoader.exists(tex_path):
		return
	var tex: Texture2D = ResourceLoader.load(tex_path)
	if not tex:
		return
	var asp := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("vfx")
	frames.set_animation_loop("vfx", false)
	for i in range(16):
		var col: int = i % 4
		var row: int = i / 4
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * 48, row * 48, 48, 48)
		frames.add_frame("vfx", at, 0.15)
	asp.sprite_frames = frames
	asp.animation = "vfx"
	asp.centered = true
	asp.position = pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	asp.z_index = 11
	asp.scale = Vector2(0.7, 0.7)
	get_tree().current_scene.add_child(asp)
	asp.play()
	asp.animation_finished.connect(func():
		if is_instance_valid(asp):
			asp.queue_free()
	, CONNECT_ONE_SHOT)

## Helper: untyped Array'i Array[String]'e donustur
static func _string_tags(raw: Array) -> Array[String]:
	var result: Array[String] = []
	for t in raw:
		result.append(str(t))
	return result

## Ailment uygula (tag'lere gore) — chance-based
func _apply_ailments(target: Node, hr: Dictionary, tags: Array) -> void:
	var ac: AilmentController = target.get_node_or_null("AilmentController")
	if not ac:
		return
	var th: Health = target.get_node_or_null("Health")
	var max_life: float = th.max_health if th else 100.0
	var dmg: float = hr.get("damage", 0.0)

	# Dusman skill'leri icin daha dusuk ailment_power
	var ap: float = dmg * 0.3
	# Dusmanlarin kendi CharacterStats'i yoksa null
	var dummy_stats: CharacterStats = null
	AilmentUtils.apply_ailments_for_tags(ac, hr, dummy_stats, max_life, tags, _parent_enemy)
