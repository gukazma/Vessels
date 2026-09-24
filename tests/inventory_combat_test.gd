extends SceneTree

const PLAYER: PackedScene = preload("res://features/player/player.tscn")
const TARGET: PackedScene = preload("res://features/combat/training_target.tscn")
const PICKUP: PackedScene = preload("res://features/items/item_pickup.tscn")
var _world: Node2D
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
	_world = Node2D.new()
	root.add_child(_world)
	var small: SurvivorInventory = SurvivorInventory.new()
	small.capacity = 2
	_world.add_child(small)
	_check(small.add_item(&"ammo_9mm", 75) == 75 and small.used_slots() == 2, "Large ammo stacks split across slots")
	_check(small.get_slot(0).quantity == 60 and small.get_slot(1).quantity == 15, "Stack sizes respect item limits")
	_check(small.add_item(&"ammo_9mm", 80) == 45 and small.count_item(&"ammo_9mm") == 120, "Full packs accept only available stack space")
	_check(small.add_item(&"medkit", 1) == 0, "Full packs reject a different item without deleting it")
	_check(small.add_item(&"invalid", 1) == 0 and small.add_item(&"medkit", -1) == 0, "Invalid IDs and negative quantities are rejected")
	var snapshot: ItemStack = small.get_slot(0)
	snapshot.quantity = 999
	_check(small.count_item(&"ammo_9mm") == 120, "Slot snapshots cannot mutate inventory internals")
	_check(small.take_slot(0).quantity == 60 and small.used_slots() == 1, "Taking a stack frees exactly one slot")
	_check(small.take_slot(-1) == null and not small.consume_at(20), "Invalid slot operations are safe")
	var partial: ItemPickup = PICKUP.instantiate() as ItemPickup
	partial.item_id = &"ammo_9mm"
	partial.quantity = 90
	_world.add_child(partial)
	_check(partial.collect(small) == 60 and partial.quantity == 30, "Partial pickup leaves the remainder in the world")
	_check(partial.collect(small) == 0 and partial.quantity == 30, "Retrying a full-pack pickup does not duplicate items")
	partial.queue_free()
	small.queue_free()
	await process_frame

	var player: SurvivorController = PLAYER.instantiate() as SurvivorController
	_world.add_child(player)
	player.set_physics_process(false)
	player.get_node("Input").set_physics_process(false)
	player.get_node("Input").set_process_unhandled_input(false)
	var inventory: SurvivorInventory = player.get_node("Inventory") as SurvivorInventory
	var weapon: WeaponController = player.get_node("Weapons") as WeaponController
	var interactor: ItemInteractor = player.get_node("Interaction") as ItemInteractor
	var health: HealthComponent = player.get_node("Health") as HealthComponent
	inventory.add_item(&"crowbar", 1)
	inventory.add_item(&"pistol", 1, 2)
	inventory.add_item(&"shotgun", 1, 2)
	inventory.add_item(&"ammo_9mm", 5)
	inventory.add_item(&"shells", 3)
	inventory.add_item(&"medkit", 2)
	_check(not weapon.equip(3), "Ammunition cannot be equipped as a weapon")
	_check(weapon.equip_item(&"pistol"), "Owned weapons can be equipped")
	var target: StaticBody2D = TARGET.instantiate() as StaticBody2D
	target.maximum_health = 1000
	target.position = Vector2(100, 6)
	_world.add_child(target)
	await _seconds(0.05)
	weapon.set_aim(Vector2.RIGHT)
	weapon.request_attack()
	await _seconds(0.03)
	_check(target.current_health == 976 and inventory.get_slot(1).loaded_ammo == 1, "A pistol hit deals damage and consumes one loaded round")
	weapon.request_attack()
	await _seconds(0.03)
	_check(target.current_health == 976 and inventory.get_slot(1).loaded_ammo == 1, "Attack cooldown prevents rapid extra shots")
	await _seconds(0.3)
	weapon.request_attack()
	await _seconds(0.05)
	_check(inventory.get_slot(1).loaded_ammo == 0, "The last loaded round can be fired")
	await _seconds(0.3)
	weapon.request_attack()
	await _seconds(0.05)
	_check(target.current_health == 952, "An empty magazine cannot deal damage")
	_check(weapon.request_reload(), "Reload starts when reserve ammunition exists")
	_check(inventory.count_item(&"ammo_9mm") == 5, "Reload does not consume ammunition before completion")
	weapon.request_attack()
	await _seconds(0.2)
	_check(target.current_health == 952, "Reloading blocks attacks")
	await _seconds(1.0)
	_check(inventory.get_slot(1).loaded_ammo == 5 and inventory.count_item(&"ammo_9mm") == 0,
		"Reload transfers only available reserve ammunition")
	inventory.add_item(&"ammo_9mm", 8)
	weapon.request_reload()
	weapon.equip_item(&"crowbar")
	await _seconds(1.0)
	_check(not weapon.is_reloading() and inventory.get_slot(1).loaded_ammo == 5
		and inventory.count_item(&"ammo_9mm") == 8, "Switching weapons cancels reload without losing ammo")
	weapon.equip_item(&"pistol")
	weapon.request_reload()
	inventory.take_slot(inventory.find_slot(&"ammo_9mm"))
	await _seconds(1.0)
	_check(inventory.get_slot(1).loaded_ammo == 5, "Removed reserve ammo cannot be duplicated by a pending reload")

	target.position = Vector2(70, 6)
	await _seconds(0.05)
	weapon.equip_item(&"shotgun")
	var before: int = target.current_health
	weapon.request_attack()
	await _seconds(0.05)
	_check(target.current_health == before - 60, "Shotgun pellets each apply damage within their spread")
	_check(inventory.get_slot(2).loaded_ammo == 1 and inventory.count_item(&"shells") == 3,
		"A shotgun volley consumes one shell, not one per pellet")
	await _seconds(0.9)
	var wall: StaticBody2D = _box(Vector2(35, -12), Vector2(8, 100))
	await _seconds(0.05)
	weapon.equip_item(&"pistol")
	before = target.current_health
	weapon.request_attack()
	await _seconds(0.05)
	_check(target.current_health == before and inventory.get_slot(1).loaded_ammo == 4,
		"World obstacles stop hitscan shots")
	wall.queue_free()
	await process_frame
	await _seconds(0.5)
	weapon.equip_item(&"crowbar")
	target.position = Vector2(25, 6)
	await _seconds(0.05)
	weapon.request_attack()
	await _seconds(0.05)
	_check(target.current_health == before - 28, "A melee swing damages targets in front")
	await _seconds(0.5)
	target.position = Vector2(-25, 6)
	await _seconds(0.05)
	before = target.current_health
	weapon.request_attack()
	await _seconds(0.05)
	_check(target.current_health == before, "A melee swing does not hit behind the player")
	await _seconds(0.5)
	target.position = Vector2(25, 6)
	wall = _box(Vector2(12, -12), Vector2(6, 100))
	await _seconds(0.05)
	weapon.request_attack()
	await _seconds(0.05)
	_check(target.current_health == before, "Melee attacks cannot damage through a wall")
	wall.queue_free()
	target.queue_free()
	await process_frame

	weapon.equip_item(&"pistol")
	_check(interactor.drop_slot(1), "Dropping an equipped weapon creates a pickup")
	_check(weapon.equipped_slot == -1 and inventory.get_slot(1) == null, "Dropped weapons are unequipped immediately")
	await _seconds(0.05)
	var dropped: ItemPickup = interactor.nearest_pickup()
	_check(dropped != null and dropped.loaded_ammo == 4, "Weapon pickups retain their loaded magazine")
	_check(interactor.collect_nearest() == 1 and inventory.get_slot(1).loaded_ammo == 4,
		"Picking a dropped weapon back up preserves ammo")
	var medkit_slot: int = inventory.find_slot(&"medkit")
	_check(not interactor.use_slot(medkit_slot) and inventory.count_item(&"medkit") == 2,
		"Full health does not consume a medkit")
	health.take_damage(25)
	_check(interactor.use_slot(medkit_slot) and health.current == 100 and inventory.count_item(&"medkit") == 1,
		"Medkits heal up to maximum and consume exactly one item")
	var hidden_pickup: ItemPickup = PICKUP.instantiate() as ItemPickup
	hidden_pickup.position = Vector2(24, -4)
	_world.add_child(hidden_pickup)
	wall = _box(Vector2(12, -4), Vector2(6, 80))
	await _seconds(0.05)
	_check(interactor.nearest_pickup() == null, "Pickups behind walls cannot be collected")
	_world.queue_free()
	await process_frame

	var scene: PackedScene = load("res://levels/quarantine_street.tscn") as PackedScene
	var street: Node2D = scene.instantiate() as Node2D
	street.get_node("MovementHUD").pause_on_focus_loss = false
	root.add_child(street)
	player = street.get_node("Actors/Player") as SurvivorController
	player.get_node("Input").set_physics_process(false)
	var hud: CanvasLayer = street.get_node("MovementHUD") as CanvasLayer
	inventory = player.get_node("Inventory") as SurvivorInventory
	weapon = player.get_node("Weapons") as WeaponController
	interactor = player.get_node("Interaction") as ItemInteractor
	await _seconds(0.05)
	_check(inventory.count_item(&"crowbar") == 1 and weapon.definition().id == &"crowbar",
		"Actual game starts with an equipped melee weapon")
	_check(interactor.collect_nearest() == 1 and inventory.count_item(&"pistol") == 1,
		"The starting pistol is reachable from the spawn")
	weapon.equip_item(&"pistol")
	weapon.request_attack()
	hud.toggle_inventory()
	_check(paused and hud.get_node("Interface/InventoryPanel").visible, "Opening the backpack pauses the game")
	await _seconds(0.1)
	_check(inventory.get_slot(weapon.equipped_slot).loaded_ammo == 8, "Opening the pack clears pending attacks")
	var panel: Control = hud.get_node("Interface/InventoryPanel") as Control
	panel.get_node("Panel/Slots").get_child(0).pressed.emit()
	panel.get_node("Panel/Action").pressed.emit()
	_check(weapon.definition().id == &"crowbar", "Inventory slot and equip buttons work while paused")
	var esc: InputEventAction = InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	hud._unhandled_input(esc)
	_check(not paused and not panel.visible, "Escape closes the pack and resumes gameplay")
	await _seconds(0.05)
	weapon.equip_item(&"pistol")
	_check(inventory.get_slot(weapon.equipped_slot).loaded_ammo == 8, "Closing the pack does not execute stale attacks")
	street.queue_free()
	await process_frame
	print("RESULT: %d/%d inventory/combat checks passed at %d Hz" % [_checks - _failures, _checks, _ticks])
	quit(1 if _failures else 0)


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


func _box(at: Vector2, size: Vector2) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_world.add_child(body)
	body.position = at
	return body
