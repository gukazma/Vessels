# game_manager.gd
# 游戏管理器 - 管理游戏整体状态和流程
extends Node

## ==================== 枚举定义 ====================

## 游戏阶段
enum GamePhase {
	PEACE,      ## 和平阶段 (Day 1-6): 日常工作、社交、购物
	APOCALYPSE, ## 末日爆发 (Day 7): 僵尸突然出现，城市陷入混乱
	SURVIVAL    ## 生存阶段 (Day 8+): 资源搜刮、据点建设、防御
}

## 游戏难度
enum Difficulty {
	EASY,    ## 简单: 僵尸弱、资源多、预兆明显
	NORMAL,  ## 普通: 标准难度
	HARD,    ## 困难: 僵尸强、资源少、预兆模糊
	NIGHTMARE ## 噩梦: 极高难度
}

## 游戏状态
enum GameState {
	MENU,     ## 主菜单
	PLAYING,  ## 游戏中
	PAUSED,   ## 暂停
	GAME_OVER ## 游戏结束
}

## ==================== 导出变量 ====================

## 当前游戏难度
@export var difficulty: Difficulty = Difficulty.NORMAL

## ==================== 游戏状态变量 ====================

## 当前游戏状态
var state: GameState = GameState.MENU

## 当前游戏阶段
var phase: GamePhase = GamePhase.PEACE

## 当前天数 (从1开始)
var current_day: int = 1

## 当前时间 (小时.分钟 格式存储)
var current_hour: int = 6
var current_minute: int = 0

## 是否是新游戏
var is_new_game: bool = true

## 玩家选择的职业ID
var player_profession: String = ""

## ==================== 难度参数 ====================

## 难度配置表
var difficulty_config: Dictionary = {
	Difficulty.EASY: {
		"zombie_health_multiplier": 0.7,
		"zombie_damage_multiplier": 0.7,
		"loot_multiplier": 1.5,
		"price_multiplier": 0.8,
		"foreshadowing_level": 3  # 预兆明显程度 (1-3)
	},
	Difficulty.NORMAL: {
		"zombie_health_multiplier": 1.0,
		"zombie_damage_multiplier": 1.0,
		"loot_multiplier": 1.0,
		"price_multiplier": 1.0,
		"foreshadowing_level": 2
	},
	Difficulty.HARD: {
		"zombie_health_multiplier": 1.3,
		"zombie_damage_multiplier": 1.3,
		"loot_multiplier": 0.7,
		"price_multiplier": 1.2,
		"foreshadowing_level": 1
	},
	Difficulty.NIGHTMARE: {
		"zombie_health_multiplier": 1.6,
		"zombie_damage_multiplier": 1.6,
		"loot_multiplier": 0.5,
		"price_multiplier": 1.5,
		"foreshadowing_level": 0
	}
}

## ==================== 胜利/失败条件 ====================

## MVP版本胜利条件
const WIN_CONDITIONS: Dictionary = {
	"survive_days": 30,       # 生存30天
	"min_team_members": 3,    # 至少3名队员
	"min_base_level": 3       # 据点等级3
}

## ==================== 信号 ====================

## 游戏状态变化
signal state_changed(new_state: GameState)

## ==================== 生命周期 ====================

func _ready() -> void:
	print("[GameManager] 游戏管理器已初始化")

	# 连接事件总线信号
	if EventBus:
		EventBus.day_changed.connect(_on_day_changed)
		EventBus.player_died.connect(_on_player_died)
		EventBus.npc_died.connect(_on_npc_died)


func _process(_delta: float) -> void:
	# 检查胜利/失败条件
	if state == GameState.PLAYING:
		_check_game_end_conditions()


## ==================== 公共方法 ====================

## 开始新游戏
func start_new_game(profession_id: String) -> void:
	print("[GameManager] 开始新游戏，职业: %s" % profession_id)

	is_new_game = true
	player_profession = profession_id
	current_day = 1
	current_hour = 6
	current_minute = 0
	phase = GamePhase.PEACE

	_set_state(GameState.PLAYING)

	# 通知阶段变化
	if EventBus:
		EventBus.phase_changed.emit("peace")
		EventBus.day_changed.emit(current_day)


## 继续游戏 (从存档加载)
func continue_game() -> void:
	print("[GameManager] 继续游戏")
	is_new_game = false
	_set_state(GameState.PLAYING)


## 暂停游戏
func pause_game() -> void:
	if state == GameState.PLAYING:
		_set_state(GameState.PAUSED)
		get_tree().paused = true
		if EventBus:
			EventBus.game_paused.emit()
		print("[GameManager] 游戏已暂停")


## 继续游戏
func resume_game() -> void:
	if state == GameState.PAUSED:
		_set_state(GameState.PLAYING)
		get_tree().paused = false
		if EventBus:
			EventBus.game_resumed.emit()
		print("[GameManager] 游戏已继续")


## 切换暂停状态
func toggle_pause() -> void:
	if state == GameState.PLAYING:
		pause_game()
	elif state == GameState.PAUSED:
		resume_game()


## 返回主菜单
func return_to_menu() -> void:
	get_tree().paused = false
	_set_state(GameState.MENU)
	print("[GameManager] 返回主菜单")


## 游戏结束 - 胜利
func win_game(reason: String = "完成所有胜利条件") -> void:
	_set_state(GameState.GAME_OVER)
	if EventBus:
		EventBus.game_won.emit(reason)
	print("[GameManager] 游戏胜利: %s" % reason)


## 游戏结束 - 失败
func lose_game(reason: String = "玩家死亡") -> void:
	_set_state(GameState.GAME_OVER)
	if EventBus:
		EventBus.game_over.emit(reason)
	print("[GameManager] 游戏失败: %s" % reason)


## 设置游戏时间
func set_time(hour: int, minute: int) -> void:
	current_hour = clampi(hour, 0, 23)
	current_minute = clampi(minute, 0, 59)


## 获取当前难度配置
func get_difficulty_config() -> Dictionary:
	return difficulty_config.get(difficulty, difficulty_config[Difficulty.NORMAL])


## 获取阶段名称 (字符串)
func get_phase_name() -> String:
	match phase:
		GamePhase.PEACE:
			return "peace"
		GamePhase.APOCALYPSE:
			return "apocalypse"
		GamePhase.SURVIVAL:
			return "survival"
		_:
			return "unknown"


## 获取阶段中文名称
func get_phase_display_name() -> String:
	match phase:
		GamePhase.PEACE:
			return "和平阶段"
		GamePhase.APOCALYPSE:
			return "末日爆发"
		GamePhase.SURVIVAL:
			return "生存阶段"
		_:
			return "未知"


## 检查是否是工作时间 (基于职业)
func is_work_time() -> bool:
	if phase != GamePhase.PEACE:
		return false

	# 根据职业获取工作时间
	var work_hours = _get_profession_work_hours()
	return current_hour >= work_hours.start and current_hour < work_hours.end


## 检查是否是夜间 (僵尸活跃时间)
func is_night_time() -> bool:
	return current_hour >= 21 or current_hour < 5


## 检查是否是危险时间段 (末日后)
func is_danger_time() -> bool:
	if phase == GamePhase.PEACE:
		return false
	return current_hour >= 18 or current_hour < 7


## 获取当前时间段名称
func get_time_period() -> String:
	if current_hour >= 5 and current_hour < 7:
		return "dawn"      # 黎明
	elif current_hour >= 7 and current_hour < 9:
		return "morning"   # 早晨
	elif current_hour >= 9 and current_hour < 12:
		return "forenoon"  # 上午
	elif current_hour >= 12 and current_hour < 13:
		return "noon"      # 中午
	elif current_hour >= 13 and current_hour < 18:
		return "afternoon" # 下午
	elif current_hour >= 18 and current_hour < 21:
		return "evening"   # 傍晚
	elif current_hour >= 21 and current_hour < 24:
		return "night"     # 夜晚
	else:
		return "midnight"  # 深夜


## 获取时间段中文名称
func get_time_period_display_name() -> String:
	match get_time_period():
		"dawn":
			return "黎明"
		"morning":
			return "早晨"
		"forenoon":
			return "上午"
		"noon":
			return "中午"
		"afternoon":
			return "下午"
		"evening":
			return "傍晚"
		"night":
			return "夜晚"
		"midnight":
			return "深夜"
		_:
			return "未知"


## ==================== 私有方法 ====================

## 设置游戏状态
func _set_state(new_state: GameState) -> void:
	if state != new_state:
		state = new_state
		state_changed.emit(new_state)


## 处理天数变化
func _on_day_changed(day: int) -> void:
	current_day = day
	print("[GameManager] 天数变化: Day %d" % day)

	# 检查阶段转换
	_check_phase_transition()


## 检查阶段转换
func _check_phase_transition() -> void:
	var old_phase = phase

	match phase:
		GamePhase.PEACE:
			# Day 7 中午触发末日爆发
			if current_day >= 7:
				phase = GamePhase.APOCALYPSE
		GamePhase.APOCALYPSE:
			# Day 7 结束后进入生存阶段
			if current_day >= 8:
				phase = GamePhase.SURVIVAL

	# 如果阶段发生变化，发送信号
	if phase != old_phase:
		print("[GameManager] 阶段转换: %s -> %s" % [
			_phase_to_string(old_phase),
			_phase_to_string(phase)
		])
		if EventBus:
			EventBus.phase_changed.emit(get_phase_name())


## 将阶段枚举转换为字符串
func _phase_to_string(p: GamePhase) -> String:
	match p:
		GamePhase.PEACE:
			return "PEACE"
		GamePhase.APOCALYPSE:
			return "APOCALYPSE"
		GamePhase.SURVIVAL:
			return "SURVIVAL"
		_:
			return "UNKNOWN"


## 玩家死亡处理
func _on_player_died() -> void:
	lose_game("玩家死亡")


## NPC死亡处理
func _on_npc_died(_npc_id: String) -> void:
	# TODO: 检查是否所有队员都死亡
	pass


## 检查游戏结束条件
func _check_game_end_conditions() -> void:
	# 只在生存阶段检查胜利条件
	if phase != GamePhase.SURVIVAL:
		return

	# TODO: 实现详细的胜利条件检查
	# 需要从其他系统获取数据:
	# - 当前天数
	# - 队员数量
	# - 据点等级


## 获取职业工作时间
func _get_profession_work_hours() -> Dictionary:
	# 默认工作时间
	var default_hours = {"start": 9, "end": 18}

	if player_profession.is_empty():
		return default_hours

	# 根据职业返回不同的工作时间
	match player_profession:
		"office_worker":
			return {"start": 9, "end": 18}
		"construction_worker":
			return {"start": 7, "end": 17}
		"doctor":
			return {"start": 8, "end": 20}
		_:
			return default_hours


## ==================== 存档相关 ====================

## 获取需要保存的数据
func get_save_data() -> Dictionary:
	return {
		"difficulty": difficulty,
		"phase": phase,
		"current_day": current_day,
		"current_hour": current_hour,
		"current_minute": current_minute,
		"player_profession": player_profession
	}


## 从存档加载数据
func load_save_data(data: Dictionary) -> void:
	difficulty = data.get("difficulty", Difficulty.NORMAL)
	phase = data.get("phase", GamePhase.PEACE)
	current_day = data.get("current_day", 1)
	current_hour = data.get("current_hour", 6)
	current_minute = data.get("current_minute", 0)
	player_profession = data.get("player_profession", "")

	print("[GameManager] 存档数据已加载")
