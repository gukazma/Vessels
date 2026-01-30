# entity.gd
# 实体基类 - 所有游戏实体的基础类
# 包含生命值、移动、受伤等基本功能
class_name Entity
extends CharacterBody2D

## ==================== 信号 ====================

## 受到伤害
signal damaged(amount: float, attacker: Node)

## 生命值变化
signal health_changed(current: float, max_hp: float)

## 死亡
signal died()

## 移动状态变化
signal movement_state_changed(is_moving: bool)

## ==================== 导出变量 ====================

## 最大生命值
@export var max_health: float = 100.0

## 移动速度 (像素/秒)
@export var move_speed: float = 100.0

## 是否无敌
@export var invincible: bool = false

## 受伤后无敌时间 (秒)
@export var invincible_duration: float = 0.5

## ==================== 状态变量 ====================

## 当前生命值
var current_health: float = 100.0:
	set(value):
		var old_value = current_health
		current_health = clampf(value, 0, max_health)
		if current_health != old_value:
			health_changed.emit(current_health, max_health)
			if current_health <= 0:
				_on_death()

## 是否存活
var is_alive: bool = true

## 是否正在移动
var is_moving: bool = false

## 移动方向
var move_direction: Vector2 = Vector2.ZERO

## 朝向 (用于精灵翻转等)
var facing_direction: Vector2 = Vector2.DOWN

## 是否处于无敌状态
var is_invincible: bool = false

## 移动速度修正系数
var speed_modifier: float = 1.0

## ==================== 私有变量 ====================

## 无敌计时器
var _invincible_timer: float = 0.0

## ==================== 生命周期 ====================

func _ready() -> void:
	# 初始化生命值
	current_health = max_health
	_on_entity_ready()


func _physics_process(delta: float) -> void:
	# 处理无敌时间
	if is_invincible and _invincible_timer > 0:
		_invincible_timer -= delta
		if _invincible_timer <= 0:
			is_invincible = false

	# 处理移动
	if is_alive:
		_process_movement(delta)


## ==================== 可重写方法 ====================

## 实体初始化完成时调用 (子类重写)
func _on_entity_ready() -> void:
	pass


## 处理移动逻辑 (子类可重写)
func _process_movement(_delta: float) -> void:
	if move_direction != Vector2.ZERO:
		# 计算实际速度
		var actual_speed = move_speed * speed_modifier
		velocity = move_direction.normalized() * actual_speed

		# 更新朝向
		_update_facing_direction()

		# 移动
		move_and_slide()

		# 更新移动状态
		if not is_moving:
			is_moving = true
			movement_state_changed.emit(true)
	else:
		velocity = Vector2.ZERO
		if is_moving:
			is_moving = false
			movement_state_changed.emit(false)


## 更新朝向
func _update_facing_direction() -> void:
	if move_direction != Vector2.ZERO:
		# 使用移动方向作为朝向
		facing_direction = move_direction.normalized()


## 死亡时调用 (子类可重写)
func _on_death() -> void:
	if is_alive:
		is_alive = false
		velocity = Vector2.ZERO
		died.emit()


## ==================== 公共方法 ====================

## 设置移动方向
func set_move_direction(direction: Vector2) -> void:
	move_direction = direction


## 停止移动
func stop_moving() -> void:
	move_direction = Vector2.ZERO


## 受到伤害
func take_damage(amount: float, attacker: Node = null) -> void:
	# 检查无敌状态
	if invincible or is_invincible:
		return

	# 检查是否存活
	if not is_alive:
		return

	# 应用伤害
	var actual_damage = _calculate_damage(amount, attacker)
	current_health -= actual_damage

	# 发送信号
	damaged.emit(actual_damage, attacker)

	# 通知事件总线
	if EventBus:
		EventBus.entity_damaged.emit(self, actual_damage, attacker)

	# 触发无敌时间
	if invincible_duration > 0:
		is_invincible = true
		_invincible_timer = invincible_duration


## 计算实际伤害 (子类可重写以添加防御等逻辑)
func _calculate_damage(amount: float, _attacker: Node) -> float:
	return amount


## 治疗
func heal(amount: float) -> void:
	if not is_alive:
		return

	current_health = minf(current_health + amount, max_health)


## 完全恢复生命
func heal_full() -> void:
	current_health = max_health


## 设置速度修正系数
func set_speed_modifier(modifier: float) -> void:
	speed_modifier = maxf(0.0, modifier)


## 重置速度修正
func reset_speed_modifier() -> void:
	speed_modifier = 1.0


## 获取生命值百分比
func get_health_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


## 检查是否满血
func is_full_health() -> bool:
	return current_health >= max_health


## 复活 (用于特殊情况)
func revive(health_percent: float = 1.0) -> void:
	is_alive = true
	current_health = max_health * clampf(health_percent, 0.1, 1.0)


## 瞬移到指定位置
func teleport_to(target_position: Vector2) -> void:
	global_position = target_position


## 获取到目标的方向
func get_direction_to(target: Node2D) -> Vector2:
	return (target.global_position - global_position).normalized()


## 获取到目标的距离
func get_distance_to(target: Node2D) -> float:
	return global_position.distance_to(target.global_position)


## 判断目标是否在指定范围内
func is_in_range(target: Node2D, range_distance: float) -> bool:
	return get_distance_to(target) <= range_distance


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	return {
		"position": {"x": global_position.x, "y": global_position.y},
		"health": current_health,
		"max_health": max_health,
		"is_alive": is_alive
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		var pos = data["position"]
		global_position = Vector2(pos.get("x", 0), pos.get("y", 0))

	max_health = data.get("max_health", max_health)
	current_health = data.get("health", max_health)
	is_alive = data.get("is_alive", true)
