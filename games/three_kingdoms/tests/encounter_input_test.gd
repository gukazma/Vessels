extends SceneTree
## Exercise the actual viewport -> GUI -> input controller -> encounter route.
## The complete battle starts from the normal scenario and receives only input;
## no test calls attack/move/reset methods or applies artificial combat damage.

const ENCOUNTER: PackedScene = preload("res://levels/encounter.tscn")
const ALLIED_STARTS: Array[Vector2] = [Vector2(560, 490), Vector2(460, 570)]
const ENEMY_STARTS: Array[Vector2] = [Vector2(1190, 490), Vector2(1290, 570)]

var _ticks: int = 60
var _checks: int = 0
var _failures: int = 0
var _battle: CommandSandbox


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			_ticks = maxi(1, int(argument.get_slice("=", 1)))
	Engine.physics_ticks_per_second = _ticks
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 800)
	_battle = ENCOUNTER.instantiate() as CommandSandbox
	root.add_child(_battle)
	# Keep deterministic screen coordinates while retaining the real HUD and Orders.
	var camera: Camera2D = _battle.get_node("Camera") as Camera2D
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.set_process_input(false)
	camera.set_process_unhandled_input(false)
	await _seconds(0.1)
	await _check_input_and_pause()
	await _check_overlapping_shortcuts()
	await _check_complete_battle()
	print("RESULT: %d/%d encounter input checks passed at %d Hz" % [
		_checks - _failures, _checks, _ticks])
	_battle.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check_input_and_pause() -> void:
	_key(KEY_SPACE)
	_check(_battle.is_tactical_paused(), "Space reaches the input controller and pauses the encounter")
	_key(KEY_2)
	_check(_battle.selected_squads() == [_battle.squads[1]], "The 2 key selects the archer squad while paused")
	_key(KEY_1)
	_check(_battle.selected_squads() == [_battle.squads[0]], "The 1 key selects the shield squad while paused")
	var shield: TacticalSquad = _battle.squads[0]
	_click_world(_battle.enemies[0].position)
	_check(_battle.combat.queue_size(shield) == 1 and shield.is_moving(),
		"Right-clicking an enemy through the viewport starts an attack approach")
	_click_world(_battle.enemies[1].position, true)
	_check(_battle.combat.queue_size(shield) == 2, "Shift-right-click appends the second enemy target")
	var paused_at: Vector2 = shield.position
	await _seconds(0.3)
	_check(shield.position.is_equal_approx(paused_at) and _armies_are_healthy(),
		"Orders prepared through input do not advance while tactical pause is active")
	_key(KEY_X)
	_check(_battle.combat.queue_size(shield) == 0 and not shield.is_moving(),
		"X reaches the input controller and clears the pending attack queue")
	var destination: Vector2 = Vector2(680, 680)
	_click_world(destination)
	_check(shield.destination().distance_to(destination) < 0.1,
		"Right-clicking open ground converts screen coordinates to the correct destination")
	_click_world(Vector2(680, 760), true)
	_check(_battle.combat.queue_size(shield) == 2, "Shift-right-click also queues movement waypoints")
	_right_click(Vector2(40, 40))
	_check(_battle.combat.queue_size(shield) == 2 and shield.destination().distance_to(destination) < 0.1,
		"The visible HUD consumes right-clicks instead of issuing hidden ground orders")
	_key(KEY_SPACE)
	await _seconds(0.3)
	_check(not _battle.is_tactical_paused() and shield.position.distance_to(paused_at) > 5.0,
		"A second Space press resumes movement from the prepared queue")
	_key(KEY_SPACE)
	_key(KEY_R)
	_check(not paused and not _battle.battle_finished and _armies_are_at_starts() and _armies_are_healthy(),
		"R restarts the encounter from tactical pause through the normal input route")
	_check(_queues_are_empty() and _battle.selected_squads() == [_battle.squads[0]],
		"Keyboard restart clears orders and restores the default selection")


func _check_overlapping_shortcuts() -> void:
	_key(KEY_SPACE)
	# This isolated input check deliberately overlaps the two selectable centers.
	# R then restores real starting positions before the complete battle below.
	_battle.squads[1].position = _battle.squads[0].position
	_key(KEY_2)
	_check(_battle.selected_squads() == [_battle.squads[1]],
		"The 2 shortcut selects its exact squad even when both squad centers overlap")
	_key(KEY_1)
	_check(_battle.selected_squads() == [_battle.squads[0]],
		"The 1 shortcut selects its exact squad when centers overlap")
	_key(KEY_R)
	_check(_armies_are_at_starts() and not paused, "Keyboard restart restores positions after the overlap fixture")


func _check_complete_battle() -> void:
	_key(KEY_SPACE)
	_key(KEY_TAB)
	_check(_battle.selected_squads().size() == 2, "Tab selects both friendly squads through the configured input map")
	_click_world(_battle.enemies[0].position)
	_click_world(_battle.enemies[1].position, true)
	_check(_battle.combat.queue_size(_battle.squads[0]) == 2
		and _battle.combat.queue_size(_battle.squads[1]) == 2,
		"Group input assigns both armies' enemy targets to each friendly squad")
	_key(KEY_SPACE)
	var observed_damage: bool = false
	var elapsed_frames: int = 0
	for frame: int in range(_ticks * 90):
		await physics_frame
		elapsed_frames = frame + 1
		observed_damage = observed_damage or not _armies_are_healthy()
		if _battle.battle_finished:
			break
	await process_frame
	_check(observed_damage, "The normal encounter produces real combat damage without test health changes")
	_check(_battle.battle_finished and _battle.winner in [0, 1],
		"The initial two-versus-two battle reaches a victory or defeat within 90 simulated seconds")
	if _battle.battle_finished:
		print("Battle input simulation completed in %.2f s; winner=%d" % [float(elapsed_frames) / float(_ticks), _battle.winner])
	_check(paused and _queues_are_empty(), "The battle result pauses simulation and clears remaining orders")
	_key(KEY_R)
	_check(not paused and not _battle.battle_finished and _armies_are_healthy()
		and _armies_are_at_starts() and _queues_are_empty(),
		"R restarts a naturally completed battle and restores both armies")


func _key(code: Key) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = code
	press.keycode = code
	press.pressed = true
	root.push_input(press, true)
	var release: InputEventKey = InputEventKey.new()
	release.physical_keycode = code
	release.keycode = code
	release.pressed = false
	root.push_input(release, true)


func _click_world(at: Vector2, append: bool = false) -> void:
	var screen: Vector2 = _battle.get_canvas_transform() * at
	_check(root.get_visible_rect().has_point(screen) and not _battle.hud_blocks_screen(screen),
		"World click lies inside the viewport and outside the HUD")
	_right_click(screen, append)


func _right_click(screen: Vector2, append: bool = false) -> void:
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.button_mask = MOUSE_BUTTON_MASK_RIGHT
	press.position = screen
	press.global_position = screen
	press.shift_pressed = append
	press.pressed = true
	root.push_input(press, true)
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.position = screen
	release.global_position = screen
	release.shift_pressed = append
	release.pressed = false
	root.push_input(release, true)


func _armies_are_healthy() -> bool:
	for squad: TacticalSquad in _battle.squads + _battle.enemies:
		if not is_equal_approx(squad.health, squad.max_health):
			return false
	return true


func _armies_are_at_starts() -> bool:
	for index: int in _battle.squads.size():
		if _battle.squads[index].position.distance_to(ALLIED_STARTS[index]) > 0.1:
			return false
	for index: int in _battle.enemies.size():
		if _battle.enemies[index].position.distance_to(ENEMY_STARTS[index]) > 0.1:
			return false
	return true


func _queues_are_empty() -> bool:
	for squad: TacticalSquad in _battle.squads + _battle.enemies:
		if _battle.combat.queue_size(squad) != 0:
			return false
	return true


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
