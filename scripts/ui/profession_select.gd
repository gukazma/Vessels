# profession_select.gd
# 职业选择界面
class_name ProfessionSelectUI
extends Control

## ==================== 信号 ====================

## 职业选择完成
signal profession_selected(profession_id: String)

## 返回主菜单
signal back_requested()

## ==================== 节点引用 ====================

## 职业列表容器
@onready var profession_list: VBoxContainer = $Panel/ProfessionList if has_node("Panel/ProfessionList") else null

## 职业详情面板
@onready var detail_panel: Panel = $Panel/DetailPanel if has_node("Panel/DetailPanel") else null

## 职业名称标签
@onready var profession_name: Label = $Panel/DetailPanel/ProfessionName if has_node("Panel/DetailPanel/ProfessionName") else null

## 职业描述标签
@onready var profession_desc: RichTextLabel = $Panel/DetailPanel/Description if has_node("Panel/DetailPanel/Description") else null

## 属性显示
@onready var stats_label: Label = $Panel/DetailPanel/Stats if has_node("Panel/DetailPanel/Stats") else null

## 确认按钮
@onready var confirm_button: Button = $Panel/ConfirmButton if has_node("Panel/ConfirmButton") else null

## 返回按钮
@onready var back_button: Button = $Panel/BackButton if has_node("Panel/BackButton") else null

## ==================== 变量 ====================

## 职业数据列表
var professions: Array = []

## 当前选中的职业ID
var selected_profession: String = ""

## ==================== 生命周期 ====================

func _ready() -> void:
	# 加载职业数据
	_load_professions()

	# 创建职业按钮
	_create_profession_buttons()

	# 连接按钮信号
	_connect_buttons()

	# 初始状态
	_hide_detail()

	print("[ProfessionSelectUI] 职业选择界面已初始化")


## ==================== 数据加载 ====================

func _load_professions() -> void:
	if DataManager:
		professions = DataManager.get_all_professions() if DataManager.has_method("get_all_professions") else []

	# 如果数据管理器没有数据，使用默认职业
	if professions.is_empty():
		professions = [
			{
				"id": "office_worker",
				"name": "上班族",
				"description": "普通的办公室职员，朝九晚五的工作，平均的各项属性。",
				"attributes": {
					"combat": 2,
					"build": 2,
					"medical": 2,
					"social": 3,
					"cooking": 2
				},
				"daily_wage": 150,
				"work_hours": {"start": 9, "end": 18}
			},
			{
				"id": "construction_worker",
				"name": "建筑工人",
				"description": "强壮的体力劳动者，擅长建造和使用工具。",
				"attributes": {
					"combat": 3,
					"build": 4,
					"medical": 1,
					"social": 1,
					"cooking": 2
				},
				"daily_wage": 180,
				"work_hours": {"start": 7, "end": 17}
			},
			{
				"id": "doctor",
				"name": "医生",
				"description": "受过专业医学训练，擅长治疗和救治伤员。",
				"attributes": {
					"combat": 1,
					"build": 1,
					"medical": 5,
					"social": 3,
					"cooking": 1
				},
				"daily_wage": 300,
				"work_hours": {"start": 8, "end": 20}
			},
			{
				"id": "chef",
				"name": "厨师",
				"description": "烹饪专家，能用普通食材做出美味佳肴。",
				"attributes": {
					"combat": 1,
					"build": 2,
					"medical": 1,
					"social": 2,
					"cooking": 5
				},
				"daily_wage": 120,
				"work_hours": {"start": 10, "end": 22}
			},
			{
				"id": "veteran",
				"name": "退伍军人",
				"description": "经验丰富的战斗人员，精通各种武器。",
				"attributes": {
					"combat": 5,
					"build": 2,
					"medical": 2,
					"social": 1,
					"cooking": 1
				},
				"daily_wage": 200,
				"work_hours": {"start": 6, "end": 18}
			}
		]


## ==================== UI 创建 ====================

func _create_profession_buttons() -> void:
	if not profession_list:
		return

	# 清除旧按钮
	for child in profession_list.get_children():
		child.queue_free()

	# 创建职业按钮
	for profession in professions:
		var button = Button.new()
		button.text = profession.get("name", "未知职业")
		button.pressed.connect(_on_profession_button_pressed.bind(profession.get("id", "")))
		profession_list.add_child(button)


func _connect_buttons() -> void:
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)

	if back_button:
		back_button.pressed.connect(_on_back_pressed)


## ==================== 显示更新 ====================

func _show_profession_detail(profession_id: String) -> void:
	# 查找职业数据
	var profession_data = {}
	for profession in professions:
		if profession.get("id") == profession_id:
			profession_data = profession
			break

	if profession_data.is_empty():
		_hide_detail()
		return

	# 显示详情面板
	if detail_panel:
		detail_panel.visible = true

	# 更新名称
	if profession_name:
		profession_name.text = profession_data.get("name", "")

	# 更新描述
	if profession_desc:
		profession_desc.text = profession_data.get("description", "")

	# 更新属性
	if stats_label:
		var attributes = profession_data.get("attributes", {})
		var stats_text = ""
		stats_text += "战斗: %d\n" % attributes.get("combat", 1)
		stats_text += "建造: %d\n" % attributes.get("build", 1)
		stats_text += "医疗: %d\n" % attributes.get("medical", 1)
		stats_text += "社交: %d\n" % attributes.get("social", 1)
		stats_text += "烹饪: %d\n" % attributes.get("cooking", 1)
		stats_text += "\n日薪: $%d" % profession_data.get("daily_wage", 100)
		stats_label.text = stats_text

	# 启用确认按钮
	if confirm_button:
		confirm_button.disabled = false


func _hide_detail() -> void:
	if detail_panel:
		detail_panel.visible = false

	if confirm_button:
		confirm_button.disabled = true


## ==================== 事件处理 ====================

func _on_profession_button_pressed(profession_id: String) -> void:
	selected_profession = profession_id
	_show_profession_detail(profession_id)


func _on_confirm_pressed() -> void:
	if selected_profession.is_empty():
		return

	print("[ProfessionSelectUI] 选择职业: %s" % selected_profession)

	profession_selected.emit(selected_profession)

	# 开始新游戏
	if GameManager:
		GameManager.start_new_game(selected_profession)

	# 隐藏界面
	visible = false

	# 加载游戏场景
	# TODO: 切换到游戏场景


func _on_back_pressed() -> void:
	back_requested.emit()
	visible = false

	# 返回主菜单
	if EventBus:
		EventBus.open_menu.emit("main_menu")


## ==================== 公共方法 ====================

## 显示界面
func show_selection() -> void:
	visible = true
	selected_profession = ""
	_hide_detail()


## 隐藏界面
func hide_selection() -> void:
	visible = false
