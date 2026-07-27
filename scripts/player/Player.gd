extends CharacterBody2D
class_name Player

@export var speed: float = 85.0

@onready var health: Health = $Health
@onready var inventory: Inventory = $Inventory
@onready var essence_inventory: EssenceInventory = $EssenceInventory
@onready var stats: CharacterStats = $CharacterStats
@onready var equipment: Equipment = $Equipment
@onready var level_system: LevelSystem = $LevelSystem
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _buff_aura: Node2D = $StatusEffectVisual/BuffAura

## Pasif ağacı için harcanabilecek puanlar
var skill_points: int = 1

## Seçilen karakter sınıfı (ör: "warrior", "mage", "rogue") — GameUI portresi vs için
var character_class: String = ""

## Son bilinen velocity yönü (animasyon seçimi için)
var _last_dir: Vector2 = Vector2.DOWN

## Hotbar: 20 slot (1-9, 0, -, =, Q, W, E, R, T, Y, U, I) -> skill path'leri
var hotbar: Array[String] = []
## Skill cooldown sistemi: {"skill_path": kalan_sure}
var _skill_cooldowns: Dictionary = {}
## Attack animasyonu ne kadar süre daha oynasın (saniye)
var _attack_anim_timer: float = 0.0

## VS (Vampire Survivors) sistemi: otomatik ates eden skill'ler
var vs_skills: Array[String] = []
## Skill seviyeleri: {skill_path: level}
var _skill_levels: Dictionary = {}
## Auto attack timer (basic attack)
var _auto_attack_timer: float = 0.0
## Auto skill cast timer'lari: {skill_path: timer}
var _auto_skill_timers: Dictionary = {}

## --- Dash (super fast movement) ---
var _is_dashing: bool = false
var _dash_start: Vector2 = Vector2.ZERO
var _dash_target: Vector2 = Vector2.ZERO
var _dash_progress: float = 0.0
var _dash_trail_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO
const DASH_DURATION: float = 0.12  # saniye (cok hizli)

## Basic attack — cooldown yok, animation timer saldiri hizina gore
const BASIC_MELEE_RANGE: float = 55.0
var _basic_projectile_scene: PackedScene = preload("res://scripts/projectile.tscn")
var _hovered_enemy: Node = null
var _game_cursor: Texture2D = null



## --- SkillInstance tabanli Skill sistemi ---
## Normal Attack'in SkillData resource'u (.tres)
var _normal_attack_skill: SkillData = null
## SkillInstance: Normal Attack + bagli support gem'lerin runtime hesaplayicisi
var _skill_instance: SkillInstance = null

## Gem havuzu: dusmanlardan dusen tum support gem'ler burada birikir
var gem_stash: Array[SupportData] = []

## --- Buff/Aura toggle sistemi ---
## Aktif buff skill'leri: {skill_path: {"ref": buff_ref, "reserve_amount": float, "use_life": bool}}
var _active_buffs: Dictionary = {}

## Hasta skill data (cache)
var _haste_skill_data: SkillData = null

## Skill kurulumlari: {skill_res_path: {"skill": SkillData, "supports": [5 eleman, SupportData/null]}}
var skill_setups: Dictionary = {}

func _ready() -> void:
	RapierPhysicsServer2D.body_set_extra_param(get_rid(), RapierPhysicsServer2D.BODY_PARAM_CONTACT_SKIN, 0.02)
	add_to_group("player")
	stats.set_equipment_source(equipment)
	inventory.set_player_stats(stats)
	inventory.set_player_level(level_system.level)
	level_system.stats_ref = stats
	# Stats degisince SkillBar'daki mana cost gostergelerini guncelle
	stats.stats_changed.connect(_on_stats_changed)
	var passive_manager := get_node_or_null("PassiveTreeManager") as PassiveTreeManager
	if passive_manager:
		passive_manager.set_stats_ref(stats)
	level_system.leveled_up.connect(_on_leveled_up)
	# Sabit oyun cursor'u - hover'dan bagimsiz her zaman aktif
	_game_cursor = _create_game_cursor()
	if _game_cursor:
		Input.set_custom_mouse_cursor(_game_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
	
	# Yeni SkillInstance sistemi: Normal Attack SkillData'yı yükle
	if ResourceLoader.exists("res://data/skills/normal_attack.tres"):
		_normal_attack_skill = load("res://data/skills/normal_attack.tres") as SkillData
		_rebuild_skill_instance()
		_verify_support_system()
	
	# Lit aydınlatma: AnimatedSprite2D'ye alıcı materyali ata
	_setup_lit_receiver()
	
	# Hotbar'i 20 bos slotla baslat
	hotbar.resize(20)
	for i in range(20):
		hotbar[i] = ""

## Oyuncu sprite'ına Lit alıcı materyali ata ve LitPointLight2D ekle.
func _setup_lit_receiver() -> void:
	# Oyuncu sprite'ı Lit'ten etkilenmesin — kendisi ışık kaynağı olduğu için
	# aşırı parlamasın, karakter net görünsün.
	# Sadece zemin/duvarlar/dekor Lit alıcıdır (DungeonGenerator üzerinden).
	if animated_sprite:
		animated_sprite.material = null
	
	# Bir LitPointLight2D düğümü ekle (oyuncuyu takip eder, Lit zeminleri aydınlatır)
	if not has_node("LitPlayerLight"):
		var lp_script: GDScript = load("res://addons/lit/nodes/lit_point_light_2d.gd")
		if not lp_script:
			return
		var lp: Node2D = lp_script.new()
		lp.name = "LitPlayerLight"
		lp.energy = 1.5
		lp.range = 350.0
		lp.color = Color(1.0, 0.92, 0.7)  # Daha geniş, daha yumuşak ışık
		lp.height = 56.0
		lp.shadow_enabled = false
		lp.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
		lp.shadow_hardness = 0.2
		lp.z_index = 5
		add_child(lp)

## Main tarafindan class secildikten sonra cagrilir.
## Silah, sprite, pasif agaci baslangicini ayarlar.
func set_class(class_id: String) -> void:
	character_class = class_id
	# Pasif ağacı başlangıç node'unu aç (merkez + sınıfa göre)
	var unlocked: Array = get_meta("passive_unlocked", [])
	if "center" not in unlocked:
		unlocked.append("center")
		# Center node bonuslarını otomatik uygula: +10 base_life, +10 base_mana
		stats.base_life += 10
		stats.base_mana += 10
	# Merkeze yakin gercek node ID'lerini unlock et
	var start_nodes: Array = [20499, 2653, 18441, 2955, 42452]
	for sid in start_nodes:
		var sid_str: String = str(sid)
		if sid_str not in unlocked:
			unlocked.append(sid_str)
	if unlocked.size() > 0:
		set_meta("passive_unlocked", unlocked)
		stats.recalculate()
	
	skill_points = 1
	
	# Baslangic silahini ver ve kusan
	_give_starting_weapon(class_id)
	
	# Class'a ozel 4 yönlü sprite ve animasyonlar
	if animated_sprite:
		_apply_class_visuals(class_id)

func _apply_class_visuals(class_id: String) -> void:
	if not animated_sprite:
		return
	# Once durdur, sonra degistir
	animated_sprite.stop()
	ClassVisuals.apply_class_visuals(animated_sprite, class_id)

func _give_starting_weapon(class_id: String) -> void:
	var weapon_path: String = ""
	match class_id:
		"warrior":
			weapon_path = "res://scripts/core/base_sword.tres"
		"mage":
			weapon_path = "res://scripts/core/base_staff.tres"
		"rogue":
			weapon_path = "res://scripts/core/base_dagger.tres"
	if weapon_path.is_empty() or not ResourceLoader.exists(weapon_path):
		return
	var weapon: ItemData = load(weapon_path) as ItemData
	if not weapon:
		return
	if equipment:
		equipment.equip(Equipment.Slot.WEAPON, weapon)
		# Stats'i yeniden hesapla (silah base_attack_speed'i icin)
		if stats:
			stats.recalculate()

## Stats degisince SkillBar'daki mana cost gostergelerini guncelle
func _on_stats_changed() -> void:
	var skill_bar := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
	if skill_bar:
		skill_bar.refresh()

func _physics_process(_delta: float) -> void:
	if _is_any_ui_open():
		return
	
	# ── Dash (süper hızlı hareket) ──
	if _is_dashing:
		_dash_progress += _delta / DASH_DURATION
		if _dash_progress >= 1.0:
			# Dash bitti
			global_position = _dash_target
			_is_dashing = false
			velocity = Vector2.ZERO
			# Sprite'ı normale döndür
			if animated_sprite:
				animated_sprite.modulate = Color.WHITE
				animated_sprite.speed_scale = 1.0
			# Bitirme efekti: küçük bir parıltı
			_spawn_dash_finish_effect()
		else:
			# Interpolasyon ile git
			global_position = _dash_start.lerp(_dash_target, _dash_progress)
			velocity = _dash_dir * (2000.0 / DASH_DURATION)  # Çok hızlı göster
			# Trail efekti
			_dash_trail_timer -= _delta
			if _dash_trail_timer <= 0.0:
				_dash_trail_timer = 0.025  # her 25ms'de bir trail ghost
				_spawn_dash_trail()
		# Dash sırasında walk animasyonu, çok hızlı
		if animated_sprite and animated_sprite.sprite_frames:
			var dash_anim: String = _get_dir_anim("walk", _dash_dir)
			if animated_sprite.sprite_frames.has_animation(dash_anim):
				animated_sprite.play(dash_anim)
			animated_sprite.speed_scale = 3.0
		# hasar almaz
		move_and_slide()
		return
	
	# ── Normal hareket ──
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * speed * stats.movement_speed
	move_and_slide()
	
	# Movement dust particles
	if velocity.length() > 50.0 and Engine.get_process_frames() % 6 == 0:
		_spawn_movement_dust()
	
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	# Animations
	if _attack_anim_timer > 0.0:
		_attack_anim_timer -= _delta
		# Attack animasyonu
		var atk_anim: String = _get_dir_anim("attack", _last_dir)
		if animated_sprite.sprite_frames.has_animation(atk_anim):
			animated_sprite.play(atk_anim)
	elif velocity.length() > 10.0:
		_last_dir = velocity
		var walk_anim: String = _get_dir_anim("walk", velocity)
		if animated_sprite.sprite_frames.has_animation(walk_anim):
			animated_sprite.play(walk_anim)
			animated_sprite.speed_scale = 1.0
	else:
		var idle_anim: String = _get_dir_anim("idle", _last_dir)
		if animated_sprite.sprite_frames.has_animation(idle_anim):
			if animated_sprite.animation != idle_anim:
				animated_sprite.play(idle_anim)
				animated_sprite.speed_scale = 1.0

func _on_attack_anim_done() -> void:
	if not is_instance_valid(animated_sprite):
		return
	# Attack bitince idle'a dön (o anki yön)
	if animated_sprite and animated_sprite.sprite_frames:
		var idle_anim: String = _get_dir_anim("idle", _last_dir)
		if animated_sprite.sprite_frames.has_animation(idle_anim):
			animated_sprite.play(idle_anim)

## velocity vektörüne göre yön ismi döndürür: "front", "back", "left", "right"
func _get_dir_anim(prefix: String, vel: Vector2) -> String:
	var v: Vector2 = vel
	if v.length_squared() < 1.0:
		v = _last_dir  # duruyorsak son bilinen yönü kullan
	if v.length_squared() < 1.0:
		return prefix + "_front"  # hiç hareket yoksa front
	
	if abs(v.x) > abs(v.y):
		return prefix + "_right" if v.x > 0 else prefix + "_left"
	else:
		return prefix + "_front" if v.y > 0 else prefix + "_back"

func _on_leveled_up(new_level: int) -> void:
	skill_points += 1
	inventory.set_player_level(new_level)

# Skill tree P tuşu ile açılır (KEY_P handler in _input)

func _input(event: InputEvent) -> void:
	# VS modunda sadece ESC kalsin
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				pass
			KEY_P:
				pass  # Skill tree kapali
	
	# VS modunda mouse tiklamalari pasif
	if event is InputEventMouseButton and event.pressed:
		pass  # Otomatik ates var, manuel gerek yok

func _toggle_game_ui() -> void:
	var game_ui: CanvasLayer = get_tree().current_scene.get_node_or_null("CanvasLayer")
	if game_ui and game_ui.has_method("_toggle_ui"):
		# Eger acik bir UI varsa (skill tree / gem panel), once onu kapat
		if not game_ui.ui_is_open():
			var main := get_tree().current_scene
			if main:
				var st = main.get_skill_tree_instance() if main.has_method("get_skill_tree_instance") else null
				if st and st.visible and st.has_method("close"):
					st.close()
				var sgp := get_tree().root.get_node_or_null("SkillGemPanelLayer") as CanvasLayer
				if sgp and sgp.has_method("is_open") and sgp.is_open() and sgp.has_method("close_ui"):
					sgp.close_ui()
		game_ui.player = self
		game_ui._toggle_ui()

func _toggle_skill_gem_panel() -> void:
	var main := get_tree().current_scene
	if not main:
		return
	var sgp := get_tree().root.get_node_or_null("SkillGemPanelLayer") as CanvasLayer
	if not sgp:
		# SkillGemPanelLayer yoksa Main.gd'de init edilmemis — skip
		return
	# SkillGemPanel scriptine eris
	if not sgp.has_method("_on_k_pressed"):
		return
	
	# GameUI aciksa once onu kapat
	var game_ui: CanvasLayer = main.get_node_or_null("CanvasLayer")
	if game_ui and game_ui.has_method("ui_is_open") and game_ui.ui_is_open():
		game_ui._close_ui()
	
	sgp._on_k_pressed()

func _open_passive_tree() -> void:
	"""P tusu: skill tree'yi tam ekran ac/kapa, oyunu pause yap."""
	var main := get_tree().current_scene
	if not main:
		return
	
	# SkillTreeUI instance'ini bul
	if not main.has_method("get_skill_tree_instance"):
		return
	var st: Control = main.get_skill_tree_instance()
	if not st:
		return
	
	# Zaten aciksa kapat
	if st.visible:
		st.close()
		return
	
	# GameUI aciksa once onu kapat
	var game_ui: CanvasLayer = main.get_node_or_null("CanvasLayer")
	if game_ui and game_ui.has_method("ui_is_open") and game_ui.ui_is_open():
		game_ui._close_ui()
	
	# Tam ekran ac
	if st.has_method("open_fullscreen"):
		st.open_fullscreen()

# ================== BASIC ATTACK SISTEMI ==================
## Temel alan etkisi yaricapi (1.0 = neredeyse tek hedef).
## Support gem'ler veya pasif agaci ile artirilabilir.
var _basic_aoe_radius: float = 1.0

func get_basic_attack_aoe_radius() -> float:
	"""Support gem'lerden gelen area bonuslariyla birlikte toplam AoE yaricapini dondur."""
	var radius: float = _basic_aoe_radius
	# Support gem'lerden AoE bonusu
	for sd in _get_active_supports_for_skill("res://data/skills/normal_attack.tres"):
		if not sd:
			continue
		# "aoe" tag ekleyen support'lar yaricapi artirir
		if "aoe" in sd.added_tags or "area" in sd.added_tags:
			# Her aoe/area tag support'u icin yaricap 30px artar
			radius += 30.0
		# Ayrica item_rarity/quantity degil, area_damage_increased kontrolu
		# Support gem damage_multiplier yuksekse (guc artisi) yaricap da artar
		if sd.damage_multiplier > 1.25:
			radius += (sd.damage_multiplier - 1.25) * 40.0
	return maxf(1.0, radius)

func _try_basic_attack() -> void:
	# Animasyon devam ediyorsa yeni saldiri baslatma
	if _attack_anim_timer > 0.0:
		return
	
	var enemy := _find_enemy_at_mouse_pos(get_global_mouse_position())
	if not enemy or not is_instance_valid(enemy):
		return
	if not enemy.has_node("Health"):
		return
	var enemy_health: Health = enemy.get_node("Health")
	if enemy_health.current_health <= 0:
		return
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var wtype: String = weapon.weapon_type if weapon else "sword"
	
	match wtype:
		"sword", "dagger", "axe":
			_do_melee_basic(enemy)
		"bow", "staff", "wand":
			if wtype == "bow":
				_do_ranged_basic(enemy.global_position, wtype, weapon)
			else:
				_do_ranged_basic(enemy.global_position, wtype, weapon)
		_:
			_do_melee_basic(enemy)
	
	# Attack animasyonu — suresi saldiri hizina gore skalalanir
	var as_mult: float = 1.0
	if stats and stats.attack_speed > 0:
		as_mult = stats.attack_speed
	# Support gem'lerden attack_speed modifier'larını uygula (Faster Attacks vs.)
	if _skill_instance != null:
		as_mult = _skill_instance.get_final_stat("attack_speed", as_mult)
	if as_mult <= 0.0:
		as_mult = 0.01
	_attack_anim_timer = 0.4 / as_mult
	if animated_sprite and animated_sprite.sprite_frames:
		var atk_anim: String = _get_dir_anim("attack", _last_dir)
		if animated_sprite.sprite_frames.has_animation(atk_anim):
			animated_sprite.play(atk_anim)

func _try_basic_attack_key(_approach_type: String = "melee_distance") -> void:
	"""Space tusu ile en yakin dusmani bul, yeterince yakinsa vur."""
	var melee_range: float = BASIC_MELEE_RANGE
	if stats and stats.melee_range_bonus > 0.0:
		melee_range += stats.melee_range_bonus * 35.0  # her birim bonus = 35px ek menzil
	var nearest: Node = _find_nearest_enemy(melee_range)
	if not nearest or not is_instance_valid(nearest):
		return
	_try_basic_attack_at(nearest)

func _try_basic_attack_at(enemy: Node) -> void:
	if _attack_anim_timer > 0.0:
		return
	if not enemy or not is_instance_valid(enemy):
		return
	if not enemy.has_node("Health"):
		return
	var enemy_health: Health = enemy.get_node("Health")
	if enemy_health.current_health <= 0:
		return
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var wtype: String = weapon.weapon_type if weapon else "sword"
	
	match wtype:
		"sword", "dagger", "axe":
			_do_melee_basic(enemy)
		"bow", "staff", "wand":
			_do_ranged_basic(enemy.global_position, wtype, weapon)
		_:
			_do_melee_basic(enemy)
	
	var as_mult: float = 1.0
	if stats and stats.attack_speed > 0:
		as_mult = stats.attack_speed
	# Support gem'lerden attack_speed modifier'larını uygula (Faster Attacks vs.)
	if _skill_instance != null:
		as_mult = _skill_instance.get_final_stat("attack_speed", as_mult)
	if as_mult <= 0.0:
		as_mult = 0.01
	_attack_anim_timer = 0.4 / as_mult
	if animated_sprite and animated_sprite.sprite_frames:
		var atk_anim: String = _get_dir_anim("attack", _last_dir)
		if animated_sprite.sprite_frames.has_animation(atk_anim):
			animated_sprite.play(atk_anim)

# ================== VS OTOMATIK SALDIRI ==================

func _vs_auto_attack() -> void:
	"""En yakin dusmani bul ve otomatik vur."""
	var melee_range: float = BASIC_MELEE_RANGE
	if stats and stats.melee_range_bonus > 0.0:
		melee_range += stats.melee_range_bonus * 35.0
	
	var nearest: Node = _find_nearest_enemy(melee_range * 1.5)
	if not nearest or not is_instance_valid(nearest):
		_auto_attack_timer = 0.5
		return
	if not nearest.has_node("Health"):
		_auto_attack_timer = 0.5
		return
	var enemy_health: Health = nearest.get_node("Health")
	if enemy_health.current_health <= 0:
		_auto_attack_timer = 0.5
		return
	
	var dist: float = global_position.distance_to(nearest.global_position)
	if dist > melee_range:
		_auto_attack_timer = 0.2
		return
	
	# Görünür kılıç sallama efekti (player'dan enemy'e doğru)
	_spawn_player_swing_effect(nearest.global_position)
	
	# Melee vurusu yap
	_do_melee_basic(nearest)
	
	# Timer'i saldiri hizina gore ayarla
	var as_mult: float = 1.0
	if stats and stats.attack_speed > 0:
		as_mult = stats.attack_speed
	if _skill_instance != null:
		as_mult = _skill_instance.get_final_stat("attack_speed", as_mult)
	if as_mult <= 0.0:
		as_mult = 0.01
	_auto_attack_timer = 1.0 / as_mult
	
	# Attack animasyonu
	if animated_sprite and animated_sprite.sprite_frames:
		var atk_anim: String = _get_dir_anim("attack", _last_dir)
		if animated_sprite.sprite_frames.has_animation(atk_anim):
			animated_sprite.play(atk_anim)

func _vs_auto_cast_skill(skill_path: String) -> void:
	"""Bir skill'i en yakin dusmana otomatik atesle."""
	if not ResourceLoader.exists(skill_path):
		vs_skills.erase(skill_path)
		return
	
	var skill_data: SkillData = _get_skill_data_from_setup(skill_path)
	if not skill_data:
		return
	
	# Cooldown kontrolu
	if _skill_cooldowns.has(skill_path) and _skill_cooldowns[skill_path] > 0.0:
		_auto_skill_timers[skill_path] = 0.1
		return
	
	# Animasyon kontrolu
	if _attack_anim_timer > 0.0:
		_auto_skill_timers[skill_path] = 0.1
		return
	
	# En yakin dusmani bul
	var cast_range: float = 400.0
	var nearest: Node = _find_nearest_enemy(cast_range)
	if not nearest or not is_instance_valid(nearest):
		_auto_skill_timers[skill_path] = 0.5
		return
	if not nearest.has_node("Health"):
		_auto_skill_timers[skill_path] = 0.5
		return
	var enemy_health: Health = nearest.get_node("Health")
	if enemy_health.current_health <= 0:
		_auto_skill_timers[skill_path] = 0.5
		return
	
	# Skill cooldown'u baslat — buyu hizina gore olceklenir
	var cast_spd: float = 1.0
	if stats and stats.cast_speed > 0.0:
		cast_spd = stats.cast_speed
	var adjusted_cd: float = skill_data.cooldown / cast_spd
	if skill_data.cooldown > 0.0:
		_skill_cooldowns[skill_path] = adjusted_cd
	
	# Skill tipine gore yonlendir — her skill benzersiz mekanik
	match skill_data.id:
		"fire_bolt":
			_cast_fire_bolt_vs(skill_data, nearest, skill_path)
		"ice_shard":
			_cast_ice_shard_vs(skill_data, nearest, skill_path)
		"lightning_chain":
			_cast_lightning_chain_vs(skill_data, nearest, skill_path)
		"arcane_orb":
			_cast_arcane_orb_vs(skill_data, nearest, skill_path)
		"toxic_circle":
			_cast_toxic_circle_vs(skill_data, nearest, skill_path)
		"whirlwind":
			_cast_whirlwind_vs(skill_data, nearest, skill_path)
		"dark_beam":
			_cast_dark_beam_vs(skill_data, nearest, skill_path)
		"holy_nova":
			_cast_holy_nova_vs(skill_data, nearest, skill_path)
		"thunder_strike":
			_cast_thunder_strike_vs(skill_data, nearest, skill_path)
		"frost_explosion":
			_cast_frost_explosion_vs(skill_data, nearest, skill_path)
		"slice_wave":
			_cast_slice_wave(skill_data, nearest)
		"fireball", "ice_nova":
			# Eski skill'ler — fallback
			_cast_projectile_skill(skill_data, nearest, skill_path)
		_:
			_cast_projectile_skill(skill_data, nearest, skill_path)
	
	# Timer'i skill cooldown'una gore ayarla (buyu hizi ile olceklenmis)
	var cd2: float = adjusted_cd
	if cd2 <= 0.0:
		cd2 = 0.5
	_auto_skill_timers[skill_path] = cd2

func _cast_projectile_skill(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Hedefe dogru mermi firlatan skill'ler."""
	var target_pos: Vector2 = target.global_position
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	
	# SkillInstance ile support gem'leri uygula
	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	var si: SkillInstance = SkillInstance.new(skill_data, supports)
	var si_total: float = si.get_total_damage(_get_base_damage_for_skill)
	if si_total > 0.0:
		var placeholder_base: float = _get_base_damage_for_skill(skill_data)
		if placeholder_base > 0.0:
			var ratio: float = dmg / placeholder_base
			dmg = si_total * ratio
		else:
			dmg = si_total
	
	var proj_instance := _basic_projectile_scene.instantiate() as Projectile
	if not proj_instance:
		return
	
	get_tree().current_scene.add_child(proj_instance)
	proj_instance.global_position = global_position
	
	# Skill'e gore hiz ve gorsel
	var tex: String = "res://assets/generated/proj_fireball_anim.png"
	var hit_tex: String = "res://assets/generated/hit_slash_arc_new.png"
	var proj_speed: float = 400.0
	var proj_fw: int = 32; var proj_fh: int = 32
	var hit_fw: int = 48; var hit_fh: int = 48
	
	match skill_data.damage_type:
		"fire":
			tex = "res://assets/generated/proj_fireball_anim.png"
			hit_tex = "res://assets/generated/vfx_fire_explosion.png"
		"cold":
			tex = "res://assets/generated/proj_fireball_anim.png"
			hit_tex = "res://assets/generated/hit_slash_arc_new.png"
		"lightning":
			tex = "res://assets/generated/proj_fireball_anim.png"
			hit_tex = "res://assets/generated/vfx_fire_explosion.png"
		"chaos":
			tex = "res://assets/generated/proj_fireball_anim.png"
			hit_tex = "res://assets/generated/hit_slash_arc_new.png"
	
	if stats and stats.projectile_speed > 0.0:
		proj_speed *= (1.0 + stats.projectile_speed / 100.0)
	
	proj_instance.speed = proj_speed
	proj_instance.lifetime = 1.5
	proj_instance.pierce_count = 0
	proj_instance.area_damage_radius = 20.0
	
	proj_instance.setup(target_pos, dmg, skill_data.tags.duplicate(), self, tex, hit_tex, skill_data.id, false, 0.0, skill_data.damage_type)
	proj_instance.proj_anim_fw = proj_fw; proj_instance.proj_anim_fh = proj_fh
	proj_instance.proj_anim_cols = 4; proj_instance.proj_anim_count = 8; proj_instance.proj_anim_fps = 12.0
	proj_instance.hit_effect_fw = hit_fw; proj_instance.hit_effect_fh = hit_fh
	proj_instance.hit_effect_cols = 4; proj_instance.hit_effect_count = 16
	proj_instance.set_meta("attacker_stats", stats)

func _cast_aoe_skill(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Hedef bolgeye alan hasari veren skill'ler."""
	var center_pos: Vector2 = target.global_position
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	
	# SkillInstance ile support gem'leri uygula
	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	var si: SkillInstance = SkillInstance.new(skill_data, supports)
	var si_total: float = si.get_total_damage(_get_base_damage_for_skill)
	if si_total > 0.0:
		var placeholder_base: float = _get_base_damage_for_skill(skill_data)
		if placeholder_base > 0.0:
			var ratio: float = dmg / placeholder_base
			dmg = si_total * ratio
		else:
			dmg = si_total
	
	var aoe_radius: float = skill_data.aoe_radius
	if aoe_radius <= 0.0:
		aoe_radius = 70.0
	if stats and stats.area_of_effect > 0.0:
		aoe_radius *= (1.0 + stats.area_of_effect / 100.0)
	
	var enemies := _find_enemies_in_radius(center_pos, aoe_radius)
	for e in enemies:
		if not is_instance_valid(e) or not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		h.take_damage(dmg, self, skill_data.tags.duplicate())
		_spawn_blood_effect(e.global_position)

func _cast_melee_aoe_skill(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Yakin cevreye alan hasari veren yakin dovus skill'leri."""
	var melee_range: float = skill_data.melee_range
	if melee_range <= 0.0:
		melee_range = 60.0
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	
	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	var si: SkillInstance = SkillInstance.new(skill_data, supports)
	var si_total: float = si.get_total_damage(_get_base_damage_for_skill)
	if si_total > 0.0:
		var placeholder_base: float = _get_base_damage_for_skill(skill_data)
		if placeholder_base > 0.0:
			var ratio: float = dmg / placeholder_base
			dmg = si_total * ratio
		else:
			dmg = si_total
	
	var enemies := _find_enemies_in_radius(global_position, melee_range)
	for e in enemies:
		if not is_instance_valid(e) or not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		h.take_damage(dmg, self, skill_data.tags.duplicate())
		_spawn_blood_effect(e.global_position)

func _find_enemy_at_mouse_pos(mouse_pos: Vector2) -> Node:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collision_mask = 1  # default layer
	var results := space_state.intersect_point(query, 8)
	for r in results:
		var collider := r.get("collider") as Node
		if collider and collider.is_in_group("enemy") and collider != self:
			return collider
	# 2. deneme: 15px yaricapli daire ile daha genis ara (hassasiyet artir)
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	var sq := PhysicsShapeQueryParameters2D.new()
	sq.shape = circle
	sq.transform = Transform2D(0.0, mouse_pos)
	sq.collision_mask = 1
	var shape_results := space_state.intersect_shape(sq, 4)
	for r in shape_results:
		var collider := r.get("collider") as Node
		if collider and collider.is_in_group("enemy") and collider != self:
			return collider
	return null

func _find_nearest_enemy(max_dist: float = 200.0) -> Node:
	"""En yakin canli dusmani bul."""
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var nearest: Node = null
	var nearest_dist: float = max_dist + 1.0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	if nearest_dist <= max_dist:
		return nearest
	return null

func _find_enemies_in_radius(center: Vector2, radius: float) -> Array[Node]:
	"""Belirtilen merkez etrafindaki yaricap icindeki tum dusmanlari bul."""
	var result: Array[Node] = []
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		var d: float = center.distance_to(e.global_position)
		if d <= radius:
			result.append(e)
	return result

## Bir dusman haric en yakin canli düsmani bul (chain icin).
func _find_nearest_enemy_except(from: Vector2, except: Node) -> Node:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var nearest: Node = null
	var nearest_dist: float = 500.0
	for e in enemies:
		if not is_instance_valid(e) or e == except:
			continue
		if not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		var d: float = from.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = e
	return nearest

## Belirtilen skill resource path'i icin kurulu support gem'leri dondurur.
func _get_supports_for_skill(skill_path: String) -> Array[Variant]:
	"""5 slotluk support dizisi dondurur (icinde SupportData veya null)."""
	if skill_setups.has(skill_path):
		var setup: Dictionary = skill_setups[skill_path]
		if setup.has("supports"):
			var s: Array = setup["supports"]
			while s.size() < 5:
				s.append(null)
			return s
	# Skill yoksa 5 bos slot olustur ve kaydet
	var new_supports: Array = [null, null, null, null, null]
	skill_setups[skill_path] = {"supports": new_supports}
	return new_supports

## Skill kurulumundaki dolu support gem'leri dondurur (null'lari filtreler).
func _get_active_supports_for_skill(skill_path: String) -> Array[SupportData]:
	var all_slots: Array = _get_supports_for_skill(skill_path)
	var result: Array[SupportData] = []
	for s in all_slots:
		if s is SupportData:
			result.append(s)
	return result

## SkillInstance'i yeniden olusturur — her support ekleme/cikarmada cagrilir.
func _rebuild_skill_instance() -> void:
	if not _normal_attack_skill:
		return
	var supports: Array[SupportData] = _get_active_supports_for_skill("res://data/skills/normal_attack.tres")
	_skill_instance = SkillInstance.new(_normal_attack_skill, supports)
	_apply_support_stat_mods()

## TÃ¼m hotbar skill'lerinin support gem'lerinden gelen non-damage stat
## modifier'larÄ±nÄ± toplar ve stats'a uygular (critical_chance, life_leech, culling vb.)
## skill_setups'tan SkillData cache'ini al (load() gerektirmez)
func _get_skill_data_from_setup(skill_path: String) -> SkillData:
	if skill_path.is_empty():
		return null
	var setup: Dictionary = skill_setups.get(skill_path, {})
	if setup.has("skill") and setup["skill"] is SkillData:
		return setup["skill"] as SkillData
	# Fallback: dogrudan yukle
	if ResourceLoader.exists(skill_path):
		return load(skill_path) as SkillData
	return null

func _apply_support_stat_mods() -> void:
	if not stats or not hotbar:
		return
	var inc_total: Dictionary = {}
	var flat_total: Dictionary = {}
	for hb_path in hotbar:
		if hb_path.is_empty():
			continue
		var sd: SkillData = _get_skill_data_from_setup(hb_path)
		if not sd:
			continue
		var supps: Array[SupportData] = _get_active_supports_for_skill(hb_path)
		if supps.is_empty():
			continue
		var si := SkillInstance.new(sd, supps)
		var mods: Dictionary = si.get_non_damage_modifiers()
		var inc_part: Dictionary = mods.get("inc", {})
		var flat_part: Dictionary = mods.get("flat", {})
		for k in inc_part:
			inc_total[k] = inc_total.get(k, 0.0) + inc_part[k]
		for k in flat_part:
			flat_total[k] = flat_total.get(k, 0.0) + flat_part[k]
	
	if inc_total.is_empty():
		stats.remove_buff_modifier("support_gems_inc")
	else:
		stats.apply_buff_modifier("support_gems_inc", inc_total)
	if flat_total.is_empty():
		stats.remove_buff_flat_modifier("support_gems_flat")
	else:
		stats.apply_buff_flat_modifier("support_gems_flat", flat_total)

## Bir skill'in belirtilen slot'una support gem ekler.
## slot_index: 0-4 arasi. Silinecek support varsa once gem_stash'e ekle.
func socket_support(skill_path: String, slot_index: int, support: SupportData) -> void:
	if slot_index < 0 or slot_index > 4:
		return
	if not support:
		return
	# Gem stash'ten cikar
	var idx := gem_stash.find(support)
	if idx >= 0:
		gem_stash.remove_at(idx)
	else:
		# Stash'te yoksa kopya olusturmayi reddet
		return
	
	var all_slots: Array = _get_supports_for_skill(skill_path)
	# Slotta eski support varsa onu stash'e geri koy
	if all_slots[slot_index] is SupportData:
		gem_stash.append(all_slots[slot_index] as SupportData)
	all_slots[slot_index] = support
	
	# SkillInstance'i yeniden olustur
	_rebuild_skill_instance()
	# Infernal Circle aktifse support degisikligini uygula
	_refresh_infernal_circle_supports(skill_path)

## Bir skill slot'undaki support gem'i cikarir ve stash'e dondurur.
func unsocket_support(skill_path: String, slot_index: int) -> void:
	if slot_index < 0 or slot_index > 4:
		return
	var all_slots: Array = _get_supports_for_skill(skill_path)
	if all_slots[slot_index] is SupportData:
		gem_stash.append(all_slots[slot_index] as SupportData)
		all_slots[slot_index] = null
		_rebuild_skill_instance()
		_refresh_infernal_circle_supports(skill_path)

## Gem stash'e yeni bir support gem ekler (dusman drop'u).
func add_to_gem_stash(support: SupportData) -> void:
	if support:
		gem_stash.append(support)

## Item affix'lerinden "adds_X_damage" türlerini toplar.
## Returns: {"physical": {"min": 0.0, "max": 0.0}, "fire": {...}, ...}
static func _get_adds_damage_from_affixes(wp: ItemData) -> Dictionary:
	var result: Dictionary = {}
	if not wp or wp.affixes.is_empty():
		return result
	var dmg_keys := {
		"adds_physical_damage": "physical",
		"adds_fire_damage": "fire",
		"adds_cold_damage": "cold",
		"adds_lightning_damage": "lightning",
		"adds_chaos_damage": "chaos"
	}
	for a in wp.affixes:
		if not a or not a.stat_name.begins_with("adds_"):
			continue
		var dmg_type: String = dmg_keys.get(a.stat_name, "")
		if dmg_type.is_empty():
			continue
		# Affix.value tek bir sayı, range = value*0.6 ~ value*1.4
		var range_min: float = floorf(a.value * 0.6)
		var range_max: float = ceilf(a.value * 1.4)
		if not result.has(dmg_type):
			result[dmg_type] = {"min": 0.0, "max": 0.0}
		result[dmg_type].min += range_min
		result[dmg_type].max += range_max
	return result

## Oyuncunun silahından base hasar aralığını hesaplar (min, max).
## _get_basic_damage() ile aynı mantık ama random yok — tooltip için.
func _calculate_weapon_damage_range() -> Dictionary:
	"""Returns {min: float, max: float, unarmed: bool} for the player's weapon(s).
	Dual wield: hem WEAPON hem OFFHAND slot'undaki silahların hasarları toplanır."""
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	if not weapon:
		var unarmed_dmg: float = 20.0
		if stats:
			unarmed_dmg *= 1.0 + stats.strength * 0.02
		unarmed_dmg *= 3.0
		return {"min": unarmed_dmg, "max": unarmed_dmg, "unarmed": true}
	
	# Main weapon hasarını hesapla (base + affix)
	var result := _calc_single_weapon_range(weapon)
	
	# Dual wield: offhand hasarinin %50'si eklenir (denge için)
	var offhand: ItemData = equipment.get_item_in_slot(Equipment.Slot.OFFHAND)
	if offhand and (offhand.base_physical_damage_min > 0.0 or offhand.base_physical_damage_max > 0.0):
		var off_range := _calc_single_weapon_range(offhand)
		result.min += off_range.min * 0.5
		result.max += off_range.max * 0.5
	
	return result

## Tek bir silahın stat scaling + 8x carpan ile hasar aralığını hesaplar.
## SADECE base fiziksel hasar — affix hasarları ayrı eklenir.
func _calc_single_weapon_range(wp: ItemData) -> Dictionary:
	var qm: float = wp.get_quality_multiplier()
	var min_d: float = wp.base_physical_damage_min * qm
	var max_d: float = wp.base_physical_damage_max * qm
	if max_d <= 0.0:
		max_d = 1.0
	
	var wt: String = wp.weapon_type
	var stat_val: float = 0.0
	if stats:
		match wt:
			"sword", "dagger", "axe":
				stat_val = stats.strength
			"bow":
				stat_val = stats.dexterity
			"staff", "wand":
				stat_val = stats.intelligence
	var stat_mult: float = 1.0 + stat_val * 0.02
	# Staff/wand ekstra scaling
	if wt in ["staff", "wand"]:
		stat_mult *= 1.0 + stat_val * 0.01
	# Elemental damage sadece staff/wand'da var (diğer silahlarda base'de elemental olmaz)
	if wp.base_elemental_damage > 0.0 and wt in ["staff", "wand"]:
		min_d += wp.base_elemental_damage
		max_d += wp.base_elemental_damage
	
	var dmg_min: float = min_d * stat_mult * 8.0
	var dmg_max: float = max_d * stat_mult * 8.0
	return {"min": dmg_min, "max": dmg_max}

## get_base_damage_for_skill: skill damage x damage_effectiveness
## Spells: skill'in own base_damage kullanir (PoE tarzi, weapon damage yok)
## Attacks: weapon damage kullanir
func _get_base_damage_for_skill(skill: SkillData) -> float:
	# Spells don't use weapon damage - use skill's own base_damage
	if skill.is_spell():
		return skill.base_damage
	# Attacks use weapon damage
	var wr := _calculate_weapon_damage_range()
	var weapon_damage: float = (wr.min + wr.max) / 2.0
	return weapon_damage * skill.damage_effectiveness

## SkillInstance sistemini test et — konsola dogrulama yazdir
func _verify_support_system() -> void:
	if not _normal_attack_skill or not _skill_instance:
		print("SKILL INSTANCE: Normal Attack skill yuklenemedi!")
		return
	
	print("\n========== SUPPORT GEM SISTEMI DOGRULAMA ==========")
	print("Skill: ", _normal_attack_skill.display_name)
	print("  Tags: ", _normal_attack_skill.tags)
	print("  Damage Buckets: ", _normal_attack_skill.damage_buckets)
	print("  Damage Effectiveness: ", _normal_attack_skill.damage_effectiveness)
	print("  Base Damage (placeholder weapon): ", _get_base_damage_for_skill(_normal_attack_skill))
	print("")
	
	# TEST 1: Support'suz temel hasar
	var _base_total: float = _get_base_damage_for_skill(_normal_attack_skill)
	var dmg_no_supp: Dictionary = _skill_instance.get_final_damage(_get_base_damage_for_skill)
	print("--- TEST 1: Support'suz Normal Attack ---")
	for bt in dmg_no_supp:
		print("  ", bt, " damage: ", dmg_no_supp[bt])
	print("  Toplam: ", _skill_instance.get_total_damage(_get_base_damage_for_skill))
	print("  (Beklenen: physical=30.0, toplam=30.0)")
	print("")
	
	# TEST 2: Melee Physical Damage Support (30% increased Physical Damage)
	var supp1_path := "res://data/supports/melee_physical_damage.tres"
	if ResourceLoader.exists(supp1_path):
		var supp1: SupportData = load(supp1_path)
		var supports2: Array[SupportData] = [supp1]
		var si2: SkillInstance = SkillInstance.new(_normal_attack_skill, supports2)
		var dmg_supp1: Dictionary = si2.get_final_damage(_get_base_damage_for_skill)
		var active2: Array = si2.get_active_supports()
		var rejected2: Array = si2.get_rejected_supports(supports2)
		print("--- TEST 2: +Melee Physical Damage Support (%30 increased Physical) ---")
		print("  Aktif support'lar: ", active2.size(), " (beklenen: 1)")
		print("  Reddedilen support'lar: ", rejected2.size(), " (beklenen: 0)")
		for bt in dmg_supp1:
			print("  ", bt, " damage: ", dmg_supp1[bt])
		print("  Toplam: ", si2.get_total_damage(_get_base_damage_for_skill))
		print("  ELDE HESAP: (30 + 0) x (1 + 30/100) = 30 x 1.30 = 39.0")
		print("")
	
	# TEST 3: Melee Physical Damage + Brutality (30% increased + 49% more)
	var brutality_path := "res://data/supports/brutal_damage.tres"
	if ResourceLoader.exists(brutality_path):
		var supp1: SupportData = load(supp1_path)
		var supp2: SupportData = load(brutality_path)
		var supports3: Array[SupportData] = [supp1, supp2]
		var si3: SkillInstance = SkillInstance.new(_normal_attack_skill, supports3)
		var dmg_supp2: Dictionary = si3.get_final_damage(_get_base_damage_for_skill)
		var active3: Array = si3.get_active_supports()
		var rejected3: Array = si3.get_rejected_supports(supports3)
		print("--- TEST 3: +Melee Physical (%30 increased) + Brutality (%49 more) ---")
		print("  Aktif support'lar: ", active3.size(), " (beklenen: 2)")
		print("  Reddedilen support'lar: ", rejected3.size(), " (beklenen: 0)")
		for bt in dmg_supp2:
			print("  ", bt, " damage: ", dmg_supp2[bt])
		print("  Toplam: ", si3.get_total_damage(_get_base_damage_for_skill))
		print("  ELDE HESAP: (30 + 0) x (1 + 30/100) x 1.49 = 30 x 1.30 x 1.49 = 58.11")
		print("")
	
	# TEST 4: Tag uyumsuzlugu — Projectile Support Melee skill'de calismamali
	var proj_path := "res://data/supports/projectile_support.tres"
	if ResourceLoader.exists(proj_path):
		var supp_bad: SupportData = load(proj_path)
		var supports4: Array[SupportData] = [supp_bad]
		var si4: SkillInstance = SkillInstance.new(_normal_attack_skill, supports4)
		var active4: Array = si4.get_active_supports()
		var rejected4: Array = si4.get_rejected_supports(supports4)
		print("--- TEST 4: Tag Uyumsuzlugu (Projectile Support -> Melee skill) ---")
		print("  Skill tags: ", _normal_attack_skill.tags)
		print("  Support allowed_tags: ", supp_bad.allowed_tags)
		print("  Aktif support'lar: ", active4.size(), " (beklenen: 0 — uyumsuz!)")
		print("  Reddedilen support'lar: ", rejected4.size(), " (beklenen: 1)")
		if rejected4.size() > 0:
			print("  Reddedilen: ", rejected4[0].display_name)
		var dmg_no_change: Dictionary = si4.get_final_damage(_get_base_damage_for_skill)
		print("  Hasar (support reddedildigi icin degismemeli):")
		for bt in dmg_no_change:
			print("    ", bt, " damage: ", dmg_no_change[bt])
		print("  Toplam: ", si4.get_total_damage(_get_base_damage_for_skill))
		print("  Beklenen: 30.0 (support uygulanmadigi icin base hasar)")
		print("")
	
	print("========== DOGRULAMA TAMAMLANDI ==========\n")

func _get_basic_damage(weapon: ItemData) -> Array:  # [damage_float, damage_type_string]
	if not weapon:
		var unarmed_dmg: float = 20.0
		if stats:
			unarmed_dmg *= 1.0 + stats.strength * 0.02
		unarmed_dmg *= 3.0
		# Pasif/affix increased damage uygula
		if stats:
			var inc_dmg: float = stats.all_damage_increased + stats.physical_damage_increased
			if inc_dmg != 0.0:
				unarmed_dmg *= 1.0 + inc_dmg / 100.0
		return [unarmed_dmg, "physical"]
	var qm: float = weapon.get_quality_multiplier()
	var min_d: float = weapon.base_physical_damage_min * qm
	var max_d: float = weapon.base_physical_damage_max * qm
	var dmg: float = 0.0
	var dmg_type: String = "physical"
	if max_d > 0:
		dmg = randf_range(min_d, max_d)

	if weapon.weapon_type == "staff" or weapon.weapon_type == "wand":
		dmg += weapon.base_elemental_damage * qm
		if weapon.base_elemental_damage > weapon.base_physical_damage_max:
			dmg_type = "fire"
	# STAT SCALING: güç/çeviklik/zeka hasarı artırır
	var wt: String = weapon.weapon_type
	var stat_val: float = 0.0
	if stats:
		match wt:
			"sword", "dagger", "axe":
				stat_val = stats.strength
			"bow":
				stat_val = stats.dexterity
			"staff", "wand":
				stat_val = stats.intelligence
	dmg *= 1.0 + stat_val * 0.02
	# Staff/wand ekstra int scaling (daha fazla büyü gücü)
	if wt in ["staff", "wand"]:
		dmg *= 1.0 + stat_val * 0.01
	# ANA HASAR CARPANI: base degerler dusuk oldugu icin 8x
	dmg *= 8.0
	
	# Affix'lerden gelen adds_X_damage flat olarak ekle (stat scaling yok)
	var adds: Dictionary = _get_adds_damage_from_affixes(weapon)
	for a_type in adds:
		var affix_range = adds[a_type]
		dmg += randf_range(affix_range.min, affix_range.max)
	
	# --- DUAL WIELD: Offhand silah hasarinin %50'sini ek (çift silah avantaji + hiz bonusu)
	if stats and stats.is_dual_wielding:
		var offhand: ItemData = equipment.get_item_in_slot(Equipment.Slot.OFFHAND)
		if offhand:
			var off_qm: float = offhand.get_quality_multiplier()
			var off_min: float = offhand.base_physical_damage_min * off_qm
			var off_max: float = offhand.base_physical_damage_max * off_qm
			var off_dmg: float = 0.0
			if off_max > 0.0:
				off_dmg = randf_range(off_min, off_max)
			if offhand.weapon_type in ["staff", "wand"]:
				off_dmg += offhand.base_elemental_damage * off_qm
			var off_stat: float = 0.0
			if stats:
				match offhand.weapon_type:
					"sword", "dagger", "axe":
						off_stat = stats.strength
					"bow":
						off_stat = stats.dexterity
					"staff", "wand":
						off_stat = stats.intelligence
			off_dmg *= 1.0 + off_stat * 0.02
			if offhand.weapon_type in ["staff", "wand"]:
				off_dmg *= 1.0 + off_stat * 0.01
			off_dmg *= 8.0
			dmg += off_dmg * 0.5  # Sadece %50'si eklenir (denge için)

	# Affix'lerden gelen flat elemental hasari ekle (adds_fire/cold/lightning/chaos_damage)
	if stats:
		var flat_total: float = 0.0
		if stats.fire_damage_flat > 0.0:
			flat_total += stats.fire_damage_flat
		if stats.cold_damage_flat > 0.0:
			flat_total += stats.cold_damage_flat
		if stats.lightning_damage_flat > 0.0:
			flat_total += stats.lightning_damage_flat
		if stats.chaos_damage_flat > 0.0:
			flat_total += stats.chaos_damage_flat
		if flat_total > 0.0:
			dmg += flat_total

	# Pasif ağacı ve eşya affix'lerinden gelen increased damage uygula
	if stats:
		var inc_dmg: float = stats.all_damage_increased
		match dmg_type:
			"physical":
				inc_dmg += stats.physical_damage_increased
			"fire":
				inc_dmg += stats.fire_damage_increased + stats.elemental_damage_increased
			"cold":
				inc_dmg += stats.cold_damage_increased + stats.elemental_damage_increased
			"lightning":
				inc_dmg += stats.lightning_damage_increased + stats.elemental_damage_increased
		if inc_dmg != 0.0:
			dmg *= 1.0 + inc_dmg / 100.0
	
	# SkillInstance tabanli support gem hesaplamasi
	if _skill_instance != null:
		var si_total: float = _skill_instance.get_total_damage(_get_base_damage_for_skill)
		if si_total > 0.0:
			var placeholder_base: float = _get_base_damage_for_skill(_normal_attack_skill)
			if placeholder_base > 0.0:
				var ratio: float = dmg / placeholder_base
				dmg = si_total * ratio
			else:
				dmg = si_total
	
	# Minimum 1 damage
	if dmg < 1.0:
		dmg = 1.0
	return [dmg, dmg_type]

func _do_melee_basic(primary_enemy: Node) -> void:
	var dist: float = global_position.distance_to(primary_enemy.global_position)
	var melee_range: float = BASIC_MELEE_RANGE
	if stats and stats.melee_range_bonus > 0.0:
		melee_range += stats.melee_range_bonus * 35.0
	if dist > melee_range:
		return  # too far
	
	EventBus.skill_cast.emit("res://data/skills/normal_attack.tres", self)
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	var dmg_type: String = dmg_arr[1] as String
	
	# Support gem'lerden tag'leri ve chain'i al
	var tags: Array[String] = ["attack", "melee"]
	var aoe_radius: float = get_basic_attack_aoe_radius()
	var melee_chain_support: int = 0
	for sd in _get_active_supports_for_skill("res://data/skills/normal_attack.tres"):
		if sd:
			for t in sd.added_tags:
				if not t in tags:
					tags.append(t)
			melee_chain_support += sd.extra_trigger_count
	tags.append(dmg_type)
	# AoE tag'i varsa ekle (yaricap 1px'den buyukse AoE sayilir)
	if aoe_radius > 2.0 and not "aoe" in tags:
		tags.append("aoe")
	
	# Hedefleri bul: birincil hedef + AoE icindeki diger dusmanlar
	var target_pos: Vector2 = primary_enemy.global_position
	var enemies: Array[Node] = _find_enemies_in_radius(target_pos, aoe_radius)
	# Her zaman birincil hedefin dahil oldugundan emin ol
	if not primary_enemy in enemies:
		enemies.append(primary_enemy)
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.has_node("Health"):
			continue
		var h := enemy.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		
		# Skill seviyesi carpani (basic attack icin)
		var na_level: int = _skill_levels.get("res://data/skills/normal_attack.tres", 1)
		var level_dmg: float = dmg * (1.0 + (na_level - 1) * 0.25)
		
		# Accuracy check via CombatEngine
		var defender_stats: CharacterStats = enemy.get_node_or_null("CharacterStats") as CharacterStats
		var hit_result: Dictionary = {"hit": true, "damage": level_dmg, "is_crit": false, "is_evaded": false, "ailment_power": level_dmg * 0.5}
		if stats and defender_stats:
			hit_result = CombatEngine.calculate_hit(stats, defender_stats, level_dmg, dmg_type, tags, false, enemy, self)
		
		if hit_result.hit:
			var hit_pen: float = hit_result.get("penetration", 0.0)
			var _result: Dictionary = h.take_damage(hit_result.damage, self, tags, false, hit_pen)
			_spawn_basic_hit_effect(enemy.global_position + Vector2(randf_range(-8,8), randf_range(-8,8)))
			# Ailment uygula (örneğin ignite, chill, freeze, shock, poison, bleed)
			if enemy.has_node("AilmentController"):
				var ac := enemy.get_node("AilmentController") as AilmentController
				AilmentUtils.apply_ailments_for_tags(ac, hit_result, stats, h.max_health, tags, self)
		else:
			_spawn_miss_effect(enemy.global_position)
	
	# --- Splash Damage: Pasif agacindaki "Strikes deal Splash Damage" node'lari icin ---
	var has_splash: bool = stats and stats.splash_damage
	if has_splash:
		var splash_targets: Array[Node] = _find_enemies_in_radius(target_pos, stats.splash_radius)
		for enemy in splash_targets:
			# Zaten tam hasar alanlari atla (birincil hedef + AoE icindekiler)
			if enemy in enemies:
				continue
			if not is_instance_valid(enemy) or not enemy.has_node("Health"):
				continue
			var sh := enemy.get_node("Health") as Health
			if sh.current_health <= 0:
				continue
			
			var splash_dmg: float = dmg * (stats.splash_damage_percent / 100.0)
			var splash_def_stats: CharacterStats = enemy.get_node_or_null("CharacterStats") as CharacterStats
			var splash_hit: Dictionary = {"hit": true, "damage": splash_dmg, "is_crit": false, "is_evaded": false, "ailment_power": splash_dmg * 0.5}
			if stats and splash_def_stats:
				splash_hit = CombatEngine.calculate_hit(stats, splash_def_stats, splash_dmg, dmg_type, tags, false, enemy, self)
			
			if splash_hit.hit:
				var splash_pen: float = splash_hit.get("penetration", 0.0)
				sh.take_damage(splash_hit.damage, self, tags, false, splash_pen)
				_spawn_basic_hit_effect(enemy.global_position + Vector2(randf_range(-8,8), randf_range(-8,8)))
				if enemy.has_node("AilmentController"):
					var ac_splash := enemy.get_node("AilmentController") as AilmentController
					AilmentUtils.apply_ailments_for_tags(ac_splash, splash_hit, stats, sh.max_health, tags, self)
	
	# --- Chain Support: melee vuruşu chain projectile fırlatır ---
	if melee_chain_support > 0:
		var chain_tex: String = ""
		match dmg_type:
			"fire": chain_tex = "res://assets/generated/proj_fireball_anim.png"
			_: chain_tex = "res://assets/generated/proj_arrow_frame_0.png"
		var total_chain: int = melee_chain_support
		if stats:
			total_chain += stats.chain_count
		# Birincil hedefin olduğu yerden chain projectile'ı başlat
		var chain_proj: Projectile = _basic_projectile_scene.instantiate()
		get_tree().current_scene.add_child(chain_proj)
		chain_proj.global_position = primary_enemy.global_position
		chain_proj.speed = 350.0
		chain_proj.lifetime = 1.0
		chain_proj.chain_count = total_chain
		# Yönü en yakın diğer düşmana doğru ayarla
		var chain_dir: Vector2 = Vector2.RIGHT
		var nearest_other: Node = _find_nearest_enemy_except(primary_enemy.global_position, primary_enemy)
		if nearest_other:
			chain_dir = (nearest_other.global_position - primary_enemy.global_position).normalized()
		chain_proj.setup(primary_enemy.global_position + chain_dir * 200.0, dmg, tags, self, chain_tex, "", "chain_melee", false, 0.0, dmg_type)
		chain_proj.set_meta("attacker_stats", stats)

func _do_ranged_basic(target_pos: Vector2, wtype: String, weapon: ItemData) -> void:
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	var dmg_type: String = dmg_arr[1] as String
	
	var tex: String
	var hit_tex: String
	var proj_speed: float = 400.0
	var lifetime: float = 1.5
	
	match wtype:
		"bow":
			tex = "res://assets/generated/proj_arrow_frame_0.png"
			hit_tex = "res://assets/generated/hit_slash_arc_new.png"
			dmg_type = "physical"
			proj_speed = 450.0
		"staff", "wand":
			tex = "res://assets/generated/proj_fireball_anim.png"
			hit_tex = "res://assets/generated/hit_fire_explosion_new.png"
			if dmg_type == "physical":
				dmg_type = "fire"
			proj_speed = 350.0
		_:
			tex = "res://assets/generated/proj_arrow_frame_0.png"
			hit_tex = "res://assets/generated/hit_slash_arc_new.png"
	
	# Passive ağacından % increased Projectile Speed uygula
	if stats and stats.projectile_speed > 0.0:
		proj_speed *= (1.0 + stats.projectile_speed / 100.0)
	
	# Support gem'lerden tag, extra projectile ve chain
	var tags: Array[String] = ["attack", "ranged"]
	var extra_proj: int = 0
	var chain_from_supports: int = 0
	for sd in _get_active_supports_for_skill("res://data/skills/normal_attack.tres"):
		if sd:
			for t in sd.added_tags:
				if not t in tags:
					tags.append(t)
			extra_proj += sd.extra_projectiles
			chain_from_supports += sd.extra_trigger_count
	tags.append(dmg_type)
	
	# Ana mermi
	var proj: Projectile = _basic_projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.speed = proj_speed
	proj.lifetime = lifetime
	proj.setup(target_pos, dmg, tags, self, tex, hit_tex, "basic_attack", false, 0.0, dmg_type)
	proj.set_meta("attacker_stats", stats)
	# Chain count (aura + pasif ağacı + support gem'lerden)
	if stats:
		proj.chain_count = stats.chain_count + chain_from_supports
	
	# Ekstra mermiler (support gem'lerden)
	if extra_proj > 0:
		var base_dir: Vector2 = (target_pos - global_position).normalized()
		var spread_angle: float = PI / 8.0  # ~22.5 derece
		for ei in range(extra_proj):
			var angle_off: float = spread_angle * (ei + 1) * (1 if ei % 2 == 0 else -1) * 0.5
			var dir: Vector2 = base_dir.rotated(angle_off)
			var offset_pos: Vector2 = global_position + dir * 16.0
			var extra := _basic_projectile_scene.instantiate()
			get_tree().current_scene.add_child(extra)
			extra.global_position = offset_pos
			extra.speed = proj_speed
			extra.lifetime = lifetime
			extra.setup(target_pos, dmg, tags, self, tex, hit_tex, "basic_attack", false, 0.0, dmg_type)
			extra.set_meta("attacker_stats", stats)
			# Chain count da ekstra mermilere aktar
			if stats:
				extra.chain_count = stats.chain_count + chain_from_supports

func _spawn_player_swing_effect(target_pos: Vector2) -> void:
	"""Düşman pozisyonunda mavi kesme efekti."""
	var tex_path := "res://assets/generated/hit_slash_arc_new.png"
	if not ResourceLoader.exists(tex_path):
		return
	var tex: Texture2D = load(tex_path)
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = _create_hit_frames(tex, 48, 48, 4, 16)
	asp.animation = "vfx"
	asp.centered = true
	asp.position = target_pos
	asp.z_index = 20
	asp.scale = Vector2(1.5, 1.5)
	asp.rotation = randf_range(0.0, 6.283)
	asp.modulate = Color(1.0, 1.0, 1.0, 0.7)
	get_tree().current_scene.add_child(asp)
	asp.play()
	asp.animation_finished.connect(func():
		if is_instance_valid(asp):
			asp.queue_free()
	, CONNECT_ONE_SHOT)

func _spawn_basic_hit_effect(pos: Vector2) -> void:
	"""Vuruş noktasında mavi kesme efekti + kan."""
	var tex_path := "res://assets/generated/hit_slash_arc_new.png"
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		var asp := AnimatedSprite2D.new()
		asp.sprite_frames = _create_hit_frames(tex, 48, 48, 4, 16)
		asp.animation = "vfx"
		asp.centered = true
		asp.position = pos
		asp.z_index = 15
		asp.scale = Vector2(1.2, 1.2)
		asp.modulate = Color(1.0, 1.0, 1.0, 0.6)
		get_tree().current_scene.add_child(asp)
		asp.play()
		asp.animation_finished.connect(func():
			if is_instance_valid(asp):
				asp.queue_free()
		, CONNECT_ONE_SHOT)
	# Kan efekti her vuruşta
	_spawn_blood_effect(pos)

func _spawn_blood_effect(pos: Vector2) -> void:
	var tex_path := "res://assets/generated/hit_blood_splatter.png"
	if not ResourceLoader.exists(tex_path):
		return
	var tex: Texture2D = load(tex_path)
	var asp := AnimatedSprite2D.new()
	asp.sprite_frames = _create_hit_frames(tex, 48, 48, 4, 16)
	asp.animation = "vfx"
	asp.centered = true
	asp.position = pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	asp.z_index = 11  # blood above other effects
	asp.scale = Vector2(0.7, 0.7)
	get_tree().current_scene.add_child(asp)
	asp.play()
	asp.animation_finished.connect(func():
		if is_instance_valid(asp):
			asp.queue_free()
	, CONNECT_ONE_SHOT)

func _spawn_miss_effect(pos: Vector2) -> void:
	# Floating "Iska!" text
	var lbl := Label.new()
	lbl.text = "Iska!"
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.position = pos - Vector2(20, 0)
	lbl.z_index = 20
	get_tree().current_scene.add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.8)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tween.finished.connect(func():
		if is_instance_valid(lbl):
			lbl.queue_free()
	)

static func _create_hit_frames(tex: Texture2D, fw: int, fh: int, cols: int, count: int) -> SpriteFrames:
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

func _spawn_movement_dust() -> void:
	"""Hareket ederken arkada kalan toz partikülleri — kaldirildi (kare efektler)"""
	pass

# ================== MOUSE CURSOR + ENEMY HIGHLIGHT ==================

func _update_target_hover(_mouse_global: Vector2) -> void:
	# Hover sistemi kaldirildi - cursor her zaman sabit
	pass

func _clear_hovered_enemy() -> void:
	_hovered_enemy = null


func _create_game_cursor() -> Texture2D:
	"""32x32 mavi parlayan crosshair cursor olustur."""
	const S := 32
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var c := 16  # center
	
	# Ana renkler
	var bright: Color = Color(0.6, 0.85, 1.0, 1.0)   # parlak mavi
	var mid: Color = Color(0.4, 0.6, 0.9, 0.9)        # orta mavi
	var dim: Color = Color(0.2, 0.35, 0.6, 0.5)       # soluk mavi
	
	# 1) Dikey cizgi (ince, 1px)
	for y in range(S):
		var dy: int = (y - c) if y >= c else (c - y)
		if dy < 2:
			img.set_pixel(c, y, mid)
		elif dy < 3:
			img.set_pixel(c, y, dim)
	# 2) Yatay cizgi (ince, 1px)
	for x in range(S):
		var dx: int = (x - c) if x >= c else (c - x)
		if dx < 2:
			img.set_pixel(x, c, mid)
		elif dx < 3:
			img.set_pixel(x, c, dim)
	
	# 3) Dis uclarda hafif genisleme (spikes)
	for i in range(3, 6):
		img.set_pixel(c + i, c - 1, dim)
		img.set_pixel(c + i, c + 1, dim)
		img.set_pixel(c - i, c - 1, dim)
		img.set_pixel(c - i, c + 1, dim)
		img.set_pixel(c - 1, c + i, dim)
		img.set_pixel(c + 1, c + i, dim)
		img.set_pixel(c - 1, c - i, dim)
		img.set_pixel(c + 1, c - i, dim)
	
	# 4) Merkez parlak nokta (5x5)
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var d: int = max(dx if dx >= 0 else -dx, dy if dy >= 0 else -dy)
			if d == 0:
				img.set_pixel(c + dx, c + dy, Color(1.0, 1.0, 1.0, 1.0))
			elif d == 1:
				img.set_pixel(c + dx, c + dy, bright)
			elif d == 2:
				img.set_pixel(c + dx, c + dy, mid)
	
	return ImageTexture.create_from_image(img)


# ================== HOTBAR SYSTEM ==================

func _process(delta: float) -> void:
	# Skill cooldown'lari guncelle
	for path in _skill_cooldowns.keys():
		_skill_cooldowns[path] = maxf(_skill_cooldowns[path] - delta, 0.0)
	
	# ===== VS OTOMATIK SALDIRI SISTEMI =====
	if not _is_any_ui_open() and not get_tree().paused:
		# Auto basic attack
		_auto_attack_timer -= delta
		if _auto_attack_timer <= 0.0:
			_vs_auto_attack()
		
		# Auto skill cast
		for skill_path in vs_skills:
			if not _auto_skill_timers.has(skill_path):
				_auto_skill_timers[skill_path] = 0.0
			_auto_skill_timers[skill_path] -= delta
			if _auto_skill_timers[skill_path] <= 0.0:
				_vs_auto_cast_skill(skill_path)
	
	# Infernal Circle can drain
	_process_infernal_circle_drain(delta)


func cast_hotbar_skill(slot_idx: int) -> void:
	"""Hotbar'daki bir skill'i kullan."""
	if slot_idx < 0 or slot_idx >= hotbar.size():
		return
	var skill_path: String = hotbar[slot_idx]
	if skill_path.is_empty():
		return
	if not ResourceLoader.exists(skill_path):
		return
	
	var skill_data: SkillData = _get_skill_data_from_setup(skill_path)
	if not skill_data:
		return
	
	# Animasyon kontrolu
	if _attack_anim_timer > 0.0:
		return
	
	# Cooldown kontrolu (cooldown_recovery'den etkilenmiş haliyle)
	if _skill_cooldowns.has(skill_path) and _skill_cooldowns[skill_path] > 0.0:
		return
	
	# ---- BUFF/AURA toggle sistemi (once, cooldown/mana gerektirmez) ----
	if skill_data.is_buff() or skill_data.is_aura():
		_toggle_buff_skill(skill_data, skill_path)
		return
	
	# Mana/life cost sistemi kaldirildi (VS modunda mana yok)
	
	# Simdi cooldown baslat
	if skill_data.cooldown > 0.0:
		var recovery_mult: float = 1.0
		if stats and stats.cooldown_recovery > 0.0:
			recovery_mult = 1.0 + stats.cooldown_recovery / 100.0
		_skill_cooldowns[skill_path] = skill_data.cooldown / recovery_mult
	
	match skill_data.id:
		"normal_attack":
			_cast_normal_attack()
		"fireball":
			_cast_fireball(skill_data)
		"ice_nova":
			_cast_ice_nova(skill_data)
		"slice_wave":
			_cast_slice_wave(skill_data)
		"dash":
			_cast_dash(skill_data)
		"infernal_circle":
			_toggle_infernal_circle(skill_data, skill_path)
		# VS benzersiz skill'ler — manual cast da destek, en yakın düşmanı bul
		"fire_bolt", "ice_shard", "lightning_chain", "arcane_orb", "toxic_circle", "whirlwind", "dark_beam", "holy_nova", "thunder_strike", "frost_explosion":
			var vs_nearest := _find_nearest_enemy(500.0)
			if not vs_nearest or not is_instance_valid(vs_nearest):
				return
			var vs_skill_path: String = skill_path
			match skill_data.id:
				"fire_bolt": _cast_fire_bolt_vs(skill_data, vs_nearest, vs_skill_path)
				"ice_shard": _cast_ice_shard_vs(skill_data, vs_nearest, vs_skill_path)
				"lightning_chain": _cast_lightning_chain_vs(skill_data, vs_nearest, vs_skill_path)
				"arcane_orb": _cast_arcane_orb_vs(skill_data, vs_nearest, vs_skill_path)
				"toxic_circle": _cast_toxic_circle_vs(skill_data, vs_nearest, vs_skill_path)
				"whirlwind": _cast_whirlwind_vs(skill_data, vs_nearest, vs_skill_path)
				"dark_beam": _cast_dark_beam_vs(skill_data, vs_nearest, vs_skill_path)
				"holy_nova": _cast_holy_nova_vs(skill_data, vs_nearest, vs_skill_path)
				"thunder_strike": _cast_thunder_strike_vs(skill_data, vs_nearest, vs_skill_path)
				"frost_explosion": _cast_frost_explosion_vs(skill_data, vs_nearest, vs_skill_path)
		_:
			# Bilinmeyen skill - normal attack yap
			_cast_normal_attack()

func _cast_normal_attack() -> void:
	"""Normal Attack - basit saldiri (melee/ranged)."""
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var wtype: String = weapon.weapon_type if weapon else "sword"
	match wtype:
		"sword", "dagger", "axe":
			_try_basic_attack()
		"bow", "staff", "wand":
			_try_basic_attack()
		_:
			_try_basic_attack()

func _cast_fireball(skill_data: SkillData) -> void:
	"""Fireball: hedefe dogru ates topu mermisi firlat. Dusman yoksa fare yonune ates et."""
	var target_pos: Vector2 = get_global_mouse_position()
	var enemy := _find_enemy_at_mouse_pos(target_pos)
	# Dusman yoksa bile fare yonune mermi at (hedefsiz)
	var has_target: bool = enemy != null and is_instance_valid(enemy)
	var aim_pos: Vector2 = enemy.global_position if has_target else target_pos
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	
	# SkillInstance ile support gem'leri uygula (fireball skill path'inden)
	var fireball_path: String = hotbar[_find_hotbar_idx("fireball")]
	var fireball_supports: Array[SupportData] = _get_active_supports_for_skill(fireball_path)
	var si_fb: SkillInstance = SkillInstance.new(skill_data, fireball_supports)
	var si_total: float = si_fb.get_total_damage(_get_base_damage_for_skill)
	if si_total > 0.0:
		var placeholder_base: float = _get_base_damage_for_skill(skill_data)
		if placeholder_base > 0.0:
			var ratio: float = dmg / placeholder_base
			dmg = si_total * ratio
		else:
			dmg = si_total
	
	var proj_instance := _basic_projectile_scene.instantiate() as Projectile
	if not proj_instance:
		return
	get_parent().add_child(proj_instance)
	proj_instance.global_position = global_position
	proj_instance.speed = 400.0
	if stats and stats.projectile_speed > 0.0:
		proj_instance.speed *= (1.0 + stats.projectile_speed / 100.0)
	proj_instance.pierce_count = 0
	proj_instance.area_damage_radius = 30.0
	# Chain count (aura + pasif ağacı + support gem'lerden)
	var chain_from_supports_fb: int = 0
	for sd in fireball_supports:
		if sd:
			chain_from_supports_fb += sd.extra_trigger_count
	if stats:
		proj_instance.chain_count = stats.chain_count + chain_from_supports_fb
	
	# Ekstra mermiler (support gem'lerden) - fireball için
	var extra_proj_fb: int = 0
	for sd in fireball_supports:
		if sd:
			extra_proj_fb += sd.extra_projectiles
	if extra_proj_fb > 0:
		var base_dir_fb: Vector2 = (aim_pos - global_position).normalized()
		var spread_angle_fb: float = PI / 8.0
		for ei in range(extra_proj_fb):
			var angle_off: float = spread_angle_fb * (ei + 1) * (1 if ei % 2 == 0 else -1) * 0.5
			var dir: Vector2 = base_dir_fb.rotated(angle_off)
			var offset_pos: Vector2 = global_position + dir * 16.0
			var extra_fb := _basic_projectile_scene.instantiate()
			get_parent().add_child(extra_fb)
			extra_fb.global_position = offset_pos
			extra_fb.speed = proj_instance.speed
			extra_fb.lifetime = 1.5
			extra_fb.setup(aim_pos, dmg, ["spell", "fire", "projectile"] as Array[String], self,
				"res://assets/generated/proj_fireball_anim.png",
				"res://assets/generated/vfx_fire_explosion.png", "fireball", false, 0.0, "fire")
			extra_fb.proj_anim_fw = 32
			extra_fb.proj_anim_fh = 32
			extra_fb.proj_anim_cols = 4
			extra_fb.proj_anim_count = 8
			extra_fb.proj_anim_fps = 12.0
			extra_fb.hit_effect_fw = 48
			extra_fb.hit_effect_fh = 48
			extra_fb.hit_effect_cols = 4
			extra_fb.hit_effect_count = 16
			if stats:
				extra_fb.chain_count = stats.chain_count + chain_from_supports_fb
			extra_fb.set_meta("attacker_stats", stats)
	
	# Fireball sprite'ini ayarla
	proj_instance.setup(
		aim_pos,
		dmg,
		["spell", "fire", "projectile"],
		self,
		"res://assets/generated/proj_fireball_anim.png",
		"res://assets/generated/vfx_fire_explosion.png",
		"fireball",
		false,
		0.0,
		"fire"
	)
	# Fireball animasyon frame bilgisi (metadata'dan)
	proj_instance.proj_anim_fw = 32
	proj_instance.proj_anim_fh = 32
	proj_instance.proj_anim_cols = 4
	proj_instance.proj_anim_count = 8
	proj_instance.proj_anim_fps = 12.0
	# Hit effect frame bilgisi
	proj_instance.hit_effect_fw = 48
	proj_instance.hit_effect_fh = 48
	proj_instance.hit_effect_cols = 4
	proj_instance.hit_effect_count = 16

func _cast_slice_wave(skill_data: SkillData, auto_target: Node = null) -> void:
	"""Kesme Dalgasi: fare yonune veya auto_target'e dogru bir dalga mermisi gonderir.
	100px mesafe gider, carptigi tum dusmanlara alan hasari verir.
	Projectile + AoE tag'leri sayesinde extra projectile, chain, AoE support'lar calisir."""
	var target_pos: Vector2
	var enemy: Node
	if auto_target and is_instance_valid(auto_target):
		enemy = auto_target
		target_pos = enemy.global_position
	else:
		target_pos = get_global_mouse_position()
		enemy = _find_enemy_at_mouse_pos(target_pos)
	var has_target: bool = enemy != null and is_instance_valid(enemy)
	var aim_pos: Vector2 = enemy.global_position if has_target else target_pos
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	
	# SkillInstance ile support gem'leri uygula
	var wave_path: String = hotbar[_find_hotbar_idx("slice_wave")]
	var wave_supports: Array[SupportData] = _get_active_supports_for_skill(wave_path)
	var si_sw: SkillInstance = SkillInstance.new(skill_data, wave_supports)
	var si_total: float = si_sw.get_total_damage(_get_base_damage_for_skill)
	if si_total > 0.0:
		var placeholder_base: float = _get_base_damage_for_skill(skill_data)
		if placeholder_base > 0.0:
			var ratio: float = dmg / placeholder_base
			dmg = si_total * ratio
		else:
			dmg = si_total
	
	# Wave projectile'i olustur
	var wave_scene: PackedScene = preload("res://scripts/slice_wave.tscn")
	var wave_proj := wave_scene.instantiate() as Projectile
	if not wave_proj:
		return
	get_parent().add_child(wave_proj)
	wave_proj.global_position = global_position
	
	# Wave: 100px gitsin -> speed 300, lifetime 0.35 = ~105px
	wave_proj.speed = 300.0
	if stats and stats.projectile_speed > 0.0:
		wave_proj.speed *= (1.0 + stats.projectile_speed / 100.0)
	wave_proj.lifetime = 0.35
	wave_proj.pierce_count = 99  # Tum dusmanlardan gecsin
	wave_proj.area_damage_radius = 60.0  # Genis AoE
	
	# Chain count (aura + pasif agaci + support gem'lerden)
	var chain_sw: int = 0
	for sd in wave_supports:
		if sd:
			chain_sw += sd.extra_trigger_count
	var main_chain: int = (stats.chain_count if stats else 0) + chain_sw
	wave_proj.chain_count = main_chain
	
	# Ekstra mermiler — her support kendi spread acisiyla dagilir
	var extra_proj_sw: int = 0
	var volley_count: int = 0
	for sd in wave_supports:
		if sd:
			if sd.id == "volley":
				volley_count += sd.extra_projectiles
			else:
				extra_proj_sw += sd.extra_projectiles
	var total_extra: int = extra_proj_sw + volley_count
	if total_extra > 0:
		var base_dir_sw: Vector2 = (aim_pos - global_position).normalized()
		# Ortak extra_proj spawn helper
		var _spawn_extra_wave := func(ei: int, count: int, spread_deg: float) -> void:
			var frac: float = float(ei + 1) / float(count + 1)
			var angle_off: float = lerp(deg_to_rad(-spread_deg), deg_to_rad(spread_deg), frac)
			var dir: Vector2 = base_dir_sw.rotated(angle_off)
			var offset_pos: Vector2 = global_position + dir * 16.0
			var extra_target: Vector2 = global_position + dir * 500.0
			var ex := wave_scene.instantiate()
			# Once add_child (projenin tree'ye eklenmesi lazim, _ready() tetiklenir)
			get_parent().add_child(ex)
			# Sonra property'leri ata (lifetime _ready() aninda default 2.0 alir, sorun degil)
			ex.global_position = offset_pos
			ex.speed = 300.0
			ex.lifetime = 1.5
			ex.pierce_count = 99
			ex.area_damage_radius = 50.0
			# Chain: setup()'tan ONCE set et (setup _remaining_chain = chain_count yapar)
			ex.chain_count = main_chain
			ex.setup(extra_target, dmg, ["attack", "physical", "projectile", "area"] as Array[String], self,
				"res://assets/generated/proj_slice_wave_frame_0.png",
				"res://assets/generated/vfx_fire_explosion.png", "slice_wave", false, 0.0, "physical")
			ex.proj_anim_fw = 32; ex.proj_anim_fh = 32
			ex.proj_anim_cols = 4; ex.proj_anim_count = 8; ex.proj_anim_fps = 12.0
			ex.hit_effect_fw = 48; ex.hit_effect_fh = 48
			ex.hit_effect_cols = 4; ex.hit_effect_count = 16
			ex.set_meta("attacker_stats", stats)
			ex.set_meta("attacker_stats", stats)
		
		# Normal extra'lar: +/-30° yelpaze
		for ei in range(extra_proj_sw):
			_spawn_extra_wave.call(ei, extra_proj_sw, 30.0)
		# Volley extra'lar: +/-80° genis V yay — belirgin sekilde ayri gorunsun
		for ei in range(volley_count):
			_spawn_extra_wave.call(ei, volley_count, 80.0)
	
	# Ana wave sprite'i
	wave_proj.setup(
		aim_pos,
		dmg,
		["attack", "physical", "projectile", "area"] as Array[String],
		self,
		"res://assets/generated/proj_slice_wave_frame_0.png",
		"res://assets/generated/vfx_fire_explosion.png",
		"slice_wave",
		false,
		0.0,
		"physical"
	)
	wave_proj.proj_anim_fw = 32
	wave_proj.proj_anim_fh = 32
	wave_proj.proj_anim_cols = 4
	wave_proj.proj_anim_count = 8
	wave_proj.proj_anim_fps = 12.0
	wave_proj.hit_effect_fw = 48
	wave_proj.hit_effect_fh = 48
	wave_proj.hit_effect_cols = 4
	wave_proj.hit_effect_count = 16
	
	# Attack animasyonu — spell'ler cast_speed kullanir
	var as_mult: float = 1.0
	if stats and stats.cast_speed > 0:
		as_mult = stats.cast_speed
	# Support gem'lerden cast_speed modifier'larini uygula (Cast Speed vs.)
	as_mult = si_sw.get_final_stat("cast_speed", as_mult)
	if as_mult <= 0.0:
		as_mult = 0.01
	_attack_anim_timer = 0.3 / as_mult
	if animated_sprite and animated_sprite.sprite_frames:
		var atk_anim: String = _get_dir_anim("attack", _last_dir)
		if animated_sprite.sprite_frames.has_animation(atk_anim):
			animated_sprite.play(atk_anim)

func _cast_ice_nova(skill_data: SkillData) -> void:
	"""Ice Nova: etrafa buz dairesi (AoE) gonderir. Dusman yoksa fare pozisyonunda patlat."""
	var target_pos: Vector2 = get_global_mouse_position()
	var enemy := _find_enemy_at_mouse_pos(target_pos)
	var has_target: bool = enemy != null and is_instance_valid(enemy)
	var center_pos: Vector2 = enemy.global_position if has_target else target_pos
	
	var weapon: ItemData = equipment.get_item_in_slot(Equipment.Slot.WEAPON)
	var dmg_arr: Array = _get_basic_damage(weapon)
	var dmg: float = dmg_arr[0] as float
	
	# SkillInstance ile support gem'leri uygula (ice_nova skill path'inden)
	var ice_path: String = hotbar[_find_hotbar_idx("ice_nova")]
	var ice_supports: Array[SupportData] = _get_active_supports_for_skill(ice_path)
	var si_in: SkillInstance = SkillInstance.new(skill_data, ice_supports)
	var si_total: float = si_in.get_total_damage(_get_base_damage_for_skill)
	if si_total > 0.0:
		var placeholder_base: float = _get_base_damage_for_skill(skill_data)
		if placeholder_base > 0.0:
			var ratio: float = dmg / placeholder_base
			dmg = si_total * ratio
		else:
			dmg = si_total
	
	# Hedef bolgedeki dusmanlara hasar ver (AoE)
	var aoe_radius: float = 80.0
	# Area of Effect stat'ını uygula (passive ağacı/item'lerden)
	if stats and stats.area_of_effect > 0.0:
		aoe_radius *= (1.0 + stats.area_of_effect / 100.0)
	var enemies := _find_enemies_in_radius(center_pos, aoe_radius)
	for e in enemies:
		if not is_instance_valid(e) or not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		var final_dmg: float = dmg
		# Affix'lerden gelen flat cold damage ekle (adds_cold_damage)
		if stats and stats.cold_damage_flat > 0.0:
			var cold_flat: float = stats.cold_damage_flat
			var inc_total: float = stats.elemental_damage_increased + stats.cold_damage_increased + stats.all_damage_increased + stats.area_damage_increased
			if inc_total != 0.0:
				cold_flat *= (1.0 + inc_total / 100.0)
			cold_flat *= (0.7 + 0.3 * stats.cast_speed)
			# Enemy resistance
			if e.has_node("CharacterStats"):
				var e_stats := e.get_node("CharacterStats") as CharacterStats
				cold_flat *= e_stats.get_incoming_damage_multiplier("cold")
			final_dmg += maxf(0.0, cold_flat)
		h.take_damage(final_dmg, self, ["spell", "cold", "area"])
		_spawn_blood_effect(e.global_position)
	
	# Ice nova efektini goster (AoE sprite)
	_spawn_ice_nova_effect(center_pos)
	
	# Attack animasyonu — spell'ler cast_speed kullanir
	var as_mult: float = 1.0
	if stats and stats.cast_speed > 0:
		as_mult = stats.cast_speed
	# Support gem'lerden cast_speed modifier'larini uygula (Cast Speed vs.)
	as_mult = si_in.get_final_stat("cast_speed", as_mult)
	if as_mult <= 0.0:
		as_mult = 0.01
	_attack_anim_timer = 0.4 / as_mult
	if animated_sprite and animated_sprite.sprite_frames:
		var atk_anim: String = _get_dir_anim("attack", _last_dir)
		if animated_sprite.sprite_frames.has_animation(atk_anim):
			animated_sprite.play(atk_anim)

func _cast_dash(_skill_data: SkillData) -> void:
	"""Dash: fare yönüne doğru süper hızlı hareket + trail efekti."""
	if _is_dashing:
		return  # Zaten dash yapıyor
	
	var dash_dist: float = 200.0
	var target_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (target_pos - global_position).normalized()
	if dir.length_squared() < 0.001:
		dir = _last_dir
	var dest: Vector2 = global_position + dir * dash_dist
	
	# Duvarlara karşı raycast — dash'in duvar içinde bitmesini engelle
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.new()
	query.from = global_position
	query.to = dest
	query.collision_mask = 1  # duvar layer'ı
	query.exclude = [self]
	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		# Duvara çarptıysak, duvarın biraz önünde dur
		var wall_pos: Vector2 = result.position
		var wall_normal: Vector2 = result.normal
		dest = wall_pos - wall_normal * 16.0  # karakter yarıçapı kadar geri
	
	# Dash state'ini başlat (teleport yerine süper hızlı hareket)
	_is_dashing = true
	_dash_start = global_position
	_dash_target = dest
	_dash_progress = 0.0
	_dash_trail_timer = 0.0
	_dash_dir = dir
	
	# İlk trail ghost'u hemen spawnla
	_spawn_dash_trail()
	
	# Dash direction animasyonu
	if animated_sprite and animated_sprite.sprite_frames:
		var dash_anim: String = _get_dir_anim("walk", dir)
		if animated_sprite.sprite_frames.has_animation(dash_anim):
			animated_sprite.play(dash_anim)
		animated_sprite.speed_scale = 3.0
		# Mavimsi flaş efekti
		animated_sprite.modulate = Color(0.5, 0.7, 1.0, 1.0)

# ── Dash trail ghost efekti ──
func _spawn_dash_trail() -> void:
	"""Dash izinde bir ghost (gölge) bırakır."""
	if not animated_sprite or not is_instance_valid(animated_sprite):
		return
	var ghost := Sprite2D.new()
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.global_position = global_position
	ghost.scale = animated_sprite.scale
	ghost.flip_h = animated_sprite.flip_h
	ghost.flip_v = animated_sprite.flip_v
	ghost.rotation = animated_sprite.rotation
	ghost.z_index = -1  # player'ın arkasında
	ghost.modulate = Color(0.4, 0.6, 1.0, 0.7)  # mavimsi yarı saydam
	get_parent().add_child(ghost)
	
	# Ghost'u yavaşça kaybolacak şekilde tweenle
	var tw := create_tween().set_parallel()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.tween_property(ghost, "scale", ghost.scale * Vector2(0.5, 0.5), 0.3)
	tw.chain()
	tw.tween_callback(func():
		if is_instance_valid(ghost):
			ghost.queue_free()
	)

func _spawn_dash_finish_effect() -> void:
	"""Dash bitişinde küçük dağılan ışık parçaları efekti — basit AnimatedSprite2D efekti."""
	var flash := Sprite2D.new()
	flash.texture = null
	flash.position = global_position
	flash.z_index = 3
	flash.modulate = Color(0.3, 0.6, 1.0, 0.6)
	get_parent().add_child(flash)
	var tw2 := create_tween()
	tw2.tween_property(flash, "modulate:a", 0.0, 0.3)
	tw2.tween_callback(flash.queue_free)

func _spawn_ice_nova_effect(pos: Vector2) -> void:
	"""Ice Nova gorsel efektini spawnla."""
	var tex_path := "res://assets/generated/vfx_ice_nova.png"
	if not ResourceLoader.exists(tex_path):
		return
	# Bir AnimatedSprite2D olustur ve goster
	var nova_sprite := AnimatedSprite2D.new()
	nova_sprite.sprite_frames = SpriteFrames.new()
	nova_sprite.sprite_frames.add_animation("default")
	var tex := load(tex_path) as Texture2D
	if not tex:
		nova_sprite.queue_free()
		return
	# 16 frame (4x4 grid) 48x48 her frame
	var fw := 48.0
	var fh := 48.0
	for row in range(4):
		for col in range(4):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * fw, row * fh, fw, fh)
			nova_sprite.sprite_frames.add_frame("default", at)
	nova_sprite.sprite_frames.set_animation_speed("default", 12)
	nova_sprite.sprite_frames.set_animation_loop("default", false)
	nova_sprite.position = pos
	nova_sprite.scale = Vector2(2.0, 2.0)
	nova_sprite.z_index = 10
	nova_sprite.play("default")
	# Find a suitable parent (main scene or world)
	var main := get_tree().current_scene
	if main:
		main.add_child(nova_sprite)
		nova_sprite.animation_finished.connect(nova_sprite.queue_free)
	else:
		get_parent().add_child(nova_sprite)
		nova_sprite.animation_finished.connect(nova_sprite.queue_free)

# ================== VS BENZERSIZ SKILL MEKANIKLERI ==================
# Her skill'in kendine has gorsel ve davranisi var.
# 
# 1. Ateş Ok (fire_bolt): NAPALM — patlar, zeminde yanık alanı bırakır
# 2. Buz Mızrağı (ice_shard): DELİCİ BUZ — tüm düşmanları deler, yavaşlatır
# 3. Yıldırım Zinciri (lightning_chain): ZİNCİR ÇARPMASI — anında çarpar, 4 düşmana seker
# 4. Gizem Küresi (arcane_orb): BOOMERANG — gider geri döner, çifte hasar
# 5. Zehir Halesi (toxic_circle): ZEHİR HAVUZU — 4sn kalan alan efekti
# 6. Kasırga (whirlwind): KILIÇ FIRTINASI — 6 yöne dilim gönderir
# 7. Karanlık Işın (dark_beam): ÖLÜM LAZERİ — 0.8sn sürekli ışın
# 8. Kutsal Nova (holy_nova): ŞİFA PATLAMASI — hasarın %20'sini cana çevirir
# 9. Gök Gürültüsü (thunder_strike): YILDIRIM FIRTINASI — büyük çarpma + 3sn takip
# 10. Don Patlaması (frost_explosion): BUZUL ÇAĞI — %30 altındakileri dondurur

func _track_dps(skill_id: String, damage: float, tags: Array) -> void:
	EventBus.skill_damage.emit(skill_id, damage, tags)

func _calc_skill_damage(skill_data: SkillData, skill_path: String) -> float:
<<<<<<< HEAD
	"""Ortak hasar hesaplama — tum skill'ler kullanir.
	Skill seviyesi hasari artirir: level 1 = %100, her ek level +%25.
	
	Spells: skill.base_damage kullanir (weapon damage yok)
	Attacks: weapon damage kullanir"""
=======
		"""Ortak hasar hesaplama — tum skill'ler kullanir.
		Skill seviyesi hasari artirir: level 1 = %100, her ek level +%25.

		Spells: skill.base_damage kullanir (weapon damage yok)
		Attacks: weapon damage kullanir"""
>>>>>>> a667904a2f60f91bce8148f96dac35a85e1f1980

	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	var si: SkillInstance = SkillInstance.new(skill_data, supports)
	var dmg: float = si.get_total_damage(_get_base_damage_for_skill)

	# Skill seviyesi carpani: her seviye +%25 hasar
	var level: int = _skill_levels.get(skill_path, 1)
	var level_mult: float = 1.0 + (level - 1) * 0.25
	dmg *= level_mult

	return dmg

# ─── 1. NAPALM (fire_bolt) ─────────────────────────────────────────
func _cast_fire_bolt_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Ateş Oku: hedefe patlayıcı ok atar, vurunca 3sn yanık alanı bırakır."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var target_pos: Vector2 = target.global_position
	var proj := _basic_projectile_scene.instantiate() as Projectile
	if not proj:
		return
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.speed = 450.0
	proj.lifetime = 1.5
	proj.pierce_count = 0
	# Çarpınca patlama ve yanık alanı
	proj.body_entered.connect(func(body: Node):
		if not is_instance_valid(proj):
			return
		# Yanık alanı bırak
		var ge := preload("res://scripts/skills/ground_effect.tscn").instantiate() as GroundEffect
		get_tree().current_scene.add_child(ge)
		ge.global_position = proj.global_position
		ge.setup(dmg * 0.3, "fire", ["spell", "fire", "area"], self, 3.0, 50.0)
		# Görsel: alev efekti
		var fire := AnimatedSprite2D.new()
		var sf := SpriteFrames.new()
		sf.add_animation("vfx")
		var tex := load("res://assets/generated/vfx_fire_explosion.png") as Texture2D
		for row in range(4):
			for col in range(4):
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = Rect2(col * 48, row * 48, 48, 48)
				sf.add_frame("vfx", atlas)
		sf.set_animation_speed("vfx", 10.0)
		fire.sprite_frames = sf
		fire.play("vfx")
		fire.scale = Vector2(0.8, 0.8)
		fire.position = proj.global_position
		fire.z_index = 5
		fire.modulate = Color(1.0, 0.6, 0.2, 0.7)
		get_tree().current_scene.add_child(fire)
		var tw := create_tween()
		tw.tween_property(fire, "modulate:a", 0.0, 2.8)
		tw.tween_callback(func(): if is_instance_valid(fire): fire.queue_free())
	, CONNECT_ONE_SHOT)
	proj.setup(target_pos, dmg, skill_data.tags.duplicate(), self,
		"res://assets/generated/proj_fireball_anim.png",
		"res://assets/generated/vfx_fire_explosion.png", "fire_bolt", false, 0.0, "fire")
	proj.proj_anim_fw = 32; proj.proj_anim_fh = 32
	proj.proj_anim_cols = 4; proj.proj_anim_count = 8; proj.proj_anim_fps = 12.0
	proj.hit_effect_fw = 48; proj.hit_effect_fh = 48
	proj.hit_effect_cols = 4; proj.hit_effect_count = 16
	proj.set_meta("attacker_stats", stats)

# ─── 2. DELİCİ BUZ (ice_shard) ──────────────────────────────────────
func _cast_ice_shard_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Buz Mızrağı: tüm düşmanları deler, yavaşlatır, her delişte hızlanır."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var target_pos: Vector2 = target.global_position
	var proj := _basic_projectile_scene.instantiate() as Projectile
	if not proj:
		return
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.speed = 500.0
	proj.lifetime = 2.0
	proj.pierce_count = 10  # Herkesi deler
	proj.area_damage_radius = 15.0  # Yanındakilere de az hasar
	
	# Her vuruşta yavaşlat ve hızlan
	var pierced_arr: Array[int] = [0]
	var orig_speed: float = proj.speed
	proj.body_entered.connect(func(body: Node):
		pierced_arr[0] += 1
		if is_instance_valid(proj):
			proj.speed = orig_speed * (1.0 + pierced_arr[0] * 0.1)
		# Yavaşlat: buz
		if body.has_node("AilmentController"):
			body.get_node("AilmentController").apply_effect(StatusEffect.Type.CHILL, 0.4, 2.0)
	)
	
	proj.setup(target_pos, dmg, skill_data.tags.duplicate(), self,
		"res://assets/generated/proj_fireball_anim.png",
		"res://assets/generated/hit_slash_arc_new.png", "ice_shard", false, 0.0, "cold")
	proj.proj_anim_fw = 32; proj.proj_anim_fh = 32
	proj.proj_anim_cols = 4; proj.proj_anim_count = 8; proj.proj_anim_fps = 12.0
	proj.set_meta("attacker_stats", stats)

# ─── 3. ZİNCİR ÇARPMASI (lightning_chain) ───────────────────────────
func _cast_lightning_chain_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Yıldırım Zinciri: oyuncudan hedefe uçan yıldırım mermisi, düşmanlara seker.
	
	Zincir sayısı: skill_data.chain_count + support gem bonusları"""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	# Zincir sayısını hesapla (base + support gem bonusları)
	var base_chains: int = skill_data.chain_count if "chain_count" in skill_data else 4
	var chain_bonus: int = 0
	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	for sd in supports:
		if sd and ("chain_count" in sd and sd.chain_count > 0):
			chain_bonus += sd.chain_count
	var total_chains: int = base_chains + chain_bonus
	# İlk vuruş = 1, sonra remaining_chains = total_chains - 1
	_fire_lightning_projectile(target, dmg, skill_data, skill_path, total_chains - 1)

## Yıldırım sheet sabitleri
const LIGHTNING_SHEET_CAST := "res://assets/vfx/lightning-strike/lightining5-Sheet.png"
const LIGHTNING_SHEET_HIT_1 := "res://assets/vfx/lightning-strike/lightining3-Sheet.png"
const LIGHTNING_SHEET_HIT_2 := "res://assets/vfx/lightning-strike/lightining6-Sheet.png"

# (particle_glow kaldırıldı — sadece AnimatedSprite2D kullanıyoruz)

## 3 aşamalı yıldırım mermisi (GPUParticles2D travel):
##   1) Sheet 5 (15 FPS) — oyuncuda çıkış efekti
##   2) GPUParticles2D — yolda parçacık izi, doğal loop, hiç sırıtmaz
##   3) Sheet 3 + Sheet 6 aynı anda — çarpma patlaması
## chain=true ise vurunca 4 kere daha seker.
func _fire_lightning_projectile(target: Node, damage: float, skill_data: SkillData, skill_path: String, remaining_chains: int = 0, from_pos: Vector2 = Vector2.INF) -> void:
	if not is_instance_valid(target):
		return
	if not target.has_node("Health"):
		target = _find_nearest_enemy(500.0)
		if not target:
			return
	
	var start_pos: Vector2 = from_pos if from_pos != Vector2.INF else global_position
	var skip_cast: bool = (from_pos != Vector2.INF and from_pos != global_position)
	
	# Aşama 1: Çıkış efekti — oyuncudan fırlayınca
	if not skip_cast:
		_play_yildirim_anim(LIGHTNING_SHEET_CAST, start_pos, false, 1.5, 15.0)
		await get_tree().create_timer(0.18).timeout
		if not is_instance_valid(target):
			return
	
	# Aşama 2: Uçan yıldırım (AnimatedSprite2D sheet 4, 60 FPS, hızlı dönen bir yıldırım gibi)
	var travel_bolt: Node2D = _create_lightning_bolt(start_pos, target.global_position)
	if not travel_bolt:
		return
	
	var target_pos: Vector2 = target.global_position
	var travel_time: float = maxf(start_pos.distance_to(target_pos) / 280.0, 0.15)
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(travel_bolt, "global_position", target_pos, travel_time)
	tween.tween_callback(func():
		if is_instance_valid(travel_bolt) and is_instance_valid(target):
			_on_lightning_arrival(travel_bolt, target, damage, skill_data, remaining_chains, skill_path)
		elif is_instance_valid(travel_bolt):
			travel_bolt.queue_free()
	)

func _on_lightning_arrival(bolt: Node2D, target: Node, damage: float, skill_data: SkillData, remaining_chains: int, skill_path: String) -> void:
	if is_instance_valid(bolt):
		bolt.queue_free()
	
	if not is_instance_valid(target) or not target.has_node("Health"):
		return
	
	var h := target.get_node("Health") as Health
	if h.current_health <= 0:
		return
	
	# Aşama 3: Çarpma patlaması — 2 sheet aynı anda! (orijinal boyut)
	_play_yildirim_anim(LIGHTNING_SHEET_HIT_1, target.global_position, false, 1.0, 15.0)
	_play_yildirim_anim(LIGHTNING_SHEET_HIT_2, target.global_position, false, 1.0, 15.0)
	
	# Kalan zincir sayısını göster (debug için)
	if remaining_chains > 0:
		pass
		# TODO: _show_damage_number not implemented
		# _show_damage_number(target.global_position, "⚡%d" % remaining_chains, Color(1.0, 0.9, 0.2))
	
	# Hasar
	h.take_damage(damage, self, skill_data.tags.duplicate(), false, 0.0)
	_spawn_basic_hit_effect(target.global_position)
	
	# Chain — daha uzağa sektir (kalan zincir varsa)
	if remaining_chains > 0:
		var next_enemy := _find_nearest_enemy_except(target.global_position, target)
		if next_enemy and is_instance_valid(next_enemy) and next_enemy.has_node("Health"):
			var next_health := next_enemy.get_node("Health") as Health
			if next_health.current_health > 0:
				# Skip cast (çıkış efekti), devam sheet 4 → 3
				_fire_lightning_projectile(next_enemy, damage * 0.75, skill_data, skill_path, remaining_chains - 1, target.global_position)

## Sheet 4'ten AnimatedSprite2D yıldırım oluştur (60 FPS, hızlı dönsün diye).
## Canlı, çatırdayan bir yıldırım efekti verir (her kare farklı şekil → hızlı geçince
## göz sürekli değişen bir elektrik arkı olarak algılar).
func _create_lightning_bolt(at_pos: Vector2, target_pos: Vector2) -> Node2D:
	var container := Node2D.new()
	container.position = at_pos
	container.z_index = 20
	container.rotation = (target_pos - at_pos).normalized().angle()
	
	# Sheet 4'ü 60 FPS'te döndür (manuel SpriteFrames, _play_yildirim_anim gibi)
	var tex := load(LIGHTNING_SHEET_TRAVEL) as Texture2D
	if not tex:
		container.queue_free()
		return null
	var meta_path := LIGHTNING_SHEET_TRAVEL.get_basename() + ".metadata.json"
	var fw := 64; var fh := 64; var cols := 5; var count := 5
	if ResourceLoader.exists(meta_path):
		var file := FileAccess.open(meta_path, FileAccess.READ)
		if file:
			var json: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if json is Dictionary:
				fw = json.get("frame_width", fw)
				fh = json.get("frame_height", fh)
				cols = json.get("columns", cols)
				count = json.get("frame_count", count)
	var asp := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("vfx")
	frames.set_animation_loop("vfx", true)
	var fps := 60.0
	for i in range(count):
		var col := i % cols
		var row := i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame("vfx", at, 1.0 / fps)
	asp.sprite_frames = frames
	asp.animation = "vfx"
	asp.centered = true
	asp.position = Vector2.ZERO
	asp.z_index = 20
	asp.scale = Vector2(1.4, 1.4)
	container.add_child(asp)
	asp.play()
	
	get_tree().current_scene.add_child(container)
	return container

## 60 FPS sabiti (kullanılmayan sabit yerine)
const LIGHTNING_SHEET_TRAVEL := "res://assets/vfx/lightning-strike/lightining4-Sheet.png"

# (parçacıklar kaldırıldı — sadece AnimatedSprite2D yıldırımı kullanılıyor)

## Bir lightning spritesheet'ten AnimatedSprite2D oluştur, sahneye ekle ve oynat.
## loop=true ise sonsuza dek döner (uçan mermi gibi).
## custom_fps > 0 ise metadata'daki fps yerine bunu kullan (yavaş/görünür olsun diye).
## Returns: AnimatedSprite2D (loop=false ise çöp toplanır, loop=true ise sen temizle)
func _play_yildirim_anim(sheet_path: String, at_pos: Vector2, loop: bool, scale_val: float = 2.0, custom_fps: float = -1.0) -> AnimatedSprite2D:
	if not ResourceLoader.exists(sheet_path):
		return null
	var tex := load(sheet_path) as Texture2D
	if not tex:
		return null
	
	# Metadata'dan frame bilgilerini oku
	var meta_path := sheet_path.get_basename() + ".metadata.json"
	var fw := 64; var fh := 64; var cols := 6; var count := 6; var fps := 12.0
	if ResourceLoader.exists(meta_path):
		var file := FileAccess.open(meta_path, FileAccess.READ)
		if file:
			var json: Variant = JSON.parse_string(file.get_as_text())
			file.close()
			if json is Dictionary:
				fw = json.get("frame_width", fw)
				fh = json.get("frame_height", fh)
				cols = json.get("columns", cols)
				count = json.get("frame_count", count)
				fps = json.get("fps", fps)
	# custom_fps verilmişse metadata'dakini ezer
	if custom_fps > 0.0:
		fps = custom_fps
	
	var asp := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	frames.add_animation("vfx")
	frames.set_animation_loop("vfx", loop)
	for i in range(count):
		var col := i % cols
		var row := i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame("vfx", at, 1.0 / fps)
	asp.sprite_frames = frames
	asp.animation = "vfx"
	asp.centered = true
	asp.position = at_pos
	asp.z_index = 20
	asp.scale = Vector2(scale_val, scale_val)
	get_tree().current_scene.add_child(asp)
	asp.play()
	
	if not loop:
		asp.animation_finished.connect(func():
			if is_instance_valid(asp): asp.queue_free()
		, CONNECT_ONE_SHOT)
	
	return asp

# ─── 4. BOOMERANG (arcane_orb) ──────────────────────────────────────
func _cast_arcane_orb_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Gizem Küresi: 200px gider, geri döner, iki yönde hasar verir."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var target_pos: Vector2 = target.global_position
	var dir: Vector2 = (target_pos - global_position).normalized()
	var fly_dist: float = 200.0
	var speed_val: float = 350.0
	var return_start: Vector2 = global_position + dir * fly_dist
	var t_total: float = fly_dist / speed_val  # ileri gitme süresi
	
	# Basit Area2D + AnimatedSprite2D ile manuel bumerang
	var orb := Area2D.new()
	var col := CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	col.shape.radius = 12.0
	orb.add_child(col)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteFrames.new()
	sprite.sprite_frames.add_animation("default")
	var tex_path := "res://assets/generated/proj_fireball_anim.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		var fw := 32; var fh := 32
		for row in range(2):
			for col2 in range(4):
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(col2 * fw, row * fh, fw, fh)
				sprite.sprite_frames.add_frame("default", at)
	sprite.sprite_frames.set_animation_speed("default", 10)
	sprite.play("default")
	sprite.z_index = 8
	orb.add_child(sprite)
	
	get_tree().current_scene.add_child(orb)
	orb.global_position = global_position
	orb.z_index = 8
	
	var boomerang_hit: Array[Node] = []
	orb.body_entered.connect(func(body: Node):
		# Oyuncunun kendi bumerangi kendine vurmasin!
		if body in boomerang_hit or not body.has_node("Health") or body == self:
			return
		boomerang_hit.append(body)
		body.get_node("Health").take_damage(dmg * 0.5, self, skill_data.tags.duplicate())
		_spawn_basic_hit_effect(body.global_position)
	)
	
	# Tween ile hareket: ileri 200px, sonra geri
	var tw := create_tween()
	tw.set_parallel(false)
	# İLERİ
	tw.tween_property(orb, "global_position", return_start, t_total)
	# GERİ
	tw.tween_property(orb, "global_position", global_position, t_total)
	tw.tween_callback(func():
		if is_instance_valid(orb):
			orb.queue_free()
	)

# ─── 5. ZEHİR HAVUZU (toxic_circle) ─────────────────────────────────
func _cast_toxic_circle_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Zehir Halesi: hedef bölgeye 4sn kalan zehir havuzu bırakır."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var ge := preload("res://scripts/skills/ground_effect.tscn").instantiate() as GroundEffect
	get_tree().current_scene.add_child(ge)
	ge.global_position = target.global_position
	ge.setup(dmg * 0.5, "chaos", ["spell", "chaos", "area"], self, 4.0, 70.0)
	# Görsel: zehir bulutu animasyonu
	var pool := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("vfx")
	var tex := load("res://assets/generated/ground_poison_cloud.png") as Texture2D
	var fw: int = 48
	var fh: int = 48
	for row in range(4):
		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * fw, row * fh, fw, fh)
			sf.add_frame("vfx", atlas)
	sf.set_animation_speed("vfx", 8.0)
	pool.sprite_frames = sf
	pool.play("vfx")
	pool.scale = Vector2(2.0, 2.0)
	pool.position = target.global_position
	pool.z_index = 4
	pool.modulate = Color(0.6, 1.0, 0.6, 0.85)
	get_tree().current_scene.add_child(pool)
	var tw := create_tween()
	tw.tween_property(pool, "modulate:a", 0.0, 3.8)
	tw.tween_callback(func(): if is_instance_valid(pool): pool.queue_free())

# ─── 6. KILIÇ FIRTINASI (whirlwind) ─────────────────────────────────
func _cast_whirlwind_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Kasırga: 6 yöne kesme dalgası fırlatır, her biri 60px AoE ile hasar verir."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var n_swords: int = 6
	for i in range(n_swords):
		var angle: float = float(i) / float(n_swords) * TAU
		var dir_vec: Vector2 = Vector2(cos(angle), sin(angle))
		var proj := _basic_projectile_scene.instantiate() as Projectile
		if not proj:
			continue
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + dir_vec * 10.0
		proj.speed = 280.0
		proj.lifetime = 0.6
		proj.pierce_count = 3
		proj.area_damage_radius = 40.0
		var target_pt: Vector2 = proj.global_position + dir_vec * 200.0
		proj.setup(target_pt, dmg * 0.5, skill_data.tags.duplicate(), self,
			"res://assets/generated/proj_slice_wave_frame_0.png",
			"res://assets/generated/hit_slash_arc_new.png", "whirlwind", false, 0.0, "physical")
		proj.set_meta("attacker_stats", stats)

# ─── 7. ÖLÜM LAZERİ (dark_beam) ─────────────────────────────────────
func _cast_dark_beam_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Karanlık Işın: 0.8sn süren sürekli lazer, içinden geçen düşmanlara hasar."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var dir_vec: Vector2 = (target.global_position - global_position).normalized()
	var beam_len: float = 300.0
	var angle: float = dir_vec.angle()
	
	# Işın görseli: iki katmanlı Line2D (dış parlama + iç çekirdek)
	# Dış parlama (geniş, yarı saydam)
	var beam_glow := Line2D.new()
	beam_glow.width = 20.0
	beam_glow.default_color = Color(0.3, 0.0, 0.5, 0.3)
	beam_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam_glow.z_index = 10
	beam_glow.position = global_position
	beam_glow.rotation = angle
	beam_glow.points = PackedVector2Array([Vector2(20, 0), Vector2(beam_len, 0)])
	get_tree().current_scene.add_child(beam_glow)
	
	# İç çekirdek (ince, parlak mor)
	var beam_core := Line2D.new()
	beam_core.width = 6.0
	beam_core.default_color = Color(0.7, 0.2, 1.0, 0.9)
	beam_core.begin_cap_mode = Line2D.LINE_CAP_ROUND
	beam_core.end_cap_mode = Line2D.LINE_CAP_ROUND
	beam_core.z_index = 11
	beam_core.position = global_position
	beam_core.rotation = angle
	beam_core.points = PackedVector2Array([Vector2(20, 0), Vector2(beam_len, 0)])
	get_tree().current_scene.add_child(beam_core)
	
	# Işını daha organik göster — rastgele nokta dalgalanması
	beam_core.points = _build_zigzag_beam(beam_len)
	beam_glow.points = _build_zigzag_beam(beam_len)
	var sparks: Array[Node] = []  # Bos — ColorRect kareler kaldirildi
	
	# Vurus araligi: base 0.5sn, buyu hizi ile azalir (cast_speed=1.0'da 0.5, =2.0'da 0.25)
	var cast_spd: float = 1.0
	if stats and stats.cast_speed > 0.0:
		cast_spd = stats.cast_speed
	var hit_interval: float = 0.5 / cast_spd
	var beam_elapsed: Array[float] = [0.0]
	var beam_timer := create_tween()
	beam_timer.tween_method(func(dt: float):
		if not is_instance_valid(beam_core):
			return
		beam_elapsed[0] += dt
		# Işın yönünü canlı hedefe güncelle
		var nearest := _find_nearest_enemy(400.0)
		if nearest and is_instance_valid(nearest):
			var new_dir: Vector2 = (nearest.global_position - global_position).normalized()
			var new_angle: float = new_dir.angle()
			beam_glow.rotation = new_angle
			beam_core.rotation = new_angle
			beam_glow.position = global_position
			beam_core.position = global_position
			# Kıvılcımları güncelle
			for si in range(sparks.size()):
				if is_instance_valid(sparks[si]):
					var t2: float = float(si) / float(sparks.size())
					sparks[si].position = global_position + new_dir * (20.0 + t2 * beam_len) - Vector2(2, 2)
		if beam_elapsed[0] >= hit_interval:
			beam_elapsed[0] = 0.0
			# Işın yolundaki tüm düşmanlara hasar
			var beam_start: Vector2 = beam_core.global_position + Vector2(20, 0).rotated(beam_core.rotation)
			var beam_end: Vector2 = beam_start + Vector2(beam_len, 0).rotated(beam_core.rotation)
			var enemies := get_tree().get_nodes_in_group("enemy")
			for e in enemies:
				if not is_instance_valid(e) or not e.has_node("Health"):
					continue
				if e.get_node("Health").current_health <= 0:
					continue
				var e_pos: Vector2 = e.global_position
				var proj_e: Vector2 = e_pos - beam_start
				var beam_dir: Vector2 = Vector2(1, 0).rotated(beam_core.rotation)
				var proj_len: float = proj_e.dot(beam_dir)
				if proj_len < 0.0 or proj_len > beam_len:
					continue
				var perp_dist: float = abs(proj_e.cross(beam_dir))
				if perp_dist < 30.0:
					e.get_node("Health").take_damage(dmg * 0.08, self, skill_data.tags.duplicate())
					_track_dps("dark_beam", dmg * 0.08, skill_data.tags)
					_spawn_basic_hit_effect(e_pos)
	, 0.0, 1.0, 2.0 / cast_spd)
	beam_timer.tween_callback(func():
		if is_instance_valid(beam_glow):
			var tw2 := create_tween()
			tw2.tween_property(beam_glow, "default_color:a", 0.0, 0.2)
		if is_instance_valid(beam_core):
			var tw3 := create_tween()
			tw3.tween_property(beam_core, "default_color:a", 0.0, 0.2)
			tw3.tween_callback(func():
				if is_instance_valid(beam_glow): beam_glow.queue_free()
				if is_instance_valid(beam_core): beam_core.queue_free()
				for sp in sparks:
					if is_instance_valid(sp): sp.queue_free()
			)
	)

func _build_zigzag_beam(length: float) -> PackedVector2Array:
	"""Lazer isini icin rastgele zigzag noktalari uretir."""
	var pts: PackedVector2Array = [Vector2.ZERO]
	var x: float = 10.0
	while x < length - 10.0:
		x += randf_range(12.0, 28.0)
		pts.append(Vector2(x, randf_range(-3.0, 3.0)))
	pts.append(Vector2(length, 0.0))
	return pts

# ─── 8. ŞİFA PATLAMASI (holy_nova) ──────────────────────────────────
func _cast_holy_nova_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Kutsal Nova: çevreye hasar + hasarın %20'sini cana çevirir."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var radius: float = skill_data.aoe_radius
	if radius <= 0.0:
		radius = 100.0
	# Görsel: altın patlama (alev + sarı ton)
	var burst := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("vfx")
	var tex := load("res://assets/generated/vfx_fire_explosion.png") as Texture2D
	for row in range(4):
		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * 48, row * 48, 48, 48)
			sf.add_frame("vfx", atlas)
	sf.set_animation_speed("vfx", 16.0)
	burst.sprite_frames = sf
	burst.play("vfx")
	var s: float = radius * 2.0 / 48.0
	burst.scale = Vector2(s, s)
	burst.position = global_position
	burst.z_index = 10
	burst.modulate = Color(1.0, 0.85, 0.3, 0.7)
	get_tree().current_scene.add_child(burst)
	var tw := create_tween()
	tw.tween_property(burst, "modulate:a", 0.0, 0.5)
	tw.tween_property(burst, "scale", burst.scale * 1.5, 0.5)
	tw.tween_callback(func(): if is_instance_valid(burst): burst.queue_free())
	
	# Hasar ver
	var enemies := _find_enemies_in_radius(global_position, radius)
	var total_damage_dealt: float = 0.0
	for e in enemies:
		if not is_instance_valid(e) or not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		h.take_damage(dmg, self, skill_data.tags.duplicate())
		_spawn_basic_hit_effect(e.global_position)
		total_damage_dealt += dmg
	# Hasarın %20'sini cana çevir
	var heal_amt: float = total_damage_dealt * 0.2
	if heal_amt > 0.0 and health:
		health.heal(heal_amt)

# ─── 9. YILDIRIM FIRTINASI (thunder_strike) ─────────────────────────
func _cast_thunder_strike_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Gök Gürültüsü: büyük yıldırım çarpması + 3sn boyunca ek yıldırımlar."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var center: Vector2 = target.global_position
	# Ana yıldırım: oyuncudan hedefe mermi
	_fire_lightning_projectile(target, dmg, skill_data, skill_path, 0)
	# Hasar
	var enemies := _find_enemies_in_radius(center, 70.0)
	for e in enemies:
		if not is_instance_valid(e) or not e.has_node("Health"):
			continue
		e.get_node("Health").take_damage(dmg, self, skill_data.tags.duplicate(), false, 0.0)
		_spawn_basic_hit_effect(e.global_position)
	# 3sn boyunca rastgele yıldırımlar
	var storm_duration: float = 3.0
	var storm_elapsed: Array[float] = [0.0]
	var storm_timer := create_tween()
	storm_timer.tween_method(func(dt: float):
		storm_elapsed[0] += dt
		if storm_elapsed[0] >= 0.4:
			storm_elapsed[0] = 0.0
			# Rastgele bir düşman seç
			var all_enemies := get_tree().get_nodes_in_group("enemy")
			var alive: Array[Node] = []
			for e in all_enemies:
				if is_instance_valid(e) and e.has_node("Health") and e.get_node("Health").current_health > 0:
					# 70px menzil içinde mi kontrol et
					if center.distance_to(e.global_position) < 200.0:
						alive.append(e)
			if alive.is_empty():
				return
			var target_e: Node = alive[randi() % alive.size()]
			# Fırtına yıldırımı: gökten iner (target'in 120px üstünden)
			_fire_lightning_projectile(target_e, dmg * 0.4, skill_data, skill_path, 0, target_e.global_position + Vector2(0, -120))
	, 0.0, 1.0, storm_duration)

# ─── 10. BUZUL ÇAĞI (frost_explosion) ──────────────────────────────
func _cast_frost_explosion_vs(skill_data: SkillData, target: Node, skill_path: String) -> void:
	"""Don Patlaması: etrafı dondurur, %30 altı HP'deki düşmanları 3sn dondurur."""
	var dmg := _calc_skill_damage(skill_data, skill_path)
	var radius: float = skill_data.aoe_radius
	if radius <= 0.0:
		radius = 90.0
	# Görsel: buz patlaması
	var burst := AnimatedSprite2D.new()
	var sf := SpriteFrames.new()
	sf.add_animation("vfx")
	var tex := load("res://assets/generated/vfx_ice_nova.png") as Texture2D
	for row in range(4):
		for col in range(4):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(col * 48, row * 48, 48, 48)
			sf.add_frame("vfx", atlas)
	sf.set_animation_speed("vfx", 14.0)
	burst.sprite_frames = sf
	burst.play("vfx")
	var s: float = radius * 2.0 / 48.0
	burst.scale = Vector2(s, s)
	burst.position = global_position
	burst.z_index = 10
	burst.modulate = Color(0.6, 0.9, 1.0, 0.8)
	get_tree().current_scene.add_child(burst)
	var tw := create_tween()
	tw.tween_property(burst, "modulate:a", 0.0, 0.6)
	tw.tween_property(burst, "scale", burst.scale * 1.3, 0.6)
	tw.tween_callback(func(): if is_instance_valid(burst): burst.queue_free())
	
	var enemies := _find_enemies_in_radius(global_position, radius)
	for e in enemies:
		if not is_instance_valid(e) or not e.has_node("Health"):
			continue
		var h := e.get_node("Health") as Health
		if h.current_health <= 0:
			continue
		# Önce hasar
		h.take_damage(dmg, self, skill_data.tags.duplicate(), false, 0.0)
		_spawn_basic_hit_effect(e.global_position)
		# %30 altındaysa dondur
		var hp_pct: float = h.current_health / maxf(h.max_health, 1.0)
		if hp_pct < 0.30:
			if e.has_node("AilmentController"):
				e.get_node("AilmentController").apply_effect(StatusEffect.Type.FREEZE, 1.0, 3.0)
		else:
			# Değilse yavaşlat
			if e.has_node("AilmentController"):
				e.get_node("AilmentController").apply_effect(StatusEffect.Type.CHILL, 0.5, 3.0)

# ================== BUFF TOGGLE SISTEMI ==================

## Bir buff/aura skill'ini aç/kapa.
## - Açma: mana/life rezerve eder, stat bonuslarını uygular
## - Kapama: rezervasyonu kaldırır, bonusları geri alır
## buff_effect_self: buff etkilerini % artırır (KarakterStats'tan okunur)
func _toggle_buff_skill(skill_data: SkillData, skill_path: String) -> void:
	# Zaten aktif mi kontrol et
	if _active_buffs.has(skill_path):
		# KAPAT: buff'ı devre dışı bırak
		var buff_info: Dictionary = _active_buffs[skill_path]
		
		# Rezervasyonu kaldır
		if buff_info.get("use_life", false):
			var health_node: Health = get_node_or_null("Health")
			if health_node:
				health_node.unreserve_life(buff_info.reserve_amount)
		else:
			var mana_node = get_node_or_null("Mana")
			if mana_node:
				mana_node.unreserve(buff_info.reserve_amount)
		
		# Stat modifier'larını kaldır (chain_aura flat kullanır)
		if skill_data.id == "chain_aura":
			stats.remove_buff_flat_modifier(skill_data.id)
		else:
			stats.remove_buff_modifier(skill_data.id)
		
		# Görsel efekti kapa
		if _buff_aura:
			_buff_aura.visible = false
		
		# Kaydı sil
		_active_buffs.erase(skill_path)
		print("Buff KAPATILDI: ", skill_data.display_name)
		# SkillBar'ı güncelle (glow kaybolsun)
		var skill_bar := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
		if skill_bar:
			skill_bar.refresh()
		return
	
	# AÇ: buff'ı aktifleştir
	# --- Rezervasyon miktarını hesapla ---
	var reserve_amount: float = 0.0
	if skill_data.aura_reservation_percent > 0.0:
		# Yüzde bazlı rezervasyon (max_mana'nın %'si)
		reserve_amount = skill_data.aura_reservation_percent
	elif skill_data.aura_reservation_flat > 0.0:
		reserve_amount = skill_data.aura_reservation_flat
	else:
		# Varsayılan: %25 mana
		reserve_amount = 25.0
	
	# --- Rezervasyon verimliliğini uygula (pasif ağacından) ---
	# Formula: effective_pct = original_pct / (1 + efficiency/100)
	if stats and stats.reservation_efficiency > 0.0:
		var eff: float = stats.reservation_efficiency
		reserve_amount = reserve_amount / (1.0 + eff / 100.0)
	
	# --- Life rezervasyon kontrolü (support gem + passive) ---
	var use_life: bool = false
	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	for sd in supports:
		if sd and "life_reservation" in sd.added_tags:
			use_life = true
			break
	
	# Passive'den gelen mana->life cost conversion da rezervasyonu etkiler
	if stats and stats.life_cost_conversion_pct > 0.0 and not use_life:
		# Kısmi life rezervasyon (passive'den)
		# life_cost_conversion_pct, mana rezervasyonunun bir kısmını life'a çevirir
		pass  # Şimdilik sadece support gem kontrolü
	
	# --- Aura Level Scaling: base değerler level ile büyüsün ---
	# Formül: scaled = base * aura_level_coefficient
	# aura_level_coefficient = 0.5 + 0.05 * aura_level
	# Level 1'de 0.55x, level 10'da 1.0x, level 20'de 1.5x, level 50'de 3.0x
	var aura_lvl: int = stats.aura_level if stats else 1
	var aura_scale_coeff: float = 0.5 + 0.05 * aura_lvl
	
	# --- buff_effect_self: buff etkilerini % artır ---
	var effect_mult: float = 1.0
	if stats and stats.buff_effect_self > 0.0:
		effect_mult = 1.0 + stats.buff_effect_self / 100.0
	
	# --- GENERALIZE BUFF PARSING ---
	# buff_tags'teki HER anahtarı dinamik olarak oku, level + effect_self ile scale et
	# Artık yeni aura eklemek için kod değiştirmeye gerek yok!
	var buff_modifiers: Dictionary = {}
	for tag in skill_data.buff_tags:
		var parts: PackedStringArray = tag.split(":")
		if parts.size() >= 2:
			var key: String = parts[0]
			var val: float = parts[1].to_float()
			buff_modifiers[key] = val * aura_scale_coeff * effect_mult
	
	# --- Support gem modifier'larını buff değerlerine uygula ---
	for sd in supports:
		if not sd:
			continue
		for mod in sd.modifiers:
			if mod is not StatModifier:
				continue
			# Hangi buff key'lerinin etkileneceğini bul
			var target_keys: Array[String] = []
			if mod.stat == "damage":
				# "damage" → buff'taki *_damage key'lerini etkile
				for bk in buff_modifiers:
					if bk.ends_with("_damage") or bk == "all_damage":
						if mod.damage_type_filter == "":
							target_keys.append(bk)
						elif mod.damage_type_filter == "elemental":
							if bk in ["fire_damage", "cold_damage", "lightning_damage", "elemental_damage"]:
								target_keys.append(bk)
						elif mod.damage_type_filter == "fire" and bk in ["fire_damage", "elemental_damage"]:
							target_keys.append(bk)
						elif mod.damage_type_filter == "cold" and bk in ["cold_damage", "elemental_damage"]:
							target_keys.append(bk)
						elif mod.damage_type_filter == "lightning" and bk in ["lightning_damage", "elemental_damage"]:
							target_keys.append(bk)
			elif mod.stat in buff_modifiers:
				target_keys.append(mod.stat)
			# Her hedef key'e modifier'ı uygula
			for bk in target_keys:
				match mod.modifier_type:
					StatModifier.ModifierType.FLAT:
						buff_modifiers[bk] += mod.value
					StatModifier.ModifierType.INCREASED, StatModifier.ModifierType.MORE:
						buff_modifiers[bk] *= (1.0 + mod.value / 100.0)
	
	# chain_aura flat modifier kullanır — ayrı handler'ı var
	if skill_data.id == "chain_aura":
		_activate_chain_aura(skill_data, skill_path, reserve_amount, use_life, aura_lvl, aura_scale_coeff)
		return
	
	# --- Rezervasyonu uygula ---
	var actual_reserve: float = 0.0
	if use_life:
		# Life rezervasyonu: max_health'in yüzdesi olarak
		var health_node: Health = get_node_or_null("Health")
		if not health_node:
			return
		# Yüzdeyi flat değere çevir (max_health üzerinden)
		if skill_data.aura_reservation_percent > 0.0:
			actual_reserve = health_node.max_health * (reserve_amount / 100.0)
		else:
			actual_reserve = reserve_amount
		
		if not health_node.reserve_life(actual_reserve):
			print("Yeterli can yok! Buff açılamadı: ", skill_data.display_name)
			return
	else:
		# Mana rezervasyonu
		var mana_node = get_node_or_null("Mana")
		if not mana_node:
			return
		# Yüzdeyi flat değere çevir (max_mana üzerinden)
		if skill_data.aura_reservation_percent > 0.0:
			actual_reserve = mana_node.max_mana * (reserve_amount / 100.0)
		else:
			actual_reserve = reserve_amount
		
		if not mana_node.reserve(actual_reserve):
			print("Yeterli mana yok! Buff açılamadı: ", skill_data.display_name)
			return
	
	# --- Stat modifier'larını uygula (CharacterStats üzerinden) ---
	stats.apply_buff_modifier(skill_data.id, buff_modifiers)
	
	# --- Görsel efekti aç ---
	if _buff_aura:
		_buff_aura.visible = true
	
	# --- Aktif buff kaydı ---
	_active_buffs[skill_path] = {
		"ref": skill_data,
		"reserve_amount": actual_reserve,
		"use_life": use_life,
	}
	
	var effect_str: String = ""
	for k in buff_modifiers:
		if not effect_str.is_empty():
			effect_str += ", "
		effect_str += k + ": " + str(buff_modifiers[k])
	print("Buff AÇILDI: ", skill_data.display_name,
		" (Rezerve: ", actual_reserve, " ", "Can" if use_life else "Mana",
		", Effects: {", effect_str, "})",
		" [buff_effect_self x", effect_mult, "]")
	# SkillBar'ı güncelle (glow gözüksün)
	var skill_bar := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
	if skill_bar:
		skill_bar.refresh()


## Chain aura'yı aktifleştir (flat modifier kullanır, increased değil)
func _activate_chain_aura(skill_data: SkillData, skill_path: String, reserve_amount: float, use_life: bool, aura_lvl: int = 1, aura_scale: float = 1.0) -> void:
	# NOT: reserve_amount zaten _toggle_buff_skill'de rezervasyon verimliligi ile hesaplanmis, tekrar uygulama!
	# --- Rezervasyonu uygula ---
	var actual_reserve: float = 0.0
	if use_life:
		var health_node: Health = get_node_or_null("Health")
		if not health_node:
			return
		if skill_data.aura_reservation_percent > 0.0:
			actual_reserve = health_node.max_health * (reserve_amount / 100.0)
		else:
			actual_reserve = reserve_amount
		if not health_node.reserve_life(actual_reserve):
			print("Yeterli can yok! Chain aura açılamadı")
			return
	else:
		var mana_node = get_node_or_null("Mana")
		if not mana_node:
			return
		if skill_data.aura_reservation_percent > 0.0:
			actual_reserve = mana_node.max_mana * (reserve_amount / 100.0)
		else:
			actual_reserve = reserve_amount
		if not mana_node.reserve(actual_reserve):
			print("Yeterli mana yok! Chain aura açılamadı")
			return
	
	# Flat modifier uygula — chain_count level ile skalalansın
	# Base chain_count değerini buff_tags'ten oku
	var base_chain: float = 1.0  # varsayılan
	for tag in skill_data.buff_tags:
		var parts: PackedStringArray = tag.split(":")
		if parts.size() >= 2 and parts[0] == "chain_count":
			base_chain = parts[1].to_float()
			break
	# Level scaling: chain_count normalde tam sayı olduğu için yuvarlıyoruz
	var final_chain: int = maxi(1, int(round(base_chain * aura_scale)))
	var chain_flat_mod: Dictionary = {"chain_count": final_chain}
	stats.apply_buff_flat_modifier(skill_data.id, chain_flat_mod)
	
	print("Chain Aura: Seviye ", aura_lvl, " -> +", final_chain, " Chain (base=", base_chain, ", scale=", aura_scale, ")")
	
	# Görsel efekti aç
	if _buff_aura:
		_buff_aura.visible = true
	
	# Aktif buff kaydı
	_active_buffs[skill_path] = {
		"ref": skill_data,
		"reserve_amount": actual_reserve,
		"use_life": use_life,
	}
	print("Chain Aura AÇILDI (Rezerve: ", actual_reserve, " ", "Can" if use_life else "Mana", ")")
	var sb := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
	if sb:
		sb.refresh()

# ================== INFERNAL CIRCLE TOGGLE ==================

## Cehennem Çemberi referansi (actikken)
var _infernal_circle_ref: InfernalCircle = null

## Infernal Circle'u ac/kapa.
## Açma: can drain baslar, etraftaki herkes yanar.
## Kapama: cember kaybolur.
func _toggle_infernal_circle(_skill_data: SkillData, skill_path: String) -> void:
	# Zaten aktif mi?
	if _infernal_circle_ref and is_instance_valid(_infernal_circle_ref):
		# KAPAT
		_infernal_circle_ref.deactivate()
		_infernal_circle_ref = null
		print("Infernal Circle KAPATILDI")
		var sb := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
		if sb:
			sb.refresh()
		return
	
	# AÇ: InfernalCircle olustur
	var circle_scene := preload("res://scripts/skills/InfernalCircle.gd")
	if not circle_scene:
		return
	var circle: InfernalCircle = circle_scene.new()
	circle.skill_path = skill_path
	circle.player_stats = stats
	circle.player_health = health
	# Support gem'leri yukle ve Genis Alan icin hardcode modifier'lari ekle
	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	for sd in supports:
		if sd and sd.id == "wider_area" and sd.modifiers.is_empty():
			# modifiers array'i bos (StatModifier resource parse edilemedi)
			# Hardcode: +40% radius, -30% damage
			var rad_mod := StatModifier.new()
			rad_mod.modifier_type = StatModifier.ModifierType.MORE
			rad_mod.value = 40.0
			rad_mod.damage_type_filter = "radius"
			rad_mod.stat = "damage"
			var dmg_mod := StatModifier.new()
			dmg_mod.modifier_type = StatModifier.ModifierType.MORE
			dmg_mod.value = -30.0
			dmg_mod.damage_type_filter = ""
			dmg_mod.stat = "damage"
			sd.modifiers = [rad_mod, dmg_mod]
	circle._active_supports = supports
	circle.apply_level_scaling(stats)
	# Support gem modifier'larini uygula (radius/damage more)
	circle.apply_support_gems(supports)
	
	# Oyuncunun child'i olarak ekle — boylece otomatik takip eder
	add_child(circle)
	circle.position = Vector2.ZERO
	circle.aura_level = stats.aura_level if stats else 1
	
	_infernal_circle_ref = circle
	# Drain timer baslasin diye update ekle
	print("Infernal Circle AÇILDI - Level scaling: radius=", circle.radius, ", damage=", circle.base_damage_per_tick)
	
	var skill_bar := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
	if skill_bar:
		skill_bar.refresh()


func _refresh_infernal_circle_supports(skill_path: String) -> void:
	"""Degisen support gem'leri Infernal Circle'a aninda uygula."""
	if not _infernal_circle_ref or not is_instance_valid(_infernal_circle_ref):
		return
	if _infernal_circle_ref.skill_path != skill_path:
		return
	var supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	for sd in supports:
		if sd and sd.id == "wider_area" and sd.modifiers.is_empty():
			var rad_mod := StatModifier.new()
			rad_mod.modifier_type = StatModifier.ModifierType.MORE
			rad_mod.value = 40.0
			rad_mod.damage_type_filter = "radius"
			rad_mod.stat = "damage"
			var dmg_mod := StatModifier.new()
			dmg_mod.modifier_type = StatModifier.ModifierType.MORE
			dmg_mod.value = -30.0
			dmg_mod.damage_type_filter = ""
			dmg_mod.stat = "damage"
			sd.modifiers = [rad_mod, dmg_mod]
	_infernal_circle_ref._active_supports = supports
	_infernal_circle_ref.apply_support_gems(supports)
	print("Infernal Circle SUPPORT REFRESH - radius=", _infernal_circle_ref.radius, ", damage=", _infernal_circle_ref.base_damage_per_tick)


func _process_infernal_circle_drain(delta: float) -> void:
	"""Her frame cagrilir — infernal circle aktifse can drain uygula."""
	if not _infernal_circle_ref or not is_instance_valid(_infernal_circle_ref):
		return
	if not stats or not health:
		return
	
	# Drain miktari = level scaling ile artan base drain
	# Base: saniyede 10 can. Level ile: 10 + level * 3 can/sn
	var base_drain: float = 10.0 + stats.aura_level * 3.0  # level 1 = 13, level 10 = 40, level 20 = 70
	
	# Life regen drain'i kismen azaltir (regen ne kadar yuksekse o kadar dayanirsin)
	var regen: float = stats.life_regen_per_second if stats else 0.0
	var net_drain: float = (base_drain - regen) * delta  # saniyelik drain -> frame'e cevir
	if net_drain <= 0.0:
		# Regen drain'den fazlaysa can azalmaz ama skill acik kalir
		return
	
	if not health.spend(net_drain):
		# Can bitti — skill otomatik kapansin
		print("Infernal Circle: Can bitti, kapatiliyor...")
		_infernal_circle_ref.deactivate()
		_infernal_circle_ref = null
		var sb := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
		if sb:
			sb.refresh()

func _find_hotbar_idx(skill_id: String) -> int:
	"""Bir skill ID'sinin hotbar'daki indexini bul. Yoksa 0 dondur."""
	for i in range(hotbar.size()):
		if hotbar[i].is_empty():
			continue
		if not ResourceLoader.exists(hotbar[i]):
			continue
		var sd := load(hotbar[i]) as SkillData
		if sd and sd.id == skill_id:
			return i
	return 0

# ================== UI KONTROL ==================

func _is_any_ui_open() -> bool:
	var scene_root: Node = get_tree().current_scene
	if not scene_root:
		return false
	var game_ui: CanvasLayer = scene_root.get_node_or_null("CanvasLayer")
	if game_ui and game_ui.has_method("ui_is_open") and game_ui.ui_is_open():
		return true
	# Skill tree tam ekran acik mi kontrol et
	if scene_root and scene_root.has_method("get_skill_tree_instance"):
		var st: Control = scene_root.get_skill_tree_instance()
		if st and st.visible:
			return true
	# Skill gem panel acik mi?
	var sgp := get_tree().root.get_node_or_null("SkillGemPanelLayer") as CanvasLayer
	if sgp and sgp.has_method("is_open") and sgp.is_open():
		return true
	return false

# Flask sistemi kaldirildi

func equip_item(item: ItemData) -> void:
	inventory.equip_item(item, equipment)

# ── Mana / Life cost hesaplama (SkillBar tooltip ve Player cast icin ortak) ──

## Skill'in efektif mana cost'unu hesaplar (passive tree + support multiplier)
func _calc_effective_mana_cost(skill_path: String, skill_data: SkillData) -> float:
	if not stats or skill_data.mana_cost <= 0.0:
		return 0.0
	var base_cost: float = skill_data.mana_cost
	var conversion_pct: float = stats.life_cost_conversion_pct / 100.0
	var mana_portion: float = base_cost * (1.0 - conversion_pct)
	mana_portion *= (1.0 + stats.mana_cost_pct / 100.0)
	var efficiency_mult: float = 1.0 - stats.mana_cost_efficiency / 100.0
	mana_portion *= efficiency_mult
	# Support gem mana multiplier
	var mana_supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	for sd in mana_supports:
		if sd and sd.mana_multiplier != 1.0:
			mana_portion *= sd.mana_multiplier
	return maxf(mana_portion, 0.0)

## Skill'in efektif life cost'unu hesaplar (conversion ile gelen)
func _calc_effective_life_cost(skill_path: String, skill_data: SkillData) -> float:
	if not stats or skill_data.mana_cost <= 0.0:
		return 0.0
	var base_cost: float = skill_data.mana_cost
	var conversion_pct: float = stats.life_cost_conversion_pct / 100.0
	var life_portion: float = base_cost * conversion_pct
	life_portion *= (1.0 + stats.life_cost_pct / 100.0)
	var efficiency_mult: float = 1.0 - stats.mana_cost_efficiency / 100.0
	life_portion *= efficiency_mult
	# Support gem mana multiplier
	var mana_supports: Array[SupportData] = _get_active_supports_for_skill(skill_path)
	for sd in mana_supports:
		if sd and sd.mana_multiplier != 1.0:
			life_portion *= sd.mana_multiplier
	return maxf(life_portion, 0.0)
