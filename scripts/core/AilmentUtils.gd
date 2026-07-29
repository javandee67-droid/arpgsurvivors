extends RefCounted
class_name AilmentUtils
## Statik yardimci fonksiyonlar — ailment uygulama mantigi.
## Hem oyuncu hem dusman skill'leri burayi kullanir.

## Ailment sansini hesapla
## defender_stats: hedefin ailment_threshold'u varsa sansi düşür
static func calc_ailment_chance(hit_result: Dictionary, stats: CharacterStats, is_crit: bool,
		defender_stats: CharacterStats = null) -> float:
	# Kritik vuruslarda guaranteed ailment
	if is_crit:
		return 1.0

	# Base chance: ailment_power / threshold
	var ailment_power: float = hit_result.get("ailment_power", 0.0)
	var base_damage: float = hit_result.get("damage", 1.0)

	# Hasar ne kadar yuksekse sans o kadar artar
	var chance: float = clampf(ailment_power / (base_damage + 10.0) * 2.0, 0.05, 0.75)

	# Player'in ailment chance modifier'lari
	if stats:
		chance *= (1.0 + stats.ailment_chance / 100.0)

	# Defender'in ailment_threshold'u: yüksek threshold = düşük sans
	if defender_stats and defender_stats.ailment_threshold > 0.0:
		chance /= (1.0 + defender_stats.ailment_threshold / 100.0)

	return clampf(chance, 0.0, 1.0)

## Yanma (IGNITE) uygulamayi dene
static func try_ignite(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats,
		is_crit: bool, source: Node, defender_stats: CharacterStats = null) -> bool:
	if not ac:
		return false

	var chance: float = calc_ailment_chance(hit_result, stats, is_crit, defender_stats)
	if randf() > chance:
		return false

	var dmg: float = hit_result.get("damage", 0.0)
	var ap: float = hit_result.get("ailment_power", 0.0)
	# Per-ailment magnitude bonus
	if stats:
		ap *= (1.0 + (stats.ailment_magnitude + stats.ignite_magnitude) / 100.0)
	var ignite_dps: float = CombatEngine.calculate_ignite_dps(dmg, ap)

	if ignite_dps > 0.0:
		var duration: float = 4.0
		# Player'in ailment duration bonusu (generic + ignite-specific)
		if stats:
			duration *= (1.0 + stats.ailment_duration / 100.0)
		ac.apply_effect(StatusEffect.Type.IGNITE, ignite_dps, duration, source)
		return true
	return false

## Sok (SHOCK) uygulamayi dene
static func try_shock(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats,
		target_max_life: float, is_crit: bool, source: Node, defender_stats: CharacterStats = null) -> bool:
	if not ac:
		return false

	var chance: float = calc_ailment_chance(hit_result, stats, is_crit, defender_stats)
	if randf() > chance:
		return false

	var dmg: float = hit_result.get("damage", 0.0)
	var ap: float = hit_result.get("ailment_power", 0.0)
	# Per-ailment magnitude bonus
	if stats:
		ap *= (1.0 + (stats.ailment_magnitude + stats.shock_magnitude) / 100.0)
	var shock_mag: float = CombatEngine.calculate_shock_magnitude(dmg, ap, target_max_life)

	if shock_mag > 0.0:
		var dur: float = 2.0
		if stats:
			dur *= (1.0 + stats.ailment_duration / 100.0)
		ac.apply_effect(StatusEffect.Type.SHOCK, shock_mag, dur, source)
		return true
	return false

## Electrocute uygulamayi dene (shock uygular + electrocute buildup ekler)
static func try_electrocute(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats,
		target_max_life: float, is_crit: bool, source: Node, defender_stats: CharacterStats = null) -> bool:
	if not ac:
		return false

	# Lightning hasari once SHOCK uygular
	var shocked: bool = try_shock(ac, hit_result, stats, target_max_life, is_crit, source, defender_stats)

	# Electrocute buildup: shock magnitude uzerinden hesapla
	var dmg: float = hit_result.get("damage", 0.0)
	var ap: float = hit_result.get("ailment_power", 0.0)
	if stats:
		ap *= (1.0 + (stats.ailment_magnitude + stats.shock_magnitude) / 100.0)
	var shock_mag: float = CombatEngine.calculate_shock_magnitude(dmg, ap, target_max_life)

	if shock_mag > 0.0:
		# Electrocute buildup: shock_mag'in 2x'i kadar (chill buildup'tan biraz az)
		var buildup: float = shock_mag * 1.2 + (0.08 if is_crit else 0.0)
		# Electrocute Buildup bonus
		if stats and stats.electrocute_buildup > 0.0:
			buildup *= (1.0 + stats.electrocute_buildup / 100.0)
		ac.add_electrocute_buildup(buildup)
		return true
	return shocked

## Chill uygulamayi dene (ve chill buildup ekle)
static func try_chill(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats,
		target_max_life: float, is_crit: bool, source: Node, defender_stats: CharacterStats = null) -> bool:
	if not ac:
		return false

	var chance: float = calc_ailment_chance(hit_result, stats, is_crit, defender_stats)
	if randf() > chance:
		return false

	var dmg: float = hit_result.get("damage", 0.0)
	var ap: float = hit_result.get("ailment_power", 0.0)
	# Per-ailment magnitude bonus
	if stats:
		ap *= (1.0 + (stats.ailment_magnitude + stats.chill_magnitude + stats.slow_magnitude) / 100.0)
	var chill_mag: float = CombatEngine.calculate_chill_magnitude(dmg, ap, target_max_life)

	if chill_mag > 0.0:
		var dur: float = 2.0
		if stats:
			# Chill duration bonus (spesifik) + generic ailment duration
			dur *= (1.0 + (stats.chill_duration + stats.ailment_duration) / 100.0)
		ac.apply_effect(StatusEffect.Type.CHILL, chill_mag, dur, source)
		# Chill buildup ekle (threshold 1.0'a ulasinca freeze)
		var buildup: float = chill_mag * 1.5 + (0.1 if is_crit else 0.0)
		# Freeze Buildup bonus: daha az chill'le dondur
		if stats and stats.freeze_buildup > 0.0:
			buildup *= (1.0 + stats.freeze_buildup / 100.0)
		# Freeze duration bonus from attacker's freeze_duration_on_enemies
		var freeze_dur_mult: float = 1.0
		if stats and stats.freeze_duration_on_enemies > 0.0:
			freeze_dur_mult = (1.0 + stats.freeze_duration_on_enemies / 100.0)
		ac.add_chill_buildup(buildup, freeze_dur_mult)
		return true
	return false

## Zehir (POISON) uygulamayi dene
static func try_poison(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats,
		is_crit: bool, source: Node, defender_stats: CharacterStats = null) -> bool:
	if not ac:
		return false

	var chance: float = calc_ailment_chance(hit_result, stats, is_crit, defender_stats)
	if randf() > chance:
		return false

	var dmg: float = hit_result.get("damage", 0.0)
	var ap: float = hit_result.get("ailment_power", 0.0)
	var poison_dps: float = CombatEngine.calculate_poison_dps(dmg, ap)

	if poison_dps > 0.0:
		var duration: float = 2.0
		if stats:
			# poison_duration (spesifik) + generic ailment_duration
			duration *= (1.0 + (stats.poison_duration + stats.ailment_duration) / 100.0)
		ac.apply_effect(StatusEffect.Type.POISON, poison_dps, duration, source)
		return true
	return false

## Kana (BLEED) uygulamayi dene
static func try_bleed(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats,
		is_crit: bool, source: Node, defender_stats: CharacterStats = null) -> bool:
	if not ac:
		return false

	var chance: float = calc_ailment_chance(hit_result, stats, is_crit, defender_stats) * 0.7  # Bleed daha zor
	if randf() > chance:
		return false

	var dmg: float = hit_result.get("damage", 0.0)
	var ap: float = hit_result.get("ailment_power", 0.0)
	# Per-ailment magnitude bonus
	if stats:
		ap *= (1.0 + (stats.ailment_magnitude + stats.bleed_magnitude) / 100.0)
	var bleed_dps: float = CombatEngine.calculate_bleed_dps(dmg, ap)

	if bleed_dps > 0.0:
		# Check for Aggravated Bleeding (from passive tree)
		# Player'dan gelen bleed'ler her zaman hasar verir (hareket sartı yok)
		var is_aggravated: bool = false
		if stats:
			if stats.aggravated_bleeding:  # "Bleeding you inflict is Aggravated"
				is_aggravated = true
			elif stats.aggravate_bleed_chance > 0.0:
				if randf() * 100.0 < stats.aggravate_bleed_chance:
					is_aggravated = true
		# Oyuncu bleed'i her zaman aggravated (0 hasar gösterme)
		if not is_aggravated and source and source.is_in_group("player"):
			is_aggravated = true
		var dur: float = 5.0
		if stats:
			# bleeding_duration (spesifik) + generic ailment_duration
			dur *= (1.0 + (stats.bleeding_duration + stats.ailment_duration) / 100.0)
		ac.apply_effect(StatusEffect.Type.BLEED, bleed_dps, dur, source, [], is_aggravated)
		return true
	return false

## Tum elemental/kaos tag'lerini kontrol et ve uygun ailment'i dene
static func apply_ailments_for_tags(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats,
		target_max_life: float, tags: Array, source: Node) -> void:
	if not ac:
		return

	var is_crit: bool = hit_result.get("is_crit", false)
	var dmg_type: String = hit_result.get("damage_type", "physical")

	# Defender'in stat'lari (ailment_threshold, ailment_duration_on_you icin)
	var defender_stats: CharacterStats = ac.get_defender_stats() if ac.has_method("get_defender_stats") else null

	# Ailment uygulama sansi, dusmanin direncinden etkilenir
	# (zaten hit_result.damage direnc dusuruldukten sonraki hasardir)

	if tags.has("fire") or (tags.has("spell") and dmg_type == "fire"):
		try_ignite(ac, hit_result, stats, is_crit, source, defender_stats)

	if tags.has("lightning") or (tags.has("spell") and dmg_type == "lightning"):
		try_electrocute(ac, hit_result, stats, target_max_life, is_crit, source, defender_stats)

	if tags.has("cold") or (tags.has("spell") and dmg_type == "cold"):
		try_chill(ac, hit_result, stats, target_max_life, is_crit, source, defender_stats)

	if tags.has("chaos") or (tags.has("spell") and dmg_type == "chaos"):
		try_poison(ac, hit_result, stats, is_crit, source, defender_stats)

	if tags.has("bleed") or (tags.has("physical") and dmg_type == "physical"):
		try_bleed(ac, hit_result, stats, is_crit, source, defender_stats)

	# Wither: chaos damage applies Withered stacks (increases chaos damage taken)
	try_withered(ac, hit_result, stats, is_crit, source)

	# Maim: chance-based, from passive tree "X% chance to Maim on Hit"
	if stats and stats.maim_chance > 0.0:
		if randf() * 100.0 < stats.maim_chance:
			ac.apply_effect(StatusEffect.Type.MAIM, 0.0, 4.0, source)

## Try to apply Withered stacks on hit
static func try_withered(ac: AilmentController, hit_result: Dictionary, stats: CharacterStats, is_crit: bool, source: Node) -> void:
	if not ac or not stats:
		return
	# Wither uygulama sansi: chaos hit + withered_chance
	var dmg_type: String = hit_result.get("damage_type", "physical")
	var is_chaos: bool = dmg_type == "chaos"
	var chance: float = 0.0
	if is_chaos:
		chance = calc_ailment_chance(hit_result, stats, is_crit)
	# Ek withered_chance passive tree'den
	if stats.withered_chance > 0.0:
		chance = maxf(chance, stats.withered_chance / 100.0)
	if chance <= 0.0 or randf() > chance:
		return
	# Wither stack: base 6%, increased by withered_magnitude
	var mag: float = 0.06  # 6% increased chaos damage taken per stack
	if stats.withered_magnitude > 0.0:
		mag *= (1.0 + stats.withered_magnitude / 100.0)
	# Duration: base 4s, increased by withered_duration
	var dur: float = 4.0
	if stats.withered_duration > 0.0:
		dur *= (1.0 + stats.withered_duration / 100.0)
	ac.apply_effect(StatusEffect.Type.WITHER, mag, dur, source)
