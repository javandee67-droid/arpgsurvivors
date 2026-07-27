extends Resource
class_name EnemySkillData
## Dusman skill'lerini tanimlayan veri kaynagi.
## Her skill: id, ad, hasar, menzil, gorsel efektler vb.

enum TargetType {
	TOWARD_PLAYER,      ## Mermi/AoE oyuncuya dogru
	SELF_AOE,           ## AoE kendi etrafinda
	AT_PLAYER_AOE,      ## AoE oyuncunun konumunda
	SELF_BUFF,          ## Kendine buff
}

## Benzersiz ID
@export var id: String = ""
## Gosterim adi (debug)
@export var display_name: String = ""
## Base hasar (dusmanin contact_damage ile carpilir)
@export var base_damage_pct: float = 1.0
## Bekleme suresi (saniye)
@export var cooldown: float = 3.0
## Hasar turu: physical, fire, cold, lightning, chaos
@export var damage_type: String = "physical"
## Skill tag'leri (ailment tetikleme icin)
@export var tags: Array[String] = ["attack"]
## Hedefleme sekli
@export var target_type: int = TargetType.TOWARD_PLAYER
## Mermi hizi (projectile ise)
@export var projectile_speed: float = 300.0
## Mermi sayisi
@export var projectile_count: int = 1
## Mermi yayilmasi (radyan)
@export var projectile_spread: float = 0.15
## AoE yaricapi
@export var aoe_radius: float = 80.0
## Yakin dovus menzili
@export var melee_range: float = 35.0
## Maksimum kullanim mesafesi
@export var max_range: float = 300.0
## Minimum kullanim mesafesi
@export var min_range: float = 0.0

## Mermi sprite yolu (bos ise varsayilan kullanilir)
@export var projectile_texture: String = ""
## Carpma efekti spritesheet yolu
@export var hit_effect_texture: String = ""
@export var hit_effect_fw: int = 64
@export var hit_effect_fh: int = 64
@export var hit_effect_cols: int = 4
@export var hit_effect_count: int = 16

## Skill tipi (runtime kontrol)
enum SkillShape {
	PROJECTILE,  ## Mermi firlatir
	MELEE,       ## Yakin dovus vurusu
	AOE,         ## Alan hasari
	BUFF,        ## Kendine buff
}

@export var shape: int = SkillShape.PROJECTILE

## Buff tag'leri (SELF_BUFF icin)
@export var buff_tags: Array[String] = []

## Yardimci fonksiyonlar
func is_projectile() -> bool:
	return shape == SkillShape.PROJECTILE

func is_melee() -> bool:
	return shape == SkillShape.MELEE

func is_aoe() -> bool:
	return shape == SkillShape.AOE

func is_buff() -> bool:
	return shape == SkillShape.BUFF
