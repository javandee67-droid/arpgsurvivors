extends Node
## Merkezi olay yayın sistemi (Event Bus).
## KURULUM: Project Settings > Autoload > bu dosyayı ekle, isim: "EventBus"
## Tüm trigger tabanlı skill'ler bu sinyallere abone olur.

signal damage_taken(payload: Dictionary)
signal damage_dealt(payload: Dictionary)
signal crit_landed(payload: Dictionary)
signal enemy_killed(enemy: Node)
signal screen_shake(intensity: float, duration: float)
signal skill_cast(skill_id: String, caster: Node)
signal periodic_tick(delta: float)
signal skill_damage(skill_id: String, amount: float, tags: Array)
signal level_up(new_level: int, position: Vector2)
signal boss_encounter(boss_name: String, position: Vector2)
signal boss_killed(boss_name: String, position: Vector2)

## payload formatı (Dictionary kullanıyoruz, class oluşturmaya gerek yok):
## {
##   "amount": float,       -> verilen/alınan hasar miktarı
##   "source": Node,        -> hasarı veren
##   "target": Node,        -> hasarı alan
##   "tags": Array[String], -> ["cold","spell"] gibi
##   "position": Vector2,   -> olayın gerçekleştiği konum
##   "is_crit": bool
## }

## _process yerine Timer kullan — her frame sinyal göndermek gereksiz CPU yükü
func _ready() -> void:
	var tick_timer := Timer.new()
	tick_timer.name = "PeriodicTickTimer"
	tick_timer.wait_time = 0.2  ## saniyede 5 kez
	tick_timer.autostart = true
	tick_timer.timeout.connect(_on_tick_timer)
	add_child(tick_timer)

func _on_tick_timer() -> void:
	periodic_tick.emit(0.2)
