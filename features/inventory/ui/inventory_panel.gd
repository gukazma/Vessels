extends Control

signal close_requested
const SLOT_SCENE: PackedScene = preload("res://features/inventory/ui/inventory_slot.tscn")
var _inventory: SurvivorInventory
var _weapons: WeaponController
var _interactor: ItemInteractor
var _selected: int = 0
@onready var _grid: GridContainer = $Panel/Slots
@onready var _name: Label = $Panel/ItemName
@onready var _description: Label = $Panel/Description
@onready var _stats: Label = $Panel/Stats
@onready var _icon: TextureRect = $Panel/ItemIcon
@onready var _item_type: Label = $Panel/ItemType
@onready var _action: Button = $Panel/Action
@onready var _drop: Button = $Panel/Drop
@onready var _capacity: Label = $Panel/Capacity


func _ready() -> void:
	$Panel/Close.pressed.connect(func() -> void: close_requested.emit())
	_action.pressed.connect(_activate_selected)
	_drop.pressed.connect(_drop_selected)


func configure(inventory: SurvivorInventory, weapons: WeaponController, interactor: ItemInteractor) -> void:
	_inventory = inventory
	_weapons = weapons
	_interactor = interactor
	for index: int in range(inventory.capacity):
		var slot: Button = SLOT_SCENE.instantiate() as Button
		_grid.add_child(slot)
		slot.pressed.connect(select_slot.bind(index))
	_inventory.changed.connect(refresh)
	_weapons.changed.connect(refresh)
	refresh()


func select_slot(index: int) -> void:
	_selected = index
	refresh()


func refresh() -> void:
	if _inventory == null:
		return
	_capacity.text = "%02d / %02d SLOTS" % [_inventory.used_slots(), _inventory.capacity]
	for index: int in range(_grid.get_child_count()):
		_grid.get_child(index).display(index, _inventory.get_slot(index), index == _selected,
			index == _weapons.equipped_slot)
	var stack: ItemStack = _inventory.get_slot(_selected)
	_icon.visible = stack != null
	_drop.disabled = stack == null
	_action.disabled = true
	_action.text = "SELECT ITEM"
	_name.text = "EMPTY SLOT"
	_item_type.text = "AVAILABLE SPACE"
	_description.text = "Room for something useful.\nPick up nearby supplies with E."
	_stats.text = ""
	if stack == null:
		return
	var item: ItemDefinition = ItemCatalog.find(stack.item_id)
	_icon.texture = item.icon
	_name.text = item.display_name
	_description.text = item.description
	_item_type.text = "AMMUNITION"
	_stats.text = "STACK  %d / %d" % [stack.quantity, item.max_stack]
	if item.kind == ItemDefinition.Kind.WEAPON:
		_item_type.text = "EQUIPPED" if _selected == _weapons.equipped_slot else "WEAPON"
		_action.text = "EQUIPPED" if _selected == _weapons.equipped_slot else "EQUIP WEAPON"
		_action.disabled = _selected == _weapons.equipped_slot
		_stats.text = "DAMAGE    %d%s" % [item.damage,
			" x%d" % item.pellets if item.pellets > 1 else ""]
		if item.magazine_size > 0:
			_stats.text += "\nMAGAZINE  %d / %d\nRESERVE   %d" % [stack.loaded_ammo,
				item.magazine_size, _inventory.count_item(item.ammo_id)]
		else:
			_stats.text += "\nCLOSE COMBAT"
	elif item.kind == ItemDefinition.Kind.CONSUMABLE:
		_item_type.text = "FIRST AID"
		_action.text = "USE / +%d HP" % item.healing
		_action.disabled = false
	else:
		_action.text = "RELOAD WITH R"


func _activate_selected() -> void:
	var stack: ItemStack = _inventory.get_slot(_selected)
	if stack == null:
		return
	if ItemCatalog.find(stack.item_id).kind == ItemDefinition.Kind.WEAPON:
		_weapons.equip(_selected)
	else:
		_interactor.use_slot(_selected)
	refresh()


func _drop_selected() -> void:
	_interactor.drop_slot(_selected)
	refresh()
