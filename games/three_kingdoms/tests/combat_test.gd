extends SceneTree
## Combat integration checks run against real physics frames at both supported rates.
## Fixtures keep harmless defenders stationary so damage and navigation failures
## cannot hide behind a different AI decision or an early battle result.

const SQUAD_SCENE: PackedScene = preload("res://features/squads/squad.tscn")
const SHIELD: UnitDefinition = preload("res://data/units/shield_infantry.tres")
const ARCHERS: UnitDefinition = preload("res://data/units/archers.tres")
const FIXTURE_BOUNDS: Rect2 = Rect2(0, 0, 1000, 800)

class CombatFixture extends RefCounted:
	var node: Node2D
	var attacker: TacticalSquad
	var defender: TacticalSquad
	var combat: BattleCombat
	var navigation: BattleNavigation
	var results: Array[int] = []


var _ticks: int = 60
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--ticks="):
			_ticks = maxi(1, int(argument.get_slice("=", 1)))
	Engine.physics_ticks_per_second = _ticks
	_run.call_deferred()


func _run() -> void:
	await _check_casualties_and_cooldown()
	await _check_ranged_rules()
	await _check_wall_and_navigation()
	await _check_guard_visibility()
	await _check_orders_and_death()
	await _check_battle_results()
	await _check_encounter_pause_and_reset()
	print("RESULT: %d/%d tactics combat checks passed at %d Hz" % [
		_checks - _failures, _checks, _ticks])
	quit(1 if _failures else 0)


func _check_casualties_and_cooldown() -> void:
	var fixture: CombatFixture = _fixture(SHIELD, _harmless(), Vector2(250, 350), Vector2(300, 350))
	fixture.defender.set_physics_process(false)
	_check(fixture.attacker.living_members() == 7 and is_equal_approx(fixture.attacker.health, 252.0),
		"Shield squad begins with seven healthy members")
	_check(not fixture.combat.order_attack(fixture.attacker, fixture.attacker),
		"Attack commands reject friendly targets")
	_check(fixture.combat.order_attack(fixture.attacker, fixture.defender), "Enemy attack order is accepted")
	var initial_health: float = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(initial_health - fixture.defender.health, 21.0),
		"One full shield squad deals one seven-member attack")
	fixture.attacker.take_damage(144.0)
	_check(fixture.attacker.living_members() == 3, "Losing four members changes the living formation")
	var after_first_hit: float = fixture.defender.health
	# Repeated target clicks must neither postpone the next attack nor bypass its cooldown.
	for iteration: int in 11:
		fixture.combat.order_attack(fixture.attacker, fixture.defender)
		await _seconds(0.1)
	_check(is_equal_approx(after_first_hit - fixture.defender.health, 9.0),
		"Casualties lower damage and repeated orders preserve the attack interval")
	fixture.attacker.restore()
	_check(fixture.attacker.living_members() == 7 and is_equal_approx(fixture.attacker.health, 252.0),
		"Restore recovers health and all seven members")
	await _dispose(fixture)


func _check_ranged_rules() -> void:
	var fixture: CombatFixture = _fixture(ARCHERS, _harmless(), Vector2(250, 350), Vector2(450, 350))
	fixture.defender.set_physics_process(false)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	var health_before: float = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(health_before - fixture.defender.health, 28.0 * 0.65),
		"Shield protection reduces an archer volley to 65 percent")
	await _dispose(fixture)
	fixture = _fixture(ARCHERS, _harmless(), Vector2(250, 350), Vector2(300, 350))
	fixture.defender.set_physics_process(false)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	health_before = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(health_before - fixture.defender.health, 28.0 * 0.65 * 0.35),
		"Archers lose ranged output when an enemy closes to melee distance")
	await _dispose(fixture)
	fixture = _fixture(ARCHERS, _harmless(), Vector2(250, 350), Vector2(450, 350))
	var nearby_enemy: TacticalSquad = _extra_squad(fixture, _harmless(), 1, Vector2(280, 390))
	var pressured_units: Array[TacticalSquad] = [fixture.attacker, fixture.defender, nearby_enemy]
	fixture.combat.configure(fixture.navigation, [], pressured_units)
	fixture.defender.set_physics_process(false)
	nearby_enemy.set_physics_process(false)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	health_before = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(health_before - fixture.defender.health, 28.0 * 0.65 * 0.35),
		"A nearby enemy suppresses archers even when they target a distant squad")
	await _dispose(fixture)
	fixture = _fixture(ARCHERS, _harmless(), Vector2(250, 350), Vector2(650, 350))
	fixture.attacker.set_physics_process(false)
	fixture.defender.set_physics_process(false)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	health_before = fixture.defender.health
	await _seconds(1.6)
	_check(is_equal_approx(fixture.defender.health, health_before),
		"A target beyond bow range takes no damage before the squad approaches")
	await _dispose(fixture)


func _check_wall_and_navigation() -> void:
	var obstacles: Array[Rect2] = [Rect2(345, 200, 60, 300)]
	var fixture: CombatFixture = _fixture(ARCHERS, _harmless(), Vector2(250, 350), Vector2(450, 350), obstacles)
	fixture.attacker.set_physics_process(false)
	fixture.defender.set_physics_process(false)
	_check(not fixture.combat.has_line_of_sight(Vector2(250, 350), Vector2(450, 350)),
		"The wall blocks line of sight between the squads")
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	var health_before: float = fixture.defender.health
	await _seconds(1.6)
	_check(is_equal_approx(fixture.defender.health, health_before), "Arrows cannot damage a target through a wall")
	await _dispose(fixture)
	fixture = _fixture(SHIELD, _harmless(), Vector2(250, 350), Vector2(500, 350), obstacles)
	fixture.defender.set_physics_process(false)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	health_before = fixture.defender.health
	var stayed_walkable: bool = true
	var hit_within_reach: bool = false
	for frame: int in range(_ticks * 12):
		await physics_frame
		stayed_walkable = stayed_walkable and fixture.navigation.is_walkable(fixture.attacker.position)
		if fixture.defender.health < health_before:
			hit_within_reach = fixture.attacker.position.distance_to(fixture.defender.position) <= SHIELD.attack_range + 1.0 \
				and fixture.combat.has_line_of_sight(fixture.attacker.position, fixture.defender.position)
			break
	_check(stayed_walkable, "Melee pursuit routes around the wall without crossing blocked terrain")
	_check(hit_within_reach, "Melee pursuit reaches a visible target before dealing damage")
	await _dispose(fixture)


func _check_guard_visibility() -> void:
	var obstacles: Array[Rect2] = [Rect2(345, 200, 60, 300)]
	var fixture: CombatFixture = _fixture(SHIELD, _harmless(), Vector2(250, 350), Vector2(450, 350), obstacles)
	var guard_start: Vector2 = fixture.defender.position
	await _seconds(0.6)
	_check(fixture.defender.position.distance_to(guard_start) < 0.1,
		"A guard does not detect and pursue a nearby enemy through the wall")
	fixture.attacker.position = Vector2(450, 600)
	await _seconds(0.4)
	_check(fixture.defender.position.distance_to(guard_start) > 5.0,
		"A guard starts pursuit when the enemy enters unobstructed vision")
	fixture.attacker.position = Vector2(250, 350)
	await _seconds(0.1)
	var lost_sight_at: Vector2 = fixture.defender.position
	await _seconds(0.3)
	_check(fixture.defender.position.distance_to(lost_sight_at) < 0.1,
		"A guard stops following when its target disappears behind the wall")
	await _dispose(fixture)
	fixture = _fixture(SHIELD, _harmless(), Vector2(250, 350), Vector2(450, 350))
	await _seconds(0.2)
	fixture.attacker.position = Vector2(950, 700)
	await _seconds(1.0)
	_check(fixture.defender.position.distance_to(Vector2(450, 350)) < 1.0,
		"A guard returns to its original post when pursuit exceeds its leash")
	await _dispose(fixture)


func _check_orders_and_death() -> void:
	var fixture: CombatFixture = _fixture(SHIELD, _harmless(), Vector2(180, 350), Vector2(850, 100))
	var first: Vector2 = Vector2(280, 350)
	var second: Vector2 = Vector2(280, 450)
	_check(_move(fixture, first), "A movement order is accepted during battle")
	_check(_move(fixture, second, true) and fixture.combat.queue_size(fixture.attacker) == 2,
		"Shift orders append a second destination")
	await _seconds(3.4)
	_check(fixture.attacker.position.distance_to(second) < 1.0 and fixture.combat.queue_size(fixture.attacker) == 0,
		"Queued movement completes in order and drains the queue")
	_move(fixture, first)
	_move(fixture, Vector2(400, 500), true)
	_move(fixture, Vector2(220, 500))
	_check(fixture.combat.queue_size(fixture.attacker) == 1,
		"A normal order replaces the entire previous queue")
	fixture.combat.order_stop(fixture.attacker)
	var stopped_at: Vector2 = fixture.attacker.position
	await _seconds(0.2)
	_check(fixture.combat.queue_size(fixture.attacker) == 0 and fixture.attacker.position.distance_to(stopped_at) < 0.1,
		"Stop clears pending orders and movement")
	_move(fixture, first)
	fixture.attacker.set_selected(true)
	fixture.attacker.take_damage(fixture.attacker.max_health)
	var defender_health: float = fixture.defender.health
	await _seconds(0.2)
	_check(not fixture.attacker.is_alive() and fixture.attacker.living_members() == 0,
		"Lethal damage removes the entire formation")
	_check(not fixture.attacker.is_moving() and fixture.attacker.position.distance_to(stopped_at) < 0.1
		and not fixture.attacker.is_selected(), "Dead squads stop moving and are deselected")
	_check(fixture.combat.queue_size(fixture.attacker) == 0 and is_equal_approx(fixture.defender.health, defender_health),
		"Dead squads lose their orders and cannot deal damage")
	_check(not fixture.combat.order_attack(fixture.attacker, fixture.defender)
		and not fixture.combat.order_attack(fixture.defender, fixture.attacker),
		"Attack commands reject dead attackers and dead targets")
	await _dispose(fixture)
	fixture = _fixture(SHIELD, _harmless(), Vector2(180, 350), Vector2(850, 100))
	var reserve: TacticalSquad = _extra_squad(fixture, _harmless(), 1, Vector2(850, 650))
	var remaining_units: Array[TacticalSquad] = [fixture.attacker, fixture.defender, reserve]
	fixture.combat.configure(fixture.navigation, [], remaining_units)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	_move(fixture, second, true)
	fixture.defender.take_damage(fixture.defender.max_health)
	_check(not fixture.combat.order_attack(fixture.attacker, fixture.defender),
		"Dead targets are rejected while other enemy squads remain alive")
	await _seconds(2.4)
	_check(fixture.attacker.position.distance_to(second) < 1.0 and fixture.combat.queue_size(fixture.attacker) == 0,
		"A queued attack skips its dead target and executes the following move")
	await _dispose(fixture)


func _check_battle_results() -> void:
	var lethal: UnitDefinition = SHIELD.duplicate() as UnitDefinition
	lethal.member_health = 1.0
	lethal.damage_per_member = 100.0
	var harmless: UnitDefinition = lethal.duplicate() as UnitDefinition
	harmless.damage_per_member = 0.0
	var fixture: CombatFixture = _fixture(lethal, harmless, Vector2(250, 350), Vector2(300, 350))
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	await _seconds(0.2)
	_check(fixture.results == [0], "Destroying the enemy produces one player victory")
	await _seconds(0.3)
	_check(fixture.results == [0], "Completed battles do not repeatedly emit a result")
	_check(not _move(fixture, Vector2(500, 350)), "Completed battles reject further combat orders")
	await _dispose(fixture)
	fixture = _fixture(harmless, lethal, Vector2(250, 350), Vector2(300, 350))
	await _seconds(0.2)
	_check(fixture.results == [1], "Losing every friendly squad produces enemy victory")
	await _dispose(fixture)
	fixture = _fixture(lethal, lethal, Vector2(250, 350), Vector2(300, 350))
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	await _seconds(0.2)
	_check(not fixture.attacker.is_alive() and not fixture.defender.is_alive() and fixture.results == [-1],
		"Simultaneous lethal attacks resolve as a draw rather than favoring iteration order")
	await _dispose(fixture)


func _check_encounter_pause_and_reset() -> void:
	var scene: PackedScene = load("res://levels/encounter.tscn") as PackedScene
	_check(scene != null, "The playable combat encounter loads")
	if scene == null:
		return
	var encounter: CommandSandbox = scene.instantiate() as CommandSandbox
	root.add_child(encounter)
	for node_path: String in ["Orders", "Camera"]:
		var automatic: Node = encounter.get_node(node_path)
		automatic.set_process(false)
		automatic.set_physics_process(false)
		automatic.set_process_input(false)
		automatic.set_process_unhandled_input(false)
	await _seconds(0.05)
	_check(encounter.squads.size() == 2 and encounter.enemies.size() == 2,
		"The encounter creates two two-squad armies")
	encounter.toggle_tactical_pause()
	var attacker: TacticalSquad = encounter.squads[0]
	var defender: TacticalSquad = encounter.enemies[0]
	attacker.position = Vector2(700, 900)
	defender.position = Vector2(750, 900)
	encounter.select_index(0)
	var health_before: float = defender.health
	_check(encounter.is_tactical_paused() and encounter.attack_selected(defender),
		"Tactical pause permits selecting units and queuing attack orders")
	await _seconds(0.3)
	_check(is_equal_approx(defender.health, health_before)
		and attacker.position.is_equal_approx(Vector2(700, 900)),
		"Tactical pause freezes movement and damage while accepting orders")
	encounter.toggle_tactical_pause()
	await _seconds(0.2)
	_check(defender.health < health_before, "Resuming executes the attack prepared during tactical pause")
	for enemy: TacticalSquad in encounter.enemies:
		enemy.take_damage(enemy.max_health)
	await _seconds(0.1)
	_check(encounter.battle_finished and encounter.winner == 0 and not encounter.battle_report().is_empty(),
		"The playable encounter publishes a victory and battle report")
	encounter.reset_squads()
	var restored: bool = true
	for squad: TacticalSquad in encounter.squads + encounter.enemies:
		restored = restored and squad.is_alive() and is_equal_approx(squad.health, squad.max_health)
		restored = restored and not squad.is_moving() and encounter.combat.queue_size(squad) == 0
	_check(restored and not encounter.battle_finished and not encounter.is_tactical_paused(),
		"Restart clears battle results, orders, casualties, and tactical pause")
	_check(encounter.selected_squads() == [encounter.squads[0]], "Restart restores the initial friendly selection")
	encounter.toggle_tactical_pause()
	encounter.reset_squads()
	_check(not paused and not encounter.is_tactical_paused(), "Restart from tactical pause restores the live scene tree")
	encounter.queue_free()
	await process_frame


func _fixture(first: UnitDefinition, second: UnitDefinition, first_position: Vector2,
		second_position: Vector2, obstacles: Array[Rect2] = []) -> CombatFixture:
	var fixture: CombatFixture = CombatFixture.new()
	fixture.node = Node2D.new()
	root.add_child(fixture.node)
	fixture.attacker = SQUAD_SCENE.instantiate() as TacticalSquad
	fixture.defender = SQUAD_SCENE.instantiate() as TacticalSquad
	fixture.attacker.position = first_position
	fixture.defender.position = second_position
	fixture.node.add_child(fixture.attacker)
	fixture.node.add_child(fixture.defender)
	fixture.attacker.configure(first, 0)
	fixture.defender.configure(second, 1)
	fixture.navigation = BattleNavigation.new()
	fixture.navigation.setup(FIXTURE_BOUNDS, obstacles, 28.0)
	fixture.combat = BattleCombat.new()
	fixture.node.add_child(fixture.combat)
	var units: Array[TacticalSquad] = [fixture.attacker, fixture.defender]
	fixture.combat.configure(fixture.navigation, obstacles, units)
	fixture.combat.battle_ended.connect(func(winner: int) -> void: fixture.results.append(winner))
	return fixture


func _harmless() -> UnitDefinition:
	var definition: UnitDefinition = SHIELD.duplicate() as UnitDefinition
	definition.member_health = 1000.0
	definition.damage_per_member = 0.0
	return definition


func _extra_squad(fixture: CombatFixture, definition: UnitDefinition, team: int, at: Vector2) -> TacticalSquad:
	var squad: TacticalSquad = SQUAD_SCENE.instantiate() as TacticalSquad
	squad.position = at
	fixture.node.add_child(squad)
	squad.configure(definition, team)
	return squad


func _move(fixture: CombatFixture, at: Vector2, append: bool = false) -> bool:
	return fixture.combat.order_move(fixture.attacker, at,
		fixture.navigation.find_path(fixture.attacker.position, at), append)


func _dispose(fixture: CombatFixture) -> void:
	fixture.node.queue_free()
	await process_frame


func _seconds(duration: float) -> void:
	for frame: int in range(maxi(1, roundi(duration * _ticks))):
		await physics_frame
	await process_frame


func _check(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS: ", description)
	else:
		_failures += 1
		push_error("FAIL: " + description)
