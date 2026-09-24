extends Node
## Screen-space dragging stays accurate as the camera pans or zooms.

const DRAG_THRESHOLD: float = 7.0
var _press_screen: Vector2
var _selecting: bool = false
@onready var _battle: CommandSandbox = get_parent() as CommandSandbox


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_press_screen = event.position
				_selecting = true
			elif _selecting:
				finish_selection(event.position, event.shift_pressed)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_battle.right_click_order(_world(event.position), event.shift_pressed)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _selecting:
		_battle.selection_rect = Rect2(_world(_press_screen), _world(event.position) - _world(_press_screen)).abs()
		_battle.queue_redraw()
	elif event.is_action_pressed("stop_order"):
		_battle.stop_selected()
	elif event.is_action_pressed("focus_selection"):
		_battle.focus_selected()
	elif event.is_action_pressed("clear_selection"):
		cancel_selection()
		_battle.clear_selection()
	elif event.is_action_pressed("select_all"):
		_battle.select_in_rect(_battle.WORLD_BOUNDS)
	elif event.is_action_pressed("reset_sandbox"):
		cancel_selection()
		_battle.reset_squads()
	elif event.is_action_pressed("tactical_pause"):
		_battle.toggle_tactical_pause()
	elif event.is_action_pressed("face_order"):
		if get_viewport().get_visible_rect().has_point(_battle.pointer_screen) \
				and not _battle.hud_blocks_screen(_battle.pointer_screen):
			_battle.face_selected(_world(_battle.pointer_screen))
	elif event.is_action_pressed("basic_encounter"):
		cancel_selection()
		_battle.switch_scenario(false)
	elif event.is_action_pressed("cover_encounter"):
		cancel_selection()
		_battle.switch_scenario(true)
	for index: int in range(3):
		if event.is_action_pressed("select_squad_%d" % (index + 1)):
			_battle.select_index(index)


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_battle.pointer_screen = event.position
	# A release over HUD may be consumed before _unhandled_input; cancel that drag.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed and _selecting and _battle.hud_blocks_screen(event.position):
		cancel_selection()


func finish_selection(screen: Vector2, additive: bool) -> void:
	if _press_screen.distance_to(screen) < DRAG_THRESHOLD:
		_battle.select_at(_world(screen), additive)
	else:
		_battle.select_in_rect(Rect2(_world(_press_screen), _world(screen) - _world(_press_screen)).abs(), additive)
	cancel_selection()


func cancel_selection() -> void:
	_selecting = false
	_battle.selection_rect = Rect2()
	_battle.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(_battle):
		cancel_selection()


func _world(screen: Vector2) -> Vector2:
	return _battle.get_canvas_transform().affine_inverse() * screen
