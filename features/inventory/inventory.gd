class_name SurvivorInventory
extends Node
## All mutations notify once. Callers receive snapshots, never mutable internal slots.

signal changed
@export_range(1, 48) var capacity: int = 12
var _slots: Array[ItemStack] = []


func _ready() -> void:
	_slots.resize(capacity)


func get_slot(index: int) -> ItemStack:
	if index < 0 or index >= _slots.size() or _slots[index] == null:
		return null
	return _slots[index].copy()


func used_slots() -> int:
	var count: int = 0
	for stack: ItemStack in _slots:
		if stack != null:
			count += 1
	return count


func count_item(id: StringName) -> int:
	var total: int = 0
	for stack: ItemStack in _slots:
		if stack != null and stack.item_id == id:
			total += stack.quantity
	return total


func find_slot(id: StringName) -> int:
	for index: int in range(_slots.size()):
		if _slots[index] != null and _slots[index].item_id == id:
			return index
	return -1


func add_item(id: StringName, quantity: int, loaded_ammo: int = 0) -> int:
	var definition: ItemDefinition = ItemCatalog.find(id)
	if definition == null or quantity <= 0:
		return 0
	var remaining: int = quantity
	if definition.max_stack > 1:
		for stack: ItemStack in _slots:
			if stack != null and stack.item_id == id:
				var moved: int = mini(remaining, definition.max_stack - stack.quantity)
				stack.quantity += moved
				remaining -= moved
	for index: int in range(_slots.size()):
		if remaining == 0:
			break
		if _slots[index] == null:
			var moved: int = mini(remaining, definition.max_stack)
			_slots[index] = ItemStack.new(id, moved, clampi(loaded_ammo, 0, definition.magazine_size))
			remaining -= moved
	if remaining != quantity:
		changed.emit()
	return quantity - remaining


func take_slot(index: int) -> ItemStack:
	var result: ItemStack = get_slot(index)
	if result != null:
		_slots[index] = null
		changed.emit()
	return result


func consume_at(index: int, amount: int = 1) -> bool:
	var stack: ItemStack = get_slot(index)
	if stack == null or amount <= 0 or stack.quantity < amount:
		return false
	_slots[index].quantity -= amount
	if _slots[index].quantity == 0:
		_slots[index] = null
	changed.emit()
	return true


func consume_loaded_round(index: int) -> bool:
	var stack: ItemStack = get_slot(index)
	if stack == null or stack.loaded_ammo < 1:
		return false
	_slots[index].loaded_ammo -= 1
	changed.emit()
	return true


func reload_weapon(index: int) -> int:
	var stack: ItemStack = get_slot(index)
	if stack == null:
		return 0
	var definition: ItemDefinition = ItemCatalog.find(stack.item_id)
	if definition.kind != ItemDefinition.Kind.WEAPON or definition.magazine_size == 0:
		return 0
	var amount: int = mini(definition.magazine_size - stack.loaded_ammo, count_item(definition.ammo_id))
	if amount <= 0:
		return 0
	var remaining: int = amount
	for slot_index: int in range(_slots.size()):
		var reserve: ItemStack = _slots[slot_index]
		if reserve == null or reserve.item_id != definition.ammo_id:
			continue
		var consumed: int = mini(remaining, reserve.quantity)
		reserve.quantity -= consumed
		remaining -= consumed
		if reserve.quantity == 0:
			_slots[slot_index] = null
		if remaining == 0:
			break
	_slots[index].loaded_ammo += amount
	changed.emit()
	return amount
