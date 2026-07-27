extends Node
class_name Inventory
## Basit envanter. Player sahnesine "Inventory" adıyla Node olarak ekle.

signal inventory_changed
signal item_added(item: ItemData)
signal item_removed(item: ItemData)

@export var max_slots: int = 32
var items: Array[ItemData] = []

## Oyuncunun statlarını tutar (requirement kontrolü için).
## Player._ready()'de set_player_stats() ile atanır.
var _player_stats: CharacterStats = null

## Oyuncunun seviyesi (level requirement kontrolü için).
var _player_level: int = 1

func set_player_stats(stats: CharacterStats) -> void:
	_player_stats = stats

func set_player_level(level: int) -> void:
	_player_level = level

func add_item(item: ItemData) -> bool:
	if not item:
		return false
	# Stackable item'lar: aynı id'ye sahip varsa stack_count'u artır
	if item.stackable and not item.id.is_empty():
		for existing in items:
			if existing and existing.stackable and existing.id == item.id:
				existing.stack_count += item.stack_count
				item_added.emit(existing)
				inventory_changed.emit()
				return true
	# Önce null slot var mı kontrol et — item kuşanınca items[idx]=null kalıyor
	var idx: int = items.find(null)
	if idx >= 0:
		items[idx] = item
	elif items.size() < max_slots:
		items.append(item)
	else:
		return false
	item_added.emit(item)
	inventory_changed.emit()
	return true

## Boolean: envanterde null slot var mı?
func _has_null_slot() -> bool:
	return items.has(null)

func remove_item(item: ItemData) -> void:
	if not item:
		return
	# Stackable item: stack_count'u azalt, sıfırsa kaldır
	if item.stackable and item.stack_count > 1:
		item.stack_count -= 1
		item_removed.emit(item)
		inventory_changed.emit()
		return
	if items.has(item):
		items.erase(item)
		item_removed.emit(item)
		inventory_changed.emit()

func is_full() -> bool:
	return not _has_null_slot() and items.size() >= max_slots

func has_stackable_space(item: ItemData) -> bool:
	## Stacklenebilir bir item için: eğer aynı id'ye sahip varsa yer var demektir
	if not item or not item.stackable:
		return not is_full()
	if not item.id.is_empty():
		for existing in items:
			if existing and existing.stackable and existing.id == item.id:
				return true  # var olan stack'e eklenir, yeni slot gerekmez
	return _has_null_slot() or items.size() < max_slots

func get_items_by_type(item_type: String) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for i in items:
		if i and i.item_type == item_type:
			result.append(i)
	return result

## Public wrapper — bu item giyilebilir mi?
func can_equip_item(item: ItemData) -> bool:
	return _meets_requirements(item)

## Eksik statları döndürür (örn. "Güç: 22/32") — boş string = giyilebilir
func get_requirement_failures(item: ItemData) -> String:
	var fail_parts: Array[String] = []
	if item.required_level > _player_level:
		fail_parts.append("Level: %d/%d" % [_player_level, item.required_level])
	if not _player_stats:
		return ", ".join(fail_parts)
	if item.required_strength > 0 and _player_stats.total_strength < item.required_strength:
		fail_parts.append("Güç: %d/%d" % [_player_stats.total_strength, item.required_strength])
	if item.required_dexterity > 0 and _player_stats.total_dexterity < item.required_dexterity:
		fail_parts.append("Çeviklik: %d/%d" % [_player_stats.total_dexterity, item.required_dexterity])
	if item.required_intelligence > 0 and _player_stats.total_intelligence < item.required_intelligence:
		fail_parts.append("Zeka: %d/%d" % [_player_stats.total_intelligence, item.required_intelligence])
	return ", ".join(fail_parts)

## Oyuncunun statlarının item gereksinimlerini karşılayıp karşılamadığını kontrol eder.
func _meets_requirements(item: ItemData) -> bool:
	if item.required_level > _player_level:
		return false
	if not _player_stats:
		return true  # stats yoksa stat kontrolu atla
	if item.required_strength > 0 and _player_stats.total_strength < item.required_strength:
		return false
	if item.required_dexterity > 0 and _player_stats.total_dexterity < item.required_dexterity:
		return false
	if item.required_intelligence > 0 and _player_stats.total_intelligence < item.required_intelligence:
		return false
	return true

## Envanterdeki bir item'ı ekipman slotuna takar. O slotta zaten item
## varsa, onu otomatik olarak envantere geri koyar (slot değiştirme).
func equip_item(item: ItemData, equipment: Equipment, force_slot_name: String = "") -> bool:
	if not item:
		return false
	if not items.has(item):
		return false
	var slot_name: String = force_slot_name if not force_slot_name.is_empty() else item.equip_slot
	if slot_name.is_empty():
		return false
	if not _meets_requirements(item):
		return false
	var slot: int = equipment.slot_name_to_enum(slot_name)
	if slot == -1:
		return false
	var previous: ItemData = equipment.equip(slot, item)
	# Slot'u null yap (erase() ile kaydırma yapma)
	var idx: int = items.find(item)
	if idx >= 0:
		items[idx] = null
	if previous:
		# Envanter doluysa eski item'i silme — yeni item'i equip etme
		if not add_item(previous):
			# Geri al: eski item'i tekrar equip et, yeni item'i envantere koy
			equipment.equip(slot, previous)
			if idx >= 0:
				items[idx] = item  # yeni item'i envanterdeki yerine geri koy
			inventory_changed.emit()
			return false
	inventory_changed.emit()
	return true

func unequip_item(slot_name: String, equipment: Equipment) -> bool:
	if slot_name.is_empty() or not equipment:
		return false
	var slot: int = equipment.slot_name_to_enum(slot_name)
	if slot == -1:
		return false
	var item: ItemData = equipment.unequip(slot)
	if item:
		if not add_item(item):
			# Envanter dolu → eşyayı geri tak
			equipment.equip(slot, item)
			return false
		inventory_changed.emit()
		return true
	return false
