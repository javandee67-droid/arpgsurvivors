extends Node
class_name LevelSystem
## Seviye ve XP takibi. Player'a "LevelSystem" adıyla Node olarak ekle.
## Player._ready() içinde level_system.stats_ref = stats ataması yapılmalı
## (seviye atlayınca statları büyütebilmek için).

signal xp_changed(current: float, required: float)
signal leveled_up(new_level: int)
signal skills_changed

@export var level: int = 1
@export var current_xp: float = 0.0
var stats_ref: CharacterStats = null

# NOT: XP artık Enemy._on_death() tarafından direkt veriliyor (xp_multiplier ile).
# EventBus.yolu çift XP vermemek için kullanılmıyor.

## PoE tarzı üstel eğri: her seviye bir öncekinden daha fazla XP ister.
## v2: Daha dik eğri + daha yüksek başlangıç — çatır çatır level atlamayı önler.
func get_xp_required() -> float:
	return round(80.0 * pow(float(level), 2.0))

func add_xp(amount: float) -> void:
	current_xp += amount
	var required = get_xp_required()
	while current_xp >= required:
		current_xp -= required
		level += 1
		_apply_level_up_growth()
		leveled_up.emit(level)
		required = get_xp_required()
	xp_changed.emit(current_xp, get_xp_required())

func emit_skills_changed() -> void:
	skills_changed.emit()

## Seviye atlayınca temel statların büyümesi.
## Her seviye: +8 can, +1 stat puanı, +1 pasif puan
func _apply_level_up_growth() -> void:
	if not stats_ref:
		return
	stats_ref.base_life += 8.0
	# Otomatik stat artışı yerine 1 stat puanı ver — oyuncu str/dex/int'in birine dağıtsın
	stats_ref.stat_points += 1
	# Pasif ağaç puanı ver (her seviye +1 puan)
	stats_ref.passive_points += 1
	# Aura seviyesini player level ile güncelle
	stats_ref.aura_level = level
	# Not: skill_points Player._on_leveled_up tarafından +1 artırılır
	stats_ref.recalculate()
