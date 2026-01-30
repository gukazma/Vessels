# container.gd
# 容器 - 可搜刮物品
# 继承 Interactable 基类
class_name LootContainer
extends Interactable

## ==================== 信号 ====================

## 容器被打开
signal container_opened()

## 容器被关闭
signal container_closed()

## 物品被拿走
signal item_taken(item_id: String, quantity: int)

## 容器被清空
signal container_emptied()

## ==================== 导出变量 ====================

## 容器名称
@export var container_name: String = "容器"

## 容器容量
@export var capacity: int = 6

## 初始物品 (物品ID -> 数量)
@export var initial_items: Dictionary = {}

## 是否可以放入物品
@export var allow_deposit: bool = false

## 是否已被搜刮过
@export var is_looted: bool = false

## 搜刮后是否重新生成物品
@export var respawn_items: bool = false

## 重生时间 (游戏小时)
@export var respawn_hours: int = 24

## 是否需要钥匙
@export var requires_key: bool = false

## 钥匙 ID
@export var key_id: String = ""

## ==================== 状态变量 ====================

## 是否已打开
var is_open: bool = false

## 容器内物品
var items: Array = []  # [{item_id: String, quantity: int}, ...]

## 上次搜刮时间
var last_looted_time: Dictionary = {}

## ==================== 节点引用 ====================

## 容器精灵
@onready var container_sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## 动画播放器
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## ==================== 生命周期 ====================

func _on_interactable_ready() -> void:
	# 添加到容器组
	add_to_group("containers")
	add_to_group("interactables")

	# 初始化物品
	_initialize_items()

	print("[Container] 容器已初始化: %s" % container_name)


## ==================== 交互实现 ====================

func _execute_interaction(player: Node) -> void:
	if requires_key and not _has_key(player):
		if EventBus:
			EventBus.emit_warning("需要钥匙!")
		return

	if is_open:
		close_container()
	else:
		open_container(player)


func _get_interaction_prompt() -> String:
	if is_open:
		return "按 E 键关闭 %s" % container_name
	else:
		if requires_key:
			return "按 E 键打开 %s (需要钥匙)" % container_name
		return "按 E 键打开 %s" % container_name


## ==================== 容器操作 ====================

## 打开容器
func open_container(player: Node = null) -> void:
	if is_open:
		return

	is_open = true
	container_opened.emit()

	# 播放打开动画
	_play_animation("open")

	# 更新视觉
	_update_visual()

	# 如果物品为空且已被搜刮，检查是否可以重生
	if items.is_empty() and is_looted and respawn_items:
		_check_respawn()

	# 显示容器内容 UI
	if EventBus:
		EventBus.open_menu.emit("container")


## 关闭容器
func close_container() -> void:
	if not is_open:
		return

	is_open = false
	container_closed.emit()

	# 播放关闭动画
	_play_animation("close")

	# 更新视觉
	_update_visual()

	# 关闭 UI
	if EventBus:
		EventBus.close_menu.emit("container")


## 拿取物品
func take_item(item_index: int, quantity: int = -1) -> Dictionary:
	if item_index < 0 or item_index >= items.size():
		return {}

	var item = items[item_index]

	# 如果数量为-1，拿走全部
	if quantity < 0:
		quantity = item["quantity"]

	var taken_quantity = mini(quantity, item["quantity"])
	var taken_item = {
		"item_id": item["item_id"],
		"quantity": taken_quantity
	}

	# 减少数量
	item["quantity"] -= taken_quantity

	# 如果数量为0，移除
	if item["quantity"] <= 0:
		items.remove_at(item_index)

	# 标记为已搜刮
	is_looted = true

	item_taken.emit(taken_item["item_id"], taken_quantity)

	# 检查是否清空
	if items.is_empty():
		container_emptied.emit()

	return taken_item


## 拿取全部物品 (返回物品列表)
func take_all_items() -> Array:
	var taken_items: Array = []

	for item in items:
		taken_items.append({
			"item_id": item["item_id"],
			"quantity": item["quantity"]
		})
		item_taken.emit(item["item_id"], item["quantity"])

	items.clear()
	is_looted = true
	container_emptied.emit()

	return taken_items


## 添加物品到容器
func add_item(item_id: String, quantity: int) -> bool:
	if not allow_deposit:
		return false

	if items.size() >= capacity:
		return false

	# 检查是否已有该物品
	for item in items:
		if item["item_id"] == item_id:
			item["quantity"] += quantity
			return true

	# 添加新物品
	items.append({
		"item_id": item_id,
		"quantity": quantity
	})

	return true


## 获取物品列表
func get_items() -> Array:
	return items.duplicate(true)


## 获取物品数量
func get_item_count(item_id: String) -> int:
	for item in items:
		if item["item_id"] == item_id:
			return item["quantity"]
	return 0


## 是否为空
func is_empty() -> bool:
	return items.is_empty()


## ==================== 辅助方法 ====================

func _initialize_items() -> void:
	items.clear()

	for item_id in initial_items:
		var quantity = initial_items[item_id]
		if quantity > 0:
			items.append({
				"item_id": item_id,
				"quantity": quantity
			})


func _has_key(player: Node) -> bool:
	if not requires_key:
		return true

	if key_id.is_empty():
		return true

	var inventory = _get_player_inventory(player)
	if inventory:
		return inventory.has_item(key_id)

	return false


func _get_player_inventory(player: Node):
	if player and player.has_node("InventoryManager"):
		return player.get_node("InventoryManager")

	if has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager")

	return null


func _check_respawn() -> void:
	if not respawn_items:
		return

	# TODO: 检查是否已过重生时间
	# 如果是，重新初始化物品

	# 简化版本：直接重新生成
	_initialize_items()
	is_looted = false


func _update_visual() -> void:
	if not container_sprite:
		return

	# 更新精灵帧
	if is_open:
		container_sprite.frame = 1
	else:
		container_sprite.frame = 0


func _play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["container_name"] = container_name
	data["items"] = items.duplicate(true)
	data["is_looted"] = is_looted
	data["is_open"] = is_open
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	container_name = data.get("container_name", "容器")
	items = data.get("items", [])
	is_looted = data.get("is_looted", false)
	is_open = data.get("is_open", false)
	_update_visual()
