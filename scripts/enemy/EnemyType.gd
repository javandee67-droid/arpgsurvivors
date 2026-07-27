extends Resource
class_name EnemyType
## Dusman tipini tanimlayan veri kaynagi. Her dusman cesidi icin bir .tres.

## Benzersiz ID (rat, skeleton, orc vb.)
@export var id: String = ""
## Ekranda gorunen ad
@export var display_name: String = ""
## Sprite dosya yolu
@export var sprite_texture: Texture2D = null
## Zorluk kademesi (1=en zayif, 5=en guclu/boss)
@export var tier: int = 1
## Temel can
@export var base_health: float = 50.0
## Temel mana
@export var base_mana: float = 0.0
## Hareket hizi
@export var speed: float = 40.0
## Temas hasari
@export var contact_damage: float = 5.0
## Saldiri araligi (saniye)
@export var attack_cooldown: float = 1.2
## XP odulu
@export var xp_reward: float = 30.0
## Kovalama mesafesi
@export var aggro_range: float = 200.0
## Baglanma mesafesi (bu kadar uzaklasirsa pes et)
@export var leash_range: float = 400.0
## Hasar turu (physical, fire, cold, lightning, chaos)
@export var damage_type: String = "physical"
## Zirh / savunma
@export var armour: float = 0.0
## Direncler {fire, cold, lightning, chaos}
@export var resistances: Dictionary = {}
## Dusme sansi (0.0 - 1.0)
@export var drop_chance: float = 0.35
## Base item tipleri (drop havuzu)
@export var drop_item_types: Array[String] = ["weapon", "helmet", "body_armour", "gloves", "boots", "offhand"]
## Olunce ozel efekt sprite (opsiyonel)
@export var death_effect: Texture2D = null
