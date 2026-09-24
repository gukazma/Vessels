extends SceneTree
## Exercises paths using independently sampled formation-to-obstacle distances.

const Navigation = preload("res://features/navigation/battle_navigation.gd")
const WORLD: Rect2 = Rect2(0, 0, 1800, 1200)
const CLEARANCE: float = 28.0

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var obstacles: Array[Rect2] = [Rect2(820, 400, 128, 320), Rect2(450, 220, 224, 64), Rect2(1150, 750, 256, 64)]
	var navigation = Navigation.new()
	navigation.setup(WORLD, obstacles, CLEARANCE)
	var from: Vector2 = Vector2(700, 550)
	var target: Vector2 = Vector2(1055, 553)
	var route: PackedVector2Array = navigation.find_path(from, target)
	_check(not route.is_empty(), "A squad can route around the central wall")
	_check(_has_endpoints(route, from, target), "Paths retain both the exact start and the exact click")
	_check(_route_is_safe(route, WORLD, obstacles, CLEARANCE), "Every point of the wall detour reserves formation clearance")
	_check(_has_detour(route, 372.0, 748.0), "Cross-wall commands produce a real detour")
	_check(navigation.find_path(from, Vector2(870, 550)).is_empty(), "An occupied target is rejected")
	_check(navigation.find_path(from, Vector2(1801, 550)).is_empty(), "An out-of-map target is rejected without snapping")
	_check(navigation.find_path(Vector2(870, 550), target).is_empty(), "A starting formation inside a wall is rejected")
	_check(navigation.find_path(Vector2(-1, 550), target).is_empty(), "An out-of-map start is rejected")
	_check(navigation.find_path(from, Vector2(805, 550)).is_empty(), "Targets inside the formation clearance margin are rejected")
	_check(not navigation.is_walkable(Vector2(27, 100)), "Formation centers cannot occupy the map-edge margin")
	_check(navigation.is_walkable(Vector2(28, 100)), "The exact map clearance boundary is valid")
	_check(not navigation.is_walkable(Vector2(1773, 100)), "Right map edge reserves the same clearance")
	_check(not navigation.is_walkable(Vector2(100, 1173)), "Bottom map edge reserves the same clearance")
	var boundary_route: PackedVector2Array = navigation.find_path(Vector2(28, 100), Vector2(1772, 1172))
	_check(_has_endpoints(boundary_route, Vector2(28, 100), Vector2(1772, 1172)), "Valid map-edge clicks connect safely to the grid")
	_check(_route_is_safe(boundary_route, WORLD, obstacles, CLEARANCE), "Endpoint connectors preserve clearance at map edges")
	var nearby: PackedVector2Array = navigation.find_path(Vector2(201, 202), Vector2(206, 207))
	_check(_has_endpoints(nearby, Vector2(201, 202), Vector2(206, 207)), "Nearby clicks preserve their precise destination")
	_check(_route_is_safe(nearby, WORLD, obstacles, CLEARANCE), "Nearby movement is collision safe")
	_check(navigation.find_path(from, from) == PackedVector2Array([from]), "Commands to the current position are stable")

	_test_disconnected_regions()
	_test_corridors()
	_test_corner_contacts()
	_test_reconfiguration()
	print("Navigation: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _test_disconnected_regions() -> void:
	var navigation = Navigation.new()
	var area: Rect2 = Rect2(0, 0, 640, 480)
	var obstacles: Array[Rect2] = [Rect2(300, 0, 40, 480)]
	navigation.setup(area, obstacles, CLEARANCE)
	_check(navigation.is_walkable(Vector2(460, 240)), "A target can be individually walkable but unreachable")
	_check(navigation.find_path(Vector2(160, 240), Vector2(460, 240)).is_empty(), "A separating wall cannot be crossed or snapped through")
	_check(navigation.find_path(Vector2(265, 240), Vector2(375, 240)).is_empty(), "Endpoint connectors cannot bridge opposite wall faces")


func _test_corridors() -> void:
	var navigation = Navigation.new()
	var area: Rect2 = Rect2(0, 0, 640, 480)
	var narrow: Array[Rect2] = [Rect2(280, 0, 64, 220), Rect2(280, 260, 64, 220)]
	navigation.setup(area, narrow, CLEARANCE)
	_check(navigation.find_path(Vector2(140, 240), Vector2(500, 240)).is_empty(), "A 40-pixel gap cannot admit a 56-pixel formation")
	var wide: Array[Rect2] = [Rect2(280, 0, 64, 160), Rect2(280, 288, 64, 192)]
	navigation.setup(area, wide, CLEARANCE)
	var route: PackedVector2Array = navigation.find_path(Vector2(140, 240), Vector2(500, 240))
	_check(not route.is_empty(), "A sufficiently wide passage remains traversable")
	_check(_route_is_safe(route, area, wide, CLEARANCE), "Passage traversal reserves clearance on both sides")


func _test_corner_contacts() -> void:
	var navigation = Navigation.new()
	var area: Rect2 = Rect2(0, 0, 640, 512)
	var obstacles: Array[Rect2] = [Rect2(260, 120, 64, 112), Rect2(120, 300, 144, 48)]
	navigation.setup(area, obstacles, CLEARANCE)
	var route: PackedVector2Array = navigation.find_path(Vector2(180, 180), Vector2(400, 370))
	_check(not route.is_empty(), "A route remains available around staggered corners")
	_check(_route_is_safe(route, area, obstacles, CLEARANCE), "Diagonal movement never cuts through the expanded obstacle corners")
	var touching: Array[Rect2] = [Rect2(0, 192, 192, 192), Rect2(192, 0, 192, 192)]
	navigation.setup(area, touching, 0.0)
	_check(navigation.find_path(Vector2(100, 100), Vector2(280, 280)).is_empty(), "Even zero-clearance routing cannot cross a single shared corner")
	var offset_bounds: Rect2 = Rect2(-97, -65, 500, 430)
	var offset_obstacles: Array[Rect2] = [Rect2(90, 40, 55, 180)]
	navigation.setup(offset_bounds, offset_obstacles, CLEARANCE)
	var offset_route: PackedVector2Array = navigation.find_path(Vector2(-55, -20), Vector2(345, 310))
	_check(not offset_route.is_empty(), "Non-grid-aligned and negative map origins are supported")
	_check(_route_is_safe(offset_route, offset_bounds, offset_obstacles, CLEARANCE), "Offset maps preserve world-space clearance")


func _test_reconfiguration() -> void:
	var navigation = Navigation.new()
	_check(navigation.find_path(Vector2.ZERO, Vector2.ONE).is_empty(), "An unconfigured navigator fails safely")
	var obstacle: Array[Rect2] = [Rect2(150, 0, 80, 384)]
	navigation.setup(Rect2(0, 0, 384, 384), obstacle, CLEARANCE)
	navigation.setup(Rect2(0, 0, 384, 384), [], CLEARANCE)
	_check(not navigation.find_path(Vector2(80, 200), Vector2(290, 200)).is_empty(), "A new setup clears obsolete obstacles and solid cells")
	navigation.setup(Rect2(0, 0, 40, 40), [], CLEARANCE)
	_check(navigation.find_path(Vector2(10, 10), Vector2(30, 30)).is_empty(), "Maps smaller than formation clearance fail safely")


func _has_endpoints(route: PackedVector2Array, from: Vector2, target: Vector2) -> bool:
	return not route.is_empty() and route[0].is_equal_approx(from) and route[-1].is_equal_approx(target)


func _has_detour(route: PackedVector2Array, minimum_y: float, maximum_y: float) -> bool:
	for point: Vector2 in route:
		if point.y < minimum_y or point.y > maximum_y:
			return true
	return false


func _route_is_safe(route: PackedVector2Array, bounds: Rect2, obstacles: Array[Rect2], clearance: float) -> bool:
	if route.is_empty():
		return false
	for index: int in range(maxi(route.size() - 1, 1)):
		var from: Vector2 = route[index]
		var target: Vector2 = route[mini(index + 1, route.size() - 1)]
		var steps: int = maxi(ceili(from.distance_to(target) / 0.5), 1)
		for sample: int in range(steps + 1):
			var point: Vector2 = from.lerp(target, float(sample) / float(steps))
			if point.x < bounds.position.x + clearance - 0.001 or point.x > bounds.end.x - clearance + 0.001 \
				or point.y < bounds.position.y + clearance - 0.001 or point.y > bounds.end.y - clearance + 0.001:
				return false
			for obstacle: Rect2 in obstacles:
				var closest: Vector2 = Vector2(clampf(point.x, obstacle.position.x, obstacle.end.x), clampf(point.y, obstacle.position.y, obstacle.end.y))
				if point.distance_to(closest) < clearance - 0.001:
					return false
				if obstacle.has_point(point):
					return false
	return true


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)
