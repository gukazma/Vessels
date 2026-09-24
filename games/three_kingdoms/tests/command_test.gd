extends SceneTree
## Integration checks for the first command sandbox slice.
## The test drives the real scene and waits on physics frames; no UI text or
## simulated squad state is used, so it can run headlessly at 60 or 120 Hz.

const SANDBOX: PackedScene = preload("res://levels/command_sandbox.tscn")
const EXPECTED_STARTS: Array[Vector2] = [
	Vector2(460, 490), Vector2(460, 670), Vector2(650, 560),
]
const EXPECTED_BOUNDS: Rect2 = Rect2(0, 0, 1800, 1200)
const EXPECTED_OBSTACLES: Array[Rect2] = [
	Rect2(820, 400, 128, 320), Rect2(450, 220, 224, 64),
	Rect2(1150, 750, 256, 64),
]
const MEMBER_CLEARANCE: float = 24.0

var _ticks: int = 60
var _checks: int = 0
var _failures: int = 0
var _sandbox: CommandSandbox
var _camera: Camera2D


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			_ticks = maxi(1, int(argument.get_slice("=", 1)))
	Engine.physics_ticks_per_second = _ticks
	_run.call_deferred()


func _run() -> void:
	_sandbox = SANDBOX.instantiate() as CommandSandbox
	root.add_child(_sandbox)
	_camera = _sandbox.get_node("Camera") as Camera2D
	_disable_automatic_devices()
	await _seconds(0.1)

	_check(_sandbox.squads.size() == 3, "Sandbox creates three playable squads")
	_check(_member_count() == 21, "Three squads expose a leader and six soldiers each")
	_check(_squads_at_starts(), "Squads use the stable scenario spawn positions")

	_check_selection_commands()
	_check_move_without_selection()
	await _check_progress_rate_independence()
	await _check_stop_and_reissue()
	await _check_group_order_and_safety()
	await _check_invalid_order_keeps_previous_destination()
	await _check_reset_and_camera()

	print("RESULT: %d/%d command checks passed at %d Hz" % [
		_checks - _failures, _checks, _ticks])
	_sandbox.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _disable_automatic_devices() -> void:
	var orders: Node = _sandbox.get_node("Orders")
	orders.set_process(false)
	orders.set_physics_process(false)
	orders.set_process_input(false)
	orders.set_process_unhandled_input(false)
	_camera.set_process(false)
	_camera.set_process_input(false)
	_camera.set_process_unhandled_input(false)


func _check_selection_commands() -> void:
	_sandbox.clear_selection()
	_check(_sandbox.selected_squads().is_empty(), "Clear selection removes every selected squad")
	_sandbox.select_at(EXPECTED_STARTS[0])
	_check(_selected_indices() == [0], "Click selects the nearest squad")
	_sandbox.select_at(EXPECTED_STARTS[1], true)
	_check(_selected_indices() == [0, 1], "Shift-click adds a second squad")
	_sandbox.select_at(EXPECTED_STARTS[1], true)
	_check(_selected_indices() == [0], "Shift-clicking a selected squad toggles it off")
	_sandbox.select_in_rect(Rect2(420, 450, 280, 250))
	_check(_selected_indices() == [0, 1, 2], "A box selects all squads inside its rectangle")
	_sandbox.clear_selection()
	_sandbox.select_at(EXPECTED_STARTS[0])
	_sandbox.select_in_rect(Rect2(420, 450, 280, 250), true)
	_check(_selected_indices() == [0, 1, 2], "Shift-box adds squads without clearing the current selection")


func _check_move_without_selection() -> void:
	_sandbox.clear_selection()
	_check(not _sandbox.move_selected(Vector2(1230, 500)),
		"Move command fails cleanly when no squad is selected")
	_sandbox.select_at(EXPECTED_STARTS[0])
	_check(_sandbox.move_selected(Vector2(700, 500)), "Selected squad accepts a reachable move order")


func _check_progress_rate_independence() -> void:
	_sandbox.reset_squads()
	await _seconds(0.05)
	_sandbox.select_at(EXPECTED_STARTS[0])
	var squad: TacticalSquad = _sandbox.squads[0]
	var start: Vector2 = squad.position
	var target: Vector2 = Vector2(700, 490)
	_check(_sandbox.move_selected(target), "Open-ground move order is accepted")
	await _seconds(0.75)
	var distance: float = squad.position.distance_to(start)
	# 105 px/s for 0.75 s, with a small allowance for the first frame and arrival.
	_check(distance > 70.0 and distance < 86.0,
		"Movement distance remains stable across the selected physics tick rate")


func _check_stop_and_reissue() -> void:
	_sandbox.reset_squads()
	await _seconds(0.05)
	_sandbox.select_at(EXPECTED_STARTS[0])
	var squad: TacticalSquad = _sandbox.squads[0]
	_check(_sandbox.move_selected(Vector2(1000, 490)), "Long move order starts the squad")
	await _seconds(0.22)
	_sandbox.stop_selected()
	var stopped_at: Vector2 = squad.position
	_check(not squad.is_moving(), "Stop command clears the active path immediately")
	await _seconds(0.35)
	_check(squad.position.distance_to(stopped_at) < 0.1, "Stopped squad does not drift on later frames")
	_check(_sandbox.move_selected(Vector2(700, 490)), "A stopped squad accepts a replacement order")
	_check(squad.is_moving(), "Replacement order resumes movement")


func _check_group_order_and_safety() -> void:
	_sandbox.reset_squads()
	await _seconds(0.05)
	_sandbox.select_in_rect(Rect2(400, 430, 300, 280))
	_check(_sandbox.selected_squads().size() == 3, "Box selection can command all three squads")
	var group_target: Vector2 = Vector2(1230, 500)
	_check(_sandbox.move_selected(group_target), "Group order finds paths around the central obstacle")
	await _seconds(15.0)
	for squad: TacticalSquad in _sandbox.squads:
		_check(not squad.is_moving(), "%s reaches its assigned group destination" % squad.squad_name)
		_check(squad.position.distance_to(squad.destination()) < 1.0,
			"%s stops at its own spaced destination" % squad.squad_name)
		_check(_safe_point(squad.position), "%s center stays in the walkable bounds" % squad.squad_name)
		for member_position: Vector2 in squad.get_member_positions():
			_check(_safe_point(member_position), "%s members keep obstacle and edge clearance" % squad.squad_name)
	# Distinct destinations are a useful guard against all selected squads stacking.
	_check(_destination_separation() > 70.0, "Group orders assign spaced destinations")


func _check_invalid_order_keeps_previous_destination() -> void:
	_sandbox.reset_squads()
	await _seconds(0.05)
	_sandbox.select_at(EXPECTED_STARTS[2])
	var squad: TacticalSquad = _sandbox.squads[2]
	var old_destination: Vector2 = Vector2(700, 560)
	_check(_sandbox.move_selected(old_destination), "Squad accepts a valid order before invalid input")
	var position_before_invalid: Vector2 = squad.position
	_check(not _sandbox.move_selected(Vector2(-80, -80)), "Out-of-bounds order is rejected")
	_check(squad.destination().distance_to(old_destination) < 0.1,
		"Rejected order preserves the previous destination")
	await _seconds(0.2)
	_check(squad.position.distance_to(position_before_invalid) > 0.1,
		"Preserved order continues moving after rejected input")


func _check_reset_and_camera() -> void:
	_sandbox.reset_squads()
	await _seconds(0.1)
	_check(_squads_at_starts(), "Reset restores every squad to its scenario start")
	_check(_selected_indices() == [0], "Reset restores the default first-squad selection")
	_check(_camera.zoom.is_equal_approx(Vector2.ONE * 0.85), "Reset restores the tactical camera zoom")
	_sandbox.clear_selection()
	_sandbox.focus_selected()
	_check(_camera.position.x >= 0.0 and _camera.position.x <= EXPECTED_BOUNDS.size.x
		and _camera.position.y >= 0.0 and _camera.position.y <= EXPECTED_BOUNDS.size.y,
		"Camera focus remains inside the world bounds")


func _safe_point(point: Vector2) -> bool:
	if not EXPECTED_BOUNDS.grow(-MEMBER_CLEARANCE).has_point(point):
		return false
	for obstacle: Rect2 in EXPECTED_OBSTACLES:
		if obstacle.grow(MEMBER_CLEARANCE).has_point(point):
			return false
	return true


func _squads_at_starts() -> bool:
	if _sandbox.squads.size() != EXPECTED_STARTS.size():
		return false
	for index: int in EXPECTED_STARTS.size():
		if _sandbox.squads[index].position.distance_to(EXPECTED_STARTS[index]) > 0.1:
			return false
	return true


func _selected_indices() -> Array[int]:
	var indices: Array[int] = []
	for index: int in _sandbox.squads.size():
		if _sandbox.squads[index].is_selected():
			indices.append(index)
	return indices


func _member_count() -> int:
	var count: int = 0
	for squad: TacticalSquad in _sandbox.squads:
		count += squad.get_member_positions().size()
	return count


func _destination_separation() -> float:
	var minimum: float = INF
	for first: int in _sandbox.squads.size():
		for second: int in range(first + 1, _sandbox.squads.size()):
			minimum = minf(minimum, _sandbox.squads[first].destination().distance_to(
				_sandbox.squads[second].destination()))
	return minimum


func _seconds(duration: float) -> void:
	for frame: int in range(maxi(1, roundi(duration * _ticks))):
		await physics_frame
	await process_frame


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
