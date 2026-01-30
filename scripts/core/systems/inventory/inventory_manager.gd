# inventory_manager.gd
# 背包系统 - 管理玩家和据点的物品
class_name InventoryManager
extends Node

## ==================== 常量 ====================

## 默认背包容量
const DEFAULT_CAPACITY: int = 12

## 最大背包容量
const MAX_CAPACITY: int = 28

## ==================== 信号 ====================

## 物品添加
signal item_added(item_id: String, quantity: int, slot: int)

## 物品移除
signal item_removed(item_id: String, quantity: int, slot: int)

## 物品使用
signal item_used(item_id: String)

## 背包已满
signal inventory_full()

## 背包变化 (通用)
signal inventory_changed()

## 装备武器变化
signal weapon_changed(weapon_id: String)

## ==================== 变量 ====================

## 背包数据 (slot_index -> {item_id, quantity})
var slots: Array = []

## 当前容量
var capacity: int = DEFAULT_CAPACITY

## 装备的武器槽位索引 (-1表示未装备)
var equipped_weapon_slot: int = -1

## ==================== 生命周期 ====================

func _ready() -> void:
	_initialize_slots()
	print("[InventoryManager] 背包系统已初始化，容量: %d" % capacity)


## ==================== 公共方法 - 物品管理 ====================

## 添加物品到背包
## 返回实际添加的数量 (可能因容量不足而少于请求数量)
func add_item(item_id: String, quantity: int = 1) -> int:
	if quantity <= 0:
		return 0

	var item_data = _get_item_data(item_id)
	if item_data.is_empty():
		print("[InventoryManager] 物品不存在: %s" % item_id)
		return 0

	var stack_max = item_data.get("stack_max", 99)
	var remaining = quantity
	var total_added = 0

	# 首先尝试堆叠到现有槽位
	for i in range(slots.size()):
		if remaining <= 0:
			break

		var slot = slots[i]
		if slot.item_id == item_id and slot.quantity < stack_max:
			var can_add = mini(remaining, stack_max - slot.quantity)
			slot.quantity += can_add
			remaining -= can_add
			total_added += can_add
			item_added.emit(item_id, can_add, i)

	# 然后尝试放入空槽位
	for i in range(slots.size()):
		if remaining <= 0:
			break

		var slot = slots[i]
		if slot.item_id.is_empty():
			var can_add = mini(remaining, stack_max)
			slot.item_id = item_id
			slot.quantity = can_add
			remaining -= can_add
			total_added += can_add
			item_added.emit(item_id, can_add, i)

	# 检查是否背包已满
	if remaining > 0:
		inventory_full.emit()
		if EventBus:
			EventBus.inventory_full.emit()

	# 发送事件
	if total_added > 0:
		inventory_changed.emit()
		if EventBus:
			EventBus.item_added.emit(item_id, total_added)

	return total_added


## 移除物品
## 返回实际移除的数量
func remove_item(item_id: String, quantity: int = 1) -> int:
	if quantity <= 0:
		return 0

	var remaining = quantity
	var total_removed = 0

	# 从后往前移除 (保持前面的物品)
	for i in range(slots.size() - 1, -1, -1):
		if remaining <= 0:
			break

		var slot = slots[i]
		if slot.item_id == item_id:
			var can_remove = mini(remaining, slot.quantity)
			slot.quantity -= can_remove
			remaining -= can_remove
			total_removed += can_remove

			if slot.quantity <= 0:
				_clear_slot(i)

			item_removed.emit(item_id, can_remove, i)

	# 发送事件
	if total_removed > 0:
		inventory_changed.emit()
		if EventBus:
			EventBus.item_removed.emit(item_id, total_removed)

	return total_removed


## 使用物品
func use_item(slot_index: int) -> bool:
	if not _is_valid_slot(slot_index):
		return false

	var slot = slots[slot_index]
	if slot.item_id.is_empty():
		return false

	var item_id = slot.item_id
	var item_data = _get_item_data(item_id)

	# 检查是否可使用
	if not _can_use_item(item_data):
		return false

	# 应用物品效果
	_apply_item_effects(item_data)

	# 消耗物品 (如果是消耗品)
	if _is_consumable(item_data):
		slot.quantity -= 1
		if slot.quantity <= 0:
			_clear_slot(slot_index)
		item_used.emit(item_id)
		inventory_changed.emit()

	if EventBus:
		EventBus.item_used.emit(item_id)

	return true


## 使用指定ID的物品
func use_item_by_id(item_id: String) -> bool:
	var slot_index = find_item(item_id)
	if slot_index < 0:
		return false
	return use_item(slot_index)


## 装备武器
func equip_weapon(slot_index: int) -> bool:
	if not _is_valid_slot(slot_index):
		return false

	var slot = slots[slot_index]
	if slot.item_id.is_empty():
		return false

	var item_data = _get_item_data(slot.item_id)
	if item_data.get("type", "") != "weapon":
		return false

	equipped_weapon_slot = slot_index
	weapon_changed.emit(slot.item_id)

	if EventBus:
		EventBus.weapon_equipped.emit(slot.item_id)

	return true


## 卸下武器
func unequip_weapon() -> void:
	equipped_weapon_slot = -1
	weapon_changed.emit("")

	if EventBus:
		EventBus.weapon_equipped.emit("")


## 获取装备的武器ID
func get_equipped_weapon() -> String:
	if equipped_weapon_slot < 0 or equipped_weapon_slot >= slots.size():
		return ""
	return slots[equipped_weapon_slot].item_id


## ==================== 公共方法 - 查询 ====================

## 获取物品数量
func get_item_count(item_id: String) -> int:
	var count = 0
	for slot in slots:
		if slot.item_id == item_id:
			count += slot.quantity
	return count


## 检查是否有物品
func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity


## 查找物品所在槽位 (返回第一个匹配的槽位索引，-1表示未找到)
func find_item(item_id: String) -> int:
	for i in range(slots.size()):
		if slots[i].item_id == item_id:
			return i
	return -1


## 获取槽位信息
func get_slot(slot_index: int) -> Dictionary:
	if not _is_valid_slot(slot_index):
		return {}
	return slots[slot_index].duplicate()


## 获取所有非空槽位
func get_all_items() -> Array:
	var items: Array = []
	for i in range(slots.size()):
		var slot = slots[i]
		if not slot.item_id.is_empty():
			items.append({
				"slot": i,
				"item_id": slot.item_id,
				"quantity": slot.quantity
			})
	return items


## 获取空槽位数量
func get_empty_slots_count() -> int:
	var count = 0
	for slot in slots:
		if slot.item_id.is_empty():
			count += 1
	return count


## 检查背包是否已满
func is_full() -> bool:
	return get_empty_slots_count() == 0


## 检查是否可以添加物品
func can_add_item(item_id: String, quantity: int = 1) -> bool:
	var item_data = _get_item_data(item_id)
	if item_data.is_empty():
		return false

	var stack_max = item_data.get("stack_max", 99)
	var remaining = quantity

	# 检查现有槽位
	for slot in slots:
		if slot.item_id == item_id and slot.quantity < stack_max:
			remaining -= (stack_max - slot.quantity)
		elif slot.item_id.is_empty():
			remaining -= stack_max

		if remaining <= 0:
			return true

	return false


## ==================== 公共方法 - 容量管理 ====================

## 扩展背包容量
func expand_capacity(amount: int) -> void:
	var new_capacity = mini(capacity + amount, MAX_CAPACITY)
	var slots_to_add = new_capacity - capacity

	for i in range(slots_to_add):
		slots.append({"item_id": "", "quantity": 0})

	capacity = new_capacity
	print("[InventoryManager] 背包容量扩展至: %d" % capacity)
	inventory_changed.emit()


## 设置背包容量
func set_capacity(new_capacity: int) -> void:
	new_capacity = clampi(new_capacity, 1, MAX_CAPACITY)

	if new_capacity > capacity:
		expand_capacity(new_capacity - capacity)
	elif new_capacity < capacity:
		# 缩小容量时，移除多余的槽位
		while slots.size() > new_capacity:
			slots.pop_back()
		capacity = new_capacity
		inventory_changed.emit()


## ==================== 公共方法 - 槽位操作 ====================

## 交换两个槽位
func swap_slots(slot1: int, slot2: int) -> bool:
	if not _is_valid_slot(slot1) or not _is_valid_slot(slot2):
		return false

	if slot1 == slot2:
		return false

	var temp = slots[slot1].duplicate()
	slots[slot1] = slots[slot2].duplicate()
	slots[slot2] = temp

	# 更新装备武器槽位
	if equipped_weapon_slot == slot1:
		equipped_weapon_slot = slot2
	elif equipped_weapon_slot == slot2:
		equipped_weapon_slot = slot1

	inventory_changed.emit()
	return true


## 移动物品到指定槽位
func move_to_slot(from_slot: int, to_slot: int) -> bool:
	if not _is_valid_slot(from_slot) or not _is_valid_slot(to_slot):
		return false

	if from_slot == to_slot:
		return false

	var from_item = slots[from_slot]
	var to_item = slots[to_slot]

	# 如果目标槽位为空，直接移动
	if to_item.item_id.is_empty():
		slots[to_slot] = from_item.duplicate()
		_clear_slot(from_slot)
	# 如果是相同物品，尝试堆叠
	elif from_item.item_id == to_item.item_id:
		var item_data = _get_item_data(from_item.item_id)
		var stack_max = item_data.get("stack_max", 99)
		var can_stack = mini(from_item.quantity, stack_max - to_item.quantity)

		to_item.quantity += can_stack
		from_item.quantity -= can_stack

		if from_item.quantity <= 0:
			_clear_slot(from_slot)
	else:
		# 交换
		return swap_slots(from_slot, to_slot)

	# 更新装备武器槽位
	if equipped_weapon_slot == from_slot:
		equipped_weapon_slot = to_slot

	inventory_changed.emit()
	return true


## 清空背包
func clear_all() -> void:
	for i in range(slots.size()):
		_clear_slot(i)
	equipped_weapon_slot = -1
	inventory_changed.emit()


## ==================== 私有方法 ====================

## 初始化槽位
func _initialize_slots() -> void:
	slots.clear()
	for i in range(capacity):
		slots.append({"item_id": "", "quantity": 0})


## 清空槽位
func _clear_slot(slot_index: int) -> void:
	if _is_valid_slot(slot_index):
		slots[slot_index].item_id = ""
		slots[slot_index].quantity = 0

		# 如果清空的是装备武器槽位，取消装备
		if equipped_weapon_slot == slot_index:
			equipped_weapon_slot = -1


## 检查槽位是否有效
func _is_valid_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < slots.size()


## 获取物品数据
func _get_item_data(item_id: String) -> Dictionary:
	if DataManager:
		return DataManager.get_item(item_id)
	return {}


## 检查是否可使用物品
func _can_use_item(item_data: Dictionary) -> bool:
	var item_type = item_data.get("type", "")
	return item_type in ["food", "medical"]


## 检查是否是消耗品
func _is_consumable(item_data: Dictionary) -> bool:
	var item_type = item_data.get("type", "")
	return item_type in ["food", "medical"]


## 应用物品效果
func _apply_item_effects(item_data: Dictionary) -> void:
	var effects = item_data.get("effects", {})

	for effect_name in effects:
		var effect_value = effects[effect_name]

		match effect_name:
			"hp", "health":
				if EventBus:
					# 通过事件通知恢复生命
					EventBus.player_stat_changed.emit("hp", effect_value, 100)
			"hunger":
				if EventBus:
					EventBus.player_stat_changed.emit("hunger", effect_value, 100)
			"stamina":
				if EventBus:
					EventBus.player_stat_changed.emit("stamina", effect_value, 100)
			"morale":
				if EventBus:
					EventBus.player_stat_changed.emit("morale", effect_value, 100)


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	var save_slots: Array = []
	for slot in slots:
		save_slots.append({
			"item_id": slot.item_id,
			"quantity": slot.quantity
		})

	return {
		"capacity": capacity,
		"slots": save_slots,
		"equipped_weapon_slot": equipped_weapon_slot
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	capacity = data.get("capacity", DEFAULT_CAPACITY)
	equipped_weapon_slot = data.get("equipped_weapon_slot", -1)

	var save_slots = data.get("slots", [])
	_initialize_slots()

	for i in range(mini(save_slots.size(), slots.size())):
		slots[i].item_id = save_slots[i].get("item_id", "")
		slots[i].quantity = save_slots[i].get("quantity", 0)

	print("[InventoryManager] 存档数据已加载")
	inventory_changed.emit()
