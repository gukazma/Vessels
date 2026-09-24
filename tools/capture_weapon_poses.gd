extends SceneTree
## Real-renderer capture and pixel assertions; do not run with --headless.
## godot --path . --script res://tools/capture_weapon_poses.gd

const PLAYER: PackedScene = preload("res://features/player/player.tscn")
const WEAPONS: Array[StringName] = [&"crowbar", &"pistol", &"shotgun"]
const DIRECTIONS: Array[Vector2] = [Vector2.UP, Vector2(1, -1), Vector2.RIGHT,
	Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1)]
const DIRECTION_NAMES: Array[String] = ["UP", "UP-RIGHT", "RIGHT", "DOWN-RIGHT",
	"DOWN", "DOWN-LEFT", "LEFT", "UP-LEFT"]
const ATTACK_TIMES: Array[float] = [0.0, 0.025, 0.05, 0.08, 0.11, 0.14, 0.18, 0.26]
const PAPER: Color = Color("e9e4d4")
const INK: Color = Color("293a49")
const OCCLUDER: Color = Color("915dac")
var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var directions: SubViewport = _viewport(Vector2i(1100, 570))
	_label(directions, "HELD WEAPONS / EIGHT DIRECTIONS / 3x PIXELS", Vector2(20, 10), 20)
	for row: int in range(WEAPONS.size()):
		_label(directions, String(WEAPONS[row]).to_upper(), Vector2(16, 51 + row * 170), 15)
		for column: int in range(DIRECTIONS.size()):
			var position: Vector2 = Vector2(82 + column * 134, 178 + row * 170)
			_spawn(directions, WEAPONS[row], DIRECTIONS[column].normalized(), position, 3.0)
			_label(directions, DIRECTION_NAMES[column], position + Vector2(-43, 24), 12)
	await _save(directions, "weapon-poses.png")
	directions.queue_free()
	await process_frame

	var attacks: SubViewport = _viewport(Vector2i(1100, 570))
	_label(attacks, "BACK-FACING ATTACK / ELAPSED SECONDS / 3x PIXELS", Vector2(20, 10), 20)
	var empty_traces: Array[Vector2] = []
	for row: int in range(WEAPONS.size()):
		_label(attacks, String(WEAPONS[row]).to_upper(), Vector2(16, 51 + row * 170), 15)
		for column: int in range(ATTACK_TIMES.size()):
			var position: Vector2 = Vector2(82 + column * 134, 178 + row * 170)
			var player: SurvivorController = _spawn(attacks, WEAPONS[row], Vector2.UP, position, 3.0)
			var pose: WeaponVisual = player.get_node("Visuals/Sprite/WeaponPose") as WeaponVisual
			pose.play_attack(Vector2.UP, empty_traces)
			pose.update_pose(Vector2.UP, ATTACK_TIMES[column])
			_label(attacks, "%.3f s" % ATTACK_TIMES[column], position + Vector2(-26, 24), 12)
	await _save(attacks, "weapon-attacks.png")
	attacks.queue_free()
	await process_frame
	await _capture_walk()

	await _verify_pixels()
	print("RESULT: %d/%d rendered weapon occlusion checks passed" % [_checks - _failures, _checks])
	quit(1 if _failures else 0)


func _capture_walk() -> void:
	var viewport: SubViewport = _viewport(Vector2i(1100, 410))
	_label(viewport, "RAISED ARMS / FOUR WALK FRAMES / UP + RIGHT", Vector2(20, 10), 20)
	for row: int in range(2):
		var id: StringName = [&"pistol", &"shotgun"][row]
		_label(viewport, String(id).to_upper(), Vector2(16, 51 + row * 175), 15)
		for column: int in range(8):
			var direction: Vector2 = Vector2.UP if column < 4 else Vector2.RIGHT
			var at: Vector2 = Vector2(82 + column * 134, 180 + row * 175)
			var player: SurvivorController = _spawn(viewport, id, direction, at, 3.0)
			var visuals: SurvivorVisual = player.get_node("Visuals") as SurvivorVisual
			visuals.update_motion(Vector2(9, 0), direction, false, float(column % 4))
			_label(viewport, "FRAME %d" % (column % 4), at + Vector2(-25, 12), 12)
	await _save(viewport, "weapon-walk.png")
	viewport.queue_free()
	await process_frame


func _verify_pixels() -> void:
	var viewport: SubViewport = _viewport(Vector2i(128, 128))
	var actors: Node2D = Node2D.new()
	actors.y_sort_enabled = true
	viewport.add_child(actors)
	var player: SurvivorController = _spawn(actors, &"shotgun", Vector2.UP, Vector2(64, 80))
	var sprite: Sprite2D = player.get_node("Visuals/Sprite") as Sprite2D
	var pose: WeaponVisual = sprite.get_node("WeaponPose") as WeaponVisual
	var body_texture: Image = sprite.texture.get_image()
	var frame_size: Vector2i = Vector2i(body_texture.get_size()) / Vector2i(sprite.hframes, sprite.vframes)
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN]:
		_set_direction(player, direction)
		pose.visible = true
		var armed: Image = await _snapshot(viewport)
		pose.visible = false
		var bare: Image = await _snapshot(viewport)
		var body_changed: int = 0
		var outside_changed: int = 0
		var frame_origin: Vector2i = sprite.frame_coords * frame_size
		var screen_origin: Vector2i = Vector2i(sprite.global_position + sprite.offset)
		screen_origin -= frame_size / 2
		for y: int in range(128):
			for x: int in range(128):
				if _same_pixel(armed.get_pixel(x, y), bare.get_pixel(x, y)):
					continue
				var local: Vector2i = Vector2i(x, y) - screen_origin
				var on_body: bool = Rect2i(Vector2i.ZERO, frame_size).has_point(local)
				if on_body:
					on_body = body_texture.get_pixelv(frame_origin + local).a > 0.99
				if on_body:
					body_changed += 1
				else:
					outside_changed += 1
		if direction == Vector2.UP:
			_check(body_changed == 0, "Rear weapon never paints over opaque body pixels")
			_check(outside_changed > 0, "Rear weapon remains visible outside the body silhouette")
		else:
			_check(body_changed > 0, "Forward weapon visibly passes in front of the torso")

	# Use a wide, tall prop so even protruding weapon pixels must participate in Y sorting.
	_set_direction(player, Vector2.RIGHT)
	pose.visible = true
	var baseline: Image = await _snapshot(viewport)
	var prop: Sprite2D = Sprite2D.new()
	var prop_image: Image = Image.create(100, 100, false, Image.FORMAT_RGBA8)
	prop_image.fill(OCCLUDER)
	prop.texture = ImageTexture.create_from_image(prop_image)
	prop.offset = Vector2(0, -30)
	actors.add_child(prop)
	prop.position = Vector2(64, 81)
	var front: Image = await _snapshot(viewport)
	var escaped_pixels: int = 0
	for y: int in range(24, 90):
		for x: int in range(24, 108):
			if not _same_pixel(front.get_pixel(x, y), OCCLUDER):
				escaped_pixels += 1
	_check(escaped_pixels == 0, "A foreground prop covers both the survivor and the protruding weapon")
	prop.position.y = 79
	var behind: Image = await _snapshot(viewport)
	var restored_body: bool = false
	var restored_weapon: bool = false
	# Both body and exposed weapon have opaque source pixels, unaffected by the prop behind.
	for y: int in range(43, 78):
		for x: int in range(49, 99):
			var expected: Color = baseline.get_pixel(x, y)
			if not _same_pixel(expected, PAPER) and _same_pixel(behind.get_pixel(x, y), expected):
				if x < 74:
					restored_body = true
				elif x > 80:
					restored_weapon = true
	_check(restored_body and restored_weapon,
		"Moving the prop behind restores both body and weapon at the same actor depth")
	var comparison: Image = Image.create(384, 128, false, Image.FORMAT_RGBA8)
	comparison.blit_rect(baseline, Rect2i(0, 0, 128, 128), Vector2i.ZERO)
	comparison.blit_rect(front, Rect2i(0, 0, 128, 128), Vector2i(128, 0))
	comparison.blit_rect(behind, Rect2i(0, 0, 128, 128), Vector2i(256, 0))
	comparison.resize(1152, 384, Image.INTERPOLATE_NEAREST)
	_check(comparison.save_png("res://.godot/weapon-occlusion.png") == OK, "Occlusion comparison image saved")
	viewport.queue_free()
	await process_frame


func _viewport(size: Vector2i) -> SubViewport:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	viewport.snap_2d_transforms_to_pixel = true
	viewport.snap_2d_vertices_to_pixel = true
	root.add_child(viewport)
	var background: ColorRect = ColorRect.new()
	background.size = Vector2(size)
	background.color = PAPER
	viewport.add_child(background)
	return viewport


func _spawn(parent: Node, item_id: StringName, direction: Vector2, at: Vector2,
		scale_factor: float = 1.0) -> SurvivorController:
	var player: SurvivorController = PLAYER.instantiate() as SurvivorController
	parent.add_child(player)
	player.position = at
	player.scale = Vector2.ONE * scale_factor
	player.set_physics_process(false)
	player.get_node("Input").set_physics_process(false)
	player.get_node("Input").set_process_unhandled_input(false)
	(player.get_node("Camera") as Camera2D).enabled = false
	var inventory: SurvivorInventory = player.get_node("Inventory") as SurvivorInventory
	var weapons: WeaponController = player.get_node("Weapons") as WeaponController
	weapons.set_physics_process(false)
	inventory.add_item(item_id, 1)
	weapons.equip_item(item_id)
	_set_direction(player, direction)
	return player


func _set_direction(player: SurvivorController, direction: Vector2) -> void:
	(player.get_node("Weapons") as WeaponController).set_aim(direction)
	(player.get_node("Visuals") as SurvivorVisual).update_motion(Vector2.ZERO, direction, false, 0.0)
	(player.get_node("Visuals/Sprite/WeaponPose") as WeaponVisual).update_pose(direction, 0.0)


func _label(parent: Node, text: String, at: Vector2, font_size: int) -> void:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)


func _snapshot(viewport: SubViewport) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()


func _save(viewport: SubViewport, filename: String) -> void:
	var snapshot: Image = await _snapshot(viewport)
	var output: String = "res://.godot/" + filename
	_check(snapshot.save_png(output) == OK, filename + " saved")
	print("Preview saved: ", ProjectSettings.globalize_path(output))


func _same_pixel(first: Color, second: Color) -> bool:
	return absf(first.r - second.r) < 0.006 and absf(first.g - second.g) < 0.006 \
		and absf(first.b - second.b) < 0.006


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
