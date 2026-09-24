class_name TacticalCover
extends Resource
## A low barricade: navigation uses its physical bounds, while only shots from
## the front across the finite segment protect the strip immediately behind it.

const EPSILON: float = 0.0001

@export var start: Vector2 = Vector2.ZERO
@export var end: Vector2 = Vector2(120.0, 0.0)
@export var front_normal: Vector2 = Vector2.UP
@export_range(1.0, 400.0) var depth: float = 72.0
@export_range(1.0, 100.0) var thickness: float = 12.0
@export_range(0.0, 1.0) var ranged_multiplier: float = 0.5


func bounds() -> Rect2:
	return Rect2(start, end - start).abs().grow(maxf(0.0, thickness) * 0.5)


func contains(at: Vector2) -> bool:
	if not at.is_finite() or start.is_equal_approx(end):
		return false
	var along: Vector2 = (end - start).normalized()
	var projection: float = (at - start).dot(along)
	var distance: float = (at - start).dot(_normal())
	return projection >= -EPSILON and projection <= start.distance_to(end) + EPSILON \
		and distance <= EPSILON and distance >= -maxf(0.0, depth) - EPSILON


func protects(source: Vector2, target: Vector2) -> bool:
	if not source.is_finite() or not contains(target):
		return false
	var normal: Vector2 = _normal()
	var source_distance: float = (source - start).dot(normal)
	var target_distance: float = (target - start).dot(normal)
	if source_distance <= EPSILON or target_distance >= -EPSILON:
		return false
	var fraction: float = source_distance / (source_distance - target_distance)
	var intersection: Vector2 = source.lerp(target, fraction)
	var projection: float = (intersection - start).dot((end - start).normalized())
	return projection >= -EPSILON and projection <= start.distance_to(end) + EPSILON


func _normal() -> Vector2:
	# Authoring selects which side is front; always use a true perpendicular so
	# a slightly imprecise normal cannot skew the protected strip or ray test.
	var tangent: Vector2 = (end - start).normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	return -normal if normal.dot(front_normal) < 0.0 else normal
