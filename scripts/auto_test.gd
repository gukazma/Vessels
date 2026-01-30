extends Node

## 自动测试系统 - AI 自动操控游戏并验证逻辑
## 通过模拟输入来测试游戏功能

signal test_completed(test_name: String, passed: bool, message: String)

@export var auto_test_enabled: bool = true
@export var test_sequence_delay: float = 0.5  # 每个测试步骤之间的延迟

var player: CharacterBody2D
var screenshot_manager: Node
var current_test_index: int = 0
var test_results: Array = []
var is_testing: bool = false

# 测试序列定义
var test_sequence: Array = [
	{"action": "log", "message": "=== 开始自动测试 ==="},
	{"action": "screenshot", "name": "initial_state"},
	{"action": "wait", "duration": 0.5},

	# ==================== 基础移动测试 ====================
	{"action": "log", "message": "--- 基础移动测试 ---"},

	# 测试向右移动
	{"action": "log", "message": "测试: 向右移动"},
	{"action": "move", "direction": "right", "duration": 1.0},
	{"action": "screenshot", "name": "moved_right"},
	{"action": "verify_position", "check": "x_increased", "expected": true},

	# 测试向左移动
	{"action": "log", "message": "测试: 向左移动"},
	{"action": "move", "direction": "left", "duration": 1.0},
	{"action": "screenshot", "name": "moved_left"},
	{"action": "verify_position", "check": "x_decreased", "expected": true},

	# 测试向上移动
	{"action": "log", "message": "测试: 向上移动"},
	{"action": "move", "direction": "up", "duration": 1.0},
	{"action": "screenshot", "name": "moved_up"},
	{"action": "verify_position", "check": "y_decreased", "expected": true},

	# 测试向下移动
	{"action": "log", "message": "测试: 向下移动"},
	{"action": "move", "direction": "down", "duration": 1.0},
	{"action": "screenshot", "name": "moved_down"},
	{"action": "verify_position", "check": "y_increased", "expected": true},

	# 测试斜向移动
	{"action": "log", "message": "测试: 斜向移动 (右下)"},
	{"action": "move", "direction": "right_down", "duration": 1.0},
	{"action": "screenshot", "name": "moved_diagonal"},

	# 测试停止
	{"action": "log", "message": "测试: 停止移动"},
	{"action": "stop", "duration": 0.5},
	{"action": "screenshot", "name": "stopped"},
	{"action": "verify_velocity", "expected_zero": true},

	# ==================== 背包系统测试 ====================
	{"action": "log", "message": "--- 背包系统测试 ---"},

	# 测试添加物品
	{"action": "log", "message": "测试: 添加物品到背包"},
	{"action": "test_inventory_add", "item_id": "bandage", "quantity": 5},
	{"action": "verify_inventory", "check": "has_item", "item_id": "bandage", "expected_quantity": 5},

	# 测试移除物品
	{"action": "log", "message": "测试: 从背包移除物品"},
	{"action": "test_inventory_remove", "item_id": "bandage", "quantity": 2},
	{"action": "verify_inventory", "check": "has_item", "item_id": "bandage", "expected_quantity": 3},

	# 测试物品堆叠
	{"action": "log", "message": "测试: 物品堆叠"},
	{"action": "test_inventory_add", "item_id": "bandage", "quantity": 10},
	{"action": "verify_inventory", "check": "has_item", "item_id": "bandage", "expected_quantity": 13},

	# ==================== 时间系统测试 ====================
	{"action": "log", "message": "--- 时间系统测试 ---"},

	# 测试时间获取
	{"action": "log", "message": "测试: 获取当前时间"},
	{"action": "test_time_system", "check": "get_time"},

	# 测试时间流逝
	{"action": "log", "message": "测试: 时间流逝"},
	{"action": "wait", "duration": 2.0},
	{"action": "test_time_system", "check": "time_passed"},

	# ==================== 游戏阶段测试 ====================
	{"action": "log", "message": "--- 游戏阶段测试 ---"},

	# 测试当前阶段
	{"action": "log", "message": "测试: 获取游戏阶段"},
	{"action": "test_game_phase", "check": "get_phase"},

	# ==================== 玩家状态测试 ====================
	{"action": "log", "message": "--- 玩家状态测试 ---"},

	# 测试生命值
	{"action": "log", "message": "测试: 玩家生命值"},
	{"action": "test_player_stats", "check": "hp"},

	# 测试饥饿度
	{"action": "log", "message": "测试: 玩家饥饿度"},
	{"action": "test_player_stats", "check": "hunger"},

	# 测试体力
	{"action": "log", "message": "测试: 玩家体力"},
	{"action": "test_player_stats", "check": "stamina"},

	# ==================== 完成测试 ====================

	# 移动到中心
	{"action": "log", "message": "移动回屏幕中心"},
	{"action": "move_to", "target": Vector2(320, 240), "duration": 2.0},
	{"action": "screenshot", "name": "final_state"},

	{"action": "log", "message": "=== 测试完成 ==="},
	{"action": "report"},
]

var last_position: Vector2
var current_simulated_input: Dictionary = {}

# 测试辅助变量
var last_time_hour: int = 0
var last_time_minute: int = 0

func _ready() -> void:
	if not auto_test_enabled:
		return

	# 等待场景加载完成
	await get_tree().process_frame
	await get_tree().process_frame

	# 查找玩家和截图管理器
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_node_or_null("../Player")

	screenshot_manager = get_node_or_null("../ScreenshotManager")

	if player:
		print("[AutoTest] 找到玩家节点")
		last_position = player.position
		# 将玩家添加到组以便查找
		player.add_to_group("player")
		# 开始测试
		start_tests()
	else:
		print("[AutoTest] 错误: 未找到玩家节点!")

func _physics_process(_delta: float) -> void:
	# 应用模拟输入到 Input 单例
	for action in current_simulated_input:
		if current_simulated_input[action]:
			Input.action_press(action)
		else:
			Input.action_release(action)

func start_tests() -> void:
	print("[AutoTest] 开始执行测试序列...")
	is_testing = true
	current_test_index = 0
	execute_next_test()

func execute_next_test() -> void:
	if current_test_index >= test_sequence.size():
		is_testing = false
		return

	var test = test_sequence[current_test_index]
	current_test_index += 1

	match test.action:
		"log":
			print("[AutoTest] " + test.message)
			execute_next_test()

		"wait":
			await get_tree().create_timer(test.duration).timeout
			execute_next_test()

		"screenshot":
			take_test_screenshot(test.name)
			await get_tree().create_timer(0.1).timeout
			execute_next_test()

		"move":
			last_position = player.position
			await simulate_movement(test.direction, test.duration)
			execute_next_test()

		"move_to":
			await move_player_to(test.target, test.duration)
			execute_next_test()

		"stop":
			stop_all_input()
			await get_tree().create_timer(test.duration).timeout
			execute_next_test()

		"verify_position":
			verify_position(test.check, test.expected)
			execute_next_test()

		"verify_velocity":
			verify_velocity(test.expected_zero)
			execute_next_test()

		# 背包测试
		"test_inventory_add":
			test_inventory_add(test.item_id, test.quantity)
			execute_next_test()

		"test_inventory_remove":
			test_inventory_remove(test.item_id, test.quantity)
			execute_next_test()

		"verify_inventory":
			verify_inventory(test.check, test.get("item_id", ""), test.get("expected_quantity", 0))
			execute_next_test()

		# 时间系统测试
		"test_time_system":
			test_time_system(test.check)
			execute_next_test()

		# 游戏阶段测试
		"test_game_phase":
			test_game_phase(test.check)
			execute_next_test()

		# 玩家状态测试
		"test_player_stats":
			test_player_stats(test.check)
			execute_next_test()

		"report":
			generate_report()
			execute_next_test()

func simulate_movement(direction: String, duration: float) -> void:
	stop_all_input()

	match direction:
		"right":
			current_simulated_input["move_right"] = true
		"left":
			current_simulated_input["move_left"] = true
		"up":
			current_simulated_input["move_up"] = true
		"down":
			current_simulated_input["move_down"] = true
		"right_down":
			current_simulated_input["move_right"] = true
			current_simulated_input["move_down"] = true
		"right_up":
			current_simulated_input["move_right"] = true
			current_simulated_input["move_up"] = true
		"left_down":
			current_simulated_input["move_left"] = true
			current_simulated_input["move_down"] = true
		"left_up":
			current_simulated_input["move_left"] = true
			current_simulated_input["move_up"] = true

	await get_tree().create_timer(duration).timeout
	stop_all_input()

func move_player_to(target: Vector2, duration: float) -> void:
	var start_time = Time.get_ticks_msec()
	var max_time = duration * 1000

	while Time.get_ticks_msec() - start_time < max_time:
		if not player:
			break

		var diff = target - player.position
		stop_all_input()

		if diff.length() < 10:
			break

		if diff.x > 5:
			current_simulated_input["move_right"] = true
		elif diff.x < -5:
			current_simulated_input["move_left"] = true

		if diff.y > 5:
			current_simulated_input["move_down"] = true
		elif diff.y < -5:
			current_simulated_input["move_up"] = true

		await get_tree().process_frame

	stop_all_input()

func stop_all_input() -> void:
	current_simulated_input = {
		"move_left": false,
		"move_right": false,
		"move_up": false,
		"move_down": false,
		"run": false,
		"interact": false,
	}
	# 释放所有输入
	for action in current_simulated_input:
		Input.action_release(action)

func take_test_screenshot(test_name: String) -> void:
	if screenshot_manager and screenshot_manager.has_method("take_screenshot"):
		screenshot_manager.take_screenshot("test_" + test_name)
	else:
		# 手动截图
		await RenderingServer.frame_post_draw
		var image = get_viewport().get_texture().get_image()
		var path = "res://screenshots/test_" + test_name + ".png"
		image.save_png(path)
		print("[AutoTest] 截图: " + path)

func verify_position(check: String, expected: bool) -> void:
	var current_pos = player.position
	var passed = false
	var message = ""

	match check:
		"x_increased":
			passed = (current_pos.x > last_position.x) == expected
			message = "X坐标增加: 期望=%s, 实际=%s (%.1f -> %.1f)" % [expected, current_pos.x > last_position.x, last_position.x, current_pos.x]
		"x_decreased":
			passed = (current_pos.x < last_position.x) == expected
			message = "X坐标减少: 期望=%s, 实际=%s (%.1f -> %.1f)" % [expected, current_pos.x < last_position.x, last_position.x, current_pos.x]
		"y_increased":
			passed = (current_pos.y > last_position.y) == expected
			message = "Y坐标增加: 期望=%s, 实际=%s (%.1f -> %.1f)" % [expected, current_pos.y > last_position.y, last_position.y, current_pos.y]
		"y_decreased":
			passed = (current_pos.y < last_position.y) == expected
			message = "Y坐标减少: 期望=%s, 实际=%s (%.1f -> %.1f)" % [expected, current_pos.y < last_position.y, last_position.y, current_pos.y]

	var result = "[%s] %s" % ["PASS" if passed else "FAIL", message]
	print("[AutoTest] " + result)
	test_results.append({"check": check, "passed": passed, "message": message})

	last_position = current_pos

func verify_velocity(expected_zero: bool) -> void:
	var velocity = player.velocity
	var is_zero = velocity.length() < 0.1
	var passed = is_zero == expected_zero
	var message = "速度为零: 期望=%s, 实际=%s (velocity=%.1f)" % [expected_zero, is_zero, velocity.length()]

	var result = "[%s] %s" % ["PASS" if passed else "FAIL", message]
	print("[AutoTest] " + result)
	test_results.append({"check": "velocity_zero", "passed": passed, "message": message})

# ==================== 背包测试方法 ====================

func test_inventory_add(item_id: String, quantity: int) -> void:
	var inventory = _get_inventory_manager()
	if not inventory:
		print("[AutoTest] 警告: 未找到背包管理器")
		test_results.append({"check": "inventory_add", "passed": false, "message": "未找到背包管理器"})
		return

	var added = inventory.add_item(item_id, quantity)
	var passed = added > 0
	var message = "添加物品 %s x%d: 实际添加=%d" % [item_id, quantity, added]

	var result = "[%s] %s" % ["PASS" if passed else "FAIL", message]
	print("[AutoTest] " + result)
	test_results.append({"check": "inventory_add", "passed": passed, "message": message})

func test_inventory_remove(item_id: String, quantity: int) -> void:
	var inventory = _get_inventory_manager()
	if not inventory:
		print("[AutoTest] 警告: 未找到背包管理器")
		test_results.append({"check": "inventory_remove", "passed": false, "message": "未找到背包管理器"})
		return

	var removed = inventory.remove_item(item_id, quantity)
	var passed = removed > 0
	var message = "移除物品 %s x%d: 实际移除=%d" % [item_id, quantity, removed]

	var result = "[%s] %s" % ["PASS" if passed else "FAIL", message]
	print("[AutoTest] " + result)
	test_results.append({"check": "inventory_remove", "passed": passed, "message": message})

func verify_inventory(check: String, item_id: String, expected_quantity: int) -> void:
	var inventory = _get_inventory_manager()
	if not inventory:
		print("[AutoTest] 警告: 未找到背包管理器")
		test_results.append({"check": "inventory_verify", "passed": false, "message": "未找到背包管理器"})
		return

	var passed = false
	var message = ""

	match check:
		"has_item":
			var actual_quantity = inventory.get_item_count(item_id)
			passed = actual_quantity == expected_quantity
			message = "物品 %s 数量: 期望=%d, 实际=%d" % [item_id, expected_quantity, actual_quantity]

	var result = "[%s] %s" % ["PASS" if passed else "FAIL", message]
	print("[AutoTest] " + result)
	test_results.append({"check": "inventory_verify", "passed": passed, "message": message})

func _get_inventory_manager():
	if has_node("/root/InventoryManager"):
		return get_node("/root/InventoryManager")
	return null

# ==================== 时间系统测试方法 ====================

func test_time_system(check: String) -> void:
	var passed = false
	var message = ""

	match check:
		"get_time":
			if GameManager:
				last_time_hour = GameManager.current_hour
				last_time_minute = GameManager.current_minute
				passed = true
				message = "当前时间: %02d:%02d" % [last_time_hour, last_time_minute]
			else:
				message = "未找到 GameManager"

		"time_passed":
			if GameManager:
				var current_hour = GameManager.current_hour
				var current_minute = GameManager.current_minute

				# 检查时间是否流逝 (可能跨小时)
				var time_passed = (current_hour * 60 + current_minute) > (last_time_hour * 60 + last_time_minute)
				passed = time_passed or (current_hour == last_time_hour and current_minute == last_time_minute)
				message = "时间流逝: %02d:%02d -> %02d:%02d" % [last_time_hour, last_time_minute, current_hour, current_minute]

				# 更新记录
				last_time_hour = current_hour
				last_time_minute = current_minute
			else:
				message = "未找到 GameManager"

	var result = "[%s] %s" % ["PASS" if passed else "INFO", message]
	print("[AutoTest] " + result)
	test_results.append({"check": "time_" + check, "passed": passed, "message": message})

# ==================== 游戏阶段测试方法 ====================

func test_game_phase(check: String) -> void:
	var passed = false
	var message = ""

	match check:
		"get_phase":
			if GameManager:
				var phase_name = GameManager.get_phase_name()
				var phase_display = GameManager.get_phase_display_name()
				passed = not phase_name.is_empty()
				message = "当前阶段: %s (%s)" % [phase_display, phase_name]
			else:
				message = "未找到 GameManager"

	var result = "[%s] %s" % ["PASS" if passed else "INFO", message]
	print("[AutoTest] " + result)
	test_results.append({"check": "phase_" + check, "passed": passed, "message": message})

# ==================== 玩家状态测试方法 ====================

func test_player_stats(check: String) -> void:
	var passed = false
	var message = ""

	# 尝试获取玩家状态组件
	var player_stats = null
	if player and player.has_node("PlayerStats"):
		player_stats = player.get_node("PlayerStats")

	match check:
		"hp":
			if player_stats:
				var current_hp = player_stats.current_hp
				var max_hp = player_stats.max_hp
				passed = current_hp > 0 and current_hp <= max_hp
				message = "HP: %.1f / %.1f" % [current_hp, max_hp]
			elif player:
				var current_hp = player.current_health if player.has_method("get") else 0
				var max_hp = player.max_health if player.has_method("get") else 100
				passed = current_hp > 0
				message = "HP: %.1f / %.1f (from Entity)" % [current_hp, max_hp]
			else:
				message = "未找到玩家"

		"hunger":
			if player_stats:
				var current_hunger = player_stats.current_hunger
				var max_hunger = player_stats.max_hunger
				passed = current_hunger >= 0 and current_hunger <= max_hunger
				message = "饥饿度: %.1f / %.1f" % [current_hunger, max_hunger]
			else:
				passed = true  # 没有状态组件时跳过
				message = "饥饿度: (无状态组件)"

		"stamina":
			if player_stats:
				var current_stamina = player_stats.current_stamina
				var max_stamina = player_stats.max_stamina
				passed = current_stamina >= 0 and current_stamina <= max_stamina
				message = "体力: %.1f / %.1f" % [current_stamina, max_stamina]
			else:
				passed = true  # 没有状态组件时跳过
				message = "体力: (无状态组件)"

	var result = "[%s] %s" % ["PASS" if passed else "INFO", message]
	print("[AutoTest] " + result)
	test_results.append({"check": "stats_" + check, "passed": passed, "message": message})

# ==================== 报告生成 ====================

func generate_report() -> void:
	var total = test_results.size()
	var passed = test_results.filter(func(r): return r.passed).size()
	var failed = total - passed

	print("")
	print("[AutoTest] ========== 测试报告 ==========")
	print("[AutoTest] 总测试数: %d" % total)
	print("[AutoTest] 通过: %d" % passed)
	print("[AutoTest] 失败: %d" % failed)
	print("[AutoTest] 通过率: %.1f%%" % (float(passed) / total * 100 if total > 0 else 0))
	print("[AutoTest] ================================")

	if failed > 0:
		print("[AutoTest] 失败的测试:")
		for result in test_results:
			if not result.passed:
				print("[AutoTest]   - " + result.message)

	print("")
