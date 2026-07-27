extends Area2D
class_name GroundEffect
## Zemin efekti (yanık alanı, zehir havuzu vb.)
## Belirli bir süre boyunca icindeki dusmanlara periyodik hasar verir.

var damage: float = 0.0
var damage_type: String = "fire"
var tags: Array[String] = []
var source: Node = null
var tick_interval: float = 0.5
var lifetime: float = 3.0
var _elapsed: float = 0.0
var _hit_bodies: Array[Node] = []

func _ready() -> void:
	var timer := get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body in _hit_bodies:
		return
	if source and source.is_in_group("player"):
		if not body.is_in_group("enemy"):
			return
	if body.has_node("Health"):
		_hit_bodies.append(body)

func _on_body_exited(body: Node) -> void:
	_hit_bodies.erase(body)

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= tick_interval:
		_elapsed = 0.0
		for body in _hit_bodies:
			if not is_instance_valid(body) or not body.has_node("Health"):
				continue
			var h := body.get_node("Health") as Health
			if h.current_health <= 0:
				continue
			h.take_damage(damage, source, tags, false, 0.0)
			if source and source is Player:
				EventBus.skill_damage.emit("toxic_circle", damage, tags)

func setup(dmg: float, dmg_type: String, tag_arr: Array[String], src: Node, dur: float = 3.0, radius: float = 60.0) -> void:
	damage = dmg
	damage_type = dmg_type
	tags = tag_arr
	source = src
	lifetime = dur
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = radius
