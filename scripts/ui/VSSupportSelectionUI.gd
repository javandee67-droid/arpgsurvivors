extends CanvasLayer
class_name VSSupportSelectionUI
## Her 5. levelde 3 support gem gosterir. Her support rastgele bir
## oyuncunun sahip oldugu skill'e baglanir.

signal support_selected(support_path: String, skill_path: String)

var _support_options: Array[Dictionary] = []  # [{support_path, skill_path, skill_name}]
var _cards: Array[Panel] = []

const ALL_SUPPORTS: Array[String] = [
	"res://data/supports/extra_projectile.tres",
	"res://data/supports/critical_strike.tres",
	"res://data/supports/wider_area.tres",
	"res://data/supports/faster_attacks.tres",
	"res://data/supports/added_fire_damage.tres",
	"res://data/supports/added_cold_damage.tres",
	"res://data/supports/added_lightning_damage.tres",
	"res://data/supports/added_chaos_damage.tres",
	"res://data/supports/concentrated_effect.tres",
	"res://data/supports/controlled_destruction.tres",
	"res://data/supports/elemental_focus.tres",
	"res://data/supports/elemental_penetration.tres",
	"res://data/supports/culling_strike.tres",
	"res://data/supports/chain_strike.tres",
	"res://data/supports/life_leech.tres",
	"res://data/supports/spell_empower.tres",
	"res://data/supports/volley.tres",
	"res://data/supports/brutal_damage.tres",
	"res://data/supports/cast_speed.tres",
	"res://data/supports/mana_efficiency.tres",
	"res://data/supports/melee_physical_damage.tres",
	"res://data/supports/greater_multi_projectile.tres",
]

const SUPPORT_COLORS: Dictionary = {
	"projectile": Color(0.3, 0.7, 1.0),
	"fire": Color(1.0, 0.4, 0.1),
	"cold": Color(0.3, 0.6, 1.0),
	"lightning": Color(1.0, 0.9, 0.2),
	"physical": Color(0.7, 0.5, 0.3),
	"chaos": Color(0.6, 0.2, 0.8),
	"spell": Color(0.6, 0.3, 1.0),
	"attack": Color(0.9, 0.5, 0.2),
	"aoe": Color(0.2, 0.8, 0.5),
	"": Color(0.6, 0.6, 0.7),
}

func show_selection(player_skills: Array[String]) -> void:
	_support_options.clear()
	
	if player_skills.is_empty():
		push_error("VS Support: Oyuncunun skill'i yok!")
		return
	
	# Karistir ve 3 support sec
	var shuffled: Array[String] = ALL_SUPPORTS.duplicate()
	shuffled.shuffle()
	
	var picked: int = 0
	for s_path in shuffled:
		if picked >= 3:
			break
		
		var support_data: SupportData = load(s_path) if ResourceLoader.exists(s_path) else null
		if not support_data:
			continue
		
		# Oyuncunun skill'lerinden biriyle uyumlu mu?
		var compatible_skills: Array[String] = []
		for ps in player_skills:
			var skill_data: SkillData = load(ps) if ResourceLoader.exists(ps) else null
			if not skill_data:
				continue
			if support_data.is_compatible(skill_data):
				compatible_skills.append(ps)
		
		# Uyumlu skill yoksa, normal_attack'e zorla bagla
		if compatible_skills.is_empty():
			compatible_skills = ["res://data/skills/normal_attack.tres"]
		
		# Rastgele bir uyumlu skill sec
		var chosen_skill: String = compatible_skills[randi() % compatible_skills.size()]
		var skill_data_ref: SkillData = load(chosen_skill) if ResourceLoader.exists(chosen_skill) else null
		var skill_name: String = skill_data_ref.display_name if skill_data_ref else "Bilinmeyen"
		
		_support_options.append({
			"support_path": s_path,
			"skill_path": chosen_skill,
			"skill_name": skill_name,
			"support_data": support_data,
		})
		picked += 1
	
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
	title.text = "DESTEK TAŞI SEÇ!"
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.1)
	title.size = Vector2(vp.x, 50)
	add_child(title)
	
	var sub := Label.new()
	sub.text = "Bir yeteneğini güçlendirecek destek taşını seç"
	sub.add_theme_color_override("font_color", Color(0.6, 0.8, 0.9, 0.8))
	sub.add_theme_font_size_override("font_size", 14)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, vp.y * 0.1 + 45)
	sub.size = Vector2(vp.x, 25)
	add_child(sub)
	
	var card_w: float = 300.0
	var card_h: float = 340.0
	var gap: float = 30.0
	var total_w: float = _support_options.size() * card_w + (_support_options.size() - 1) * gap
	var start_x: float = (vp.x - total_w) / 2.0
	var card_y: float = vp.y * 0.22
	
	for i in range(_support_options.size()):
		var opt := _support_options[i]
		var supp_data: SupportData = opt.support_data as SupportData
		if not supp_data:
			continue
		
		var card := Panel.new()
		card.name = "SupportCard_%d" % i
		card.position = Vector2(start_x + i * (card_w + gap), card_y)
		card.size = Vector2(card_w, card_h)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var primary_tag: String = supp_data.allowed_tags[0].to_lower() if supp_data.allowed_tags.size() > 0 else ""
		var s_color: Color = SUPPORT_COLORS.get(primary_tag, Color(0.5, 0.5, 0.6))
		
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.06, 0.06, 0.1, 0.95)
		card_style.border_width_left = 3
		card_style.border_width_right = 3
		card_style.border_width_top = 3
		card_style.border_width_bottom = 3
		card_style.border_color = s_color
		card_style.set_corner_radius_all(12)
		card_style.shadow_color = Color(0, 0, 0, 0.5)
		card_style.shadow_size = 8
		card_style.shadow_offset = Vector2(0, 4)
		card.add_theme_stylebox_override("panel", card_style)
		
		# Icon
		var icon_rect := TextureRect.new()
		icon_rect.name = "SupportIcon"
		icon_rect.position = Vector2((card_w - 72) / 2.0, 20)
		icon_rect.size = Vector2(72, 72)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if supp_data.icon_path and ResourceLoader.exists(supp_data.icon_path):
			icon_rect.texture = load(supp_data.icon_path)
		else:
			icon_rect.modulate = s_color
		card.add_child(icon_rect)
		
		# Support adi
		var name_lbl := Label.new()
		name_lbl.text = supp_data.display_name
		name_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		name_lbl.add_theme_font_size_override("font_size", 17)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.position = Vector2(0, 100)
		name_lbl.size = Vector2(card_w, 26)
		card.add_child(name_lbl)
		
		# Tag badge
		if primary_tag:
			var tag_lbl := Label.new()
			tag_lbl.text = primary_tag.capitalize()
			tag_lbl.add_theme_color_override("font_color", s_color)
			tag_lbl.add_theme_font_size_override("font_size", 11)
			tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tag_lbl.position = Vector2(0, 126)
			tag_lbl.size = Vector2(card_w, 18)
			card.add_child(tag_lbl)
		
		# Ayirici
		var line := ColorRect.new()
		line.color = Color(s_color.r, s_color.g, s_color.b, 0.3)
		line.position = Vector2(15, 150)
		line.size = Vector2(card_w - 30, 1)
		card.add_child(line)
		
		# Aciklama
		var desc_lbl := Label.new()
		desc_lbl.text = supp_data.gem_description
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.72, 0.9))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.position = Vector2(15, 160)
		desc_lbl.size = Vector2(card_w - 30, 60)
		card.add_child(desc_lbl)
		
		# Ayirici
		var line2 := ColorRect.new()
		line2.color = Color(s_color.r, s_color.g, s_color.b, 0.2)
		line2.position = Vector2(15, 225)
		line2.size = Vector2(card_w - 30, 1)
		card.add_child(line2)
		
		# Baglandigi skill
		var apply_lbl := Label.new()
		apply_lbl.text = "→ " + opt.skill_name
		apply_lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 0.4, 1.0))
		apply_lbl.add_theme_font_size_override("font_size", 15)
		apply_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		apply_lbl.position = Vector2(0, 235)
		apply_lbl.size = Vector2(card_w, 26)
		card.add_child(apply_lbl)
		
		var for_lbl := Label.new()
		for_lbl.text = "yeteneğine takılacak"
		for_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.4, 0.7))
		for_lbl.add_theme_font_size_override("font_size", 11)
		for_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		for_lbl.position = Vector2(0, 257)
		for_lbl.size = Vector2(card_w, 18)
		card.add_child(for_lbl)
		
		# Sec butonu
		var select_btn := Button.new()
		select_btn.name = "Btn_%d" % i
		select_btn.text = "TAK  [%d]" % (i + 1)
		select_btn.position = Vector2(35, card_h - 60)
		select_btn.size = Vector2(card_w - 70, 42)
		
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(s_color.r, s_color.g, s_color.b, 0.2)
		btn_style.border_width_left = 2
		btn_style.border_width_right = 2
		btn_style.border_width_top = 2
		btn_style.border_width_bottom = 2
		btn_style.border_color = s_color
		btn_style.set_corner_radius_all(8)
		select_btn.add_theme_stylebox_override("normal", btn_style)
		
		var btn_hover := StyleBoxFlat.new()
		btn_hover.bg_color = Color(s_color.r, s_color.g, s_color.b, 0.35)
		btn_hover.border_width_left = 2
		btn_hover.border_width_right = 2
		btn_hover.border_width_top = 2
		btn_hover.border_width_bottom = 2
		btn_hover.border_color = Color(s_color.r + 0.3, s_color.g + 0.3, s_color.b + 0.3, 1.0)
		btn_hover.set_corner_radius_all(8)
		select_btn.add_theme_stylebox_override("hover", btn_hover)
		
		select_btn.add_theme_color_override("font_color", Color.WHITE)
		select_btn.add_theme_font_size_override("font_size", 14)
		select_btn.pressed.connect(_on_support_chosen.bind(opt.support_path, opt.skill_path))
		card.add_child(select_btn)
		
		add_child(card)
		_cards.append(card)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				if _support_options.size() >= 1:
					var o := _support_options[0]
					_on_support_chosen(o.support_path, o.skill_path)
			KEY_2:
				if _support_options.size() >= 2:
					var o := _support_options[1]
					_on_support_chosen(o.support_path, o.skill_path)
			KEY_3:
				if _support_options.size() >= 3:
					var o := _support_options[2]
					_on_support_chosen(o.support_path, o.skill_path)

func _on_support_chosen(support_path: String, skill_path: String) -> void:
	support_selected.emit(support_path, skill_path)
	queue_free()
