extends CanvasLayer
class_name FloatingDamage
## DuskForged Floating Damage v2 — havuzlu, renk kodlamali, animasyonlu, responsive.
## EventBus.damage_dealt + enemy_killed sinyallerine baglanir.
## Hasar numaralarini, kritik efektlerini, level-up ve oldurme yazilarini gosterir.

# ---------- BUG FIXES ----------
# 1) Obje havuzu — surekli Label.new/queue_free yerine 30 label recycle
# 2) Hardcoded size (60x24) — otomatik boyutlanir
# 3) Viewport resize — ekran disina tasmaz
# 4) Cakisan sayilar — stagger sistemiyle offsetlenir
# 5) Signal disconnect — _exit_tree'de temizlenir

# ---------- CONSTANTS ----------
const POOL_SIZE := 30
const MAX_VISIBLE := 40
const LAYER := 60
const BASE_FONT_SZ := 18
const CRIT_FONT_SZ := 28
const KILL_FONT_SZ := 16
const FLOAT_DIST := 42.0
const CRIT_FLOAT_DIST := 55.0
const STAGGER_RADIUS := 28.0
const STACK_WINDOW := 0.5
const FADE_DELAY := 0.35
const CRIT_FADE_DELAY := 0.5
const ANIM_DURATION := 1.1
const LEVEL_FONT_SZ := 26
const OUTLINE_NORMAL := 1
const OUTLINE_CRIT := 3
const EDGE_MARGIN := 30

# Damage type colors
const CLR_PHYSICAL := Color(1.0, 0.9, 0.7, 1.0)
const CLR_FIRE := Color(1.0, 0.5, 0.15, 1.0)
const CLR_ICE := Color(0.4, 0.75, 1.0, 1.0)
const CLR_LIGHTNING := Color(0.9, 0.85, 0.2, 1.0)
const CLR_ARCANE := Color(0.7, 0.4, 1.0, 1.0)
const CLR_TOXIC := Color(0.3, 0.9, 0.4, 1.0)
const CLR_DARK := Color(0.6, 0.3, 0.8, 1.0)
const CLR_HOLY := Color(1.0, 0.9, 0.5, 1.0)
const CLR_CRIT := Color(1.0, 0.85, 0.1, 1.0)
const CLR_HEAL := Color(0.3, 0.9, 0.5, 1.0)
const CLR_KILL := Color(0.5, 0.9, 0.5, 0.9)
const CLR_LEVEL := Color(1.0, 0.9, 0.2, 1.0)
const CLR_MISS := Color(0.5, 0.5, 0.6, 0.7)
const CLR_OUTLINE := Color(0.0, 0.0, 0.0, 0.75)
const CLR_OUTLINE_CRIT := Color(0.0, 0.0, 0.0, 0.85)

const DMG_COLORS := {
	"physical": CLR_PHYSICAL, "fire": CLR_FIRE, "ice": CLR_ICE,
	"lightning": CLR_LIGHTNING, "arcane": CLR_ARCANE, "toxic": CLR_TOXIC,
	"poison": CLR_TOXIC, "dark": CLR_DARK, "holy": CLR_HOLY,
}

# ---------- STATE ----------
var _pool: Array[Label] = []
var _pool_idx: int = 0
var _active_count: int = 0
var _position_log: Dictionary = {}  # pos_key -> [time, count]
var _kill_spawned_at: float = 0.0
var _total_time: float = 0.0
var _tw: Tween = null

func _ready() -> void:
	layer = LAYER
	_build_pool()
	if is_instance_valid(EventBus):
		if EventBus.has_signal("damage_dealt"):
			EventBus.damage_dealt.connect(_on_damage_dealt)
		if EventBus.has_signal("enemy_killed"):
			EventBus.enemy_killed.connect(_on_enemy_killed)

func _exit_tree() -> void:
	if is_instance_valid(EventBus):
		if EventBus.is_connected("damage_dealt", _on_damage_dealt):
			EventBus.damage_dealt.disconnect(_on_damage_dealt)
		if EventBus.is_connected("enemy_killed", _on_enemy_killed):
			EventBus.enemy_killed.disconnect(_on_enemy_killed)

func _process(delta: float) -> void:
	_total_time += delta
	# Pool'daki eski stagger kayitlarini temizle
	if int(_total_time) > int(_total_time - delta):
		_clean_position_log()
# ═══ POOL ════
func _build_pool() -> void:
	for i in POOL_SIZE:
		var lbl := Label.new()
		lbl.name = "FDPool_%d" % i
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.visible = false
		lbl.add_theme_constant_override("outline_size", OUTLINE_NORMAL)
		lbl.add_theme_color_override("font_outline_color", CLR_OUTLINE)
		add_child(lbl)
		_pool.append(lbl)

func _get_label() -> Label:
	_active_count += 1
	var lbl: Label = _pool[_pool_idx % POOL_SIZE]
	_pool_idx += 1
	# Once visible olanlari gizle
	if lbl.visible:
		lbl.visible = false
	# Eger cok fazla aktif varsa en son label'i kullan
	if _active_count > MAX_VISIBLE:
		_active_count = MAX_VISIBLE
	lbl.visible = true
	lbl.modulate = Color.WHITE
	lbl.scale = Vector2.ONE
	lbl.size = Vector2.ZERO  # auto-size
	lbl.text = ""
	lbl.z_index = 0
	return lbl

func _release_label(lbl: Label) -> void:
	lbl.visible = false
	lbl.text = ""
	_active_count = maxi(0, _active_count - 1)

func _clean_position_log() -> void:
	var cutoff: float = _total_time - 1.5
	for key in _position_log.keys():
		if _position_log[key][0] < cutoff:
			_position_log.erase(key)

# ═══ SIGNALS ═══
func _on_damage_dealt(payload: Dictionary) -> void:
	# Sadece oyuncunun vuruslari, canavarlarin oyuncuya vurusu degil
	var target: Node = payload.get("target", null)
	if target and target.is_in_group("player"):
		return
	var pos: Vector2 = payload.get("position", Vector2.ZERO)
	if pos == Vector2.ZERO:
		return
	var amount: float = payload.get("amount", 0.0)
	if amount <= 0.0:
		return
	var is_crit: bool = payload.get("is_crit", false)
	var dmg_types: Array = payload.get("damage_types", ["physical"])
	var dmg_type: String = dmg_types[0] if dmg_types.size() > 0 else "physical"

	# Hit flash
	if target and target.has_method("do_hit_flash"):
		target.do_hit_flash(dmg_type)

	# Kritikte screen shake
	if is_crit:
		if EventBus.has_signal("screen_shake"):
			EventBus.screen_shake.emit(0.3, 4.0, 1.0)

	_spawn_number(pos, amount, is_crit, dmg_type)

func _on_enemy_killed(enemy: Node) -> void:
	var pos: Vector2 = enemy.global_position if enemy and is_instance_valid(enemy) else Vector2.ZERO
	if pos == Vector2.ZERO:
		return
	# Kill spam korumasi — son 0.5sn'de kill text gosterildiyse atla
	if _total_time - _kill_spawned_at < 0.5:
		return
	_kill_spawned_at = _total_time
	_spawn_text(pos, "OLDU!", CLR_KILL, KILL_FONT_SZ, OUTLINE_NORMAL)

# ═══ SPAWN ═══
func _spawn_number(pos: Vector2, amount: float, is_crit: bool, dmg_type: String = "physical") -> void:
	var lbl: Label = _get_label()

	# Stack kontrolu — ayni pozisyonda 0.5sn icinde yeni hasar
	var pkey: String = "%d_%d" % [int(pos.x / 30), int(pos.y / 30)]
	var stack_count: int = 1
	if _position_log.has(pkey):
		var entry: Array = _position_log[pkey]
		if _total_time - entry[0] < STACK_WINDOW:
			stack_count = entry[1] + 1
			_position_log[pkey] = [_total_time, stack_count]
		else:
			_position_log[pkey] = [_total_time, 1]
	else:
		_position_log[pkey] = [_total_time, 1]

	var display_amt: int = maxi(1, int(amount))
	var clr: Color = DMG_COLORS.get(dmg_type, CLR_PHYSICAL)
	var fs: int = BASE_FONT_SZ
	var outline_sz: int = OUTLINE_NORMAL
	var float_dist: float = FLOAT_DIST
	var start_scale: float = 0.6
	var pop_scale: float = 1.08
	var fade_delay: float = FADE_DELAY

	if is_crit:
		clr = CLR_CRIT
		fs = CRIT_FONT_SZ
		outline_sz = OUTLINE_CRIT
		float_dist = CRIT_FLOAT_DIST
		start_scale = 0.4
		pop_scale = 1.2
		fade_delay = CRIT_FADE_DELAY
		lbl.z_index = 10

	var prefix: String = "+" if dmg_type == "heal" else ""
	lbl.text = "%s%d" % [prefix, display_amt]
	if stack_count > 1:
		lbl.text += " x%d" % stack_count
	if is_crit:
		lbl.text += "!"

	lbl.add_theme_color_override("font_color", clr)
	lbl.add_theme_font_size_override("font_size", fs)
	lbl.add_theme_constant_override("outline_size", outline_sz)
	lbl.add_theme_color_override("font_outline_color", CLR_OUTLINE_CRIT if is_crit else CLR_OUTLINE)

	# Pozisyon: dunyadan ekrana
	var cam := get_viewport().get_camera_2d()
	var screen_pos: Vector2 = pos
	if cam and is_instance_valid(cam):
		screen_pos = cam.get_canvas_transform() * pos

	# Stagger offset — cakismalari engelle
	var stagger: Vector2 = _get_stagger(pkey)
	screen_pos += stagger

	# Kenar clamp
	var vp_size: Vector2i = get_viewport().size
	screen_pos.x = clampf(screen_pos.x, EDGE_MARGIN, vp_size.x - EDGE_MARGIN)
	screen_pos.y = clampf(screen_pos.y, EDGE_MARGIN, vp_size.y - EDGE_MARGIN - 100)

	lbl.position = screen_pos
	lbl.pivot_offset = Vector2(lbl.size.x / 2, lbl.size.y / 2)
	lbl.scale = Vector2(start_scale, start_scale)

	# Animasyon
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "scale", Vector2(pop_scale, pop_scale), 0.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.08).set_delay(0.1).set_ease(Tween.EASE_IN)
	var drift_x := randf_range(-14.0, 14.0)
	tw.tween_property(lbl, "position:y", screen_pos.y - float_dist, ANIM_DURATION).set_delay(0.03).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "position:x", screen_pos.x + drift_x, ANIM_DURATION).set_delay(0.03).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(fade_delay)
	tw.tween_callback(_release_label.bind(lbl)).set_delay(ANIM_DURATION + 0.1)

func _spawn_text(pos: Vector2, text: String, color: Color, font_size: int, outline: int) -> void:
	var lbl: Label = _get_label()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_constant_override("outline_size", outline)
	lbl.add_theme_color_override("font_outline_color", CLR_OUTLINE)

	var cam := get_viewport().get_camera_2d()
	var screen_pos: Vector2 = pos
	if cam and is_instance_valid(cam):
		screen_pos = cam.get_canvas_transform() * pos
	screen_pos += Vector2(randf_range(-20, 20), randf_range(-10, 0))

	var vp_size2: Vector2 = get_viewport().size
	screen_pos.x = clampf(screen_pos.x, EDGE_MARGIN, vp_size2.x - EDGE_MARGIN)
	screen_pos.y = clampf(screen_pos.y, EDGE_MARGIN, vp_size2.y - EDGE_MARGIN)

	lbl.position = screen_pos
	lbl.pivot_offset = Vector2(lbl.size.x / 2, lbl.size.y / 2)
	lbl.scale = Vector2(0.5, 0.5)
	lbl.z_index = 5

	var tw2: Tween = create_tween()
	tw2.set_parallel(true)
	tw2.tween_property(lbl, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT)
	tw2.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.15).set_ease(Tween.EASE_IN)
	tw2.tween_property(lbl, "position:y", screen_pos.y - 35, ANIM_DURATION).set_delay(0.05).set_ease(Tween.EASE_OUT)
	tw2.tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tw2.tween_callback(_release_label.bind(lbl)).set_delay(ANIM_DURATION + 0.1)

func _get_stagger(key: String) -> Vector2:
	if not _position_log.has(key):
		return Vector2.ZERO
	var entry: Array = _position_log[key]
	var count: int = entry[1]
	if count <= 1:
		return Vector2.ZERO
	# Cakisan sayilari dagit — spiral pattern
	var angle: float = (count % 6) * 1.047  # 60 derece
	var radius: float = STAGGER_RADIUS * (1.0 + (count / 6) * 0.5)
	return Vector2(cos(angle), sin(angle)) * radius

# ═══ LEVEL UP ═══
func show_level_up(new_level: int) -> void:
	var lbl := _get_label()
	lbl.text = "SEVIYE ATLADIN! (%d)" % new_level
	lbl.add_theme_color_override("font_color", CLR_LEVEL)
	lbl.add_theme_font_size_override("font_size", LEVEL_FONT_SZ)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", CLR_OUTLINE_CRIT)
	lbl.z_index = 20

	var vp3: Vector2 = get_viewport().size
	lbl.position = Vector2(vp3.x / 2 - 160, vp3.y / 2 - 80)
	lbl.pivot_offset = Vector2(lbl.size.x / 2, lbl.size.y / 2)
	lbl.scale = Vector2(0.3, 0.3)

	var tw4: Tween = create_tween()
	tw4.set_parallel(true)
	tw4.tween_property(lbl, "scale", Vector2(1.2, 1.2), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw4.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.12).set_delay(0.25).set_ease(Tween.EASE_IN)
	tw4.tween_property(lbl, "position:y", lbl.position.y - 40, 1.5).set_ease(Tween.EASE_OUT)
	tw4.tween_property(lbl, "modulate:a", 0.0, 1.0).set_delay(0.7)
	tw4.tween_callback(_release_label.bind(lbl)).set_delay(1.8)

# ═══ RESET ═══
func reset() -> void:
	# Yeni oyun basinda havuzu temizle
	for lbl in _pool:
		lbl.visible = false
	_pool_idx = 0
	_active_count = 0
	_position_log.clear()
	_total_time = 0.0
	_kill_spawned_at = 0.0
