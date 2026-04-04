# ── ToolManager（Autoload 全局单例）──────────────────────────
# 管理玩家当前持有的工具
#
# 为什么用 Autoload 而不是把工具状态放在 Player 里？
# → UI 按钮、NPC、作物等各种节点都需要知道当前工具
# → Autoload 是全局单例，任何脚本都可以 ToolManager.select_tool(...)
# → 解耦：UI 不需要持有 Player 的引用
#
# 使用方式：
#   ToolManager.select_tool(DataTypes.Tools.AxeWood)   # 切换工具
#   ToolManager.tool_selected.connect(my_func)          # 监听工具变化
# ─────────────────────────────────────────────────────────────
extends Node

# 当前选中的工具（默认空手）
var selected_tool: DataTypes.Tools = DataTypes.Tools.None

# 工具被选中时发出（UI 和 Player 都监听这个）
signal tool_selected(tool: DataTypes.Tools)

# 用于通知 UI 某个工具按钮可以被启用（例如解锁新工具后）
signal enable_tool(tool: DataTypes.Tools)


# 切换工具并通知所有监听者
func select_tool(tool: DataTypes.Tools) -> void:
	selected_tool = tool
	tool_selected.emit(tool)
	print("[ToolManager] 切换工具 → ", DataTypes.Tools.keys()[tool])


# 通知 UI 启用某个工具按钮（在特定剧情触发后调用）
func enable_tool_button(tool: DataTypes.Tools) -> void:
	enable_tool.emit(tool)
