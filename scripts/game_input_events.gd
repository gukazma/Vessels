# ── GameInputEvents ───────────────────────────────────────────
# 静态输入工具类，所有状态脚本通过它读取输入
#
# 为什么用静态类而不是在每个状态里直接调用 Input？
# → 集中管理输入逻辑，改按键映射只需改这一个文件
# → static var direction 跨调用保持，idle_state 和 walk_state
#   都读同一个 direction，不会出现不一致
# ─────────────────────────────────────────────────────────────
class_name GameInputEvents

# 当前帧的移动方向（由 movement_input() 写入）
static var direction: Vector2


# 读取方向输入，返回 Vector2.LEFT / RIGHT / UP / DOWN / ZERO
#
# 注意使用 if/elif（不是 if/if）：
# 同一帧只能有一个方向，不允许对角线移动
# 这是 farming RPG 的标准设计（对角线移动会让动画方向判断变复杂）
static func movement_input() -> Vector2:
	if Input.is_action_pressed("walk_left"):
		direction = Vector2.LEFT
	elif Input.is_action_pressed("walk_right"):
		direction = Vector2.RIGHT
	elif Input.is_action_pressed("walk_up"):
		direction = Vector2.UP
	elif Input.is_action_pressed("walk_down"):
		direction = Vector2.DOWN
	else:
		direction = Vector2.ZERO
	return direction


# 当前帧是否有任何方向输入
static func is_movement_input() -> bool:
	return direction != Vector2.ZERO


# 是否按下"使用工具"键
# 用 just_pressed（不是 pressed）：按一次触发一次，不会持续触发
static func use_tool() -> bool:
	return Input.is_action_just_pressed("hit")
