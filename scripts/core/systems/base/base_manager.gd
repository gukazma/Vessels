# base_manager.gd
# 据点系统 - 管理据点建设和资源
class_name BaseManager
extends Node

## ==================== 信号 ====================

## 据点属性变化
signal stat_changed(stat: String, old_value: float, new_value: float)

## 据点等级提升
signal level_up(new_level: int)

## 建筑建造开始
signal building_started(building_id: String)

## 建筑建造完成
signal building_completed(building_id: String)

## 建筑被摧毁
signal building_destroyed(building_id: String)

## 据点被攻击
signal base_attacked(damage: float)

## 资源不足
signal resource_insufficient(resource: String, required: int, available: int)

## ==================== 常量 ====================

## 基础每日食物消耗 (每人)
const FOOD_PER_PERSON: int = 10

## 等级要求
const LEVEL_REQUIREMENTS: Dictionary = {
	2: {"defense": 100, "comfort": 50, "population": 2},
	3: {"defense": 150, "comfort": 70, "population": 5},
	4: {"defense": 200, "comfort": 90, "population": 8}
}

## ==================== 变量 ====================

## 据点等级
var level: int = 1

## 防御值
var defense: float = 50.0

## 最大防御值
var defense_max: float = 200.0

## 食物存储
var food_storage: int = 0

## 食物容量
var food_capacity: int = 50

## 舒适度
var comfort: float = 30.0

## 当前人口
var population: int = 1

## 人口上限
var population_max: int = 2

## 已建造的建筑列表
var buildings: Array = []

## 正在建造的建筑
var building_queue: Array = []

## ==================== 生命周期 ====================

func _ready() -> void:
	print("[BaseManager] 据点系统已初始化")

	# 连接事件
	if EventBus:
		EventBus.day_changed.connect(_on_day_changed)


## ==================== 公共方法 - 属性管理 ====================

## 设置防御值
func set_defense(value: float) -> void:
	var old_value = defense
	defense = clampf(value, 0, defense_max)
	if defense != old_value:
		_emit_stat_changed("defense", old_value, defense)


## 增加防御值
func add_defense(amount: float) -> void:
	set_defense(defense + amount)


## 设置食物存储
func set_food(value: int) -> void:
	var old_value = food_storage
	food_storage = clampi(value, 0, food_capacity)
	if food_storage != old_value:
		_emit_stat_changed("food_storage", old_value, food_storage)


## 增加食物
func add_food(amount: int) -> void:
	set_food(food_storage + amount)


## 消耗食物
func consume_food(amount: int) -> bool:
	if food_storage >= amount:
		set_food(food_storage - amount)
		return true
	return false


## 设置舒适度
func set_comfort(value: float) -> void:
	var old_value = comfort
	comfort = clampf(value, 0, 100)
	if comfort != old_value:
		_emit_stat_changed("comfort", old_value, comfort)


## 增加舒适度
func add_comfort(amount: float) -> void:
	set_comfort(comfort + amount)


## 设置人口
func set_population(value: int) -> void:
	var old_value = population
	population = clampi(value, 0, population_max)
	if population != old_value:
		_emit_stat_changed("population", old_value, population)


## 增加人口上限
func add_population_max(amount: int) -> void:
	population_max += amount
	_emit_stat_changed("population_max", population_max - amount, population_max)


## ==================== 公共方法 - 建筑管理 ====================

## 建造建筑
func build(building_id: String, position: Vector2 = Vector2.ZERO) -> bool:
	var building_data = _get_building_data(building_id)
	if building_data.is_empty():
		print("[BaseManager] 建筑不存在: %s" % building_id)
		return false

	# 检查等级要求
	var unlock_level = building_data.get("unlock_level", 1)
	if level < unlock_level:
		print("[BaseManager] 据点等级不足: 需要等级 %d" % unlock_level)
		return false

	# 检查材料
	var materials = building_data.get("materials", {})
	if not _check_materials(materials):
		return false

	# 消耗材料
	_consume_materials(materials)

	# 添加到建造队列
	var build_time = building_data.get("build_time", 1)
	building_queue.append({
		"id": building_id,
		"position": position,
		"remaining_time": build_time,
		"data": building_data
	})

	building_started.emit(building_id)
	if EventBus:
		EventBus.building_construction_started.emit(building_id, position)

	print("[BaseManager] 开始建造: %s (需要 %d 小时)" % [building_data.get("name", building_id), build_time])
	return true


## 完成建筑建造
func complete_building(building_id: String) -> void:
	# 从队列中查找
	for i in range(building_queue.size() - 1, -1, -1):
		if building_queue[i].id == building_id:
			var building = building_queue[i]
			building_queue.remove_at(i)

			# 添加到已建造列表
			buildings.append({
				"id": building_id,
				"position": building.position,
				"durability": building.data.get("durability", -1)
			})

			# 应用建筑效果
			_apply_building_effects(building.data.get("effects", {}))

			building_completed.emit(building_id)
			if EventBus:
				EventBus.building_construction_completed.emit(building_id)

			print("[BaseManager] 建造完成: %s" % building.data.get("name", building_id))
			break


## 摧毁建筑
func destroy_building(index: int) -> void:
	if index < 0 or index >= buildings.size():
		return

	var building = buildings[index]
	var building_data = _get_building_data(building.id)

	# 移除建筑效果
	_remove_building_effects(building_data.get("effects", {}))

	buildings.remove_at(index)

	building_destroyed.emit(building.id)
	if EventBus:
		EventBus.building_destroyed.emit(building.id)

	print("[BaseManager] 建筑被摧毁: %s" % building.id)


## 修复建筑
func repair_building(index: int, amount: int) -> void:
	if index < 0 or index >= buildings.size():
		return

	var building = buildings[index]
	var building_data = _get_building_data(building.id)
	var max_durability = building_data.get("durability", -1)

	if max_durability > 0 and building.has("durability"):
		building.durability = mini(building.durability + amount, max_durability)


## 获取建筑列表
func get_buildings() -> Array:
	return buildings.duplicate()


## 获取建造队列
func get_building_queue() -> Array:
	return building_queue.duplicate()


## 检查是否有指定建筑
func has_building(building_id: String) -> bool:
	for building in buildings:
		if building.id == building_id:
			return true
	return false


## 统计指定建筑数量
func count_building(building_id: String) -> int:
	var count = 0
	for building in buildings:
		if building.id == building_id:
			count += 1
	return count


## ==================== 公共方法 - 等级管理 ====================

## 检查升级条件
func can_level_up() -> bool:
	var next_level = level + 1
	if not LEVEL_REQUIREMENTS.has(next_level):
		return false

	var req = LEVEL_REQUIREMENTS[next_level]
	return defense >= req.defense and comfort >= req.comfort and population >= req.population


## 尝试升级
func try_level_up() -> bool:
	if can_level_up():
		level += 1
		level_up.emit(level)
		if EventBus:
			EventBus.base_level_up.emit(level)
		print("[BaseManager] 据点升级到等级 %d" % level)
		return true
	return false


## 获取升级要求
func get_level_requirements(target_level: int) -> Dictionary:
	return LEVEL_REQUIREMENTS.get(target_level, {})


## ==================== 公共方法 - 战斗相关 ====================

## 据点受到攻击
func take_damage(damage: float) -> void:
	var actual_damage = maxf(0, damage - defense * 0.5)
	add_defense(-actual_damage)

	base_attacked.emit(actual_damage)
	if EventBus:
		EventBus.base_attacked.emit(actual_damage)

	# 检查建筑耐久度损耗
	_damage_buildings(actual_damage * 0.1)


## 夜间防御结算
func process_night_defense(zombie_count: int) -> Dictionary:
	# 计算僵尸总攻击力 (每只僵尸 15 点攻击)
	var zombie_attack = zombie_count * 15.0

	# 计算防御减免
	var defense_reduction = defense * 0.5

	# 计算守卫输出
	var guard_output = _calculate_guard_output()

	# 计算最终伤害
	var final_damage = maxf(0, zombie_attack - defense_reduction - guard_output)

	# 应用伤害
	take_damage(final_damage)

	return {
		"zombie_attack": zombie_attack,
		"defense_reduction": defense_reduction,
		"guard_output": guard_output,
		"final_damage": final_damage,
		"survived": defense > 0
	}


## ==================== 公共方法 - 每日结算 ====================

## 每日消耗计算
func process_daily_consumption() -> Dictionary:
	var result = {
		"food_consumed": 0,
		"food_shortage": 0,
		"comfort_effect": ""
	}

	# 计算食物消耗 (规模效益)
	var food_per_person = FOOD_PER_PERSON
	if population >= 7:
		food_per_person = 7
	elif population >= 4:
		food_per_person = 8
	elif population >= 2:
		food_per_person = 9

	var food_needed = food_per_person * population
	result.food_consumed = mini(food_needed, food_storage)
	result.food_shortage = food_needed - result.food_consumed

	# 消耗食物
	consume_food(result.food_consumed)

	# 舒适度效果
	if comfort <= 20:
		result.comfort_effect = "士气-10，恢复-50%"
	elif comfort <= 40:
		result.comfort_effect = "士气-5"
	elif comfort <= 60:
		result.comfort_effect = "无"
	elif comfort <= 80:
		result.comfort_effect = "士气+5，恢复+20%"
	else:
		result.comfort_effect = "士气+10，恢复+50%"

	return result


## ==================== 私有方法 ====================

## 获取建筑数据
func _get_building_data(building_id: String) -> Dictionary:
	if DataManager:
		return DataManager.get_building(building_id)
	return {}


## 检查材料是否足够
func _check_materials(materials: Dictionary) -> bool:
	# TODO: 与 InventoryManager 集成检查材料
	for material_id in materials:
		var required = materials[material_id]
		# 暂时假设材料足够
		# var available = InventoryManager.get_item_count(material_id)
		# if available < required:
		#     resource_insufficient.emit(material_id, required, available)
		#     return false
	return true


## 消耗材料
func _consume_materials(materials: Dictionary) -> void:
	# TODO: 与 InventoryManager 集成消耗材料
	for material_id in materials:
		var amount = materials[material_id]
		# InventoryManager.remove_item(material_id, amount)
	pass


## 应用建筑效果
func _apply_building_effects(effects: Dictionary) -> void:
	for effect in effects:
		match effect:
			"defense":
				add_defense(effects[effect])
			"comfort":
				add_comfort(effects[effect])
			"population_max":
				add_population_max(effects[effect])
			"food_capacity":
				food_capacity += effects[effect]


## 移除建筑效果
func _remove_building_effects(effects: Dictionary) -> void:
	for effect in effects:
		match effect:
			"defense":
				add_defense(-effects[effect])
			"comfort":
				add_comfort(-effects[effect])
			"population_max":
				population_max = maxi(1, population_max - effects[effect])
			"food_capacity":
				food_capacity = maxi(10, food_capacity - effects[effect])


## 建筑耐久度损耗
func _damage_buildings(damage: float) -> void:
	for i in range(buildings.size() - 1, -1, -1):
		var building = buildings[i]
		if building.has("durability") and building.durability > 0:
			building.durability -= int(damage)
			if building.durability <= 0:
				destroy_building(i)


## 计算守卫输出
func _calculate_guard_output() -> float:
	# TODO: 与 CharacterManager 集成计算守卫输出
	return 0.0


## 发送属性变化信号
func _emit_stat_changed(stat: String, old_value: float, new_value: float) -> void:
	stat_changed.emit(stat, old_value, new_value)
	if EventBus:
		EventBus.base_stat_changed.emit(stat, new_value)


## 天数变化处理
func _on_day_changed(_day: int) -> void:
	# 处理每日消耗
	var result = process_daily_consumption()
	print("[BaseManager] 每日消耗: 食物 %d, 短缺 %d" % [result.food_consumed, result.food_shortage])


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	return {
		"level": level,
		"defense": defense,
		"defense_max": defense_max,
		"food_storage": food_storage,
		"food_capacity": food_capacity,
		"comfort": comfort,
		"population": population,
		"population_max": population_max,
		"buildings": buildings.duplicate(),
		"building_queue": building_queue.duplicate()
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	level = data.get("level", 1)
	defense = data.get("defense", 50.0)
	defense_max = data.get("defense_max", 200.0)
	food_storage = data.get("food_storage", 0)
	food_capacity = data.get("food_capacity", 50)
	comfort = data.get("comfort", 30.0)
	population = data.get("population", 1)
	population_max = data.get("population_max", 2)
	buildings = data.get("buildings", [])
	building_queue = data.get("building_queue", [])

	print("[BaseManager] 存档数据已加载，等级: %d" % level)
