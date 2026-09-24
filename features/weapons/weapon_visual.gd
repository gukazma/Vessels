class_name WeaponVisual
extends Node2D
## Actor-local grip rig. The parent body masks rear-facing weapons and effects.

const SHOT_DURATION: float = 0.12
const SWING_DURATION: float = 0.22
const FRONT_FORESHORTENING: float = 0.625
var _item: ItemDefinition
var _remaining: float = 0.0
var _attack_direction: Vector2 = Vector2.RIGHT
var _traces: Array[Vector2] = []
var _trace_start: Vector2
var _trace_start_pending: bool = false
var _tip: Vector2
@onready var _pivot: Node2D = $Pivot
@onready var _held: Sprite2D = $Pivot/Held


func set_weapon(item: ItemDefinition) -> void:
	if _item == item:
		return
	_item = item
	_remaining = 0.0
	_traces.clear()
	_trace_start_pending = false
	visible = item != null
	_held.texture = item.held_texture if item != null else null
	_held.offset = -item.held_grip if item != null else Vector2.ZERO
	_tip = item.held_tip if item != null else Vector2.ZERO
	queue_redraw()


func is_firearm_equipped() -> bool:
	return _item != null and _item.magazine_size > 0


func set_hand_socket(socket: Vector2) -> void:
	position = socket
	# Movement selects this frame's body pose after the attack has been resolved.
	# Commit the tracer origin here so a turn-and-fire uses the raised hand's new position.
	if _trace_start_pending:
		_trace_start = muzzle_global_position()
		_trace_start_pending = false


func facing_direction(aim: Vector2) -> Vector2:
	return _attack_direction if _remaining > 0.0 else aim


func update_pose(aim: Vector2, delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	var direction: Vector2 = facing_direction(aim)
	# Keeping z_index at zero preserves the entire player's world Y-sort group.
	show_behind_parent = direction.y < 0.0
	# Forward/back aim needs a view along the barrel, not a rotated side profile.
	var horizontal: bool = absf(direction.x) > absf(direction.y)
	var axial: bool = _item != null and not horizontal and _item.held_axial_texture != null
	if _item != null:
		_held.texture = _item.held_axial_texture if axial else _item.held_texture
		_tip = _item.held_axial_tip if axial else _item.held_tip
	# Flip at the body's cardinal turn, not when the mouse crosses straight up.
	var mirrored: bool = direction.x < 0.0 if horizontal else direction.y < 0.0
	var mirror: float = -1.0 if mirrored else 1.0
	# A barrel pointing toward the camera projects shorter than its side profile.
	var length_scale: float = FRONT_FORESHORTENING if axial and direction.y > 0.0 else 1.0
	_pivot.scale = Vector2(length_scale, mirror)
	_pivot.rotation = direction.angle()
	_pivot.position = Vector2.ZERO
	if _item != null and _remaining > 0.0:
		if _item.magazine_size == 0:
			var progress: float = 1.0 - _remaining / SWING_DURATION
			# Sweep through the attack cone, then return to the resting grip.
			var angle: float = lerpf(-1.0, 1.0, progress / 0.7) if progress < 0.7 \
				else lerpf(1.0, 0.0, (progress - 0.7) / 0.3)
			_pivot.rotation += angle * mirror
		else:
			var kick: float = _remaining / SHOT_DURATION
			_pivot.position = -direction * 2.0 * kick
			_pivot.rotation -= mirror * 0.12 * kick
	queue_redraw()


func play_attack(aim: Vector2, traces: Array[Vector2]) -> void:
	if _item == null:
		return
	_attack_direction = aim
	_remaining = SWING_DURATION if _item.magazine_size == 0 else SHOT_DURATION
	_traces = traces.duplicate()
	update_pose(aim, 0.0)
	_trace_start = muzzle_global_position()
	_trace_start_pending = not _traces.is_empty()


func muzzle_global_position() -> Vector2:
	return _pivot.to_global(_tip - _item.held_grip) if _item != null else global_position


func _draw() -> void:
	if _item == null or _remaining <= 0.0:
		return
	var tint: Color = Color("f5d991")
	if _item.magazine_size == 0:
		tint.a = _remaining / SWING_DURATION
		draw_arc(Vector2.ZERO, 21.0, _pivot.rotation - 0.35,
			_pivot.rotation + 0.35, 8, tint, 1.0)
	else:
		tint.a = _remaining / SHOT_DURATION
		for end: Vector2 in _traces:
			# A wall closer than the muzzle must not produce a backwards tracer.
			if (end - _trace_start).dot(_attack_direction) > 0.0:
				draw_line(to_local(_trace_start), to_local(end), tint, 1.0)
		if _remaining > SHOT_DURATION * 0.55:
			draw_circle(to_local(muzzle_global_position()), 2.0, tint)
