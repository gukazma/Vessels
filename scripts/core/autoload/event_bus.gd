# event_bus.gd
# 事件总线 - 全局事件管理器
# 使用发布-订阅模式解耦模块间通信
extends Node

## ==================== 时间相关信号 ====================

## 游戏时间更新 (每游戏分钟触发)
## hour: 当前小时 (0-23)
## minute: 当前分钟 (0-59)
signal time_tick(hour: int, minute: int)

## 新的一天开始
## day: 当前天数 (从1开始)
signal day_changed(day: int)

## 游戏阶段变化
## phase: 阶段名称 ("peace" / "apocalypse" / "survival")
signal phase_changed(phase: String)

## 时间段变化 (黎明、早晨、上午、中午、下午、傍晚、夜晚、深夜)
## period: 时间段名称
signal time_period_changed(period: String)

## ==================== 玩家相关信号 ====================

## 玩家属性变化
## stat: 属性名 ("hp" / "hunger" / "stamina" / "morale")
## value: 新的属性值
## max_value: 属性最大值
signal player_stat_changed(stat: String, value: float, max_value: float)

## 玩家金钱变化
## amount: 当前金额
## delta: 变化量 (正数增加，负数减少)
signal player_money_changed(amount: int, delta: int)

## 玩家状态效果变化
## effect: 状态效果名称 ("injured" / "hungry" / "exhausted" / "infected")
## active: 是否激活
signal player_status_effect_changed(effect: String, active: bool)

## 玩家死亡
signal player_died()

## 玩家职业属性变化
## attribute: 职业属性名 ("combat" / "build" / "medical" / "social" / "cooking")
## value: 新的属性值
signal player_attribute_changed(attribute: String, value: int)

## ==================== 物品相关信号 ====================

## 物品添加到背包
## item_id: 物品ID
## quantity: 添加数量
signal item_added(item_id: String, quantity: int)

## 物品从背包移除
## item_id: 物品ID
## quantity: 移除数量
signal item_removed(item_id: String, quantity: int)

## 物品使用
## item_id: 物品ID
signal item_used(item_id: String)

## 背包已满
signal inventory_full()

## 装备武器变化
## weapon_id: 武器ID (空字符串表示卸下)
signal weapon_equipped(weapon_id: String)

## ==================== NPC相关信号 ====================

## NPC好感度变化
## npc_id: NPC的ID
## value: 新的好感度值
## delta: 变化量
signal npc_relationship_changed(npc_id: String, value: int, delta: int)

## NPC被招募
## npc_id: NPC的ID
signal npc_recruited(npc_id: String)

## NPC离队
## npc_id: NPC的ID
## reason: 离队原因
signal npc_left(npc_id: String, reason: String)

## NPC死亡
## npc_id: NPC的ID
signal npc_died(npc_id: String)

## 开始与NPC对话
## npc_id: NPC的ID
signal dialog_started(npc_id: String)

## 结束与NPC对话
## npc_id: NPC的ID
signal dialog_ended(npc_id: String)

## ==================== 据点相关信号 ====================

## 据点属性变化
## stat: 属性名 ("defense" / "food_storage" / "comfort" / "population")
## value: 新的属性值
signal base_stat_changed(stat: String, value: float)

## 据点等级提升
## level: 新等级
signal base_level_up(level: int)

## 建筑建造开始
## building_id: 建筑ID
## position: 建造位置
signal building_construction_started(building_id: String, position: Vector2)

## 建筑建造完成
## building_id: 建筑ID
signal building_construction_completed(building_id: String)

## 建筑被摧毁
## building_id: 建筑ID
signal building_destroyed(building_id: String)

## 据点被攻击
## damage: 受到的伤害
signal base_attacked(damage: float)

## ==================== 战斗相关信号 ====================

## 僵尸生成
## position: 生成位置
## zombie_type: 僵尸类型
signal zombie_spawned(position: Vector2, zombie_type: String)

## 僵尸死亡
## position: 死亡位置
## zombie_type: 僵尸类型
signal zombie_killed(position: Vector2, zombie_type: String)

## 实体受到伤害
## entity: 受伤的实体
## damage: 伤害值
## attacker: 攻击者 (可为null)
signal entity_damaged(entity: Node, damage: float, attacker: Node)

## 战斗开始
signal combat_started()

## 战斗结束
signal combat_ended()

## 夜间防御战开始
## zombie_count: 僵尸数量
signal night_defense_started(zombie_count: int)

## 夜间防御战结束
## survived: 是否存活
## casualties: 伤亡人数
signal night_defense_ended(survived: bool, casualties: int)

## ==================== 工作相关信号 ====================

## 工作开始
## workplace: 工作地点
signal work_started(workplace: String)

## 工作结束
## wage: 获得的工资
## stamina_cost: 消耗的体力
signal work_ended(wage: int, stamina_cost: int)

## 迟到
## penalty: 惩罚金额
signal work_late(penalty: int)

## 旷工
signal work_missed()

## ==================== 任务相关信号 ====================

## 任务接受
## quest_id: 任务ID
signal quest_accepted(quest_id: String)

## 任务进度更新
## quest_id: 任务ID
## progress: 当前进度
## total: 总进度
signal quest_progress_updated(quest_id: String, progress: int, total: int)

## 任务完成
## quest_id: 任务ID
signal quest_completed(quest_id: String)

## 任务失败
## quest_id: 任务ID
signal quest_failed(quest_id: String)

## ==================== 系统相关信号 ====================

## 游戏保存
signal game_saved()

## 游戏加载
signal game_loaded()

## 游戏暂停
signal game_paused()

## 游戏继续
signal game_resumed()

## 游戏结束 (胜利)
## reason: 胜利原因
signal game_won(reason: String)

## 游戏结束 (失败)
## reason: 失败原因
signal game_over(reason: String)

## ==================== UI相关信号 ====================

## 显示消息提示
## message: 消息内容
## type: 消息类型 ("info" / "warning" / "error" / "success")
signal show_message(message: String, type: String)

## 显示确认对话框
## title: 标题
## message: 消息内容
## callback: 回调函数名
signal show_confirm_dialog(title: String, message: String, callback: Callable)

## 打开菜单
## menu_name: 菜单名称
signal open_menu(menu_name: String)

## 关闭菜单
## menu_name: 菜单名称
signal close_menu(menu_name: String)

## ==================== 交互相关信号 ====================

## 进入可交互范围
## interactable: 可交互物体
signal interaction_available(interactable: Node)

## 离开可交互范围
## interactable: 可交互物体
signal interaction_unavailable(interactable: Node)

## 交互执行
## interactable: 被交互的物体
signal interaction_performed(interactable: Node)

## ==================== 初始化 ====================

func _ready() -> void:
	# 事件总线初始化完成
	print("[EventBus] 事件总线已初始化")


## ==================== 辅助方法 ====================

## 发送显示消息的便捷方法
func emit_info(message: String) -> void:
	show_message.emit(message, "info")


func emit_warning(message: String) -> void:
	show_message.emit(message, "warning")


func emit_error(message: String) -> void:
	show_message.emit(message, "error")


func emit_success(message: String) -> void:
	show_message.emit(message, "success")
