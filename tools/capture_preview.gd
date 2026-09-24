extends SceneTree
## Use a real renderer: godot --path . --script res://tools/capture_preview.gd


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var scene: PackedScene = load("res://levels/quarantine_street.tscn") as PackedScene
	var level: Node = scene.instantiate()
	level.get_node("MovementHUD").pause_on_focus_loss = false
	root.add_child(level)
	for frame: int in range(30):
		await process_frame
	var inventory_preview: bool = "--inventory" in OS.get_cmdline_user_args()
	var paused_preview: bool = "--paused" in OS.get_cmdline_user_args()
	var aiming_preview: bool = "--aiming" in OS.get_cmdline_user_args()
	if inventory_preview:
		# Preview fixture: collect the existing demo supplies to show a populated pack.
		var player: SurvivorController = level.get_node("Actors/Player") as SurvivorController
		var inventory: SurvivorInventory = player.get_node("Inventory") as SurvivorInventory
		for pickup: Node in get_nodes_in_group("pickups"):
			(pickup as ItemPickup).collect(inventory)
		(player.get_node("Weapons") as WeaponController).equip_item(&"pistol")
		level.get_node("MovementHUD").toggle_inventory()
		level.get_node("MovementHUD/Interface/InventoryPanel").select_slot(inventory.find_slot(&"pistol"))
		for frame: int in range(3):
			await process_frame
	elif aiming_preview:
		var player: SurvivorController = level.get_node("Actors/Player") as SurvivorController
		player.get_node("Input").set_physics_process(false)
		player.get_node("Input").set_process_unhandled_input(false)
		var inventory: SurvivorInventory = player.get_node("Inventory") as SurvivorInventory
		inventory.add_item(&"pistol", 1)
		var weapons: WeaponController = player.get_node("Weapons") as WeaponController
		weapons.equip_item(&"pistol")
		weapons.set_aim(Vector2.UP)
		for frame: int in range(3):
			await physics_frame
	elif paused_preview:
		level.get_node("MovementHUD").set_paused(true)
		await process_frame
	await RenderingServer.frame_post_draw
	var filename: String = "pixel-preview.png"
	if inventory_preview:
		filename = "inventory-preview.png"
	elif paused_preview:
		filename = "pause-preview.png"
	elif aiming_preview:
		filename = "aiming-preview.png"
	var output: String = "res://.godot/" + filename
	var error: Error = root.get_texture().get_image().save_png(output)
	print("Preview saved: ", ProjectSettings.globalize_path(output))
	quit(error)
