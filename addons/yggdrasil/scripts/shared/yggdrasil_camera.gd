@tool
class_name YggdrasilCamera
extends RefCounted
## Camera for panning and zooming a Yggdrasil tree view.

signal zoom_changed(zoom: float, previous_zoom: float)

var _viewport: Control
var _bounds: Rect2

var _zoom: float = 1.0
var _dragging = false
var _last_mouse_pos: Vector2

func set_viewport(viewport: Control) -> void:
	_viewport = viewport
	# Use direct position/scale instead of offset_transform for reliable zoom-toward-center behavior
	_viewport.offset_transform_enabled = false
	_viewport.get_parent().resized.connect(_on_viewport_resized)

func set_bounds(bounds: Rect2) -> void:
	_bounds = bounds

func input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		set_camera_zoom(min(_zoom + 0.1, 2.0))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		set_camera_zoom(max(_zoom - 0.1, 0.08))
	elif event is InputEventMouseButton:
		# Left, middle, or right mouse button starts/stops drag (pan)
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_RIGHT]:
			_dragging = event.pressed
			if _dragging:
				_last_mouse_pos = event.position
	elif event is InputEventMouseMotion and _dragging:
		var delta = event.position - _last_mouse_pos
		_last_mouse_pos = event.position
		_on_camera_dragged(delta)

func set_camera_zoom(zoom: float, _unused: Vector2 = Vector2(-1, -1)):
	var previous_zoom = _zoom
	_zoom = clamp(zoom, 0.05, 2.0)
	if _zoom == previous_zoom:
		return

	var view_size = _viewport.get_parent().get_rect().size
	var ratio = _zoom / previous_zoom
	var old_pos = _viewport.position

	# Zoom toward viewport center (maintains current pan position)
	var center = view_size * 0.5
	var new_pos = center - (center - old_pos) * ratio
	_viewport.position = new_pos

	_viewport.scale = Vector2(_zoom, _zoom)
	# _clamp() devre disi - kullanici konumunu koru
	# _clamp()

	zoom_changed.emit(_zoom, previous_zoom)

	_viewport.scale = Vector2(_zoom, _zoom)
	_clamp()

	zoom_changed.emit(_zoom, previous_zoom)

func _on_camera_dragged(delta: Vector2):
	_viewport.position += delta
	_clamp()

func _on_viewport_resized():
	_clamp()

func _clamp():
	# Clamp'i devre disi birakiyoruz - kullanici aaci nereye kaydirdiysa orada kalsin
	# Bu sayede zoom yaparken viewport merkeze isinlanmiyor
	pass
