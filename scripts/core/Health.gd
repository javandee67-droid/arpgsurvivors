extends Node
class_name Health
## Full PoE-style health system with Energy Shield, Block, Dodge, Leech, and DoT support.

@export var base_max_health: float = 100.0
var max_health: float
var current_health: float

## Energy Shield
var current_es: float = 0.0
var max_es: float = 0.0
var _es_recharge_timer: float = 0.0  ## Time since last ES damage

## Life Leech instances
var _life_leech_instances: Array[Dictionary] = []

signal died
signal health_changed(current: float, max: float)
signal es_changed(current: float, max: float)
signal damage_blocked
signal damage_dodged
signal damage_taken_signal(amount: float, source: Node, tags: Array)

var _stats: CharacterStats = null
var _initialized: bool = false
## Son saldırgan (on-kill/gain-on-hit işlemleri için)
var _last_attacker: Node = null

func _ready() -> void:
	max_health = base_max_health
	current_health = max_health
	current_es = 0.0

	_stats = get_parent().get_node_or_null("CharacterStats")
	if _stats:
		_stats.stats_changed.connect(_on_stats_changed)

func _process(delta: float) -> void:
	# Process life leech
	if not _life_leech_instances.is_empty():
		var heal_amount: float = 0.0
		for leech in _life_leech_instances:
			if leech.remaining <= 0.0:
				continue
			var tick_amount: float = leech.rate * delta
			tick_amount = minf(tick_amount, leech.remaining)
			leech.remaining -= tick_amount
			heal_amount += tick_amount
		if heal_amount > 0.0:
			heal(heal_amount)
		# Clean up finished leech instances
		_life_leech_instances = _life_leech_instances.filter(func(l): return l.remaining > 0.0)
	
	# --- Passive Life Regeneration ---
	if _stats and _stats.life_regen_per_second > 0.0 and current_health < max_health:
		heal(_stats.life_regen_per_second * delta)
	
	# --- Passive ES Regeneration ---
	if _stats and _stats.es_regen_per_second > 0.0 and current_es < max_es:
		current_es = minf(current_es + _stats.es_regen_per_second * delta, max_es)
		es_changed.emit(current_es, max_es)
	
	# Energy Shield Recharge (default 5sn gecikme, %33/sn hız)
	if _stats and current_es < max_es:
		_es_recharge_timer += delta
		var delay: float = _stats.es_recharge_delay
		if _es_recharge_timer >= delay:
			var recharge_rate: float = _stats.max_energy_shield * (_stats.es_recharge_rate_percent / 100.0)
			current_es = minf(current_es + recharge_rate * delta, max_es)
			es_changed.emit(current_es, max_es)

func _on_stats_changed() -> void:
	var old_max := max_health
	max_health = _stats.max_life
	var old_es_max := max_es
	max_es = _stats.max_energy_shield
	
	if not _initialized:
		current_health = max_health
		current_es = max_es
		_initialized = true
	else:
		if old_max > 0.0:
			current_health = current_health * (max_health / old_max)
		if old_es_max > 0.0:
			current_es = current_es * (max_es / old_es_max)
		else:
			current_es = max_es
	
	current_health = minf(current_health, max_health)
	current_es = minf(current_es, max_es)
	health_changed.emit(current_health, max_health)
	es_changed.emit(current_es, max_es)

## Main damage intake. Handles: dodge → block → ES absorb → armour → resist → health.
## Returns HitResult dictionary for the caller to show damage numbers etc.
## penetration: attacker's penetration value (reduces defender's resistance)
func take_damage(amount: float, source: Node = null, tags: Array = [], is_spell: bool = false, penetration: float = 0.0) -> Dictionary:
	# Track last attacker for on-kill / on-hit effects
	if source and is_instance_valid(source):
		_last_attacker = source
	
	if amount <= 0.0:
		return {"final_damage": 0.0, "blocked": false, "dodged": false, "evaded": false, "es_absorbed": 0.0}
	
	var result := {"final_damage": 0.0, "blocked": false, "dodged": false, "evaded": false, "es_absorbed": 0.0}
	var damage_type := _extract_damage_type(tags)
	
	# --- Evasion-based Dodge (CombatEngine.calculate_hit zaten accuracy vs evasion kontrolü yaptı) ---
	# Ayrı bir flat attack_dodge_chance artık yok.
	# Kaçınma tamamen evasion puanı üzerinden CombatEngine'de hesaplanır.
	
	# --- Block (75% cap applied in CombatEngine) ---
	if not is_spell and _stats and _stats.attack_block_chance > 0.0:
		if CombatEngine.roll_block(_stats.attack_block_chance):
			result.blocked = true
			damage_blocked.emit()
			# Block still deals some damage if not full block
			var block_reduction: float = 1.0  ## Full block
			amount = maxf(amount - amount * block_reduction, 0.0)
			if amount <= 0.0:
				return result
	
	if is_spell and _stats and _stats.spell_block_chance > 0.0:
		if CombatEngine.roll_block(_stats.spell_block_chance):
			result.blocked = true
			damage_blocked.emit()
			var block_reduction: float = 1.0
			amount = maxf(amount - amount * block_reduction, 0.0)
			if amount <= 0.0:
				return result
	
	# --- Energy Shield absorbs damage first ---
	var es_absorbed: float = 0.0
	if current_es > 0.0 and damage_type != "chaos":
		es_absorbed = minf(current_es, amount)
		current_es -= es_absorbed
		amount -= es_absorbed
		result.es_absorbed = es_absorbed
		_es_recharge_timer = 0.0  ## Reset ES recharge timer
		es_changed.emit(current_es, max_es)
	elif damage_type == "chaos":
		pass  ## Chaos bypasses ES
	
	# --- Apply resistances (penetration reduces enemy resistance) ---
	var final_amount: float = amount
	if _stats:
		var effective_pen: float = penetration
		final_amount = amount * _stats.get_incoming_damage_multiplier(damage_type, effective_pen)
	
	result.final_damage = final_amount
	
	# --- Culling Strike: attacker with culling_threshold instantly kills low-life enemies ---
	if source and is_instance_valid(source) and source.has_node("CharacterStats"):
		var caster_stats: CharacterStats = source.get_node("CharacterStats") as CharacterStats
		if caster_stats and caster_stats.culling_threshold > 0.0:
			var cull_pct: float = caster_stats.culling_threshold
			if current_health / max_health <= cull_pct / 100.0:
				current_health = 0.0
				health_changed.emit(current_health, max_health)
				
	# --- Apply damage to health ---
	if final_amount > 0.0 and current_health > 0.0:
		current_health = maxf(current_health - final_amount, 0.0)
		health_changed.emit(current_health, max_health)
	
	# --- Emit events ---
	var payload := {
		"amount": final_amount + es_absorbed,
		"source": source,
		"target": get_parent(),
		"tags": tags,
		"position": get_parent().global_position,
		"is_crit": tags.has("critical"),
		"es_absorbed": es_absorbed,
	}
	EventBus.damage_taken.emit(payload)
	
	if source:
		var dealt_payload := payload.duplicate()
		dealt_payload["amount"] = final_amount
		EventBus.damage_dealt.emit(dealt_payload)
		if payload.get("is_crit", false):
			EventBus.crit_landed.emit(dealt_payload)
	
	damage_taken_signal.emit(final_amount, source, tags)
	
	if current_health <= 0.0:
		die()
	
	return result

func _extract_damage_type(tags: Array) -> String:
	for t: String in tags:
		var tl: String = t.to_lower()
		if tl in ["fire", "cold", "lightning", "chaos"]:
			return tl
	return "physical"

func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)

# --- Buff/Aura reservasyonu ---
var reserved_life: float = 0.0  ## Buff/Aura skill'leri için rezerve edilen can

## Kullanılabilir can = max_health - reserved_life
func get_available_life() -> float:
	return maxf(max_health - reserved_life, 0.0)

## Can rezerve et (life-reservation support gem ile). Yeterli boş can yoksa false döner.
func reserve_life(amount: float) -> bool:
	var new_reserved: float = reserved_life + amount
	if new_reserved > max_health:
		return false
	reserved_life = new_reserved
	if current_health > get_available_life():
		current_health = get_available_life()
		health_changed.emit(current_health, max_health)
	return true

## Can rezervasyonunu kaldır
func unreserve_life(amount: float) -> void:
	reserved_life = maxf(reserved_life - amount, 0.0)

## Life cost olarak harca (skill cost vs.) — yeterli can yoksa false döner
func spend(amount: float) -> bool:
	if current_health < amount:
		return false
	current_health -= amount
	health_changed.emit(current_health, max_health)
	return true

## Recover energy shield
func recover_es(amount: float) -> void:
	current_es = minf(current_es + amount, max_es)
	_es_recharge_timer = 0.0
	es_changed.emit(current_es, max_es)

## Add a life leech instance
func add_life_leech(damage_dealt: float, leech_percent: float) -> void:
	if leech_percent <= 0.0 or max_health <= 0.0:
		return
	var leech := CombatEngine.calculate_leech(damage_dealt, leech_percent, max_health, _stats)
	if leech.total > 0.0:
		_life_leech_instances.append(leech)

## Returns true if there are active life leech instances
func is_leeching() -> bool:
	return not _life_leech_instances.is_empty()

func die() -> void:
	var parent := get_parent()
	if parent and is_instance_valid(parent):
		# Player ise queue_free yapma -> Main.gd respawn yönetsin
		if parent.is_in_group("player"):
			died.emit()
			return
		
		# Düşman öldü — saldırgan eğer player ise on-kill affix'lerini uygula
		if _last_attacker and is_instance_valid(_last_attacker) and _last_attacker.is_in_group("player"):
			_apply_on_kill_effects(_last_attacker)
		
		EventBus.enemy_killed.emit(parent)
	died.emit()
	# Enemy.gd _on_death() zaten queue_free cagiriyor (tween + drop islemlerinden sonra).
	# Buradaki queue_free, _on_death'in await sonrasi calismasini engelliyor ve drop'lari kiriyor.
	# _on_death() kendi cleanup'ini yapar.
	# Player icin zaten yukarida return edildi.

## Vuruş anında player'ın life_gain_on_hit ve leech affix'lerini uygula
static func apply_on_hit_effects_to_attacker(attacker: Node, damage_dealt: float) -> void:
	if not attacker or not is_instance_valid(attacker):
		return
	var stats: CharacterStats = attacker.get_node_or_null("CharacterStats")
	if not stats:
		return
	
	# Life gain on hit
	if stats.life_gain_on_hit > 0.0:
		var p_health: Health = attacker.get_node_or_null("Health")
		if p_health:
			p_health.heal(stats.life_gain_on_hit)
	
	# Life leech
	if stats.life_leech_percent > 0.0:
		var p_health: Health = attacker.get_node_or_null("Health")
		if p_health:
			p_health.add_life_leech(damage_dealt, stats.life_leech_percent)
	
## Düşman öldürünce player'ın life_on_kill affix'lerini uygula
func _apply_on_kill_effects(player_node: Node) -> void:
	var p_stats: CharacterStats = player_node.get_node_or_null("CharacterStats")
	if not p_stats:
		return
	
	# Life on kill
	if p_stats.life_on_kill > 0.0:
		var p_health: Health = player_node.get_node_or_null("Health")
		if p_health:
			p_health.heal(p_stats.life_on_kill)
