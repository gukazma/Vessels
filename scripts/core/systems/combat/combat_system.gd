# combat_system.gd
# 战斗系统 - 处理战斗相关逻辑
class_name CombatSystem
extends Node

## ==================== 信号 ====================

## 伤害造成
signal damage_dealt(attacker: Node, target: Node, damage: float)

## 实体死亡
signal entity_killed(entity: Node, killer: Node)

## 战斗开始
signal combat_started()

## 战斗结束
signal combat_ended()

## ==================== 常量 ====================

## 基础攻击力 (徒手)
const BASE_ATTACK: float = 5.0

## 基础攻击速度
const BASE_ATTACK_SPEED: float = 1.5

## 基础命中率
const BASE_HIT_CHANCE: float = 0.9

## ==================== 变量 ====================

## 是否处于战斗状态
var is_in_combat: bool = false

## 当前战斗中的实体列表
var combat_entities: Array = []

## ==================== 生命周期 ====================

func _ready() -> void:
	print("[CombatSystem] 战斗系统已初始化")


## ==================== 公共方法 - 伤害计算 ====================

## 计算攻击伤害
## attacker_stats: 攻击者属性 {combat, weapon_damage, weapon_speed}
## defender_stats: 防御者属性 {defense}
func calculate_damage(attacker_stats: Dictionary, defender_stats: Dictionary = {}) -> Dictionary:
	# 获取攻击者属性
	var combat_stat = attacker_stats.get("combat", 0)
	var weapon_damage = attacker_stats.get("weapon_damage", 0.0)
	var weapon_speed = attacker_stats.get("weapon_speed", 1.0)

	# 计算基础伤害
	# 公式: 武器伤害 + 战斗属性 * 2
	var base_damage = weapon_damage if weapon_damage > 0 else BASE_ATTACK
	var stat_bonus = combat_stat * 2.0
	var total_damage = base_damage + stat_bonus

	# 计算命中率
	# 公式: 90% + 战斗属性 * 2%
	var hit_chance = BASE_HIT_CHANCE + combat_stat * 0.02

	# 计算DPS
	var actual_speed = weapon_speed if weapon_damage > 0 else BASE_ATTACK_SPEED
	var dps = total_damage * actual_speed

	# 应用防御减免 (如果有)
	var defense = defender_stats.get("defense", 0.0)
	var final_damage = maxf(1, total_damage - defense * 0.5)

	return {
		"base_damage": base_damage,
		"stat_bonus": stat_bonus,
		"total_damage": total_damage,
		"final_damage": final_damage,
		"hit_chance": hit_chance,
		"attack_speed": actual_speed,
		"dps": dps
	}


## 执行攻击
func perform_attack(attacker: Node, target: Node, attacker_stats: Dictionary) -> Dictionary:
	var result = {
		"hit": false,
		"damage": 0.0,
		"critical": false,
		"killed": false
	}

	# 计算伤害
	var damage_info = calculate_damage(attacker_stats)

	# 命中判定
	if randf() <= damage_info.hit_chance:
		result.hit = true
		result.damage = damage_info.final_damage

		# 暴击判定 (10%几率，伤害翻倍)
		if randf() <= 0.1:
			result.critical = true
			result.damage *= 2.0

		# 应用伤害
		if target.has_method("take_damage"):
			target.take_damage(result.damage, attacker)

		# 发送信号
		damage_dealt.emit(attacker, target, result.damage)

		# 检查是否击杀
		if target.has_method("is_alive") and not target.is_alive():
			result.killed = true
			entity_killed.emit(target, attacker)

	return result


## ==================== 公共方法 - 战斗状态 ====================

## 开始战斗
func start_combat(entities: Array = []) -> void:
	if is_in_combat:
		return

	is_in_combat = true
	combat_entities = entities

	combat_started.emit()
	if EventBus:
		EventBus.combat_started.emit()

	print("[CombatSystem] 战斗开始")


## 结束战斗
func end_combat() -> void:
	if not is_in_combat:
		return

	is_in_combat = false
	combat_entities.clear()

	combat_ended.emit()
	if EventBus:
		EventBus.combat_ended.emit()

	print("[CombatSystem] 战斗结束")


## 添加战斗实体
func add_combat_entity(entity: Node) -> void:
	if entity not in combat_entities:
		combat_entities.append(entity)


## 移除战斗实体
func remove_combat_entity(entity: Node) -> void:
	combat_entities.erase(entity)

	# 如果没有敌对实体了，结束战斗
	if _count_enemies() == 0:
		end_combat()


## ==================== 公共方法 - 武器相关 ====================

## 获取武器属性
func get_weapon_stats(weapon_id: String) -> Dictionary:
	if weapon_id.is_empty():
		return {
			"damage": BASE_ATTACK,
			"speed": BASE_ATTACK_SPEED,
			"type": "melee",
			"range": 32.0  # 近战范围 (像素)
		}

	var item_data = {}
	if DataManager:
		item_data = DataManager.get_item(weapon_id)

	return {
		"damage": item_data.get("damage", BASE_ATTACK),
		"speed": item_data.get("attack_speed", BASE_ATTACK_SPEED),
		"type": item_data.get("subtype", "melee"),
		"range": 32.0 if item_data.get("subtype", "melee") == "melee" else 200.0,
		"durability": item_data.get("durability", -1)
	}


## 计算击杀时间 (秒)
func calculate_time_to_kill(attacker_stats: Dictionary, target_hp: float) -> float:
	var damage_info = calculate_damage(attacker_stats)
	if damage_info.dps <= 0:
		return INF
	return target_hp / damage_info.dps


## ==================== 公共方法 - 僵尸相关 ====================

## 获取普通僵尸属性
func get_zombie_stats(zombie_type: String = "normal") -> Dictionary:
	match zombie_type:
		"normal":
			return {
				"hp": 50.0,
				"attack": 15.0,
				"attack_speed": 0.8,
				"move_speed": 70.0,  # 玩家的70%
				"detection_range": 150.0,
				"attack_range": 24.0
			}
		"fast":
			return {
				"hp": 30.0,
				"attack": 10.0,
				"attack_speed": 1.2,
				"move_speed": 100.0,
				"detection_range": 200.0,
				"attack_range": 24.0
			}
		"tank":
			return {
				"hp": 150.0,
				"attack": 25.0,
				"attack_speed": 0.5,
				"move_speed": 50.0,
				"detection_range": 100.0,
				"attack_range": 32.0
			}
		_:
			return get_zombie_stats("normal")


## 应用难度修正
func apply_difficulty_modifier(stats: Dictionary) -> Dictionary:
	var modifier = {}
	if GameManager:
		modifier = GameManager.get_difficulty_config()

	var hp_mult = modifier.get("zombie_health_multiplier", 1.0)
	var dmg_mult = modifier.get("zombie_damage_multiplier", 1.0)

	return {
		"hp": stats.get("hp", 50.0) * hp_mult,
		"attack": stats.get("attack", 15.0) * dmg_mult,
		"attack_speed": stats.get("attack_speed", 0.8),
		"move_speed": stats.get("move_speed", 70.0),
		"detection_range": stats.get("detection_range", 150.0),
		"attack_range": stats.get("attack_range", 24.0)
	}


## ==================== 公共方法 - 夜间防御 ====================

## 计算夜间防御战结果
func simulate_night_defense(
	day: int,
	team_combat_power: int,
	base_defense: float
) -> Dictionary:
	# 计算僵尸数量 (根据天数)
	var zombie_count = _calculate_zombie_count(day)

	# 计算僵尸总攻击力
	var zombie_stats = get_zombie_stats("normal")
	zombie_stats = apply_difficulty_modifier(zombie_stats)
	var zombie_total_attack = zombie_count * zombie_stats.attack

	# 计算防御减免
	var defense_reduction = base_defense * 0.5

	# 计算团队输出 (每轮战斗，假设5轮)
	var team_dps = team_combat_power * 3.0  # 简化计算
	var team_total_output = team_dps * 5.0

	# 计算僵尸存活数量
	var zombie_hp_total = zombie_count * zombie_stats.hp
	var zombies_killed = mini(zombie_count, int(team_total_output / zombie_stats.hp))
	var zombies_survived = zombie_count - zombies_killed

	# 计算最终伤害
	var final_damage = maxf(0, zombies_survived * zombie_stats.attack - defense_reduction)

	return {
		"zombie_count": zombie_count,
		"zombies_killed": zombies_killed,
		"zombies_survived": zombies_survived,
		"base_damage": final_damage,
		"survived": final_damage < base_defense,
		"team_output": team_total_output
	}


## ==================== 私有方法 ====================

## 计算僵尸数量
func _calculate_zombie_count(day: int) -> int:
	if day < 8:
		return 0

	if day <= 10:
		return randi_range(5, 10)
	elif day <= 15:
		return randi_range(10, 20)
	elif day <= 20:
		return randi_range(20, 30)
	else:
		return 30 + (day - 20) * 2


## 统计敌对实体数量
func _count_enemies() -> int:
	var count = 0
	for entity in combat_entities:
		if is_instance_valid(entity) and entity.is_in_group("enemy"):
			count += 1
	return count


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	return {
		"is_in_combat": is_in_combat
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	is_in_combat = data.get("is_in_combat", false)
	print("[CombatSystem] 存档数据已加载")
