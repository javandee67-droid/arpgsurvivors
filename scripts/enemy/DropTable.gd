extends Node
class_name DropTable
## Düşman öldüğünde item düşürme mantığı. ItemGenerator ile prosedürel
## olarak rastgele affix'li item üretir. Inspector'dan possible_base_items
## dizisine AFFIX'SİZ taban ItemData'lar sürükle (README adım 10'a bak).

@export var possible_base_items: Array[ItemData] = []
@export var drop_chance: float = 0.35

## Bu haritanın/bölgenin zorluk tier'ı. 1 = zayıf, 10 = üst düzey.
## İleride MapGenerator/harita seçim ekranından otomatik ayarlanabilir.
@export_range(1, 10) var tier: int = 1

## Currency düşme şansı (ana drop chance'tan bağımsız ek şans)
# Currency artik orsten elde edilir, dusmandan dusmez

var _cached_player: Node = null

func _get_player() -> Node:
	if not is_instance_valid(_cached_player):
		_cached_player = get_tree().get_first_node_in_group("player")
	return _cached_player

func try_drop(pos: Vector2) -> void:
	# Player'ın item_rarity / item_quantity stat'larını kontrol et
	var rarity_boost: float = 0.0
	var quantity_boost: float = 0.0
	var player := _get_player()
	if player:
		var stats: CharacterStats = player.get_node_or_null("CharacterStats")
		if stats:
			rarity_boost = stats.item_rarity
			quantity_boost = stats.item_quantity
	
	# Item quantity drop şansını artırır
	var effective_chance: float = drop_chance * (1.0 + quantity_boost / 100.0)
	if randf() > effective_chance:
		return
	if possible_base_items.is_empty():
		return

	var base: ItemData = possible_base_items[randi() % possible_base_items.size()]
	var generated: ItemData = ItemGenerator.generate_item(base, tier, rarity_boost)

	# Yere düşen item oluştur
	var world := get_tree().current_scene
	if world and world.has_method("_spawn_ground_item"):
		world._spawn_ground_item(generated, pos)
	else:
		# Fallback: direkt envantere ekle
		if player and player.inventory:
			player.inventory.add_item(generated)
	
	# Currency düşüşü kaldırıldı: orblar sadece örs'te item parçalayarak elde edilir
