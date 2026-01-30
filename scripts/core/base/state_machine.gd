# state_machine.gd
# 状态机 - 通用的有限状态机实现
# 用于管理实体的状态切换和更新
class_name StateMachine
extends Node

## ==================== 信号 ====================

## 状态切换
signal state_changed(from_state: String, to_state: String)

## ==================== 导出变量 ====================

## 初始状态名称
@export var initial_state: String = ""

## 是否启用调试日志
@export var debug_mode: bool = false

## ==================== 变量 ====================

## 当前状态
var current_state: State = null

## 当前状态名称
var current_state_name: String = ""

## 上一个状态名称
var previous_state_name: String = ""

## 状态字典
var states: Dictionary = {}

## 状态机拥有者 (通常是Entity)
var owner_entity: Node = null

## 是否已初始化
var is_initialized: bool = false

## ==================== 生命周期 ====================

func _ready() -> void:
	# 获取拥有者
	owner_entity = get_parent()

	# 等待一帧，确保所有子节点都已准备好
	await owner_entity.ready

	# 收集所有状态子节点
	_collect_states()

	# 初始化到初始状态
	if not initial_state.is_empty() and states.has(initial_state):
		_change_state(initial_state)
	elif states.size() > 0:
		# 如果没有指定初始状态，使用第一个状态
		_change_state(states.keys()[0])

	is_initialized = true


func _process(delta: float) -> void:
	if current_state and is_initialized:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state and is_initialized:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state and is_initialized:
		current_state.handle_input(event)


## ==================== 公共方法 ====================

## 切换到指定状态
func change_state(new_state_name: String, params: Dictionary = {}) -> void:
	if not states.has(new_state_name):
		if debug_mode:
			print("[StateMachine] 状态不存在: %s" % new_state_name)
		return

	if current_state_name == new_state_name:
		if debug_mode:
			print("[StateMachine] 已经是当前状态: %s" % new_state_name)
		return

	_change_state(new_state_name, params)


## 获取当前状态名称
func get_current_state() -> String:
	return current_state_name


## 获取上一个状态名称
func get_previous_state() -> String:
	return previous_state_name


## 检查是否是指定状态
func is_state(state_name: String) -> bool:
	return current_state_name == state_name


## 检查是否是指定状态之一
func is_state_any(state_names: Array) -> bool:
	return current_state_name in state_names


## 添加状态
func add_state(state_name: String, state_node: State) -> void:
	states[state_name] = state_node
	state_node.state_machine = self
	state_node.entity = owner_entity


## 移除状态
func remove_state(state_name: String) -> void:
	if states.has(state_name):
		states.erase(state_name)


## 检查状态是否存在
func has_state(state_name: String) -> bool:
	return states.has(state_name)


## 获取所有状态名称
func get_state_names() -> Array:
	return states.keys()


## ==================== 私有方法 ====================

## 收集所有状态子节点
func _collect_states() -> void:
	for child in get_children():
		if child is State:
			var state_name = child.name.to_snake_case()
			states[state_name] = child
			child.state_machine = self
			child.entity = owner_entity
			if debug_mode:
				print("[StateMachine] 注册状态: %s" % state_name)


## 内部状态切换
func _change_state(new_state_name: String, params: Dictionary = {}) -> void:
	# 退出当前状态
	if current_state:
		current_state.exit()
		previous_state_name = current_state_name

	# 切换到新状态
	current_state_name = new_state_name
	current_state = states[new_state_name]

	# 进入新状态
	current_state.enter(params)

	# 发送信号
	state_changed.emit(previous_state_name, current_state_name)

	if debug_mode:
		print("[StateMachine] 状态切换: %s -> %s" % [previous_state_name, current_state_name])


## ==================== 状态基类 ====================

## 状态基类 - 所有状态都应该继承此类
class State:
	extends Node

	## 状态机引用
	var state_machine: StateMachine = null

	## 实体引用
	var entity: Node = null

	## 进入状态时调用
	func enter(_params: Dictionary = {}) -> void:
		pass

	## 退出状态时调用
	func exit() -> void:
		pass

	## 每帧更新 (对应_process)
	func update(_delta: float) -> void:
		pass

	## 物理帧更新 (对应_physics_process)
	func physics_update(_delta: float) -> void:
		pass

	## 处理输入
	func handle_input(_event: InputEvent) -> void:
		pass

	## 切换到另一个状态的便捷方法
	func change_state(new_state: String, params: Dictionary = {}) -> void:
		if state_machine:
			state_machine.change_state(new_state, params)
