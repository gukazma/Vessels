# pickup_item.gd
# 地面物品 - 可拾取物品
# 继承 Interactable 基类
class_name PickupItem
extends Interactable

## ==================== 信号 ====================

## 物品被拾取
signal picked_up(item_id: String, quantity: int)

## ==================== 导出变量 ====================

## 物品 ID
@export var item_id: String = ""

## 物品数量
@export var quantity: int = 1

## 自动拾取 (玩家触碰即拾取)
@export var auto_pickup: bool = false

## 拾取后是否销毁
@export var destroy_on_pickup: bool = true

## 物品弹跳效果
@export var bounce_effect: bool = true

## 物品发光效果
@export var glow_effect: bool = false

## ==================== 节点引用 ====================

## 物品精灵
@onready var item_sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## 动画播放器
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## ==================== 私有变量 ====================

## 原始位置 (用于弹跳效果)
var _original_y: float = 0.0

## 弹跳计时器
var _bounce_timer: float = 0.0

## ==================== 生命周期 ====================

func _on_interactable_ready() -> void:
	# 添加到物品组
	add_to_group("items")
	add_to_group("pickups")

	# 设置交互提示
	_update_interaction_prompt()

	# 加载物品图标
	_load_item_icon()

	# 保存原始位置
	_original_y = position.y

	# 如果是自动拾取，监听碰撞
	if auto_pickup:
		body_entered.connect(_on_auto_pickup_body_entered)

	print("[PickupItem] 物品已生成: %s x%d" % [item_id, quantity])


func _process(delta: float) -> void:
	# 弹跳效果
	if bounce_effect and item_sprite:
		_bounce_timer += delta * 2.0
		item_sprite.position.y = sin(_bounce_timer) * 2.0


## ==================== 交互实现 ====================

func _execute_interaction(player: Node) -> void:
	_try_pickup(player)


func _can_interact(_player: Node) -> bool:
	return is_interactable and quantity > 0


func _get_interaction_prompt() -> String:
	var item_name = _get_item_name()
	if quantity > 1:
		return "按 E 键拾取 %s x%d" % [item_name, quantity]
	else:
		return "按 E 键拾取 %s" % item_name


## ==================== 拾取逻辑 ====================

func _try_pickup(player: Node) -> void:
	if quantity <= 0:
		return

	# 获取背包管理器
	var inventory = _get_inventory_manager()
	if not inventory:
		# 尝试从玩家获取
		if player.has_node("InventoryManager"):
			inventory = player.get_node("InventoryManager")

	if not inventory:
		if EventBus:
			EventBus.emit_error("无法访问背包!")
		return

	# 检查是否可以添加物品
	if not inventory.can_add_item(item_id, quantity):
		if EventBus:
			EventBus.emit_warning("背包已满!")
		return

	# 添加到背包
	var added = inventory.add_item(item_id, quantity)

	if added > 0:
		# 更新数量
		quantity -= added

		# 发送信号
		picked_up.emit(item_id, added)

		# 显示拾取消息
		var item_name = _get_item_name()
		if EventBus:
			EventBus.emit_info("拾取了 %s x%d" % [item_name, added])

		# 播放拾取音效/动画
		_play_pickup_effect()

		# 如果数量为0，销毁
		if quantity <= 0 and destroy_on_pickup:
			queue_free()


func _on_auto_pickup_body_entered(body: Node2D) -> void:
	if not auto_pickup:
		return

	if body.is_in_group("player"):
		_try_pickup(body)


## ==================== 辅助方法 ====================

func _get_inventory_manager() -> Node:
	# 尝试获取全局背包管理器
	if has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager")
	return null


func _get_item_name() -> String:
	if DataManager:
		var item_data = DataManager.get_item(item_id)
		if not item_data.is_empty():
			return item_data.get("name", item_id)
	return item_id


func _get_item_icon_path() -> String:
	if DataManager:
		var item_data = DataManager.get_item(item_id)
		if not item_data.is_empty():
			return item_data.get("icon_path", "")
	return ""


func _load_item_icon() -> void:
	if not item_sprite:
		return

	var icon_path = _get_item_icon_path()
	if icon_path.is_empty():
		return

	var texture = load(icon_path)
	if texture:
		item_sprite.texture = texture


func _update_interaction_prompt() -> void:
	interaction_prompt = _get_interaction_prompt()


func _play_pickup_effect() -> void:
	# 播放拾取动画
	if animation_player and animation_player.has_animation("pickup"):
		animation_player.play("pickup")

	# TODO: 播放拾取音效


## ==================== 公共方法 ====================

## 设置物品
func set_item(new_item_id: String, new_quantity: int = 1) -> void:
	item_id = new_item_id
	quantity = new_quantity
	_update_interaction_prompt()
	_load_item_icon()


## 添加数量
func add_quantity(amount: int) -> void:
	quantity += amount
	_update_interaction_prompt()


## 移除数量
func remove_quantity(amount: int) -> int:
	var removed = mini(amount, quantity)
	quantity -= removed
	_update_interaction_prompt()

	if quantity <= 0 and destroy_on_pickup:
		queue_free()

	return removed


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["item_id"] = item_id
	data["quantity"] = quantity
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	item_id = data.get("item_id", "")
	quantity = data.get("quantity", 1)
	_update_interaction_prompt()
	_load_item_icon()
