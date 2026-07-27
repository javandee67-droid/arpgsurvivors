extends Node2D
## VS (Vampire Survivors) tarzi ana oyun kontrolcusu.
## Sonsuz harita, surekli dusman spawni, seviye atlayinca skill secimi.

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

# VS game controller
@onready var map_generator: MapGenerator = $MapGenerator

var player: Node = null
var _game_camera: Camera2D = null

# VS sistemi degiskenleri
var _kill_count: int = 0
var _difficulty_tier: int = 1
var _next_difficulty_at: int = 100
var _game_time: float = 0.0
var _time_difficulty_tier: int = 1  # Her 120sn'de bir artar
var _next_time_difficulty_at: float = 120.0
var _spawn_timer: float = 0.0
var _spawn_interval: float = 2.0
var _enemies_per_spawn: int = 6
var _max_enemies: int = 150
var _game_over: bool = false
var _player_skills: Array[String] = []
var _passive_nodes_owned: Array[String] = []
var _skill_tree_instance: Control = null
var _wave: int = 1
var _enemies_killed_in_wave: int = 0
const ENEMIES_PER_WAVE: int = 20

# Boss sistemi
var _boss_active: bool = false
var _last_boss: Node = null
const BOSS_POOL: Array[String] = ["ogre_boss", "necromancer", "demon_lord", "hydra"]

func _ready() -> void:
	call_deferred("_init_game")

func _init_game() -> void:
	_kill_count = 0
	_difficulty_tier = 1
	_next_difficulty_at = 100
	_game_time = 0.0
	_spawn_timer = 0.0
	_game_over = false
	_player_skills = []
	_passive_nodes_owned = []
	_time_difficulty_tier = 1
	_next_time_difficulty_at = 120.0
	_boss_active = false
	_last_boss = null
	_wave = 1
	_enemies_killed_in_wave = 0
	
	# Haritayi 2 kat buyut
	_generate_large_map()
	
	# UI katmanlarini olustur
	_create_world_ui()
	
	# Oyuncuyu olustur (haritanin ortasinda)
	_spawn_player()
	
	if player:
		player.stats.strength = 10
		player.stats.dexterity = 10
		player.stats.intelligence = 10
		player.stats.stat_points = 20
		player.stats.passive_points = 5  # Başlangıç pasif puanı
		player.stats.recalculate()
		player.set_class("warrior")
		player.level_system.leveled_up.connect(_on_player_leveled_up)
		
		# Pasif Ağaç panelini oyuncuya bağla
		_setup_passive_tree_player()
		
		# Sadece normal attack skill'ini ekle
		var na_path := "res://data/skills/normal_attack.tres"
		if ResourceLoader.exists(na_path):
			var na_skill: SkillData = load(na_path)
			if na_skill:
				player.skill_setups[na_path] = {"skill": na_skill, "supports": [null, null, null, null]}
				player._rebuild_skill_instance()
				_player_skills.append(na_path)
				player._skill_levels[na_path] = 1  # Baslangic seviyesi
		
		# Normal attack harici baslangic skill'i yok
		# Skill'ler level atlayinca Main._show_skill_selection() ile kazanilir
		
		# Hotbar'a sadece normal attack koy
		player.hotbar.resize(20)
		for i in range(20):
			player.hotbar[i] = ""
		player.hotbar[0] = na_path
	
	_setup_floating_damage()

func _generate_large_map() -> void:
	for ch in get_children():
		if ch == player or ch == map_generator:
			continue
		if ch is CanvasLayer:
			continue
		ch.queue_free()
	
	if map_generator:
		map_generator.map_width = 160
		map_generator.map_height = 120
		map_generator.generate()

func _create_world_ui() -> void:
	if not get_tree().root.get_node_or_null("WorldUI"):
		var wui := CanvasLayer.new()
		wui.name = "WorldUI"
		wui.layer = 10
		get_tree().root.add_child(wui)
		
		# DPS Meter ekle
		var dps := preload("res://scripts/ui/DPSMeter.gd").new()
		wui.add_child(dps)
		
		# Pasif Ağaç paneli ve butonu ekle
		_setup_passive_tree_ui(wui)

func _setup_passive_tree_ui(parent: CanvasLayer) -> void:
	# Pasif Ağaç paneli (başlangıçta gizli)
	var passive_panel := PassiveTreePanel.new()
	passive_panel.name = "PassiveTreePanel"
	passive_panel.visible = false
	parent.add_child(passive_panel)
	
	# Pasif Ağaç butonu (sağ üst köşe)
	var btn := Button.new()
	btn.name = "PassiveTreeButton"
	btn.text = "⚡ PASİF AĞAÇ"
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.position = Vector2(-160, 10)
	btn.size = Vector2(150, 40)
	btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(_toggle_passive_tree)
	parent.add_child(btn)

var _passive_tree_visible: bool = false

func _toggle_passive_tree() -> void:
	var wui := get_tree().root.get_node_or_null("WorldUI") as CanvasLayer
	if not wui:
		return
	
	var panel: Control = wui.get_node_or_null("PassiveTreePanel")
	var btn: Button = wui.get_node_or_null("PassiveTreeButton") as Button
	
	if not panel:
		return
	
	_passive_tree_visible = not _passive_tree_visible
	panel.visible = _passive_tree_visible
	
	# Oyunu duraklat pasif ağaç açıkken
	get_tree().paused = _passive_tree_visible
	
	if btn:
		if _passive_tree_visible:
			btn.text = "✕ KAPAT"
			btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		else:
			btn.text = "⚡ PASİF AĞAÇ"
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

func _setup_passive_tree_player() -> void:
	"""Pasif Ağaç panelini oyuncunun statlarına bağla."""
	var wui := get_tree().root.get_node_or_null("WorldUI") as CanvasLayer
	if not wui or not player:
		return
	
	var panel: PassiveTreePanel = wui.get_node_or_null("PassiveTreePanel") as PassiveTreePanel
	if not panel:
		return
	
	# Oyuncunun pasif puanlarını panele ver
	panel.passive_tree.set_passive_points(player.stats.passive_points)
	
	# Pasif node açıldığında stat değişikliklerini uygula
	panel.passive_tree.passive_unlocked.connect(_on_passive_node_unlocked)

func _on_passive_node_unlocked(node_id: String) -> void:
	"""Bir pasif node açıldığında oyuncunun statlarına uygula."""
	if not player or not player.stats:
		return
	
	var panel: PassiveTreePanel = get_tree().root.get_node_or_null("WorldUI/PassiveTreePanel") as PassiveTreePanel
	if not panel:
		return
	
	var node_info: Dictionary = panel.passive_tree.get_node_info(node_id)
	if node_info.is_empty():
		return
	
	# Açılan node'un istatistiklerini oyuncuya uygula
	for effect in node_info.get("effects", []):
		var stat: String = effect.get("stat", "")
		var value: float = effect.get("value", 0.0)
		var eff_type: String = effect.get("type", "")
		
		match stat:
			"all_damage":
				player.stats.all_damage_increased += value
			"physical_damage_increased":
				player.stats.physical_damage_increased += value
			"fire_damage_increased":
				player.stats.fire_damage_increased += value
			"cold_damage_increased":
				player.stats.cold_damage_increased += value
			"lightning_damage_increased":
				player.stats.lightning_damage_increased += value
			"max_life":
				player.stats.base_life += value
			"life_regen_per_second":
				player.stats.life_regen_per_second += value
			"armour":
				player.stats.base_armour += value
			"evasion":
				player.stats.base_evasion += value
			"all_resistance":
				player.stats.base_fire_resistance += value
				player.stats.base_cold_resistance += value
				player.stats.base_lightning_resistance += value
				player.stats.base_chaos_resistance += value
			"attack_speed":
				player.stats.base_attack_speed += value / 100.0
			"cast_speed":
				player.stats.base_cast_speed += value / 100.0
			"movement_speed":
				player.stats.base_movement_speed += value / 100.0
			"cooldown_recovery":
				player.stats.cooldown_recovery_increased += value
			"critical_chance":
				player.stats.base_critical_chance += value
			"critical_multiplier":
				player.stats.base_critical_multiplier += value
			"accuracy":
				player.stats.base_accuracy += value
			"max_mana":
				player.stats.base_mana += value
			"mana_regen_per_second":
				player.stats.base_mana_regen += value
			"pickup_radius":
				player.stats.pickup_radius += value
			"gold_find":
				player.stats.gold_find += value
			"experience_gain":
				player.stats.experience_gain += value
			"luck":
				player.stats.luck += value
			"chain_count":
				player.stats.chain_count += int(value)
			"extra_projectiles":
				player.stats.extra_projectiles += int(value)
			"area_of_effect":
				player.stats.area_of_effect += value
		
		# İstatistiği güncelle
		player.stats.recalculate()
		
		# Oyuncunun pasif puanını güncelle
		player.stats.passive_points = panel.passive_tree.get_remaining_points()

func _spawn_player() -> void:
	if not player_scene:
		return
	
	var spawn_pos := _get_center_position()
	
	if player and is_instance_valid(player):
		player.global_position = spawn_pos
		if _game_camera and is_instance_valid(_game_camera):
			_game_camera.global_position = spawn_pos
		return
	
	player = player_scene.instantiate()
	add_child(player)
	player.global_position = spawn_pos
	
	if not _game_camera:
		_game_camera = Camera2D.new()
		_game_camera.name = "GameCamera"
		_game_camera.enabled = true
		_game_camera.zoom = Vector2(1.0, 1.0)
		_game_camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
		_game_camera.limit_enabled = false
		add_child(_game_camera)
		_game_camera.make_current()
	_game_camera.global_position = player.global_position
	
	if player.has_node("Health"):
		player.health.died.connect(_on_player_died)
	
	# _setup_player_light() — PlayerLight kaldirildi

func _get_center_position() -> Vector2:
	return Vector2(80 * 32, 60 * 32)

# PlayerLight kaldirildi — LitPointLight2D Player.gd _ready'de kuruluyor

func _setup_floating_damage() -> void:
	if not get_tree().root.get_node_or_null("FloatingDamage"):
		var fd_instance := CanvasLayer.new()
		fd_instance.set_script(load("res://scripts/ui/FloatingDamage.gd"))
		fd_instance.name = "FloatingDamage"
		get_tree().root.add_child(fd_instance)
	
	if not get_tree().root.get_node_or_null("JuiceManager"):
		var jm := JuiceManager.new()
		jm.name = "JuiceManager"
		get_tree().root.add_child(jm)
		jm.camera = _game_camera
		jm.player = player
		jm.set_process(true)

# ==================== ENEMY SPAWNING ====================

func _process(delta: float) -> void:
	if _game_over or not player or not is_instance_valid(player):
		return
	
	_game_time += delta
	
	# ZAMAN BAZLI ZORLUK: Her 120 saniyede bir tier atla
	if _game_time >= _next_time_difficulty_at:
		_time_difficulty_tier += 1
		_next_time_difficulty_at = (_time_difficulty_tier) * 120.0
		# Sadece time-based tier arttı, kill tier'ı ayrı
		var effective_tier: int = maxi(_difficulty_tier, _time_difficulty_tier)
		if effective_tier > _difficulty_tier:
			_difficulty_tier = effective_tier
			_enemies_per_spawn = mini(6 + _difficulty_tier * 2, 30)
			_spawn_interval = maxf(0.6, 1.5 - _difficulty_tier * 0.04)
			print("VS: Zaman bazli zorluk %d -> %d! (%.0f saniye)" % [_time_difficulty_tier - 1, _time_difficulty_tier, _game_time])
	
	if _game_camera and player:
		_game_camera.global_position = player.global_position
	
	# HUD'da süre kronometresini güncelle
	var hud: HUD = get_node_or_null("CanvasLayer2") as HUD
	if hud:
		hud.set_game_time(_game_time)
	
	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_try_spawn_enemies()

func _try_spawn_enemies() -> void:
	var current_enemies: int = _count_alive_enemies()
	if current_enemies >= _max_enemies:
		return
	
	if not enemy_scene:
		return
	
	var to_spawn: int = mini(_enemies_per_spawn, _max_enemies - current_enemies)
	
	for i in range(to_spawn):
		_spawn_single_enemy()

func _spawn_single_enemy() -> void:
	var spawn_pos := _get_random_edge_position()
	
	var enemy := enemy_scene.instantiate()
	enemy.position = spawn_pos
	add_child(enemy)
	enemy.add_to_group("enemy")  # Ensure enemy is counted
	
	_configure_vs_enemy(enemy)
	
	if not enemy.tree_exited.is_connected(_on_vs_enemy_killed):
		enemy.tree_exited.connect(_on_vs_enemy_killed)

func _get_random_edge_position() -> Vector2:
	var player_pos: Vector2 = player.global_position if player else Vector2(1280, 960)
	
	var angle := randf_range(0.0, TAU)
	var distance := randf_range(400.0, 550.0)
	var pos := player_pos + Vector2(cos(angle), sin(angle)) * distance
	
	var margin: float = 50.0
	var max_x: float = 160 * 32 - margin
	var max_y: float = 120 * 32 - margin
	pos.x = clampf(pos.x, margin, max_x)
	pos.y = clampf(pos.y, margin, max_y)
	
	return pos

func _configure_vs_enemy(enemy: Node) -> void:
	if not enemy.has_method("set_enemy_type"):
		return
	
	var tier: int = mini(_difficulty_tier, 5)
	var enemy_pool: Array[String] = []
	match tier:
		1: enemy_pool = ["rat", "bat", "slime", "spider"]
		2: enemy_pool = ["skeleton", "zombie", "goblin", "wolf"]
		3: enemy_pool = ["orc", "knight", "shaman", "scorpion"]
		4: enemy_pool = ["wraith", "troll", "imp", "serpent"]
		5: enemy_pool = ["fire_elemental", "skeleton_archer", "orc_berserker", "wolf_rider"]
		_: enemy_pool = ["rat", "bat", "slime", "spider"]
	
	if _difficulty_tier > 5:
		enemy_pool = ["ogre_boss", "necromancer", "demon_lord", "skeleton", "orc", "troll", "fire_elemental"]
	
	var enemy_id: String = enemy_pool[randi() % enemy_pool.size()]
	var etype: Dictionary = EnemyDatabase.get_enemy_type(enemy_id)
	if etype.is_empty():
		return
	
	enemy.set_enemy_type(etype)
	
	var diff_mult: float = 1.0 + (_difficulty_tier - 1) * 0.2
	
	var health_node := enemy.get_node_or_null("Health") as Health
	if health_node:
		var base_hp: float = etype.get("base_health", 50.0)
		health_node.max_health = base_hp * diff_mult * 2.0
		health_node.current_health = health_node.max_health
	
	var base_dmg: float = etype.get("contact_damage", 5.0)
	if enemy.get("contact_damage", null) != null:
		enemy.contact_damage = base_dmg * diff_mult * 0.5
	
	if enemy.get("speed", null) != null:
		enemy.speed = etype.get("speed", 40.0) * 0.4
	
	var stats_node := enemy.get_node_or_null("CharacterStats") as CharacterStats
	if stats_node and health_node:
		stats_node.base_life = health_node.max_health
		stats_node.base_armour = 5.0 * _difficulty_tier
		stats_node.recalculate()
	
	if enemy.has_method("apply_rarity"):
		enemy.apply_rarity(Enemy.EnemyRarity.NORMAL, _difficulty_tier)
	
	if enemy.has_method("set_enemy_class_info"):
		enemy.set_enemy_class_info(Enemy.EnemyClass.MELEE, [])

func _count_alive_enemies() -> int:
	var count := 0
	for ch in get_children():
		if ch.is_in_group("enemy") and is_instance_valid(ch):
			if ch.has_node("Health"):
				var h := ch.get_node("Health") as Health
				if h.current_health > 0:
					count += 1
			else:
				count += 1
	return count

func _on_vs_enemy_killed() -> void:
	_kill_count += 1
	_enemies_killed_in_wave += 1
	if _enemies_killed_in_wave >= ENEMIES_PER_WAVE:
		_wave += 1
		_enemies_killed_in_wave = 0
		var hud: HUD = get_node_or_null("CanvasLayer2") as HUD
		if hud:
			hud.set_wave(_wave)
	
	# Boss olumunu kontrol et
	if _boss_active and _last_boss and not is_instance_valid(_last_boss):
		_boss_active = false
	
	var hud: HUD = get_node_or_null("CanvasLayer2") as HUD
	if hud:
		hud.set_kill_count(_kill_count)
	
	# XP gem'leri düşmanın kendisi düşürüyor (XPGem.gd)
	# Main.gd artık direkt XP eklemiyor
	
	# Her 100 kisilmede bir essiz boss spawnla
	if _kill_count % 100 == 0 and not _boss_active:
		_spawn_boss()
	
	if _kill_count >= _next_difficulty_at:
		_difficulty_tier += 1
		_next_difficulty_at += 100
		_enemies_per_spawn = mini(6 + _difficulty_tier * 2, 30)
		_spawn_interval = maxf(0.6, 1.5 - _difficulty_tier * 0.04)
		print("VS: Zorluk seviyesi %d'e yukseldi! (%d kisilmesi)" % [_difficulty_tier, _kill_count])

# ==================== BOSS SPAWN ====================

func _spawn_boss() -> void:
	if not enemy_scene or not player or not is_instance_valid(player):
		return
	
	# Rastgele boss sec
	var boss_id: String = BOSS_POOL[randi() % BOSS_POOL.size()]
	var etype: Dictionary = EnemyDatabase.get_enemy_type(boss_id)
	if etype.is_empty():
		return
	
	# Boss'u oyuncunun yakinina spawnla (gorunur mesafede)
	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(200.0, 300.0)
	var spawn_pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	var margin: float = 50.0
	var max_x: float = 160 * 32 - margin
	var max_y: float = 120 * 32 - margin
	spawn_pos.x = clampf(spawn_pos.x, margin, max_x)
	spawn_pos.y = clampf(spawn_pos.y, margin, max_y)
	
	var boss := enemy_scene.instantiate()
	boss.position = spawn_pos
	boss.scale = Vector2(1.8, 1.8)
	add_child(boss)
	boss.add_to_group("enemy")  # Count boss as enemy
	_last_boss = boss
	_boss_active = true
	
	# Boss'u yapilandir
	boss.set_enemy_type(etype)
	boss.apply_rarity(Enemy.EnemyRarity.UNIQUE, _difficulty_tier)
	
	var diff_mult: float = 1.0 + (_difficulty_tier - 1) * 0.5
	var health_node := boss.get_node_or_null("Health") as Health
	if health_node:
		var base_hp: float = etype.get("base_health", 400.0)
		health_node.max_health = base_hp * diff_mult * 3.0
		health_node.current_health = health_node.max_health
	
	var base_dmg: float = etype.get("contact_damage", 35.0)
	if boss.get("contact_damage", null) != null:
		boss.contact_damage = base_dmg * diff_mult
	
	if boss.get("speed", null) != null:
		boss.speed = etype.get("speed", 40.0) * 0.5
	
	var stats_node := boss.get_node_or_null("CharacterStats") as CharacterStats
	if stats_node and health_node:
		stats_node.base_life = health_node.max_health
		stats_node.base_armour = 50.0 * _difficulty_tier
		stats_node.recalculate()
	
	if boss.has_method("set_enemy_class_info"):
		boss.set_enemy_class_info(Enemy.EnemyClass.MELEE, [])
	
	# Boss kill sayaci ve olumunu takip et
	if not boss.tree_exited.is_connected(_on_vs_enemy_killed):
		boss.tree_exited.connect(_on_vs_enemy_killed)
	if not boss.tree_exited.is_connected(_on_boss_killed):
		boss.tree_exited.connect(_on_boss_killed)
	
	# Gorsel bildirim: ekran flasi
	_spawn_boss_announce(etype.get("name", boss_id), boss)
	
	# Bol XP odolu (boss kill normalde _on_vs_enemy_killed ile sayilir)
	print("VS: BOSS SPAWNLANDI! %s (%.0f can)" % [etype.get("name", boss_id), health_node.max_health if health_node else 0])

func _spawn_boss_announce(boss_name: String, _boss_node: Node) -> void:
	# Ekranin her yerine buyuk bir flas efekti
	var flash := ColorRect.new()
	var viewport_size = get_viewport().get_visible_rect().size
	flash.size = viewport_size
	flash.color = Color(0.3, 0.0, 0.1, 0.4)
	flash.z_index = 100
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var canvas := get_node_or_null("CanvasLayer") as CanvasLayer
	if canvas:
		canvas.add_child(flash)
	else:
		add_child(flash)
	var tw := create_tween()
	tw.tween_property(flash, "color:a", 0.0, 1.0)
	tw.tween_callback(func(): if is_instance_valid(flash): flash.queue_free())
	
	# Boss ismini yaz
	var label := Label.new()
	label.text = "☠ %s GÖRÜNDÜ! ☠" % [boss_name]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	label.add_theme_font_size_override("font_size", 36)
	# Center label on screen
	label.position = (viewport_size - Vector2(680, 100)) / 2
	label.size = Vector2(680, 100)
	label.z_index = 101
	if canvas:
		canvas.add_child(label)
	else:
		add_child(label)
	var tw2 := create_tween()
	tw2.tween_property(label, "position:y", label.position.y - 50, 1.5)
	tw2.parallel().tween_property(label, "modulate:a", 0.0, 1.5).set_delay(1.0)
	tw2.tween_callback(func(): if is_instance_valid(label): label.queue_free())

func _on_boss_killed() -> void:
	_boss_active = false
	_last_boss = null
	print("VS: BOSS OLDU! Oyuncu buyuk XP kazandi.")
	# Ekstra XP odulu
	if player and is_instance_valid(player):
		player.level_system.add_xp(100.0 * _difficulty_tier)

# ==================== LEVEL UP / SKILL SELECTION ====================

func _on_player_leveled_up(new_level: int) -> void:
	var fd := get_tree().root.get_node_or_null("FloatingDamage")
	if fd and fd.has_method("show_level_up"):
		fd.show_level_up(new_level)
	
	get_tree().paused = true
	
	# Destek tasi ve pasif agaci gecici olarak devre disi
	# Her levelde skill secimi goster
	_show_skill_selection()

func _show_skill_selection() -> void:
	var selection_ui := VSSkillSelectionUI.new()
	selection_ui.process_mode = PROCESS_MODE_ALWAYS
	selection_ui.layer = 200
	add_child(selection_ui)
	# Skill seviyelerini UI'ya gonder (evolution sistemi)
	var skill_levels: Dictionary = {}
	if player and is_instance_valid(player):
		skill_levels = player._skill_levels.duplicate()
	selection_ui.show_selection(_player_skills, skill_levels)
	selection_ui.skill_selected.connect(_on_skill_chosen)

func _on_skill_chosen(skill_path: String) -> void:
	if not player or not is_instance_valid(player):
		get_tree().paused = false
		return
	
	if ResourceLoader.exists(skill_path):
		var skill_data: SkillData = load(skill_path)
		if skill_data:
			if skill_path not in _player_skills:
				# YENI SKILL: ekle
				_player_skills.append(skill_path)
				player.skill_setups[skill_path] = {"skill": skill_data, "supports": [null, null, null, null]}
				player.vs_skills.append(skill_path)
				player._skill_levels[skill_path] = 1
				print("VS: Yeni skill eklendi: %s (Seviye 1)" % skill_data.display_name)
			else:
				# SKILL EVOLUTION: mevcut skill'i yukselt
				var current_level: int = player._skill_levels.get(skill_path, 1)
				player._skill_levels[skill_path] = current_level + 1
				print("VS: Skill yukseltildi: %s (Seviye %d -> %d)" % [
					skill_data.display_name, current_level, current_level + 1])
	
	# Pasif agaci devre disi, direkt unpause
	get_tree().paused = false

func _show_support_selection() -> void:
	"""Her 5. levelde: 3 support gem goster, rastgele bir skill'e baglanacak."""
	if not player or not is_instance_valid(player):
		get_tree().paused = false
		return
	
	get_tree().paused = true  # Pause game while UI is up
	var support_ui := VSSupportSelectionUI.new()
	support_ui.process_mode = PROCESS_MODE_ALWAYS
	support_ui.layer = 200
	add_child(support_ui)
	support_ui.show_selection(_player_skills)
	support_ui.support_selected.connect(_on_support_chosen)

func _on_support_chosen(support_path: String, skill_path: String) -> void:
	"""Support gem secildi: skill'e tak."""
	if not player or not is_instance_valid(player):
		get_tree().paused = false
		return
	
	if ResourceLoader.exists(support_path):
		var support_data: SupportData = load(support_path)
		if support_data and player.skill_setups.has(skill_path):
			# Skill'in support slotlarindan ilk bos olana tak
			var setup: Dictionary = player.skill_setups[skill_path]
			var supports: Array = setup.get("supports", [null, null, null, null])
			var added: bool = false
			for si in range(supports.size()):
				if supports[si] == null:
					supports[si] = support_data
					added = true
					break
			if not added:
				# Tum slotlar doluysa ilkini degistir
				supports[0] = support_data
			setup["supports"] = supports
			player.skill_setups[skill_path] = setup
			player._rebuild_skill_instance()
			print("VS: Destek tasi takildi: %s -> %s" % [support_data.display_name, skill_path])
	
	get_tree().paused = false

func _show_passive_selection() -> void:
	if not player or not is_instance_valid(player):
		get_tree().paused = false
		return
	
	get_tree().paused = true  # Pause game while UI is up
	var passive_ui := VSPassiveSelectionUI.new()
	passive_ui.process_mode = PROCESS_MODE_ALWAYS
	passive_ui.layer = 300
	add_child(passive_ui)
	passive_ui.show_selection(_passive_nodes_owned)
	passive_ui.passive_selected.connect(_on_passive_chosen)

func _on_passive_chosen(node_id: String, node_data: Dictionary) -> void:
	if node_id not in _passive_nodes_owned:
		_passive_nodes_owned.append(node_id)
	
	if player and is_instance_valid(player):
		var applier := PassiveEffectApplier.new()
		var modifiers: Array = node_data.get("modifiers", [])
		var json_string := JSON.stringify(modifiers)
		if player.stats:
			applier.apply_modifiers(json_string, player.stats)
			player.stats.recalculate()
	
	print("VS: Pasif node secildi: %s (ID: %s)" % [node_data.get("name", ""), node_id])
	
	get_tree().paused = false

# ==================== DEATH / RESPAWN ====================

func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	
	# Oyunu duraklat
	get_tree().paused = true
	
	await get_tree().create_timer(0.5).timeout
	
	var death_screen := VSDeathScreen.new()
	death_screen.process_mode = PROCESS_MODE_ALWAYS
	death_screen.layer = 400
	add_child(death_screen)
	
	var p_level: int = player.level_system.level if player else 1
	death_screen.set_stats(p_level, _kill_count, _game_time)
	
	death_screen.respawn_requested.connect(_on_respawn)

func _on_respawn() -> void:
	# Olum ekranini kaldir (CanvasLayer oldugu icin _clear_all silmez)
	for ch in get_children():
		if ch is VSDeathScreen:
			ch.queue_free()
	get_tree().paused = false
	
	# UI bilesenlerini sifirla (CanvasLayer olduklari icin _clear_all silmez)
	var hud := get_node_or_null("CanvasLayer2") as HUD
	if hud:
		hud.player = null
		hud._connected = false
	var game_ui := get_node_or_null("CanvasLayer") as GameUI
	if game_ui:
		game_ui.player = null
		game_ui._connected = false
	var skill_bar := get_tree().root.get_node_or_null("SkillBarLayer")
	if skill_bar:
		skill_bar.player = null
	
	_clear_all()
	call_deferred("_init_game")

func _clear_all() -> void:
	for ch in get_children():
		if ch == map_generator:
			continue
		if ch is CanvasLayer:
			continue
		if ch.name == "GameCamera":
			continue
		# Keep persistent UI layers
		if ch.name in ["FloatingDamage", "JuiceManager"]:
			continue
		ch.queue_free()
	
	# Also clean any other CanvasLayers under root that aren't persistent
	var root := get_tree().root
	for child in root.get_children():
		if child == get_tree().current_scene or child.name == "root":
			continue
		if child is CanvasLayer:
			if child.name in ["FloatingDamage", "JuiceManager"]:
				continue
			child.queue_free()
		elif child.name in ["FloatingDamage", "JuiceManager"]:
			continue
		else:
			child.queue_free()
	
	player = null

# ==================== EVENT HANDLERS ====================

func _on_screen_shake(intensity: float, duration: float) -> void:
	if not _game_camera or not is_instance_valid(_game_camera):
		return
	var original_offset = _game_camera.offset
	var tween = create_tween()
	tween.tween_property(_game_camera, "offset:x", original_offset.x + randf_range(-intensity, intensity), duration/2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_game_camera, "offset:x", original_offset.x, duration/2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_game_camera, "offset:y", original_offset.y + randf_range(-intensity, intensity), duration/2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_game_camera, "offset:y", original_offset.y, duration/2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): if is_instance_valid(_game_camera): _game_camera.offset = original_offset)
