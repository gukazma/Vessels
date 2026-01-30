# main_menu.gd
# 主菜单界面
class_name MainMenu
extends Control

## ==================== 信号 ====================

## 新游戏点击
signal new_game_requested()

## 继续游戏点击
signal continue_game_requested()

## 设置点击
signal settings_requested()

## 退出点击
signal exit_requested()

## ==================== 节点引用 ====================

## 新游戏按钮
@onready var new_game_button: Button = $MenuPanel/NewGameButton if has_node("MenuPanel/NewGameButton") else null

## 继续游戏按钮
@onready var continue_button: Button = $MenuPanel/ContinueButton if has_node("MenuPanel/ContinueButton") else null

## 设置按钮
@onready var settings_button: Button = $MenuPanel/SettingsButton if has_node("MenuPanel/SettingsButton") else null

## 退出按钮
@onready var exit_button: Button = $MenuPanel/ExitButton if has_node("MenuPanel/ExitButton") else null

## 版本标签
@onready var version_label: Label = $VersionLabel if has_node("VersionLabel") else null

## ==================== 生命周期 ====================

func _ready() -> void:
	# 连接按钮信号
	_connect_buttons()

	# 检查是否有存档
	_check_save_available()

	# 显示版本
	_show_version()

	print("[MainMenu] 主菜单已初始化")


## ==================== 信号连接 ====================

func _connect_buttons() -> void:
	if new_game_button:
		new_game_button.pressed.connect(_on_new_game_pressed)

	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)


## ==================== 按钮事件 ====================

func _on_new_game_pressed() -> void:
	print("[MainMenu] 新游戏")
	new_game_requested.emit()

	# 切换到职业选择界面
	if EventBus:
		EventBus.open_menu.emit("profession_select")


func _on_continue_pressed() -> void:
	print("[MainMenu] 继续游戏")
	continue_game_requested.emit()

	# 加载存档
	if SaveManager:
		SaveManager.load_game()


func _on_settings_pressed() -> void:
	print("[MainMenu] 设置")
	settings_requested.emit()

	# 打开设置界面
	if EventBus:
		EventBus.open_menu.emit("settings")


func _on_exit_pressed() -> void:
	print("[MainMenu] 退出")
	exit_requested.emit()

	# 退出游戏
	get_tree().quit()


## ==================== 辅助方法 ====================

func _check_save_available() -> void:
	var has_save = false

	if SaveManager:
		has_save = SaveManager.has_save_data()

	if continue_button:
		continue_button.disabled = not has_save


func _show_version() -> void:
	if version_label:
		version_label.text = "v0.1.0 MVP"


## ==================== 公共方法 ====================

## 显示主菜单
func show_menu() -> void:
	visible = true
	_check_save_available()


## 隐藏主菜单
func hide_menu() -> void:
	visible = false
