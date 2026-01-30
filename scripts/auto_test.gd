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

	# 移动到中心
	{"action": "log", "message": "移动回屏幕中心"},
	{"action": "move_to", "target": Vector2(320, 240), "duration": 2.0},
	{"action": "screenshot", "name": "final_state"},

	{"action": "log", "message": "=== 测试完成 ==="},
	{"action": "report"},
]

var last_position: Vector2
var current_simulated_input: Dictionary = {}

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
