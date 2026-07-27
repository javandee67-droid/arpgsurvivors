extends Node
class_name UniqueItemRegistry
## 50+ PoE-tarzı unique item'ın veritabanı.

static var _ids: Array[String] = []
static var _items: Dictionary = {}

static func _static_init() -> void:
	_register_all()

static func get_all() -> Array[ItemData]:
	if _ids.is_empty():
		_register_all()
	var result: Array[ItemData] = []
	for uid in _ids:
		result.append(_items[uid])
	return result

static func get_random() -> ItemData:
	if _ids.is_empty():
		_register_all()
	if _ids.is_empty():
		return null
	return _items[_ids[randi() % _ids.size()]].duplicate_item()

static func get_by_id(uid: String) -> ItemData:
	if _ids.is_empty():
		_register_all()
	return _items.get(uid, null).duplicate_item() if _items.has(uid) else null

static func _make_aff(stat_name: String, value: float, pct: bool = false) -> Affix:
	var a := Affix.new()
	a.stat_name = stat_name
	a.value = value
	a.is_percentage = pct
	return a

static func _register_all() -> void:
	if not _ids.is_empty():
		return
	_ids.clear()
	_items.clear()
	# ─── WEAPONS (13) ───
	_register("face_breaker","Yüz Kırıcı","weapon","weapon",8,[_make_aff("physical_damage",60.0),_make_aff("critical_multiplier",150.0),_make_aff("attack_speed",15.0,true)],"axe")
	_register("wanderlust","Gezginin Yoldaşı","weapon","weapon",6,[_make_aff("movement_speed",25.0,true),_make_aff("physical_damage",30.0),_make_aff("attack_speed",20.0,true)],"sword")
	_register("winds_of_change","Değişim Rüzgarı","weapon","weapon",12,[_make_aff("elemental_damage",40.0,true),_make_aff("cast_speed",18.0,true),_make_aff("mana_regen",40.0,true)],"staff")
	_register("eternal_knife","Sonsuz Bıçak","weapon","weapon",10,[_make_aff("physical_damage",45.0),_make_aff("critical_chance",8.0),_make_aff("life_leech",2.0)],"dagger")
	_register("thunderfury","Yıldırım Öfkesi","weapon","weapon",14,[_make_aff("lightning_damage",35.0,true),_make_aff("attack_speed",22.0,true),_make_aff("elemental_damage",25.0,true)],"sword")
	_register("soul_taker","Ruh Toplayıcı","weapon","weapon",10,[_make_aff("physical_damage",50.0),_make_aff("life_on_kill",50.0),_make_aff("mana_on_kill",30.0)],"axe")
	_register("frost_bite","Buz Diş","weapon","weapon",12,[_make_aff("cold_damage",40.0,true),_make_aff("critical_multiplier",80.0),_make_aff("attack_speed",10.0,true)],"dagger")
	_register("doomfang","Kıyamet Dişi","weapon","weapon",14,[_make_aff("chaos_damage",25.0,true),_make_aff("physical_damage",30.0),_make_aff("critical_chance",5.0)],"dagger")
	_register("staff_of_magius","Magius Asası","weapon","weapon",16,[_make_aff("elemental_damage",55.0,true),_make_aff("critical_chance",8.0),_make_aff("mana_regen",50.0,true)],"staff")
	_register("viper_strike","Engerek Darbesi","weapon","weapon",10,[_make_aff("chaos_damage",30.0,true),_make_aff("attack_speed",25.0,true),_make_aff("critical_chance",6.0)],"dagger")
	_register("shadow_strike","Gölge Darbesi","weapon","weapon",12,[_make_aff("critical_chance",9.0),_make_aff("physical_damage",25.0),_make_aff("attack_speed",30.0,true)],"dagger")
	_register("poison_tongue","Zehirli Dil","weapon","weapon",12,[_make_aff("chaos_damage",20.0,true),_make_aff("critical_multiplier",60.0),_make_aff("attack_speed",20.0,true)],"dagger")
	_register("soul_reaver","Ruh Yağmacısı","weapon","weapon",14,[_make_aff("physical_damage",35.0),_make_aff("life_leech",3.0),_make_aff("mana_leech",1.5)],"axe")
	# ─── BODY ARMOURS (6) ───
	_register("tabula_rasa","Boş Levha","body_armour","body_armour",5,[])
	_register("coil_of_the_serpent","Yılan Kıvrımı","body_armour","body_armour",10,[_make_aff("max_life",150.0),_make_aff("armour",200.0),_make_aff("fire_resistance",30.0)])
	_register("shroud_of_the_void","Boşluk Kefeni","body_armour","body_armour",14,[_make_aff("max_energy_shield",250.0),_make_aff("chaos_resistance",40.0),_make_aff("all_resistance",10.0)])
	_register("immortal_flesh","Ölümsüz Et","body_armour","body_armour",16,[_make_aff("max_life",300.0),_make_aff("life_regen",20.0,true),_make_aff("armour",250.0)])
	_register("dragon_scale","Ejderha Pulu","body_armour","body_armour",18,[_make_aff("armour",400.0),_make_aff("all_resistance",15.0),_make_aff("strength",30.0)])
	_register("shadow_weave","Gölge Dokuması","body_armour","body_armour",12,[_make_aff("evasion",350.0),_make_aff("movement_speed",10.0,true),_make_aff("dexterity",25.0)])
	# ─── HELMETS (6) ───
	_register("goldrim","Altın Çember","helmet","helmet",6,[_make_aff("all_resistance",30.0),_make_aff("item_rarity",20.0,true),_make_aff("max_life",60.0)])
	_register("crown_of_eyes","Gözler Tacı","helmet","helmet",10,[_make_aff("max_energy_shield",100.0),_make_aff("accuracy",300.0),_make_aff("intelligence",20.0)])
	_register("brimstone_helm","Kükürt Miğferi","helmet","helmet",8,[_make_aff("fire_resistance",50.0),_make_aff("armour",150.0),_make_aff("strength",25.0)])
	_register("horns_of_war","Savaş Boynuzları","helmet","helmet",10,[_make_aff("physical_damage",15.0),_make_aff("max_life",100.0),_make_aff("attack_block_chance",5.0)])
	_register("mind_cage","Zihin Kafesi","helmet","helmet",12,[_make_aff("max_mana",120.0),_make_aff("mana_regen",30.0,true),_make_aff("elemental_damage",20.0,true)])
	_register("mask_of_the_stalker","Takipçi Maskesi","helmet","helmet",8,[_make_aff("evasion",180.0),_make_aff("attack_speed",10.0,true),_make_aff("accuracy",200.0)])
	# ─── GLOVES (4) ───
	_register("grip_of_the_giant","Devin Kavrayışı","gloves","gloves",10,[_make_aff("physical_damage",20.0),_make_aff("strength",30.0),_make_aff("attack_speed",10.0,true)])
	_register("touch_of_void","Boşluk Dokunuşu","gloves","gloves",12,[_make_aff("chaos_damage",15.0,true),_make_aff("critical_chance",4.0),_make_aff("life_gain_on_hit",15.0)])
	_register("mage_gauntlets","Büyücü Eldivenleri","gloves","gloves",10,[_make_aff("elemental_damage",25.0,true),_make_aff("cast_speed",15.0,true),_make_aff("mana_regen",25.0,true)])
	_register("dusk_grasp","Alacakaranlık Kavrayışı","gloves","gloves",8,[_make_aff("evasion",120.0),_make_aff("life_leech",1.5),_make_aff("dexterity",20.0)])
	# ─── BOOTS (4) ───
	_register("seven_leagues","Yedi Fersah","boots","boots",8,[_make_aff("movement_speed",35.0,true),_make_aff("evasion",150.0),_make_aff("dexterity",20.0)])
	_register("stone_treads","Taş Basamaklar","boots","boots",8,[_make_aff("armour",150.0),_make_aff("max_life",80.0),_make_aff("strength",20.0)])
	_register("sandals_of_the_mystic","Gizemlinin Sandaletleri","boots","boots",10,[_make_aff("movement_speed",15.0,true),_make_aff("mana_regen",30.0,true),_make_aff("max_mana",60.0)])
	_register("death_dance","Ölüm Dansı","boots","boots",12,[_make_aff("attack_dodge_chance",5.0),_make_aff("movement_speed",20.0,true),_make_aff("evasion",200.0)])
	# ─── BELTS (3) ───
	_register("headhunter","Kafa Avcısı","belt","belt",14,[_make_aff("max_life",120.0),_make_aff("strength",30.0),_make_aff("dexterity",25.0)])
	_register("immortal_belt","Ölümsüz Kemer","belt","belt",12,[_make_aff("max_life",200.0),_make_aff("armour",100.0),_make_aff("all_resistance",10.0)])
	_register("woven_magic","Büyülü Dokuma","belt","belt",10,[_make_aff("max_mana",100.0),_make_aff("mana_regen",35.0,true),_make_aff("cooldown_recovery",20.0,true)])
	# ─── AMULETS (5) ───
	_register("heart_of_the_mountain","Dağın Kalbi","amulet","amulet",10,[_make_aff("max_life",150.0),_make_aff("armour",100.0),_make_aff("fire_resistance",25.0)])
	_register("eye_of_the_storm","Fırtınanın Gözü","amulet","amulet",14,[_make_aff("critical_chance",5.0),_make_aff("critical_multiplier",60.0),_make_aff("lightning_damage",20.0,true)])
	_register("soul_anchor","Ruh Çapası","amulet","amulet",12,[_make_aff("max_energy_shield",150.0),_make_aff("chaos_resistance",30.0),_make_aff("elemental_damage",20.0,true)])
	_register("wolftime","Kurt Zamanı","amulet","amulet",8,[_make_aff("attack_speed",15.0,true),_make_aff("life_leech",1.0),_make_aff("physical_damage",15.0)])
	_register("moonlight","Mehtap","amulet","amulet",10,[_make_aff("elemental_damage",30.0,true),_make_aff("max_mana",80.0),_make_aff("cold_resistance",25.0)])
	# ─── RINGS (6) ───
	_register("ring_of_wrath","Gazap Yüzüğü","ring","ring_1",8,[_make_aff("fire_damage",25.0,true),_make_aff("fire_resistance",35.0),_make_aff("max_life",60.0)])
	_register("ring_of_frost","Buz Yüzüğü","ring","ring_1",8,[_make_aff("cold_damage",25.0,true),_make_aff("cold_resistance",35.0),_make_aff("max_mana",60.0)])
	_register("ring_of_storms","Fırtına Yüzüğü","ring","ring_1",10,[_make_aff("lightning_damage",25.0,true),_make_aff("lightning_resistance",35.0),_make_aff("critical_chance",3.0)])
	_register("lifespark","Yaşam Kıvılcımı","ring","ring_1",6,[_make_aff("max_life",100.0),_make_aff("life_regen",8.0,true),_make_aff("all_resistance",8.0)])
	_register("manasurge","Mana Dalgası","ring","ring_1",8,[_make_aff("max_mana",100.0),_make_aff("mana_regen",30.0,true),_make_aff("cast_speed",10.0,true)])
	_register("shadow_band","Gölge Halkası","ring","ring_1",10,[_make_aff("chaos_resistance",30.0),_make_aff("evasion",100.0),_make_aff("attack_dodge_chance",3.0)])
	# ─── SHIELDS / OFFHAND (3) ───
	_register("wall_of_dawn","Şafak Duvarı","offhand","offhand",10,[_make_aff("attack_block_chance",20.0),_make_aff("spell_block_chance",15.0),_make_aff("armour",200.0)])
	_register("skull_of_the_fallen","Düşmüşlerin Kafatası","offhand","offhand",12,[_make_aff("elemental_damage",25.0,true),_make_aff("max_energy_shield",100.0),_make_aff("chaos_resistance",20.0)])
	_register("amber_ward","Kehribar Koruyucu","offhand","offhand",8,[_make_aff("all_resistance",15.0),_make_aff("max_life",80.0),_make_aff("spell_block_chance",10.0)])

static func _register(item_id: String, display_name: String, type: String, slot: String, level: int, affixes: Array[Affix], wp_type: String = "") -> void:
	var item := ItemData.new()
	item.id = item_id
	item.display_name = display_name
	item.item_type = type
	item.equip_slot = slot
	if not wp_type.is_empty():
		item.weapon_type = wp_type
	item.rarity = "unique"
	item.required_level = level
	item.affixes = affixes
	_ids.append(item_id)
	_items[item_id] = item
