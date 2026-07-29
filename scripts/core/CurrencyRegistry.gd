extends Node
class_name CurrencyRegistry
## Tüm orb/currency tanımlarını tutar. Item pazarında currency'lerin
## hangi etkiye sahip olduğunu belirler. PoE 1/2 mantığı.

static var _orb_ids: Array[String] = []
static var _orbs: Dictionary = {}  # id -> CurrencyData

static func _static_init() -> void:
	_register_all()

static func get_orb(orb_id: String) -> CurrencyData:
	if _orb_ids.is_empty():
		_register_all()
	return _orbs.get(orb_id, null)

static func get_all_orbs() -> Array[CurrencyData]:
	if _orb_ids.is_empty():
		_register_all()
	var result: Array[CurrencyData] = []
	for oid in _orb_ids:
		result.append(_orbs[oid])
	return result

## Düşme ağırlığına göre rastgele bir orb seç
static func get_random_orb() -> CurrencyData:
	if _orb_ids.is_empty():
		_register_all()
	# Ağırlıklı seçim
	var total_weight: int = 0
	for oid in _orb_ids:
		total_weight += _orbs[oid].drop_weight
	var roll: int = randi() % total_weight
	var accum: int = 0
	for oid in _orb_ids:
		accum += _orbs[oid].drop_weight
		if roll < accum:
			return _orbs[oid]
	return _orbs[_orb_ids[0]]

## CurrencyData'dan ItemData üret (yere düşsün diye)
static func make_orb_item(orb_id: String) -> ItemData:
	var cd: CurrencyData = get_orb(orb_id)
	if not cd:
		return make_orb_item(_orb_ids[randi() % _orb_ids.size()])
	var item := ItemData.new()
	item.id = orb_id
	item.display_name = cd.display_name
	item.item_type = "currency"
	item.rarity = "currency"
	item.icon = cd.get_icon()
	item.stackable = true
	item.stack_count = 1
	item.item_level = 1
	return item

static func _register_all() -> void:
	if not _orb_ids.is_empty():
		return
	_orb_ids.clear()
	_orbs.clear()

	# ──────────────────────────────────────────────
	# POE 1/2 TARZI ORBLAR
	# ──────────────────────────────────────────────

	_orb("chaos_orb", "Kaos Küresi", "Tüm affix'leri yeniden rastgele yap",
		CurrencyData.EffectType.REROLL_ALL, 30,
		"res://assets/generated/icon_chaos_orb_frame_0.png", [], ["magic","rare"])

	_orb("exalted_orb", "Yüce Küre", "Rare item'a yeni bir affix ekle",
		CurrencyData.EffectType.ADD_MOD, 5,
		"res://assets/generated/icon_exalted_orb_frame_0.png", [], ["rare"])

	_orb("divine_orb", "İlahi Küre", "Tüm affix değerlerini yeniden rolla",
		CurrencyData.EffectType.REROLL_VALUES, 8,
		"res://assets/generated/icon_divine_orb_frame_0.png", [], ["magic","rare"])

	_orb("alchemy_orb", "Simya Küresi", "Normal item'ı Rare yap",
		CurrencyData.EffectType.MAKE_RARE, 20,
		"res://assets/generated/icon_alchemy_orb_frame_0.png", [], ["normal"])

	_orb("regal_orb", "Kraliyet Küresi", "Magic→Rare yap (+1 affix)",
		CurrencyData.EffectType.UPGRADE_RARITY, 15,
		"res://assets/generated/icon_regal_orb_frame_0.png", [], ["magic"])

	_orb("scouring_orb", "Arındırma Küresi", "Tüm affix'leri sil, normal yap",
		CurrencyData.EffectType.DOWNGRADE_RARITY, 18,
		"res://assets/generated/icon_scouring_orb_frame_0.png", [], ["magic","rare"])

	_orb("transmutation_orb", "Dönüşüm Küresi", "Normal item'ı Magic yap (1 affix)",
		CurrencyData.EffectType.MAKE_MAGIC, 40,
		"res://assets/generated/icon_transmutation_orb_frame_0.png", [], ["normal"])

	_orb("augmentation_orb", "Artırım Küresi", "Magic item'a 2. affix ekle",
		CurrencyData.EffectType.AUGMENT_MAGIC, 35,
		"res://assets/generated/icon_augmentation_orb_frame_0.png", [], ["magic"])

	_orb("alteration_orb", "Değişim Küresi", "Magic affix'lerini yenile",
		CurrencyData.EffectType.REROLL_MAGIC, 50,
		"res://assets/generated/icon_alteration_orb_frame_0.png", [], ["magic"])

	_orb("annulment_orb", "Fesih Küresi", "Rastgele bir affix sil",
		CurrencyData.EffectType.REMOVE_MOD, 10,
		"res://assets/generated/icon_annulment_orb_frame_0.png", [], ["magic","rare"])

	_orb("vaal_orb", "Vaal Küresi", "Item'ı yozlaştır — sonuç tahmin edilemez!",
		CurrencyData.EffectType.CORRUPT, 6,
		"res://assets/generated/icon_vaal_orb_frame_0.png", [], ["normal","magic","rare"])

	_orb("orb_of_fate", "Kader Küresi", "Item'ı tamamen rastgele yap (sıfırdan)",
		CurrencyData.EffectType.FULLY_RANDOMIZE, 3,
		"res://assets/generated/icon_orb_of_fate_frame_0.png", [], ["magic","rare"])

	_orb("orb_of_resistance", "Direnç Küresi", "Rastgele bir direnç affix'i ekle",
		CurrencyData.EffectType.ADD_RESISTANCE, 12,
		"res://assets/generated/icon_orb_of_resistance_frame_0.png", [], ["magic","rare"])

	_orb("quality_orb", "Bileği Taşı", "Item kalitesini artır (+%5, max %100)",
		CurrencyData.EffectType.INCREASE_QUALITY, 25,
		"res://assets/generated/icon_scouring_orb_frame_0.png", [], ["normal","magic","rare","unique"])

static func _orb(id: String, name: String, desc: String, effect: CurrencyData.EffectType,
		weight: int, icon_path: String, item_types: Array[String] = [], rarities: Array[String] = []) -> void:
	var cd := CurrencyData.new()
	cd.id = id
	cd.display_name = name
	cd.description = desc
	cd.effect_type = effect
	cd.drop_weight = weight
	cd.icon_path = icon_path
	cd.allowed_item_types = item_types
	cd.allowed_rarities = rarities
	_orb_ids.append(id)
	_orbs[id] = cd
