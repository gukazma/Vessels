class_name UnitDefinition
extends Resource
## Shared, immutable combat tuning. Health and attack cooldown belong to a squad.

@export var id: StringName = &""
@export var display_name: String = "部队"
@export_range(1.0, 1000.0) var member_health: float = 36.0
@export_range(0.0, 1000.0) var damage_per_member: float = 3.0
@export_range(0.05, 20.0) var attack_interval: float = 1.0
@export_range(1.0, 1000.0) var attack_range: float = 58.0
@export_range(1.0, 400.0) var move_speed: float = 105.0
@export var ranged: bool = false
@export_range(0.0, 2.0) var ranged_damage_multiplier: float = 1.0
