# hud.gd
# HUD - 游戏主界面显示
# 显示生命/饥饿/体力/时间等信息
class_name HUD
extends CanvasLayer

## ==================== 信号 ====================

## 菜单按钮点击
signal menu_button_pressed(menu_name: String)

## ==================== 节点引用 ====================

## 生命值进度条
@onready var hp_bar: ProgressBar = $StatusPanel/HPBar if has_node("StatusPanel/HPBar") else null

## 饥饿度进度条
@onready var hunger_bar: ProgressBar = $StatusPanel/HungerBar if has_node("StatusPanel/HungerBar") else null

## 体力进度条
@onready var stamina_bar: ProgressBar = $StatusPanel/StaminaBar if has_node("StatusPanel/StaminaBar") else null

## 时间标签
@onready var time_label: Label = $TimePanel/TimeLabel if has_node("TimePanel/TimeLabel") else null

## 日期标签
@onready var day_label: Label = $TimePanel/DayLabel if has_node("TimePanel/DayLabel") else null

## 阶段标签
@onready var phase_label: Label = $TimePanel/PhaseLabel if has_node("TimePanel/PhaseLabel") else null

## 金钱标签
@onready var money_label: Label = $InfoPanel/MoneyLabel if has_node("InfoPanel/MoneyLabel") else null

## 交互提示标签
@onready var interaction_label: Label = $InteractionPanel/InteractionLabel if has_node("InteractionPanel/InteractionLabel") else null

## 消息容器
@onready var message_container: VBoxContainer = $MessagePanel/MessageContainer if has_node("MessagePanel/MessageContainer") else null

## ==================== 变量 ====================

## 消息队列
var message_queue: Array = []

## 最大消息数量
var max_messages: int = 5

## 消息显示时间 (秒)
var message_duration: float = 3.0

## ==================== 生命周期 ====================

func _ready() -> void:
	# 连接事件总线信号
	_connect_event_bus()

	# 初始化显示
	_initialize_display()

	# 隐藏交互提示
	_hide_interaction_prompt()

	print("[HUD] HUD 已初始化")


func _process(_delta: float) -> void:
	# 更新时间显示
	_update_time_display()


## ==================== 事件总线连接 ====================

func _connect_event_bus() -> void:
	if not EventBus:
		return

	# 玩家属性变化
	EventBus.player_stat_changed.connect(_on_player_stat_changed)

	# 金钱变化
	EventBus.player_money_changed.connect(_on_player_money_changed)

	# 时间变化
	EventBus.time_tick.connect(_on_time_tick)
	EventBus.day_changed.connect(_on_day_changed)

	# 阶段变化
	EventBus.phase_changed.connect(_on_phase_changed)

	# 交互提示
	EventBus.interaction_available.connect(_on_interaction_available)
	EventBus.interaction_unavailable.connect(_on_interaction_unavailable)

	# 消息显示
	EventBus.show_message.connect(_on_show_message)


## ==================== 显示更新 ====================

func _initialize_display() -> void:
	# 初始化状态条
	_update_stat_bar(hp_bar, 100, 100)
	_update_stat_bar(hunger_bar, 100, 100)
	_update_stat_bar(stamina_bar, 100, 100)

	# 初始化时间显示
	_update_time_display()

	# 初始化金钱显示
	_update_money_display(0)


func _update_stat_bar(bar: ProgressBar, current: float, max_value: float) -> void:
	if not bar:
		return

	bar.max_value = max_value
	bar.value = current

	# 更新颜色 (根据百分比)
	var percent = current / max_value if max_value > 0 else 0

	if percent <= 0.2:
		bar.modulate = Color.RED
	elif percent <= 0.5:
		bar.modulate = Color.YELLOW
	else:
		bar.modulate = Color.WHITE


func _update_time_display() -> void:
	if not GameManager:
		return

	# 更新时间
	if time_label:
		time_label.text = "%02d:%02d" % [GameManager.current_hour, GameManager.current_minute]

	# 更新日期
	if day_label:
		day_label.text = "Day %d" % GameManager.current_day

	# 更新阶段
	if phase_label:
		phase_label.text = GameManager.get_phase_display_name()


func _update_money_display(amount: int) -> void:
	if money_label:
		money_label.text = "$%d" % amount


func _show_interaction_prompt(prompt: String) -> void:
	if interaction_label:
		interaction_label.text = prompt
		interaction_label.visible = true


func _hide_interaction_prompt() -> void:
	if interaction_label:
		interaction_label.visible = false


## ==================== 信号处理 ====================

func _on_player_stat_changed(stat: String, value: float, max_value: float) -> void:
	match stat:
		"hp", "health":
			_update_stat_bar(hp_bar, value, max_value)
		"hunger":
			_update_stat_bar(hunger_bar, value, max_value)
		"stamina":
			_update_stat_bar(stamina_bar, value, max_value)


func _on_player_money_changed(amount: int, _delta: int) -> void:
	_update_money_display(amount)


func _on_time_tick(_hour: int, _minute: int) -> void:
	_update_time_display()


func _on_day_changed(_day: int) -> void:
	_update_time_display()


func _on_phase_changed(_phase: String) -> void:
	_update_time_display()


func _on_interaction_available(interactable: Node) -> void:
	if interactable.has_method("get_prompt"):
		var prompt = interactable.get_prompt()
		_show_interaction_prompt(prompt)
	else:
		_show_interaction_prompt("按 E 键交互")


func _on_interaction_unavailable(_interactable: Node) -> void:
	_hide_interaction_prompt()


func _on_show_message(message: String, type: String) -> void:
	add_message(message, type)


## ==================== 消息系统 ====================

## 添加消息
func add_message(text: String, type: String = "info") -> void:
	if not message_container:
		return

	# 创建消息标签
	var label = Label.new()
	label.text = text

	# 根据类型设置颜色
	match type:
		"info":
			label.modulate = Color.WHITE
		"warning":
			label.modulate = Color.YELLOW
		"error":
			label.modulate = Color.RED
		"success":
			label.modulate = Color.GREEN
		_:
			label.modulate = Color.WHITE

	# 添加到容器
	message_container.add_child(label)
	message_queue.append(label)

	# 限制消息数量
	while message_queue.size() > max_messages:
		var old_label = message_queue.pop_front()
		if is_instance_valid(old_label):
			old_label.queue_free()

	# 自动移除消息
	get_tree().create_timer(message_duration).timeout.connect(
		func():
			if is_instance_valid(label):
				message_queue.erase(label)
				label.queue_free()
	)


## 清除所有消息
func clear_messages() -> void:
	for label in message_queue:
		if is_instance_valid(label):
			label.queue_free()
	message_queue.clear()


## ==================== 公共方法 ====================

## 显示/隐藏 HUD
func set_visible(visible: bool) -> void:
	for child in get_children():
		if child is Control:
			child.visible = visible


## 设置状态条值
func set_hp(current: float, max_value: float) -> void:
	_update_stat_bar(hp_bar, current, max_value)


func set_hunger(current: float, max_value: float) -> void:
	_update_stat_bar(hunger_bar, current, max_value)


func set_stamina(current: float, max_value: float) -> void:
	_update_stat_bar(stamina_bar, current, max_value)


## 设置金钱
func set_money(amount: int) -> void:
	_update_money_display(amount)
