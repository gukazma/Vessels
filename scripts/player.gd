# ── Player ───────────────────────────────────────────────────
# 角色根节点脚本，只负责存储共享数据
#
# 移动、动画、工具使用等逻辑已全部拆到独立的 NodeState 子节点
# 各状态脚本通过 @export var player: Player 获得这里的数据
# ─────────────────────────────────────────────────────────────
class_name Player
extends CharacterBody2D

# 玩家当前朝向（由 walk_state 更新，供动作状态判断攻击/动画方向）
var player_direction: Vector2 = Vector2.DOWN

# 当前持有的工具（由 ToolManager 信号更新，步骤三完成后接入）
var current_tool: DataTypes.Tools = DataTypes.Tools.None
