extends Node2D
## BuffAura: Haste/Aura açıkken oyuncunun etrafında dönen bir halka efekti.

var _rotation_speed: float = 2.0  # Saniyede tur
var _angle: float = 0.0
var _ring_radius: float = 36.0   # Oyuncunun merkezinden uzaklık
var _dot_count: int = 12         # Halkadaki nokta sayısı
var _pulse_time: float = 0.0

func _ready() -> void:
	z_index = 2  # Oyuncunun üstünde görünsün

func _process(delta: float) -> void:
	_angle += delta * _rotation_speed * TAU
	_pulse_time += delta * 1.5
	queue_redraw()

func _draw() -> void:
	var center := Vector2.ZERO
	var base_alpha: float = 0.6 + 0.4 * sin(_pulse_time)
	var base_color := Color(1.0, 0.85, 0.3, base_alpha)  # Altın sarısı
	
	# Dış halka (büyük, soluk)
	draw_arc(center, _ring_radius, 0.0, TAU, 32, Color(1.0, 0.85, 0.3, base_alpha * 0.3), 2.0)
	
	# Dönen noktalar
	for i in range(_dot_count):
		var a: float = _angle + (TAU / _dot_count) * i
		var dot_pos := center + Vector2(cos(a), sin(a)) * _ring_radius
		var dot_size: float = 3.0 + 1.5 * sin(_pulse_time + float(i))
		var dot_color := Color(base_color.r, base_color.g, base_color.b, base_alpha * (0.6 + 0.4 * sin(_pulse_time + float(i) * 2.0)))
		draw_circle(dot_pos, dot_size, dot_color)
	
	# İç halka (küçük, hafif)
	var inner_radius: float = _ring_radius * 0.7
	draw_arc(center, inner_radius, _angle, _angle + PI * 1.5, 24, Color(1.0, 0.9, 0.5, base_alpha * 0.2), 1.5)
