class_name CommandHud
extends CanvasLayer
## Small gray-box HUD. It exposes controls without becoming a final UI commitment.

var _title: Label
var _instructions: Label
var _status: Label
var _selection: Label
var _panel: ColorRect
var _status_until: float = 0.0
@onready var _battle: CommandSandbox = get_parent() as CommandSandbox


func _ready() -> void:
	_panel = ColorRect.new()
	_panel.position = Vector2(18, 18)
	_panel.size = Vector2(430, 112)
	_panel.color = Color(0.05, 0.09, 0.1, 0.86)
	add_child(_panel)
	_title = _label("三国 · 战术试验场  /  M0 灰盒", Vector2(18, 14), 22, Color("eadfbd"))
	_instructions = _label("左键选择 / 拖拽框选    Shift 加选\n右键移动    X 停止    F 聚焦    R 重置    Esc 清除", Vector2(18, 47), 15, Color("bdc8b2"))
	_status = _label("", Vector2(18, 115), 15, Color("e6bf7c"))
	_selection = _label("", Vector2(18, 142), 15, Color("3f7772"))
	_battle.order_feedback.connect(_on_order_feedback)
	_battle.selection_changed.connect(_on_selection_changed)
	_on_selection_changed()


func _process(delta: float) -> void:
	_status_until = maxf(0.0, _status_until - delta)
	if _status_until <= 0.0:
		_status.text = ""
	_on_selection_changed()


func blocks_screen(at: Vector2) -> bool:
	return Rect2(_panel.position, _panel.size).has_point(at) or Rect2(18, 130, 430, 42).has_point(at)


func _on_order_feedback(message: String) -> void:
	_status.text = message
	_status_until = 2.2


func _on_selection_changed() -> void:
	if not is_instance_valid(_selection) or _status_until > 0.0:
		return
	var selected: Array[TacticalSquad] = _battle.selected_squads()
	if selected.is_empty():
		_selection.text = "未选择部队"
	else:
		var names: PackedStringArray = PackedStringArray()
		for squad: TacticalSquad in selected:
			names.append(squad.squad_name)
		_selection.text = "已选择：" + "、".join(names)


func _label(text: String, at: Vector2, size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
