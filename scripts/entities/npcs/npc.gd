# npc.gd
# NPC 基础逻辑 - 继承 Entity 基类
# 实现对话、好感度、招募等功能
class_name NPC
extends Entity

## ==================== 信号 ====================

## 开始对话
signal dialog_started()

## 结束对话
signal dialog_ended()

## 好感度变化
signal relationship_changed(new_value: int, delta: int)

## 被招募
signal recruited()

## 离队
signal left_team(reason: String)

## ==================== 枚举 ====================

enum NPCState {
	IDLE,      ## 闲置
	WORKING,   ## 工作中
	TALKING,   ## 对话中
	FOLLOWING, ## 跟随中
	FIGHTING,  ## 战斗中
	FLEEING    ## 逃跑中
}

enum NPCRole {
	CIVILIAN,  ## 平民
	MERCHANT,  ## 商人
	WORKER,    ## 工人
	GUARD,     ## 守卫
	RECRUIT    ## 队员
}

## ==================== 导出变量 ====================

## NPC ID
@export var npc_id: String = ""

## NPC 名称
@export var npc_name: String = "NPC"

## NPC 角色
@export var role: NPCRole = NPCRole.CIVILIAN

## 初始好感度
@export var initial_relationship: int = 50

## 招募所需好感度
@export var recruit_threshold: int = 80

## 是否可招募
@export var can_be_recruited: bool = true

## 是否已加入队伍
@export var is_team_member: bool = false

## 跟随距离
@export var follow_distance: float = 64.0

## ==================== 状态变量 ====================

## 当前状态
var current_state: NPCState = NPCState.IDLE

## 好感度
var relationship: int = 50:
	set(value):
		var old_value = relationship
		relationship = clampi(value, 0, 100)
		if relationship != old_value:
			var delta = relationship - old_value
			relationship_changed.emit(relationship, delta)
			_notify_relationship_change(delta)

## 是否正在对话
var is_talking: bool = false

## 跟随目标
var follow_target: Node = null

## 战斗目标
var combat_target: Node = null

## 对话数据
var dialog_data: Dictionary = {}

## ==================== 节点引用 ====================

## 动画精灵节点
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

## 交互区域 (继承自 Interactable 的功能)
@onready var interaction_area: Area2D = $InteractionArea if has_node("InteractionArea") else null

## ==================== 生命周期 ====================

func _on_entity_ready() -> void:
	# 添加到 NPC 组
	add_to_group("npcs")

	# 初始化好感度
	relationship = initial_relationship

	# 从数据管理器加载 NPC 数据
	_load_npc_data()

	# 连接事件总线
	_connect_event_bus()

	# 设置交互区域
	_setup_interaction()

	print("[NPC] NPC 已初始化: %s (%s)" % [npc_name, npc_id])


func _process(_delta: float) -> void:
	if not is_alive:
		return

	# 更新动画
	_update_animation()


func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# 根据状态处理行为
	match current_state:
		NPCState.IDLE:
			_process_idle(delta)
		NPCState.WORKING:
			_process_working(delta)
		NPCState.TALKING:
			_process_talking(delta)
		NPCState.FOLLOWING:
			_process_following(delta)
		NPCState.FIGHTING:
			_process_fighting(delta)
		NPCState.FLEEING:
			_process_fleeing(delta)


## ==================== 状态处理 ====================

func _process_idle(_delta: float) -> void:
	# 闲置状态 - 随机走动或站立
	pass


func _process_working(_delta: float) -> void:
	# 工作状态 - 在和平期执行工作
	pass


func _process_talking(_delta: float) -> void:
	# 对话状态 - 面向玩家
	if follow_target:
		facing_direction = get_direction_to(follow_target)


func _process_following(_delta: float) -> void:
	# 跟随状态 - 跟随玩家
	if not follow_target or not is_instance_valid(follow_target):
		_change_state(NPCState.IDLE)
		return

	var distance = get_distance_to(follow_target)

	if distance > follow_distance:
		# 移动向玩家
		var direction = get_direction_to(follow_target)
		set_move_direction(direction)
	else:
		# 停止移动
		stop_moving()


func _process_fighting(_delta: float) -> void:
	# 战斗状态 - 攻击敌人
	if not combat_target or not is_instance_valid(combat_target):
		_find_combat_target()
		if not combat_target:
			_change_state(NPCState.FOLLOWING if is_team_member else NPCState.IDLE)
			return

	# TODO: 实现战斗逻辑


func _process_fleeing(_delta: float) -> void:
	# 逃跑状态 - 远离危险
	if combat_target and is_instance_valid(combat_target):
		var direction = -get_direction_to(combat_target)
		set_move_direction(direction)
	else:
		_change_state(NPCState.IDLE)


func _change_state(new_state: NPCState) -> void:
	var old_state = current_state
	current_state = new_state

	# 退出旧状态
	match old_state:
		NPCState.TALKING:
			is_talking = false
		NPCState.FIGHTING:
			combat_target = null

	# 进入新状态
	match new_state:
		NPCState.IDLE:
			stop_moving()
		NPCState.TALKING:
			stop_moving()
			is_talking = true
		NPCState.FOLLOWING:
			pass
		NPCState.FIGHTING:
			pass
		NPCState.FLEEING:
			set_speed_modifier(1.5)


## ==================== 对话系统 ====================

## 开始对话
func start_dialog(player: Node) -> void:
	if is_talking:
		return

	follow_target = player
	_change_state(NPCState.TALKING)

	dialog_started.emit()

	# 通知事件总线
	if EventBus:
		EventBus.dialog_started.emit(npc_id)


## 结束对话
func end_dialog() -> void:
	if not is_talking:
		return

	_change_state(NPCState.FOLLOWING if is_team_member else NPCState.IDLE)

	dialog_ended.emit()

	# 通知事件总线
	if EventBus:
		EventBus.dialog_ended.emit(npc_id)


## 获取对话选项
func get_dialog_options() -> Array:
	var options: Array = []

	# 基础对话选项
	options.append({
		"id": "greet",
		"text": "你好",
		"response": _get_greeting()
	})

	# 查询状态
	options.append({
		"id": "status",
		"text": "你最近怎么样?",
		"response": _get_status_response()
	})

	# 招募选项 (如果可以招募)
	if can_be_recruited and not is_team_member:
		if relationship >= recruit_threshold:
			options.append({
				"id": "recruit",
				"text": "愿意加入我们吗?",
				"response": "好的，我加入你们!",
				"action": "recruit"
			})
		else:
			options.append({
				"id": "recruit_hint",
				"text": "我们需要帮手...",
				"response": "我还不太信任你。(好感度: %d/%d)" % [relationship, recruit_threshold]
			})

	# 告别
	options.append({
		"id": "bye",
		"text": "再见",
		"response": "再见!",
		"action": "end_dialog"
	})

	return options


## 处理对话选择
func handle_dialog_choice(choice_id: String) -> String:
	var options = get_dialog_options()

	for option in options:
		if option["id"] == choice_id:
			# 执行动作
			if option.has("action"):
				match option["action"]:
					"recruit":
						recruit_to_team()
					"end_dialog":
						end_dialog()

			return option["response"]

	return "..."


func _get_greeting() -> String:
	if relationship >= 80:
		return "老朋友，见到你真高兴!"
	elif relationship >= 60:
		return "嗨，很高兴见到你。"
	elif relationship >= 40:
		return "你好。"
	else:
		return "...你找我有事?"


func _get_status_response() -> String:
	if GameManager:
		match GameManager.phase:
			GameManager.GamePhase.PEACE:
				return "还不错，生活照常进行。"
			GameManager.GamePhase.APOCALYPSE:
				return "太可怕了!到处都是那些东西!"
			GameManager.GamePhase.SURVIVAL:
				if is_team_member:
					return "有你在，我觉得安全多了。"
				else:
					return "日子很艰难，但我在努力活下去。"

	return "还行吧。"


## ==================== 招募系统 ====================

## 招募到队伍
func recruit_to_team() -> void:
	if not can_be_recruited or is_team_member:
		return

	if relationship < recruit_threshold:
		return

	is_team_member = true
	role = NPCRole.RECRUIT
	follow_target = _find_player()

	recruited.emit()

	# 通知事件总线
	if EventBus:
		EventBus.npc_recruited.emit(npc_id)

	# 通知角色管理器
	if CharacterManager:
		CharacterManager.recruit_character(npc_id)

	print("[NPC] %s 加入了队伍" % npc_name)

	# 开始跟随
	_change_state(NPCState.FOLLOWING)


## 离开队伍
func leave_team(reason: String = "自愿离开") -> void:
	if not is_team_member:
		return

	is_team_member = false
	role = NPCRole.CIVILIAN
	follow_target = null

	left_team.emit(reason)

	# 通知事件总线
	if EventBus:
		EventBus.npc_left.emit(npc_id, reason)

	print("[NPC] %s 离开了队伍: %s" % [npc_name, reason])

	_change_state(NPCState.IDLE)


## 增加好感度
func add_relationship(amount: int) -> void:
	relationship += amount


## 减少好感度
func remove_relationship(amount: int) -> void:
	relationship -= amount

	# 好感度过低可能导致离队
	if is_team_member and relationship < 20:
		leave_team("好感度过低")


## ==================== 战斗系统 ====================

## 进入战斗状态
func enter_combat(target: Node = null) -> void:
	combat_target = target
	_change_state(NPCState.FIGHTING)


## 进入逃跑状态
func flee_from(threat: Node) -> void:
	combat_target = threat
	_change_state(NPCState.FLEEING)


func _find_combat_target() -> void:
	# 查找附近的敌人
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_distance = INF
	var closest_enemy: Node = null

	for enemy in enemies:
		if enemy is Node2D and enemy.has_method("get") and enemy.is_alive:
			var distance = get_distance_to(enemy)
			if distance < closest_distance and distance < 200:
				closest_distance = distance
				closest_enemy = enemy

	combat_target = closest_enemy


## ==================== 交互设置 ====================

func _setup_interaction() -> void:
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)


func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 通知可交互
		if EventBus:
			EventBus.interaction_available.emit(self)


func _on_player_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if EventBus:
			EventBus.interaction_unavailable.emit(self)


## 交互方法 (供玩家调用)
func interact(player: Node) -> void:
	start_dialog(player)


## 获取交互提示
func get_prompt() -> String:
	return "按 E 键与 %s 交谈" % npc_name


## ==================== 辅助方法 ====================

func _load_npc_data() -> void:
	if npc_id.is_empty() or not DataManager:
		return

	var data = DataManager.get_npc(npc_id)
	if data.is_empty():
		return

	npc_name = data.get("name", npc_name)
	initial_relationship = data.get("initial_relationship", 50)
	relationship = initial_relationship


func _connect_event_bus() -> void:
	if not EventBus:
		return

	# 连接阶段变化信号
	EventBus.phase_changed.connect(_on_phase_changed)


func _on_phase_changed(phase: String) -> void:
	# 根据游戏阶段调整行为
	match phase:
		"apocalypse":
			if not is_team_member:
				flee_from(null)
		"survival":
			pass


func _notify_relationship_change(delta: int) -> void:
	if EventBus:
		EventBus.npc_relationship_changed.emit(npc_id, relationship, delta)


func _find_player() -> Node:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null


## ==================== 动画更新 ====================

func _update_animation() -> void:
	if not animated_sprite:
		return

	var anim_name = ""

	match current_state:
		NPCState.IDLE, NPCState.WORKING, NPCState.TALKING:
			anim_name = "idle"
		NPCState.FOLLOWING, NPCState.FLEEING:
			anim_name = "walk" if is_moving else "idle"
		NPCState.FIGHTING:
			anim_name = "attack"

	# 播放动画
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)

	# 水平翻转
	if facing_direction.x != 0:
		animated_sprite.flip_h = facing_direction.x < 0


## ==================== 重写基类方法 ====================

func _on_death() -> void:
	super._on_death()

	# 如果是队员，从队伍移除
	if is_team_member:
		is_team_member = false

	# 通知事件总线
	if EventBus:
		EventBus.npc_died.emit(npc_id)

	print("[NPC] %s 死亡" % npc_name)


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	var data = super.get_save_data()
	data["npc_id"] = npc_id
	data["npc_name"] = npc_name
	data["relationship"] = relationship
	data["is_team_member"] = is_team_member
	data["role"] = role
	data["current_state"] = current_state
	return data


func load_save_data(data: Dictionary) -> void:
	super.load_save_data(data)
	npc_id = data.get("npc_id", "")
	npc_name = data.get("npc_name", "NPC")
	relationship = data.get("relationship", 50)
	is_team_member = data.get("is_team_member", false)
	role = data.get("role", NPCRole.CIVILIAN)
	_change_state(data.get("current_state", NPCState.IDLE))

	if is_team_member:
		follow_target = _find_player()
