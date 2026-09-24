class_name SurvivorVisual
extends Node2D
## Four rows: down, left, right, up. Frame 0 doubles as the idle pose.

const STRIDE_PIXELS: float = 9.0
const WALK_TEXTURE: Texture2D = preload("res://assets/pixel/survivor.png")
const AIMING_TEXTURE: Texture2D = preload("res://assets/pixel/survivor_aiming.png")
@onready var _sprite: Sprite2D = $Sprite
@onready var _weapon_pose: WeaponVisual = $Sprite/WeaponPose
var _travel: float = 0.0


func update_motion(motion: Vector2, facing: Vector2, dashing: bool, delta: float) -> void:
	var row: int = 0
	if absf(facing.x) > absf(facing.y):
		row = 1 if facing.x < 0.0 else 2
	elif facing.y < 0.0:
		row = 3
	var frame_index: int = 0
	if motion.length() > 2.0:
		_travel = fmod(_travel + motion.length() * delta, STRIDE_PIXELS * 4.0)
		frame_index = int(_travel / STRIDE_PIXELS)
	else:
		_travel = 0.0
	var aiming: bool = _weapon_pose.is_firearm_equipped()
	_sprite.texture = AIMING_TEXTURE if aiming else WALK_TEXTURE
	_sprite.frame = row * 4 + frame_index
	_sprite.modulate = Color(1.18, 1.13, 0.88) if dashing else Color.WHITE
	var hand: Vector2 = _aiming_socket(row, frame_index) if aiming else _hand_socket(row, frame_index)
	_weapon_pose.set_hand_socket(hand)


func _aiming_socket(row: int, frame_index: int) -> Vector2:
	# Bent arms stay raised while the legs walk; only the torso's one-pixel bob moves the grip.
	var sockets: Array[Vector2] = [Vector2(1, -13), Vector2(-10, -15),
		Vector2(9, -15), Vector2(1, -22)]
	var bob: float = 1.0 if frame_index in [1, 3] else 0.0
	return sockets[row] + Vector2(0, bob)


func _hand_socket(row: int, frame_index: int) -> Vector2:
	# Match the glove in survivor_art.py, including torso bob and arm swing.
	var bob: float = 1.0 if frame_index in [1, 3] else 0.0
	var swing: float = [0.0, 1.0, 0.0, -1.0][frame_index]
	match row:
		1:
			return Vector2(-3.0 - [0.0, -2.0, 0.0, 1.0][frame_index], -10.0 + bob)
		2:
			return Vector2(2.0 + [0.0, -2.0, 0.0, 1.0][frame_index], -10.0 + bob)
		3:
			return Vector2(8.0, -11.0 - swing + bob)
	return Vector2(-8.0, -11.0 + swing + bob)
