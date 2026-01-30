# interactable.gd
# 可交互物基类 - 所有可交互物体的基础类
# 包含交互范围、高亮显示、交互方法等
class_name Interactable
extends Area2D

## ==================== 信号 ====================

## 玩家进入交互范围
signal player_entered()

## 玩家离开交互范围
signal player_exited()

## 交互执行
signal interacted(player: Node)

## 交互完成
signal interaction_completed()

## ==================== 导出变量 ====================

## 交互提示文字
@export var interaction_prompt: String = "按 E 键交互"

## 是否可交互
@export var is_interactable: bool = true

## 交互冷却时间 (秒)
@export var interaction_cooldown: float = 0.5

## 是否一次性交互 (交互后禁用)
@export var one_time_interaction: bool = false

## 高亮颜色 (玩家在范围内时)
@export var highlight_color: Color = Color(1.2, 1.2, 1.2, 1.0)

## ==================== 变量 ====================

## 玩家是否在交互范围内
var player_in_range: bool = false

## 当前在范围内的玩家引用
var current_player: Node = null

## 交互冷却计时器
var _cooldown_timer: float = 0.0

## 是否正在高亮
var _is_highlighted: bool = false

## 原始调制颜色 (用于恢复)
var _original_modulate: Color = Color.WHITE

## ==================== 节点引用 ====================

## 精灵节点 (用于高亮显示，子类可设置)
var sprite_node: Node2D = null

## ==================== 生命周期 ====================

func _ready() -> void:
	# 连接碰撞信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 尝试查找精灵节点
	_find_sprite_node()

	# 保存原始颜色
	if sprite_node:
		_original_modulate = sprite_node.modulate

	# 子类初始化
	_on_interactable_ready()


func _process(delta: float) -> void:
	# 更新冷却计时器
	if _cooldown_timer > 0:
		_cooldown_timer -= delta


func _unhandled_input(event: InputEvent) -> void:
	# 检查交互输入
	if player_in_range and is_interactable and _cooldown_timer <= 0:
		if event.is_action_pressed("interact"):
			_perform_interaction()


## ==================== 可重写方法 ====================

## 初始化完成时调用 (子类重写)
func _on_interactable_ready() -> void:
	pass


## 执行交互逻辑 (子类必须重写)
func _execute_interaction(_player: Node) -> void:
	# 子类实现具体交互逻辑
	pass


## 检查是否可以交互 (子类可重写)
func _can_interact(_player: Node) -> bool:
	return is_interactable


## 获取交互提示 (子类可重写)
func _get_interaction_prompt() -> String:
	return interaction_prompt


## ==================== 公共方法 ====================

## 手动触发交互
func interact(player: Node = null) -> void:
	if player == null:
		player = current_player

	if player and _can_interact(player):
		_perform_interaction()


## 启用交互
func enable_interaction() -> void:
	is_interactable = true


## 禁用交互
func disable_interaction() -> void:
	is_interactable = false
	_set_highlight(false)


## 设置交互提示
func set_prompt(prompt: String) -> void:
	interaction_prompt = prompt


## 获取当前交互提示
func get_prompt() -> String:
	return _get_interaction_prompt()


## 检查玩家是否在范围内
func is_player_in_range() -> bool:
	return player_in_range


## 设置精灵节点 (用于高亮)
func set_sprite(sprite: Node2D) -> void:
	sprite_node = sprite
	if sprite_node:
		_original_modulate = sprite_node.modulate


## ==================== 私有方法 ====================

## 执行交互
func _perform_interaction() -> void:
	if not current_player:
		return

	if not _can_interact(current_player):
		return

	# 执行交互逻辑
	_execute_interaction(current_player)

	# 发送信号
	interacted.emit(current_player)

	# 通知事件总线
	if EventBus:
		EventBus.interaction_performed.emit(self)

	# 设置冷却
	_cooldown_timer = interaction_cooldown

	# 如果是一次性交互，禁用
	if one_time_interaction:
		disable_interaction()

	# 交互完成
	interaction_completed.emit()


## 玩家进入范围
func _on_body_entered(body: Node2D) -> void:
	# 检查是否是玩家
	if not _is_player(body):
		return

	player_in_range = true
	current_player = body

	# 高亮显示
	if is_interactable:
		_set_highlight(true)

	# 通知事件总线
	if EventBus:
		EventBus.interaction_available.emit(self)

	# 发送信号
	player_entered.emit()


## 玩家离开范围
func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return

	player_in_range = false
	current_player = null

	# 取消高亮
	_set_highlight(false)

	# 通知事件总线
	if EventBus:
		EventBus.interaction_unavailable.emit(self)

	# 发送信号
	player_exited.emit()


## 检查是否是玩家
func _is_player(body: Node) -> bool:
	# 检查是否在 "player" 组中
	return body.is_in_group("player")


## 设置高亮状态
func _set_highlight(highlighted: bool) -> void:
	if not sprite_node:
		return

	if highlighted and not _is_highlighted:
		_is_highlighted = true
		sprite_node.modulate = highlight_color
	elif not highlighted and _is_highlighted:
		_is_highlighted = false
		sprite_node.modulate = _original_modulate


## 尝试查找精灵节点
func _find_sprite_node() -> void:
	# 尝试查找常见的精灵节点名称
	var sprite_names = ["Sprite2D", "Sprite", "AnimatedSprite2D", "AnimatedSprite"]
	for sprite_name in sprite_names:
		sprite_node = get_node_or_null(sprite_name)
		if sprite_node:
			break

	# 如果没找到，尝试在父节点中查找
	if not sprite_node and get_parent():
		for sprite_name in sprite_names:
			sprite_node = get_parent().get_node_or_null(sprite_name)
			if sprite_node:
				break


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	return {
		"is_interactable": is_interactable,
		"position": {"x": global_position.x, "y": global_position.y}
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	is_interactable = data.get("is_interactable", true)

	if data.has("position"):
		var pos = data["position"]
		global_position = Vector2(pos.get("x", 0), pos.get("y", 0))
