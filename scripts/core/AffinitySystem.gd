extends RefCounted
class_name AffinitySystem
## Damage Affinity System - Connects equipment affixes to skill damage types.
## PoE-style: Fire Damage affixes boost Fire skills, Physical boosts attacks, etc.
## Also handles tag-based bonuses (Projectile, AoE, Spell, Attack).

## Damage type to stat key mapping
const DAMAGE_TYPE_STATS := {
	"fire": "fire_damage_increased",
	"cold": "cold_damage_increased",
	"lightning": "lightning_damage_increased",
	"physical": "physical_damage_increased",
	"chaos": "chaos_damage_increased",
	"elemental": "elemental_damage_increased",
}

## Tag to stat key mapping (for generic tag bonuses)
const TAG_STATS := {
	"projectile": "projectile_damage_increased",
	"area": "area_damage_increased",
	"spell": "spell_damage_increased",
	"attack": "attack_damage_increased",
}

## Affinity multiplier cache for performance
static var _cache: Dictionary = {}
static var _cache_stats_ref: Node = null

## Get the affinity multiplier for a skill based on character stats.
## Returns: float (multiplier, e.g., 1.5 = +50% damage)
##
## Calculation:
## 1. Damage-type bonus: skill's damage type → corresponding stat
## 2. Tag bonuses: all skill tags → corresponding stats
## 3. Elemental synergy: if skill has multiple elemental types, apply elemental bonus
static func get_affinity_multiplier(stats: Node, skill_data: SkillData) -> float:
	# Validate inputs
	if not is_instance_valid(stats) or not skill_data:
		return 1.0

	# Cache check - if stats ref changed, invalidate cache
	if _cache_stats_ref != stats:
		_cache.clear()
		_cache_stats_ref = stats

	var cache_key := _make_cache_key(skill_data)
	if _cache.has(cache_key):
		return _cache[cache_key]

	var multiplier: float = 1.0

	# 1. DAMAGE TYPE AFFINITY (primary bonus)
	# Fire damage affix → Fire skills (+50% effectiveness)
	# Cold damage affix → Cold skills (+50% effectiveness)
	# etc.
	var dmg_type: String = skill_data.damage_type.to_lower()
	if DAMAGE_TYPE_STATS.has(dmg_type):
		var stat_key: String = DAMAGE_TYPE_STATS[dmg_type]
		var type_bonus: float = _get_stat_value(stats, stat_key)
		multiplier *= (1.0 + type_bonus / 100.0 * 0.5)  # 50% effectiveness

	# 2. ELEMENTAL SYNERGY (bonus for elemental skills)
	# If skill has both fire+cold or fire+lightning, apply elemental bonus
	var elemental_types: int = 0
	if skill_data.tags.has("Fire"):
		elemental_types += 1
	if skill_data.tags.has("Cold"):
		elemental_types += 1
	if skill_data.tags.has("Lightning"):
		elemental_types += 1

	if elemental_types >= 2:
		# Multi-elemental skill gets elemental damage bonus
		var elem_bonus: float = _get_stat_value(stats, "elemental_damage_increased")
		multiplier *= (1.0 + elem_bonus / 100.0 * 0.75)  # 75% effectiveness

	# 3. TAG-BASED BONUSES
	# Projectile skills get projectile_damage bonus
	# AoE skills get area_damage bonus
	# Spells get spell_damage bonus (if elemental)
	for tag in skill_data.tags:
		var tag_lower: String = tag.to_lower()
		if TAG_STATS.has(tag_lower):
			var stat_key: String = TAG_STATS[tag_lower]
			var tag_bonus: float = _get_stat_value(stats, stat_key)
			multiplier *= (1.0 + tag_bonus / 100.0 * 0.5)  # 50% effectiveness

	# 4. SPELL VS ATTACK DIVISION
	# Spells primarily use elemental stats
	# Attacks primarily use physical stats
	if skill_data.is_spell():
		# Spells get bonus from all_damage_increased
		var all_dmg: float = _get_stat_value(stats, "all_damage_increased")
		multiplier *= (1.0 + all_dmg / 100.0 * 0.3)
	elif skill_data.is_attack() or skill_data.skill_type == SkillData.SkillType.MELEE:
		# Attacks get bonus from attack_speed's related damage (handled separately)
		pass

	# 5. AREA OF EFFECT BONUS
	if skill_data.skill_type == SkillData.SkillType.AOE or skill_data.tags.has("Area"):
		var aoe_bonus: float = _get_stat_value(stats, "area_damage_increased")
		multiplier *= (1.0 + aoe_bonus / 100.0 * 0.6)  # 60% effectiveness

	# 6. PROJECTILE BONUS
	if skill_data.skill_type == SkillData.SkillType.PROJECTILE or skill_data.tags.has("Projectile"):
		var proj_bonus: float = _get_stat_value(stats, "projectile_damage_increased")
		multiplier *= (1.0 + proj_bonus / 100.0 * 0.6)  # 60% effectiveness

	# Cache and return
	_cache[cache_key] = multiplier
	return multiplier

## Get a specific damage type bonus for a skill
## Returns percentage value (e.g., 25.0 = +25% to that type)
static func get_damage_type_bonus(stats: Node, skill_data: SkillData, dmg_type: String) -> float:
	if not is_instance_valid(stats) or not skill_data:
		return 0.0

	var stat_key: String = DAMAGE_TYPE_STATS.get(dmg_type.to_lower(), "")
	if stat_key.is_empty():
		return 0.0

	return _get_stat_value(stats, stat_key)

## Get the radius/AoE bonus for a skill based on area_damage stat
static func get_aoe_radius_bonus(stats: Node, skill_data: SkillData, base_radius: float) -> float:
	if not is_instance_valid(stats) or not skill_data:
		return base_radius

	if skill_data.skill_type != SkillData.SkillType.AOE and not skill_data.tags.has("Area"):
		return base_radius

	var area_pct: float = _get_stat_value(stats, "area_damage_increased")
	return base_radius * (1.0 + area_pct / 100.0 * 0.5)

## Get projectile speed bonus
static func get_projectile_speed_bonus(stats: Node, skill_data: SkillData, base_speed: float) -> float:
	if not is_instance_valid(stats) or not skill_data:
		return base_speed

	var proj_pct: float = _get_stat_value(stats, "projectile_damage_increased")
	# Projectile damage stat also affects projectile speed
	return base_speed * (1.0 + proj_pct / 100.0 * 0.3)

## Clear the affinity cache (call when stats change)
static func clear_cache() -> void:
	_cache.clear()
	_cache_stats_ref = null

## Internal: Get a stat value from CharacterStats
static func _get_stat_value(stats: Node, stat_name: String) -> float:
	if not stats or not (stat_name in stats):
		return 0.0
	return stats.get(stat_name)

## Internal: Create cache key from skill data
static func _make_cache_key(skill_data: SkillData) -> String:
	return "%s_%s_%s" % [skill_data.id, skill_data.damage_type, ",".join(skill_data.tags)]

## Debug: Print affinity breakdown for a skill
static func debug_affinity(stats: Node, skill_data: SkillData) -> String:
	var lines: Array[String] = []
	lines.append("=== Affinity Debug: %s ===" % skill_data.display_name)
	lines.append("Damage Type: %s" % skill_data.damage_type)
	lines.append("Tags: %s" % str(skill_data.tags))
	lines.append("")

	var dmg_type: String = skill_data.damage_type.to_lower()
	if DAMAGE_TYPE_STATS.has(dmg_type):
		var stat_key: String = DAMAGE_TYPE_STATS[dmg_type]
		var val: float = _get_stat_value(stats, stat_key)
		lines.append("%s Affinity: %.1f%% (%.2fx)" % [dmg_type.capitalize(), val, 1.0 + val/100.0*0.5])

	for tag in skill_data.tags:
		var tag_lower: String = tag.to_lower()
		if TAG_STATS.has(tag_lower):
			var stat_key: String = TAG_STATS[tag_lower]
			var val: float = _get_stat_value(stats, stat_key)
			lines.append("%s Tag Bonus: %.1f%% (%.2fx)" % [tag.capitalize(), val, 1.0 + val/100.0*0.5])

	lines.append("")
	lines.append("Final Multiplier: %.3fx" % get_affinity_multiplier(stats, skill_data))

	return "\n".join(lines)
