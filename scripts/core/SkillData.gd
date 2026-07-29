extends Resource
class_name SkillData
## Complete PoE-style skill gem definition.
## Now supports damage_buckets (dictionary-based damage types) and
## damage_effectiveness for weapon-based skill scaling.

enum SkillType {
	PROJECTILE,
	AOE,
	MELEE,
	BUFF,
	AURA,
	CURSE,
	MOVEMENT,
	TRIGGER,
}

@export var id: String = ""
@export var display_name: String = ""
@export var skill_type: SkillType = SkillType.PROJECTILE
@export var tags: Array[String] = []
@export var base_damage: float = 10.0
## ⚠️ DEPRECATED: Artık mana kullanılmıyor (ücretsiz otomatik yetenekler)
@export var mana_cost: float = 0.0
@export var cooldown: float = 0.0
@export var damage_type: String = "physical"
@export var trigger_event: String = ""

## --- YENİ: Damage Buckets (dictionary-based damage) ---
## Skill'in hangi damage type'larda ne kadar hasar verdiğini belirtir.
## Örn: {"physical": 10} veya {"physical": 8, "fire": 4}
## Boş dictionary bırakılırsa, eski base_damage + damage_type kullanılır.
@export var damage_buckets: Dictionary = {}

## --- YENİ: Damage Effectiveness ---
## Weapon damage'in ne kadarının skill'e aktarılacağını belirler.
## PoE2'deki "Damage Effectiveness" karşılığı. Örn: 8.0 = %800
## SkillInstance.get_final_damage() bu değeri weapon damage ile çarpar.
@export var damage_effectiveness: float = 1.0

## --- Projectile ---
@export var projectile_scene: PackedScene
@export var projectile_count: int = 1
@export var projectile_speed: float = 400.0
@export var projectile_spread: float = 0.15

## --- AoE ---
@export var aoe_radius: float = 100.0
@export var aoe_scene: PackedScene

## --- Chain (Lightning/Zincir) ---
## Bu skill kaç kere zincirleyecek (yıldırım zinciri vb.)
## Support gem'ler ile artırılabilir.
@export var chain_count: int = 0

## --- Melee ---
@export var melee_range: float = 20.0
@export var melee_angle: float = 90.0

## --- Buff / Aura ---
@export var buff_duration: float = 4.0
@export var aura_reservation_flat: float = 0.0
@export var aura_reservation_percent: float = 0.0
@export var buff_tags: Array[String] = []

## --- Curse ---
@export var curse_duration: float = 8.0
@export var curse_area: float = 200.0

## --- Visual ---
@export var icon: Texture2D
@export var icon_path: String = ""
@export var cast_time: float = 0.0

func is_spell() -> bool:
	return tags.has("spell")

func is_attack() -> bool:
	return tags.has("attack") or tags.has("melee")

func is_projectile() -> bool:
	return skill_type == SkillType.PROJECTILE

func is_aoe() -> bool:
	return skill_type == SkillType.AOE

func is_melee() -> bool:
	return skill_type == SkillType.MELEE

func is_buff() -> bool:
	return skill_type == SkillType.BUFF

func is_aura() -> bool:
	return skill_type == SkillType.AURA

func is_curse() -> bool:
	return skill_type == SkillType.CURSE

func is_manual() -> bool:
	return trigger_event == ""
