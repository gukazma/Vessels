class_name CommandHud
extends CanvasLayer
## Plain command/status UI for testing rules; no dependencies on combat internals.

var _status: Label
var _selection: Label
var _objective: Label
var _report: Label
var _pause_button: Button
var _inspection: Label
var _panels: Array[Control] = []
var _status_until: float = 0.0
var _refresh_remaining: float = 0.0
@onready var _battle: CommandSandbox = get_parent() as CommandSandbox


func _ready() -> void:
	var top: Panel = _panel(Vector2(18, 18), Vector2(560, 202 if _battle.cover_enabled else 178))
	var title: String = "三国 · 第一场遭遇战" if _battle.combat_enabled else "三国 · 指挥训练场"
	if _battle.cover_enabled:
		title = "三国 · 掩体与侧射练习"
	_label(top, title, Vector2(16, 10), 22, Color("eadfbd"))
	var help: String = "左键/框选 选择　Shift 加选　右键 移动　1/2 选队\nWASD/中键 镜头　滚轮 缩放　F 聚焦　Tab 全选"
	if _battle.combat_enabled:
		help += "\n右键敌军 攻击　Shift+右键 追加命令　空格 暂停\nX 清空命令并守卫　R 重开　Esc 清除选择"
	else:
		help += "\nX 停止　R 重置　Esc 清除选择"
	if _battle.cover_enabled:
		help += "\nQ 面向鼠标定向守卫　悬停敌军 预估伤害"
	help += "\nF1 基础遭遇战　F2 掩体练习（切换会重开）"
	_label(top, help, Vector2(16, 43), 15, Color("d4d9c8"))
	var bottom: Panel = _panel(Vector2(18, 0), Vector2(660, 205 if _battle.cover_enabled else 158))
	_objective = _label(bottom, "", Vector2(16, 10), 17, Color("e6bf7c"))
	_selection = _label(bottom, "", Vector2(16, 39), 15, Color("d4d9c8"))
	_status = _label(bottom, "", Vector2(16, 172 if _battle.cover_enabled else 112), 14, Color("e6bf7c"))
	if _battle.cover_enabled:
		_label(bottom, "绿带：掩体位置；棕箭头：受保护的来袭方向。\n盾弧保护正前方；绕过墙端可避开掩体。\n掩体与盾牌取较强防护，近战须绕过矮墙。",
			Vector2(16, 96), 14, Color("b7c7b6"))
	var actions: Panel = _panel(Vector2.ZERO, Vector2(308, 185))
	_report = _label(actions, "", Vector2(14, 10), 15, Color("d4d9c8"))
	_pause_button = _button(actions, "暂停 / 继续 [空格]", Vector2(14, 94), Vector2(280, 32), _battle.toggle_tactical_pause)
	_button(actions, "清空命令 [X]", Vector2(14, 136), Vector2(134, 32), _battle.stop_selected)
	_button(actions, "重开 [R]", Vector2(158, 136), Vector2(136, 32), _battle.reset_squads)
	actions.visible = _battle.combat_enabled
	var inspection: Panel = _panel(Vector2.ZERO, Vector2(308, 205))
	inspection.visible = _battle.cover_enabled
	_inspection = _label(inspection, "", Vector2(14, 12), 14, Color("eadfbd"))
	_battle.order_feedback.connect(_on_order_feedback)
	_battle.selection_changed.connect(_refresh)
	_battle.battle_state_changed.connect(_refresh)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_refresh()


func _layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_panels[1].position = Vector2(18, viewport_size.y - _panels[1].size.y - 17)
	_panels[1].size.x = minf(660.0, viewport_size.x - (362.0 if _battle.cover_enabled else 36.0))
	_panels[2].position = Vector2(viewport_size.x - 326, 18)
	_panels[3].position = Vector2(viewport_size.x - 326, viewport_size.y - 222)


func _process(delta: float) -> void:
	_status_until = maxf(0.0, _status_until - delta)
	if _status_until <= 0.0:
		_status.text = ""
	_refresh_remaining -= delta
	if _refresh_remaining <= 0.0:
		_refresh_remaining = 0.1
		_refresh()


func blocks_screen(at: Vector2) -> bool:
	for panel: Control in _panels:
		if panel.visible and panel.get_global_rect().has_point(at):
			return true
	return false


func _on_order_feedback(message: String) -> void:
	_status.text = message
	_status_until = 3.0
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_selection):
		return
	if _battle.combat_enabled:
		_objective.text = "目标：击败全部敌军 · 盾兵接敌，弓兵保持距离"
		if _battle.cover_enabled:
			_objective.text = "目标：突破敌军阵地 · 比较正攻与绕侧"
		if _battle.is_tactical_paused():
			_objective.text = "战术暂停 · 可以排命令 · 按空格开始执行"
		if _battle.battle_finished:
			_objective.text = ["战斗胜利", "战斗失败"][_battle.winner] if _battle.winner >= 0 else "双方同归于尽"
			_objective.text += " · 按 R 重新挑战"
		_report.text = "实时伤亡\n" + _battle.battle_report().replace(" · ", "\n")
		_pause_button.disabled = _battle.battle_finished
		_pause_button.text = "继续战斗 [空格]" if _battle.is_tactical_paused() else "战术暂停 [空格]"
	else:
		_objective.text = "移动训练 · 试试绕过障碍，调整队伍位置"
	var lines: PackedStringArray = []
	for squad: TacticalSquad in _battle.selected_squads():
		var line: String = squad.squad_name
		if _battle.combat_enabled:
			line += "  %d/7 人  HP %d/%d  %s" % [squad.living_members(),
				ceili(squad.health), ceili(squad.max_health), _battle.combat.order_label(squad)]
			var pending: int = maxi(0, _battle.combat.queue_size(squad) - 1)
			if pending > 0:
				line += "（+%d 条）" % pending
			if _battle.combat.is_under_pressure(squad):
				line += "  贴身受压"
			if _battle.cover_enabled and _battle.combat.cover_at(squad) != null:
				line += "  掩体内"
		lines.append(line)
	_selection.text = "\n".join(lines) if not lines.is_empty() else "未选部队 · 点击我军或按 Tab 全选"
	if _battle.cover_enabled:
		_refresh_inspection()


func _refresh_inspection() -> void:
	var target: TacticalSquad = _battle.hovered_enemy()
	var selected: Array[TacticalSquad] = _battle.selected_squads()
	if target == null or selected.is_empty():
		_inspection.text = "攻击预估\n\n选中我军，将鼠标停在敌军上。\n\n比较正面与侧后方的单轮伤害。\n超出射程也可观察防护关系。\n实际伤害随伤亡与朝向变化。"
		return
	var lines: PackedStringArray = ["目标：%s · %d 人" % [target.squad_name, target.living_members()]]
	for squad: TacticalSquad in selected:
		var preview: Dictionary = _battle.combat.attack_preview(squad, target)
		lines.append("%s → 单轮 %.1f" % [squad.definition.display_name, preview.damage])
		var protection: String = "掩体减伤" if preview.covered else ("正面盾防" if preview.shielded else "无防护减伤")
		if preview.flanked:
			protection += " · 侧背"
		lines.append(protection)
		var condition: String = "射程与朝向满足"
		if preview.blocked:
			condition = "被墙阻挡"
		elif not preview.in_range:
			condition = "超出射程"
		elif not preview.aligned:
			condition = "需要转向"
		if preview.under_pressure:
			condition += " · 我军贴身受压"
		lines.append(condition)
	_inspection.text = "\n".join(lines)


func _panel(at: Vector2, dimensions: Vector2) -> Panel:
	var panel: Panel = Panel.new()
	panel.position = at
	panel.size = dimensions
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.09, 0.1, 0.92)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	_panels.append(panel)
	return panel


func _label(parent: Control, text: String, at: Vector2, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _button(parent: Control, title: String, at: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = title
	button.position = at
	button.size = dimensions
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	parent.add_child(button)
	return button
