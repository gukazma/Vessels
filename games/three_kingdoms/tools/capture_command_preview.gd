extends SceneTree
## Real-renderer preview for the M0 command sandbox.


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var scene: PackedScene = load("res://levels/command_sandbox.tscn") as PackedScene
	var sandbox: CommandSandbox = scene.instantiate() as CommandSandbox
	root.add_child(sandbox)
	for frame: int in range(8):
		await process_frame
	# Demonstrate the path command in the saved preview without depending on OS input.
	sandbox.select_in_rect(Rect2(400, 430, 300, 280))
	sandbox.move_selected(Vector2(1230, 500))
	for frame: int in range(24):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var output: String = "res://.godot/three-kingdoms-m0.png"
	var error: Error = image.save_png(output)
	print("Preview saved: ", ProjectSettings.globalize_path(output))
	quit(error)
