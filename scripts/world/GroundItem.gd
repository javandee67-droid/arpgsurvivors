extends Area2D
class_name GroundItem
## Yerde duran, mouse ile tıklanıp alınabilen item.
## Normal=beyaz, magic=mavi, rare=altın+gradyan glow

var item_data: ItemData = null
var _picked_up: bool = false
var _hovered: bool = false
var tooltip_label: RichTextLabel = null
var glow_nodes: Array[Node] = []
var icon_sprite: TextureRect = null

const RARITY_COLORS := {
	"normal": Color(1, 1, 1),
	"magic": Color(0.3, 0.5, 1.0),
	"rare": Color(1.0, 0.75, 0.05),
	"unique": Color(1.0, 0.45, 0.05),
}
const ITEM_ICONS := {
	"weapon": "res://assets/generated/icon_sword_frame_0.png",
	"sword": "res://assets/generated/icon_sword_frame_0.png",
	"helmet": "res://assets/generated/icon_helmet_frame_0.png",
	"body_armour": "res://assets/generated/icon_chest_v2_frame_0.png",
	"gloves": "res://assets/generated/icon_gloves_frame_0.png",
	"boots": "res://assets/generated/icon_boots_frame_0.png",
	"offhand": "res://assets/generated/icon_shield_frame_0.png",
	"ring": "res://assets/generated/icon_ring_frame_0.png",
	"accessory": "res://assets/generated/icon_amulet_frame_0.png",
	"belt": "res://assets/generated/icon_belt_frame_0.png",
	"dagger": "res://assets/generated/icon_dagger_frame_0.png",
	"staff": "res://assets/generated/icon_staff_frame_0.png",
	"bow": "res://assets/generated/icon_bow_frame_0.png",
	"wand": "res://assets/generated/icon_wand_frame_0.png",
	"axe": "res://assets/generated/icon_axe_frame_0.png",
	"support_gem": "res://assets/generated/icon_gem_frame_0.png",
}

func setup(data: ItemData) -> void:
	item_data = data
	var rarity: String = data.rarity
	var col: Color = RARITY_COLORS.get(rarity, Color.WHITE)
	
	# Nadir/unique soft glow (yuvarlak, gradient benzeri, katmanlı)
	if rarity == "rare" or rarity == "unique":
		for i in range(3):
			var g := ColorRect.new()
			var size := 28.0 + i * 10.0
			g.size = Vector2(size, size)
			g.position = Vector2(-size/2, -size/2)
			# Soft renk, düşük opaklık
			var alpha := 0.15 - i * 0.05
			g.color = Color(col.r, col.g, col.b, alpha)
			g.self_modulate = Color(1, 1, 1, 1.0)
			add_child(g)
			glow_nodes.append(g)
	
	# İtem simgesi — önce item.icon varsa onu kullan, sonra CURRENCY_ICONS, sonra tür bazlı
	var use_icon: Texture2D = data.icon
	if not use_icon:
		# Currency items: CURRENCY_ICONS sözlüğünden bul
		if data.item_type == "currency" or data.rarity == "currency":
			var cpath: String = ItemData.CURRENCY_ICONS.get(data.id, "")
			if cpath != "" and ResourceLoader.exists(cpath):
				use_icon = load(cpath)
	if not use_icon:
		var lookup_key: String = data.weapon_type if data.weapon_type and data.weapon_type != "" else data.item_type
		var icon_path: String = ITEM_ICONS.get(lookup_key, "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			use_icon = load(icon_path)
	if use_icon:
		icon_sprite = TextureRect.new()
		icon_sprite.texture = use_icon
		icon_sprite.size = Vector2(24, 24)
		icon_sprite.position = Vector2(-12, -12)
		icon_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon_sprite)
	else:
		# Fallback: renkli daire
		var sq := ColorRect.new()
		sq.size = Vector2(18, 18)
		sq.position = Vector2(-9, -9)
		sq.color = col
		sq.self_modulate = Color(1, 1, 1, 0.85)
		add_child(sq)
		var inn := ColorRect.new()
		inn.size = Vector2(10, 10)
		inn.position = Vector2(-5, -5)
		inn.color = col.lerp(Color(0.15, 0.15, 0.2), 0.3)
		add_child(inn)
	
	# İsim etiketi
	var lbl := Label.new()
	lbl.text = data.display_name
	lbl.position = Vector2(-48, -22)
	lbl.size = Vector2(96, 14)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(lbl)
	
	# Çarpışma (deferred — Area2D physics flush hatasını önler)
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 14
	cs.shape = sh
	call_deferred("add_child", cs)
	
	# Mouse interaksiyonu (Area2D için input_pickable gerekli)
	input_pickable = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_input_event)
	
	# WorldUI katmanına tooltip
	call_deferred("_create_tooltip", col)

func _create_tooltip(border_color: Color) -> void:
	var world_ui := get_tree().root.get_node_or_null("WorldUI") as CanvasLayer
	if not world_ui:
		world_ui = CanvasLayer.new()
		world_ui.name = "WorldUI"
		world_ui.layer = 10
		get_tree().root.add_child(world_ui)
	
	tooltip_label = RichTextLabel.new()
	tooltip_label.visible = false
	tooltip_label.size = Vector2(260, 40)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.bbcode_enabled = true
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_label.add_theme_color_override("default_color", Color(0.85, 0.85, 0.9))
	tooltip_label.add_theme_font_size_override("normal_font_size", 11)
	# Style — daha kalın border
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.05, 0.95)
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(4)
	tooltip_label.add_theme_stylebox_override("normal", style)
	tooltip_label.z_index = 1000
	world_ui.add_child(tooltip_label)

func _process(_delta: float) -> void:
	if _picked_up: return
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Otomatik pickup — pickup_radius'a göre
	var pickup_range := 50.0
	if player.has_node("CharacterStats"):
		var stats := player.get_node("CharacterStats") as CharacterStats
		pickup_range += stats.pickup_radius
	
	var dist := global_position.distance_to(player.global_position)
	if dist < pickup_range:
		_pickup_mouse()

func _input_event(_vp: Node, event: InputEvent, _sid: int) -> void:
	if _picked_up: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_pickup_mouse()

func _pickup_mouse() -> void:
	if _picked_up: return
	_picked_up = true
	if tooltip_label:
		tooltip_label.queue_free()
		tooltip_label = null
	# Currency/orb'leri ayri envantere (ÖZLER) yönlendir
	if item_data.item_type == "currency" and item_data.rarity == "currency":
		var p := get_tree().get_first_node_in_group("player") as Node
		if p:
			var ei := p.get_node_or_null("EssenceInventory") as EssenceInventory
			if ei and ei.add_essence(item_data):
				var tw := create_tween()
				tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
				tw.tween_callback(queue_free)
				return
		_picked_up = false
		return
	var inv := _player_inv()
	if inv and inv.add_item(item_data):
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
		tw.tween_callback(queue_free)
		return
	_picked_up = false

func _player_inv() -> Node:
	var p := get_tree().get_first_node_in_group("player") as Node
	if not p:
		return null
	var inv := p.get_node_or_null("Inventory")
	return inv

func _on_mouse_entered() -> void:
	_hovered = true
	_show_tooltip()
	# Hover efekti - glow'u parlat (soft)
	for g in glow_nodes:
		if g is ColorRect:
			g.self_modulate = Color(2.0, 2.0, 2.0, 1.5)
	if icon_sprite:
		icon_sprite.scale = Vector2(1.2, 1.2)
	scale = Vector2(1.1, 1.1)

func _on_mouse_exited() -> void:
	_hovered = false
	_hide_tooltip()
	for g in glow_nodes:
		if g is ColorRect:
			g.self_modulate = Color(1, 1, 1, 1.0)
	if icon_sprite:
		icon_sprite.scale = Vector2(1, 1)
	scale = Vector2(1, 1)

func _show_tooltip() -> void:
	if not tooltip_label or not item_data: return
	tooltip_label.text = _build_tooltip(item_data)
	tooltip_label.visible = true
	# İlk açılışta minimum boyut — async sizing tamamlanana kadar incecik kalmasın
	tooltip_label.size = Vector2(240, 120)
	_update_tp_pos()
	# RichTextLabel içerik yüksekliğini hesapladıktan sonra kesin boyuta geç
	for i in 2:
		await get_tree().process_frame
		if not is_instance_valid(tooltip_label):
			return
	var content_h: float = tooltip_label.get_content_height()
	if content_h < 20.0:
		content_h = 120.0
	tooltip_label.size.y = min(content_h + 20.0, 600.0)
	tooltip_label.size.x = 240
	_update_tp_pos()

func _hide_tooltip() -> void:
	if tooltip_label:
		tooltip_label.visible = false

func _update_tp_pos() -> void:
	if not tooltip_label or not tooltip_label.visible: return
	# CanvasLayer ekran koordinatı kullanır — viewport mouse pozisyonu al
	var vp := get_viewport()
	if not vp: return
	var mp: Vector2 = vp.get_mouse_position()
	var ts: Vector2 = tooltip_label.size
	var vp_size: Vector2 = vp.get_visible_rect().size
	# Tooltip'in ekrandan taşmaması için pozisyon ayarla
	var px := mp.x + 16.0
	var py := mp.y - 16.0
	if px + ts.x > vp_size.x:
		px = mp.x - ts.x - 16.0  # Sol tarafa açıl
	if py < 0:
		py = 4.0
	if py + ts.y > vp_size.y:
		py = vp_size.y - ts.y - 4.0
	tooltip_label.global_position = Vector2(px, py)

func _process(_d: float) -> void:
	if _hovered and tooltip_label and tooltip_label.visible:
		_update_tp_pos()

func _build_tooltip(item: ItemData) -> String:
	var rc: String = ""
	var rt: String = ""
	match item.rarity:
		"magic": rc = "#5b6eff"; rt = "BÜYÜLÜ"
		"rare": rc = "#ffd700"; rt = "NADİR"
		"unique": rc = "#ff8822"; rt = "EŞSİZ"
		_: rc = "#ffffff"
	var t := ""
	if rc != "":
		t += "[color=%s][b]%s[/b]\n" % [rc, item.display_name]
		if rt != "": t += "[i]%s[/i][/color]\n" % rt
	# Currency item tooltip — açıklamayı CurrencyRegistry'den al
	if item.item_type == "currency" or item.rarity == "currency":
		var cd: CurrencyData = CurrencyRegistry.get_orb(item.id)
		if cd:
			t += "[color=#88ff88]" + cd.description + "[/color]\n"
		t += "[color=#888888]Orb  •  Envanterde stack'lenir[/color]\n"
		return t
	# Item Level gösterimi
	t += "[color=#888888]%s  •  Item Level: %d  •  Gereken Level: %d[/color]\n" % [item.item_type.capitalize(), item.item_level, item.required_level]

	# Kalite göster
	if item.quality > 0:
		t += "[color=#ffd700]Kalite: +%d%%[/color]\n" % [item.quality]
	# === BASE STATS ===
	var base_lines: Array[String] = []
	if item.base_physical_damage_min > 0 or item.base_physical_damage_max > 0:
		base_lines.append("[color=#ffffff]Fiziksel Hasar: %d-%d[/color]" % [item.base_physical_damage_min, item.base_physical_damage_max])
	if item.base_elemental_damage > 0:
		base_lines.append("[color=#ffffff]Element Hasarı: %d[/color]" % [item.base_elemental_damage])
	if item.base_armour > 0:
		base_lines.append("[color=#ffffff]Zırh: %d[/color]" % [item.base_armour])
	if item.base_evasion > 0:
		base_lines.append("[color=#ffffff]Kaçınma: %d[/color]" % [item.base_evasion])
	if item.base_energy_shield > 0:
		base_lines.append("[color=#ffffff]Enerji Kalkanı: %d[/color]" % [item.base_energy_shield])
	if item.base_block_chance > 0:
		base_lines.append("[color=#ffffff]Saldırı Blok Şansı: %d%%[/color]" % [item.base_block_chance])
	if item.base_attack_speed > 0:
		base_lines.append("[color=#ffffff]Saldırı Hızı: %.1f[/color]" % [item.base_attack_speed])
	if item.base_cast_speed > 0:
		base_lines.append("[color=#ffffff]Büyü Hızı: %.1f[/color]" % [item.base_cast_speed])
	if base_lines.size() > 0:
		t += "\n".join(base_lines) + "\n"

	# === STAT REQUIREMENTS ===
	var req_lines: Array[String] = []
	if item.required_strength > 0:
		req_lines.append("[color=#e06666]Güç: %d[/color]" % [item.required_strength])
	if item.required_dexterity > 0:
		req_lines.append("[color=#66b3e0]Çeviklik: %d[/color]" % [item.required_dexterity])
	if item.required_intelligence > 0:
		req_lines.append("[color=#9966cc]Zeka: %d[/color]" % [item.required_intelligence])
	if req_lines.size() > 0:
		t += "[color=#aaaaaa]Gereken: [/color]" + "  ".join(req_lines) + "\n"

	# === AFFIXES ===
	if item.affixes.is_empty():
		t += "[color=#666666]  (ek özellik yok)[/color]\n"
	else:
		for affix in item.affixes:
			t += "  " + affix.get_colored_text() + "\n"
	return t

# Otomatik pickup KALDIRILDI - sadece sol tıkla alınır
