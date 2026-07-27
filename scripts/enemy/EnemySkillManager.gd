extends Node
class_name EnemySkillManager
## Dusman skill'lerini yoneten ve kullanan manager.
## Her Enemy'e child olarak eklenir.

## Dusman siniflari
enum EnemyClass {
	MELEE,      ## Yaklasir, yakin dovus yapar
	RANGED,     ## Uzakta durur, ok atar
	MAGE,       ## Ortada durur, buyu atar
	BOSS,       ## Karisik, tum skill'leri kullanir
}

## Enemy Class isimleri
const ENEMY_CLASS_NAMES := {
	EnemyClass.MELEE: "Yakın Dövüşçü",
	EnemyClass.RANGED: "Okçu",
	EnemyClass.MAGE: "Büyücü",
	EnemyClass.BOSS: "Patron",
}

# Sinif etiketleri (group ismi olarak)
const ENEMY_CLASS_TAGS := {
	EnemyClass.MELEE: "enemy_melee",
	EnemyClass.RANGED: "enemy_ranged",
	EnemyClass.MAGE: "enemy_mage",
	EnemyClass.BOSS: "enemy_boss",
}

## Skill tanimlari (dictionary) — EnemySkillData kullanmak yerine
## dogrudan dictionary kullaniriz (daha hizli, resource yuklemeye gerek yok)
## Format: { "skill_id": { "display_name", "base_damage_pct", ... } }
const SKILL_DB: Dictionary = {
	# ============= YAKIN DÖVÜŞ SKILLERI (17) =============
	"slash": {
		"name": "Kesme",
		"dmg_pct": 1.0, "cd": 1.5, "dmg_type": "physical",
		"tags": ["attack", "melee"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_slash_arc_new.png",
	},
	"double_strike": {
		"name": "Çifte Vuruş",
		"dmg_pct": 0.7, "cd": 2.0, "dmg_type": "physical",
		"tags": ["attack", "melee"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_blood_slash.png",
	},
	"cleave": {
		"name": "Yarma",
		"dmg_pct": 1.3, "cd": 2.5, "dmg_type": "physical",
		"tags": ["attack", "melee", "aoe"], "shape": "aoe",
		"range": 40.0, "max_range": 45.0, "aoe_radius": 50.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_slash_arc_new.png",
		"target": "self_aoe",
	},
	"power_strike": {
		"name": "Kudretli Vuruş",
		"dmg_pct": 2.0, "cd": 3.0, "dmg_type": "physical",
		"tags": ["attack", "melee"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_ground_shock.png",
	},
	"whirlwind": {
		"name": "Kasırga",
		"dmg_pct": 0.6, "cd": 4.0, "dmg_type": "physical",
		"tags": ["attack", "melee", "aoe"], "shape": "aoe",
		"range": 50.0, "max_range": 60.0, "aoe_radius": 60.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_slash_arc_new.png",
		"target": "self_aoe",
	},
	"shield_bash": {
		"name": "Kalkan Darbesi",
		"dmg_pct": 1.5, "cd": 3.0, "dmg_type": "physical",
		"tags": ["attack", "melee"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_ground_shock.png",
	},
	"ground_slam": {
		"name": "Yer Sarsıntısı",
		"dmg_pct": 1.8, "cd": 3.5, "dmg_type": "physical",
		"tags": ["attack", "melee", "aoe"], "shape": "aoe",
		"range": 60.0, "max_range": 70.0, "aoe_radius": 70.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_ground_shock.png",
		"target": "self_aoe",
	},
	"leap_slam": {
		"name": "Sıçrayış",
		"dmg_pct": 2.2, "cd": 5.0, "dmg_type": "physical",
		"tags": ["attack", "melee", "aoe"], "shape": "aoe",
		"range": 80.0, "max_range": 150.0, "aoe_radius": 60.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_ground_shock.png",
		"target": "at_player_aoe",
	},
	"puncture": {
		"name": "Delme",
		"dmg_pct": 1.2, "cd": 2.5, "dmg_type": "physical",
		"tags": ["attack", "melee", "bleed"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_blood_slash.png",
	},
	"fury": {
		"name": "Hiddet",
		"dmg_pct": 0.0, "cd": 8.0, "dmg_type": "physical",
		"tags": ["buff"], "shape": "buff",
		"range": 0.0, "max_range": 0.0,
		"proj_tex": "", "hit_tex": "",
		"target": "self_buff", "buff_tags": ["onslaught"],
	},
	"sweep": {
		"name": "Süpürme",
		"dmg_pct": 0.9, "cd": 3.0, "dmg_type": "physical",
		"tags": ["attack", "melee", "aoe", "cold"], "shape": "aoe",
		"range": 40.0, "max_range": 45.0, "aoe_radius": 50.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_ice_shatter_new.png",
		"target": "self_aoe",
	},
	"lacerate": {
		"name": "Yırtma",
		"dmg_pct": 1.0, "cd": 2.0, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 150.0, "max_range": 200.0,
		"proj_tex": "res://assets/generated/proj_wind_slash.png",
		"hit_tex": "res://assets/generated/hit_blood_slash.png",
		"proj_speed": 350.0,
	},
	"fire_slash": {
		"name": "Alev Kılıcı",
		"dmg_pct": 1.4, "cd": 2.5, "dmg_type": "fire",
		"tags": ["attack", "melee", "fire"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_fire_explosion_new.png",
	},
	"ice_slash": {
		"name": "Buz Kılıcı",
		"dmg_pct": 1.4, "cd": 2.5, "dmg_type": "cold",
		"tags": ["attack", "melee", "cold"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_ice_shatter_new.png",
	},
	"lightning_slash": {
		"name": "Yıldırım Kılıcı",
		"dmg_pct": 1.4, "cd": 2.5, "dmg_type": "lightning",
		"tags": ["attack", "melee", "lightning"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_lightning_strike_new.png",
	},
	"poison_blade": {
		"name": "Zehirli Bıçak",
		"dmg_pct": 1.1, "cd": 3.0, "dmg_type": "chaos",
		"tags": ["attack", "melee", "chaos"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_poison_splash_anim.png",
	},
	"chaos_strike": {
		"name": "Kaos Saldırısı",
		"dmg_pct": 1.6, "cd": 3.5, "dmg_type": "chaos",
		"tags": ["attack", "melee", "chaos"], "shape": "melee",
		"range": 35.0, "max_range": 40.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_dark_explosion.png",
	},

	# ============= OKÇU SKILLERI (18) =============
	"shoot": {
		"name": "Atış",
		"dmg_pct": 1.0, "cd": 1.5, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_arrow.png",
		"hit_tex": "res://assets/generated/hit_blood_slash.png",
		"proj_speed": 400.0,
	},
	"multi_shot": {
		"name": "Çoklu Atış",
		"dmg_pct": 0.7, "cd": 3.0, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 180.0, "max_range": 280.0,
		"proj_tex": "res://assets/generated/proj_arrow.png",
		"hit_tex": "res://assets/generated/hit_blood_slash.png",
		"proj_speed": 380.0, "proj_count": 3, "proj_spread": 0.2,
	},
	"power_shot": {
		"name": "Güç Atışı",
		"dmg_pct": 2.0, "cd": 3.0, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 250.0, "max_range": 350.0,
		"proj_tex": "res://assets/generated/proj_arrow.png",
		"hit_tex": "res://assets/generated/hit_ground_shock.png",
		"proj_speed": 500.0,
	},
	"poison_arrow": {
		"name": "Zehirli Ok",
		"dmg_pct": 1.0, "cd": 3.0, "dmg_type": "chaos",
		"tags": ["attack", "projectile", "chaos"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_poison_arrow.png",
		"hit_tex": "res://assets/generated/hit_poison_splash_anim.png",
		"proj_speed": 350.0,
	},
	"fire_arrow": {
		"name": "Alev Oku",
		"dmg_pct": 1.3, "cd": 2.5, "dmg_type": "fire",
		"tags": ["attack", "projectile", "fire"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_fire_arrow.png",
		"hit_tex": "res://assets/generated/hit_fire_explosion_new.png",
		"proj_speed": 380.0,
	},
	"ice_arrow": {
		"name": "Buz Oku",
		"dmg_pct": 1.3, "cd": 2.5, "dmg_type": "cold",
		"tags": ["attack", "projectile", "cold"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_ice_arrow.png",
		"hit_tex": "res://assets/generated/hit_ice_shatter_new.png",
		"proj_speed": 380.0,
	},
	"lightning_arrow": {
		"name": "Yıldırım Oku",
		"dmg_pct": 1.3, "cd": 2.5, "dmg_type": "lightning",
		"tags": ["attack", "projectile", "lightning"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_lightning_arrow.png",
		"hit_tex": "res://assets/generated/hit_lightning_strike_new.png",
		"proj_speed": 420.0,
	},
	"rain_of_arrows": {
		"name": "Ok Yağmuru",
		"dmg_pct": 0.8, "cd": 4.0, "dmg_type": "physical",
		"tags": ["attack", "aoe"], "shape": "aoe",
		"range": 200.0, "max_range": 300.0, "aoe_radius": 80.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_blood_slash.png",
		"target": "at_player_aoe",
	},
	"barrage": {
		"name": "Yağmur",
		"dmg_pct": 0.5, "cd": 3.5, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 180.0, "max_range": 280.0,
		"proj_tex": "res://assets/generated/proj_arrow.png",
		"hit_tex": "res://assets/generated/hit_blood_slash.png",
		"proj_speed": 500.0, "proj_count": 5, "proj_spread": 0.1,
	},
	"snipe": {
		"name": "Nişancı",
		"dmg_pct": 3.0, "cd": 5.0, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 350.0, "max_range": 450.0,
		"proj_tex": "res://assets/generated/proj_magic_arrow.png",
		"hit_tex": "res://assets/generated/hit_ground_shock.png",
		"proj_speed": 600.0,
	},
	"arrow_nova": {
		"name": "Yayılan Oklar",
		"dmg_pct": 0.6, "cd": 4.0, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 150.0, "max_range": 250.0,
		"proj_tex": "res://assets/generated/proj_arrow.png",
		"hit_tex": "res://assets/generated/hit_blood_slash.png",
		"proj_speed": 350.0, "proj_count": 8, "proj_spread": 0.5,
	},
	"piercing_shot": {
		"name": "Delici Atış",
		"dmg_pct": 1.5, "cd": 3.0, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 250.0, "max_range": 350.0,
		"proj_tex": "res://assets/generated/proj_magic_arrow.png",
		"hit_tex": "res://assets/generated/hit_slash_arc_new.png",
		"proj_speed": 450.0,
	},
	"split_arrow": {
		"name": "Bölünen Ok",
		"dmg_pct": 1.2, "cd": 3.5, "dmg_type": "physical",
		"tags": ["attack", "projectile"], "shape": "projectile",
		"range": 180.0, "max_range": 280.0,
		"proj_tex": "res://assets/generated/proj_arrow.png",
		"hit_tex": "res://assets/generated/hit_blood_slash.png",
		"proj_speed": 380.0,
	},
	"explosive_arrow": {
		"name": "Patlayıcı Ok",
		"dmg_pct": 1.5, "cd": 4.0, "dmg_type": "fire",
		"tags": ["attack", "projectile", "fire", "aoe"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_fire_arrow.png",
		"hit_tex": "res://assets/generated/hit_fire_explosion_new.png",
		"proj_speed": 350.0, "aoe_radius": 60.0,
	},
	"caustic_arrow": {
		"name": "Kostik Ok",
		"dmg_pct": 0.8, "cd": 4.0, "dmg_type": "chaos",
		"tags": ["attack", "projectile", "chaos"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_poison_arrow.png",
		"hit_tex": "res://assets/generated/ground_poison_cloud.png",
		"proj_speed": 320.0,
	},
	"freezing_arrow": {
		"name": "Donduran Ok",
		"dmg_pct": 1.2, "cd": 4.0, "dmg_type": "cold",
		"tags": ["attack", "projectile", "cold"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_ice_arrow.png",
		"hit_tex": "res://assets/generated/hit_ice_burst.png",
		"proj_speed": 380.0,
	},
	"shocking_arrow": {
		"name": "Şok Eden Ok",
		"dmg_pct": 1.2, "cd": 4.0, "dmg_type": "lightning",
		"tags": ["attack", "projectile", "lightning"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_lightning_arrow.png",
		"hit_tex": "res://assets/generated/hit_lightning_strike_new.png",
		"proj_speed": 420.0,
	},
	"burning_arrow": {
		"name": "Yakan Ok",
		"dmg_pct": 1.5, "cd": 3.5, "dmg_type": "fire",
		"tags": ["attack", "projectile", "fire"], "shape": "projectile",
		"range": 200.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_fire_arrow.png",
		"hit_tex": "res://assets/generated/hit_fire_explosion_new.png",
		"proj_speed": 380.0,
	},

	# ============= BÜYÜCÜ SKILLERI (18) =============
	"fireball": {
		"name": "Ateş Topu",
		"dmg_pct": 1.2, "cd": 2.0, "dmg_type": "fire",
		"tags": ["spell", "projectile", "fire"], "shape": "projectile",
		"range": 250.0, "max_range": 350.0,
		"proj_tex": "res://assets/generated/proj_fireball_anim.png",
		"hit_tex": "res://assets/generated/hit_fire_explosion_new.png",
		"proj_speed": 300.0,
		"proj_anim_fw": 32, "proj_anim_fh": 32,
		"proj_anim_cols": 4, "proj_anim_count": 8,
		"proj_anim_fps": 12.0,
	},
	"frostbolt": {
		"name": "Buz Mermisi",
		"dmg_pct": 1.1, "cd": 2.0, "dmg_type": "cold",
		"tags": ["spell", "projectile", "cold"], "shape": "projectile",
		"range": 250.0, "max_range": 350.0,
		"proj_tex": "res://assets/generated/proj_frostbolt_anim.png",
		"hit_tex": "res://assets/generated/hit_ice_shatter_new.png",
		"proj_speed": 320.0,
	},
	"lightning_bolt": {
		"name": "Yıldırım",
		"dmg_pct": 1.3, "cd": 2.5, "dmg_type": "lightning",
		"tags": ["spell", "projectile", "lightning"], "shape": "projectile",
		"range": 280.0, "max_range": 380.0,
		"proj_tex": "res://assets/generated/proj_lightning_anim.png",
		"hit_tex": "res://assets/generated/hit_lightning_strike_new.png",
		"proj_speed": 500.0,
	},
	"arc": {
		"name": "Ark",
		"dmg_pct": 1.0, "cd": 3.0, "dmg_type": "lightning",
		"tags": ["spell", "projectile", "lightning"], "shape": "projectile",
		"range": 250.0, "max_range": 350.0,
		"proj_tex": "res://assets/generated/proj_lightning.png",
		"hit_tex": "res://assets/generated/hit_lightning_strike_new.png",
		"proj_speed": 600.0,
	},
	"fire_nova": {
		"name": "Ateş Halkası",
		"dmg_pct": 1.0, "cd": 3.5, "dmg_type": "fire",
		"tags": ["spell", "aoe", "fire"], "shape": "aoe",
		"range": 100.0, "max_range": 150.0, "aoe_radius": 80.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_nova_ring.png",
		"target": "self_aoe",
	},
	"ice_nova": {
		"name": "Buz Halkası",
		"dmg_pct": 1.0, "cd": 3.5, "dmg_type": "cold",
		"tags": ["spell", "aoe", "cold"], "shape": "aoe",
		"range": 100.0, "max_range": 150.0, "aoe_radius": 80.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_nova_ring.png",
		"target": "self_aoe",
	},
	"lightning_nova": {
		"name": "Yıldırım Halkası",
		"dmg_pct": 1.1, "cd": 3.5, "dmg_type": "lightning",
		"tags": ["spell", "aoe", "lightning"], "shape": "aoe",
		"range": 100.0, "max_range": 150.0, "aoe_radius": 80.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_lightning_strike_new.png",
		"target": "self_aoe",
	},
	"meteor": {
		"name": "Meteor",
		"dmg_pct": 2.5, "cd": 5.0, "dmg_type": "fire",
		"tags": ["spell", "aoe", "fire"], "shape": "aoe",
		"range": 200.0, "max_range": 400.0, "aoe_radius": 80.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_fire_explosion_new.png",
		"target": "at_player_aoe",
	},
	"blizzard": {
		"name": "Kar Fırtınası",
		"dmg_pct": 0.5, "cd": 5.0, "dmg_type": "cold",
		"tags": ["spell", "aoe", "cold"], "shape": "aoe",
		"range": 200.0, "max_range": 350.0, "aoe_radius": 100.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/ground_blizzard.png",
		"target": "at_player_aoe",
	},
	"poison_cloud": {
		"name": "Zehir Bulutu",
		"dmg_pct": 0.6, "cd": 4.0, "dmg_type": "chaos",
		"tags": ["spell", "aoe", "chaos"], "shape": "aoe",
		"range": 200.0, "max_range": 300.0, "aoe_radius": 90.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/ground_poison_cloud.png",
		"target": "at_player_aoe",
	},
	"chaos_bolt": {
		"name": "Kaos Mermisi",
		"dmg_pct": 1.4, "cd": 2.5, "dmg_type": "chaos",
		"tags": ["spell", "projectile", "chaos"], "shape": "projectile",
		"range": 250.0, "max_range": 350.0,
		"proj_tex": "res://assets/generated/proj_chaos.png",
		"hit_tex": "res://assets/generated/hit_dark_explosion.png",
		"proj_speed": 350.0,
	},
	"frost_nova": {
		"name": "Don Halkası",
		"dmg_pct": 1.3, "cd": 4.0, "dmg_type": "cold",
		"tags": ["spell", "aoe", "cold"], "shape": "aoe",
		"range": 100.0, "max_range": 150.0, "aoe_radius": 80.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_ice_burst.png",
		"target": "self_aoe",
	},
	"firestorm": {
		"name": "Ateş Fırtınası",
		"dmg_pct": 0.7, "cd": 4.5, "dmg_type": "fire",
		"tags": ["spell", "aoe", "fire"], "shape": "aoe",
		"range": 200.0, "max_range": 350.0, "aoe_radius": 90.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_fire_explosion_new.png",
		"target": "at_player_aoe",
	},
	"lightning_storm": {
		"name": "Yıldırım Fırtınası",
		"dmg_pct": 0.8, "cd": 4.5, "dmg_type": "lightning",
		"tags": ["spell", "aoe", "lightning"], "shape": "aoe",
		"range": 200.0, "max_range": 350.0, "aoe_radius": 90.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_lightning_strike_new.png",
		"target": "at_player_aoe",
	},
	"mana_drain": {
		"name": "Mana Emme",
		"dmg_pct": 0.8, "cd": 4.0, "dmg_type": "chaos",
		"tags": ["spell", "projectile", "chaos"], "shape": "projectile",
		"range": 250.0, "max_range": 350.0,
		"proj_tex": "res://assets/generated/proj_arcane.png",
		"hit_tex": "res://assets/generated/hit_dark_explosion.png",
		"proj_speed": 380.0,
	},
	"dark_bolt": {
		"name": "Karanlık Mermi",
		"dmg_pct": 1.5, "cd": 3.0, "dmg_type": "chaos",
		"tags": ["spell", "projectile", "chaos"], "shape": "projectile",
		"range": 280.0, "max_range": 380.0,
		"proj_tex": "res://assets/generated/proj_dark_arrow.png",
		"hit_tex": "res://assets/generated/hit_dark_explosion.png",
		"proj_speed": 400.0,
	},
	"summon_minion": {
		"name": "Çağır",
		"dmg_pct": 0.0, "cd": 10.0, "dmg_type": "physical",
		"tags": ["spell"], "shape": "buff",
		"range": 0.0, "max_range": 0.0,
		"proj_tex": "", "hit_tex": "",
		"target": "self_buff",
	},
	"blink": {
		"name": "Işınlanma",
		"dmg_pct": 0.0, "cd": 8.0, "dmg_type": "physical",
		"tags": ["movement"], "shape": "buff",
		"range": 0.0, "max_range": 0.0,
		"proj_tex": "", "hit_tex": "res://assets/generated/hit_dark_explosion.png",
		"target": "self_buff",
	},
	"fire_orbital": {
		"name": "Ateş Küreleri",
		"dmg_pct": 0.8, "cd": 0.1, "dmg_type": "fire",
		"tags": ["attack", "fire", "spell"], "shape": "orbital",
		"range": 0.0, "max_range": 300.0,
		"proj_tex": "res://assets/generated/proj_fire_orb.png",
		"hit_tex": "res://assets/generated/fx_fire_explosion.png",
		"orbital_count": 6,
		"orbital_radius": 80.0,
		"orbital_speed": 1.5,
		"fire_speed": 350.0,
		"aggro_range": 200.0,
	},
}

# DGG'nin hangi skill ID'lerine sahip oldugunu tanimla
## Her enemy ID'si -> { "class": EnemyClass, "skills": [skill_id, ...] }
const ENEMY_SKILL_ASSIGNMENTS: Dictionary = {
	# ===== TIER 1 =====
	"rat":       { "class": EnemyClass.MELEE,  "skills": ["slash"] },
	"bat":       { "class": EnemyClass.MELEE,  "skills": ["slash", "puncture"] },
	"slime":     { "class": EnemyClass.MELEE,  "skills": ["ground_slam"] },
	"spider":    { "class": EnemyClass.MELEE,  "skills": ["slash", "poison_blade"] },

	# ===== TIER 2 =====
	"skeleton":  { "class": EnemyClass.MELEE,  "skills": ["slash", "shield_bash"] },
	"zombie":    { "class": EnemyClass.MELEE,  "skills": ["power_strike", "cleave"] },
	"goblin":    { "class": EnemyClass.RANGED, "skills": ["shoot", "multi_shot", "poison_arrow"] },
	"wolf":      { "class": EnemyClass.MELEE,  "skills": ["slash", "puncture", "fury"] },

	# ===== TIER 3 =====
	"orc":       { "class": EnemyClass.MELEE,  "skills": ["power_strike", "cleave", "ground_slam"] },
	"knight":    { "class": EnemyClass.MELEE,  "skills": ["slash", "shield_bash", "whirlwind", "fire_slash"] },
	"shaman":    { "class": EnemyClass.MAGE,   "skills": ["fireball", "frostbolt", "lightning_bolt", "fire_nova"] },
	"scorpion":  { "class": EnemyClass.MELEE,  "skills": ["puncture", "poison_blade", "chaos_strike"] },

	# ===== TIER 4 =====
	"wraith":        { "class": EnemyClass.MAGE,   "skills": ["frostbolt", "frost_nova", "dark_bolt", "blink"] },
	"troll":         { "class": EnemyClass.MELEE,  "skills": ["ground_slam", "power_strike", "sweep", "leap_slam"] },
	"imp":           { "class": EnemyClass.MAGE,   "skills": ["fireball", "meteor", "firestorm", "fire_nova"] },
	"serpent":       { "class": EnemyClass.RANGED, "skills": ["poison_cloud", "caustic_arrow", "chaos_bolt", "poison_blade"] },
	"fire_elemental":{ "class": EnemyClass.MAGE,   "skills": ["fireball", "meteor", "fire_nova", "firestorm", "lightning_bolt"] },

	# ===== TIER 5: Boss =====
	"ogre_boss":     { "class": EnemyClass.BOSS, "skills": ["ground_slam", "leap_slam", "power_strike", "whirlwind", "cleave"] },
	"necromancer":   { "class": EnemyClass.BOSS, "skills": ["dark_bolt", "chaos_bolt", "frostbolt", "arc", "blizzard", "summon_minion"] },
	"hydra":         { "class": EnemyClass.BOSS, "skills": ["fireball", "lightning_bolt", "fire_arrow", "fire_orbital", "poison_cloud", "rain_of_arrows"] },
	"demon_lord":    { "class": EnemyClass.BOSS, "skills": ["fireball", "meteor", "firestorm", "fire_nova", "fire_orbital", "dark_bolt"] },

	# ===== NEW TIER 1 =====
	"mole":          { "class": EnemyClass.MELEE,  "skills": ["slash", "ground_slam"] },
	"frog":          { "class": EnemyClass.MELEE,  "skills": ["slash", "puncture"] },
	"snail":         { "class": EnemyClass.MELEE,  "skills": ["ground_slam"] },
	"rabbit":        { "class": EnemyClass.MELEE,  "skills": ["slash", "puncture"] },
	"crow":          { "class": EnemyClass.MELEE,  "skills": ["slash"] },
	"bee":           { "class": EnemyClass.MELEE,  "skills": ["puncture", "poison_blade"] },
	"worm":          { "class": EnemyClass.MELEE,  "skills": ["poison_blade"] },
	"mushroom":      { "class": EnemyClass.MAGE,   "skills": ["poison_cloud", "chaos_bolt"] },

	# ===== NEW TIER 2 =====
	"bandit":        { "class": EnemyClass.RANGED, "skills": ["shoot", "multi_shot", "poison_arrow"] },
	"cultist":       { "class": EnemyClass.MAGE,   "skills": ["dark_bolt", "chaos_bolt", "poison_cloud"] },
	"ghoul":         { "class": EnemyClass.MELEE,  "skills": ["slash", "puncture", "cleave"] },
	"wasp":          { "class": EnemyClass.MELEE,  "skills": ["puncture", "poison_blade"] },
	"boar":          { "class": EnemyClass.MELEE,  "skills": ["power_strike", "cleave", "fury"] },
	"turtle":        { "class": EnemyClass.MELEE,  "skills": ["shield_bash", "ground_slam"] },
	"mummy":         { "class": EnemyClass.MELEE,  "skills": ["slash", "chaos_strike"] },
	"salamander":    { "class": EnemyClass.MAGE,   "skills": ["fireball", "fire_nova", "meteor"] },

	# ===== NEW TIER 3 =====
	"minotaur":      { "class": EnemyClass.MELEE,  "skills": ["power_strike", "cleave", "ground_slam", "whirlwind"] },
	"harpy":         { "class": EnemyClass.RANGED, "skills": ["shoot", "multi_shot", "ice_arrow"] },
	"golem":         { "class": EnemyClass.MELEE,  "skills": ["ground_slam", "shield_bash", "power_strike"] },
	"lich":          { "class": EnemyClass.MAGE,   "skills": ["frostbolt", "frost_nova", "dark_bolt", "blizzard"] },
	"basilisk":      { "class": EnemyClass.MAGE,   "skills": ["poison_cloud", "chaos_bolt", "caustic_arrow"] },
	"centaur":       { "class": EnemyClass.RANGED, "skills": ["shoot", "multi_shot", "fire_arrow", "ice_arrow"] },
	"werewolf":      { "class": EnemyClass.MELEE,  "skills": ["slash", "puncture", "fury", "cleave"] },
	"chimera":       { "class": EnemyClass.MAGE,   "skills": ["fireball", "lightning_bolt", "poison_cloud", "fire_nova"] },
	"treant":        { "class": EnemyClass.MELEE,  "skills": ["ground_slam", "power_strike", "sweep"] },
	"naga":          { "class": EnemyClass.MAGE,   "skills": ["poison_cloud", "chaos_bolt", "dark_bolt"] },
	"gargoyle":      { "class": EnemyClass.MELEE,  "skills": ["slash", "shield_bash", "cleave"] },
	"crab":          { "class": EnemyClass.MELEE,  "skills": ["shield_bash", "ground_slam", "cleave"] },
	"scarab":        { "class": EnemyClass.MELEE,  "skills": ["power_strike", "cleave", "shield_bash"] },
	"mandrake":      { "class": EnemyClass.MAGE,   "skills": ["poison_cloud", "chaos_bolt", "dark_bolt"] },

	# ===== NEW TIER 4 =====
	"drake":         { "class": EnemyClass.MELEE,  "skills": ["fire_slash", "fireball", "ground_slam", "cleave"] },
	"beholder":      { "class": EnemyClass.MAGE,   "skills": ["lightning_bolt", "arc", "lightning_storm", "frostbolt"] },
	"giant":         { "class": EnemyClass.MELEE,  "skills": ["ground_slam", "leap_slam", "power_strike", "whirlwind", "sweep"] },
	"succubus":      { "class": EnemyClass.MAGE,   "skills": ["dark_bolt", "chaos_bolt", "blink", "fireball"] },
	"phantom":       { "class": EnemyClass.MAGE,   "skills": ["frostbolt", "frost_nova", "blink", "dark_bolt"] },
	"gorgon":        { "class": EnemyClass.MAGE,   "skills": ["chaos_bolt", "dark_bolt", "poison_cloud", "frostbolt"] },
	"phoenix":       { "class": EnemyClass.MAGE,   "skills": ["fireball", "meteor", "fire_nova", "firestorm", "lightning_bolt"] },
	"manticore":     { "class": EnemyClass.RANGED, "skills": ["poison_cloud", "caustic_arrow", "chaos_bolt", "multi_shot"] },
	"wyvern":        { "class": EnemyClass.MELEE,  "skills": ["poison_blade", "chaos_strike", "fire_slash", "cleave"] },
	"siren":         { "class": EnemyClass.MAGE,   "skills": ["frostbolt", "frost_nova", "blizzard", "ice_arrow"] },
	"shadow":        { "class": EnemyClass.MELEE,  "skills": ["puncture", "poison_blade", "chaos_strike", "blink"] },
	"banshee":       { "class": EnemyClass.MAGE,   "skills": ["frostbolt", "frost_nova", "dark_bolt", "blizzard"] },

	# ===== NEW TIER 5: Boss =====
	"dragon":        { "class": EnemyClass.BOSS, "skills": ["fireball", "meteor", "firestorm", "fire_nova", "fire_orbital", "fire_slash"] },
	"lich_king":     { "class": EnemyClass.BOSS, "skills": ["frostbolt", "frost_nova", "blizzard", "dark_bolt", "blink", "summon_minion"] },
	"leviathan":     { "class": EnemyClass.BOSS, "skills": ["frostbolt", "blizzard", "ice_arrow", "ground_slam", "cleave", "shield_bash"] },
	"titan":         { "class": EnemyClass.BOSS, "skills": ["ground_slam", "leap_slam", "power_strike", "whirlwind", "sweep", "cleave"] },
	"archdemon":     { "class": EnemyClass.BOSS, "skills": ["fireball", "meteor", "firestorm", "fire_nova", "fire_orbital", "chaos_bolt"] },
	"sphinx":        { "class": EnemyClass.BOSS, "skills": ["lightning_bolt", "arc", "lightning_storm", "fireball", "shoot", "multi_shot"] },
	"kraken":        { "class": EnemyClass.BOSS, "skills": ["chaos_bolt", "dark_bolt", "poison_cloud", "cleave", "sweep", "ground_slam"] },
	"vampire_lord":  { "class": EnemyClass.BOSS, "skills": ["dark_bolt", "chaos_bolt", "blink", "puncture", "slash", "fury"] },
}

## Skill ID'sine gore skill datasini getir
static func get_skill_data(skill_id: String) -> Dictionary:
	return SKILL_DB.get(skill_id, {})

## Dusman icin skill listesini getir
static func get_enemy_skills(enemy_id: String) -> Array:
	var assignment: Dictionary = ENEMY_SKILL_ASSIGNMENTS.get(enemy_id, {})
	return assignment.get("skills", [])

## Dusman sinifini getir
static func get_enemy_class(enemy_id: String) -> int:
	var assignment: Dictionary = ENEMY_SKILL_ASSIGNMENTS.get(enemy_id, {})
	return assignment.get("class", EnemyClass.MELEE)

## Dusman sinif ismini getir
static func get_class_name(class_id: int) -> String:
	return ENEMY_CLASS_NAMES.get(class_id, "Bilinmeyen")

## Skill'in hangi tur hedefleme kullandigini soyler
static func get_skill_targeting(skill: Dictionary) -> String:
	return skill.get("target", "toward_player")