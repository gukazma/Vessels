extends Node2D
## Level recovery is independent from the reusable character controller.

const PLAYABLE_BOUNDS: Rect2 = Rect2(0, 0, 960, 640)
const SPAWN_POSITION: Vector2 = Vector2(480, 402)
const SUPPLY_DEMO: PackedScene = preload("res://levels/supply_demo.tscn")
@onready var _player: SurvivorController = $Actors/Player


func _ready() -> void:
	$Actors.add_child(SUPPLY_DEMO.instantiate())
	var inventory: SurvivorInventory = _player.get_node("Inventory") as SurvivorInventory
	inventory.add_item(&"crowbar", 1)
	inventory.add_item(&"medkit", 1)
	(_player.get_node("Weapons") as WeaponController).equip_item(&"crowbar")


func _physics_process(_delta: float) -> void:
	if not PLAYABLE_BOUNDS.has_point(_player.position):
		_player.stop_motion()
		_player.position = SPAWN_POSITION
		(_player.get_node("Camera") as Camera2D).reset_smoothing()
