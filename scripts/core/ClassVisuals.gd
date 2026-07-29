extends Resource
class_name ClassVisuals
## Her class icin 4 yonlu sprite gorselleri (front/back/left/right).
## Ayakta durma (idle), yurume (walk), saldiri (attack) animasyonlari.
## Yurume: 4 yonlu tileset; Saldiri: tek yon (front).

const CLASS_CONFIG: Dictionary = {
	"warrior": {
		"icon": "res://assets/generated/icon_sword_frame_0.png",
		"tileset_4dir": {
			"path": "res://assets/generated/knight_4dir_walk.png",
			"fw": 48, "fh": 48, "cols": 4, "rows": 4
		},
		"attack": { "path": "res://assets/generated/knight_attack_16f.png", "fw": 64, "fh": 64, "cols": 4, "rows": 4, "count": 16 },
	},
	"mage": {
		"icon": "res://assets/generated/icon_frostbolt_frame_0.png",
		"tileset_4dir": {
			"path": "res://assets/generated/mage_4dir_walk.png",
			"fw": 48, "fh": 48, "cols": 4, "rows": 4
		},
		"attack": { "path": "res://assets/generated/mage_attack_16f.png", "fw": 64, "fh": 64, "cols": 4, "rows": 4, "count": 16 },
	},
	"rogue": {
		"icon": "res://assets/generated/icon_slice_frame_0.png",
		"tileset_4dir": {
			"path": "res://assets/generated/rogue_4dir_walk.png",
			"fw": 48, "fh": 48, "cols": 4, "rows": 4
		},
		"attack": { "path": "res://assets/generated/rogue_attack_16f.png", "fw": 64, "fh": 64, "cols": 4, "rows": 4, "count": 16 },
	},
}

## Spritesheet satir sirasi: 0=back(yukari), 1=right(sag), 2=front(asagi), 3=left(sol)
const DIR_NAMES: Array[String] = ["back", "right", "front", "left"]

## Animasyon frame sureleri (saniye cinsinden)
const WALK_SPEED: float = 0.30
const IDLE_SPEED: float = 0.40
const ATTACK_SPEED: float = 0.22

# ---------------------------------------------------------------------------

static func apply_class_visuals(animated_sprite: AnimatedSprite2D, class_id: String) -> void:
	## 4 yonlu walk + idle + attack animasyonlarini yukler.
	if not animated_sprite:
		return
	var cfg: Dictionary = CLASS_CONFIG.get(class_id, {}) as Dictionary
	if cfg.is_empty():
		return
	var frames := SpriteFrames.new()

	# Spritesheet tileset'indan yukle
	var ts_cfg: Dictionary = cfg.get("tileset_4dir", {})
	_load_4dir_walk(frames, ts_cfg)
	_load_4dir_idle(frames, ts_cfg)

	# 4 yonlu ATTACK
	var atk_cfg: Dictionary = cfg.get("attack", {})
	_load_4dir_attack(frames, atk_cfg)

	animated_sprite.sprite_frames = frames
	animated_sprite.animation = "idle_front"
	animated_sprite.play()

# ---------------------------------------------------------------------------

static func _load_4dir_walk(frames: SpriteFrames, ts_cfg: Dictionary) -> void:
	## Tileset'in 4 satirindan walk animasyonlarini yukler.
	if ts_cfg.is_empty():
		return
	var tex: Texture2D = _load_texture(ts_cfg.get("path", ""))
	if not tex:
		return
	var fw: int = ts_cfg.get("fw", 48)
	var fh: int = ts_cfg.get("fh", 48)
	var cols: int = ts_cfg.get("cols", 4)

	for dir_idx in range(4):
		var aname: String = "walk_" + DIR_NAMES[dir_idx]
		frames.add_animation(aname)
		frames.set_animation_loop(aname, true)
		for col in range(cols):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * fw, dir_idx * fh, fw, fh)
			frames.add_frame(aname, at, WALK_SPEED)

static func _load_4dir_idle(frames: SpriteFrames, ts_cfg: Dictionary) -> void:
	## 4 yonlu yurumenin ilk karesini idle olarak kullanir.
	if ts_cfg.is_empty():
		return
	var tex: Texture2D = _load_texture(ts_cfg.get("path", ""))
	if not tex:
		return
	var fw: int = ts_cfg.get("fw", 48)
	var fh: int = ts_cfg.get("fh", 48)

	for dir_idx in range(4):
		var aname: String = "idle_" + DIR_NAMES[dir_idx]
		frames.add_animation(aname)
		frames.set_animation_loop(aname, true)
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, dir_idx * fh, fw, fh)
		frames.add_frame(aname, at, IDLE_SPEED)

static func _load_4dir_attack(frames: SpriteFrames, atk_cfg: Dictionary) -> void:
	## Attack spritesheet'ini yukler, tum yonlere ayni front spritesheet'ini kopyalar.
	var tex: Texture2D = _load_texture(atk_cfg.get("path", ""))
	if not tex:
		return
	var fw: int = atk_cfg.get("fw", 64)
	var fh: int = atk_cfg.get("fh", 64)
	var cols: int = atk_cfg.get("cols", 4)
	var count: int = atk_cfg.get("count", 8)

	var aname_front: String = "attack_front"
	frames.add_animation(aname_front)
	frames.set_animation_loop(aname_front, false)
	for i in range(count):
		var col: int = i % cols
		var row: int = i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		frames.add_frame(aname_front, at, ATTACK_SPEED)

	for d in ["back", "left", "right"]:
		var aname: String = "attack_" + d
		frames.add_animation(aname)
		frames.set_animation_loop(aname, false)
		for i in range(frames.get_frame_count(aname_front)):
			var tex2: Texture2D = frames.get_frame_texture(aname_front, i)
			var dur: float = frames.get_frame_duration(aname_front, i)
			frames.add_frame(aname, tex2, dur)

# ---------------------------------------------------------------------------

static func _load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path)

static func get_sprite_faces_right(_class_id: String) -> bool:
	return true

static func get_class_icon(class_id: String) -> Texture2D:
	var cfg: Dictionary = CLASS_CONFIG.get(class_id, {}) as Dictionary
	return _load_texture(cfg.get("icon", ""))

## Yon index'leri (spritesheet satir sirasiyla eslesir)
## 0=BACK, 1=RIGHT, 2=FRONT, 3=LEFT
enum Dir { BACK = 0, RIGHT = 1, FRONT = 2, LEFT = 3 }
