import json, re

with open('data/passive_skill_tree.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

raw_texts = set()
for node in data.get('nodes', []):
    for mod in node.get('modifiers', []):
        raw_texts.add(mod.get('raw', ''))
for node in data.get('ascendancy_nodes', []):
    for mod in node.get('modifiers', []):
        raw_texts.add(mod.get('raw', ''))

sorted_texts = sorted(raw_texts)
print(f'Total unique raw texts: {len(sorted_texts)}')

def extract_num(raw):
    m = re.search(r'[+\-]?\d+\.?\d*', raw)
    return float(m.group()) if m else 0.0

def parse_raw(raw):
    rl = raw.lower()
    val = extract_num(raw)
    inc = {}
    flat = {}
    if val == 0.0:
        if 'cannot be blinded' in rl: flat['cannot_be_blinded'] = 1.0
        return bool(inc or flat)
    if 'surrounded' not in rl and ('increased' in rl or 'more' in rl or 'reduced' in rl):
        pct = val
        if 'damage' in rl:
            di = rl.index('damage')
            bd = rl[:di]
            tr = bd.strip()
            if 'physical' in bd: inc['physical_damage'] = inc.get('physical_damage', 0) + pct
            elif 'fire' in bd: inc['fire_damage'] = inc.get('fire_damage', 0) + pct
            elif 'cold' in bd: inc['cold_damage'] = inc.get('cold_damage', 0) + pct
            elif 'lightning' in bd: inc['lightning_damage'] = inc.get('lightning_damage', 0) + pct
            elif 'chaos' in bd: inc['chaos_damage'] = inc.get('chaos_damage', 0) + pct
            elif 'elemental' in bd: inc['elemental_damage'] = inc.get('elemental_damage', 0) + pct
            elif 'spell' in bd: inc['spell_damage'] = inc.get('spell_damage', 0) + pct
            elif 'over time' in bd or 'damage over time' in rl: inc['damage_over_time'] = inc.get('damage_over_time', 0) + pct
            elif 'projectile' in bd: inc['projectile_damage'] = inc.get('projectile_damage', 0) + pct
            elif 'area' in bd: inc['area_damage'] = inc.get('area_damage', 0) + pct
            elif 'poison' in bd: inc['damage_over_time'] = inc.get('damage_over_time', 0) + pct
            elif 'attack' in bd: inc['all_damage'] = inc.get('all_damage', 0) + pct
            elif 'melee' in bd: inc['all_damage'] = inc.get('all_damage', 0) + pct
            elif 'damage' in tr or tr == '': inc['all_damage'] = inc.get('all_damage', 0) + pct
    if 'attack speed' in rl and 'while' not in rl: inc['attack_speed'] = inc.get('attack_speed', 0) + val
    if 'cast speed' in rl and 'while' not in rl: inc['cast_speed'] = inc.get('cast_speed', 0) + val
    if 'movement speed' in rl or 'move speed' in rl: inc['movement_speed'] = inc.get('movement_speed', 0) + val
    if 'skill speed' in rl:
        inc['attack_speed'] = inc.get('attack_speed', 0) + val * 0.5
        inc['cast_speed'] = inc.get('cast_speed', 0) + val * 0.5
    if 'critical hit chance' in rl or 'critical chance' in rl: inc['critical_chance'] = inc.get('critical_chance', 0) + val
    if 'critical damage bonus' in rl or 'critical multiplier' in rl: inc['critical_multiplier'] = inc.get('critical_multiplier', 0) + val
    if '+1% to critical hit chance' in rl or '+1% to critical strike chance' in rl: flat['critical_chance'] = flat.get('critical_chance', 0) + 1.0
    if 'accuracy rating' in rl: inc['accuracy'] = inc.get('accuracy', 0) + val
    if 'evasion rating' in rl: inc['evasion'] = inc.get('evasion', 0) + val
    if 'armour' in rl and 'break' not in rl and 'broken' not in rl and 'applies' not in rl: inc['armour'] = inc.get('armour', 0) + val
    if 'maximum energy shield' in rl: inc['max_energy_shield'] = inc.get('max_energy_shield', 0) + val
    if 'maximum mana' in rl: inc['max_mana'] = inc.get('max_mana', 0) + val
    if 'maximum life' in rl: inc['max_life'] = inc.get('max_life', 0) + val
    if ('life regeneration' in rl or 'regen' in rl) and 'life' in rl: inc['life_regen'] = inc.get('life_regen', 0) + val
    if 'mana regeneration' in rl: inc['mana_regen'] = inc.get('mana_regen', 0) + val
    if 'life recovery' in rl or 'recovery rate' in rl: inc['life_recovery_rate'] = inc.get('life_recovery_rate', 0) + val
    if 'mana recovery' in rl: inc['mana_recovery_rate'] = inc.get('mana_recovery_rate', 0) + val


    if any(x in rl for x in ['ailment','ignite','bleeding','poison','shock','chill','freeze']):
        pm = re.search(r'(\d+(?:\.\d+)?)%', rl)
        if pm:
            pv = float(pm.group(1))
            if 'magnitude of shock' in rl: inc['shock_magnitude'] = inc.get('shock_magnitude', 0) + pv
            elif 'magnitude of chill' in rl: inc['chill_magnitude'] = inc.get('chill_magnitude', 0) + pv
            elif 'ignite magnitude' in rl: inc['ignite_magnitude'] = inc.get('ignite_magnitude', 0) + pv
            elif 'magnitude of bleeding' in rl or 'bleeding magnitude' in rl: inc['bleed_magnitude'] = inc.get('bleed_magnitude', 0) + pv
            elif 'magnitude of ailments' in rl or 'magnitude of non-damaging ailments' in rl: inc['ailment_magnitude'] = inc.get('ailment_magnitude', 0) + pv
        if ('ailments deal damage' in rl or 'damaging ailments' in rl) and 'faster' in rl: inc['ailment_speed'] = inc.get('ailment_speed', 0) + val
        if 'ignite' in rl and 'faster' in rl: inc['ignite_speed'] = inc.get('ignite_speed', 0) + val
        if 'bleed' in rl and 'faster' in rl: inc['bleed_speed'] = inc.get('bleed_speed', 0) + val
        if ('chance to inflict' in rl or 'increased chance to' in rl) and 'ailment' in rl: inc['ailment_chance'] = inc.get('ailment_chance', 0) + val
        if 'poison duration' in rl: inc['poison_duration'] = inc.get('poison_duration', 0) + val


    if 'skill effect duration' in rl: inc['skill_effect_duration'] = inc.get('skill_effect_duration', 0) + val
    if 'area of effect' in rl: inc['area_of_effect'] = inc.get('area_of_effect', 0) + val
    if 'cooldown recovery' in rl: inc['cooldown_recovery'] = inc.get('cooldown_recovery', 0) + val
    if 'mana cost efficiency' in rl or 'cost efficiency' in rl: inc['mana_cost_efficiency'] = inc.get('mana_cost_efficiency', 0) + val
    if 'mana costs converted' in rl or 'life costs' in rl: flat['life_cost_pct'] = flat.get('life_cost_pct', 0) + val
    if 'resistance' in rl and 'maximum' not in rl and 'penetrat' not in rl:
        if 'all' in rl: flat['all_resistance'] = flat.get('all_resistance', 0) + val
        elif 'fire' in rl: flat['fire_resistance'] = flat.get('fire_resistance', 0) + val
        elif 'cold' in rl: flat['cold_resistance'] = flat.get('cold_resistance', 0) + val
        elif 'lightning' in rl: flat['lightning_resistance'] = flat.get('lightning_resistance', 0) + val
        elif 'chaos' in rl: flat['chaos_resistance'] = flat.get('chaos_resistance', 0) + val
    if 'to strength' in rl: flat['strength'] = flat.get('strength', 0) + val
    if 'to dexterity' in rl: flat['dexterity'] = flat.get('dexterity', 0) + val
    if 'to intelligence' in rl: flat['intelligence'] = flat.get('intelligence', 0) + val
    if 'to all attributes' in rl or 'to all stats' in rl:
        flat['strength'] = flat.get('strength', 0) + val
        flat['dexterity'] = flat.get('dexterity', 0) + val
        flat['intelligence'] = flat.get('intelligence', 0) + val
    if 'amount of life leeched' in rl or 'amount of mana leeched' in rl: inc['leech_amount'] = inc.get('leech_amount', 0) + val
    if 'leech life' in rl and 'slower' in rl: inc['leech_speed'] = inc.get('leech_speed', 0) - val
    if 'attack speed while leeching' in rl: inc['attack_speed_while_leeching'] = inc.get('attack_speed_while_leeching', 0) + val
    if 'damage while leeching' in rl: inc['damage_while_leeching'] = inc.get('damage_while_leeching', 0) + val
    if 'armour' in rl and 'evasion' in rl and 'leeching' in rl: inc['armour_evasion_while_leeching'] = inc.get('armour_evasion_while_leeching', 0) + val
    if 'block chance' in rl: inc['block_chance'] = inc.get('block_chance', 0) + val
    if 'maximum block' in rl: flat['attack_block_chance'] = flat.get('attack_block_chance', 0) + val
    if 'block recovery' in rl: inc['block_recovery'] = inc.get('block_recovery', 0) + val
    if 'life when you block' in rl or 'life gained when you block' in rl: flat['life_on_block'] = flat.get('life_on_block', 0) + val
    if 'penetrates' in rl and 'resistance' in rl:
        if 'elemental' in rl: flat['penetration_elemental'] = flat.get('penetration_elemental', 0) + val
        elif 'fire' in rl: flat['penetration_fire'] = flat.get('penetration_fire', 0) + val
        elif 'cold' in rl: flat['penetration_cold'] = flat.get('penetration_cold', 0) + val
        elif 'lightning' in rl: flat['penetration_lightning'] = flat.get('penetration_lightning', 0) + val
    if 'exposure effect' in rl: inc['exposure_effect'] = inc.get('exposure_effect', 0) + val
    if 'culling strike' in rl and 'threshold' in rl: flat['culling_threshold'] = flat.get('culling_threshold', 0) + val
    if 'recouped' in rl or 'recoup' in rl:
        if 'life' in rl: flat['life_recoup'] = flat.get('life_recoup', 0) + val
        if 'mana' in rl: flat['mana_recoup'] = flat.get('mana_recoup', 0) + val
        if 'speed' in rl or 'faster' in rl: inc['recoup_speed'] = inc.get('recoup_speed', 0) + val


    if 'armour break' in rl or 'break armour' in rl or 'break' in rl:
        if 'duration' in rl: inc['armour_break_duration'] = inc.get('armour_break_duration', 0) + val
        elif 'fully broken' in rl or 'effect of' in rl: inc['armour_break_effect'] = inc.get('armour_break_effect', 0) + val
        elif 'increased armour' not in rl: inc['armour_break'] = inc.get('armour_break', 0) + val
    if 'daze' in rl or 'dazed' in rl:
        if 'chance' in rl or 'on hit' in rl: flat['daze_chance'] = flat.get('daze_chance', 0) + val
        if 'duration' in rl: inc['daze_duration'] = inc.get('daze_duration', 0) + val
        if 'damage against' in rl or 'against dazed' in rl: inc['damage_vs_dazed'] = inc.get('damage_vs_dazed', 0) + val
    if 'blind' in rl:
        if 'chance' in rl or 'on hit' in rl: flat['blind_chance'] = flat.get('blind_chance', 0) + val
        if 'effect' in rl or 'blind effect' in rl: inc['blind_effect'] = inc.get('blind_effect', 0) + val
        if 'duration' in rl: inc['blind_duration'] = inc.get('blind_duration', 0) + val
    if 'electrocute buildup' in rl: inc['electrocute_buildup'] = inc.get('electrocute_buildup', 0) + val
    if 'thorns' in rl:
        if 'damage' in rl or 'thorns damage' in rl: flat['thorns'] = flat.get('thorns', 0) + val
        if 'chance' in rl: flat['thorns_chance'] = flat.get('thorns_chance', 0) + val
    if 'aura skill' in rl and 'magnitude' in rl: inc['aura_magnitude'] = inc.get('aura_magnitude', 0) + val
    if 'withered' in rl:
        if 'magnitude' in rl: inc['withered_magnitude'] = inc.get('withered_magnitude', 0) + val
        if 'apply' in rl or 'inflict' in rl or 'chance' in rl: flat['withered_chance'] = flat.get('withered_chance', 0) + val
        if 'decay' in rl or 'duration' in rl: inc['withered_duration'] = inc.get('withered_duration', 0) + val
        if 'reduced damage' in rl or 'less damage' in rl: flat['withered_damage_reduction'] = flat.get('withered_damage_reduction', 0) + val
    if 'chance to inflict' in rl or 'chance to poison' in rl or 'chance to bleed' in rl:
        if 'bleed' in rl or 'bleeding' in rl: flat['bleed_chance'] = flat.get('bleed_chance', 0) + val
        if 'poison' in rl: flat['poison_chance'] = flat.get('poison_chance', 0) + val
    if 'to level of all' in rl or '+1 to level' in rl:
        if 'cold' in rl: flat['cold_skill_level'] = flat.get('cold_skill_level', 0) + val
        if 'fire' in rl: flat['fire_skill_level'] = flat.get('fire_skill_level', 0) + val
        if 'lightning' in rl: flat['lightning_skill_level'] = flat.get('lightning_skill_level', 0) + val
        if 'chaos' in rl: flat['chaos_skill_level'] = flat.get('chaos_skill_level', 0) + val
    if 'life per enemy killed' in rl or 'life on kill' in rl: flat['life_on_kill'] = flat.get('life_on_kill', 0) + val
    if 'mana on kill' in rl: flat['mana_on_kill'] = flat.get('mana_on_kill', 0) + val
    if 'light radius' in rl: inc['light_radius'] = inc.get('light_radius', 0) + val
    if 'slowing potency' in rl or 'slow potency' in rl: flat['slow_potency_reduction'] = flat.get('slow_potency_reduction', 0) + val
    if 'debuffs on you expire' in rl: inc['debuff_expiry_speed'] = inc.get('debuff_expiry_speed', 0) + val
    if 'debuffs you inflict' in rl and 'slow magnitude' in rl: inc['slow_magnitude'] = inc.get('slow_magnitude', 0) + val


    if 'gain' in rl and 'extra' in rl and 'damage' in rl:
        pe = val; src = ''; tgt = ''
        if 'physical damage' in rl and 'as extra' in rl: src = 'physical'
        elif 'elemental damage' in rl and 'as extra' in rl: src = 'elemental'
        elif 'fire damage' in rl and 'as extra' in rl: src = 'fire'
        elif 'cold damage' in rl and 'as extra' in rl: src = 'cold'
        elif 'lightning damage' in rl and 'as extra' in rl: src = 'lightning'
        elif 'damage as extra' in rl: src = 'all'
        if 'as extra fire' in rl: tgt = 'fire'
        elif 'as extra cold' in rl: tgt = 'cold'
        elif 'as extra lightning' in rl: tgt = 'lightning'
        elif 'as extra chaos' in rl: tgt = 'chaos'
        elif 'as extra physical' in rl: tgt = 'physical'
        if src and tgt: flat[f'extra_{src}_{tgt}'] = flat.get(f'extra_{src}_{tgt}', 0) + pe
        elif tgt: flat[f'extra_all_{tgt}'] = flat.get(f'extra_all_{tgt}', 0) + pe
    if 'lucky' in rl:
        if 'with hits' in rl or 'damage with hits' in rl: flat['lucky_hits'] = flat.get('lucky_hits', 0) + 1.0
        if 'lightning' in rl: flat['lucky_lightning'] = flat.get('lucky_lightning', 0) + 1.0
        if 'chance' in rl: flat['lucky_chance'] = flat.get('lucky_chance', 0) + val
    if 'unlucky' in rl:
        if 'hitting you' in rl: flat['enemy_unlucky'] = flat.get('enemy_unlucky', 0) + 1.0
        if 'chance' in rl: flat['unlucky_chance'] = flat.get('unlucky_chance', 0) + val
    if 'aggravated' in rl or 'aggravate' in rl:
        if 'bleeding you inflict is aggravated' in rl: flat['aggravated_bleeding'] = 1.0
        if 'chance to aggravate' in rl or 'chance for bleeding to be aggravated' in rl: flat['aggravate_bleed_chance'] = flat.get('aggravate_bleed_chance', 0) + val
    if 'splash damage' in rl or 'deal splash' in rl: flat['splash_damage'] = flat.get('splash_damage', 0) + 1.0
    if 'maim' in rl or 'maimed' in rl:
        if 'chance to maim' in rl or 'chance for attacks to maim' in rl: flat['maim_chance'] = flat.get('maim_chance', 0) + val
        if 'immune to maim' in rl: flat['immune_to_maim'] = 1.0
        if 'damage against' in rl or 'against maimed' in rl: inc['damage_vs_maimed'] = inc.get('damage_vs_maimed', 0) + val
        if 'enemies you fully armour break are maimed' in rl: flat['maim_on_armourbreak'] = 1.0
        if 'attacks have' in rl and 'maim on hit' in rl: flat['maim_chance'] = flat.get('maim_chance', 0) + val
    if 'surrounded' in rl:
        if 'area of effect' in rl: inc['area_of_effect'] = inc.get('area_of_effect', 0) + val
        elif 'attack damage' in rl or 'melee damage' in rl: inc['surrounded_attack_damage'] = inc.get('surrounded_attack_damage', 0) + val
        elif 'attack speed' in rl: inc['surrounded_attack_speed'] = inc.get('surrounded_attack_speed', 0) + val
        elif 'movement speed' in rl or 'move speed' in rl: inc['surrounded_movement_speed'] = inc.get('surrounded_movement_speed', 0) + val
        elif 'armour' in rl: inc['surrounded_armour'] = inc.get('surrounded_armour', 0) + val
        elif 'evasion' in rl: inc['surrounded_evasion'] = inc.get('surrounded_evasion', 0) + val
        elif 'accuracy' in rl: inc['surrounded_accuracy'] = inc.get('surrounded_accuracy', 0) + val
        elif 'life' in rl: inc['surrounded_life_regen'] = inc.get('surrounded_life_regen', 0) + val
        else: inc['surrounded_all_damage'] = inc.get('surrounded_all_damage', 0) + val
    if 'fully broken' in rl or 'fully armour break' in rl:
        if 'fire damage taken' in rl: flat['fully_broken_fire_dmg_taken'] = 1.0
        if 'cold and lightning damage taken' in rl: flat['fully_broken_cold_lightning_taken'] = 1.0
        if 'cannot regenerate life' in rl: flat['fully_broken_no_regen'] = 1.0
        if 'are maimed' in rl: flat['maim_on_armourbreak'] = 1.0
    if 'melee strike range' in rl and val > 0.0: flat['melee_range'] = flat.get('melee_range', 0) + (val * 25.0)
    if ('armour also applies' in rl or 'armour also' in rl) and val > 0.0: flat['armour_elemental_pct'] = flat.get('armour_elemental_pct', 0) + val
    if '% to maximum' in rl and 'resistance' in rl and val > 0.0:
        rl2 = raw.lower()
        if 'all elemental' in rl2 or 'all maximum' in rl2:
            flat['max_fire_resistance'] = flat.get('max_fire_resistance', 0) + val
            flat['max_cold_resistance'] = flat.get('max_cold_resistance', 0) + val
            flat['max_lightning_resistance'] = flat.get('max_lightning_resistance', 0) + val
            flat['max_chaos_resistance'] = flat.get('max_chaos_resistance', 0) + val
        elif 'cold' in rl2: flat['max_cold_resistance'] = flat.get('max_cold_resistance', 0) + val
        elif 'fire' in rl2: flat['max_fire_resistance'] = flat.get('max_fire_resistance', 0) + val
        elif 'lightning' in rl2: flat['max_lightning_resistance'] = flat.get('max_lightning_resistance', 0) + val
        elif 'chaos' in rl2: flat['max_chaos_resistance'] = flat.get('max_chaos_resistance', 0) + val
    return bool(inc or flat)


unhandled = [raw for raw in sorted_texts if not parse_raw(raw)]
print(f"Unhandled count: {len(unhandled)}")
cats = {}
for raw in unhandled:
    rl = raw.lower()
    c = 'OTHER - needs manual review'
    if 'sands of time' in rl: c = 'Unique: Sands of Time'
    elif 'thaumaturgical' in rl: c = 'Unique: Thaumaturgical Dynamism'
    elif 'unravelling' in rl: c = 'Unique: Unravelling'
    elif 'demonflame' in rl: c = 'Unique: Demonflame'
    elif 'decimating' in rl: c = 'Unique: Decimating Strike'
    elif 'walk the paths' in rl: c = 'Unique: Walk the Paths Not Taken'
    elif 'crushing blow' in rl: c = 'Unique: Crushing Blows'
    elif 'inevitable critical' in rl: c = 'Unique: Inevitable Critical'
    elif 'passive skill point' in rl: c = 'Grants: Passive Skill Point'
    elif 'additional skill slot' in rl: c = 'Grants: Additional Skill Slot'
    elif 'grant skill:' in rl or 'grants skill:' in rl: c = 'Grants: A Skill'
    elif 'allies' in rl and 'presence' in rl: c = 'Presence: Allies in Presence'
    elif 'in your presence' in rl: c = 'Presence: In your Presence effects'
    elif 'presence area' in rl: c = 'Presence Area'
    elif 'tame beast' in rl or 'tamed' in rl: c = 'Minion: Tame Beast'
    elif 'minion' in rl or 'summon' in rl or 'hound' in rl: c = 'Minion: Summon/Minion'
    elif 'ballista' in rl: c = 'Skill: Ballista'
    elif 'offering' in rl: c = 'Skill: Offering'
    elif 'banner' in rl: c = 'Skill: Banner'
    elif 'herald' in rl: c = 'Skill: Herald'
    elif 'detonator' in rl: c = 'Skill: Detonator'
    elif 'grenade' in rl: c = 'Skill: Grenade'
    elif 'trap' in rl or 'mine' in rl: c = 'Skill: Trap/Mine'
    elif 'shapeshift' in rl: c = 'Skill: Shapeshift'
    elif 'invoc' in rl: c = 'Skill: Invocation'
    elif 'seal' in rl: c = 'Skill: Seal'
    elif 'remnant' in rl: c = 'Skill: Remnant'
    elif 'infusion' in rl: c = 'Skill: Infusion'
    elif 'meta skill' in rl: c = 'Skill: Meta'
    elif 'empowered attack' in rl or 'ancestrally' in rl: c = 'Skill: Empowered Attack/Ancestral'
    elif 'fissure' in rl: c = 'Skill: Fissure'
    elif 'aftershock' in rl: c = 'Skill: Aftershock'
    elif 'slam' in rl: c = 'Skill: Slam'
    elif 'strike' in rl: c = 'Skill: Strike'
    elif 'channelling' in rl: c = 'Skill: Channelling'
    elif 'plant' in rl or 'overgrow' in rl: c = 'Skill: Plant'
    elif 'storm' in rl or 'stag' in rl: c = 'Skill: Storm/Stag'
    elif 'hazard' in rl: c = 'Skill: Hazard'
    elif 'orb skill' in rl: c = 'Skill: Orb'
    elif 'concoction' in rl: c = 'Skill: Concoction'
    elif 'projectile' in rl or 'pierce' in rl or 'fork' in rl or 'chain' in rl: c = 'Projectile mechanics'
    elif 'crossbow' in rl or 'bolt' in rl or 'ammunition' in rl or 'reload' in rl: c = 'Weapon: Crossbow/Ammunition'
    elif 'quarterstaff' in rl: c = 'Weapon: Quarterstaff'
    elif 'spear' in rl: c = 'Weapon: Spear'
    elif 'flail' in rl: c = 'Weapon: Flail'
    elif 'dagger' in rl: c = 'Weapon: Dagger'
    elif 'mace' in rl: c = 'Weapon: Mace'
    elif 'axe' in rl: c = 'Weapon: Axe'
    elif 'sword' in rl: c = 'Weapon: Sword'
    elif 'staff' in rl: c = 'Weapon: Staff'
    elif 'bow' in rl and 'crossbow' not in rl: c = 'Weapon: Bow'
    elif 'rage' in rl: c = 'Rage mechanic'
    elif 'glory' in rl: c = 'Glory mechanic'
    elif 'combo' in rl: c = 'Combo mechanic'
    elif 'pin' in rl or 'pinned' in rl: c = 'Pin mechanic'
    elif 'immobil' in rl: c = 'Immobilise mechanic'
    elif 'heavy stun' in rl: c = 'Heavy Stun mechanic'
    elif 'concentration' in rl: c = 'Concentration mechanic'
    elif 'parry' in rl: c = 'Parry mechanic'
    elif 'incision' in rl: c = 'Incision mechanic'
    elif 'intimidat' in rl: c = 'Intimidate mechanic'
    elif 'volatility' in rl or 'volatile power' in rl: c = 'Volatility mechanic'
    elif 'infernal flame' in rl: c = 'Infernal Flame mechanic'
    elif 'archon' in rl or 'arcane surge' in rl: c = 'Archon/Arcane Surge mechanic'
    elif 'tailwind' in rl: c = 'Tailwind mechanic'
    elif 'onslaught' in rl: c = 'Onslaught mechanic'
    elif 'wisp' in rl or 'vivid' in rl: c = 'Vivid Wisp mechanic'
    elif 'owl feather' in rl or 'primal bounty' in rl: c = 'Owl Feather/Primal Bounty'
    elif 'jade' in rl: c = 'Jade mechanic'
    elif 'rune' in rl or 'tattoo' in rl: c = 'Rune/Tattoo mechanic'
    elif 'idol' in rl: c = 'Idol mechanic'
    elif 'socket' in rl or 'support gem' in rl: c = 'Socket/Gem mechanic'
    elif 'gem quality' in rl: c = 'Gem Quality'
    elif 'reservation' in rl: c = 'Reservation mechanic'
    elif 'charge' in rl: c = 'Charge mechanic'
    elif 'dodge roll' in rl or 'sprint' in rl: c = 'Movement: Dodge Roll/Sprint'
    elif 'dodge' in rl: c = 'Dodge mechanic'
    elif 'unarmed' in rl: c = 'Unarmed mechanic'
    elif 'dual wield' in rl or 'two-hand' in rl or 'one-hand' in rl: c = 'Weapon type: Dual/Two/One Hand'
    elif 'shield' in rl: c = 'Equipment: Shield'
    elif 'focus' in rl: c = 'Equipment: Focus'
    elif 'quiver' in rl: c = 'Equipment: Quiver'
    elif 'body armour' in rl or 'helmet' in rl or 'gloves' in rl or 'boots' in rl: c = 'Equipment: Armour Slot'
    elif 'flask' in rl or 'charm' in rl: c = 'Equipment: Flask/Charm'
    elif 'immune' in rl or 'cannot' in rl or 'unaffected' in rl or 'never' in rl: c = 'Immunity/Unaffected'
    elif 'explode' in rl: c = 'Explosion effect'
    elif 'converted' in rl or 'convert' in rl: c = 'Conversion mechanic'
    elif 'damage taken' in rl: c = 'Damage Taken modifier'
    elif 'recover' in rl: c = 'Recovery effect'
    elif 'regenerat' in rl or 'regen' in rl: c = 'Regeneration effect'
    elif 'gain' in rl and 'extra' in rl and 'damage' in rl: c = 'Gain as Extra Damage (conditional)'
    elif 'gain' in rl and 'damage' in rl: c = 'Gain Damage effect'
    elif 'gain' in rl: c = 'Gain effect'
    elif ('increased' in rl and 'damage' in rl) or ('more' in rl and 'damage' in rl) or ('reduced' in rl and 'damage' in rl) or ('less' in rl and 'damage' in rl): c = 'DAMAGE PARSER BUG: generic increased/reduced/more/less damage not matched'
    elif 'damage' in rl: c = 'DAMAGE: Other unhandled'
    elif 'attack speed' in rl: c = 'SPEED: Conditional attack speed'
    elif 'cast speed' in rl: c = 'SPEED: Conditional cast speed'
    elif 'movement speed' in rl: c = 'SPEED: Conditional movement speed'
    elif 'skill speed' in rl: c = 'SPEED: Skill speed'
    elif 'critical' in rl: c = 'CRIT: Conditional/partial'
    elif 'life' in rl and 'mana' in rl: c = 'Life/Mana interaction'
    elif 'life' in rl: c = 'Life-specific'
    elif 'mana' in rl: c = 'Mana-specific'
    elif 'energy shield' in rl: c = 'Energy Shield-specific'
    elif 'armour' in rl: c = 'Armour-specific'
    elif 'evasion' in rl: c = 'Evasion-specific'
    elif 'accuracy' in rl: c = 'Accuracy-specific'
    elif 'block' in rl: c = 'Block-specific'
    elif 'stun' in rl: c = 'Stun-specific'
    elif 'knock' in rl: c = 'Knockback-specific'
    elif 'resistance' in rl: c = 'Resistance-specific'
    elif 'penetrat' in rl: c = 'Penetration-specific'
    elif 'exposure' in rl: c = 'Exposure-specific'
    elif 'culling' in rl: c = 'Culling Strike-specific'
    elif 'splash' in rl: c = 'Splash-specific'
    elif 'lucky' in rl or 'unlucky' in rl: c = 'Lucky/Unlucky-specific'
    elif 'aggravat' in rl: c = 'Aggravated Bleeding-specific'
    elif 'maim' in rl: c = 'Maim-specific'
    elif 'blind' in rl: c = 'Blind-specific'
    elif 'daze' in rl: c = 'Daze-specific'
    elif 'wither' in rl: c = 'Withered-specific'
    elif 'electrocute' in rl: c = 'Electrocute-specific'
    elif 'thorns' in rl: c = 'Thorns-specific'

    if c not in cats: cats[c] = []
    cats[c].append(raw)

print()
for cat in sorted(cats.keys()):
    items = sorted(set(cats[cat]))
    print(f"=== {cat} ({len(items)}) ===")
    for item in items:
        print(f"  {item}")
    print()

with open("data/parser_gaps_report.md", "w", encoding="utf-8") as f:
    f.write("# PARSER GAPS REPORT

")
    f.write(f"Total unique raw texts: {len(sorted_texts)}
")
    f.write(f"Unhandled count: {len(unhandled)}

")
    for cat in sorted(cats.keys()):
        items = sorted(set(cats[cat]))
        f.write(f"## {cat} ({len(items)})

")
        for item in items:
            f.write(f"- {item}
")
        f.write("
")
    print("Report saved to data/parser_gaps_report.md")
print()
for cat in sorted(cats.keys()):
    items = sorted(set(cats[cat]))
    print(f"=== {cat} ({len(items)}) ===")
    for item in items:
        print(f"  {item}")
    print()
