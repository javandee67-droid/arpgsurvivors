extends Node
class_name PersistentUpgrades
## Persistent Upgrade System - Gold-based permanent upgrades.
## These upgrades persist across game sessions and are saved to a file.
## Used to give players a sense of progression and meta-game.

const SAVE_FILE := "user://persistent_upgrades.save"
const UPGRADE_FILE := "user://upgrade_data.save"

## Upgrade categories
enum Category {
	GENERAL,
	OFFENSE,
	DEFENSE,
	UTILITY,
}

## Upgrade definitions
const UPGRADES := {
	# === GENERAL ===
	"starting_gold": {
		"name": "Baslangic Altini",
		"description": "Yeni oyuna baslarken +{value} altin ile basla",
		"category": Category.GENERAL,
		"base_cost": 100,
		"cost_scale": 1.8,
		"max_level": 20,
		"effect": "starting_gold_bonus",
		"value_per_level": 50,
		"icon": "✦",
	},
	"starting_essence": {
		"name": "Baslangic Özü",
		"description": "Yeni oyuna baslarken +{value} öz ile basla",
		"category": Category.GENERAL,
		"base_cost": 150,
		"cost_scale": 2.0,
		"max_level": 10,
		"effect": "starting_essence_bonus",
		"value_per_level": 5,
		"icon": "✧",
	},
	
	# === OFFENSE ===
	"damage_boost": {
		"name": "Hasar Gücü",
		"description": "Tüm skill hasari +{value}%",
		"category": Category.OFFENSE,
		"base_cost": 200,
		"cost_scale": 2.2,
		"max_level": 25,
		"effect": "damage_multiplier",
		"value_per_level": 2.0,
		"icon": "⚔️",
	},
	"critical_chance": {
		"name": "Keskin Göz",
		"description": "Kritik vurus sansi +{value}%",
		"category": Category.OFFENSE,
		"base_cost": 175,
		"cost_scale": 1.9,
		"max_level": 15,
		"effect": "critical_chance_bonus",
		"value_per_level": 1.0,
		"icon": "🎯",
	},
	"critical_multiplier": {
		"name": "Savurgan Hasar",
		"description": "Kritik hasar carpani +{value}%",
		"category": Category.OFFENSE,
		"base_cost": 250,
		"cost_scale": 2.0,
		"max_level": 20,
		"effect": "critical_multiplier_bonus",
		"value_per_level": 5.0,
		"icon": "💥",
	},
	"pickup_radius": {
		"name": "Altin Toplayici",
		"description": "Pickup mesafesi +{value}",
		"category": Category.UTILITY,
		"base_cost": 80,
		"cost_scale": 1.5,
		"max_level": 30,
		"effect": "pickup_radius_bonus",
		"value_per_level": 15.0,
		"icon": "🧲",
	},
	"xp_bonus": {
		"name": "Bilgelik",
		"description": "Tecrübe kazanci +{value}%",
		"category": Category.GENERAL,
		"base_cost": 150,
		"cost_scale": 1.7,
		"max_level": 20,
		"effect": "xp_multiplier",
		"value_per_level": 3.0,
		"icon": "⭐",
	},
	"gold_find": {
		"name": "Refik",
		"description": "Altin düsme sansi +{value}%",
		"category": Category.UTILITY,
		"base_cost": 120,
		"cost_scale": 1.6,
		"max_level": 25,
		"effect": "gold_find_bonus",
		"value_per_level": 2.0,
		"icon": "💰",
	},
	
	# === DEFENSE ===
	"max_life": {
		"name": "Dayaniklilik",
		"description": "Maksimum can +{value}",
		"category": Category.DEFENSE,
		"base_cost": 100,
		"cost_scale": 1.6,
		"max_level": 40,
		"effect": "max_life_bonus",
		"value_per_level": 25.0,
		"icon": "❤️",
	},
	"life_regen": {
		"name": "Iyilesme",
		"description": "Can yenilenmesi +{value}/saniye",
		"category": Category.DEFENSE,
		"base_cost": 130,
		"cost_scale": 1.8,
		"max_level": 25,
		"effect": "life_regen_bonus",
		"value_per_level": 0.5,
		"icon": "💚",
	},
	"armor_boost": {
		"name": "Sert Deri",
		"description": "Zirh +{value}",
		"category": Category.DEFENSE,
		"base_cost": 90,
		"cost_scale": 1.5,
		"max_level": 35,
		"effect": "armor_bonus",
		"value_per_level": 15.0,
		"icon": "🛡️",
	},
	"movement_speed": {
		"name": "Ceviklik",
		"description": "Hareket hizi +{value}%",
		"category": Category.UTILITY,
		"base_cost": 110,
		"cost_scale": 1.7,
		"max_level": 20,
		"effect": "movement_speed_bonus",
		"value_per_level": 1.5,
		"icon": "⚡",
	},
	
	# === UTILITY ===
	"cooldown_reduction": {
		"name": "Hizli El",
		"description": "Skill bekleme suresi -{value}%",
		"category": Category.UTILITY,
		"base_cost": 200,
		"cost_scale": 2.0,
		"max_level": 15,
		"effect": "cooldown_reduction_bonus",
		"value_per_level": 2.0,
		"icon": "⏱️",
	},
	"skill_duration": {
		"name": "Uzun Süren",
		"description": "Buff/skill süresi +{value}%",
		"category": Category.UTILITY,
		"base_cost": 140,
		"cost_scale": 1.8,
		"max_level": 20,
		"effect": "skill_duration_bonus",
		"value_per_level": 3.0,
		"icon": "⏳",
	},
	"item_rarity": {
		"name": "Shaper's Eye",
		"description": "Eşya nadirligi +{value}%",
		"category": Category.UTILITY,
		"base_cost": 180,
		"cost_scale": 1.9,
		"max_level": 20,
		"effect": "item_rarity_bonus",
		"value_per_level": 3.0,
		"icon": "💎",
	},
}

## Save data structure
var upgrade_levels: Dictionary = {}  # {upgrade_id: level}
var total_gold_earned: float = 0.0
var total_kills: int = 0
var games_played: int = 0

## Singleton pattern
static var _instance: PersistentUpgrades = null
static func get_instance() -> PersistentUpgrades:
	if _instance == null:
		_instance = PersistentUpgrades.new()
		_instance.load_data()
	return _instance

func _init() -> void:
	pass  # Don't auto-save in _init

## Get the current level of an upgrade
func get_level(upgrade_id: String) -> int:
	return upgrade_levels.get(upgrade_id, 0)

## Get the cost for the next level
func get_upgrade_cost(upgrade_id: String) -> int:
	var current_level: int = get_level(upgrade_id)
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	if def.is_empty():
		return -1  # Invalid upgrade
	if current_level >= def.get("max_level", 1):
		return -1  # Max level
	var base_cost: float = def.get("base_cost", 100)
	var cost_scale: float = def.get("cost_scale", 1.5)
	return int(base_cost * pow(cost_scale, current_level))

## Get the current value of an upgrade
func get_value(upgrade_id: String) -> float:
	var current_level: int = get_level(upgrade_id)
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	if def.is_empty():
		return 0.0
	return def.get("value_per_level", 1.0) * current_level

## Check if an upgrade can be purchased
func can_purchase(upgrade_id: String, gold: float) -> bool:
	var cost: int = get_upgrade_cost(upgrade_id)
	if cost < 0:
		return false
	return gold >= float(cost)

## Purchase an upgrade (returns true if successful)
func purchase_upgrade(upgrade_id: String, gold: float) -> bool:
	if not can_purchase(upgrade_id, gold):
		return false
	var cost: int = get_upgrade_cost(upgrade_id)
	if cost < 0:
		return false
	upgrade_levels[upgrade_id] = get_level(upgrade_id) + 1
	save_data()
	return true

## Get all bonuses as a dictionary (for applying to new games)
func get_all_bonuses() -> Dictionary:
	var bonuses: Dictionary = {}
	for upgrade_id in UPGRADES.keys():
		var def: Dictionary = UPGRADES[upgrade_id]
		var effect: String = def.get("effect", "")
		var value: float = get_value(upgrade_id)
		if not effect.is_empty() and value > 0:
			bonuses[effect] = value
	return bonuses

## Calculate starting gold for a new game
func get_starting_gold() -> int:
	var bonus: float = get_value("starting_gold")
	return int(100 + bonus)  # Base 100 gold

## Calculate starting essence for a new game
func get_starting_essence() -> int:
	var bonus: float = get_value("starting_essence")
	return int(bonus)

## Add earned gold (for stats tracking)
func add_gold(amount: float) -> void:
	total_gold_earned += amount
	save_data()

## Add kill (for stats tracking)
func add_kill() -> void:
	total_kills += 1
	save_data()

## Increment games played
func increment_games_played() -> void:
	games_played += 1
	save_data()

## Get total gold available for spending (lifetime earned - this would need persistence)
func get_lifetime_gold() -> float:
	return total_gold_earned

## Save data to file
func save_data() -> void:
	var save_file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file == null:
		push_error("Cannot save persistent upgrades: " + str(FileAccess.get_open_error()))
		return
	
	var save_data := {
		"upgrade_levels": upgrade_levels,
		"total_gold_earned": total_gold_earned,
		"total_kills": total_kills,
		"games_played": games_played,
	}
	var json_str := JSON.stringify(save_data, "\t")
	save_file.store_line(json_str)
	save_file.close()
	print("Persistent upgrades saved!")

## Load data from file
func load_data() -> void:
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found, starting fresh")
		return
	
	var save_file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if save_file == null:
		push_error("Cannot load persistent upgrades: " + str(FileAccess.get_open_error()))
		return
	
	var json_str := save_file.get_as_text()
	save_file.close()
	
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("Failed to parse save data")
		return
	
	var data: Dictionary = json.data
	if data.is_empty():
		return
	
	upgrade_levels = data.get("upgrade_levels", {})
	total_gold_earned = data.get("total_gold_earned", 0.0)
	total_kills = data.get("total_kills", 0)
	games_played = data.get("games_played", 0)
	print("Persistent upgrades loaded! Games played: ", games_played)

## Reset all upgrades (for testing)
func reset_all() -> void:
	upgrade_levels.clear()
	total_gold_earned = 0.0
	total_kills = 0
	games_played = 0
	save_data()

## Get formatted description for an upgrade
func get_upgrade_description(upgrade_id: String) -> String:
	var def: Dictionary = UPGRADES.get(upgrade_id, {})
	if def.is_empty():
		return ""
	
	var current_level: int = get_level(upgrade_id)
	var max_level: int = def.get("max_level", 1)
	var value_per_level: float = def.get("value_per_level", 1.0)
	var current_value: float = value_per_level * current_level
	
	var desc_template: String = def.get("description", "")
	var desc: String = desc_template.format({"value": "%.1f" % current_value})
	
	if current_level >= max_level:
		desc += " [MAX]"
	else:
		var next_value: float = value_per_level * (current_level + 1)
		desc += "\nSonraki: " + desc_template.format({"value": "%.1f" % next_value})
	
	return desc
