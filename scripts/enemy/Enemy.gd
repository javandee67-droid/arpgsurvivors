extends CharacterBody2D
class_name Enemy
## Enhanced enemy with EnemyDatabase type configuration.

@export var speed: float = 50.0
@export var contact_damage: float = 8.0
@export var attack_cooldown: float = 1.2
@export var xp_reward: float = 100.0
@export var aggro_range: float = 500.0
@export var leash_range: float = 1000.0

# Agresyon menzil çarpanları — çok uzaktan aggro sorununu düzeltmek için
# Her enemy type'ın veritabanındaki değerlerini global olarak ölçekler
const AGGRO_RANGE_MULTIPLIER: float = 0.45
const LEASH_RANGE_MULTIPLIER: float = 0.70
@export var damage_type: String = "physical"

# === VS MODE: SADECE MELEE ===
enum EnemyClass { MELEE }
var enemy_class: int = EnemyClass.MELEE

# === RARITY SYSTEM ===
enum EnemyRarity { NORMAL, MAGIC, RARE, UNIQUE }

# Stat multipliers per rarity level
const RARITY_STAT_MULT := {
	EnemyRarity.NORMAL: {"hp": 1.0, "dmg": 1.0, "speed": 1.0, "xp": 1.0, "drop_chance": 0.15, "drop_count": 0},
	EnemyRarity.MAGIC:  {"hp": 1.5, "dmg": 1.3, "speed": 1.0, "xp": 2.5, "drop_chance": 3.0, "drop_count": 1},
	EnemyRarity.RARE:   {"hp": 2.8, "dmg": 1.6, "speed": 1.1, "xp": 5.0, "drop_chance": 8.0, "drop_count": 3},
	EnemyRarity.UNIQUE: {"hp": 5.0, "dmg": 2.2, "speed": 1.2, "xp": 10.0, "drop_chance": 15.0, "drop_count": 5},
}

# Name color per rarity
const RARITY_COLORS := {
	EnemyRarity.NORMAL: Color.WHITE,
	EnemyRarity.MAGIC: Color(0.3, 0.6, 1.0),
	EnemyRarity.RARE: Color(1.0, 0.85, 0.0),
	EnemyRarity.UNIQUE: Color(1.0, 0.5, 0.0),
}

# Mod count ranges per rarity
const RARITY_MOD_COUNT := {
	EnemyRarity.NORMAL: [0, 0],
	EnemyRarity.MAGIC: [1, 2],
	EnemyRarity.RARE: [3, 5],
	EnemyRarity.UNIQUE: [4, 6],
}

# Enemy mod pool with stat effects
const ENEMY_MODS := {
	"extra_fire": {"name": "Alevli", "weight": 10, "extra_damage_pct": 0.25, "extra_damage_type": "fire"},
	"extra_cold": {"name": "Buzul", "weight": 10, "extra_damage_pct": 0.25, "extra_damage_type": "cold"},
	"extra_lightning": {"name": "Yıldırımlı", "weight": 10, "extra_damage_pct": 0.25, "extra_damage_type": "lightning"},
	"extra_chaos": {"name": "Kaotik", "weight": 5, "extra_damage_pct": 0.20, "extra_damage_type": "chaos"},
	"fast_attacks": {"name": "Hızlı", "weight": 10, "attack_speed_pct": 0.35},
	"fast_movement": {"name": "Çevik", "weight": 8, "move_speed_pct": 0.40},
	"life_leech": {"name": "Kan Emici", "weight": 6, "life_leech_pct": 0.03},
	"life_regen": {"name": "Yenileyici", "weight": 6, "life_regen_pct": 0.02},
	"tough": {"name": "Zırhlı", "weight": 8, "phys_resist_pct": 0.25},
	"resistant": {"name": "Dirençli", "weight": 7, "ele_resist_pct": 0.25},
	"berserker": {"name": "Azgın", "weight": 4, "damage_pct": 0.40, "move_speed_pct": 0.30, "phys_resist_pct": -0.20},
}

# Rarity roll weights for regular enemies (more Normal/Magic, fewer Rare/Unique)
const RARITY_ROLL_WEIGHTS := {
	EnemyRarity.NORMAL: 0.50,
	EnemyRarity.MAGIC: 0.44,
	EnemyRarity.RARE: 0.05,
	EnemyRarity.UNIQUE: 0.01,
}

const RARITY_ROLL_NAMES := {
	EnemyRarity.NORMAL: "",
	EnemyRarity.MAGIC: "[Büyülü] ",
	EnemyRarity.RARE: "[Nadir] ",
	EnemyRarity.UNIQUE: "[Eşsiz] ",
}

var rarity: int = EnemyRarity.NORMAL
var active_mods: Array[String] = []
var rarity_name: String = ""
var xp_multiplier: float = 1.0
var drop_multiplier: float = 1.0
var extra_drops: int = 0
var _extra_damage_mods: Array[Dictionary] = []  # Applied during attack calc

# Life leech tracking
var _leech_amount: float = 0.0

@onready var health: Health = $Health
@onready var stats: CharacterStats = $CharacterStats
@onready var ailment_ctrl: AilmentController = $AilmentController
@onready var drop_table: DropTable = $DropTable
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var name_label: Label = $NameLabel

var _target: Node = null
var _attack_timer: float = 0.0
var _spawn_position: Vector2
var enemy_level: int = 1
var _enemy_id: String = ""
var _enemy_name: String = ""

# === VS MODE: her zaman kovala ===
enum AIState { CHASE }
var _ai_state: int = AIState.CHASE

# === ANIMATION ===
enum AnimState { IDLE, WALK, ATTACK }
var _anim_state: int = AnimState.IDLE
var _anim_dir: String = "front"
var _attack_anim_playing: bool = false

func _ready() -> void:
	RapierPhysicsServer2D.body_set_extra_param(get_rid(), RapierPhysicsServer2D.BODY_PARAM_CONTACT_SKIN, 0.02)
	add_to_group("enemy")
	_spawn_position = global_position
	health.died.connect(_on_death)
	health.damage_taken_signal.connect(_on_hit)
	health.health_changed.connect(_on_health_changed)
	_target = get_tree().get_first_node_in_group("player")
	queue_redraw()

func _on_health_changed(_curr: float, _max_hp: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not health or health.max_health <= 0:
		return
	var pct := clampf(health.current_health / health.max_health, 0.0, 1.0)
	var bar_w := 34.0
	var bar_h := 4.0
	# Sprite boyutuna göre can barı pozisyonu (büyük canavarlar için dinamik)
	var sprite_h: float = (sprite.scale.y * 48.0) if sprite and sprite.scale.y > 0 else 48.0
	var bar_y: float = -(sprite_h * 0.5 + 6.0)  # Sprite'ın üst kenarı + 6px boşluk
	
	# Arka plan (siyah)
	draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w, bar_h), Color(0.0, 0.0, 0.0, 0.7))
	
	# Kırmızı can barı — can azaldıkça bar kısalır
	if pct > 0.0:
		draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w * pct, bar_h), Color(0.9, 0.15, 0.15))


## VS: Dusman sinifi - sadece melee
func set_enemy_class_info(class_id: int, skill_ids: Array) -> void:
	enemy_class = EnemyClass.MELEE

func _add_status_effect_visual() -> void:
	var sev := preload("res://scripts/core/StatusEffectVisual.tscn").instantiate()
	sev.name = "StatusEffectVisual"
	add_child(sev)

func get_contact_damage() -> float:
	return contact_damage

func set_enemy_type(etype: Dictionary) -> void:
	_enemy_id = etype.get("id", "")
	_enemy_name = etype.get("name", "")
	
	speed = etype.get("speed", speed)
	contact_damage = etype.get("contact_damage", contact_damage)
	attack_cooldown = etype.get("attack_cooldown", attack_cooldown)
	xp_reward = etype.get("xp_reward", xp_reward)
	aggro_range = etype.get("aggro_range", aggro_range) * AGGRO_RANGE_MULTIPLIER
	leash_range = etype.get("leash_range", leash_range) * LEASH_RANGE_MULTIPLIER
	damage_type = etype.get("damage_type", damage_type)
	
	# leash_range guncellendiyse deaggro mesafesini de guncelle
	# VS mode: deaggro_range kullanilmaz
	
	if health:
		health.max_health = etype.get("base_health", 50.0)
		health.current_health = health.max_health
	
	if stats:
		stats.base_life = etype.get("base_health", 50.0)
		stats.base_armour = etype.get("armour", 0.0)
		stats.base_evasion = etype.get("evasion", etype.get("tier", 1) * 5.0)
		stats.base_movement_speed = 1.0
		stats.base_fire_resistance = etype.get("resistances", {}).get("fire", 0.0)
		stats.base_cold_resistance = etype.get("resistances", {}).get("cold", 0.0)
		stats.base_lightning_resistance = etype.get("resistances", {}).get("lightning", 0.0)
		stats.base_chaos_resistance = etype.get("resistances", {}).get("chaos", 0.0)
		stats.recalculate()
	
	if drop_table:
		drop_table.drop_chance = etype.get("drop_chance", 0.35)
		drop_table.tier = etype.get("tier", 1)
		var item_types: Array = etype.get("drop_item_types", ["weapon"])
		var base_dir := "res://scripts/core/"
		for it in item_types:
			if it == "weapon":
				# Tüm silah türlerini ekle (yay, asa, değnek, hançer, balta, kılıç)
				var all_weapons := ["base_sword.tres", "base_bow.tres", "base_staff.tres", "base_dagger.tres", "base_axe.tres", "base_wand.tres"]
				for w in all_weapons:
					var wp: String = base_dir + w
					if ResourceLoader.exists(wp):
						var wi: ItemData = load(wp)
						if wi and not drop_table.possible_base_items.has(wi):
							drop_table.possible_base_items.append(wi)
			else:
				var path := _get_base_item_path(it)
				if path != "" and ResourceLoader.exists(path):
					var item: ItemData = load(path)
					if item and not drop_table.possible_base_items.has(item):
						drop_table.possible_base_items.append(item)
	
	# Animasyonları yükle
	if sprite:
		EnemyVisuals.apply_visuals(sprite, _enemy_id)
	
	# Status effect görsellerini ekle (overlay animasyonlari)
	if not has_node("StatusEffectVisual"):
		_add_status_effect_visual()

func apply_rarity(r: int, zone_tier: int) -> void:
	rarity = r
	enemy_level = max(1, zone_tier * 2 + randi_range(-1, 1))
	var mults: Dictionary = RARITY_STAT_MULT.get(rarity, RARITY_STAT_MULT[EnemyRarity.NORMAL])
	
	# Stat scaling
	xp_multiplier = mults.xp
	drop_multiplier = mults.drop_chance
	extra_drops = mults.drop_count
	
	# Apply HP multiplier
	if health:
		health.max_health *= mults.hp
		health.current_health = health.max_health
	
	# Apply damage multiplier
	contact_damage *= mults.dmg
	
	# Apply speed multiplier
	speed *= mults.speed
	
	# Apply to CharacterStats
	if stats:
		stats.base_life = health.max_health if health else stats.base_life
		stats.base_armour *= mults.hp  # Higher rarity = tougher
		# Kaçınma: bölge zorluğu + nadirlik artışı
		stats.base_evasion = maxf(5.0, stats.base_evasion * (0.5 + zone_tier * 0.3))  # zone 1→0.8x, zone 5→2.0x, zone 10→3.5x
		stats.base_evasion *= mults.get("evasion", 1.5 if rarity > EnemyRarity.NORMAL else 1.0)
		# Düşman isabeti: zone tier arttıkça artar → kaçınma daha az etkili olur
		stats.base_accuracy = 50 + zone_tier * 15
		stats.recalculate()
	
	# Roll mods for Magic+ enemies
	if rarity > EnemyRarity.NORMAL:
		_roll_mods(zone_tier)
	
	# Update name label
	_update_name_label()


func _roll_mods(_zone_tier: int) -> void:
	var mod_range: Array = RARITY_MOD_COUNT.get(rarity, [0, 0])
	var mod_count: int = randi_range(mod_range[0], mod_range[1])
	
	var available_mods: Array[String] = []
	for mod_id in ENEMY_MODS:
		var weight: int = ENEMY_MODS[mod_id].get("weight", 10)
		for w in range(weight):
			available_mods.append(mod_id)
	available_mods.shuffle()
	
	var chosen: int = 0
	for mod_id in available_mods:
		if chosen >= mod_count:
			break
		if mod_id in active_mods:
			continue
		active_mods.append(mod_id)
		chosen += 1
		
		# Apply mod effects immediately
		var mod_data: Dictionary = ENEMY_MODS[mod_id]
		
		if mod_data.has("attack_speed_pct"):
			attack_cooldown /= (1.0 + mod_data.attack_speed_pct)
		
		if mod_data.has("move_speed_pct"):
			speed *= (1.0 + mod_data.move_speed_pct)
		
		if mod_data.has("damage_pct"):
			contact_damage *= (1.0 + mod_data.damage_pct)
		
		if mod_data.has("extra_damage_pct") and mod_data.has("extra_damage_type"):
			_extra_damage_mods.append(mod_data)
		
		if mod_data.has("life_regen_pct"):
			# Life regen: restore % of max life per second
			_start_life_regen(mod_data.life_regen_pct)
		
		if mod_data.has("life_leech_pct"):
			_leech_amount = mod_data.life_leech_pct


func _start_life_regen(pct: float) -> void:
	if not health:
		return
	if has_node("RegenTimer"):
		return
	var regen_timer := Timer.new()
	regen_timer.name = "RegenTimer"
	regen_timer.wait_time = 1.0
	regen_timer.autostart = true
	add_child(regen_timer)
	regen_timer.timeout.connect(func():
		if health and is_instance_valid(health):
			var regen_amount: float = health.max_health * pct
			health.heal(regen_amount)
	)


## Grup merkezini spawn pozisyonu olarak ayarla (VS mode: sadece spawn pos)
func set_spawn_position(pos: Vector2) -> void:
	_spawn_position = pos

func _update_name_label() -> void:
	if not name_label:
		return
	# Renk zaten ARPG geleneğini anlatır: beyaz=normal, mavi=magic, sarı=rare, turuncu=unique
	var prefix: String = RARITY_ROLL_NAMES.get(rarity, "")
	name_label.text = "Sv.%d %s%s" % [enemy_level, prefix, _enemy_name]
	name_label.modulate = RARITY_COLORS.get(rarity, Color.WHITE)


## Roll rarity for an enemy spawn. Can force specific rarity (e.g. for boss).
static func roll_rarity() -> int:
	var roll := randf()
	var cumulative := 0.0
	for r in RARITY_ROLL_WEIGHTS:
		cumulative += RARITY_ROLL_WEIGHTS[r]
		if roll <= cumulative:
			return r
	return EnemyRarity.NORMAL


func _get_base_item_path(item_type: String) -> String:
	var base_dir := "res://scripts/core/"
	match item_type:
		"weapon":
			# Tüm silah türlerinden rastgele seç — önce tür, sonra model
			var weapon_types := ["sword", "bow", "staff", "dagger", "axe", "wand"]
			var wt: String = weapon_types[randi() % weapon_types.size()]
			match wt:
				"sword":
					var swords := ["base_sword.tres", "base_sword_iron.tres", "base_sword_steel.tres",
						"base_sword_war.tres", "base_sword_long.tres", "base_sword_broad.tres",
						"base_sword_ancient.tres", "base_sword_rune.tres", "base_sword_crystal.tres",
						"base_sword_shadow.tres", "base_sword_hellfire.tres", "base_sword_legion.tres",
						"base_sword_bronze.tres", "base_sword_copper.tres", "base_sword_falchion.tres",
						"base_sword_scimitar.tres", "base_sword_katana.tres", "base_sword_claymore.tres",
						"base_sword_greatsword.tres", "base_sword_bastard.tres", "base_sword_flamberge.tres",
						"base_sword_rapier.tres", "base_sword_cutlass.tres", "base_sword_zweihander.tres",
						"base_sword_titan.tres", "base_sword_void.tres", "base_sword_dragonbone.tres",
						"base_sword_soulreaper.tres", "base_sword_celestial.tres", "base_sword_doom.tres",
						"base_sword_eternal.tres", "base_sword_godslayer.tres"]
					return base_dir + swords[randi() % swords.size()]
				"bow":
					var bows := ["base_bow.tres", "base_bow_short.tres", "base_bow_long.tres",
						"base_bow_recurve.tres", "base_bow_composite.tres", "base_bow_war.tres",
						"base_bow_elven.tres", "base_bow_hunter.tres", "base_bow_silver.tres",
						"base_bow_dark.tres", "base_bow_wind.tres", "base_bow_crystal.tres",
						"base_bow_hickory.tres", "base_bow_oak.tres", "base_bow_crossbow.tres",
						"base_bow_flatbow.tres", "base_bow_yew.tres", "base_bow_longbow.tres",
						"base_bow_hybrid.tres", "base_bow_greatbow.tres", "base_bow_forest.tres",
						"base_bow_snake.tres", "base_bow_eagle.tres", "base_bow_spirit.tres",
						"base_bow_thunder.tres", "base_bow_phantom.tres", "base_bow_moon.tres",
						"base_bow_star.tres", "base_bow_shadowhunter.tres", "base_bow_windrunner.tres",
						"base_bow_sun.tres", "base_bow_apocalypse.tres"]
					return base_dir + bows[randi() % bows.size()]
				"staff":
					var staves := ["base_staff.tres", "base_staff_wood.tres", "base_staff_apprentice.tres",
						"base_staff_mage.tres", "base_staff_fire.tres", "base_staff_frost.tres",
						"base_staff_arcane.tres", "base_staff_rune.tres", "base_staff_soul.tres",
						"base_staff_dragon.tres", "base_staff_void.tres", "base_staff_phoenix.tres",
						"base_staff_bone.tres", "base_staff_crystal.tres", "base_staff_oak.tres",
						"base_staff_ivory.tres", "base_staff_obsidian.tres", "base_staff_sapphire.tres",
						"base_staff_ruby.tres", "base_staff_emerald.tres", "base_staff_amethyst.tres",
						"base_staff_twilight.tres", "base_staff_storm.tres", "base_staff_earth.tres",
						"base_staff_inferno.tres", "base_staff_ice.tres", "base_staff_lightning.tres",
						"base_staff_shadow.tres", "base_staff_mystic.tres", "base_staff_primordial.tres",
						"base_staff_astral.tres", "base_staff_infinite.tres"]
					return base_dir + staves[randi() % staves.size()]
				"dagger":
					return base_dir + "base_dagger.tres"
				"axe":
					return base_dir + "base_axe.tres"
				"wand":
					return base_dir + "base_wand.tres"
				_: return base_dir + "base_sword.tres"
		"helmet": return base_dir + "base_helmet.tres"
		"body_armour": return base_dir + "base_chest.tres"
		"gloves": return base_dir + "base_gloves.tres"
		"boots": return base_dir + "base_boots.tres"
		"offhand": return base_dir + "base_shield.tres"
		"ring": return base_dir + "base_ring.tres"
		"accessory": return base_dir + "base_amulet.tres"
		"amulet": return base_dir + "base_amulet.tres"
		"belt": return base_dir + "base_belt.tres"
		"dagger": return base_dir + "base_dagger.tres"
		"staff": return base_dir + "base_staff.tres"
		"bow": return base_dir + "base_bow.tres"
		"wand": return base_dir + "base_wand.tres"
		"axe": return base_dir + "base_axe.tres"
	return ""

func _physics_process(delta: float) -> void:
	_attack_timer = max(_attack_timer - delta, 0.0)
	
	# === STAGGER / KNOCKBACK DURUMU ===
	if _stagger_timer > 0.0:
		_stagger_timer -= delta
		velocity = _stagger_knockback_dir * _stagger_knockback_force * (1.0 - ease(1.0 - _stagger_timer / _stagger_duration, 0.5))
		move_and_slide()
		_update_animation()
		return
	
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(_target):
			return
	
	if ailment_ctrl and ailment_ctrl.is_frozen():
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return
	
	var to_target: Vector2 = _target.global_position - global_position
	var dist: float = to_target.length()
	
	# === VS MODE: SADECE KOVALA, YAKINSA VUR ===
	_vs_chase_and_attack(dist)
	
	_update_animation()

## VS: Oyuncuya dogru kovala ve yakinsa vur
func _vs_chase_and_attack(dist: float) -> void:
	if not is_instance_valid(_target):
		return
	
	# Her zaman oyuncuya dogru git
	_move_toward(_target.global_position)
	
	# Yakindaysa vur (sadece melee)
	if dist < 35.0 and _attack_timer <= 0.0:
		_attack_player()
		_play_attack_anim()




func _move_in_direction(dir: Vector2) -> void:
	var move_speed: float = speed
	if ailment_ctrl:
		var mods: Dictionary = ailment_ctrl.get_combined_modifiers()
		move_speed *= (1.0 + mods.get("movement_speed", 0.0))
		move_speed *= (1.0 + mods.get("action_speed", 0.0))
	velocity = dir * move_speed
	move_and_slide()

func _move_toward(target: Vector2) -> void:
	var dir: Vector2 = (target - global_position).normalized()
	var move_speed: float = speed
	
	if ailment_ctrl:
		var mods: Dictionary = ailment_ctrl.get_combined_modifiers()
		move_speed *= (1.0 + mods.get("movement_speed", 0.0))
		move_speed *= (1.0 + mods.get("action_speed", 0.0))
	
	velocity = dir * move_speed
	
	# Yön bilgisini güncelle (sprite flip için)
	if velocity.length_squared() > 1.0:
		_anim_dir = _get_move_dir(velocity)
	move_and_slide()

func _get_move_dir(vel: Vector2) -> String:
	if abs(vel.x) > abs(vel.y):
		if sprite:
			sprite.flip_h = vel.x < 0
		return "right"
	else:
		if sprite:
			sprite.flip_h = false
		return "front" if vel.y > 0 else "back"

func _update_animation() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	
	# Saldırı animasyonu oynuyorsa bekle
	if _attack_anim_playing:
		if not sprite.is_playing():
			_attack_anim_playing = false
			_anim_state = AnimState.IDLE
		else:
			return
	
	# Hangi animasyonu oynatacağımıza karar ver
	if velocity.length_squared() > 10.0:
		if _anim_state != AnimState.WALK:
			_anim_state = AnimState.WALK
			var aname: String = "walk_%s" % _anim_dir
			if sprite.sprite_frames.has_animation(aname):
				sprite.animation = aname
				sprite.play()
	else:
		if _anim_state != AnimState.IDLE:
			_anim_state = AnimState.IDLE
			var aname: String = "idle_%s" % _anim_dir
			if sprite.sprite_frames.has_animation(aname):
				sprite.animation = aname
				sprite.play()

func _attack_player() -> void:
	if not is_instance_valid(_target) or not _target.has_node("Health"):
		return
	
	# Apply extra damage from mods
	var total_damage: float = contact_damage
	for mod_data in _extra_damage_mods:
		total_damage += contact_damage * mod_data.get("extra_damage_pct", 0.0)
	
	var final_damage: float = total_damage
	var hit_result: Dictionary = {"hit": true, "damage": total_damage, "is_crit": false}
	
	if stats:
		var defender_stats: CharacterStats = null
		if _target.has_node("CharacterStats"):
			defender_stats = _target.get_node("CharacterStats") as CharacterStats
		hit_result = CombatEngine.calculate_hit(stats, defender_stats, total_damage, damage_type, ["attack"], false)
		final_damage = hit_result.damage
	
	if hit_result.hit:
		var target_health: Health = _target.get_node_or_null("Health")
		if target_health:
			target_health.take_damage(final_damage, self, [damage_type, "attack"], false)
	
	_attack_timer = attack_cooldown

func _play_attack_anim() -> void:
	if sprite and sprite.sprite_frames:
		var aname: String = "attack_%s" % _anim_dir
		if sprite.sprite_frames.has_animation(aname):
			# Attack spritesheet'te flip_h kullanma — her yön kendi satırında
			sprite.flip_h = false
			sprite.animation = aname
			sprite.play()
			_attack_anim_playing = true
			_anim_state = AnimState.ATTACK

# Stagger state: düşman geçici olarak sersemler ve geriye yalpalar
var _stagger_timer: float = 0.0
var _stagger_duration: float = 0.25  # saniye
var _stagger_knockback_dir: Vector2 = Vector2.ZERO
var _stagger_knockback_force: float = 0.0

func _apply_hit_reaction(source_pos: Vector2, knockback_force: float, stagger_duration: float) -> void:
	# Düşmanın stagger durumuna geç — knockback vektörü hesapla
	_stagger_timer = stagger_duration
	_stagger_duration = stagger_duration
	_stagger_knockback_force = knockback_force
	_stagger_knockback_dir = (global_position - source_pos).normalized()

func _on_hit(_amount: float, _source: Node, _tags: Array) -> void:
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE
	
	# Vuran kaynaktan knockback yönü ve kuvveti
	if is_instance_valid(_source):
		var kb_force: float = 150.0
		var stagger_dur: float = 0.25
		
		# Nadir/Eşsiz düşmanlar daha dirençli
		if rarity == EnemyRarity.RARE:
			kb_force *= 0.5
			stagger_dur *= 0.6
		elif rarity == EnemyRarity.UNIQUE:
			kb_force *= 0.3
			stagger_dur *= 0.4
		
		_apply_hit_reaction(_source.global_position, kb_force, stagger_dur)

func _on_death() -> void:
	# Collision'u hemen devre dışı bırak — düşman artık çarpışma/etkileşim yapmasın
	$CollisionShape2D.set_deferred("disabled", true)
	if name_label:
		name_label.hide()
	
	# Ekran sarsıntısı — nadirliğe göre şiddetlenir
	var shake_intensity: float = 3.0
	var shake_duration: float = 0.3
	match rarity:
		EnemyRarity.MAGIC:
			shake_intensity = 5.0
			shake_duration = 0.4
		EnemyRarity.RARE:
			shake_intensity = 8.0
			shake_duration = 0.5
		EnemyRarity.UNIQUE:
			shake_intensity = 12.0
			shake_duration = 0.7
	EventBus.screen_shake.emit(shake_intensity, shake_duration)
	
	# Ölüm efekti: sprite anında kırmızı + büyü + yukarı uçuş + kaybol
	if sprite:
		var orig_scale := sprite.scale
		var orig_pos := sprite.position
		sprite.modulate = Color(1.0, 0.1, 0.1, 1.0)  # Anında kırmızı
		
		var tw := create_tween().set_parallel(true)
		# Büyüyüp kaybol (0.8s)
		tw.tween_property(sprite, "scale", orig_scale * 2.0, 0.7).set_ease(Tween.EASE_OUT)
		tw.tween_property(sprite, "modulate", Color(1.0, 0.0, 0.0, 0.0), 0.6).set_delay(0.15)
		# Hafif yukarı uçuş (ölürken geriye devrilme hissi)
		tw.tween_property(sprite, "position", orig_pos + Vector2(0, -12), 0.5).set_ease(Tween.EASE_OUT)
		# Döndürme
		tw.tween_property(sprite, "rotation", deg_to_rad(randf_range(15, 45)) * (-1 if randf() < 0.5 else 1), 0.6)
	
	# ÖLÜM EFEKTİ (pas)
	_spawn_death_effect()
	
	# XP GEM'LERİNİ DÜŞÜR — VS görünür kristal sistemi
	_spawn_xp_gems()
	
	# 0.9sn bekle (efektin oynaması için)
	await get_tree().create_timer(0.9).timeout
	
	# Guvenlik: node'un hala geçerli olduğundan emin ol
	if not is_instance_valid(self):
		return
	
	# Drop items with rarity multipliers
	var original_drop_chance: float = drop_table.drop_chance
	drop_table.drop_chance *= drop_multiplier
	drop_table.try_drop(global_position)
	drop_table.drop_chance = original_drop_chance  # Restore
	
	# Extra drops for rare+ enemies
	for i in range(extra_drops):
		drop_table.drop_chance = original_drop_chance * 1.5
		drop_table.try_drop(global_position)
	drop_table.drop_chance = original_drop_chance
	
	queue_free()

func _spawn_death_effect() -> void:
	"""Ölüm patlama efektleri kaldırıldı — ekran kirliliğini önlemek için."""
	pass

func _spawn_xp_gems() -> void:
	"""Ölünce XP kristalleri düşür — VS tarzı görünür XP toplama."""
	var total_xp: float = xp_reward * xp_multiplier
	
	# Kaç kristal düşecek? (nadirliğe göre artar)
	var gem_count: int = 1
	match rarity:
		EnemyRarity.NORMAL: gem_count = 1
		EnemyRarity.MAGIC: gem_count = 2
		EnemyRarity.RARE: gem_count = 4
		EnemyRarity.UNIQUE: gem_count = 8
	
	var xp_per_gem: float = total_xp / float(gem_count)
	
	var gem_scene_path := "res://scripts/core/xp_gem.tscn"
	if not ResourceLoader.exists(gem_scene_path):
		return
	
	var gem_scene := load(gem_scene_path) as PackedScene
	if not gem_scene:
		return
	
	for i in range(gem_count):
		var gem := gem_scene.instantiate() as XPGem
		if not gem:
			continue
		get_tree().current_scene.add_child(gem)
		gem.setup(xp_per_gem, global_position)

## Support gem dÃ¼ÅŸÃ¼rme ÅŸansÄ±. Her Ã¶lÃ¼mde %12 temel ÅŸans + rarity bonusu.
func _try_support_gem_drop() -> void:
	var base_chance: float = 0.12
	# Rarity bonusu
	var rarity_mult: float = 1.0
	match rarity:
		EnemyRarity.MAGIC:
			rarity_mult = 2.0
		EnemyRarity.RARE:
			rarity_mult = 4.0
		EnemyRarity.UNIQUE:
			rarity_mult = 8.0
	
	if randf() > base_chance * rarity_mult:
		return
	
	# TÃ¼m support gem'leri yÃ¼kle
	var all_supports: Array[SupportData] = []
	var supp_dir := "res://data/supports/"
	var dir := DirAccess.open(supp_dir)
	if dir:
		for fname in dir.get_files():
			if fname.ends_with(".tres") or fname.ends_with(".res"):
				var path := supp_dir + fname
				if ResourceLoader.exists(path):
					var sd: SupportData = load(path) as SupportData
					if sd:
						all_supports.append(sd)
	
	if all_supports.is_empty():
		return
	
	# Rastgele bir support gem seÃ§
	var chosen: SupportData = all_supports[randi() % all_supports.size()]
	if not chosen:
		return
	
	# Player's gem stash'ine ekle
	var player := get_tree().get_first_node_in_group("player") as Node
	if player and player.has_method("add_to_gem_stash"):
		player.add_to_gem_stash(chosen)
		print("Support gem dÃ¼ÅŸtÃ¼: ", chosen.display_name)
