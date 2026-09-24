extends CommandSandbox
## A fixed garrison makes approaching one position from different sides comparable.

const PLAYER_STARTS: Array[Vector2] = [Vector2(570, 510), Vector2(520, 630)]
const GARRISON_STARTS: Array[Vector2] = [Vector2(952, 485), Vector2(952, 600)]


func _setup_terrain() -> void:
	obstacles.assign([Rect2(1150, 260, 240, 56)])
	covers.assign([
		_make_cover(Vector2(900, 420), Vector2(900, 680), Vector2.LEFT),
		_make_cover(Vector2(790, 550), Vector2(790, 710), Vector2.RIGHT),
	])


func allied_start_positions() -> Array[Vector2]:
	return PLAYER_STARTS


func enemy_start_positions() -> Array[Vector2]:
	return GARRISON_STARTS


func _configure_combat() -> void:
	super._configure_combat()
	for squad: TacticalSquad in squads:
		squad.set_facing_immediate(Vector2.RIGHT)
	for enemy: TacticalSquad in enemies:
		enemy.set_facing_immediate(Vector2.LEFT)
		combat.order_stop(enemy)


func _make_cover(from: Vector2, to: Vector2, normal: Vector2) -> TacticalCover:
	var cover: TacticalCover = TacticalCover.new()
	cover.start = from
	cover.end = to
	cover.front_normal = normal
	return cover


func _draw() -> void:
	super._draw()
	for cover: TacticalCover in covers:
		var back: Vector2 = -cover.front_normal.normalized() * cover.depth
		draw_colored_polygon(PackedVector2Array([
			cover.start, cover.end, cover.end + back, cover.start + back,
		]), Color(0.18, 0.48, 0.42, 0.16))
		draw_line(cover.start + back, cover.end + back, Color("719583"), 1.0)
		draw_rect(cover.bounds(), Color("998663"))
		draw_line(cover.start, cover.end, Color("d9c194"), 3.0)
		var center: Vector2 = (cover.start + cover.end) * 0.5
		var front: Vector2 = cover.front_normal.normalized()
		var tip: Vector2 = center + front * 38.0
		var side: Vector2 = Vector2(-front.y, front.x) * 6.0
		draw_line(center + front * 10.0, tip, Color("846f4c"), 2.0)
		draw_line(tip, tip - front * 10.0 + side, Color("846f4c"), 2.0)
		draw_line(tip, tip - front * 10.0 - side, Color("846f4c"), 2.0)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(800, 385), "绕过墙端，尝试侧射", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("5d6655"))
	draw_string(font, Vector2(975, 715), "绿色：掩体保护区", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("436b5e"))
	draw_string(font, Vector2(650, 530), "我军也可进入掩体", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("436b5e"))
	var target: TacticalSquad = hovered_enemy()
	if target != null:
		draw_arc(target.position, 30.0, 0.0, TAU, 32, Color("9e543f"), 2.0)
