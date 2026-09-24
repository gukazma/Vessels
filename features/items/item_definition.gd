class_name ItemDefinition
extends Resource
## Immutable item design data. Runtime quantities and magazines live in ItemStack.

enum Kind { MATERIAL, WEAPON, CONSUMABLE }
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var kind: Kind = Kind.MATERIAL
@export_range(1, 999) var max_stack: int = 1
@export_category("Weapon")
@export var ammo_id: StringName
@export var magazine_size: int = 0
@export var damage: int = 0
@export var attack_range: float = 0.0
@export var attack_interval: float = 0.4
@export var reload_time: float = 1.0
@export var pellets: int = 1
@export var spread_radians: float = 0.0
@export_category("Weapon presentation")
@export var held_texture: Texture2D
@export var held_grip: Vector2 = Vector2(6, 9)
@export var held_tip: Vector2 = Vector2(20, 6)
@export var held_axial_texture: Texture2D
@export var held_axial_tip: Vector2 = Vector2(18, 9)
@export_category("Consumable")
@export var healing: int = 0
