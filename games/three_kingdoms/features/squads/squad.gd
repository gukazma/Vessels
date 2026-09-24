class_name TacticalSquad
extends Node2D
## One controllable formation. Orders and paths use global coordinates.
## The battlefield owns pathfinding and keeps a 24 px clearance around obstacles.

const FORMATION: Array[Vector2] = [
	Vector2(0.0, 10.0),
	Vector2(-8.0, 2.0), Vector2(8.0, 2.0),
	Vector2(-8.0, -6.0), Vector2(8.0, -6.0),
	Vector2(-8.0, -14.0), Vector2(8.0, -14.0),
]
const ARRIVAL_EPSILON: float = 0.05
const TURN_SPEED: float = 7.0
const FORMATION_SPEED: float = 58.0

@export var squad_name: String = "Squad"
@export var accent: Color = Color("689a8a")
@export_range(1.0, 400.0, 1.0) var walk_speed: float = 105.0

var _selected: bool = false
var _moving: bool = false
var _formation_frozen: bool = false
var _destination: Vector2
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _facing: Vector2 = Vector2.UP
var _desired_facing: Vector2 = Vector2.UP
var _member_offsets: PackedVector2Array = PackedVector2Array()
var _stride: float = 0.0


func _ready() -> void:
	_destination = global_position
	_initialize_formation()
	queue_redraw()


func set_selected(selected: bool) -> void:
	_selected = selected
	queue_redraw()


func is_selected() -> bool:
	return _selected


func issue_move(target: Vector2, path: PackedVector2Array = PackedVector2Array()) -> void:
	if not target.is_finite():
		return
	var valid_path: PackedVector2Array = PackedVector2Array()
	for waypoint: Vector2 in path:
		if not waypoint.is_finite():
			return
		valid_path.append(waypoint)
	if valid_path.is_empty() or not valid_path[-1].is_equal_approx(target):
		valid_path.append(target)
	_destination = target
	_path = valid_path
	_path_index = 0
	_formation_frozen = false
	_moving = true


func stop() -> void:
	_moving = false
	_path.clear()
	_path_index = 0
	_destination = global_position
	_formation_frozen = true
	queue_redraw()


func is_moving() -> bool:
	return _moving


func destination() -> Vector2:
	return _destination


func get_member_positions() -> PackedVector2Array:
	var positions: PackedVector2Array = PackedVector2Array()
	for offset: Vector2 in _member_offsets:
		positions.append(to_global(offset))
	return positions


func _physics_process(delta: float) -> void:
	var previous_position: Vector2 = global_position
	if _moving:
		_advance_path(walk_speed * delta)
	var distance_travelled: float = global_position.distance_to(previous_position)
	_stride = fmod(_stride + distance_travelled * 0.2, TAU)
	if not _formation_frozen:
		_update_formation(delta)
	queue_redraw()


func _advance_path(distance_budget: float) -> void:
	while _path_index < _path.size():
		var offset: Vector2 = _path[_path_index] - global_position
		var distance: float = offset.length()
		if distance <= ARRIVAL_EPSILON:
			global_position = _path[_path_index]
			_path_index += 1
			continue
		_desired_facing = offset / distance
		if distance_budget < distance:
			global_position += _desired_facing * distance_budget
			return
		global_position = _path[_path_index]
		distance_budget -= distance
		_path_index += 1
	_moving = false
	_path.clear()
	_path_index = 0


func _initialize_formation() -> void:
	_member_offsets.clear()
	for slot: Vector2 in FORMATION:
		_member_offsets.append(_slot_offset(slot))


func _slot_offset(slot: Vector2) -> Vector2:
	var right: Vector2 = Vector2(-_facing.y, _facing.x)
	return right * slot.x + _facing * slot.y


func _update_formation(delta: float) -> void:
	var angle: float = rotate_toward(_facing.angle(), _desired_facing.angle(), TURN_SPEED * delta)
	_facing = Vector2.from_angle(angle)
	for member: int in _member_offsets.size():
		_member_offsets[member] = _member_offsets[member].move_toward(
			_slot_offset(FORMATION[member]), FORMATION_SPEED * delta
		)


func _draw() -> void:
	if _member_offsets.is_empty():
		return
	if _selected:
		_draw_selection()
	for member: int in _member_offsets.size():
		var offset: Vector2 = _member_offsets[member]
		draw_circle(offset + Vector2(1.0, 2.0), 4.3 if member == 0 else 3.2,
			Color(0.08, 0.12, 0.13, 0.25))
	# Sort inside this one squad so a lower soldier covers a higher soldier's spear.
	var draw_order: Array[int] = []
	for member: int in _member_offsets.size():
		draw_order.append(member)
	draw_order.sort_custom(func(a: int, b: int) -> bool:
		return _member_offsets[a].y < _member_offsets[b].y
	)
	for member: int in draw_order:
		_draw_member(member)


func _draw_selection() -> void:
	var color: Color = accent.lightened(0.42)
	color.a = 0.85
	for segment: int in 12:
		var start: float = float(segment) * TAU / 12.0
		draw_arc(Vector2.ZERO, 23.0, start, start + TAU / 19.0, 4, color, 1.3, true)
	draw_circle(Vector2.ZERO, 21.0, Color(accent.r, accent.g, accent.b, 0.055))


func _draw_member(member: int) -> void:
	var center: Vector2 = _member_offsets[member]
	var right: Vector2 = Vector2(-_facing.y, _facing.x)
	var leader: bool = member == 0
	var radius: float = 3.6 if leader else 2.7
	var ink: Color = Color("263e43")
	var body: Color = accent.lightened(0.12) if leader else accent.darkened(0.12)
	if _moving:
		var step: float = sin(_stride + float(member) * PI * 0.7) * 1.0
		draw_line(center - right * 1.5, center - right * 1.5 + _facing * step, ink, 1.6)
		draw_line(center + right * 1.5, center + right * 1.5 - _facing * step, ink, 1.6)
	if not leader:
		var grip: Vector2 = center + right * 2.7
		draw_line(grip - _facing * 1.5, grip + _facing * 6.0, Color("6a6354"), 1.0)
		draw_line(grip + _facing * 6.0, grip + _facing * 7.2, Color("dfdfd0"), 1.3)
	draw_line(center - right * radius, center + right * radius, ink, radius * 1.5, true)
	draw_circle(center, radius, ink)
	draw_circle(center, radius - 0.8, body)
	draw_circle(center + _facing * 0.5, 1.6 if leader else 1.2, Color("d7c6a1"))
	draw_line(center - _facing * 0.8 - right * 1.5,
		center - _facing * 0.8 + right * 1.5, ink, 1.1)
	if leader:
		var flag_base: Vector2 = center - right * 4.0
		var flag_tip: Vector2 = flag_base + Vector2(0.0, -9.0)
		draw_line(flag_base, flag_tip, Color("cec9b2"), 1.0)
		draw_colored_polygon(PackedVector2Array([
			flag_tip, flag_tip + Vector2(-5.0, 1.0), flag_tip + Vector2(0.0, 4.0)
		]), accent.lightened(0.5))
