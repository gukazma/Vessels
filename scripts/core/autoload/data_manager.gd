# data_manager.gd
# 数据管理器 - 加载和管理静态游戏数据
extends Node

## ==================== 常量 ====================

## 数据文件路径
const DATA_DIR: String = "res://data/"
const ITEMS_FILE: String = DATA_DIR + "items.json"
const NPCS_FILE: String = DATA_DIR + "npcs.json"
const PROFESSIONS_FILE: String = DATA_DIR + "professions.json"
const BUILDINGS_FILE: String = DATA_DIR + "buildings.json"

## ==================== 信号 ====================

## 数据加载完成
signal data_loaded()

## 数据加载失败
signal data_load_failed(file: String, error: String)

## ==================== 数据存储 ====================

## 物品数据 (item_id -> item_data)
var items: Dictionary = {}

## NPC数据 (npc_id -> npc_data)
var npcs: Dictionary = {}

## 职业数据 (profession_id -> profession_data)
var professions: Dictionary = {}

## 建筑数据 (building_id -> building_data)
var buildings: Dictionary = {}

## 数据是否已加载
var is_loaded: bool = false

## ==================== 生命周期 ====================

func _ready() -> void:
	print("[DataManager] 数据管理器初始化中...")
	_load_all_data()


## ==================== 公共方法 - 物品 ====================

## 获取物品数据
func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


## 获取物品名称
func get_item_name(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("name", item_id)


## 获取物品类型
func get_item_type(item_id: String) -> String:
	var item = get_item(item_id)
	return item.get("type", "unknown")


## 获取某类型的所有物品
func get_items_by_type(item_type: String) -> Array:
	var result: Array = []
	for id in items:
		if items[id].get("type", "") == item_type:
			result.append(items[id])
	return result


## 获取某稀有度的所有物品
func get_items_by_rarity(rarity: String) -> Array:
	var result: Array = []
	for id in items:
		if items[id].get("rarity", "") == rarity:
			result.append(items[id])
	return result


## 检查物品是否存在
func item_exists(item_id: String) -> bool:
	return items.has(item_id)


## 获取所有物品ID列表
func get_all_item_ids() -> Array:
	return items.keys()


## ==================== 公共方法 - NPC ====================

## 获取NPC数据
func get_npc(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {})


## 获取NPC名称
func get_npc_name(npc_id: String) -> String:
	var npc = get_npc(npc_id)
	return npc.get("name", npc_id)


## 获取NPC属性
func get_npc_stats(npc_id: String) -> Dictionary:
	var npc = get_npc(npc_id)
	return npc.get("stats", {})


## 获取NPC招募所需好感度
func get_npc_recruit_affection(npc_id: String) -> int:
	var npc = get_npc(npc_id)
	return npc.get("recruit_affection", 80)


## 获取NPC招募任务ID
func get_npc_recruit_quest(npc_id: String) -> String:
	var npc = get_npc(npc_id)
	return npc.get("recruit_quest", "")


## 检查NPC是否存在
func npc_exists(npc_id: String) -> bool:
	return npcs.has(npc_id)


## 获取所有NPC ID列表
func get_all_npc_ids() -> Array:
	return npcs.keys()


## ==================== 公共方法 - 职业 ====================

## 获取职业数据
func get_profession(profession_id: String) -> Dictionary:
	return professions.get(profession_id, {})


## 获取职业名称
func get_profession_name(profession_id: String) -> String:
	var profession = get_profession(profession_id)
	return profession.get("name", profession_id)


## 获取职业属性加成
func get_profession_stats(profession_id: String) -> Dictionary:
	var profession = get_profession(profession_id)
	return profession.get("stats", {})


## 获取职业起始物品
func get_profession_start_items(profession_id: String) -> Array:
	var profession = get_profession(profession_id)
	return profession.get("start_items", [])


## 获取职业起始金钱
func get_profession_start_money(profession_id: String) -> int:
	var profession = get_profession(profession_id)
	return profession.get("start_money", 100)


## 获取职业工作信息
func get_profession_work_info(profession_id: String) -> Dictionary:
	var profession = get_profession(profession_id)
	return {
		"workplace": profession.get("workplace", ""),
		"work_hours": profession.get("work_hours", {"start": 9, "end": 18}),
		"daily_wage": profession.get("daily_wage", 80),
		"work_stamina_cost": profession.get("work_stamina_cost", 30)
	}


## 检查职业是否存在
func profession_exists(profession_id: String) -> bool:
	return professions.has(profession_id)


## 获取所有职业ID列表
func get_all_profession_ids() -> Array:
	return professions.keys()


## ==================== 公共方法 - 建筑 ====================

## 获取建筑数据
func get_building(building_id: String) -> Dictionary:
	return buildings.get(building_id, {})


## 获取建筑名称
func get_building_name(building_id: String) -> String:
	var building = get_building(building_id)
	return building.get("name", building_id)


## 获取建筑所需材料
func get_building_materials(building_id: String) -> Dictionary:
	var building = get_building(building_id)
	return building.get("materials", {})


## 获取建筑效果
func get_building_effects(building_id: String) -> Dictionary:
	var building = get_building(building_id)
	return building.get("effects", {})


## 获取建筑解锁等级
func get_building_unlock_level(building_id: String) -> int:
	var building = get_building(building_id)
	return building.get("unlock_level", 1)


## 获取某类型的所有建筑
func get_buildings_by_category(category: String) -> Array:
	var result: Array = []
	for id in buildings:
		if buildings[id].get("category", "") == category:
			result.append(buildings[id])
	return result


## 获取指定等级可用的建筑
func get_buildings_by_level(level: int) -> Array:
	var result: Array = []
	for id in buildings:
		if buildings[id].get("unlock_level", 1) <= level:
			result.append(buildings[id])
	return result


## 检查建筑是否存在
func building_exists(building_id: String) -> bool:
	return buildings.has(building_id)


## 获取所有建筑ID列表
func get_all_building_ids() -> Array:
	return buildings.keys()


## ==================== 私有方法 ====================

## 加载所有数据
func _load_all_data() -> void:
	var success = true

	# 加载物品数据
	if not _load_items():
		success = false

	# 加载NPC数据
	if not _load_npcs():
		success = false

	# 加载职业数据
	if not _load_professions():
		success = false

	# 加载建筑数据
	if not _load_buildings():
		success = false

	if success:
		is_loaded = true
		print("[DataManager] 所有数据加载完成")
		print("  - 物品: %d" % items.size())
		print("  - NPC: %d" % npcs.size())
		print("  - 职业: %d" % professions.size())
		print("  - 建筑: %d" % buildings.size())
		data_loaded.emit()
	else:
		print("[DataManager] 部分数据加载失败")


## 加载物品数据
func _load_items() -> bool:
	var data = _load_json_file(ITEMS_FILE)
	if data.is_empty():
		# 如果文件不存在，使用默认数据
		print("[DataManager] 物品数据文件不存在，使用默认数据")
		items = _get_default_items()
		return true

	items = data
	return true


## 加载NPC数据
func _load_npcs() -> bool:
	var data = _load_json_file(NPCS_FILE)
	if data.is_empty():
		print("[DataManager] NPC数据文件不存在，使用默认数据")
		npcs = _get_default_npcs()
		return true

	npcs = data
	return true


## 加载职业数据
func _load_professions() -> bool:
	var data = _load_json_file(PROFESSIONS_FILE)
	if data.is_empty():
		print("[DataManager] 职业数据文件不存在，使用默认数据")
		professions = _get_default_professions()
		return true

	professions = data
	return true


## 加载建筑数据
func _load_buildings() -> bool:
	var data = _load_json_file(BUILDINGS_FILE)
	if data.is_empty():
		print("[DataManager] 建筑数据文件不存在，使用默认数据")
		buildings = _get_default_buildings()
		return true

	buildings = data
	return true


## 加载JSON文件
func _load_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("[DataManager] 文件不存在: %s" % file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error_msg = "无法打开文件: %s" % file_path
		print("[DataManager] %s" % error_msg)
		data_load_failed.emit(file_path, error_msg)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		var error_msg = "JSON解析错误: %s (行 %d)" % [json.get_error_message(), json.get_error_line()]
		print("[DataManager] %s" % error_msg)
		data_load_failed.emit(file_path, error_msg)
		return {}

	return json.get_data()


## ==================== 默认数据 (备用) ====================

## 默认物品数据
func _get_default_items() -> Dictionary:
	return {
		"F001": {
			"id": "F001",
			"name": "面包",
			"type": "food",
			"rarity": "common",
			"effects": {"hunger": 20},
			"price": 10,
			"stack_max": 10,
			"description": "新鲜的面包，基础食物"
		},
		"F002": {
			"id": "F002",
			"name": "罐头",
			"type": "food",
			"rarity": "common",
			"effects": {"hunger": 30},
			"special": "no_spoil",
			"price": 25,
			"stack_max": 10,
			"description": "保质期很长的罐头食品"
		},
		"W001": {
			"id": "W001",
			"name": "棒球棍",
			"type": "weapon",
			"subtype": "melee",
			"rarity": "common",
			"damage": 15,
			"attack_speed": 1.0,
			"durability": 50,
			"price": 50,
			"stack_max": 1,
			"description": "运动用品店的常见货物"
		},
		"M001": {
			"id": "M001",
			"name": "木材",
			"type": "material",
			"rarity": "common",
			"price": 5,
			"stack_max": 50,
			"description": "建造的基础材料"
		},
		"H001": {
			"id": "H001",
			"name": "绷带",
			"type": "medical",
			"rarity": "common",
			"effects": {"hp": 20},
			"price": 15,
			"stack_max": 5,
			"description": "基础的伤口处理"
		}
	}


## 默认NPC数据
func _get_default_npcs() -> Dictionary:
	return {
		"li_qiang": {
			"id": "li_qiang",
			"name": "李强",
			"age": 45,
			"profession": "保安",
			"stats": {"combat": 8, "build": 4, "medical": 2, "social": 3, "cooking": 5},
			"traits": ["calm", "taciturn", "responsible"],
			"recruit_affection": 80,
			"recruit_quest": "protect_resident",
			"spawn_locations": ["residential_gate", "supermarket"],
			"skills": ["tactical_command", "emergency_defense"],
			"description": "在部队待了二十年，什么场面没见过。"
		},
		"chen_yuqing": {
			"id": "chen_yuqing",
			"name": "陈雨晴",
			"age": 28,
			"profession": "护士",
			"stats": {"combat": 1, "build": 2, "medical": 9, "social": 6, "cooking": 4},
			"traits": ["kind", "careful", "timid"],
			"recruit_affection": 70,
			"recruit_quest": "save_infected",
			"spawn_locations": ["hospital", "pharmacy"],
			"skills": ["professional_care", "emergency_surgery"],
			"description": "在急诊室工作了五年，本以为见惯了生死。"
		},
		"wang_dachui": {
			"id": "wang_dachui",
			"name": "王大厨",
			"age": 52,
			"profession": "餐馆老板",
			"stats": {"combat": 3, "build": 3, "medical": 1, "social": 7, "cooking": 10},
			"traits": ["optimistic", "talkative", "nostalgic"],
			"recruit_affection": 80,
			"recruit_quest": "last_supper",
			"spawn_locations": ["restaurant", "market"],
			"skills": ["master_cooking", "feast"],
			"description": "开了三十年的馆子，末日来了也不能让大家饿肚子。"
		}
	}


## 默认职业数据
func _get_default_professions() -> Dictionary:
	return {
		"office_worker": {
			"id": "office_worker",
			"name": "办公室职员",
			"stats": {"combat": 0, "build": 0, "medical": 0, "social": 5, "cooking": 2},
			"start_items": ["briefcase", "energy_drink", "energy_drink", "energy_drink", "smartphone"],
			"start_money": 200,
			"workplace": "office",
			"work_hours": {"start": 9, "end": 18},
			"daily_wage": 80,
			"work_stamina_cost": 30,
			"skills": ["network", "ppt_power"],
			"description": "每天朝九晚五，在格子间里对着电脑发呆。"
		},
		"construction_worker": {
			"id": "construction_worker",
			"name": "建筑工人",
			"stats": {"combat": 3, "build": 5, "medical": 0, "social": 0, "cooking": 1},
			"start_items": ["safety_helmet", "toolbox", "lunch_box", "lunch_box"],
			"start_money": 120,
			"workplace": "construction_site",
			"work_hours": {"start": 7, "end": 17},
			"daily_wage": 100,
			"work_stamina_cost": 50,
			"skills": ["iron_man", "emergency_fortify"],
			"description": "搬砖搬了十年，手上的老茧比脸皮还厚。"
		},
		"doctor": {
			"id": "doctor",
			"name": "医生",
			"stats": {"combat": 0, "build": 0, "medical": 10, "social": 3, "cooking": 0},
			"start_items": ["medical_kit", "scalpel", "antibiotics", "antibiotics"],
			"start_money": 300,
			"workplace": "hospital",
			"work_hours": {"start": 8, "end": 20},
			"daily_wage": 150,
			"work_stamina_cost": 40,
			"skills": ["diagnosis", "first_aid"],
			"description": "在医院见惯了生死，你以为自己已经麻木了。"
		}
	}


## 默认建筑数据
func _get_default_buildings() -> Dictionary:
	return {
		"bed_simple": {
			"id": "bed_simple",
			"name": "简易床位",
			"category": "living",
			"unlock_level": 1,
			"materials": {"wood": 5, "cloth": 3},
			"build_time": 1,
			"effects": {"population_max": 1, "comfort": 5},
			"size": [1, 1],
			"description": "有个睡觉的地方总比没有强"
		},
		"fence_wood": {
			"id": "fence_wood",
			"name": "木栅栏",
			"category": "defense",
			"unlock_level": 1,
			"materials": {"wood": 10},
			"build_time": 2,
			"effects": {"defense": 10},
			"durability": 50,
			"description": "最基础的防御，聊胜于无"
		},
		"kitchen_simple": {
			"id": "kitchen_simple",
			"name": "简易厨房",
			"category": "functional",
			"unlock_level": 1,
			"materials": {"wood": 10, "metal": 5},
			"build_time": 2,
			"effects": {"food_efficiency": 1.2},
			"description": "热食总比冷食强"
		},
		"medical_room": {
			"id": "medical_room",
			"name": "医疗室",
			"category": "functional",
			"unlock_level": 1,
			"materials": {"wood": 8, "cloth": 5},
			"build_time": 2,
			"effects": {"healing_efficiency": 1.3},
			"description": "总比在地上治疗强"
		},
		"workbench": {
			"id": "workbench",
			"name": "工作台",
			"category": "functional",
			"unlock_level": 1,
			"materials": {"wood": 10, "metal": 10},
			"build_time": 3,
			"effects": {"can_craft": true},
			"description": "必备的生产设施"
		}
	}
