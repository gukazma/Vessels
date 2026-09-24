class_name SurvivorController
extends CharacterBody3D
## World-space locomotion. Input devices and camera behavior live in sibling scripts.

@export_category("Locomotion")
@export_range(0.1, 20.0, 0.1) var walk_speed: float = 4.2
@export_range(0.1, 30.0, 0.1) var sprint_speed: float = 7.2
@export_range(0.1, 100.0, 0.1) var acceleration: float = 24.0
@export_range(0.1, 100.0, 0.1) var braking: float = 32.0
@export_range(0.0, 1.0, 0.01) var air_control: float = 0.3
@export_range(0.1, 20.0, 0.1) var jump_speed: float = 7.5
@export_range(0.1, 30.0, 0.1) var turn_speed: float = 14.0

@onready var visuals: SurvivorVisual = $Visuals

var _movement: Vector3 = Vector3.ZERO
var _sprinting: bool = false
var _jump_requested: bool = false


func set_movement_input(direction: Vector3, sprinting: bool) -> void:
	_movement = Vector3(direction.x, 0.0, direction.z).limit_length(1.0)
	_sprinting = sprinting


func request_jump() -> void:
	_jump_requested = true


func _physics_process(delta: float) -> void:
	var grounded: bool = is_on_floor()
	if not grounded:
		velocity += get_gravity() * delta
	if _jump_requested and grounded:
		velocity.y = jump_speed
	_jump_requested = false

	var target_speed: float = sprint_speed if _sprinting else walk_speed
	var target_velocity: Vector2 = Vector2(_movement.x, _movement.z) * target_speed
	var rate: float = braking if _movement.is_zero_approx() else acceleration
	if not grounded:
		rate *= air_control
	var planar: Vector2 = Vector2(velocity.x, velocity.z).move_toward(
		target_velocity, rate * delta
	)
	velocity.x = planar.x
	velocity.z = planar.y
	move_and_slide()

	if not _movement.is_zero_approx():
		var heading: float = atan2(-_movement.x, -_movement.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, heading, 1.0 - exp(-turn_speed * delta))
	var actual_speed: float = Vector2(get_real_velocity().x, get_real_velocity().z).length()
	visuals.animate_motion(actual_speed, is_on_floor(), delta)
