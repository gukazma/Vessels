extends CanvasLayer

const HEALTH_BAR_WIDTH: float = 110.0
const DASH_BAR_WIDTH: float = 30.0
const MAP_ORIGIN: Vector2 = Vector2(553, 31)
const MAP_TRAVEL: Vector2 = Vector2(57, 37)
const WORLD_SIZE: Vector2 = Vector2(960, 640)

@export var player_path: NodePath
@export var pause_on_focus_loss: bool = true
@onready var _player: SurvivorController = get_node(player_path) as SurvivorController
@onready var _interface: Control = $Interface
@onready var _state: Label = $Interface/Status
@onready var _dash_bar: ColorRect = $Interface/DashFill
@onready var _dash_label: Label = $Interface/DashLabel
@onready var _health_bar: ColorRect = $Interface/HealthFill
@onready var _pause_screen: ColorRect = $Interface/PauseScreen
@onready var _map_dot: ColorRect = $Interface/MapDot
@onready var _inventory: SurvivorInventory = _player.get_node("Inventory") as SurvivorInventory
@onready var _weapons: WeaponController = _player.get_node("Weapons") as WeaponController
@onready var _interactor: ItemInteractor = _player.get_node("Interaction") as ItemInteractor
@onready var _health: HealthComponent = _player.get_node("Health") as HealthComponent
@onready var _pack: Control = $Interface/InventoryPanel
@onready var _weapon_label: Label = $Interface/Weapon
@onready var _weapon_icon: TextureRect = $Interface/WeaponIcon
@onready var _ammo_label: Label = $Interface/Ammo
@onready var _weapon_hint: Label = $Interface/WeaponHint
@onready var _pickup_label: Label = $Interface/Pickup
@onready var _toast: Label = $Interface/Toast
var _manual_paused: bool = false
var _bag_open: bool = false
var _toast_remaining: float = 0.0


func _ready() -> void:
	_pack.configure(_inventory, _weapons, _interactor)
	_pack.close_requested.connect(toggle_inventory)
	_weapons.feedback.connect(show_feedback)
	_interactor.feedback.connect(show_feedback)


func _process(delta: float) -> void:
	_update_vitals()
	_update_equipment()
	_update_prompts(delta)
	_pause_screen.visible = _manual_paused and not _bag_open
	var map_ratio: Vector2 = (_player.position / WORLD_SIZE).clamp(Vector2.ZERO, Vector2.ONE)
	_map_dot.position = (MAP_ORIGIN + map_ratio * MAP_TRAVEL).round()


func _update_vitals() -> void:
	var movement: String = "STEADY"
	if _player.is_dashing:
		movement = "DASH"
	elif _player.velocity.length() > _player.walk_speed + 5.0:
		movement = "RUNNING"
	elif _player.velocity.length() > 2.0:
		movement = "WALKING"
	_state.text = "%03d / %s" % [_health.current, movement]
	_health_bar.size.x = HEALTH_BAR_WIDTH * clampf(float(_health.current) / maxi(1, _health.maximum), 0.0, 1.0)
	_health_bar.color = Color("c9745c") if _health.current <= 30 else Color("619786")
	_dash_bar.size.x = DASH_BAR_WIDTH * _player.dash_readiness()
	_dash_label.text = "SPACE / READY" if is_equal_approx(_player.dash_readiness(), 1.0) else (
		"SPACE / %02d%%" % roundi(_player.dash_readiness() * 100.0)
	)


func _update_equipment() -> void:
	var item: ItemDefinition = _weapons.definition()
	_weapon_label.text = "EMPTY HANDS"
	_weapon_icon.visible = item != null
	_ammo_label.text = "--"
	_weapon_hint.text = "B  EQUIP FROM PACK"
	if item != null:
		_weapon_label.text = item.display_name
		_weapon_icon.texture = item.icon
		_ammo_label.text = "MELEE"
		_weapon_hint.text = "LMB  SWING"
		if item.magazine_size > 0:
			_ammo_label.text = "%02d / %02d" % [
				_inventory.get_slot(_weapons.equipped_slot).loaded_ammo,
				_inventory.count_item(item.ammo_id)]
			_weapon_hint.text = "LMB FIRE   R RELOAD"
		if _weapons.is_reloading():
			_weapon_hint.text = "RELOADING..."


func _update_prompts(delta: float) -> void:
	var pickup: ItemPickup = _interactor.nearest_pickup() if not get_tree().paused else null
	_pickup_label.visible = pickup != null
	if pickup != null:
		_pickup_label.text = "E  %s  x%d" % [ItemCatalog.find(pickup.item_id).display_name, pickup.quantity]
		_pickup_label.reset_size()
		_pickup_label.position.x = roundf((_interface.size.x - _pickup_label.size.x) * 0.5)
	_toast_remaining = maxf(0, _toast_remaining - delta)
	_toast.visible = _toast_remaining > 0 and not _bag_open


func set_paused(value: bool) -> void:
	_manual_paused = value
	_apply_pause()


func toggle_inventory() -> void:
	if _manual_paused and not _bag_open:
		return
	_bag_open = not _bag_open
	_pack.visible = _bag_open
	if _bag_open:
		_pack.refresh()
		_pack.get_node("Panel/Help").text = "B / TAB / ESC  CLOSE PACK                         WORLD PAUSED"
	_apply_pause()


func _apply_pause() -> void:
	_player.stop_motion()
	_weapons.clear_attack_request()
	get_tree().paused = _manual_paused or _bag_open


func show_feedback(message: String) -> void:
	_toast.text = message
	_toast_remaining = 2.5
	if _bag_open:
		_pack.get_node("Panel/Help").text = message


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if _bag_open:
			toggle_inventory()
		else:
			set_paused(not _manual_paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory") and not event.is_echo():
		toggle_inventory()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and pause_on_focus_loss and is_node_ready():
		set_paused(true)
