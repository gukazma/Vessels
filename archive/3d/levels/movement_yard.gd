extends Node3D
## Demo-only recovery; the reusable player has no knowledge of the level.

const FALL_LIMIT: float = -12.0
@onready var _player: SurvivorController = $Player
@onready var _spawn: Marker3D = $Spawn


func _physics_process(_delta: float) -> void:
	if _player.global_position.y < FALL_LIMIT:
		_player.global_position = _spawn.global_position
		_player.velocity = Vector3.ZERO
