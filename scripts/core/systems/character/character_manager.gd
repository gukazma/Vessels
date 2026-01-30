# character_manager.gd
# 角色管理系统 - 管理NPC数据和交互
class_name CharacterManager
extends Node

## ==================== 信号 ====================

## NPC遇到
signal npc_met(npc_id: String)

## 好感度变化
signal affection_changed(npc_id: String, old_value: int, new_value: int)

## NPC招募
signal npc_recruited(npc_id: String)

## NPC离队
signal npc_left(npc_id: String, reason: String)

## NPC死亡
signal npc_died(npc_id: String)

## 任务分配
signal task_assigned(npc_id: String, task: int)

## ==================== 变量 ====================

## 所有NPC数据 (npc_id -> CharacterData)
var npcs: Dictionary = {}

## 已招募的队员ID列表
var team_members: Array[String] = []

## ==================== 生命周期 ====================

func _ready() -> void:
	_load_npc_data()
	print("[CharacterManager] 角色管理系统已初始化，NPC数量: %d" % npcs.size())


## ==================== 公共方法 - NPC管理 ====================

## 遇到NPC (首次接触)
func meet_npc(npc_id: String) -> void:
	if not npcs.has(npc_id):
		return

	var npc = npcs[npc_id] as CharacterData
	if npc.state == CharacterData.CharacterState.UNKNOWN:
		npc.state = CharacterData.CharacterState.MET
		npc_met.emit(npc_id)
		print("[CharacterManager] 遇到NPC: %s" % npc.name_cn)


## 增加好感度
func add_affection(npc_id: String, amount: int) -> void:
	if not npcs.has(npc_id):
		return

	var npc = npcs[npc_id] as CharacterData
	var old_value = npc.affection
	npc.add_affection(amount)

	if npc.affection != old_value:
		affection_changed.emit(npc_id, old_value, npc.affection)

		# 通知事件总线
		if EventBus:
			EventBus.npc_relationship_changed.emit(npc_id, npc.affection, amount)

		# 检查状态转换
		_check_relationship_state(npc)


## 设置好感度
func set_affection(npc_id: String, value: int) -> void:
	if not npcs.has(npc_id):
		return

	var npc = npcs[npc_id] as CharacterData
	var old_value = npc.affection
	npc.affection = clampi(value, 0, 100)

	if npc.affection != old_value:
		affection_changed.emit(npc_id, old_value, npc.affection)
		_check_relationship_state(npc)


## 招募NPC
func recruit_npc(npc_id: String) -> bool:
	if not npcs.has(npc_id):
		return false

	var npc = npcs[npc_id] as CharacterData

	# 检查招募条件
	if not npc.can_recruit():
		print("[CharacterManager] %s 无法招募 (状态不符)" % npc.name_cn)
		return false

	if not npc.has_enough_affection():
		print("[CharacterManager] %s 好感度不足 (%d/%d)" % [npc.name_cn, npc.affection, npc.recruit_affection])
		return false

	# TODO: 检查招募任务是否完成
	# TODO: 检查据点是否有床位

	# 执行招募
	npc.recruit()
	team_members.append(npc_id)

	npc_recruited.emit(npc_id)
	if EventBus:
		EventBus.npc_recruited.emit(npc_id)

	print("[CharacterManager] 成功招募: %s" % npc.name_cn)
	return true


## NPC离队
func dismiss_npc(npc_id: String, reason: String = "主动离开") -> void:
	if npc_id not in team_members:
		return

	var npc = npcs[npc_id] as CharacterData
	npc.state = CharacterData.CharacterState.MET
	npc.clear_task()

	team_members.erase(npc_id)

	npc_left.emit(npc_id, reason)
	if EventBus:
		EventBus.npc_left.emit(npc_id, reason)

	print("[CharacterManager] %s 离队: %s" % [npc.name_cn, reason])


## NPC死亡
func kill_npc(npc_id: String) -> void:
	if not npcs.has(npc_id):
		return

	var npc = npcs[npc_id] as CharacterData
	npc.state = CharacterData.CharacterState.DEAD
	npc.current_hp = 0

	if npc_id in team_members:
		team_members.erase(npc_id)

	npc_died.emit(npc_id)
	if EventBus:
		EventBus.npc_died.emit(npc_id)

	print("[CharacterManager] %s 死亡" % npc.name_cn)


## ==================== 公共方法 - 任务分配 ====================

## 分配任务给队员
func assign_task(npc_id: String, task: CharacterData.TaskType, target: String = "") -> bool:
	if npc_id not in team_members:
		return false

	var npc = npcs[npc_id] as CharacterData
	npc.assign_task(task, target)

	task_assigned.emit(npc_id, task)
	print("[CharacterManager] %s 分配任务: %s" % [npc.name_cn, _task_to_string(task)])
	return true


## 清除任务
func clear_task(npc_id: String) -> void:
	if not npcs.has(npc_id):
		return

	var npc = npcs[npc_id] as CharacterData
	npc.clear_task()


## 获取执行指定任务的队员列表
func get_members_by_task(task: CharacterData.TaskType) -> Array[String]:
	var result: Array[String] = []
	for npc_id in team_members:
		var npc = npcs[npc_id] as CharacterData
		if npc.current_task == task:
			result.append(npc_id)
	return result


## ==================== 公共方法 - 查询 ====================

## 获取NPC数据
func get_npc(npc_id: String) -> CharacterData:
	return npcs.get(npc_id, null)


## 获取NPC名称
func get_npc_name(npc_id: String) -> String:
	if npcs.has(npc_id):
		return npcs[npc_id].name_cn
	return npc_id


## 获取所有已遇到的NPC
func get_met_npcs() -> Array[String]:
	var result: Array[String] = []
	for npc_id in npcs:
		var npc = npcs[npc_id] as CharacterData
		if npc.state != CharacterData.CharacterState.UNKNOWN:
			result.append(npc_id)
	return result


## 获取所有队员
func get_team_members() -> Array[String]:
	return team_members.duplicate()


## 获取队伍人数
func get_team_size() -> int:
	return team_members.size()


## 检查NPC是否是队员
func is_team_member(npc_id: String) -> bool:
	return npc_id in team_members


## 获取队伍总战斗力
func get_team_combat_power() -> int:
	var total = 0
	for npc_id in team_members:
		var npc = npcs[npc_id] as CharacterData
		total += npc.combat
	return total


## 获取队伍总建造能力
func get_team_build_power() -> int:
	var total = 0
	for npc_id in team_members:
		var npc = npcs[npc_id] as CharacterData
		total += npc.build
	return total


## 获取最擅长指定技能的队员
func get_best_member_for_task(task: CharacterData.TaskType) -> String:
	var best_id = ""
	var best_value = -1

	for npc_id in team_members:
		var npc = npcs[npc_id] as CharacterData
		var value = 0

		match task:
			CharacterData.TaskType.SCAVENGE:
				value = npc.social
			CharacterData.TaskType.BUILD:
				value = npc.build
			CharacterData.TaskType.GUARD:
				value = npc.combat
			CharacterData.TaskType.COOK:
				value = npc.cooking
			CharacterData.TaskType.HEAL:
				value = npc.medical

		if value > best_value:
			best_value = value
			best_id = npc_id

	return best_id


## ==================== 私有方法 ====================

## 加载NPC数据
func _load_npc_data() -> void:
	if not DataManager:
		print("[CharacterManager] DataManager 未初始化")
		return

	var npc_ids = DataManager.get_all_npc_ids()
	for npc_id in npc_ids:
		var npc_dict = DataManager.get_npc(npc_id)
		if not npc_dict.is_empty():
			var npc = CharacterData.from_dict(npc_dict)
			npcs[npc_id] = npc


## 检查关系状态转换
func _check_relationship_state(npc: CharacterData) -> void:
	if npc.state == CharacterData.CharacterState.MET:
		if npc.affection >= 40:
			npc.state = CharacterData.CharacterState.FRIENDLY


## 任务类型转字符串
func _task_to_string(task: CharacterData.TaskType) -> String:
	match task:
		CharacterData.TaskType.NONE:
			return "无"
		CharacterData.TaskType.SCAVENGE:
			return "搜刮"
		CharacterData.TaskType.BUILD:
			return "建造"
		CharacterData.TaskType.GUARD:
			return "守卫"
		CharacterData.TaskType.COOK:
			return "烹饪"
		CharacterData.TaskType.HEAL:
			return "医疗"
		CharacterData.TaskType.REST:
			return "休息"
		_:
			return "未知"


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	var npc_save_data: Dictionary = {}
	for npc_id in npcs:
		var npc = npcs[npc_id] as CharacterData
		npc_save_data[npc_id] = {
			"state": npc.state,
			"affection": npc.affection,
			"current_hp": npc.current_hp,
			"morale": npc.morale,
			"current_task": npc.current_task,
			"task_target": npc.task_target
		}

	return {
		"npcs": npc_save_data,
		"team_members": team_members.duplicate()
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	# 加载NPC状态
	var npc_save_data = data.get("npcs", {})
	for npc_id in npc_save_data:
		if npcs.has(npc_id):
			var npc = npcs[npc_id] as CharacterData
			var save = npc_save_data[npc_id]
			npc.state = save.get("state", CharacterData.CharacterState.UNKNOWN)
			npc.affection = save.get("affection", 0)
			npc.current_hp = save.get("current_hp", npc.max_hp)
			npc.morale = save.get("morale", 50)
			npc.current_task = save.get("current_task", CharacterData.TaskType.NONE)
			npc.task_target = save.get("task_target", "")

	# 加载队员列表
	team_members.clear()
	var saved_members = data.get("team_members", [])
	for member_id in saved_members:
		if npcs.has(member_id):
			team_members.append(member_id)

	print("[CharacterManager] 存档数据已加载，队员数量: %d" % team_members.size())
