extends SceneTree
## Render a reproducible encounter: deployment, contact, pause and final report.
## Run without --headless; previews stay in the ignored .godot directory.


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var use_cover: bool = "--cover" in OS.get_cmdline_user_args()
	var use_flank: bool = use_cover and "--flank" in OS.get_cmdline_user_args()
	var scene: PackedScene = load("res://levels/cover_encounter.tscn" if use_cover else "res://levels/encounter.tscn") as PackedScene
	var battle: CommandSandbox = scene.instantiate() as CommandSandbox
	root.add_child(battle)
	# Keep an unrelated desktop mouse position from panning the capture camera.
	battle.camera.set_process(false)
	for frame: int in range(8):
		await process_frame
	if use_cover:
		battle.select_index(1)
		battle.pointer_screen = battle.get_canvas_transform() * battle.enemies[0].position
	await _save("deployment")
	if use_flank:
		battle.select_index(0)
		battle.move_selected(Vector2(840, 600))
		battle.select_index(1)
		battle.move_selected(Vector2(780, 350))
		battle.move_selected(Vector2(1030, 350), true)
		battle.move_selected(Vector2(1100, 470), true)
		battle.attack_selected(battle.enemies[1], true)
		battle.attack_selected(battle.enemies[0], true)
	else:
		battle.select_in_rect(battle.WORLD_BOUNDS)
		battle.attack_selected(battle.enemies[0])
		battle.attack_selected(battle.enemies[1], true)
	var captured_contact: bool = false
	for frame: int in range(60 * 90):
		await physics_frame
		if use_flank and frame == 60 * 8:
			battle.select_index(0)
			battle.attack_selected(battle.enemies[1])
			battle.attack_selected(battle.enemies[0], true)
			battle.select_index(1)
		var target: TacticalSquad = battle.enemies[1 if use_flank else 0]
		if not captured_contact and target.health < target.max_health:
			captured_contact = true
			await _save("contact")
			battle.toggle_tactical_pause()
			if use_cover:
				battle.pointer_screen = battle.get_canvas_transform() * target.position
			await _save("paused")
			battle.toggle_tactical_pause()
		if battle.battle_finished:
			await _save("result")
			print("Encounter completed: winner=", battle.winner, " ", battle.battle_report())
			quit(0)
			return
	push_error("Encounter did not finish within 90 simulated seconds.")
	quit(1)


func _save(stage: String) -> void:
	# Allow status labels and camera transforms to settle before reading pixels.
	for frame: int in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	var prefix: String = "cover" if "--cover" in OS.get_cmdline_user_args() else "encounter"
	if prefix == "cover" and "--flank" in OS.get_cmdline_user_args():
		prefix += "-flank"
	var output: String = "res://.godot/%s-%s.png" % [prefix, stage]
	var error: Error = root.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Cannot save preview: %s" % output)
		quit(error)
	print("Preview saved: ", ProjectSettings.globalize_path(output))
