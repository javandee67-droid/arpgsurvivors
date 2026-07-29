extends Node
class_name PassiveEffectApplier
## Applies passive skill node effects to CharacterStats.
## Extracted from the old SkillTreeUI._apply_node_bonus logic.

var _pct_regex: RegEx = RegEx.create_from_string(r"(\d+)%\s*increased")

func apply_modifiers(modifiers_json: String, stats: CharacterStats, remove: bool = false) -> void:
	"""Apply or remove modifiers from a JSON array of modifiers."""
	if modifiers_json.is_empty():
		return

	var p = JSON.new()
	var err = p.parse(modifiers_json)
	if err != OK:
		return
	var mods: Array = p.get_data()
	if mods.is_empty():
		return

	var increased: Dictionary = {}
	var flat_base: Dictionary = {}
	var flat_mod: Dictionary = {}

	for m in mods:
		if not (m is Dictionary): continue
		var mtype: String = m.get("type", "")
		var key: String = m.get("key", "")
		var val: float = m.get("value", 0.0)

		match mtype:
			"increased":
				increased[key] = increased.get(key, 0.0) + val
			"flat_base":
				flat_base[key] = flat_base.get(key, 0.0) + val
			"flat_mod":
				flat_mod[key] = flat_mod.get(key, 0.0) + val
			"unknown":
				var raw: String = m.get("raw", "")
				if raw.is_empty(): continue
				_parse_unknown_raw_text(raw, increased, flat_mod)
				# Special cases
				if raw.find("melee strike range") >= 0:
					var msr_pct := _extract_first_number(raw)
					if msr_pct > 0.0:
						flat_mod["melee_range"] = flat_mod.get("melee_range", 0.0) + (msr_pct * 25.0)
				if raw.find("armour also applies") >= 0 or raw.find("armour also") >= 0:
					var aae_pct := _extract_first_number(raw)
					if aae_pct > 0.0:
						flat_mod["armour_elemental_pct"] = flat_mod.get("armour_elemental_pct", 0.0) + aae_pct
				if raw.find("% to maximum") >= 0 and raw.find("resistance") >= 0:
					_parse_max_resistance(raw, flat_mod)

	var sign = -1.0 if remove else 1.0

	# Apply flat_base
	for key in flat_base:
		var v: float = flat_base[key] * sign
		match key:
			"strength": stats.strength += int(v)
			"dexterity": stats.dexterity += int(v)
			"intelligence": stats.intelligence += int(v)
			"base_life": stats.base_life += v
			"base_mana", "mana": stats.base_mana += v
			"base_energy_shield", "energy_shield": stats.base_energy_shield += v
			"base_accuracy": stats.base_accuracy += v
			"base_fire_resistance": stats.base_fire_resistance += v
			"base_cold_resistance": stats.base_cold_resistance += v
			"base_lightning_resistance": stats.base_lightning_resistance += v
			"base_chaos_resistance": stats.base_chaos_resistance += v
			"all_resistance":
				stats.base_fire_resistance += v
				stats.base_cold_resistance += v
				stats.base_lightning_resistance += v
				stats.base_chaos_resistance += v
			"max_fire_resistance": stats.max_fire_resistance += v
			"max_cold_resistance": stats.max_cold_resistance += v
			"max_lightning_resistance": stats.max_lightning_resistance += v
			"max_chaos_resistance": stats.max_chaos_resistance += v
			"all_max_resistance":
				stats.max_fire_resistance += v
				stats.max_cold_resistance += v
				stats.max_lightning_resistance += v
				stats.max_chaos_resistance += v
			"armour": increased["armour"] = increased.get("armour", 0.0) + v
			"evasion": increased["evasion"] = increased.get("evasion", 0.0) + v
			"max_energy_shield": increased["max_energy_shield"] = increased.get("max_energy_shield", 0.0) + v
			"block_chance", "attack_block_chance": stats.base_block_chance += v
			"critical_chance", "crit_chance": increased["critical_chance"] = increased.get("critical_chance", 0.0) + v
			"critical_multiplier": increased["critical_multiplier"] = increased.get("critical_multiplier", 0.0) + v
			"movement_speed": increased["movement_speed"] = increased.get("movement_speed", 0.0) + v
			"attack_speed": increased["attack_speed"] = increased.get("attack_speed", 0.0) + v
			"cast_speed": increased["cast_speed"] = increased.get("cast_speed", 0.0) + v
			"mana_regen": stats.base_mana_regen += v

	# Apply increased
	for key in increased:
		var v: float = increased[key] * sign
		if stats._passive_increased_mods.has(key):
			stats._passive_increased_mods[key] = stats._passive_increased_mods[key] + v
		else:
			stats._passive_increased_mods[key] = v

	# Apply flat_mod
	for key in flat_mod:
		var v: float = flat_mod[key] * sign
		if stats._passive_flat_mods.has(key):
			stats._passive_flat_mods[key] = stats._passive_flat_mods[key] + v
		else:
			stats._passive_flat_mods[key] = v

	stats.recalculate()


func _parse_unknown_raw_text(raw: String, increased: Dictionary, flat_mod: Dictionary) -> void:
	var rl: String = raw.to_lower()
	var val := _extract_first_number(raw)
	if val == 0.0:
		if "cannot be blinded" in rl: flat_mod["cannot_be_blinded"] = 1.0
		# Handle other "cannot" or "immune" keywords
		if "cannot be electrocuted" in rl: flat_mod["cannot_be_electrocuted"] = 1.0
		if "cannot be chilled" in rl: flat_mod["cannot_be_chilled"] = 1.0
		if "cannot be frozen" in rl: flat_mod["cannot_be_frozen"] = 1.0
		if "cannot be stunned" in rl: flat_mod["cannot_be_stunned"] = 1.0
		if "cannot be poisoned" in rl: flat_mod["cannot_be_poisoned"] = 1.0
		return

	if "surrounded" in rl:
		var key := ""
		if "damage" in rl: key = "surrounded_damage"
		elif "accuracy" in rl: key = "surrounded_accuracy"
		elif "life" in rl: key = "surrounded_life_regen"
		else: key = "surrounded_all_damage"
		increased[key] = increased.get(key, 0.0) + val
		return

	if "fully broken" in rl or "fully armour break" in rl:
		if "fire damage taken" in rl: flat_mod["fully_broken_fire_dmg_taken"] = 1.0
		if "cold and lightning damage taken" in rl: flat_mod["fully_broken_cold_lightning_taken"] = 1.0
		if "cannot regenerate life" in rl: flat_mod["fully_broken_no_regen"] = 1.0
		if "are maimed" in rl: flat_mod["maim_on_armourbreak"] = 1.0
		return

	# ---- CONDITIONAL: "while dual wielding" — özel key'ler kullan, generic'e düşme ----
	if "while dual wielding" in rl:
		var sign_dw = -1.0 if "reduced" in rl else 1.0
		var v_dw = val * sign_dw
		if "attack speed" in rl: increased["attack_speed_dual_wield"] = increased.get("attack_speed_dual_wield", 0.0) + v_dw
		elif "attack damage" in rl or "attack" in rl and "damage" in rl: increased["attack_damage_dual_wield"] = increased.get("attack_damage_dual_wield", 0.0) + v_dw
		elif "accuracy" in rl: increased["accuracy_dual_wield"] = increased.get("accuracy_dual_wield", 0.0) + v_dw
		elif "critical hit chance" in rl or "crit chance" in rl: increased["critical_chance_dual_wield"] = increased.get("critical_chance_dual_wield", 0.0) + v_dw
		elif "movement speed" in rl: increased["movement_speed_dual_wield"] = increased.get("movement_speed_dual_wield", 0.0) + v_dw
		return

	# ---- CONDITIONAL: "while shapeshifted" ----
	if "while shapeshifted" in rl:
		if "physical" in rl and "damage" in rl: increased["physical_damage"] = increased.get("physical_damage", 0.0) + val
		elif "elemental" in rl and "damage" in rl: increased["elemental_damage"] = increased.get("elemental_damage", 0.0) + val
		elif "damage" in rl: increased["all_damage"] = increased.get("all_damage", 0.0) + val
		elif "attack speed" in rl: increased["attack_speed"] = increased.get("attack_speed", 0.0) + val
		elif "cast speed" in rl: increased["cast_speed"] = increased.get("cast_speed", 0.0) + val
		elif "mana" in rl and "regen" in rl: increased["mana_regen_rate"] = increased.get("mana_regen_rate", 0.0) + val
		return

	# Generic increased/reduced parsing
	var is_increased := false
	var is_reduced := false
	if "increased" in rl: is_increased = true
	if "reduced" in rl: is_reduced = true

	# ---- SPECIAL: "gain X% of damage as extra Y" MUST be checked BEFORE flat-only return
	# AND before the "AGAINST" check, because gain+extra text can also contain "against" (e.g. "against Frozen Enemies")
	if "gain" in rl and "extra" in rl and "damage" in rl:
		_parse_extra_damage(rl, val, flat_mod)
		return

	# ---- "AGAINST" conditional damage patterns: "X% increased damage against Y" ----
	# Also handle "X% increased damage with hits against Y"
	if "against" in rl and ("damage" in rl):
		var is_with_hits: bool = "with hits" in rl
		var cond_key := _parse_conditional_against(rl)
		if cond_key != "":
			var sign2 = -1.0 if is_reduced else 1.0
			increased[cond_key] = increased.get(cond_key, 0.0) + val * sign2
			return
		# Fall through to generic damage parser for simple cases

	if not is_increased and not is_reduced:
		# Flat modifiers
		if "to maximum life" in rl: flat_mod["base_life"] = flat_mod.get("base_life", 0.0) + val
		elif "to maximum mana" in rl: flat_mod["base_mana"] = flat_mod.get("base_mana", 0.0) + val
		elif "to maximum energy shield" in rl: flat_mod["base_energy_shield"] = flat_mod.get("base_energy_shield", 0.0) + val
		elif "to accuracy" in rl: flat_mod["base_accuracy"] = flat_mod.get("base_accuracy", 0.0) + val
		elif "to all" in rl and "resistance" in rl: flat_mod["all_resistance"] = flat_mod.get("all_resistance", 0.0) + val
		elif "to strength" in rl or "to dexterity" in rl or "to intelligence" in rl:
			if "strength" in rl: flat_mod["strength"] = flat_mod.get("strength", 0.0) + val
			if "dexterity" in rl: flat_mod["dexterity"] = flat_mod.get("dexterity", 0.0) + val
			if "intelligence" in rl: flat_mod["intelligence"] = flat_mod.get("intelligence", 0.0) + val
		elif "to all attributes" in rl:
			flat_mod["strength"] = flat_mod.get("strength", 0.0) + val
			flat_mod["dexterity"] = flat_mod.get("dexterity", 0.0) + val
			flat_mod["intelligence"] = flat_mod.get("intelligence", 0.0) + val
		elif "resistance" in rl:
			if "fire" in rl: flat_mod["base_fire_resistance"] = flat_mod.get("base_fire_resistance", 0.0) + val
			elif "cold" in rl: flat_mod["base_cold_resistance"] = flat_mod.get("base_cold_resistance", 0.0) + val
			elif "lightning" in rl: flat_mod["base_lightning_resistance"] = flat_mod.get("base_lightning_resistance", 0.0) + val
			elif "chaos" in rl: flat_mod["base_chaos_resistance"] = flat_mod.get("base_chaos_resistance", 0.0) + val
		elif "gain" in rl and "rage on" in rl and "hit" in rl: flat_mod["rage_on_hit"] = flat_mod.get("rage_on_hit", 0.0) + val
		elif "gain" in rl and "rage when" in rl and "hit" in rl: flat_mod["rage_on_hit"] = flat_mod.get("rage_on_hit", 0.0) + val
		elif "to maximum rage" in rl: flat_mod["max_rage_bonus"] = flat_mod.get("max_rage_bonus", 0.0) + val
		elif "to quality of all skills" in rl: pass  # Skill quality not implemented
		elif "chance to" in rl and "on hit" in rl:
			# X% chance to Y on hit
			_parse_chance_on_hit(rl, val, flat_mod)
		return

	# Increased/Reduced parsing
	var sign = -1.0 if is_reduced else 1.0
	var v = val * sign

	# ---- CHANCE TO INFLICT patterns: "X% increased chance to inflict Y" ----
	if "chance to" in rl and ("inflict" in rl or "apply" in rl):
		if "ailment" in rl: increased["ailment_chance"] = increased.get("ailment_chance", 0.0) + v
		elif "bleeding" in rl or "bleed" in rl: flat_mod["bleed_chance"] = flat_mod.get("bleed_chance", 0.0) + v
		elif "poison" in rl: flat_mod["poison_chance"] = flat_mod.get("poison_chance", 0.0) + v
		elif "shock" in rl: increased["shock_chance"] = increased.get("shock_chance", 0.0) + v
		elif "ignite" in rl: increased["ignite_chance"] = increased.get("ignite_chance", 0.0) + v
		elif "chill" in rl: increased["chill_chance"] = increased.get("chill_chance", 0.0) + v
		elif "freeze" in rl: increased["freeze_chance"] = increased.get("freeze_chance", 0.0) + v
		elif "maim" in rl: flat_mod["maim_chance"] = flat_mod.get("maim_chance", 0.0) + v
		elif "blind" in rl: flat_mod["blind_chance"] = flat_mod.get("blind_chance", 0.0) + v
		elif "daze" in rl: flat_mod["daze_chance"] = flat_mod.get("daze_chance", 0.0) + v
		elif "hinder" in rl: flat_mod["hinder_chance"] = flat_mod.get("hinder_chance", 0.0) + v
		elif "immobilise" in rl or "immobilization" in rl: increased["immobilise_chance"] = increased.get("immobilise_chance", 0.0) + v
		return

	# ---- BUILDUP patterns: "X% increased Y buildup" ----
	if "buildup" in rl:
		if "freeze" in rl: increased["freeze_buildup"] = increased.get("freeze_buildup", 0.0) + v
		elif "electrocute" in rl: increased["electrocute_buildup"] = increased.get("electrocute_buildup", 0.0) + v
		return

	# ---- DURATION patterns: "X% increased Y duration" ----
	if "duration" in rl:
		if "skill effect" in rl: increased["skill_effect_duration"] = increased.get("skill_effect_duration", 0.0) + v
		elif "ignite" in rl and "on you" not in rl: increased["ignite_duration_on_enemies"] = increased.get("ignite_duration_on_enemies", 0.0) + v
		elif "ignite" in rl and "on you" in rl: increased["ailment_duration_on_you"] = increased.get("ailment_duration_on_you", 0.0) - v
		elif "freeze" in rl and "on you" not in rl: increased["freeze_duration_on_enemies"] = increased.get("freeze_duration_on_enemies", 0.0) + v
		elif "freeze" in rl and "on you" in rl: increased["ailment_duration_on_you"] = increased.get("ailment_duration_on_you", 0.0) - v
		elif "chill" in rl and "on you" not in rl: increased["chill_duration"] = increased.get("chill_duration", 0.0) + v
		elif "chill" in rl and "on you" in rl: increased["ailment_duration_on_you"] = increased.get("ailment_duration_on_you", 0.0) - v
		elif "shock" in rl and "on you" not in rl: increased["shock_duration"] = increased.get("shock_duration", 0.0) + v
		elif "shock" in rl and "on you" in rl: increased["ailment_duration_on_you"] = increased.get("ailment_duration_on_you", 0.0) - v
		elif "poison" in rl: increased["poison_duration"] = increased.get("poison_duration", 0.0) + v
		elif "bleeding" in rl or "bleed" in rl: increased["bleeding_duration"] = increased.get("bleeding_duration", 0.0) + v
		elif "blind" in rl: increased["blind_duration"] = increased.get("blind_duration", 0.0) + v
		elif "daze" in rl: increased["daze_duration"] = increased.get("daze_duration", 0.0) + v
		elif "pin" in rl: increased["pin_duration"] = increased.get("pin_duration", 0.0) + v
		elif "hinder" in rl: increased["hinder_duration"] = increased.get("hinder_duration", 0.0) + v
		elif "hazard" in rl: increased["hazard_duration"] = increased.get("hazard_duration", 0.0) + v
		elif "ailment" in rl and "on you" in rl: increased["ailment_duration_on_you"] = increased.get("ailment_duration_on_you", 0.0) - v
		elif "ailment" in rl: increased["ailment_duration"] = increased.get("ailment_duration", 0.0) + v
		elif "armour break" in rl: increased["armour_break_duration"] = increased.get("armour_break_duration", 0.0) + v
		elif "charge" in rl: increased["charge_duration"] = increased.get("charge_duration", 0.0) + v
		elif "infusion" in rl: _flag_missing("infusion_duration")
		elif "offering" in rl: _flag_missing("offering_duration")
		elif "banner" in rl: increased["banner_duration"] = increased.get("banner_duration", 0.0) + v
		elif "charm" in rl: increased["charm_duration"] = increased.get("charm_duration", 0.0) + v
		elif "withered" in rl: increased["withered_duration"] = increased.get("withered_duration", 0.0) + v
		elif "parried" in rl: increased["parried_duration"] = increased.get("parried_duration", 0.0) + v
		return

	# ---- RESERVATION: "X% increased reservation efficiency" ----
	if "reservation" in rl:
		increased["reservation_efficiency"] = increased.get("reservation_efficiency", 0.0) + v
		return

	# ---- SPECIAL: "damage penetrates X% resistance" ----
	if "penetrate" in rl or "penetration" in rl:
		_parse_penetration(rl, val, flat_mod)
		return

	# ---- SPECIAL: "X% chance to Y on hit" (already handled above for flat) ----
	# For increased/reduced "chance to" patterns

	# ---- COOLDOWN: "X% increased cooldown recovery rate" ----
	if "cooldown" in rl and "recovery" in rl:
		increased["cooldown_recovery"] = increased.get("cooldown_recovery", 0.0) + v
		return

	# ---- MAGNITUDE patterns (not under "ailment" keyword) ----
	if "magnitude" in rl:
		if "poison" in rl: increased["poison_magnitude"] = increased.get("poison_magnitude", 0.0) + v
		elif "bleeding" in rl or "bleed" in rl: increased["bleed_magnitude"] = increased.get("bleed_magnitude", 0.0) + v
		elif "shock" in rl: increased["shock_magnitude"] = increased.get("shock_magnitude", 0.0) + v
		elif "chill" in rl: increased["chill_magnitude"] = increased.get("chill_magnitude", 0.0) + v
		elif "ignite" in rl: increased["ignite_magnitude"] = increased.get("ignite_magnitude", 0.0) + v
		elif "ailment" in rl: increased["ailment_magnitude"] = increased.get("ailment_magnitude", 0.0) + v
		elif "impale" in rl: increased["impale_magnitude"] = increased.get("impale_magnitude", 0.0) + v
		elif "non-damaging" in rl: increased["ailment_magnitude"] = increased.get("ailment_magnitude", 0.0) + v
		elif "daze" in rl: increased["daze_magnitude"] = increased.get("daze_magnitude", 0.0) + v
		return

	# ---- ARMOUR BREAK ----
	if "armour break" in rl:
		if "duration" in rl: increased["armour_break_duration"] = increased.get("armour_break_duration", 0.0) + v
		elif "effect" in rl: increased["armour_break_effect"] = increased.get("armour_break_effect", 0.0) + v
		elif "increased" in rl: increased["armour_break"] = increased.get("armour_break", 0.0) + v
		return

	# ---- AURA magnitude: "aura skills have X% increased magnitude" ----
	if "aura" in rl and ("magnitude" in rl or "magnitudes" in rl):
		increased["aura_magnitude"] = increased.get("aura_magnitude", 0.0) + v
		return

	# ---- THORNS ----
	if "thorns" in rl:
		flat_mod["thorns"] = flat_mod.get("thorns", 0.0) + v
		return

	# ---- CULLING STRIKE THRESHOLD ----
	if "culling strike" in rl:
		flat_mod["culling_threshold"] = flat_mod.get("culling_threshold", 0.0) + v
		return

	# ---- EXPOSURE ----
	if "exposure" in rl:
		increased["exposure_effect"] = increased.get("exposure_effect", 0.0) + v
		return

	# ---- BLOCK RECOVERY ----
	if "block" in rl and "recovery" in rl:
		increased["block_recovery"] = increased.get("block_recovery", 0.0) + v
		return

	# ---- RECOUP SPEED ----
	if "recoup" in rl:
		increased["recoup_speed"] = increased.get("recoup_speed", 0.0) + v
		return

	# ---- LIFE/MANA LOST PER SECOND / REGEN CONDITIONAL ----
	if "life" in rl:
		if "regen" in rl or "regeneration" in rl: increased["life_regen"] = increased.get("life_regen", 0.0) + v
		elif "recovery" in rl: increased["life_recovery_rate"] = increased.get("life_recovery_rate", 0.0) + v
		elif "maximum" in rl: increased["max_life"] = increased.get("max_life", 0.0) + v
		elif "on kill" in rl: flat_mod["life_on_kill"] = flat_mod.get("life_on_kill", 0.0) + v
		elif "leeched" in rl or "leech" in rl: increased["leech_amount"] = increased.get("leech_amount", 0.0) + v
		elif "gain on hit" in rl: flat_mod["life_gain_on_hit"] = flat_mod.get("life_gain_on_hit", 0.0) + v
	elif "mana" in rl:
		if "regen" in rl or "regeneration" in rl: increased["mana_regen_rate"] = increased.get("mana_regen_rate", 0.0) + v
		elif "recovery" in rl: increased["mana_recovery_rate"] = increased.get("mana_recovery_rate", 0.0) + v
		elif "cost" in rl: increased["mana_cost"] = increased.get("mana_cost", 0.0) - v
		elif "maximum" in rl: increased["max_mana"] = increased.get("max_mana", 0.0) + v
		elif "leeched" in rl or "leech" in rl: increased["leech_amount"] = increased.get("leech_amount", 0.0) + v
		elif "on kill" in rl: flat_mod["mana_on_kill"] = flat_mod.get("mana_on_kill", 0.0) + v
	elif "energy shield" in rl:
		if "recharge" in rl: increased["es_recharge_rate"] = increased.get("es_recharge_rate", 0.0) + v
		elif "recovery" in rl: increased["es_recovery_rate"] = increased.get("es_recovery_rate", 0.0) + v
		elif "delay" in rl: increased["es_recharge_delay"] = increased.get("es_recharge_delay", 0.0) - v
		else: increased["max_energy_shield"] = increased.get("max_energy_shield", 0.0) + v
	elif "armour" in rl: increased["armour"] = increased.get("armour", 0.0) + v
	elif "evasion" in rl: increased["evasion"] = increased.get("evasion", 0.0) + v
	elif "attack speed" in rl: increased["attack_speed"] = increased.get("attack_speed", 0.0) + v
	elif "cast speed" in rl: increased["cast_speed"] = increased.get("cast_speed", 0.0) + v
	elif "movement" in rl: increased["movement_speed"] = increased.get("movement_speed", 0.0) + v
	elif "critical" in rl:
		if "chance" in rl: increased["critical_chance"] = increased.get("critical_chance", 0.0) + v
		elif "multiplier" in rl or "damage bonus" in rl: increased["critical_multiplier"] = increased.get("critical_multiplier", 0.0) + v
	elif "accuracy" in rl: increased["accuracy"] = increased.get("accuracy", 0.0) + v
	elif "block" in rl:
		if "chance" in rl: flat_mod["base_block_chance"] = flat_mod.get("base_block_chance", 0.0) + v
	elif "area of effect" in rl or ("area" in rl and "presence" not in rl): increased["area_of_effect"] = increased.get("area_of_effect", 0.0) + v
	elif "skill speed" in rl: increased["skill_speed"] = increased.get("skill_speed", 0.0) + v
	elif "proj speed" in rl or "projectile speed" in rl or "bolt speed" in rl: increased["projectile_speed"] = increased.get("projectile_speed", 0.0) + v
	elif "ailment" in rl:
		_parse_ailment_modifier(rl, increased, val)
	elif "stun" in rl:
		if "threshold" in rl: increased["stun_threshold"] = increased.get("stun_threshold", 0.0) + v
	elif "threat" in rl: increased["threat_generation"] = increased.get("threat_generation", 0.0) + v
	elif "debuffs on you" in rl or "debuffs on you expire" in rl:
		increased["debuff_expiry_speed"] = increased.get("debuff_expiry_speed", 0.0) + v
	elif "slow potency" in rl or "slowing potency" in rl:
		flat_mod["slow_potency_reduction"] = flat_mod.get("slow_potency_reduction", 0.0) + v
	elif "hazard" in rl:
		if "damage" in rl: increased["hazard_damage"] = increased.get("hazard_damage", 0.0) + v
		elif "duration" in rl: increased["hazard_duration"] = increased.get("hazard_duration", 0.0) + v
		elif "area" in rl: increased["hazard_area"] = increased.get("hazard_area", 0.0) + v
		else: increased["hazard_damage"] = increased.get("hazard_damage", 0.0) + v
	elif "presence" in rl and "area" in rl:
		increased["presence_area"] = increased.get("presence_area", 0.0) + v
	elif "warcry" in rl:
		if "damage" in rl: increased["warcry_damage"] = increased.get("warcry_damage", 0.0) + v
		if "speed" in rl: increased["warcry_speed"] = increased.get("warcry_speed", 0.0) + v
	elif "chance to" in rl and "on hit" in rl:
		_parse_chance_on_hit(rl, val, flat_mod)


func _parse_conditional_against(rl: String) -> String:
	"""Parse 'X% increased damage against Y' patterns into damage_vs_Y keys."""
	if "blinded" in rl or "blind" in rl: return "damage_vs_blinded"
	if "burning" in rl: return "damage_vs_burning"
	if "chilled" in rl: return "damage_vs_chilled"
	if "shocked" in rl: return "damage_vs_shocked"
	if "ignited" in rl: return "damage_vs_ignited"
	if "frozen" in rl: return "damage_vs_frozen"
	if "low life" in rl or "on low life" in rl: return "damage_vs_low_life"
	if "full life" in rl or "on full life" in rl: return "damage_vs_full_life"
	if "ailments" in rl or "affected by ailments" in rl: return "damage_vs_ailments"
	if "elemental ailments" in rl: return "damage_vs_ailments"
	if "dazed" in rl: return "damage_vs_dazed"
	if "maimed" in rl: return "damage_vs_maimed"
	if "immobilised" in rl: return "damage_vs_immobilised"
	if "hindered" in rl: return "damage_vs_hindered"
	if "rare" in rl or "unique" in rl: return "damage_vs_rare_unique"
	if "heavy stun" in rl or "heavy stunned" in rl: return "damage_vs_heavy_stun"
	if "fully broken" in rl: return "damage_vs_fully_broken"
	return ""


func _parse_chance_on_hit(rl: String, val: float, flat_mod: Dictionary) -> void:
	"""Parse 'X% chance to Y on hit' patterns."""
	if "bleed" in rl: flat_mod["bleed_chance"] = flat_mod.get("bleed_chance", 0.0) + val
	elif "poison" in rl: flat_mod["poison_chance"] = flat_mod.get("poison_chance", 0.0) + val
	elif "blind" in rl: flat_mod["blind_chance"] = flat_mod.get("blind_chance", 0.0) + val
	elif "daze" in rl: flat_mod["daze_chance"] = flat_mod.get("daze_chance", 0.0) + val
	elif "maim" in rl: flat_mod["maim_chance"] = flat_mod.get("maim_chance", 0.0) + val
	elif "hinder" in rl: flat_mod["hinder_chance"] = flat_mod.get("hinder_chance", 0.0) + val
	elif "impale" in rl: flat_mod["impale_chance"] = flat_mod.get("impale_chance", 0.0) + val
	elif "aggravate" in rl and "bleed" in rl: flat_mod["aggravate_bleed_chance"] = flat_mod.get("aggravate_bleed_chance", 0.0) + val


func _parse_extra_damage(rl: String, val: float, flat_mod: Dictionary) -> void:
	"""Parse 'gain X% of <source> damage as extra <target> damage' patterns.
	Supports sources: all, physical, elemental, cold, fire, lightning, chaos.
	Supports conditionals: against Frozen/Chilled/Shocked/Ignited/Dazed/HeavyStunned etc.
	"""
	var rl_lower: String = rl.to_lower()

	# --- Detect source ---
	var extra_source := ""
	if "of physical" in rl_lower:
		extra_source = "physical"
	elif "of cold" in rl_lower:
		extra_source = "cold"
	elif "of fire" in rl_lower:
		extra_source = "fire"
	elif "of lightning" in rl_lower:
		extra_source = "lightning"
	elif "of chaos" in rl_lower:
		extra_source = "chaos"
	elif "of elemental" in rl_lower:
		extra_source = "elemental"
	elif "of damage" in rl_lower or "of all" in rl_lower:
		extra_source = "all"

	if extra_source.is_empty():
		return  # couldn't determine source

	# --- Detect target element ---
	var extra_target := ""
	if "fire" in rl_lower and "extra fire" in rl_lower:
		extra_target = "fire"
	elif "cold" in rl_lower and "extra cold" in rl_lower:
		extra_target = "cold"
	elif "lightning" in rl_lower and "extra lightning" in rl_lower:
		extra_target = "lightning"
	elif "chaos" in rl_lower and "extra chaos" in rl_lower:
		extra_target = "chaos"
	elif "physical" in rl_lower and "extra physical" in rl_lower:
		extra_target = "physical"

	if extra_target.is_empty():
		return  # couldn't determine target

	# --- Build base key ---
	var base_key: String = "extra_" + extra_source + "_" + extra_target

	# --- Check for conditional: "against X" or "while on X Ground" ---
	var condition := ""
	if "against" in rl_lower:
		if "frozen" in rl_lower: condition = "frozen"
		elif "ignited" in rl_lower: condition = "ignited"
		elif "shocked" in rl_lower: condition = "shocked"
		elif "chilled" in rl_lower: condition = "chilled"
		elif "dazed" in rl_lower: condition = "dazed"
		elif "heavy stunned" in rl_lower or "heavy stun" in rl_lower: condition = "heavy_stun"
		elif "electrocuted" in rl_lower: condition = "electrocuted"
	elif "while on" in rl_lower or "while standing on" in rl_lower:
		if "shocked ground" in rl_lower: condition = "shocked_ground"
		elif "ignited ground" in rl_lower: condition = "ignited_ground"
		elif "chilled ground" in rl_lower: condition = "chilled_ground"
	elif "per" in rl_lower and "charge consumed" in rl_lower:
		# "per Endurance Charge consumed Recently" — too complex, skip conditional
		pass

	if condition.is_empty():
		# No conditional — simple extra damage
		flat_mod[base_key] = flat_mod.get(base_key, 0.0) + val
	else:
		# Conditional extra damage: key = "extra_source_target_condition"
		var cond_key: String = base_key + "_" + condition
		flat_mod[cond_key] = flat_mod.get(cond_key, 0.0) + val


func _parse_penetration(rl: String, val: float, flat_mod: Dictionary) -> void:
	"""Parse 'damage penetrates X% Y resistance' patterns."""
	if "fire" in rl: flat_mod["penetration_fire"] = flat_mod.get("penetration_fire", 0.0) + val
	elif "cold" in rl: flat_mod["penetration_cold"] = flat_mod.get("penetration_cold", 0.0) + val
	elif "lightning" in rl: flat_mod["penetration_lightning"] = flat_mod.get("penetration_lightning", 0.0) + val
	elif "chaos" in rl: flat_mod["penetration_chaos"] = flat_mod.get("penetration_chaos", 0.0) + val
	elif "elemental" in rl: flat_mod["penetration_elemental"] = flat_mod.get("penetration_elemental", 0.0) + val


func _parse_ailment_modifier(rl: String, increased: Dictionary, val: float) -> void:
	"""Parse ailment modifier patterns. Artik gercek val kullaniliyor."""
	if "magnitude" in rl:
		if "shock" in rl: increased["shock_magnitude"] = increased.get("shock_magnitude", 0.0) + val
		elif "chill" in rl: increased["chill_magnitude"] = increased.get("chill_magnitude", 0.0) + val
		elif "ignite" in rl: increased["ignite_magnitude"] = increased.get("ignite_magnitude", 0.0) + val
		elif "bleeding" in rl: increased["bleed_magnitude"] = increased.get("bleed_magnitude", 0.0) + val
		elif "ailment" in rl: increased["ailment_magnitude"] = increased.get("ailment_magnitude", 0.0) + val
		elif "poison" in rl: increased["poison_magnitude"] = increased.get("poison_magnitude", 0.0) + val
	elif "chance" in rl:
		if "shock" in rl: increased["shock_chance"] = increased.get("shock_chance", 0.0) + val
		elif "ignite" in rl: increased["ignite_chance"] = increased.get("ignite_chance", 0.0) + val
		elif "chill" in rl: increased["chill_chance"] = increased.get("chill_chance", 0.0) + val
		elif "freeze" in rl: increased["freeze_chance"] = increased.get("freeze_chance", 0.0) + val
		elif "poison" in rl: increased["poison_chance"] = increased.get("poison_chance", 0.0) + val
		elif "bleeding" in rl: increased["bleed_chance"] = increased.get("bleed_chance", 0.0) + val
		else: increased["ailment_chance"] = increased.get("ailment_chance", 0.0) + val
	elif "duration" in rl:
		if "on you" in rl: increased["ailment_duration_on_you"] = increased.get("ailment_duration_on_you", 0.0) + val
		else: increased["ailment_duration"] = increased.get("ailment_duration", 0.0) + val
	elif "effect" in rl: increased["ailment_effect"] = increased.get("ailment_effect", 0.0) + val
	elif "threshold" in rl: increased["ailment_threshold"] = increased.get("ailment_threshold", 0.0) + val
	elif "faster" in rl or "speed" in rl: increased["ailment_speed"] = increased.get("ailment_speed", 0.0) + val


func _parse_max_resistance(raw: String, flat_mod: Dictionary) -> void:
	var rl := raw.to_lower()
	var val := _extract_first_number(raw)
	if val <= 0.0: return
	if "all elemental" in rl or "all maximum" in rl:
		flat_mod["max_fire_resistance"] = flat_mod.get("max_fire_resistance", 0.0) + val
		flat_mod["max_cold_resistance"] = flat_mod.get("max_cold_resistance", 0.0) + val
		flat_mod["max_lightning_resistance"] = flat_mod.get("max_lightning_resistance", 0.0) + val
		flat_mod["max_chaos_resistance"] = flat_mod.get("max_chaos_resistance", 0.0) + val
	elif "cold" in rl: flat_mod["max_cold_resistance"] = flat_mod.get("max_cold_resistance", 0.0) + val
	elif "fire" in rl: flat_mod["max_fire_resistance"] = flat_mod.get("max_fire_resistance", 0.0) + val
	elif "lightning" in rl: flat_mod["max_lightning_resistance"] = flat_mod.get("max_lightning_resistance", 0.0) + val
	elif "chaos" in rl: flat_mod["max_chaos_resistance"] = flat_mod.get("max_chaos_resistance", 0.0) + val


func _flag_missing(key: String) -> void:
	"""Placeholder for unsupported mechanics."""
	pass


func _extract_first_number(raw: String) -> float:
	var m := RegEx.create_from_string(r"([+\-]?\d+\.?\d*)").search(raw)
	if m: return float(m.get_string(1))
	return 0.0
