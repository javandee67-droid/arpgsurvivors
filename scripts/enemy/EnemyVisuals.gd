extends Resource
class_name EnemyVisuals
## Her düşman tipi için 4 yönlü yürüme, durma (idle) ve saldırı animasyonları.
## Yürüme: 4 yönlü spritesheet (4 satır × 4 sütun, 48×48 frame)
## Saldırı: 4×4 grid spritesheet (64×64 frame)

const ENEMY_DATA: Dictionary = {
	"rat":            {"walk": "res://assets/generated/enemy_rat_walk.png",             "attack": "res://assets/generated/enemy_rat_attack.png"},
	"bat":            {"walk": "res://assets/generated/enemy_bat_walk.png",             "attack": "res://assets/generated/enemy_bat_attack.png"},
	"slime":          {"walk": "res://assets/generated/enemy_slime_walk.png",           "attack": "res://assets/generated/enemy_slime_attack.png"},
	"spider":         {"walk": "res://assets/generated/enemy_spider_walk.png",           "attack": "res://assets/generated/enemy_spider_attack.png"},
	"skeleton":       {"walk": "res://assets/generated/enemy_skeleton_walk.png",        "attack": "res://assets/generated/enemy_skeleton_attack.png"},
	"zombie":         {"walk": "res://assets/generated/enemy_zombie_walk.png",          "attack": "res://assets/generated/enemy_zombie_attack.png"},
	"goblin":         {"walk": "res://assets/generated/enemy_goblin_walk.png",          "attack": "res://assets/generated/enemy_goblin_attack.png"},
	"wolf":           {"walk": "res://assets/generated/enemy_wolf_walk.png",            "attack": "res://assets/generated/enemy_wolf_attack.png"},
	"orc":            {"walk": "res://assets/generated/enemy_orc_walk.png",             "attack": "res://assets/generated/enemy_orc_attack_2.png", "attack_fw": 48, "attack_fh": 48},
	"knight":         {"walk": "res://assets/generated/enemy_knight_walk.png",           "attack": "res://assets/generated/enemy_knight_attack.png"},
	"shaman":         {"walk": "res://assets/generated/enemy_shaman_walk.png",          "attack": "res://assets/generated/enemy_shaman_attack.png"},
	"scorpion":       {"walk": "res://assets/generated/enemy_scorpion_walk.png",        "attack": "res://assets/generated/enemy_scorpion_attack.png"},
	"wraith":         {"walk": "res://assets/generated/enemy_wraith_walk.png",          "attack": "res://assets/generated/enemy_wraith_attack.png"},
	"troll":          {"walk": "res://assets/generated/enemy_troll_walk.png",           "attack": "res://assets/generated/enemy_troll_attack.png"},
	"imp":            {"walk": "res://assets/generated/enemy_imp_walk.png",             "attack": "res://assets/generated/enemy_imp_attack.png"},
	"serpent":        {"walk": "res://assets/generated/enemy_serpent_walk.png",         "attack": "res://assets/generated/enemy_serpent_attack.png"},
	"fire_elemental": {"walk": "res://assets/generated/enemy_fire_elemental_walk.png",  "attack": "res://assets/generated/enemy_fire_elemental_attack.png"},
	"ogre_boss":      {"walk": "res://assets/generated/enemy_ogre_boss_walk.png",      "attack": "res://assets/generated/enemy_ogre_boss_attack.png"},
	"necromancer":    {"walk": "res://assets/generated/enemy_necromancer_walk.png",    "attack": "res://assets/generated/enemy_necromancer_attack.png"},
	"hydra":          {"walk": "res://assets/generated/enemy_hydra_walk.png",           "attack": "res://assets/generated/enemy_hydra_attack.png"},
	"demon_lord":     {"walk": "res://assets/generated/enemy_demon_lord_walk.png",     "attack": "res://assets/generated/enemy_demon_lord_attack.png"},
	
	# ===== NEW TIER 1 =====
	"mole":           {"walk": "res://assets/generated/enemy_mole_walk.png",           "attack": "res://assets/generated/enemy_mole_attack.png"},
	"frog":           {"walk": "res://assets/generated/enemy_frog_walk.png",           "attack": "res://assets/generated/enemy_frog_attack.png"},
	"snail":          {"walk": "res://assets/generated/enemy_snail_walk.png",          "attack": "res://assets/generated/enemy_snail_attack.png"},
	"rabbit":         {"walk": "res://assets/generated/enemy_rabbit_walk.png",         "attack": "res://assets/generated/enemy_rabbit_attack.png"},
	"crow":           {"walk": "res://assets/generated/enemy_crow_walk.png",           "attack": "res://assets/generated/enemy_crow_attack.png"},
	"bee":            {"walk": "res://assets/generated/enemy_bee_walk.png",            "attack": "res://assets/generated/enemy_bee_attack.png"},
	"worm":           {"walk": "res://assets/generated/enemy_worm_walk.png",           "attack": "res://assets/generated/enemy_worm_attack.png"},
	"mushroom":       {"walk": "res://assets/generated/enemy_mushroom_walk.png",       "attack": "res://assets/generated/enemy_mushroom_attack.png"},
	
	# ===== NEW TIER 2 =====
	"bandit":         {"walk": "res://assets/generated/enemy_bandit_walk.png",         "attack": "res://assets/generated/enemy_bandit_attack.png"},
	"cultist":        {"walk": "res://assets/generated/enemy_cultist_walk.png",        "attack": "res://assets/generated/enemy_cultist_attack.png"},
	"ghoul":          {"walk": "res://assets/generated/enemy_ghoul_walk.png",          "attack": "res://assets/generated/enemy_ghoul_attack.png"},
	"wasp":           {"walk": "res://assets/generated/enemy_wasp_walk.png",           "attack": "res://assets/generated/enemy_wasp_attack.png"},
	"boar":           {"walk": "res://assets/generated/enemy_boar_walk.png",           "attack": "res://assets/generated/enemy_boar_attack.png"},
	"turtle":         {"walk": "res://assets/generated/enemy_turtle_walk.png",         "attack": "res://assets/generated/enemy_turtle_attack.png"},
	"mummy":          {"walk": "res://assets/generated/enemy_mummy_walk.png",          "attack": "res://assets/generated/enemy_mummy_attack.png"},
	"salamander":     {"walk": "res://assets/generated/enemy_salamander_walk.png",     "attack": "res://assets/generated/enemy_salamander_attack.png"},
	
	# ===== NEW TIER 3 =====
	"minotaur":       {"walk": "res://assets/generated/enemy_minotaur_walk.png",       "attack": "res://assets/generated/enemy_minotaur_attack.png"},
	"harpy":          {"walk": "res://assets/generated/enemy_harpy_walk.png",          "attack": "res://assets/generated/enemy_harpy_attack.png"},
	"golem":          {"walk": "res://assets/generated/enemy_golem_walk.png",          "attack": "res://assets/generated/enemy_golem_attack.png"},
	"lich":           {"walk": "res://assets/generated/enemy_lich_walk.png",           "attack": "res://assets/generated/enemy_lich_attack.png"},
	"basilisk":       {"walk": "res://assets/generated/enemy_basilisk_walk.png",       "attack": "res://assets/generated/enemy_basilisk_attack.png"},
	"centaur":        {"walk": "res://assets/generated/enemy_centaur_walk.png",        "attack": "res://assets/generated/enemy_centaur_attack.png"},
	"werewolf":       {"walk": "res://assets/generated/enemy_werewolf_walk.png",       "attack": "res://assets/generated/enemy_werewolf_attack.png"},
	"chimera":        {"walk": "res://assets/generated/enemy_chimera_walk.png",        "attack": "res://assets/generated/enemy_chimera_attack.png"},
	"treant":         {"walk": "res://assets/generated/enemy_treant_walk.png",         "attack": "res://assets/generated/enemy_treant_attack.png"},
	"naga":           {"walk": "res://assets/generated/enemy_naga_walk.png",           "attack": "res://assets/generated/enemy_naga_attack.png"},
	"gargoyle":       {"walk": "res://assets/generated/enemy_gargoyle_walk.png",       "attack": "res://assets/generated/enemy_gargoyle_attack.png"},
	"crab":           {"walk": "res://assets/generated/enemy_crab_walk.png",           "attack": "res://assets/generated/enemy_crab_attack.png"},
	"scarab":         {"walk": "res://assets/generated/enemy_scarab_walk.png",         "attack": "res://assets/generated/enemy_scarab_attack.png"},
	"mandrake":       {"walk": "res://assets/generated/enemy_mandrake_walk.png",       "attack": "res://assets/generated/enemy_mandrake_attack.png"},
	
	# ===== NEW TIER 4 =====
	"drake":          {"walk": "res://assets/generated/enemy_drake_walk.png",          "attack": "res://assets/generated/enemy_drake_attack.png"},
	"beholder":       {"walk": "res://assets/generated/enemy_beholder_walk.png",       "attack": "res://assets/generated/enemy_beholder_attack.png"},
	"giant":          {"walk": "res://assets/generated/enemy_giant_walk.png",          "attack": "res://assets/generated/enemy_giant_attack.png"},
	"succubus":       {"walk": "res://assets/generated/enemy_succubus_walk.png",       "attack": "res://assets/generated/enemy_succubus_attack.png"},
	"phantom":        {"walk": "res://assets/generated/enemy_phantom_walk.png",        "attack": "res://assets/generated/enemy_phantom_attack.png"},
	"gorgon":         {"walk": "res://assets/generated/enemy_gorgon_walk.png",         "attack": "res://assets/generated/enemy_gorgon_attack.png"},
	"phoenix":        {"walk": "res://assets/generated/enemy_phoenix_walk.png",        "attack": "res://assets/generated/enemy_phoenix_attack.png"},
	"manticore":      {"walk": "res://assets/generated/enemy_manticore_walk.png",      "attack": "res://assets/generated/enemy_manticore_attack.png"},
	"wyvern":         {"walk": "res://assets/generated/enemy_wyvern_walk.png",         "attack": "res://assets/generated/enemy_wyvern_attack.png"},
	"siren":          {"walk": "res://assets/generated/enemy_siren_walk.png",          "attack": "res://assets/generated/enemy_siren_attack.png"},
	"shadow":         {"walk": "res://assets/generated/enemy_shadow_walk.png",         "attack": "res://assets/generated/enemy_shadow_attack.png"},
	"banshee":        {"walk": "res://assets/generated/enemy_banshee_walk.png",        "attack": "res://assets/generated/enemy_banshee_attack.png"},
	
	# ===== NEW TIER 5: Boss =====
	"dragon":         {"walk": "res://assets/generated/enemy_dragon_walk.png",         "attack": "res://assets/generated/enemy_dragon_attack.png"},
	"lich_king":      {"walk": "res://assets/generated/enemy_lich_king_walk.png",      "attack": "res://assets/generated/enemy_lich_king_attack.png"},
	"leviathan":      {"walk": "res://assets/generated/enemy_leviathan_walk.png",      "attack": "res://assets/generated/enemy_leviathan_attack.png"},
	"titan":          {"walk": "res://assets/generated/enemy_titan_walk.png",          "attack": "res://assets/generated/enemy_titan_attack.png"},
	"archdemon":      {"walk": "res://assets/generated/enemy_archdemon_walk.png",      "attack": "res://assets/generated/enemy_archdemon_attack.png"},
	"sphinx":         {"walk": "res://assets/generated/enemy_sphinx_walk.png",         "attack": "res://assets/generated/enemy_sphinx_attack.png"},
	"kraken":         {"walk": "res://assets/generated/enemy_kraken_walk.png",         "attack": "res://assets/generated/enemy_kraken_attack.png"},
	"vampire_lord":   {"walk": "res://assets/generated/enemy_vampire_lord_walk.png",   "attack": "res://assets/generated/enemy_vampire_lord_attack.png"},
}

const DIR_NAMES: Array[String] = ["back", "right", "front", "left"]

const WALK_FRAME_W: int = 48
const WALK_FRAME_H: int = 48
const WALK_COLS: int = 4
const WALK_SPEED: float = 0.55

const ATTACK_FRAME_W: int = 64
const ATTACK_FRAME_H: int = 64
const ATTACK_COLS: int = 4

# Boyut ve offset ayarlari: scale > 1 = normalden buyuk, scale < 1 = kucuk
# offset sprite'in goruntusunu kaydirarak merkezleme hatasini duzeltir
const SIZE_DATA: Dictionary = {
	# ===== TINY (ölçek 0.7) =====
	"snail":    {"scale": 0.7},
	"worm":     {"scale": 0.7},
	"frog":     {"scale": 0.7},
	"bee":      {"scale": 0.7},
	"wasp":     {"scale": 0.7},
	
	# ===== SMALL (ölçek 0.85) =====
	"rat":      {"scale": 0.85},
	"bat":      {"scale": 0.85},
	"spider":   {"scale": 0.85},
	"mole":     {"scale": 0.85},
	"rabbit":   {"scale": 0.85},
	"scarab":   {"scale": 0.85},
	"imp":      {"scale": 0.85},
	"crow":     {"scale": 0.85},
	"mushroom": {"scale": 0.85},
	
	# ===== MEDIUM (ölçek 1.0 — varsayilan) =====
	"slime":         {"scale": 1.0},
	"skeleton":      {"scale": 1.0},
	"zombie":        {"scale": 1.0},
	"goblin":        {"scale": 1.0},
	"wolf":          {"scale": 1.0},
	"bandit":        {"scale": 1.0},
	"cultist":       {"scale": 1.0},
	"ghoul":         {"scale": 1.0},
	"boar":          {"scale": 1.0},
	"turtle":        {"scale": 1.0},
	"mummy":         {"scale": 1.0},
	"salamander":    {"scale": 1.0},
	"serpent":       {"scale": 1.0},
	"harpy":         {"scale": 1.0},
	"centaur":       {"scale": 1.0},
	"werewolf":      {"scale": 1.0},
	"crab":          {"scale": 1.0},
	"naga":          {"scale": 1.0},
	"mandrake":      {"scale": 1.0},
	"phantom":       {"scale": 1.0},
	"succubus":      {"scale": 1.0},
	"shadow":        {"scale": 1.0},
	"banshee":       {"scale": 1.0},
	"siren":         {"scale": 1.0},
	"gorgon":        {"scale": 1.0},
	"manticore":     {"scale": 1.0},
	"basilisk":      {"scale": 1.0},
	"lich":          {"scale": 1.0},
	"scorpion":      {"scale": 1.0},
	"wraith":        {"scale": 1.0},
	"shaman":        {"scale": 1.0},
	"knight":        {"scale": 1.0},
	"orc":           {"scale": 1.0},
	"fire_elemental": {"scale": 1.0},
	
	# ===== LARGE (ölçek 1.4) =====
	"minotaur":  {"scale": 1.4},
	"golem":     {"scale": 1.4},
	"treant":    {"scale": 1.4},
	"gargoyle":  {"scale": 1.4},
	"ogre_boss": {"scale": 1.4},
	"troll":     {"scale": 1.4},
	"drake":     {"scale": 1.4},
	"beholder":  {"scale": 1.4},
	"giant":     {"scale": 1.7},
	"wyvern":    {"scale": 1.4},
	"chimera":   {"scale": 1.4},
	"phoenix":   {"scale": 1.4},
	"necromancer": {"scale": 1.3},
	
	# ===== HUGE (ölçek 2.0 — bosslar) =====
	"dragon":       {"scale": 2.2},
	"lich_king":    {"scale": 1.8},
	"leviathan":    {"scale": 2.5},
	"titan":        {"scale": 2.5},
	"archdemon":    {"scale": 2.2},
	"sphinx":       {"scale": 2.0},
	"kraken":       {"scale": 2.5},
	"vampire_lord": {"scale": 1.8},
	"hydra":        {"scale": 2.0},
	"demon_lord":   {"scale": 2.0},
}
const ATTACK_SPEED: float = 0.30


static func _try_load_tex(path: String) -> Texture2D:
	if path == "":
		return null
	if ResourceLoader.exists(path):
		# Import edilmiş texture'ı yükle, ham Image'e dönüştür, ImageTexture yap
		# Bu export'ta da çalışır ve alpha her zaman korunur
		var tex: Texture2D = load(path)
		var img := tex.get_image()
		if img and img.get_size().x > 0:
			return ImageTexture.create_from_image(img)
		return tex
	# Fallback: direkt PNG oku (sadece editor)
	var img2 := Image.new()
	if img2.load(path) == OK and img2.get_size().x > 0:
		return ImageTexture.create_from_image(img2)
	return null


static func apply_visuals(anim_sprite: AnimatedSprite2D, enemy_id: String) -> void:
	if not anim_sprite:
		return
	var cfg: Dictionary = ENEMY_DATA.get(enemy_id, {})
	if cfg.is_empty():
		cfg = ENEMY_DATA.get("orc", {})
	
	var frames := SpriteFrames.new()
	
	# 4 yönlü yürüme + idle
	var walk_tex := _try_load_tex(cfg.get("walk", ""))
	if walk_tex:
		_load_4dir_walk(frames, walk_tex)
		_load_4dir_idle(frames, walk_tex)
	
	# Saldırı animasyonu
	var atk_tex := _try_load_tex(cfg.get("attack", ""))
	if atk_tex:
		var afw: int = cfg.get("attack_fw", ATTACK_FRAME_W)
		var afh: int = cfg.get("attack_fh", ATTACK_FRAME_H)
		_load_attack(frames, atk_tex, afw, afh)
	
	# Hiçbir animasyon yoksa fallback olarak tek kare ekle
	if not frames.has_animation("idle_front"):
		_create_fallback_animation(frames, enemy_id)
	
	anim_sprite.sprite_frames = frames
	if frames.has_animation("idle_front"):
		anim_sprite.animation = "idle_front"
	else:
		var names: Array[String] = frames.get_animation_names()
		if names.size() > 0:
			anim_sprite.animation = names[0]
	
	# Boyut olcegi uygula
	var size_info: Dictionary = SIZE_DATA.get(enemy_id, {})
	var scale_val: float = size_info.get("scale", 1.0)
	anim_sprite.scale = Vector2(scale_val, scale_val)
	
	# Gorsel merkezleme duzeltmesi (sola sıkışmış sprite'lar icin)
	if size_info.has("offset_x") or size_info.has("offset_y"):
		var ox: float = size_info.get("offset_x", 0.0)
		var oy: float = size_info.get("offset_y", 0.0)
		anim_sprite.offset = Vector2(ox, oy)
	
	anim_sprite.play()


static func _load_4dir_walk(frames: SpriteFrames, tex: Texture2D) -> void:
	if not tex:
		return
	for dir_idx in range(4):
		var aname: String = "walk_%s" % DIR_NAMES[dir_idx]
		frames.add_animation(aname)
		frames.set_animation_loop(aname, true)
		for col in range(WALK_COLS):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * WALK_FRAME_W, dir_idx * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)
			frames.add_frame(aname, at, WALK_SPEED)


static func _load_4dir_idle(frames: SpriteFrames, tex: Texture2D) -> void:
	if not tex:
		return
	for dir_idx in range(4):
		var aname: String = "idle_%s" % DIR_NAMES[dir_idx]
		frames.add_animation(aname)
		frames.set_animation_loop(aname, true)
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, dir_idx * WALK_FRAME_H, WALK_FRAME_W, WALK_FRAME_H)
		frames.add_frame(aname, at, 0.5)


static func _load_attack(frames: SpriteFrames, tex: Texture2D, fw: int = ATTACK_FRAME_W, fh: int = ATTACK_FRAME_H) -> void:
	if not tex:
		return
	
	# Her yön kendi satırındaki kareleri kullanır (walk/idle ile aynı sistem)
	var tex_w: int = tex.get_width()
	var tex_h: int = tex.get_height()
	var total_cols: int = maxi(1, int(tex_w / float(fw)))
	var total_rows: int = maxi(1, int(tex_h / float(fh)))
	
	for dir_idx in range(mini(4, total_rows)):
		var aname: String = "attack_%s" % DIR_NAMES[dir_idx]
		frames.add_animation(aname)
		frames.set_animation_loop(aname, false)
		for col in range(total_cols):
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(col * fw, dir_idx * fh, fw, fh)
			frames.add_frame(aname, at, ATTACK_SPEED)


# Texture yüklenemezse yedek animasyon (saydam kare — background göstermemek için)
static func _create_fallback_animation(frames: SpriteFrames, _id: String) -> void:
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 0.0))  # Tam saydam (gri değil!)
	var tex := ImageTexture.create_from_image(img)
	for dn in DIR_NAMES:
		var aname: String = "walk_%s" % dn
		frames.add_animation(aname)
		frames.set_animation_loop(aname, true)
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(0, 0, 48, 48)
		frames.add_frame(aname, at, 0.3)
		aname = "idle_%s" % dn
		frames.add_animation(aname)
		frames.set_animation_loop(aname, true)
		var at2 := AtlasTexture.new()
		at2.atlas = tex
		at2.region = Rect2(0, 0, 48, 48)
		frames.add_frame(aname, at2, 0.5)
