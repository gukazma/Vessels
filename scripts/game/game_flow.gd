# game_flow.gd
# 游戏流程控制 - 管理游戏阶段转换和事件触发
# 作为 Autoload 使用
extends Node

## ==================== 信号 ====================

## 末日爆发
signal apocalypse_triggered()

## 防御战开始
signal defense_battle_started(zombie_count: int)

## 防御战结束
signal defense_battle_ended(victory: bool, casualties: int)

## 游戏胜利
signal victory_achieved(reason: String)

## 游戏失败
signal game_over_triggered(reason: String)

## ==================== 常量 ====================

## 末日爆发天数
const APOCALYPSE_DAY: int = 7

## 末日爆发时间 (12点)
const APOCALYPSE_HOUR: int = 12

## 胜利所需天数
const VICTORY_DAYS: int = 30

## 胜利所需队员数
const VICTORY_TEAM_SIZE: int = 3

## 胜利所需据点等级
const VICTORY_BASE_LEVEL: int = 3

## ==================== 状态变量 ====================

## 是否已触发末日
var apocalypse_triggered_flag: bool = false

## 是否正在进行防御战
var is_defense_battle: bool = false

## 当前防御战敌人数量
var current_battle_enemy_count: int = 0

## 已击杀敌人数量
var enemies_killed: int = 0

## ==================== 预兆事件 ====================

## 预兆事件列表 (Day -> 事件内容)
var foreshadowing_events: Dictionary = {
	2: "新闻报道: 某地发现不明疾病...",
	3: "街上有人在囤积物资。",
	4: "医院传来奇怪的消息...",
	5: "政府宣布进入紧急状态。",
	6: "城市开始戒严，人心惶惶。"
}

## 末日事件序列
var apocalypse_sequence: Array = [
	{"delay": 0, "message": "突然间，天空变得阴沉..."},
	{"delay": 2, "message": "远处传来尖叫声!"},
	{"delay": 4, "message": "你看到街上有人在奔跑..."},
	{"delay": 6, "message": "那些东西...不是活人!"},
	{"delay": 8, "message": "末日降临了。"}
]

## ==================== 生命周期 ====================

func _ready() -> void:
	# 连接事件总线信号
	_connect_event_bus()

	print("[GameFlow] 游戏流程控制已初始化")


## ==================== 事件总线连接 ====================

func _connect_event_bus() -> void:
	if not EventBus:
		return

	EventBus.time_tick.connect(_on_time_tick)
	EventBus.day_changed.connect(_on_day_changed)
	EventBus.zombie_killed.connect(_on_zombie_killed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.npc_died.connect(_on_npc_died)


## ==================== 时间事件处理 ====================

func _on_time_tick(hour: int, _minute: int) -> void:
	if not GameManager:
		return

	# 检查末日触发
	if not apocalypse_triggered_flag:
		if GameManager.current_day == APOCALYPSE_DAY and hour == APOCALYPSE_HOUR:
			trigger_apocalypse()

	# 检查夜间防御战
	if GameManager.phase == GameManager.GamePhase.SURVIVAL:
		if hour == 21 and not is_defense_battle:
			_start_night_defense()
		elif hour == 5 and is_defense_battle:
			_end_night_defense(true)


func _on_day_changed(day: int) -> void:
	# 检查预兆事件
	if foreshadowing_events.has(day):
		_show_foreshadowing(day)

	# 检查胜利条件
	if day >= VICTORY_DAYS:
		_check_victory_conditions()


## ==================== 末日触发 ====================

## 触发末日爆发
func trigger_apocalypse() -> void:
	if apocalypse_triggered_flag:
		return

	apocalypse_triggered_flag = true

	print("[GameFlow] 末日爆发!")

	apocalypse_triggered.emit()

	# 播放末日事件序列
	_play_apocalypse_sequence()


func _play_apocalypse_sequence() -> void:
	for event in apocalypse_sequence:
		var delay = event.get("delay", 0)
		var message = event.get("message", "")

		if delay > 0:
			await get_tree().create_timer(delay).timeout

		if EventBus:
			EventBus.emit_warning(message)

	# 切换到末日阶段
	if GameManager:
		GameManager.phase = GameManager.GamePhase.APOCALYPSE
		if EventBus:
			EventBus.phase_changed.emit("apocalypse")

	# 生成初始僵尸
	_spawn_initial_zombies()


func _spawn_initial_zombies() -> void:
	# TODO: 在玩家周围生成僵尸
	if EventBus:
		EventBus.zombie_spawned.emit(Vector2.ZERO, "normal")


## ==================== 预兆事件 ====================

func _show_foreshadowing(day: int) -> void:
	var message = foreshadowing_events.get(day, "")
	if message.is_empty():
		return

	# 根据难度决定是否显示预兆
	if GameManager:
		var config = GameManager.get_difficulty_config()
		var foreshadowing_level = config.get("foreshadowing_level", 2)

		# 难度越高，预兆越少
		if day > 6 - foreshadowing_level:
			if EventBus:
				EventBus.emit_info(message)


## ==================== 夜间防御战 ====================

func _start_night_defense() -> void:
	is_defense_battle = true
	enemies_killed = 0

	# 计算僵尸数量 (基于天数和难度)
	var base_count = 5
	if GameManager:
		base_count += (GameManager.current_day - 7) * 2
		var config = GameManager.get_difficulty_config()
		base_count = int(base_count * config.get("zombie_health_multiplier", 1.0))

	current_battle_enemy_count = base_count

	print("[GameFlow] 夜间防御战开始! 僵尸数量: %d" % current_battle_enemy_count)

	defense_battle_started.emit(current_battle_enemy_count)

	if EventBus:
		EventBus.night_defense_started.emit(current_battle_enemy_count)
		EventBus.emit_warning("夜间防御战开始! 抵御 %d 只僵尸!" % current_battle_enemy_count)

	# TODO: 生成僵尸波次


func _end_night_defense(victory: bool) -> void:
	is_defense_battle = false

	var casualties = 0  # TODO: 计算伤亡

	print("[GameFlow] 夜间防御战结束! 胜利: %s" % victory)

	defense_battle_ended.emit(victory, casualties)

	if EventBus:
		EventBus.night_defense_ended.emit(victory, casualties)

		if victory:
			EventBus.emit_success("你撑过了这一夜!")
		else:
			EventBus.emit_error("防线被突破了...")


func _on_zombie_killed(_position: Vector2, _zombie_type: String) -> void:
	if is_defense_battle:
		enemies_killed += 1

		# 检查是否击杀所有僵尸
		if enemies_killed >= current_battle_enemy_count:
			_end_night_defense(true)


## ==================== 胜利/失败条件 ====================

func _check_victory_conditions() -> void:
	if not GameManager:
		return

	# 检查生存天数
	if GameManager.current_day < VICTORY_DAYS:
		return

	# 检查队员数量
	var team_size = _get_team_size()
	if team_size < VICTORY_TEAM_SIZE:
		return

	# 检查据点等级
	var base_level = _get_base_level()
	if base_level < VICTORY_BASE_LEVEL:
		return

	# 胜利!
	_trigger_victory("完成所有胜利条件!")


func _trigger_victory(reason: String) -> void:
	print("[GameFlow] 游戏胜利: %s" % reason)

	victory_achieved.emit(reason)

	if GameManager:
		GameManager.win_game(reason)


func _trigger_game_over(reason: String) -> void:
	print("[GameFlow] 游戏失败: %s" % reason)

	game_over_triggered.emit(reason)

	if GameManager:
		GameManager.lose_game(reason)


func _on_player_died() -> void:
	_trigger_game_over("玩家死亡")


func _on_npc_died(_npc_id: String) -> void:
	# 检查是否所有队员都死亡
	var team_size = _get_team_size()
	if team_size <= 0 and GameManager and GameManager.phase == GameManager.GamePhase.SURVIVAL:
		# 所有队员死亡但玩家还活着，继续游戏
		if EventBus:
			EventBus.emit_warning("你失去了所有队友...")


## ==================== 辅助方法 ====================

func _get_team_size() -> int:
	if CharacterManager:
		return CharacterManager.get_team_size() if CharacterManager.has_method("get_team_size") else 0

	# 备选方案：直接计数
	var count = 0
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.has_method("get") and npc.is_team_member:
			count += 1
	return count


func _get_base_level() -> int:
	if BaseManager:
		return BaseManager.get_base_level() if BaseManager.has_method("get_base_level") else 0
	return 0


## ==================== 公共方法 ====================

## 检查当前胜利进度
func get_victory_progress() -> Dictionary:
	return {
		"days": {
			"current": GameManager.current_day if GameManager else 0,
			"required": VICTORY_DAYS
		},
		"team_size": {
			"current": _get_team_size(),
			"required": VICTORY_TEAM_SIZE
		},
		"base_level": {
			"current": _get_base_level(),
			"required": VICTORY_BASE_LEVEL
		}
	}


## 检查是否处于危险时间
func is_danger_period() -> bool:
	if not GameManager:
		return false

	if GameManager.phase == GameManager.GamePhase.PEACE:
		return false

	return GameManager.is_danger_time()


## 获取当前阶段描述
func get_phase_description() -> String:
	if not GameManager:
		return ""

	match GameManager.phase:
		GameManager.GamePhase.PEACE:
			return "和平时期 - 正常生活，为未来做准备"
		GameManager.GamePhase.APOCALYPSE:
			return "末日爆发 - 混乱时期，寻找安全地带"
		GameManager.GamePhase.SURVIVAL:
			return "生存阶段 - 建立据点，招募队员，生存下去"
		_:
			return ""


## ==================== 存档相关 ====================

func get_save_data() -> Dictionary:
	return {
		"apocalypse_triggered": apocalypse_triggered_flag,
		"is_defense_battle": is_defense_battle,
		"enemies_killed": enemies_killed
	}


func load_save_data(data: Dictionary) -> void:
	apocalypse_triggered_flag = data.get("apocalypse_triggered", false)
	is_defense_battle = data.get("is_defense_battle", false)
	enemies_killed = data.get("enemies_killed", 0)
