extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var animation_timer: float = 0.0
var current_frame: int = 0

func _ready() -> void:
	# 随机初始帧，让多棵树不同步
	current_frame = randi() % 4
	animation_timer = randf() * 0.3

func _process(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= 0.15:
		animation_timer = 0.0
		current_frame = (current_frame + 1) % 4

	sprite.frame = current_frame
