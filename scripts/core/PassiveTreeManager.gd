extends Node
class_name PassiveTreeManager
## @deprecated Bu sınıf artık kullanılmıyor. SkillTreeUI (YETENEKLER tab) pasif ağacı yönetiyor.
## Manages passive skill unlocks and applies bonuses to CharacterStats.

const TREE := [
	{"id": "start", "name": "Başlangıç", "row": 4, "col": 4, "connects": ["life_1", "mana_1", "dmg_1"], "bonus": {}},
	{"id": "life_1", "name": "Can +20", "row": 3, "col": 4, "connects": ["life_2"], "bonus": {"base_life": 20.0}},
	{"id": "life_2", "name": "Can +30", "row": 2, "col": 4, "connects": ["life_3"], "bonus": {"base_life": 30.0}},
	{"id": "life_3", "name": "Can Rejene.", "row": 1, "col": 4, "connects": [], "bonus": {"life_regen_percent": 2.0}},
	{"id": "mana_1", "name": "Mana +20", "row": 4, "col": 5, "connects": ["mana_2"], "bonus": {"base_mana": 20.0}},
	{"id": "mana_2", "name": "Mana +30", "row": 4, "col": 6, "connects": ["mana_3"], "bonus": {"base_mana": 30.0}},
	{"id": "mana_3", "name": "Mana Rejene.", "row": 4, "col": 7, "connects": [], "bonus": {"mana_regen_percent": 20.0}},
	{"id": "dmg_1", "name": "Hasar +%10", "row": 4, "col": 3, "connects": ["dmg_2"], "bonus": {"damage_percent": 10.0}},
	{"id": "dmg_2", "name": "Hasar +%15", "row": 4, "col": 2, "connects": ["dmg_3"], "bonus": {"damage_percent": 15.0}},
	{"id": "dmg_3", "name": "Krit +%5", "row": 4, "col": 1, "connects": [], "bonus": {"critical_chance": 5.0}},
	{"id": "armour_1", "name": "Zırh +%20", "row": 5, "col": 5, "connects": ["armour_2"], "bonus": {"armour_percent": 20.0}},
	{"id": "armour_2", "name": "Zırh +%30", "row": 5, "col": 6, "connects": [], "bonus": {"armour_percent": 30.0}},
	{"id": "evasion_1", "name": "Kaçınma +%20", "row": 5, "col": 3, "connects": ["evasion_2"], "bonus": {"evasion_percent": 20.0}},
	{"id": "evasion_2", "name": "Kaçınma +%30", "row": 5, "col": 2, "connects": [], "bonus": {"evasion_percent": 30.0}},
	{"id": "res_fire", "name": "Ateş Direnci", "row": 5, "col": 7, "connects": [], "bonus": {"base_fire_resistance": 15.0}},
	{"id": "res_cold", "name": "Soğuk Direnci", "row": 6, "col": 4, "connects": [], "bonus": {"base_cold_resistance": 15.0}},
	{"id": "res_light", "name": "Yıld. Direnci", "row": 6, "col": 3, "connects": [], "bonus": {"base_lightning_resistance": 15.0}},
	{"id": "speed_1", "name": "Hız +%10", "row": 3, "col": 3, "connects": [], "bonus": {"movement_speed": 0.1}},
	{"id": "block_1", "name": "Blok +%5", "row": 6, "col": 6, "connects": [], "bonus": {"attack_block_chance": 5.0}},
	{"id": "acc_1", "name": "İsabet +50", "row": 6, "col": 2, "connects": [], "bonus": {"base_accuracy": 50.0}},
]

static func get_tree_data() -> Array:
	return TREE

signal tree_changed(unlocked: Array)

var unlocked_nodes: Array[String] = ["start"]
var _stats_ref: CharacterStats = null

func set_stats_ref(s: CharacterStats) -> void:
	_stats_ref = s

func get_available_nodes() -> Array:
	var available: Array = []
	for node in TREE:
		if node.id in unlocked_nodes:
			continue
		for c in node.connects:
			if c in unlocked_nodes:
				available.append(node)
				break
	return available

func unlock_node(node_id: String) -> void:
	if node_id in unlocked_nodes:
		return
	var node: Dictionary = _get_node(node_id)
	if node.is_empty():
		return
	var can_unlock := false
	for existing_id in unlocked_nodes:
		var existing: Dictionary = _get_node(existing_id)
		if node_id in existing.connects:
			can_unlock = true
			break
		if existing_id in node.connects:
			can_unlock = true
			break
	if not can_unlock:
		return
	unlocked_nodes.append(node_id)
	_apply_bonus(node)
	tree_changed.emit(unlocked_nodes)

func _apply_bonus(node: Dictionary) -> void:
	if not _stats_ref or node.bonus.is_empty():
		return
	for key in node.bonus:
		var val: float = node.bonus[key]
		# Use set() with string property name
		_stats_ref.set(key, _stats_ref.get(key) + val)
	_stats_ref.recalculate()

func _get_node(node_id: String) -> Dictionary:
	for n in TREE:
		if n.id == node_id:
			return n
	return {}

func is_node_unlocked(node_id: String) -> bool:
	return node_id in unlocked_nodes
