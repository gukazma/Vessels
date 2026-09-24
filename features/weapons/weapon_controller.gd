class_name WeaponController
extends Node2D
## Hitscan weapons and a melee cone share world occlusion and item-owned magazines.

signal changed
signal feedback(message: String)
const WORLD_MASK: int = 1
const TARGET_MASK: int = 4
var equipped_slot: int = -1
var aim_direction: Vector2 = Vector2.RIGHT
var _cooldown: float = 0.0
var _reload_remaining: float = 0.0
var _attack_requested: bool = false
@onready var inventory: SurvivorInventory = $"../Inventory"
@onready var _pose: WeaponVisual = $"../Visuals/Sprite/WeaponPose"


func _ready() -> void:
	# Resolve attack pose before the player picks its directional body frame.
	process_physics_priority = -5
	inventory.changed.connect(_inventory_changed)


func definition() -> ItemDefinition:
	var stack: ItemStack = inventory.get_slot(equipped_slot)
	return ItemCatalog.find(stack.item_id) if stack != null else null


func equip(index: int) -> bool:
	var stack: ItemStack = inventory.get_slot(index)
	if stack == null or ItemCatalog.find(stack.item_id).kind != ItemDefinition.Kind.WEAPON:
		return false
	if equipped_slot != index:
		cancel_reload()
		clear_attack_request()
		_pose.set_weapon(null)
		equipped_slot = index
		changed.emit()
	_update_held()
	return true


func equip_item(id: StringName) -> bool:
	var result: bool = equip(inventory.find_slot(id))
	if not result:
		feedback.emit("Not in your pack. Find and pick up this weapon.")
	return result


func set_aim(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		aim_direction = direction.normalized()


func visual_direction() -> Vector2:
	return _pose.facing_direction(aim_direction)


func request_attack() -> void:
	_attack_requested = true


func clear_attack_request() -> void:
	_attack_requested = false


func is_reloading() -> bool:
	return _reload_remaining > 0.0


func cancel_reload() -> void:
	_reload_remaining = 0.0


func request_reload() -> bool:
	var item: ItemDefinition = definition()
	if item == null or item.magazine_size == 0 or is_reloading():
		return false
	if inventory.get_slot(equipped_slot).loaded_ammo >= item.magazine_size:
		return false
	if inventory.count_item(item.ammo_id) == 0:
		feedback.emit("No reserve ammunition. Pick up an ammo box.")
		return false
	_reload_remaining = item.reload_time
	clear_attack_request()
	changed.emit()
	return true


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_pose.update_pose(aim_direction, delta)
	if is_reloading():
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
		if not is_reloading():
			inventory.reload_weapon(equipped_slot)
			changed.emit()
	if _attack_requested:
		_attack_requested = false
		_attack()


func _attack() -> void:
	var item: ItemDefinition = definition()
	if item == null or is_reloading() or _cooldown > 0.0:
		return
	if item.magazine_size > 0 and not inventory.consume_loaded_round(equipped_slot):
		feedback.emit("Empty magazine. Press R to reload.")
		return
	_cooldown = item.attack_interval
	var traces: Array[Vector2] = []
	if item.magazine_size == 0:
		_melee(item)
	else:
		for pellet: int in range(item.pellets):
			var spread: float = 0.0
			if item.pellets > 1:
				spread = lerpf(-item.spread_radians / 2.0, item.spread_radians / 2.0,
					float(pellet) / float(item.pellets - 1))
			var end: Vector2 = global_position + aim_direction.rotated(spread) * item.attack_range
			var result: Dictionary = _ray(global_position, end, WORLD_MASK | TARGET_MASK)
			if not result.is_empty():
				end = result.position
				var collider: Object = result.collider
				if collider.has_method("take_damage"):
					collider.call("take_damage", item.damage)
			traces.append(end)
	_pose.play_attack(aim_direction, traces)
	changed.emit()


func _melee(item: ItemDefinition) -> void:
	var area: CircleShape2D = CircleShape2D.new()
	area.radius = item.attack_range
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = area
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = TARGET_MASK
	var hit_ids: Array[int] = []
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query):
		var target: Node2D = result.collider as Node2D
		if target == null or not target.has_method("take_damage") or target.get_instance_id() in hit_ids:
			continue
		var target_position: Vector2 = target.global_position
		if target.has_method("hit_position"):
			target_position = target.call("hit_position")
		var direction: Vector2 = target_position - global_position
		if not direction.is_zero_approx() and direction.normalized().dot(aim_direction) < 0.45:
			continue
		if not _ray(global_position, target_position, WORLD_MASK).is_empty():
			continue
		hit_ids.append(target.get_instance_id())
		target.call("take_damage", item.damage)


func _ray(from: Vector2, to: Vector2, mask: int) -> Dictionary:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, mask)
	query.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(query)


func _inventory_changed() -> void:
	if inventory.get_slot(equipped_slot) == null:
		equipped_slot = -1
		cancel_reload()
		clear_attack_request()
	_update_held()
	changed.emit()


func _update_held() -> void:
	_pose.set_weapon(definition())
	_pose.update_pose(aim_direction, 0.0)
