extends Node
class_name CombatEngine
## Central combat calculator that handles all damage, crit, accuracy,
## armor, evasion, block, and ailment application.

signal damage_number_spawned(text: String, position: Vector2, color: Color, is_crit: bool)
## Rolls an attack hit check. Returns HitResult with calculated damage.
## defender_node: optional, used for damage_vs_maimed / fully_broken / withered
## attacker_node: optional, used for surrounded check
static func calculate_hit(
	attacker_stats: CharacterStats,
	defender_stats: CharacterStats,
	base_damage: float,
	damage_type: String,
	skill_tags: Array[String],
	is_spell: bool = false,
	defender_node: Node = null,
	attacker_node: Node = null
) -> Dictionary:
	# Normalize damage_type (büyük/küçük harf koruması)
	var dmg_type_lower: String = damage_type.to_lower()

	# --- Accuracy vs Evasion (only for attacks, not spells) ---
	if not is_spell and defender_stats:
		var hit_chance: float = _calculate_hit_chance(attacker_stats, defender_stats)
		if randf() > hit_chance:
			return {"hit": false, "damage": 0.0, "is_crit": false, "is_evaded": true, "ailment_power": 0.0}

	# --- Calculate damage ---
	var final_damage: float = base_damage

	# Apply character stat modifiers
	if attacker_stats:
		match dmg_type_lower:
			"physical":
				final_damage += attacker_stats.physical_damage_flat
				final_damage *= (1.0 + attacker_stats.physical_damage_increased / 100.0)
			"fire":
				final_damage *= (1.0 + (attacker_stats.elemental_damage_increased + attacker_stats.fire_damage_increased) / 100.0)
			"cold":
				final_damage *= (1.0 + (attacker_stats.elemental_damage_increased + attacker_stats.cold_damage_increased) / 100.0)
			"lightning":
				final_damage *= (1.0 + (attacker_stats.elemental_damage_increased + attacker_stats.lightning_damage_increased) / 100.0)
			"chaos":
				final_damage *= (1.0 + attacker_stats.chaos_damage_increased / 100.0)

	# Generic all-damage multiplier (from passive tree "X% increased Damage")
	if attacker_stats and attacker_stats.all_damage_increased != 0.0:
		final_damage *= (1.0 + attacker_stats.all_damage_increased / 100.0)


	# Projectile / Area damage (tag bazlı)
	if attacker_stats:
		if "projectile" in skill_tags:
			final_damage *= (1.0 + attacker_stats.projectile_damage_increased / 100.0)
		elif "aoe" in skill_tags or "area" in skill_tags:
			final_damage *= (1.0 + attacker_stats.area_damage_increased / 100.0)


	# NOTE: Attack/cast speed affects DPS (more hits per second) but NOT per-hit damage.
	# This matches PoE design where speed and damage are separate multipliers.
	# --- Damage Conversion (PoE-style chains) ---
	# Tam dönüşüm: Hasara etki eden skill tag'leri varsa damage_type güncellenir
	# Not: Full dönüşüm sistemi henüz implemente edilmedi;
	# 50% kesinti kaldırıldı çünkü dönüşen yarı hasar eklenmiyordu.

	# --- Critical Strike ---
	var is_crit: bool = false
	var crit_multi: float = 1.5
	if attacker_stats:
		var crit_chance: float = attacker_stats.critical_chance / 100.0
		# spell_critical_chance kaldirildi — tek kritik sansi
		crit_multi = attacker_stats.critical_multiplier / 100.0

		if crit_chance > 0.0:
			is_crit = randf() < crit_chance  # Normal tek roll — Lucky/Unlucky hasar roll'unu etkiler, kirit degil

		if is_crit:
			final_damage *= crit_multi
			# Track crit time for "damage if crit recently" passive
			if attacker_stats:
				attacker_stats.last_crit_time = Time.get_ticks_msec()

	# --- Armour Damage Reduction ---
	# Fully Broken Armour kontrolu: armour = 0, fiziksel hasar bypass
	var _is_fully_broken: bool = false
	if defender_node:
		var fb_ac: AilmentController = defender_node.get_node_or_null("AilmentController") as AilmentController
		if fb_ac and fb_ac.has_effect(StatusEffect.Type.FULLY_BROKEN):
			_is_fully_broken = true

	if defender_stats:
		if damage_type == "physical":
			var armour_val: float = 0.0 if _is_fully_broken else defender_stats.armour
			final_damage = _apply_armour(final_damage, armour_val)
		elif damage_type in ["fire", "cold", "lightning"] and defender_stats.armour_elemental_pct > 0.0:
			var effective_armour: float = defender_stats.armour * (defender_stats.armour_elemental_pct / 100.0)
			final_damage = _apply_armour(final_damage, effective_armour)

	# --- Armour Break Accumulation ---
	if not _is_fully_broken and defender_node and defender_stats \
		and damage_type == "physical" and not is_spell:
		var break_ac: AilmentController = defender_node.get_node_or_null("AilmentController") as AilmentController
		if break_ac:
			var break_pct: float = 0.05
			if attacker_stats:
				break_pct *= (1.0 + attacker_stats.armour_break_pct / 100.0)
			var break_amount: float = final_damage * break_pct
			var break_duration: float = 4.0
			if attacker_stats and attacker_stats.armour_break_duration > 0.0:
				break_duration *= (1.0 + attacker_stats.armour_break_duration / 100.0)
			break_ac.add_armour_break(break_amount, defender_stats.armour, break_duration)

	# --- Extra Damage as X (Gain X% as Extra Y) ---
	if attacker_stats:
		var extra_total: float = 0.0
		var _pct: float = 0.0
		var _extra: float = 0.0

		for _elem in attacker_stats.extra_damage_all:
			_pct = attacker_stats.extra_damage_all[_elem] / 100.0
			_extra = final_damage * _pct
			_extra *= (1.0 + _get_element_increased(attacker_stats, _elem) / 100.0)
			extra_total += _extra

		if dmg_type_lower == "physical":
			for _elem in attacker_stats.extra_damage_physical:
				_pct = attacker_stats.extra_damage_physical[_elem] / 100.0
				_extra = final_damage * _pct
				_extra *= (1.0 + _get_element_increased(attacker_stats, _elem) / 100.0)
				extra_total += _extra

		if dmg_type_lower in ["fire", "cold", "lightning"]:
			for _elem in attacker_stats.extra_damage_elemental:
				_pct = attacker_stats.extra_damage_elemental[_elem] / 100.0
				_extra = final_damage * _pct
				_extra *= (1.0 + _get_element_increased(attacker_stats, _elem) / 100.0)
				extra_total += _extra

		if dmg_type_lower == "cold":
			for _elem in attacker_stats.extra_damage_cold:
				_pct = attacker_stats.extra_damage_cold[_elem] / 100.0
				_extra = final_damage * _pct
				_extra *= (1.0 + _get_element_increased(attacker_stats, _elem) / 100.0)
				extra_total += _extra

		if dmg_type_lower == "fire":
			for _elem in attacker_stats.extra_damage_fire:
				_pct = attacker_stats.extra_damage_fire[_elem] / 100.0
				_extra = final_damage * _pct
				_extra *= (1.0 + _get_element_increased(attacker_stats, _elem) / 100.0)
				extra_total += _extra

		if dmg_type_lower == "lightning":
			for _elem in attacker_stats.extra_damage_lightning:
				_pct = attacker_stats.extra_damage_lightning[_elem] / 100.0
				_extra = final_damage * _pct
				_extra *= (1.0 + _get_element_increased(attacker_stats, _elem) / 100.0)
				extra_total += _extra

		if dmg_type_lower == "chaos":
			for _elem in attacker_stats.extra_damage_chaos:
				_pct = attacker_stats.extra_damage_chaos[_elem] / 100.0
				_extra = final_damage * _pct
				_extra *= (1.0 + _get_element_increased(attacker_stats, _elem) / 100.0)
				extra_total += _extra

		# --- Conditional extra damage ---
		if not attacker_stats.extra_damage_conditional.is_empty() and defender_node:
			var ac: AilmentController = defender_node.get_node_or_null("AilmentController")
			for cond_key: String in attacker_stats.extra_damage_conditional:
				var cond_pct: float = attacker_stats.extra_damage_conditional[cond_key] / 100.0
				var parts: PackedStringArray = cond_key.split("_")
				if parts.size() < 3:
					continue
				var cond_source: String = parts[0]
				var cond_target: String = parts[1]
				var cond_cond: String = ""
				for pi in range(2, parts.size()):
					if pi > 2: cond_cond += "_"
					cond_cond += parts[pi]

				var source_matches: bool = false
				match cond_source:
					"all": source_matches = true
					"physical": source_matches = (dmg_type_lower == "physical")
					"elemental": source_matches = (dmg_type_lower in ["fire", "cold", "lightning"])
					"cold": source_matches = (dmg_type_lower == "cold")
					"fire": source_matches = (dmg_type_lower == "fire")
					"lightning": source_matches = (dmg_type_lower == "lightning")
					"chaos": source_matches = (dmg_type_lower == "chaos")
				if not source_matches:
					continue

				var condition_met: bool = false
				match cond_cond:
					"frozen": condition_met = ac and ac.has_effect(StatusEffect.Type.FREEZE)
					"ignited": condition_met = ac and ac.has_effect(StatusEffect.Type.IGNITE)
					"shocked": condition_met = ac and ac.has_effect(StatusEffect.Type.SHOCK)
					"chilled": condition_met = ac and ac.has_effect(StatusEffect.Type.CHILL)
					"electrocuted": condition_met = ac and ac.has_effect(StatusEffect.Type.ELECTROCUTE)
					"shocked_ground": condition_met = true
					"ignited_ground": condition_met = true
					"chilled_ground": condition_met = true
				if not condition_met:
					continue

				_extra = final_damage * cond_pct
				_extra *= (1.0 + _get_element_increased(attacker_stats, cond_target) / 100.0)
				extra_total += _extra


		if extra_total > 0.0:
			final_damage += extra_total

	# --- Condition Damage (pasif ağacından gelen "damage vs X" bonusları) ---
	if attacker_stats and defender_node:
		var ac: AilmentController = defender_node.get_node_or_null("AilmentController")
		var health_node: Health = defender_node.get_node_or_null("Health")

		# Damage vs Maimed
		if attacker_stats.damage_vs_maimed > 0.0 and ac and ac.has_effect(StatusEffect.Type.MAIM):
			final_damage *= (1.0 + attacker_stats.damage_vs_maimed / 100.0)

		# Damage vs Blinded
		if attacker_stats.damage_vs_blinded > 0.0 and ac and ac.has_effect(StatusEffect.Type.BLIND):
			final_damage *= (1.0 + attacker_stats.damage_vs_blinded / 100.0)

		# Damage vs Frozen
		if attacker_stats.damage_vs_frozen > 0.0 and ac and ac.has_effect(StatusEffect.Type.FREEZE):
			final_damage *= (1.0 + attacker_stats.damage_vs_frozen / 100.0)

		# Damage vs Burning / Ignited (IGNITE = burning)
		if attacker_stats.damage_vs_burning > 0.0 and ac and ac.has_effect(StatusEffect.Type.IGNITE):
			final_damage *= (1.0 + attacker_stats.damage_vs_burning / 100.0)
		if attacker_stats.damage_vs_ignited > 0.0 and ac and ac.has_effect(StatusEffect.Type.IGNITE):
			final_damage *= (1.0 + attacker_stats.damage_vs_ignited / 100.0)

		# Damage vs Shocked
		if attacker_stats.damage_vs_shocked > 0.0 and ac and ac.has_effect(StatusEffect.Type.SHOCK):
			final_damage *= (1.0 + attacker_stats.damage_vs_shocked / 100.0)

		# Damage vs Chilled
		if attacker_stats.damage_vs_chilled > 0.0 and ac and ac.has_effect(StatusEffect.Type.CHILL):
			final_damage *= (1.0 + attacker_stats.damage_vs_chilled / 100.0)

		# Damage vs Immobilised (FREEZE veya CRUSHED)
		if attacker_stats.damage_vs_immobilised > 0.0 and ac:
			if ac.has_effect(StatusEffect.Type.FREEZE) or ac.has_effect(StatusEffect.Type.CRUSHED):
				final_damage *= (1.0 + attacker_stats.damage_vs_immobilised / 100.0)

		# Damage vs Ailments (affected by any elemental ailment)
		if attacker_stats.damage_vs_ailments > 0.0 and ac:
			if ac.has_effect(StatusEffect.Type.IGNITE) or ac.has_effect(StatusEffect.Type.SHOCK) \
				or ac.has_effect(StatusEffect.Type.CHILL) or ac.has_effect(StatusEffect.Type.FREEZE) \
				or ac.has_effect(StatusEffect.Type.POISON) or ac.has_effect(StatusEffect.Type.BLEED):
				final_damage *= (1.0 + attacker_stats.damage_vs_ailments / 100.0)

		# Damage vs Low Life (health < 35%)
		if attacker_stats.damage_vs_low_life > 0.0 and health_node and health_node.max_health > 0:
			var hp_pct: float = health_node.current_health / health_node.max_health
			if hp_pct <= 0.35:
				final_damage *= (1.0 + attacker_stats.damage_vs_low_life / 100.0)

		# Damage vs Full Life (health >= 99.9%)
		if attacker_stats.damage_vs_full_life > 0.0 and health_node and health_node.max_health > 0:
			var hp_pct: float = health_node.current_health / health_node.max_health
			if hp_pct >= 0.999:
				final_damage *= (1.0 + attacker_stats.damage_vs_full_life / 100.0)

		# Damage vs Rare/Unique (enemy rarity check)
		if attacker_stats.damage_vs_rare_unique > 0.0:
			if defender_node is Enemy and (defender_node.rarity == Enemy.EnemyRarity.RARE or defender_node.rarity == Enemy.EnemyRarity.UNIQUE):
				final_damage *= (1.0 + attacker_stats.damage_vs_rare_unique / 100.0)

		# Damage if Crit Recently (attacker last crit within 4 seconds)
		if attacker_stats.damage_if_crit_recently > 0.0:
			var elapsed: float = Time.get_ticks_msec() - attacker_stats.last_crit_time
			if elapsed < 4000.0:
				final_damage *= (1.0 + attacker_stats.damage_if_crit_recently / 100.0)

	# --- Damage while Leeching ---
	if _is_leeching(attacker_node) and attacker_stats and attacker_stats.damage_while_leeching > 0.0:
		final_damage *= (1.0 + attacker_stats.damage_while_leeching / 100.0)

	# --- Fully Broken Armour bonus damage ---
	if _is_fully_broken and attacker_stats and defender_node:
		# armour_break_effect: pasif ağacından gelen % increased damage when Fully Broken
		var break_eff_mult: float = 1.0 + attacker_stats.armour_break_effect / 100.0
		# "Fully Broken enemies take increased Fire Damage"
		if attacker_stats.fully_broken_fire_dmg_taken and dmg_type_lower == "fire":
			final_damage *= 1.10 * break_eff_mult  # 10% more fire damage
		# "Fully Broken enemies take increased Cold and Lightning Damage"
		if attacker_stats.fully_broken_cold_lightning_taken and dmg_type_lower in ["cold", "lightning"]:
			final_damage *= 1.10 * break_eff_mult  # 10% more cold/lightning damage

	# --- Withered: increased chaos damage taken from Wither stacks ---
	if defender_node and dmg_type_lower == "chaos":
		var wither_ac: AilmentController = defender_node.get_node_or_null("AilmentController") as AilmentController
		if wither_ac:
			var mods: Dictionary = wither_ac.get_combined_modifiers()
			var chaos_taken_bonus: float = mods.get("chaos_damage_taken", 0.0)
			if chaos_taken_bonus > 0.0:
				final_damage *= (1.0 + chaos_taken_bonus)

	# --- Surrounded bonus: increased damage when surrounded by enemies ---
	if attacker_stats and attacker_node:
		var surrounded_dmg_pct: float = attacker_stats.surrounded_attack_damage + attacker_stats.surrounded_all_damage
		if surrounded_dmg_pct > 0.0 and _is_surrounded(attacker_node, 200.0, 3):
			final_damage *= (1.0 + surrounded_dmg_pct / 100.0)

	# --- Damage Roll (simulates weapon damage range for Lucky/Unlucky) ---
	# Lucky: iki hasar hesapla, yüksek olani seç. Unlucky: iki hasar hesapla, düşük olani seç.
	# İkisi birden aktifse birbirini iptal eder (normal tek roll).
	var is_lucky: bool = attacker_stats and attacker_stats.lucky_hits > 0.0
	var is_unlucky: bool = defender_stats and defender_stats.unlucky_hits > 0.0
	if is_lucky and not is_unlucky:
		var variance: float = _get_damage_variance(attacker_stats)
		var roll1: float = final_damage * (1.0 - variance + randf() * 2.0 * variance)
		var roll2: float = final_damage * (1.0 - variance + randf() * 2.0 * variance)
		final_damage = maxf(roll1, roll2)
	elif is_unlucky and not is_lucky:
		var variance: float = _get_damage_variance(attacker_stats)
		var roll1: float = final_damage * (1.0 - variance + randf() * 2.0 * variance)
		var roll2: float = final_damage * (1.0 - variance + randf() * 2.0 * variance)
		final_damage = minf(roll1, roll2)

	# --- Flat Added Elemental Damage ("adds X fire damage" affix'lerinden) ---
	# Bunlar silah/skills'ten bağımsız olarak her vuruşa eklenen flat hasarlardır.
	# Kendi element tiplerine göre increased multiplier + resistance uygulanır.
	if attacker_stats:
		var _fire_flat: float = attacker_stats.fire_damage_flat if "fire_damage_flat" in attacker_stats else 0.0
		var _cold_flat: float = attacker_stats.cold_damage_flat if "cold_damage_flat" in attacker_stats else 0.0
		var _light_flat: float = attacker_stats.lightning_damage_flat if "lightning_damage_flat" in attacker_stats else 0.0
		var _chaos_flat: float = attacker_stats.chaos_damage_flat if "chaos_damage_flat" in attacker_stats else 0.0
		var _ele_pairs: Array[Dictionary] = [
			{"key":"fire","val":_fire_flat,"inc_elem":"elemental_damage_increased","inc_type":"fire_damage_increased"},
			{"key":"cold","val":_cold_flat,"inc_elem":"elemental_damage_increased","inc_type":"cold_damage_increased"},
			{"key":"lightning","val":_light_flat,"inc_elem":"elemental_damage_increased","inc_type":"lightning_damage_increased"},
			{"key":"chaos","val":_chaos_flat,"inc_elem":"","inc_type":"chaos_damage_increased"}
		]
		for ep in _ele_pairs:
			var flat_val: float = ep.val
			if flat_val <= 0.0:
				continue
			var ele_dmg: float = flat_val
			# Type-specific increased
			var inc_total: float = attacker_stats.all_damage_increased
			if ep.inc_elem != "":
				inc_total += attacker_stats.get(ep.inc_elem)
			inc_total += attacker_stats.get(ep.inc_type)
			if inc_total != 0.0:
				ele_dmg *= (1.0 + inc_total / 100.0)
			# Skill tag modifiers
			if "projectile" in skill_tags:
				ele_dmg *= (1.0 + attacker_stats.projectile_damage_increased / 100.0)
			elif "aoe" in skill_tags or "area" in skill_tags:
				ele_dmg *= (1.0 + attacker_stats.area_damage_increased / 100.0)
			# Attack/cast speed
			if is_spell:
				ele_dmg *= (0.7 + 0.3 * attacker_stats.cast_speed)
			elif "attack" in skill_tags:
				ele_dmg *= (0.7 + 0.3 * attacker_stats.attack_speed)
			# Enemy resistance
			if defender_stats:
				ele_dmg *= defender_stats.get_incoming_damage_multiplier(ep.key)
			ele_dmg = maxf(0.0, ele_dmg - 0.0)
			final_damage += ele_dmg

	# Round to 1 decimal for display
	final_damage = snappedf(final_damage, 0.1)

	# --- Calculate ailment power for threshold-based ailments ---
	var ailment_power: float = final_damage * 0.5  ## 50% of hit damage as ailment base
	# damage_over_time_increased ve ailment_effect ailment gücünü artırır
	if attacker_stats:
		ailment_power *= (1.0 + (attacker_stats.damage_over_time_increased + attacker_stats.ailment_effect) / 100.0)

	# --- Penetration: reduces enemy resistance ---
	var penetration: float = 0.0
	if attacker_stats:
		match dmg_type_lower:
			"fire": penetration = attacker_stats.penetration_fire
			"cold": penetration = attacker_stats.penetration_cold
			"lightning": penetration = attacker_stats.penetration_lightning
			"chaos": penetration = attacker_stats.penetration_chaos
		# Elemental penetration applies to fire/cold/lightning
		if dmg_type_lower in ["fire", "cold", "lightning"] and attacker_stats.penetration_elemental > penetration:
			penetration = attacker_stats.penetration_elemental

	return {
		"hit": true,
		"damage": final_damage,
		"is_crit": is_crit,
		"is_evaded": false,
		"crit_multiplier": crit_multi if is_crit else 1.0,
		"ailment_power": ailment_power,
		"damage_type": damage_type,
		"penetration": penetration,
	}

## Calculate chance to hit based on accuracy vs evasion
static func _calculate_hit_chance(attacker: CharacterStats, defender: CharacterStats) -> float:
	var accuracy: float = attacker.accuracy
	if defender == null:
		return 1.0
	var evasion: float = defender.evasion

	if evasion <= 0.0:
		return 1.0

	# PoE-style formula: chance to hit = accuracy / (accuracy + (evasion/4)^0.8)
	var chance: float = accuracy / (accuracy + pow(evasion / 4.0, 0.8))
	return clampf(chance, 0.05, 0.95)  ## 5% min, 95% max

## Apply armour-based physical damage reduction (PoE formula)
static func _apply_armour(damage: float, armour: float) -> float:
	if armour <= 0.0 or damage <= 0.0:
		return damage
	# PoE armour formula: reduction = armour / (armour + damage * 10)
	# This means big hits are reduced less (percentage-wise)
	var reduction: float = armour / (armour + damage * 10.0)
	reduction = clampf(reduction, 0.0, 0.9)  ## 90% cap
	return damage * (1.0 - reduction)

## Calculate shock effect magnitude (threshold: damage as % of max life)
static func calculate_shock_magnitude(_hit_damage: float, ailment_power: float, target_max_life: float) -> float:
	if target_max_life <= 0.0:
		return 0.0
	var percent_of_life: float = ailment_power / target_max_life
	# Shock: 0-50% increased damage taken, requires 0-10% of max life
	var shock_mag: float = clampf(percent_of_life * 5.0, 0.0, 0.5)
	# Minimum shock threshold: 0.32% of max life for 5% shock
	if shock_mag < 0.05:
		return 0.0
	return shock_mag

## Calculate chill effect magnitude
static func calculate_chill_magnitude(_hit_damage: float, ailment_power: float, target_max_life: float) -> float:
	if target_max_life <= 0.0:
		return 0.0
	var percent_of_life: float = ailment_power / target_max_life
	# Chill: 0-30% reduced action speed
	var chill_mag: float = clampf(percent_of_life * 3.0, 0.0, 0.3)
	if chill_mag < 0.05:
		return 0.0
	return chill_mag

## Calculate freeze duration (based on % of max life)
static func calculate_freeze_duration(_hit_damage: float, ailment_power: float, target_max_life: float) -> float:
	if target_max_life <= 0.0:
		return 0.0
	var threshold: float = ailment_power / target_max_life
	if threshold < 0.05:  ## need at least 5% of max life
		return 0.0
	# Base 0.06s per 1% threshold, capped at 50% threshold for 3s
	return clampf(threshold * 6.0, 0.0, 3.0)

## Calculate ignite damage per second
static func calculate_ignite_dps(_base_fire_damage: float, ailment_power: float) -> float:
	# Ignite deals 90% of hit's fire damage per second for 4 seconds
	return ailment_power * 0.9 / 4.0

## Calculate poison damage per second (chaos)
static func calculate_poison_dps(_base_damage: float, ailment_power: float) -> float:
	# Poison deals 30% of combined phys+chaos per second for 2 seconds
	return ailment_power * 0.3 / 2.0

## Calculate bleed damage per second (physical, requires moving)
static func calculate_bleed_dps(_base_phys_damage: float, ailment_power: float) -> float:
	# Bleed deals 70% of physical hit per second while moving, for 5 seconds
	return ailment_power * 0.7 / 5.0

## Calculate energy shield recharge start delay and rate
## Değerler artık CharacterStats.es_recharge_delay ve es_recharge_rate_percent'ten gelir.
static func get_es_recharge_delay(stats: CharacterStats) -> float:
	return stats.es_recharge_delay

static func get_es_recharge_rate(stats: CharacterStats) -> float:
	var rate: float = stats.max_energy_shield * (stats.es_recharge_rate_percent / 100.0)
	return rate

## Calculate life/mana leech instances
## attacker_stats: optional, provides leech_amount (cap boost) and leech_speed (duration reduction)
static func calculate_leech(damage_dealt: float, leech_percent: float, max_pool: float, attacker_stats: CharacterStats = null) -> Dictionary:
	var leech_amount: float = damage_dealt * leech_percent
	## Base: 2% of max pool per second. leech_amount pasifi: cap artışı
	var cap_mult: float = 1.0
	if attacker_stats and attacker_stats.leech_amount > 0.0:
		cap_mult = 1.0 + attacker_stats.leech_amount / 100.0
	var max_per_leech: float = max_pool * 0.02 * cap_mult
	## Base: 5 seconds. leech_speed pasifi: daha hızlı leech (süre kısalır)
	var base_duration: float = 5.0
	if attacker_stats and attacker_stats.leech_speed > 0.0:
		base_duration = 5.0 / (1.0 + attacker_stats.leech_speed / 100.0)
	var rate: float = minf(leech_amount / base_duration, max_per_leech)
	return {
		"total": leech_amount,
		"rate": rate,
		"duration": base_duration,
		"remaining": leech_amount,
	}

## Roll for block (attack block or spell block)
static func roll_block(block_chance: float) -> bool:
	return randf() < clampf(block_chance, 0.0, 0.75)  ## 75% cap

## Roll for dodge (separate from evasion — pure % chance)
static func roll_dodge(dodge_chance: float) -> bool:
	return randf() < clampf(dodge_chance, 0.0, 0.75)

## Get elemental-type-specific increased damage from CharacterStats
## Used by Extra Damage as X calculation in calculate_hit()
static func _get_element_increased(stats: CharacterStats, elem: String) -> float:
	match elem:
		"fire":
			return stats.fire_damage_increased + stats.elemental_damage_increased
		"cold":
			return stats.cold_damage_increased + stats.elemental_damage_increased
		"lightning":
			return stats.lightning_damage_increased + stats.elemental_damage_increased
		"chaos":
			return stats.chaos_damage_increased
		"physical":
			return stats.physical_damage_increased
	return 0.0

## Get damage variance (simulates weapon damage range)
## Default ±20% range. If attacker has no damage range mod, returns 0.2
static func _get_damage_variance(_stats: CharacterStats) -> float:
	# TODO: Weapon-specific damage range could be added here
	return 0.2  ## ±20% variance

## Check if a node is surrounded by enemies within radius
## Returns true if count_min or more enemies from group "enemy" are nearby
static func _is_surrounded(node: Node, radius: float, count_min: int = 3) -> bool:
	if not node or not node.is_inside_tree():
		return false
	var tree: SceneTree = node.get_tree()
	if not tree:
		return false
	var enemies: Array[Node] = tree.get_nodes_in_group("enemy")
	var pos: Vector2 = node.global_position
	var nearby: int = 0
	for e in enemies:
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_squared_to(pos) <= radius * radius:
			nearby += 1
			if nearby >= count_min:
				return true
	return false

## Check if a node is currently leeching (has active Health leech instances)
static func _is_leeching(node: Node) -> bool:
	if not node or not node.is_inside_tree():
		return false
	var health: Health = node.get_node_or_null("Health") as Health
	if not health:
		return false
	return health.is_leeching()
