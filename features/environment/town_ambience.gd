extends Node2D
## A few native-pixel butterflies above flower beds. No gameplay or input effects.

const GARDENS: Array[Vector2] = [Vector2(256, 337), Vector2(704, 336), Vector2(344, 506)]
var _time: float = 0.0


func _process(delta: float) -> void:
	_time = fmod(_time + delta, 120.0)
	queue_redraw()


func _draw() -> void:
	for index: int in range(GARDENS.size()):
		var phase: float = _time * 0.8 + float(index) * 2.1
		var offset: Vector2 = Vector2(sin(phase) * 12.0, cos(phase * 1.7) * 5.0 - 11.0)
		var point: Vector2 = (GARDENS[index] + offset).round()
		var spread: int = 2 if sin(_time * 9.0 + index) > 0.0 else 1
		draw_rect(Rect2(point + Vector2(-spread, 0), Vector2(spread, 2)), Color("fff0b8"))
		draw_rect(Rect2(point + Vector2(1, -1), Vector2(spread, 2)), Color("efb48e"))
		draw_line(point + Vector2(0, -1), point + Vector2(0, 2), Color("688b6c"))
