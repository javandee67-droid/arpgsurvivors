extends Area2D
class_name InfernalCircle
## Cehennem Çemberi — oyuncunun etrafinda fire hasari veren alan.
## Skill acikken can drain'i Player.gd handle eder, bu sadece hasar + gorsel.
## Level arttikca radius buyur, hasar artar, drain artar.

signal circle_deactivated

## Animasyonlu alev halkası sprite
var _fire_sprite: AnimatedSprite2D = null

## Referanslar (Player tarafindan set edilir)
var skill_path: String = ""
var player_stats: CharacterStats = null
var player_health: Health = null
var _active_supports: Array[SupportData] = []  # Player tarafindan set edilir

## Base yaricap (level scaling ile buyur)
var radius: float = 120.0
## Mevcut aura level (stat'dan)
var aura_level: int = 1
## Tick basina base fire hasari (level ile artar)
var base_damage_per_tick: float = 8.0

## Support gem'lerden gelen radius modifier
var _radius_mult: float = 1.0
var _damage_mult: float = 1.0

## Hasar verme araligi
const DAMAGE_INTERVAL: float = 0.5

var _damage_timer: float = 0.0
var _pulse_phase: float = 0.0
var _is_active: bool = false

# Renkler
const INNER_FILL: Color = Color(1.0, 0.6, 0.1, 0.35)
const OUTER_ARC: Color = Color(1.0, 0.2, 0.0, 0.2)
const MID_ARC: Color = Color(1.0, 0.4, 0.0, 0.55)
const INNER_ARC: Color = Color(1.0, 0.7, 0.1, 0.65)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # enemy layer (dusmanlar default layer 1'de)
	
	# CollisionShape2D — daire
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)
	
	# Animasyonlu alev halkası sprite
	_fire_sprite = AnimatedSprite2D.new()
	_fire_sprite.name = "FireRingSprite"
	_fire_sprite.centered = true
	_fire_sprite.position = Vector2.ZERO
	# Sprite'ın boyutunu radius'a göre scale et (frame 64x64, radius ~120-200)
	var sprite_scale: float = (radius * 2.0) / 64.0
	_fire_sprite.scale = Vector2(sprite_scale, sprite_scale)
	# SpriteFrames yukle (16 frame, 4x4 grid, 64x64)
	var tex_path: String = "res://assets/generated/infernal_circle_fire_ring.png"
	if ResourceLoader.exists(tex_path):
		var tex := load(tex_path) as Texture2D
		if tex:
			var sf := SpriteFrames.new()
			sf.add_animation("fire_ring")
			sf.set_animation_speed("fire_ring", 8.0)
			sf.set_animation_loop("fire_ring", true)
			var frame_w: int = 64
			var frame_h: int = 64
			var cols: int = 4
			for row in range(4):
				for col in range(cols):
					var atlas := AtlasTexture.new()
					atlas.atlas = tex
					atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
					sf.add_frame("fire_ring", atlas)
			_fire_sprite.sprite_frames = sf
			_fire_sprite.play("fire_ring")
	add_child(_fire_sprite)
	
	_is_active = true


func _process(delta: float) -> void:
	if not _is_active:
		return
	
	# Oyuncu olmadan calisma
	if not player_stats or not player_health:
		queue_free()
		return
	
	# Oyuncu olmus mu?
	if player_health.current_health <= 0.0:
		deactivate()
		return
	
	# Animasyonlu sprite yoksa _draw ile çiz
	if _fire_sprite and _fire_sprite.sprite_frames:
		if not _fire_sprite.is_playing():
			_fire_sprite.play()
	else:
		# _draw fallback — animasyon spritesiz pulse
		_pulse_phase += delta * 2.0
		queue_redraw()
	
	# Periyodik hasar
	_damage_timer += delta
	if _damage_timer >= DAMAGE_INTERVAL:
		_damage_timer = 0.0
		_deal_area_damage()


func _draw() -> void:
	var center := Vector2.ZERO
	# Collision shape sabit — gorsel de sabit radius'te cizilir
	# Sadece ic dolgu ve ates noktalari pulse yapar (dis halka sabit)
	
	# En dis soluk halka (SABIT — collision ile eslesir)
	draw_arc(center, radius, 0.0, TAU, 48, OUTER_ARC, 3.0)
	# Orta halka (sabit)
	draw_arc(center, radius * 0.95, 0.0, TAU, 48, MID_ARC, 2.5)
	
	# Ic dolgu (ates rengi, pulse ile oynar — sadece gorsel)
	var fill_r: float = radius * 0.85
	var fill_a: float = INNER_FILL.a * (0.5 + 0.5 * sin(_pulse_phase * 0.7))
	var fill_c := Color(INNER_FILL.r, INNER_FILL.g, INNER_FILL.b, fill_a)
	draw_circle(center, fill_r, fill_c)
	
	# En ic halka (parlak, hafif pulse — sadece gorsel)
	var inner_r: float = fill_r * 0.85
	var inner_pulse: float = 0.9 + 0.1 * sin(_pulse_phase * 1.3 + 1.0)
	draw_arc(center, inner_r * inner_pulse, 0.0, TAU, 36, INNER_ARC, 2.0)
	
	# Ates noktalari (halka boyunca doner, pulse sadece parlaklik)
	var dot_count: int = 8
	var dot_phase: float = _pulse_phase * 0.5
	for i in range(dot_count):
		var a: float = dot_phase + (TAU / dot_count) * i
		var dot_pos := center + Vector2(cos(a), sin(a)) * (radius * 0.9)
		var dot_a: float = 0.4 + 0.6 * sin(_pulse_phase * 3.0 + float(i))
		var dot_c := Color(1.0, 0.7 + 0.3 * sin(_pulse_phase + float(i)), 0.1, dot_a)
		draw_circle(dot_pos, 4.0, dot_c)


## Ic alandaki her dusmana periyodik fire hasari verir
func _deal_area_damage() -> void:
	if not player_stats or not player_health:
		return
	
	var overlapping: Array[Node2D] = get_overlapping_bodies()
	if overlapping.is_empty():
		return
	
	# Fire damage scaling (Spell + Fire + Area + Elemental + All tags)
	var total_inc: float = player_stats.fire_damage_increased \
			+ player_stats.area_damage_increased \
			+ player_stats.elemental_damage_increased \
			+ player_stats.all_damage_increased
	var inc_pct: float = total_inc / 100.0
	
	# Support gem FLAT damage (added_fire_damage, added_cold_damage, etc.)
	var support_flat: float = 0.0
	for sd in _active_supports:
		if not sd:
			continue
		for mod in sd.modifiers:
			if mod.stat == "damage" and mod.modifier_type == StatModifier.ModifierType.FLAT:
				if mod.damage_type_filter == "fire" or mod.damage_type_filter == "elemental" or mod.damage_type_filter == "":
					support_flat += mod.value
	
	# Life regen = extra damage (2x life_regen)
	var life_regen_bonus: float = player_stats.life_regen_per_second * 2.0
	var tick_dmg: float = (base_damage_per_tick + support_flat + life_regen_bonus) * (1.0 + inc_pct)
	
	for body in overlapping:
		if not is_instance_valid(body):
			continue
		if not body.is_in_group("enemy"):
			continue
		var health: Health = body.get_node_or_null("Health") as Health
		if not health or health.current_health <= 0.0:
			continue
		
		# Dogrudan hasar uygula (Health.take_damage resistanslari otomatik uygular)
		var _result: Dictionary = health.take_damage(tick_dmg, player_health.get_parent(), ["fire", "spell", "area", "infernal_circle"], true, player_stats.penetration_fire)
		# Not: Ailment uygulamasi icin AilmentUtils.try_ignite hit_result Dictionary gerektirir.
		# Infernal Circle su an icin sadece raw fire hasari verir.


## Support gem modifier'larini uygula
func apply_support_gems(supports: Array[SupportData]) -> void:
	_active_supports = supports
	_radius_mult = 1.0
	_damage_mult = 1.0
	for sd in _active_supports:
		if not sd:
			continue
		for mod in sd.modifiers:
			if mod.damage_type_filter == "radius":
				# Radius MORE modifier (pozitif = buyut, negatif = kucult)
				_radius_mult *= (1.0 + mod.value / 100.0)
			elif mod.stat == "damage":
				if mod.modifier_type == StatModifier.ModifierType.MORE or mod.modifier_type == StatModifier.ModifierType.INCREASED:
					# Damage MORE/INCREASED modifier (ikisi de carpan olarak uygulanir)
					_damage_mult *= (1.0 + mod.value / 100.0)
	# Radius ve hasari guncelle
	var new_radius: float = (120.0 + aura_level * 8.0) * _radius_mult
	update_radius(new_radius)
	# 2x base damage buff — can drain'in karsiligini versin
	base_damage_per_tick = (15.0 + aura_level * 5.0) * _damage_mult

## Level/stat scaling guncellemesi
func apply_level_scaling(stat_node: CharacterStats) -> void:
	aura_level = stat_node.aura_level if stat_node else 1
	# Support modifier'larini base scaling'den sonra uygula
	# (supports zaten set edilmis olmali)


func update_radius(new_radius: float) -> void:
	radius = new_radius
	for child in get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			child.shape.radius = radius
		if child is AnimatedSprite2D:
			var sprite_scale: float = (radius * 2.0) / 64.0
			child.scale = Vector2(sprite_scale, sprite_scale)


func deactivate() -> void:
	_is_active = false
	circle_deactivated.emit()
	queue_free()
