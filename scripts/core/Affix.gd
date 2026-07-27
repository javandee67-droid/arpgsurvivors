extends Resource
class_name Affix
## Bir item'ın taşıdığı tekil özellik. Renkli ve okunabilir görüntüleme.

## Stat adlarını Türkçe/güzel isimlere çevir
## NOT: Bu isimler zaten tek başına anlamlı, "%" işaretini kod ekliyor
const STAT_NAMES := {
	"max_life": "Maksimum Can",
	"max_life_percent": "Maksimum Can",
	"max_mana": "Maksimum Mana",
	"max_mana_percent": "Maksimum Mana",
	"max_energy_shield": "Maksimum Enerji Kalkanı",
	"max_energy_shield_percent": "Maksimum Enerji Kalkanı",
	"armour": "Zırh",
	"armour_percent": "Zırh",
	"evasion": "Kaçınma",
	"evasion_percent": "Kaçınma",
	"accuracy": "İsabet",
	"fire_resistance": "Ateş Direnci",
	"cold_resistance": "Soğuk Direnci",
	"lightning_resistance": "Yıldırım Direnci",
	"chaos_resistance": "Kaos Direnci",
	"physical_damage": "Fiziksel Hasar",
	"physical_damage_percent": "Fiziksel Hasar Artışı",
	"elemental_damage": "Element Hasarı",
	"cold_damage": "Soğuk Hasarı",
	"fire_damage": "Ateş Hasarı",
	"lightning_damage": "Yıldırım Hasarı",
	"chaos_damage": "Kaos Hasarı",
	"damage_over_time": "Zamanla Hasar",
	"critical_chance": "Kritik Vuruş Şansı",
	"critical_multiplier": "Kritik Vuruş Çarpanı",
	"attack_speed": "Saldırı Hızı",
	"cast_speed": "Büyü Hızı",
	"movement_speed": "Hareket Hızı",
	"life_regen": "Can Yenilenmesi",
	"mana_regen": "Mana Yenilenmesi",
	"life_leech": "Can Çalma",
	"mana_leech": "Mana Çalma",
	"attack_block_chance": "Saldırı Blok Şansı",
	"spell_block_chance": "Büyü Blok Şansı",
	"attack_dodge_chance": "Kaçınma (Evasion)",  # _collect_affixes'te evasion'a eklenir
	"item_rarity": "Eşya Nadirliği",
	"item_quantity": "Eşya Miktarı",
	"all_resistance": "Tüm Dirençler",
	"projectile_damage": "Mermi Hasarı",
	"area_damage": "Alan Hasarı",
	# "critical_chance_spells" kaldirildi
	"energy_shield_regen": "Enerji Kalkanı Yenilenmesi",
	# spell_dodge_chance removed - spells can't be dodged
	"life_gain_on_hit": "Vuruş Başına Can",
	"base_life": "Temel Can",
	"base_mana": "Temel Mana",
	"strength": "Güç",
	"dexterity": "Çeviklik",
	"intelligence": "Zeka",
	"life_on_kill": "Öldürmede Can",
	"mana_on_kill": "Öldürmede Mana",
	"cooldown_recovery": "Bekleme Süresi Hızı",
	# "flask_effect" kaldirildi
	"ailment_effect": "Ailment Etkisi",
	"block_chance": "Blok Şansı",
	"base_accuracy": "Temel İsabet",
	"energy_shield": "Enerji Kalkanı",
	"adds_physical_damage": "Fiziksel Hasar Ekler",
	"adds_fire_damage": "Ateş Hasarı Ekler",
	"adds_cold_damage": "Soğuk Hasarı Ekler",
	"adds_lightning_damage": "Yıldırım Hasarı Ekler",
	"adds_chaos_damage": "Kaos Hasarı Ekler",
	"base_energy_shield": "Temel Enerji Kalkanı",
	"es_regen_per_second": "Enerji Kalkanı/s",
	"spell_damage": "Büyü Hasarı",
	# "spell_critical_chance" kaldirildi
	# Gain-as-Extra modifier'ları (pasif ağacından)
	"gain_physical_as_fire": "Fiziksel→Ateş Ekstra",
	"gain_physical_as_cold": "Fiziksel→Buz Ekstra",
	"gain_physical_as_lightning": "Fiziksel→Yıldırım Ekstra",
	"gain_physical_as_chaos": "Fiziksel→Kaos Ekstra",
	"gain_elemental_as_fire": "Element→Ateş Ekstra",
	"gain_elemental_as_cold": "Element→Buz Ekstra",
	"gain_elemental_as_lightning": "Element→Yıldırım Ekstra",
	"gain_generic_as_fire": "Hasar→Ateş Ekstra",
	"gain_generic_as_cold": "Hasar→Buz Ekstra",
	"gain_generic_as_lightning": "Hasar→Yıldırım Ekstra",
	"gain_generic_as_chaos": "Hasar→Kaos Ekstra",
	"gain_generic_as_physical": "Hasar→Fiziksel Ekstra",
	"gain_lightning_as_cold": "Yıldırım→Buz Ekstra",
	"gain_cold_as_lightning": "Buz→Yıldırım Ekstra",
	"gain_cold_as_fire": "Buz→Ateş Ekstra",
	"gain_as_extra_random": "Rastgele Element Ekstra",
}

@export var stat_name: String = ""
@export var value: float = 0.0
@export var is_percentage: bool = false
@export var tier: int = 1  ## 1-99 arası; T1=en iyi, T99=en kötü
@export var is_passive: bool = false  ## Pasif ağacından gelen affix
@export var raw_text: String = ""  ## Ham metin (özel pasif node'lar için, stat_name+value yerine direkt gösterilir)

func _format_value(val: float) -> String:
	# Kk ondalıklı değerleri düzgün göster
	if val == int(val):
		return str(int(val))
	elif abs(val) < 10.0:
		# 1 ondalık (life_leech 0.6 gibi)
		return "%.1f" % val
	else:
		return str(int(val))

func get_display_text() -> String:
	if not raw_text.is_empty():
		return raw_text + " [T%d]" % tier
	var sign_str: String = "+" if value >= 0 else ""
	var display_name: String = STAT_NAMES.get(stat_name, stat_name)
	var val_str: String = _format_value(value)
	if stat_name.begins_with("adds_"):
		# "Adds X-Y Fire Damage" formatı (range gösterimi)
		var range_min: String = _format_value(floorf(value * 0.6))
		var range_max: String = _format_value(ceilf(value * 1.4))
		return "%s%s-%s %s [T%d]" % [sign_str, range_min, range_max, display_name, tier]
	if is_percentage:
		return "%s%s%% %s [T%d]" % [sign_str, val_str, display_name, tier]
	return "%s%s %s [T%d]" % [sign_str, val_str, display_name, tier]

## BBCode renkli formatlı görüntüleme (GameUI tooltip'leri için)
func get_colored_text() -> String:
	if not raw_text.is_empty():
		var prefix: String = "⭐ " if is_passive else ""
		var tier_color: String = _tier_color()
		return "[font_size=13][color=#a0d0ff]%s%s[/color]  [color=%s][b]T%d[/b][/color][/font_size]" % [prefix, raw_text, tier_color, tier]
	var sign_str: String = "+" if value >= 0 else ""
	var display_name: String = STAT_NAMES.get(stat_name, stat_name)
	var val_str: String = _format_value(value)
	var color: String = "#a0d0ff"  # açık mavi (soğuk statlar)
	# Renk kodları: can=yeşil, mana=mavi, hasar=kırmızı, direnç=turuncu
	if stat_name.contains("life") or stat_name.contains("health"):
		color = "#6fdc8c"  # yeşil
	elif stat_name.contains("mana"):
		color = "#5b9cff"  # mavi
	elif stat_name.contains("damage") or stat_name.contains("attack"):
		color = "#ff7b6b"  # kırmızı
	elif stat_name.contains("resistance"):
		color = "#ffb347"  # turuncu
	elif stat_name.contains("speed") or stat_name.contains("movement"):
		color = "#b0d060"  # sarımsı yeşil

	var tier_color: String = _tier_color()
	
	var prefix: String = "⭐ " if is_passive else ""
	
	var affix_text: String = ""
	if stat_name.begins_with("adds_"):
		var range_min: String = _format_value(floorf(value * 0.6))
		var range_max: String = _format_value(ceilf(value * 1.4))
		affix_text = "%s%s%s-%s %s" % [prefix, sign_str, range_min, range_max, display_name]
	elif is_percentage:
		affix_text = "%s%s%s%% %s" % [prefix, sign_str, val_str, display_name]
	else:
		affix_text = "%s%s%s %s" % [prefix, sign_str, val_str, display_name]
	
	return "[font_size=15][color=%s][b]%s[/b][/color]  [color=%s][font_size=12]T%d[/font_size][/color][/font_size]" % [color, affix_text, tier_color, tier]

## Tier değerine göre renk (T1-T99): T1=altın/kırmızı, T99=çok koyu gri
func _tier_color() -> String:
	if tier <= 5:
		return "#ff4444"    # T1-5: Kırmızı (en iyi, ultra rare)
	elif tier <= 10:
		return "#ff8800"    # T6-10: Turuncu (çok iyi)
	elif tier <= 20:
		return "#ddaa33"    # T11-20: Altın
	elif tier <= 40:
		return "#aabbcc"    # T21-40: Gümüş
	elif tier <= 60:
		return "#888888"    # T41-60: Gri
	elif tier <= 80:
		return "#555555"    # T61-80: Koyu gri
	else:
		return "#333333"    # T81-99: Çok koyu gri (en kötü)
