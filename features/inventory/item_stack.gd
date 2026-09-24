class_name ItemStack
extends RefCounted

var item_id: StringName
var quantity: int
var loaded_ammo: int


func _init(id: StringName = &"", amount: int = 0, loaded: int = 0) -> void:
	item_id = id
	quantity = amount
	loaded_ammo = loaded


func copy() -> ItemStack:
	return ItemStack.new(item_id, quantity, loaded_ammo)
