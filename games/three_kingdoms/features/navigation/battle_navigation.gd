class_name BattleNavigation
extends RefCounted
## Routes a squad's center while reserving room for its entire formation.
## Grid cells include their edges in collision checks, so diagonal steps cannot
## shave an obstacle corner even when both cell centers appear unobstructed.

const CELL_SIZE: float = 16.0
const ENDPOINT_SEARCH_RADIUS: int = 2
const MAX_ENDPOINT_CANDIDATES: int = 6
const EPSILON: float = 0.0001

var _grid: AStarGrid2D = AStarGrid2D.new()
var _safe_bounds: Rect2
var _expanded_obstacles: Array[Rect2] = []
var _configured: bool = false


func setup(bounds: Rect2, obstacles: Array[Rect2], clearance: float = 28.0) -> void:
	_configured = false
	_expanded_obstacles.clear()
	var area: Rect2 = bounds.abs()
	var margin: float = maxf(clearance, 0.0)
	_safe_bounds = area.grow(-margin)
	if _safe_bounds.size.x <= 0.0 or _safe_bounds.size.y <= 0.0:
		return
	for obstacle: Rect2 in obstacles:
		_expanded_obstacles.append(obstacle.abs().grow(margin))
	var first: Vector2i = Vector2i(floori(area.position.x / CELL_SIZE), floori(area.position.y / CELL_SIZE))
	var last: Vector2i = Vector2i(ceili(area.end.x / CELL_SIZE), ceili(area.end.y / CELL_SIZE))
	_grid.region = Rect2i(first, last - first)
	_grid.cell_size = Vector2.ONE * CELL_SIZE
	_grid.offset = Vector2.ONE * CELL_SIZE * 0.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.jumping_enabled = false
	_grid.update()
	for y: int in range(first.y, last.y):
		for x: int in range(first.x, last.x):
			var id: Vector2i = Vector2i(x, y)
			var cell: Rect2 = Rect2(Vector2(id) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
			_grid.set_point_solid(id, not _cell_is_clear(cell))
	_configured = true


func is_walkable(point: Vector2) -> bool:
	if not _configured or not point.is_finite():
		return false
	if point.x < _safe_bounds.position.x or point.y < _safe_bounds.position.y:
		return false
	if point.x > _safe_bounds.end.x or point.y > _safe_bounds.end.y:
		return false
	for obstacle: Rect2 in _expanded_obstacles:
		if _contains_closed(obstacle, point):
			return false
	return true


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not is_walkable(from) or not is_walkable(to):
		return PackedVector2Array()
	if from.is_equal_approx(to):
		return PackedVector2Array([from])
	var starts: Array[Vector2i] = _endpoint_candidates(from)
	var ends: Array[Vector2i] = _endpoint_candidates(to)
	for start: Vector2i in starts:
		for end: Vector2i in ends:
			var route: PackedVector2Array = _grid.get_point_path(start, end, false)
			if route.is_empty():
				continue
			var result: PackedVector2Array = PackedVector2Array([from])
			# A single cell needs no trip to its center if the direct step is safe.
			if start != end or not _segment_is_clear(from, to):
				for point: Vector2 in route:
					if not result[-1].is_equal_approx(point):
						result.append(point)
			if not result[-1].is_equal_approx(to):
				result.append(to)
			return result
	return PackedVector2Array()


func _endpoint_candidates(point: Vector2) -> Array[Vector2i]:
	var cell: Vector2i = Vector2i(floori(point.x / CELL_SIZE), floori(point.y / CELL_SIZE))
	var candidates: Array[Vector2i] = []
	for y: int in range(cell.y - ENDPOINT_SEARCH_RADIUS, cell.y + ENDPOINT_SEARCH_RADIUS + 1):
		for x: int in range(cell.x - ENDPOINT_SEARCH_RADIUS, cell.x + ENDPOINT_SEARCH_RADIUS + 1):
			var id: Vector2i = Vector2i(x, y)
			if not _grid.is_in_boundsv(id) or _grid.is_point_solid(id):
				continue
			if _segment_is_clear(point, _grid.get_point_position(id)):
				candidates.append(id)
	# Endpoint connectors are short, collision-checked segments, never a snap
	# to the opposite side of a wall or to a different valid destination.
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return point.distance_squared_to(_grid.get_point_position(a)) < point.distance_squared_to(_grid.get_point_position(b)))
	if candidates.size() > MAX_ENDPOINT_CANDIDATES:
		candidates.resize(MAX_ENDPOINT_CANDIDATES)
	return candidates


func _cell_is_clear(cell: Rect2) -> bool:
	if not _safe_bounds.encloses(cell):
		return false
	for obstacle: Rect2 in _expanded_obstacles:
		if cell.position.x <= obstacle.end.x and cell.end.x >= obstacle.position.x \
			and cell.position.y <= obstacle.end.y and cell.end.y >= obstacle.position.y:
			return false
	return true


func _segment_is_clear(from: Vector2, to: Vector2) -> bool:
	if not is_walkable(from) or not is_walkable(to):
		return false
	for obstacle: Rect2 in _expanded_obstacles:
		if _segment_hits_rect(from, to, obstacle):
			return false
	return true


func _segment_hits_rect(from: Vector2, to: Vector2, obstacle: Rect2) -> bool:
	# Slab intersection rejects every contact, including a single corner.
	var direction: Vector2 = to - from
	var enter: float = 0.0
	var leave: float = 1.0
	for axis: int in range(2):
		if absf(direction[axis]) <= EPSILON:
			if from[axis] < obstacle.position[axis] or from[axis] > obstacle.end[axis]:
				return false
		else:
			var near: float = (obstacle.position[axis] - from[axis]) / direction[axis]
			var far: float = (obstacle.end[axis] - from[axis]) / direction[axis]
			enter = maxf(enter, minf(near, far))
			leave = minf(leave, maxf(near, far))
			if enter > leave:
				return false
	return true


func _contains_closed(rect: Rect2, point: Vector2) -> bool:
	return point.x >= rect.position.x and point.x <= rect.end.x \
		and point.y >= rect.position.y and point.y <= rect.end.y
