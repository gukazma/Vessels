class_name BattleCamera
extends Camera2D
## Camera input is independent of unit orders and respects the world boundary.

const MIN_ZOOM: float = 0.65
const MAX_ZOOM: float = 1.8
@export var pan_speed: float = 620.0
var world_bounds: Rect2 = Rect2(0, 0, 1800, 1200)
var _dragging: bool = false


func _process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	position += direction * pan_speed * delta / zoom.x
	_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var previous_mouse: Vector2 = get_global_mouse_position()
			var factor: float = 1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12
			zoom = Vector2.ONE * clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
			force_update_scroll()
			position += previous_mouse - get_global_mouse_position()
			_clamp_position()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		position -= event.relative / zoom.x
		_clamp_position()
		get_viewport().set_input_as_handled()


func focus_on(at: Vector2) -> void:
	position = at
	_clamp_position()
	force_update_scroll()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_dragging = false


func _clamp_position() -> void:
	var half_view: Vector2 = get_viewport_rect().size / (zoom * 2.0)
	for axis: int in range(2):
		var minimum: float = world_bounds.position[axis] + half_view[axis]
		var maximum: float = world_bounds.end[axis] - half_view[axis]
		position[axis] = clampf(position[axis], minimum, maximum) if minimum <= maximum \
			else world_bounds.get_center()[axis]
