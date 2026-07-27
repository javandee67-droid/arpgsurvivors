extends RefCounted
class_name SkillInstance
## PoE2-style runtime skill instance: takes a SkillData + linked SupportData[],
## validates tag compatibility, and calculates final stats using the PoE formula:
##
##   final = (base + Σflat) × (1 + Σincreased/100) × Π(1 + more/100)
##
## Damage supports damage buckets (dictionary-based damage types).
## Non-damage stats (mana_cost, attack_speed, etc.) are calculated as single values.

var skill: SkillData
var active_supports: Array[SupportData] = []

## Creates a new SkillInstance. Incompatible supports are silently filtered out.
func _init(p_skill: SkillData, p_supports: Array[SupportData] = []) -> void:
	skill = p_skill
	for sd in p_supports:
		if sd and sd.is_compatible(skill):
			active_supports.append(sd)

## Returns the list of supports that passed compatibility checks.
func get_active_supports() -> Array[SupportData]:
	return active_supports.duplicate()

## Returns the list of supports that were rejected (for debugging).
func get_rejected_supports(p_supports: Array[SupportData]) -> Array[SupportData]:
	var rejected: Array[SupportData] = []
	for sd in p_supports:
		if sd and not sd.is_compatible(skill):
			rejected.append(sd)
	return rejected

# ======================== DAMAGE (BUCKET-BASED) ========================

## Calculate final damage per damage bucket.
## base_value_provider: Callable(skill: SkillData) -> float
##   Returns the TOTAL base damage value (weapon damage × effectiveness, etc.)
##   This value is distributed across the skill's damage buckets proportionally.
##
## Returns Dictionary: {"physical": 13.0, "fire": 5.0} etc.
func get_final_damage(base_value_provider: Callable) -> Dictionary:
	var base_total: float = base_value_provider.call(skill)
	
	# Get damage distribution from skill's buckets
	var buckets: Dictionary = skill.damage_buckets.duplicate()
	if buckets.is_empty():
		# Fallback: if no buckets, create default from base_damage field
		if skill.base_damage > 0.0:
			# Use damage_type field to determine bucket
			var dmg_type: String = skill.damage_type if skill.damage_type != "" else "physical"
			buckets[dmg_type] = skill.base_damage
		else:
			buckets["physical"] = base_total
	
	# Calculate total bucket weight
	var bucket_total: float = 0.0
	for key in buckets:
		bucket_total += absf(buckets[key])
	
	if bucket_total <= 0.0:
		bucket_total = 1.0
		buckets = {"physical": base_total}
	
	# Calculate final value for each bucket
	var result: Dictionary = {}
	for bucket_type in buckets:
		var base_bucket: float = (absf(buckets[bucket_type]) / bucket_total) * base_total
		result[bucket_type] = _calculate_bucket_final(bucket_type, base_bucket)
	
	return result

## Calculate total damage (sum of all buckets).
func get_total_damage(base_value_provider: Callable) -> float:
	var buckets: Dictionary = get_final_damage(base_value_provider)
	var total: float = 0.0
	for key in buckets:
		total += buckets[key]
	return total

## Calculate a single bucket's final value using the PoE formula.
func _calculate_bucket_final(bucket_type: String, base_value: float) -> float:
	var flat_total: float = 0.0
	var increased_total: float = 0.0
	var more_multipliers: Array[float] = []
	
	for sd in active_supports:
		for mod in sd.modifiers:
			if not _modifier_applies_to_bucket(mod, bucket_type):
				continue
			if mod.stat != "damage":
				continue
			
			match mod.modifier_type:
				StatModifier.ModifierType.FLAT:
					flat_total += mod.value
				StatModifier.ModifierType.INCREASED:
					increased_total += mod.value
				StatModifier.ModifierType.MORE:
					more_multipliers.append(1.0 + mod.value / 100.0)
	
	# PoE formula: (base + flat) × (1 + increased/100) × more₁ × more₂ × ...
	var result: float = (base_value + flat_total) * (1.0 + increased_total / 100.0)
	for m in more_multipliers:
		result *= m
	
	return result

## Check if a modifier applies to a specific damage bucket.
func _modifier_applies_to_bucket(mod: StatModifier, bucket_type: String) -> bool:
	# Check damage_type_filter
	if mod.damage_type_filter != "":
		if mod.damage_type_filter == "elemental":
			# "elemental" = fire + cold + lightning together
			if bucket_type not in ["fire", "cold", "lightning"]:
				return false
		elif mod.damage_type_filter != bucket_type:
			return false
	
	# Check skill_tag_filter
	if mod.skill_tag_filter != "":
		if mod.skill_tag_filter not in skill.tags:
			return false
	
	return true

# ======================== NON-DAMAGE STATS ========================

## Calculate the final value of a non-damage stat (mana_cost, attack_speed, etc.)
## This uses a single-value approach (no buckets).
## The base_value is the skill's base stat value (e.g., skill.mana_cost).
func get_final_stat(stat_name: String, base_value: float) -> float:
	var flat_total: float = 0.0
	var increased_total: float = 0.0
	var more_multipliers: Array[float] = []
	
	for sd in active_supports:
		for mod in sd.modifiers:
			if mod.stat != stat_name:
				continue
			# Non-damage stats don't use damage_type_filter
			# But skill_tag_filter still applies
			if mod.skill_tag_filter != "":
				if mod.skill_tag_filter not in skill.tags:
					continue
			
			match mod.modifier_type:
				StatModifier.ModifierType.FLAT:
					flat_total += mod.value
				StatModifier.ModifierType.INCREASED:
					increased_total += mod.value
				StatModifier.ModifierType.MORE:
					more_multipliers.append(1.0 + mod.value / 100.0)
	
	var result: float = (base_value + flat_total) * (1.0 + increased_total / 100.0)
	for m in more_multipliers:
		result *= m
	
	return result


## Returns two dictionaries from active supports:
## - inc_mods: INCREASED-type non-damage stats (for apply_buff_modifier)
## - flat_mods: FLAT-type non-damage stats (for apply_buff_flat_modifier)
func get_non_damage_modifiers() -> Dictionary:
	var inc_mods: Dictionary = {}
	var flat_mods: Dictionary = {}
	for sd in active_supports:
		for mod in sd.modifiers:
			if mod is StatModifier:
				if mod.stat == "damage":
					continue
				if mod.skill_tag_filter != "":
					if mod.skill_tag_filter not in skill.tags:
						continue
				match mod.modifier_type:
					StatModifier.ModifierType.INCREASED:
						inc_mods[mod.stat] = inc_mods.get(mod.stat, 0.0) + mod.value
					StatModifier.ModifierType.FLAT:
						flat_mods[mod.stat] = flat_mods.get(mod.stat, 0.0) + mod.value
	return {"inc": inc_mods, "flat": flat_mods}
