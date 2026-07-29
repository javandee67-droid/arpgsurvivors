extends Node
class_name DPSMeter
## DPS Meter v2 — hasar takibi, animasyonlu panel, renk kodlamali, suruklenebilir.
## EventBus.skill_damage + crit_landed + enemy_killed sinyallerine baglanir.
## F2 tusu ile acilip kapanir, fareyle suruklenebilir.

# ---------- BUG FIXES ----------
# 1) get_parent().add_child() -> panel direkt child olarak eklenir
# 2) _skill_timers artik her _process'te guncellenir (DPS dogru hesaplanir)
# 3) Label _ready'de olusturulur (lazy degil)
# 4) Viewport resize'a tepki verir
# 5) EventBus null check

# ---------- CONSTANTS ----------
const PANEL_W := 220
const PANEL_H := 340
const PAD := 6
const FONT_SZ := 11
const MAX_VISIBLE := 10
const UPDATE_INTERVAL := 0.3
const AUTO_HIDE_DELAY := 8.0
const FADE_SPEED := 4.0
const DRAG_EDGE := 10
const TOGGLE_KEY := KEY_F2

const CLR_BG := Color(0.03, 0.03, 0.06, 0.85)
const CLR_BORDER := Color(0.5, 0.7, 1.0, 0.4)
const CLR_TITLE := Color(0.4, 0.7, 1.0, 0.9)
const CLR_SEP := Color(0.3, 0.3, 0.4, 0.3)
const CLR_TEXT := Color(0.85, 0.85, 0.9, 0.9)
const CLR_MUTED := Color(0.4, 0.4, 0.5, 0.7)
const CLR_GOLD := Color(1.0, 0.78, 0.2, 1.0)
const CLR_SILVER := Color(0.7, 0.7, 0.75, 0.9)
const CLR_BRONZE := Color(0.8, 0.5, 0.25, 0.9)

const COLORS := {
	"fire": Color(0.95, 0.35, 0.15, 0.9),
	"ice": Color(0.3, 0.6, 1.0, 0.9),
	"lightning": Color(0.9, 0.85, 0.15, 0.9),
	"arcane": Color(0.7, 0.3, 1.0, 0.9),
	"toxic": Color(0.3, 0.9, 0.35, 0.9),
	"holy": Color(0.95, 0.85, 0.5, 0.9),
	"dark": Color(0.6, 0.2, 0.8, 0.9),
	"physical": Color(0.7, 0.6, 0.5, 0.9),
}

const SKILL_META := {
	"normal_attack": ["⚔", null, "Vuruş"],
	"fire_bolt": ["🔥", "fire", "Ateş Oku"],
	"ice_shard": ["❄", "ice", "Buz Mızrağı"],
	"lightning_chain": ["⚡", "lightning", "Yıldırım"],
	"arcane_orb": ["🔮", "arcane", "Küre"],
	"toxic_circle": ["☠", "toxic", "Zehir"],
	"whirlwind": ["🌀", "physical", "Kasırga"],
	"dark_beam": ["🌑", "dark", "Lazer"],
	"holy_nova": ["✨", "holy", "Nova"],
	"thunder_strike": ["🌩", "lightning", "Fırtına"],
	"frost_explosion": ["🧊", "frost", "Don"],
	"slice_wave": ["🗡", "physical", "Kesme"],
	"fireball": ["🔥", "fire", "Ateş Topu"],
	"ice_nova": ["❄", "ice", "Buz Nova"],
}

var visible_state: bool = true
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var _dirty: bool = false
var _total_time: float = 0.0
var _last_update: float = 0.0
var _last_dmg_time: float = 0.0
var _current_alpha: float = 1.0
var _target_alpha: float = 1.0
var _is_paused: bool = false

class _SkillData:
	var total_dmg: float = 0.0
	var peak_dps: float = 0.0
	var hit_count: int = 0
	var crit_count: int = 0
	var kill_count: int = 0
	var timer: float = 0.0
	var highest_hit: float = 0.0
	var hist: Array[float] = []
	var hist_idx: int = 0
	var sum_hist: float = 0.0

var _data: Dictionary = {}  # String -> _SkillData
var _panel: Panel = null
var _rtl: RichTextLabel = null

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_create_ui()
	if is_instance_valid(EventBus):
		if EventBus.has_signal("skill_damage"):
			EventBus.skill_damage.connect(_on_skill_damage)
		if EventBus.has_signal("crit_landed"):
			EventBus.crit_landed.connect(_on_crit_landed)
		if EventBus.has_signal("enemy_killed"):
			EventBus.enemy_killed.connect(_on_enemy_killed)
	var vp: Viewport = get_viewport()
	if vp:
		vp.size_changed.connect(_on_viewport_resized)

func _exit_tree() -> void:
	if is_instance_valid(EventBus):
		if EventBus.is_connected("skill_damage", _on_skill_damage):
			EventBus.skill_damage.disconnect(_on_skill_damage)
		if EventBus.is_connected("crit_landed", _on_crit_landed):
			EventBus.crit_landed.disconnect(_on_crit_landed)
		if EventBus.is_connected("enemy_killed", _on_enemy_killed):
			EventBus.enemy_killed.disconnect(_on_enemy_killed)

func _process(delta: float) -> void:
	if _is_paused: return
	_total_time += delta
	# Timer'ları güncelle — BUG FIX: eski kodda hiç artmıyordu!
	for sd in _data.values():
		sd.timer += delta
		var slot: int = int(sd.timer) % 8
		if slot != sd.hist_idx:
			while sd.hist.size() <= slot: sd.hist.append(0.0)
			sd.sum_hist = maxf(0.0, sd.sum_hist - sd.hist[slot])
			sd.hist[slot] = 0.0; sd.hist_idx = slot
	_last_update += delta
	if _last_update < UPDATE_INTERVAL and not _dirty: return
	_last_update = 0.0; _dirty = false
	# Auto-hide: hasar yoksa veya 8sn geçtiyse soluklaş
	if _data.is_empty() or _total_time - _last_dmg_time > AUTO_HIDE_DELAY:
		_target_alpha = 0.3
	else:
		_target_alpha = 1.0
	_current_alpha = lerpf(_current_alpha, _target_alpha, delta * FADE_SPEED)
	if _panel and is_instance_valid(_panel):
		_panel.modulate = Color(1, 1, 1, _current_alpha)
	_update_display()

func _input(event: InputEvent) -> void:
	# F2 ile aç/kapa
	if event is InputEventKey and event.keycode == TOGGLE_KEY and event.pressed and not event.echo:
		visible_state = not visible_state
		if _panel: _panel.visible = visible_state
	# Sürükleme
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _panel and _panel.get_global_rect().grow(DRAG_EDGE).has_point(event.position):
			is_dragging = true; drag_offset = _panel.position - event.position
		elif not event.pressed: is_dragging = false
	if event is InputEventMouseMotion and is_dragging and _panel:
		var vp: Vector2 = get_viewport().size
		var np: Vector2 = event.position + drag_offset
		np.x = clampf(np.x, 0, vp.x - PANEL_W)
		np.y = clampf(np.y, 0, vp.y - PANEL_H)
		_panel.position = np

func _create_ui() -> void:
	_panel = Panel.new(); _panel.name = "DPSMeterPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var s := StyleBoxFlat.new(); s.bg_color = CLR_BG; s.border_color = CLR_BORDER
	s.border_width_left = 1; s.border_width_right = 1; s.border_width_top = 1; s.border_width_bottom = 1
	s.set_corner_radius_all(6); _panel.add_theme_stylebox_override("panel", s)
	var vp: Vector2 = get_viewport().size if get_viewport() else Vector2(1280, 720)
	_panel.position = Vector2(vp.x - PANEL_W - 8, 56)
	_panel.size = Vector2(PANEL_W, PANEL_H); _panel.modulate = Color(1, 1, 1, 0.85)
	_rtl = RichTextLabel.new(); _rtl.name = "DPSContent"
	_rtl.anchor_left = 0.0; _rtl.anchor_right = 1.0; _rtl.anchor_top = 0.0; _rtl.anchor_bottom = 1.0
	_rtl.offset_left = PAD; _rtl.offset_right = -PAD; _rtl.offset_top = PAD; _rtl.offset_bottom = -PAD
	_rtl.bbcode_enabled = true; _rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rtl.add_theme_font_size_override("normal_font_size", FONT_SZ)
	_rtl.add_theme_color_override("default_color", CLR_TEXT)
	_rtl.autowrap_mode = TextServer.AUTOWRAP_OFF; _rtl.scroll_active = true
	_panel.add_child(_rtl); add_child(_panel)

func _on_skill_damage(skill_id: String, amount: float, _tags: Array) -> void:
	if not _data.has(skill_id): _data[skill_id] = _SkillData.new()
	var sd: _SkillData = _data[skill_id]; sd.total_dmg += amount; sd.hit_count += 1
	if amount > sd.highest_hit: sd.highest_hit = amount
	var slot: int = int(sd.timer) % 8
	while sd.hist.size() <= slot: sd.hist.append(0.0)
	sd.hist[slot] += amount; sd.sum_hist += amount
	var idps: float = amount / maxf(0.001, get_process_delta_time())
	if idps > sd.peak_dps: sd.peak_dps = idps
	_last_dmg_time = _total_time; _dirty = true

func _on_crit_landed(payload: Dictionary) -> void:
	var sid: String = payload.get("source", "")
	if sid and _data.has(sid): _data[sid].crit_count += 1

func _on_enemy_killed(_enemy: Node) -> void:
	var best: String = ""; var best_val: float = 0.0
	for sid in _data.keys():
		var sd: _SkillData = _data[sid]
		var r: float = sd.hist[int(sd.timer) % 8] if sd.hist.size() > 0 else 0.0
		if r > best_val: best_val = r; best = sid
	if best and _data.has(best): _data[best].kill_count += 1

func _on_viewport_resized() -> void:
	if not _panel or not get_viewport(): return
	var vp: Vector2 = get_viewport().size
	_panel.position.x = clampf(_panel.position.x, 0, vp.x - PANEL_W)
	_panel.position.y = clampf(_panel.position.y, 0, vp.y - PANEL_H)

func _update_display() -> void:
	if not _rtl or not is_instance_valid(_rtl): return
	var bb := ""
	bb += "[center][color=#%s]HASAR METRE[/color][/center]" % _to_hex(CLR_TITLE)
	bb += "[center][color=#%s]F2: Gizle/Göster[/color][/center]\n" % _to_hex(CLR_MUTED)
	bb += "[color=#%s]─────────────────[/color]\n" % _to_hex(CLR_SEP)
	if _data.is_empty():
		bb += "[center][color=#%s](Hasar yok)[/color][/center]" % _to_hex(CLR_MUTED)
		_rtl.text = bb; return
	var sorted: Array[String] = []
	for k in _data.keys(): sorted.append(k)
	sorted.sort_custom(func(a, b): return _data[a].total_dmg > _data[b].total_dmg)
	var total_dmg: float = 0.0
	for sid in sorted: total_dmg += _data[sid].total_dmg
	var total_dps: float = total_dmg / maxf(_total_time, 0.01)
	var count: int = 0
	for sid in sorted:
		count += 1
		if count > MAX_VISIBLE:
			bb += "[color=#%s]... +%d skill daha[/color]\n" % [_to_hex(CLR_MUTED), sorted.size()-MAX_VISIBLE]
			break
		var sd: _SkillData = _data[sid]
		var meta: Array = SKILL_META.get(sid, ["⚙", null, sid])
		var icon: String = meta[0]; var elem = meta[1]; var ns: String = meta[2]
		var clr: Color = COLORS.get(elem, CLR_TEXT) if elem is String else CLR_TEXT
		var hex: String = _to_hex(clr)
		var ri: String = ""
		match count:
			1: ri = "[color=#%s]★ [/color]" % _to_hex(CLR_GOLD)
			2: ri = "[color=#%s]◎ [/color]" % _to_hex(CLR_SILVER)
			3: ri = "[color=#%s]○ [/color]" % _to_hex(CLR_BRONZE)
			_: ri = "[color=#%s]%d.[/color] " % [_to_hex(CLR_MUTED), count]
		var dpms: float = sd.total_dmg / maxf(sd.timer, 0.01)
		var bw: int = clampi(int((sd.total_dmg/maxf(total_dmg,0.01))*20), 0, 20)
		var bar_s: String = "[color=#%s]%s[/color]" % [_to_hex(Color(clr.r,clr.g,clr.b,0.35)), "█".repeat(bw)] if bw > 0 else ""
		bb += "%s[color=#%s]%s %s[/color] [color=#%s]%s/s[/color]\n" % [ri, hex, icon, ns, _to_hex(CLR_MUTED), _fmt_num(dpms)]
		bb += "  [color=#%s]%s ~%s/hit %d✖[/color]\n" % [_to_hex(clr*Color(1,1,1,0.5)), _fmt_num(sd.total_dmg), _fmt_num(sd.total_dmg/maxf(sd.hit_count,1)), sd.hit_count]
		if sd.crit_count > 0:
			bb += "  [color=#%s]%d✖ crit[/color]\n" % [_to_hex(Color(1.0,0.85,0.4,0.6)), sd.crit_count]
		if sd.kill_count > 0:
			bb += "  [color=#%s]%d skull[/color]\n" % [_to_hex(Color(0.5,0.9,0.5,0.6)), sd.kill_count]
		if bar_s != "": bb += "  %s\n" % bar_s
	bb += "[color=#%s]─────────────────[/color]\n" % _to_hex(CLR_SEP)
	bb += "[color=#%s]Toplam:[/color] [color=#%s]%s[/color] [color=#%s]%s/s[/color]" % [_to_hex(CLR_TEXT), _to_hex(CLR_GOLD), _fmt_num(total_dmg), _to_hex(CLR_MUTED), _fmt_num(total_dps)]
	_rtl.text = bb

func _fmt_num(val: float) -> String:
	if is_nan(val) or is_inf(val): return "0"
	var v: float = abs(val)
	if v >= 1000000000.0: return "%.2fB" % (val/1000000000.0)
	elif v >= 1000000.0: return "%.1fM" % (val/1000000.0)
	elif v >= 1000.0: return "%.1fK" % (val/1000.0)
	elif v >= 1.0: return "%.0f" % val
	return "%.1f" % val

func _to_hex(c: Color) -> String: return c.to_html(false)

func reset() -> void:
	_data.clear(); _total_time = 0.0; _last_dmg_time = 0.0; _last_update = 0.0
	_current_alpha = 1.0; _target_alpha = 1.0; _dirty = false
	if _rtl and is_instance_valid(_rtl): _rtl.text = ""
