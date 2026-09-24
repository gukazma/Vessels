class_name ItemPickup
extends Area2D

@export var item_id: StringName = &"ammo_9mm"
@export_range(1, 999) var quantity: int = 1
@export var loaded_ammo: int = 0
@onready var _icon: Sprite2D = $Icon


func _ready() -> void:
	var item: ItemDefinition = ItemCatalog.find(item_id)
	assert(item != null, "Unknown pickup item: " + str(item_id))
	_icon.texture = item.icon
	queue_redraw()


func collect(inventory: SurvivorInventory) -> int:
	if quantity <= 0:
		return 0
	var collected: int = inventory.add_item(item_id, quantity, loaded_ammo)
	quantity -= collected
	if quantity == 0:
		collision_layer = 0
		queue_free()
	return collected


func _draw() -> void:
	draw_set_transform(Vector2(2, 6), 0, Vector2(1, 0.35))
	draw_circle(Vector2.ZERO, 11, Color(0.20, 0.31, 0.31, 0.32))
	draw_set_transform(Vector2.ZERO)
	# A folded supply cloth anchors the inventory icon to the pavement.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, 0), Vector2(-7, -7), Vector2(8, -6),
		Vector2(11, 3), Vector2(7, 7), Vector2(-9, 6)
	]), Color("b8bea1"))
	draw_line(Vector2(-9, 0), Vector2(-6, -5), Color("e1d9b6"))
	draw_line(Vector2(-6, -5), Vector2(7, -4), Color("ded9b6"))
	draw_line(Vector2(-3, -18), Vector2(0, -15), Color("637d6e"), 3)
	draw_line(Vector2(0, -15), Vector2(3, -18), Color("637d6e"), 3)
	draw_line(Vector2(-3, -18), Vector2(0, -15), Color("fff2cc"))
	draw_line(Vector2(0, -15), Vector2(3, -18), Color("fff2cc"))
