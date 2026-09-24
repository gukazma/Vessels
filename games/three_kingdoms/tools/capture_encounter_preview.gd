extends SceneTree
## Render a reproducible encounter: deployment, contact, pause and final report.
## Run without --headless; previews stay in the ignored .godot directory.


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var scene: PackedScene = load("res://levels/encounter.tscn") as PackedScene
	var battle: CommandSandbox = scene.instantiate() as CommandSandbox
	root.add_child(battle)
	# Keep an unrelated desktop mouse position from panning the capture camera.
	battle.camera.set_process(false)
	for frame: int in range(8):
		await process_frame
	await _save("deployment")
	battle.select_in_rect(battle.WORLD_BOUNDS)
	battle.attack_selected(battle.enemies[0])
	battle.attack_selected(battle.enemies[1], true)
	var captured_contact: bool = false
	for frame: int in range(60 * 90):
		await physics_frame
		if not captured_contact and battle.enemies[0].health < battle.enemies[0].max_health:
			captured_contact = true
			await _save("contact")
			battle.toggle_tactical_pause()
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
	var output: String = "res://.godot/encounter-%s.png" % stage
	var error: Error = root.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Cannot save preview: %s" % output)
		quit(error)
	print("Preview saved: ", ProjectSettings.globalize_path(output))
