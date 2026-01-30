# dialogue_ui.gd
# 对话界面 - 显示 NPC 对话
class_name DialogueUI
extends Control

## ==================== 信号 ====================

## 对话选项选择
signal choice_selected(choice_id: String)

## 对话结束
signal dialogue_ended()

## ==================== 节点引用 ====================

## 对话面板
@onready var dialogue_panel: PanelContainer = $DialoguePanel if has_node("DialoguePanel") else null

## NPC 名称标签
@onready var npc_name_label: Label = $DialoguePanel/NPCName if has_node("DialoguePanel/NPCName") else null

## 对话内容标签
@onready var dialogue_label: RichTextLabel = $DialoguePanel/DialogueText if has_node("DialoguePanel/DialogueText") else null

## 选项容器
@onready var choices_container: VBoxContainer = $DialoguePanel/ChoicesContainer if has_node("DialoguePanel/ChoicesContainer") else null

## 继续按钮
@onready var continue_button: Button = $DialoguePanel/ContinueButton if has_node("DialoguePanel/ContinueButton") else null

## NPC 头像
@onready var npc_portrait: TextureRect = $DialoguePanel/Portrait if has_node("DialoguePanel/Portrait") else null

## ==================== 变量 ====================

## 当前对话的 NPC
var current_npc: Node = null

## 当前对话文本队列
var text_queue: Array = []

## 当前选项
var current_choices: Array = []

## 是否正在打字
var is_typing: bool = false

## 打字速度 (字符/秒)
var typing_speed: float = 30.0

## ==================== 生命周期 ====================

func _ready() -> void:
	# 连接事件总线
	_connect_event_bus()

	# 连接按钮信号
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

	# 初始隐藏
	visible = false

	print("[DialogueUI] 对话界面已初始化")


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# 按空格或回车继续对话
	if event.is_action_pressed("ui_accept"):
		_on_continue_pressed()

	# ESC 关闭对话
	if event.is_action_pressed("ui_cancel"):
		end_dialogue()


## ==================== 事件总线连接 ====================

func _connect_event_bus() -> void:
	if not EventBus:
		return

	EventBus.dialog_started.connect(_on_dialog_started)
	EventBus.dialog_ended.connect(_on_dialog_ended)


func _on_dialog_started(npc_id: String) -> void:
	# 查找 NPC
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.has_method("get") and npc.npc_id == npc_id:
			start_dialogue(npc)
			return


func _on_dialog_ended(_npc_id: String) -> void:
	end_dialogue()


## ==================== 对话控制 ====================

## 开始对话
func start_dialogue(npc: Node) -> void:
	current_npc = npc
	visible = true

	# 设置 NPC 名称
	if npc_name_label:
		npc_name_label.text = npc.npc_name if npc.has_method("get") else "???"

	# 设置 NPC 头像
	# TODO: 加载 NPC 头像

	# 获取对话选项
	if npc.has_method("get_dialog_options"):
		current_choices = npc.get_dialog_options()
		_show_choices()
	else:
		_show_text("...")

	# 暂停游戏
	get_tree().paused = true


## 结束对话
func end_dialogue() -> void:
	if current_npc and current_npc.has_method("end_dialog"):
		current_npc.end_dialog()

	current_npc = null
	current_choices.clear()
	text_queue.clear()
	visible = false

	# 继续游戏
	get_tree().paused = false

	dialogue_ended.emit()


## 显示文本
func _show_text(text: String) -> void:
	if dialogue_label:
		dialogue_label.text = text

	# 隐藏选项
	_hide_choices()

	# 显示继续按钮
	if continue_button:
		continue_button.visible = true


## 显示选项
func _show_choices() -> void:
	if not choices_container:
		return

	# 清除旧选项
	for child in choices_container.get_children():
		child.queue_free()

	# 创建选项按钮
	for choice in current_choices:
		var button = Button.new()
		button.text = choice.get("text", "...")
		button.pressed.connect(_on_choice_pressed.bind(choice.get("id", "")))
		choices_container.add_child(button)

	# 隐藏继续按钮
	if continue_button:
		continue_button.visible = false

	# 清空对话文本
	if dialogue_label:
		dialogue_label.text = ""


func _hide_choices() -> void:
	if not choices_container:
		return

	for child in choices_container.get_children():
		child.queue_free()


## ==================== 输入处理 ====================

func _on_continue_pressed() -> void:
	if text_queue.size() > 0:
		# 显示下一段文本
		var next_text = text_queue.pop_front()
		_show_text(next_text)
	else:
		# 返回选项
		if current_npc and current_npc.has_method("get_dialog_options"):
			current_choices = current_npc.get_dialog_options()
			_show_choices()


func _on_choice_pressed(choice_id: String) -> void:
	if not current_npc:
		return

	# 处理选择
	var response = ""
	if current_npc.has_method("handle_dialog_choice"):
		response = current_npc.handle_dialog_choice(choice_id)

	# 显示回应
	if not response.is_empty():
		_show_text(response)

	choice_selected.emit(choice_id)

	# 如果选择了结束对话的选项，关闭
	if choice_id == "bye":
		await get_tree().create_timer(1.0).timeout
		end_dialogue()


## ==================== 公共方法 ====================

## 显示简单消息
func show_message(speaker: String, text: String) -> void:
	visible = true

	if npc_name_label:
		npc_name_label.text = speaker

	_show_text(text)

	# 暂停游戏
	get_tree().paused = true


## 添加对话文本到队列
func queue_text(text: String) -> void:
	text_queue.append(text)


## 设置打字速度
func set_typing_speed(speed: float) -> void:
	typing_speed = speed


## 检查是否正在对话
func is_in_dialogue() -> bool:
	return visible and current_npc != null
