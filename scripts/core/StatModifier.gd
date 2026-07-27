extends Resource
class_name StatModifier
## PoE2-style stat modifier: defines how a support gem changes a skill stat.
## Three types: FLAT (adds to base), INCREASED (additive with other increased),
## MORE (multiplicative with other mores).
##
## Each modifier can optionally filter by:
## - damage_type_filter: only applies to specific damage bucket ("physical", "fire", etc.)
## - skill_tag_filter: only applies if skill has this tag ("melee", "attack", etc.)

enum ModifierType {
	FLAT,      # Adds directly to base value: +5 Physical Damage
	INCREASED, # Additive percentage: 30% increased = +30% in the additive bucket
	MORE,      # Multiplicative percentage: 49% more = ×1.49 multiplier
}

## Which stat this modifies: "damage", "mana_cost", "attack_speed", "cast_speed", "crit_chance"
@export var stat: String = "damage"

## FLAT, INCREASED, or MORE
@export var modifier_type: ModifierType = ModifierType.INCREASED

## Numeric value.
## - FLAT: absolute value (e.g., 5.0 = +5 damage)
## - INCREASED: percentage (e.g., 30.0 = +30% increased)
## - MORE: percentage (e.g., 49.0 = ×1.49 multiplier)
@export var value: float = 0.0

## Optional: only apply to specific damage bucket(s).
## "" (empty) = applies to all buckets.
## "physical", "fire", "cold", "lightning", "chaos" = only that bucket.
## "elemental" = fire + cold + lightning combined.
@export var damage_type_filter: String = ""

## Optional: only apply if skill has this specific tag.
## "" (empty) = no tag requirement.
## "melee", "attack", "spell", "projectile", "aoe", "physical", etc.
@export var skill_tag_filter: String = ""
