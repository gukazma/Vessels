# player_stats.gd
# 玩家状态管理 - HP/Hunger/Stamina
# 处理饥饿衰减、体力恢复、饥饿惩罚等
class_name PlayerStats
extends Node

## ==================== 信号 ====================

## 属性变化
signal stat_changed(stat_name: String, current: float, max_value: float)

## 饥饿警告
signal hunger_warning(level: int)  # 1=低, 2=危险, 3=饥饿

## 体力耗尽
signal stamina_depleted()

## ==================== 导出变量 ====================

## 最大生命值
@export var max_hp: float = 100.0

## 最大饥饿度
@export var max_hunger: float = 100.0

## 最大体力
@export var max_stamina: float = 100.0

## 饥饿衰减速率 (每游戏小时)
@export var hunger_decay_per_hour: float = 2.0

## 体力恢复速率 (每秒，静止时)
@export var stamina_regen_per_second: float = 1.0

## 体力恢复速率 (每秒，移动时)
@export var stamina_regen_while_moving: float = 0.3

## 饥饿伤害 (饥饿=0时每秒扣血)
@export var starvation_damage_per_second: float = 1.0

## ==================== 状态变量 ====================

## 当前生命值
var current_hp: float = 100.0:
	set(value):
		var old_value = current_hp
		current_hp = clampf(value, 0, max_hp)
		if current_hp != old_value:
			_emit_stat_changed("hp", current_hp, max_hp)

## 当前饥饿度
var current_hunger: float = 100.0:
	set(value):
		var old_value = current_hunger
		current_hunger = clampf(value, 0, max_hunger)
		if current_hunger != old_value:
			_emit_stat_changed("hunger", current_hunger, max_hunger)
			_check_hunger_warning()

## 当前体力
var current_stamina: float = 100.0:
	set(value):
		var old_value = current_stamina
		current_stamina = clampf(value, 0, max_stamina)
		if current_stamina != old_value:
			_emit_stat_changed("stamina", current_stamina, max_stamina)
			if current_stamina <= 0 and old_value > 0:
				stamina_depleted.emit()

## ==================== 私有变量 ====================

## 父节点玩家引用
var _player: Player = null

## 上次的饥饿警告等级
var _last_hunger_warning: int = 0

## ==================== 生命周期 ====================

func _ready() -> void:
	# 获取父节点玩家
	_player = get_parent() as Player

	# 初始化属性
	current_hp = max_hp
	current_hunger = max_hunger
	current_stamina = max_stamina

	# 连接事件总线
	_connect_event_bus()

	print("[PlayerStats] 玩家状态系统已初始化")


func _process(delta: float) -> void:
	if not _player or not _player.is_alive:
		return

	# 处理体力恢复
	_process_stamina_regen(delta)

	# 处理饥饿惩罚
	_process_starvation(delta)


## ==================== 事件总线连接 ====================

func _connect_event_bus() -> void:
	if not EventBus:
		return

	# 连接时间信号
	EventBus.time_tick.connect(_on_time_tick)


func _on_time_tick(hour: int, minute: int) -> void:
	# 每游戏小时处理饥饿衰减 (在整点时)
	if minute == 0:
		_process_hunger_decay()


## ==================== 饥饿处理 ====================

func _process_hunger_decay() -> void:
	# 每游戏小时减少饥饿度
	current_hunger -= hunger_decay_per_hour

	if current_hunger <= 0:
		if EventBus:
			EventBus.emit_warning("你已经饿坏了!")


func _check_hunger_warning() -> void:
	var warning_level = 0

	if current_hunger <= 10:
		warning_level = 3  # 饥饿
	elif current_hunger <= 25:
		warning_level = 2  # 危险
	elif current_hunger <= 40:
		warning_level = 1  # 低

	if warning_level != _last_hunger_warning and warning_level > 0:
		_last_hunger_warning = warning_level
		hunger_warning.emit(warning_level)

		# 发送消息
		if EventBus:
			match warning_level:
				1:
					EventBus.emit_warning("你开始感到饥饿了")
				2:
					EventBus.emit_warning("你非常饿了!")
				3:
					EventBus.emit_error("你快要饿死了!")


func _process_starvation(delta: float) -> void:
	# 饥饿度为0时持续扣血
	if current_hunger <= 0:
		take_damage(starvation_damage_per_second * delta)


## ==================== 体力处理 ====================

func _process_stamina_regen(delta: float) -> void:
	if current_stamina >= max_stamina:
		return

	# 根据移动状态选择恢复速率
	var regen_rate = stamina_regen_per_second
	if _player and _player.is_moving:
		regen_rate = stamina_regen_while_moving

	# 跑步时不恢复体力
	if _player and _player.is_running:
		return

	current_stamina += regen_rate * delta


## ==================== 公共方法 ====================

## 消耗体力
## 返回是否成功消耗
func consume_stamina(amount: float) -> bool:
	if current_stamina < amount:
		return false

	current_stamina -= amount
	return true


## 恢复生命
func heal(amount: float) -> void:
	current_hp += amount


## 受到伤害
func take_damage(amount: float) -> void:
	current_hp -= amount

	# 同步到玩家 Entity
	if _player:
		_player.current_health = current_hp

	# 检查死亡
	if current_hp <= 0 and _player:
		_player.current_health = 0


## 恢复饥饿度
func restore_hunger(amount: float) -> void:
	current_hunger += amount


## 恢复体力
func restore_stamina(amount: float) -> void:
	current_stamina += amount


## 完全恢复
func restore_all() -> void:
	current_hp = max_hp
	current_hunger = max_hunger
	current_stamina = max_stamina


## 获取生命百分比
func get_hp_percent() -> float:
	return current_hp / max_hp if max_hp > 0 else 0.0


## 获取饥饿度百分比
func get_hunger_percent() -> float:
	return current_hunger / max_hunger if max_hunger > 0 else 0.0


## 获取体力百分比
func get_stamina_percent() -> float:
	return current_stamina / max_stamina if max_stamina > 0 else 0.0


## 检查是否饥饿
func is_hungry() -> bool:
	return current_hunger < 40


## 检查是否快饿死
func is_starving() -> bool:
	return current_hunger <= 0


## 检查是否疲劳
func is_exhausted() -> bool:
	return current_stamina < 20


## ==================== 私有方法 ====================

func _emit_stat_changed(stat_name: String, current: float, max_value: float) -> void:
	stat_changed.emit(stat_name, current, max_value)

	# 同步到事件总线
	if EventBus:
		EventBus.player_stat_changed.emit(stat_name, current, max_value)


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	return {
		"hp": current_hp,
		"max_hp": max_hp,
		"hunger": current_hunger,
		"max_hunger": max_hunger,
		"stamina": current_stamina,
		"max_stamina": max_stamina
	}


func load_save_data(data: Dictionary) -> void:
	max_hp = data.get("max_hp", 100.0)
	max_hunger = data.get("max_hunger", 100.0)
	max_stamina = data.get("max_stamina", 100.0)

	current_hp = data.get("hp", max_hp)
	current_hunger = data.get("hunger", max_hunger)
	current_stamina = data.get("stamina", max_stamina)

	print("[PlayerStats] 存档数据已加载")
