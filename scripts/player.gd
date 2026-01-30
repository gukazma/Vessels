extends CharacterBody2D

@export var speed: float = 150.0

@onready var sprite: Sprite2D = $Sprite2D

var animation_timer: float = 0.0
var current_frame: int = 0
var is_walking: bool = false

func _physics_process(delta: float) -> void:
	# 获取输入方向
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	# 标准化方向向量，防止斜向移动更快
	if direction.length() > 1.0:
		direction = direction.normalized()

	# 设置速度
	velocity = direction * speed

	# 播放动画
	if velocity.length() > 0:
		is_walking = true
		# 根据水平方向翻转精灵
		if velocity.x != 0:
			sprite.flip_h = velocity.x < 0
	else:
		is_walking = false
		current_frame = 0

	# 简单的帧动画
	if is_walking:
		animation_timer += delta
		if animation_timer >= 0.15:
			animation_timer = 0.0
			current_frame = (current_frame + 1) % 4

	sprite.frame = current_frame

	move_and_slide()
