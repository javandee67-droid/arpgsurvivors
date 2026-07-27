#!/usr/bin/env python3
"""
PoE2 Passive Tree Excel -> JSON Converter
Maps PoE2 effects to the game's stat system (CharacterStats.gd keys).
"""

import openpyxl
import json
import re
import math

INPUT_PATH = "C:/Users/javan/Desktop/poelike/poelike/data/poe2_pasif_agac_nodelari.xlsx"
OUTPUT_PATH = "C:/Users/javan/Desktop/poelike/poelike/data/passive_skill_tree.json"

# ──────────────────────────────────────────────
# GAME STAT SYSTEM KEYS (CharacterStats.gd)
# ──────────────────────────────────────────────
# Flat base fields
BASE_FLAT_KEYS = {
    "base_life": "life",
    "mana": "mana",
    "base_mana": "mana",
    "energy_shield": "energy_shield",
    "base_energy_shield": "energy_shield",
    "base_accuracy": "accuracy",
}

# % increased modifiers (go into _passive_increased_mods)
INCREASED_KEYS = {
    "physical_damage", "elemental_damage", "spell_damage",
    "fire_damage", "cold_damage", "lightning_damage", "chaos_damage",
    "damage_over_time", "projectile_damage", "area_damage",
    "attack_speed", "cast_speed",
    "life_regen", "mana_regen",
    "cooldown_recovery", "item_rarity", "item_quantity",
    "energy_shield_regen",
}

# Flat modifiers (go into _passive_flat_mods)
FLAT_MODS = {
    "life_leech", "mana_leech", "life_gain_on_hit",
    "life_on_kill", "mana_on_kill",
    "attack_dodge_chance", "spell_dodge_chance",
}

# Direct base fields (multiply or add)
DIRECT_BASE = {
    "armour", "evasion", "max_energy_shield",
    "block_chance", "attack_block_chance",
    "critical_chance", "crit_chance", "critical_multiplier",
    "movement_speed",
    "all_resistance",
    "base_fire_resistance", "base_cold_resistance",
    "base_lightning_resistance", "base_chaos_resistance",
    "max_fire_resistance", "max_cold_resistance",
    "max_lightning_resistance", "max_chaos_resistance",
}

# Stat name -> display name (Turkish)
STAT_NAMES_TR = {
    "life": "Can",
    "mana": "Mana",
    "energy_shield": "Enerji Kalkanı",
    "accuracy": "İsabet",
    "physical_damage": "Fiziksel Hasar",
    "elemental_damage": "Element Hasarı",
    "spell_damage": "Büyü Hasarı",
    "fire_damage": "Ateş Hasarı",
    "cold_damage": "Soğuk Hasarı",
    "lightning_damage": "Yıldırım Hasarı",
    "chaos_damage": "Kaos Hasarı",
    "damage_over_time": "Zamanla Hasar",
    "projectile_damage": "Mermi Hasarı",
    "area_damage": "Alan Hasarı",
    "attack_speed": "Saldırı Hızı",
    "cast_speed": "Büyü Hızı",
    "life_regen": "Can Yenilenmesi",
    "mana_regen": "Mana Yenilenmesi",
    "cooldown_recovery": "Bekleme Süresi",
    "item_rarity": "Eşya Nadirliği",
    "item_quantity": "Eşya Miktarı",
    "armour": "Zırh",
    "evasion": "Kaçınma",
    "block_chance": "Blok Şansı",
    "critical_chance": "Kritik Şansı",
    "critical_multiplier": "Kritik Çarpanı",
    "movement_speed": "Hareket Hızı",
    "all_resistance": "Tüm Dirençler",
    "life_leech": "Can Çalma",
    "mana_leech": "Mana Çalma",
    "life_gain_on_hit": "Vuruş Başına Can",
    "life_on_kill": "Öldürmede Can",
    "mana_on_kill": "Öldürmede Mana",
    "attack_dodge_chance": "Saldırı Kaçınma",
    "spell_dodge_chance": "Büyü Kaçınma",
}

# ──────────────────────────────────────────────
# PATTERN MATCHING
# ──────────────────────────────────────────────

def parse_pct(text):
    """Extract percentage number from text like '12%'."""
    m = re.search(r'(\d+(?:\.\d+)?)\s*%', text)
    return float(m.group(1)) if m else None

def parse_flat(text):
    """Extract flat number from text like '+12', '+5 to'."""
    m = re.search(r'\+?\s*(\d+(?:\.\d+)?)', text)
    return float(m.group(1)) if m else None

def parse_flat_range(text):
    """Extract 'X to Y' range."""
    m = re.search(r'(\d+)\s*to\s*(\d+)', text)
    return (float(m.group(1)), float(m.group(2))) if m else None

def match_increased(text):
    """Match 'X% increased Y' patterns."""
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(.+)$', text)
    if not m:
        return None
    pct = float(m.group(1))
    what = m.group(2).strip()
    return (pct, what)

def match_reduced(text):
    """Match 'X% reduced Y' patterns."""
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+reduced\s+(.+)$', text)
    if not m:
        return None
    pct = float(m.group(1))
    what = m.group(2).strip()
    return (-pct, what)

def match_more_less(text):
    """Match 'X% more/less Y' patterns."""
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+(more|less)\s+(.+)$', text)
    if not m:
        return None
    pct = float(m.group(1))
    mult = 1.0 if m.group(2) == 'more' else -1.0
    what = m.group(3).strip()
    return (pct * mult, what)

def match_flat_to(text):
    """Match '+X to Y' patterns."""
    m = re.match(r'^\+?\s*(\d+(?:\.\d+)?)\s*to\s+(.+)$', text)
    if not m:
        return None
    return (float(m.group(1)), m.group(2).strip())

def match_damage_penetrates(text):
    """Match 'Damage Penetrates X% Y Resistance'."""
    m = re.match(r'^Damage\s+Penetrates\s+(\d+(?:\.\d+)?)%\s+(.+?)\s*Resistance$', text)
    if not m:
        return None
    return (float(m.group(1)), m.group(2).strip())

def match_faster_start(text):
    """Match 'X% faster start of Energy Shield Recharge'."""
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+faster\s+start\s+of\s+Energy Shield Recharge', text)
    if not m:
        return None
    return (float(m.group(1)),)

def match_gain_extra(text):
    """Match 'Gain X% of Damage as Extra Y' or 'Gain X% of Y as Extra Z'."""
    m = re.match(r'^Gain\s+(\d+(?:\.\d+)?)%\s+of\s+(.+?)\s+as\s+Extra\s+(.+)$', text)
    if not m:
        return None
    return (float(m.group(1)), m.group(2).strip(), m.group(3).strip())

def match_chance_to(text):
    """Match 'X% chance to Y' - returns (chance, effect_text)."""
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+chance\s+(?:for\s+)?(?:that\s+)?(.+)$', text)
    if not m:
        return None
    return (float(m.group(1)), m.group(2).strip())

def match_adds_damage(text):
    """Match 'Adds X to Y Z damage to Attacks'."""
    m = re.match(r'^Adds\s+(\d+)\s+to\s+(\d+)\s+(.+?)\s+damage\s+to\s+Attacks$', text)
    if not m:
        return None
    return (float(m.group(1)), float(m.group(2)), m.group(3).strip())

def match_recover_pct(text):
    """Match 'Recover X% of maximum Y on Z'."""
    m = re.match(r'^Recover\s+(\d+(?:\.\d+)?)%\s+of\s+maximum\s+(.+?)\s+on\s+(.+)$', text)
    if not m:
        m = re.match(r'^Recover\s+(\d+(?:\.\d+)?)%\s+of\s+maximum\s+(.+?)\s+when\s+(.+)$', text)
    if not m:
        m = re.match(r'^Recover\s+(\d+(?:\.\d+)?)%\s+of\s+maximum\s+(.+)$', text)
        if m:
            return (float(m.group(1)), m.group(2).strip(), "general")
    if m:
        return (float(m.group(1)), m.group(2).strip(), m.group(3).strip())
    return None

def match_regenerate_pct(text):
    """Match 'Regenerate X% of maximum Y'."""
    m = re.match(r'^Regenerate\s+(\d+(?:\.\d+)?)%\s+of\s+maximum\s+(.+?)\s+per\s+second', text)
    if not m:
        m = re.match(r'^Regenerate\s+(\d+(?:\.\d+)?)%\s+of\s+maximum\s+(.+)$', text)
    if m:
        return (float(m.group(1)), m.group(2).strip())
    return None

def match_gain_on(text):
    """Match 'Gain X Y when Z' for flat gains."""
    m = re.match(r'^Gain\s+(\d+)\s+(.+?)\s+when\s+(.+)$', text)
    if m:
        return (float(m.group(1)), m.group(2).strip(), m.group(3).strip())
    m = re.match(r'^Gain\s+(\d+)\s+(.+?)\s+on\s+(.+)$', text)
    if m:
        return (float(m.group(1)), m.group(2).strip(), m.group(3).strip())
    return None

# ──────────────────────────────────────────────
# STAT NAME MAPPING DICTIONARIES
# ──────────────────────────────────────────────

# Map PoE2 stat names to our game stat keys
STAT_MAP = {
    # Life / Mana / ES
    "maximum life": "base_life",
    "life": "base_life",
    "maximum mana": "base_mana",
    "mana": "base_mana",
    "maximum energy shield": "base_energy_shield",
    "energy shield": "base_energy_shield",
    
    # Regen
    "life regeneration rate": "life_regen",
    "life regeneration": "life_regen",
    "mana regeneration rate": "mana_regen",
    "mana regeneration": "mana_regen",
    
    # Damage types
    "attack damage": "physical_damage",
    "physical damage": "physical_damage",
    "melee damage": "physical_damage",
    "elemental damage": "elemental_damage",
    "spell damage": "spell_damage",
    "fire damage": "fire_damage",
    "cold damage": "cold_damage",
    "lightning damage": "lightning_damage",
    "chaos damage": "chaos_damage",
    "damage over time": "damage_over_time",
    "projectile damage": "projectile_damage",
    "area damage": "area_damage",
    "spell area damage": "area_damage",
    "attack area damage": "area_damage",
    
    # Speed
    "attack speed": "attack_speed",
    "cast speed": "cast_speed",
    "skill speed": "cast_speed",  # Skill speed ≈ cast speed in our system
    
    # Defense
    "armour": "armour",
    "evasion rating": "evasion",
    "evasion": "evasion",
    
    # Block / Crit / Accuracy
    "block chance": "block_chance",
    "critical hit chance": "critical_chance",
    "critical damage bonus": "critical_multiplier",
    "accuracy rating": "base_accuracy",
    
    # Movement
    "movement speed": "movement_speed",
    
    # Misc that maps well
    "cooldown recovery rate": "cooldown_recovery",
    "skill effect duration": None,  # Not in our system
    "stun buildup": None,
    "stun threshold": None,
    "stun recovery": None,
    "freeze buildup": None,
    "electrocute buildup": None,
    "ailments": None,
}

# Element names for resistance mapping
ELEMENT_MAP = {
    "fire": "fire",
    "cold": "cold",
    "lightning": "lightning",
    "elemental": "elemental",
}

def map_stat_name(what):
    """Map a PoE2 stat name to our game key. Returns (key, is_known)."""
    what_lower = what.lower().strip()
    
    # Direct lookup
    if what_lower in STAT_MAP:
        v = STAT_MAP[what_lower]
        if v:
            return (v, True)
        return (None, False)
    
    # Handle "all elemental resistances" / "all resistances"
    if "all" in what_lower and "resistance" in what_lower:
        return ("all_resistance", True)
    
    # Handle "maximum X resistance"
    m = re.match(r'maximum\s+(fire|cold|lightning|chaos)\s+resistance', what_lower)
    if m:
        el = m.group(1)
        return (f"max_{el}_resistance", True)
    
    # Handle "X resistance" (flat)
    m = re.match(r'(fire|cold|lightning|chaos)\s+resistance', what_lower)
    if m:
        el = m.group(1)
        return (f"base_{el}_resistance", True)
    
    # Handle "maximum energy shield"
    if "maximum" in what_lower and "energy shield" in what_lower:
        return ("base_energy_shield", True)
    
    # Handle "energy shield recharge" rate
    if "energy shield recharge" in what_lower and ("rate" in what_lower or "faster" in what_lower or "start" in what_lower):
        return ("energy_shield_regen", True)
    
    return (None, False)

def is_keystone_special(effect_text):
    """Check if this is a special keystone mechanic that needs custom handling."""
    specials = [
        "no mana", "no non-fire", "cannot dodge roll", "maximum life is 1",
        "immune to chaos", "no rage effect", "never deal critical",
        "cannot be light stunned", "cannot recover life", "life leech effects",
        "no energy shield recharge", "no armour", "no evasion",
        "converts all evasion", "convert 100%",
        "all damage is taken from mana", "mana costs are doubled",
        "accuracy rating is doubled", "cannot recover energy shield",
        "you have no mana", "deal no non-fire",
    ]
    text_lower = effect_text.lower()
    for s in specials:
        if s in text_lower:
            return True
    return False

# ──────────────────────────────────────────────
# EFFECT PARSER
# ──────────────────────────────────────────────

def parse_effect(effect_text):
    """
    Parse a single PoE2 effect string into one or more modifier actions.
    Returns list of dicts: {key, value, type, raw}
    type: 'increased', 'flat_base', 'flat_mod', 'keystone', 'unknown'
    """
    results = []
    text = effect_text.strip()
    if not text:
        return results
    
    # Check for keystone special effects
    if is_keystone_special(text):
        results.append({
            "type": "keystone",
            "raw": text,
            "key": "keystone_special",
            "value": 0
        })
        return results
    
    # 1. Try "X% increased Y"
    r = match_increased(text)
    if r:
        pct, what = r
        key, known = map_stat_name(what)
        if key:
            if key in INCREASED_KEYS or key in {"base_life", "base_mana", "base_energy_shield", "base_accuracy", 
                                                  "armour", "evasion", "max_energy_shield",
                                                  "critical_chance", "critical_multiplier",
                                                  "block_chance", "all_resistance",
                                                  "movement_speed", "attack_speed", "cast_speed",
                                                  "life_regen", "mana_regen", "energy_shield_regen",
                                                  "cooldown_recovery", "item_rarity", "item_quantity"}:
                results.append({
                    "type": "increased",
                    "key": key,
                    "value": pct,
                    "raw": text
                })
            else:
                results.append({
                    "type": "flat_base",
                    "key": key,
                    "value": pct,
                    "raw": text
                })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 2. Try "X% reduced Y"
    r = match_reduced(text)
    if r:
        pct, what = r
        key, known = map_stat_name(what)
        if key:
            results.append({
                "type": "increased",
                "key": key,
                "value": pct,  # negative
                "raw": text
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 3. Try "X% more/less Y"
    r = match_more_less(text)
    if r:
        pct, what = r
        # "more/less" in PoE = multiplicative, but we store as increased for now
        # User can manually adjust
        key, known = map_stat_name(what)
        if key:
            results.append({
                "type": "increased",
                "key": key,
                "value": pct,
                "raw": text
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 4. Try "+X to Y"
    r = match_flat_to(text)
    if r:
        val, what = r
        key, known = map_stat_name(what)
        if key:
            if key in {"base_life", "base_mana", "base_energy_shield", "base_accuracy",
                       "all_resistance", "base_fire_resistance", "base_cold_resistance",
                       "base_lightning_resistance", "base_chaos_resistance",
                       "max_fire_resistance", "max_cold_resistance",
                       "max_lightning_resistance", "max_chaos_resistance"}:
                results.append({
                    "type": "flat_base",
                    "key": key,
                    "value": val,
                    "raw": text
                })
            else:
                results.append({"type": "unknown", "raw": text})
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 5. Try "Damage Penetrates X% Y Resistance"
    r = match_damage_penetrates(text)
    if r:
        pct, element = r
        el = element.lower()
        if el in ELEMENT_MAP:
            elem = ELEMENT_MAP[el]
            results.append({
                "type": "increased",
                "key": f"{elem}_damage",
                "value": pct * 0.5,  # penetration ≈ 50% of damage increase value
                "raw": text,
                "note": f"Penetrates {pct}% {element} Resistance"
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 6. Try "X% faster start of Energy Shield Recharge"
    r = match_faster_start(text)
    if r:
        pct = r[0]
        results.append({
            "type": "increased",
            "key": "energy_shield_regen",
            "value": pct,
            "raw": text
        })
        return results
    
    # 7. Try "Gain X% of Damage as Extra Y"
    r = match_gain_extra(text)
    if r:
        pct, source, target = r
        target_lower = target.lower()
        if "fire" in target_lower:
            results.append({
                "type": "increased",
                "key": "fire_damage",
                "value": pct * 0.5,
                "raw": text,
                "note": f"Extra: {pct}% of {source} as {target}"
            })
        elif "cold" in target_lower:
            results.append({
                "type": "increased",
                "key": "cold_damage",
                "value": pct * 0.5,
                "raw": text,
                "note": f"Extra: {pct}% of {source} as {target}"
            })
        elif "lightning" in target_lower:
            results.append({
                "type": "increased",
                "key": "lightning_damage",
                "value": pct * 0.5,
                "raw": text,
                "note": f"Extra: {pct}% of {source} as {target}"
            })
        elif "chaos" in target_lower:
            results.append({
                "type": "increased",
                "key": "chaos_damage",
                "value": pct * 0.5,
                "raw": text,
                "note": f"Extra: {pct}% of {source} as {target}"
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 8. Try "Regenerate X% of maximum Y"
    r = match_regenerate_pct(text)
    if r:
        pct, what = r
        what_lower = what.lower()
        if "life" in what_lower:
            # % max life regen -> life_regen as % of max life
            results.append({
                "type": "increased",
                "key": "life_regen",
                "value": pct * 5.0,  # scale: 1% max life regen ≈ 5 flat life regen
                "raw": text,
                "note": f"Regen {pct}% max {what}/s"
            })
        elif "mana" in what_lower:
            results.append({
                "type": "increased",
                "key": "mana_regen",
                "value": pct * 5.0,
                "raw": text,
                "note": f"Regen {pct}% max {what}/s"
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 9. Try flat gain/recover patterns
    r = match_gain_on(text)
    if r:
        val, what, condition = r
        what_lower = what.lower()
        if "life" in what_lower and ("kill" in condition.lower() or "enemy killed" in condition.lower()):
            results.append({
                "type": "flat_mod",
                "key": "life_on_kill",
                "value": val,
                "raw": text
            })
        elif "mana" in what_lower and ("kill" in condition.lower() or "enemy killed" in condition.lower()):
            results.append({
                "type": "flat_mod",
                "key": "mana_on_kill",
                "value": val,
                "raw": text
            })
        elif "rage" in what_lower:
            results.append({"type": "unknown", "raw": text})
        elif "energy shield" in what_lower and "block" in condition.lower():
            results.append({
                "type": "flat_mod",
                "key": "energy_shield",
                "value": val,
                "raw": text
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 10. Try "Recover X% of maximum Y"
    r = match_recover_pct(text)
    if r:
        pct, what, condition = r
        what_lower = what.lower()
        if "life" in what_lower:
            results.append({
                "type": "increased",
                "key": "life_on_kill",
                "value": pct * 3.0,
                "raw": text,
                "note": f"Recover {pct}% max {what} on {condition}"
            })
        elif "mana" in what_lower:
            results.append({
                "type": "increased",
                "key": "mana_on_kill",
                "value": pct * 3.0,
                "raw": text,
                "note": f"Recover {pct}% max {what} on {condition}"
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # 11. Try "X% chance to Y"
    r = match_chance_to(text)
    if r:
        # These are special mechanics - mark as unknown with the info
        results.append({
            "type": "unknown",
            "raw": text,
            "chance": r[0],
            "effect": r[1]
        })
        return results
    
    # 12. Try "Adds X to Y Z damage to Attacks"
    r = match_adds_damage(text)
    if r:
        dmin, dmax, dtype = r
        dtype_lower = dtype.lower()
        avg_dmg = (dmin + dmax) / 2.0
        if "fire" in dtype_lower:
            results.append({
                "type": "increased",
                "key": "fire_damage",
                "value": avg_dmg * 0.5,
                "raw": text,
                "note": f"Adds {dmin}-{dmax} {dtype} damage"
            })
        elif "cold" in dtype_lower:
            results.append({
                "type": "increased",
                "key": "cold_damage",
                "value": avg_dmg * 0.5,
                "raw": text,
                "note": f"Adds {dmin}-{dmax} {dtype} damage"
            })
        elif "lightning" in dtype_lower:
            results.append({
                "type": "increased",
                "key": "lightning_damage",
                "value": avg_dmg * 0.5,
                "raw": text,
                "note": f"Adds {dmin}-{dmax} {dtype} damage"
            })
        elif "chaos" in dtype_lower:
            results.append({
                "type": "increased",
                "key": "chaos_damage",
                "value": avg_dmg * 0.5,
                "raw": text,
                "note": f"Adds {dmin}-{dmax} {dtype} damage"
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # Special: "X% of Damage taken Recouped as Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+of\s+(.+?)\s+taken\s+Recouped\s+as\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        source = m.group(2).strip()
        target = m.group(3).strip()
        target_lower = target.lower()
        if "life" in target_lower:
            results.append({
                "type": "flat_mod",
                "key": "life_leech",  # closest match
                "value": pct * 0.5,
                "raw": text,
                "note": f"{pct}% of {source} recouped as {target}"
            })
        elif "mana" in target_lower:
            results.append({
                "type": "flat_mod",
                "key": "mana_leech",
                "value": pct * 0.5,
                "raw": text,
                "note": f"{pct}% of {source} recouped as {target}"
            })
        else:
            results.append({"type": "unknown", "raw": text})
        return results
    
    # Special: "+X metres to Melee Strike     # Special: "X% reduced effect of Y on you"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+reduced\s+effect\s+of\s+(.+?)\s+on\s+you$', text)
    if m:
        results.append({"type": "unknown", "raw": text})
        return results
    
    # === ADDITIONAL PATTERNS ===
    
    # "X% increased Y for/with/while Z" - try to extract stat from after "increased"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(.+?)\s+(?:for|with|while|against)\s+.+$', text)
    if m:
        pct = float(m.group(1))
        what = m.group(2).strip()
        key, known = map_stat_name(what)
        if key:
            results.append({"type": "increased", "key": key, "value": pct, "raw": text, "note": "conditional"})
            return results
    
    # "X% increased Y and Z" - split into two mods
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(.+?)\s+and\s+(.+)$', text)
    if m:
        pct = float(m.group(1))
        what1 = m.group(2).strip()
        what2 = m.group(3).strip()
        key1, known1 = map_stat_name(what1)
        key2, known2 = map_stat_name(what2)
        added = False
        if key1:
            results.append({"type": "increased", "key": key1, "value": pct, "raw": text, "note": f"from '{what1} and {what2}'"})
            added = True
        if key2 and key2 != key1:
            results.append({"type": "increased", "key": key2, "value": pct, "raw": text, "note": f"from '{what1} and {what2}'"})
            added = True
        if added:
            return results
    
    # "X% increased Y against/on Z" - extract main stat
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(.+?)\s+(?:against|while|when|if|per)\s+', text)
    if m:
        pct = float(m.group(1))
        what = m.group(2).strip()
        key, known = map_stat_name(what)
        if key:
            results.append({"type": "increased", "key": key, "value": pct, "raw": text, "note": "conditional"})
            return results
    
    # "X% increased Y with Z" - weapon-specific damage
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(damage|attack damage|spell damage)\s+with\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        dmg_type = m.group(2).lower()
        weapon = m.group(3).strip().lower()
        key = "physical_damage"
        if "spell" in dmg_type:
            key = "spell_damage"
        results.append({"type": "increased", "key": key, "value": pct, "raw": text, "note": f"with {weapon}"})
        return results
    
    # "X% increased Critical Hit Chance for Spells/Attacks"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Critical Hit Chance\s+(?:for|with)\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "critical_chance", "value": pct, "raw": text})
        return results
    
    # "X% increased Critical Damage Bonus for/with Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Critical Damage Bonus', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "critical_multiplier", "value": pct, "raw": text})
        return results
    
    # "X% increased amount of Life/Mana Leeched"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+amount\s+of\s+(Life|Mana)\s+Leeched', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        what = m.group(2).lower()
        key = "life_leech" if what == "life" else "mana_leech"
        results.append({"type": "flat_mod", "key": key, "value": pct * 0.3, "raw": text, "note": f"{pct}% increased {what} leeched"})
        return results
    
    # "X% increased Elemental Damage with Attacks"
    if "elemental damage with attacks" in text.lower():
        m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Elemental Damage with Attacks', text, re.IGNORECASE)
        if m:
            pct = float(m.group(1))
            results.append({"type": "increased", "key": "elemental_damage", "value": pct, "raw": text})
            return results
    
    # "X% increased Physical/Magic/etc Damage"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(.+?)\s+Damage\s+with\s+(.+?)\s+Weapons?$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        dmg_type = m.group(2).lower()
        if "physical" in dmg_type or "attack" in dmg_type or "melee" in dmg_type:
            results.append({"type": "increased", "key": "physical_damage", "value": pct, "raw": text})
            return results
    
    # "X% increased Damage with Two/One Handed Weapons"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Damage\s+with\s+(.+?)\s+Handed\s+Weapons?$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "physical_damage", "value": pct, "raw": text, "note": f"{m.group(1)} handed weapons"})
        return results
    
    # "X% increased Damage with Hits against Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Damage\s+with\s+Hits\s+against\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "physical_damage", "value": pct, "raw": text, "note": f"hits vs {m.group(2)}"})
        return results
    
    # "X% increased Damage against Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Damage\s+against\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "physical_damage", "value": pct, "raw": text, "note": f"vs {m.group(2)}"})
        return results
    
    # "X% increased Damage if/when/while Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Damage\s+(?:if|when|while)\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "physical_damage", "value": pct, "raw": text, "note": f"conditional: {m.group(2)}"})
        return results
    
    # "X% increased Magnitude of Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Magnitude\s+of\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        what = m.group(2).lower()
        if "poison" in what or "bleeding" in what or "ignite" in what:
            results.append({"type": "increased", "key": "damage_over_time", "value": pct * 0.5, "raw": text, "note": f"ailment magnitude"})
            return results
    
    # "X% increased Duration of Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(?:Duration|duration)\s+of\s+(.+)$', text, re.IGNORECASE)
    if m:
        # Not directly mappable - leave as unknown
        pass
    
    # "+X to Strength/Dexterity/Intelligence" - special attribute nodes
    m = re.match(r'^\+(\d+)\s+(?:to\s+)?(Strength|Dexterity|Intelligence)$', text, re.IGNORECASE)
    if m:
        val = float(m.group(1))
        attr = m.group(2).capitalize()
        # Map STR → physical damage, DEX → accuracy/evasion, INT → mana/spell
        attr_key = "physical_damage"  # Default for STR
        if "dexterity" in attr.lower():
            attr_key = "evasion"
        elif "intelligence" in attr.lower():
            attr_key = "base_mana"
        results.append({"type": "flat_base", "key": attr_key, "value": val * 2.0, "raw": text, "note": f"+{val} {attr}"})
        return results
    
    # "+X to all Attributes"
    m = re.match(r'^\+(\d+)\s+to\s+all\s+Attributes$', text, re.IGNORECASE)
    if m:
        val = float(m.group(1))
        results.append({"type": "flat_base", "key": "base_life", "value": val * 3.0, "raw": text, "note": f"+{val} all attributes"})
        return results
    
    # "+X to any Attribute" (generic attribute nodes - map to base_life as approximation)
    m = re.match(r'^\+(\d+)\s+to\s+any\s+Attribute$', text, re.IGNORECASE)
    if m:
        val = float(m.group(1))
        results.append({"type": "flat_base", "key": "base_life", "value": val * 3.0, "raw": text, "note": f"+{val} any attribute"})
        return results
    
    # "X% chance to inflict Bleeding/Poison on Hit"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+chance\s+to\s+inflict\s+(.+?)\s+on\s+Hit$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        effect = m.group(2).lower()
        if "bleeding" in effect or "poison" in effect:
            results.append({"type": "increased", "key": "damage_over_time", "value": pct * 0.3, "raw": text, "note": f"{pct}% chance to {effect}"})
            return results
    
    # "X% chance to Y on Hit"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+chance\s+to\s+(.+?)\s+on\s+Hit$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        effect = m.group(2).lower()
        results.append({"type": "unknown", "raw": text, "chance": pct, "effect": effect})
        return results
    
    # "X Mana/Life gained when you Block"
    m = re.match(r'^(\d+)\s+(Mana|Life)\s+gained\s+when\s+you\s+Block$', text, re.IGNORECASE)
    if m:
        val = float(m.group(1))
        what = m.group(2).lower()
        if "mana" in what:
            results.append({"type": "flat_mod", "key": "mana_on_kill", "value": val, "raw": text})
        else:
            results.append({"type": "flat_mod", "key": "life_gain_on_hit", "value": val, "raw": text})
        return results
    
    # "Recover X Life/Mana when you Block"
    m = re.match(r'^Recover\s+(\d+)\s+(Life|Mana)\s+when\s+you\s+Block$', text, re.IGNORECASE)
    if m:
        val = float(m.group(1))
        what = m.group(2).lower()
        if "life" in what:
            results.append({"type": "flat_mod", "key": "life_gain_on_hit", "value": val, "raw": text})
        else:
            results.append({"type": "flat_mod", "key": "mana_on_kill", "value": val, "raw": text})
        return results
    
    # "X Life/Mana gained when you Kill"
    m = re.match(r'^Gain\s+(\d+)\s+(Life|Mana)\s+per\s+enemy\s+killed$', text, re.IGNORECASE)
    if m:
        val = float(m.group(1))
        what = m.group(2).lower()
        if "life" in what:
            results.append({"type": "flat_mod", "key": "life_on_kill", "value": val, "raw": text})
        else:
            results.append({"type": "flat_mod", "key": "mana_on_kill", "value": val, "raw": text})
        return results
    
    # "Break X% increased Armour"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Armour\s+Break', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "physical_damage", "value": pct * 0.3, "raw": text, "note": "armour break"})
        return results
    
    # "5% of X applies to Y" / "X% of Y also applies to Z"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+of\s+(.+?)\s+(?:applies|also applies|also grant|converted)\s+to\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        source = m.group(2).lower()
        target = m.group(3).lower()
        if "armour" in source and "elemental" in target:
            results.append({"type": "increased", "key": "all_resistance", "value": pct * 0.1, "raw": text, "note": f"{pct}% armour→elemental"})
            return results
    
    # "Gain X Rage on Melee Hit" / "Gain X Rage when Hit"
    m = re.match(r'^Gain\s+(\d+)\s+Rage\s+(?:on|when)\s+(.+)$', text, re.IGNORECASE)
    if m:
        val = float(m.group(1))
        results.append({"type": "unknown", "raw": text, "rage_on_hit": val})
        return results
    
    # "Hits against you have X% reduced Critical Damage Bonus"
    m = re.match(r'^Hits\s+against\s+you\s+have\s+(\d+(?:\.\d+)?)%\s+reduced\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "evasion", "value": pct * 0.5, "raw": text, "note": "defensive"})
        return results
    
    # "Allies in your Presence Y"
    m = re.match(r'^Allies\s+in\s+your\s+Presence\s+(.+)$', text, re.IGNORECASE)
    if m:
        results.append({"type": "unknown", "raw": text, "note": "party buff"})
        return results
    
    # Skills deal X% increased Damage per Y
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(.+?)\s+per\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        what = m.group(2).strip()
        key, known = map_stat_name(what)
        if key:
            results.append({"type": "increased", "key": key, "value": pct, "raw": text, "note": f"per {m.group(3)}"})
            return results
    
    # "X% increased Life/Mana Cost of Skills"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(Life|Mana)\s+Cost\s+of\s+Skills$', text, re.IGNORECASE)
    if m:
        results.append({"type": "unknown", "raw": text})
        return results
    
    # "Culling Strike against..."
    if "culling strike" in text.lower():
        results.append({"type": "increased", "key": "physical_damage", "value": 10.0, "raw": text, "note": "culling strike"})
        return results
    
    # "Armour/Evasion from Equipped X"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+(.+?)\s+from\s+Equipped\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        what = m.group(2).strip()
        key, known = map_stat_name(what)
        if key:
            results.append({"type": "increased", "key": key, "value": pct, "raw": text, "note": f"from equipped {m.group(3)}"})
            return results
    
    # "X% chance to Avoid Death from Hits"
    if "avoid death" in text.lower():
        results.append({"type": "keystone", "raw": text, "key": "avoid_death"})
        return results
    
    # "Channelling Skills deal X% increased Damage"
    m = re.match(r'^Channelling\s+Skills\s+deal\s+(\d+(?:\.\d+)?)%\s+increased\s+Damage$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "spell_damage", "value": pct, "raw": text})
        return results
    
    # "X% increased Damage while Leeching"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+increased\s+Damage\s+while\s+Leeching', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        results.append({"type": "increased", "key": "physical_damage", "value": pct, "raw": text, "note": "while leeching"})
        return results
    
    # "Skills gain X Glory every Y seconds"
    if "glory" in text.lower():
        results.append({"type": "unknown", "raw": text})
        return results
    
    # "Damage Penetrates X% of Enemy Elemental Resistances"
    m = re.match(r'^Damage\s+Penetrates\s+(\d+(?:\.\d+)?)%\s+of\s+Enemy\s+(.+?)\s+Resistances?$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        what = m.group(2).lower()
        if "elemental" in what:
            results.append({"type": "increased", "key": "elemental_damage", "value": pct * 0.5, "raw": text, "note": "penetration"})
            return results
    
    # "X% chance to Y on Critical Hit"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+chance\s+(?:for|to)\s+(.+?)\s+(?:on|when)\s+(.+)$', text, re.IGNORECASE)
    if m:
        results.append({"type": "unknown", "raw": text, "chance": float(m.group(1))})
        return results
    
    # "Increases and Reductions to X also apply to Y at Z%"
    if "increases and reductions" in text.lower():
        results.append({"type": "unknown", "raw": text})
        return results
    
    # "X% faster Y" patterns (not ES recharge)
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+faster\s+(.+)', text)
    if m:
        results.append({"type": "unknown", "raw": text})
        return results
    
    # "X% more/less Y"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+(more|less)\s+(.+)$', text, re.IGNORECASE)
    if m:
        pct = float(m.group(1))
        mult = 1.0 if m.group(2) == 'more' else -1.0
        what = m.group(3).strip()
        key, known = map_stat_name(what)
        if key:
            results.append({"type": "increased", "key": key, "value": pct * mult, "raw": text, "note": f"{m.group(2)}"})
            return results
    
    # Special: "Cannot be X" or "Immune to X"
    if text.lower().startswith("cannot be ") or text.lower().startswith("immune to ") or text.lower().startswith("never deal "):
        results.append({
            "type": "keystone",
            "raw": text,
            "key": "immunity_or_prohibition"
        })
        return results
    
    # Special: "X% reduced effect of Y on you"
    m = re.match(r'^(\d+(?:\.\d+)?)%\s+reduced\s+effect\s+of\s+(.+?)\s+on\s+you$', text)
    if m:
        results.append({"type": "unknown", "raw": text})
        return results
    
    # Fallback: anything unrecognized
    # Fallback: anything unrecognized
    results.append({"type": "unknown", "raw": text})
    return results

def parse_effects_group(effects_text):
    """
    Parse a full Effect(s) cell (may contain multiple effects separated by '|').
    Returns list of parsed effect dicts.
    """
    if not effects_text:
        return []
    
    parts = [p.strip() for p in effects_text.split('|')]
    all_results = []
    for part in parts:
        parsed = parse_effect(part)
        all_results.extend(parsed)
    return all_results


def determine_node_size_and_type(node_type):
    """Map PoE2 type to our size/visual."""
    t = node_type.lower() if node_type else "small"
    if "keystone" in t:
        return "keystone"
    elif "notable" in t:
        return "notable"
    elif "attribute" in t:
        return "attribute"
    elif "small" in t:
        return "small"
    elif "ascendancy choice" in t:
        return "ascendancy_choice"
    else:
        return "small"


def parse_connected(text):
    """Parse comma/space separated node IDs into a list of ints."""
    if not text:
        return []
    parts = re.split(r'[,\s]+', str(text).strip())
    ids = []
    for p in parts:
        p = p.strip()
        if p and p.isdigit():
            ids.append(int(p))
    return ids


def process_sheet(ws, tree_name="main"):
    """Process a worksheet and return list of node dicts."""
    nodes = []
    for i, row in enumerate(ws.iter_rows(values_only=True)):
        if i == 0:  # header row
            continue
        nid, name, typ, location, effects, points, flavor, connected = row
        
        node = {
            "id": int(nid) if nid else 0,
            "name": str(name) if name else "",
            "type": str(typ) if typ else "Small",
            "tree": tree_name,
            "location": str(location) if location else "",
            "effects_raw": str(effects) if effects else "",
            "passive_points": int(points) if points else 0,
            "flavor_text": str(flavor) if flavor else "",
            "connects": parse_connected(connected),
            "size": determine_node_size_and_type(typ),
            "modifiers": [],
            "class_restriction": "",
        }
        
        # Parse effects
        if effects:
            node["modifiers"] = parse_effects_group(effects)
        
        # Parse class from location for ascendancy
        if tree_name == "ascendancy" and location:
            # Format: "Ascendancy: Class - Subclass"
            m = re.match(r'Ascendancy:\s*(.+?)\s*-\s*(.+)$', str(location))
            if m:
                node["class"] = m.group(1).strip()
                node["subclass"] = m.group(2).strip()
        
        nodes.append(node)
    
    return nodes


def main():
    print("Loading workbook...")
    wb = openpyxl.load_workbook(INPUT_PATH, data_only=True)
    
    print("Processing Main Tree...")
    main_nodes = process_sheet(wb['Main Tree'], "main")
    print(f"  -> {len(main_nodes)} nodes")
    
    print("Processing Ascendancy Nodes...")
    asc_nodes = process_sheet(wb['Ascendancy Nodes'], "ascendancy")
    print(f"  -> {len(asc_nodes)} nodes")
    
    # Analyze mapping coverage
    total_mods = 0
    mapped_mods = 0
    unknown_effects = set()
    for nodes_list in [main_nodes, asc_nodes]:
        for node in nodes_list:
            for mod in node["modifiers"]:
                total_mods += 1
                if mod["type"] != "unknown":
                    mapped_mods += 1
                else:
                    unknown_effects.add(mod["raw"])
    
    print(f"\nMapping coverage: {mapped_mods}/{total_mods} effects mapped ({mapped_mods/total_mods*100:.1f}%)")
    print(f"Unknown effect patterns: {len(unknown_effects)}")
    
    # Build output
    output = {
        "version": "1.0",
        "source": "PoE2 Official Skill Tree Export (17 July 2026)",
        "filtered": "Minion, Flask, Jewel, Totem, Trap, Mine, Spectre, Skeleton, Zombie, Companion, Spirit, Deflection",
        "nodes": main_nodes,
        "ascendancy_nodes": asc_nodes,
        "stat_name_map": STAT_NAMES_TR,
    }
    
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(output, f, ensure_ascii=False, indent=1)
    
    # Save unknown effects report
    report_path = OUTPUT_PATH.replace('.json', '_UNMAPPED.txt')
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(f"UNMAPPED EFFECT PATTERNS ({len(unknown_effects)})\n")
        f.write("=" * 60 + "\n\n")
        for eff in sorted(unknown_effects):
            f.write(f"  • {eff}\n")
    
    print(f"\nOutput: {OUTPUT_PATH}")
    print(f"Unmapped report: {report_path}")
    print("Done!")

if __name__ == "__main__":
    main()
