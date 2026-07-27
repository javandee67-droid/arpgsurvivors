extends Resource
class_name SupportData
## PoE'deki "support gem" karşılığı. Bir skill'e takılıp onun davranışını
## değiştirir. allowed_tags boşsa her skill'e takılabilir.
##
## YENİ: modifiers alanı (Array[StatModifier]) ile FLAT/INCREASED/MORE
## modifier'ları destekler. Eski damage_multiplier/mana_multiplier alanları
## geriye uyumluluk için korunmuştur.

@export var id: String = ""
@export var display_name: String = ""
## Kisa aciklama (tooltip'te gosterilir)
@export var gem_description: String = ""
## Ikon resmi yolu (32x32 png)
@export var icon_path: String = ""

## Bu support kaçıncı seviyede takılabilir?
@export var required_level: int = 1

## Bu support hangi tag'lere sahip skill'lere takılabilir?
## Örn: ["projectile"] -> sadece projectile skill'lere takılır.
@export var allowed_tags: Array[String] = []

## --- Eski sistem (geriye uyumluluk) ---
@export var damage_multiplier: float = 1.0
@export var mana_multiplier: float = 1.0
@export var extra_projectiles: int = 0

## Bir trigger skill normalde 1 kez ateşlenir, bu support ile +1 eklenirse 2 kez ateşlenir.
@export var extra_trigger_count: int = 0

## Bu support skill'e yeni tag ekleyebilir (örn. bir "AoE" support
## skill'e "aoe" tag'i ekleyip başka support'ların onu görmesini sağlar).
@export var added_tags: Array[String] = []

## --- YENİ: StatModifier tabanlı sistem ---
## Bu support'un skill'e uyguladığı FLAT/INCREASED/MORE modifier'lar.
## SkillInstance bunları kullanarak PoE2 formülüyle final stat'ları hesaplar.
@export var modifiers: Array[StatModifier] = []

func is_compatible(skill: SkillData) -> bool:
	if allowed_tags.is_empty():
		return true
	var tag_lower: String
	var st_lower: String
	for t in allowed_tags:
		tag_lower = t.to_lower()
		for st in skill.tags:
			st_lower = st.to_lower()
			if st_lower == tag_lower:
				return true
	return false
