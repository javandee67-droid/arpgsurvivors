extends CanvasLayer
class_name SkillGemPanel

## Yetenek Gem Paneli — K tusu ile acilir.
## Sol: Skill listesi, Sag: 5 support slotu, Alt: Gem havuzu.

var player = null  # type: Node (assigned at runtime)
var _visible: bool = false

# UI references
var _bg: ColorRect
var _main_panel: Panel

# Sol panel: skill listesi
var _skill_list_container: VBoxContainer
var _selected_skill_idx: int = 0
var _skill_buttons: Array[Button] = []
var _skill_paths: Array[String] = []

# Sag panel: support slotlari
var _slot_containers: Array[Control] = []  # 5 slot
var _slot_bg_rects: Array[ColorRect] = []
var _slot_labels: Array[Label] = []
var _selected_skill_info: RichTextLabel

# Alt panel: gem havuzu
var _gem_grid: GridContainer
var _gem_buttons: Array[Button] = []

# Tooltip
var _tooltip_bg: ColorRect
var _tooltip_label: RichTextLabel
var _tooltip_visible: bool = false

# Drag state (future use — drag & drop from stash to slots)

# Colors
const BG_OVERLAY := Color(0.02, 0.02, 0.04, 0.92)
const PANEL_BG := Color(0.04, 0.04, 0.07, 0.98)
const BORDER_COLOR := Color(0.6, 0.5, 0.25, 1.0)
const SLOT_EMPTY := Color(0.12, 0.12, 0.16, 1.0)
const SLOT_FILLED := Color(0.08, 0.08, 0.14, 1.0)
const SLOT_HOVER := Color(0.2, 0.18, 0.22, 1.0)
const GEM_STASH_BG := Color(0.06, 0.06, 0.09, 0.8)
const TEXT_COLOR := Color(0.88, 0.88, 0.92, 1.0)
const DIM_TEXT := Color(0.5, 0.5, 0.55, 1.0)
const ACCENT := Color(0.85, 0.75, 0.4, 1.0)
const GEM_COLOR := Color(0.6, 0.9, 1.0, 1.0)
const SECTION_BORDER := Color(0.2, 0.18, 0.16, 0.4)

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 90  # GameUI(55)'in ustunde, SkillTreeLayer(100)'in altinda
	_build_ui()
	visible = _visible

func _build_ui() -> void:
	# === Full-screen dark overlay ===
	_bg = ColorRect.new()
	_bg.color = BG_OVERLAY
	_bg.anchor_right = 1.0
	_bg.anchor_bottom = 1.0
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	
	# === Main panel ===
	_main_panel = Panel.new()
	_main_panel.anchor_left = 0.05
	_main_panel.anchor_top = 0.05
	_main_panel.anchor_right = 0.95
	_main_panel.anchor_bottom = 0.95
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = BORDER_COLOR
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.set_corner_radius_all(8)
	_main_panel.add_theme_stylebox_override("panel", style)
	add_child(_main_panel)
	
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 720)
	var m := 12.0
	var panel_w: float = vp_w * 0.9 - m * 2
	var panel_h: float = vp_h * 0.9 - m * 2
	
	# === BASLIK ===
	var title := Label.new()
	title.text = "YETENEK GEM PANELI"
	title.position = Vector2(m, m)
	title.size = Vector2(200, 24)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 16)
	_main_panel.add_child(title)
	
	var hint := Label.new()
	hint.text = "K: Kapat"
	hint.position = Vector2(panel_w - 80, m + 2)
	hint.size = Vector2(70, 20)
	hint.add_theme_color_override("font_color", DIM_TEXT)
	hint.add_theme_font_size_override("font_size", 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_main_panel.add_child(hint)
	
	var title_bar_border := ColorRect.new()
	title_bar_border.color = SECTION_BORDER
	title_bar_border.position = Vector2(4, m + 28)
	title_bar_border.size = Vector2(panel_w - 8, 1)
	_main_panel.add_child(title_bar_border)
	
	# === SOL PANEL: Skill listesi (width 35%) ===
	var top_y: float = m + 34
	var skill_w: float = panel_w * 0.35
	var skill_h: float = panel_h * 0.70 - top_y + m
	
	var skill_bg := ColorRect.new()
	skill_bg.color = Color(0.06, 0.06, 0.09, 0.5)
	skill_bg.position = Vector2(m, top_y)
	skill_bg.size = Vector2(skill_w, skill_h)
	_main_panel.add_child(skill_bg)
	
	var skill_title := Label.new()
	skill_title.text = "SKILLER"
	skill_title.position = Vector2(m + 4, top_y + 2)
	skill_title.size = Vector2(skill_w - 8, 20)
	skill_title.add_theme_color_override("font_color", ACCENT)
	skill_title.add_theme_font_size_override("font_size", 11)
	_main_panel.add_child(skill_title)
	
	var skill_scroll := ScrollContainer.new()
	skill_scroll.position = Vector2(m + 2, top_y + 24)
	skill_scroll.size = Vector2(skill_w - 4, skill_h - 26)
	_main_panel.add_child(skill_scroll)
	
	_skill_list_container = VBoxContainer.new()
	_skill_list_container.size = Vector2(skill_w - 18, 0)
	_skill_list_container.add_theme_constant_override("separation", 2)
	skill_scroll.add_child(_skill_list_container)
	
	# === SAG PANEL: Support slotlari (width 60%) ===
	var slot_x: float = m + skill_w + 8
	var slot_w: float = panel_w - skill_w - m - 8
	
	var slot_title := Label.new()
	slot_title.text = "SUPPORT SOKETLERI"
	slot_title.position = Vector2(slot_x, top_y + 2)
	slot_title.size = Vector2(slot_w - 4, 20)
	slot_title.add_theme_color_override("font_color", ACCENT)
	slot_title.add_theme_font_size_override("font_size", 11)
	_main_panel.add_child(slot_title)
	
	_selected_skill_info = RichTextLabel.new()
	_selected_skill_info.position = Vector2(slot_x, top_y + 24)
	_selected_skill_info.size = Vector2(slot_w, 40)
	_selected_skill_info.bbcode_enabled = true
	_selected_skill_info.add_theme_color_override("default_color", DIM_TEXT)
	_selected_skill_info.add_theme_font_size_override("normal_font_size", 10)
	_main_panel.add_child(_selected_skill_info)
	
	# 5 support slotu
	var slot_start_y: float = top_y + 72
	var slot_size: float = 56.0
	var slot_gap: float = 8.0
	
	for i in range(5):
		var sx: float = slot_x + i * (slot_size + slot_gap)
		var sr := ColorRect.new()
		sr.color = SLOT_EMPTY
		sr.position = Vector2(sx, slot_start_y)
		sr.size = Vector2(slot_size, slot_size)
		sr.mouse_filter = Control.MOUSE_FILTER_STOP
		var s_style := StyleBoxFlat.new()
		s_style.border_color = SECTION_BORDER
		s_style.border_width_left = 1
		s_style.border_width_right = 1
		s_style.border_width_top = 1
		s_style.border_width_bottom = 1
		s_style.set_corner_radius_all(4)
		sr.add_theme_stylebox_override("panel", s_style)
		_main_panel.add_child(sr)
		_slot_bg_rects.append(sr)
		
		var sl := Label.new()
		sl.position = Vector2(sx + 2, slot_start_y + 2)
		sl.size = Vector2(slot_size - 4, slot_size - 4)
		sl.add_theme_color_override("font_color", DIM_TEXT)
		sl.add_theme_font_size_override("font_size", 8)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_main_panel.add_child(sl)
		_slot_labels.append(sl)
		
		# Slot numarasi
		var sn := Label.new()
		sn.text = str(i + 1)
		sn.position = Vector2(sx + slot_size - 14, slot_start_y + slot_size - 14)
		sn.size = Vector2(12, 12)
		sn.add_theme_color_override("font_color", DIM_TEXT)
		sn.add_theme_font_size_override("font_size", 8)
		sn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_main_panel.add_child(sn)
		
		# Slot container (click + hover area)
		var slot_area := Control.new()
		slot_area.name = "SlotArea_" + str(i)
		slot_area.position = Vector2(sx, slot_start_y)
		slot_area.size = Vector2(slot_size, slot_size)
		slot_area.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_area.gui_input.connect(_on_slot_gui_input.bind(i))
		slot_area.mouse_entered.connect(_on_slot_hovered.bind(i))
		slot_area.mouse_exited.connect(_hide_tooltip)
		_main_panel.add_child(slot_area)
		_slot_containers.append(slot_area)
	
	# === ALT PANEL: Gem havuzu ===
	var stash_y: float = top_y + skill_h + 8
	var stash_h: float = panel_h - stash_y
	
	var stash_bg := ColorRect.new()
	stash_bg.color = GEM_STASH_BG
	stash_bg.position = Vector2(m, stash_y)
	stash_bg.size = Vector2(panel_w - m * 2, stash_h - m)
	_main_panel.add_child(stash_bg)
	
	var stash_title := Label.new()
	stash_title.text = "GEM HAVUZU"
	stash_title.position = Vector2(m + 4, stash_y + 2)
	stash_title.size = Vector2(200, 20)
	stash_title.add_theme_color_override("font_color", ACCENT)
	stash_title.add_theme_font_size_override("font_size", 11)
	_main_panel.add_child(stash_title)
	
	var gem_scroll := ScrollContainer.new()
	gem_scroll.position = Vector2(m + 2, stash_y + 24)
	gem_scroll.size = Vector2(panel_w - m * 2 - 4, stash_h - m - 26)
	_main_panel.add_child(gem_scroll)
	
	_gem_grid = GridContainer.new()
	_gem_grid.columns = 8
	_gem_grid.size = Vector2(gem_scroll.size.x - 14, 0)
	_gem_grid.add_theme_constant_override("separation", 4)
	gem_scroll.add_child(_gem_grid)
	
	# === TOOLTIP (hover bilgisi) ===
	_tooltip_bg = ColorRect.new()
	_tooltip_bg.color = Color(0.04, 0.04, 0.1, 0.95)
	_tooltip_bg.size = Vector2(280, 60)
	_tooltip_bg.visible = false
	var tt_style := StyleBoxFlat.new()
	tt_style.border_color = BORDER_COLOR
	tt_style.border_width_left = 1
	tt_style.border_width_right = 1
	tt_style.border_width_top = 1
	tt_style.border_width_bottom = 1
	tt_style.set_corner_radius_all(4)
	_tooltip_bg.add_theme_stylebox_override("panel", tt_style)
	_main_panel.add_child(_tooltip_bg)
	
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.position = Vector2(6, 4)
	_tooltip_label.size = Vector2(268, 52)
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.add_theme_color_override("default_color", TEXT_COLOR)
	_tooltip_label.add_theme_font_size_override("normal_font_size", 9)
	_tooltip_bg.add_child(_tooltip_label)

func open_ui() -> void:
	_visible = true
	visible = true
	get_tree().paused = true
	_refresh_all()
	_refresh_gems()

func close_ui() -> void:
	_visible = false
	visible = false
	get_tree().paused = false

func is_open() -> bool:
	return _visible

func _refresh_all() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return
	
	# Refresh skill list
	_refresh_skill_list()
	# Refresh selected skill info and slots
	_refresh_selected_skill()

func _refresh_skill_list() -> void:
	# Clear old buttons
	for btn in _skill_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_skill_buttons.clear()
	_skill_paths.clear()
	
	if not player:
		print("SGP: No player reference!")
		return
	
	# Build list from skill_setups
	var setups: Dictionary = player.skill_setups
	var paths: Array = setups.keys()
	if paths.size() == 0:
		# Default: Normal Attack
		var na_path := "res://data/skills/normal_attack.tres"
		if ResourceLoader.exists(na_path):
			var skill: SkillData = load(na_path)
			if skill:
				player.skill_setups[na_path] = {"supports": [null, null, null, null, null]}
				paths = [na_path]
	
	for skill_path in paths:
		var skill_data: SkillData = null
		if player.skill_setups.has(skill_path) and player.skill_setups[skill_path].has("skill"):
			skill_data = player.skill_setups[skill_path]["skill"]
		elif ResourceLoader.exists(skill_path):
			skill_data = load(skill_path) as SkillData
		
		if not skill_data:
			continue
		
		# Ensure setup entry has skill ref
		if not player.skill_setups[skill_path].has("skill"):
			player.skill_setups[skill_path]["skill"] = skill_data
		
		var active_count: int = 0
		if player.skill_setups[skill_path].has("supports"):
			for s in player.skill_setups[skill_path]["supports"]:
				if s is SupportData:
					active_count += 1
		
		var btn := Button.new()
		
		# Ikon yukle
		if not skill_data.icon_path.is_empty():
			var tex := load(skill_data.icon_path) as Texture2D
			if tex:
				btn.icon = tex
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var supp_info: String = ""
		if active_count > 0:
			supp_info = " (" + str(active_count) + " support)"
		# Hotbar slot bilgisi
		var hb_info: String = ""
		if player and player.hotbar.size() > 0:
			for hb_i in range(player.hotbar.size()):
				if player.hotbar[hb_i] == skill_path:
					var hb_num: String = _hotbar_key_name(hb_i)
					hb_info = "  [" + hb_num + "]"
					break
		btn.text = skill_data.display_name + supp_info + hb_info
		btn.custom_minimum_size = Vector2(160, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_skill_selected.bind(_skill_paths.size()))
		btn.mouse_entered.connect(_on_skill_hover.bind(_skill_paths.size()))
		# Right-click: hotbar ata
		btn.gui_input.connect(_on_skill_gui_input.bind(_skill_paths.size()))
		_style_skill_btn(btn, _skill_paths.size() == _selected_skill_idx)
		
		_skill_list_container.add_child(btn)
		_skill_buttons.append(btn)
		_skill_paths.append(skill_path)

func _style_skill_btn(btn: Button, selected: bool) -> void:
	var s := StyleBoxFlat.new()
	if selected:
		s.bg_color = Color(0.22, 0.18, 0.12, 1.0)
		s.border_color = ACCENT
	else:
		s.bg_color = Color(0.14, 0.12, 0.16, 1.0)
		s.border_color = Color(0.3, 0.25, 0.2, 1.0)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("pressed", s)
	var h := s.duplicate()
	h.bg_color = Color(0.25, 0.2, 0.22, 1.0)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_color_override("font_color", TEXT_COLOR)
	btn.add_theme_font_size_override("font_size", 10)

func _on_skill_selected(idx: int) -> void:
	if idx < 0 or idx >= _skill_paths.size():
		return
	_selected_skill_idx = idx
	_refresh_skill_list()  # Rebuild to update styles
	_refresh_selected_skill()

func _on_skill_hover(_idx: int) -> void:
	pass  # Could show tooltip

func _refresh_selected_skill() -> void:
	if not player or _skill_paths.size() == 0:
		return
	
	if _selected_skill_idx >= _skill_paths.size():
		_selected_skill_idx = 0
	
	var skill_path: String = _skill_paths[_selected_skill_idx]
	var skill_data: SkillData = null
	if player.skill_setups.has(skill_path) and player.skill_setups[skill_path].has("skill"):
		skill_data = player.skill_setups[skill_path]["skill"]
	if not skill_data and ResourceLoader.exists(skill_path):
		skill_data = load(skill_path) as SkillData
	
	if not skill_data:
		return
	
	# Info text — sadece skill adi goster
	var info_text: String = "[b]" + skill_data.display_name + "[/b]"
	_selected_skill_info.text = info_text
	
	# Once tum slot ikonlarini temizle (guvenli cleanup)
	_clear_all_slot_icons()
	
	# Support slots
	var slots: Array = player._get_supports_for_skill(skill_path)
	for i in range(5):
		if i < slots.size() and slots[i] is SupportData:
			var sd: SupportData = slots[i] as SupportData
			_slot_labels[i].text = sd.display_name
			_slot_labels[i].add_theme_color_override("font_color", GEM_COLOR)
			_slot_bg_rects[i].color = SLOT_FILLED
			# Slot ikonu
			_update_slot_icon(i, sd)
		else:
			_slot_labels[i].text = ""
			_slot_labels[i].add_theme_color_override("font_color", DIM_TEXT)
			_slot_bg_rects[i].color = SLOT_EMPTY
	
	_refresh_gems()

func _refresh_gems() -> void:
	# Clear old gem buttons
	for btn in _gem_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_gem_buttons.clear()
	
	if not player:
		return
	
	var stash: Array = player.gem_stash
	for gem in stash:
		if not gem is SupportData:
			continue
		var sd: SupportData = gem as SupportData
		var btn := Button.new()
		btn.text = sd.display_name
		btn.size = Vector2(80, 36)
		btn.custom_minimum_size = Vector2(80, 36)
		btn.add_theme_font_size_override("font_size", 9)
		
		# Ikon yukle
		if not sd.icon_path.is_empty():
			var tex := load(sd.icon_path) as Texture2D
			if tex:
				btn.icon = tex
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.08, 0.08, 0.12, 1.0)
		s.border_color = Color(0.3, 0.5, 0.7, 0.6)
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", s)
		
		var h := s.duplicate()
		h.bg_color = Color(0.15, 0.15, 0.25, 1.0)
		btn.add_theme_stylebox_override("hover", h)
		
		btn.pressed.connect(_on_gem_pressed.bind(sd))
		btn.mouse_entered.connect(_show_gem_tooltip.bind(sd, btn))
		btn.mouse_exited.connect(_hide_tooltip)
		_gem_grid.add_child(btn)
		_gem_buttons.append(btn)

func _on_gem_pressed(gem: SupportData) -> void:
	"""Gem havuzundan bir gemi tiklayinca, secili skill'in ilk bos slotuna yerlestir."""
	if not player:
		return
	if _skill_paths.size() == 0:
		return
	var skill_path: String = _skill_paths[_selected_skill_idx]
	var slots: Array = player._get_supports_for_skill(skill_path)
	
	# Ilk bos slotu bul
	for i in range(5):
		if i >= slots.size() or slots[i] == null or not (slots[i] is SupportData):
			# Tag uyumlulugunu kontrol et
			var skill_data: SkillData = null
			if player.skill_setups.has(skill_path) and player.skill_setups[skill_path].has("skill"):
				skill_data = player.skill_setups[skill_path]["skill"]
			if not skill_data and ResourceLoader.exists(skill_path):
				skill_data = load(skill_path) as SkillData
			
			if skill_data:
				if not gem.is_compatible(skill_data):
					continue  # Uyumsuz support'u atla
			
			player.socket_support(skill_path, i, gem)
			_refresh_selected_skill()
			return
	# Tum slotlar doluysa hicbir sey yapma

func _on_slot_hovered(slot_idx: int) -> void:
	"""Slot uzerine gelince support gem tooltip'ini goster."""
	if not player or _skill_paths.size() == 0:
		return
	var skill_path: String = _skill_paths[_selected_skill_idx]
	var slots: Array = player._get_supports_for_skill(skill_path)
	if slot_idx < slots.size() and slots[slot_idx] is SupportData:
		_show_slot_tooltip(slots[slot_idx] as SupportData, slot_idx)

func _on_slot_gui_input(event: InputEvent, slot_idx: int) -> void:
	"""Support slot'una sag tiklayinca gem'i cikar."""
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if not player or _skill_paths.size() == 0:
					return
				var skill_path: String = _skill_paths[_selected_skill_idx]
				player.unsocket_support(skill_path, slot_idx)
				_refresh_selected_skill()

# ============= INPUT =============
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				if _visible:
					close_ui()
					get_viewport().set_input_as_handled()

func _on_k_pressed() -> void:
	"""Player._toggle_skill_gem_panel() tarafindan cagrilir. K tusu ile ac/kapa."""
	if _visible:
		close_ui()
	else:
		open_ui()

# ============= SLOT ICON =============
func _update_slot_icon(slot_idx: int, sd: SupportData) -> void:
	"""Slot'ta support gem ikonunu goster."""
	# Once eski ikonu temizle
	_clear_slot_icon(slot_idx)
	if sd.icon_path.is_empty():
		return
	var tex := load(sd.icon_path) as Texture2D
	if not tex:
		return
	var icon_rect := TextureRect.new()
	icon_rect.name = "SlotIcon_" + str(slot_idx)
	icon_rect.texture = tex
	icon_rect.position = Vector2(4, 4)
	icon_rect.size = Vector2(24, 24)
	icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slot_bg_rects[slot_idx].add_child(icon_rect)

func _clear_all_slot_icons() -> void:
	"""Tum slot ikonlarini aninda temizle."""
	for bg in _slot_bg_rects:
		var to_remove: Array[Node] = []
		for child in bg.get_children():
			if child.name.begins_with("SlotIcon_"):
				to_remove.append(child)
		for child in to_remove:
			bg.remove_child(child)
			child.free()

func _clear_slot_icon(slot_idx: int) -> void:
	"""Slot'taki ikonu aninda kaldir."""
	var bg := _slot_bg_rects[slot_idx]
	var to_remove: Array[Node] = []
	for child in bg.get_children():
		if child.name.begins_with("SlotIcon_"):
			to_remove.append(child)
	for child in to_remove:
		bg.remove_child(child)
		child.free()

# ============= HOTBAR ATAMA =============
func _on_skill_gui_input(event: InputEvent, skill_idx: int) -> void:
	"""Skill'e sag tiklayinca hotbar menu ac."""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if skill_idx < 0 or skill_idx >= _skill_paths.size():
			return
		if not player:
			return
		var skill_path: String = _skill_paths[skill_idx]
		
		# Basit popup menu
		var popup := PopupMenu.new()
		popup.add_label("Hotbar'a Ata:")
		for hb_i in range(min(20, player.hotbar.size())):
			var hb_num: String = _hotbar_key_name(hb_i)
			var current_skill: String = player.hotbar[hb_i]
			var current_name: String = ""
			if not current_skill.is_empty() and ResourceLoader.exists(current_skill):
				var cs := load(current_skill) as SkillData
				if cs:
					current_name = " (" + cs.display_name + ")"
			var label: String = "[Slot " + hb_num + "]" + current_name
			if player.hotbar[hb_i] == skill_path:
				label += " ✓"
			popup.add_item(label, hb_i)
		popup.size = Vector2(180, 8 + min(20, player.hotbar.size()) * 20)
		popup.position = get_viewport().get_mouse_position()
		popup.index_pressed.connect(_on_hotbar_menu_selected.bind(skill_path))
		add_child(popup)
		popup.popup()

func _on_hotbar_menu_selected(index: int, skill_path: String) -> void:
	"""Popup menuden bir hotbar slot'u secildi - skill'i ata."""
	if not player:
		return
	if index < 0 or index >= player.hotbar.size():
		return
	# Ayni skill zaten bu slot'ta mi? Toggle: baska yerde varsa once onu kaldir
	if player.hotbar[index] == skill_path:
		player.hotbar[index] = ""  # Kaldir
	else:
		# Basit: direkt ata (override)
		player.hotbar[index] = skill_path
	
	# SkillBar UI'ini guncelle
	var skill_bar := get_tree().root.get_node_or_null("SkillBarLayer") as SkillBar
	if skill_bar:
		skill_bar.refresh()
	
	# Panel UI'ini yenile (hotbar numarasi guncellensin)
	_refresh_skill_list()

func _hotbar_key_name(idx: int) -> String:
	"""Hotbar index'inin tus adini dondur."""
	var keys := ["1","2","3","4","5","6","7","8","9","0","-","=","Q","W","E","R","T","Y","U","I"]
	if idx >= 0 and idx < keys.size():
		return keys[idx]
	return str(idx)

# ============= TOOLTIP =============
func _build_modifier_lines(sd: SupportData) -> String:
	"""Support gem'in modifier'larindan okunabilir satirlar olusturur."""
	var lines: String = ""
	
	# StatModifier'lari goster - insan tarafindan okunabilir formatta
	for m in sd.modifiers:
		if m is StatModifier:
			var label: String = m.stat.capitalize()
			# damage ozel bir durum: damage_type_filter'dan gelen hasar turu
			if m.stat == "damage":
				if not m.damage_type_filter.is_empty():
					label = m.damage_type_filter.capitalize() + " Hasarı"
				else:
					label = "Toplam Hasar"
			
			var sign: String = "+" if m.value >= 0.0 else ""
			var value_str: String = sign + str(m.value)
			
			# Modifier tipine gore format
			match m.modifier_type:
				StatModifier.ModifierType.FLAT:
					# Flat: "+5 Ateş Hasarı" — direkt yaz
					lines += "\n  [color=#88ff88]+" + str(m.value) + " " + label + "[/color]"
					
				StatModifier.ModifierType.INCREASED:
					# Increased: "+%30 Fiziksel Hasar" veya "+%15 Toplam Hasar"
					var tag_part: String = ""
					if not m.skill_tag_filter.is_empty():
						tag_part = " (" + m.skill_tag_filter.capitalize() + ")"
					lines += "\n  [color=#66aaff]" + sign + "%" + str(m.value) + " " + label + tag_part + "[/color]"
					
				StatModifier.ModifierType.MORE:
					# More: "+%25 Toplam Hasar" (pozitif) veya "-%10 Toplam Hasar" (negatif=Less)
					var color: String = "#ff6666" if m.value < 0.0 else "#ffcc66"
					var pct_label: String = "%" + value_str + " " + label
					if m.value < 0.0:
						pct_label = "%" + str(absf(m.value)) + " " + label + " (Less)"
					lines += "\n  [color=" + color + "]" + pct_label + "[/color]"
	
	# extra_trigger_count (chain strike icin)
	if sd.extra_trigger_count > 0:
		lines += "\n  [color=#88ff88]+" + str(sd.extra_trigger_count) + " Zincirleme Vuruş[/color]"
	
	# extra_projectiles
	if sd.extra_projectiles > 0:
		lines += "\n  [color=#88ff88]+" + str(sd.extra_projectiles) + " Ekstra Mermi[/color]"
	
	# mana_multiplier
	if sd.mana_multiplier != 1.0:
		var mana_pct: float = (sd.mana_multiplier - 1.0) * 100.0
		var mana_sign: String = "+" if mana_pct > 0 else ""
		var mana_color: String = "#ff6666" if mana_pct > 0 else "#66ff66"
		lines += "\n  [color=" + mana_color + "]Mana Maliyeti: " + mana_sign + str(mana_pct) + "%[/color]"
	
	return lines

func _show_gem_tooltip(sd: SupportData, btn: Button) -> void:
	var desc: String = sd.gem_description
	if desc.is_empty():
		desc = "Açıklama yok."
	var mods_lines: String = _build_modifier_lines(sd)
	var body: String = "[b]" + sd.display_name + "[/b]\n" + desc
	if not mods_lines.is_empty():
		body += "\n" + mods_lines
	_show_tooltip(body, btn)

func _show_slot_tooltip(sd: SupportData, slot_idx: int) -> void:
	var desc: String = sd.gem_description
	if desc.is_empty():
		desc = "Açıklama yok."
	var mods_lines: String = _build_modifier_lines(sd)
	var body: String = "[b]" + sd.display_name + "[/b] (Slot " + str(slot_idx + 1) + ")\n" + desc
	if not mods_lines.is_empty():
		body += "\n" + mods_lines
	_show_tooltip(body, _slot_containers[slot_idx])

func _show_tooltip(text: String, _anchor: Control) -> void:
	var vp_w: float = _main_panel.size.x
	var vp_h: float = _main_panel.size.y
	# Icerik yuksekligine gore tooltip boyutunu ayarla
	_tooltip_label.text = text
	# RichTextLabel'in icerik yuksekligini al
	await get_tree().process_frame  # Bir frame bekle ki layout hesaplansin
	var content_h: float = _tooltip_label.get_content_height() + 8  # padding
	content_h = clamp(content_h, 24, 160)
	_tooltip_bg.size.y = content_h
	_tooltip_label.size.y = content_h - 8
	
	var local_pos: Vector2 = _main_panel.get_local_mouse_position()
	_tooltip_bg.position = Vector2(
		clamp(local_pos.x + 10, 4, vp_w - _tooltip_bg.size.x - 4),
		clamp(local_pos.y - 20, 4, vp_h - _tooltip_bg.size.y - 4)
	)
	_tooltip_bg.visible = true
	_tooltip_visible = true

func _hide_tooltip() -> void:
	_tooltip_bg.visible = false
	_tooltip_visible = false
