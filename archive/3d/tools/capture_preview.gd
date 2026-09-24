extends SceneTree
## Use a real renderer: godot --path . --script res://tools/capture_preview.gd


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var scene: PackedScene = load("res://levels/movement_yard.tscn") as PackedScene
	var level: Node = scene.instantiate()
	root.add_child(level)
	for frame: int in range(30):
		await process_frame
	await RenderingServer.frame_post_draw
	var output: String = "res://.godot/movement-preview.png"
	var error: Error = root.get_texture().get_image().save_png(output)
	print("Preview saved: ", ProjectSettings.globalize_path(output))
	quit(error)
