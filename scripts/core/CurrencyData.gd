extends Resource
class_name CurrencyData
## Bir currency türünü temsil eder. Her currency'nin benzersiz bir etkisi vardır.
## PoE/Path of Exile 2 tarzı — item modifiye etme, dönüştürme, güçlendirme.

enum EffectType {
	REROLL_ALL,          ## Tüm modifierları yeniden rolla (Chaos)
	REROLL_VALUES,       ## Değerleri yeniden rolla (Divine)
	ADD_MOD,             ## Rastgele yeni bir modifier ekle (Exalted)
	REMOVE_MOD,          ## Rastgele bir modifier'ı sil (Annulment)
	UPGRADE_RARITY,      ## Rarity'yi bir üst seviyeye çıkar (Regal → unique'e kadar)
	DOWNGRADE_RARITY,    ## Rarity'yi bir alt seviyeye düşür
	REROLL_MAGIC,        ## Magic item modifierlarını yenile (Alteration)
	AUGMENT_MAGIC,       ## Magic item'a modifier ekle (Augmentation)
	MAKE_MAGIC,          ## Normal → Magic (Transmutation)
	MAKE_RARE,           ## Normal → Rare (Alchemy)
	CORRUPT,             ## Sonuç tahmin edilemez (Vaal)
	ADD_RESISTANCE,      ## Rastgele bir resistance modifier'ı ekle
	ADD_ATTRIBUTE,       ## Rastgele bir stat modifier'ı ekle (strength/dex/int)
	ADD_SPEED,           ## Rastgele speed modifier'ı ekle
	ADD_DEFENSE,         ## Rastgele defense modifier'ı ekle
	ADD_DAMAGE,          ## Rastgele damage modifier'ı ekle
	ADD_MANA,            ## Rastgele mana modifier'ı ekle (mana on kill/regen/hit)
	ADD_LIFE,            ## Rastgele life modifier'ı ekle
	ADD_ELEMENTAL,       ## Rastgele elemental modifier ekle
	ADD_CRIT,            ## Rastgele crit modifier'ı ekle
	ADD_LEECH,           ## Rastgele leech modifier'ı ekle
	SWAP_MOD_TIER,       ## Bir modifier'ın tier'ını yükselt veya düşür
	REROLL_TWO_MODS,     ## İki modifier'ı yeniden rolla
	REMOVE_ADD,          ## Bir modifier sil, bir tane ekle (yeni tier)
	INCREASE_QUALITY,    ## Item quality'sini artır
	FULLY_RANDOMIZE,     ## Tamamen rastgele yeni bir item yap (Orb of Fate)
	MIRROR_MODS,         ## Item'daki iki modifier'ın yerini değiştir
	SCROLL_IDENTIFY,     ## Tanımlanmamış item'ı tanımla
	ENCHANT,             ## Item'a özel bir enchant ekle
}

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var effect_type: EffectType = EffectType.REROLL_ALL
## Hangi item tiplerine uygulanabilir (boş = tümü)
@export var allowed_item_types: Array[String] = []
## Hangi rarity seviyelerine uygulanabilir (boş = tümü)
@export var allowed_rarities: Array[String] = []
## Currency'nin drop rarity ağırlığı (yüksek = daha sık düşer)
@export var drop_weight: int = 100
@export var icon_path: String = ""
@export var tier_min: int = 1  ## En düşük harita tier'ında düşer
@export var tier_max: int = 10 ## En yüksek harita tier'ında düşer
## Özel efekt parametreleri (currency'ye özel)
@export var effect_params: Dictionary = {}

## Currency'nin belirtilen item'e uygulanıp uygulanamayacağını kontrol eder
func can_apply_to(item: ItemData) -> bool:
	if not item:
		return false
	if not allowed_rarities.is_empty():
		if item.rarity not in allowed_rarities:
			return false
	if not allowed_item_types.is_empty():
		if item.item_type not in allowed_item_types:
			return false
	# Unique item'lara sadece quality orb uygulanabilir
	if item.rarity == "unique":
		return effect_type == EffectType.INCREASE_QUALITY
	return true

func get_icon() -> Texture2D:
	if icon_path.is_empty():
		return null
	return load(icon_path) as Texture2D
