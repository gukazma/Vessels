class_name CommandSandbox
extends Node2D
## First playable slice: readable selection and reliable orders before combat.

signal selection_changed
signal order_feedback(message: String)
const SQUAD_SCENE: PackedScene = preload("res://features/squads/squad.tscn")
const WORLD_BOUNDS: Rect2 = Rect2(0, 0, 1800, 1200)
const OBSTACLES: Array[Rect2] = [Rect2(820, 400, 128, 320),
	Rect2(450, 220, 224, 64), Rect2(1150, 750, 256, 64)]
const STARTS: Array[Vector2] = [Vector2(460, 490), Vector2(460, 670), Vector2(650, 560)]
const GROUP_SPACING: float = 92.0
var squads: Array[TacticalSquad] = []
var navigation: BattleNavigation = BattleNavigation.new()
var selection_rect: Rect2
var _order_markers: Array[Vector2] = []
var _marker_lifetime: float = 0.0
@onready var camera: BattleCamera = $Camera


func _ready() -> void:
	navigation.setup(WORLD_BOUNDS, OBSTACLES, 28.0)
	camera.world_bounds = WORLD_BOUNDS
	var names: Array[String] = ["青龙队", "白虎队", "朱雀队"]
	var colors: Array[Color] = [Color("477b82"), Color("8b7857"), Color("af695b")]
	for index: int in range(STARTS.size()):
		var squad: TacticalSquad = SQUAD_SCENE.instantiate() as TacticalSquad
		squad.squad_name = names[index]
		squad.accent = colors[index]
		squad.position = STARTS[index]
		$Squads.add_child(squad)
		squads.append(squad)
	select_at(STARTS[0])


func selected_squads() -> Array[TacticalSquad]:
	var result: Array[TacticalSquad] = []
	for squad: TacticalSquad in squads:
		if squad.is_selected():
			result.append(squad)
	return result


func select_at(at: Vector2, additive: bool = false) -> void:
	var nearest: TacticalSquad
	var distance: float = 36.0
	for squad: TacticalSquad in squads:
		var candidate: float = squad.position.distance_to(at)
		if candidate < distance:
			nearest = squad
			distance = candidate
	if not additive:
		_set_all_selected(false)
	if nearest != null:
		nearest.set_selected(not nearest.is_selected() if additive else true)
	selection_changed.emit()


func select_in_rect(rect: Rect2, additive: bool = false) -> void:
	if not additive:
		_set_all_selected(false)
	for squad: TacticalSquad in squads:
		if rect.abs().has_point(squad.position):
			squad.set_selected(true)
	selection_changed.emit()


func select_index(index: int) -> void:
	if index >= 0 and index < squads.size():
		select_at(squads[index].position)


func clear_selection() -> void:
	_set_all_selected(false)
	selection_changed.emit()


func move_selected(at: Vector2) -> bool:
	var selected: Array[TacticalSquad] = selected_squads()
	if selected.is_empty():
		order_feedback.emit("先选择一支部队，再下达移动命令。")
		return false
	# Validate the entire order before assigning paths; invalid orders keep existing ones.
	var paths: Array[PackedVector2Array] = []
	var targets: Array[Vector2] = []
	for index: int in range(selected.size()):
		var target: Vector2 = at + Vector2(0, (float(index) - float(selected.size() - 1) / 2.0) * GROUP_SPACING)
		var path: PackedVector2Array = navigation.find_path(selected[index].position, target)
		if path.is_empty():
			order_feedback.emit("目的地空间不足或不可达，请选择开阔地面。")
			return false
		paths.append(path)
		targets.append(target)
	for index: int in range(selected.size()):
		selected[index].issue_move(targets[index], paths[index])
	_order_markers = targets
	_marker_lifetime = 2.5
	order_feedback.emit("已下令 %d 队移动 · 小队将绕过障碍" % selected.size())
	return true


func stop_selected() -> void:
	for squad: TacticalSquad in selected_squads():
		squad.stop()
	_order_markers.clear()
	order_feedback.emit("已下达停止命令。")


func focus_selected() -> void:
	var selected: Array[TacticalSquad] = selected_squads()
	if selected.is_empty():
		return
	var center: Vector2 = Vector2.ZERO
	for squad: TacticalSquad in selected:
		center += squad.position
	camera.focus_on(center / float(selected.size()))


func reset_squads() -> void:
	for index: int in range(squads.size()):
		squads[index].stop()
		squads[index].position = STARTS[index]
	_order_markers.clear()
	select_at(STARTS[0])
	camera.zoom = Vector2.ONE * 0.85
	camera.focus_on(Vector2(820, 580))
	order_feedback.emit("部队已返回出发点。")


func hud_blocks_screen(at: Vector2) -> bool:
	return $HUD.blocks_screen(at)


func _set_all_selected(value: bool) -> void:
	for squad: TacticalSquad in squads:
		squad.set_selected(value)


func _process(delta: float) -> void:
	_marker_lifetime = maxf(0.0, _marker_lifetime - delta)
	if _marker_lifetime <= 0.0:
		_order_markers.clear()
	queue_redraw()


func _draw() -> void:
	draw_rect(WORLD_BOUNDS, Color("d8d4bf"))
	# Neutral tabletop geometry communicates obstacles without choosing a final art style.
	for x: int in range(0, 1801, 64):
		draw_line(Vector2(x, 0), Vector2(x, 1200), Color(0.25, 0.32, 0.3, 0.07))
	for y: int in range(0, 1201, 64):
		draw_line(Vector2(0, y), Vector2(1800, y), Color(0.25, 0.32, 0.3, 0.07))
	draw_rect(Rect2(200, 380, 490, 410), Color(0.28, 0.46, 0.44, 0.06))
	draw_rect(Rect2(1090, 360, 420, 310), Color(0.7, 0.51, 0.3, 0.08))
	for obstacle: Rect2 in OBSTACLES:
		draw_rect(Rect2(obstacle.position + Vector2(8, 10), obstacle.size), Color(0.12, 0.2, 0.19, 0.13))
		draw_rect(obstacle, Color("858c7c"))
		draw_rect(obstacle.grow(-7), Color("9ea48e"))
		draw_rect(obstacle, Color("626f65"), false, 2.0)
		for y: int in range(int(obstacle.position.y + 16), int(obstacle.end.y), 20):
			draw_line(Vector2(obstacle.position.x + 10, y), Vector2(obstacle.end.x - 10, y), Color(0.3, 0.38, 0.32, 0.2))
	draw_rect(WORLD_BOUNDS.grow(-2), Color("626f65"), false, 4.0)
	for marker: Vector2 in _order_markers:
		var marker_color: Color = Color("44756b")
		draw_arc(marker, 18, 0, TAU, 32, marker_color, 2.0, true)
		draw_line(marker - Vector2(7, 0), marker + Vector2(7, 0), marker_color, 2.0)
		draw_line(marker - Vector2(0, 7), marker + Vector2(0, 7), marker_color, 2.0)
	if selection_rect.has_area():
		draw_rect(selection_rect, Color(0.18, 0.49, 0.49, 0.14))
		draw_rect(selection_rect, Color("387579"), false, 1.5)
