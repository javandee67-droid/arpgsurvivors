extends Node
class_name DPSMeter
## VS DPS Meter: skill damage tracking + display.
## Sag ust kosede her skill'in toplam hasarini ve DPS'ini gosterir.
## EventBus.skill_damage sinyaline baglanarak hasar takibi yapar.

var _dps_label: Label = null
var _skill_damage: Dictionary = {}  # {skill_id: total_damage}
var _skill_timers: Dictionary = {}  # {skill_id: time_since_reset}
var _total_time: float = 0.0
var _last_update: float = 0.0

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	if EventBus.has_signal("skill_damage"):
		EventBus.skill_damage.connect(_on_skill_damage)

func _process(delta: float) -> void:
	_total_time += delta
	_last_update += delta
	if _last_update < 0.3:
		return
	_last_update = 0.0
	_update_display()
	
	if not _dps_label:
		_create_dps_label()

func _create_dps_label() -> void:
	_dps_label = Label.new()
	_dps_label.name = "DPSMeterLabel"
	_dps_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.7, 0.9))
	_dps_label.add_theme_font_size_override("font_size", 9)
	_dps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dps_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_dps_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	var vp: Vector2 = get_viewport().get_visible_rect().size
	_dps_label.position = Vector2(vp.x - 200, 8)
	_dps_label.size = Vector2(195, 400)
	
	get_parent().add_child(_dps_label)

func _on_skill_damage(skill_id: String, amount: float, _tags: Array) -> void:
	if not _skill_damage.has(skill_id):
		_skill_damage[skill_id] = 0.0
		_skill_timers[skill_id] = 0.0
	_skill_damage[skill_id] += amount

func _update_display() -> void:
	if not _dps_label or not is_instance_valid(_dps_label):
		return
	
	if _skill_damage.is_empty():
		_dps_label.text = "HASAR\n------\n(Hic)"
		return
	
	var text := "HASAR\n"
	text += "------\n"
	
	var sorted: Array[String] = []
	for k in _skill_damage.keys():
		sorted.append(k)
	
	sorted.sort_custom(func(a: String, b: String) -> bool:
		return _skill_damage.get(a, 0.0) > _skill_damage.get(b, 0.0)
	)
	
	var total_dmg: float = 0.0
	for skill_id in sorted:
		var dmg: float = _skill_damage.get(skill_id, 0.0)
		total_dmg += dmg
		var elapsed: float = _skill_timers.get(skill_id, 0.01)
		var dps: float = dmg / elapsed
		
		var short_name: String = _shorten_name(skill_id)
		text += "%s %s %s\n" % [short_name, _fmt_num(dmg), _fmt_num(dps)]
	
	text += "------\n"
	text += "Top %s %s" % [_fmt_num(total_dmg), _fmt_num(total_dmg / maxf(_total_time, 0.01))]
	
	_dps_label.text = text

func _shorten_name(id: String) -> String:
	var names: Dictionary = {
		"normal_attack": "Vurus",
		"fire_bolt": "Ates Oku",
		"ice_shard": "Buz Mizragi",
		"lightning_chain": "Yildirim",
		"arcane_orb": "Kure",
		"toxic_circle": "Zehir",
		"whirlwind": "Kasirga",
		"dark_beam": "Lazer",
		"holy_nova": "Nova",
		"thunder_strike": "Firtina",
		"frost_explosion": "Don",
		"slice_wave": "Kesme",
		"fireball": "Ates Topu",
		"ice_nova": "Buz Nova",
	}
	return names.get(id, id)

func _fmt_num(val: float) -> String:
	if abs(val) >= 1000000.0:
		return "%.1fM" % (val / 1000000.0)
	elif abs(val) >= 1000.0:
		return "%.1fK" % (val / 1000.0)
	else:
		return "%.0f" % val
