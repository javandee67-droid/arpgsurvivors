extends CanvasLayer
class_name GameUI

signal essence_inventory_changed
enum LeftTab { INVENTORY }

const INV_COLUMNS: int = 8
const EQUIP_SLOT_SIZE := Vector2(48, 48)
const TEXT_COLOR := Color(0.85, 0.82, 0.78)
const SLOT_ENUM_TO_NAME: Dictionary = {
	0: "weapon", 1: "offhand", 2: "helmet", 3: "body_armour",
	4: "gloves", 5: "boots", 6: "belt", 7: "amulet", 8: "ring_1", 9: "ring_2"
}

var _drag_item: ItemData = null
var _drag_source_idx: int = -1
var _drag_source_is_equipment: bool = false
var _drag_source_slot: int = -1
var _is_dragging: bool = false
var _drag_press_pos: Vector2 = Vector2.ZERO
var _drag_moved: bool = false
var _drag_ghost: TextureRect = null
var _active_left_tab: int = LeftTab.INVENTORY
var _connected: bool = false
var _inv_total_h: float = 640.0
var player = null  # type: Node (assigned at runtime)
var visible_ui: bool = false
var _left_content: Control = null
var _stats_label: RichTextLabel = null
var _notif_label: Label = null
var _tooltip_panel: Panel = null
var _tooltip_label: RichTextLabel = null
var _inv_scroll: ScrollContainer = null
var inventory_grid: GridContainer = null
var _anvil_zone: Control = null
# Anvil islem durumu (crafting)
var _anvil_item_slot: TextureRect = null  ## Item slot görseli
var _essence_grid: GridContainer = null
var _essence_buttons: Array[Button] = []
var equipment_slot_buttons: Array[Button] = []
var _right_vbox: VBoxContainer = null
var _off_label: RichTextLabel = null
var _def_label: RichTextLabel = null
var _util_label: RichTextLabel = null
var _off_arrow: Button = null
var _def_arrow: Button = null
var _util_arrow: Button = null
var _off_expanded: bool = true
var _def_expanded: bool = true
var _util_expanded: bool = true
var _off_header: HBoxContainer = null
var _def_header: HBoxContainer = null
var _util_header: HBoxContainer = null

func _ready() -> void:
	layer = 55
	visible = false
	process_mode = PROCESS_MODE_ALWAYS
	_build_ui()
	# Envanter sinyallerini hemen bagla — ilk item alindiginda UI kapali olsa bile
	# inventory_changed tetiklensin diye. _open_ui() icinde de ayrica baglanir (cift baglanti zararsiz).
	call_deferred("_try_connect_early_inventory_signal")

func _try_connect_early_inventory_signal() -> void:
	"""Player hazir oldugunda inventory sinyallerini erken bagla.
	Sadece inventory sinyallerini baglar. _connected=true yapmaz,
	boylece _open_ui() icindeki _connect_signals() diger sinyalleri
	de baglayabilir."""
	var p := get_tree().get_first_node_in_group("player")
	if p:
		var inv := p.get_node_or_null("Inventory")
		if inv:
			if not inv.inventory_changed.is_connected(_update_inventory):
				inv.inventory_changed.connect(_update_inventory)
			if not inv.item_added.is_connected(_on_inventory_item_added):
				inv.item_added.connect(_on_inventory_item_added)
	else:
		call_deferred("_try_connect_early_inventory_signal")

func _on_inventory_item_added(item: ItemData) -> void:
	"""Envantere item eklenince kisa bir bildirim goster."""
	if not item:
		return
	# Item adini ust-orta ekranda 2sn goster
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.append_text("[color=#aadd88][center]+ [/center][/color]" + item.display_name)
	lbl.add_theme_color_override("default_color", Color(0.7, 0.85, 0.7))
	lbl.add_theme_font_size_override("normal_font_size", 14)
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.position = Vector2(get_viewport().size.x / 2 - 100, 80)
	lbl.size = Vector2(200, 24)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.z_index = 1000
	add_child(lbl)
	# 2sn sonra kaybol
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(lbl, "modulate", Color(1, 1, 1, 0), 0.5)
	tw.tween_callback(lbl.queue_free)

func _panel_style(p: Panel) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	p.add_theme_stylebox_override("panel", s)
	var bc := ColorRect.new()
	bc.color = Color(0.04, 0.04, 0.06, 0.92)
	bc.size = p.size
	bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(bc)
	var border := StyleBoxFlat.new()
	border.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	border.border_width_left = 1
	border.border_width_right = 1
	border.border_width_top = 1
	border.border_width_bottom = 1
	border.border_color = Color(0.2, 0.18, 0.25, 0.6)
	border.set_corner_radius_all(6)
	p.add_theme_stylebox_override("panel", border)

func _build_right_stats(right_w: float, parent: Control = null) -> void:
	_right_vbox = VBoxContainer.new()
	_right_vbox.name = "RightStats"
	_right_vbox.position = Vector2(4, 4)
	_right_vbox.size = Vector2(right_w - 8, 0)
	_right_vbox.add_theme_constant_override("separation", 6)
	_right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if parent: parent.add_child(_right_vbox)
	else: get_node("RightPanel").add_child(_right_vbox)
	_off_header = _make_section_header("SALDIRI", "_off_label")
	_right_vbox.add_child(_off_header)
	_off_label = RichTextLabel.new()
	_off_label.name = "OffLabel"
	_off_label.bbcode_enabled = true
	_off_label.fit_content = true
	_off_label.scroll_active = false
	_off_label.add_theme_color_override("default_color", TEXT_COLOR)
	_off_label.add_theme_font_size_override("normal_font_size", 10)
	_off_label.custom_minimum_size = Vector2(right_w, 0)
	_right_vbox.add_child(_off_label)
	_right_vbox.add_child(HSeparator.new())
	_def_header = _make_section_header("SAVUNMA", "_def_label")
	_right_vbox.add_child(_def_header)
	_def_label = RichTextLabel.new()
	_def_label.name = "DefLabel"
	_def_label.bbcode_enabled = true
	_def_label.fit_content = true
	_def_label.scroll_active = false
	_def_label.add_theme_color_override("default_color", TEXT_COLOR)
	_def_label.add_theme_font_size_override("normal_font_size", 10)
	_def_label.custom_minimum_size = Vector2(right_w, 0)
	_right_vbox.add_child(_def_label)
	_right_vbox.add_child(HSeparator.new())
	_util_header = _make_section_header("YARDIMCI", "_util_label")
	_right_vbox.add_child(_util_header)
	_util_label = RichTextLabel.new()
	_util_label.name = "UtilLabel"
	_util_label.bbcode_enabled = true
	_util_label.fit_content = true
	_util_label.scroll_active = false
	_util_label.add_theme_color_override("default_color", TEXT_COLOR)
	_util_label.add_theme_font_size_override("normal_font_size", 10)
	_util_label.custom_minimum_size = Vector2(right_w, 0)
	_right_vbox.add_child(_util_label)
	_update_right_stats()

func _make_char_spriteframes(class_id: String) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_loop("idle", true)
	sf.set_animation_speed("idle", 6)
	var tex_path: String = "res://assets/generated/char_%s_idle.png" % class_id
	if not ResourceLoader.exists(tex_path):
		tex_path = "res://assets/generated/char_warrior_idle.png"
	if not ResourceLoader.exists(tex_path):
		return sf
	var tex := load(tex_path) as Texture2D
	if not tex:
		return sf
	# Try to load metadata JSON for frame regions
	var meta_path: String = tex_path.get_basename() + ".metadata.json"
	var regions: Array = []
	if ResourceLoader.exists(meta_path):
		var f := FileAccess.open(meta_path, FileAccess.READ)
		if f:
			var j := JSON.new()
			if j.parse(f.get_as_text()) == OK:
				var d = j.get_data()
				regions = d.get("frame_regions", [])
	if regions.size() > 0:
		for r in regions:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(r.x, r.y, r.w, r.h)
			sf.add_frame("idle", at)
	else:
		# Manual split: 4 cols x 2 rows, each 96x96
		var fw := 96; var fh := 96; var cols := 4; var rows := 2
		for row in rows:
			for col in cols:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(col * fw, row * fh, fw, fh)
				sf.add_frame("idle", at)
	return sf

func _kill_char_tweens() -> void:
	if _char_tween: _char_tween.kill(); _char_tween = null
	if _char_tween2: _char_tween2.kill(); _char_tween2 = null

func _sync_char_sprite() -> void:
	if not _left_content: return
	var doll := _left_content.get_node_or_null("PaperdollSection")
	if not doll: return
	var portrait := doll.get_node_or_null("CharPortrait") as AnimatedSprite2D
	if not portrait: return
	var class_id := "warrior"
	if player and not player.character_class.is_empty():
		class_id = player.character_class.to_lower()
	var sf := _make_char_spriteframes(class_id)
	portrait.sprite_frames = sf
	if sf.get_animation_names().size() > 0:
		portrait.play(sf.get_animation_names()[0])

func _make_section_header(title: String, label_var_name: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var arrow := Button.new()
	arrow.text = "v"
	arrow.flat = true
	arrow.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	arrow.add_theme_font_size_override("font_size", 10)
	arrow.custom_minimum_size = Vector2(16, 16)
	arrow.pressed.connect(_toggle_section.bind(label_var_name))
	hb.add_child(arrow)
	if label_var_name == "_off_label": _off_arrow = arrow
	if label_var_name == "_def_label": _def_arrow = arrow
	if label_var_name == "_util_label": _util_arrow = arrow
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 12)
	var hdr_color: Color
	match label_var_name:
		"_off_label": hdr_color = Color(0.83, 0.72, 0.48)  # gold
		"_def_label": hdr_color = Color(0.48, 0.72, 0.91)  # blue
		"_util_label": hdr_color = Color(0.48, 0.91, 0.63)  # green
		_: hdr_color = Color(0.65, 0.65, 0.7)
	lbl.add_theme_color_override("font_color", hdr_color)
	var bold_font := Theme.new()
	lbl.theme = bold_font
	hb.add_child(lbl)
	hb.add_theme_constant_override("separation", 4)
	# thin accent line below
	var spacer := ColorRect.new()
	spacer.custom_minimum_size = Vector2(0, 1)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.color = Color(hdr_color.r, hdr_color.g, hdr_color.b, 0.3)
	hb.add_child(spacer)
	return hb

func _toggle_section(label_var_name: String) -> void:
	match label_var_name:
		"_off_label": _off_expanded = not _off_expanded; _off_arrow.text = "v" if _off_expanded else ">"; _off_label.visible = _off_expanded
		"_def_label": _def_expanded = not _def_expanded; _def_arrow.text = "v" if _def_expanded else ">"; _def_label.visible = _def_expanded
		"_util_label": _util_expanded = not _util_expanded; _util_arrow.text = "v" if _util_expanded else ">"; _util_label.visible = _util_expanded

func _build_ui() -> void:
	var vp := get_viewport()
	var w: float = vp.size.x
	var h: float = vp.size.y
	var bg := ColorRect.new()
	bg.name = "UIBg"
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.size = Vector2(w, h)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	var right_w := 300.0
	var left_w: float = w - right_w
	var left_panel := Panel.new()
	left_panel.name = "LeftPanel"
	left_panel.position = Vector2(0, 0)
	left_panel.size = Vector2(left_w, h)
	_panel_style(left_panel)
	add_child(left_panel)
	_left_content = Control.new()
	_left_content.name = "LeftContent"
	_left_content.position = Vector2(10, 10)
	_left_content.size = Vector2(left_w - 20, h - 20)
	left_panel.add_child(_left_content)
	var right_panel := Panel.new()
	right_panel.name = "RightPanel"
	right_panel.position = Vector2(left_w, 0)
	right_panel.size = Vector2(right_w, h)
	_panel_style(right_panel)
	add_child(right_panel)
	var right_scroll := ScrollContainer.new()
	right_scroll.name = "RightScroll"
	right_scroll.position = Vector2(0, 0)
	right_scroll.size = Vector2(right_w, h)
	right_scroll.clip_contents = true
	right_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	right_panel.add_child(right_scroll)
	_build_right_stats(right_w - 16, right_scroll)
	_build_inventory_content()
	_build_tooltip()
	_show_left_tab(LeftTab.INVENTORY)
	var pt_timer := Timer.new()
	pt_timer.name = "PTSync"
	pt_timer.timeout.connect(_sync_skill_points)
	pt_timer.wait_time = 0.5
	pt_timer.autostart = true
	add_child(pt_timer)

func _build_inventory_content() -> void:
	for c in _left_content.get_children():
		c.free()
	equipment_slot_buttons.clear()
	_essence_buttons.clear()
	_char_init_breathe = false
	_kill_char_tweens()
	_essence_grid = null
	var c := _left_content
	var w: float = c.size.x
	var total_h: float = max(c.size.y, 640.0)
	_inv_total_h = total_h
	var esz := EQUIP_SLOT_SIZE
	var doll_h: float = min(esz.y * 5.0 + 40.0, 300.0)
	var doll_section := Control.new()
	doll_section.name = "PaperdollSection"
	doll_section.position = Vector2(0, 0)
	doll_section.size = Vector2(w, doll_h)
	c.add_child(doll_section)
	var portrait_sz: float = min(w * 0.40, 160.0)
	var portrait_x: float = w * 0.5 - portrait_sz * 0.5
	var portrait_y: float = 18.0
	var btn_helm := _make_equip_btn(Equipment.Slot.HELMET)
	btn_helm.position = Vector2(w * 0.5 - esz.x * 0.5, 0)
	doll_section.add_child(btn_helm)
	var class_id: String = "warrior"
	if player and not player.character_class.is_empty():
		class_id = player.character_class.to_lower()
	# Character portrait sprite — static image from portrait_frame_0
	var tex_p := "res://assets/generated/char_%s_portrait_frame_0.png" % class_id
	if not ResourceLoader.exists(tex_p):
		tex_p = "res://assets/generated/char_warrior_portrait_frame_0.png"
	var portrait2 := Sprite2D.new()
	portrait2.name = "CharPortrait"
	portrait2.centered = true
	portrait2.scale = Vector2(portrait_sz / 96.0, portrait_sz / 96.0)
	portrait2.position = Vector2(portrait_x + portrait_sz * 0.5, portrait_y + portrait_sz * 0.5)
	if ResourceLoader.exists(tex_p):
		portrait2.texture = load(tex_p) as Texture2D
	doll_section.add_child(portrait2)
	var left_x: float = max(portrait_x - esz.x - 6.0, 4.0)
	var right_x: float = min(portrait_x + portrait_sz + 6.0, w - esz.x - 4.0)
	var left_items := [Equipment.Slot.WEAPON, Equipment.Slot.GLOVES, Equipment.Slot.RING_1, Equipment.Slot.BELT]
	var col_y: float = portrait_y + 4.0
	var gap: float = (portrait_sz - 4.0 - left_items.size() * esz.y) / float(left_items.size() - 1) if left_items.size() > 1 else 4.0
	if gap < 4.0: gap = 4.0
	for i in left_items.size():
		var btn := _make_equip_btn(left_items[i])
		btn.position = Vector2(left_x, col_y + float(i) * (esz.y + gap))
		doll_section.add_child(btn)
	var right_items := [Equipment.Slot.OFFHAND, Equipment.Slot.BODY_ARMOUR, Equipment.Slot.RING_2, Equipment.Slot.AMULET]
	for i in right_items.size():
		var btn := _make_equip_btn(right_items[i])
		btn.position = Vector2(right_x, col_y + float(i) * (esz.y + gap))
		doll_section.add_child(btn)
	var belt_y: float = portrait_y + portrait_sz + 4.0
	var btn_boots := _make_equip_btn(Equipment.Slot.BOOTS)
	btn_boots.position = Vector2(w * 0.5 - esz.x * 0.5, belt_y)
	doll_section.add_child(btn_boots)
	_build_stat_panel(doll_section, w, doll_h)
	var stats_y: float = doll_h + 2
	_stats_label = RichTextLabel.new()
	_stats_label.name = "StatsLabel"
	_stats_label.position = Vector2(4, stats_y)
	_stats_label.size = Vector2(w - 8, 0)
	_stats_label.bbcode_enabled = true
	_stats_label.scroll_active = false
	_stats_label.fit_content = true
	_stats_label.add_theme_color_override("default_color", TEXT_COLOR)
	_stats_label.add_theme_font_size_override("normal_font_size", 11)
	c.add_child(_stats_label)
	var cell_sz := 40.0
	var sep := 3.0
	var row_h: float = cell_sz + sep
	var grid_w: float = INV_COLUMNS * cell_sz + (INV_COLUMNS - 1) * sep
	var inv_y: float = stats_y + 72.0
	var avail_h: float = max(total_h - inv_y - 4, 0.0)
	var visible_rows: int = maxi(floori(avail_h / row_h), 6)
	var inv_h: float = visible_rows * row_h
	_inv_scroll = ScrollContainer.new()
	_inv_scroll.name = "InvScroll"
	_inv_scroll.position = Vector2(2, inv_y)
	_inv_scroll.size = Vector2(grid_w, inv_h)
	_inv_scroll.clip_contents = true
	_inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_inv_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	c.add_child(_inv_scroll)
	var grid := GridContainer.new()
	grid.name = "InvGrid"
	grid.columns = INV_COLUMNS
	grid.add_theme_constant_override("h_separation", sep)
	grid.add_theme_constant_override("v_separation", sep)
	grid.size_flags_horizontal = Control.SIZE_FILL
	_inv_scroll.add_child(grid)
	inventory_grid = grid
	_notif_label = Label.new()
	_notif_label.name = "EquipNotif"
	_notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_label.custom_minimum_size = Vector2(grid_w, 24)
	_notif_label.size = Vector2(grid_w, 24)
	_notif_label.add_theme_font_size_override("font_size", 11)
	_notif_label.visible = false
	_notif_label.modulate = Color(0.95, 0.3, 0.3, 0.0)
	_notif_label.position = Vector2(2, inv_y + inv_h - 24)
	c.add_child(_notif_label)
	# Essence grid: inventory'nin saginda, ayni Y'de
	var ess_cell := 40.0; var ess_sep := 4.0
	var ess_rows := 4; var ess_cols := 4
	var ess_gw: float = ess_cell * ess_cols + ess_sep * (ess_cols - 1)
	var ess_gh: float = ess_cell * ess_rows + ess_sep * (ess_rows - 1)
	var ess_grid_x: float = grid_w + 10.0
	_essence_grid = GridContainer.new()
	_essence_grid.name = "EssenceGrid"
	_essence_grid.columns = ess_cols
	_essence_grid.position = Vector2(ess_grid_x, inv_y + 14)
	_essence_grid.size = Vector2(ess_gw, ess_gh)
	_essence_grid.add_theme_constant_override("h_separation", ess_sep)
	_essence_grid.add_theme_constant_override("v_separation", ess_sep)
	c.add_child(_essence_grid)
	var ess_header := Label.new()
	ess_header.text = "OZLER"
	ess_header.position = Vector2(ess_grid_x, inv_y)
	ess_header.size = Vector2(ess_gw, 14)
	ess_header.add_theme_color_override("font_color", Color(0.55, 0.35, 0.95))
	ess_header.add_theme_font_size_override("font_size", 9)
	c.add_child(ess_header)
	for i in range(ess_rows * ess_cols):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(ess_cell, ess_cell)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 8)
		_style_inv_btn(btn)
		var s2 := StyleBoxFlat.new()
		s2.bg_color = Color(0.1, 0.07, 0.15, 0.9)
		s2.border_color = Color(0.45, 0.3, 0.6, 0.6)
		s2.border_width_left = 1; s2.border_width_right = 1
		s2.border_width_top = 1; s2.border_width_bottom = 1
		s2.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", s2)
		btn.add_theme_stylebox_override("pressed", s2)
		btn.add_theme_stylebox_override("hover", s2)
		btn.set_meta("essence_slot", i)
		# Tooltip hover (click/pressed yok — sadece drag ile item üstüne bırak)
		btn.mouse_entered.connect(_on_essence_slot_hover.bind(i))
		btn.mouse_exited.connect(_on_inv_slot_unhover)
		_essence_grid.add_child(btn)
		_essence_buttons.append(btn)
	# ─── ÖRS (Sadece item parçalama) ────────────────────────────
	var anvil_x2: float = ess_grid_x
	var anvil_y2: float = inv_y + 14 + ess_gh + 8.0
	var anvil_w2 := 138.0
	var anvil_h2 := 62.0
	_anvil_zone = Control.new()
	_anvil_zone.name = "AnvilZone"
	_anvil_zone.position = Vector2(anvil_x2, anvil_y2)
	_anvil_zone.size = Vector2(anvil_w2, anvil_h2)
	_anvil_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(_anvil_zone)
	var a_bg := ColorRect.new()
	a_bg.color = Color(0.08, 0.06, 0.12, 0.85)
	a_bg.size = Vector2(anvil_w2, anvil_h2)
	a_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var a_border := StyleBoxFlat.new()
	a_border.bg_color = Color(0.08, 0.06, 0.12, 0.85)
	a_border.border_width_left = 2; a_border.border_width_right = 2
	a_border.border_width_top = 2; a_border.border_width_bottom = 2
	a_border.border_color = Color(0.4, 0.25, 0.55, 0.7)
	a_border.set_corner_radius_all(8)
	a_bg.add_theme_stylebox_override("panel", a_border)
	_anvil_zone.add_child(a_bg)
	# Başlık + alt yazı
	var a_label := Label.new()
	a_label.text = "ÖRS"
	a_label.add_theme_font_size_override("font_size", 12)
	a_label.add_theme_color_override("font_color", Color(0.65, 0.55, 0.85, 0.8))
	a_label.position = Vector2(6, 2)
	a_label.size = Vector2(60, 16)
	a_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anvil_zone.add_child(a_label)
	var a_hint := Label.new()
	a_hint.text = "İtem bırak → parçala"
	a_hint.add_theme_font_size_override("font_size", 8)
	a_hint.add_theme_color_override("font_color", Color(0.5, 0.4, 0.6, 0.6))
	a_hint.position = Vector2(50, 4)
	a_hint.size = Vector2(84, 12)
	a_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anvil_zone.add_child(a_hint)
	# İtem slotu (tek slot — görsel)
	_anvil_item_slot = TextureRect.new()
	_anvil_item_slot.name = "AnvilItemSlot"
	_anvil_item_slot.position = Vector2(8, 20)
	_anvil_item_slot.size = Vector2(36, 36)
	_anvil_item_slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_anvil_item_slot.modulate = Color(0.4, 0.4, 0.5, 0.3)
	var a_item_slot_bg := ColorRect.new()
	a_item_slot_bg.color = Color(0.15, 0.12, 0.2, 0.8)
	a_item_slot_bg.size = Vector2(36, 36)
	a_item_slot_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anvil_item_slot.add_child(a_item_slot_bg)
	_anvil_zone.add_child(_anvil_item_slot)
	# Info yazısı (sağda)
	var a_info := Label.new()
	a_info.text = "Parçalanan\nitem'lar orba\ndönüşür"
	a_info.add_theme_font_size_override("font_size", 7)
	a_info.add_theme_color_override("font_color", Color(0.55, 0.45, 0.65, 0.7))
	a_info.position = Vector2(52, 22)
	a_info.size = Vector2(80, 36)
	a_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anvil_zone.add_child(a_info)

func _make_equip_btn(slot: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = EQUIP_SLOT_SIZE
	btn.text = Equipment.Slot.keys()[slot].capitalize()
	btn.add_theme_font_size_override("font_size", 7)
	btn.set_meta("slot_enum", slot)
	_style_inv_btn(btn)
	equipment_slot_buttons.append(btn)
	return btn

func _style_inv_btn(btn: Button) -> void:
	var normal_s := StyleBoxFlat.new()
	normal_s.bg_color = Color(0.15, 0.12, 0.18, 0.95)
	normal_s.border_color = Color(0.55, 0.5, 0.65, 0.75)
	normal_s.border_width_left = 1; normal_s.border_width_right = 1
	normal_s.border_width_top = 1; normal_s.border_width_bottom = 1
	normal_s.set_corner_radius_all(4)
	var hover_s := StyleBoxFlat.new()
	hover_s.bg_color = Color(0.2, 0.16, 0.25, 0.95)
	hover_s.border_color = Color(0.7, 0.65, 0.8, 0.9)
	hover_s.border_width_left = 1; hover_s.border_width_right = 1
	hover_s.border_width_top = 1; hover_s.border_width_bottom = 1
	hover_s.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal_s)
	btn.add_theme_stylebox_override("pressed", normal_s)
	btn.add_theme_stylebox_override("hover", hover_s)
	btn.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.93, 0.9))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))

func _build_stat_panel(parent: Control, w: float, doll_h: float) -> void:
	var panel := Panel.new()
	panel.name = "StatPanel"
	var pw: float = 114.0
	panel.position = Vector2(w - pw - 4.0, 4)
	panel.size = Vector2(pw, doll_h - 8)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.04, 0.06, 0.0)
	s.border_width_left = 1; s.border_width_right = 1
	s.border_width_top = 1; s.border_width_bottom = 1
	s.border_color = Color(0.15, 0.12, 0.2, 0.3)
	s.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", s)
	parent.add_child(panel)
	var stat_keys := ["strength", "dexterity", "intelligence"]
	var stat_names := ["STR", "DEX", "INT"]
	var stat_colors := [Color(0.9, 0.4, 0.3), Color(0.3, 0.8, 0.4), Color(0.3, 0.5, 0.9)]
	for i in 3:
		var row_y: float = 4.0 + float(i) * 22.0
		# "-" button
		var btn_minus := Button.new()
		btn_minus.name = stat_names[i] + "_Minus"
		btn_minus.position = Vector2(2, row_y)
		btn_minus.size = Vector2(18, 18)
		btn_minus.text = "-"
		btn_minus.add_theme_font_size_override("font_size", 12)
		btn_minus.add_theme_constant_override("outline_size", 0)
		# Store which stat this button modifies
		var stat_key: String = stat_keys[i]
		btn_minus.pressed.connect(_on_stat_minus.bind(stat_key))
		panel.add_child(btn_minus)

		# Value label
		var lbl := Label.new()
		lbl.name = stat_names[i]
		lbl.position = Vector2(22, row_y)
		lbl.size = Vector2(70, 18)
		lbl.add_theme_color_override("font_color", stat_colors[i])
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(lbl)

		# "+" button
		var btn_plus := Button.new()
		btn_plus.name = stat_names[i] + "_Plus"
		btn_plus.position = Vector2(pw - 20, row_y)
		btn_plus.size = Vector2(18, 18)
		btn_plus.text = "+"
		btn_plus.add_theme_font_size_override("font_size", 12)
		btn_plus.add_theme_constant_override("outline_size", 0)
		btn_plus.pressed.connect(_on_stat_plus.bind(stat_key))
		panel.add_child(btn_plus)

	# Remaining points label
	var rem := Label.new()
	rem.name = "RemainingLabel"
	rem.position = Vector2(2, 4.0 + 3.0 * 22.0)
	rem.size = Vector2(pw - 4, 18)
	rem.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	rem.add_theme_font_size_override("font_size", 11)
	rem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(rem)

func _build_tooltip() -> void:
	_tooltip_panel = Panel.new()
	_tooltip_panel.name = "TooltipPanel"
	_tooltip_panel.visible = false; _tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip_panel)
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.06, 0.04, 0.1, 0.97)
	s.border_width_left = 2; s.border_width_right = 2
	s.border_width_top = 2; s.border_width_bottom = 2
	s.border_color = Color(0.35, 0.28, 0.5, 0.8)
	s.border_blend = true
	s.set_corner_radius_all(6)
	s.set_corner_radius(CORNER_TOP_LEFT, 6)
	s.set_corner_radius(CORNER_TOP_RIGHT, 6)
	s.set_corner_radius(CORNER_BOTTOM_LEFT, 6)
	s.set_corner_radius(CORNER_BOTTOM_RIGHT, 6)
	s.content_margin_left = 10; s.content_margin_right = 10
	s.content_margin_top = 8; s.content_margin_bottom = 8
	_tooltip_panel.add_theme_stylebox_override("panel", s)
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.name = "TooltipContent"
	_tooltip_label.bbcode_enabled = true; _tooltip_label.scroll_active = false
	_tooltip_label.fit_content = true
	_tooltip_label.add_theme_color_override("default_color", TEXT_COLOR)
	_tooltip_label.add_theme_font_size_override("normal_font_size", 16)
	_tooltip_label.position = Vector2(8, 6); _tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.add_child(_tooltip_label)

func _get_item_icon(item: ItemData) -> Texture2D:
	if not item: return null
	if item.icon: return item.icon
	if item.item_type == "currency" and not item.id.is_empty():
		var icon_path: String = ItemData.CURRENCY_ICONS.get(item.id, "")
		if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
			return load(icon_path) as Texture2D
	# Item türüne/weapon_type'a göre otomatik ikon çözümle
	var auto_path := _resolve_type_icon(item)
	if not auto_path.is_empty() and ResourceLoader.exists(auto_path):
		return load(auto_path) as Texture2D
	var default_path: String = "res://assets/generated/icon_placeholder_frame_0.png"
	if ResourceLoader.exists(default_path):
		return load(default_path) as Texture2D
	return null

func _resolve_type_icon(item: ItemData) -> String:
	"""item weapon_type/equip_slot'a gore dogru ikon dosyasini bul."""
	# Silahlar weapon_type'a gore
	var weapon_map := {
		"sword": "icon_sword_frame_0.png",
		"axe": "icon_axe_frame_0.png",
		"dagger": "icon_dagger_frame_0.png",
		"staff": "icon_staff_frame_0.png",
		"bow": "icon_bow_frame_0.png",
		"wand": "icon_wand_frame_0.png",
	}
	if item.weapon_type in weapon_map:
		return "res://assets/generated/" + weapon_map[item.weapon_type]
	# Zirh/aksesuar equip_slot'a gore (item_type farkli olabilir: gloves/boots/body_armour vb.)
	var slot_map := {
		"body_armour": "icon_chest_v2_frame_0.png",
		"helmet": "icon_helmet_frame_0.png",
		"boots": "icon_boots_frame_0.png",
		"gloves": "icon_gloves_frame_0.png",
		"shield": "icon_shield_frame_0.png",
		"ring_1": "icon_ring_frame_0.png",
		"ring_2": "icon_ring_frame_0.png",
		"ring": "icon_ring_frame_0.png",
		"amulet": "icon_amulet_frame_0.png",
		"belt": "icon_belt_frame_0.png",
		"weapon": "icon_sword_frame_0.png",  # Generic silah yedek ikonu
	}
	if item.equip_slot in slot_map:
		return "res://assets/generated/" + slot_map[item.equip_slot]
	return ""

func _show_left_tab(tab: int) -> void:
	for c in _left_content.get_children(): c.queue_free()
	_char_init_breathe = false; _essence_grid = null; _essence_buttons.clear(); equipment_slot_buttons.clear()
	if _notif_label: _notif_label.visible = false
	match tab:
		LeftTab.INVENTORY: _build_inventory_content(); _update_inventory(); _update_essence_inventory(); _update_equipment(); _update_stats()

func _update_right_stats() -> void:
	if not player or not _off_label: return
	var stats: CharacterStats = player.stats
	var oc := "[color=#d4b87a]"
	var dc := "[color=#7ab8e8]"
	var uc := "[color=#7ae8a0]"
	var ec := "[/color]"
	var sh := "[b][color=#b8b4c0]"
	var se := "[/color][/b]"
	var nl := "\n"
	var level: int = player.level_system.level if player.level_system else 1
	_off_label.text = _fmt_off(stats, oc, ec, sh, se, nl)
	_def_label.text = _fmt_def(stats, dc, ec, sh, se, nl, level)
	_util_label.text = _fmt_util(stats, uc, ec, sh, se, nl)

func _fmt_off(stats: CharacterStats, oc: String, ec: String, sh: String, se: String, nl: String) -> String:
	var t := ""
	t += sh + "═══ HASAR ═══" + se + nl
	t += "Fiziksel Hasar: " + oc + "+" + str(int(stats.physical_damage_increased)) + "%" + ec + "  Element Hasarı: " + oc + "+" + str(int(stats.elemental_damage_increased)) + "%" + ec + nl
	t += "Ateş Hasarı: " + oc + "+" + str(int(stats.fire_damage_increased)) + "%" + ec + "  Soğuk Hasarı: " + oc + "+" + str(int(stats.cold_damage_increased)) + "%" + ec + nl
	t += "Yıldırım Hasarı: " + oc + "+" + str(int(stats.lightning_damage_increased)) + "%" + ec + "  Kaos Hasarı: " + oc + "+" + str(int(stats.chaos_damage_increased)) + "%" + ec + nl
	# Flat added elemental damage (adds_X_damage affix'leri)
	var flat_lines: Array[String] = []
	var phys_added: float = stats.physical_damage_flat - stats.total_strength * 1.0
	if phys_added > 0.0: flat_lines.append("Fiziksel " + oc + "+" + str(int(phys_added)) + ec)
	if stats.fire_damage_flat > 0.0: flat_lines.append("Ateş " + oc + "+" + str(int(stats.fire_damage_flat)) + ec)
	if stats.cold_damage_flat > 0.0: flat_lines.append("Soğuk " + oc + "+" + str(int(stats.cold_damage_flat)) + ec)
	if stats.lightning_damage_flat > 0.0: flat_lines.append("Yıldırım " + oc + "+" + str(int(stats.lightning_damage_flat)) + ec)
	if stats.chaos_damage_flat > 0.0: flat_lines.append("Kaos " + oc + "+" + str(int(stats.chaos_damage_flat)) + ec)
	if not flat_lines.is_empty():
		t += "Eklenen: " + "  ".join(flat_lines) + nl
	t += "Tüm Hasar: " + oc + "+" + str(int(stats.all_damage_increased)) + "%" + ec + nl
	t += "Zamanla Hasar: " + oc + "+" + str(int(stats.damage_over_time_increased)) + "%" + ec + nl
	t += "Mermi Hasarı: " + oc + "+" + str(int(stats.projectile_damage_increased)) + "%" + ec + "  Alan Hasarı: " + oc + "+" + str(int(stats.area_damage_increased)) + "%" + ec + nl
	t += "Sekme Sayısı: " + oc + str(stats.chain_count) + ec + "  İsabet Oranı: " + oc + str(int(stats.accuracy)) + "%" + ec + nl
	t += nl + sh + "═══ HIZ & KRİTİK ═══" + se + nl
	t += "Saldırı Hızı: " + oc + "+" + str(int((stats.attack_speed - 1.0) * 100.0)) + "%" + ec + "  Büyü Hızı: " + oc + "+" + str(int((stats.cast_speed - 1.0) * 100.0)) + "%" + ec + nl
	t += "Mermi Hızı: " + oc + "+" + str(int(stats.projectile_speed)) + "%" + ec + "  Bekleme Süresi: " + oc + "+" + str(int(stats.cooldown_recovery)) + "%" + ec + nl
	t += "Kritik Vuruş İhtimali: " + oc + str(int(stats.critical_chance)) + "%" + ec + "  Kritik Vuruş Hasarı: " + oc + "+" + str(int(stats.critical_multiplier - 100.0)) + "%" + ec + nl
	t += nl + sh + "═══ NÜFUZ ═══" + se + nl
	t += "Ateş Nüfuzu: " + oc + str(int(stats.penetration_fire)) + ec + "  Soğuk Nüfuzu: " + oc + str(int(stats.penetration_cold)) + ec + nl
	t += "Yıldırım Nüfuzu: " + oc + str(int(stats.penetration_lightning)) + ec + "  Kaos Nüfuzu: " + oc + str(int(stats.penetration_chaos)) + ec + nl
	t += "Tüm Element Nüfuzu: " + oc + str(int(stats.penetration_elemental)) + ec + nl
	return t

func _fmt_def(stats: CharacterStats, dc: String, ec: String, sh: String, se: String, nl: String, level: int = 1) -> String:
	var t := ""
	var armour_pct: float = snapped(stats.armour / (stats.armour + level * 100.0) * 100.0, 0.1)
	var evasion_pct: float = snapped(stats.evasion / (stats.evasion + level * 100.0) * 100.0, 0.1)
	t += sh + "═══ ZIRH & KAÇINMA ═══" + se + nl
	t += "Zırh: " + dc + str(int(stats.armour)) + " (%" + str(armour_pct) + ")" + ec + "  Kaçınma: " + dc + str(int(stats.evasion)) + " (%" + str(evasion_pct) + ")" + ec + nl
	t += "Enerji Kalkanı: " + dc + str(int(stats.max_energy_shield)) + ec + nl
	t += "Saldırı Bloklama Şansı: " + dc + str(int(stats.attack_block_chance * 100.0)) + "%" + ec + "  Büyü Bloklama Şansı: " + dc + str(int(stats.spell_block_chance * 100.0)) + "%" + ec + nl
	t += nl + sh + "═══ DİRENÇLER ═══" + se + nl
	t += "Ateş Direnci: " + dc + str(int(stats.fire_resistance)) + "%" + ec + "  Soğuk Direnci: " + dc + str(int(stats.cold_resistance)) + "%" + ec + nl
	t += "Yıldırım Direnci: " + dc + str(int(stats.lightning_resistance)) + "%" + ec + "  Kaos Direnci: " + dc + str(int(stats.chaos_resistance)) + "%" + ec + nl
	t += nl + sh + "═══ YENİLEME & EMME ═══" + se + nl
	t += "Can Yenileme: " + dc + "+" + str(int(stats.life_regen_per_second)) + "/s" + ec + nl
	t += "Mana Yenileme: " + dc + "+" + str(int(stats.mana_regen_per_second)) + "/s" + ec + nl
	t += "Enerji Kalkanı Yenileme: " + dc + "+" + str(int(stats.es_regen_per_second)) + "/s" + ec + nl
	t += "Can Emme Oranı: " + dc + str(int(stats.life_leech_percent)) + "%" + ec + "  Mana Emme Oranı: " + dc + str(int(stats.mana_leech_percent)) + "%" + ec + nl
	t += "Her Vuruşta Can: " + dc + str(int(stats.life_gain_on_hit)) + ec + "  Öldürme Başına Can: " + dc + str(int(stats.life_on_kill)) + ec + nl
	t += "Öldürme Başına Mana: " + dc + str(int(stats.mana_on_kill)) + ec + nl
	t += "Enerji Kalkanı Şarjı: " + dc + str(snapped(stats.es_recharge_delay, 0.1)) + "sn  " + str(int(stats.es_recharge_rate_percent)) + "%/sn" + ec + nl
	return t

func _fmt_util(stats: CharacterStats, uc: String, ec: String, sh: String, se: String, nl: String) -> String:
	var t := ""
	t += sh + "═══ TEMEL ═══" + se + nl
	var ms := int((stats.movement_speed - 1.0) * 100.0)
	t += "Hareket Hızı: " + uc + "+" + str(ms) + "%" + ec + "  Menzil: " + uc + "+" + str(int(stats.melee_range_bonus * 100.0)) + "%" + ec + nl
	var mana_node: Node = player.get_node_or_null("Mana")
	if mana_node:
		t += "Can: " + uc + str(player.health.current_health) + "/" + str(player.health.max_health) + ec + "  Mana: " + uc + str(mana_node.current_mana) + "/" + str(mana_node.max_mana) + ec + nl
	else:
		t += "Can: " + uc + str(player.health.current_health) + "/" + str(player.health.max_health) + ec + nl
	t += nl + sh + "═══ GERİ KAZANIM ═══" + se + nl
	t += "Can Geri Kazanım Hızı: " + uc + "+" + str(int(stats.life_recovery_rate)) + "%" + ec + "  Mana Geri Kazanım Hızı: " + uc + "+" + str(int(stats.mana_recovery_rate)) + "%" + ec + nl
	t += "Hasardan Geri Kazan (Can): " + uc + str(int(stats.life_recoup_pct)) + "%" + ec + "  (Mana): " + uc + str(int(stats.mana_recoup_pct)) + "%" + ec + "  Hız: " + uc + str(int(stats.recoup_speed)) + "%" + ec + nl
	t += nl + sh + "═══ EZİYET ═══" + se + nl
	t += "Eziyet Etkisi: " + uc + "+" + str(int(stats.ailment_effect)) + "%" + ec + "  Eziyet Şansı: " + uc + "+" + str(int(stats.ailment_chance)) + "%" + ec + nl
	t += "Eziyet Süresi: " + uc + "+" + str(int(stats.ailment_duration)) + "%" + ec + "  Eziyet Şiddeti: " + uc + "+" + str(int(stats.ailment_magnitude)) + "%" + ec + nl
	t += "Şok Büyüklüğü: " + uc + str(int(stats.shock_magnitude)) + ec + "  Üşüme Büyüklüğü: " + uc + str(int(stats.chill_magnitude)) + ec + nl
	t += "Tutuşma Büyüklüğü: " + uc + str(int(stats.ignite_magnitude)) + ec + "  Kanama Büyüklüğü: " + uc + str(int(stats.bleed_magnitude)) + ec + nl
	t += nl + sh + "═══ EŞYA ═══" + se + nl
	t += "Eşya Nadirliği: " + uc + "+" + str(int(stats.item_rarity)) + "%" + ec + "  Eşya Miktarı: " + uc + "+" + str(int(stats.item_quantity)) + "%" + ec + nl
	t += "Öldürme Eşiği: " + uc + str(int(stats.culling_threshold)) + "%" + ec + nl
	return t

func _sync_skill_points() -> void: pass

func _toggle_ui() -> void:
	if visible_ui: _close_ui()
	else: _open_ui()

func _open_ui() -> void:
	visible_ui = true; visible = true; get_tree().paused = true
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node
		_connected = false
	_active_left_tab = LeftTab.INVENTORY
	_show_left_tab(LeftTab.INVENTORY); _update_right_stats()
	call_deferred("_update_stat_panel")
	if not _connected: _connect_signals()

func _close_ui() -> void: visible_ui = false; visible = false; _hide_tooltip(); get_tree().paused = false

func ui_is_open() -> bool: return visible_ui

func _connect_signals() -> void:
	if not player: return
	if not player.inventory.inventory_changed.is_connected(_update_inventory):
		player.inventory.inventory_changed.connect(_update_inventory)
	if not player.essence_inventory.essence_inventory_changed.is_connected(_update_essence_inventory):
		player.essence_inventory.essence_inventory_changed.connect(_update_essence_inventory)
	if not player.equipment.equipment_changed.is_connected(_update_equipment):
		player.equipment.equipment_changed.connect(_update_equipment)
	if not player.stats.stats_changed.is_connected(_on_stats_changed):
		player.stats.stats_changed.connect(_on_stats_changed)
	if not player.health.health_changed.is_connected(_on_health_changed_for_stats):
		player.health.health_changed.connect(_on_health_changed_for_stats)
	var mana_node: Node = player.get_node_or_null("Mana")
	if mana_node and not mana_node.mana_changed.is_connected(_on_mana_changed_for_stats):
		mana_node.mana_changed.connect(_on_mana_changed_for_stats)
	_connected = true
	_update_stats(); _update_equipment(); _update_inventory()
	_update_essence_inventory(); _update_stat_panel()
	if visible_ui: _update_right_stats()

func _close_all_other_uis() -> void:
	"""Skill tree veya gem panel aciksa kapat."""
	var main := get_tree().current_scene
	if main and main.has_method("get_skill_tree_instance"):
		var st = main.get_skill_tree_instance()
		if st and st.visible and st.has_method("close"):
			st.close()
	var sgp := get_tree().root.get_node_or_null("SkillGemPanelLayer") as CanvasLayer
	if sgp and sgp.has_method("is_open") and sgp.is_open() and sgp.has_method("close_ui"):
		sgp.close_ui()

func _is_any_ui_open_external() -> bool:
	"""Skill tree veya gem panel acik mi kontrol et."""
	var main := get_tree().current_scene
	if main and main.has_method("get_skill_tree_instance"):
		var st = main.get_skill_tree_instance()
		if st and st.visible: return true
	var sgp := get_tree().root.get_node_or_null("SkillGemPanelLayer") as CanvasLayer
	if sgp and sgp.has_method("is_open") and sgp.is_open(): return true
	return false

func _update_inventory() -> void:
	if not player or not is_instance_valid(inventory_grid): return
	# free() kullan — queue_free() eski child'lari get_children() icinde birakir,
	# bu da _try_drag_start'te eski butonlarin bulunup drag'in baslamamasina yol acar
	for c in inventory_grid.get_children(): c.free()
	var inv: Inventory = player.inventory
	var max_idx: int = max(inv.max_slots, inv.items.size())
	for idx in max_idx:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(40, 40)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var item: ItemData = inv.items[idx] if idx < inv.items.size() else null
		if is_instance_valid(item):
			btn.icon = _get_item_icon(item)
			btn.set_meta("item_data", item)
			if item.stackable and item.stack_count > 1: btn.text = str(item.stack_count)
			# Stat karsilamiyor mu? Kirmizi renk ver
			if player.inventory and not player.inventory.can_equip_item(item):
				btn.modulate = Color(1.0, 0.3, 0.3, 0.85)
			else:
				btn.modulate = Color.WHITE
			# Tooltip hover
			btn.mouse_entered.connect(_on_inv_slot_hover.bind(item))
			btn.mouse_exited.connect(_on_inv_slot_unhover)
			# Click-to-equip _input handler'da mouse release'de yapilir (cift tetikleme olmasin)
		else: btn.set_meta("item_data", null)
		_style_inv_btn(btn); btn.set_meta("inv_idx", idx)
		inventory_grid.add_child(btn)

func _on_inv_slot_hover(item: ItemData) -> void:
	var mp: Vector2 = get_viewport().get_mouse_position()
	_show_tooltip(item, mp)

func _on_equip_slot_hover(btn: Button) -> void:
	var item: ItemData = btn.get_meta("item_data", null) as ItemData
	if not item: return
	var mp: Vector2 = get_viewport().get_mouse_position()
	_show_tooltip(item, mp)

func _on_inv_slot_unhover() -> void:
	_hide_tooltip()

func _update_essence_inventory() -> void:
	if not player or not is_instance_valid(_essence_grid): return
	var ei: EssenceInventory = player.essence_inventory
	for i in range(min(EssenceInventory.MAX_SLOTS, _essence_buttons.size())):
		var btn: Button = _essence_buttons[i]
		if not is_instance_valid(btn): continue
		if i < ei.slots.size() and ei.slots[i]:
			var item: ItemData = ei.slots[i]
			btn.icon = _get_item_icon(item)
			btn.set_meta("has_item", true); btn.set_meta("essence_data", item)
			btn.text = str(item.stack_count) if item.stack_count > 1 else ""
			var s := StyleBoxFlat.new()
			s.bg_color = Color(0.1, 0.07, 0.15, 0.9)
			s.border_color = Color(0.55, 0.35, 0.95, 0.8)
			s.border_width_left = 1; s.border_width_right = 1
			s.border_width_top = 1; s.border_width_bottom = 1; s.set_corner_radius_all(3)
			btn.add_theme_stylebox_override("normal", s)
			btn.add_theme_stylebox_override("pressed", s)
			btn.add_theme_stylebox_override("hover", s)
		else:
			btn.icon = null; btn.text = ""
			btn.set_meta("has_item", false); btn.remove_meta("essence_data")
			var s := StyleBoxFlat.new()
			s.bg_color = Color(0.08, 0.06, 0.12, 0.85)
			s.border_color = Color(0.35, 0.2, 0.5, 0.5)
			s.border_width_left = 1; s.border_width_right = 1
			s.border_width_top = 1; s.border_width_bottom = 1; s.set_corner_radius_all(3)
			btn.add_theme_stylebox_override("normal", s)
			btn.add_theme_stylebox_override("pressed", s)
			btn.add_theme_stylebox_override("hover", s)

func _update_equipment() -> void:
	if not player: return
	for btn in equipment_slot_buttons:
		if not is_instance_valid(btn): continue
		var slot: int = btn.get_meta("slot_enum", -1)
		if slot < 0: continue
		var item: ItemData = player.equipment.get_item_in_slot(slot)
		if item:
			btn.icon = _get_item_icon(item); btn.text = ""
			btn.set_meta("item_data", item)
			# Tooltip hover
			if not btn.mouse_entered.is_connected(_on_equip_slot_hover):
				btn.mouse_entered.connect(_on_equip_slot_hover.bind(btn))
			if not btn.mouse_exited.is_connected(_on_inv_slot_unhover):
				btn.mouse_exited.connect(_on_inv_slot_unhover)
		else:
			btn.icon = null; btn.text = Equipment.Slot.keys()[slot].capitalize()
			btn.remove_meta("item_data")
			if btn.mouse_entered.is_connected(_on_equip_slot_hover):
				btn.mouse_entered.disconnect(_on_equip_slot_hover)
			if btn.mouse_exited.is_connected(_on_inv_slot_unhover):
				btn.mouse_exited.disconnect(_on_inv_slot_unhover)

func _update_stats() -> void:
	if not player or not is_instance_valid(_stats_label): return
	var s: String = ""; var stats: CharacterStats = player.stats
	var ls: LevelSystem = player.level_system
	s += "Seviye: %d\n" % ls.level
	s += "XP: %d/%d\n" % [ls.current_xp, ls.get_xp_required()]
	s += "Can: %d/%d\n" % [player.health.current_health, player.health.max_health]
	var mana_node: Node = player.get_node_or_null("Mana")
	if mana_node: s += "Mana: %d/%d\n" % [mana_node.current_mana, mana_node.max_mana]
	if player.has_node("EnergyShield"):
		var es = player.get_node("EnergyShield")
		if es.has_method("get_current") and es.has_method("get_max"):
			s += "ES: %d/%d\n" % [es.get_current(), es.get_max()]
	_stats_label.text = s

func _update_stat_panel() -> void:
	if not player: return
	var doll_section: Control = _left_content.get_node_or_null("PaperdollSection")
	if not doll_section: return
	var panel: Panel = doll_section.get_node_or_null("StatPanel")
	if not panel: return
	var stats: CharacterStats = player.stats
	var sl: Label = panel.get_node_or_null("STR")
	var dl: Label = panel.get_node_or_null("DEX")
	var il: Label = panel.get_node_or_null("INT")
	if sl: sl.text = "STR %d" % stats.total_strength
	if dl: dl.text = "DEX %d" % stats.total_dexterity
	if il: il.text = "INT %d" % stats.total_intelligence
	var rem: Label = panel.get_node_or_null("RemainingLabel")
	if rem:
		var pts: int = stats.stat_points
		rem.text = "Kalan: %d" % pts
		# Enable/disable +/- buttons based on remaining points and minimum stat of 10
		for i in range(3):
			var stat_names_local := ["STR", "DEX", "INT"]
			var stat_key: String = ["strength", "dexterity", "intelligence"][i]
			var base_val: int = stats.get(stat_key)
			var btn_plus: Button = panel.get_node_or_null(stat_names_local[i] + "_Plus")
			var btn_minus: Button = panel.get_node_or_null(stat_names_local[i] + "_Minus")
			if btn_plus: btn_plus.disabled = (pts <= 0)
			if btn_minus: btn_minus.disabled = (base_val <= 10)

func _on_stat_plus(stat_key: String) -> void:
	if not player: return
	var stats: CharacterStats = player.stats
	if stats.stat_points <= 0: return
	stats.set(stat_key, stats.get(stat_key) + 1)
	stats.stat_points -= 1
	stats.recalculate()
	_update_stat_panel()
	_update_right_stats()

func _on_stat_minus(stat_key: String) -> void:
	if not player: return
	var stats: CharacterStats = player.stats
	var base_val: int = stats.get(stat_key)
	if base_val <= 10: return
	stats.set(stat_key, base_val - 1)
	stats.stat_points += 1
	stats.recalculate()
	_update_stat_panel()
	_update_right_stats()

func _on_health_changed_for_stats(_current: float, _max: float) -> void:
	_on_stats_changed()

func _on_mana_changed_for_stats(_current: float, _max: float, _regen: float) -> void:
	_on_stats_changed()

func _on_stats_changed() -> void: _update_stats(); _update_stat_panel()

func _on_inventory_item_pressed(item: ItemData) -> void:
	if item.item_type == "currency":
		_show_equip_note("Currency'i surukleyip bir esyanin uzerine birak!", true); return
	if item.equip_slot == "": return
	if not player.inventory.can_equip_item(item):
		var fail: String = player.inventory.get_requirement_failures(item)
		_show_equip_error("Yetersiz stat! " + fail); return
	if item.equip_slot == "weapon" and (item.base_physical_damage_min > 0.0 or item.base_physical_damage_max > 0.0):
		var eq: Equipment = player.equipment
		if eq.get_item_in_slot(Equipment.Slot.WEAPON) and not eq.get_item_in_slot(Equipment.Slot.OFFHAND):
			player.inventory.equip_item(item, player.equipment, "offhand"); return
	player.inventory.equip_item(item, player.equipment)

func _show_equip_error(msg: String) -> void:
	if not is_instance_valid(_notif_label): return
	_notif_label.text = msg; _notif_label.modulate = Color(0.95, 0.3, 0.3, 1.0)
	_notif_label.visible = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_notif_label, "modulate:a", 0.0, 1.5).set_delay(0.3)

func _show_equip_note(msg: String, _info: bool = false) -> void:
	if not is_instance_valid(_notif_label): return
	_notif_label.text = msg; _notif_label.modulate = Color(0.3, 0.7, 0.95, 1.0)
	_notif_label.visible = true
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_notif_label, "modulate:a", 0.0, 2.0).set_delay(0.5)

var _char_init_breathe: bool = false
var _char_tween: Tween = null
var _char_tween2: Tween = null

func _process(_delta: float) -> void:
	if not visible_ui or not _left_content or not player: return
	_update_right_stats()
	_update_stat_panel()
	# Start character breathing idle animation once
	if _left_content and not _char_init_breathe:
		var doll := _left_content.get_node_or_null("PaperdollSection")
		if doll:
			var ch := doll.get_node_or_null("CharPortrait") as Sprite2D
			if ch and ch.texture:
				_char_init_breathe = true
				var base_s := ch.scale.x
				var base_y := ch.position.y
				_char_tween = create_tween().set_loops(0)
				_char_tween.tween_property(ch, "scale", Vector2(base_s * 1.012, base_s * 1.012), 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				_char_tween.tween_property(ch, "scale", Vector2(base_s, base_s), 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				_char_tween2 = create_tween().set_loops(0)
				_char_tween2.tween_property(ch, "position:y", base_y - 1.5, 0.9).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				_char_tween2.tween_property(ch, "position:y", base_y, 0.9).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func _input(event: InputEvent) -> void:
	# Tab / ESC — UI acikken kapatmaya yarar (pause'da da calisir)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if visible_ui:
					_close_ui()
					get_viewport().set_input_as_handled()
				return
			KEY_TAB:
				if visible_ui:
					_close_ui()
				else:
					_close_all_other_uis()
					_open_ui()
				get_viewport().set_input_as_handled()
				return
	if not visible_ui or not is_instance_valid(player): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_press_pos = event.position
			_drag_moved = false
			_try_drag_start(event.position)
		elif _is_dragging:
			if _drag_moved:
				_try_drag_end(event.position)
			else:
				# Click (no drag) — equip item
				if _drag_source_is_equipment:
					var sn: String = SLOT_ENUM_TO_NAME.get(_drag_source_slot, "")
					if not sn.is_empty(): player.inventory.unequip_item(sn, player.equipment)
				else:
					if _drag_source_idx >= 0 and _drag_source_idx < player.inventory.items.size():
						var item: ItemData = player.inventory.items[_drag_source_idx]
						if item: _on_inventory_item_pressed(item)
				_cleanup_drag()
		else:
			# Click on empty area — hide tooltip
			_hide_tooltip()
	if event is InputEventMouseMotion:
		if _drag_item and not _drag_moved:
			_drag_moved = true
			_create_drag_ghost()
			_update_drag_position(event.position)
		elif _drag_item:
			_update_drag_position(event.position)

func _try_drag_start(mouse_pos: Vector2) -> void:
	if not is_instance_valid(inventory_grid) or not visible_ui: return
	_drag_item = null; _drag_source_idx = -1; _drag_source_is_equipment = false
	_drag_source_slot = -1; _is_dragging = false
	if is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free(); _drag_ghost = null
	for btn in equipment_slot_buttons:
		if not is_instance_valid(btn): continue
		if btn.get_global_rect().has_point(mouse_pos):
			if btn.has_meta("item_data"):
				_drag_item = btn.get_meta("item_data") as ItemData
				_drag_source_slot = btn.get_meta("slot_enum", -1)
				_drag_source_is_equipment = true; _is_dragging = true
			return
	for btn in _essence_buttons:
		if not is_instance_valid(btn): continue
		if btn.get_global_rect().has_point(mouse_pos) and btn.get_meta("has_item", false):
			_drag_item = btn.get_meta("essence_data", null) as ItemData
			if _drag_item:
				_drag_source_idx = btn.get_meta("essence_slot", -1)
				_drag_source_is_equipment = false; _is_dragging = true
			return
	for b in inventory_grid.get_children():
		if b is Button and b.get_global_rect().has_point(mouse_pos):
			if b.has_meta("item_data") and b.get_meta("item_data", null) != null:
				_drag_item = b.get_meta("item_data")
				_drag_source_idx = b.get_index()
				_drag_source_is_equipment = false; _is_dragging = true
			return

func _try_drag_end(mouse_pos: Vector2) -> void:
	if not _drag_item: _cleanup_drag(); return
	var is_orb: bool = (_drag_item.item_type == "currency" and _drag_item.rarity == "currency")
	# Anvil: item parçalama (orb'lar örse bırakılmaz)
	if is_instance_valid(_anvil_zone) and _anvil_zone.get_global_rect().has_point(mouse_pos):
		if is_orb:
			_show_equip_note("Orb'ları doğrudan item üzerine sürükleyin!", true)
			_cleanup_drag(); return
		_handle_anvil_drop(); _cleanup_drag(); return
	# Equipment slot: orb→apply, item→equip
	for btn in equipment_slot_buttons:
		if not is_instance_valid(btn): continue
		if btn.get_global_rect().has_point(mouse_pos):
			var si: int = btn.get_meta("slot_enum", -1)
			if is_orb:
				_apply_orb_to_equipped(si)
				_cleanup_drag(); return
			if _drag_source_is_equipment: _do_drag_equip_swap(si)
			else: _do_drag_equip(si)
			_cleanup_drag(); return
	# Essence grid: orb'u geri bırak (no-op)
	for btn in _essence_buttons:
		if is_instance_valid(btn) and btn.get_global_rect().has_point(mouse_pos):
			_cleanup_drag(); return
	# Inventory grid: orb→apply to item, item→swap/unequip
	if is_instance_valid(inventory_grid):
		for b in inventory_grid.get_children():
			if b is Button and b.get_global_rect().has_point(mouse_pos):
				var ti: int = b.get_index()
				if is_orb:
					_apply_orb_to_inventory(ti)
				elif _drag_source_is_equipment:
					var sn: String = SLOT_ENUM_TO_NAME.get(_drag_source_slot, "")
					if not sn.is_empty(): player.inventory.unequip_item(sn, player.equipment)
				else: _do_drag_inventory_swap(ti)
				_cleanup_drag(); return
	if _drag_source_is_equipment:
		var sn: String = SLOT_ENUM_TO_NAME.get(_drag_source_slot, "")
		if not sn.is_empty(): player.inventory.unequip_item(sn, player.equipment)
	_cleanup_drag()

func _can_equip_to_slot(item: ItemData, slot_name: String) -> bool:
	if item.equip_slot == slot_name: return true
	if slot_name == "offhand" and item.equip_slot == "weapon":
		if item.base_physical_damage_min > 0.0 or item.base_physical_damage_max > 0.0: return true
	return false

func _do_drag_equip(slot_idx: int) -> void:
	if not player or not _drag_item: return
	var sn: String = SLOT_ENUM_TO_NAME.get(slot_idx, "")
	if sn.is_empty(): return
	if not _can_equip_to_slot(_drag_item, sn):
		_show_equip_error("Bu item " + sn + " slot'una takilamaz!"); return
	if not player.inventory.can_equip_item(_drag_item):
		_show_equip_error("Yetersiz stat! " + player.inventory.get_requirement_failures(_drag_item)); return
	player.inventory.equip_item(_drag_item, player.equipment, "offhand") if sn == "offhand" and _drag_item.equip_slot == "weapon" else player.inventory.equip_item(_drag_item, player.equipment)

func _do_drag_equip_swap(target_slot: int) -> void:
	if not player or not _drag_item: return
	var tsn: String = SLOT_ENUM_TO_NAME.get(target_slot, "")
	if tsn.is_empty(): return
	if not _can_equip_to_slot(_drag_item, tsn):
		_show_equip_error("Bu item " + tsn + " slot'una takilamaz!"); return
	var eq: Equipment = player.equipment
	var ti: ItemData = eq.get_item_in_slot(target_slot)
	eq.slots[_drag_source_slot] = null
	if ti:
		var ssn: String = SLOT_ENUM_TO_NAME.get(_drag_source_slot, "")
		if ssn != "" and _can_equip_to_slot(ti, ssn): eq.slots[_drag_source_slot] = ti
		elif not player.inventory.add_item(ti):
			eq.slots[_drag_source_slot] = _drag_item; eq.slots[target_slot] = ti
			_show_equip_error("Envanter dolu!"); eq.equipment_changed.emit(); return
	eq.slots[target_slot] = _drag_item; eq.equipment_changed.emit()

func _do_drag_inventory_swap(target_idx: int) -> void:
	if not player or target_idx < 0: return
	var inv: Inventory = player.inventory
	if _drag_source_idx >= 0 and _drag_source_idx < inv.items.size() and target_idx < inv.max_slots:
		# Array'i target_idx'i kapsayacak kadar genişlet (boş slotlar)
		while inv.items.size() <= target_idx:
			inv.items.append(null)
		var si: ItemData = inv.items[_drag_source_idx]
		var ti: ItemData = inv.items[target_idx]
		inv.items[_drag_source_idx] = ti
		inv.items[target_idx] = si
		inv.inventory_changed.emit()

# ─── ORB→ITEM UYGULAMA ───────────────────────────────────────
func _apply_orb_to_inventory(inv_idx: int) -> void:
	"""ÖZLER'den sürüklenen orb'u envanterdeki bir item'e uygula."""
	if not player or not _drag_item: return
	var inv: Inventory = player.inventory
	if inv_idx < 0 or inv_idx >= inv.items.size(): return
	var target: ItemData = inv.items[inv_idx]
	if not target: return
	var cd: CurrencyData = CurrencyRegistry.get_orb(_drag_item.id)
	if not cd: return
	if not cd.can_apply_to(target):
		_show_equip_note(cd.display_name + " bu item'a uygulanamaz!", true)
		return
	# ÖNCE uygula, SONRA tüket (başarısız olursa orb kaybolmasın)
	var success: bool = CurrencySystem.apply_currency(target, cd)
	if not success:
		_show_equip_note(cd.display_name + " başarısız oldu!", true)
		return
	# Başarılı → orb'u tüket
	var ei: EssenceInventory = player.essence_inventory
	if ei:
		ei.consume_essence(_drag_source_idx)
	_show_equip_note(cd.display_name + " başarıyla uygulandı!", true)
	if player.stats: player.stats.recalculate()

func _apply_orb_to_equipped(slot_idx: int) -> void:
	"""ÖZLER'den sürüklenen orb'u ekipmandaki item'e uygula."""
	if not player or not _drag_item: return
	var eq: Equipment = player.equipment
	var target: ItemData = eq.get_item_in_slot(slot_idx)
	if not target: return
	var cd: CurrencyData = CurrencyRegistry.get_orb(_drag_item.id)
	if not cd: return
	if not cd.can_apply_to(target):
		_show_equip_note(cd.display_name + " bu item'a uygulanamaz!", true)
		return
	# ÖNCE uygula, SONRA tüket (başarısız olursa orb kaybolmasın)
	var success: bool = CurrencySystem.apply_currency(target, cd)
	if not success:
		_show_equip_note(cd.display_name + " başarısız oldu!", true)
		return
	# Başarılı → orb'u tüket
	var ei: EssenceInventory = player.essence_inventory
	if ei:
		ei.consume_essence(_drag_source_idx)
	_show_equip_note(cd.display_name + " başarıyla uygulandı!", true)
	if player.stats: player.stats.recalculate()

func _create_drag_ghost() -> void:
	"""Suruklenen item'in ikonunu fareyi takip eden bir ghost olarak goster."""
	if not _drag_item: return
	if is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free(); _drag_ghost = null
	var tex: Texture2D = _get_item_icon(_drag_item)
	if not tex: return
	_drag_ghost = TextureRect.new()
	_drag_ghost.texture = tex
	_drag_ghost.custom_minimum_size = Vector2(36, 36)
	_drag_ghost.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	_drag_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.z_index = 500
	add_child(_drag_ghost)

func _update_drag_position(mouse_pos: Vector2) -> void:
	if is_instance_valid(_drag_ghost):
		_drag_ghost.position = mouse_pos - Vector2(18, 18)

func _cleanup_drag() -> void:
	_drag_item = null; _drag_source_idx = -1; _drag_source_is_equipment = false
	_drag_source_slot = -1; _is_dragging = false
	if is_instance_valid(_drag_ghost):
		_drag_ghost.queue_free(); _drag_ghost = null

func _show_tooltip(item: ItemData, global_pos: Vector2) -> void:
	if not is_instance_valid(_tooltip_panel) or not item: return
	_tooltip_label.text = _build_item_tooltip(item)
	_tooltip_label.size = Vector2(360, 0)
	_tooltip_panel.size = Vector2(380, max(_tooltip_label.get_content_height() + 20, 40))
	# Ekrandan taşmaması için pozisyon ayarla
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var px: float = global_pos.x + 16.0
	var py: float = global_pos.y + 16.0
	if px + _tooltip_panel.size.x > vp_size.x:
		px = global_pos.x - _tooltip_panel.size.x - 16.0
	if py + _tooltip_panel.size.y > vp_size.y:
		py = global_pos.y - _tooltip_panel.size.y - 16.0
	_tooltip_panel.position = Vector2(px, py)
	_tooltip_panel.visible = true

func _hide_tooltip() -> void:
	if is_instance_valid(_tooltip_panel): _tooltip_panel.visible = false

func _build_item_tooltip(item: ItemData) -> String:
	if not item: return ""
	var s: String = ""
	var cm := {"normal":"#aaaaaa","magic":"#5b6eff","rare":"#ffd700","unique":"#ff8844","currency":"#88ff88"}
	var rt_map := {"magic":"BÜYÜLÜ","rare":"NADİR","unique":"EŞSİZ"}
	var c: String = cm.get(item.rarity, "#aaaaaa")
	# === BÜYÜK ITEM ADI ===
	s += "[center][font_size=22][color=" + c + "][b]" + item.display_name + "[/b][/color][/font_size]"
	var rt: String = rt_map.get(item.rarity, "")
	if rt != "":
		s += "\n[font_size=14][color=" + c + "][i]" + rt + "[/i][/color][/font_size]"
	s += "[/center]\n"
	# === Currency item ===
	if item.item_type == "currency" or item.rarity == "currency":
		var cd: CurrencyData = CurrencyRegistry.get_orb(item.id)
		if cd:
			s += "\n[font_size=15][color=#88ff88]" + cd.description + "[/color][/font_size]\n"
		s += "[font_size=13][color=#888888]Orb  •  Envanterde stack'lenir[/color][/font_size]\n"
		if cd:
			var app_str: String = ""
			for arr in cd.allowed_rarities:
				if not app_str.is_empty(): app_str += ", "
				app_str += arr.capitalize()
			if not app_str.is_empty():
				s += "[font_size=13][color=#aaaaaa]Kullanılabilir: " + app_str + " item'lar[/color][/font_size]\n"
		return s
	# === ITEM TÜRÜ VE LEVEL ===
	s += "[center][font_size=13][color=#888888]" + item.item_type.capitalize()
	s += "  •  Item Level: " + str(item.item_level)
	s += "  •  Gereken Level: " + str(item.required_level) + "[/color][/font_size][/center]\n"
	# === BASE STATS (kalite çarpanı uygulanmış) ===
	var qm: float = item.get_quality_multiplier()
	var has_q: bool = item.quality > 0
	var base_lines: Array[String] = []
	if item.base_physical_damage_min > 0 or item.base_physical_damage_max > 0:
		var dmg_min: float = item.base_physical_damage_min * qm
		var dmg_max: float = item.base_physical_damage_max * qm
		if has_q:
			base_lines.append("[color=#ffffff]Fiziksel Hasar: %d-%d[/color] [color=#888888](taban: %d-%d)[/color]" % [dmg_min, dmg_max, item.base_physical_damage_min, item.base_physical_damage_max])
		else:
			base_lines.append("[color=#ffffff]Fiziksel Hasar: %d-%d[/color]" % [dmg_min, dmg_max])
	if item.base_elemental_damage > 0:
		var ed: float = item.base_elemental_damage * qm
		if has_q:
			base_lines.append("[color=#ffffff]Element Hasarı: %d[/color] [color=#888888](taban: %d)[/color]" % [ed, item.base_elemental_damage])
		else:
			base_lines.append("[color=#ffffff]Element Hasarı: %d[/color]" % [ed])
	if item.base_armour > 0:
		var arm: float = item.base_armour * qm
		if has_q:
			base_lines.append("[color=#ffffff]Zırh: %d[/color] [color=#888888](taban: %d)[/color]" % [arm, item.base_armour])
		else:
			base_lines.append("[color=#ffffff]Zırh: %d[/color]" % [arm])
	if item.base_evasion > 0:
		var ev: float = item.base_evasion * qm
		if has_q:
			base_lines.append("[color=#ffffff]Kaçınma: %d[/color] [color=#888888](taban: %d)[/color]" % [ev, item.base_evasion])
		else:
			base_lines.append("[color=#ffffff]Kaçınma: %d[/color]" % [ev])
	if item.base_energy_shield > 0:
		var es: float = item.base_energy_shield * qm
		if has_q:
			base_lines.append("[color=#ffffff]Enerji Kalkanı: %d[/color] [color=#888888](taban: %d)[/color]" % [es, item.base_energy_shield])
		else:
			base_lines.append("[color=#ffffff]Enerji Kalkanı: %d[/color]" % [es])
	if item.base_block_chance > 0:
		base_lines.append("[color=#ffffff]Blok Şansı: %d%%[/color]" % [item.base_block_chance])
	if item.base_attack_speed > 0:
		base_lines.append("[color=#ffffff]Saldırı Hızı: %.1f[/color]" % [item.base_attack_speed])
	if item.base_cast_speed > 0:
		base_lines.append("[color=#ffffff]Büyü Hızı: %.1f[/color]" % [item.base_cast_speed])
	if has_q:
		s += "\n[color=#ffd700]Kalite: +%d%%[/color]" % [item.quality]
	if base_lines.size() > 0:
		s += "\n[font_size=15]" + "\n".join(base_lines) + "[/font_size]\n"
	# === AFFIXES ===
	if item.affixes.size() > 0:
		s += "\n"
		for a in item.affixes:
			if a:
				s += "  " + a.get_colored_text() + "\n"
	# === REQUIREMENTS ===
	var req_lines: Array[String] = []
	if item.required_strength > 0:
		req_lines.append("[color=#e06666]Güç: %d[/color]" % [item.required_strength])
	if item.required_dexterity > 0:
		req_lines.append("[color=#66b3e0]Çeviklik: %d[/color]" % [item.required_dexterity])
	if item.required_intelligence > 0:
		req_lines.append("[color=#9966cc]Zeka: %d[/color]" % [item.required_intelligence])
	if req_lines.size() > 0:
		s += "\n[font_size=13][color=#aaaaaa]Gereken: [/color]" + "  ".join(req_lines) + "[/font_size]\n"
	return s

# ─── ÖZLER HANDLERS ────────────────────────────────────────────
func _on_essence_slot_hover(slot_idx: int) -> void:
	if not player or not player.essence_inventory:
		return
	var ei: EssenceInventory = player.essence_inventory
	if slot_idx < 0 or slot_idx >= ei.slots.size():
		return
	var item: ItemData = ei.slots[slot_idx]
	if not item:
		return
	var mp: Vector2 = get_viewport().get_mouse_position()
	_show_tooltip(item, mp)

# ─── ANVIL / CRAFTING HANDLERS ─────────────────────────────────
func _handle_anvil_drop() -> void:
	if not _drag_item:
		return
	var item_name: String = _drag_item.display_name if not _drag_item.display_name.is_empty() else _drag_item.id
	if _drag_item.item_type == "currency":
		# Orb'lar örse bırakılmaz — direkt item üzerine sürüklenir
		_show_equip_note("Orb'ları doğrudan item üzerine sürükleyin!", true)
		return
	# Normal item: ÖRS'E BIRAK => PARÇALA => ORB DÜŞÜR
	# Önce item'ı envanterden/ekipmandan kaldır
	if not _drag_source_is_equipment and player and player.inventory:
		player.inventory.remove_item(_drag_item)
	elif _drag_source_is_equipment and player and player.inventory:
		var sn: String = SLOT_ENUM_TO_NAME.get(_drag_source_slot, "")
		if not sn.is_empty():
			player.inventory.unequip_item(sn, player.equipment)
	else:
		return
	
	# Item parçalandı! Rastgele orb sayısı
	var orb_count: int = 1
	match _drag_item.rarity:
		"magic": orb_count = randi_range(1, 2)
		"rare": orb_count = randi_range(2, 3)
		"unique": orb_count = randi_range(3, 5)
		_: orb_count = 1
	
	# Orbları ÖZLER (EssenceInventory) envanterine ekle
	var orbs_added: int = 0
	for i in range(orb_count):
		var cd: CurrencyData = CurrencyRegistry.get_random_orb()
		if cd:
			var orb_item: ItemData = CurrencyRegistry.make_orb_item(cd.id)
			if player and player.essence_inventory:
				if player.essence_inventory.add_essence(orb_item):
					orbs_added += 1
	
	_show_equip_note(item_name + " parçalandı! " + str(orbs_added) + " orb envantere eklendi.", true)
