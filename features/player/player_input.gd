extends Node
## Device sampling precedes movement. Pausing is owned by the HUD.

@onready var _player: SurvivorController = get_parent() as SurvivorController
@onready var _weapons: WeaponController = $"../Weapons"
@onready var _interactor: ItemInteractor = $"../Interaction"


func _ready() -> void:
	process_physics_priority = -10


func _physics_process(_delta: float) -> void:
	_weapons.set_aim(_weapons.get_global_mouse_position() - _weapons.global_position)
	var direction: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	_player.set_movement_input(direction, Input.is_action_pressed("sprint"))
	if Input.is_action_just_pressed("dash"):
		_player.request_dash()
	if Input.is_action_just_pressed("interact"):
		_interactor.collect_nearest()
	if Input.is_action_just_pressed("reload"):
		_weapons.request_reload()
	for index: int in range(3):
		if Input.is_action_just_pressed("weapon_%d" % (index + 1)):
			_weapons.equip_item([&"crowbar", &"pistol", &"shotgun"][index])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_weapons.request_attack()
		get_viewport().set_input_as_handled()
