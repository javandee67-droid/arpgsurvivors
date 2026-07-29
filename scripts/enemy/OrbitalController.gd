extends Node
class_name OrbitalController
## Boss etrafında dönen N tane ateş topunu yönetir.
## Oyuncu aggro_range'e girince sırayla fırlatır.

## Skill data referansları
var _boss: Node = null
var _orbitals: Array[Node] = []       ## OrbitalProjectile node'ları
var _next_index: int = 0               ## Sıradaki fırlatılacak orb indeksi
var _orbital_scene: PackedScene = null
var _fire_cooldown: float = 0.0
var _skill_data: Dictionary = {}

## Skill verisi ile kurulum
func setup(boss: Node, sdata: Dictionary) -> void:
	_boss = boss
	_skill_data = sdata
	_orbital_scene = preload("res://scripts/enemy/OrbitalProjectile.tscn") as PackedScene
	if not _orbital_scene:
		return

	var count: int = sdata.get("orbital_count", 6)
	var radius: float = sdata.get("orbital_radius", 80.0)
	var orbit_speed: float = sdata.get("orbital_speed", 1.5)

	for i in range(count):
		var orb: Node = _orbital_scene.instantiate()
		orb.orbit_radius = radius
		orb.orbit_speed = orbit_speed
		orb.angle_offset = (TAU / count) * i
		orb.boss = boss
		orb.damage_pct = sdata.get("dmg_pct", 0.8)
		orb.damage_type = sdata.get("dmg_type", "fire")
		orb.fire_speed = sdata.get("fire_speed", 350.0)
		orb.hit_tex = sdata.get("hit_tex", "")
		add_child(orb)
		_orbitals.append(orb)

	name = "OrbitalController"

func _process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)

	if not _boss or not is_instance_valid(_boss):
		return

	var player: Node = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return

	var dist: float = _boss.global_position.distance_to(player.global_position)
	var aggro: float = _skill_data.get("aggro_range", 200.0)

	if dist > aggro:
		# Menzil dışında — tüm fırlatılmış orb'ları geri getir
		_reset_orbitals()
		return

	# Menzilde — sırayla fırlat
	if _fire_cooldown <= 0.0:
		_fire_next_orb(player.global_position)
		_fire_cooldown = 0.6  # Her orb arasında 0.6sn bekle (6 orb = 3sn'de biter)

func _fire_next_orb(target_pos: Vector2) -> void:
	if _orbitals.is_empty():
		return

	# Sıradaki fırlatılmamış orb'u bul
	for attempt in range(_orbitals.size()):
		var idx: int = (_next_index + attempt) % _orbitals.size()
		var orb: Node = _orbitals[idx]
		if orb and not orb.is_fired:
			_next_index = (idx + 1) % _orbitals.size()
			orb.fire_at(target_pos)
			return

	# Tüm orb'lar fırlatılmışsa bekle
	pass

func _reset_orbitals() -> void:
	# Oyunucu menzilden çıkarsa, orb'ları resetle
	# Not: OrbitalProjectile fırlatılınca geri dönmez, yok edilir.
	# Yeni orb'lar spawn etmek için buradayız — boşalan slotları doldur

	# Eksik orb sayısını hesapla
	var count: int = _skill_data.get("orbital_count", 6)
	var active_count: int = 0
	for orb in _orbitals:
		if orb and is_instance_valid(orb) and not orb._exploded:
			active_count += 1

	# Eksik orb'ları yeniden oluştur
	var missing: int = count - active_count
	if missing <= 0:
		return

	var radius: float = _skill_data.get("orbital_radius", 80.0)
	var orbit_speed: float = _skill_data.get("orbital_speed", 1.5)

	# Eski fırlatılmış orb'ları temizle
	for i in range(_orbitals.size() - 1, -1, -1):
		var orb: Node = _orbitals[i]
		if not orb or not is_instance_valid(orb) or orb._exploded:
			_orbitals.remove_at(i)
			if orb and is_instance_valid(orb):
				orb.queue_free()

	# Yeni orb'lar ekle
	for i in range(missing):
		if not _orbital_scene:
			return
		var orb: Node = _orbital_scene.instantiate()
		var total: int = _orbitals.size()
		orb.orbit_radius = radius
		orb.orbit_speed = orbit_speed
		orb.angle_offset = (TAU / count) * total
		orb.boss = _boss
		orb.damage_pct = _skill_data.get("dmg_pct", 0.8)
		orb.damage_type = _skill_data.get("dmg_type", "fire")
		orb.fire_speed = _skill_data.get("fire_speed", 350.0)
		orb.hit_tex = _skill_data.get("hit_tex", "")
		add_child(orb)
		_orbitals.append(orb)

	_next_index = 0
