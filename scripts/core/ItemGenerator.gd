extends Node
class_name ItemGenerator
## 10x item cesitliligi: 50'den fazla affix, 14 item tipi, PoE tarzi isimler.

const AFFIX_POOL = {
	# === TEMEL STATLAR (10) - T99=minimum, T1=maksimum (ultra rare) ===
	"max_life": {"min": 5.0, "max": 3500.0, "pct": false, "types": []},
	"max_life_percent": {"min": 1.0, "max": 35.0, "pct": true, "types": []},
	"max_mana": {"min": 5.0, "max": 2000.0, "pct": false, "types": []},
	"max_mana_percent": {"min": 1.0, "max": 30.0, "pct": true, "types": []},
	"max_energy_shield": {"min": 3.0, "max": 1500.0, "pct": false, "types": ["helmet", "body_armour", "offhand"]},
	"max_energy_shield_percent": {"min": 1.0, "max": 50.0, "pct": true, "types": ["helmet", "body_armour"]},
	"armour": {"min": 3.0, "max": 3000.0, "pct": false, "types": ["helmet", "body_armour", "gloves", "boots", "offhand"]},
	"armour_percent": {"min": 1.0, "max": 40.0, "pct": true, "types": ["helmet", "body_armour"]},
	"evasion": {"min": 3.0, "max": 3000.0, "pct": false, "types": ["helmet", "body_armour", "gloves", "boots"]},
	"evasion_percent": {"min": 1.0, "max": 40.0, "pct": true, "types": ["helmet", "body_armour"]},
	
	# === DIRENCLER (5) ===
	"fire_resistance": {"min": 2.0, "max": 200.0, "pct": false, "types": []},
	"cold_resistance": {"min": 2.0, "max": 200.0, "pct": false, "types": []},
	"lightning_resistance": {"min": 2.0, "max": 200.0, "pct": false, "types": []},
	"chaos_resistance": {"min": 2.0, "max": 150.0, "pct": false, "types": []},
	"all_resistance": {"min": 1.0, "max": 50.0, "pct": false, "types": []},
	
	# === HASAR AFFIX'LERI (12) ===
	"physical_damage": {"min": 2.0, "max": 600.0, "pct": false, "types": ["weapon", "gloves"]},
	"physical_damage_percent": {"min": 3.0, "max": 200.0, "pct": true, "types": ["weapon"]},
	"elemental_damage": {"min": 3.0, "max": 180.0, "pct": true, "types": ["weapon", "gloves", "offhand", "amulet"]},
	"cold_damage": {"min": 2.0, "max": 150.0, "pct": true, "types": ["weapon", "gloves"]},
	"fire_damage": {"min": 2.0, "max": 150.0, "pct": true, "types": ["weapon", "gloves"]},
	"lightning_damage": {"min": 2.0, "max": 150.0, "pct": true, "types": ["weapon", "gloves"]},
	"chaos_damage": {"min": 2.0, "max": 120.0, "pct": true, "types": ["weapon", "gloves"]},
	"damage_over_time": {"min": 3.0, "max": 100.0, "pct": true, "types": ["weapon", "gloves"]},
	"projectile_damage": {"min": 3.0, "max": 120.0, "pct": true, "types": ["weapon", "gloves"]},
	"area_damage": {"min": 3.0, "max": 100.0, "pct": true, "types": ["weapon"]},
	
	# === ADDS DAMAGE (5) — silahlara flat hasar ekler, range olarak gösterilir ===
	"adds_physical_damage": {"min": 3.0, "max": 600.0, "pct": false, "types": ["weapon", "gloves", "offhand", "amulet"]},
	"adds_fire_damage": {"min": 3.0, "max": 400.0, "pct": false, "types": ["weapon", "gloves", "offhand", "amulet"]},
	"adds_cold_damage": {"min": 3.0, "max": 400.0, "pct": false, "types": ["weapon", "gloves", "offhand", "amulet"]},
	"adds_lightning_damage": {"min": 3.0, "max": 400.0, "pct": false, "types": ["weapon", "gloves", "offhand", "amulet"]},
	"adds_chaos_damage": {"min": 2.0, "max": 250.0, "pct": false, "types": ["weapon", "offhand", "amulet"]},
	
	# === KRITIK (3) ===
	"critical_chance": {"min": 0.5, "max": 25.0, "pct": false, "types": ["weapon", "gloves"]},
	"critical_multiplier": {"min": 5.0, "max": 200.0, "pct": false, "types": ["weapon", "amulet"]},
	# "critical_chance_spells": {"min": 0.5, "max": 20.0, "pct": false, "types": ["weapon", "offhand"]}, kaldirildi
	
	# === HIZ (4) ===
	"attack_speed": {"min": 1.0, "max": 60.0, "pct": true, "types": ["weapon", "gloves"]},
	"cast_speed": {"min": 1.0, "max": 60.0, "pct": true, "types": ["weapon", "amulet"]},
	"movement_speed": {"min": 1.0, "max": 50.0, "pct": true, "types": ["boots"]},
	"cooldown_recovery": {"min": 3.0, "max": 80.0, "pct": true, "types": ["amulet", "belt"]},
	
	# === YENILENME / EMME (6) ===
	"life_regen": {"min": 1.0, "max": 80.0, "pct": true, "types": []},
	"mana_regen": {"min": 3.0, "max": 100.0, "pct": true, "types": []},
	"energy_shield_regen": {"min": 1.0, "max": 50.0, "pct": true, "types": ["helmet", "body_armour"]},
	"life_leech": {"min": 0.1, "max": 15.0, "pct": false, "types": ["weapon", "gloves"]},
	"mana_leech": {"min": 0.1, "max": 10.0, "pct": false, "types": ["weapon"]},
	"life_gain_on_hit": {"min": 1.0, "max": 80.0, "pct": false, "types": ["weapon", "gloves"]},
	
	# === SAVUNMA (4) ===
	"attack_block_chance": {"min": 1.0, "max": 25.0, "pct": false, "types": ["offhand"]},
	"spell_block_chance": {"min": 1.0, "max": 20.0, "pct": false, "types": ["offhand"]},
	"attack_dodge_chance": {"min": 1.0, "max": 20.0, "pct": false, "types": ["boots"]},
	# spell_dodge_chance removed - spells can't be dodged
	
	# === NITELIK (3) ===
	"strength": {"min": 3.0, "max": 300.0, "pct": false, "types": []},
	"dexterity": {"min": 3.0, "max": 300.0, "pct": false, "types": []},
	"intelligence": {"min": 3.0, "max": 300.0, "pct": false, "types": []},
	
	# === UTILITY (5) ===
	"item_rarity": {"min": 3.0, "max": 120.0, "pct": true, "types": []},
	"item_quantity": {"min": 3.0, "max": 80.0, "pct": true, "types": []},
	"accuracy": {"min": 5.0, "max": 1000.0, "pct": false, "types": ["weapon", "gloves", "helmet"]},
	"mana_on_kill": {"min": 1.0, "max": 50.0, "pct": false, "types": []},
	"life_on_kill": {"min": 1.0, "max": 80.0, "pct": false, "types": []},
}
# Toplam: ~55 affix — T1-T99 sistemi ile yeniden dengelendi

const MAX_AFFIXES = 8
const MAX_TIER = 99  # T1=en iyi (ultra rare), T99=en kötü (common)

const RARITY_AFFIX_COUNT = {
	"normal": [0, 0],
	"magic": [1, 3],
	"rare": [3, 8],
	"unique": [4, 8],
}

const RARITY_WEIGHTS = {
	"normal": 65.0,
	"magic": 22.0,
	"rare": 10.0,
	"unique": 3.0,
}

# PoE tarzi isim generatoru - 40 prefix + 40 suffix
const NAME_PREFIXES := [
	"Ölümcül", "Yıkıcı", "Karanlık", "Alevli", "Buzul", "Yıldırım",
	"Kutsal", "Lanetli", "Kanlı", "Gölge", "Hayalet", "Fırtına",
	"Zehirli", "Kadim", "Yırtıcı", "Vahşi", "Sessiz", "Çılgın",
	"Asil", "Sonsuz", "Yıkılmış", "Çürümüş", "Parlak", "Donuk",
	"Gümüş", "Demir", "Çelik", "Ejder", "Kurt", "Şahin",
	"Gece", "Sabah", "Alaca", "Kızıl", "Mavi", "Yeşil",
	"Mor", "Beyaz", "Siyah", "Altın"
]

const NAME_SUFFIXES := [
	"Kıyamet", "Fırtına", "Avcı", "Cellat", "Savaş", "Kurt",
	"Ejderha", "Şeytan", "Azap", "Hüzün", "İsyan", "Yıkım",
	"Fetih", "Kader", "İntikam", "Şafak", "Alacakaranlık",
	"Cehennem", "Bilgelik", "Zırh", "Kalkan", "Yürek",
	"Ruh", "Güç", "Kanat", "Diş", "Pençe", "Göz",
	"Gölge", "Alev", "Buz", "Taş", "Rüzgar", "Dalga",
	"Yıldızı", "Canı", "Özü", "Nefesi", "Ateşi"
]

static func _generate_name(item: ItemData) -> void:
	var r: String = item.rarity
	var base_name: String = item.display_name
	
	if r == "normal":
		if randi() % 3 == 0:
			item.display_name = "%s %s" % [NAME_PREFIXES[randi() % NAME_PREFIXES.size()], base_name]
		return
	
	if r == "magic":
		var prefix: String = NAME_PREFIXES[randi() % NAME_PREFIXES.size()]
		item.display_name = "%s %s" % [prefix, base_name]
	
	elif r == "rare" or r == "unique":
		var prefix: String = NAME_PREFIXES[randi() % NAME_PREFIXES.size()]
		var suffix: String = NAME_SUFFIXES[randi() % NAME_SUFFIXES.size()]
		item.display_name = "%s %s (%s)" % [prefix, base_name, suffix]

static func generate_item(base_item: ItemData, tier: int, rarity_boost: float = 0.0) -> ItemData:
	var item: ItemData = base_item.duplicate_item()
	item.rarity = _roll_rarity(rarity_boost)
	# Item level'ı tier'a göre ayarla (1-100 arası)
	item.item_level = tier * 10 + randi_range(1, 9)
	item.required_level = maxi(1, tier * 2 - 1)
	
	# Base statları item_level'e göre scale et
	# Yüksek level item = daha yüksek base hasar/zırh ve stat gereksinimi
	var _lvl: float = float(item.item_level)
	var _dmg_scale: float = 1.0 + (_lvl - 1.0) * 0.03     # ~%3/lvl
	var _arm_scale: float = 1.0 + (_lvl - 1.0) * 0.025    # ~%2.5/lvl
	var _req_scale: float = 1.0 + (_lvl - 1.0) * 0.02     # ~%2/lvl
	item.base_physical_damage_min = round(item.base_physical_damage_min * _dmg_scale)
	item.base_physical_damage_max = round(item.base_physical_damage_max * _dmg_scale)
	item.base_elemental_damage = round(item.base_elemental_damage * _dmg_scale)
	item.base_armour = round(item.base_armour * _arm_scale)
	item.base_evasion = round(item.base_evasion * _arm_scale)
	item.base_energy_shield = round(item.base_energy_shield * _arm_scale)
	item.base_block_chance = round(item.base_block_chance * _arm_scale * 10.0) / 10.0
	item.required_strength = maxi(0, roundi(item.required_strength * _req_scale))
	item.required_dexterity = maxi(0, roundi(item.required_dexterity * _req_scale))
	item.required_intelligence = maxi(0, roundi(item.required_intelligence * _req_scale))
	
	# Unique rarity → UniqueItemRegistry'den önceden tanımlı item kullan
	if item.rarity == "unique":
		var unique_item := UniqueItemRegistry.get_random()
		if unique_item:
			var u := unique_item.duplicate_item()
			u.item_level = item.item_level
			# Copy ALL base stats from the original base item (already scaled above).
			# UniqueItemRegistry only stores id/name/type/slot/level/affixes — NO base stats!
			# NOT: weapon_type kopyalanmaz — UniqueItemRegistry kendi weapon_type'ını zaten tanımlar.
			# Base item'dan kopyalamak, helmet unique'lerin kılıç ikonu göstermesine yol açar.
			u.base_physical_damage_min = item.base_physical_damage_min
			u.base_physical_damage_max = item.base_physical_damage_max
			u.base_elemental_damage = item.base_elemental_damage
			u.base_attack_speed = item.base_attack_speed
			u.base_armour = item.base_armour
			u.base_evasion = item.base_evasion
			u.base_energy_shield = item.base_energy_shield
			u.base_block_chance = item.base_block_chance
			u.required_strength = item.required_strength
			u.required_dexterity = item.required_dexterity
			u.required_intelligence = item.required_intelligence
			u.required_level = item.required_level
			# Unique affix'leri item_level'e göre scale et (T1-T99 sistemi)
			_scale_unique_affixes(u)
			# HER unique item'a pasif ağacından rastgele 1 node bonusu ekle (kesin)
			_add_passive_affix(u)
			# Copy weapon display_name for tooltip clarity
			if u.display_name.is_empty():
				u.display_name = item.display_name
			return u
		# Fallback: unique yoksa rare'e düş
		item.rarity = "rare"
	
	_generate_name(item)

	var base_affixes: Array[Affix] = []
	for aff in item.affixes:
		base_affixes.append(aff)

	var affix_range: Array = RARITY_AFFIX_COUNT.get(item.rarity, [0, 0])
	var extra_affix_count: int = randi_range(int(affix_range[0]), int(affix_range[1]))
	extra_affix_count = min(extra_affix_count, MAX_AFFIXES)

	var used_stats: Array[String] = []
	for aff in base_affixes:
		used_stats.append(aff.stat_name)

	var compatible_stats := _get_compatible_stats(item.item_type)
	var available_stats: Array[String] = []
	for s in compatible_stats:
		if s not in used_stats:
			available_stats.append(s)
	available_stats.shuffle()

	# Base tier'ı item_level'den hesapla
	var base_tier: int = _item_level_to_tier(item.item_level)
	var chosen_count = min(extra_affix_count, available_stats.size())
	for i in range(chosen_count):
		var cur_tier: int = _roll_affix_tier(base_tier)
		var affix = _roll_affix(available_stats[i], cur_tier)
		item.affixes.append(affix)

	return item

static func _get_compatible_stats(item_type: String) -> Array[String]:
	var result: Array[String] = []
	for stat_name in AFFIX_POOL.keys():
		var def: Dictionary = AFFIX_POOL[stat_name]
		var types: Array = def["types"]
		if types.is_empty() or item_type in types:
			result.append(stat_name)
	return result

## Affix tier'ını item_level'den hesapla (T1-T99)
## item_level 1-990: 99-1 arası tier (düşük level = kötü tier)
## item_level 1 → tier 99, item_level 990 → tier 1
## T1=en iyi (yüksek değerler), T99=en kötü (düşük değerler)
static func _item_level_to_tier(item_level: int) -> int:
	return clampi(100 - floori(item_level / 10), 1, MAX_TIER)

## Her affix kendi tier'ını bağımsız olarak roll'lar
## base_tier item_level'den gelir, ±1-10 farklılık gösterebilir
static func _roll_affix_tier(base_tier: int) -> int:
	var variance := randi() % 21  # 0-20
	var offset: int
	if variance <= 2:       offset = -10
	elif variance <= 5:     offset = -5
	elif variance <= 7:     offset = -3
	elif variance <= 10:    offset = -1
	elif variance <= 14:    offset = 0
	elif variance <= 17:    offset = 1
	elif variance <= 19:    offset = 3
	else:                   offset = 5
	return clampi(base_tier + offset, 1, MAX_TIER)

static func _roll_affix(stat_name: String, tier: int) -> Affix:
	var def: Dictionary = AFFIX_POOL[stat_name]
	var min_v: float = def["min"]
	var max_v: float = def["max"]
	var is_pct: bool = def["pct"]

	# T1=best (en yüksek değerler), T99=worst (en düşük değerler)
	# T1 → ratio=1.0 (max_v'ye yakın), T99 → ratio=0.05 (min_v'ye yakın)
	var tier_ratio: float = clamp(float(MAX_TIER - tier + 1) / float(MAX_TIER), 0.05, 1.0)
	
	# BUG FIX: T1 gibi iyi tier'lar düşük değer alamamalı
	# accessible_min da tier_ratio'ya göre yükselsin
	# T1 için accessible_min = max_v * 0.75 (maksimumun %75'i)
	# T50 için accessible_min = min_v (en düşük)
	# T99 için accessible_min = min_v (en düşük)
	var accessible_min: float = min_v
	if tier_ratio > 0.5:
		# İyi tier'lar (T1-T50): alt sınır da yükselir
		accessible_min = min_v + (max_v - min_v) * (tier_ratio - 0.5) * 1.5
	var accessible_max: float = min_v + (max_v - min_v) * tier_ratio

	var value: float = randf_range(accessible_min, accessible_max)
	if is_pct:
		# Percentage değerleri her zaman 1 ondalık
		value = round(value * 10.0) / 10.0
	else:
		# Smart rounding: küçük değerlerde hassasiyeti koru
		if min_v < 1.0:
			# Çok küçük min değerler (mana_leech 0.1 gibi) yuvarlanınca 0 olmasın
			if max_v < 1.0:
				value = round(value * 100.0) / 100.0      # 2 ondalık
			else:
				value = round(value * 10.0) / 10.0         # 1 ondalık
		elif max_v < 10.0:
			value = round(value * 10.0) / 10.0         # 1 ondalık (crit chance gibi)
		else:
			value = round(value)                       # tam sayı (armour gibi)

	var affix := Affix.new()
	affix.stat_name = stat_name
	affix.value = value
	affix.is_percentage = is_pct
	affix.tier = tier
	return affix

## Unique affix değerlerini item_level'e göre T1-T99 sistemiyle yeniden hesapla
## Unique'ler normal item'lerden DAHA GÜÇLÜ:
##   1) Zone tier'inin altına düşemez (negatif varyans yok)
##   2) 1.5x değer çarpanı (aynı tier'daki magic item'den %50 fazla)
static func _scale_unique_affixes(item: ItemData) -> void:
	"""Her unique affix'in değerini item_level bazlı T1-T99 sistemiyle yeniden hesaplar.
	Unique'ler normal item'lerden %50 daha güçlü olacak şekilde çarpan uygulanır."""
	var base_tier: int = _item_level_to_tier(item.item_level)
	for aff in item.affixes:
		if not AFFIX_POOL.has(aff.stat_name):
			continue  # AFFIX_POOL'da olmayan stat'lar olduğu gibi kalsın
		# Unique: negatif varyans yok (zone tier'inin altına düşmez)
		var cur_tier: int = _roll_affix_tier(base_tier)
		cur_tier = mini(cur_tier, base_tier)  # asla zone tier'indan kötü olamaz
		var new_aff: Affix = _roll_affix(aff.stat_name, cur_tier)
		# 1.5x çarpan — unique'ler gerçekten "eşsiz" hissettirsin
		new_aff.value *= 1.5
		aff.value = new_aff.value
		aff.is_percentage = new_aff.is_percentage
		aff.tier = new_aff.tier

## HER unique item'a pasif ağacından rastgele 1 node bonusu ekler.
## Pasif ağacı JSON'ındaki "increased"/"flat_base"/"flat_mod" tipli modifier'ları
## Affix.STAT_NAMES'deki key'lerle eşleştirip item affix'i olarak ekler.
static var _passive_affix_pool: Array[Dictionary] = []
static var _passive_pool_loaded: bool = false

## Pasif ağacı key'lerini Affix.STAT_NAMES key'lerine eşle
const _PASSIVE_KEY_MAP := {
	"block_chance": "attack_block_chance",
	"base_accuracy": "accuracy",
	"energy_shield": "max_energy_shield",
}

## Item affix'i olarak eklenmemesi gereken özel pasif key'leri
const _PASSIVE_SKIP_KEYS := ["keystone_special", "immunity_or_prohibition"]

## "Gain X% of Y as Extra Z" kalıbını tespit et ve parse et
## Döndürür: {stat_name, value, display_text} veya null
static func _parse_gain_as_extra(raw_text: String) -> Dictionary:
	var regex := RegEx.new()
	# Kalıp: "(Empowered Attacks )?Gain X% of Y as Extra Z (...conditionals...)"
	var compil_err := regex.compile("(?:Empowered Attacks\\s+)?Gain\\s+(\\d+(?:\\.\\d+)?)%\\s+of\\s+(.+?)\\s+as\\s+Extra\\s+(.+?)(?:\\s+damage)?(?:\\s+against\\s+.*|\\s+while\\s+on\\s+.*|\\s+per\\s+.*)?$")
	if compil_err != OK:
		return {}
	var match := regex.search(raw_text.strip_edges())
	if not match:
		return {}
	var pct := match.get_string(1).to_float()
	var source := match.get_string(2).strip_edges().to_lower()
	var target := match.get_string(3).strip_edges().to_lower()
	
	# Kaynak ve hedef türlerini normalize et
	var src_map: Dictionary = {
		"physical damage": "physical",
		"damage": "generic",
		"elemental damage": "elemental",
		"fire damage": "fire",
		"cold damage": "cold",
		"lightning damage": "lightning",
		"chaos damage": "chaos",
		"lightning": "lightning",
		"cold": "cold",
	}
	var tgt_map: Dictionary = {
		"fire damage": "fire",
		"fire": "fire",
		"cold damage": "cold",
		"cold": "cold",
		"lightning damage": "lightning",
		"lightning": "lightning",
		"chaos damage": "chaos",
		"chaos": "chaos",
		"physical damage": "physical",
		"physical": "physical",
	}
	var src_v: Variant = src_map.get(source, "")
	var tgt_v: Variant = tgt_map.get(target, "")
	var src_type: String = str(src_v)
	var tgt_type: String = str(tgt_v)
	# "random Element" kontrolü
	if "random" in target:
		return {"stat_name": "gain_as_extra_random", "value": pct, "display_text": raw_text}
	if src_type.is_empty() or tgt_type.is_empty():
		return {}
	return {
		"stat_name": "gain_" + src_type + "_as_" + tgt_type,
		"value": pct,
		"display_text": raw_text
	}

static func _load_passive_affix_pool() -> void:
	if _passive_pool_loaded:
		return
	_passive_pool_loaded = true
	
	var file := FileAccess.open("res://data/passive_skill_tree.json", FileAccess.READ)
	if not file:
		push_error("Passive tree JSON yüklenemedi!")
		return
	
	var json_str := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(json_str)
	if err != OK:
		push_error("Passive tree JSON parse hatasi: ", err)
		return
	
	var data: Dictionary = json.data
	# Ana ağaç + ascendancy node'larını tara
	for nodes_key in ["nodes", "ascendancy_nodes"]:
		var nodes: Array = data.get(nodes_key, [])
		for node in nodes:
			var modifiers: Array = node.get("modifiers", [])
			for mod in modifiers:
				var mod_type: String = mod.get("type", "")
				# Keystoneları atla (özel efektler, basit stat bonusu değil)
				if mod_type == "keystone":
					continue
				var key: String = mod.get("key", "")
				var raw_txt: String = mod.get("raw", "")
				
				if not key.is_empty() and key not in _PASSIVE_SKIP_KEYS:
					# Normal stat-based mod
					var stat_name: String = _PASSIVE_KEY_MAP.get(key, key)
					if Affix.STAT_NAMES.has(stat_name):
						var value: float = mod.get("value", 0.0)
						if value != 0.0:
							_passive_affix_pool.append({
								"stat_name": stat_name,
								"value": value,
								"is_percentage": (mod_type == "increased"),
								"raw": raw_txt,
								"raw_text": "",
							})
				elif not raw_txt.is_empty() and raw_txt.begins_with("Gain") and "as Extra" in raw_txt:
					# "Gain X% of Y as Extra Z" — özel modifier
					var parsed := _parse_gain_as_extra(raw_txt)
					if not parsed.is_empty():
						_passive_affix_pool.append({
							"stat_name": parsed["stat_name"],
							"value": parsed["value"],
							"is_percentage": false,
							"raw": raw_txt,
							"raw_text": parsed["display_text"],
						})
	
	print("Passive affix havuzu: %d adet modifier yüklendi" % _passive_affix_pool.size())

static func _add_passive_affix(item: ItemData) -> void:
	"""Her unique item'a pasif ağacından rastgele 1 node bonusunu affix olarak ekler"""
	
	_load_passive_affix_pool()
	if _passive_affix_pool.is_empty():
		return
	
	var entry: Dictionary = _passive_affix_pool[randi() % _passive_affix_pool.size()]
	
	var aff := Affix.new()
	aff.stat_name = entry["stat_name"]
	aff.value = entry["value"]
	aff.is_percentage = entry["is_percentage"]
	aff.tier = 1  # Passive node bonusu — en iyi tier işareti
	aff.is_passive = true  # Tooltip'te ⭐ işareti göster
	aff.raw_text = entry.get("raw_text", entry.get("raw", ""))
	
	item.affixes.append(aff)
	print("✨ Unique item'a pasif affix eklendi: ⭐%s = %s" % [entry["stat_name"], entry["raw"]])

## rarity_boost: player'ın item_rarity stat'ından gelen % değer (0-100+)
## Bu değer normal ağırlıktan düşülüp rare/unique'e eklenir.
static func _roll_rarity(rarity_boost: float = 0.0) -> String:
	var weights := RARITY_WEIGHTS.duplicate()
	if rarity_boost > 0.0:
		var shift: float = minf(rarity_boost, weights["normal"])
		weights["normal"] -= shift
		var half_shift: float = shift * 0.5
		weights["magic"] += half_shift
		weights["rare"] += half_shift * 0.6
		weights["unique"] += half_shift * 0.4
	
	var total: float = 0.0
	for w in weights.values():
		total += w
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for rarity in RARITY_WEIGHTS.keys():
		cumulative += weights[rarity]
		if roll <= cumulative:
			return rarity
	return "normal"
