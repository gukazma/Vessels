class_name BattleCombat
extends Node
## Deterministic squad combat. Orders, cooldowns and enemy awareness live here;
## formations only move and present their remaining members.

signal battle_ended(winner: int)

const MAX_ORDERS: int = 16
const ENEMY_SIGHT: float = 420.0
const ENEMY_LEASH: float = 600.0
const REPATH_INTERVAL: float = 0.4
const ARCHER_PRESSURE_RANGE: float = 70.0
const ARCHER_PRESSURE_MULTIPLIER: float = 0.35
const EPSILON: float = 0.0001

enum OrderKind { MOVE, ATTACK }

class BattleOrder:
	extends RefCounted
	var kind: OrderKind
	var destination: Vector2
	var target: TacticalSquad
	var started: bool = false

class SquadState:
	extends RefCounted
	var orders: Array[BattleOrder] = []
	var spawn: Vector2
	var cooldown: float = 0.0
	var repath: float = 0.0
	var target: TacticalSquad
	var returning: bool = false
	var holding: bool = false
	var index: int = 0

var _navigation: BattleNavigation
var _obstacles: Array[Rect2] = []
var _units: Array[TacticalSquad] = []
var _states: Dictionary = {}
var _finished: bool = false
var _contested: bool = false


func configure(navigation: BattleNavigation, obstacles: Array[Rect2], units: Array[TacticalSquad]) -> void:
	_navigation = navigation
	_obstacles.assign(obstacles)
	_units.assign(units)
	_states.clear()
	_finished = false
	var teams: Dictionary = {}
	for index: int in _units.size():
		var squad: TacticalSquad = _units[index]
		if not is_instance_valid(squad):
			continue
		var state: SquadState = SquadState.new()
		state.spawn = squad.global_position
		state.index = index
		_states[squad.get_instance_id()] = state
		teams[squad.team] = true
		squad.stop()
	_contested = teams.has(0) and teams.has(1)


func order_move(squad: TacticalSquad, at: Vector2, path: PackedVector2Array, append: bool = false) -> bool:
	if not _can_order(squad, append) or not at.is_finite() or _navigation == null:
		return false
	for point: Vector2 in path:
		if not point.is_finite():
			return false
	# Recompute from the actual center, including for queued movement when it
	# activates. A caller's preview path may precede combat movement or a pause.
	if _navigation.find_path(squad.global_position, at).is_empty():
		return false
	var order: BattleOrder = BattleOrder.new()
	order.kind = OrderKind.MOVE
	order.destination = at
	_enqueue(squad, order, append)
	return true


func order_attack(squad: TacticalSquad, target: TacticalSquad, append: bool = false) -> bool:
	if not _can_order(squad, append) or not _valid_enemy(squad, target):
		return false
	var state: SquadState = _state(squad)
	if not append and state.orders.size() == 1 and state.orders[0].kind == OrderKind.ATTACK \
			and state.orders[0].target == target:
		return true
	var order: BattleOrder = BattleOrder.new()
	order.kind = OrderKind.ATTACK
	order.target = target
	_enqueue(squad, order, append)
	return true


func order_stop(squad: TacticalSquad) -> void:
	if not is_instance_valid(squad) or not _states.has(squad.get_instance_id()):
		return
	var state: SquadState = _state(squad)
	state.orders.clear()
	state.target = null
	state.returning = false
	state.holding = true
	state.repath = 0.0
	squad.stop()


func order_label(squad: TacticalSquad) -> String:
	if not is_instance_valid(squad) or not squad.is_alive():
		return "已覆灭"
	var state: SquadState = _state(squad)
	if state == null or _finished:
		return "待命"
	if not state.orders.is_empty():
		return "移动" if state.orders[0].kind == OrderKind.MOVE else "进攻"
	if state.returning:
		return "返回驻地"
	return "交战" if _valid_enemy(squad, state.target) else "原地警戒"


func queue_size(squad: TacticalSquad) -> int:
	var state: SquadState = _state(squad)
	return state.orders.size() if state != null else 0


func is_under_pressure(squad: TacticalSquad) -> bool:
	return is_instance_valid(squad) and squad.is_alive() and squad.definition != null \
		and squad.definition.ranged and _nearest_enemy(squad, ARCHER_PRESSURE_RANGE) != null


func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	if not from.is_finite() or not to.is_finite():
		return false
	for obstacle: Rect2 in _obstacles:
		if _segment_hits_rect(from, to, obstacle.abs()):
			return false
	return true


func _physics_process(delta: float) -> void:
	if _finished or _navigation == null:
		return
	var damage: Dictionary = {}
	# Resolve targeting and collect every ready hit before changing any health.
	# Equal attacks can therefore kill both squads in the same simulation tick.
	for squad: TacticalSquad in _units:
		if not is_instance_valid(squad):
			continue
		var state: SquadState = _state(squad)
		if not squad.is_alive():
			state.orders.clear()
			state.target = null
			continue
		state.cooldown = maxf(0.0, state.cooldown - delta)
		state.repath = maxf(0.0, state.repath - delta)
		_update_orders(squad, state)
		if squad.is_moving() or not _valid_enemy(squad, state.target) or squad.definition == null:
			continue
		if not _can_hit(squad, state.target):
			continue
		squad.face_direction(state.target.global_position - squad.global_position)
		if state.cooldown > EPSILON:
			continue
		var amount: float = _attack_damage(squad, state.target)
		var key: int = state.target.get_instance_id()
		damage[key] = float(damage.get(key, 0.0)) + amount
		state.cooldown = maxf(0.05, squad.definition.attack_interval)
		squad.flash_attack(state.target.global_position)
	for squad: TacticalSquad in _units:
		if is_instance_valid(squad) and damage.has(squad.get_instance_id()):
			squad.take_damage(float(damage[squad.get_instance_id()]))
	_check_result()


func _can_order(squad: TacticalSquad, append: bool) -> bool:
	if _finished or not is_instance_valid(squad) or not squad.is_alive():
		return false
	var state: SquadState = _state(squad)
	return state != null and (not append or state.orders.size() < MAX_ORDERS)


func _state(squad: TacticalSquad) -> SquadState:
	if not is_instance_valid(squad):
		return null
	return _states.get(squad.get_instance_id()) as SquadState


func _enqueue(squad: TacticalSquad, order: BattleOrder, append: bool) -> void:
	var state: SquadState = _state(squad)
	if not append:
		state.orders.clear()
		squad.stop()
		state.target = null
		state.repath = 0.0
	state.returning = false
	state.holding = false
	state.orders.append(order)
	if state.orders.size() == 1:
		_update_orders(squad, state)


func _update_orders(squad: TacticalSquad, state: SquadState) -> void:
	# Completing an invalid/dead target also activates its successor this tick.
	while not state.orders.is_empty():
		var order: BattleOrder = state.orders[0]
		if order.kind == OrderKind.MOVE:
			state.target = null
			if not order.started:
				var path: PackedVector2Array = _navigation.find_path(squad.global_position, order.destination)
				order.started = true
				if not path.is_empty():
					squad.issue_move(order.destination, path)
					return
			if squad.is_moving():
				return
			state.orders.pop_front()
			continue
		if not _valid_enemy(squad, order.target):
			state.orders.pop_front()
			state.target = null
			state.repath = 0.0
			squad.stop()
			continue
		state.target = order.target
		_approach_target(squad, state)
		return
	_update_guard(squad, state)


func _update_guard(squad: TacticalSquad, state: SquadState) -> void:
	if squad.team != 1 or state.holding:
		state.target = _nearest_enemy(squad, _attack_range(squad)) if not squad.is_moving() else null
		return
	if state.returning:
		state.target = null
		if squad.global_position.distance_to(state.spawn) <= 1.0:
			state.returning = false
			squad.stop()
		elif not squad.is_moving() and state.repath <= 0.0:
			_return_to_spawn(squad, state)
		return
	if _valid_enemy(squad, state.target):
		if state.spawn.distance_to(state.target.global_position) > ENEMY_LEASH \
				or state.spawn.distance_to(squad.global_position) > ENEMY_LEASH:
			state.returning = true
			state.target = null
			_return_to_spawn(squad, state)
			return
		if not has_line_of_sight(squad.global_position, state.target.global_position):
			state.target = null
			squad.stop()
	else:
		state.target = null
	if state.target == null:
		state.target = _nearest_enemy(squad, ENEMY_SIGHT)
	if state.target != null:
		_approach_target(squad, state)
	elif squad.is_moving():
		squad.stop()


func _return_to_spawn(squad: TacticalSquad, state: SquadState) -> void:
	state.repath = REPATH_INTERVAL
	var path: PackedVector2Array = _navigation.find_path(squad.global_position, state.spawn)
	if path.is_empty():
		squad.stop()
	else:
		squad.issue_move(state.spawn, path)


func _approach_target(squad: TacticalSquad, state: SquadState) -> void:
	if _can_hit(squad, state.target):
		if squad.is_moving():
			squad.stop()
		return
	if state.repath > 0.0:
		return
	state.repath = REPATH_INTERVAL
	var path: PackedVector2Array = _engagement_path(squad, state)
	if path.is_empty():
		squad.stop()
	else:
		squad.issue_move(path[-1], path)


func _engagement_path(squad: TacticalSquad, state: SquadState) -> PackedVector2Array:
	var target_at: Vector2 = state.target.global_position
	var radius: float = maxf(8.0, _attack_range(squad) - 8.0)
	var base_angle: float = (squad.global_position - target_at).angle() + float(state.index % 5) * 0.24
	var best: PackedVector2Array = PackedVector2Array()
	var best_cost: float = INF
	for step: int in 12:
		var candidate: Vector2 = target_at + Vector2.from_angle(base_angle + float(step) * TAU / 12.0) * radius
		if not _navigation.is_walkable(candidate) or not has_line_of_sight(candidate, target_at):
			continue
		var path: PackedVector2Array = _navigation.find_path(squad.global_position, candidate)
		if path.is_empty():
			continue
		var cost: float = 0.0
		for segment: int in range(1, path.size()):
			cost += path[segment - 1].distance_to(path[segment])
		# Keep independent approach slots, including units already holding range.
		for other: TacticalSquad in _units:
			if not is_instance_valid(other) or other == squad or other == state.target or not other.is_alive():
				continue
			var occupied: Vector2 = other.destination() if other.is_moving() else other.global_position
			if candidate.distance_to(occupied) < 42.0:
				cost += 300.0
		if cost < best_cost:
			best = path
			best_cost = cost
	return best


func _nearest_enemy(squad: TacticalSquad, radius: float) -> TacticalSquad:
	var target: TacticalSquad
	var distance: float = radius * radius
	for candidate: TacticalSquad in _units:
		if not _valid_enemy(squad, candidate):
			continue
		var candidate_distance: float = squad.global_position.distance_squared_to(candidate.global_position)
		if candidate_distance <= distance and has_line_of_sight(squad.global_position, candidate.global_position):
			target = candidate
			distance = candidate_distance
	return target


func _valid_enemy(squad: TacticalSquad, target: TacticalSquad) -> bool:
	return is_instance_valid(target) and target.is_alive() and target.team != squad.team \
		and _states.has(target.get_instance_id())


func _attack_range(squad: TacticalSquad) -> float:
	return squad.definition.attack_range if squad.definition != null else 0.0


func _can_hit(squad: TacticalSquad, target: TacticalSquad) -> bool:
	return squad.definition != null \
		and squad.global_position.distance_to(target.global_position) <= _attack_range(squad) + EPSILON \
		and has_line_of_sight(squad.global_position, target.global_position)


func _attack_damage(squad: TacticalSquad, target: TacticalSquad) -> float:
	var damage: float = squad.definition.damage_per_member * squad.living_members()
	if squad.definition.ranged:
		if target.definition != null:
			damage *= target.definition.ranged_damage_multiplier
		if is_under_pressure(squad):
			damage *= ARCHER_PRESSURE_MULTIPLIER
	return damage


func _check_result() -> void:
	if not _contested:
		return
	var survivors: Dictionary = {}
	for squad: TacticalSquad in _units:
		if is_instance_valid(squad) and squad.is_alive():
			survivors[squad.team] = true
	if survivors.has(0) and survivors.has(1):
		return
	_finished = true
	for squad: TacticalSquad in _units:
		if is_instance_valid(squad):
			order_stop(squad)
	var winner: int = 0 if survivors.has(0) else (1 if survivors.has(1) else -1)
	battle_ended.emit(winner)


func _segment_hits_rect(from: Vector2, to: Vector2, obstacle: Rect2) -> bool:
	# Closed slab intersection: even a corner contact blocks a shot.
	var direction: Vector2 = to - from
	var enter: float = 0.0
	var leave: float = 1.0
	for axis: int in 2:
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
