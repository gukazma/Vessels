class_name SurvivorController
extends CharacterBody2D
## Top-down movement in pixels/second. Input and artwork remain replaceable.

@export_category("Movement")
@export_range(1.0, 400.0, 1.0) var walk_speed: float = 86.0
@export_range(1.0, 600.0, 1.0) var sprint_speed: float = 140.0
@export_range(1.0, 3000.0, 1.0) var acceleration: float = 850.0
@export_range(1.0, 3000.0, 1.0) var braking: float = 1050.0
@export_category("Dash")
@export_range(1.0, 800.0, 1.0) var dash_speed: float = 245.0
@export_range(0.05, 1.0, 0.01) var dash_duration: float = 0.16
@export_range(0.2, 3.0, 0.05) var dash_cooldown: float = 0.75

var facing: Vector2 = Vector2.DOWN
var is_dashing: bool:
	get:
		return _dash_remaining > 0.0
var _direction: Vector2 = Vector2.ZERO
var _sprinting: bool = false
var _dash_requested: bool = false
var _dash_direction: Vector2 = Vector2.DOWN
var _dash_remaining: float = 0.0
var _cooldown_remaining: float = 0.0
@onready var _visuals: SurvivorVisual = $Visuals
@onready var _weapons: WeaponController = $Weapons


func set_movement_input(direction: Vector2, sprinting: bool) -> void:
	_direction = direction.limit_length(1.0)
	_sprinting = sprinting


func request_dash() -> void:
	_dash_requested = true


func dash_readiness() -> float:
	return 1.0 - clampf(_cooldown_remaining / dash_cooldown, 0.0, 1.0)


func stop_motion() -> void:
	_direction = Vector2.ZERO
	velocity = Vector2.ZERO
	_sprinting = false
	_dash_requested = false
	_dash_remaining = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	_dash_remaining = maxf(0.0, _dash_remaining - delta)
	if not _direction.is_zero_approx() and not is_dashing:
		facing = _direction.normalized()
	if _dash_requested and is_zero_approx(_cooldown_remaining):
		_dash_direction = facing
		_dash_remaining = dash_duration
		_cooldown_remaining = dash_cooldown
	_dash_requested = false
	if is_dashing:
		velocity = _dash_direction * dash_speed
	else:
		var speed: float = sprint_speed if _sprinting else walk_speed
		var rate: float = braking if _direction.is_zero_approx() else acceleration
		velocity = velocity.move_toward(_direction * speed, rate * delta)
	move_and_slide()
	var body_direction: Vector2 = _weapons.visual_direction() if _weapons.definition() != null else facing
	_visuals.update_motion(get_real_velocity(), body_direction, is_dashing, delta)
