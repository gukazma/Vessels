# inventory_ui.gd
# 背包界面 - 显示和管理玩家物品
class_name InventoryUI
extends Control

## ==================== 信号 ====================

## 物品选中
signal item_selected(slot_index: int)

## 物品使用请求
signal item_use_requested(slot_index: int)

## 物品丢弃请求
signal item_drop_requested(slot_index: int, quantity: int)

## 界面关闭
signal closed()

## ==================== 导出变量 ====================

## 每行槽位数量
@export var slots_per_row: int = 4

## 槽位场景
@export var slot_scene: PackedScene = null

## ==================== 节点引用 ====================

## 槽位网格容器
@onready var slots_grid: GridContainer = $Panel/SlotsGrid if has_node("Panel/SlotsGrid") else null

## 物品信息面板
@onready var info_panel: Panel = $Panel/InfoPanel if has_node("Panel/InfoPanel") else null

## 物品名称标签
@onready var item_name_label: Label = $Panel/InfoPanel/ItemName if has_node("Panel/InfoPanel/ItemName") else null

## 物品描述标签
@onready var item_desc_label: Label = $Panel/InfoPanel/ItemDesc if has_node("Panel/InfoPanel/ItemDesc") else null

## 使用按钮
@onready var use_button: Button = $Panel/InfoPanel/UseButton if has_node("Panel/InfoPanel/UseButton") else null

## 丢弃按钮
@onready var drop_button: Button = $Panel/InfoPanel/DropButton if has_node("Panel/InfoPanel/DropButton") else null

## 关闭按钮
@onready var close_button: Button = $Panel/CloseButton if has_node("Panel/CloseButton") else null

## ==================== 变量 ====================

## 槽位节点列表
var slot_nodes: Array = []

## 当前选中的槽位
var selected_slot: int = -1

## 背包管理器引用
var inventory_manager: Node = null

## ==================== 生命周期 ====================

func _ready() -> void:
	# 获取背包管理器
	inventory_manager = _get_inventory_manager()

	# 创建槽位
	_create_slots()

	# 连接信号
	_connect_signals()

	# 初始化显示
	_refresh_display()

	# 隐藏信息面板
	_hide_item_info()

	print("[InventoryUI] 背包界面已初始化")


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC 关闭背包
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("inventory"):
		close_inventory()


## ==================== 信号连接 ====================

func _connect_signals() -> void:
	# 连接按钮信号
	if use_button:
		use_button.pressed.connect(_on_use_button_pressed)

	if drop_button:
		drop_button.pressed.connect(_on_drop_button_pressed)

	if close_button:
		close_button.pressed.connect(close_inventory)

	# 连接背包管理器信号
	if inventory_manager:
		if inventory_manager.has_signal("inventory_changed"):
			inventory_manager.inventory_changed.connect(_on_inventory_changed)


## ==================== 槽位管理 ====================

func _create_slots() -> void:
	if not slots_grid:
		return

	# 设置网格列数
	slots_grid.columns = slots_per_row

	# 获取背包容量
	var capacity = 12
	if inventory_manager:
		capacity = inventory_manager.capacity

	# 创建槽位
	for i in range(capacity):
		var slot = _create_slot_node(i)
		slots_grid.add_child(slot)
		slot_nodes.append(slot)


func _create_slot_node(index: int) -> Control:
	var slot: Control

	if slot_scene:
		slot = slot_scene.instantiate()
	else:
		# 创建默认槽位
		slot = Panel.new()
		slot.custom_minimum_size = Vector2(48, 48)

		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.anchors_preset = Control.PRESET_FULL_RECT
		slot.add_child(icon)

		var quantity_label = Label.new()
		quantity_label.name = "Quantity"
		quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		quantity_label.anchors_preset = Control.PRESET_FULL_RECT
		slot.add_child(quantity_label)

	# 连接点击信号
	slot.gui_input.connect(_on_slot_gui_input.bind(index))

	return slot


func _update_slot(index: int) -> void:
	if index < 0 or index >= slot_nodes.size():
		return

	var slot_node = slot_nodes[index]

	# 获取槽位数据
	var slot_data = {}
	if inventory_manager:
		slot_data = inventory_manager.get_slot(index)

	var item_id = slot_data.get("item_id", "")
	var quantity = slot_data.get("quantity", 0)

	# 更新图标
	var icon = slot_node.get_node_or_null("Icon")
	if icon is TextureRect:
		if item_id.is_empty():
			icon.texture = null
		else:
			var item_data = _get_item_data(item_id)
			var icon_path = item_data.get("icon_path", "")
			if not icon_path.is_empty():
				icon.texture = load(icon_path)
			else:
				icon.texture = null

	# 更新数量
	var quantity_label = slot_node.get_node_or_null("Quantity")
	if quantity_label is Label:
		if quantity > 1:
			quantity_label.text = str(quantity)
		else:
			quantity_label.text = ""

	# 更新选中状态
	_update_slot_selection(index)


func _update_slot_selection(index: int) -> void:
	if index < 0 or index >= slot_nodes.size():
		return

	var slot_node = slot_nodes[index]

	if index == selected_slot:
		slot_node.modulate = Color(1.2, 1.2, 1.2)
	else:
		slot_node.modulate = Color.WHITE


## ==================== 显示更新 ====================

func _refresh_display() -> void:
	for i in range(slot_nodes.size()):
		_update_slot(i)


func _show_item_info(slot_index: int) -> void:
	if not info_panel:
		return

	var slot_data = {}
	if inventory_manager:
		slot_data = inventory_manager.get_slot(slot_index)

	var item_id = slot_data.get("item_id", "")

	if item_id.is_empty():
		_hide_item_info()
		return

	var item_data = _get_item_data(item_id)

	# 显示信息面板
	info_panel.visible = true

	# 更新名称
	if item_name_label:
		item_name_label.text = item_data.get("name", item_id)

	# 更新描述
	if item_desc_label:
		item_desc_label.text = item_data.get("description", "")

	# 更新按钮状态
	var item_type = item_data.get("type", "")
	if use_button:
		use_button.visible = item_type in ["food", "medical"]

	if drop_button:
		drop_button.visible = true


func _hide_item_info() -> void:
	if info_panel:
		info_panel.visible = false


## ==================== 输入处理 ====================

func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_slot(index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_select_slot(index)
			if selected_slot >= 0:
				_on_use_button_pressed()


func _select_slot(index: int) -> void:
	# 取消之前的选中
	if selected_slot >= 0:
		_update_slot_selection(selected_slot)

	selected_slot = index
	_update_slot_selection(index)

	# 显示物品信息
	_show_item_info(index)

	item_selected.emit(index)


## ==================== 按钮事件 ====================

func _on_use_button_pressed() -> void:
	if selected_slot < 0:
		return

	# 使用物品
	if inventory_manager:
		if inventory_manager.use_item(selected_slot):
			_refresh_display()
			_hide_item_info()
			selected_slot = -1

	item_use_requested.emit(selected_slot)


func _on_drop_button_pressed() -> void:
	if selected_slot < 0:
		return

	# TODO: 显示数量选择对话框

	# 暂时丢弃1个
	if inventory_manager:
		var slot_data = inventory_manager.get_slot(selected_slot)
		var item_id = slot_data.get("item_id", "")
		if not item_id.is_empty():
			inventory_manager.remove_item(item_id, 1)
			_refresh_display()

			if EventBus:
				EventBus.emit_info("丢弃了物品")

	item_drop_requested.emit(selected_slot, 1)


func _on_inventory_changed() -> void:
	_refresh_display()


## ==================== 公共方法 ====================

## 打开背包
func open_inventory() -> void:
	visible = true
	_refresh_display()

	# 暂停游戏
	get_tree().paused = true


## 关闭背包
func close_inventory() -> void:
	visible = false
	selected_slot = -1
	_hide_item_info()

	# 继续游戏
	get_tree().paused = false

	closed.emit()


## 切换显示状态
func toggle_inventory() -> void:
	if visible:
		close_inventory()
	else:
		open_inventory()


## ==================== 辅助方法 ====================

func _get_inventory_manager():
	if has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager")
	return null


func _get_item_data(item_id: String) -> Dictionary:
	if DataManager:
		return DataManager.get_item(item_id)
	return {}
