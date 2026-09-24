extends SceneTree
## Integration checks against real CharacterBody3D physics, without test plugins.
## godot --headless --path . --script res://tests/player_movement_test.gd -- --ticks=60

const PLAYER_SCENE: PackedScene = preload("res://features/player/player.tscn")
var _player: SurvivorController
var _world: Node3D
var _failures: int = 0
var _checks: int = 0
var _ticks: int = 60


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			_ticks = int(argument.get_slice("=", 1))
	Engine.physics_ticks_per_second = _ticks
	_run.call_deferred()


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	_add_box(Vector3(0, -0.5, 0), Vector3(200, 1, 200))
	_player = PLAYER_SCENE.instantiate() as SurvivorController
	_player.get_node("Input").capture_on_start = false
	_world.add_child(_player)
	_player.get_node("Input").set_physics_process(false)
	await _reset_player()
	_check(_player.is_on_floor(), "Spawn settles on floor")
	_check(absf(_player.position.y) < 0.03, "Capsule feet align with floor")

	_player.set_movement_input(Vector3.FORWARD, false)
	await _seconds(1.0)
	_check(is_equal_approx(_planar_speed(), _player.walk_speed), "Walk reaches configured speed")
	var start: Vector3 = _player.position
	await _seconds(1.0)
	_check(absf(_player.position.distance_to(start) - _player.walk_speed) < 0.1,
		"One second of walking covers configured distance")

	await _reset_player()
	_player.set_movement_input(Vector3(1, 0, -1), false)
	await _seconds(1.0)
	_check(absf(_planar_speed() - _player.walk_speed) < 0.01, "Diagonal input cannot exceed walk speed")
	_check(absf(absf(_player.velocity.x) - absf(_player.velocity.z)) < 0.01,
		"Diagonal motion distributes speed evenly")
	_player.set_movement_input(Vector3.FORWARD, true)
	await _seconds(1.0)
	_check(absf(_planar_speed() - _player.sprint_speed) < 0.01, "Sprint reaches configured speed")
	_player.set_movement_input(Vector3.ZERO, false)
	await _seconds(0.5)
	_check(_planar_speed() < 0.01, "Release brakes to a full stop")

	await _reset_player()
	_player.request_jump()
	await _seconds(0.1)
	_check(not _player.is_on_floor() and _player.position.y > 0.3, "Jump leaves floor")
	var rising_speed: float = _player.velocity.y
	_player.request_jump()
	await _seconds(0.05)
	_check(_player.velocity.y < rising_speed, "Jump request in air does not double jump")
	await _seconds(1.0)
	_check(_player.is_on_floor(), "Gravity returns player to floor")
	await _seconds(0.2)
	_check(_player.is_on_floor(), "Rejected airborne jump is not queued for landing")

	var wall: StaticBody3D = _add_box(Vector3(0, 1.5, -3), Vector3(8, 3, 0.5))
	await _reset_player()
	_player.set_movement_input(Vector3.FORWARD, true)
	await _seconds(1.0)
	_check(_player.position.z > -2.5, "Sprinting cannot pass through a wall")
	_player.set_movement_input(Vector3(1, 0, -1), false)
	await _seconds(0.4)
	_check(_player.position.x > 0.6 and _player.position.z > -2.5, "Diagonal contact slides along wall")
	wall.queue_free()
	await process_frame

	var ramp: StaticBody3D = _add_box(Vector3(0, 0.55, -2.5), Vector3(4, 0.3, 5))
	ramp.rotation.x = deg_to_rad(18.0)
	await _reset_player(Vector3(0, 0.05, 1))
	_player.set_movement_input(Vector3.FORWARD, false)
	await _seconds(1.0)
	_check(_player.position.y > 0.7 and _player.is_on_floor(), "Walk climbs an 18-degree incline")
	_player.set_movement_input(Vector3.BACK, false)
	await _seconds(0.6)
	_check(_player.is_on_floor(), "Floor snapping maintains contact descending an incline")
	ramp.queue_free()
	await process_frame

	await _reset_player()
	var camera: SurvivorCamera = _player.get_node("CameraRig") as SurvivorCamera
	camera.rotation.y = PI / 2.0
	var forward: Vector3 = camera.movement_direction(Vector2(0, -1))
	_check(forward.distance_to(Vector3.LEFT) < 0.001, "Camera yaw rotates movement direction")
	camera.orbit(Vector2(0, 100000))
	var arm: SpringArm3D = camera.get_node("SpringArm3D") as SpringArm3D
	_check(is_equal_approx(arm.rotation.x, deg_to_rad(camera.minimum_pitch_degrees)), "Camera pitch is clamped")
	_check(is_equal_approx(camera.movement_direction(Vector2(0, -1)).length(), 1.0),
		"Looking up or down does not change movement speed")
	camera.rotation.y = 0
	arm.rotation.x = 0
	var camera_wall: StaticBody3D = _add_box(Vector3(0, 1.5, 2), Vector3(6, 3, 0.4))
	await _seconds(0.2)
	_check(arm.get_hit_length() < 2.0, "Spring arm retracts before camera clips through wall")
	camera_wall.queue_free()
	await process_frame
	await _seconds(0.2)
	_check(arm.get_hit_length() > 4.5, "Spring arm restores distance when obstruction is gone")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_player.set_movement_input(Vector3.FORWARD, true)
	_player.get_node("Input").set_physics_process(true)
	await _seconds(0.4)
	_check(_planar_speed() < 0.01, "Released cursor suppresses movement input")
	_player.get_node("Input").set_physics_process(false)
	_world.queue_free()
	await process_frame

	var yard_scene: PackedScene = load("res://levels/movement_yard.tscn") as PackedScene
	var yard: Node3D = yard_scene.instantiate() as Node3D
	yard.get_node("Player/Input").capture_on_start = false
	root.add_child(yard)
	_player = yard.get_node("Player") as SurvivorController
	_player.get_node("Input").set_physics_process(false)
	await _seconds(0.4)
	_check(_player.is_on_floor(), "Actual demo scene spawns on solid ground")
	await _reset_player(Vector3(-6, 0.05, 3.6))
	_player.set_movement_input(Vector3.FORWARD, false)
	await _seconds(1.1)
	_check(_player.position.y > 0.5 and _player.is_on_floor(), "Actual demo ramp is traversable")
	_player.set_movement_input(Vector3.ZERO, false)
	_player.position = Vector3(0, -20, 0)
	await _seconds(0.5)
	_check(_player.is_on_floor() and _player.position.distance_to(Vector3(0, 0, 7)) < 0.1,
		"Falling out of the demo restores the spawn position")
	print("RESULT: %d/%d checks passed at %d Hz" % [_checks - _failures, _checks, _ticks])
	yard.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


func _reset_player(at: Vector3 = Vector3(0, 0.05, 0)) -> void:
	_player.set_movement_input(Vector3.ZERO, false)
	_player.velocity = Vector3.ZERO
	_player.position = at
	await _seconds(0.3)


func _seconds(duration: float) -> void:
	for frame: int in range(roundi(duration * _ticks)):
		await physics_frame
	await process_frame


func _planar_speed() -> float:
	return Vector2(_player.velocity.x, _player.velocity.z).length()


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)


func _add_box(at: Vector3, size: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_world.add_child(body)
	body.position = at
	return body
