extends Node
class_name SimplifiedPassiveTree
## Basitleştirilmiş pasif ağaç sistemi - PoE2'nin 1000+ node'u yerine 50 özellik
## Kategorilere ayrılmış, her kategori farklı renk ve ikonla gösteriliyor

signal passive_points_changed(points: int)
signal passive_unlocked(node_id: String)

const PASSIVE_TREE_PATH := "res://data/passive_tree_simplified.json"
const MAX_PASSIVE_POINTS := 20  # Toplam kullanılabilecek puan

var tree_data: Dictionary = {}
var unlocked_nodes: Array[String] = []
var _passive_points: int = 0

func _ready() -> void:
	_load_tree_data()

func _load_tree_data() -> void:
	if not FileAccess.file_exists(PASSIVE_TREE_PATH):
		push_error("Passive tree data not found: " + PASSIVE_TREE_PATH)
		return
	
	var file := FileAccess.open(PASSIVE_TREE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to load passive tree: " + str(FileAccess.get_open_error()))
		return
	
	var json_text: String = file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		push_error("Failed to parse passive tree JSON: " + json.get_error_message())
		return
	tree_data = json.data as Dictionary

## Oyuncunun kalan pasif puanını döndürür
func get_remaining_points() -> int:
	return _passive_points

## Pasif puan ayarla
func set_passive_points(points: int) -> void:
	_passive_points = maxi(0, mini(points, MAX_PASSIVE_POINTS))
	passive_points_changed.emit(_passive_points)

## Belirli bir node'u açıp açamayacağını kontrol eder
func can_unlock_node(node_id: String) -> bool:
	if node_id in unlocked_nodes:
		return false
	
	if _passive_points <= 0:
		return false
	
	var node: Dictionary = _find_node(node_id)
	if node.is_empty():
		return false
	
	# Gereksinim kontrolü
	if node.has("requires"):
		var req_id: String = node["requires"]
		if req_id not in unlocked_nodes:
			return false
	
	return true

## Bir node'u açar
func unlock_node(node_id: String) -> bool:
	if not can_unlock_node(node_id):
		return false
	
	var node: Dictionary = _find_node(node_id)
	if node.is_empty():
		return false
	
	var cost: int = node.get("cost", 1) as int
	if _passive_points < cost:
		return false
	
	_passive_points -= cost
	unlocked_nodes.append(node_id)
	passive_points_changed.emit(_passive_points)
	passive_unlocked.emit(node_id)
	
	return true

## Node'u kapatır (puan iade edilmez)
func lock_node(node_id: String) -> void:
	if node_id in unlocked_nodes:
		unlocked_nodes.erase(node_id)

## Bir node'un bilgilerini döndürür
func get_node_info(node_id: String) -> Dictionary:
	return _find_node(node_id)

## Açılmış node'ların toplam etkilerini hesaplar
func get_total_modifiers() -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	
	for node_id in unlocked_nodes:
		var node: Dictionary = _find_node(node_id)
		if node.is_empty():
			continue
		
		if node.has("effects"):
			for effect in node["effects"]:
				modifiers.append(effect.duplicate())
	
	return modifiers

## Tüm kategorileri ve node'ları döndürür
func get_all_nodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	if not tree_data.has("categories"):
		return result
	
	for category in tree_data["categories"]:
		for node in category["nodes"]:
			var node_copy: Dictionary = node.duplicate()
			node_copy["category_id"] = category["id"]
			node_copy["category_name"] = category["name"]
			node_copy["category_color"] = category["color"]
			node_copy["is_unlocked"] = node_copy["id"] in unlocked_nodes
			node_copy["can_unlock"] = can_unlock_node(node_copy["id"])
			result.append(node_copy)
	
	return result

## Belirli bir kategorideki node'ları döndürür
func get_category_nodes(category_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	
	if not tree_data.has("categories"):
		return result
	
	for category in tree_data["categories"]:
		if category["id"] == category_id:
			for node in category["nodes"]:
				var node_copy: Dictionary = node.duplicate()
				node_copy["category_id"] = category["id"]
				node_copy["category_name"] = category["name"]
				node_copy["category_color"] = category["color"]
				node_copy["is_unlocked"] = node_copy["id"] in unlocked_nodes
				node_copy["can_unlock"] = can_unlock_node(node_copy["id"])
				result.append(node_copy)
			break
	
	return result

## İstatistik etkilerini formatlı string olarak döndürür
func get_stat_display(node_id: String) -> String:
	var node: Dictionary = _find_node(node_id)
	if node.is_empty():
		return ""
	
	var parts: Array[String] = []
	var effects: Array = node.get("effects", [])
	
	for effect in effects:
		var stat: String = effect.get("stat", "")
		var value: float = effect.get("value", 0.0)
		var eff_type: String = effect.get("type", "")
		
		var stat_names: Dictionary = {
			"all_damage": "Hasar",
			"physical_damage_increased": "Fiziksel Hasar",
			"fire_damage_increased": "Ateş Hasarı",
			"cold_damage_increased": "Buz Hasarı",
			"lightning_damage_increased": "Yıldırım Hasarı",
			"max_life": "Maks Can",
			"life_regen_per_second": "Can Yenilenme",
			"armour": "Zırh",
			"evasion": "Kaçınma",
			"all_resistance": "Direnç",
			"attack_speed": "Saldırı Hızı",
			"cast_speed": "Büyü Hızı",
			"movement_speed": "Hareket Hızı",
			"cooldown_recovery": "Bekleme Kısaltma",
			"critical_chance": "Kritik Şansı",
			"critical_multiplier": "Kritik Hasar",
			"accuracy": "İsabet",
			"max_mana": "Maks Mana",
			"mana_regen_per_second": "Mana Yenilenme",
			"pickup_radius": "Bulma Mesafesi",
			"gold_find": "Altın Bulma",
			"experience_gain": "Tecrübe Kazanma",
			"luck": "Şans",
			"chain_count": "Zincir",
			"extra_projectiles": "Ek Mermi",
			"area_of_effect": "Alan Etkisi"
		}
		
		var display_name: String = stat_names.get(stat, stat.replace("_", " ").capitalize())
		var prefix: String = "+" if value >= 0 else ""
		
		match eff_type:
			"flat":
				parts.append("%s%.0f %s" % [prefix, value, display_name])
			"increased":
				parts.append("%s%.0f%% %s" % [prefix, value, display_name])
			"more":
				parts.append("%s%.0f%% %s (More)" % [prefix, value, display_name])
	
	return ", ".join(parts)

## Node'u veri dosyasında bulur
func _find_node(node_id: String) -> Dictionary:
	if not tree_data.has("categories"):
		return {}
	
	for category in tree_data["categories"]:
		for node in category["nodes"]:
			if node.get("id") == node_id:
				return node.duplicate()
	
	return {}

## Oyuncunun açtığı toplam node sayısını döndürür
func get_unlocked_count() -> int:
	return unlocked_nodes.size()

## Tüm açılmış node'ların bir özetini döndürür
func get_summary() -> String:
	var lines: Array[String] = []
	
	if not tree_data.has("categories"):
		return "Pasif ağaç yüklenemedi."
	
	for category in tree_data["categories"]:
		var cat_nodes: Array = get_category_nodes(category["id"])
		var unlocked_in_cat: int = 0
		for node in cat_nodes:
			if node["id"] in unlocked_nodes:
				unlocked_in_cat += 1
		
		if unlocked_in_cat > 0:
			lines.append("%s [%d/%d]: %s" % [
				category["name"],
				unlocked_in_cat,
				cat_nodes.size(),
				_aggregate_category_stats(category["id"])
			])
	
	if lines.is_empty():
		return "Henüz pasif node açılmadı. (_passive_points) puan mevcut."
	
	return "\n".join(lines)

## Bir kategorinin istatistiklerini toplu olarak gösterir
func _aggregate_category_stats(category_id: String) -> String:
	var stats: Dictionary = {}
	
	for node_id in unlocked_nodes:
		var node: Dictionary = _find_node(node_id)
		if node.is_empty() or node.get("category_id") != category_id:
			continue
		
		for effect in node.get("effects", []):
			var stat: String = effect.get("stat", "")
			var value: float = effect.get("value", 0.0)
			var eff_type: String = effect.get("type", "")
			
			if eff_type == "flat":
				stats[stat] = stats.get(stat, 0.0) + value
			else:  # increased or more
				var existing: float = stats.get(stat, 0.0)
				stats[stat] = existing + value
	
	var stat_names: Dictionary = {
		"all_damage": "Hasar",
		"physical_damage_increased": "Fiz.Hasar",
		"fire_damage_increased": "Ateş",
		"cold_damage_increased": "Buz",
		"lightning_damage_increased": "Yıldırım",
		"max_life": "Can",
		"life_regen_per_second": "CanReg",
		"attack_speed": "SaldırıHızı",
		"cast_speed": "BüyüHızı",
		"movement_speed": "Hareket",
		"critical_chance": "Kritik",
		"critical_multiplier": "KritHasar"
	}
	
	var parts: Array[String] = []
	for stat in stats:
		var display: String = stat_names.get(stat, stat)
		var val: float = stats[stat]
		if val >= 100 or val <= -100:
			parts.append("%s:%.0f%%" % [display, val])
		else:
			parts.append("%s:%.0f" % [display, val])
	
	return ", ".join(parts) if not parts.is_empty() else "—"
