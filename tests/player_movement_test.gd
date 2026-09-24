extends SceneTree
## Real 2D physics and input integration, without a third-party test framework.

const PLAYER: PackedScene = preload("res://features/player/player.tscn")
var _player: SurvivorController
var _world: Node2D
var _ticks: int = 60
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			_ticks = int(argument.get_slice("=", 1))
	Engine.physics_ticks_per_second = _ticks
	_run.call_deferred()


func _run() -> void:
	_world = Node2D.new()
	root.add_child(_world)
	_player = PLAYER.instantiate() as SurvivorController
	_world.add_child(_player)
	_player.get_node("Input").set_physics_process(false)
	await _seconds(0.05)
	_check(_player.position.is_zero_approx(), "Stationary top-down character has no gravity drift")
	_player.set_movement_input(Vector2.UP, false)
	await _seconds(0.05)
	_check(_speed() > 0.0 and _speed() < _player.walk_speed, "Walking accelerates gradually")
	await _seconds(0.5)
	_check(absf(_speed() - _player.walk_speed) < 0.01, "Walking reaches configured speed")
	var start: Vector2 = _player.position
	await _seconds(1.0)
	_check(absf(_player.position.distance_to(start) - _player.walk_speed) < 2.0,
		"Walking distance is independent of physics tick rate")
	_reset()
	_player.set_movement_input(Vector2(1, -1), false)
	await _seconds(0.5)
	_check(absf(_speed() - _player.walk_speed) < 0.01, "Diagonal movement cannot exceed walk speed")
	_check(absf(absf(_player.velocity.x) - absf(_player.velocity.y)) < 0.01,
		"Diagonal speed is evenly distributed")
	_player.set_movement_input(Vector2.RIGHT, true)
	await _seconds(0.5)
	_check(absf(_speed() - _player.sprint_speed) < 0.01, "Running reaches configured speed")
	_player.set_movement_input(Vector2.ZERO, false)
	await _seconds(0.3)
	_check(_speed() < 0.01, "Releasing movement brakes to rest")
	_check(_player.facing == Vector2.RIGHT, "Idle retains the last facing direction")
	var sprite: Sprite2D = _player.get_node("Visuals/Sprite") as Sprite2D
	_check(sprite.frame == 8, "Idle displays the correct directional sprite")

	_player.request_dash()
	await _seconds(0.05)
	_check(_player.is_dashing and absf(_speed() - _player.dash_speed) < 0.01,
		"Dash starts at configured speed")
	_check(_player.velocity.x > 0.0 and is_zero_approx(_player.velocity.y),
		"Stationary dash uses the retained facing direction")
	await _seconds(0.25)
	_check(not _player.is_dashing and _player.dash_readiness() < 1.0,
		"Dash expires before cooldown finishes")
	_player.request_dash()
	await _seconds(0.05)
	_check(not _player.is_dashing, "Cooldown rejects repeated dash requests")
	await _seconds(0.7)
	_check(is_equal_approx(_player.dash_readiness(), 1.0), "Dash becomes ready after cooldown")

	var wall: StaticBody2D = _box(Vector2(0, -80), Vector2(600, 16))
	_reset()
	_player.set_movement_input(Vector2.UP, true)
	await _seconds(1.0)
	_check(_player.position.y > -64.0, "Running cannot penetrate solid obstacles")
	_player.set_movement_input(Vector2(1, -1), false)
	await _seconds(0.5)
	_check(_player.position.x > 20.0 and _player.position.y > -64.0,
		"Diagonal collision slides along obstacles")
	_player.set_movement_input(Vector2.UP, false)
	await _seconds(0.05)
	_player.request_dash()
	await _seconds(0.15)
	_check(_player.position.y > -64.0, "Dashing respects collision instead of crossing walls")
	wall.queue_free()
	await process_frame

	_reset()
	_player.get_node("Input").set_physics_process(true)
	Input.action_press("move_right")
	Input.action_press("move_forward")
	await _seconds(0.5)
	_check(_player.velocity.x > 0.0 and _player.velocity.y < 0.0,
		"Input Map actions drive the controller through PlayerInput")
	_check(absf(_speed() - _player.walk_speed) < 0.01, "Input sampling also normalizes diagonals")
	Input.action_release("move_right")
	Input.action_release("move_forward")
	await _seconds(0.3)
	_check(_speed() < 0.01, "Releasing mapped keys stops movement")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	await _seconds(0.2)
	_check(_player.velocity.y < -50.0, "Physical W key is mapped to forward")
	key = key.duplicate() as InputEventKey
	key.pressed = false
	Input.parse_input_event(key)
	await _seconds(0.2)
	_player.get_node("Input").set_physics_process(false)
	_world.queue_free()
	await process_frame

	var packed: PackedScene = load("res://levels/quarantine_street.tscn") as PackedScene
	var street: Node2D = packed.instantiate() as Node2D
	street.get_node("MovementHUD").pause_on_focus_loss = false
	root.add_child(street)
	_player = street.get_node("Actors/Player") as SurvivorController
	_player.get_node("Input").set_physics_process(false)
	await _seconds(0.1)
	_check(_player.position.distance_to(Vector2(480, 402)) < 0.1,
		"Actual street scene has a clear, stable spawn")
	_check((street.get_node("Actors") as Node2D).y_sort_enabled,
		"Character and props share Y-sorting for foreground occlusion")
	_reset(Vector2(306, 354))
	_player.set_movement_input(Vector2.UP, true)
	await _seconds(0.5)
	_check(_player.position.y > 332.0, "Clinic artwork has matching solid collision")
	_reset(Vector2(28, 420))
	_player.set_movement_input(Vector2.LEFT, true)
	await _seconds(0.5)
	_check(_player.position.x >= 21.9, "Left map boundary blocks escape")
	_reset(Vector2(850, 610))
	_player.set_movement_input(Vector2.DOWN, true)
	await _seconds(0.5)
	_check(_player.position.y <= 622.1, "Bottom map boundary blocks escape")

	_reset(Vector2(480, 402))
	_player.set_movement_input(Vector2.DOWN, true)
	await _seconds(0.1)
	var hud: CanvasLayer = street.get_node("MovementHUD") as CanvasLayer
	hud.set_paused(true)
	start = _player.position
	await _seconds(0.2)
	_check(paused and _player.position == start and _speed() < 0.01,
		"Pausing freezes physics and clears movement")
	hud.set_paused(false)
	await _seconds(0.1)
	_check(not paused and _player.position == start, "Resuming does not retain stale motion")
	_player.position = Vector2(-100, -100)
	await _seconds(0.1)
	_check(_player.position == Vector2(480, 402), "Invalid position recovers at the level spawn")

	print("RESULT: %d/%d checks passed at %d Hz" % [_checks - _failures, _checks, _ticks])
	street.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _reset(at: Vector2 = Vector2.ZERO) -> void:
	_player.stop_motion()
	_player.position = at


func _seconds(duration: float) -> void:
	for frame: int in range(roundi(duration * _ticks)):
		await physics_frame
	await process_frame


func _speed() -> float:
	return _player.velocity.length()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)


func _box(at: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_world.add_child(body)
	body.position = at
	return body
