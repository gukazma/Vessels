class_name Player
extends CharacterBody2D

# ── 状态机 ──────────────────────────────────────────────────
enum State { IDLE, WALK }

# ── 常量 ────────────────────────────────────────────────────
const SPEED := 80.0

# ── 运行时变量 ───────────────────────────────────────────────
var state            := State.IDLE
var facing           := "front"          # "front" | "back" | "left" | "right"
var player_direction := Vector2.DOWN     # 供后续动作状态（chopping/tilling 等）使用

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ────────────────────────────────────────────────────────────
func _ready() -> void:
	sprite.play("idle_front")

func _physics_process(_delta: float) -> void:
	_handle_movement()
	_update_animation()

# ── 移动 ─────────────────────────────────────────────────────
func _handle_movement() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if dir.length_squared() > 0.0:
		state    = State.WALK
		velocity = dir.normalized() * SPEED
		# 优先水平方向判定朝向
		if abs(dir.x) >= abs(dir.y):
			facing           = "right" if dir.x > 0 else "left"
			player_direction = Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
		else:
			facing           = "front" if dir.y > 0 else "back"
			player_direction = Vector2.DOWN if dir.y > 0 else Vector2.UP
	else:
		state    = State.IDLE
		velocity = Vector2.ZERO

	move_and_slide()

# ── 动画状态机 ────────────────────────────────────────────────
func _update_animation() -> void:
	var prefix := "walk" if state == State.WALK else "idle"
	var anim   := prefix + "_" + facing
	if sprite.animation != anim:
		sprite.play(anim)
