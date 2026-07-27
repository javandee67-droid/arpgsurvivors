extends CanvasLayer
class_name HUD
## Modern HUD: HP+ES shield overlay, full-width XP bar at bottom.

var player = null  # type: Node (assigned at runtime)
var health_fill: ColorRect
var health_drain: ColorRect  # Delay bar (two-layer health effect)
var health_bg: ColorRect
var _drain_target: float = 1.0  # HP orani hedefi (delay bar icin)
var _drain_current: float = 1.0
var es_overlay: ColorRect
var level_label: Label
var health_label: Label
var es_label: Label
var xp_fill: ColorRect
var xp_bg: ColorRect
var xp_label: Label
var _vignette: ColorRect = null  # Dusuk can efekti
var _damage_flash: ColorRect = null  # Hasar aldığında kırmızı flash
var _vs_kill_label: Label = null  # VS kill counter
var _connected: bool = false
var _wave_label: Label = null
var _tier_label: Label = null  # Difficulty tier göstergesi

# ── Status Effects UI (top-left ailment display) ──
var _status_container: HBoxContainer = null
var _status_tooltip_panel: Panel = null
var _status_tooltip_label: RichTextLabel = null
var _hovered_effect_row: int = -1  # index of hovered effect for tooltip
var _ailment_ctrl: AilmentController = null
var _effect_rows: Array[Control] = []  # cached rows for updating timers
var _biome_label: Label = null          # Biyom bildirimi etiketi
var _boss_bar: ColorRect = null         # Boss can çubuğu arkaplanı
var _boss_fill: ColorRect = null        # Boss can çubuğu dolgusu
var _boss_name: Label = null            # Boss adı
var _boss_hp_label: Label = null        # Boss can yazısı
var _boss_node: Node = null             # Mevcut boss referansı

# VS süre kronometresi
var _timer_label: Label = null
const STATUS_ICONS: Dictionary = {
	0: "res://assets/generated/status_chill_frame_0.png",   # CHILL
	1: "res://assets/generated/status_chill_frame_0.png",   # FREEZE (chill icon)
	2: "res://assets/generated/status_shock_frame_0.png",   # SHOCK
	3: "res://assets/generated/status_burn_frame_0.png",    # IGNITE
	4: "res://assets/generated/status_poison_frame_0.png",  # POISON
	5: "res://assets/generated/status_bleed_frame_0.png",   # BLEED
	6: "res://assets/generated/status_debuff_new_frame_0.png",  # CRUSHED
	7: "res://assets/generated/status_debuff_new_frame_0.png",  # INTIMIDATED
	8: "res://assets/generated/status_debuff_new_frame_0.png",  # UNNERVE
	9: "res://assets/generated/status_debuff_new_frame_0.png",  # MAIM
	10: "res://assets/generated/status_debuff_new_frame_0.png", # HINDER
	11: "res://assets/generated/status_debuff_new_frame_0.png", # BLIND
	12: "res://assets/generated/status_debuff_new_frame_0.png", # WITHER
	13: "res://assets/generated/status_debuff_new_frame_0.png", # TAUNT
	14: "res://assets/generated/status_buff_new_frame_0.png",   # CONSECRATED
	15: "res://assets/generated/status_buff_new_frame_0.png",   # BUFF_ONSLAUGHT
	16: "res://assets/generated/status_buff_new_frame_0.png",   # BUFF_FORTIFY
	17: "res://assets/generated/status_buff_new_frame_0.png",   # BUFF_HASTE
}

const STATUS_DISPLAY: Dictionary = {
	0: {"name": "Yavaşlatma", "desc": "Hareket ve saldırı hızın azalır."},           # CHILL
	1: {"name": "Donma", "desc": "Tamamen donarsın, hiçbir şey yapamazsın!"},         # FREEZE
	2: {"name": "Şok", "desc": "%d%% daha fazla hasar alırsın."},                    # SHOCK (magnitude)
	3: {"name": "Yanma", "desc": "Her saniye ateş hasarı alırsın!"},                  # IGNITE
	4: {"name": "Zehir", "desc": "Her saniye kaos hasarı alırsın. (Birikir)"},        # POISON
	5: {"name": "Kanama", "desc": "Hareket ettiğinde fiziksel hasar alırsın."},       # BLEED
	6: {"name": "Ezilme", "desc": "Aksiyon hızın azalır."},                           # CRUSHED
	7: {"name": "Sindirme", "desc": "Aldığın hasar artar."},                          # INTIMIDATED
	8: {"name": "Bezdiri", "desc": "Aldığın büyü hasarı artar."},                     # UNNERVE
	9: {"name": "Sakatlama", "desc": "Hareket hızın %%30 azalır."},                   # MAIM
	10: {"name": "Engelleme", "desc": "Büyü hızın azalır."},                          # HINDER
	11: {"name": "Körlük", "desc": "İsabet şansın %%20 azalır."},                     # BLIND
	12: {"name": "Soldurma", "desc": "Aldığın kaos hasarı artar. (Birikir)"},         # WITHER
	13: {"name": "Tahrik", "desc": "Seni kışkırtan düşmana saldırmak zorundasın!"},  # TAUNT
	14: {"name": "Kutsanma", "desc": "Her saniye canının %%6'sını yenilersin."},      # CONSECRATED
	15: {"name": "Hücum", "desc": "Saldırı hızı, büyü hızı ve hareket hızı artar."}, # BUFF_ONSLAUGHT
	16: {"name": "Tahkim", "desc": "Aldığın hasar %%20 azalır."},                     # BUFF_FORTIFY
	17: {"name": "Hızlanma", "desc": "Saldırı hızın ve hareket hızın artar."},        # BUFF_HASTE
}

func set_kill_count(count: int) -> void:
	if _vs_kill_label:
		_vs_kill_label.text = "Öldürülen: %d" % count

func set_game_time(time_sec: float) -> void:
	if _timer_label:
		var minutes: int = int(time_sec) / 60
		var seconds: int = int(time_sec) % 60
		_timer_label.text = "%d:%02d" % [minutes, seconds]

func set_wave(wave: int) -> void:
	if _wave_label:
		_wave_label.text = "Wave: %d" % wave

func set_tier(tier: int) -> void:
	if _tier_label:
		# Renk kodlaması: tier arttıkça kırmızıya döner
		var tier_color: Color
		match tier:
			1: tier_color = Color(0.5, 0.9, 0.5)  # Yeşil - kolay
			2: tier_color = Color(0.9, 0.9, 0.4)  # Sarı - orta
			3: tier_color = Color(0.9, 0.7, 0.3)  # Turuncu - zor
			4: tier_color = Color(0.9, 0.5, 0.3)  # Koyu turuncu - çok zor
			5: tier_color = Color(0.9, 0.3, 0.3)  # Kırmızı - çok zor
			_: tier_color = Color(0.7, 0.2, 0.9)  # Mor - boss seviyesi
		
		var icon: String
		match tier:
			1: icon = "☆"
			2: icon = "★"
			3: icon = "★★"
			4: icon = "★★★"
			5: icon = "✦✦✦"
			_: icon = "⚠"
		
		_tier_label.text = "%s TIER %d" % [icon, tier]
		_tier_label.add_theme_color_override("font_color", tier_color)

func _ready() -> void:
	_build_ui()
	process_mode = PROCESS_MODE_ALWAYS
	# Viewport boyutu değişince HUD'u yeniden konumlandır
	var root := get_tree().root
	if root:
		root.size_changed.connect(_reposition_ui)
	# Hasar aldığında damage flash göster
	EventBus.damage_dealt.connect(_on_damage_dealt)

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	var bx := 16
	var by := 50  # Sol ust kose — alt kisimda SkillBar ile cakismasin

	# === KOMPAKT ARKAPLAN (sadece HP/MP kısmı, XP ayrı) ===
	var bg_panel := ColorRect.new()
	bg_panel.color = Color(0.02, 0.02, 0.04, 0.6)
	bg_panel.position = Vector2(bx - 8, by - 4)
	bg_panel.size = Vector2(276, 70)
	add_child(bg_panel)

	var border_line := ColorRect.new()
	border_line.color = Color(0.35, 0.25, 0.5, 0.25)
	border_line.position = Vector2(bx - 8, by - 5)
	border_line.size = Vector2(276, 1)
	add_child(border_line)

	# === SEVİYE ===
	level_label = Label.new()
	level_label.position = Vector2(bx, by - 2)
	level_label.size = Vector2(80, 14)
	level_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.5))
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.text = "Seviye 1"
	add_child(level_label)

	var sy := by + 14

	# == CAN BAR (HP + ES overlay) ==
	# Arkaplan (koyu)
	health_bg = ColorRect.new()
	health_bg.color = Color(0.05, 0.05, 0.06, 0.95)
	health_bg.position = Vector2(bx, sy)
	health_bg.size = Vector2(260, 24)
	add_child(health_bg)

	# HP drain (arka katman - koyu kırmızı, yavaş azalır)
	health_drain = ColorRect.new()
	health_drain.color = Color(0.5, 0.08, 0.08)
	health_drain.position = Vector2(bx, sy)
	health_drain.size = Vector2(260, 24)
	add_child(health_drain)

	# HP fill (üst katman - parlak kırmızı, anlık değişir)
	health_fill = ColorRect.new()
	health_fill.color = Color(0.72, 0.12, 0.12)
	health_fill.position = Vector2(bx, sy)
	health_fill.size = Vector2(260, 24)
	add_child(health_fill)

	# ES overlay (üst katman - mavi yarı saydam shield, HP'nin üstünde)
	# Sağdan sola dolan, HP'nin üzerine oturan bir shield görünümü
	es_overlay = ColorRect.new()
	es_overlay.color = Color(0.15, 0.35, 0.85, 0.55)
	es_overlay.position = Vector2(bx, sy)
	es_overlay.size = Vector2(0, 24)
	add_child(es_overlay)

	# ES parlak border (üst kısımda ince çizgi)
	var es_glow := ColorRect.new()
	es_glow.name = "ESGlow"
	es_glow.color = Color(0.3, 0.6, 1.0, 0.4)
	es_glow.position = Vector2(bx, sy)
	es_glow.size = Vector2(0, 2)
	add_child(es_glow)

	# HP ikonu (kalp)
	var hp_icon := Label.new()
	hp_icon.text = "♥"
	hp_icon.position = Vector2(bx + 4, sy)
	hp_icon.size = Vector2(18, 24)
	hp_icon.add_theme_color_override("font_color", Color(1, 0.2, 0.2, 0.7))
	hp_icon.add_theme_font_size_override("font_size", 12)
	hp_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(hp_icon)

	# ES ikonu (kalkan) — ES varsa gösterilir
	es_label = Label.new()
	es_label.position = Vector2(bx + 22, sy + 2)
	es_label.size = Vector2(100, 20)
	es_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 0.8))
	es_label.add_theme_font_size_override("font_size", 9)
	es_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	es_label.text = ""
	add_child(es_label)

	# HP/ES değer yazısı (ortada)
	health_label = Label.new()
	health_label.position = Vector2(bx, sy)
	health_label.size = Vector2(260, 24)
	health_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	health_label.add_theme_font_size_override("font_size", 10)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.text = ""
	add_child(health_label)

	# Mana bar çıkarıldı (mana sistemi kaldırıldı)

	# == BİYOM BİLDİRİMİ (ekranın üst kısmı, ortalanmış) ==
	_biome_label = Label.new()
	_biome_label.name = "BiomeLabel"
	_biome_label.position = Vector2(vp.x / 2 - 150, 80)
	_biome_label.size = Vector2(300, 36)
	_biome_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.6, 1.0))
	_biome_label.add_theme_font_size_override("font_size", 22)
	_biome_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_biome_label.add_theme_constant_override("shadow_outline_size", 2)
	_biome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_biome_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_biome_label.modulate = Color(1, 1, 1, 0)
	_biome_label.text = ""
	add_child(_biome_label)
	
	# == DÜŞÜK CAN VIGNETTE (ekran kenarlarında koyulaşma) ==
	_vignette = ColorRect.new()
	_vignette.name = "Vignette"
	_vignette.color = Color(0.3, 0.0, 0.0, 0.0)
	_vignette.anchor_right = 1.0
	_vignette.anchor_bottom = 1.0
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.show_behind_parent = true
	add_child(_vignette)
	
	# == BOSS CAN ÇUBUĞU (ekranın üst-orta kısmı) - İYİLEŞTİRİLMİŞ ==
	# Dış çerçeve
	var boss_frame := StyleBoxFlat.new()
	boss_frame.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	boss_frame.border_width_left = 3; boss_frame.border_width_right = 3
	boss_frame.border_width_top = 3; boss_frame.border_width_bottom = 3
	boss_frame.border_color = Color(0.6, 0.15, 0.1, 1.0)
	boss_frame.set_corner_radius_all(8)
	boss_frame.shadow_color = Color(0.8, 0.2, 0.1, 0.5)
	boss_frame.shadow_size = 8
	boss_frame.shadow_offset = Vector2(0, 4)

	_boss_bar = Panel.new()
	_boss_bar.name = "BossBar"
	_boss_bar.position = Vector2(vp.x / 2 - 250, 50)
	_boss_bar.size = Vector2(500, 36)
	_boss_bar.visible = false
	_boss_bar.add_theme_stylebox_override("panel", boss_frame)
	add_child(_boss_bar)

	_boss_fill = ColorRect.new()
	_boss_fill.color = Color(0.85, 0.15, 0.1, 1.0)
	_boss_fill.position = Vector2(4, 4)
	_boss_fill.size = Vector2(492, 28)
	_boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.add_child(_boss_fill)

	# HP bar ışıltı efekti
	var boss_glow := ColorRect.new()
	boss_glow.color = Color(1.0, 0.4, 0.3, 0.2)
	boss_glow.position = Vector2(4, 4)
	boss_glow.size = Vector2(492, 4)
	boss_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.add_child(boss_glow)

	_boss_name = Label.new()
	_boss_name.position = Vector2(0, -22)
	_boss_name.size = Vector2(500, 20)
	_boss_name.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 1.0))
	_boss_name.add_theme_font_size_override("font_size", 16)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_name.text = ""
	_boss_bar.add_child(_boss_name)

	_boss_hp_label = Label.new()
	_boss_hp_label.position = Vector2(0, 6)
	_boss_hp_label.size = Vector2(500, 24)
	_boss_hp_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9, 1.0))
	_boss_hp_label.add_theme_font_size_override("font_size", 12)
	_boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_boss_hp_label.text = ""
	_boss_bar.add_child(_boss_hp_label)

	# == XP BAR (en altta, tam genişlik, ince) ==
	var xp_y := vp.y - 10
	xp_bg = ColorRect.new()
	xp_bg.color = Color(0.08, 0.06, 0.1, 0.9)
	xp_bg.position = Vector2(0, xp_y)
	xp_bg.size = Vector2(vp.x, 10)
	add_child(xp_bg)

	# Üst border (belirgin)
	var xp_border := ColorRect.new()
	xp_border.color = Color(0.6, 0.5, 0.35, 0.6)
	xp_border.position = Vector2(0, xp_y)
	xp_border.size = Vector2(vp.x, 1)
	add_child(xp_border)

	xp_fill = ColorRect.new()
	xp_fill.color = Color(0.8, 0.55, 0.1)
	xp_fill.position = Vector2(0, xp_y)
	xp_fill.size = Vector2(0, 10)
	add_child(xp_fill)

	# XP fill ışıltı efekti (üst kısımda parlak çizgi)
	var xp_shine := ColorRect.new()
	xp_shine.name = "XPShine"
	xp_shine.color = Color(0.95, 0.75, 0.3, 0.3)
	xp_shine.position = Vector2(0, xp_y)
	xp_shine.size = Vector2(0, 3)
	add_child(xp_shine)

	# XP bar sol ve sağ kenarlar
	var xp_edge_l := ColorRect.new()
	xp_edge_l.color = Color(0.6, 0.5, 0.35, 0.5)
	xp_edge_l.position = Vector2(0, xp_y)
	xp_edge_l.size = Vector2(1, 10)
	add_child(xp_edge_l)

	var xp_edge_r := ColorRect.new()
	xp_edge_r.color = Color(0.6, 0.5, 0.35, 0.5)
	xp_edge_r.position = Vector2(vp.x - 1, xp_y)
	xp_edge_r.size = Vector2(1, 10)
	add_child(xp_edge_r)

	xp_label = Label.new()
	xp_label.position = Vector2(0, xp_y)
	xp_label.size = Vector2(vp.x, 10)
	xp_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 0.8))
	xp_label.add_theme_font_size_override("font_size", 8)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_label.text = ""
	add_child(xp_label)
	
	# == VS SÜRE KRONOMETRESİ (ust orta) ==
	_timer_label = Label.new()
	_timer_label.name = "VSTimerLabel"
	_timer_label.position = Vector2(vp.x / 2 - 100, 4)
	_timer_label.size = Vector2(200, 30)
	_timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	_timer_label.add_theme_font_size_override("font_size", 20)
	_timer_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_timer_label.add_theme_constant_override("shadow_outline_size", 2)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.text = "0:00"
	add_child(_timer_label)
	
	# == VS KILL COUNTER (sag ust kose) ==
	_vs_kill_label = Label.new()
	_vs_kill_label.name = "VSKillLabel"
	_vs_kill_label.position = Vector2(vp.x - 200, 30)
	_vs_kill_label.size = Vector2(190, 24)
	_vs_kill_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 0.9))
	_vs_kill_label.add_theme_font_size_override("font_size", 14)
	_vs_kill_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_vs_kill_label.add_theme_constant_override("shadow_outline_size", 2)
	_vs_kill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_vs_kill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_vs_kill_label.text = "Öldürülen: 0"
	add_child(_vs_kill_label)
	
	# Wave label
	_wave_label = Label.new()
	_wave_label.name = "WaveLabel"
	_wave_label.position = Vector2(vp.x - 200, 60)
	_wave_label.size = Vector2(150, 24)
	_wave_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	_wave_label.add_theme_font_size_override("font_size", 18)
	_wave_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_wave_label.add_theme_constant_override("shadow_outline_size", 2)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wave_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_label.text = "Wave: 1"
	add_child(_wave_label)

	# Difficulty tier label (wave'ın altında)
	_tier_label = Label.new()
	_tier_label.name = "TierLabel"
	_tier_label.position = Vector2(vp.x - 200, 85)
	_tier_label.size = Vector2(150, 22)
	_tier_label.add_theme_font_size_override("font_size", 14)
	_tier_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_tier_label.add_theme_constant_override("shadow_outline_size", 2)
	_tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tier_label.text = "☆ TIER 1"
	_tier_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
	add_child(_tier_label)
	
	# Status Effects UI (top-left)
	_build_status_effects_ui()
	_build_status_tooltip()

# ═══════════════════════════════════════
# STATUS EFFECTS UI (top-left ailments)
# ═══════════════════════════════════════

func _build_status_effects_ui() -> void:
	# Ana konteyner: sol ust kose, horizontal flow of icon squares
	_status_container = HBoxContainer.new()
	_status_container.name = "StatusEffects"
	_status_container.position = Vector2(10, 10)
	_status_container.size = Vector2(400, 0)  # width flexible, height auto
	_status_container.add_theme_constant_override("separation", 3)
	_status_container.mouse_filter = Control.MOUSE_FILTER_STOP  # catch mouse for tooltip
	add_child(_status_container)

func _build_status_tooltip() -> void:
	_status_tooltip_panel = Panel.new()
	_status_tooltip_panel.visible = false
	_status_tooltip_panel.position = Vector2(220, 10)
	_status_tooltip_panel.size = Vector2(220, 60)
	_status_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_tooltip_panel.z_index = 200
	var tt_style := StyleBoxFlat.new()
	tt_style.bg_color = Color(0.03, 0.03, 0.05, 0.95)
	tt_style.border_color = Color(0.4, 0.3, 0.5, 0.6)
	tt_style.border_width_left = 1
	tt_style.border_width_right = 1
	tt_style.border_width_top = 1
	tt_style.border_width_bottom = 1
	tt_style.set_corner_radius_all(6)
	_status_tooltip_panel.add_theme_stylebox_override("panel", tt_style)
	add_child(_status_tooltip_panel)
	
	_status_tooltip_label = RichTextLabel.new()
	_status_tooltip_label.name = "StatusTooltipContent"
	_status_tooltip_label.position = Vector2(6, 6)
	_status_tooltip_label.size = Vector2(208, 48)
	_status_tooltip_label.bbcode_enabled = true
	_status_tooltip_label.fit_content = true
	_status_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_tooltip_label.add_theme_color_override("default_color", Color(0.8, 0.8, 0.85))
	_status_tooltip_label.add_theme_font_size_override("normal_font_size", 10)
	_status_tooltip_panel.add_child(_status_tooltip_label)

func _refresh_status_effects(_unused = null) -> void:
	if not _status_container or not is_instance_valid(_status_container):
		return
	# Temizle
	for c in _status_container.get_children():
		_status_container.remove_child(c)
		c.queue_free()
	_effect_rows.clear()
	_hovered_effect_row = -1
	_status_tooltip_panel.visible = false
	
	if not _ailment_ctrl or not is_instance_valid(_ailment_ctrl):
		return
	
	var effects: Array[StatusEffect] = _ailment_ctrl.active_effects
	if effects.is_empty():
		return
	
	var idx: int = 0
	for eff in effects:
		# Her effect = kare icon + altinda kronometre
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		cell.add_theme_constant_override("separation", 1)
		cell.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# ── Icon kutusu (28x28) ──
		var icon_panel := Panel.new()
		icon_panel.custom_minimum_size = Vector2(28, 28)
		icon_panel.size = Vector2(28, 28)
		icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Kutunun stilli: koyu zemin + renkli cerceve
		var pstyle := StyleBoxFlat.new()
		pstyle.bg_color = Color(0.05, 0.03, 0.07, 0.92)
		var border_col: Color = _get_status_color(eff.effect_type)
		pstyle.border_color = border_col
		pstyle.border_width_left = 2
		pstyle.border_width_right = 2
		pstyle.border_width_top = 2
		pstyle.border_width_bottom = 2
		icon_panel.add_theme_stylebox_override("panel", pstyle)
		
		# Icon resmi
		var icon_path: String = STATUS_ICONS.get(eff.effect_type, "res://assets/generated/status_debuff.png")
		var icon_tex: Texture2D = null
		if ResourceLoader.exists(icon_path):
			icon_tex = load(icon_path) as Texture2D
		var icon_rect := TextureRect.new()
		icon_rect.texture = icon_tex
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP
		icon_rect.position = Vector2(6, 6)  # 16x16'i 28x28 icinde ortala
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.size = Vector2(16, 16)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_panel.add_child(icon_rect)
		cell.add_child(icon_panel)
		
		# ── Sure bilgisi (kucuk yazi) ──
		var timer_lbl := Label.new()
		timer_lbl.name = "TimerLabel"
		timer_lbl.text = "%.1fs" % maxf(eff.duration, 0.0)
		timer_lbl.add_theme_color_override("font_color", Color(0.65, 0.6, 0.75, 0.9))
		timer_lbl.add_theme_font_size_override("font_size", 8)
		timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(timer_lbl)
		
		# Metadata for tooltip
		cell.set_meta("effect_index", idx)
		cell.set_meta("effect_type", eff.effect_type)
		cell.set_meta("magnitude", eff.magnitude)
		
		# Hover baglantilari
		cell.mouse_entered.connect(_on_status_row_mouse_entered.bind(idx))
		cell.mouse_exited.connect(_on_status_row_mouse_exited)
		
		_status_container.add_child(cell)
		_effect_rows.append(cell)
		idx += 1

func _update_status_timers() -> void:
	if not _ailment_ctrl or not is_instance_valid(_ailment_ctrl):
		return
	if _effect_rows.is_empty():
		return
	var effects: Array[StatusEffect] = _ailment_ctrl.active_effects
	for i in range(min(_effect_rows.size(), effects.size())):
		var row: Control = _effect_rows[i]
		if not row or not is_instance_valid(row):
			continue
		var timer_lbl: Label = row.get_node_or_null("TimerLabel")
		if timer_lbl:
			timer_lbl.text = "%.1fs" % maxf(effects[i].duration, 0.0)

func _connect_ailment_signals() -> void:
	if not player or not is_instance_valid(player):
		return
	var ac: AilmentController = player.get_node_or_null("AilmentController")
	if not ac:
		return
	_ailment_ctrl = ac
	# Connect signals - _refresh_status_effects has optional arg so it handles both 0 and 1 args
	if not ac.effect_added.is_connected(_refresh_status_effects):
		ac.effect_added.connect(_refresh_status_effects)
	if not ac.effect_removed.is_connected(_refresh_status_effects):
		ac.effect_removed.connect(_refresh_status_effects)
	if not ac.all_effects_cleared.is_connected(_refresh_status_effects):
		ac.all_effects_cleared.connect(_refresh_status_effects)
	# Initial refresh
	_refresh_status_effects()

func _on_status_row_mouse_entered(idx: int) -> void:
	_hovered_effect_row = idx
	if not _ailment_ctrl or not is_instance_valid(_ailment_ctrl):
		return
	var effects: Array[StatusEffect] = _ailment_ctrl.active_effects
	if idx < 0 or idx >= effects.size():
		return
	var eff: StatusEffect = effects[idx]
	var info: Dictionary = STATUS_DISPLAY.get(eff.effect_type, {"name": "", "desc": ""})
	var eff_name: String = info.get("name", "Bilinmiyor")
	var desc: String = info.get("desc", "")
	# Format description with magnitude where applicable
	if eff.effect_type == StatusEffect.Type.SHOCK:
		desc = "Şok oldun! %.0f%% daha fazla hasar alırsın." % (eff.magnitude * 100)
	elif eff.effect_type == StatusEffect.Type.CHILL:
		desc = "Yavaşladın! Hareket ve saldırı hızın %.0f%% azalır." % (eff.magnitude * 100)
	
	var col: Color = _get_status_color(eff.effect_type)
	var col_hex: String = col.to_html()
	var bb_text: String = "[color=#%s][b]%s[/b][/color]\n" % [col_hex, eff_name]
	bb_text += "[color=#aaaaaa]%s[/color]" % desc
	
	_status_tooltip_label.text = bb_text
	_status_tooltip_label.size.y = 0  # Auto-size
	await get_tree().process_frame
	var th: float = _status_tooltip_label.get_content_height() + 12
	_status_tooltip_panel.size.y = maxf(th, 30)
	# Tooltip'i icon'un altina konumlandir
	# idx'den icon'un x pozisyonunu hesapla: 10 (container x) + idx * (28+3) (icon width + spacing)
	var icon_x: float = 10.0 + idx * 31.0
	_status_tooltip_panel.position = Vector2(icon_x, 44)  # 10 (container y) + 28 (icon height) + 6
	_status_tooltip_panel.visible = true

func _on_status_row_mouse_exited() -> void:
	_hovered_effect_row = -1
	_status_tooltip_panel.visible = false

func _get_status_color(etype: int) -> Color:
	match etype:
		StatusEffect.Type.IGNITE:
			return Color(1.0, 0.4, 0.2)      # ates-turuncu
		StatusEffect.Type.POISON:
			return Color(0.4, 1.0, 0.2)      # yesil
		StatusEffect.Type.SHOCK:
			return Color(1.0, 0.87, 0.2)     # sari
		StatusEffect.Type.CHILL, StatusEffect.Type.FREEZE:
			return Color(0.4, 0.8, 1.0)      # buz-mavi
		StatusEffect.Type.BLEED:
			return Color(1.0, 0.2, 0.2)      # kirmizi
		StatusEffect.Type.WITHER:
			return Color(0.67, 0.4, 1.0)     # mor
		StatusEffect.Type.BLIND:
			return Color(0.5, 0.5, 0.5)      # gri
		StatusEffect.Type.BUFF_ONSLAUGHT, StatusEffect.Type.BUFF_FORTIFY, StatusEffect.Type.BUFF_HASTE, StatusEffect.Type.CONSECRATED:
			return Color(1.0, 0.87, 0.4)     # altin
		_:
			return Color(0.8, 0.53, 1.0)     # lavanta

func _update_bar(fill: ColorRect, bg: ColorRect, current: float, max_val: float) -> void:
	if max_val <= 0.0 or not is_instance_valid(fill) or not is_instance_valid(bg):
		return
	var w: float = clampf(current / max_val, 0.0, 1.0) * bg.size.x
	fill.size.x = w

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return
		_connected = false
	if not _connected:
		player.health.health_changed.connect(_on_health_changed)
		player.health.es_changed.connect(_on_es_changed)
		# Mana sistemi kaldırıldı
		player.level_system.xp_changed.connect(_on_xp_changed)
		player.level_system.leveled_up.connect(_on_leveled_up)
		_connected = true
		_drain_current = 1.0
		_drain_target = 1.0
		_on_health_changed(player.health.current_health, player.health.max_health)
		_on_es_changed(player.health.current_es, player.health.max_es)
		_on_xp_changed(player.level_system.current_xp, player.level_system.get_xp_required())
		level_label.text = "Seviye %d" % player.level_system.level
		# Connect status effect signals
		_connect_ailment_signals()
	
	# Update status effect timers every frame
	if _status_container and _status_container.visible and not _effect_rows.is_empty():
		_update_status_timers()
	
	# Boss can çubuğu
	_update_boss_bar()
	
	# Health drain animation: drain bar yavaşça hedefe yaklaşır
	if _drain_current > _drain_target and is_instance_valid(health_drain) and is_instance_valid(health_bg):
		_drain_current = maxf(_drain_current - delta * 1.2, _drain_target)
		var w: float = _drain_current * health_bg.size.x
		health_drain.size.x = w

func _update_boss_bar() -> void:
	"""Boss node'u tespit et ve can çubuğunu güncelle."""
	var boss_group := get_tree().get_nodes_in_group("boss")
	var found_boss: Node = null
	for b in boss_group:
		if is_instance_valid(b) and b.has_node("Health"):
			found_boss = b
			break
	
	if found_boss:
		# Boss ölü mü kontrol et (life regen son anda can yenilese bile)
		var bh: Health = found_boss.get_node("Health")
		if bh.current_health <= 0.0:
			_boss_node = null
			_boss_bar.visible = false
			return
		if _boss_node != found_boss:
			_boss_node = found_boss
			# Boss adını al
			var bname: String = ""
			if "_enemy_name" in found_boss:
				bname = found_boss._enemy_name
			elif found_boss.has_node("NameLabel"):
				bname = found_boss.get_node("NameLabel").text
			if bname.is_empty():
				bname = "BOSS"
			_boss_name.text = bname
			_boss_bar.visible = true
		
		# Can değerlerini güncelle
		var hp_ratio: float = bh.current_health / bh.max_health if bh.max_health > 0 else 0.0
		_boss_fill.size.x = 396 * clamp(hp_ratio, 0.0, 1.0)
		# Rengi can oranına göre değiştir
		if hp_ratio > 0.6:
			_boss_fill.color = Color(0.7, 0.3, 0.2, 1.0)
		elif hp_ratio > 0.3:
			_boss_fill.color = Color(0.85, 0.6, 0.15, 1.0)
		else:
			_boss_fill.color = Color(0.9, 0.15, 0.1, 1.0)
		_boss_hp_label.text = "%d / %d" % [bh.current_health, bh.max_health]
	else:
		if _boss_node:
			_boss_node = null
			_boss_bar.visible = false
			_boss_fill.size.x = 396

func _on_health_changed(current: float, max_h: float) -> void:
	if not is_instance_valid(health_fill): return
	_update_bar(health_fill, health_bg, current, max_h)
	# Damage flash: can azalinca kisa kirmizi flash
	var old_ratio: float = _drain_current  # onceki bilinen oran
	if current / max_h < old_ratio:
		_do_damage_flash()
	# Drain target: can azaldiysa drain yavasça arkasindan gelsin
	var ratio: float = clampf(current / max_h, 0.0, 1.0)
	if ratio < _drain_target:
		_drain_target = ratio
	# Vignette: can azaldikca ekran kenarlari koyulasir
	if is_instance_valid(_vignette):
		var vig_alpha: float = clampf(1.0 - ratio / 0.35, 0.0, 1.0)  # %35 altinda gorunmeye baslar
		_vignette.color = Color(0.3, 0.0, 0.0, vig_alpha * 0.5)
	# HP/ES birleşik değer: "HP / MaxHP  [ES]"
	var es_str: String = ""
	if player and player.health.max_es > 0:
		es_str = "  [" + str(player.health.current_es) + "]"
	health_label.text = "%d / %d%s" % [current, max_h, es_str]

func _on_es_changed(current: float, max_e: float) -> void:
	if not is_instance_valid(es_overlay): return
	# ES, HP barının üstüne overlay olarak çizilir
	_update_bar(es_overlay, health_bg, current, max_e)
	# ES glow çizgisi
	var glow := get_node_or_null("ESGlow") as ColorRect
	if glow:
		if max_e > 0 and current > 0:
			_update_bar(glow, health_bg, current, max_e)
			glow.visible = true
		else:
			glow.visible = false
	# ES label
	if max_e > 0:
		es_label.text = "🛡 %d" % current
	else:
		es_label.text = ""
	# HP yazısını da güncelle (ES değerini göstersin)
	if player:
		_on_health_changed(player.health.current_health, player.health.max_health)

func _on_mana_changed(_current: float, _max_m: float, _reserved: float = 0.0) -> void:
	pass

func _reposition_ui() -> void:
	# Viewport boyutu değişince HUD'u yeniden konumlandır
	var vp := get_viewport().get_visible_rect().size
	var bx := 16
	var by := 50  # Sol ust kose
	
	# Arkaplan panel (2. child = bg yer tutucu, 1. child = kenar)
	for c in get_children():
		if c is ColorRect:
			if c.size.x > 250 and c.size.y > 50:  # bg panel
				c.position = Vector2(bx - 8, by - 4)
			elif c.size.y == 1:  # border line
				c.position = Vector2(bx - 8, by - 5)
	
	if level_label and is_instance_valid(level_label):
		level_label.position = Vector2(bx, by - 2)
	
	var sy := by + 14
	if health_bg and is_instance_valid(health_bg):
		health_bg.position.y = sy
		health_bg.size.x = 260
	# Mana bar kaldırıldı (mana sistemi yok)
	
	# XP barı tam genişlik, en altta
	if xp_bg and is_instance_valid(xp_bg):
		xp_bg.position = Vector2(0, vp.y - 10)
		xp_bg.size = Vector2(vp.x, 10)
	if xp_fill and is_instance_valid(xp_fill):
		xp_fill.position.y = vp.y - 10
	if xp_label and is_instance_valid(xp_label):
		xp_label.position = Vector2(0, vp.y - 12)
		xp_label.size = Vector2(vp.x, 12)

func _do_damage_flash() -> void:
	"""Can azalinca HP barinda kisa kirmizi flash."""
	if not is_instance_valid(health_fill):
		return
	var flash_rect := ColorRect.new()
	flash_rect.color = Color(1.0, 0.15, 0.15, 0.5)
	flash_rect.position = health_fill.position
	flash_rect.size = health_fill.size
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_rect)
	var tw := create_tween()
	tw.tween_property(flash_rect, "modulate", Color(1, 0.15, 0.15, 0.0), 0.2)
	tw.tween_callback(flash_rect.queue_free).set_delay(0.25)

func _on_xp_changed(current: float, required: float) -> void:
	if not is_instance_valid(xp_fill) or not is_instance_valid(xp_bg): return
	_update_bar(xp_fill, xp_bg, current, required)
	# XP shine'ı da güncelle
	var shine := get_node_or_null("XPShine") as ColorRect
	if shine:
		_update_bar(shine, xp_bg, current, required)
	# XP pulse efekti — kısa süreli parlaklık
	if is_instance_valid(xp_fill):
		var orig_color := xp_fill.color
		xp_fill.color = Color(0.95, 0.75, 0.3)
		var tw := create_tween()
		tw.tween_property(xp_fill, "color", orig_color, 0.3)
	if xp_label:
		xp_label.text = "XP: %d / %d" % [current, required]

func _on_leveled_up(new_level: int) -> void:
	level_label.text = "Seviye %d" % new_level

## Yeni biyoma girildiğinde ekranın üstünde kısa bir bildirim göster
func show_biome_notification(biome_name: String) -> void:
	if not _biome_label or not is_instance_valid(_biome_label):
		return
	_biome_label.text = "📍 %s" % biome_name
	_biome_label.modulate = Color(1, 1, 1, 1)
	
	# 5 saniye bekle, 2 saniyede fade out
	var tween := create_tween()
	tween.tween_property(_biome_label, "modulate", Color(1, 1, 1, 0), 2.0).set_delay(5.0)

func show_damage_flash() -> void:
	"""Oyuncu hasar aldığında kırmızı ekran efekti göster"""
	if not is_instance_valid(_damage_flash):
		return
	_damage_flash.modulate.a = 0.4
	# Hızlı fade out
	var tw := create_tween()
	tw.tween_property(_damage_flash, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_OUT)

func _on_damage_dealt(payload: Dictionary) -> void:
	# Oyuncunun kendine gelen hasarı yakala
	var target: Node = payload.get("target", null)
	if target and target.is_in_group("player"):
		show_damage_flash()
