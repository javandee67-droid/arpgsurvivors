extends Node2D
class_name StatusEffectVisual
## status effect'lerin gorsel efektlerini yoneten node.
## AilmentController'dan sinyaller alir ve overlay animasyonlarini gosterir.

enum VisualLayer {
	OVERLAY,  ## Yanma, sok, chill, zehir overlay'i
	FREEZE,   ## Donma buz kayasi (buyuk)
}

const OVERLAY_ANIMS := {
	StatusEffect.Type.IGNITE: "ignite",
	StatusEffect.Type.SHOCK: "shock",
	StatusEffect.Type.CHILL: "chill",
	StatusEffect.Type.POISON: "poison",
	StatusEffect.Type.ELECTROCUTE: "electrocute",
	StatusEffect.Type.FREEZE: "freeze",
}

var _overlay_sprite: AnimatedSprite2D = null
var _freeze_sprite: AnimatedSprite2D = null
var _ailment_ctrl: AilmentController = null

func _ready() -> void:
	# Overlay sprite (32x32)
	_overlay_sprite = AnimatedSprite2D.new()
	_overlay_sprite.name = "OverlaySprite"
	_overlay_sprite.centered = true
	_overlay_sprite.set("z_index", 10)  # Enemy uzerinde gozukmeli
	add_child(_overlay_sprite)

	# Freeze sprite (48x48, buyuk)
	_freeze_sprite = AnimatedSprite2D.new()
	_freeze_sprite.name = "FreezeSprite"
	_freeze_sprite.centered = true
	_freeze_sprite.set("z_index", 11)  # Overlay'in da ustunde
	add_child(_freeze_sprite)

	# Animasyonlari yukle
	_load_animations()

	# Varsayilan: gizli
	_overlay_sprite.visible = false
	_freeze_sprite.visible = false

	# AilmentController'i bul
	_ailment_ctrl = _find_ailment_ctrl()
	if _ailment_ctrl:
		_ailment_ctrl.effect_added.connect(_on_effect_added)
		_ailment_ctrl.effect_removed.connect(_on_effect_removed)
		_ailment_ctrl.all_effects_cleared.connect(_on_all_cleared)
		# Mevcut efektleri kontrol et
		_update_visuals()

func _find_ailment_ctrl() -> AilmentController:
	var parent: Node = get_parent()
	while parent:
		if parent.has_node("AilmentController"):
			return parent.get_node("AilmentController") as AilmentController
		parent = parent.get_parent()
	return null

func _load_animations() -> void:
	# Overlay animasyonlari: ignite, shock, chill, poison
	var overlay_tex_map := {
		"ignite": "res://assets/generated/efx_burn_anim.png",
		"shock": "res://assets/generated/efx_shock_anim.png",
		"chill": "res://assets/generated/efx_chill_anim.png",
		"poison": "res://assets/generated/efx_poison_anim.png",
		"electrocute": "res://assets/generated/efx_electrocute_anim.png",
	}

	for anim_name in overlay_tex_map:
		var tex_path: String = overlay_tex_map[anim_name]
		_load_anim_from_spritesheet(_overlay_sprite, anim_name, tex_path, 32, 32)

	# Freeze animasyonu (48x48)
	_load_anim_from_spritesheet(_freeze_sprite, "freeze",
		"res://assets/generated/efx_freeze_anim.png", 48, 48)

func _load_anim_from_spritesheet(sprite: AnimatedSprite2D, anim_name: String, tex_path: String,
		frame_w: int, frame_h: int, cols: int = 4) -> void:
	if not ResourceLoader.exists(tex_path):
		printerr("StatusEffectVisual: texture not found: ", tex_path)
		return

	var tex: Texture2D = load(tex_path)
	if not tex:
		return

	# Metadata'dan frame bilgilerini al
	var meta_path: String = tex_path.replace(".png", ".metadata.json")
	var frame_data: Dictionary = {}
	if ResourceLoader.exists(meta_path):
		var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
		if file:
			var json_str: String = file.get_as_text()
			var json: JSON = JSON.new()
			if json.parse(json_str) == OK:
				frame_data = json.data

	# Frame sayisini bul
	var frame_count: int = frame_data.get("frame_count", 16)
	var speed: float = frame_data.get("fps", 8.0)

	var frames := SpriteFrames.new()
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, speed)

	for i in range(min(frame_count, 32)):
		var col: int = i % cols
		var row: int = i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
		frames.add_frame(anim_name, at)

	sprite.sprite_frames = frames

func _on_effect_added(effect_type: int) -> void:
	_update_visuals()

func _on_effect_removed(effect_type: int) -> void:
	_update_visuals()

func _on_all_cleared() -> void:
	_overlay_sprite.visible = false
	_freeze_sprite.visible = false

func _update_visuals() -> void:
	if not _ailment_ctrl:
		_overlay_sprite.visible = false
		_freeze_sprite.visible = false
		return

	# Freeze en ustun efekt - once kontrol et
	if _ailment_ctrl.is_frozen():
		_freeze_sprite.visible = true
		if _freeze_sprite.sprite_frames and _freeze_sprite.sprite_frames.has_animation("freeze"):
			_freeze_sprite.animation = "freeze"
			_freeze_sprite.play()
		_overlay_sprite.visible = false  # Freeze'de overlay gosterme
		return
	else:
		_freeze_sprite.visible = false

	# Diger efektleri sirala (oncelik: ignite > shock > poison > chill)
	var priority_order: Array[int] = [
		StatusEffect.Type.IGNITE,
		StatusEffect.Type.ELECTROCUTE,
		StatusEffect.Type.SHOCK,
		StatusEffect.Type.POISON,
		StatusEffect.Type.CHILL,
	]

	var shown: bool = false
	for etype in priority_order:
		if _ailment_ctrl.has_effect(etype):
			var anim_name: String = OVERLAY_ANIMS.get(etype, "")
			if anim_name != "" and _overlay_sprite.sprite_frames and _overlay_sprite.sprite_frames.has_animation(anim_name):
				_overlay_sprite.visible = true
				_overlay_sprite.animation = anim_name
				_overlay_sprite.play()
				shown = true
			break

	if not shown:
		_overlay_sprite.visible = false
