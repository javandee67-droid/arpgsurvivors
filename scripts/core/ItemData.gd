extends Resource
class_name ItemData
## Bir item'ın verisi. .tres olarak kaydedilir.

@export var id: String = ""
@export var display_name: String = ""
@export var item_type: String = "weapon"  # weapon, armor, accessory, currency
@export var rarity: String = "normal"  # normal, magic, rare, unique, currency
@export var affixes: Array[Affix] = []
@export var icon: Texture2D

## Currency ID → özel icon yolu eşlemesi (tüm para birimleri)
const CURRENCY_ICONS: Dictionary = {
	# Essence'lar (renkli özel ikonlar)
	"attribute_essence": "res://assets/generated/essence_icon_attribute_frame_0.png",
	"essence_of_anger": "res://assets/generated/essence_icon_anger_frame_0.png",
	"essence_of_crit": "res://assets/generated/essence_icon_crit_frame_0.png",
	"essence_of_defense": "res://assets/generated/essence_icon_defense_frame_0.png",
	"essence_of_speed": "res://assets/generated/essence_icon_speed_frame_0.png",
	"mana_essence": "res://assets/generated/essence_icon_mana_frame_0.png",
	# Küreler (renk tonu farklı orb ikonları)
	"chaos_orb": "res://assets/generated/icon_chaos_orb_frame_0.png",
	"exalted_orb": "res://assets/generated/icon_exalted_orb_frame_0.png",
	"divine_orb": "res://assets/generated/icon_divine_orb_frame_0.png",
	"alchemy_orb": "res://assets/generated/icon_alchemy_orb_frame_0.png",
	"regal_orb": "res://assets/generated/icon_regal_orb_frame_0.png",
	"vaal_orb": "res://assets/generated/icon_vaal_orb_frame_0.png",
	"scouring_orb": "res://assets/generated/icon_scouring_orb_frame_0.png",
	"transmutation_orb": "res://assets/generated/icon_transmutation_orb_frame_0.png",
	"annulment_orb": "res://assets/generated/icon_annulment_orb_frame_0.png",
	"augmentation_orb": "res://assets/generated/icon_augmentation_orb_frame_0.png",
	"alteration_orb": "res://assets/generated/icon_alteration_orb_frame_0.png",
	"orb_of_fate": "res://assets/generated/icon_orb_of_fate_frame_0.png",
	"orb_of_resistance": "res://assets/generated/icon_orb_of_resistance_frame_0.png",
	"prism_of_power": "res://assets/generated/icon_prism_of_power_frame_0.png",
	"remove_add_orb": "res://assets/generated/icon_remove_add_orb_frame_0.png",
}

## Stack sistemi — aynı türden currency'ler tek slot'ta birikir
@export var stackable: bool = false
@export var stack_count: int = 1

## ITEM LEVEL: Bu item'in seviyesi. Affix tier'larını belirler.
## Ne kadar yüksekse affix değerleri o kadar iyi olur.
@export var item_level: int = 1

## Bu item ekipman slotlarından hangisine takılabilir?
## Boş bırakılırsa (örn. crafting materyali, currency) hiç takılamaz.
## Geçerli değerler: "weapon","offhand","helmet","body_armour","gloves",
## "boots","belt","amulet","ring_1","ring_2"
@export var equip_slot: String = ""
@export var required_level: int = 1

## Çift elli silah mı? (true ise offhand slot'a başka silah takılamaz)
@export var is_two_handed: bool = false

## Silah tipi (sadece item_type=="weapon" ise anlamlı)
## "sword", "bow", "staff", "dagger", "axe", "wand"
@export var weapon_type: String = ""

## Item quality'si (0-100). Base statları artırır ancak affix'leri etkilemez.
@export var quality: int = 0

## Support gem referansı (sadece item_type == "support_gem" ise anlamlı)
@export var support_gem_data: SupportData = null

## --- BASE STATS (item'in kendi taban değerleri) ---
@export var base_physical_damage_min: float = 0.0
@export var base_physical_damage_max: float = 0.0
@export var base_elemental_damage: float = 0.0
@export var base_armour: float = 0.0
@export var base_evasion: float = 0.0
@export var base_energy_shield: float = 0.0
@export var base_block_chance: float = 0.0
@export var base_attack_speed: float = 0.0
@export var base_cast_speed: float = 0.0

## --- EQUIP REQUIREMENTS (giyebilmek için gereken statlar) ---
@export var required_strength: int = 0
@export var required_dexterity: int = 0
@export var required_intelligence: int = 0

## Quality'in base statlara uyguladığı çarpan (PoE: her %5 quality = %20 fiziksel hasar)
func get_quality_multiplier() -> float:
	return 1.0 + float(quality) * 0.01  # Her %1 quality = %1 base stat artışı

## Deep copy - Resource.duplicate(true) typed array ile calismaz, elle kopyala
func duplicate_item() -> ItemData:
	var new := ItemData.new()
	new.id = id
	new.display_name = display_name
	new.item_type = item_type
	new.rarity = rarity
	new.icon = icon
	new.equip_slot = equip_slot
	new.required_level = required_level
	new.item_level = item_level
	# Base stats
	new.base_physical_damage_min = base_physical_damage_min
	new.base_physical_damage_max = base_physical_damage_max
	new.base_elemental_damage = base_elemental_damage
	new.base_armour = base_armour
	new.base_evasion = base_evasion
	new.base_energy_shield = base_energy_shield
	new.base_block_chance = base_block_chance
	new.base_attack_speed = base_attack_speed
	new.base_cast_speed = base_cast_speed
	# Requirements
	new.required_strength = required_strength
	new.required_dexterity = required_dexterity
	new.required_intelligence = required_intelligence
	new.is_two_handed = is_two_handed
	new.weapon_type = weapon_type
	new.quality = quality
	new.stackable = stackable
	new.stack_count = stack_count
	new.support_gem_data = support_gem_data
	# Affix'leri elle kopyala (typed array sorunlarını önler)
	for a in affixes:
		if a:
			var affix_copy := Affix.new()
			affix_copy.stat_name = a.stat_name
			affix_copy.value = a.value
			affix_copy.is_percentage = a.is_percentage
			affix_copy.tier = a.tier
			new.affixes.append(affix_copy)
	return new
