extends Node
## Samples actions before the controller's physics tick. Escape releases control.

@export var capture_on_start: bool = true
@onready var _player: SurvivorController = get_parent() as SurvivorController
@onready var _camera: SurvivorCamera = $"../CameraRig"


func _ready() -> void:
	process_physics_priority = -10
	if capture_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(_delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_player.set_movement_input(Vector3.ZERO, false)
		return
	var axis: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	_player.set_movement_input(_camera.movement_direction(axis), Input.is_action_pressed("sprint"))
	if Input.is_action_just_pressed("jump"):
		_player.request_jump()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_cursor"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
