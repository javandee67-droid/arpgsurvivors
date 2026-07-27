extends Node
class_name SaveLoadSystem
## Game Save/Load System
## Saves and loads game state including player stats, inventory, skills, and progress.

const SAVE_FILE := "user://savegame.save"

static func save_game(player: Node, game_state: Dictionary) -> bool:
	"""Save current game state to file"""
	var save_data := {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"game_state": game_state,
		"player": _serialize_player(player),
		"skills": _serialize_skills(player),
		"inventory": _serialize_inventory(player),
		"essence": _serialize_essence(player),
		"passive_tree": _serialize_passive_tree(player),
		"stats": _serialize_stats(player),
	}
	
	var save_file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if save_file == null:
		push_error("Cannot save game: " + str(FileAccess.get_open_error()))
		return false
	
	var json_str := JSON.stringify(save_data, "\t")
	save_file.store_line(json_str)
	save_file.close()
	print("Game saved!")
	return true

static func load_game() -> Dictionary:
	"""Load game state from file"""
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found")
		return {}
	
	var save_file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if save_file == null:
		push_error("Cannot load save: " + str(FileAccess.get_open_error()))
		return {}
	
	var json_str := save_file.get_as_text()
	save_file.close()
	
	var json := JSON.new()
	if json.parse(json_str) != OK:
		push_error("Failed to parse save data")
		return {}
	
	var data: Dictionary = json.data
	print("Game loaded! Timestamp: ", data.get("timestamp", "unknown"))
	return data

static func has_save() -> bool:
	"""Check if a save file exists"""
	return FileAccess.file_exists(SAVE_FILE)

static func delete_save() -> bool:
	"""Delete the save file"""
	if not has_save():
		return true
	DirAccess.remove_absolute(SAVE_FILE)
	return true

static func get_save_info() -> Dictionary:
	"""Get basic info about the save file without loading full data"""
	if not has_save():
		return {}
	
	var data := load_game()
	return {
		"timestamp": data.get("timestamp", ""),
		"level": data.get("player", {}).get("level", 0),
		"kills": data.get("game_state", {}).get("kill_count", 0),
		"game_time": data.get("game_state", {}).get("game_time", 0.0),
	}

static func _serialize_player(player: Node) -> Dictionary:
	"""Serialize player data"""
	var data := {
		"level": player.level_system.level if player.has("level_system") else 1,
		"xp": player.level_system.xp if player.has("level_system") else 0,
		"xp_to_next": player.level_system.xp_to_next_level if player.has("level_system") else 100,
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y,
		},
		"health": player.health.current if player.has("health") else 100,
		"max_health": player.health.max_value if player.has("health") else 100,
	}
	
	# Class info
	if player.has("character_class"):
		data["character_class"] = player.character_class
	
	return data

static func _serialize_skills(player: Node) -> Dictionary:
	"""Serialize equipped skills and hotbar"""
	var data := {
		"hotbar": [],
		"skill_setups": {},
		"skill_levels": {},
	}
	
	# Hotbar
	if player.has("hotbar"):
		data["hotbar"] = Array(player.hotbar)
	
	# Skill setups
	if player.has("skill_setups"):
		for key in player.skill_setups:
			var setup = player.skill_setups[key]
			if setup and setup is Dictionary:
				data["skill_setups"][key] = {
					"skill_path": key,
					"supports": setup.get("supports", []),
				}
	
	# Skill levels
	if player.has("_skill_levels"):
		data["skill_levels"] = player._skill_levels.duplicate(true)
	
	return data

static func _serialize_inventory(player: Node) -> Array:
	"""Serialize inventory items"""
	var items := []
	
	if player.has("inventory"):
		var inv = player.get_node("Inventory")
		for item in inv.items:
			if item:
				items.append({
					"id": item.id,
					"name": item.name,
					"rarity": item.rarity,
					"stack_count": item.stack_count if item.has("stack_count") else 1,
				})
	
	return items

static func _serialize_essence(player: Node) -> Dictionary:
	"""Serialize essence inventory"""
	var data := {"essences": {}}
	
	if player.has("EssenceInventory"):
		var ei = player.get_node("EssenceInventory")
		if ei.has("essences"):
			for type in ei.essences:
				data["essences"][type] = ei.essences[type]
	
	return data

static func _serialize_passive_tree(player: Node) -> Dictionary:
	"""Serialize passive tree nodes"""
	var data := {"owned_nodes": []}
	
	if player.has("_passive_nodes_owned"):
		data["owned_nodes"] = Array(player._passive_nodes_owned)
	
	return data

static func _serialize_stats(player: Node) -> Dictionary:
	"""Serialize character stats"""
	var data := {}
	
	if player.has("stats"):
		var stats = player.stats
		var stat_keys := [
			"strength", "dexterity", "intelligence", "vitality",
			"stat_points", "passive_points",
			"max_life", "armour", "fire_resistance", "cold_resistance", "lightning_resistance",
			"physical_damage_increased", "fire_damage_increased", "cold_damage_increased", 
			"lightning_damage_increased", "elemental_damage_increased",
			"attack_speed_increased", "cast_speed_increased", "movement_speed_increased",
			"pickup_radius", "gold_find", "xp_bonus",
			"critical_chance", "critical_multiplier",
			"life_regen", "mana_regen",
		]
		for key in stat_keys:
			if stats.has(key):
				data[key] = stats.get(key)
	
	return data

static func apply_save_data(player: Node, data: Dictionary) -> void:
	"""Apply loaded save data to player"""
	if data.is_empty():
		return
	
	# Apply player data
	var player_data := data.get("player", {})
	if not player_data.is_empty():
		if player.has("level_system") and player_data.has("level"):
			player.level_system.level = player_data.get("level", 1)
			player.level_system.xp = player_data.get("xp", 0)
			player.level_system.xp_to_next_level = player_data.get("xp_to_next", 100)
		
		if player.has("health") and player_data.has("health"):
			player.health.current = player_data.get("health", 100)
		
		if player_data.has("character_class"):
			player.set_class(player_data.get("character_class", "warrior"))
	
	# Apply skills
	var skills_data := data.get("skills", {})
	if not skills_data.is_empty():
		if skills_data.has("hotbar") and player.has("hotbar"):
			for i in range(min(skills_data["hotbar"].size(), player.hotbar.size())):
				player.hotbar[i] = skills_data["hotbar"][i]
		
		if skills_data.has("skill_levels") and player.has("_skill_levels"):
			player._skill_levels = skills_data["skill_levels"].duplicate(true)
	
	# Apply stats
	var stats_data := data.get("stats", {})
	if not stats_data.is_empty() and player.has("stats"):
		for key in stats_data:
			if key in [
				"strength", "dexterity", "intelligence", "vitality",
				"stat_points", "passive_points",
				"max_life", "armour", "fire_resistance", "cold_resistance", "lightning_resistance",
				"physical_damage_increased", "fire_damage_increased", "cold_damage_increased", 
				"lightning_damage_increased", "elemental_damage_increased",
				"attack_speed_increased", "cast_speed_increased", "movement_speed_increased",
				"pickup_radius", "gold_find", "xp_bonus",
				"critical_chance", "critical_multiplier",
				"life_regen", "mana_regen",
			]:
				player.stats.set(key, stats_data[key])
		
		player.stats.recalculate()
	
	print("Save data applied to player")
