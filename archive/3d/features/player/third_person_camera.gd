class_name SurvivorCamera
extends Node3D
## Yaw-only movement basis; pitch affects the camera, never movement speed.

@export_range(0.0001, 0.02, 0.0001) var mouse_sensitivity: float = 0.0025
@export_range(-85.0, 0.0, 1.0) var minimum_pitch_degrees: float = -65.0
@export_range(0.0, 80.0, 1.0) var maximum_pitch_degrees: float = 35.0
@onready var _arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	_arm.add_excluded_object((get_parent() as CollisionObject3D).get_rid())


func movement_direction(axis: Vector2) -> Vector3:
	return global_basis * Vector3(axis.x, 0.0, axis.y)


func orbit(relative_motion: Vector2) -> void:
	rotation.y = wrapf(rotation.y - relative_motion.x * mouse_sensitivity, -PI, PI)
	_arm.rotation.x = clampf(
		_arm.rotation.x - relative_motion.y * mouse_sensitivity,
		deg_to_rad(minimum_pitch_degrees),
		deg_to_rad(maximum_pitch_degrees)
	)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		orbit(event.screen_relative)
