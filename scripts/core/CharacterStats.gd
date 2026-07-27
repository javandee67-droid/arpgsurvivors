extends Node
class_name CharacterStats
## Full PoE-style stat system with attributes, defenses, offenses, and utilities.

signal stats_changed

# --- Core Attributes ---
@export var strength: int = 10
@export var dexterity: int = 10
@export var intelligence: int = 10

# --- Base values ---
@export var base_life: float = 100.0
@export var base_mana: float = 60.0
@export var base_mana_regen: float = 2.0  ## Sabit pasif mana yenilenmesi (saniyede)
@export var base_energy_shield: float = 0.0
@export var base_armour: float = 0.0
@export var base_evasion: float = 0.0
@export var base_accuracy: float = 50.0
@export var base_movement_speed: float = 1.0
@export var base_critical_chance: float = 5.0
@export var base_critical_multiplier: float = 150.0
@export var base_attack_speed: float = 1.0
@export var base_cast_speed: float = 1.0
@export var base_block_chance: float = 0.0

## Seviye atlayınca dağıtılmak üzere biriken stat puanları
var stat_points: int = 0

## Pasif ağaç için biriken puanlar (her seviye +1)
var passive_points: int = 0

@export var base_fire_resistance: float = -75.0
@export var base_cold_resistance: float = -75.0
@export var base_lightning_resistance: float = -75.0
@export var base_chaos_resistance: float = -75.0
@export var max_fire_resistance: float = 75.0
@export var max_cold_resistance: float = 75.0
@export var max_lightning_resistance: float = 75.0
@export var max_chaos_resistance: float = 75.0

# --- Total attributes (base + equipment) for display ---
var total_strength: float
var total_dexterity: float
var total_intelligence: float

# --- Computed offense stats ---
var max_life: float
var max_mana: float
var max_energy_shield: float
var armour: float
var evasion: float
var accuracy: float
var movement_speed: float
var critical_chance: float
var critical_multiplier: float
# spell_critical_chance kaldirildi — tek kritik sansi var
var attack_speed: float
var cast_speed: float
var projectile_speed: float = 0.0  ## % increased Projectile Speed
var life_recovery_rate: float = 0.0  ## % increased Life Recovery Rate (regen + leech + recoup)
var mana_recovery_rate: float = 0.0  ## % increased Mana Recovery Rate (regen + leech + recoup)
var fire_resistance: float
var cold_resistance: float
var lightning_resistance: float
var chaos_resistance: float
var physical_damage_flat: float
var fire_damage_flat: float
var cold_damage_flat: float
var lightning_damage_flat: float
var chaos_damage_flat: float
var physical_damage_increased: float
var elemental_damage_increased: float
var cold_damage_increased: float
var fire_damage_increased: float
var lightning_damage_increased: float
var chaos_damage_increased: float
var damage_over_time_increased: float
var projectile_damage_increased: float
var area_damage_increased: float
var chain_count: int = 0  ## Flat chain count (aura + passive tree)

# --- Computed defense stats ---
var attack_block_chance: float
var spell_block_chance: float
var attack_dodge_chance: float
var life_regen_per_second: float
var mana_regen_per_second: float
var es_regen_per_second: float
var life_leech_percent: float
var mana_leech_percent: float
var life_gain_on_hit: float
var life_on_kill: float
var mana_on_kill: float

# --- Energy Shield recharge ---
var es_recharge_delay: float        ## Base hasar sonrası recharge başlama gecikmesi (sn)
var es_recharge_rate_percent: float ## Max ES'in yüzdesi olarak recharge hızı (örn. 33.0 = %33/sn)

# --- Computed utility stats ---
var ailment_effect: float  ## % increased effect of ailments
var ailment_chance: float = 0.0  ## % increased chance to inflict ailments
var ailment_duration: float = 0.0  ## % increased duration of ailments
var shock_magnitude: float = 0.0   ## % increased Shock magnitude
var chill_magnitude: float = 0.0   ## % increased Chill magnitude
var ignite_magnitude: float = 0.0  ## % increased Ignite magnitude
var bleed_magnitude: float = 0.0   ## % increased Bleed magnitude
var ailment_magnitude: float = 0.0 ## % increased magnitude of all ailments
# flask_effect kaldırıldı
var cooldown_recovery: float ## % increased cooldown recovery speed

# --- Melee Strike Range bonus (from passive tree) ---
var melee_range_bonus: float = 0.0  ## Pasif agacindan +0.2 metres vb -> pixel cinsinden bonus

# --- Armour also applies to Elemental Damage ---
var armour_elemental_pct: float = 0.0  ## % of Armour that applies to Fire/Cold/Lightning hits

# --- Generic all-damage multiplier ---
var all_damage_increased: float = 0.0

# --- Item rarity / quantity (for drops) ---
var item_rarity: float = 0.0
var item_quantity: float = 0.0

# --- Penetration (flat resistance ignore) ---
var penetration_fire: float = 0.0
var penetration_cold: float = 0.0
var penetration_lightning: float = 0.0
var penetration_elemental: float = 0.0
var penetration_chaos: float = 0.0

# --- Exposure ---
var exposure_effect: float = 0.0

# --- Culling Strike ---
var culling_threshold: float = 0.0  ## % of max life at which culling applies (default 0 = off)

# --- Recoup ---
var life_recoup_pct: float = 0.0
var mana_recoup_pct: float = 0.0
var recoup_speed: float = 0.0

# --- Armour Break ---
var armour_break_pct: float = 0.0      ## % increased Armour Break amount
var armour_break_duration: float = 0.0 ## % increased duration
var armour_break_effect: float = 0.0   ## % increased effect of Fully Broken Armour
var fully_broken_fire_dmg_taken: bool = false  ## Fully broken enemies take extra fire damage
var fully_broken_cold_lightning_taken: bool = false  ## Fully broken enemies take extra cold/lightning dmg
var fully_broken_no_regen: bool = false  ## Fully broken enemies cannot regenerate life

# --- Withered ---
var withered_magnitude: float = 0.0  ## % increased Withered effect per stack
var withered_chance: float = 0.0  ## % chance to inflict Withered on hit
var withered_duration: float = 0.0  ## % increased Withered duration
var withered_damage_reduction: float = 0.0  ## Withered enemies deal % reduced damage

# --- Surrounded (conditional stats, active when enemies nearby) ---
var surrounded_attack_damage: float = 0.0  ## % increased Attack Damage while Surrounded
var surrounded_attack_speed: float = 0.0  ## % increased Attack Speed while Surrounded
var surrounded_movement_speed: float = 0.0  ## % increased Movement Speed while Surrounded
var surrounded_armour: float = 0.0  ## % increased Armour while Surrounded
var surrounded_evasion: float = 0.0  ## % increased Evasion while Surrounded
var surrounded_accuracy: float = 0.0  ## % increased Accuracy while Surrounded
var surrounded_life_regen: float = 0.0  ## % life regen while Surrounded
var surrounded_all_damage: float = 0.0  ## Generic % increased damage while Surrounded

# --- Daze ---
var daze_chance: float = 0.0      ## flat % chance to Daze on Hit
var daze_duration: float = 0.0    ## % increased Daze duration
var damage_vs_dazed: float = 0.0  ## % increased Damage against Dazed enemies

# --- Blind ---
var blind_chance: float = 0.0     ## flat % chance to Blind on Hit
var blind_effect: float = 0.0     ## % increased Blind Effect

# --- Electrocute ---
var freeze_buildup: float = 0.0  ## % increased Freeze Buildup (chill'den freeze'e daha hizli)
var electrocute_buildup: float = 0.0  ## % increased Electrocute Buildup

# --- Thorns ---
var thorns_flat: float = 0.0      ## flat Thorns damage
var thorns_pct: float = 0.0       ## % of armour/etc as Thorns

# --- Aura ---
var aura_magnitude: float = 0.0   ## % increased Aura Skill Magnitudes
var aura_level: int = 1           ## Aura seviyesi (player level ile yükselir)

# --- Ailment speed (faster/slower damage over time) ---
var ailment_speed: float = 0.0        ## generic: Damaging Ailments deal damage X% faster
var ignite_speed: float = 0.0        ## Ignite-specific speed
var bleed_speed: float = 0.0         ## Bleed-specific speed
var poison_duration: float = 0.0     ## % increased Poison Duration
var bleeding_duration: float = 0.0   ## % increased Bleeding Duration
var freeze_duration_on_enemies: float = 0.0  ## % increased Freeze Duration on enemies
var chill_duration: float = 0.0      ## % increased Chill Duration
var ailment_threshold: float = 0.0   ## % increased Ailment Threshold (defensive)
var ailment_duration_on_you: float = 0.0  ## % reduced Ailment Duration on you (defensive)

# --- Skill / AoE / Duration ---
var skill_effect_duration: float = 0.0  ## % increased Skill Effect Duration
var area_of_effect: float = 0.0         ## % increased Area of Effect

# --- Utility (Pasif Ağaç) ---
var pickup_radius: float = 0.0
var gold_find: float = 0.0
var experience_gain: float = 0.0
var luck: float = 0.0
var extra_projectiles: int = 0

# --- Mana / Life Cost & Reservation ---
var mana_cost_efficiency: float = 0.0  ## % increased Mana Cost Efficiency (lower cost)
var mana_cost_pct: float = 0.0        ## % increased Mana Cost of Skills
var life_cost_pct: float = 0.0        ## % increased Life Cost of Skills
var life_cost_conversion_pct: float = 0.0  ## % of Mana Cost converted to Life Cost
var reservation_efficiency: float = 0.0  ## % increased Reservation Efficiency (lower reservation)

# --- Debuff / Slow / Buff effect ---
var slow_potency_reduction: float = 0.0  ## % reduced Slowing Potency of Debuffs on You
var debuff_expiry_speed: float = 0.0    ## % faster Debuffs on You expire
var buff_expiry_speed: float = 0.0      ## % slower Buffs on You expire
var slow_magnitude: float = 0.0         ## % increased Slow Magnitude of Debuffs you inflict
var buff_effect_self: float = 0.0       ## % increased effect of Buffs on You

# --- Leech enhancements ---
var leech_amount: float = 0.0        ## % increased amount of Life/Mana Leeched
var leech_speed: float = 0.0         ## leech speed modifier
var damage_while_leeching: float = 0.0
var attack_speed_while_leeching: float = 0.0
var armour_evasion_while_leeching: float = 0.0

# --- Block enhancements ---
var block_recovery: float = 0.0      ## % increased Block Recovery

# --- Recoup speed ---
# (already added above)

# --- Extra Damage as X (Gain X% of Damage as Extra Y) ---
var extra_damage_all: Dictionary = {}  ## key: element (fire/cold/lightning/chaos/physical), value: % of ALL damage gained as extra
var extra_damage_physical: Dictionary = {}  ## key: element, value: % of Physical damage gained as extra
var extra_damage_elemental: Dictionary = {}  ## key: element, value: % of Elemental damage gained as extra
var extra_damage_cold: Dictionary = {}  ## key: element, value: % of Cold damage gained as extra
var extra_damage_fire: Dictionary = {}  ## key: element, value: % of Fire damage gained as extra
var extra_damage_lightning: Dictionary = {}  ## key: element, value: % of Lightning damage gained as extra
var extra_damage_chaos: Dictionary = {}  ## key: element, value: % of Chaos damage gained as extra
var extra_damage_conditional: Dictionary = {}  ## key: "source_target_condition" (e.g. "cold_fire_frozen"), value: % extra damage when condition met

# --- Splash Damage ---
var splash_damage: bool = false  ## Strikes deal Splash Damage
var splash_radius: float = 60.0  ## Splash AoE radius in pixels, scales with AoE increases
var splash_damage_percent: float = 50.0  ## % of hit damage dealt to splash targets

# --- Aggravated Bleeding ---
var aggravated_bleeding: bool = false  ## Bleeding is always Aggravated
var aggravate_bleed_chance: float = 0.0  ## % chance to Aggravate Bleeding

# --- Condition Damage (pasif ağacından, CombatEngine'de kontrol edilir) ---
var damage_vs_blinded: float = 0.0      ## % increased Damage against Blinded enemies
var damage_vs_low_life: float = 0.0     ## % increased Damage against Low Life enemies
var damage_vs_full_life: float = 0.0    ## % increased Damage against Full Life enemies
var damage_vs_frozen: float = 0.0       ## % increased Damage against Frozen enemies
var damage_vs_burning: float = 0.0      ## % increased Damage against Burning enemies
var damage_vs_ignited: float = 0.0      ## % increased Damage against Ignited enemies
var damage_vs_shocked: float = 0.0      ## % increased Damage against Shocked enemies
var damage_vs_chilled: float = 0.0      ## % increased Damage against Chilled enemies
var damage_vs_rare_unique: float = 0.0  ## % increased Damage against Rare/Unique enemies
var damage_vs_immobilised: float = 0.0  ## % increased Damage against Immobilised enemies
var damage_vs_ailments: float = 0.0     ## % increased Damage against enemies affected by any Ailment
var damage_if_crit_recently: float = 0.0 ## % increased Damage if you've dealt a Crit Recently
var last_crit_time: float = -99999.0    ## Timestamp (ms) of last crit, for damage_if_crit_recently

# --- Dual Wield ---
var is_dual_wielding: bool = false  ## Computed: hem WEAPON hem OFFHAND'te silah var mı
var attack_speed_dual_wield: float = 0.0  ## % increased Attack Speed while Dual Wielding
var attack_damage_dual_wield: float = 0.0  ## % increased Attack Damage while Dual Wielding
var accuracy_dual_wield: float = 0.0  ## % increased Accuracy Rating while Dual Wielding
var critical_chance_dual_wield: float = 0.0  ## % increased Critical Hit Chance while Dual Wielding
var movement_speed_dual_wield: float = 0.0  ## % increased Movement Speed while Dual Wielding

# --- Maim ---
var maim_chance: float = 0.0  ## % chance to Maim on Hit
var damage_vs_maimed: float = 0.0  ## % increased Damage against Maimed enemies

# --- Lucky/Unlucky ---
var lucky_hits: float = 0.0  ## Damage with Hits is Lucky
var unlucky_hits: float = 0.0  ## Damage of Enemies Hitting you is Unlucky

# --- Passive tree bonus accumulators (recalculate-safe) ---
var _passive_flat_mods: Dictionary = {}    ## Pasif ağacından gelen flat bonuslar
var _passive_increased_mods: Dictionary = {}  ## Pasif ağacından gelen % bonuslar

var _equipment: Equipment = null

## --- Aktif buff'lardan gelen geçici stat modifier'ları ---
## key: buff_id (örn. "haste"), value: {"attack_speed": 30.0, "movement_speed": 20.0}
## Değerler INCREASED yüzde olarak (30.0 = %30 increased attack_speed)
var _active_buff_mods: Dictionary = {}

## --- Aktif buff'lardan gelen geçici FLAT modifier'lar ---
## key: buff_id, value: {"chain_count": 1.0}
## Bunlar flat dict'e eklenir (increased/increased yerine)
var _active_buff_flat_mods: Dictionary = {}

## Bir buff'dan gelen stat modifier'larını uygula.
## buff_id: Benzersiz buff tanımlayıcı (örn. "haste")
## modifiers: {"stat_name": increased_yuzde} — 30.0 = %30 increased
func apply_buff_modifier(buff_id: String, modifiers: Dictionary) -> void:
	_active_buff_mods[buff_id] = modifiers
	recalculate()

## Bir buff'ın modifier'larını kaldır.
func remove_buff_modifier(buff_id: String) -> void:
	_active_buff_mods.erase(buff_id)
	recalculate()

## Bir buff'dan gelen FLAT stat modifier'larını uygula (chain_count gibi).
func apply_buff_flat_modifier(buff_id: String, modifiers: Dictionary) -> void:
	_active_buff_flat_mods[buff_id] = modifiers
	recalculate()

## Bir buff'ın flat modifier'larını kaldır.
func remove_buff_flat_modifier(buff_id: String) -> void:
	_active_buff_flat_mods.erase(buff_id)
	recalculate()

func _ready() -> void:
	recalculate()

# Helper'lar recalculate() icinde tanimlanir (increased/flat lokal degiskenler)

func set_equipment_source(equipment: Equipment) -> void:
	_equipment = equipment
	equipment.equipment_changed.connect(recalculate)
	recalculate()

func recalculate() -> void:
	var flat := _collect_affixes(false)
	var increased := _collect_affixes(true)
	# Pasif ağacı bonuslarını flat/increased sözlüklerine ekle (recalculate-safe)
	for k in _passive_flat_mods:
		flat[k] = flat.get(k, 0.0) + _passive_flat_mods[k]
	for k in _passive_increased_mods:
		increased[k] = increased.get(k, 0.0) + _passive_increased_mods[k]
	# Aktif buff'lardan gelen increased modifier'ları ekle
	for buff_id in _active_buff_mods:
		var buff_mods: Dictionary = _active_buff_mods[buff_id]
		for stat_key in buff_mods:
			increased[stat_key] = increased.get(stat_key, 0.0) + buff_mods[stat_key]
	# Aktif buff'lardan gelen FLAT modifier'ları ekle (chain_count gibi)
	for buff_id in _active_buff_flat_mods:
		var buff_mods: Dictionary = _active_buff_flat_mods[buff_id]
		for stat_key in buff_mods:
			flat[stat_key] = flat.get(stat_key, 0.0) + buff_mods[stat_key]

	# Helper: increased dict'ten oku, alternatif key adlarini da dene
	var _get_inc := func(p: String, a: String = "") -> float:
		var v: float = increased.get(p, 0.0)
		if v == 0.0 and not a.is_empty():
			v = increased.get(a, 0.0)
		return v

	# Helper: flat dict'ten oku, alternatif key adlarini da dene
	var _get_flat := func(p: String, a: String = "") -> float:
		var v: float = flat.get(p, 0.0)
		if v == 0.0 and not a.is_empty():
			v = flat.get(a, 0.0)
		return v

	# --- Attributes (base + affix flat) ---
	total_strength = strength + flat.get("strength", 0.0)
	total_dexterity = dexterity + flat.get("dexterity", 0.0)
	total_intelligence = intelligence + flat.get("intelligence", 0.0)

	# --- Attribute passive bonuses ---
	# Strength: +2 HP per point, +1 physical damage per point
	# --- Dual Wield Check (hem WEAPON hem OFFHAND'te silah var mı?) ---
	is_dual_wielding = false
	if _equipment:
		var main_wp: ItemData = _equipment.get_item_in_slot(Equipment.Slot.WEAPON)
		var off_wp: ItemData = _equipment.get_item_in_slot(Equipment.Slot.OFFHAND)
		if main_wp and off_wp:
			if off_wp.base_physical_damage_min > 0.0 or off_wp.base_physical_damage_max > 0.0:
				is_dual_wielding = true

	var life_from_str: float = total_strength * 2.0
	var phys_from_str: float = total_strength * 1.0
	
	# Intelligence: +2 Mana per point, +1 flat Energy Shield per point
	var mana_from_int: float = total_intelligence * 2.0
	var es_from_int_flat: float = total_intelligence * 1.0
	
	# Dexterity: +0.1% evasion per point, +0.2% attack speed per point
	var dex_evasion_pct: float = total_dexterity * 0.1
	var dex_attack_speed_pct: float = total_dexterity * 0.2
	
	var accuracy_from_dex: float = total_dexterity * 2.0

	# --- Life / Mana / ES ---
	# Not: Pasif agaci "base_life" key'ini kullanir, diger kaynaklar "max_life"
	max_life = (base_life + life_from_str + flat.get("max_life", 0.0)) * (1.0 + _get_inc.call("max_life", "base_life") / 100.0)
	max_mana = (base_mana + mana_from_int + flat.get("max_mana", 0.0)) * (1.0 + _get_inc.call("max_mana", "base_mana") / 100.0)
	max_energy_shield = (base_energy_shield + es_from_int_flat + _get_flat.call("max_energy_shield", "energy_shield")) * (1.0 + _get_inc.call("max_energy_shield", "base_energy_shield") / 100.0)

	# --- Defenses ---
	armour = (base_armour + flat.get("armour", 0.0)) * (1.0 + increased.get("armour", 0.0) / 100.0)
	evasion = (base_evasion + flat.get("evasion", 0.0)) * (1.0 + (increased.get("evasion", 0.0) + dex_evasion_pct) / 100.0)
	accuracy = (base_accuracy + accuracy_from_dex + flat.get("accuracy", 0.0)) * (1.0 + _get_inc.call("accuracy", "base_accuracy") / 100.0)
	movement_speed = base_movement_speed * (1.0 + increased.get("movement_speed", 0.0) / 100.0)

	# --- Chain Count (flat) ---
	chain_count = int(flat.get("chain_count", 0.0))

		# --- Projectile Speed ---
	projectile_speed = increased.get("projectile_speed", 0.0)

	# --- Crit (base + flat from items + increased from passives) ---
	critical_chance = (base_critical_chance + flat.get("critical_chance", 0.0)) * (1.0 + _get_inc.call("critical_chance") / 100.0)
	critical_multiplier = (base_critical_multiplier + flat.get("critical_multiplier", 0.0)) * (1.0 + _get_inc.call("critical_multiplier") / 100.0)
	# spell_critical_chance kaldirildi

	# --- Speed (weapon base_attack_speed from flat, multiplied with char base) ---
	var weapon_speed_mult: float = flat.get("attack_speed", 0.0)
	if weapon_speed_mult <= 0.0:
		weapon_speed_mult = 1.0
	attack_speed = base_attack_speed * weapon_speed_mult * (1.0 + (increased.get("attack_speed", 0.0) + dex_attack_speed_pct) / 100.0)
	# Dual wield attack speed bonus (pasif ağacından: "attack_speed_dual_wield")
	attack_speed_dual_wield = increased.get("attack_speed_dual_wield", 0.0)
	attack_damage_dual_wield = increased.get("attack_damage_dual_wield", 0.0)
	accuracy_dual_wield = increased.get("accuracy_dual_wield", 0.0)
	critical_chance_dual_wield = increased.get("critical_chance_dual_wield", 0.0)
	movement_speed_dual_wield = increased.get("movement_speed_dual_wield", 0.0)
	if is_dual_wielding:
		if attack_speed_dual_wield > 0.0:
			attack_speed *= (1.0 + attack_speed_dual_wield / 100.0)
		if attack_damage_dual_wield > 0.0:
			physical_damage_increased += attack_damage_dual_wield
			# attack damage increases physical damage as well
		if accuracy_dual_wield > 0.0:
			accuracy *= (1.0 + accuracy_dual_wield / 100.0)
		if critical_chance_dual_wield > 0.0:
			critical_chance *= (1.0 + critical_chance_dual_wield / 100.0)
		if movement_speed_dual_wield > 0.0:
			movement_speed *= (1.0 + movement_speed_dual_wield / 100.0)
	# Weapon base cast speed from flat, multiplied with char base
	var weapon_cast_speed_mult: float = flat.get("cast_speed", 0.0)
	if weapon_cast_speed_mult <= 0.0:
		weapon_cast_speed_mult = 1.0
	cast_speed = base_cast_speed * weapon_cast_speed_mult * (1.0 + increased.get("cast_speed", 0.0) / 100.0)

	# --- Block & Dodge ---
	attack_block_chance = clampf(base_block_chance + flat.get("attack_block_chance", 0.0) / 100.0 + increased.get("block_chance", 0.0) / 100.0, 0.0, 0.75)
	spell_block_chance = clampf(flat.get("spell_block_chance", 0.0) / 100.0 + increased.get("spell_block_chance", 0.0) / 100.0, 0.0, 0.75)
	# Kaçınma şansı artık evasion puanından hesaplanır (CombatEngine._calculate_hit_chance)
	# Ayrı bir flat attack_dodge_chance yok — affix'ler evasion'a eklenir
	attack_dodge_chance = 0.0

	# --- Resistances (all_resistance affix adds to all 4) ---
	# Her direncin kendi max değeri var; eşya/pasiften gelen "max_X_resistance" ile artırılabilir.
	# Aura buff_tag'lari da "fire_resistance:40" ile deger ekleyebilir (increased dict uzerinden)
	var all_res: float = flat.get("all_resistance", 0.0) + increased.get("all_resistance", 0.0)
	var fire_cap: float = max_fire_resistance + flat.get("max_fire_resistance", 0.0)
	var cold_cap: float = max_cold_resistance + flat.get("max_cold_resistance", 0.0)
	var light_cap: float = max_lightning_resistance + flat.get("max_lightning_resistance", 0.0)
	var chaos_cap: float = max_chaos_resistance + flat.get("max_chaos_resistance", 0.0)
	fire_resistance = clampf(base_fire_resistance + flat.get("fire_resistance", 0.0) + increased.get("fire_resistance", 0.0) + all_res, -200.0, fire_cap)
	cold_resistance = clampf(base_cold_resistance + flat.get("cold_resistance", 0.0) + increased.get("cold_resistance", 0.0) + all_res, -200.0, cold_cap)
	lightning_resistance = clampf(base_lightning_resistance + flat.get("lightning_resistance", 0.0) + increased.get("lightning_resistance", 0.0) + all_res, -200.0, light_cap)
	chaos_resistance = clampf(base_chaos_resistance + flat.get("chaos_resistance", 0.0) + increased.get("chaos_resistance", 0.0) + all_res, -200.0, chaos_cap)

	# --- Damage ---
	physical_damage_flat = flat.get("physical_damage", 0.0) + flat.get("adds_physical_damage", 0.0) + phys_from_str
	fire_damage_flat = flat.get("adds_fire_damage", 0.0)
	cold_damage_flat = flat.get("adds_cold_damage", 0.0)
	lightning_damage_flat = flat.get("adds_lightning_damage", 0.0)
	chaos_damage_flat = flat.get("adds_chaos_damage", 0.0)
	physical_damage_increased = increased.get("physical_damage", 0.0)
	elemental_damage_increased = increased.get("elemental_damage", 0.0) + increased.get("spell_damage", 0.0)
	cold_damage_increased = increased.get("cold_damage", 0.0)
	fire_damage_increased = increased.get("fire_damage", 0.0)
	lightning_damage_increased = increased.get("lightning_damage", 0.0)
	chaos_damage_increased = increased.get("chaos_damage", 0.0)
	damage_over_time_increased = increased.get("damage_over_time", 0.0)
	projectile_damage_increased = increased.get("projectile_damage", 0.0)
	area_damage_increased = increased.get("area_damage", 0.0)
	all_damage_increased = increased.get("all_damage", 0.0)

	# --- Regen & Leech ---
	life_recovery_rate = increased.get("life_recovery_rate", 0.0)
	life_regen_per_second = (flat.get("life_regen", 0.0) + max_life * increased.get("life_regen", 0.0) / 100.0) * (1.0 + life_recovery_rate / 100.0)
	mana_recovery_rate = increased.get("mana_recovery_rate", 0.0)
	mana_regen_per_second = (base_mana_regen + flat.get("mana_regen", 0.0) + max_mana * increased.get("mana_regen", 0.0) / 100.0) * (1.0 + mana_recovery_rate / 100.0)
	es_regen_per_second = max_energy_shield * increased.get("energy_shield_regen", 0.0) / 100.0
	life_leech_percent = flat.get("life_leech", 0.0)  # affix zaten % olarak (0.6 = %0.6)
	mana_leech_percent = flat.get("mana_leech", 0.0)  # affix zaten % olarak
	life_gain_on_hit = flat.get("life_gain_on_hit", 0.0)
	life_on_kill = flat.get("life_on_kill", 0.0)
	mana_on_kill = flat.get("mana_on_kill", 0.0)
	
	# --- ES Recharge (default: 5 sn gecikme, %33/sn hız) ---
	# Pasif ağacı: "es_recharge_delay_reduction" flat düşüş, "es_recharge_rate" % artış
	es_recharge_delay = maxf(0.5, 5.0 - flat.get("es_recharge_delay_reduction", 0.0))
	es_recharge_rate_percent = 33.0 + increased.get("es_recharge_rate", 0.0)

	# --- Utility ---
	ailment_effect = increased.get("ailment_effect", 0.0)
	ailment_chance = increased.get("ailment_chance", 0.0)
	ailment_duration = increased.get("ailment_duration", 0.0)
	shock_magnitude = increased.get("shock_magnitude", 0.0)
	chill_magnitude = increased.get("chill_magnitude", 0.0)
	ignite_magnitude = increased.get("ignite_magnitude", 0.0)
	bleed_magnitude = increased.get("bleed_magnitude", 0.0)
	ailment_magnitude = increased.get("ailment_magnitude", 0.0)
	# flask_effect kaldırıldı
	cooldown_recovery = increased.get("cooldown_recovery", 0.0)
	
	# Passive tree bonuses
	melee_range_bonus = flat.get("melee_range", 0.0)
	armour_elemental_pct = flat.get("armour_elemental_pct", 0.0)
	
	# --- New mechanic stats ---
	penetration_fire = flat.get("penetration_fire", 0.0)
	penetration_cold = flat.get("penetration_cold", 0.0)
	penetration_lightning = flat.get("penetration_lightning", 0.0)
	penetration_elemental = flat.get("penetration_elemental", 0.0)
	penetration_chaos = flat.get("penetration_chaos", 0.0)
	exposure_effect = increased.get("exposure_effect", 0.0)
	culling_threshold = flat.get("culling_threshold", 0.0)
	life_recoup_pct = flat.get("life_recoup", 0.0)
	mana_recoup_pct = flat.get("mana_recoup", 0.0)
	recoup_speed = increased.get("recoup_speed", 0.0)
	armour_break_pct = increased.get("armour_break", 0.0)
	armour_break_duration = increased.get("armour_break_duration", 0.0)
	armour_break_effect = increased.get("armour_break_effect", 0.0)
	fully_broken_fire_dmg_taken = flat.get("fully_broken_fire_dmg_taken", 0.0) > 0.0
	fully_broken_cold_lightning_taken = flat.get("fully_broken_cold_lightning_taken", 0.0) > 0.0
	fully_broken_no_regen = flat.get("fully_broken_no_regen", 0.0) > 0.0
	withered_magnitude = increased.get("withered_magnitude", 0.0)
	withered_chance = flat.get("withered_chance", 0.0)
	withered_duration = increased.get("withered_duration", 0.0)
	withered_damage_reduction = flat.get("withered_damage_reduction", 0.0)
	surrounded_attack_damage = increased.get("surrounded_attack_damage", 0.0)
	surrounded_attack_speed = increased.get("surrounded_attack_speed", 0.0)
	surrounded_movement_speed = increased.get("surrounded_movement_speed", 0.0)
	surrounded_armour = increased.get("surrounded_armour", 0.0)
	surrounded_evasion = increased.get("surrounded_evasion", 0.0)
	surrounded_accuracy = increased.get("surrounded_accuracy", 0.0)
	surrounded_life_regen = increased.get("surrounded_life_regen", 0.0)
	surrounded_all_damage = increased.get("surrounded_all_damage", 0.0)
	daze_chance = flat.get("daze_chance", 0.0)
	daze_duration = increased.get("daze_duration", 0.0)
	damage_vs_dazed = increased.get("damage_vs_dazed", 0.0)
	damage_vs_blinded = increased.get("damage_vs_blinded", 0.0)
	damage_vs_low_life = increased.get("damage_vs_low_life", 0.0)
	damage_vs_full_life = increased.get("damage_vs_full_life", 0.0)
	damage_vs_frozen = increased.get("damage_vs_frozen", 0.0)
	damage_vs_burning = increased.get("damage_vs_burning", 0.0)
	damage_vs_ignited = increased.get("damage_vs_ignited", 0.0)
	damage_vs_shocked = increased.get("damage_vs_shocked", 0.0)
	damage_vs_chilled = increased.get("damage_vs_chilled", 0.0)
	damage_vs_rare_unique = increased.get("damage_vs_rare_unique", 0.0)
	damage_vs_immobilised = increased.get("damage_vs_immobilised", 0.0)
	damage_vs_ailments = increased.get("damage_vs_ailments", 0.0)
	damage_if_crit_recently = increased.get("damage_if_crit_recently", 0.0)
	blind_chance = flat.get("blind_chance", 0.0)
	blind_effect = increased.get("blind_effect", 0.0)
	freeze_buildup = increased.get("freeze_buildup", 0.0)
	electrocute_buildup = increased.get("electrocute_buildup", 0.0)
	thorns_flat = flat.get("thorns", 0.0)
	thorns_pct = flat.get("thorns_pct", 0.0)
	aura_magnitude = increased.get("aura_magnitude", 0.0)
	ailment_speed = increased.get("ailment_speed", 0.0)
	ignite_speed = increased.get("ignite_speed", 0.0)
	bleed_speed = increased.get("bleed_speed", 0.0)
	poison_duration = increased.get("poison_duration", 0.0)
	bleeding_duration = increased.get("bleeding_duration", 0.0)
	freeze_duration_on_enemies = increased.get("freeze_duration_on_enemies", 0.0)
	chill_duration = increased.get("chill_duration", 0.0)
	ailment_threshold = increased.get("ailment_threshold", 0.0)
	ailment_duration_on_you = increased.get("ailment_duration_on_you", 0.0)
	skill_effect_duration = increased.get("skill_effect_duration", 0.0)
	area_of_effect = increased.get("area_of_effect", 0.0)
	mana_cost_efficiency = increased.get("mana_cost_efficiency", 0.0)
	reservation_efficiency = increased.get("reservation_efficiency", 0.0)
	mana_cost_pct = increased.get("mana_cost_pct", 0.0)
	life_cost_pct = increased.get("life_cost_pct", 0.0)
	life_cost_conversion_pct = flat.get("life_cost_conversion", 0.0)
	slow_potency_reduction = flat.get("slow_potency_reduction", 0.0)
	debuff_expiry_speed = increased.get("debuff_expiry_speed", 0.0)
	buff_expiry_speed = increased.get("buff_expiry_speed", 0.0)
	slow_magnitude = increased.get("slow_magnitude", 0.0)
	buff_effect_self = increased.get("buff_effect_self", 0.0)
	leech_amount = increased.get("leech_amount", 0.0)
	leech_speed = increased.get("leech_speed", 0.0)
	damage_while_leeching = increased.get("damage_while_leeching", 0.0)
	attack_speed_while_leeching = increased.get("attack_speed_while_leeching", 0.0)
	armour_evasion_while_leeching = increased.get("armour_evasion_while_leeching", 0.0)
	block_recovery = increased.get("block_recovery", 0.0)
	# --- Extra Damage as X ---
	extra_damage_all = {}
	extra_damage_physical = {}
	extra_damage_elemental = {}
	extra_damage_cold = {}
	extra_damage_fire = {}
	extra_damage_lightning = {}
	extra_damage_chaos = {}
	extra_damage_conditional = {}
	var extra_keys: Array[String] = ["fire", "cold", "lightning", "chaos", "physical"]
	for ek in extra_keys:
		var v_all: float = flat.get("extra_all_" + ek, 0.0)
		if v_all != 0.0:
			extra_damage_all[ek] = v_all
		var v_phys: float = flat.get("extra_physical_" + ek, 0.0)
		if v_phys != 0.0:
			extra_damage_physical[ek] = v_phys
		var v_elem: float = flat.get("extra_elemental_" + ek, 0.0)
		if v_elem != 0.0:
			extra_damage_elemental[ek] = v_elem
		var v_cold: float = flat.get("extra_cold_" + ek, 0.0)
		if v_cold != 0.0:
			extra_damage_cold[ek] = v_cold
		var v_fire: float = flat.get("extra_fire_" + ek, 0.0)
		if v_fire != 0.0:
			extra_damage_fire[ek] = v_fire
		var v_lightning: float = flat.get("extra_lightning_" + ek, 0.0)
		if v_lightning != 0.0:
			extra_damage_lightning[ek] = v_lightning
		var v_chaos: float = flat.get("extra_chaos_" + ek, 0.0)
		if v_chaos != 0.0:
			extra_damage_chaos[ek] = v_chaos
	# Parse conditional extra damage keys: "extra_<source>_<target>_<condition>"
	# Unconditional keys like "extra_cold_fire" have 2 parts, conditionals have 3+
	for k: String in flat:
		if not k.begins_with("extra_"):
			continue
		var prefix_removed: String = k.trim_prefix("extra_")
		# Count underscores in the remaining part
		var underscore_count: int = 0
		for __ch in prefix_removed:
			if __ch == "_":
				underscore_count += 1
		# 2+ underscores = 3+ segments = has condition (e.g. "cold_fire_frozen" or "physical_fire_heavy_stun")
		if underscore_count >= 2:
			var cv: float = flat.get(k, 0.0)
			if cv != 0.0:
				extra_damage_conditional[prefix_removed] = cv
	splash_damage = flat.get("splash_damage", 0.0) > 0.0
	splash_radius = flat.get("splash_radius", 60.0) * (1.0 + increased.get("area_of_effect", 0.0) / 100.0)
	splash_damage_percent = flat.get("splash_damage_percent", 50.0)
	aggravated_bleeding = flat.get("aggravated_bleeding", 0.0) > 0.0
	aggravate_bleed_chance = flat.get("aggravate_bleed_chance", 0.0)
	maim_chance = flat.get("maim_chance", 0.0)
	damage_vs_maimed = increased.get("damage_vs_maimed", 0.0)
	lucky_hits = flat.get("lucky_hits", 0.0)
	unlucky_hits = flat.get("enemy_unlucky", 0.0)
	
	item_rarity = increased.get("item_rarity", 0.0)
	item_quantity = increased.get("item_quantity", 0.0)

	stats_changed.emit()

func _collect_affixes(percentage: bool) -> Dictionary:
	var result := {}
	if not _equipment:
		return result
	for item in _equipment.get_equipped_items():
		# Base item stats (only on non-percentage collection)
		if not percentage:
			if item.base_physical_damage_min > 0 or item.base_physical_damage_max > 0:
				var avg_phys: float = (item.base_physical_damage_min + item.base_physical_damage_max) / 2.0
				result["physical_damage"] = result.get("physical_damage", 0.0) + avg_phys
			var qmf: float = item.get_quality_multiplier()
			if item.base_armour > 0:
				result["armour"] = result.get("armour", 0.0) + item.base_armour * qmf
			if item.base_evasion > 0:
				result["evasion"] = result.get("evasion", 0.0) + item.base_evasion * qmf
			if item.base_energy_shield > 0:
				result["max_energy_shield"] = result.get("max_energy_shield", 0.0) + item.base_energy_shield * qmf
			if item.base_block_chance > 0:
				result["attack_block_chance"] = result.get("attack_block_chance", 0.0) + item.base_block_chance
			if item.base_attack_speed > 0:
				result["attack_speed"] = result.get("attack_speed", 0.0) + item.base_attack_speed
			if item.base_cast_speed > 0:
				result["cast_speed"] = result.get("cast_speed", 0.0) + item.base_cast_speed
			# base_elemental_damage _calc_single_weapon_range()'de sadece staff/wand'a eklenir
		# Affix'ler
		for affix in item.affixes:
			if affix.is_percentage == percentage:
				var key := affix.stat_name
				# ItemGenerator "_percent" sonekli üretiyor ama recalculate
				# soneksiz key'leri okuyor -> düzelt
				if key.ends_with("_percent"):
					key = key.trim_suffix("_percent")
				# Eski "attack_dodge_chance" affix'leri artık evasion'a eklenir
				if key == "attack_dodge_chance":
					key = "evasion"
				result[key] = result.get(key, 0.0) + affix.value
	return result

## Belirli bir düşman isabet değerine karşı kaçınma şansını hesaplar.
## PoE benzeri formül: kaçınma_şansı = evasion / (evasion + (düşman_isabeti)^0.8)
## Yüksek zone tier → düşman isabeti artar → kaçınma daha az etkili olur → daha çok evasion kasman gerekir.
func get_dodge_chance_vs(monster_accuracy: float) -> float:
	if evasion <= 0.0 or monster_accuracy <= 0.0:
		return 0.0
	var chance: float = evasion / (evasion + pow(monster_accuracy, 0.8))
	return clampf(chance, 0.0, 0.75)  # %75 üst sınır

## Varsayılan düşmana karşı kaçınma şansı (GameUI'da gösterim için).
## Varsayılan düşman isabeti: 50 + zone_tier * 15, varsayılan zone_tier = 1
func get_effective_dodge_chance() -> float:
	return get_dodge_chance_vs(65.0)  # zone 1 için: 50 + 1*15 = 65

func get_incoming_damage_multiplier(damage_type: String, penetration: float = 0.0) -> float:
	var res: float = 0.0
	match damage_type.to_lower():
		"fire": res = fire_resistance
		"cold": res = cold_resistance
		"lightning": res = lightning_resistance
		"chaos": res = chaos_resistance
		_: res = 0.0
	# Penetration reduces effective resistance (can go below 0%)
	if penetration > 0.0:
		res -= penetration
	return 1.0 - (res / 100.0)
