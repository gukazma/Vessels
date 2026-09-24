class_name SurvivorVisual
extends Node3D
## Lightweight placeholder gait on Blender-authored pivots; replace with a rig later.

@onready var _left_arm: Node3D = $Survivor.find_child("ArmLeftPivot", true, false) as Node3D
@onready var _right_arm: Node3D = $Survivor.find_child("ArmRightPivot", true, false) as Node3D
@onready var _left_leg: Node3D = $Survivor.find_child("LegLeftPivot", true, false) as Node3D
@onready var _right_leg: Node3D = $Survivor.find_child("LegRightPivot", true, false) as Node3D
@onready var _model: Node3D = $Survivor
var _phase: float = 0.0
var _stride: float = 0.0


func animate_motion(speed: float, grounded: bool, delta: float) -> void:
	var amount: float = clampf(speed / 7.2, 0.0, 1.0) if grounded else 0.0
	_stride = lerpf(_stride, amount, 1.0 - exp(-12.0 * delta))
	_phase = fmod(_phase + speed * delta * 2.5, TAU)
	var swing: float = sin(_phase) * _stride
	_left_arm.rotation.x = swing * 0.7
	_right_arm.rotation.x = -swing * 0.7
	_left_leg.rotation.x = -swing * 0.65
	_right_leg.rotation.x = swing * 0.65
	_model.position.y = absf(cos(_phase)) * _stride * 0.035
