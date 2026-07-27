class_name JuiceManager
extends CanvasLayer
## Merkezi görsel/işitsel geri bildirim (juice) yöneticisi.
## EventBus üzerinden gelen olayları dinler ve görsel efektleri tetikler.

# --- References (set externally) ---
var camera: Camera2D = null
var player: Node = null

# --- Combo tracking ---
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _combo_aura: Node = null
const COMBO_TIMEOUT: float = 2.5

# --- Cooldown flash tracking ---
var _cooldown_trackers: Dictionary = {}  # skill_index -> bool (was_on_cooldown)

# Shared particle texture (tiny white circle)
var _particle_tex: Texture2D = null

func _ready() -> void:
	layer = 80  # FloatingDamage'in (60) ustunde
	process_mode = PROCESS_MODE_ALWAYS
	
	# Create shared particle texture
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for x in 8:
		for y in 8:
			var dx := (x - 3.5) / 3.5
			var dy := (y - 3.5) / 3.5
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	_particle_tex = ImageTexture.create_from_image(img)
	
	# EventBus baglantilari
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.damage_taken.connect(_on_damage_taken)
	EventBus.crit_landed.connect(_on_crit_landed)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.screen_shake.connect(_on_screen_shake)
	EventBus.skill_cast.connect(_on_skill_cast)
	EventBus.level_up.connect(_on_level_up_event)
	EventBus.boss_encounter.connect(_on_boss_encounter)
	EventBus.boss_killed.connect(_on_boss_killed)

func _process(delta: float) -> void:
	# Combo timeout
	if _combo_count > 0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			_combo_count = 0
			_update_combo_aura()

# ==================== HIT REACTIONS ====================

func _on_damage_dealt(payload: Dictionary) -> void:
	var target: Node = payload.get("target", null)
	if not target or target.is_in_group("player"):
		return
	
	var is_crit: bool = payload.get("is_crit", false)
	var amount: float = payload.get("amount", 0.0)
	
	# Screen shake
	if is_crit:
		_do_screen_shake(4.0, 0.2)
	else:
		_do_screen_shake(1.5, 0.08)
	
	# Increment combo
	if amount > 0:
		_combo_count += 1
		_combo_timer = COMBO_TIMEOUT
		_update_combo_aura()

func _on_damage_taken(payload: Dictionary) -> void:
	# Player takes damage - screen pulse
	var target: Node = payload.get("target", null)
	if target and target.is_in_group("player"):
		_do_screen_shake(2.0, 0.1)
		# Health bar flash handled separately in HUD

func _on_crit_landed(payload: Dictionary) -> void:
	_do_screen_flash(Color(1.0, 0.95, 0.7, 0.25), 0.15)

func _on_enemy_killed(enemy: Node) -> void:
	if not enemy:
		return
	var pos: Vector2 = enemy.global_position if enemy.has_method("get_global_position") else Vector2.ZERO
	_spawn_death_effect(pos, enemy)
	_do_screen_shake(5.0, 0.3)
	_combo_count = 0
	_update_combo_aura()

func _on_skill_cast(skill_id: String, caster: Node) -> void:
	if caster != player:
		return
	# _spawn_cast_effect(caster.global_position, skill_id)  # Mavi bulut efekti kaldirildi

func _on_screen_shake(intensity: float, duration: float) -> void:
	_do_screen_shake(intensity, duration)

func _on_level_up_event(new_level: int, pos: Vector2) -> void:
	show_level_up_effect(new_level)
	_spawn_level_up_burst(pos)

func _on_boss_encounter(boss_name: String, pos: Vector2) -> void:
	_do_boss_spawn_flash(boss_name, pos)

func _on_boss_killed(_boss_name: String, pos: Vector2) -> void:
	_do_boss_killed_effect(pos)

# ==================== PRIMITIVES ====================

func _do_screen_shake(intensity: float, duration: float) -> void:
	if not camera or not is_instance_valid(camera):
		return
	var original_offset: Vector2 = Vector2.ZERO
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_OUT)
	
	# Rastgele sallanti
	var shake_count: int = maxi(3, int(duration / 0.033))
	for i in shake_count:
		var t := float(i) / float(shake_count)
		var decay: float = 1.0 - t
		var offset_x := randf_range(-1.0, 1.0) * intensity * decay
		var offset_y := randf_range(-1.0, 1.0) * intensity * decay
		tw.tween_property(camera, "offset", Vector2(offset_x, offset_y), duration * 0.5 / shake_count)
	tw.tween_property(camera, "offset", Vector2.ZERO, duration * 0.3)

func _do_screen_flash(color: Color, duration: float) -> void:
	var flash := ColorRect.new()
	flash.color = color
	flash.anchor_right = 1.0
	flash.anchor_bottom = 1.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var tw := create_tween()
	tw.tween_property(flash, "modulate", Color(color.r, color.g, color.b, 0.0), duration)
	tw.tween_callback(flash.queue_free).set_delay(duration + 0.05)

# ==================== VFX ====================

func _spawn_hit_effect(pos: Vector2, damage_type: String, is_crit: bool) -> void:
	var em := GPUParticles2D.new()
	var mat := ParticleProcessMaterial.new()
	
	# Damage type'e gore renk
	var color: Color
	match damage_type:
		"fire": color = Color(1.0, 0.4, 0.1)
		"cold": color = Color(0.3, 0.6, 1.0)
		"lightning": color = Color(1.0, 0.9, 0.2)
		"chaos": color = Color(0.6, 0.2, 0.8)
		_: color = Color(1.0, 0.8, 0.5)  # physical
	
	if is_crit:
		color = Color(1.0, 0.9, 0.1)
		em.amount = 16
	else:
		em.amount = 6
	
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.gravity = Vector3(0, 60, 0)
	mat.initial_velocity_min = 30.0 if is_crit else 15.0
	mat.initial_velocity_max = 80.0 if is_crit else 40.0
	mat.scale_min = 1.0
	mat.scale_max = 3.0
	mat.color = color
	var grad: Gradient = _make_gradient(color)
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 8
	gtex.height = 8
	mat.color_ramp = gtex
	
	em.texture = _particle_tex
	em.process_material = mat
	em.one_shot = true
	em.explosiveness = 1.0
	em.lifetime = 0.5
	em.position = pos
	em.z_index = 100
	
	get_tree().current_scene.add_child(em)
	em.emitting = true
	# Auto cleanup
	get_tree().create_timer(1.0).timeout.connect(em.queue_free)

func _spawn_death_effect(pos: Vector2, enemy: Node) -> void:
	# Blood explosion (kucultuldu - abartili efektler rahatsiz ediciydi)
	var em := GPUParticles2D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 360.0
	mat.gravity = Vector3(0, 60, 0)
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 60.0
	mat.scale_min = 0.6
	mat.scale_max = 1.8
	mat.color = Color(0.6, 0.05, 0.05)
	em.texture = _particle_tex
	em.process_material = mat
	em.amount = 10
	em.one_shot = true
	em.explosiveness = 1.0
	em.lifetime = 0.5
	em.position = pos
	em.z_index = 50
	get_tree().current_scene.add_child(em)
	em.emitting = true
	get_tree().create_timer(1.0).timeout.connect(em.queue_free)
	
	# Rarity glow on death - item drop icin
	var rarity := 0  # NORMAL
	if enemy.has_method("get_rarity"):
		rarity = enemy.get_rarity()
	if rarity >= 2:  # RARE+
		_spawn_light_pillar(pos, rarity)

func _spawn_cast_effect(pos: Vector2, skill_id: String) -> void:
	var em := GPUParticles2D.new()
	# (Bu basit bir ornektir; gercek partikul sistemi skill tipine gore ozellestirilir)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.gravity = Vector3(0, -20, 0)
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 100.0
	mat.scale_min = 1.5
	mat.scale_max = 4.0
	mat.color = Color(0.4, 0.6, 1.0, 0.8)
	em.texture = _particle_tex
	em.process_material = mat
	em.amount = 10
	em.one_shot = true
	em.explosiveness = 1.0
	em.lifetime = 0.4
	em.position = pos
	em.z_index = 60
	get_tree().current_scene.add_child(em)
	em.emitting = true
	get_tree().create_timer(1.0).timeout.connect(em.queue_free)

func _spawn_light_pillar(pos: Vector2, rarity: int) -> void:
	var color: Color
	match rarity:
		2: color = Color(1.0, 0.8, 0.2)   # RARE - gold
		3: color = Color(1.0, 0.5, 0.1)   # UNIQUE - orange
		_: color = Color(0.4, 0.6, 1.0)   # MAGIC - blue
	
	# Light pillar using a tall thin ColorRect
	var pillar := ColorRect.new()
	pillar.color = Color(color.r, color.g, color.b, 0.6)
	pillar.size = Vector2(6, 400)
	pillar.position = pos - Vector2(3, 400)
	pillar.z_index = 40
	get_tree().current_scene.add_child(pillar)
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(pillar, "modulate", Color(color.r, color.g, color.b, 0.0), 1.5)
	tw.tween_callback(pillar.queue_free).set_delay(1.6)

# ==================== COMBO AURA ====================

func _update_combo_aura() -> void:
	if _combo_aura and is_instance_valid(_combo_aura):
		_combo_aura.queue_free()
		_combo_aura = null
	
	if _combo_count < 3 or not player:
		return
	
	# Create a pulsing ring around player
	var aura := ColorRect.new()
	aura.name = "ComboAura"
	var min_dim := 48.0  # player height estimate
	var aura_size := min_dim + float(mini(_combo_count, 20)) * 4.0
	aura.size = Vector2(aura_size, aura_size)
	
	# StyleBoxFlat to make it circular
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.8, 0.3, 0.12)
	style.set_corner_radius_all(int(aura_size * 0.5))
	style.set_border_width_all(2)
	style.border_color = Color(1.0, 0.9, 0.3, 0.5)
	aura.add_theme_stylebox_override("panel", style)
	
	player.add_child(aura)
	aura.position = -aura.size * 0.5 + Vector2(0, -24)  # Center on player, slight upward
	
	# Pulsing animation
	var tw := create_tween().set_loops()
	tw.set_parallel(true)
	tw.tween_property(aura, "modulate", Color(1, 1, 1, 0.25), 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(aura, "modulate", Color(1, 1, 1, 0.1), 0.5).set_delay(0.5).set_ease(Tween.EASE_IN_OUT)
	
	_combo_aura = aura

# ==================== LEVEL UP ====================

func show_level_up_effect(_new_level: int) -> void:
	if not camera or not is_instance_valid(camera):
		return
	_do_screen_flash(Color(1.0, 0.95, 0.6, 0.3), 0.4)
	_do_screen_shake(3.0, 0.15)

func _spawn_level_up_burst(pos: Vector2) -> void:
	var em := GPUParticles2D.new()
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 360.0
	mat.gravity = Vector3(0, -20, 0)
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 100.0
	mat.scale_min = 1.5
	mat.scale_max = 3.5
	mat.color = Color(1.0, 0.85, 0.2)
	
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 0.6), Color(1, 0.7, 0.15), Color(1, 1, 1, 0)])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 8
	gtex.height = 8
	mat.color_ramp = gtex
	
	em.texture = _particle_tex
	em.process_material = mat
	em.amount = 16
	em.one_shot = true
	em.explosiveness = 1.0
	em.lifetime = 0.6
	em.position = pos
	em.z_index = 100
	get_tree().current_scene.add_child(em)
	em.emitting = true
	get_tree().create_timer(1.5).timeout.connect(em.queue_free)

# ==================== UTILITY ====================

func _make_gradient(base_color: Color) -> Gradient:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	var light := Color(base_color.r * 1.5, base_color.g * 1.5, base_color.b * 1.5, 1.0)
	grad.colors = PackedColorArray([light, base_color])
	return grad

# _make_particle_texture() removed — now created in _ready()
