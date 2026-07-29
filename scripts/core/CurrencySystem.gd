extends Node
class_name CurrencySystem
## Currency'lerin item'lere uygulanma mantığı. Statically-accessible methods.

static var _affix_pool_cache: Array[Dictionary] = []

## Currency'yi item'e uygular. Başarılı olursa true döndürür.
static func apply_currency(item: ItemData, currency: CurrencyData) -> bool:
	if not currency.can_apply_to(item):
		return false

	var success := false
	match currency.effect_type:
		CurrencyData.EffectType.REROLL_ALL:
			success = _reroll_all(item)
		CurrencyData.EffectType.REROLL_VALUES:
			success = _reroll_values(item)
		CurrencyData.EffectType.ADD_MOD:
			success = _add_random_mod(item)
		CurrencyData.EffectType.REMOVE_MOD:
			success = _remove_random_mod(item)
		CurrencyData.EffectType.UPGRADE_RARITY:
			success = _upgrade_rarity(item)
		CurrencyData.EffectType.DOWNGRADE_RARITY:
			success = _downgrade_rarity(item)
		CurrencyData.EffectType.REROLL_MAGIC:
			success = _reroll_magic(item)
		CurrencyData.EffectType.AUGMENT_MAGIC:
			success = _augment_magic(item)
		CurrencyData.EffectType.MAKE_MAGIC:
			success = _make_magic(item)
		CurrencyData.EffectType.MAKE_RARE:
			success = _make_rare(item)
		CurrencyData.EffectType.CORRUPT:
			success = _corrupt(item)
		CurrencyData.EffectType.ADD_RESISTANCE:
			success = _add_specific_mod(item, "resistance")
		CurrencyData.EffectType.ADD_ATTRIBUTE:
			success = _add_specific_mod(item, "attribute")
		CurrencyData.EffectType.ADD_SPEED:
			success = _add_specific_mod(item, "speed")
		CurrencyData.EffectType.ADD_DEFENSE:
			success = _add_specific_mod(item, "defense")
		CurrencyData.EffectType.ADD_DAMAGE:
			success = _add_specific_mod(item, "damage")
		CurrencyData.EffectType.ADD_MANA:
			success = _add_specific_mod(item, "mana")
		CurrencyData.EffectType.ADD_LIFE:
			success = _add_specific_mod(item, "life")
		CurrencyData.EffectType.ADD_ELEMENTAL:
			success = _add_specific_mod(item, "elemental")
		CurrencyData.EffectType.ADD_CRIT:
			success = _add_specific_mod(item, "crit")
		CurrencyData.EffectType.ADD_LEECH:
			success = _add_specific_mod(item, "leech")
		CurrencyData.EffectType.SWAP_MOD_TIER:
			success = _swap_mod_tier(item)
		CurrencyData.EffectType.REROLL_TWO_MODS:
			success = _reroll_two_mods(item)
		CurrencyData.EffectType.REMOVE_ADD:
			success = _remove_add(item)
		CurrencyData.EffectType.INCREASE_QUALITY:
			success = _increase_quality(item)
		CurrencyData.EffectType.FULLY_RANDOMIZE:
			success = _fully_randomize(item)
		CurrencyData.EffectType.MIRROR_MODS:
			success = _mirror_mods(item)
		CurrencyData.EffectType.SCROLL_IDENTIFY:
			success = true  # dummy — identify mekaniği ileride
		CurrencyData.EffectType.ENCHANT:
			success = _enchant(item)

	if success:
		item.emit_changed()
	return success

## Bir currency'yi item'in üzerine uygulamak için GUI'de çağrılır
## "Bu currency bu item'a uygulanabilir mi?" kontrolü
static func can_apply(item: ItemData, currency: CurrencyData) -> bool:
	if not item or not currency:
		return false
	return currency.can_apply_to(item)

# ─── EFFECT IMPLEMENTATIONS ───────────────────────────────────────

static func _reroll_all(item: ItemData) -> bool:
	# Tüm affixleri sil, yerlerine aynı sayıda yeni rastgele affix ekle
	# DİKKAT: Aynı stat_name iki kez gelmesin (duplicate affix stacking bug)
	var count := item.affixes.size()
	if count <= 0:
		return false
	item.affixes.clear()
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	if pool.is_empty():
		return false
	var used_stats: Array[String] = []
	for i in range(count):
		var available := pool.filter(func(e: Dictionary) -> bool:
			return not e.stat_name in used_stats
		)
		if available.is_empty():
			break
		var aff := _make_affix_from_pool(available, item)
		if aff:
			item.affixes.append(aff)
			used_stats.append(aff.stat_name)
	item.display_name = _generate_random_name(item)
	return item.affixes.size() > 0

static func _reroll_values(item: ItemData) -> bool:
	# Tüm affix değerlerini yeniden rolla — tier bazlı min-max arasında (ItemGenerator ile aynı sistem)
	if item.affixes.is_empty():
		return false
	for aff in item.affixes:
		var entry := _find_affix_entry(aff.stat_name)
		if entry:
			# Affix'in mevcut tier'ını koruyarak değeri yeniden hesapla
			# ItemGenerator._roll_affix() tier'a göre uygun aralıkta değer üretir
			var new_aff: Affix = ItemGenerator._roll_affix(aff.stat_name, aff.tier)
			if new_aff:
				aff.value = new_aff.value
	return true

static func _add_random_mod(item: ItemData) -> bool:
	# Yeni bir affix ekle (Exalted Orb gibi)
	if item.affixes.size() >= ItemGenerator.MAX_AFFIXES:
		return false
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	# Halihazırda var olan stat'ları filtrele
	var existing := {}
	for aff in item.affixes:
		existing[aff.stat_name] = true
	pool = pool.filter(func(e): return not existing.has(e.stat_name))
	if pool.is_empty():
		return false
	var aff := _make_affix_from_pool(pool, item)
	if aff:
		item.affixes.append(aff)
		# Rarity kontrol — rare değilse rare yap
		if item.rarity in ["normal", "magic"]:
			item.rarity = "rare"
		return true
	return false

static func _remove_random_mod(item: ItemData) -> bool:
	if item.affixes.is_empty():
		return false
	var idx := randi() % item.affixes.size()
	item.affixes.remove_at(idx)
	return true

static func _upgrade_rarity(item: ItemData) -> bool:
	match item.rarity:
		"normal":
			item.rarity = "magic"
			# 1-2 affix ekle
			var add_count := randi_range(1, 2)
			_cache_affix_pool()
			var pool := _get_compatible_pool(item)
			for i in range(add_count):
				if pool.is_empty():
					break
				var aff := _make_affix_from_pool(pool, item)
				if aff:
					item.affixes.append(aff)
					pool = pool.filter(func(e): return e.stat_name != aff.stat_name)
			return true
		"magic":
			item.rarity = "rare"
			# Bir modifier ekle (Regal Orb: büyülü→nadir +1 modifier)
			_cache_affix_pool()
			var pool := _get_compatible_pool(item)
			var existing := {}
			for aff in item.affixes:
				existing[aff.stat_name] = true
			pool = pool.filter(func(e): return not existing.has(e.stat_name))
			if not pool.is_empty():
				var aff := _make_affix_from_pool(pool, item)
				if aff:
					item.affixes.append(aff)
			return true
		"rare":
			# Rare zaten en üst — bir affix daha ekle
			return _add_random_mod(item)
	return false

static func _downgrade_rarity(item: ItemData) -> bool:
	# Scouring Orb: tüm modifierları sil, normal yap
	item.rarity = "normal"
	item.affixes.clear()
	return true

static func _reroll_magic(item: ItemData) -> bool:
	if item.rarity != "magic":
		return false
	item.affixes.clear()
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	for i in range(2):
		if pool.is_empty():
			break
		var aff := _make_affix_from_pool(pool, item)
		if aff:
			item.affixes.append(aff)
			pool = pool.filter(func(e): return e.stat_name != aff.stat_name)
	return item.affixes.size() > 0

static func _augment_magic(item: ItemData) -> bool:
	if item.rarity != "magic" or item.affixes.size() >= 2:
		return false
	return _add_random_mod(item)

static func _make_magic(item: ItemData) -> bool:
	if item.rarity != "normal":
		return false
	item.rarity = "magic"
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	var aff := _make_affix_from_pool(pool, item)
	if aff:
		item.affixes.append(aff)
	return item.affixes.size() > 0

static func _make_rare(item: ItemData) -> bool:
	if item.rarity != "normal":
		return false
	item.rarity = "rare"
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	var count := randi_range(3, 5)
	for i in range(count):
		if pool.is_empty():
			break
		var aff := _make_affix_from_pool(pool, item)
		if aff:
			item.affixes.append(aff)
			pool = pool.filter(func(e): return e.stat_name != aff.stat_name)
	return item.affixes.size() > 0

static func _corrupt(item: ItemData) -> bool:
	# Vaal Orb: PoE tarzı — rastgele sonuç
	var outcome := randi() % 6
	match outcome:
		0:
			# Hiçbir şey olmaz
			return false
		1:
			# +1 affix ekle (tüm sınırları aşar, max affix > 6 olabilir)
			_cache_affix_pool()
			var pool := _get_compatible_pool(item)
			if pool.is_empty():
				return false
			var existing := {}
			for aff in item.affixes:
				existing[aff.stat_name] = true
			pool = pool.filter(func(e): return not existing.has(e.stat_name))
			if pool.is_empty():
				return false
			var aff := _make_affix_from_pool(pool, item)
			if aff:
				item.affixes.append(aff)
			return true
		2:
			# Tüm affix'leri yeniden rolla (iyi veya kötü)
			_reroll_values(item)
			# Rastgele bir affix'in min-max aralığını aşmasına izin ver (80% bonus/penaltı)
			if not item.affixes.is_empty():
				var aff := item.affixes[randi() % item.affixes.size()]
				if randf() > 0.5:
					aff.value *= 1.8  # güçlendir
				else:
					aff.value *= 0.3  # zayıflat
			return true
		2:
			# Item'ı tamamen değiştir (bazen çok iyi, bazen kötü)
			if randi() % 2 == 0:
				item.rarity = "rare"
				item.affixes.clear()
				_cache_affix_pool()
				var pool := _get_compatible_pool(item)
				for i in range(6):
					if pool.is_empty():
						break
					var aff := _make_affix_from_pool(pool, item)
					if aff:
						aff.value *= 1.3  # bonus
						item.affixes.append(aff)
						pool = pool.filter(func(e): return e.stat_name != aff.stat_name)
			else:
				_item_corrupt_destroy(item)
			return true
	return false

static func _item_corrupt_destroy(item: ItemData) -> void:
	# Corrupt başarısız — item'ın çoğu affixini sil
	var keep_count := randi() % maxi(1, item.affixes.size() / 2)
	if item.affixes.size() > keep_count:
		item.affixes = item.affixes.slice(0, keep_count)
	item.rarity = "magic"

static func _add_specific_mod(item: ItemData, category: String) -> bool:
	if item.affixes.size() >= ItemGenerator.MAX_AFFIXES:
		return false
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	# Kategori filtreleme
	var stat_categories := _get_category_stats(category)
	pool = pool.filter(func(e): return e.stat_name in stat_categories)
	# Halihazırda var olanları çıkar
	var existing := {}
	for aff in item.affixes:
		existing[aff.stat_name] = true
	pool = pool.filter(func(e): return not existing.has(e.stat_name))
	if pool.is_empty():
		return false
	var aff := _make_affix_from_pool(pool, item)
	if aff:
		item.affixes.append(aff)
		if item.rarity == "normal":
			item.rarity = "magic"
		return true
	return false

static func _swap_mod_tier(item: ItemData) -> bool:
	if item.affixes.is_empty():
		return false
	var aff := item.affixes[randi() % item.affixes.size()]
	var entry := _find_affix_entry(aff.stat_name)
	if entry == null:
		return false
	# Tier'ı ±1-10 rastgele değiştir (ItemGenerator._roll_affix_tier benzeri)
	var tier_offset: int = [0, 0, 0, 1, 1, -1, -1, 3, -3, 5][randi() % 10]
	var new_tier: int = clampi(aff.tier + tier_offset, 1, ItemGenerator.MAX_TIER)
	var new_aff: Affix = ItemGenerator._roll_affix(aff.stat_name, new_tier)
	if new_aff:
		aff.value = new_aff.value
		aff.tier = new_aff.tier
	return true

static func _reroll_two_mods(item: ItemData) -> bool:
	if item.affixes.size() < 2:
		return _add_random_mod(item)
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	if pool.is_empty():
		return false
	var idx1 := randi() % item.affixes.size()
	var idx2 := randi() % item.affixes.size()
	while idx2 == idx1 and item.affixes.size() > 1:
		idx2 = randi() % item.affixes.size()

	# İkinci affix birinciden farklı stat_name olsun (duplicate bug fix)
	var aff1 := _make_affix_from_pool(pool, item)
	var aff2: Affix = null
	if aff1:
		var pool2 := pool.filter(func(e: Dictionary) -> bool:
			return e.stat_name != aff1.stat_name
		)
		if not pool2.is_empty():
			aff2 = _make_affix_from_pool(pool2, item)
	if aff1:
		item.affixes[idx1] = aff1
	if aff2 and idx2 != idx1:
		item.affixes[idx2] = aff2
	# En az bir modifier değişmiş mi kontrol et
	return aff1 != null or aff2 != null

static func _remove_add(item: ItemData) -> bool:
	if item.affixes.is_empty():
		return _add_random_mod(item)
	# Bir modifier sil, yeni bir tane ekle (genelde daha yüksek tier)
	var removed := _remove_random_mod(item)
	var added := _add_random_mod(item)
	if added and removed:
		# Yeni eklenen modifier'ın değerini %20 daha yüksek yap
		var last: Affix = item.affixes.back() if not item.affixes.is_empty() else null
		if last != null:
			last.value *= 1.25
	return removed or added

static func _increase_quality(item: ItemData) -> bool:
	# Item quality'sini +1 ile +5 arasında rastgele artır (max 100).
	if item.quality >= 100:
		return false
	item.quality = mini(item.quality + randi_range(1, 5), 100)
	return true

static func _fully_randomize(item: ItemData) -> bool:
	# Item'ı tamamen yeni bir rastgele item yap
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	item.affixes.clear()
	item.rarity = "rare"
	var count := randi_range(4, 7)
	for i in range(count):
		if pool.is_empty():
			break
		var aff := _make_affix_from_pool(pool, item)
		if aff:
			item.affixes.append(aff)
			pool = pool.filter(func(e): return e.stat_name != aff.stat_name)
	item.display_name = _generate_random_name(item)
	return item.affixes.size() > 0

static func _mirror_mods(item: ItemData) -> bool:
	# İki modifier'ın değerlerini takas et
	if item.affixes.size() < 2:
		return false
	var idx1 := randi() % item.affixes.size()
	var idx2 := randi() % item.affixes.size()
	while idx2 == idx1:
		idx2 = randi() % item.affixes.size()
	var temp_val := item.affixes[idx1].value
	item.affixes[idx1].value = item.affixes[idx2].value
	item.affixes[idx2].value = temp_val
	return true

static func _enchant(item: ItemData) -> bool:
	# Enchant: base item'a eklenebilecek özel bir affix ekle
	if item.affixes.size() >= ItemGenerator.MAX_AFFIXES + 2:
		return false
	_cache_affix_pool()
	var pool := _get_compatible_pool(item)
	if pool.is_empty():
		return false
	var aff := _make_affix_from_pool(pool, item)
	if aff:
		aff.value *= 1.5  # Enchant değerleri genelde daha yüksek
		item.affixes.append(aff)
		return true
	return false

# ─── HELPER FUNCTIONS ─────────────────────────────────────────────

static func _cache_affix_pool() -> void:
	if not _affix_pool_cache.is_empty():
		return
	# ItemGenerator.AFFIX_POOL: {stat_name: {min, max, pct, types}}
	for stat_name in ItemGenerator.AFFIX_POOL:
		var entry: Dictionary = ItemGenerator.AFFIX_POOL[stat_name]
		if entry is Dictionary:
			var dup: Dictionary = entry.duplicate()
			dup.stat_name = stat_name
			_affix_pool_cache.append(dup)

static func _get_compatible_pool(item: ItemData) -> Array[Dictionary]:
	var types := _get_item_types_for(item)
	return _affix_pool_cache.filter(func(entry: Dictionary) -> bool:
		var allowed: Array = entry.get("types", []) as Array
		if allowed.is_empty():
			return true
		for t in types:
			if t in allowed:
				return true
		return false
	)

static func _get_item_types_for(item: ItemData) -> Array[String]:
	var types: Array[String] = []
	types.append(item.item_type)
	if item.item_type == "weapon":
		types.append("weapon")
	elif item.item_type in ["helmet", "body_armour", "gloves", "boots"]:
		types.append("armor")
	elif item.item_type in ["ring", "accessory"]:
		types.append("accessory")
	if item.equip_slot in ["weapon", "offhand"]:
		types.append("weapon_slot")
	return types

static func _make_affix_from_pool(pool: Array[Dictionary], item: ItemData) -> Affix:
	if pool.is_empty():
		return null
	var entry := pool[randi() % pool.size()]
	var stat_name: String = entry.stat_name
	# Item level'e göre tier hesapla (ItemGenerator ile aynı sistem)
	var base_tier: int = ItemGenerator._item_level_to_tier(item.item_level)
	var final_tier: int = ItemGenerator._roll_affix_tier(base_tier)
	var aff: Affix = ItemGenerator._roll_affix(stat_name, final_tier)
	return aff

static func _find_affix_entry(stat_name: String) -> Dictionary:
	_cache_affix_pool()
	for entry in _affix_pool_cache:
		if entry.stat_name == stat_name:
			return entry
	return {}

## ItemGenerator'daki AFFIX_POOL'dan kategori bazlı stat isimlerini döndür
static func _get_category_stats(category: String) -> Array[String]:
	match category:
		"resistance":
			return ["fire_resistance", "cold_resistance", "lightning_resistance", "chaos_resistance", "all_resistance"]
		"attribute":
			return ["strength", "dexterity", "intelligence"]
		"speed":
			return ["attack_speed", "cast_speed", "movement_speed", "cooldown_recovery"]
		"defense":
			return ["armour", "evasion", "max_energy_shield", "attack_block_chance", "spell_block_chance", "attack_dodge_chance"]
		"damage":
			return ["physical_damage", "physical_damage_percent", "elemental_damage", "cold_damage", "fire_damage", "lightning_damage", "chaos_damage", "damage_over_time", "projectile_damage", "area_damage"]
		"mana":
			return ["max_mana", "max_mana_percent", "mana_regen", "mana_on_kill", "mana_leech"]
		"life":
			return ["max_life", "max_life_percent", "life_regen", "life_on_kill", "life_gain_on_hit", "life_leech"]
		"elemental":
			return ["cold_damage", "fire_damage", "lightning_damage", "elemental_damage"]
		"crit":
			return ["critical_chance", "critical_multiplier"]
		"leech":
			return ["life_leech", "mana_leech", "life_gain_on_hit"]
	return []

static func _generate_random_name(item: ItemData) -> String:
	var prefixes := ItemGenerator.NAME_PREFIXES
	var suffixes := ItemGenerator.NAME_SUFFIXES
	var result_name: String = item.display_name
	if not prefixes.is_empty() and randf() > 0.3:
		result_name = prefixes[randi() % prefixes.size()] + " " + result_name
	if not suffixes.is_empty() and randf() > 0.4:
		result_name = result_name + " (" + suffixes[randi() % suffixes.size()] + ")"
	return result_name
