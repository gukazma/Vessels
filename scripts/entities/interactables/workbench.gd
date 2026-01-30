# workbench.gd
# 工作台 - 制作物品
# 继承 Interactable 基类
class_name Workbench
extends Interactable

## ==================== 信号 ====================

## 工作台打开
signal workbench_opened()

## 工作台关闭
signal workbench_closed()

## 制作完成
signal crafting_completed(item_id: String, quantity: int)

## 制作失败
signal crafting_failed(reason: String)

## ==================== 枚举 ====================

enum WorkbenchType {
	BASIC,      ## 基础工作台
	ADVANCED,   ## 高级工作台
	KITCHEN,    ## 厨房
	MEDICAL,    ## 医疗台
	WEAPON      ## 武器台
}

## ==================== 导出变量 ====================

## 工作台类型
@export var workbench_type: WorkbenchType = WorkbenchType.BASIC

## 工作台名称
@export var workbench_name: String = "工作台"

## 可制作的配方列表 (配方ID数组)
@export var available_recipes: Array[String] = []

## 制作速度倍率
@export var craft_speed_multiplier: float = 1.0

## ==================== 状态变量 ====================

## 是否已打开
var is_open: bool = false

## 当前正在制作的物品
var current_crafting: String = ""

## 制作进度 (0-1)
var crafting_progress: float = 0.0

## ==================== 节点引用 ====================

## 工作台精灵
@onready var workbench_sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## 动画播放器
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## ==================== 生命周期 ====================

func _on_interactable_ready() -> void:
	# 添加到工作台组
	add_to_group("workbenches")
	add_to_group("interactables")

	# 设置交互提示
	interaction_prompt = "按 E 键使用 %s" % workbench_name

	# 加载可用配方
	_load_available_recipes()

	print("[Workbench] 工作台已初始化: %s" % workbench_name)


func _process(delta: float) -> void:
	# 处理制作进度
	if not current_crafting.is_empty():
		_process_crafting(delta)


## ==================== 交互实现 ====================

func _execute_interaction(_player: Node) -> void:
	if is_open:
		close_workbench()
	else:
		open_workbench()


func _get_interaction_prompt() -> String:
	if is_open:
		return "按 E 键关闭 %s" % workbench_name
	return "按 E 键使用 %s" % workbench_name


## ==================== 工作台操作 ====================

## 打开工作台
func open_workbench() -> void:
	if is_open:
		return

	is_open = true
	workbench_opened.emit()

	# 打开制作 UI
	if EventBus:
		EventBus.open_menu.emit("crafting")


## 关闭工作台
func close_workbench() -> void:
	if not is_open:
		return

	is_open = false
	workbench_closed.emit()

	# 关闭制作 UI
	if EventBus:
		EventBus.close_menu.emit("crafting")


## 获取可用配方
func get_available_recipes() -> Array:
	var recipes: Array = []

	for recipe_id in available_recipes:
		var recipe = _get_recipe_data(recipe_id)
		if not recipe.is_empty():
			recipes.append(recipe)

	return recipes


## 检查是否可以制作
func can_craft(recipe_id: String) -> bool:
	var recipe = _get_recipe_data(recipe_id)
	if recipe.is_empty():
		return false

	# 检查材料
	var requirements = recipe.get("requirements", {})
	var inventory = _get_inventory_manager()

	if not inventory:
		return false

	for item_id in requirements:
		var required_amount = requirements[item_id]
		if not inventory.has_item(item_id, required_amount):
			return false

	return true


## 开始制作
func start_crafting(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		crafting_failed.emit("材料不足")
		return false

	if not current_crafting.is_empty():
		crafting_failed.emit("正在制作中")
		return false

	var recipe = _get_recipe_data(recipe_id)
	if recipe.is_empty():
		return false

	# 消耗材料
	var requirements = recipe.get("requirements", {})
	var inventory = _get_inventory_manager()

	for item_id in requirements:
		var amount = requirements[item_id]
		inventory.remove_item(item_id, amount)

	# 开始制作
	current_crafting = recipe_id
	crafting_progress = 0.0

	# 播放制作动画
	_play_animation("crafting")

	return true


## 立即完成制作 (用于简化或测试)
func instant_craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		crafting_failed.emit("材料不足")
		return false

	var recipe = _get_recipe_data(recipe_id)
	if recipe.is_empty():
		return false

	# 消耗材料
	var requirements = recipe.get("requirements", {})
	var inventory = _get_inventory_manager()

	for item_id in requirements:
		var amount = requirements[item_id]
		inventory.remove_item(item_id, amount)

	# 添加产物
	var result_id = recipe.get("result", "")
	var result_quantity = recipe.get("result_quantity", 1)

	if inventory.add_item(result_id, result_quantity) > 0:
		crafting_completed.emit(result_id, result_quantity)

		# 显示消息
		if EventBus:
			var item_name = _get_item_name(result_id)
			EventBus.emit_success("制作了 %s x%d" % [item_name, result_quantity])

		return true
	else:
		if EventBus:
			EventBus.emit_error("背包已满!")
		return false


## 取消制作
func cancel_crafting() -> void:
	if current_crafting.is_empty():
		return

	# TODO: 返还部分材料?

	current_crafting = ""
	crafting_progress = 0.0
	_play_animation("idle")


## ==================== 制作处理 ====================

func _process_crafting(delta: float) -> void:
	if current_crafting.is_empty():
		return

	var recipe = _get_recipe_data(current_crafting)
	if recipe.is_empty():
		cancel_crafting()
		return

	var craft_time = recipe.get("craft_time", 1.0)
	var actual_delta = delta * craft_speed_multiplier

	crafting_progress += actual_delta / craft_time

	if crafting_progress >= 1.0:
		_complete_crafting()


func _complete_crafting() -> void:
	var recipe = _get_recipe_data(current_crafting)
	if recipe.is_empty():
		current_crafting = ""
		crafting_progress = 0.0
		return

	# 添加产物
	var result_id = recipe.get("result", "")
	var result_quantity = recipe.get("result_quantity", 1)

	var inventory = _get_inventory_manager()
	if inventory and inventory.add_item(result_id, result_quantity) > 0:
		crafting_completed.emit(result_id, result_quantity)

		# 显示消息
		if EventBus:
			var item_name = _get_item_name(result_id)
			EventBus.emit_success("制作完成: %s x%d" % [item_name, result_quantity])
	else:
		if EventBus:
			EventBus.emit_error("背包已满，物品掉落在地上!")

		# TODO: 生成地面物品

	current_crafting = ""
	crafting_progress = 0.0
	_play_animation("idle")


## ==================== 辅助方法 ====================

func _load_available_recipes() -> void:
	# 根据工作台类型加载配方
	if DataManager:
		# TODO: 从数据管理器加载配方
		pass


func _get_recipe_data(recipe_id: String) -> Dictionary:
	if DataManager:
		return DataManager.get_recipe(recipe_id) if DataManager.has_method("get_recipe") else {}
	return {}


func _get_inventory_manager():
	if has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager")
	return null


func _get_item_name(item_id: String) -> String:
	if DataManager:
		var item_data = DataManager.get_item(item_id)
		if not item_data.is_empty():
			return item_data.get("name", item_id)
	return item_id


func _play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["workbench_type"] = workbench_type
	data["current_crafting"] = current_crafting
	data["crafting_progress"] = crafting_progress
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	workbench_type = data.get("workbench_type", WorkbenchType.BASIC)
	current_crafting = data.get("current_crafting", "")
	crafting_progress = data.get("crafting_progress", 0.0)
