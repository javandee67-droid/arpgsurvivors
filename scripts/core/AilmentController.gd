extends Node
class_name AilmentController
## Manages all status effects (ailments, buffs, debuffs) on an entity.
## Attach to Player and Enemy scenes as "AilmentController".

signal effects_changed
signal effect_added(effect_type: int)
signal effect_removed(effect_type: int)
signal all_effects_cleared

var active_effects: Array[StatusEffect] = []
var _entity: Node = null
var _stats: CharacterStats = null

# Görsel efektler icin modulate renkleri
var _default_modulate: Color = Color.WHITE

# Chill buildup sistemi: belirli birikme seviyesine ulasinca FREEZE
var _chill_buildup: float = 0.0
const CHILL_FREEZE_THRESHOLD: float = 1.0  # 1.0 birikince donma
var _chill_buildup_decay: float = 0.25  # saniyede ne kadar azalir

# Electrocute buildup sistemi: birikince ELECTROCUTE (paraliz)
var _electrocute_buildup: float = 0.0
const ELECTROCUTE_THRESHOLD: float = 1.0
var _electrocute_buildup_decay: float = 0.15  # chill'den biraz yavas decay

func _ready() -> void:
	_entity = get_parent()
	_stats = _entity.get_node_or_null("CharacterStats")
	var sprite: Node = _entity.get_node_or_null("AnimatedSprite2D")
	if sprite and sprite is CanvasItem:
		_default_modulate = sprite.modulate

func _process(delta: float) -> void:
	# Chill buildup decay
	if _chill_buildup > 0.0 and not has_effect(StatusEffect.Type.CHILL) and not has_effect(StatusEffect.Type.FREEZE):
		_chill_buildup = maxf(_chill_buildup - _chill_buildup_decay * delta, 0.0)
	
	# Electrocute buildup decay
	if _electrocute_buildup > 0.0 and not has_effect(StatusEffect.Type.SHOCK) and not has_effect(StatusEffect.Type.ELECTROCUTE):
		_electrocute_buildup = maxf(_electrocute_buildup - _electrocute_buildup_decay * delta, 0.0)
	
	# Armour break decay (50% per second when not fully broken)
	if _armour_break_amount > 0.0 and not has_effect(StatusEffect.Type.FULLY_BROKEN):
		_armour_break_amount = maxf(_armour_break_amount - _armour_break_amount * 0.5 * delta, 0.0)
		if _armour_break_amount <= 0.0:
			_armour_break_source_max = 0.0
	
	if active_effects.is_empty():
		return
		
	var is_moving: bool = false
	# Check if entity is moving (for bleed)
	if _entity is CharacterBody2D:
		is_moving = _entity.velocity.length_squared() > 1.0
	
	var dot_damage_total: float = 0.0
	var dot_source: Node = null
	var dot_tags: Array[String] = ["dot"]
	
	for effect in active_effects:
		dot_damage_total += effect.tick(delta, is_moving)
		# Kaynagi ve element tipini efektten al
		if not dot_source and effect.source:
			dot_source = effect.source
		if effect.damage_type and not effect.damage_type in dot_tags:
			dot_tags.append(effect.damage_type)
	
	# Apply accumulated DoT damage
	if dot_damage_total > 0.0 and _entity.has_node("Health"):
		var health: Health = _entity.get_node("Health")
		var valid_source: Node = dot_source if (is_instance_valid(dot_source)) else null
		health.take_damage(dot_damage_total, valid_source, dot_tags)
	
	# Remove expired effects
	var before_count = active_effects.size()
	var removed_types: Array[int] = []
	for e in active_effects:
		if e.is_expired():
			removed_types.append(e.effect_type)
	active_effects = active_effects.filter(func(e: StatusEffect): return not e.is_expired())
	if active_effects.size() != before_count:
		effects_changed.emit()
		for etype in removed_types:
			effect_removed.emit(etype)

## Apply a new status effect
func apply_effect(effect_type: StatusEffect.Type, magnitude: float, duration: float, source: Node = null, tags: Array = [], aggravated: bool = false) -> void:
	# ===== DEFANSIF STAT'LAR (player'in kendi stat'lari etkiyi azaltır/artırır) =====
	if _stats:
		# Ailment duration reduction
		if duration > 0.0 and effect_type in [
				StatusEffect.Type.CHILL, StatusEffect.Type.FREEZE, StatusEffect.Type.IGNITE,
				StatusEffect.Type.POISON, StatusEffect.Type.BLEED, StatusEffect.Type.SHOCK,
				StatusEffect.Type.ELECTROCUTE, StatusEffect.Type.BLIND, StatusEffect.Type.MAIM, StatusEffect.Type.HINDER]:
			if _stats.ailment_duration_on_you > 0.0:
				duration /= (1.0 + _stats.ailment_duration_on_you / 100.0)
		
		# Debuff expiry speed: "debuffs on you expire X% faster"
		if duration > 0.0 and effect_type in [
				StatusEffect.Type.CHILL, StatusEffect.Type.MAIM, StatusEffect.Type.HINDER,
				StatusEffect.Type.BLIND, StatusEffect.Type.CRUSHED, StatusEffect.Type.INTIMIDATED,
				StatusEffect.Type.UNNERVE, StatusEffect.Type.WITHER, StatusEffect.Type.TAUNT]:
			if _stats.debuff_expiry_speed > 0.0:
				duration /= (1.0 + _stats.debuff_expiry_speed / 100.0)
		
		# Slow potency reduction: "X% reduced Slowing Potency of Debuffs on You"
		if effect_type in [StatusEffect.Type.CHILL, StatusEffect.Type.HINDER, StatusEffect.Type.MAIM]:
			if _stats.slow_potency_reduction > 0.0:
				magnitude *= (1.0 - _stats.slow_potency_reduction / 100.0)
		
		# Buff expiry: "buffs on you expire X% slower"
		if duration > 0.0 and effect_type in [
				StatusEffect.Type.BUFF_ONSLAUGHT, StatusEffect.Type.BUFF_FORTIFY,
				StatusEffect.Type.BUFF_HASTE, StatusEffect.Type.CONSECRATED]:
			if _stats.buff_expiry_speed > 0.0:
				duration *= (1.0 + _stats.buff_expiry_speed / 100.0)
		
		# Buff effect on self: "X% increased effect of Buffs on You"
		if effect_type in [StatusEffect.Type.BUFF_ONSLAUGHT, StatusEffect.Type.BUFF_FORTIFY,
				StatusEffect.Type.BUFF_HASTE, StatusEffect.Type.CONSECRATED]:
			if _stats.buff_effect_self > 0.0:
				magnitude *= (1.0 + _stats.buff_effect_self / 100.0)
	
	var stack_mode: StatusEffect.StackMode = _get_stack_mode(effect_type)
	
	# Handle stacking logic
	match stack_mode:
		StatusEffect.StackMode.NONE:
			# Remove existing, apply new one (highest magnitude wins)
			for existing in active_effects:
				if existing.effect_type == effect_type:
					if existing.magnitude >= magnitude:
						return  ## Existing is stronger
					active_effects.erase(existing)
					break
		
		StatusEffect.StackMode.REFRESH:
			for existing in active_effects:
				if existing.effect_type == effect_type:
					existing.duration = maxf(existing.duration, duration)
					existing.total_duration = existing.duration
					return
		
		StatusEffect.StackMode.INDEPENDENT:
			pass  ## Always add a new instance
		
		StatusEffect.StackMode.ADDITIVE:
			for existing in active_effects:
				if existing.effect_type == effect_type:
					existing.magnitude = minf(existing.magnitude + magnitude, _get_cap(effect_type))
					existing.duration = maxf(existing.duration, duration)
					return
	
	var effect := StatusEffect.new()
	effect.configure(effect_type, magnitude, duration, source, tags, aggravated)
	active_effects.append(effect)
	effects_changed.emit()
	effect_added.emit(effect_type)
	_update_sprite_tint()

## Remove a specific effect type
func remove_effect(effect_type: StatusEffect.Type) -> void:
	active_effects = active_effects.filter(func(e: StatusEffect): return e.effect_type != effect_type)
	effects_changed.emit()
	effect_removed.emit(effect_type)
	_update_sprite_tint()

## Remove all effects (e.g. on death)
func clear_all_effects() -> void:
	active_effects.clear()
	effects_changed.emit()
	all_effects_cleared.emit()

## Check if entity has a specific effect
func has_effect(effect_type: StatusEffect.Type) -> bool:
	for effect in active_effects:
		if effect.effect_type == effect_type:
			return true
	return false

## Check if entity is frozen (prevent actions)
func is_frozen() -> bool:
	return has_effect(StatusEffect.Type.FREEZE)

## Check if entity is electrocuted (prevent actions)
func is_electrocuted() -> bool:
	return has_effect(StatusEffect.Type.ELECTROCUTE)

## Entity'nin CharacterStats'ini döndür (defansif stat'lar için AilmentUtils kullanır)
func get_defender_stats() -> CharacterStats:
	return _stats

## Chill birikimi ekle, threshold'a ulasinca FREEZE uygula
func add_chill_buildup(amount: float, freeze_duration_mult: float = 1.0) -> void:
	if is_frozen():
		return  # Zaten donuksa tekrar biriktirme
	
	_chill_buildup += amount
	if _chill_buildup >= CHILL_FREEZE_THRESHOLD:
		# Donma suresi: birikme miktarina bagli x attacker's freeze_duration bonus
		var freeze_duration: float = clampf(_chill_buildup * 1.5, 1.0, 4.0) * freeze_duration_mult
		# Defender's ailment_duration_on_you: süreyi kısalt
		if _stats and _stats.ailment_duration_on_you > 0.0:
			freeze_duration /= (1.0 + _stats.ailment_duration_on_you / 100.0)
		apply_effect(StatusEffect.Type.FREEZE, 1.0, freeze_duration)
		_chill_buildup = 0.0  # Sifirla

## Electrocute birikimi ekle, threshold'a ulasinca ELECTROCUTE uygula
func add_electrocute_buildup(amount: float, elec_duration_mult: float = 1.0) -> void:
	if is_electrocuted():
		return  # Zaten elektriklenmisse tekrar biriktirme
	
	_electrocute_buildup += amount
	if _electrocute_buildup >= ELECTROCUTE_THRESHOLD:
		# Paraliz suresi: chill'den daha kisa (0.5-2.0sn)
		var elec_duration: float = clampf(_electrocute_buildup * 1.0, 0.5, 2.5) * elec_duration_mult
		# Defender's ailment_duration_on_you: süreyi kısalt
		if _stats and _stats.ailment_duration_on_you > 0.0:
			elec_duration /= (1.0 + _stats.ailment_duration_on_you / 100.0)
		apply_effect(StatusEffect.Type.ELECTROCUTE, 1.0, elec_duration)
		_electrocute_buildup = 0.0  # Sifirla

# --- Armour Break Accumulation ---
var _armour_break_amount: float = 0.0  ## Biriken armour break miktari (damage cinsinden)
var _armour_break_source_max: float = 0.0  ## Hedefin orijinal armour'u (threshold)

## Armour break birikimi ekle, threshold'a ulasinca FULLY_BROKEN uygula
func add_armour_break(amount: float, max_armour: float, duration: float = 4.0) -> void:
	if max_armour <= 0.0:
		return  # Armour yoksa break de olmaz
	if has_effect(StatusEffect.Type.FULLY_BROKEN):
		return  # Zaten fully broken
	
	_armour_break_source_max = maxf(_armour_break_source_max, max_armour)
	_armour_break_amount += amount
	
	if _armour_break_amount >= _armour_break_source_max:
		apply_effect(StatusEffect.Type.FULLY_BROKEN, 1.0, duration)
		_armour_break_amount = 0.0
		_armour_break_source_max = 0.0

## Mevcut armour break birikimini getir (0.0 - threshold)
func get_armour_break_amount() -> float:
	return _armour_break_amount

## Mevcut chill birikimini getir (0.0 - 1.0)
func get_chill_buildup() -> float:
	return _chill_buildup

## Mevcut electrocute birikimini getir (0.0 - 1.0)
func get_electrocute_buildup() -> float:
	return _electrocute_buildup

## Get combined stat modifiers from all active effects
func get_combined_modifiers() -> Dictionary:
	var mods: Dictionary = {}
	for effect in active_effects:
		var effect_mods := effect.get_stat_modifier()
		for key in effect_mods:
			mods[key] = mods.get(key, 0.0) + effect_mods[key]
	return mods

## Get list of active effect display texts for UI
func get_active_display_texts() -> Array[String]:
	var texts: Array[String] = []
	for effect in active_effects:
		var text := effect.get_display_text()
		if effect.duration < effect.total_duration:
			text += " (%.1fs)" % effect.duration
		if not texts.has(text):
			texts.append(text)
	return texts

func _get_stack_mode(effect_type: StatusEffect.Type) -> StatusEffect.StackMode:
	match effect_type:
		StatusEffect.Type.POISON:
			return StatusEffect.StackMode.INDEPENDENT
		StatusEffect.Type.WITHER:
			return StatusEffect.StackMode.ADDITIVE
		StatusEffect.Type.IGNITE, StatusEffect.Type.BLEED:
			return StatusEffect.StackMode.NONE  ## Only strongest applies
		StatusEffect.Type.CHILL, StatusEffect.Type.SHOCK:
			return StatusEffect.StackMode.NONE
		_:
			return StatusEffect.StackMode.REFRESH

func _get_cap(effect_type: StatusEffect.Type) -> float:
	match effect_type:
		StatusEffect.Type.SHOCK:
			return 0.5
		StatusEffect.Type.CHILL:
			return 0.3
		StatusEffect.Type.WITHER:
			return 0.9  ## 90% increased chaos damage taken (15 stacks of 6%)
		_:
			return 1.0

# --- Görsel tint (enemy sprite rengini efektlere gore degistir) ---

## Efektlere gore enemy sprite'in modulate'ini guncelle
func _update_sprite_tint() -> void:
	var sprite: Node = _entity.get_node_or_null("AnimatedSprite2D") if _entity else null
	if not sprite or not sprite is CanvasItem:
		return
	
	# En oncelikli efektten renk sec
	if has_effect(StatusEffect.Type.FREEZE):
		sprite.modulate = Color(0.7, 0.8, 1.2)  # Buz mavisi
	elif has_effect(StatusEffect.Type.ELECTROCUTE):
		sprite.modulate = Color(1.5, 1.2, 0.4)  # Parlak sari/simsek
	elif has_effect(StatusEffect.Type.CHILL):
		sprite.modulate = Color(0.8, 0.9, 1.1)  # Acik mavi
	elif has_effect(StatusEffect.Type.SHOCK):
		sprite.modulate = Color(1.2, 1.0, 0.5)  # Sari
	elif has_effect(StatusEffect.Type.IGNITE):
		sprite.modulate = Color(1.3, 0.7, 0.5)  # Turuncu
	elif has_effect(StatusEffect.Type.POISON):
		sprite.modulate = Color(0.7, 1.1, 0.6)  # Yesil
	else:
		sprite.modulate = _default_modulate  # Normal
