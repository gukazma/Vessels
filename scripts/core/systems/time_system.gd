# time_system.gd
# 时间系统 - 管理游戏内时间流逝
# 1 游戏小时 = 25 秒现实时间
# 1 游戏天 = 10 分钟现实时间
class_name TimeSystem
extends Node

## ==================== 常量 ====================

## 每游戏小时对应的现实秒数
const SECONDS_PER_GAME_HOUR: float = 25.0

## 每游戏分钟对应的现实秒数
const SECONDS_PER_GAME_MINUTE: float = SECONDS_PER_GAME_HOUR / 60.0

## 一天的开始时间 (小时)
const DAY_START_HOUR: int = 6

## 一天的结束时间 (小时) - 用于自动睡眠
const DAY_END_HOUR: int = 22

## ==================== 导出变量 ====================

## 时间流逝速度倍率 (1.0为正常速度)
@export var time_scale: float = 1.0

## 是否暂停时间
@export var is_paused: bool = false

## ==================== 变量 ====================

## 当前天数
var current_day: int = 1

## 当前小时 (0-23)
var current_hour: int = 6

## 当前分钟 (0-59)
var current_minute: int = 0

## 累计的现实时间 (秒)
var _accumulated_time: float = 0.0

## 上一次的时间段
var _last_time_period: String = ""

## 是否处于加速状态 (睡眠/工作时)
var _is_fast_forward: bool = false

## 加速倍率
var _fast_forward_multiplier: float = 10.0

## ==================== 信号 ====================

## 分钟变化
signal minute_changed(hour: int, minute: int)

## 小时变化
signal hour_changed(hour: int)

## 时间段变化
signal period_changed(period: String)

## ==================== 生命周期 ====================

func _ready() -> void:
	print("[TimeSystem] 时间系统已初始化")
	_last_time_period = get_time_period()


func _process(delta: float) -> void:
	if is_paused:
		return

	# 计算实际时间增量
	var actual_delta = delta * time_scale
	if _is_fast_forward:
		actual_delta *= _fast_forward_multiplier

	# 累计时间
	_accumulated_time += actual_delta

	# 检查是否过了一分钟
	while _accumulated_time >= SECONDS_PER_GAME_MINUTE:
		_accumulated_time -= SECONDS_PER_GAME_MINUTE
		_advance_minute()


## ==================== 公共方法 ====================

## 设置时间
func set_time(day: int, hour: int, minute: int = 0) -> void:
	current_day = max(1, day)
	current_hour = clampi(hour, 0, 23)
	current_minute = clampi(minute, 0, 59)

	# 同步到 GameManager
	if GameManager:
		GameManager.current_day = current_day
		GameManager.current_hour = current_hour
		GameManager.current_minute = current_minute

	# 发送时间tick
	_emit_time_tick()


## 获取格式化的时间字符串
func get_time_string() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


## 获取完整的日期时间字符串
func get_datetime_string() -> String:
	return "Day %d - %s" % [current_day, get_time_string()]


## 获取当前时间段
func get_time_period() -> String:
	if current_hour >= 5 and current_hour < 7:
		return "dawn"      # 黎明
	elif current_hour >= 7 and current_hour < 9:
		return "morning"   # 早晨
	elif current_hour >= 9 and current_hour < 12:
		return "forenoon"  # 上午
	elif current_hour >= 12 and current_hour < 13:
		return "noon"      # 中午
	elif current_hour >= 13 and current_hour < 18:
		return "afternoon" # 下午
	elif current_hour >= 18 and current_hour < 21:
		return "evening"   # 傍晚
	elif current_hour >= 21 and current_hour < 24:
		return "night"     # 夜晚
	else:
		return "midnight"  # 深夜


## 获取时间段中文名称
func get_time_period_cn() -> String:
	match get_time_period():
		"dawn": return "黎明"
		"morning": return "早晨"
		"forenoon": return "上午"
		"noon": return "中午"
		"afternoon": return "下午"
		"evening": return "傍晚"
		"night": return "夜晚"
		"midnight": return "深夜"
		_: return "未知"


## 暂停时间
func pause() -> void:
	is_paused = true


## 继续时间
func resume() -> void:
	is_paused = false


## 开始加速 (用于睡眠、工作等)
func start_fast_forward(multiplier: float = 10.0) -> void:
	_is_fast_forward = true
	_fast_forward_multiplier = multiplier


## 停止加速
func stop_fast_forward() -> void:
	_is_fast_forward = false


## 检查是否是夜间
func is_night() -> bool:
	return current_hour >= 21 or current_hour < 5


## 检查是否是白天
func is_day() -> bool:
	return current_hour >= 6 and current_hour < 18


## 检查是否是危险时间 (僵尸活跃时段)
func is_danger_time() -> bool:
	# 仅在末日后才有危险时间
	if GameManager and GameManager.phase == GameManager.GamePhase.PEACE:
		return false
	return current_hour >= 18 or current_hour < 7


## 获取到指定时间需要多少游戏分钟
func get_minutes_until(target_hour: int, target_minute: int = 0) -> int:
	var current_total = current_hour * 60 + current_minute
	var target_total = target_hour * 60 + target_minute

	if target_total <= current_total:
		# 跨天
		target_total += 24 * 60

	return target_total - current_total


## 等待到指定时间 (协程)
func wait_until(target_hour: int, target_minute: int = 0) -> void:
	while current_hour != target_hour or current_minute < target_minute:
		await get_tree().process_frame

		# 如果已经过了目标时间，退出
		if current_hour > target_hour:
			break
		if current_hour == target_hour and current_minute >= target_minute:
			break


## 快进到指定时间
func skip_to(target_hour: int, target_minute: int = 0) -> void:
	# 计算需要跨越多少分钟
	var minutes = get_minutes_until(target_hour, target_minute)

	# 直接设置时间
	var new_minute = current_minute + minutes
	var new_hour = current_hour + new_minute / 60
	new_minute = new_minute % 60

	var days_passed = new_hour / 24
	new_hour = new_hour % 24

	if days_passed > 0:
		current_day += days_passed
		if EventBus:
			EventBus.day_changed.emit(current_day)

	current_hour = new_hour
	current_minute = new_minute

	_emit_time_tick()


## ==================== 私有方法 ====================

## 推进一分钟
func _advance_minute() -> void:
	var old_hour = current_hour

	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		_advance_hour()

	# 发送信号
	minute_changed.emit(current_hour, current_minute)
	_emit_time_tick()

	# 检查时间段变化
	_check_period_change()


## 推进一小时
func _advance_hour() -> void:
	current_hour += 1
	if current_hour >= 24:
		current_hour = 0
		_advance_day()

	hour_changed.emit(current_hour)


## 推进一天
func _advance_day() -> void:
	current_day += 1
	print("[TimeSystem] 新的一天: Day %d" % current_day)

	# 同步到 GameManager
	if GameManager:
		GameManager.current_day = current_day

	# 通知事件总线
	if EventBus:
		EventBus.day_changed.emit(current_day)


## 发送时间tick信号
func _emit_time_tick() -> void:
	# 同步到 GameManager
	if GameManager:
		GameManager.current_hour = current_hour
		GameManager.current_minute = current_minute

	# 通知事件总线
	if EventBus:
		EventBus.time_tick.emit(current_hour, current_minute)


## 检查时间段变化
func _check_period_change() -> void:
	var new_period = get_time_period()
	if new_period != _last_time_period:
		_last_time_period = new_period
		period_changed.emit(new_period)

		# 通知事件总线
		if EventBus:
			EventBus.time_period_changed.emit(new_period)


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute,
		"accumulated_time": _accumulated_time
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	current_day = data.get("day", 1)
	current_hour = data.get("hour", 6)
	current_minute = data.get("minute", 0)
	_accumulated_time = data.get("accumulated_time", 0.0)

	_last_time_period = get_time_period()

	print("[TimeSystem] 存档数据已加载: Day %d, %s" % [current_day, get_time_string()])
