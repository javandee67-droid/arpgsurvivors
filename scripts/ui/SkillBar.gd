extends CanvasLayer
class_name SkillBar
## Alt ekrandaki skill hotbar'ı. 20 slot (1-9, 0, -, =, Q, W, E, R, T, Y, U, I).
## SkillGemPanel'de skill'leri hotbar'a atayıp tuşlarla kullanabilirsin.

var player = null  # type: Node (assigned at runtime)

var _slot_bgs: Array[ColorRect] = []
var _slot_labels: Array[Label] = []
var _slot_mana_labels: Array[Label] = []  # Mana cost göstergesi
var _slot_icons: Array[TextureRect] = []
var _slot_glows: Array[ColorRect] = []  # Aktif aura göstergesi
var _slot_cooldown_overlays: Array[ColorRect] = []  # Cooldown overlay
var _slot_cooldown_labels: Array[Label] = []  # Cooldown countdown label

const SLOT_SIZE := 44
const SLOT_GAP := 3
const BAR_COLOR := Color(0.03, 0.03, 0.06, 0.88)
const EMPTY_COLOR := Color(0.06, 0.06, 0.1, 0.95)     # Daha koyu
const FILLED_COLOR := Color(0.1, 0.08, 0.15, 0.98)  # Daha belirgin
const BORDER_COLOR := Color(0.3, 0.28, 0.35, 0.7)   # Daha parlak
const ACTIVE_BORDER_COLOR := Color(0.5, 0.45, 0.6, 0.9)  # Aktif slot kenarlığı
const KEY_LABEL_COLOR := Color(0.5, 0.5, 0.55, 0.7)
const TEXT_COLOR := Color(0.85, 0.85, 0.9, 1.0)

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	layer = 50
	_build_ui()
	_setup_drag_ghost()
	# Refresh UI'sini kisa sure sonra cagir (player hazir olmayabilir)
	call_deferred("_deferred_refresh")

func _deferred_refresh() -> void:
	refresh()

func _process(_delta: float) -> void:
	# Aktif aura glow gösterimini güncelle ve pulse animasyonu
	if not _slot_glows.is_empty() and player:
		_update_aura_glows()
	# Cooldown overlay güncelle
	if not _slot_cooldown_overlays.is_empty() and player:
		_update_cooldown_overlays()

func _build_ui() -> void:
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
	var bar_w: float = 20 * SLOT_SIZE + 19 * SLOT_GAP
	var bar_x: float = (vp_w - bar_w) / 2
	var bar_y: float = ProjectSettings.get_setting("display/window/size/viewport_height", 720) - SLOT_SIZE - 10
	
	# Arkaplan panel
	var panel := ColorRect.new()
	panel.color = BAR_COLOR
	panel.position = Vector2(bar_x - 8, bar_y - 6)
	panel.size = Vector2(bar_w + 16, SLOT_SIZE + 12)
	add_child(panel)
	
	var key_names := ["1","2","3","4","5","6","7","8","9","0","-","=","Q","-","E","R","T","Y","U","I"]
	
	for i in range(20):
		var sx: float = bar_x + i * (SLOT_SIZE + SLOT_GAP)
		
		# Slot arkaplanı
		var sbg := ColorRect.new()
		sbg.name = "Slot_" + str(i)
		sbg.color = EMPTY_COLOR
		sbg.position = Vector2(sx, bar_y)
		sbg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		var st := StyleBoxFlat.new()
		st.bg_color = Color.TRANSPARENT
		st.border_color = BORDER_COLOR
		st.border_width_left = 1
		st.border_width_right = 1
		st.border_width_top = 1
		st.border_width_bottom = 1
		st.set_corner_radius_all(3)
		sbg.add_theme_stylebox_override("panel", st)
		add_child(sbg)
		_slot_bgs.append(sbg)
		
		# Ikon
		var icon_rect := TextureRect.new()
		icon_rect.name = "Icon_" + str(i)
		icon_rect.position = Vector2(sx + 4, bar_y + 2)
		icon_rect.size = Vector2(24, 24)
		icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon_rect)
		_slot_icons.append(icon_rect)
			
			# Cooldown overlay
			var cd_overlay := ColorRect.new()
			cd_overlay.name = "CDOverlay_" + str(i)
			cd_overlay.color = Color(0, 0, 0, 0)
			cd_overlay.position = Vector2(sx, bar_y)
			cd_overlay.size = Vector2(SLOT_SIZE, SLOT_SIZE)
			add_child(cd_overlay)
			_slot_cooldown_overlays.append(cd_overlay)
			
			# Cooldown label
			var cd_label := Label.new()
			cd_label.name = "CDLabel_" + str(i)
			cd_label.text = ""
			cd_label.add_theme_color_override("font_color", Color.WHITE)
			cd_label.add_theme_font_size_override("font_size", 14)
			cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cd_label.position = Vector2(sx, bar_y)
			cd_label.size = Vector2(SLOT_SIZE, SLOT_SIZE)
			cd_label.modulate = Color(1, 1, 1, 0.9)
			add_child(cd_label)
			_slot_cooldown_labels.append(cd_label)
		
		# Skill adı (ikon altında)
		var lbl := Label.new()
		lbl.position = Vector2(sx + 1, bar_y + 26)
		lbl.size = Vector2(SLOT_SIZE - 2, 14)
		lbl.add_theme_color_override("font_color", TEXT_COLOR)
		lbl.add_theme_font_size_override("font_size", 7)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lbl)
		_slot_labels.append(lbl)
		
		# Mana cost label (sag alt kose)
		var mana_lbl := Label.new()
		mana_lbl.position = Vector2(sx + SLOT_SIZE - 20, bar_y + SLOT_SIZE - 11)
		mana_lbl.size = Vector2(18, 10)
		mana_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, 0.8))
		mana_lbl.add_theme_font_size_override("font_size", 6)
		mana_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mana_lbl.visible = false
		add_child(mana_lbl)
		_slot_mana_labels.append(mana_lbl)
		
		# Tuş numarası
		var klbl := Label.new()
		klbl.text = key_names[i]
		klbl.position = Vector2(sx + 2, bar_y + 1)
		klbl.size = Vector2(14, 10)
		klbl.add_theme_color_override("font_color", KEY_LABEL_COLOR)
		klbl.add_theme_font_size_override("font_size", 7)
		add_child(klbl)
		
		# Aktif aura glow overlay (görünmez başlar)
		var glow := ColorRect.new()
		glow.name = "Glow_" + str(i)
		glow.position = Vector2(sx - 1, bar_y - 1)
		glow.size = Vector2(SLOT_SIZE + 2, SLOT_SIZE + 2)
		glow.color = Color(0.3, 0.8, 1.0, 0.0)  # Görünmez başlangıç
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.z_index = 10
		var glow_style := StyleBoxFlat.new()
		glow_style.bg_color = Color.TRANSPARENT
		glow_style.border_color = Color(0.3, 0.8, 1.0, 0.8)
		glow_style.border_width_left = 2
		glow_style.border_width_right = 2
		glow_style.border_width_top = 2
		glow_style.border_width_bottom = 2
		glow_style.set_corner_radius_all(4)
		glow.add_theme_stylebox_override("panel", glow_style)
		glow.visible = false
		add_child(glow)
		_slot_glows.append(glow)
		
		# Tıklama alanı
		var btn := Button.new()
		btn.position = Vector2(sx, bar_y)
		btn.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		btn.focus_mode = Control.FOCUS_NONE  # Space/ui_accept butonu tekrar tetiklemesin
		btn.gui_input.connect(_on_slot_gui_input.bind(i))
		btn.mouse_entered.connect(_on_slot_hover.bind(i))
		btn.mouse_exited.connect(_on_slot_unhover)
		var es := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", es)
		btn.add_theme_stylebox_override("pressed", es)
		btn.add_theme_stylebox_override("hover", es)
		add_child(btn)

## SkillData'yi player.skill_setups uzerinden cache'den al (load() gereksiz)
func _get_skill_data(skill_path: String) -> SkillData:
	if skill_path.is_empty() or not player:
		return null
	var setup: Dictionary = player.skill_setups.get(skill_path, {})
	if setup.has("skill") and setup["skill"] is SkillData:
		return setup["skill"] as SkillData
	# Fallback: dogrudan yukle (skill_setups'ta yoksa)
	if ResourceLoader.exists(skill_path):
		return load(skill_path) as SkillData
	return null

func refresh() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return
	
	for i in range(20):
		var skill_path: String = ""
		if player.hotbar.size() > i:
			skill_path = player.hotbar[i]
		
		if skill_path.is_empty():
			_slot_bgs[i].color = EMPTY_COLOR
			_slot_labels[i].text = ""
			_slot_icons[i].texture = null
			continue
		
		var skill: SkillData = _get_skill_data(skill_path)
		if not skill:
			_slot_bgs[i].color = EMPTY_COLOR
			_slot_labels[i].text = "?"
			_slot_icons[i].texture = null
			continue
		
		_slot_labels[i].text = skill.display_name
		_slot_bgs[i].color = FILLED_COLOR
		
		# Ikon yukle
		if not skill.icon_path.is_empty():
			var tex := load(skill.icon_path) as Texture2D
			if tex:
				_slot_icons[i].texture = tex
			else:
				_slot_icons[i].texture = null
		else:
			_slot_icons[i].texture = null
	
	# ── Mana cost göstergelerini güncelle ──
	_update_mana_costs()
	
	# ── Aktif aura glow gösterimi ──
	_update_aura_glows()

## ⚠️ MANA SİSTEMİ KALDIRILDI: Vampire Survivors modunda tüm yetenekler ücretsizdir
func _update_mana_costs() -> void:
	# Tüm mana cost etiketlerini gizle
	for i in range(_slot_mana_labels.size()):
		_slot_mana_labels[i].visible = false

## Aktif buff/aura skill'leri olan hotbar slot'larında glow efekti göster.
## Player._active_buffs'teki skill_path'ler ile hotbar slotlarını eşleştirir.
func _update_cooldown_overlays() -> void:
	"""Cooldown overlay ve label'larını güncelle"""
	for i in range(min(20, player.hotbar.size())):
		if i >= _slot_cooldown_overlays.size() or i >= _slot_cooldown_labels.size():
			continue
		
		var skill_path: String = player.hotbar[i]
		if skill_path.is_empty():
			_slot_cooldown_overlays[i].color = Color(0, 0, 0, 0)
			_slot_cooldown_labels[i].text = ""
			continue
		
		var cd_remaining: float = 0.0
		if player._skill_cooldowns.has(skill_path):
			cd_remaining = player._skill_cooldowns[skill_path]
		
		if cd_remaining > 0:
			# Cooldown aktif - overlay göster
			var max_cd: float = 1.0
			var sd: SkillData = load(skill_path) as SkillData
			if sd and sd.cooldown > 0:
				max_cd = sd.cooldown
			var fill_ratio: float = clampf(cd_remaining / max_cd, 0.0, 1.0)
			_slot_cooldown_overlays[i].color = Color(0, 0, 0, 0.7 * fill_ratio)
			_slot_cooldown_labels[i].text = "%.1f" % cd_remaining
		else:
			# Cooldown yok - temizle
			_slot_cooldown_overlays[i].color = Color(0, 0, 0, 0)
			_slot_cooldown_labels[i].text = ""

func _update_aura_glows() -> void:
	if not player:
		return
	# Tüm glovları önce kapat (arkaplanları refresh ile aynı renge döndür)
	for g in _slot_glows:
		g.visible = false
	# Aktif buff'ları tara
	if not player.has_method("_toggle_buff_skill") or not player.get("_active_buffs"):
		_restore_slot_bg_colors()
		return
	var active_buffs: Dictionary = player._active_buffs
	if active_buffs.is_empty():
		_restore_slot_bg_colors()
		return
	# Hangi slot hangi skill_path'e sahip eşle
	var t: float = Time.get_ticks_msec() / 600.0
	var found_any: bool = false
	for i in range(player.hotbar.size()):
		var sp: String = player.hotbar[i]
		if sp.is_empty():
			continue
		if active_buffs.has(sp):
			found_any = true
			# Bu slot aktif aura — glow göster
			_slot_glows[i].visible = true
			# Beyaz-mavi arası gidip gelen yanıp sönme, her slot hafif farklı fazda
			var pulse: float = 0.5 + 0.5 * sin(t + i * 1.2)
			var alpha: float = 0.7 + 0.3 * pulse
			var white_amount: float = 0.3 + 0.7 * (1.0 - pulse)
			_slot_glows[i].modulate = Color(1.0, white_amount, white_amount * 0.6, alpha)
			# Arka plana da hafif parlama ekle (beyazımsı-mavi)
			var bg_brightness: float = 0.08 + 0.12 * (1.0 - pulse)
			_slot_bgs[i].color = Color(0.08 + bg_brightness, 0.08 + bg_brightness * 0.6, 0.12 + bg_brightness * 0.8, 0.9)
	if not found_any:
		_restore_slot_bg_colors()

func _restore_slot_bg_colors() -> void:
	"""Aktif aura yoksa slot arkaplanlarını varsayılan renge döndür."""
	if not player:
		return
	for i in range(player.hotbar.size()):
		if i >= _slot_bgs.size():
			break
		var sp: String = player.hotbar[i] if i < player.hotbar.size() else ""
		if sp.is_empty():
			_slot_bgs[i].color = EMPTY_COLOR
		else:
			_slot_bgs[i].color = FILLED_COLOR

# ── Drag-and-Drop sistemi ──
var _drag_source_slot: int = -1          # Surukleme baslangic slotu
var _drag_mouse_start: Vector2 = Vector2.ZERO  # Fare baslangic pozisyonu
var _drag_hover_slot: int = -1           # Su an uzerinde olunan slot
var _is_dragging: bool = false           # Surukleme aktif mi?
var _drag_ghost: ColorRect = null        # Suruklenen gorsel
const DRAG_THRESHOLD: float = 8.0        # Piksel cinsinden surukleme esigi

## Surukleme ghost'u (gorsel geribildirim) olustur
func _setup_drag_ghost() -> void:
	if _drag_ghost:
		return
	_drag_ghost = ColorRect.new()
	_drag_ghost.name = "DragGhost"
	_drag_ghost.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	_drag_ghost.color = Color(0.25, 0.2, 0.3, 0.85)
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.visible = false
	_drag_ghost.z_index = 100
	var border := StyleBoxFlat.new()
	border.bg_color = Color.TRANSPARENT
	border.border_color = Color(1.0, 0.8, 0.4, 0.7)
	border.border_width_left = 2
	border.border_width_right = 2
	border.border_width_top = 2
	border.border_width_bottom = 2
	border.set_corner_radius_all(4)
	_drag_ghost.add_theme_stylebox_override("panel", border)
	add_child(_drag_ghost)

## Fareyi global input'tan takip et (surukleme sirasinda)
func _input(event: InputEvent) -> void:
	# Bekleyen surukleme var mi? Threshold asildi mi?
	if not _is_dragging and _drag_source_slot >= 0:
		if event is InputEventMouseMotion:
			var dist: float = event.global_position.distance_to(_drag_mouse_start)
			if dist > DRAG_THRESHOLD:
				_is_dragging = true
				_setup_drag_ghost()
				if _drag_ghost:
					_drag_ghost.visible = true
					var half: float = SLOT_SIZE / 2.0
					_drag_ghost.position = event.global_position - Vector2(half, half)
				# Tooltip'i gizle
				if _tooltip_panel:
					_tooltip_panel.visible = false
				# Kaynak slotu highlight et
				if _drag_source_slot >= 0 and _drag_source_slot < _slot_bgs.size():
					_slot_bgs[_drag_source_slot].color = Color(0.3, 0.25, 0.4, 0.95)
			return  # Motion events: her durumda yakala
		# Motion degilse (RMB, Escape vb.) asagidaki kodun calismasina izin ver
	
	
	if not _is_dragging:
		return
	
	if event is InputEventMouseMotion:
		# Hayalet gorseli fareyi takip etsin
		if _drag_ghost and _drag_ghost.visible:
			var half: float = SLOT_SIZE / 2.0
			_drag_ghost.position = event.global_position - Vector2(half, half)
		
		# Hangi slotun uzerinde oldugumuzu bul
		var slot_idx: int = _get_slot_at_position(event.global_position)
		if slot_idx != _drag_hover_slot:
			# Eski highlight'i kaldir
			if _drag_hover_slot >= 0 and _drag_hover_slot < _slot_bgs.size() and _drag_hover_slot != _drag_source_slot:
				_slot_bgs[_drag_hover_slot].color = FILLED_COLOR if not player.hotbar[_drag_hover_slot].is_empty() else EMPTY_COLOR
			# Yeni highlight ekle
			_drag_hover_slot = slot_idx
			if _drag_hover_slot >= 0 and _drag_hover_slot < _slot_bgs.size() and _drag_hover_slot != _drag_source_slot:
				_slot_bgs[_drag_hover_slot].color = Color(0.3, 0.25, 0.4, 0.95)
	
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Birakma — swap yap
		_end_drag(event.global_position)
		get_viewport().set_input_as_handled()
	
	# Sag tik veya Escape ile suruklemeyi iptal et
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		_cancel_drag()
		get_viewport().set_input_as_handled()

## Slot suruklemeyi baslat
func _start_drag(slot_idx: int) -> void:
	if not player:
		return
	if slot_idx < 0 or slot_idx >= player.hotbar.size():
		return
	if player.hotbar[slot_idx].is_empty():
		return
	
	_drag_source_slot = slot_idx
	_drag_mouse_start = get_viewport().get_mouse_position()
	_drag_hover_slot = -1
	_is_dragging = false  # Henuz aktif degil, threshold'u bekliyor

## Suruklemeyi sonlandir ve swap yap
func _end_drag(mouse_pos: Vector2) -> void:
	var target_slot: int = _get_slot_at_position(mouse_pos)
	
	# Highlight'lari kaldir
	# Kaynak slot
	if _drag_source_slot >= 0 and _drag_source_slot < _slot_bgs.size():
		var ssp: String = player.hotbar[_drag_source_slot] if _drag_source_slot < player.hotbar.size() else ""
		_slot_bgs[_drag_source_slot].color = FILLED_COLOR if not ssp.is_empty() else EMPTY_COLOR
	# Hedef slot
	if _drag_hover_slot >= 0 and _drag_hover_slot < _slot_bgs.size() and _drag_hover_slot != _drag_source_slot:
		var sp: String = player.hotbar[_drag_hover_slot] if _drag_hover_slot < player.hotbar.size() else ""
		_slot_bgs[_drag_hover_slot].color = FILLED_COLOR if not sp.is_empty() else EMPTY_COLOR
	
	# Gorseli gizle
	if _drag_ghost:
		_drag_ghost.visible = false
	
	_tooltip_panel.visible = false
	
	# Swap: farkli bir slot ve gecerliyse
	if (_is_dragging and target_slot >= 0 and target_slot < player.hotbar.size()
			and target_slot != _drag_source_slot
			and _drag_source_slot >= 0 and _drag_source_slot < player.hotbar.size()):
		_swap_slots(_drag_source_slot, target_slot)
	
	_drag_source_slot = -1
	_drag_hover_slot = -1
	_is_dragging = false

## Suruklemeyi iptal et (sag tik / Escape ile)
func _cancel_drag() -> void:
	if _drag_ghost:
		_drag_ghost.visible = false
	# Kaynak slot highlight'ini geri yukle
	if _drag_source_slot >= 0 and _drag_source_slot < _slot_bgs.size():
		var sp: String = player.hotbar[_drag_source_slot] if _drag_source_slot < player.hotbar.size() else ""
		_slot_bgs[_drag_source_slot].color = FILLED_COLOR if not sp.is_empty() else EMPTY_COLOR
	# Hedef highlight'i kaldir
	if _drag_hover_slot >= 0 and _drag_hover_slot < _slot_bgs.size() and _drag_hover_slot != _drag_source_slot:
		var tsp: String = player.hotbar[_drag_hover_slot] if _drag_hover_slot < player.hotbar.size() else ""
		_slot_bgs[_drag_hover_slot].color = FILLED_COLOR if not tsp.is_empty() else EMPTY_COLOR
	_drag_source_slot = -1
	_drag_hover_slot = -1
	_is_dragging = false

## Iki hotbar slotunun icerigini degistir
func _swap_slots(from_idx: int, to_idx: int) -> void:
	if not player:
		return
	if from_idx < 0 or from_idx >= player.hotbar.size():
		return
	if to_idx < 0 or to_idx >= player.hotbar.size():
		return
	if from_idx == to_idx:
		return
	
	var temp: String = player.hotbar[from_idx]
	player.hotbar[from_idx] = player.hotbar[to_idx]
	player.hotbar[to_idx] = temp
	refresh()

## Global pozisyona gore hangi slotun uzerinde oldugumuzu bul
func _get_slot_at_position(pos: Vector2) -> int:
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
	var bar_w: float = 20 * SLOT_SIZE + 19 * SLOT_GAP
	var bar_x: float = (vp_w - bar_w) / 2
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 720)
	var bar_y: float = vp_h - SLOT_SIZE - 10
	
	var rel_x: float = pos.x - bar_x
	var rel_y: float = pos.y - bar_y
	
	if rel_y < -10 or rel_y > SLOT_SIZE + 10:
		return -1
	if rel_x < -10 or rel_x > bar_w + 10:
		return -1
	
	var idx: int = int(rel_x / (SLOT_SIZE + SLOT_GAP))
	if idx < 0 or idx >= 20:
		return -1
	
	# Tasma kontroli
	var slot_x: float = idx * (SLOT_SIZE + SLOT_GAP)
	if rel_x < slot_x - 2 or rel_x > slot_x + SLOT_SIZE + 2:
		return -1
	
	return idx

# ── Tooltip sistemi ──
var _tooltip_panel: Panel = null
var _tooltip_label: RichTextLabel = null
var _hovered_slot: int = -1

func _setup_tooltip() -> void:
	if _tooltip_panel:
		return
	_tooltip_panel = Panel.new()
	_tooltip_panel.visible = false
	_tooltip_panel.position = Vector2(0, 0)
	_tooltip_panel.size = Vector2(220, 100)
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_panel.z_index = 200
	var tt_style := StyleBoxFlat.new()
	tt_style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	tt_style.border_color = Color(0.6, 0.5, 0.35, 0.6)
	tt_style.border_width_left = 1
	tt_style.border_width_right = 1
	tt_style.border_width_top = 1
	tt_style.border_width_bottom = 1
	tt_style.set_corner_radius_all(6)
	tt_style.shadow_color = Color(0, 0, 0, 0.6)
	tt_style.shadow_size = 6
	tt_style.shadow_offset = Vector2(2, 3)
	_tooltip_panel.add_theme_stylebox_override("panel", tt_style)
	add_child(_tooltip_panel)
	
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.position = Vector2(6, 6)
	_tooltip_label.size = Vector2(208, 88)
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_label.add_theme_color_override("default_color", Color(0.85, 0.85, 0.9, 1.0))
	_tooltip_label.add_theme_font_size_override("normal_font_size", 9)
	_tooltip_panel.add_child(_tooltip_label)

# ── Hasar araligi yardimcisi ──

## Eski tek-satir gosterimi (kullanilmaz oldu, yerine _per_type_damage_text geldi)
func _damage_range_text(buckets_min: Dictionary, buckets_max: Dictionary) -> String:
	var parts: Array[String] = []
	for dmg_type in buckets_min:
		var lo := int(round(buckets_min[dmg_type]))
		var hi := int(round(buckets_max.get(dmg_type, lo)))
		var tname: String = dmg_type.capitalize()
		parts.append(str(lo) + "-" + str(hi) + " " + tname)
	return ", ".join(parts)

## Her hasar türünü ayrı satırda göster — renkli, Türkçe etiketli
func _per_type_damage_text(buckets_min: Dictionary, buckets_max: Dictionary, label: String = "Hasar") -> String:
	var type_colors := {
		"physical": "#ff7b6b",
		"fire": "#ff6633",
		"cold": "#66ccff",
		"lightning": "#ffee44",
		"chaos": "#cc44ff",
		"elemental": "#88ddff",
	}
	var type_names := {
		"physical": "Fiziksel",
		"fire": "Ateş",
		"cold": "Buz",
		"lightning": "Yıldırım",
		"chaos": "Kaos",
		"elemental": "Element",
	}
	var lines: Array[String] = []
	for dmg_type in buckets_min:
		var lo := int(round(buckets_min[dmg_type]))
		var hi := int(round(buckets_max.get(dmg_type, lo)))
		if lo <= 0 and hi <= 0:
			continue
		var c: String = type_colors.get(dmg_type, "#ffffff")
		var n: String = type_names.get(dmg_type, dmg_type.capitalize())
		lines.append("  [color=%s]%s: %d-%d[/color]" % [c, n, lo, hi])
	if lines.is_empty():
		return ""
	return "[color=#aaaaaa]" + label + ":[/color]\n" + "\n".join(lines)

func _on_slot_hover(slot_idx: int) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			return
	if slot_idx < 0 or slot_idx >= player.hotbar.size():
		return
	var skill_path: String = player.hotbar[slot_idx]
	if skill_path.is_empty() or not ResourceLoader.exists(skill_path):
		return
	var skill_data: SkillData = _get_skill_data(skill_path)
	if not skill_data:
		return
	
	_hovered_slot = slot_idx
	_setup_tooltip()
	
	# Tooltip metnini olustur
	var key_names := ["1","2","3","4","5","6","7","8","9","0","-","=","Q","-","E","R","T","Y","U","I"]
	var key_name: String = key_names[slot_idx] if slot_idx < key_names.size() else "?"
	
	var tt := "[b]" + skill_data.display_name + "[/b]  [color=#888888][ " + key_name + " ][/color]\n"
	tt += "[color=#aaaaaa]" + ", ".join(skill_data.tags) + "[/color]\n\n"
	
	# ── BUFF/AURA skill'leri ──
	if skill_data.is_buff() or skill_data.is_aura():
		# Aura seviyesi (player level'dan)
		var aura_lvl: int = player.stats.aura_level if player and player.stats else 1
		var aura_scale_coeff: float = 0.5 + 0.05 * aura_lvl
		tt += "[color=#ddaa66]Aura Seviyesi:[/color] [b]" + str(aura_lvl) + "[/b]  [color=#888888](x%.2f güç)[/color]\n\n" % aura_scale_coeff
		
		# Rezervasyon bilgisi
		if skill_data.aura_reservation_percent > 0.0:
			# Hangi kaynaktan rezerve edildiğini kontrol et (Life Reservation support)
			var has_life_res: bool = false
			var supports: Array[SupportData] = player._get_active_supports_for_skill(skill_path)
			for sd in supports:
				if sd and "life_reservation" in sd.added_tags:
					has_life_res = true
					break
			if has_life_res:
				tt += "[color=#dd6666]Reserve:[/color] %s%% Life\n" % str(skill_data.aura_reservation_percent)
			else:
				tt += "[color=#5588dd]Reserve:[/color] %s%% Mana\n" % str(skill_data.aura_reservation_percent)
		elif skill_data.aura_reservation_flat > 0.0:
			tt += "[color=#5588dd]Reserve:[/color] %g Mana\n" % skill_data.aura_reservation_flat
		else:
			tt += "[color=#5588dd]Reserve:[/color] 25%% Mana\n"
		
		# Buff etkileri (buff_tags'ten oku: "attack_speed:30" -> +30% Attack Speed)
		if skill_data.buff_tags.size() > 0:
			tt += "\n[color=#88dd88]Effects:[/color]\n"
			# İstatistiklerin güzel görünen adları
			var stat_display_names: Dictionary = {
				"attack_speed": "Saldırı Hızı",
				"movement_speed": "Hareket Hızı",
				"max_life": "Maksimum Can",
				"life_recovery_rate": "Can Geri Kazanım",
				"chain_count": "Chain",
				"accuracy": "İsabet",
				"critical_chance": "Kritik Şansı",
				"armour": "Zırh",
				"block_chance": "Blok Şansı",
				"max_energy_shield": "Enerji Kalkanı",
				"elemental_damage": "Element Hasarı",
				"cast_speed": "Yetenek Hızı",
				"life_regen": "Can Yenilenme",
				"mana_regen": "Mana Yenilenme",
				"physical_damage": "Fiziksel Hasar",
				"fire_damage": "Ateş Hasarı",
				"cold_damage": "Buz Hasarı",
				"lightning_damage": "Yıldırım Hasarı",
				"chaos_damage": "Kaos Hasarı",
				"max_mana": "Maksimum Mana",
				"evasion": "Kaçınma",
				"mana_recovery_rate": "Mana Geri Kazanım",
				"all_resistance": "Tüm Dirençler",
				"area_of_effect": "Alan Etkisi",
				"cooldown_recovery": "Bekleme Süresi",
				"projectile_speed": "Mermi Hızı",
				"damage_over_time": "Zamanla Hasar",
				"projectile_damage": "Mermi Hasarı",
				"area_damage": "Alan Hasarı",
				"dodge_chance": "Kaçınma Şansı",
				"life_gain_on_hit": "Vuruşta Can",
				"es_recharge_delay": "ES Şarj Gecikmesi",
				"es_recharge_rate": "ES Şarj Hızı",
				"melee_range_bonus": "Yakın Dövüş Menzili",
			}
			for tag in skill_data.buff_tags:
				var parts: PackedStringArray = tag.split(":")
				var effect_key: String = parts[0]
				var effect_name: String = stat_display_names.get(effect_key, effect_key.replace("_", " ").capitalize())
				if parts.size() >= 2:
					var val_str: String = parts[1]
					var val_num: float = val_str.to_float()
					
					# Scaled değeri hesapla (level ile büyütülmüş)
					var scaled_val: float = val_num * aura_scale_coeff
					
					# chain_count gibi flat değerler % olarak gösterilmez
					if effect_key == "chain_count":
						var final_chain: int = maxi(1, int(round(scaled_val)))
						var prefix: String = "+" if final_chain >= 0 else ""
						tt += "  • [color=#88ccaa]" + prefix + str(final_chain) + " " + effect_name + "[/color]"
						if aura_lvl > 1:
							tt += " [color=#666666](base: " + val_str + ")[/color]"
						tt += "\n"
					elif effect_key == "max_life" and val_num < 0.0:
						# Negatif max_life (ör. sacrifice_aura) kırmızı ceza olarak
						var penalty_val: float = absf(scaled_val)
						tt += "  • [color=#dd6666]-%d%%[/color] " % penalty_val + effect_name + " [color=#886666](ceza)[/color]\n"
					elif val_num < 0.0:
						var penalty_val: float = absf(scaled_val)
						tt += "  • [color=#dd6666]-%d%%[/color] " % penalty_val + effect_name + "\n"
					else:
						var display_val: int = int(round(scaled_val))
						tt += "  • [color=#88ccaa]+%d%%[/color] " % display_val + effect_name
						if aura_lvl > 1:
							tt += " [color=#666666](base: +" + val_str + "%[/color][color=#666666])[/color]"
						tt += "\n"
				else:
					tt += "  • " + effect_name + "\n"
		
		# Cooldown
		if skill_data.cooldown > 0:
			tt += "\n[color=#88aadd]Cooldown:[/color] " + str(skill_data.cooldown) + "s\n"
		
		# Support gem modifier'larini buff degerlerine uygula (tooltip gostergesi)
		var bs_supports: Array[SupportData] = player._get_active_supports_for_skill(skill_path)
		var has_support_effect: bool = false
		if bs_supports.size() > 0:
			# Her buff tag icin support-modified degeri hesapla
			var support_buff_mods: Dictionary = {}
			for tag in skill_data.buff_tags:
				var parts: PackedStringArray = tag.split(":")
				if parts.size() >= 2:
					var key: String = parts[0]
					support_buff_mods[key] = (parts[1].to_float() * aura_scale_coeff)
			# Support mod'larini uygula (toggle_buff ile ayni mantik)
			for sd in bs_supports:
				if sd is SupportData:
					for mod in sd.modifiers:
						if mod is not StatModifier:
							continue
						var target_keys: Array[String] = []
						if mod.stat == "damage":
							for bk in support_buff_mods:
								if bk.ends_with("_damage") or bk == "all_damage":
									if mod.damage_type_filter == "":
										target_keys.append(bk)
									elif mod.damage_type_filter == "elemental":
										if bk in ["fire_damage", "cold_damage", "lightning_damage", "elemental_damage"]:
											target_keys.append(bk)
									elif mod.damage_type_filter == "fire" and bk in ["fire_damage", "elemental_damage"]:
										target_keys.append(bk)
									elif mod.damage_type_filter == "cold" and bk in ["cold_damage", "elemental_damage"]:
										target_keys.append(bk)
									elif mod.damage_type_filter == "lightning" and bk in ["lightning_damage", "elemental_damage"]:
										target_keys.append(bk)
						elif mod.stat in support_buff_mods:
							target_keys.append(mod.stat)
						for bk in target_keys:
							match mod.modifier_type:
								StatModifier.ModifierType.FLAT:
									support_buff_mods[bk] += mod.value
								StatModifier.ModifierType.INCREASED, StatModifier.ModifierType.MORE:
									support_buff_mods[bk] *= (1.0 + mod.value / 100.0)
							has_support_effect = true
			# Support etkisi varsa "With Support" satiri ekle
			if has_support_effect:
				tt += "\n[color=#eebb55]With Support:[/color]\n"
				for bkey in support_buff_mods:
					var base_val: float = -9999.0
					for tag in skill_data.buff_tags:
						var parts: PackedStringArray = tag.split(":")
						if parts.size() >= 2 and parts[0] == bkey:
							base_val = parts[1].to_float() * aura_scale_coeff
							break
					if base_val == -9999.0:
						continue
					var display_name: String = {
					"attack_speed": "Saldırı Hızı",
					"movement_speed": "Hareket Hızı",
					"max_life": "Maksimum Can",
					"life_recovery_rate": "Can Geri Kazanım",
					"chain_count": "Chain",
					"accuracy": "İsabet",
					"critical_chance": "Kritik Şansı",
					"armour": "Zırh",
					"block_chance": "Blok Şansı",
					"max_energy_shield": "Enerji Kalkanı",
					"elemental_damage": "Element Hasarı",
					"cast_speed": "Yetenek Hızı",
					"life_regen": "Can Yenilenme",
					"mana_regen": "Mana Yenilenme",
					"physical_damage": "Fiziksel Hasar",
					"fire_damage": "Ateş Hasarı",
					"cold_damage": "Buz Hasarı",
					"lightning_damage": "Yıldırım Hasarı",
					"chaos_damage": "Kaos Hasarı",
					"max_mana": "Maksimum Mana",
					"evasion": "Kaçınma",
					"mana_recovery_rate": "Mana Geri Kazanım",
					"all_resistance": "Tüm Dirençler",
					"area_of_effect": "Alan Etkisi",
					"cooldown_recovery": "Bekleme Süresi",
					"all_damage": "Tüm Hasar",
					"projectile_speed": "Mermi Hızı",
					"damage_over_time": "Zamanla Hasar",
					"projectile_damage": "Mermi Hasarı",
					"area_damage": "Alan Hasarı",
					"dodge_chance": "Kaçınma Şansı",
					"life_gain_on_hit": "Vuruşta Can",
					"es_recharge_delay": "ES Şarj Gecikmesi",
					"es_recharge_rate": "ES Şarj Hızı",
					"melee_range_bonus": "Yakın Dövüş Menzili",
				}.get(bkey, bkey.replace("_", " ").capitalize())
					var new_val: float = support_buff_mods[bkey]
					if absf(new_val - base_val) > 0.01:
						if bkey == "chain_count":
							tt += "  • [color=#88ccaa]+%d[/color] " % maxi(1, int(round(new_val))) + display_name
							tt += " [color=#888888](base: +%d)[/color]\n" % maxi(1, int(round(base_val)))
						else:
							var prefix: String = "+" if new_val >= 0 else ""
							tt += "  • [color=#88ccaa]" + prefix + "%d%%[/color] " % int(round(new_val)) + display_name
							tt += " [color=#888888](base: +%d%%)[/color]\n" % int(round(base_val))
		
		# Support gem listesi
		if bs_supports.size() > 0:
			tt += "\n[color=#88dd88]Support Gems:[/color]\n"
			for sd in bs_supports:
				if sd is SupportData:
					var desc_parts: Array[String] = []
					for mod in sd.modifiers:
						var mod_str: String = ""
						match mod.modifier_type:
							StatModifier.ModifierType.FLAT:
								mod_str = "+" + str(mod.value) + " Flat"
							StatModifier.ModifierType.INCREASED:
								mod_str = "+" + str(mod.value) + "% Increased"
							StatModifier.ModifierType.MORE:
								if mod.value < 0.0:
									mod_str = str(mod.value) + "% More"
								else:
									mod_str = "+" + str(mod.value) + "% More"
						if mod.damage_type_filter != "":
							if mod.damage_type_filter == "radius":
								mod_str += " Radius"
							else:
								mod_str += " " + mod.damage_type_filter.capitalize()
						desc_parts.append(mod_str)
					tt += "  • " + sd.display_name + " [color=#88aacc](" + ", ".join(desc_parts) + ")[/color]\n"
		
		_tooltip_label.text = tt
		_tooltip_panel.size = Vector2(250, _tooltip_label.get_content_height() + 12)
		# Tooltip'i slot'un yaninda goster
		var tt_vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
		var tt_bar_w: float = 20 * SLOT_SIZE + 19 * SLOT_GAP
		var tt_bar_x: float = (tt_vp_w - tt_bar_w) / 2
		var tt_sx: float = tt_bar_x + slot_idx * (SLOT_SIZE + SLOT_GAP)
		var tt_vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 720)
		var tt_bar_y: float = tt_vp_h - SLOT_SIZE - 10
		_tooltip_panel.position = Vector2(tt_sx, tt_bar_y - _tooltip_panel.size.y - 4)
		_tooltip_panel.visible = true
		return
	
	# ── Normal skill'ler için chain/AoE/projectile bilgisi ──
	var has_extra_info: bool = false
	var extra_info_parts: Array[String] = []
	
	# Chain count
	if ("chain_count" in skill_data and skill_data.chain_count > 0):
		extra_info_parts.append("⚡ %d Zincir" % skill_data.chain_count)
		has_extra_info = true
	
	# AoE radius
	if ("area_radius" in skill_data and skill_data.area_radius > 0.0):
		extra_info_parts.append("💥 %.0fpx Alan" % skill_data.area_radius)
		has_extra_info = true
	
	# Projectile count
	if ("projectile_count" in skill_data and skill_data.projectile_count > 0):
		extra_info_parts.append("🏹 %d Mermi" % skill_data.projectile_count)
		has_extra_info = true
	
	# Pierce count
	if ("pierce_count" in skill_data and skill_data.pierce_count > 0):
		extra_info_parts.append("🗡️ %d Delme" % skill_data.pierce_count)
		has_extra_info = true
	
	if has_extra_info:
		tt += "\n[color=#88aacc]" + " • ".join(extra_info_parts) + "[/color]\n"
	
	# ── Infernal Circle: özel tooltip (hasar runtime'da hesaplanır) ──
	if skill_data.id == "infernal_circle":
		var aura_lvl: int = player.stats.aura_level if player and player.stats else 1
		var base_tick: float = 8.0 + aura_lvl * 2.5
		var radius_val: float = 120.0 + aura_lvl * 8.0
		tt += "[color=#ddaa66]Aura Seviyesi:[/color] [b]" + str(aura_lvl) + "[/b]\n"
		tt += "[color=#dd8844]Radius:[/color] %d\n" % int(radius_val)
		tt += "[color=#dd8844]Tick Hızı:[/color] her 0.5s\n\n"
		
		# Passive scaling'i hesapla
		if player.stats:
			var total_inc: float = player.stats.fire_damage_increased \
					+ player.stats.area_damage_increased \
					+ player.stats.elemental_damage_increased \
					+ player.stats.all_damage_increased
			var life_regen_bonus: float = player.stats.life_regen_per_second * 2.0
			var tick_dmg: float = (base_tick + life_regen_bonus) * (1.0 + total_inc / 100.0)
			var dps: float = tick_dmg * 2.0  # 2 tick/s
			
			tt += "[color=#eebb55]Base Tick:[/color] %.1f Fire\n" % base_tick
			if life_regen_bonus > 0.0:
				tt += "[color=#88ccaa]+%.1f[/color] [color=#88aa88](Can Yenilenme x2)[/color]\n" % life_regen_bonus
			if total_inc > 0.0:
				tt += "[color=#88ccaa]x%.2f[/color] [color=#88aa88](+%d%% passive)[/color]\n" % [1.0 + total_inc / 100.0, int(total_inc)]
			tt += "\n[color=#dd8844]Tick Damage:[/color] [b]%.1f[/b] Fire\n" % tick_dmg
			tt += "[color=#dd8844]DPS:[/color] [b]%.1f[/b] Fire\n" % dps
		
		# Life drain info
		var base_drain: float = 10.0 + aura_lvl * 3.0
		var regen: float = player.stats.life_regen_per_second if player.stats else 0.0
		tt += "\n[color=#dd6666]Life Drain:[/color] %.1f/s" % base_drain
		if regen > 0.0:
			tt += "  [color=#66dd66](-%.1f regen)[/color]" % regen
			var net: float = base_drain - regen
			if net <= 0.0:
				tt += "\n[color=#66dd66]Can yenilenmen drain'i karsiliyor![/color]"
		
		# Support gem listesi
		var active_supports: Array[SupportData] = player._get_active_supports_for_skill(skill_path)
		if active_supports.size() > 0:
			tt += "\n[color=#88dd88]Support Gems:[/color]\n"
			for sd in active_supports:
				if sd is SupportData:
					var desc_parts: Array[String] = []
					for mod in sd.modifiers:
						var mod_str: String = ""
						match mod.modifier_type:
							StatModifier.ModifierType.FLAT:
								mod_str = "+" + str(mod.value) + " Flat"
							StatModifier.ModifierType.INCREASED:
								mod_str = "+" + str(mod.value) + "% Increased"
							StatModifier.ModifierType.MORE:
								if mod.value < 0.0:
									mod_str = str(mod.value) + "% More"
								else:
									mod_str = "+" + str(mod.value) + "% More"
						if mod.damage_type_filter != "":
							if mod.damage_type_filter == "radius":
								mod_str += " Radius"
							else:
								mod_str += " " + mod.damage_type_filter.capitalize()
						desc_parts.append(mod_str)
					tt += "  • " + sd.display_name + " [color=#88aacc](" + ", ".join(desc_parts) + ")[/color]\n"
		
		_tooltip_label.text = tt
		_tooltip_panel.size = Vector2(250, _tooltip_label.get_content_height() + 12)
		var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
		var bar_w: float = 20 * SLOT_SIZE + 19 * SLOT_GAP
		var bar_x: float = (vp_w - bar_w) / 2
		var sx: float = bar_x + slot_idx * (SLOT_SIZE + SLOT_GAP)
		var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 720)
		var bar_y: float = vp_h - SLOT_SIZE - 10
		_tooltip_panel.position = Vector2(sx, bar_y - _tooltip_panel.size.y - 4)
		_tooltip_panel.visible = true
		return
	
	# ── Gerçek silah hasarını oku (player._calculate_weapon_damage_range) ──
	var wr: Dictionary = player._calculate_weapon_damage_range()
	var weapon_min: float = wr.min
	var weapon_max: float = wr.max
	# Skill damage_effectiveness uygula
	var wpn_min: float = weapon_min * skill_data.damage_effectiveness
	var wpn_max: float = weapon_max * skill_data.damage_effectiveness
	var wpn_avg: float = (wpn_min + wpn_max) / 2.0
	
	# Silah affix'lerinden gelen adds_X_damage (flat, bucket dağıtımına tabi değil)
	var wpn_item: ItemData = player.equipment.get_item_in_slot(0)  # WEAPON slot
	var adds_damage: Dictionary = {}  # {"fire": [min, max], ...}
	if wpn_item and wpn_item.affixes.size() > 0:
		var adds_raw: Dictionary = {}
		if player and player.has_method("_get_adds_damage_from_affixes"):
			adds_raw = player._get_adds_damage_from_affixes(wpn_item)
		for dmg_type in adds_raw:
			var aff_range = adds_raw[dmg_type]
			adds_damage[dmg_type] = [aff_range.min * skill_data.damage_effectiveness, aff_range.max * skill_data.damage_effectiveness]
	
	# Bucket distribution (sadece base silah hasarı)
	var buckets: Dictionary = skill_data.damage_buckets.duplicate()
	if buckets.is_empty():
		var dt: String = skill_data.damage_type if skill_data.damage_type != "" else "physical"
		buckets[dt] = skill_data.base_damage
	var bucket_total: float = 0.0
	for key in buckets:
		bucket_total += absf(buckets[key])
	if bucket_total <= 0.0:
		bucket_total = 1.0
		buckets = {"physical": wpn_avg}
	
	var btype_ratios: Dictionary = {}
	for btype in buckets:
		btype_ratios[btype] = absf(buckets[btype]) / bucket_total
	
	var base_min_no_inc: Dictionary = {}
	var base_max_no_inc: Dictionary = {}
	for btype in buckets:
		base_min_no_inc[btype] = btype_ratios[btype] * wpn_min
		base_max_no_inc[btype] = btype_ratios[btype] * wpn_max
	
	# Pasif ağacı increased damage uygula (en yüksek bucket'a göre)
	var dmg_type_label: String = "physical"
	var highest_val: float = 0.0
	for bt in buckets:
		var av: float = absf(buckets[bt])
		if av > highest_val:
			highest_val = av
			dmg_type_label = bt
	
	var inc_mult: float = 1.0
	if player.stats:
		var inc_dmg: float = player.stats.all_damage_increased
		match dmg_type_label:
			"physical":
				inc_dmg += player.stats.physical_damage_increased
			"fire":
				inc_dmg += player.stats.fire_damage_increased + player.stats.elemental_damage_increased
			"cold":
				inc_dmg += player.stats.cold_damage_increased + player.stats.elemental_damage_increased
			"lightning":
				inc_dmg += player.stats.lightning_damage_increased + player.stats.elemental_damage_increased
		if inc_dmg != 0.0:
			inc_mult = 1.0 + inc_dmg / 100.0
	
	# Base + passive inc (sadece base weapon damage, affix flat olarak eklenir)
	var base_min_buckets: Dictionary = {}
	var base_max_buckets: Dictionary = {}
	for btype in base_min_no_inc:
		base_min_buckets[btype] = base_min_no_inc[btype] * inc_mult
		base_max_buckets[btype] = base_max_no_inc[btype] * inc_mult
	
	# Affix hasarını da passive inc etkiler (ama bucket dağıtımı yapılmaz)
	var affix_min_buckets: Dictionary = {}
	var affix_max_buckets: Dictionary = {}
	for dmg_type in adds_damage:
		affix_min_buckets[dmg_type] = adds_damage[dmg_type][0] * inc_mult
		affix_max_buckets[dmg_type] = adds_damage[dmg_type][1] * inc_mult
	
	# Final hasar = base + affix (her tür ayrı)
	var final_min_buckets: Dictionary = base_min_buckets.duplicate()
	var final_max_buckets: Dictionary = base_max_buckets.duplicate()
	for dmg_type in affix_min_buckets:
		if not final_min_buckets.has(dmg_type):
			final_min_buckets[dmg_type] = 0.0
			final_max_buckets[dmg_type] = 0.0
		final_min_buckets[dmg_type] += affix_min_buckets[dmg_type]
		final_max_buckets[dmg_type] += affix_max_buckets[dmg_type]
	
	var inc_label: String = ""
	if inc_mult > 1.01:
		var inc_pct: int = int(round((inc_mult - 1.0) * 100.0))
		inc_label = "  [color=#88aa88](+%d%% pasif)[/color]" % inc_pct
	
	# Support gem'leri al ve SkillInstance ile modified hasari hesapla
	var active_supports: Array = player._get_active_supports_for_skill(skill_path)
	
	if active_supports.size() > 0:
		tt += _per_type_damage_text(final_min_buckets, final_max_buckets, "Base Damage") + inc_label + "\n"
		
		# SkillInstance: sadece support gem'leri uygular
		var skill_inst := SkillInstance.new(skill_data, active_supports)
		var modified_avg_no_inc: Dictionary = skill_inst.get_final_damage(func(_s): return wpn_avg)
		
		# Support ratio'sunu hesapla
		var mod_min_buckets: Dictionary = {}
		var mod_max_buckets: Dictionary = {}
		for btype in base_min_no_inc:
			var base_min_val: float = base_min_no_inc[btype]
			var base_max_val: float = base_max_no_inc[btype]
			var avg_val: float = modified_avg_no_inc.get(btype, (base_min_val + base_max_val) / 2.0)
			var avg_base: float = (base_min_val + base_max_val) / 2.0
			if avg_base == 0.0:
				mod_min_buckets[btype] = base_min_val * inc_mult
				mod_max_buckets[btype] = base_max_val * inc_mult
			else:
				var ratio_change: float = avg_val / avg_base
				mod_min_buckets[btype] = base_min_val * inc_mult * ratio_change
				mod_max_buckets[btype] = base_max_val * inc_mult * ratio_change
		# Affix hasarına da support çarpanı uygula (base bucket ile aynı oran)
		for dmg_type in affix_min_buckets:
			if not mod_min_buckets.has(dmg_type):
				mod_min_buckets[dmg_type] = 0.0
				mod_max_buckets[dmg_type] = 0.0
			var aff_min: float = affix_min_buckets[dmg_type]
			var aff_max: float = affix_max_buckets[dmg_type]
			# Aynı damage type için varsa support ratio'sunu uygula, yoksa olduğu gibi ekle
			if base_min_no_inc.has(dmg_type) and base_min_no_inc[dmg_type] != 0.0:
				var avg_base_for_type: float = (base_min_no_inc[dmg_type] + base_max_no_inc[dmg_type]) / 2.0
				var avg_val: float = modified_avg_no_inc.get(dmg_type, avg_base_for_type)
				var ratio: float = avg_val / avg_base_for_type
				mod_min_buckets[dmg_type] += aff_min * ratio
				mod_max_buckets[dmg_type] += aff_max * ratio
			else:
				mod_min_buckets[dmg_type] += aff_min
				mod_max_buckets[dmg_type] += aff_max
		tt += "[color=#eebb55]With Support:[/color]\n" + _per_type_damage_text(mod_min_buckets, mod_max_buckets) + "\n"
		
		# Support gem listesi
		tt += "\n[color=#88dd88]Support Gems:[/color]\n"
		for sd in active_supports:
			if sd is SupportData:
				var desc_parts: Array[String] = []
				for mod in sd.modifiers:
					var mod_str: String = ""
					match mod.modifier_type:
						StatModifier.ModifierType.FLAT:
							mod_str = "+" + str(mod.value) + " Flat"
						StatModifier.ModifierType.INCREASED:
							mod_str = "+" + str(mod.value) + "% Increased"
						StatModifier.ModifierType.MORE:
							mod_str = "+" + str(mod.value) + "% More"
					if mod.damage_type_filter != "":
						if mod.damage_type_filter == "radius":
							mod_str += " Radius"
						else:
							mod_str += " " + mod.damage_type_filter.capitalize()
					desc_parts.append(mod_str)
				tt += "  • " + sd.display_name + " [color=#88aacc](" + ", ".join(desc_parts) + ")[/color]\n"
	else:
		# Support yok, hasarı göster
		tt += _per_type_damage_text(final_min_buckets, final_max_buckets, "Damage") + inc_label + "\n"
	
	# Mana / Life cost (efektif, passive + support dahil)
	if skill_data.mana_cost > 0:
		var mana_cost: float = player._calc_effective_mana_cost(skill_path, skill_data)
		var life_cost: float = player._calc_effective_life_cost(skill_path, skill_data)
		if mana_cost > 0.0 and life_cost > 0.0:
			tt += "\n[color=#5588dd]Mana Cost:[/color] " + str(int(mana_cost)) + "  [color=#dd6666]Life Cost:[/color] " + str(int(life_cost)) + "\n"
		elif mana_cost > 0.0:
			tt += "\n[color=#5588dd]Mana Cost:[/color] " + str(int(mana_cost)) + "\n"
		elif life_cost > 0.0:
			tt += "\n[color=#dd6666]Life Cost:[/color] " + str(int(life_cost)) + "\n"
	
	# Cooldown
	if skill_data.cooldown > 0:
		tt += "[color=#88aadd]Cooldown:[/color] " + str(skill_data.cooldown) + "s\n"
	
	_tooltip_label.text = tt
	_tooltip_panel.size = Vector2(250, _tooltip_label.get_content_height() + 12)
	
	# Tooltip'i slot'un yaninda goster
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 1280)
	var bar_w: float = 20 * SLOT_SIZE + 19 * SLOT_GAP
	var bar_x: float = (vp_w - bar_w) / 2
	var sx: float = bar_x + slot_idx * (SLOT_SIZE + SLOT_GAP)
	
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 720)
	var bar_y: float = vp_h - SLOT_SIZE - 10
	_tooltip_panel.position = Vector2(sx, bar_y - _tooltip_panel.size.y - 4)
	
	_tooltip_panel.visible = true

func _on_slot_unhover() -> void:
	_hovered_slot = -1
	if _tooltip_panel:
		_tooltip_panel.visible = false

func _on_slot_gui_input(event: InputEvent, slot_idx: int) -> void:
	"""Sol tik = skill kullan / drag baslangici. Sag tik = buff toggle."""
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Sag tik: buff toggle / skill kullan
			player.cast_hotbar_skill(slot_idx)
		
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Sol tik basili: drag baslangicini kaydet
			if not player.hotbar[slot_idx].is_empty():
				_start_drag(slot_idx)
		
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			# Sol tik birakma
			if _drag_source_slot >= 0 and _is_dragging:
				# Surukleme yapildi -> swap yap
				_end_drag(event.global_position)
			elif _drag_source_slot >= 0 and not _is_dragging:
				# Threshold asilmadi -> bu bir tiklamaydi, skill'i kullan
				_drag_source_slot = -1
				player.cast_hotbar_skill(slot_idx)
