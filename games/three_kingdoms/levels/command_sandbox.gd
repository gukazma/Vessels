class_name CommandSandbox
extends Node2D
## Scenario setup and player commands; the combat component owns battle rules.

signal selection_changed
signal order_feedback(message: String)
signal battle_state_changed
const SQUAD_SCENE: PackedScene = preload("res://features/squads/squad.tscn")
const WORLD_BOUNDS: Rect2 = Rect2(0, 0, 1800, 1200)
const OBSTACLES: Array[Rect2] = [Rect2(820, 400, 128, 320),
	Rect2(450, 220, 224, 64), Rect2(1150, 750, 256, 64)]
const STARTS: Array[Vector2] = [Vector2(460, 490), Vector2(460, 670), Vector2(650, 560)]
const GROUP_SPACING: float = 92.0
const SHIELD: UnitDefinition = preload("res://data/units/shield_infantry.tres")
const ARCHERS: UnitDefinition = preload("res://data/units/archers.tres")
const ALLIED_STARTS: Array[Vector2] = [Vector2(560, 490), Vector2(460, 570)]
const ENEMY_STARTS: Array[Vector2] = [Vector2(1190, 490), Vector2(1290, 570)]
@export var combat_enabled: bool = false
var squads: Array[TacticalSquad] = []
var enemies: Array[TacticalSquad] = []
var battle_finished: bool = false
var winner: int = -2
var navigation: BattleNavigation = BattleNavigation.new()
var selection_rect: Rect2
var _order_markers: Array[Vector2] = []
var _marker_lifetime: float = 0.0
@onready var camera: BattleCamera = $Camera
@onready var combat: BattleCombat = $Combat


func _ready() -> void:
	navigation.setup(WORLD_BOUNDS, OBSTACLES, 28.0)
	camera.world_bounds = WORLD_BOUNDS
	combat.battle_ended.connect(_on_battle_ended)
	if combat_enabled:
		_spawn_army(squads, ALLIED_STARTS, 0)
		_spawn_army(enemies, ENEMY_STARTS, 1)
		combat.configure(navigation, OBSTACLES, _all_units())
		select_index(0)
		return
	combat.set_physics_process(false)
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


func _spawn_army(army: Array[TacticalSquad], starts: Array[Vector2], team: int) -> void:
	var definitions: Array[UnitDefinition] = [SHIELD, ARCHERS]
	for index: int in range(starts.size()):
		var squad: TacticalSquad = SQUAD_SCENE.instantiate() as TacticalSquad
		squad.position = starts[index]
		squad.squad_name = ("我军·" if team == 0 else "敌军·") + definitions[index].display_name
		squad.accent = Color("477b82") if team == 0 else Color("aa5548")
		$Squads.add_child(squad)
		squad.configure(definitions[index], team)
		army.append(squad)


func _all_units() -> Array[TacticalSquad]:
	var units: Array[TacticalSquad] = squads.duplicate()
	units.append_array(enemies)
	return units


func selected_squads() -> Array[TacticalSquad]:
	var result: Array[TacticalSquad] = []
	for squad: TacticalSquad in squads:
		if squad.is_selected() and squad.is_alive():
			result.append(squad)
	return result


func select_at(at: Vector2, additive: bool = false) -> void:
	var nearest: TacticalSquad
	var distance: float = 36.0
	for squad: TacticalSquad in squads:
		if not squad.is_alive():
			continue
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
		if squad.is_alive() and rect.abs().has_point(squad.position):
			squad.set_selected(true)
	selection_changed.emit()


func select_index(index: int) -> void:
	if index >= 0 and index < squads.size():
		_set_all_selected(false)
		squads[index].set_selected(true)
		selection_changed.emit()


func clear_selection() -> void:
	_set_all_selected(false)
	selection_changed.emit()


func move_selected(at: Vector2, append: bool = false) -> bool:
	if battle_finished:
		return false
	var selected: Array[TacticalSquad] = selected_squads()
	if selected.is_empty():
		order_feedback.emit("先选择一支部队，再下达移动命令。")
		return false
	# Validate the entire order before assigning paths; invalid orders keep existing ones.
	var paths: Array[PackedVector2Array] = []
	var targets: Array[Vector2] = []
	for index: int in range(selected.size()):
		if combat_enabled and append and combat.queue_size(selected[index]) >= 16:
			order_feedback.emit("命令队列已满：每队最多 16 条。")
			return false
		var target: Vector2 = at + Vector2(0, (float(index) - float(selected.size() - 1) / 2.0) * GROUP_SPACING)
		var path: PackedVector2Array = navigation.find_path(selected[index].position, target)
		if path.is_empty():
			order_feedback.emit("目的地空间不足或不可达，请选择开阔地面。")
			return false
		paths.append(path)
		targets.append(target)
	for index: int in range(selected.size()):
		if combat_enabled:
			combat.order_move(selected[index], targets[index], paths[index], append)
		else:
			selected[index].issue_move(targets[index], paths[index])
	_order_markers = targets
	_marker_lifetime = 2.5
	order_feedback.emit(("已追加 %d 队移动命令" if append and combat_enabled else "已下令 %d 队移动") % selected.size())
	return true


func right_click_order(at: Vector2, append: bool = false) -> bool:
	if combat_enabled:
		for enemy: TacticalSquad in enemies:
			if enemy.is_alive() and enemy.position.distance_to(at) <= 36.0:
				return attack_selected(enemy, append)
	return move_selected(at, append)


func attack_selected(target: TacticalSquad, append: bool = false) -> bool:
	if not combat_enabled or battle_finished or not is_instance_valid(target) \
			or target not in enemies or not target.is_alive():
		return false
	var selected: Array[TacticalSquad] = selected_squads()
	if selected.is_empty():
		order_feedback.emit("先选择我军，再右键敌军发起攻击。")
		return false
	for squad: TacticalSquad in selected:
		if append and combat.queue_size(squad) >= 16:
			order_feedback.emit("命令队列已满：每队最多 16 条。")
			return false
	for squad: TacticalSquad in selected:
		combat.order_attack(squad, target, append)
	order_feedback.emit(("已追加攻击：" if append else "集中攻击：") + target.squad_name)
	return true


func stop_selected() -> void:
	if battle_finished:
		return
	for squad: TacticalSquad in selected_squads():
		if combat_enabled:
			combat.order_stop(squad)
		else:
			squad.stop()
	_order_markers.clear()
	order_feedback.emit("已清空命令，原地守卫。" if combat_enabled else "已下达停止命令。")


func toggle_tactical_pause() -> void:
	if not combat_enabled or battle_finished:
		return
	get_tree().paused = not get_tree().paused
	order_feedback.emit("战术暂停：可以选择部队并下令，再按空格执行。" if get_tree().paused else "战斗继续。")
	battle_state_changed.emit()


func is_tactical_paused() -> bool:
	return combat_enabled and get_tree().paused and not battle_finished


func _on_battle_ended(result: int) -> void:
	if battle_finished:
		return
	battle_finished = true
	winner = result
	for unit: TacticalSquad in _all_units():
		unit.stop()
	get_tree().paused = true
	_order_markers.clear()
	battle_state_changed.emit()
	selection_changed.emit()


func battle_report() -> String:
	var allied_alive: int = 0
	var enemy_alive: int = 0
	for squad: TacticalSquad in squads:
		allied_alive += squad.living_members()
	for squad: TacticalSquad in enemies:
		enemy_alive += squad.living_members()
	return "我军存活 %d / %d（伤亡 %d） · 敌军存活 %d / %d（伤亡 %d）" % [
		allied_alive, squads.size() * 7, squads.size() * 7 - allied_alive,
		enemy_alive, enemies.size() * 7, enemies.size() * 7 - enemy_alive]


func focus_selected() -> void:
	var selected: Array[TacticalSquad] = selected_squads()
	if selected.is_empty():
		return
	var center: Vector2 = Vector2.ZERO
	for squad: TacticalSquad in selected:
		center += squad.position
	camera.focus_on(center / float(selected.size()))


func reset_squads() -> void:
	get_tree().paused = false
	battle_finished = false
	winner = -2
	_order_markers.clear()
	if combat_enabled:
		_restore_army(squads, ALLIED_STARTS)
		_restore_army(enemies, ENEMY_STARTS)
		combat.configure(navigation, OBSTACLES, _all_units())
		combat.set_physics_process(true)
		_order_markers.clear()
		select_index(0)
		camera.zoom = Vector2.ONE * 0.85
		camera.focus_on(Vector2(900, 550))
		order_feedback.emit("遭遇战已重开：先观察敌军，再下达命令。")
		battle_state_changed.emit()
		return
	for index: int in range(squads.size()):
		squads[index].stop()
		squads[index].position = STARTS[index]
	_order_markers.clear()
	select_at(STARTS[0])
	camera.zoom = Vector2.ONE * 0.85
	camera.focus_on(Vector2(820, 580))
	order_feedback.emit("部队已返回出发点。")


func _restore_army(army: Array[TacticalSquad], starts: Array[Vector2]) -> void:
	for index: int in range(army.size()):
		army[index].position = starts[index]
		army[index].restore()
		army[index].set_selected(false)


func _exit_tree() -> void:
	# Leaving a completed or tactically paused encounter must not freeze the next scene.
	if combat_enabled:
		get_tree().paused = false


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
