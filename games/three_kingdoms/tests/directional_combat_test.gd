extends SceneTree
## M2 rules use real squad turning and physics ticks. The existing M1 suite
## separately protects the default, nondirectional combat contract.

const SQUAD_SCENE: PackedScene = preload("res://features/squads/squad.tscn")
const SHIELD: UnitDefinition = preload("res://data/units/shield_infantry.tres")
const ARCHERS: UnitDefinition = preload("res://data/units/archers.tres")
const BOUNDS: Rect2 = Rect2(0, 0, 1000, 800)

class Fixture extends RefCounted:
	var node: Node2D
	var attacker: TacticalSquad
	var defender: TacticalSquad
	var combat: BattleCombat
	var navigation: BattleNavigation
	var covers: Array[TacticalCover] = []


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
	_check_cover_geometry()
	await _check_shield_directions()
	await _check_cover_damage()
	await _check_pressure_across_cover()
	await _check_low_wall_melee()
	await _check_turn_before_attack()
	await _check_face_orders_and_cooldown()
	await _check_face_lock_release()
	await _check_pause_and_reconfigure()
	print("RESULT: %d/%d directional combat checks passed at %d Hz" % [
		_checks - _failures, _checks, _ticks])
	quit(1 if _failures else 0)


func _check_cover_geometry() -> void:
	var cover: TacticalCover = _cover()
	_check(cover.contains(Vector2(450, 350)) and not cover.contains(Vector2(350, 350)),
		"Cover protects the rear band rather than the attacker's side")
	_check(not cover.contains(Vector2(490, 350)) and not cover.contains(Vector2(450, 480)),
		"Cover depth and finite endpoints limit the protected band")
	_check(cover.protects(Vector2(250, 350), Vector2(450, 350)),
		"A frontal shot crossing the actual wall segment receives protection")
	_check(not cover.protects(Vector2(350, 180), Vector2(450, 280)),
		"A shot around the finite wall endpoint receives no protection")
	_check(not cover.protects(Vector2(550, 350), Vector2(450, 350)),
		"A shot from behind the protected band receives no wall protection")
	_check(cover.bounds().has_point(cover.start) and cover.bounds().has_point(cover.end),
		"Navigation bounds include both low-wall endpoints")


func _check_shield_directions() -> void:
	var front_damage: float = await _one_volley(Vector2.LEFT)
	var back_damage: float = await _one_volley(Vector2.RIGHT)
	var side_damage: float = await _one_volley(Vector2.UP)
	_check(is_equal_approx(front_damage, 28.0 * 0.65), "A frontal arrow volley meets the shield's directional protection")
	_check(is_equal_approx(back_damage, 28.0), "The same volley at the same range deals full damage from behind")
	_check(is_equal_approx(side_damage, 28.0), "A side volley outside the frontal 120 degrees deals full damage")
	var fixture: Fixture = _fixture(ARCHERS, Vector2(250, 350), Vector2(450, 350))
	fixture.defender.set_facing_immediate(Vector2.LEFT.rotated(deg_to_rad(59.0)))
	var preview: Dictionary = fixture.combat.attack_preview(fixture.attacker, fixture.defender)
	_check(bool(preview["shielded"]), "A shot just inside the frontal shield arc remains protected")
	fixture.defender.set_facing_immediate(Vector2.LEFT.rotated(deg_to_rad(61.0)))
	preview = fixture.combat.attack_preview(fixture.attacker, fixture.defender)
	_check(not bool(preview["shielded"]) and bool(preview["flanked"]),
		"Crossing the shield arc boundary marks the target as flanked")
	await _dispose(fixture)


func _one_volley(defender_facing: Vector2) -> float:
	var fixture: Fixture = _fixture(ARCHERS, Vector2(250, 350), Vector2(450, 350))
	fixture.defender.set_facing_immediate(defender_facing)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	var before: float = fixture.defender.health
	await _seconds(0.1)
	var damage: float = before - fixture.defender.health
	await _dispose(fixture)
	return damage


func _check_cover_damage() -> void:
	var fixture: Fixture = _fixture(ARCHERS, Vector2(250, 350), Vector2(450, 350), [_cover()])
	var preview: Dictionary = fixture.combat.attack_preview(fixture.attacker, fixture.defender)
	_check(bool(preview["shielded"]) and bool(preview["covered"])
		and not bool(preview["blocked"]) and bool(preview["in_range"]),
		"Preview distinguishes a protected ranged target from blocked line of sight")
	_check(is_equal_approx(float(preview["damage"]), 14.0),
		"Shield and wall choose the stronger reduction instead of multiplying together")
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	var before: float = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(before - fixture.defender.health, 14.0),
		"The real protected volley matches its damage preview")
	await _dispose(fixture)
	fixture = _fixture(ARCHERS, Vector2(350, 180), Vector2(450, 280), [_cover()])
	fixture.defender.set_facing_immediate(Vector2.RIGHT)
	fixture.attacker.set_facing_immediate(Vector2(1, 1))
	preview = fixture.combat.attack_preview(fixture.attacker, fixture.defender)
	_check(not bool(preview["covered"]) and not bool(preview["blocked"]),
		"A finite-endpoint side shot stays unprotected in the combat preview")
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	before = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(before - fixture.defender.health, 28.0),
		"Shooting around the wall end deals full damage to an exposed shield side")
	await _dispose(fixture)
	fixture = _fixture(ARCHERS, Vector2(350, 350), Vector2(490, 350), [_cover()])
	fixture.defender.set_facing_immediate(Vector2.RIGHT)
	_check(fixture.combat.cover_at(fixture.defender) == null,
		"Standing beyond wall depth does not grant cover")
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	before = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(before - fixture.defender.health, 28.0),
		"An uncovered target behind a distant wall takes full arrow damage")
	await _dispose(fixture)
	fixture = _fixture(SHIELD, Vector2(450, 300), Vector2(450, 350), [_cover()])
	fixture.attacker.set_facing_immediate(Vector2.DOWN)
	fixture.defender.set_facing_immediate(Vector2.UP)
	_check(fixture.combat.cover_at(fixture.defender) != null, "The melee target still stands inside a cover band")
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	before = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(before - fixture.defender.health, 21.0),
		"Melee from the same side of a wall ignores both ranged defenses")
	await _dispose(fixture)


func _check_pressure_across_cover() -> void:
	var fixture: Fixture = _fixture(ARCHERS, Vector2(365.5, 350), Vector2(434.5, 350), [_cover()])
	var preview: Dictionary = fixture.combat.attack_preview(fixture.attacker, fixture.defender)
	_check(not bool(preview["under_pressure"]),
		"A low wall prevents a nearby enemy on the opposite side from suppressing archers")
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	var before: float = fixture.defender.health
	await _seconds(0.1)
	_check(is_equal_approx(before - fixture.defender.health, 14.0),
		"Archers behind a separating low wall keep normal firing output against cover")
	await _dispose(fixture)
	fixture = _fixture(ARCHERS, Vector2(450, 300), Vector2(450, 350), [_cover()])
	fixture.attacker.set_facing_immediate(Vector2.DOWN)
	fixture.defender.set_facing_immediate(Vector2.UP)
	preview = fixture.combat.attack_preview(fixture.attacker, fixture.defender)
	_check(bool(preview["under_pressure"]) and is_equal_approx(float(preview["damage"]), 28.0 * 0.65 * 0.35),
		"A nearby enemy on the same side still suppresses archers after directional protection")
	await _dispose(fixture)


func _check_low_wall_melee() -> void:
	var long_reach: UnitDefinition = SHIELD.duplicate() as UnitDefinition
	long_reach.attack_range = 80.0
	var fixture: Fixture = _fixture(long_reach, Vector2(360, 350), Vector2(440, 350), [_cover()])
	var preview: Dictionary = fixture.combat.attack_preview(fixture.attacker, fixture.defender)
	_check(bool(preview["in_range"]) and bool(preview["blocked"]),
		"A low wall blocks melee even when a target is inside nominal attack range")
	fixture.attacker.set_physics_process(false)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	var before: float = fixture.defender.health
	await _seconds(0.2)
	_check(is_equal_approx(fixture.defender.health, before), "A stationary melee squad cannot strike through a low wall")
	fixture.attacker.set_physics_process(true)
	var walkable: bool = true
	var reached: bool = false
	for frame: int in range(_ticks * 12):
		await physics_frame
		walkable = walkable and fixture.navigation.is_walkable(fixture.attacker.position)
		if fixture.defender.health < before:
			reached = not bool(fixture.combat.attack_preview(fixture.attacker, fixture.defender)["blocked"])
			break
	_check(walkable and reached, "Melee routes around a low-wall endpoint before making contact")
	await _dispose(fixture)


func _check_turn_before_attack() -> void:
	var fixture: Fixture = _fixture(ARCHERS, Vector2(250, 350), Vector2(450, 350))
	fixture.attacker.set_facing_immediate(Vector2.LEFT)
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	var before: float = fixture.defender.health
	await _seconds(0.2)
	var turned: float = absf(Vector2.LEFT.angle_to(fixture.attacker.facing_direction()))
	_check(turned > 0.45 and turned < 0.8 and is_equal_approx(fixture.defender.health, before),
		"A new attack turns gradually at about 180 degrees per second without firing backward")
	var reached: bool = false
	var elapsed: float = 0.2
	for frame: int in range(_ticks * 2):
		await physics_frame
		elapsed = 0.2 + float(frame + 1) / float(_ticks)
		if fixture.defender.health < before:
			reached = fixture.attacker.facing_direction().dot(Vector2.RIGHT) >= cos(PI / 6.0) - 0.001
			break
	_check(reached and elapsed >= 0.78 and elapsed < 1.05,
		"The first shot waits until the real formation faces within 30 degrees of its target")
	await _dispose(fixture)


func _check_face_orders_and_cooldown() -> void:
	var fixture: Fixture = _fixture(ARCHERS, Vector2(250, 350), Vector2(450, 350))
	fixture.combat.order_attack(fixture.attacker, fixture.defender)
	await _seconds(0.1)
	var after_first_hit: float = fixture.defender.health
	_move(fixture, Vector2(250, 500))
	fixture.combat.order_attack(fixture.attacker, fixture.defender, true)
	_check(not fixture.combat.order_face(fixture.attacker, Vector2.ZERO)
		and fixture.combat.queue_size(fixture.attacker) == 2,
		"An invalid facing direction leaves existing orders intact")
	_check(fixture.combat.order_face(fixture.attacker, Vector2.RIGHT)
		and fixture.combat.queue_size(fixture.attacker) == 0 and not fixture.attacker.is_moving(),
		"A valid face order replaces queued movement and attacks with directional guard")
	for iteration: int in 11:
		fixture.combat.order_face(fixture.attacker, Vector2.RIGHT)
		await _seconds(0.1)
	_check(is_equal_approx(fixture.defender.health, after_first_hit),
		"Repeated face orders cannot bypass the archer's current attack cooldown")
	await _seconds(0.35)
	_check(is_equal_approx(after_first_hit - fixture.defender.health, 18.2),
		"Repeated face orders also cannot indefinitely postpone the next guard volley")
	await _dispose(fixture)


func _check_face_lock_release() -> void:
	for command: String in ["attack", "stop", "move"]:
		var fixture: Fixture = _fixture(ARCHERS, Vector2(250, 350), Vector2(450, 350))
		fixture.attacker.set_facing_immediate(Vector2.LEFT)
		fixture.combat.order_face(fixture.attacker, Vector2.LEFT)
		var before: float = fixture.defender.health
		await _seconds(0.25)
		_check(fixture.attacker.facing_direction().is_equal_approx(Vector2.LEFT)
			and is_equal_approx(fixture.defender.health, before),
			"Directional guard ignores enemies behind its command facing before %s" % command)
		match command:
			"attack": fixture.combat.order_attack(fixture.attacker, fixture.defender)
			"stop": fixture.combat.order_stop(fixture.attacker)
			"move": _move(fixture, Vector2(250, 400))
		await _seconds(1.4)
		_check(fixture.defender.health < before, "An explicit %s order releases the directional guard lock" % command)
		await _dispose(fixture)


func _check_pause_and_reconfigure() -> void:
	var fixture: Fixture = _fixture(ARCHERS, Vector2(250, 350), Vector2(450, 350))
	fixture.attacker.set_facing_immediate(Vector2.LEFT)
	paused = true
	fixture.combat.order_face(fixture.attacker, Vector2.RIGHT)
	await _seconds(0.4)
	_check(fixture.attacker.facing_direction().is_equal_approx(Vector2.LEFT),
		"Issuing a face command during tactical pause does not rotate the actual formation")
	paused = false
	await _seconds(0.2)
	_check(not fixture.attacker.facing_direction().is_equal_approx(Vector2.LEFT),
		"The pending face order starts rotating only after simulation resumes")
	fixture.attacker.set_facing_immediate(Vector2.LEFT)
	fixture.combat.order_face(fixture.attacker, Vector2.LEFT)
	var units: Array[TacticalSquad] = [fixture.attacker, fixture.defender]
	fixture.combat.configure(fixture.navigation, [], units)
	fixture.combat.order_stop(fixture.defender)
	var before: float = fixture.defender.health
	await _seconds(1.1)
	_check(fixture.defender.health < before, "Reconfiguring a battle clears stale directional guard locks")
	await _dispose(fixture)


func _fixture(definition: UnitDefinition, from: Vector2, to: Vector2,
		covers: Array[TacticalCover] = []) -> Fixture:
	var fixture: Fixture = Fixture.new()
	fixture.node = Node2D.new()
	fixture.node.process_mode = Node.PROCESS_MODE_PAUSABLE
	root.add_child(fixture.node)
	fixture.attacker = SQUAD_SCENE.instantiate() as TacticalSquad
	fixture.defender = SQUAD_SCENE.instantiate() as TacticalSquad
	fixture.attacker.position = from
	fixture.defender.position = to
	fixture.node.add_child(fixture.attacker)
	fixture.node.add_child(fixture.defender)
	fixture.attacker.configure(definition, 0)
	var harmless: UnitDefinition = SHIELD.duplicate() as UnitDefinition
	harmless.member_health = 1000.0
	harmless.damage_per_member = 0.0
	fixture.defender.configure(harmless, 1)
	fixture.attacker.set_facing_immediate(Vector2.RIGHT)
	fixture.defender.set_facing_immediate(Vector2.LEFT)
	fixture.defender.set_physics_process(false)
	fixture.covers.assign(covers)
	var walls: Array[Rect2] = []
	for cover: TacticalCover in covers:
		walls.append(cover.bounds())
	fixture.navigation = BattleNavigation.new()
	fixture.navigation.setup(BOUNDS, walls, 28.0)
	fixture.combat = BattleCombat.new()
	fixture.combat.directional_defense_enabled = true
	fixture.node.add_child(fixture.combat)
	var units: Array[TacticalSquad] = [fixture.attacker, fixture.defender]
	fixture.combat.configure(fixture.navigation, [], units, covers)
	fixture.combat.order_stop(fixture.defender)
	return fixture


func _cover() -> TacticalCover:
	var cover: TacticalCover = TacticalCover.new()
	cover.start = Vector2(400, 260)
	cover.end = Vector2(400, 440)
	cover.front_normal = Vector2.LEFT
	cover.depth = 72.0
	cover.thickness = 12.0
	cover.ranged_multiplier = 0.5
	return cover


func _move(fixture: Fixture, to: Vector2) -> bool:
	return fixture.combat.order_move(fixture.attacker, to,
		fixture.navigation.find_path(fixture.attacker.position, to))


func _dispose(fixture: Fixture) -> void:
	paused = false
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
