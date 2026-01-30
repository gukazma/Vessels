# bed.gd
# 床 - 睡觉跳过时间
# 继承 Interactable 基类
class_name Bed
extends Interactable

## ==================== 信号 ====================

## 开始睡觉
signal sleep_started()

## 睡眠结束
signal sleep_ended(hours_slept: int)

## 睡眠被打断
signal sleep_interrupted(reason: String)

## ==================== 导出变量 ====================

## 床的名称
@export var bed_name: String = "床"

## 是否属于玩家
@export var is_player_owned: bool = false

## 睡眠恢复效果 (每小时恢复)
@export var hp_regen_per_hour: float = 5.0
@export var stamina_regen_per_hour: float = 20.0

## 最早起床时间 (默认6点)
@export var wake_up_hour: int = 6

## 最早可睡觉时间 (默认21点)
@export var sleep_available_hour: int = 21

## 是否可以白天睡觉
@export var allow_daytime_sleep: bool = false

## ==================== 状态变量 ====================

## 是否正在睡觉
var is_sleeping: bool = false

## 睡眠开始时间
var sleep_start_hour: int = 0

## 当前睡眠的玩家
var sleeping_player: Node = null

## ==================== 节点引用 ====================

## 床精灵
@onready var bed_sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## 动画播放器
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## ==================== 生命周期 ====================

func _on_interactable_ready() -> void:
	# 添加到床组
	add_to_group("beds")
	add_to_group("interactables")

	# 连接事件总线
	_connect_event_bus()

	print("[Bed] 床已初始化: %s" % bed_name)


## ==================== 交互实现 ====================

func _execute_interaction(player: Node) -> void:
	if is_sleeping:
		wake_up("手动起床")
	else:
		_try_sleep(player)


func _can_interact(_player: Node) -> bool:
	if is_sleeping:
		return true  # 允许起床

	return is_interactable and _can_sleep()


func _get_interaction_prompt() -> String:
	if is_sleeping:
		return "按 E 键起床"

	if not _can_sleep():
		if not allow_daytime_sleep:
			return "现在还不能睡觉 (夜间可用)"
		return "暂时无法使用"

	return "按 E 键睡觉"


## ==================== 睡眠操作 ====================

## 尝试睡觉
func _try_sleep(player: Node) -> void:
	if not _can_sleep():
		if EventBus:
			EventBus.emit_warning("现在还不能睡觉!")
		return

	# 检查危险
	if _is_danger_nearby():
		if EventBus:
			EventBus.emit_warning("附近有危险，无法入睡!")
		return

	# 开始睡觉
	start_sleep(player)


## 开始睡觉
func start_sleep(player: Node) -> void:
	if is_sleeping:
		return

	is_sleeping = true
	sleeping_player = player

	# 记录睡眠开始时间
	if GameManager:
		sleep_start_hour = GameManager.current_hour

	sleep_started.emit()

	# 禁用玩家控制
	if player.has_method("set_process"):
		player.set_process(false)
		player.set_physics_process(false)

	# 开始时间快进
	_start_time_skip()

	# 更新视觉
	_update_visual()

	if EventBus:
		EventBus.emit_info("开始睡觉...")


## 起床
func wake_up(reason: String = "") -> void:
	if not is_sleeping:
		return

	# 计算睡眠时长
	var hours_slept = _calculate_hours_slept()

	# 应用恢复效果
	_apply_sleep_recovery(hours_slept)

	is_sleeping = false

	# 恢复玩家控制
	if sleeping_player:
		if sleeping_player.has_method("set_process"):
			sleeping_player.set_process(true)
			sleeping_player.set_physics_process(true)

	sleeping_player = null

	# 停止时间快进
	_stop_time_skip()

	# 更新视觉
	_update_visual()

	if reason.is_empty():
		sleep_ended.emit(hours_slept)
		if EventBus:
			EventBus.emit_info("睡了 %d 小时，精神焕发!" % hours_slept)
	else:
		sleep_interrupted.emit(reason)
		if EventBus:
			EventBus.emit_warning("睡眠被打断: %s" % reason)


## ==================== 时间处理 ====================

func _connect_event_bus() -> void:
	if not EventBus:
		return

	EventBus.time_tick.connect(_on_time_tick)
	EventBus.combat_started.connect(_on_combat_started)


func _on_time_tick(hour: int, _minute: int) -> void:
	if not is_sleeping:
		return

	# 检查是否该起床了
	if hour >= wake_up_hour and hour < sleep_available_hour:
		wake_up()


func _on_combat_started() -> void:
	if is_sleeping:
		wake_up("战斗警报!")


func _start_time_skip() -> void:
	# 使用时间系统的快进功能
	if has_node("/root/TimeSystem"):
		var time_system = get_node("/root/TimeSystem")
		if time_system.has_method("start_fast_forward"):
			time_system.start_fast_forward(20.0)  # 20倍速


func _stop_time_skip() -> void:
	if has_node("/root/TimeSystem"):
		var time_system = get_node("/root/TimeSystem")
		if time_system.has_method("stop_fast_forward"):
			time_system.stop_fast_forward()


## ==================== 辅助方法 ====================

func _can_sleep() -> bool:
	if allow_daytime_sleep:
		return true

	if not GameManager:
		return true

	# 检查是否是夜间
	var hour = GameManager.current_hour
	return hour >= sleep_available_hour or hour < wake_up_hour


func _is_danger_nearby() -> bool:
	# 检查附近是否有敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node2D:
			var distance = global_position.distance_to(enemy.global_position)
			if distance < 200:
				return true
	return false


func _calculate_hours_slept() -> int:
	if not GameManager:
		return 8

	var current_hour = GameManager.current_hour
	var hours = 0

	if current_hour >= sleep_start_hour:
		# 同一天
		hours = current_hour - sleep_start_hour
	else:
		# 跨天
		hours = (24 - sleep_start_hour) + current_hour

	return maxi(hours, 1)


func _apply_sleep_recovery(hours_slept: int) -> void:
	if not sleeping_player:
		return

	# 获取玩家状态组件
	if sleeping_player.has_node("PlayerStats"):
		var stats = sleeping_player.get_node("PlayerStats")

		# 恢复生命
		var hp_recovery = hp_regen_per_hour * hours_slept
		if stats.has_method("heal"):
			stats.heal(hp_recovery)

		# 恢复体力
		var stamina_recovery = stamina_regen_per_hour * hours_slept
		if stats.has_method("restore_stamina"):
			stats.restore_stamina(stamina_recovery)


func _update_visual() -> void:
	if not bed_sprite:
		return

	# 更新床的显示状态
	if is_sleeping:
		bed_sprite.frame = 1  # 有人睡觉
	else:
		bed_sprite.frame = 0  # 空床


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["bed_name"] = bed_name
	data["is_player_owned"] = is_player_owned
	data["is_sleeping"] = is_sleeping
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	bed_name = data.get("bed_name", "床")
	is_player_owned = data.get("is_player_owned", false)

	# 睡眠状态不从存档恢复
	is_sleeping = false
	_update_visual()
