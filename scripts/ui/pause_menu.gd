# pause_menu.gd
# 暂停菜单界面
class_name PauseMenu
extends Control

## ==================== 信号 ====================

## 继续游戏
signal resume_requested()

## 保存游戏
signal save_requested()

## 加载游戏
signal load_requested()

## 设置
signal settings_requested()

## 返回主菜单
signal main_menu_requested()

## ==================== 节点引用 ====================

## 继续按钮
@onready var resume_button: Button = $Panel/ResumeButton if has_node("Panel/ResumeButton") else null

## 保存按钮
@onready var save_button: Button = $Panel/SaveButton if has_node("Panel/SaveButton") else null

## 加载按钮
@onready var load_button: Button = $Panel/LoadButton if has_node("Panel/LoadButton") else null

## 设置按钮
@onready var settings_button: Button = $Panel/SettingsButton if has_node("Panel/SettingsButton") else null

## 返回主菜单按钮
@onready var main_menu_button: Button = $Panel/MainMenuButton if has_node("Panel/MainMenuButton") else null

## 状态标签 (显示当前游戏信息)
@onready var status_label: Label = $Panel/StatusLabel if has_node("Panel/StatusLabel") else null

## ==================== 生命周期 ====================

func _ready() -> void:
	# 连接按钮信号
	_connect_buttons()

	# 初始隐藏
	visible = false

	print("[PauseMenu] 暂停菜单已初始化")


func _input(event: InputEvent) -> void:
	# ESC 切换暂停菜单
	if event.is_action_pressed("pause"):
		toggle_pause()


## ==================== 信号连接 ====================

func _connect_buttons() -> void:
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)

	if save_button:
		save_button.pressed.connect(_on_save_pressed)

	if load_button:
		load_button.pressed.connect(_on_load_pressed)

	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)


## ==================== 按钮事件 ====================

func _on_resume_pressed() -> void:
	print("[PauseMenu] 继续游戏")
	resume_game()


func _on_save_pressed() -> void:
	print("[PauseMenu] 保存游戏")
	save_requested.emit()

	if SaveManager:
		SaveManager.save_game()
		if EventBus:
			EventBus.emit_success("游戏已保存!")


func _on_load_pressed() -> void:
	print("[PauseMenu] 加载游戏")
	load_requested.emit()

	if SaveManager:
		SaveManager.load_game(0)
		resume_game()


func _on_settings_pressed() -> void:
	print("[PauseMenu] 设置")
	settings_requested.emit()

	# 打开设置界面
	if EventBus:
		EventBus.open_menu.emit("settings")


func _on_main_menu_pressed() -> void:
	print("[PauseMenu] 返回主菜单")
	main_menu_requested.emit()

	# 确认对话框
	_show_confirm_dialog()


func _show_confirm_dialog() -> void:
	# TODO: 显示确认对话框

	# 暂时直接返回
	_return_to_main_menu()


func _return_to_main_menu() -> void:
	# 返回主菜单
	if GameManager:
		GameManager.return_to_menu()

	resume_game()

	# 切换到主菜单场景
	# get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


## ==================== 暂停控制 ====================

## 暂停游戏
func pause_game() -> void:
	visible = true
	get_tree().paused = true

	# 更新状态信息
	_update_status()

	if GameManager:
		GameManager.pause_game()


## 继续游戏
func resume_game() -> void:
	visible = false
	get_tree().paused = false

	resume_requested.emit()

	if GameManager:
		GameManager.resume_game()


## 切换暂停状态
func toggle_pause() -> void:
	if visible:
		resume_game()
	else:
		pause_game()


## ==================== 显示更新 ====================

func _update_status() -> void:
	if not status_label:
		return

	var status_text = ""

	if GameManager:
		status_text += "Day %d\n" % GameManager.current_day
		status_text += "%02d:%02d\n" % [GameManager.current_hour, GameManager.current_minute]
		status_text += GameManager.get_phase_display_name()

	status_label.text = status_text


## ==================== 公共方法 ====================

## 检查是否已暂停
func is_paused() -> bool:
	return visible
