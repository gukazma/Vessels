extends SceneTree
## Route real Q/F1/F2 input through the playable scenes, including scene changes
## while paused. Combat tests separately exercise damage and wall geometry.

const BASIC_ENCOUNTER: PackedScene = preload("res://levels/encounter.tscn")
const ALLIED_STARTS: Array[Vector2] = [Vector2(570, 510), Vector2(520, 630)]
const ENEMY_STARTS: Array[Vector2] = [Vector2(952, 485), Vector2(952, 600)]

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
	_battle = BASIC_ENCOUNTER.instantiate() as CommandSandbox
	root.add_child(_battle)
	current_scene = _battle
	_disable_camera_input()
	await _seconds(0.1)
	_check(not _battle.cover_enabled and not _battle.combat.directional_defense_enabled,
		"The F1 scenario retains the original nondirectional combat rules")
	await _switch(KEY_F2)
	_check(_battle != null and _battle.cover_enabled and _battle.combat.directional_defense_enabled,
		"F2 loads the playable cover encounter through the real input controller")
	if _battle == null or not _battle.cover_enabled:
		_finish()
		return
	await _check_cover_setup()
	await _check_face_input()
	await _check_restart_and_switch()
	_finish()


func _check_cover_setup() -> void:
	_check(_battle.covers.size() == 2 and _at_starts(), "The cover encounter spawns two barricades and both armies at their authored positions")
	_check(_initial_facings(), "Attackers face right and the defending formation faces left")
	_check(not _battle.navigation.is_walkable(Vector2(900, 550))
		and _battle.combat.has_line_of_sight(Vector2(850, 550), Vector2(952, 550)),
		"The low wall blocks movement while retaining ranged visibility")
	_check(_battle.combat.cover_at(_battle.enemies[0]) != null
		and _battle.combat.cover_at(_battle.enemies[1]) != null,
		"Both defending squads begin inside the wall's protected band")
	await _seconds(1.0)
	_check(_at_starts(), "The cover defenders hold their posts instead of chasing out of cover on load")


func _check_face_input() -> void:
	_key(KEY_SPACE)
	_key(KEY_1)
	_right_click_world(_battle.enemies[0].position)
	var squad: TacticalSquad = _battle.squads[0]
	_check(_battle.combat.queue_size(squad) == 1, "An attack can be prepared before issuing a Q facing order")
	_mouse_world(squad.position + Vector2.UP * 160.0)
	_key(KEY_Q)
	_check(_battle.combat.queue_size(squad) == 0 and not squad.is_moving(),
		"Q replaces the selected squad's queued attack with stationary directional guard")
	await _seconds(0.3)
	_check(squad.facing_direction().is_equal_approx(Vector2.RIGHT),
		"Q changes the planned facing without rotating troops during tactical pause")
	_key(KEY_SPACE)
	await _seconds(0.2)
	var turned: float = absf(Vector2.RIGHT.angle_to(squad.facing_direction()))
	_check(turned > 0.45 and turned < 0.8,
		"Resuming turns the actual squad gradually toward the mouse's world position")
	await _seconds(0.4)
	_check(squad.facing_direction().dot(Vector2.UP) > 0.999,
		"The selected squad settles on the mouse-directed guard bearing")
	_mouse_screen(Vector2(40, 40))
	_key(KEY_Q)
	await _seconds(0.25)
	_check(squad.facing_direction().dot(Vector2.UP) > 0.999,
		"Q over the HUD does not turn troops toward a hidden point underneath the panel")


func _check_restart_and_switch() -> void:
	_key(KEY_SPACE)
	_key(KEY_R)
	_check(not paused and _at_starts() and _initial_facings(),
		"R restores cover positions and initial facing while clearing tactical pause")
	var clear_orders: bool = true
	for squad: TacticalSquad in _battle.squads + _battle.enemies:
		clear_orders = clear_orders and _battle.combat.queue_size(squad) == 0
	_check(clear_orders and not _battle.battle_finished, "Restart clears every cover encounter order and result")
	_key(KEY_SPACE)
	await _switch(KEY_F1)
	_check(_battle != null and not paused and not _battle.cover_enabled
		and not _battle.combat.directional_defense_enabled,
		"F1 switches out of a paused cover encounter without leaving the scene tree paused")
	_key(KEY_SPACE)
	await _switch(KEY_F2)
	_check(_battle != null and not paused and _battle.cover_enabled and _at_starts() and _initial_facings(),
		"F2 returns to a fresh cover encounter from a paused basic encounter")


func _switch(code: Key) -> void:
	_key(code)
	await process_frame
	await process_frame
	_battle = current_scene as CommandSandbox
	if _battle != null:
		_disable_camera_input()
		await _seconds(0.05)


func _disable_camera_input() -> void:
	var camera: Camera2D = _battle.get_node("Camera") as Camera2D
	camera.set_process(false)
	camera.set_physics_process(false)
	camera.set_process_input(false)
	camera.set_process_unhandled_input(false)


func _key(code: Key) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.physical_keycode = code
	press.keycode = code
	press.pressed = true
	root.push_input(press, true)
	var release: InputEventKey = InputEventKey.new()
	release.physical_keycode = code
	release.keycode = code
	root.push_input(release, true)


func _mouse_world(at: Vector2) -> void:
	var screen: Vector2 = _battle.get_canvas_transform() * at
	_check(root.get_visible_rect().has_point(screen) and not _battle.hud_blocks_screen(screen),
		"The Q target is visible and outside the HUD")
	_mouse_screen(screen)


func _mouse_screen(at: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	root.push_input(motion, true)


func _right_click_world(at: Vector2) -> void:
	var screen: Vector2 = _battle.get_canvas_transform() * at
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.button_mask = MOUSE_BUTTON_MASK_RIGHT
	press.position = screen
	press.global_position = screen
	press.pressed = true
	root.push_input(press, true)
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.position = screen
	release.global_position = screen
	root.push_input(release, true)


func _at_starts() -> bool:
	for index: int in _battle.squads.size():
		if _battle.squads[index].position.distance_to(ALLIED_STARTS[index]) > 0.1:
			return false
	for index: int in _battle.enemies.size():
		if _battle.enemies[index].position.distance_to(ENEMY_STARTS[index]) > 0.1:
			return false
	return true


func _initial_facings() -> bool:
	for squad: TacticalSquad in _battle.squads:
		if squad.facing_direction().dot(Vector2.RIGHT) < 0.999:
			return false
	for squad: TacticalSquad in _battle.enemies:
		if squad.facing_direction().dot(Vector2.LEFT) < 0.999:
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


func _finish() -> void:
	print("RESULT: %d/%d cover input checks passed at %d Hz" % [_checks - _failures, _checks, _ticks])
	quit(1 if _failures else 0)
