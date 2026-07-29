extends CanvasLayer
class_name MainMenu
## DuskForged Main Menu — karanlık fantezi, animasyonlu, responsive.
signal start_new_game()
signal continue_game()
signal open_upgrades()
signal open_settings()
signal quit_game()
enum State { MAIN, UPGRADES, SETTINGS, CONFIRM_NEW_GAME }
var current_state: State = State.MAIN
var persistent_upgrades: PersistentUpgrades
# ── Tema ──
const BG_COLOR := Color(0.02, 0.02, 0.04, 1.0)
const ACCENT_GOLD := Color(1.0, 0.78, 0.2, 1.0)
const ACCENT_SUBTLE := Color(0.85, 0.65, 0.25, 1.0)
const TEXT_MAIN := Color(0.92, 0.9, 0.85, 1.0)
const TEXT_MUTED := Color(0.5, 0.5, 0.55, 1.0)
const TEXT_DIM := Color(0.35, 0.35, 0.4, 1.0)
const HIGHLIGHT := Color(1.0, 0.92, 0.6, 1.0)
const DANGER := Color(0.9, 0.3, 0.2, 1.0)
const SUCCESS := Color(0.3, 0.85, 0.5, 1.0)
const BLUE_ACCENT := Color(0.4, 0.7, 1.0, 1.0)
const PANEL_BG := Color(0.04, 0.04, 0.08, 0.97)
const CARD_BG := Color(0.07, 0.07, 0.12, 0.85)
const CARD_BORDER := Color(0.15, 0.15, 0.2, 0.5)
# ── Font ──
const FONT_TITLE := 56
const FONT_SUBTITLE := 16
const FONT_BUTTON := 16
const FONT_SMALL := 12
const FONT_TINY := 10
const FONT_SECTION := 14
const FONT_PANEL_TITLE := 22
# ── Vars ──
var _buttons: Array[Button] = []
var _gold_label: Label = null
var _title_label: Label = null
var _particles_node: Node2D = null
var _anim_time: float = 0.0
var _current_panel: Control = null

func _ready() -> void:
	DisplayServer.window_set_title("DuskForged")
	process_mode = PROCESS_MODE_ALWAYS
	persistent_upgrades = PersistentUpgrades.get_instance()
	_build_ui()
	_play_intro_animation()

func _process(delta: float) -> void:
	_anim_time += delta
	# Title float
	if _title_label:
		_title_label.offset_top = 80 + sin(_anim_time * 1.2) * 4.0
	# Gold update
	if _gold_label:
		_gold_label.text = "✦ %d Altın" % _get_player_gold()
	# Particles (every 60ms, max 40)
	if _particles_node and _anim_time > 0.06:
		_anim_time = 0.0
		_spawn_particle()

## Build the main menu UI
func _build_ui() -> void:
	add_child(_cr(ColorRect.new(), "Background", BG_COLOR, true))
	var grad := _cr(ColorRect.new(), "GradientOverlay", Color(0.1, 0.05, 0.15, 0.3), true)
	add_child(grad)
	_tween_gradient(grad)
	add_child(_cr(ColorRect.new(), "Vignette", Color(0, 0, 0, 0.6), true))
	_particles_node = Node2D.new()
	_particles_node.name = "Particles"
	add_child(_particles_node)
	# Title
	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = "DuskForged"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.anchor_left = 0.5; _title_label.anchor_right = 0.5
	_title_label.anchor_top = 0.0; _title_label.anchor_bottom = 0.0
	_title_label.offset_left = -350; _title_label.offset_right = 350
	_title_label.offset_top = 80; _title_label.offset_bottom = 150
	_title_label.add_theme_font_size_override("font_size", FONT_TITLE)
	_title_label.add_theme_color_override("font_color", ACCENT_GOLD)
	_title_label.add_theme_color_override("font_shadow_color", Color(0.3, 0.2, 0.0, 0.5))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_title_label)
	# Title underline glow
	var line := _cr(ColorRect.new(), "TitleLine", ACCENT_GOLD, false)
	line.anchor_left = 0.5; line.anchor_right = 0.5
	line.anchor_top = 0.0; line.anchor_bottom = 0.0
	line.offset_left = -120; line.offset_right = 120
	line.offset_top = 152; line.offset_bottom = 156
	line.modulate = Color(1, 1, 1, 0.6)
	add_child(line)
	var twl := create_tween().set_loops()
	twl.tween_property(line, "modulate:a", 0.2, 1.5); twl.tween_property(line, "modulate:a", 0.6, 1.5)
	# Subtitle
	var sub := Label.new()
	sub.name = "Subtitle"
	sub.text = "The chaos has a rhythm."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.anchor_left = 0.5; sub.anchor_right = 0.5
	sub.anchor_top = 0.0; sub.anchor_bottom = 0.0
	sub.offset_left = -250; sub.offset_right = 250
	sub.offset_top = 160; sub.offset_bottom = 185
	sub.add_theme_font_size_override("font_size", FONT_SUBTITLE)
	sub.add_theme_color_override("font_color", TEXT_MUTED)
	add_child(sub)
	# Menu buttons
	var menu_box := VBoxContainer.new()
	menu_box.name = "MenuContainer"
	menu_box.anchor_left = 0.5; menu_box.anchor_right = 0.5
	menu_box.anchor_top = 0.38; menu_box.anchor_bottom = 0.65
	menu_box.offset_left = -160; menu_box.offset_right = 160
	menu_box.add_theme_constant_override("separation", 10)
	menu_box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(menu_box)
	_create_menu_buttons(menu_box)
	# Gold
	_gold_label = Label.new()
	_gold_label.name = "GoldLabel"
	_gold_label.text = "✦ %d Altın" % _get_player_gold()
	_gold_label.anchor_left = 1.0; _gold_label.anchor_right = 1.0
	_gold_label.anchor_top = 0.0; _gold_label.anchor_bottom = 0.0
	_gold_label.offset_left = -220; _gold_label.offset_right = -20
	_gold_label.offset_top = 20; _gold_label.offset_bottom = 50
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_gold_label.add_theme_font_size_override("font_size", 18)
	_gold_label.add_theme_color_override("font_color", ACCENT_GOLD)
	add_child(_gold_label)
	_create_gold_glow()
	_create_stats_bar()
	# Version
	var ver := Label.new()
	ver.name = "Version"
	ver.text = "v0.1.0-alpha"
	ver.anchor_left = 1.0; ver.anchor_right = 1.0
	ver.anchor_top = 1.0; ver.anchor_bottom = 1.0
	ver.offset_left = -140; ver.offset_right = -10
	ver.offset_top = -35; ver.offset_bottom = -15
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ver.add_theme_font_size_override("font_size", FONT_TINY)
	ver.add_theme_color_override("font_color", TEXT_DIM)
	add_child(ver)

## ─── HELPERS ───
func _cr(rect: ColorRect, name: String, color: Color, full: bool) -> ColorRect:
	rect.name = name; rect.color = color
	if full: rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect

func _make_s(bg: Color, border: Color, bw: int = 1, r: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg; sb.border_color = border
	sb.border_width_left = bw; sb.border_width_right = bw
	sb.border_width_top = bw; sb.border_width_bottom = bw
	sb.set_corner_radius_all(r)
	return sb

func _tween_gradient(rect: ColorRect) -> void:
	var tw := create_tween().set_loops()
	for c in [Color(0.08, 0.03, 0.12, 0.25), Color(0.03, 0.05, 0.12, 0.25), Color(0.1, 0.04, 0.08, 0.25)]:
		tw.tween_property(rect, "color", c, 4.0)

func _create_gold_glow() -> void:
	if not _gold_label: return
	var tw := create_tween().set_loops()
	tw.tween_property(_gold_label, "modulate:a", 0.7, 2.0); tw.tween_property(_gold_label, "modulate:a", 1.0, 2.0)

## ─── PARTICLES ───
func _spawn_particle() -> void:
	if not _particles_node: return
	var p: ColorRect = null
	for child in _particles_node.get_children():
		if not child.is_queued_for_deletion() and not child.visible: p = child; break
	if not p:
		if _particles_node.get_child_count() >= 40: return
		p = ColorRect.new(); _particles_node.add_child(p)
	else: p.show()
	var vs: Vector2 = get_viewport().size
	var gt := randf_range(0, 1)
	if gt < 0.4: p.color = Color(1.0, 0.75 + randf()*0.25, 0.2, 0.15+randf()*0.3)
	elif gt < 0.7: p.color = Color(0.5+randf()*0.3, 0.2+randf()*0.2, 0.8+randf()*0.2, 0.15+randf()*0.25)
	else: p.color = Color(0.3+randf()*0.2, 0.5+randf()*0.3, 0.9+randf()*0.1, 0.15+randf()*0.2)
	var sz := 2.0 + randf() * 4.0; p.size = Vector2(sz, sz)
	var st := StyleBoxFlat.new(); st.bg_color = p.color; st.set_corner_radius_all(sz/2)
	p.add_theme_stylebox_override("panel", st)
	p.position = Vector2(randf_range(40, vs.x-40), vs.y+20+randf()*40)
	var dur := 4.0 + randf()*3.0; var drift := randf_range(-50, 50)
	var tw := create_tween(); tw.set_parallel(true)
	tw.tween_property(p, "position:y", -40, dur); tw.tween_property(p, "position:x", p.position.x+drift, dur)
	tw.tween_property(p, "modulate:a", 0.0, 1.5).set_delay(dur-1.5)
	tw.finished.connect(func(): if is_instance_valid(p): p.hide())

## ─── BUTTONS ───
func _create_menu_buttons(parent: VBoxContainer) -> void:
	var configs := [
		{"text": "▶  DEVAM ET", "id": "continue", "color": SUCCESS},
		{"text": "✦  YENİ OYUN", "id": "new_game", "color": ACCENT_GOLD},
		{"text": "⬆  YÜKSELTİLER", "id": "upgrades", "color": BLUE_ACCENT},
		{"text": "⚙  AYARLAR", "id": "settings", "color": TEXT_MAIN},
		{"text": "✕  ÇIKIŞ", "id": "quit", "color": DANGER},
	]
	for cfg in configs:
		var btn := Button.new()
		btn.name = "Btn_"+cfg["id"]; btn.text = cfg["text"]
		btn.custom_minimum_size = Vector2(300, 52)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", FONT_BUTTON)
		btn.add_theme_color_override("font_color", cfg["color"])
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", cfg["color"])
		btn.add_theme_stylebox_override("normal", _make_s(Color(0.08,0.08,0.12,0.8), Color(0.25,0.25,0.3,0.5)))
		btn.add_theme_stylebox_override("hover", _make_s(Color(0.14,0.14,0.2,0.9), cfg["color"], 2))
		btn.add_theme_stylebox_override("pressed", _make_s(Color(0.1,0.08,0.06,0.95), cfg["color"], 2))
		btn.add_theme_stylebox_override("disabled", _make_s(Color(0.05,0.05,0.08,0.5), Color(0.15,0.15,0.2,0.3)))
		btn.mouse_entered.connect(func():
			if not is_instance_valid(btn): return
			create_tween().set_trans(Tween.TRANS_BACK).tween_property(btn, "scale", Vector2(1.05,1.05), 0.15)
		)
		btn.mouse_exited.connect(func():
			if not is_instance_valid(btn): return
			create_tween().set_trans(Tween.TRANS_BACK).tween_property(btn, "scale", Vector2.ONE, 0.15)
		)
		btn.pressed.connect(_on_menu_button.bind(cfg["id"]))
		parent.add_child(btn); _buttons.append(btn)
	if not _has_save_file():
		for b in _buttons:
			if b.name == "Btn_continue": b.disabled = true; b.modulate = Color(1,1,1,0.4)

## ─── STATS ───
func _create_stats_bar() -> void:
	var container := HBoxContainer.new()
	container.name = "StatsContainer"
	container.anchor_left = 0.5; container.anchor_right = 0.5
	container.anchor_top = 1.0; container.anchor_bottom = 1.0
	container.offset_left = -350; container.offset_right = 350
	container.offset_top = -60; container.offset_bottom = -30
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(container)
	var upg_count := 0
	for k in persistent_upgrades.upgrade_levels.keys(): upg_count += persistent_upgrades.upgrade_levels[k]
	var items := [{"l":"Oynanan: %d"%persistent_upgrades.games_played}, {"l":"Öldürme: %s"%_format_number(persistent_upgrades.total_kills)}, {"l":"Yükseltme: %d"%upg_count}]
	var first := true
	for it in items:
		if not first:
			var sep := Label.new(); sep.text = "  •  "
			sep.add_theme_color_override("font_color", TEXT_DIM); sep.add_theme_font_size_override("font_size", FONT_SMALL)
			container.add_child(sep)
		first = false
		var lb := Label.new(); lb.text = it["l"]
		lb.add_theme_font_size_override("font_size", FONT_SMALL); lb.add_theme_color_override("font_color", TEXT_MUTED)
		container.add_child(lb)

func _on_menu_button(button_id: String) -> void:
	match button_id:
		"continue":
			if _has_save_file(): _continue_game()
			else: _show_message("Kayıtlı oyun yok!", true)
		"new_game": _show_confirm_dialog()
		"upgrades": _show_upgrades_panel()
		"settings": _show_settings_panel()
		"quit": _show_confirm_quit()

## ─── INTRO ───
func _play_intro_animation() -> void:
	var bg := get_node_or_null("Background") as ColorRect
	if bg: bg.modulate = Color(1,1,1,0)
	if _title_label: _title_label.modulate = Color(1,1,1,0); _title_label.offset_top = -60
	var sub := get_node_or_null("Subtitle") as Label
	if sub: sub.modulate = Color(1,1,1,0)
	var line := get_node_or_null("TitleLine") as ColorRect
	if line: line.modulate = Color(1,1,1,0)
	for btn in _buttons: btn.modulate = Color(1,1,1,0); btn.offset_left = -200
	var tw := create_tween().set_parallel(); tw.set_trans(Tween.TRANS_BACK); tw.set_ease(Tween.EASE_OUT)
	if bg: tw.tween_property(bg, "modulate", Color.WHITE, 0.8)
	if _title_label: tw.tween_property(_title_label, "offset_top", 80, 0.7); tw.tween_property(_title_label, "modulate", Color.WHITE, 0.5)
	if sub: tw.tween_property(sub, "modulate", Color.WHITE, 0.6).set_delay(0.2)
	if line: tw.tween_property(line, "modulate", Color(1,1,1,0.6), 0.5).set_delay(0.3)
	var idx := 0
	for btn in _buttons:
		tw.tween_property(btn, "offset_left", 0, 0.5).set_delay(0.4+idx*0.07)
		tw.tween_property(btn, "modulate", Color.WHITE, 0.3).set_delay(0.4+idx*0.07); idx += 1

func _replay_intro() -> void: _play_intro_animation()

## ─── DIALOGS ───
func _show_confirm_dialog() -> void:
	_make_confirm("Yeni Oyun", "Yeni oyun başlatmak istediğinize\nemin misiniz?", ACCENT_GOLD,
		func(c,d): d.queue_free(); if c: _start_new_game())

func _show_confirm_quit() -> void:
	_make_confirm("Çıkış", "Oyundan çıkmak istediğinize\nemin misiniz?", DANGER,
		func(c,d): d.queue_free(); if c: get_tree().quit())

func _make_confirm(title_text: String, msg: String, border: Color, cb: Callable) -> Panel:
	var d := Panel.new()
	d.anchor_left=0.5; d.anchor_right=0.5; d.anchor_top=0.5; d.anchor_bottom=0.5
	d.offset_left=-200; d.offset_right=200; d.offset_top=-90; d.offset_bottom=90
	d.add_theme_stylebox_override("panel", _make_s(Color(0.05,0.05,0.1,0.98), border, 2, 8))
	var t := Label.new(); t.text=title_text; t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	t.offset_left=10; t.offset_right=-10; t.offset_top=12; t.offset_bottom=40
	t.add_theme_color_override("font_color", border); t.add_theme_font_size_override("font_size", FONT_SECTION); d.add_child(t)
	var m := Label.new(); m.text=msg; m.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	m.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; m.offset_left=20; m.offset_right=-20
	m.offset_top=40; m.offset_bottom=90
	m.add_theme_color_override("font_color", TEXT_MAIN); m.add_theme_font_size_override("font_size", 14); d.add_child(m)
	var hb := HBoxContainer.new(); hb.alignment=BoxContainer.ALIGNMENT_CENTER
	hb.offset_left=30; hb.offset_right=-30; hb.offset_top=95; hb.offset_bottom=130
	hb.add_theme_constant_override("separation", 20); d.add_child(hb)
	var yb := Button.new(); yb.text="EVET"; yb.custom_minimum_size=Vector2(90,38)
	yb.add_theme_font_size_override("font_size",14); yb.add_theme_color_override("font_color",SUCCESS)
	yb.add_theme_color_override("font_hover_color",Color.WHITE)
	yb.add_theme_stylebox_override("normal",_make_s(Color(0.08,0.1,0.08,0.9),Color(0.2,0.5,0.2,0.6)))
	yb.add_theme_stylebox_override("hover",_make_s(Color(0.1,0.15,0.1,0.95),SUCCESS,2))
	yb.pressed.connect(cb.bind(true,d)); hb.add_child(yb)
	var nb := Button.new(); nb.text="HAYIR"; nb.custom_minimum_size=Vector2(90,38)
	nb.add_theme_font_size_override("font_size",14); nb.add_theme_color_override("font_color",DANGER)
	nb.add_theme_color_override("font_hover_color",Color.WHITE)
	nb.add_theme_stylebox_override("normal",_make_s(Color(0.1,0.08,0.08,0.9),Color(0.5,0.2,0.2,0.6)))
	nb.add_theme_stylebox_override("hover",_make_s(Color(0.15,0.1,0.1,0.95),DANGER,2))
	nb.pressed.connect(cb.bind(false,d)); hb.add_child(nb)
	add_child(d)
	d.scale = Vector2(0.5,0.5); d.modulate = Color(1,1,1,0)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(d,"scale",Vector2.ONE,0.25); tw.tween_property(d,"modulate",Color.WHITE,0.2)
	return d

## ─── UPGRADES PANEL ───
func _show_upgrades_panel() -> void:
	if _current_panel: _current_panel.queue_free()
	var p := _create_upgrades_panel(); _current_panel = p; add_child(p)
	p.scale = Vector2(0.85,0.85); p.modulate = Color(1,1,1,0)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(p,"scale",Vector2.ONE,0.25); tw.tween_property(p,"modulate",Color.WHITE,0.2)

func _close_panel() -> void:
	if _current_panel:
		var p := _current_panel; _current_panel = null
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_BACK)
		tw.tween_property(p,"scale",Vector2(0.8,0.8),0.15); tw.tween_property(p,"modulate:a",0.0,0.15)
		tw.tween_callback(p.queue_free)

func _create_upgrades_panel() -> Panel:
	var panel := Panel.new(); panel.name = "UpgradesPanel"
	panel.anchor_left = 0.08; panel.anchor_right = 0.92; panel.anchor_top = 0.08; panel.anchor_bottom = 0.92
	panel.add_theme_stylebox_override("panel", _make_s(PANEL_BG, Color(0.5,0.8,1.0,0.8), 2, 8))
	# Title
	var title := Label.new(); title.text = "⬆ KALICI YÜKSELTİLER"
	title.anchor_left=0.5; title.anchor_right=0.5; title.anchor_top=0.0; title.anchor_bottom=0.0
	title.offset_left=-180; title.offset_right=180; title.offset_top=14; title.offset_bottom=48
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_PANEL_TITLE); title.add_theme_color_override("font_color", BLUE_ACCENT)
	panel.add_child(title)
	# Close
	var cb := Button.new(); cb.text="✕"; cb.anchor_left=1.0; cb.anchor_right=1.0; cb.anchor_top=0.0; cb.anchor_bottom=0.0
	cb.offset_left=-50; cb.offset_right=-12; cb.offset_top=10; cb.offset_bottom=42
	cb.add_theme_font_size_override("font_size",18)
	cb.add_theme_color_override("font_color", TEXT_MUTED); cb.add_theme_color_override("font_hover_color", Color.WHITE)
	cb.add_theme_stylebox_override("normal",_make_s(Color.TRANSPARENT,Color.TRANSPARENT))
	cb.add_theme_stylebox_override("hover",_make_s(Color(0.15,0.15,0.2,0.5),Color.TRANSPARENT,0,4))
	cb.pressed.connect(_close_panel); panel.add_child(cb)
	# Scroll
	var sc := ScrollContainer.new(); sc.name="UpgradeScroll"
	sc.anchor_left=0.04; sc.anchor_right=0.96; sc.anchor_top=0.10; sc.anchor_bottom=0.96
	var sbg := StyleBoxFlat.new(); sbg.bg_color=Color(0.1,0.1,0.15,0.3)
	sc.add_theme_stylebox_override("bg", sbg)
	var sbar := StyleBoxFlat.new(); sbar.bg_color=Color(0.4,0.4,0.5,0.5); sbar.set_corner_radius_all(3)
	sc.get_v_scroll_bar().add_theme_stylebox_override("scroll", sbg)
	sc.get_v_scroll_bar().add_theme_stylebox_override("scroll_drag", sbar)
	sc.get_v_scroll_bar().custom_minimum_size = Vector2(8,0)
	panel.add_child(sc)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size=Vector2(500,0); vb.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation",4); sc.add_child(vb)
	# Group by category
	var cn := {0:"GENEL",1:"SALDIRI",2:"SAVUNMA",3:"YETENEK"}
	var bc: Array = [[],[],[],[]]
	for uid in PersistentUpgrades.UPGRADES.keys():
		var def: Dictionary = PersistentUpgrades.UPGRADES[uid]
		var c: int = def.get("category",-1)
		if c>=0 and c<4: bc[c].append([uid,def])
	for ci in 4:
		var items: Array = bc[ci]
		if items.is_empty(): continue
		var hdr := HBoxContainer.new(); hdr.size_flags_horizontal=Control.SIZE_EXPAND_FILL; vb.add_child(hdr)
		var ll := ColorRect.new(); ll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		ll.custom_minimum_size=Vector2(0,1); ll.color=Color(0.3,0.4,0.6,0.4); hdr.add_child(ll)
		var cl := Label.new(); cl.text=cn.get(ci,"")
		cl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		cl.add_theme_font_size_override("font_size",FONT_SECTION)
		cl.add_theme_color_override("font_color",Color(0.5,0.7,0.9,0.9))
		cl.custom_minimum_size=Vector2(100,0); hdr.add_child(cl)
		var rl := ColorRect.new(); rl.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		rl.custom_minimum_size=Vector2(0,1); rl.color=Color(0.3,0.4,0.6,0.4); hdr.add_child(rl)
		var sp := Control.new(); sp.custom_minimum_size=Vector2(0,3); vb.add_child(sp)
		var gr := GridContainer.new(); gr.columns=2
		gr.add_theme_constant_override("h_separation",8); gr.add_theme_constant_override("v_separation",4)
		gr.size_flags_horizontal=Control.SIZE_EXPAND_FILL; vb.add_child(gr)
		for p in items:
			var it := _make_card(p[0],p[1]); it.size_flags_horizontal=Control.SIZE_EXPAND_FILL; gr.add_child(it)
	return panel

func _make_card(uid: String, def: Dictionary) -> Panel:
	var card := Panel.new(); card.custom_minimum_size=Vector2(0,58)
	var bg := StyleBoxFlat.new(); bg.bg_color=CARD_BG; bg.border_color=CARD_BORDER
	bg.border_width_bottom=1; bg.set_corner_radius_all(4); card.add_theme_stylebox_override("panel",bg)
	var cost: int = persistent_upgrades.get_upgrade_cost(uid)
	var lvl: int = persistent_upgrades.get_level(uid); var maxl: int = def.get("max_level",1); var is_max: bool = cost<0

	# Hover helper - captures card+bg so hover always reverts
	var _set_hovered := func(hovered: bool) -> void:
		if not is_instance_valid(card): return
		if hovered:
			var hs:=StyleBoxFlat.new(); hs.bg_color=Color(0.1,0.1,0.16,0.9); hs.border_color=Color(0.3,0.4,0.6,0.6)
			hs.border_width_left=1; hs.border_width_right=1; hs.border_width_top=1; hs.border_width_bottom=1
			hs.set_corner_radius_all(4); card.add_theme_stylebox_override("panel",hs)
		else:
			card.add_theme_stylebox_override("panel",bg)
	card.mouse_entered.connect(_set_hovered.bind(true))
	card.mouse_exited.connect(_set_hovered.bind(false))
	var hb := HBoxContainer.new()
	hb.anchor_left=0.0; hb.anchor_right=1.0; hb.anchor_top=0.0; hb.anchor_bottom=1.0
	hb.offset_left=8; hb.offset_right=-8; hb.offset_top=4; hb.offset_bottom=-4; card.add_child(hb)
	var vb := VBoxContainer.new(); vb.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation",1); hb.add_child(vb)
	var nl := Label.new(); nl.text=def.get("icon","•")+" "+def.get("name",uid)
	nl.add_theme_font_size_override("font_size",12); nl.add_theme_color_override("font_color",ACCENT_SUBTLE); vb.add_child(nl)
	var vv: float = persistent_upgrades.get_value(uid)
	var dl := Label.new(); dl.text=def.get("description","").format({"value":"%.1f"%vv})
	dl.add_theme_font_size_override("font_size",FONT_TINY); dl.add_theme_color_override("font_color",TEXT_MUTED)
	dl.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; vb.add_child(dl)
	var btn := Button.new(); btn.custom_minimum_size=Vector2(130,0); btn.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size",FONT_TINY)
	btn.add_theme_stylebox_override("normal",_make_s(Color(0.1,0.1,0.15,0.6),Color(0.25,0.25,0.3,0.4)))
	btn.add_theme_stylebox_override("hover",_make_s(Color(0.15,0.15,0.22,0.8),Color(0.4,0.5,0.7,0.6),1))
	if is_max: btn.text="MAX"; btn.disabled=true; btn.add_theme_color_override("font_color",SUCCESS)
	else:
		var ca: bool = _get_player_gold()>=cost
		btn.text="✦%d  Lv.%d/%d"%[cost,lvl,maxl]
		btn.add_theme_color_override("font_color",ACCENT_GOLD if ca else DANGER)
		btn.pressed.connect(_on_buy_upgrade.bind(uid))
	hb.add_child(btn); return card

func _on_buy_upgrade(uid: String) -> void:
	var cost: int = persistent_upgrades.get_upgrade_cost(uid)
	if cost<0: return
	var gold: int = _get_player_gold()
	if gold<cost: _show_message("Yetersiz altın!",true); return
	if persistent_upgrades.purchase_upgrade(uid,float(cost)):
		_show_message("Yükseltme alındı!"); _close_panel(); _show_upgrades_panel()
	else: _show_message("Yükseltme alınamadı!",true)

## ─── SETTINGS ───
func _show_settings_panel() -> void:
	if _current_panel: _current_panel.queue_free()
	var settings = GameSettings.get_instance()
	var panel := Panel.new(); panel.name="SettingsPanel"
	panel.anchor_left=0.25; panel.anchor_right=0.75; panel.anchor_top=0.25; panel.anchor_bottom=0.75
	panel.add_theme_stylebox_override("panel",_make_s(PANEL_BG,Color(0.7,0.7,0.75,0.8),2,8))
	_current_panel=panel; add_child(panel)
	panel.scale=Vector2(0.85,0.85); panel.modulate=Color(1,1,1,0)
	var tw:=create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel,"scale",Vector2.ONE,0.25); tw.tween_property(panel,"modulate",Color.WHITE,0.2)
	# Title
	var title:=Label.new(); title.text="⚙ AYARLAR"
	title.anchor_left=0.5; title.anchor_right=0.5; title.anchor_top=0.0; title.anchor_bottom=0.0
	title.offset_left=-80; title.offset_right=80; title.offset_top=15; title.offset_bottom=48
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",FONT_PANEL_TITLE); title.add_theme_color_override("font_color",TEXT_MAIN)
	panel.add_child(title)
	# Close
	var cb:=Button.new(); cb.text="✕"; cb.anchor_left=1.0; cb.anchor_right=1.0; cb.anchor_top=0.0; cb.anchor_bottom=0.0
	cb.offset_left=-50; cb.offset_right=-12; cb.offset_top=10; cb.offset_bottom=42
	cb.add_theme_font_size_override("font_size",18)
	cb.add_theme_color_override("font_color",TEXT_MUTED); cb.add_theme_color_override("font_hover_color",Color.WHITE)
	cb.add_theme_stylebox_override("normal",_make_s(Color.TRANSPARENT,Color.TRANSPARENT))
	cb.add_theme_stylebox_override("hover",_make_s(Color(0.15,0.15,0.2,0.5),Color.TRANSPARENT,0,4))
	cb.pressed.connect(_close_panel); panel.add_child(cb)
	# Content
	var ct:=VBoxContainer.new(); ct.anchor_left=0.1; ct.anchor_right=0.9; ct.anchor_top=0.16; ct.anchor_bottom=0.92
	ct.add_theme_constant_override("separation",12); panel.add_child(ct)
	ct.add_child(_slider_row("Ses Seviyesi",settings.master_volume,func(v):settings.set_master_volume(v)))
	ct.add_child(_slider_row("Müzik",settings.music_volume,func(v):settings.set_music_volume(v)))
	ct.add_child(_slider_row("Efektler",settings.sfx_volume,func(v):settings.set_sfx_volume(v)))
	ct.add_child(_toggle_row("Tam Ekran",settings.fullscreen,func(v):settings.set_fullscreen(v)))
	ct.add_child(_toggle_row("VSync",settings.vsync,func(v):settings.set_vsync(v)))

func _slider_row(label_text: String, init: float, cb: Callable) -> HBoxContainer:
	var r:=HBoxContainer.new(); r.custom_minimum_size=Vector2(0,38)
	var l:=Label.new(); l.text=label_text; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size",FONT_SMALL); l.add_theme_color_override("font_color",TEXT_MAIN); r.add_child(l)
	var p:=Label.new(); p.text="%d%%"%int(init*100); p.custom_minimum_size=Vector2(38,0)
	p.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; p.add_theme_font_size_override("font_size",FONT_SMALL)
	p.add_theme_color_override("font_color",ACCENT_GOLD); r.add_child(p)
	var s:=HSlider.new(); s.size_flags_horizontal=Control.SIZE_EXPAND_FILL; s.min_value=0; s.max_value=100; s.value=init*100
	s.value_changed.connect(func(v:float): p.text="%d%%"%int(v); cb.call(v/100.0)); r.add_child(s); return r

func _toggle_row(label_text: String, def: bool, cb: Callable) -> HBoxContainer:
	var r:=HBoxContainer.new(); r.custom_minimum_size=Vector2(0,38)
	var l:=Label.new(); l.text=label_text; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size",FONT_SMALL); l.add_theme_color_override("font_color",TEXT_MAIN); r.add_child(l)
	var c:=CheckButton.new(); c.button_pressed=def; c.toggled.connect(cb); r.add_child(c); return r

## ─── MESSAGE ───
func _show_message(text: String, is_error: bool = false) -> void:
	var panel:=Panel.new()
	panel.anchor_left=0.5; panel.anchor_right=0.5; panel.anchor_top=0.5; panel.anchor_bottom=0.5
	panel.offset_left=-180; panel.offset_right=180; panel.offset_top=-30; panel.offset_bottom=30
	panel.add_theme_stylebox_override("panel",_make_s(Color(0.05,0.05,0.1,0.95),Color(1.0,0.85,0.4,0.8) if not is_error else DANGER,2,6))
	panel.z_index=200; add_child(panel)
	var lb:=Label.new(); lb.text=text; lb.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; lb.anchor_left=0.0; lb.anchor_right=1.0
	lb.anchor_top=0.0; lb.anchor_bottom=1.0; lb.offset_left=15; lb.offset_right=-15
	lb.add_theme_color_override("font_color",HIGHLIGHT if not is_error else DANGER)
	lb.add_theme_font_size_override("font_size",16); panel.add_child(lb)
	panel.modulate=Color(1,1,1,0)
	var tw:=create_tween(); tw.tween_property(panel,"modulate",Color.WHITE,0.2)
	tw.tween_property(panel,"modulate:a",0.0,0.5).set_delay(1.8); tw.tween_callback(panel.queue_free)

## ─── HELPERS ───
func _get_player_gold() -> int: return int(persistent_upgrades.get_spendable_gold())
func _has_save_file() -> bool: return FileAccess.file_exists("user://savegame.save")
func _format_number(n: float) -> String:
	if n>=1000000: return "%.1fM"%(n/1000000.0)
	elif n>=1000: return "%.1fK"%(n/1000.0)
	return str(int(n))
func _continue_game() -> void: persistent_upgrades.increment_games_played(); continue_game.emit()
func _start_new_game() -> void: persistent_upgrades.increment_games_played(); start_new_game.emit()
