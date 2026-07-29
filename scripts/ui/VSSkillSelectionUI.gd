extends CanvasLayer
class_name VSSkillSelectionUI## Kart tabanli skill secim ekrani.i.
## Level atlayinca 3 kart gosterir, 1 tane secilir.
## Skill evolution: sahip olunan skill'leri upgrade etme secenegi de sunar.

signal skill_selected(skill_path: String)

var _skill_options: Array[String] = []
var _skill_levels: Dictionary = {}  # skill_path -> level (disaridan gonderilir)
var _cards: Array[Panel] = []

const ALL_SKILLS: Array[String] = [
	"res://data/skills/fire_bolt.tres",
	"res://data/skills/ice_shard.tres",
	"res://data/skills/lightning_chain.tres",
	"res://data/skills/arcane_orb.tres",
	"res://data/skills/toxic_circle.tres",
	"res://data/skills/whirlwind.tres",
	"res://data/skills/dark_beam.tres",
	"res://data/skills/holy_nova.tres",
	"res://data/skills/thunder_strike.tres",
	"res://data/skills/frost_explosion.tres",
	"res://data/skills/fireball.tres",
	"res://data/skills/ice_nova.tres",
	"res://data/skills/slice_wave.tres",
]

const DAMAGE_COLORS: Dictionary = {
	"fire": Color(1.0, 0.4, 0.1),
	"cold": Color(0.3, 0.6, 1.0),
	"lightning": Color(1.0, 0.9, 0.2),
	"physical": Color(0.7, 0.5, 0.3),
	"chaos": Color(0.6, 0.2, 0.8),
}

func show_selection(player_skills: Array[String], skill_levels: Dictionary = {}) -> void:
	_skill_levels = skill_levels

	# Karistir: yeni skill'ler (alinmamis) + sahip olunan skill'ler (upgrade icin)
	var available_new: Array[String] = []
	for s in ALL_SKILLS:
		if s not in player_skills:
			available_new.append(s)

	var owned: Array[String] = player_skills.duplicate()
	owned.shuffle()
	available_new.shuffle()

	# 3 secenek olustur: en az 1 yeni skill, kalanlar karisik
	_skill_options = []

	# Bir tane yeni skill ekle (varsa)
	if not available_new.is_empty():
		_skill_options.append(available_new[0])
		available_new.remove_at(0)

	# Kalan slotlari doldur: once yeni skill'ler, sonra owned
	var pool: Array[String] = []
	pool.append_array(available_new)
	pool.append_array(owned)

	while _skill_options.size() < 3 and not pool.is_empty():
		var pick: String = pool[0]
		pool.remove_at(0)
		if pick not in _skill_options:
			_skill_options.append(pick)

	# Hala 3'ten azsa, owned'den ekle
	if _skill_options.size() < 3 and not owned.is_empty():
		for s in owned:
			if s not in _skill_options:
				_skill_options.append(s)
				if _skill_options.size() >= 3:
					break

	# Hala 3 yoksa, ALL_SKILLS'den doldur (tekrar secilebilir)
	while _skill_options.size() < 3:
		var fallback: String = ALL_SKILLS[randi() % ALL_SKILLS.size()]
		if fallback not in _skill_options:
			_skill_options.append(fallback)

	_skill_options = _skill_options.slice(0, 3)
	_build_ui()

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size

	var bg := ColorRect.new()
	bg.name = "SelectionBG"
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var title := Label.new()
	title.text = "YENİ YETENEK SEÇ!"
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.12)
	title.size = Vector2(vp.x, 50)
	add_child(title)

	var sub := Label.new()
	sub.text = "Geliştirmek istediğin yeteneği seç"
	sub.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6, 0.8))
	sub.add_theme_font_size_override("font_size", 14)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, vp.y * 0.12 + 45)
	sub.size = Vector2(vp.x, 25)
	add_child(sub)

	var card_w: float = 280.0
	var card_h: float = 380.0
	var gap: float = 30.0
	var total_w: float = _skill_options.size() * card_w + (_skill_options.size() - 1) * gap
	var start_x: float = (vp.x - total_w) / 2.0
	var card_y: float = vp.y * 0.23

	for i in range(_skill_options.size()):
		var skill_path: String = _skill_options[i]
		var skill_data: SkillData = load(skill_path) if ResourceLoader.exists(skill_path) else null
		if not skill_data:
			continue

		var is_upgrade: bool = _skill_levels.has(skill_path)
		var current_level: int = _skill_levels.get(skill_path, 1)
		var next_level: int = current_level + 1

		var card := Panel.new()
		card.name = "SkillCard_%d" % i
		card.position = Vector2(start_x + i * (card_w + gap), card_y)
		card.size = Vector2(card_w, card_h)
		card.mouse_filter = Control.MOUSE_FILTER_STOP

		var dmg_color: Color = DAMAGE_COLORS.get(skill_data.damage_type, Color(0.6, 0.5, 0.4))

		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
		card_style.border_width_left = 3
		card_style.border_width_right = 3
		card_style.border_width_top = 3
		card_style.border_width_bottom = 3
		card_style.border_color = dmg_color
		card_style.set_corner_radius_all(12)
		card_style.shadow_color = Color(0, 0, 0, 0.5)
		card_style.shadow_size = 8
		card_style.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("panel", card_style)

		# Upgrade/Yeni badge
		var badge := Label.new()
		if is_upgrade:
			badge.text = "⬆ YÜKSELTME Seviye %d" % current_level
			badge.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 0.9))
		else:
			badge.text = "✦ YENİ"
			badge.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 0.9))
		badge.add_theme_font_size_override("font_size", 11)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.position = Vector2(0, 8)
		badge.size = Vector2(card_w, 16)
		card.add_child(badge)

		var icon_rect := TextureRect.new()
		icon_rect.name = "SkillIcon"
		icon_rect.position = Vector2((card_w - 80) / 2.0, 26)
		icon_rect.size = Vector2(80, 80)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if skill_data.icon_path and ResourceLoader.exists(skill_data.icon_path):
			icon_rect.texture = load(skill_data.icon_path)
		elif skill_data.icon:
			icon_rect.texture = skill_data.icon
		else:
			icon_rect.modulate = dmg_color
		card.add_child(icon_rect)

		var name_lbl := Label.new()
		name_lbl.text = skill_data.display_name
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.add_theme_constant_override("shadow_outline_size", 1)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.position = Vector2(0, 112)
		name_lbl.size = Vector2(card_w, 28)
		card.add_child(name_lbl)

		var type_names: Array[String] = ["Mermi", "Alan", "Yakın", "Güçlendirme", "Aura", "Lanet", "Hareket", "Tetik"]
		var type_badge := Label.new()
		type_badge.text = type_names[skill_data.skill_type] if skill_data.skill_type < type_names.size() else "?"
		type_badge.add_theme_color_override("font_color", dmg_color)
		type_badge.add_theme_font_size_override("font_size", 11)
		type_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		type_badge.position = Vector2(0, 140)
		type_badge.size = Vector2(card_w, 18)
		card.add_child(type_badge)

		var line := ColorRect.new()
		line.color = Color(dmg_color.r, dmg_color.g, dmg_color.b, 0.3)
		line.position = Vector2(15, 162)
		line.size = Vector2(card_w - 30, 1)
		card.add_child(line)

		var dmg_str: String = ""
		if skill_data.damage_buckets and not skill_data.damage_buckets.is_empty():
			var parts: PackedStringArray = []
			for d_type in skill_data.damage_buckets:
				var val: float = skill_data.damage_buckets[d_type]
				parts.append("%.0f %s" % [val, d_type.capitalize()])
			dmg_str = " / ".join(parts)
		else:
			dmg_str = "%.0f" % skill_data.base_damage

		var dmg_lbl := Label.new()
		if is_upgrade:
			var cur_dmg_mult: float = 1.0 + (current_level - 1) * 0.25
			var next_dmg_mult: float = 1.0 + (next_level - 1) * 0.25
			dmg_lbl.text = "⚔ Hasar: %.1f → %.1f" % [cur_dmg_mult, next_dmg_mult]
		else:
			dmg_lbl.text = "⚔ Hasar: %s" % dmg_str
		dmg_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.7, 0.9))
		dmg_lbl.add_theme_font_size_override("font_size", 13)
		dmg_lbl.position = Vector2(15, 172)
		dmg_lbl.size = Vector2(card_w - 30, 22)
		card.add_child(dmg_lbl)

		var cd_str: String = "%.1fs" % skill_data.cooldown if skill_data.cooldown > 0 else "Anlık"
		var cd_lbl := Label.new()
		cd_lbl.text = "⏱ Bekleme: %s" % cd_str
		cd_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9, 0.9))
		cd_lbl.add_theme_font_size_override("font_size", 13)
		cd_lbl.position = Vector2(15, 196)
		cd_lbl.size = Vector2(card_w - 30, 22)
		card.add_child(cd_lbl)

		if is_upgrade:
			var lvl_lbl := Label.new()
			lvl_lbl.text = "⬆ Seviye %d → %d (+%%25 hasar)" % [current_level, next_level]
			lvl_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 0.8))
			lvl_lbl.add_theme_font_size_override("font_size", 12)
			lvl_lbl.position = Vector2(15, 220)
			lvl_lbl.size = Vector2(card_w - 30, 22)
			card.add_child(lvl_lbl)

		var line2 := ColorRect.new()
		line2.color = Color(dmg_color.r, dmg_color.g, dmg_color.b, 0.2)
		line2.position = Vector2(15, 250)
		line2.size = Vector2(card_w - 30, 1)
		card.add_child(line2)

		var tags_lbl := Label.new()
		var tag_str: String = ""
		for t in skill_data.tags:
			if tag_str.length() > 0:
				tag_str += " • "
			tag_str += str(t)
		tags_lbl.text = tag_str
		tags_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6, 0.7))
		tags_lbl.add_theme_font_size_override("font_size", 10)
		tags_lbl.position = Vector2(15, 260)
		tags_lbl.size = Vector2(card_w - 30, 20)
		card.add_child(tags_lbl)

		# Ekstra skill bilgileri: chain, AoE, projectile count
		var extra_info_lbl := Label.new()
		var extra_parts: Array[String] = []

		# Chain count (Lightning Chain vb.)
		if ("chain_count" in skill_data and skill_data.chain_count > 0):
			var chains: int = skill_data.chain_count
			extra_parts.append("⚡ %d Zincir" % chains)

		# AoE radius (area skills)
		if ("area_radius" in skill_data and skill_data.area_radius > 0.0):
			var radius: float = skill_data.area_radius
			extra_parts.append("💥 %.0fpx AoE" % radius)

		# Projectile count
		if ("projectile_count" in skill_data and skill_data.projectile_count > 0):
			var proj_count: int = skill_data.projectile_count
			extra_parts.append("🏹 %d Mermi" % proj_count)

		# Pierce count
		if ("pierce_count" in skill_data and skill_data.pierce_count > 0):
			var pierce: int = skill_data.pierce_count
			extra_parts.append("🗡️ %d Delme" % pierce)

		# DPS hesabı (tahmini)
		var base_dmg: float = skill_data.base_damage
		if skill_data.damage_buckets and not skill_data.damage_buckets.is_empty():
			base_dmg = 0.0
			for d_type in skill_data.damage_buckets:
				base_dmg += skill_data.damage_buckets[d_type]
		var cd: float = skill_data.cooldown if skill_data.cooldown > 0 else 1.0
		var dps: float = base_dmg / cd
		extra_parts.append("📊 ~%.0f DPS" % dps)

		if not extra_parts.is_empty():
			extra_info_lbl.text = " • ".join(extra_parts)
			extra_info_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.9))
			extra_info_lbl.add_theme_font_size_override("font_size", 11)
			extra_info_lbl.position = Vector2(15, 278)
			extra_info_lbl.size = Vector2(card_w - 30, 18)
			card.add_child(extra_info_lbl)

		var line3 := ColorRect.new()
		line3.color = Color(dmg_color.r, dmg_color.g, dmg_color.b, 0.2)
		line3.position = Vector2(15, 300)
		line3.size = Vector2(card_w - 30, 1)
		card.add_child(line3)

		var desc_lbl := Label.new()
		var desc_map: Dictionary = {
			"fire_bolt": "Ateşten bir ok fırlatır",
			"ice_shard": "Buz mızrakları fırlatır",
			"lightning_chain": "Yıldırım zinciri çarpar",
			"arcane_orb": "Gizemli bir küre gönderir",
			"toxic_circle": "Zehirli bir alan oluşturur",
			"whirlwind": "Etrafındaki herkesi keser",
			"dark_beam": "Karanlık bir ışın gönderir",
			"holy_nova": "Kutsal bir patlama yaratır",
			"thunder_strike": "Gök gürültüsü indirir",
			"frost_explosion": "Buz patlaması yaratır",
			"fireball": "Ateş topu fırlatır",
			"ice_nova": "Buz halkası yayar",
			"slice_wave": "Keskin bir dalga gönderir",
		}
		desc_lbl.text = desc_map.get(skill_data.id, "Güçlü bir yetenek")
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7, 0.85))
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.position = Vector2(15, 295)
		desc_lbl.size = Vector2(card_w - 30, 40)
		card.add_child(desc_lbl)

		var select_btn := Button.new()
		select_btn.name = "Btn_%d" % i
		if is_upgrade:
			select_btn.text = "YÜKSELT  [%d]" % (i + 1)
		else:
			select_btn.text = "SEÇ  [%d]" % (i + 1)
		select_btn.position = Vector2(30, card_h - 55)
		select_btn.size = Vector2(card_w - 60, 40)

		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(dmg_color.r, dmg_color.g, dmg_color.b, 0.25)
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = dmg_color
		btn_style.set_corner_radius_all(8)
		select_btn.add_theme_stylebox_override("normal", btn_style)

		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = Color(dmg_color.r, dmg_color.g, dmg_color.b, 0.4)
		btn_hover.border_width_left = 2
		btn_hover.border_width_right = 2
		btn_hover.border_width_top = 2
		btn_hover.border_width_bottom = 2
		btn_hover.border_color = Color(dmg_color.r + 0.3, dmg_color.g + 0.3, dmg_color.b + 0.3, 1.0)
		btn_hover.set_corner_radius_all(8)
		select_btn.add_theme_stylebox_override("hover", btn_hover)

		select_btn.add_theme_color_override("font_color", Color.WHITE)
		select_btn.add_theme_font_size_override("font_size", 15)
		select_btn.pressed.connect(_on_skill_chosen.bind(skill_path))
		card.add_child(select_btn)

		add_child(card)
		_cards.append(card)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				if _skill_options.size() >= 1:
					_on_skill_chosen(_skill_options[0])
			KEY_2:
				if _skill_options.size() >= 2:
					_on_skill_chosen(_skill_options[1])
			KEY_3:
				if _skill_options.size() >= 3:
					_on_skill_chosen(_skill_options[2])

func _on_skill_chosen(skill_path: String) -> void:
	skill_selected.emit(skill_path)
	queue_free()
