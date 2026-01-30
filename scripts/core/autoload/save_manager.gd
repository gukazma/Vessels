# save_manager.gd
# 存档管理器 - 处理游戏数据的保存和加载
extends Node

## ==================== 常量 ====================

## 存档文件路径
const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_PREFIX: String = "save_"
const SAVE_FILE_EXTENSION: String = ".json"
const AUTO_SAVE_NAME: String = "autosave"
const MAX_SAVE_SLOTS: int = 5

## 存档版本 (用于兼容性检查)
const SAVE_VERSION: String = "1.0"

## ==================== 信号 ====================

## 存档操作完成
signal save_completed(success: bool, slot: int)

## 加载操作完成
signal load_completed(success: bool, slot: int)

## 存档列表更新
signal save_list_updated(saves: Array)

## ==================== 变量 ====================

## 当前存档槽位 (0表示未选择)
var current_slot: int = 0

## 是否启用自动存档
var auto_save_enabled: bool = true

## 自动存档间隔 (游戏天数)
var auto_save_interval: int = 1

## 上次自动存档的天数
var _last_auto_save_day: int = 0

## ==================== 生命周期 ====================

func _ready() -> void:
	print("[SaveManager] 存档管理器已初始化")

	# 确保存档目录存在
	_ensure_save_directory()

	# 连接事件
	if EventBus:
		EventBus.day_changed.connect(_on_day_changed)


## ==================== 公共方法 ====================

## 保存游戏到指定槽位
func save_game(slot: int = 0) -> bool:
	if slot == 0:
		slot = current_slot
	if slot == 0:
		slot = 1  # 默认使用槽位1

	print("[SaveManager] 保存游戏到槽位 %d" % slot)

	var save_data = _collect_save_data()
	var success = _write_save_file(slot, save_data)

	if success:
		current_slot = slot
		if EventBus:
			EventBus.game_saved.emit()
		print("[SaveManager] 游戏保存成功")
	else:
		print("[SaveManager] 游戏保存失败")

	save_completed.emit(success, slot)
	return success


## 加载游戏从指定槽位
func load_game(slot: int) -> bool:
	print("[SaveManager] 加载游戏从槽位 %d" % slot)

	var save_data = _read_save_file(slot)
	if save_data.is_empty():
		print("[SaveManager] 存档文件为空或不存在")
		load_completed.emit(false, slot)
		return false

	# 检查版本兼容性
	var save_version = save_data.get("version", "0.0")
	if not _is_version_compatible(save_version):
		print("[SaveManager] 存档版本不兼容: %s" % save_version)
		load_completed.emit(false, slot)
		return false

	# 分发数据到各个系统
	var success = _distribute_save_data(save_data)

	if success:
		current_slot = slot
		if EventBus:
			EventBus.game_loaded.emit()
		print("[SaveManager] 游戏加载成功")
	else:
		print("[SaveManager] 游戏加载失败")

	load_completed.emit(success, slot)
	return success


## 自动存档
func auto_save() -> bool:
	if not auto_save_enabled:
		return false

	print("[SaveManager] 执行自动存档")
	return _write_auto_save()


## 删除存档
func delete_save(slot: int) -> bool:
	var file_path = _get_save_file_path(slot)
	if FileAccess.file_exists(file_path):
		var err = DirAccess.remove_absolute(file_path)
		if err == OK:
			print("[SaveManager] 删除存档槽位 %d 成功" % slot)
			return true
		else:
			print("[SaveManager] 删除存档槽位 %d 失败: %d" % [slot, err])
			return false
	return true  # 文件不存在也算成功


## 检查存档是否存在
func save_exists(slot: int) -> bool:
	var file_path = _get_save_file_path(slot)
	return FileAccess.file_exists(file_path)


## 检查自动存档是否存在
func auto_save_exists() -> bool:
	var file_path = SAVE_DIR + AUTO_SAVE_NAME + SAVE_FILE_EXTENSION
	return FileAccess.file_exists(file_path)


## 检查是否有任何存档数据
func has_save_data() -> bool:
	# 检查所有存档槽位
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		if save_exists(slot):
			return true
	# 检查自动存档
	return auto_save_exists()


## 获取存档信息列表
func get_save_list() -> Array:
	var saves: Array = []

	for slot in range(1, MAX_SAVE_SLOTS + 1):
		var info = get_save_info(slot)
		if info:
			saves.append(info)

	# 检查自动存档
	var auto_info = _get_auto_save_info()
	if auto_info:
		saves.append(auto_info)

	save_list_updated.emit(saves)
	return saves


## 获取指定槽位的存档信息
func get_save_info(slot: int) -> Dictionary:
	if not save_exists(slot):
		return {}

	var save_data = _read_save_file(slot)
	if save_data.is_empty():
		return {}

	return {
		"slot": slot,
		"timestamp": save_data.get("timestamp", ""),
		"day": save_data.get("game_state", {}).get("day", 1),
		"phase": save_data.get("game_state", {}).get("phase", "peace"),
		"profession": save_data.get("player", {}).get("profession", ""),
		"play_time": save_data.get("play_time", 0)
	}


## 从自动存档加载
func load_auto_save() -> bool:
	var file_path = SAVE_DIR + AUTO_SAVE_NAME + SAVE_FILE_EXTENSION
	if not FileAccess.file_exists(file_path):
		print("[SaveManager] 自动存档不存在")
		return false

	var save_data = _read_json_file(file_path)
	if save_data.is_empty():
		return false

	return _distribute_save_data(save_data)


## ==================== 私有方法 ====================

## 确保存档目录存在
func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		print("[SaveManager] 创建存档目录: %s" % SAVE_DIR)


## 获取存档文件路径
func _get_save_file_path(slot: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXTENSION


## 收集需要保存的数据
func _collect_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"play_time": 0,  # TODO: 实现游戏时间统计
		"game_state": {},
		"player": {},
		"inventory": [],
		"npcs": {},
		"base": {},
		"quests": {}
	}

	# 从 GameManager 收集数据
	if GameManager:
		data["game_state"] = GameManager.get_save_data()

	# TODO: 从其他系统收集数据
	# if InventoryManager:
	#     data["inventory"] = InventoryManager.get_save_data()
	# if CharacterManager:
	#     data["npcs"] = CharacterManager.get_save_data()
	# if BaseManager:
	#     data["base"] = BaseManager.get_save_data()

	return data


## 分发存档数据到各个系统
func _distribute_save_data(data: Dictionary) -> bool:
	# 加载到 GameManager
	if GameManager and data.has("game_state"):
		GameManager.load_save_data(data["game_state"])

	# TODO: 加载到其他系统
	# if InventoryManager and data.has("inventory"):
	#     InventoryManager.load_save_data(data["inventory"])
	# if CharacterManager and data.has("npcs"):
	#     CharacterManager.load_save_data(data["npcs"])
	# if BaseManager and data.has("base"):
	#     BaseManager.load_save_data(data["base"])

	return true


## 写入存档文件
func _write_save_file(slot: int, data: Dictionary) -> bool:
	var file_path = _get_save_file_path(slot)
	return _write_json_file(file_path, data)


## 读取存档文件
func _read_save_file(slot: int) -> Dictionary:
	var file_path = _get_save_file_path(slot)
	return _read_json_file(file_path)


## 写入自动存档
func _write_auto_save() -> bool:
	var file_path = SAVE_DIR + AUTO_SAVE_NAME + SAVE_FILE_EXTENSION
	var save_data = _collect_save_data()
	return _write_json_file(file_path, save_data)


## 获取自动存档信息
func _get_auto_save_info() -> Dictionary:
	var file_path = SAVE_DIR + AUTO_SAVE_NAME + SAVE_FILE_EXTENSION
	if not FileAccess.file_exists(file_path):
		return {}

	var save_data = _read_json_file(file_path)
	if save_data.is_empty():
		return {}

	return {
		"slot": -1,  # -1 表示自动存档
		"is_auto_save": true,
		"timestamp": save_data.get("timestamp", ""),
		"day": save_data.get("game_state", {}).get("day", 1),
		"phase": save_data.get("game_state", {}).get("phase", "peace"),
		"profession": save_data.get("player", {}).get("profession", ""),
		"play_time": save_data.get("play_time", 0)
	}


## 写入JSON文件
func _write_json_file(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("[SaveManager] 无法打开文件进行写入: %s" % file_path)
		return false

	var json_string = JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true


## 读取JSON文件
func _read_json_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("[SaveManager] 无法打开文件进行读取: %s" % file_path)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("[SaveManager] JSON解析错误: %s" % json.get_error_message())
		return {}

	return json.get_data()


## 检查版本兼容性
func _is_version_compatible(version: String) -> bool:
	# 简单的版本兼容检查
	# TODO: 实现更复杂的版本兼容逻辑
	var current_parts = SAVE_VERSION.split(".")
	var save_parts = version.split(".")

	if current_parts.size() < 1 or save_parts.size() < 1:
		return false

	# 主版本号必须相同
	return current_parts[0] == save_parts[0]


## 天数变化时检查自动存档
func _on_day_changed(day: int) -> void:
	if not auto_save_enabled:
		return

	# 检查是否需要自动存档
	if day - _last_auto_save_day >= auto_save_interval:
		_last_auto_save_day = day
		auto_save()
