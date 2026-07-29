extends CanvasLayer
class_name InitialSkillSelectionUI
## Oyun başında gösterilen başlangıç skill seçim ekranı.
## Başlangıçta 3 skill kartı arasından seçim yapılır.

signal skill_selected(skill_path: String)

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
	"arcane": Color(0.5, 0.2, 1.0),
	"holy": Color(1.0, 0.95, 0.6),
}

var _selected_index: int = -1
var _skill_options: Array[String] = []
var _cards: Array[Panel] = []

func _ready() -> void:
	_setup_initial_options()
	_build_ui()

func _setup_initial_options() -> void:
	# Rastgele 3 skill seç (ama her zaman farklı tipler olsun)
	var shuffled := ALL_SKILLS.duplicate()
	shuffled.shuffle()
	_skill_options = shuffled.slice(0, 3)

func _build_ui() -> void:
	var vp := get_viewport().get_visible_rect().size
	
	# Arkaplan
	var bg := ColorRect.new()
	bg.name = "SelectionBG"
	bg.color = Color(0.02, 0.02, 0.05, 0.98)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Başlık
	var title := Label.new()
	title.text = "YETENEK SEÇ"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, vp.y * 0.04)
	title.size = Vector2(vp.x, 50)
	add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "Başlamak için bir yetenek seç"
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.65, 0.6, 0.7))
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, vp.y * 0.04 + 55)
	subtitle.size = Vector2(vp.x, 25)
	add_child(subtitle)
	
	# Kartları oluştur - ekrana sığacak şekilde responsive
	var card_w: float = min(340.0, vp.x * 0.22)
	var card_h: float = min(380.0, vp.y * 0.55)
	var gap: float = min(30.0, vp.x * 0.025)
	var total_w: float = _skill_options.size() * card_w + (_skill_options.size() - 1) * gap
	var start_x: float = max(10.0, (vp.x - total_w) / 2.0)
	var card_y: float = vp.y * 0.15
	
	for i in range(_skill_options.size()):
		var skill_path: String = _skill_options[i]
		_create_skill_card(skill_path, i, Vector2(start_x + i * (card_w + gap), card_y), Vector2(card_w, card_h))
	
	# Alt bilgi
	var hint := Label.new()
	hint.text = "Fare ile üzerine gel ve tıkla veya 1-2-3 tuşlarına bas"
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.6))
	hint.add_theme_font_size_override("font_size", 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, vp.y * 0.94)
	hint.size = Vector2(vp.x, 20)
	add_child(hint)

func _create_skill_card(skill_path: String, index: int, pos: Vector2, size: Vector2) -> void:
	var skill_data: SkillData = load(skill_path) if ResourceLoader.exists(skill_path) else null
	if not skill_data:
		return
	
	var card := Panel.new()
	card.name = "SkillCard_%d" % index
	card.position = pos
	card.size = size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var dmg_color: Color = DAMAGE_COLORS.get(skill_data.damage_type, Color(0.6, 0.5, 0.4))
	
	# Kart arka planı - gradient efekti
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.06, 0.06, 0.1, 0.97)
	card_style.border_width_left = 3
	card_style.border_width_right = 3
	card_style.border_width_top = 3
	card_style.border_width_bottom = 3
	card_style.border_color = dmg_color.darkened(0.3)
	card_style.set_corner_radius_all(12)
	card_style.shadow_color = Color(dmg_color.r * 0.3, dmg_color.g * 0.3, dmg_color.b * 0.3, 0.4)
	card_style.shadow_size = 12
	card_style.shadow_offset = Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)
	
	# Hover efektini takip et
	card.mouse_entered.connect(_on_card_hover.bind(index, card, dmg_color))
	card.mouse_exited.connect(_on_card_exit.bind(index, card, dmg_color))
	
	# İkon alanı (üst kısım) - daha kompakt
	var icon_bg := ColorRect.new()
	icon_bg.name = "IconBg"
	icon_bg.color = Color(dmg_color.r * 0.15, dmg_color.g * 0.15, dmg_color.b * 0.15, 1.0)
	icon_bg.position = Vector2(20, 14)
	icon_bg.size = Vector2(size.x - 40, 80)
	card.add_child(icon_bg)
	
	var icon_rect := TextureRect.new()
	icon_rect.name = "SkillIcon"
	icon_rect.position = Vector2((size.x - 64) / 2.0, 22)
	icon_rect.size = Vector2(64, 64)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if skill_data.icon_path and ResourceLoader.exists(skill_data.icon_path):
		icon_rect.texture = load(skill_data.icon_path)
	elif skill_data.icon:
		icon_rect.texture = skill_data.icon
	else:
		icon_rect.modulate = dmg_color
	card.add_child(icon_rect)
	
	# Yetenek adı
	var name_lbl := Label.new()
	name_lbl.text = skill_data.display_name
	name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 0.95))
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(0, 100)
	name_lbl.size = Vector2(size.x, 26)
	card.add_child(name_lbl)
	
	# Yetenek tipi
	var type_names: Array[String] = ["Mermi", "Alan", "Yakın Dövüş", "Güçlendirme", "Aura", "Lanet", "Hareket", "Tetikleyici"]
	var type_lbl := Label.new()
	type_lbl.text = type_names[skill_data.skill_type] if skill_data.skill_type < type_names.size() else "?"
	type_lbl.add_theme_color_override("font_color", dmg_color)
	type_lbl.add_theme_font_size_override("font_size", 11)
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_lbl.position = Vector2(0, 126)
	type_lbl.size = Vector2(size.x, 18)
	card.add_child(type_lbl)
	
	# Ayırıcı çizgi
	var sep := ColorRect.new()
	sep.color = Color(dmg_color.r, dmg_color.g, dmg_color.b, 0.25)
	sep.position = Vector2(25, 150)
	sep.size = Vector2(size.x - 50, 1)
	card.add_child(sep)
	
	# Hasar bilgisi
	var dmg_str := _get_damage_string(skill_data)
	var dmg_lbl := Label.new()
	dmg_lbl.text = "⚔ %s" % dmg_str
	dmg_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.7))
	dmg_lbl.add_theme_font_size_override("font_size", 13)
	dmg_lbl.position = Vector2(20, 158)
	dmg_lbl.size = Vector2(size.x - 40, 22)
	card.add_child(dmg_lbl)
	
	# Cooldown bilgisi
	var cd_lbl := Label.new()
	var cd_str := "%.1fs" % skill_data.cooldown if skill_data.cooldown > 0 else "Anlık"
	cd_lbl.text = "⏱ %s" % cd_str
	cd_lbl.add_theme_color_override("font_color", Color(0.6, 0.75, 0.9))
	cd_lbl.add_theme_font_size_override("font_size", 13)
	cd_lbl.position = Vector2(20, 180)
	cd_lbl.size = Vector2(size.x - 40, 22)
	card.add_child(cd_lbl)
	
	# Ekstra özellikler
	var extra_parts: Array[String] = []
	if "chain_count" in skill_data and skill_data.chain_count > 0:
		extra_parts.append("⚡ %d Zincir" % skill_data.chain_count)
	if "area_radius" in skill_data and skill_data.area_radius > 0.0:
		extra_parts.append("💥 %.0fpx Alan" % skill_data.area_radius)
	if "projectile_count" in skill_data and skill_data.projectile_count > 0:
		extra_parts.append("🏹 %d Mermi" % skill_data.projectile_count)
	
	var desc_y: float = 210
	if not extra_parts.is_empty():
		var extra_lbl := Label.new()
		extra_lbl.text = " • ".join(extra_parts)
		extra_lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 0.85))
		extra_lbl.add_theme_font_size_override("font_size", 11)
		extra_lbl.position = Vector2(20, 202)
		extra_lbl.size = Vector2(size.x - 40, 20)
		card.add_child(extra_lbl)
		desc_y = 225
	
	# Açıklama
	var desc_map: Dictionary = {
		"fire_bolt": "Ateşten bir ok fırlatır. Düşmanları yakar.",
		"ice_shard": "Buz mızrakları fırlatır. Yavaşlatır.",
		"lightning_chain": "Yıldırım zinciri oluşturur. Zincirleme hasar verir.",
		"arcane_orb": "Gizemli bir küre gönderir. Delici hasar verir.",
		"toxic_circle": "Zehirli bir alan oluşturur. Zamanla hasar verir.",
		"whirlwind": "Etrafındaki düşmanları keser. Yakın dövüş.",
		"dark_beam": "Karanlık bir ışın gönderir. Yüksek hasar.",
		"holy_nova": "Kutsal bir patlama yaratır. Aldığın hasarı iyileşmeye çevirir.",
		"thunder_strike": "Gök gürültüsü indirir. Şimşek efekti.",
		"frost_explosion": "Buz patlaması yaratır. Alan hasarı.",
		"fireball": "Ateş topu fırlatır. Patlama alanı oluşturur.",
		"ice_nova": "Buz halkası yayar. Çevredekileri dondurur.",
		"slice_wave": "Keskin bir dalga gönderir. Geniş menzil.",
	}
	var desc_lbl := Label.new()
	desc_lbl.text = desc_map.get(skill_data.id, "Güçlü bir yetenek")
	desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 0.9))
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.position = Vector2(20, desc_y)
	desc_lbl.size = Vector2(size.x - 40, 50)
	card.add_child(desc_lbl)
	
	# Seç butonu
	var select_btn := Button.new()
	select_btn.name = "Btn_%d" % index
	select_btn.text = "SEÇ  [%d]" % (index + 1)
	select_btn.position = Vector2(30, size.y - 55)
	select_btn.size = Vector2(size.x - 60, 38)
	
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(dmg_color.r * 0.3, dmg_color.g * 0.3, dmg_color.b * 0.3, 0.9)
	btn_normal.border_width_left = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = dmg_color
	btn_normal.set_corner_radius_all(10)
	select_btn.add_theme_stylebox_override("normal", btn_normal)
	
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(dmg_color.r * 0.5, dmg_color.g * 0.5, dmg_color.b * 0.5, 1.0)
	btn_hover.border_width_left = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_bottom = 2
	btn_hover.border_color = dmg_color.lightened(0.3)
	btn_hover.set_corner_radius_all(10)
	select_btn.add_theme_stylebox_override("hover", btn_hover)
	
	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(dmg_color.r * 0.7, dmg_color.g * 0.7, dmg_color.b * 0.7, 1.0)
	btn_pressed.border_width_left = 2
	btn_pressed.border_width_right = 2
	btn_pressed.border_width_top = 2
	btn_pressed.border_width_bottom = 2
	btn_pressed.border_color = dmg_color.lightened(0.5)
	btn_pressed.set_corner_radius_all(10)
	select_btn.add_theme_stylebox_override("pressed", btn_pressed)
	
	select_btn.add_theme_color_override("font_color", Color.WHITE)
	select_btn.add_theme_font_size_override("font_size", 16)
	select_btn.pressed.connect(_on_skill_chosen.bind(skill_path))
	card.add_child(select_btn)
	
	add_child(card)
	_cards.append(card)

func _get_damage_string(skill_data: SkillData) -> String:
	if skill_data.damage_buckets and not skill_data.damage_buckets.is_empty():
		var parts: PackedStringArray = []
		for d_type in skill_data.damage_buckets:
			var val: float = skill_data.damage_buckets[d_type]
			parts.append("%.0f %s" % [val, d_type.capitalize()])
		return " / ".join(parts)
	else:
		return "%.0f %s" % [skill_data.base_damage, skill_data.damage_type.capitalize()]

func _on_card_hover(index: int, card: Panel, base_color: Color) -> void:
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = base_color.lightened(0.2)
		style.shadow_color = Color(base_color.r * 0.5, base_color.g * 0.5, base_color.b * 0.5, 0.6)

func _on_card_exit(index: int, card: Panel, base_color: Color) -> void:
	var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.border_color = base_color.darkened(0.3)
		style.shadow_color = Color(base_color.r * 0.3, base_color.g * 0.3, base_color.b * 0.3, 0.4)

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
			KEY_ENTER:
				if _selected_index >= 0 and _selected_index < _skill_options.size():
					_on_skill_chosen(_skill_options[_selected_index])

func _on_skill_chosen(skill_path: String) -> void:
	skill_selected.emit(skill_path)
	queue_free()
