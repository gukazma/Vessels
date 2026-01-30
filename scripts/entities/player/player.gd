# player.gd
# 玩家控制脚本 - 继承 Entity 基类
# 实现 WASD/方向键移动、8方向动画、交互、跑步等功能
class_name Player
extends Entity

## ==================== 信号 ====================

## 交互尝试
signal interaction_attempted()

## 跑步状态变化
signal running_state_changed(is_running: bool)

## ==================== 导出变量 ====================

## 跑步速度倍率
@export var run_speed_multiplier: float = 1.5

## 跑步体力消耗 (每秒)
@export var run_stamina_cost: float = 5.0

## 交互距离
@export var interaction_range: float = 32.0

## ==================== 状态变量 ====================

## 是否正在跑步
var is_running: bool = false

## 当前可交互物体
var current_interactable: Node = null

## 动画方向 (用于8方向动画)
var anim_direction: String = "down"

## ==================== 节点引用 ====================

## 动画精灵节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

## 玩家状态组件
@onready var player_stats: PlayerStats = $PlayerStats if has_node("PlayerStats") else null

## 交互检测区域
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null

## ==================== 生命周期 ====================

func _on_entity_ready() -> void:
	# 将玩家添加到 player 组
	add_to_group("player")

	# 连接事件总线信号
	_connect_event_bus()

	# 设置交互区域
	_setup_interaction_area()

	print("[Player] 玩家已初始化")


func _process(_delta: float) -> void:
	# 处理输入
	_handle_input()

	# 更新动画
	_update_animation()


func _physics_process(delta: float) -> void:
	# 调用父类处理移动
	super._physics_process(delta)

	# 处理跑步体力消耗
	if is_running and is_moving and player_stats:
		if not player_stats.consume_stamina(run_stamina_cost * delta):
			# 体力耗尽，停止跑步
			_stop_running()


## ==================== 输入处理 ====================

func _handle_input() -> void:
	if not is_alive:
		move_direction = Vector2.ZERO
		return

	# 获取移动输入
	var input_direction = Vector2.ZERO
	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")

	# 设置移动方向
	set_move_direction(input_direction)

	# 处理跑步
	_handle_running()

	# 处理交互
	if Input.is_action_just_pressed("interact"):
		_try_interact()


func _handle_running() -> void:
	var wants_to_run = Input.is_action_pressed("run")

	if wants_to_run and is_moving and not is_running:
		# 开始跑步
		if player_stats and player_stats.current_stamina > 0:
			_start_running()
	elif (not wants_to_run or not is_moving) and is_running:
		# 停止跑步
		_stop_running()


func _start_running() -> void:
	is_running = true
	set_speed_modifier(run_speed_multiplier)
	running_state_changed.emit(true)


func _stop_running() -> void:
	is_running = false
	reset_speed_modifier()
	running_state_changed.emit(false)


## ==================== 交互处理 ====================

func _try_interact() -> void:
	interaction_attempted.emit()

	if current_interactable and current_interactable.has_method("interact"):
		current_interactable.interact(self)


func _setup_interaction_area() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_body_entered)
		interaction_area.body_exited.connect(_on_interaction_body_exited)
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)


func _on_interaction_body_entered(body: Node2D) -> void:
	if body is Interactable:
		current_interactable = body


func _on_interaction_body_exited(body: Node2D) -> void:
	if body == current_interactable:
		current_interactable = null


func _on_interaction_area_entered(area: Area2D) -> void:
	if area is Interactable:
		current_interactable = area


func _on_interaction_area_exited(area: Area2D) -> void:
	if area == current_interactable:
		current_interactable = null


## ==================== 动画更新 ====================

func _update_animation() -> void:
	if not animated_sprite:
		return

	# 根据移动方向确定动画方向
	if move_direction != Vector2.ZERO:
		anim_direction = _get_direction_name(move_direction)

	# 选择动画
	var anim_name = ""
	if is_moving:
		if is_running:
			anim_name = "run_" + anim_direction
		else:
			anim_name = "walk_" + anim_direction
	else:
		anim_name = "idle_" + anim_direction

	# 播放动画 (如果动画存在)
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)
	elif animated_sprite.sprite_frames:
		# 尝试简化的动画名 (walk/idle)
		var simple_anim = "walk" if is_moving else "idle"
		if animated_sprite.sprite_frames.has_animation(simple_anim):
			if animated_sprite.animation != simple_anim:
				animated_sprite.play(simple_anim)


func _get_direction_name(direction: Vector2) -> String:
	# 8方向名称
	var angle = direction.angle()

	# 将角度转换为8个方向
	# 角度范围: -PI 到 PI
	if angle >= -PI/8 and angle < PI/8:
		return "right"
	elif angle >= PI/8 and angle < 3*PI/8:
		return "down_right"
	elif angle >= 3*PI/8 and angle < 5*PI/8:
		return "down"
	elif angle >= 5*PI/8 and angle < 7*PI/8:
		return "down_left"
	elif angle >= 7*PI/8 or angle < -7*PI/8:
		return "left"
	elif angle >= -7*PI/8 and angle < -5*PI/8:
		return "up_left"
	elif angle >= -5*PI/8 and angle < -3*PI/8:
		return "up"
	else:
		return "up_right"


## ==================== 事件总线连接 ====================

func _connect_event_bus() -> void:
	if not EventBus:
		return

	# 连接交互相关信号
	EventBus.interaction_available.connect(_on_interaction_available)
	EventBus.interaction_unavailable.connect(_on_interaction_unavailable)


func _on_interaction_available(interactable: Node) -> void:
	# 更新当前可交互物体
	current_interactable = interactable


func _on_interaction_unavailable(interactable: Node) -> void:
	if current_interactable == interactable:
		current_interactable = null


## ==================== 重写基类方法 ====================

func _on_death() -> void:
	super._on_death()

	# 停止所有行动
	is_running = false
	move_direction = Vector2.ZERO

	# 通知事件总线
	if EventBus:
		EventBus.player_died.emit()

	print("[Player] 玩家死亡")


func _calculate_damage(amount: float, attacker: Node) -> float:
	# 可以在这里添加防御计算
	var final_damage = amount

	# TODO: 根据装备计算防御

	return final_damage


## ==================== 公共方法 ====================

## 获取当前可交互物体
func get_current_interactable() -> Node:
	return current_interactable


## 检查是否有可交互物体
func has_interactable() -> bool:
	return current_interactable != null


## 获取交互提示
func get_interaction_prompt() -> String:
	if current_interactable and current_interactable.has_method("get_prompt"):
		return current_interactable.get_prompt()
	return ""


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["anim_direction"] = anim_direction

	# 保存玩家状态数据
	if player_stats:
		data["stats"] = player_stats.get_save_data()

	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	anim_direction = data.get("anim_direction", "down")

	# 加载玩家状态数据
	if player_stats and data.has("stats"):
		player_stats.load_save_data(data["stats"])
