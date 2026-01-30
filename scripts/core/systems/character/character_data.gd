# character_data.gd
# 角色数据类 - 定义NPC和队员的属性
class_name CharacterData
extends Resource

## ==================== 枚举 ====================

## 角色状态
enum CharacterState {
	UNKNOWN,    ## 未遇到
	MET,        ## 已遇到
	FRIENDLY,   ## 友好
	RECRUITED,  ## 已招募
	DEAD        ## 死亡
}

## 任务类型
enum TaskType {
	NONE,       ## 无任务
	SCAVENGE,   ## 搜刮
	BUILD,      ## 建造
	GUARD,      ## 守卫
	COOK,       ## 烹饪
	HEAL,       ## 医疗
	REST        ## 休息
}

## ==================== 基础信息 ====================

## 角色ID
@export var id: String = ""

## 角色名称
@export var name_cn: String = ""

## 年龄
@export var age: int = 30

## 职业
@export var profession: String = ""

## 描述/背景故事
@export var description: String = ""

## ==================== 属性 ====================

## 战斗属性 (0-10)
@export_range(0, 10) var combat: int = 0

## 建造属性 (0-10)
@export_range(0, 10) var build: int = 0

## 医疗属性 (0-10)
@export_range(0, 10) var medical: int = 0

## 社交属性 (0-10)
@export_range(0, 10) var social: int = 0

## 烹饪属性 (0-10)
@export_range(0, 10) var cooking: int = 0

## ==================== 状态 ====================

## 当前状态
@export var state: CharacterState = CharacterState.UNKNOWN

## 当前生命值
@export var current_hp: float = 100.0

## 最大生命值
@export var max_hp: float = 100.0

## 当前士气
@export var morale: int = 50

## ==================== 关系 ====================

## 好感度 (0-100)
@export_range(0, 100) var affection: int = 0

## 招募所需好感度
@export var recruit_affection: int = 80

## 招募任务ID
@export var recruit_quest: String = ""

## ==================== 特性和技能 ====================

## 性格特点
@export var traits: Array[String] = []

## 技能列表
@export var skills: Array[String] = []

## ==================== 当前任务 ====================

## 当前分配的任务类型
@export var current_task: TaskType = TaskType.NONE

## 任务目标位置
@export var task_target: String = ""

## ==================== 方法 ====================

## 从字典创建角色数据
static func from_dict(data: Dictionary) -> CharacterData:
	var character = CharacterData.new()
	character.id = data.get("id", "")
	character.name_cn = data.get("name", "")
	character.age = data.get("age", 30)
	character.profession = data.get("profession", "")
	character.description = data.get("description", "")

	# 解析属性
	var stats = data.get("stats", {})
	character.combat = stats.get("combat", 0)
	character.build = stats.get("build", 0)
	character.medical = stats.get("medical", 0)
	character.social = stats.get("social", 0)
	character.cooking = stats.get("cooking", 0)

	# 解析关系
	character.recruit_affection = data.get("recruit_affection", 80)
	character.recruit_quest = data.get("recruit_quest", "")

	# 解析特性和技能
	character.traits = Array(data.get("traits", []), TYPE_STRING, "", null)
	character.skills = Array(data.get("skills", []), TYPE_STRING, "", null)

	return character


## 转换为字典
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name_cn,
		"age": age,
		"profession": profession,
		"description": description,
		"stats": {
			"combat": combat,
			"build": build,
			"medical": medical,
			"social": social,
			"cooking": cooking
		},
		"state": state,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"morale": morale,
		"affection": affection,
		"recruit_affection": recruit_affection,
		"recruit_quest": recruit_quest,
		"traits": traits,
		"skills": skills,
		"current_task": current_task,
		"task_target": task_target
	}


## 获取属性评价
func get_stat_rating(stat_value: int) -> String:
	if stat_value <= 2:
		return "无能"
	elif stat_value <= 4:
		return "普通"
	elif stat_value <= 6:
		return "熟练"
	elif stat_value <= 8:
		return "精通"
	else:
		return "大师"


## 获取战斗评价
func get_combat_rating() -> String:
	return get_stat_rating(combat)


## 获取建造评价
func get_build_rating() -> String:
	return get_stat_rating(build)


## 获取医疗评价
func get_medical_rating() -> String:
	return get_stat_rating(medical)


## 获取社交评价
func get_social_rating() -> String:
	return get_stat_rating(social)


## 获取烹饪评价
func get_cooking_rating() -> String:
	return get_stat_rating(cooking)


## 获取好感度等级
func get_affection_level() -> String:
	if affection < 20:
		return "陌生人"
	elif affection < 40:
		return "熟人"
	elif affection < 60:
		return "朋友"
	elif affection < 80:
		return "挚友"
	else:
		return "伙伴"


## 增加好感度
func add_affection(amount: int) -> void:
	affection = clampi(affection + amount, 0, 100)


## 检查是否可招募
func can_recruit() -> bool:
	return state == CharacterState.MET or state == CharacterState.FRIENDLY
	# 还需要检查:
	# - 好感度是否达到要求
	# - 是否完成招募任务
	# - 据点是否有床位


## 检查是否达到招募好感度
func has_enough_affection() -> bool:
	return affection >= recruit_affection


## 招募角色
func recruit() -> void:
	state = CharacterState.RECRUITED
	morale = 60  # 初始士气


## 分配任务
func assign_task(task: TaskType, target: String = "") -> void:
	current_task = task
	task_target = target


## 清除任务
func clear_task() -> void:
	current_task = TaskType.NONE
	task_target = ""


## 获取任务效率 (基于属性)
func get_task_efficiency(task: TaskType) -> float:
	var base_efficiency = 1.0
	var stat_bonus = 0.0

	match task:
		TaskType.SCAVENGE:
			stat_bonus = social * 0.05  # 社交影响搜刮
		TaskType.BUILD:
			stat_bonus = build * 0.1
		TaskType.GUARD:
			stat_bonus = combat * 0.1
		TaskType.COOK:
			stat_bonus = cooking * 0.1
		TaskType.HEAL:
			stat_bonus = medical * 0.1
		TaskType.REST:
			stat_bonus = 0.0

	# 士气影响
	var morale_modifier = 1.0
	if morale < 20:
		morale_modifier = 0.5
	elif morale < 40:
		morale_modifier = 0.8
	elif morale > 80:
		morale_modifier = 1.2

	return (base_efficiency + stat_bonus) * morale_modifier


## 受伤
func take_damage(amount: float) -> void:
	current_hp = maxf(0, current_hp - amount)
	if current_hp <= 0:
		state = CharacterState.DEAD


## 治疗
func heal(amount: float) -> void:
	current_hp = minf(max_hp, current_hp + amount)


## 检查是否存活
func is_alive() -> bool:
	return state != CharacterState.DEAD


## 检查是否是队员
func is_recruited() -> bool:
	return state == CharacterState.RECRUITED


## 获取生命值百分比
func get_hp_percent() -> float:
	return current_hp / max_hp if max_hp > 0 else 0.0
