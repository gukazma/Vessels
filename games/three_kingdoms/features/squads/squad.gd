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
@export_range(0.05, 20.0) var turn_speed: float = TURN_SPEED
@export var team: int = 0
@export var definition: UnitDefinition

var max_health: float = 252.0
var health: float = 252.0
var show_facing: bool = false

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
var _attack_flash: float = 0.0
var _attack_target: Vector2
var _defense_flash: float = 0.0
var _defense_label: String = ""


func _ready() -> void:
	_destination = global_position
	if definition != null:
		configure(definition, team)
	_initialize_formation()
	queue_redraw()


func configure(unit: UnitDefinition, faction: int) -> void:
	definition = unit
	team = faction
	walk_speed = unit.move_speed if unit != null else 105.0
	max_health = (unit.member_health if unit != null else 36.0) * FORMATION.size()
	restore()


func living_members() -> int:
	# Losses remove the last formation slot first; slot zero is the flag bearer.
	if health <= 0.0:
		return 0
	return clampi(ceili(health / (max_health / FORMATION.size())), 1, FORMATION.size())


func is_alive() -> bool:
	return health > 0.0


func take_damage(amount: float) -> void:
	if not is_finite(amount) or amount <= 0.0 or not is_alive():
		return
	health = maxf(0.0, health - amount)
	if not is_alive():
		stop()
		_selected = false
		_attack_flash = 0.0
	queue_redraw()


func restore() -> void:
	health = max_health
	_attack_flash = 0.0
	_defense_flash = 0.0
	_defense_label = ""
	_stride = 0.0
	_facing = Vector2.UP
	_desired_facing = Vector2.UP
	_initialize_formation()
	stop()
	queue_redraw()


func face_direction(direction: Vector2) -> void:
	if not is_alive() or not direction.is_finite() or direction.is_zero_approx():
		return
	_desired_facing = direction.normalized()
	_formation_frozen = false


func facing_direction() -> Vector2:
	return _facing


func set_facing_immediate(direction: Vector2) -> void:
	if not direction.is_finite() or direction.is_zero_approx():
		return
	_facing = direction.normalized()
	_desired_facing = _facing
	_initialize_formation()
	queue_redraw()


func flash_defense(label: String) -> void:
	if not is_alive():
		return
	_defense_label = label
	_defense_flash = 1.0
	queue_redraw()


func flash_attack(target: Vector2) -> void:
	if not is_alive() or not target.is_finite():
		return
	_attack_target = target
	_attack_flash = 0.14
	queue_redraw()


func set_selected(selected: bool) -> void:
	_selected = selected and is_alive()
	queue_redraw()


func is_selected() -> bool:
	return _selected


func issue_move(target: Vector2, path: PackedVector2Array = PackedVector2Array()) -> void:
	if not is_alive() or not target.is_finite():
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
	_attack_flash = 0.0
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
	for member: int in mini(living_members(), _member_offsets.size()):
		positions.append(to_global(_member_offsets[member]))
	return positions


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	_attack_flash = maxf(0.0, _attack_flash - delta)
	_defense_flash = maxf(0.0, _defense_flash - delta)
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
	var angle: float = rotate_toward(_facing.angle(), _desired_facing.angle(), turn_speed * delta)
	_facing = Vector2.from_angle(angle)
	for member: int in _member_offsets.size():
		_member_offsets[member] = _member_offsets[member].move_toward(
			_slot_offset(FORMATION[member]), FORMATION_SPEED * delta
		)


func _draw() -> void:
	if _member_offsets.is_empty() or not is_alive():
		return
	if _selected:
		_draw_selection()
	if show_facing:
		_draw_facing()
	for member: int in living_members():
		var offset: Vector2 = _member_offsets[member]
		draw_circle(offset + Vector2(1.0, 2.0), 4.3 if member == 0 else 3.2,
			Color(0.08, 0.12, 0.13, 0.25))
	# Sort inside this one squad so a lower soldier covers a higher soldier's spear.
	var draw_order: Array[int] = []
	for member: int in living_members():
		draw_order.append(member)
	draw_order.sort_custom(func(a: int, b: int) -> bool:
		return _member_offsets[a].y < _member_offsets[b].y
	)
	for member: int in draw_order:
		_draw_member(member)
	if definition != null:
		draw_rect(Rect2(-19.0, -31.0, 38.0, 4.0), Color("263e43"))
		draw_rect(Rect2(-18.0, -30.0, 36.0 * health / max_health, 2.0), accent.lightened(0.35))
		var font: Font = ThemeDB.fallback_font
		var caption: String = "%s %d" % [definition.display_name, living_members()]
		var width: float = font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_string(font, Vector2(-width * 0.5, -36.0), caption,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("263e43"))
	if _attack_flash > 0.0:
		var end: Vector2 = to_local(_attack_target)
		var color: Color = Color("f5d68a", _attack_flash / 0.14)
		if definition != null and definition.ranged:
			draw_line(Vector2.ZERO, end, color, 1.4)
		else:
			draw_arc(end * 0.5, 10.0, end.angle() - 0.8, end.angle() + 0.8, 6, color, 2.0)
	if _defense_flash > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-24.0, 38.0), _defense_label,
			HORIZONTAL_ALIGNMENT_CENTER, 48.0, 12, Color("263e43"))


func _draw_facing() -> void:
	var right: Vector2 = Vector2(-_facing.y, _facing.x)
	var tip: Vector2 = _facing * 30.0
	draw_line(_facing * 22.0, tip, accent.darkened(0.3), 1.5)
	draw_line(tip, tip - _facing * 5.0 + right * 3.0, accent.darkened(0.3), 1.5)
	draw_line(tip, tip - _facing * 5.0 - right * 3.0, accent.darkened(0.3), 1.5)
	if definition != null and definition.ranged_damage_multiplier < 1.0:
		draw_arc(Vector2.ZERO, 25.0, _facing.angle() - PI / 3.0, _facing.angle() + PI / 3.0,
			16, Color(accent.r, accent.g, accent.b, 0.7), 2.0)


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
