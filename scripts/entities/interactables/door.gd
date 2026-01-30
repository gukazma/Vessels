# door.gd
# 门 - 可开关、可上锁
# 继承 Interactable 基类
class_name Door
extends Interactable

## ==================== 信号 ====================

## 门状态变化
signal door_state_changed(is_open: bool)

## 门被上锁/解锁
signal lock_state_changed(is_locked: bool)

## 尝试开锁定的门
signal locked_door_attempted()

## ==================== 枚举 ====================

enum DoorState {
	CLOSED,
	OPEN,
	LOCKED
}

## ==================== 导出变量 ====================

## 门的初始状态
@export var initial_state: DoorState = DoorState.CLOSED

## 需要的钥匙 ID (空字符串表示不需要钥匙)
@export var key_id: String = ""

## 开门后是否自动关闭
@export var auto_close: bool = false

## 自动关闭延迟 (秒)
@export var auto_close_delay: float = 3.0

## 是否阻挡移动 (关闭时)
@export var blocks_movement: bool = true

## ==================== 状态变量 ====================

## 当前状态
var current_state: DoorState = DoorState.CLOSED

## 是否打开
var is_open: bool = false

## 是否上锁
var is_locked: bool = false

## ==================== 节点引用 ====================

## 门精灵 (开关状态切换)
@onready var door_sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## 碰撞形状 (阻挡移动)
@onready var collision_shape: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

## 静态碰撞体 (用于物理阻挡)
@onready var static_body: StaticBody2D = $StaticBody2D if has_node("StaticBody2D") else null

## 动画播放器
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

## ==================== 生命周期 ====================

func _on_interactable_ready() -> void:
	# 添加到门组
	add_to_group("doors")
	add_to_group("interactables")

	# 设置初始状态
	_set_state(initial_state)

	print("[Door] 门已初始化")


## ==================== 交互实现 ====================

func _execute_interaction(player: Node) -> void:
	match current_state:
		DoorState.CLOSED:
			open_door()
		DoorState.OPEN:
			close_door()
		DoorState.LOCKED:
			_try_unlock(player)


func _get_interaction_prompt() -> String:
	match current_state:
		DoorState.CLOSED:
			return "按 E 键开门"
		DoorState.OPEN:
			return "按 E 键关门"
		DoorState.LOCKED:
			if key_id.is_empty():
				return "门已锁定"
			else:
				return "按 E 键开锁 (需要钥匙)"
		_:
			return "按 E 键交互"


## ==================== 门操作 ====================

## 开门
func open_door() -> void:
	if current_state == DoorState.LOCKED:
		locked_door_attempted.emit()
		if EventBus:
			EventBus.emit_warning("门是锁着的!")
		return

	_set_state(DoorState.OPEN)
	is_open = true
	door_state_changed.emit(true)

	# 播放开门动画
	_play_animation("open")

	# 禁用碰撞
	_set_collision_enabled(false)

	# 自动关闭
	if auto_close:
		await get_tree().create_timer(auto_close_delay).timeout
		if is_open:
			close_door()


## 关门
func close_door() -> void:
	if current_state != DoorState.OPEN:
		return

	_set_state(DoorState.CLOSED)
	is_open = false
	door_state_changed.emit(false)

	# 播放关门动画
	_play_animation("close")

	# 启用碰撞
	_set_collision_enabled(true)


## 上锁
func lock_door() -> void:
	if is_open:
		close_door()

	_set_state(DoorState.LOCKED)
	is_locked = true
	lock_state_changed.emit(true)


## 解锁
func unlock_door() -> void:
	if current_state != DoorState.LOCKED:
		return

	_set_state(DoorState.CLOSED)
	is_locked = false
	lock_state_changed.emit(false)

	if EventBus:
		EventBus.emit_success("门已解锁!")


## 尝试解锁 (需要钥匙)
func _try_unlock(player: Node) -> void:
	if key_id.is_empty():
		if EventBus:
			EventBus.emit_warning("这扇门无法打开。")
		return

	# 检查玩家是否有钥匙
	var inventory = _get_player_inventory(player)
	if inventory and inventory.has_item(key_id):
		# 消耗钥匙并解锁
		inventory.remove_item(key_id, 1)
		unlock_door()
	else:
		locked_door_attempted.emit()
		if EventBus:
			EventBus.emit_warning("你需要钥匙!")


func _get_player_inventory(player: Node):
	if player.has_node("InventoryManager"):
		return player.get_node("InventoryManager")

	# 尝试全局
	if has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager")

	return null


## ==================== 辅助方法 ====================

func _set_state(new_state: DoorState) -> void:
	current_state = new_state
	interaction_prompt = _get_interaction_prompt()

	# 更新视觉
	_update_visual()


func _update_visual() -> void:
	if not door_sprite:
		return

	# 简单的帧切换 (假设精灵表有不同状态)
	match current_state:
		DoorState.CLOSED:
			door_sprite.frame = 0
		DoorState.OPEN:
			door_sprite.frame = 1
		DoorState.LOCKED:
			door_sprite.frame = 0  # 锁定状态看起来和关闭一样


func _set_collision_enabled(enabled: bool) -> void:
	if not blocks_movement:
		return

	if collision_shape:
		collision_shape.disabled = not enabled

	if static_body and static_body.has_node("CollisionShape2D"):
		static_body.get_node("CollisionShape2D").disabled = not enabled


func _play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["current_state"] = current_state
	data["is_open"] = is_open
	data["is_locked"] = is_locked
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	is_open = data.get("is_open", false)
	is_locked = data.get("is_locked", false)
	_set_state(data.get("current_state", DoorState.CLOSED))
	_set_collision_enabled(not is_open)
