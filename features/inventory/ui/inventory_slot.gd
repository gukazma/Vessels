extends Button

@onready var _icon: TextureRect = $Icon
@onready var _quantity: Label = $Quantity
@onready var _number: Label = $Number
@onready var _equipped: Label = $Equipped


func display(index: int, stack: ItemStack, selected: bool, equipped: bool) -> void:
	_number.text = "%02d" % (index + 1)
	_equipped.visible = equipped
	button_pressed = selected
	_icon.visible = stack != null
	_quantity.text = "-"
	tooltip_text = "Empty slot"
	if stack == null:
		return
	var item: ItemDefinition = ItemCatalog.find(stack.item_id)
	_icon.texture = item.icon
	tooltip_text = item.display_name
	if item.magazine_size > 0:
		_quantity.text = "%d / %d" % [stack.loaded_ammo, item.magazine_size]
	elif item.kind == ItemDefinition.Kind.WEAPON:
		_quantity.text = "MELEE"
	else:
		_quantity.text = "x%d" % stack.quantity
