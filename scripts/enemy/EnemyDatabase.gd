extends Node
class_name EnemyDatabase
## 21 farkli dusman tipini tanimlayan veritabani.
## Her dusman: id, ad, tier, stats, drop pool.

const ENEMY_TYPES := {
	# ===== TIER 1: Zayif (rats, bats, slimes, spiders) =====
	"rat": {
		"id": "rat",
		"name": "Dev Fare",
		"tier": 1,
		"base_health": 20.0, "speed": 55.0, "contact_damage": 3.0,
		"attack_cooldown": 0.8, "xp_reward": 5.0, "armour": 0.0,
		"aggro_range": 450.0, "leash_range": 1400.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.25,
		"drop_item_types": ["weapon", "helmet", "boots"],
		"sprite": "res://assets/generated/enemy_rat_frame_0.png"
	},
	"bat": {
		"id": "bat",
		"name": "Yarasa",
		"tier": 1,
		"base_health": 15.0, "speed": 70.0, "contact_damage": 2.0,
		"attack_cooldown": 0.6, "xp_reward": 4.0, "armour": 0.0,
		"aggro_range": 500.0, "leash_range": 800.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.2,
		"drop_item_types": ["helmet", "gloves"],
		"sprite": "res://assets/generated/enemy_bat_frame_0.png"
	},
	"slime": {
		"id": "slime",
		"name": "Balçık",
		"tier": 1,
		"base_health": 30.0, "speed": 30.0, "contact_damage": 4.0,
		"attack_cooldown": 1.5, "xp_reward": 6.0, "armour": 2.0,
		"aggro_range": 375.0, "leash_range": 1200.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 50.0},
		"drop_chance": 0.3,
		"drop_item_types": ["body_armour", "boots", "offhand"],
		"sprite": "res://assets/generated/enemy_slime_frame_0.png"
	},
	"spider": {
		"id": "spider",
		"name": "Örümcek",
		"tier": 1,
		"base_health": 25.0, "speed": 60.0, "contact_damage": 5.0,
		"attack_cooldown": 1.0, "xp_reward": 7.0, "armour": 1.0,
		"aggro_range": 475.0, "leash_range": 1400.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.28,
		"drop_item_types": ["helmet", "gloves", "weapon"],
		"sprite": "res://assets/generated/enemy_spider_frame_0.png"
	},

	# ===== TIER 2: Orta (skeleton, zombie, goblin, wolf) =====
	"skeleton": {
		"id": "skeleton",
		"name": "İskelet",
		"tier": 2,
		"base_health": 45.0, "speed": 40.0, "contact_damage": 8.0,
		"attack_cooldown": 1.2, "xp_reward": 12.0, "armour": 5.0,
		"aggro_range": 550.0, "leash_range": 800.0,
		"damage_type": "physical",
		"resistances": {"cold": 20.0},
		"drop_chance": 0.35,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand"],
		"sprite": "res://assets/generated/enemy_skeleton_frame_0.png"
	},
	"zombie": {
		"id": "zombie",
		"name": "Zombi",
		"tier": 2,
		"base_health": 60.0, "speed": 30.0, "contact_damage": 10.0,
		"attack_cooldown": 1.5, "xp_reward": 10.0, "armour": 3.0,
		"aggro_range": 500.0, "leash_range": 1400.0,
		"damage_type": "physical",
		"resistances": {"chaos": 30.0},
		"drop_chance": 0.35,
		"drop_item_types": ["body_armour", "boots", "gloves"],
		"sprite": "res://assets/generated/enemy_zombie_frame_0.png"
	},
	"goblin": {
		"id": "goblin",
		"name": "Goblin",
		"tier": 2,
		"base_health": 35.0, "speed": 50.0, "contact_damage": 7.0,
		"attack_cooldown": 1.0, "xp_reward": 13.0, "armour": 2.0,
		"aggro_range": 575.0, "leash_range": 840.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.4,
		"drop_item_types": ["weapon", "helmet", "boots", "gloves"],
		"sprite": "res://assets/generated/enemy_goblin_frame_0.png"
	},
	"wolf": {
		"id": "wolf",
		"name": "Kurt",
		"tier": 2,
		"base_health": 40.0, "speed": 65.0, "contact_damage": 9.0,
		"attack_cooldown": 0.9, "xp_reward": 13.0, "armour": 2.0,
		"aggro_range": 625.0, "leash_range": 1000.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.32,
		"drop_item_types": ["weapon", "body_armour", "boots"],
		"sprite": "res://assets/generated/enemy_wolf_frame_0.png"
	},

	# ===== TIER 3: Guclu (orc, dark knight, shaman, scorpion) =====
	"orc": {
		"id": "orc",
		"name": "Ork Savaşçı",
		"tier": 3,
		"base_health": 80.0, "speed": 45.0, "contact_damage": 14.0,
		"attack_cooldown": 1.3, "xp_reward": 20.0, "armour": 10.0,
		"aggro_range": 600.0, "leash_range": 900.0,
		"damage_type": "physical",
		"resistances": {"fire": 15.0},
		"drop_chance": 0.4,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand", "boots"],
		"sprite": "res://assets/generated/enemy_orc_frame_0.png"
	},
	"knight": {
		"id": "knight",
		"name": "Kara Şövalye",
		"tier": 3,
		"base_health": 100.0, "speed": 40.0, "contact_damage": 18.0,
		"attack_cooldown": 1.4, "xp_reward": 25.0, "armour": 15.0,
		"aggro_range": 625.0, "leash_range": 900.0,
		"damage_type": "physical",
		"resistances": {"fire": 20.0, "cold": 20.0},
		"drop_chance": 0.45,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand", "gloves", "boots", "ring", "amulet", "belt"],
		"sprite": "res://assets/generated/enemy_knight_frame_0.png"
	},
	"shaman": {
		"id": "shaman",
		"name": "Büyücü Şaman",
		"tier": 3,
		"base_health": 60.0, "speed": 35.0, "contact_damage": 12.0,
		"attack_cooldown": 2.0, "xp_reward": 27.0, "armour": 4.0,
		"aggro_range": 650.0, "leash_range": 1000.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 40.0, "lightning": 20.0},
		"drop_chance": 0.5,
		"drop_item_types": ["weapon", "offhand", "helmet", "body_armour"],
		"sprite": "res://assets/generated/enemy_shaman_frame_0.png"
	},
	"scorpion": {
		"id": "scorpion",
		"name": "Akrep",
		"tier": 3,
		"base_health": 70.0, "speed": 55.0, "contact_damage": 15.0,
		"attack_cooldown": 1.1, "xp_reward": 22.0, "armour": 12.0,
		"aggro_range": 525.0, "leash_range": 760.0,
		"damage_type": "physical",
		"resistances": {"fire": 25.0},
		"drop_chance": 0.35,
		"drop_item_types": ["weapon", "helmet", "offhand", "gloves"],
		"sprite": "res://assets/generated/enemy_scorpion_frame_0.png"
	},

	# ===== TIER 4: Elit (wraith, troll, imp, serpent, fire elemental) =====
	"wraith": {
		"id": "wraith",
		"name": "Hayalet",
		"tier": 4,
		"base_health": 90.0, "speed": 50.0, "contact_damage": 20.0,
		"attack_cooldown": 1.0, "xp_reward": 33.0, "armour": 5.0,
		"aggro_range": 700.0, "leash_range": 1000.0,
		"damage_type": "cold",
		"resistances": {"cold": 50.0, "chaos": 30.0},
		"drop_chance": 0.5,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand", "gloves", "boots", "ring", "amulet", "belt"],
		"sprite": "res://assets/generated/enemy_wraith_frame_0.png"
	},
	"troll": {
		"id": "troll",
		"name": "Dev Troll",
		"tier": 4,
		"base_health": 180.0, "speed": 35.0, "contact_damage": 25.0,
		"attack_cooldown": 1.8, "xp_reward": 40.0, "armour": 20.0,
		"aggro_range": 550.0, "leash_range": 800.0,
		"damage_type": "physical",
		"resistances": {"fire": 30.0, "cold": 10.0},
		"drop_chance": 0.55,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand", "boots"],
		"sprite": "res://assets/generated/enemy_troll_frame_0.png"
	},
	"imp": {
		"id": "imp",
		"name": "İblis Cini",
		"tier": 4,
		"base_health": 55.0, "speed": 65.0, "contact_damage": 18.0,
		"attack_cooldown": 0.8, "xp_reward": 37.0, "armour": 3.0,
		"aggro_range": 675.0, "leash_range": 1000.0,
		"damage_type": "fire",
		"resistances": {"fire": 50.0},
		"drop_chance": 0.45,
		"drop_item_types": ["weapon", "helmet", "gloves", "body_armour"],
		"sprite": "res://assets/generated/enemy_imp_frame_0.png"
	},
	"serpent": {
		"id": "serpent",
		"name": "Dev Yılan",
		"tier": 4,
		"base_health": 110.0, "speed": 50.0, "contact_damage": 22.0,
		"attack_cooldown": 1.3, "xp_reward": 32.0, "armour": 8.0,
		"aggro_range": 600.0, "leash_range": 840.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 40.0, "fire": 15.0},
		"drop_chance": 0.4,
		"drop_item_types": ["weapon", "helmet", "offhand", "body_armour", "boots"],
		"sprite": "res://assets/generated/enemy_serpent_frame_0.png"
	},
	"fire_elemental": {
		"id": "fire_elemental",
		"name": "Ateş Elementali",
		"tier": 4,
		"base_health": 75.0, "speed": 45.0, "contact_damage": 24.0,
		"attack_cooldown": 1.2, "xp_reward": 35.0, "armour": 2.0,
		"aggro_range": 650.0, "leash_range": 960.0,
		"damage_type": "fire",
		"resistances": {"fire": 75.0, "cold": -30.0},
		"drop_chance": 0.45,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand", "gloves", "boots", "ring", "amulet", "belt"],
		"sprite": "res://assets/generated/enemy_fire_elemental_frame_0.png"
	},

	# ===== TIER 5: Boss (ogre, necromancer, hydra, demon lord) =====
	"ogre_boss": {
		"id": "ogre_boss",
		"name": "Dev Ogre Lordu",
		"tier": 5,
		"base_health": 400.0, "speed": 40.0, "contact_damage": 35.0,
		"attack_cooldown": 2.0, "xp_reward": 50.0, "armour": 30.0,
		"aggro_range": 750.0, "leash_range": 1200.0,
		"damage_type": "physical",
		"resistances": {"fire": 30.0, "cold": 30.0, "lightning": 30.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand", "ring", "amulet", "belt"],
		"sprite": "res://assets/generated/enemy_ogre_boss_frame_0.png"
	},
	"necromancer": {
		"id": "necromancer",
		"name": "Nekromansi Ustası",
		"tier": 5,
		"base_health": 250.0, "speed": 35.0, "contact_damage": 28.0,
		"attack_cooldown": 1.5, "xp_reward": 60.0, "armour": 10.0,
		"aggro_range": 800.0, "leash_range": 1300.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 60.0, "cold": 40.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "offhand", "helmet", "body_armour", "gloves", "boots", "ring", "amulet", "belt"],
		"sprite": "res://assets/generated/enemy_necromancer_frame_0.png"
	},
	"hydra": {
		"id": "hydra",
		"name": "Üç Başlı Yılan",
		"tier": 5,
		"base_health": 350.0, "speed": 45.0, "contact_damage": 30.0,
		"attack_cooldown": 1.3, "xp_reward": 65.0, "armour": 20.0,
		"aggro_range": 700.0, "leash_range": 1100.0,
		"damage_type": "fire",
		"resistances": {"fire": 50.0, "cold": 50.0, "lightning": 50.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand", "ring", "amulet", "belt"],
		"sprite": "res://assets/generated/enemy_hydra_frame_0.png"
	},
	"demon_lord": {
		"id": "demon_lord",
		"name": "İblis Lordu",
		"tier": 5,
		"base_health": 500.0, "speed": 50.0, "contact_damage": 40.0,
		"attack_cooldown": 1.6, "xp_reward": 80.0, "armour": 25.0,
		"aggro_range": 875.0, "leash_range": 1400.0,
		"damage_type": "fire",
		"resistances": {"fire": 75.0, "cold": 20.0, "lightning": 40.0, "chaos": 50.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand", "ring", "amulet", "belt"],
		"sprite": "res://assets/generated/enemy_demon_lord_frame_0.png"
	},

	# ===== NEW TIER 1: Zayif (mole, frog, snail, rabbit, crow, bee, worm, mushroom) =====
	"mole": {
		"id": "mole",
		"name": "Köstebek",
		"tier": 1,
		"base_health": 18.0, "speed": 40.0, "contact_damage": 4.0,
		"attack_cooldown": 1.0, "xp_reward": 5.0, "armour": 2.0,
		"aggro_range": 400.0, "leash_range": 1200.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.22,
		"drop_item_types": ["helmet", "boots"],
		"sprite": "res://assets/generated/enemy_mole_frame_0.png"
	},
	"frog": {
		"id": "frog",
		"name": "Kurbağa",
		"tier": 1,
		"base_health": 16.0, "speed": 45.0, "contact_damage": 3.0,
		"attack_cooldown": 0.9, "xp_reward": 4.0, "armour": 0.0,
		"aggro_range": 425.0, "leash_range": 640.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.25,
		"drop_item_types": ["gloves", "boots"],
		"sprite": "res://assets/generated/enemy_frog_frame_0.png"
	},
	"snail": {
		"id": "snail",
		"name": "Sümüklü Böcek",
		"tier": 1,
		"base_health": 35.0, "speed": 20.0, "contact_damage": 3.0,
		"attack_cooldown": 2.0, "xp_reward": 6.0, "armour": 5.0,
		"aggro_range": 325.0, "leash_range": 1120.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 30.0},
		"drop_chance": 0.30,
		"drop_item_types": ["body_armour", "offhand"],
		"sprite": "res://assets/generated/enemy_snail_frame_0.png"
	},
	"rabbit": {
		"id": "rabbit",
		"name": "Vahşi Tavşan",
		"tier": 1,
		"base_health": 14.0, "speed": 75.0, "contact_damage": 2.0,
		"attack_cooldown": 0.6, "xp_reward": 3.0, "armour": 0.0,
		"aggro_range": 500.0, "leash_range": 760.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.18,
		"drop_item_types": ["boots", "gloves"],
		"sprite": "res://assets/generated/enemy_rabbit_frame_0.png"
	},
	"crow": {
		"id": "crow",
		"name": "Karga",
		"tier": 1,
		"base_health": 12.0, "speed": 80.0, "contact_damage": 3.0,
		"attack_cooldown": 0.5, "xp_reward": 4.0, "armour": 0.0,
		"aggro_range": 550.0, "leash_range": 800.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.15,
		"drop_item_types": ["helmet"],
		"sprite": "res://assets/generated/enemy_crow_frame_0.png"
	},
	"bee": {
		"id": "bee",
		"name": "Dev Arı",
		"tier": 1,
		"base_health": 10.0, "speed": 85.0, "contact_damage": 4.0,
		"attack_cooldown": 0.7, "xp_reward": 5.0, "armour": 0.0,
		"aggro_range": 575.0, "leash_range": 840.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.20,
		"drop_item_types": ["weapon", "gloves"],
		"sprite": "res://assets/generated/enemy_bee_frame_0.png"
	},
	"worm": {
		"id": "worm",
		"name": "Solucan",
		"tier": 1,
		"base_health": 22.0, "speed": 35.0, "contact_damage": 3.0,
		"attack_cooldown": 1.2, "xp_reward": 4.0, "armour": 1.0,
		"aggro_range": 350.0, "leash_range": 1040.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 20.0},
		"drop_chance": 0.24,
		"drop_item_types": ["body_armour", "offhand"],
		"sprite": "res://assets/generated/enemy_worm_frame_0.png"
	},
	"mushroom": {
		"id": "mushroom",
		"name": "Mantar",
		"tier": 1,
		"base_health": 28.0, "speed": 25.0, "contact_damage": 5.0,
		"attack_cooldown": 1.8, "xp_reward": 7.0, "armour": 1.0,
		"aggro_range": 375.0, "leash_range": 1120.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 40.0},
		"drop_chance": 0.28,
		"drop_item_types": ["helmet", "offhand"],
		"sprite": "res://assets/generated/enemy_mushroom_frame_0.png"
	},

	# ===== NEW TIER 2: Orta (bandit, cultist, ghoul, wasp, boar, turtle, mummy, salamander) =====
	"bandit": {
		"id": "bandit",
		"name": "Haydut",
		"tier": 2,
		"base_health": 38.0, "speed": 55.0, "contact_damage": 8.0,
		"attack_cooldown": 1.1, "xp_reward": 14.0, "armour": 2.0,
		"aggro_range": 600.0, "leash_range": 860.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.38,
		"drop_item_types": ["weapon", "helmet", "boots"],
		"sprite": "res://assets/generated/enemy_bandit_frame_0.png"
	},
	"cultist": {
		"id": "cultist",
		"name": "Tarikatçı",
		"tier": 2,
		"base_health": 35.0, "speed": 40.0, "contact_damage": 9.0,
		"attack_cooldown": 1.5, "xp_reward": 15.0, "armour": 1.0,
		"aggro_range": 625.0, "leash_range": 900.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 20.0},
		"drop_chance": 0.40,
		"drop_item_types": ["weapon", "offhand", "helmet"],
		"sprite": "res://assets/generated/enemy_cultist_frame_0.png"
	},
	"ghoul": {
		"id": "ghoul",
		"name": "Gul",
		"tier": 2,
		"base_health": 50.0, "speed": 45.0, "contact_damage": 11.0,
		"attack_cooldown": 1.3, "xp_reward": 13.0, "armour": 2.0,
		"aggro_range": 525.0, "leash_range": 760.0,
		"damage_type": "physical",
		"resistances": {"chaos": 15.0},
		"drop_chance": 0.32,
		"drop_item_types": ["body_armour", "gloves", "boots"],
		"sprite": "res://assets/generated/enemy_ghoul_frame_0.png"
	},
	"wasp": {
		"id": "wasp",
		"name": "Dev Eşekarısı",
		"tier": 2,
		"base_health": 30.0, "speed": 75.0, "contact_damage": 9.0,
		"attack_cooldown": 0.7, "xp_reward": 14.0, "armour": 1.0,
		"aggro_range": 625.0, "leash_range": 900.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.30,
		"drop_item_types": ["weapon", "gloves"],
		"sprite": "res://assets/generated/enemy_wasp_frame_0.png"
	},
	"boar": {
		"id": "boar",
		"name": "Yaban Domuzu",
		"tier": 2,
		"base_health": 55.0, "speed": 60.0, "contact_damage": 12.0,
		"attack_cooldown": 1.2, "xp_reward": 16.0, "armour": 4.0,
		"aggro_range": 550.0, "leash_range": 800.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.35,
		"drop_item_types": ["weapon", "helmet", "body_armour"],
		"sprite": "res://assets/generated/enemy_boar_frame_0.png"
	},
	"turtle": {
		"id": "turtle",
		"name": "Sert Kaplumbağa",
		"tier": 2,
		"base_health": 65.0, "speed": 25.0, "contact_damage": 7.0,
		"attack_cooldown": 1.6, "xp_reward": 14.0, "armour": 10.0,
		"aggro_range": 375.0, "leash_range": 1200.0,
		"damage_type": "physical",
		"resistances": {"fire": 30.0, "cold": 30.0},
		"drop_chance": 0.36,
		"drop_item_types": ["body_armour", "offhand", "helmet"],
		"sprite": "res://assets/generated/enemy_turtle_frame_0.png"
	},
	"mummy": {
		"id": "mummy",
		"name": "Mumya",
		"tier": 2,
		"base_health": 48.0, "speed": 35.0, "contact_damage": 10.0,
		"attack_cooldown": 1.4, "xp_reward": 12.0, "armour": 6.0,
		"aggro_range": 500.0, "leash_range": 1440.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 25.0, "fire": 20.0},
		"drop_chance": 0.33,
		"drop_item_types": ["body_armour", "boots", "offhand"],
		"sprite": "res://assets/generated/enemy_mummy_frame_0.png"
	},
	"salamander": {
		"id": "salamander",
		"name": "Semender",
		"tier": 2,
		"base_health": 40.0, "speed": 50.0, "contact_damage": 10.0,
		"attack_cooldown": 1.0, "xp_reward": 15.0, "armour": 2.0,
		"aggro_range": 575.0, "leash_range": 840.0,
		"damage_type": "fire",
		"resistances": {"fire": 40.0},
		"drop_chance": 0.34,
		"drop_item_types": ["weapon", "helmet", "body_armour"],
		"sprite": "res://assets/generated/enemy_salamander_frame_0.png"
	},

	# ===== NEW TIER 3: Guclu (minotaur, harpy, golem, lich, basilisk, centaur, werewolf, chimera) =====
	"minotaur": {
		"id": "minotaur",
		"name": "Minotor",
		"tier": 3,
		"base_health": 110.0, "speed": 42.0, "contact_damage": 20.0,
		"attack_cooldown": 1.5, "xp_reward": 28.0, "armour": 14.0,
		"aggro_range": 625.0, "leash_range": 920.0,
		"damage_type": "physical",
		"resistances": {"physical": 15.0},
		"drop_chance": 0.42,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots"],
		"sprite": "res://assets/generated/enemy_minotaur_frame_0.png"
	},
	"harpy": {
		"id": "harpy",
		"name": "Harpi",
		"tier": 3,
		"base_health": 55.0, "speed": 65.0, "contact_damage": 14.0,
		"attack_cooldown": 0.9, "xp_reward": 26.0, "armour": 3.0,
		"aggro_range": 700.0, "leash_range": 1040.0,
		"damage_type": "cold",
		"resistances": {"cold": 30.0},
		"drop_chance": 0.38,
		"drop_item_types": ["weapon", "boots", "gloves"],
		"sprite": "res://assets/generated/enemy_harpy_frame_0.png"
	},
	"golem": {
		"id": "golem",
		"name": "Taş Golem",
		"tier": 3,
		"base_health": 130.0, "speed": 30.0, "contact_damage": 22.0,
		"attack_cooldown": 2.0, "xp_reward": 30.0, "armour": 25.0,
		"aggro_range": 500.0, "leash_range": 760.0,
		"damage_type": "physical",
		"resistances": {"physical": 30.0, "fire": 40.0, "cold": 40.0},
		"drop_chance": 0.44,
		"drop_item_types": ["body_armour", "helmet", "offhand", "boots"],
		"sprite": "res://assets/generated/enemy_golem_frame_0.png"
	},
	"lich": {
		"id": "lich",
		"name": "İskelet Büyücü",
		"tier": 3,
		"base_health": 65.0, "speed": 38.0, "contact_damage": 13.0,
		"attack_cooldown": 2.2, "xp_reward": 29.0, "armour": 5.0,
		"aggro_range": 700.0, "leash_range": 1040.0,
		"damage_type": "cold",
		"resistances": {"cold": 40.0, "chaos": 25.0},
		"drop_chance": 0.45,
		"drop_item_types": ["weapon", "offhand", "helmet"],
		"sprite": "res://assets/generated/enemy_lich_frame_0.png"
	},
	"basilisk": {
		"id": "basilisk",
		"name": "Basilisk",
		"tier": 3,
		"base_health": 85.0, "speed": 50.0, "contact_damage": 17.0,
		"attack_cooldown": 1.3, "xp_reward": 27.0, "armour": 8.0,
		"aggro_range": 600.0, "leash_range": 860.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 35.0, "fire": 20.0},
		"drop_chance": 0.40,
		"drop_item_types": ["weapon", "helmet", "body_armour"],
		"sprite": "res://assets/generated/enemy_basilisk_frame_0.png"
	},
	"centaur": {
		"id": "centaur",
		"name": "Centaur",
		"tier": 3,
		"base_health": 75.0, "speed": 60.0, "contact_damage": 15.0,
		"attack_cooldown": 1.0, "xp_reward": 28.0, "armour": 6.0,
		"aggro_range": 675.0, "leash_range": 1000.0,
		"damage_type": "physical",
		"resistances": {"physical": 10.0},
		"drop_chance": 0.42,
		"drop_item_types": ["weapon", "boots", "body_armour"],
		"sprite": "res://assets/generated/enemy_centaur_frame_0.png"
	},
	"werewolf": {
		"id": "werewolf",
		"name": "Kurtadam",
		"tier": 3,
		"base_health": 90.0, "speed": 70.0, "contact_damage": 19.0,
		"attack_cooldown": 1.1, "xp_reward": 30.0, "armour": 7.0,
		"aggro_range": 650.0, "leash_range": 960.0,
		"damage_type": "physical",
		"resistances": {},
		"drop_chance": 0.40,
		"drop_item_types": ["weapon", "gloves", "boots", "helmet"],
		"sprite": "res://assets/generated/enemy_werewolf_frame_0.png"
	},
	"chimera": {
		"id": "chimera",
		"name": "Kimera",
		"tier": 3,
		"base_health": 95.0, "speed": 48.0, "contact_damage": 20.0,
		"attack_cooldown": 1.4, "xp_reward": 32.0, "armour": 10.0,
		"aggro_range": 625.0, "leash_range": 900.0,
		"damage_type": "fire",
		"resistances": {"fire": 30.0, "chaos": 20.0},
		"drop_chance": 0.44,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand"],
		"sprite": "res://assets/generated/enemy_chimera_frame_0.png"
	},

	# ===== NEW TIER 4: Elit (drake, beholder, giant, succubus, phantom, gorgon, phoenix, manticore) =====
	"drake": {
		"id": "drake",
		"name": "Ejder",
		"tier": 4,
		"base_health": 120.0, "speed": 48.0, "contact_damage": 26.0,
		"attack_cooldown": 1.4, "xp_reward": 38.0, "armour": 15.0,
		"aggro_range": 675.0, "leash_range": 960.0,
		"damage_type": "fire",
		"resistances": {"fire": 50.0, "cold": 10.0},
		"drop_chance": 0.48,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots"],
		"sprite": "res://assets/generated/enemy_drake_frame_0.png"
	},
	"beholder": {
		"id": "beholder",
		"name": "Gözcü",
		"tier": 4,
		"base_health": 80.0, "speed": 55.0, "contact_damage": 22.0,
		"attack_cooldown": 1.1, "xp_reward": 40.0, "armour": 4.0,
		"aggro_range": 750.0, "leash_range": 1100.0,
		"damage_type": "lightning",
		"resistances": {"lightning": 50.0, "cold": 20.0},
		"drop_chance": 0.50,
		"drop_item_types": ["weapon", "helmet", "offhand", "gloves"],
		"sprite": "res://assets/generated/enemy_beholder_frame_0.png"
	},
	"giant": {
		"id": "giant",
		"name": "Dev",
		"tier": 4,
		"base_health": 200.0, "speed": 30.0, "contact_damage": 30.0,
		"attack_cooldown": 2.0, "xp_reward": 45.0, "armour": 22.0,
		"aggro_range": 575.0, "leash_range": 840.0,
		"damage_type": "physical",
		"resistances": {"physical": 20.0, "fire": 20.0},
		"drop_chance": 0.52,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots"],
		"sprite": "res://assets/generated/enemy_giant_frame_0.png"
	},
	"succubus": {
		"id": "succubus",
		"name": "Succubus",
		"tier": 4,
		"base_health": 70.0, "speed": 60.0, "contact_damage": 20.0,
		"attack_cooldown": 1.0, "xp_reward": 36.0, "armour": 3.0,
		"aggro_range": 700.0, "leash_range": 1040.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 50.0, "fire": 30.0},
		"drop_chance": 0.48,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand"],
		"sprite": "res://assets/generated/enemy_succubus_frame_0.png"
	},
	"phantom": {
		"id": "phantom",
		"name": "Hortlak",
		"tier": 4,
		"base_health": 75.0, "speed": 55.0, "contact_damage": 20.0,
		"attack_cooldown": 1.2, "xp_reward": 34.0, "armour": 2.0,
		"aggro_range": 700.0, "leash_range": 1040.0,
		"damage_type": "cold",
		"resistances": {"cold": 60.0, "chaos": 40.0},
		"drop_chance": 0.46,
		"drop_item_types": ["weapon", "body_armour", "offhand", "gloves"],
		"sprite": "res://assets/generated/enemy_phantom_frame_0.png"
	},
	"gorgon": {
		"id": "gorgon",
		"name": "Gorgon",
		"tier": 4,
		"base_health": 100.0, "speed": 42.0, "contact_damage": 24.0,
		"attack_cooldown": 1.6, "xp_reward": 38.0, "armour": 12.0,
		"aggro_range": 625.0, "leash_range": 900.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 45.0, "physical": 15.0},
		"drop_chance": 0.48,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots"],
		"sprite": "res://assets/generated/enemy_gorgon_frame_0.png"
	},
	"phoenix": {
		"id": "phoenix",
		"name": "Anka Kuşu",
		"tier": 4,
		"base_health": 85.0, "speed": 50.0, "contact_damage": 26.0,
		"attack_cooldown": 1.3, "xp_reward": 40.0, "armour": 5.0,
		"aggro_range": 675.0, "leash_range": 1000.0,
		"damage_type": "fire",
		"resistances": {"fire": 80.0, "cold": -40.0},
		"drop_chance": 0.50,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand", "gloves", "boots"],
		"sprite": "res://assets/generated/enemy_phoenix_frame_0.png"
	},
	"manticore": {
		"id": "manticore",
		"name": "Manticore",
		"tier": 4,
		"base_health": 115.0, "speed": 52.0, "contact_damage": 28.0,
		"attack_cooldown": 1.5, "xp_reward": 42.0, "armour": 14.0,
		"aggro_range": 650.0, "leash_range": 940.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 40.0, "fire": 30.0, "physical": 10.0},
		"drop_chance": 0.50,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand", "boots"],
		"sprite": "res://assets/generated/enemy_manticore_frame_0.png"
	},

	# ===== NEW TIER 5: Boss (dragon, lich_king, leviathan, titan, archdemon, sphinx, kraken, vampire_lord) =====
	"dragon": {
		"id": "dragon",
		"name": "Ejderha Kralı",
		"tier": 5,
		"base_health": 450.0, "speed": 42.0, "contact_damage": 38.0,
		"attack_cooldown": 1.8, "xp_reward": 70.0, "armour": 28.0,
		"aggro_range": 800.0, "leash_range": 1300.0,
		"damage_type": "fire",
		"resistances": {"fire": 70.0, "cold": 30.0, "lightning": 30.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand"],
		"sprite": "res://assets/generated/enemy_dragon_frame_0.png"
	},
	"lich_king": {
		"id": "lich_king",
		"name": "İskelet Kral",
		"tier": 5,
		"base_health": 300.0, "speed": 38.0, "contact_damage": 30.0,
		"attack_cooldown": 1.6, "xp_reward": 75.0, "armour": 15.0,
		"aggro_range": 850.0, "leash_range": 1360.0,
		"damage_type": "cold",
		"resistances": {"cold": 70.0, "chaos": 50.0, "fire": 20.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "offhand", "helmet", "body_armour", "gloves", "boots"],
		"sprite": "res://assets/generated/enemy_lich_king_frame_0.png"
	},
	"leviathan": {
		"id": "leviathan",
		"name": "Leviathan",
		"tier": 5,
		"base_health": 380.0, "speed": 48.0, "contact_damage": 32.0,
		"attack_cooldown": 1.5, "xp_reward": 72.0, "armour": 22.0,
		"aggro_range": 750.0, "leash_range": 1200.0,
		"damage_type": "cold",
		"resistances": {"cold": 60.0, "fire": 20.0, "lightning": 40.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand"],
		"sprite": "res://assets/generated/enemy_leviathan_frame_0.png"
	},
	"titan": {
		"id": "titan",
		"name": "Titan",
		"tier": 5,
		"base_health": 550.0, "speed": 35.0, "contact_damage": 45.0,
		"attack_cooldown": 2.2, "xp_reward": 85.0, "armour": 35.0,
		"aggro_range": 700.0, "leash_range": 1100.0,
		"damage_type": "physical",
		"resistances": {"physical": 40.0, "fire": 40.0, "cold": 40.0, "lightning": 40.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand"],
		"sprite": "res://assets/generated/enemy_titan_frame_0.png"
	},
	"archdemon": {
		"id": "archdemon",
		"name": "Baş İblis",
		"tier": 5,
		"base_health": 480.0, "speed": 45.0, "contact_damage": 42.0,
		"attack_cooldown": 1.7, "xp_reward": 85.0, "armour": 20.0,
		"aggro_range": 900.0, "leash_range": 1440.0,
		"damage_type": "fire",
		"resistances": {"fire": 80.0, "cold": 10.0, "lightning": 30.0, "chaos": 40.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand"],
		"sprite": "res://assets/generated/enemy_archdemon_frame_0.png"
	},
	"sphinx": {
		"id": "sphinx",
		"name": "Sfenks",
		"tier": 5,
		"base_health": 340.0, "speed": 44.0, "contact_damage": 34.0,
		"attack_cooldown": 1.4, "xp_reward": 68.0, "armour": 24.0,
		"aggro_range": 775.0, "leash_range": 1240.0,
		"damage_type": "lightning",
		"resistances": {"lightning": 60.0, "fire": 30.0, "cold": 30.0, "chaos": 30.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand"],
		"sprite": "res://assets/generated/enemy_sphinx_frame_0.png"
	},
	"kraken": {
		"id": "kraken",
		"name": "Kraken",
		"tier": 5,
		"base_health": 420.0, "speed": 40.0, "contact_damage": 36.0,
		"attack_cooldown": 1.9, "xp_reward": 75.0, "armour": 26.0,
		"aggro_range": 725.0, "leash_range": 1160.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 60.0, "cold": 50.0, "fire": 10.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand"],
		"sprite": "res://assets/generated/enemy_kraken_frame_0.png"
	},
	"vampire_lord": {
		"id": "vampire_lord",
		"name": "Vampir Lordu",
		"tier": 5,
		"base_health": 320.0, "speed": 52.0, "contact_damage": 32.0,
		"attack_cooldown": 1.3, "xp_reward": 70.0, "armour": 18.0,
		"aggro_range": 825.0, "leash_range": 1320.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 55.0, "cold": 40.0, "fire": 20.0},
		"drop_chance": 1.0,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots", "gloves", "offhand"],
		"sprite": "res://assets/generated/enemy_vampire_lord_frame_0.png"
	},

	# ===== NEW TIER 3-4: Ek canavarlar (treant, naga, gargoyle, wyvern, siren, shadow, banshee, crab, scarab, mandrake) =====
	"treant": {
		"id": "treant",
		"name": "Ağaç Devri",
		"tier": 3,
		"base_health": 120.0, "speed": 28.0, "contact_damage": 18.0,
		"attack_cooldown": 1.8, "xp_reward": 28.0, "armour": 18.0,
		"aggro_range": 500.0, "leash_range": 760.0,
		"damage_type": "physical",
		"resistances": {"fire": -20.0, "cold": 30.0},
		"drop_chance": 0.42,
		"drop_item_types": ["body_armour", "helmet", "boots"],
		"sprite": "res://assets/generated/enemy_treant_frame_0.png"
	},
	"naga": {
		"id": "naga",
		"name": "Naga",
		"tier": 3,
		"base_health": 70.0, "speed": 55.0, "contact_damage": 16.0,
		"attack_cooldown": 1.2, "xp_reward": 26.0, "armour": 5.0,
		"aggro_range": 650.0, "leash_range": 960.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 30.0, "fire": 10.0},
		"drop_chance": 0.40,
		"drop_item_types": ["weapon", "helmet", "offhand"],
		"sprite": "res://assets/generated/enemy_naga_frame_0.png"
	},
	"gargoyle": {
		"id": "gargoyle",
		"name": "Gargoyle",
		"tier": 3,
		"base_health": 88.0, "speed": 45.0, "contact_damage": 18.0,
		"attack_cooldown": 1.3, "xp_reward": 27.0, "armour": 16.0,
		"aggro_range": 600.0, "leash_range": 880.0,
		"damage_type": "physical",
		"resistances": {"physical": 25.0, "fire": 30.0},
		"drop_chance": 0.40,
		"drop_item_types": ["weapon", "helmet", "body_armour"],
		"sprite": "res://assets/generated/enemy_gargoyle_frame_0.png"
	},
	"wyvern": {
		"id": "wyvern",
		"name": "Wyvern",
		"tier": 4,
		"base_health": 105.0, "speed": 55.0, "contact_damage": 25.0,
		"attack_cooldown": 1.3, "xp_reward": 38.0, "armour": 10.0,
		"aggro_range": 675.0, "leash_range": 980.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 35.0, "fire": 30.0},
		"drop_chance": 0.46,
		"drop_item_types": ["weapon", "helmet", "body_armour", "boots"],
		"sprite": "res://assets/generated/enemy_wyvern_frame_0.png"
	},
	"siren": {
		"id": "siren",
		"name": "Deniz Kızı",
		"tier": 4,
		"base_health": 65.0, "speed": 50.0, "contact_damage": 20.0,
		"attack_cooldown": 1.0, "xp_reward": 36.0, "armour": 3.0,
		"aggro_range": 725.0, "leash_range": 1080.0,
		"damage_type": "cold",
		"resistances": {"cold": 45.0, "chaos": 20.0},
		"drop_chance": 0.46,
		"drop_item_types": ["weapon", "offhand", "helmet"],
		"sprite": "res://assets/generated/enemy_siren_frame_0.png"
	},
	"shadow": {
		"id": "shadow",
		"name": "Gölge",
		"tier": 4,
		"base_health": 60.0, "speed": 70.0, "contact_damage": 22.0,
		"attack_cooldown": 0.8, "xp_reward": 35.0, "armour": 2.0,
		"aggro_range": 750.0, "leash_range": 1120.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 50.0, "physical": 15.0},
		"drop_chance": 0.44,
		"drop_item_types": ["weapon", "gloves", "boots"],
		"sprite": "res://assets/generated/enemy_shadow_frame_0.png"
	},
	"banshee": {
		"id": "banshee",
		"name": "Cadı",
		"tier": 4,
		"base_health": 70.0, "speed": 48.0, "contact_damage": 22.0,
		"attack_cooldown": 1.2, "xp_reward": 37.0, "armour": 3.0,
		"aggro_range": 725.0, "leash_range": 1060.0,
		"damage_type": "cold",
		"resistances": {"cold": 55.0, "chaos": 35.0},
		"drop_chance": 0.46,
		"drop_item_types": ["weapon", "helmet", "body_armour", "offhand"],
		"sprite": "res://assets/generated/enemy_banshee_frame_0.png"
	},
	"crab": {
		"id": "crab",
		"name": "Dev Yengeç",
		"tier": 3,
		"base_health": 100.0, "speed": 35.0, "contact_damage": 16.0,
		"attack_cooldown": 1.5, "xp_reward": 24.0, "armour": 20.0,
		"aggro_range": 450.0, "leash_range": 680.0,
		"damage_type": "physical",
		"resistances": {"physical": 20.0, "fire": 20.0, "cold": 20.0},
		"drop_chance": 0.38,
		"drop_item_types": ["body_armour", "helmet", "gloves"],
		"sprite": "res://assets/generated/enemy_crab_frame_0.png"
	},
	"scarab": {
		"id": "scarab",
		"name": "Bok Böceği",
		"tier": 3,
		"base_health": 90.0, "speed": 40.0, "contact_damage": 17.0,
		"attack_cooldown": 1.2, "xp_reward": 25.0, "armour": 18.0,
		"aggro_range": 525.0, "leash_range": 760.0,
		"damage_type": "physical",
		"resistances": {"physical": 15.0, "chaos": 20.0},
		"drop_chance": 0.38,
		"drop_item_types": ["weapon", "helmet", "body_armour"],
		"sprite": "res://assets/generated/enemy_scarab_frame_0.png"
	},
	"mandrake": {
		"id": "mandrake",
		"name": "Mandrake",
		"tier": 3,
		"base_health": 60.0, "speed": 32.0, "contact_damage": 15.0,
		"attack_cooldown": 1.6, "xp_reward": 26.0, "armour": 4.0,
		"aggro_range": 575.0, "leash_range": 840.0,
		"damage_type": "chaos",
		"resistances": {"chaos": 40.0, "fire": -10.0},
		"drop_chance": 0.40,
		"drop_item_types": ["weapon", "offhand", "helmet"],
		"sprite": "res://assets/generated/enemy_mandrake_frame_0.png"
	}
}

## ID'ye gore dusman tipi verisi getir
static func get_enemy_type(enemy_id: String) -> Dictionary:
	return ENEMY_TYPES.get(enemy_id, {})

## Belirli bir tier'daki dusman ID'lerini getir
static func get_enemies_by_tier(tier: int) -> Array[String]:
	var result: Array[String] = []
	for id in ENEMY_TYPES:
		if ENEMY_TYPES[id].tier == tier:
			result.append(id)
	return result

## Tier araligindaki dusmanlari getir (min_tier ile max_tier arasi)
static func get_enemies_in_tier_range(min_tier: int, max_tier: int) -> Array[String]:
	var result: Array[String] = []
	for id in ENEMY_TYPES:
		var t: int = ENEMY_TYPES[id].tier
		if t >= min_tier and t <= max_tier:
			result.append(id)
	return result

## Rastgele bir dusman ID'si sec (tier agirlikli)
static func get_random_enemy_for_map(map_tier: int = 1) -> String:
	var candidates: Array[String] = []
	# Harita tier'ina gore hangi dusmanlarin cikacagini belirle
	var min_tier := maxi(1, map_tier - 1)
	var max_tier := mini(5, map_tier + 1)
	for id in ENEMY_TYPES:
		var t: int = ENEMY_TYPES[id].tier
		if t >= min_tier and t <= max_tier:
			candidates.append(id)
	if candidates.is_empty():
		candidates = get_enemies_in_tier_range(1, 3)
	return candidates[randi() % candidates.size()]

## Harita icin kac adet ve hangi dusmanlarin spawn olacagini belirle
## map_tier: 1-5, enemy_count: toplam dusman sayisi
static func generate_spawn_list(map_tier: int, enemy_count: int) -> Array[String]:
	var list: Array[String] = []

	# Harita tier'ina gore % dagilim
	var tier1_pct: float = 0.0
	var tier2_pct: float = 0.0
	var tier3_pct: float = 0.0
	var tier4_pct: float = 0.0
	var tier5_pct: float = 0.0

	match map_tier:
		1: tier1_pct = 0.5; tier2_pct = 0.35; tier3_pct = 0.15
		2: tier1_pct = 0.2; tier2_pct = 0.4; tier3_pct = 0.3; tier4_pct = 0.1
		3: tier2_pct = 0.25; tier3_pct = 0.35; tier4_pct = 0.3; tier5_pct = 0.1
		4: tier2_pct = 0.1; tier3_pct = 0.3; tier4_pct = 0.4; tier5_pct = 0.2
		5: tier3_pct = 0.2; tier4_pct = 0.4; tier5_pct = 0.4
		_: tier1_pct = 0.3; tier2_pct = 0.3; tier3_pct = 0.3; tier4_pct = 0.1

	var tier_pcts := {1: tier1_pct, 2: tier2_pct, 3: tier3_pct, 4: tier4_pct, 5: tier5_pct}

	for i in range(enemy_count):
		var roll := randf()
		var cumulative := 0.0
		var chosen_tier := 1
		for t in range(1, 6):
			cumulative += tier_pcts[t]
			if roll <= cumulative:
				chosen_tier = t
				break
		var tier_enemies := get_enemies_by_tier(chosen_tier)
		if tier_enemies.is_empty():
			tier_enemies = get_enemies_by_tier(1)
		var eid := tier_enemies[randi() % tier_enemies.size()]
		list.append(eid)

	return list
