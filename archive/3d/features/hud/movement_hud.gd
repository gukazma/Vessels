extends CanvasLayer

@export var player_path: NodePath
@onready var _player: SurvivorController = get_node(player_path) as SurvivorController
@onready var _status: Label = $Margin/Layout/Footer/Telemetry/Status
@onready var _capture_hint: Label = $CaptureHint


func _process(_delta: float) -> void:
	var planar: Vector2 = Vector2(_player.velocity.x, _player.velocity.z)
	var state: String = "GROUNDED" if _player.is_on_floor() else "AIRBORNE"
	_status.text = "%s   /   %04.1f m/s" % [state, planar.length()]
	_capture_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
