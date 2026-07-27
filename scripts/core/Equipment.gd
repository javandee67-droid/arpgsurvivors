extends Node
class_name Equipment
## Ekipman slotlarını tutar. Player'a "Equipment" adıyla Node olarak ekle.
## CharacterStats bu node'a abone olup ekipman her değiştiğinde
## statları otomatik yeniden hesaplar.

signal equipment_changed

enum Slot {
	WEAPON, OFFHAND, HELMET, BODY_ARMOUR, GLOVES, BOOTS, BELT, AMULET, RING_1, RING_2
}

var slots: Dictionary = {}

func _ready() -> void:
	for s in Slot.values():
		slots[s] = null

## Bir slota item takar, o slotta zaten item varsa onu geri döndürür
## (Inventory bu döneni tekrar envantere ekler).
func equip(slot: int, item: ItemData) -> ItemData:
	var previous = slots.get(slot)
	slots[slot] = item
	equipment_changed.emit()
	return previous

func unequip(slot: int) -> ItemData:
	var item = slots.get(slot)
	slots[slot] = null
	equipment_changed.emit()
	return item

func get_equipped_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in slots.values():
		if item:
			result.append(item)
	return result

func get_item_in_slot(slot: int) -> ItemData:
	return slots.get(slot)

## ItemData.equip_slot (string) ile enum arası çeviri.
func slot_name_to_enum(slot_name: String) -> int:
	match slot_name:
		"weapon":
			return Slot.WEAPON
		"offhand":
			return Slot.OFFHAND
		"helmet":
			return Slot.HELMET
		"body_armour":
			return Slot.BODY_ARMOUR
		"gloves":
			return Slot.GLOVES
		"boots":
			return Slot.BOOTS
		"belt":
			return Slot.BELT
		"amulet":
			return Slot.AMULET
		"ring_1":
			return Slot.RING_1
		"ring_2":
			return Slot.RING_2
	return -1
