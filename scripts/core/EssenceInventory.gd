extends Node
class_name EssenceInventory
## Tüm currency/orb item'larını tutan ayrı envanter (ÖZLER paneli).
## Normal envanteri doldurmamaları için ayrı bir sistem.
## Artık sadece 6 essence değil, tüm orb/currency türleri kabul edilir.
## Slotlar dinamiktir: aynı ID'ye sahip item'lar stacklenir, boş slot bulunur.

signal essence_inventory_changed

## Maksimum gösterilebilecek slot sayısı (14 küre türü + yedek)
const MAX_SLOTS: int = 16

var slots: Array[ItemData] = []

## Currency item mı kontrol et (sadece type/rarity kontrolü, ID filtresi yok)
static func is_essence(item: ItemData) -> bool:
	if not item:
		return false
	if item.item_type != "currency":
		return false
	if item.rarity != "currency":
		return false
	return true

## ID'ye göre slot dizinini bul (dinamik arama)
static func get_slot_for_essence_id(_essence_id: String) -> int:
	# Artık statik ESSENCE_IDS yok — sadece var olan slotları tara
	# (Bu static metod sadece GroundItem.gd pickup için kullanılır,
	# idiomatik olarak saklanır ama asıl iş add_essence() yapar)
	return -1

## Bir currency/orb item'ını envantere ekler.
## Aynı ID'ye sahip stacklenebilir item varsa stack_count'u artırır.
## Yoksa ilk boş slot'a yerleştirir.
func add_essence(item: ItemData) -> bool:
	if not is_essence(item):
		return false
	
	# Önce aynı ID'ye sahip var mı kontrol et (stackleme)
	for i in range(slots.size()):
		var existing: ItemData = slots[i]
		if existing and existing.stackable and existing.id == item.id:
			existing.stack_count += item.stack_count
			essence_inventory_changed.emit()
			return true
	
	# Boş slot bul
	var empty_idx: int = slots.find(null)
	if empty_idx >= 0:
		slots[empty_idx] = item
		essence_inventory_changed.emit()
		return true
	
	# Yeni slot ekle (MAX_SLOTS'a kadar)
	if slots.size() < MAX_SLOTS:
		slots.append(item)
		essence_inventory_changed.emit()
		return true
	
	return false  # Dolu

## Bir slot'taki item'dan 1 tane tüketir.
## Stack sıfırsa slot'u temizler.
func consume_essence(slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= slots.size():
		return false
	var item: ItemData = slots[slot_idx]
	if not item:
		return false
	if item.stackable and item.stack_count > 1:
		item.stack_count -= 1
	else:
		slots[slot_idx] = null
	essence_inventory_changed.emit()
	return true

## Belirtilen ID'ye sahip currency'den kaç tane olduğunu döndürür.
func get_essence_count(essence_id: String) -> int:
	for i in range(slots.size()):
		var item: ItemData = slots[i]
		if item and item.id == essence_id:
			return item.stack_count
	return 0
