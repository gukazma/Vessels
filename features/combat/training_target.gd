extends StaticBody2D
## A reusable damage receiver. The target resets after a short knockout.

@export var maximum_health: int = 100
@export var respawn_delay: float = 3.0
var current_health: int = 100
var _reset_remaining: float = 0.0
var _flash_remaining: float = 0.0
@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	current_health = maximum_health


func hit_position() -> Vector2:
	return global_position + Vector2(0, -18)


func take_damage(amount: int) -> void:
	if current_health <= 0 or amount <= 0:
		return
	current_health = maxi(0, current_health - amount)
	_flash_remaining = 0.13
	if current_health == 0:
		collision_layer = 0
		_reset_remaining = respawn_delay
	queue_redraw()


func _physics_process(delta: float) -> void:
	_flash_remaining = maxf(0, _flash_remaining - delta)
	if _reset_remaining > 0:
		_reset_remaining = maxf(0, _reset_remaining - delta)
		if _reset_remaining == 0:
			current_health = maximum_health
			collision_layer = 4
			queue_redraw()
	_sprite.modulate = Color(1.7, 1.1, 0.8) if _flash_remaining > 0 else Color.WHITE
	_sprite.modulate.a = 0.25 if current_health == 0 else 1.0


func _draw() -> void:
	draw_rect(Rect2(-13, -49, 26, 3), Color("5c7c71"))
	draw_rect(Rect2(-12, -48, 24.0 * current_health / maximum_health, 1), Color("f5e4ad"))
