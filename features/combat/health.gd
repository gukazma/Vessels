class_name HealthComponent
extends Node

signal changed
signal depleted
@export var maximum: int = 100
var current: int = 100


func _ready() -> void:
	current = maximum


func take_damage(amount: int) -> void:
	if amount <= 0 or current <= 0:
		return
	current = maxi(0, current - amount)
	changed.emit()
	if current == 0:
		depleted.emit()


func heal(amount: int) -> int:
	var restored: int = mini(maxi(amount, 0), maximum - current)
	if restored > 0:
		current += restored
		changed.emit()
	return restored
