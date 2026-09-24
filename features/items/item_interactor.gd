class_name ItemInteractor
extends Node2D

signal feedback(message: String)
const PICKUP_SCENE: PackedScene = preload("res://features/items/item_pickup.tscn")
@export var pickup_range: float = 38.0
@onready var inventory: SurvivorInventory = $"../Inventory"
@onready var _player: SurvivorController = get_parent() as SurvivorController
@onready var _health: HealthComponent = $"../Health"


func nearest_pickup() -> ItemPickup:
	var nearest: ItemPickup
	var distance: float = pickup_range
	for node: Node in get_tree().get_nodes_in_group("pickups"):
		var pickup: ItemPickup = node as ItemPickup
		if pickup == null or pickup.quantity <= 0:
			continue
		var candidate: float = global_position.distance_to(pickup.global_position)
		if candidate > distance:
			continue
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			global_position, pickup.global_position, 1
		)
		query.hit_from_inside = true
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		nearest = pickup
		distance = candidate
	return nearest


func collect_nearest() -> int:
	var pickup: ItemPickup = nearest_pickup()
	if pickup == null:
		feedback.emit("Move closer to a supply marker, then press E.")
		return 0
	var item: ItemDefinition = ItemCatalog.find(pickup.item_id)
	var amount: int = pickup.collect(inventory)
	feedback.emit("Picked up %s x%d" % [item.display_name, amount] if amount > 0 else "Pack full. Open B and drop a stack.")
	return amount


func drop_slot(index: int) -> bool:
	var stack: ItemStack = inventory.get_slot(index)
	if stack == null:
		return false
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 9.0
	var point: Vector2
	var found: bool = false
	for direction: Vector2 in [_player.facing, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.ZERO]:
		point = global_position + direction * 22.0
		var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0, point)
		query.collision_mask = 1
		if space.intersect_shape(query).is_empty():
			found = true
			break
	if not found:
		feedback.emit("No free ground here to drop this item.")
		return false
	var pickup: ItemPickup = PICKUP_SCENE.instantiate() as ItemPickup
	pickup.item_id = stack.item_id
	pickup.quantity = stack.quantity
	pickup.loaded_ammo = stack.loaded_ammo
	_player.get_parent().add_child(pickup)
	pickup.global_position = point
	inventory.take_slot(index)
	feedback.emit("Dropped " + ItemCatalog.find(stack.item_id).display_name)
	return true


func use_slot(index: int) -> bool:
	var stack: ItemStack = inventory.get_slot(index)
	if stack == null:
		return false
	var item: ItemDefinition = ItemCatalog.find(stack.item_id)
	if item.kind != ItemDefinition.Kind.CONSUMABLE:
		return false
	var restored: int = _health.heal(item.healing)
	if restored == 0:
		feedback.emit("Health is full. Medkit kept in your pack.")
		return false
	inventory.consume_at(index)
	feedback.emit("Recovered %d HP" % restored)
	return true
