extends Resource
class_name StatusEffect
## Represents an active status effect on an entity (ailment, buff, debuff).
## Managed by AilmentController.

enum Type {
	CHILL,          ## Slows action speed by up to 30%
	FREEZE,         ## Prevents action entirely (white ice visual)
	SHOCK,          ## Increases damage taken by up to 50% (yellow tint)
	ELECTROCUTE,    ## Paralyzes entirely (bright electrical visual)
	IGNITE,         ## Fire DoT over 4 seconds
	POISON,         ## Chaos DoT over 2 seconds (stackable)
	BLEED,          ## Physical DoT while moving
	CRUSHED,        ## Action speed reduction from certain skills
	INTIMIDATED,    ## 10% increased damage dealt to target
	UNNERVE,        ## 10% increased spell damage taken
	MAIM,           ## 30% reduced movement speed
	HINDER,         ## Reduced movement speed for spells
	BLIND,          ## 20% less accuracy
	WITHER,         ## Increased chaos damage taken (stackable)
	FULLY_BROKEN,   ## Armour reduced to 0, special effects from passives activate
	TAUNT,          ## Forced to attack taunter
	CONSECRATED,    ## Life regen buff
	BUFF_ONSLAUGHT, ## 20% increased attack/cast/movement speed
	BUFF_FORTIFY,   ## 20% less damage taken
	BUFF_HASTE,     ## Configurable attack speed + movement speed buff (from Haste skill)
}

## How this effect stacks with itself
enum StackMode {
	NONE,           ## Cannot stack, only highest magnitude applies
	REFRESH,        ## New application refreshes duration only
	INDEPENDENT,    ## Each application is a separate instance
	ADDITIVE,       ## Magnitude stacks additively up to cap
}

@export var effect_type: Type
@export var stack_mode: StackMode = StackMode.NONE
@export var magnitude: float = 0.0       ## Varies by type (e.g., chill 0-30% slow)
@export var duration: float = 0.0         ## Remaining seconds
@export var total_duration: float = 0.0   ## Original duration for UI
var source: Node = null
@export var damage_per_tick: float = 0.0  ## For DoT effects
@export var tick_interval: float = 1.0    ## Seconds between DoT ticks
@export var damage_type: String = "physical"  ## For DoT resistance

var _tick_timer: float = 0.0
var _ticks_remaining: int = 0
var _total_ticks: int = 0
var _damage_per_tick_constant: float = 0.0  ## Pre-computed constant damage per actual tick interval
var _aggravated: bool = false  ## Bleed deals max damage regardless of movement

## Initialize a status effect with its parameters
func configure(type: Type, mag: float, dur: float, src: Node = null, _tags: Array = [], aggravated: bool = false) -> void:
	effect_type = type
	magnitude = mag
	duration = dur
	total_duration = dur
	source = src
	_aggravated = aggravated
	
	match type:
		Type.IGNITE:
			damage_type = "fire"
			damage_per_tick = mag  ## mag = total damage over duration
			tick_interval = 1.0
			_ticks_remaining = int(ceil(dur / tick_interval))
			_total_ticks = _ticks_remaining
			_damage_per_tick_constant = mag / float(_total_ticks) if _total_ticks > 0 else 0.0
		Type.POISON:
			damage_type = "chaos"
			damage_per_tick = mag
			tick_interval = 1.0
			_ticks_remaining = int(ceil(dur / tick_interval))
			_total_ticks = _ticks_remaining
			_damage_per_tick_constant = mag / float(_total_ticks) if _total_ticks > 0 else 0.0
		Type.BLEED:
			damage_type = "physical"
			damage_per_tick = mag
			tick_interval = 0.5
			_ticks_remaining = int(ceil(dur / tick_interval))
			_total_ticks = _ticks_remaining
			_damage_per_tick_constant = mag / float(_total_ticks) if _total_ticks > 0 else 0.0

## Called each physics frame, returns damage to apply this tick
func tick(delta: float, is_moving: bool = false) -> float:
	duration -= delta
	if duration <= 0.0:
		_ticks_remaining = 0  # Force expiry
		return 0.0
	
	var dot_damage: float = 0.0
	
	if _ticks_remaining > 0:
		# Bleed only deals damage while moving (unless Aggravated)
		if effect_type == Type.BLEED and not is_moving and not _aggravated:
			_tick_timer += delta  ## timer still advances but no damage
			if _tick_timer >= tick_interval:
				_tick_timer -= tick_interval
				_ticks_remaining -= 1
			return 0.0
		
		_tick_timer += delta
		if _tick_timer >= tick_interval:
			_tick_timer -= tick_interval
			dot_damage = _damage_per_tick_constant * tick_interval
			_ticks_remaining -= 1
	
	return dot_damage

func is_expired() -> bool:
	return duration <= 0.0 and _ticks_remaining <= 0

## Get the effective stat modifier for this effect
func get_stat_modifier() -> Dictionary:
	match effect_type:
		Type.CHILL:
			return {"action_speed": -clampf(magnitude, 0.0, 0.3)}
		Type.SHOCK:
			return {"damage_taken": clampf(magnitude, 0.0, 0.5)}
		Type.MAIM:
			return {"movement_speed": -0.3}
		Type.HINDER:
			return {"movement_speed": -clampf(magnitude, 0.0, 0.4)}
		Type.BLIND:
			return {"accuracy": -0.2}
		Type.INTIMIDATED:
			return {"damage_taken": 0.1}
		Type.UNNERVE:
			return {"elemental_damage_taken": 0.1}
		Type.BUFF_ONSLAUGHT:
			return {"attack_speed": 0.2, "cast_speed": 0.2, "movement_speed": 0.2}
		Type.BUFF_FORTIFY:
			return {"damage_taken": -0.2}
		Type.BUFF_HASTE:
			return {"attack_speed": magnitude, "movement_speed": magnitude * 0.667}
		Type.WITHER:
			return {"chaos_damage_taken": clampf(magnitude, 0.0, 0.9)}
		Type.CONSECRATED:
			return {"life_regen_percent": 0.06}  ## 6% life per second
	return {}

func get_display_text() -> String:
	match effect_type:
		Type.CHILL:
			return "Chill (%d%%)" % int(magnitude * 100)
		Type.FREEZE:
			return "Frozen"
		Type.SHOCK:
			return "Shock (%d%%)" % int(magnitude * 100)
		Type.ELECTROCUTE:
			return "Electrocuted"
		Type.IGNITE:
			return "Ignite"
		Type.POISON:
			return "Poison"
		Type.BLEED:
			return "Bleed"
		Type.MAIM:
			return "Maimed"
		Type.HINDER:
			return "Hindered"
		Type.BLIND:
			return "Blinded"
		Type.INTIMIDATED:
			return "Intimidated"
		Type.UNNERVE:
			return "Unnerved"
		Type.WITHER:
			return "Wither"
		Type.BUFF_ONSLAUGHT:
			return "Onslaught"
		Type.BUFF_FORTIFY:
			return "Fortify"
		Type.BUFF_HASTE:
			return "Haste (%d%%)" % int(magnitude * 100)
		Type.CONSECRATED:
			return "Consecrated"
		Type.FULLY_BROKEN:
			return "Fully Broken"
		_:
			return Type.keys()[effect_type]
