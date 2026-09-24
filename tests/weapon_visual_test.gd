extends SceneTree
## Presentation regressions run against the real player scene and item resources.

const PLAYER: PackedScene = preload("res://features/player/player.tscn")
const DIRECTIONS: Array[Vector2] = [Vector2.UP, Vector2(1, -1), Vector2.RIGHT,
	Vector2(1, 1), Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2(-1, -1)]
var _checks: int = 0
var _failures: int = 0
var _ticks: int = 60


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			_ticks = int(argument.get_slice("=", 1))
	Engine.physics_ticks_per_second = _ticks
	_run.call_deferred()


func _run() -> void:
	var world: Node2D = Node2D.new()
	world.y_sort_enabled = true
	root.add_child(world)
	var player: SurvivorController = PLAYER.instantiate() as SurvivorController
	world.add_child(player)
	player.get_node("Input").set_physics_process(false)
	player.get_node("Input").set_process_unhandled_input(false)
	var inventory: SurvivorInventory = player.get_node("Inventory") as SurvivorInventory
	var weapons: WeaponController = player.get_node("Weapons") as WeaponController
	var sprite: Sprite2D = player.get_node("Visuals/Sprite") as Sprite2D
	var pose: WeaponVisual = sprite.get_node("WeaponPose") as WeaponVisual
	var pivot: Node2D = pose.get_node("Pivot") as Node2D
	var held: Sprite2D = pivot.get_node("Held") as Sprite2D
	for id: StringName in [&"crowbar", &"pistol", &"shotgun"]:
		inventory.add_item(id, 1, ItemCatalog.find(id).magazine_size)
	weapons.equip_item(&"pistol")
	weapons.set_aim(Vector2.UP)
	player.set_movement_input(Vector2.DOWN, false)
	await _seconds(0.12)
	_check(sprite.frame >= 12 and sprite.frame < 16,
		"An armed survivor faces the aim while moving backward")
	_check(player.velocity.y > 0.0 and player.facing == Vector2.DOWN,
		"Aiming does not replace the movement direction")
	player.request_dash()
	await _seconds(0.03)
	_check(player.is_dashing and player.velocity.y > 0.0 and is_zero_approx(player.velocity.x),
		"A backward dash keeps its movement direction while aiming upward")
	player.stop_motion()
	inventory.take_slot(weapons.equipped_slot)
	await _seconds(0.03)
	_check(sprite.frame == 0 and not held.is_visible_in_tree()
		and sprite.texture == SurvivorVisual.WALK_TEXTURE,
		"Dropping the active weapon clears its visual and restores movement facing")

	# Freeze automatic updates so attack poses can be sampled at exact elapsed times.
	player.set_physics_process(false)
	weapons.set_physics_process(false)
	_check_firearm_stances(player)
	for id: StringName in [&"crowbar", &"pistol", &"shotgun"]:
		var item: ItemDefinition = ItemCatalog.find(id)
		pose.set_weapon(item)
		for direction: Vector2 in DIRECTIONS:
			pose.update_pose(direction.normalized(), 0.0)
			var grip: Vector2 = item.held_grip
			if held.flip_h:
				grip.x = float(held.texture.get_width()) - grip.x
			if held.flip_v:
				grip.y = float(held.texture.get_height()) - grip.y
			var grip_local: Vector2 = held.offset + grip
			if held.centered:
				grip_local -= held.texture.get_size() / 2.0
			_check(held.to_global(grip_local).distance_to(pivot.global_position) < 0.01,
				"%s grip remains at the hand pivot when aiming %s" % [id, direction])
			_check(pose.show_behind_parent == (direction.y < 0.0),
				"%s chooses the correct body side when aiming %s" % [id, direction])

	var empty_traces: Array[Vector2] = []
	pose.set_weapon(ItemCatalog.find(&"crowbar"))
	pose.update_pose(Vector2.UP, 0.0)
	var idle_rotation: float = pivot.rotation
	pose.play_attack(Vector2.UP, empty_traces)
	pose.update_pose(Vector2.RIGHT, 0.05)
	var locked_facing: Vector2 = pose.facing_direction(Vector2.RIGHT)
	_check(locked_facing.is_equal_approx(Vector2.UP) and pose.show_behind_parent,
		"A melee swing retains its attack direction and rear occlusion")
	_check(absf(angle_difference(idle_rotation, pivot.rotation)) > 0.05,
		"Melee attacks animate the actual held weapon")
	pose.update_pose(Vector2.RIGHT, 0.4)
	var released_facing: Vector2 = pose.facing_direction(Vector2.RIGHT)
	_check(released_facing.is_equal_approx(Vector2.RIGHT) and not pose.show_behind_parent,
		"A completed melee swing releases its facing lock")

	pose.set_weapon(ItemCatalog.find(&"pistol"))
	pose.update_pose(Vector2.UP, 0.0)
	var idle_hand: Vector2 = pivot.position
	pose.play_attack(Vector2.UP, empty_traces)
	pose.update_pose(Vector2.RIGHT, 0.03)
	_check(pivot.position.distance_to(idle_hand) > 0.01,
		"Firing animates recoil at the weapon pivot")
	pose.update_pose(Vector2.UP, 0.3)
	_check(pivot.position.distance_to(idle_hand) < 0.01,
		"Recoil settles back onto the original grip socket")
	pose.play_attack(Vector2.UP, empty_traces)
	pose.set_weapon(ItemCatalog.find(&"shotgun"))
	pose.update_pose(Vector2.RIGHT, 0.0)
	released_facing = pose.facing_direction(Vector2.RIGHT)
	_check(released_facing.is_equal_approx(Vector2.RIGHT)
		and held.texture == ItemCatalog.find(&"shotgun").held_texture,
		"Changing weapons clears the old attack pose and replaces the held artwork")
	pose.play_attack(Vector2.RIGHT, empty_traces)
	pose.set_weapon(null)
	pose.update_pose(Vector2.DOWN, 0.0)
	released_facing = pose.facing_direction(Vector2.DOWN)
	_check(not held.is_visible_in_tree() and released_facing.is_equal_approx(Vector2.DOWN),
		"Unequipping during an attack clears the visible weapon and facing lock")
	weapons.equip_item(&"shotgun")
	weapons.set_aim(Vector2.RIGHT)
	var visuals: SurvivorVisual = player.get_node("Visuals") as SurvivorVisual
	visuals.update_motion(Vector2.ZERO, Vector2.RIGHT, false, 0.0)
	var previous_muzzle: Vector2 = pose.muzzle_global_position()
	weapons.set_aim(Vector2.UP)
	weapons.request_attack()
	weapons._physics_process(0.0)
	visuals.update_motion(Vector2.ZERO, weapons.visual_direction(), false, 0.0)
	var trace_origin: Vector2 = pose.get("_trace_start")
	_check(trace_origin.distance_to(pose.muzzle_global_position()) < 0.01
		and trace_origin.distance_to(previous_muzzle) > 5.0,
		"Turning and firing in one tick starts the tracer at the new aiming socket")

	print("RESULT: %d/%d weapon presentation checks passed at %d Hz" % [
		_checks - _failures, _checks, _ticks])
	world.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check_firearm_stances(player: SurvivorController) -> void:
	var visuals: SurvivorVisual = player.get_node("Visuals") as SurvivorVisual
	var sprite: Sprite2D = visuals.get_node("Sprite") as Sprite2D
	var pose: WeaponVisual = sprite.get_node("WeaponPose") as WeaponVisual
	var held: Sprite2D = pose.get_node("Pivot/Held") as Sprite2D
	var pivot: Node2D = pose.get_node("Pivot") as Node2D
	for id: StringName in [&"pistol", &"shotgun"]:
		var item: ItemDefinition = ItemCatalog.find(id)
		pose.set_weapon(item)
		var stable_grip: bool = true
		var correct_view: bool = true
		for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			pose.update_pose(direction, 0.0)
			visuals.update_motion(Vector2.ZERO, direction, false, 0.0)
			var resting_hand: Vector2 = pose.position
			if direction.x == 0.0:
				var muzzle_axis: Vector2 = pose.muzzle_global_position() - pivot.global_position
				correct_view = correct_view and held.texture == item.held_axial_texture \
					and absf(muzzle_axis.normalized().cross(direction)) < 0.01
			else:
				correct_view = correct_view and held.texture == item.held_texture
			for frame: int in range(4):
				visuals.update_motion(Vector2(9, 0), direction, false, 1.0)
				stable_grip = stable_grip and is_equal_approx(pose.position.x, resting_hand.x) \
					and absf(pose.position.y - resting_hand.y) <= 1.0
		_check(sprite.texture == SurvivorVisual.AIMING_TEXTURE and stable_grip,
			"%s keeps raised arms and a steady grip through all walking frames" % id)
		_check(correct_view, "%s uses an axial barrel view for front/back aim and a side view laterally" % id)
	pose.set_weapon(ItemCatalog.find(&"crowbar"))
	visuals.update_motion(Vector2.ZERO, Vector2.RIGHT, false, 0.0)
	_check(sprite.texture == SurvivorVisual.WALK_TEXTURE,
		"Switching from a firearm to melee restores the original arm animation")


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
