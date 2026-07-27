extends Resource
class_name ClassVisuals
## Her class için 4 yönlü sprite görselleri (front/back/left/right).
## Ayakta durma (idle), yürüme (walk), saldırı (attack) animasyonları.
## Yürüme: 4 yönlü tileset; Saldırı: tek yön (front).

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

## Spritesheet satır sırası: 0=back(yukarı), 1=right(sağ), 2=front(aşağı), 3=left(sol)
const DIR_NAMES: Array[String] = ["back", "right", "front", "left"]

## Animasyon frame süreleri (saniye cinsinden) - yavaş ve görünür
const WALK_SPEED: float = 0.30
const IDLE_SPEED: float = 0.40
const ATTACK_SPEED: float = 0.22

# ---------------------------------------------------------------------------

static func apply_class_visuals(animated_sprite: AnimatedSprite2D, class_id: String) -> void:
	## 4 yönlü walk + idle + attack animasyonlarını yükler.
	if not animated_sprite:
		return
	var cfg: Dictionary = CLASS_CONFIG.get(class_id, {}) as Dictionary
	if cfg.is_empty():
		return

	var frames := SpriteFrames.new()
	var ts_cfg: Dictionary = cfg.get("tileset_4dir", {})

	# 4 yönlü YÜRÜME (walk_front, walk_back, walk_left, walk_right)
	_load_4dir_walk(frames, ts_cfg)

	# 4 yönlü IDLE (her yönün ilk karesi)
	_load_4dir_idle(frames, ts_cfg)

	# 4 yönlü ATTACK (tek spritesheet tüm yönlere kopyalanır)
	var atk_cfg: Dictionary = cfg.get("attack", {})
	_load_4dir_attack(frames, atk_cfg)

	animated_sprite.sprite_frames = frames
	animated_sprite.animation = "idle_front"
	animated_sprite.play()

# ---------------------------------------------------------------------------

static func _load_4dir_walk(frames: SpriteFrames, ts_cfg: Dictionary) -> void:
	## Tileset'ın 4 satırından (front/back/left/right) walk animasyonlarını yükler.
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
	## 4 yönlü yürümenin ilk karesini idle olarak kullanır.
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
		at.region = Rect2(0, dir_idx * fh, fw, fh)  # İlk kare (col=0)
		frames.add_frame(aname, at, IDLE_SPEED)

static func _load_4dir_attack(frames: SpriteFrames, atk_cfg: Dictionary) -> void:
	## Attack spritesheet'ini yükler, tüm yönlere aynı front spritesheet'ini kopyalar.
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
	return true  # 4 yönlü sistemde kullanılmıyor

static func get_class_icon(class_id: String) -> Texture2D:
	var cfg: Dictionary = CLASS_CONFIG.get(class_id, {}) as Dictionary
	return _load_texture(cfg.get("icon", ""))

## Yön index'leri (spritesheet satır sırasıyla eşleşir)
## 0=BACK, 1=RIGHT, 2=FRONT, 3=LEFT
enum Dir { BACK = 0, RIGHT = 1, FRONT = 2, LEFT = 3 }
