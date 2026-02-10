extends CharacterBody2D

const SPEED := 120.0

var facing := "down"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 0:
		direction = direction.normalized()
		velocity = direction * SPEED
		facing = _get_facing(direction)
		animated_sprite.play("walk_" + facing)
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("idle_" + facing)

	move_and_slide()

func _get_facing(dir: Vector2) -> String:
	# Use angle to determine 8-direction facing
	var angle := dir.angle()
	# Normalize to 0..TAU
	if angle < 0:
		angle += TAU

	# 8 directions, each covering 45 degrees (PI/4)
	# Right = 0, Down-Right = PI/4, Down = PI/2, etc.
	var index := int(round(angle / (PI / 4.0))) % 8

	var directions := [
		"right",      # 0
		"down_right", # 1
		"down",       # 2
		"down_left",  # 3
		"left",       # 4
		"up_left",    # 5
		"up",         # 6
		"up_right",   # 7
	]
	return directions[index]
