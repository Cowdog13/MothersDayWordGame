class_name ScoreChart
extends Control
## Line chart of score per game.

var scores: Array = []
var first_game := 1 ## game number of scores[0]


func show_scores(p_scores: Array, p_first_game := 1) -> void:
	scores = p_scores
	first_game = p_first_game
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var fs := 18
	var ink := Color(1, 1, 1, 0.8)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.25))
	if scores.is_empty():
		draw_string(font, Vector2(20, size.y / 2.0), "Finish a game to see your scores here.",
				HORIZONTAL_ALIGNMENT_LEFT, size.x - 40, fs, ink)
		return

	var plot := Rect2(54, 16, size.x - 54 - 18, size.y - 16 - 36)
	var top_score := 10
	for s in scores:
		top_score = maxi(top_score, int(s))
	var y_max := int(ceil(top_score / 10.0)) * 10

	for step in 5:
		var y := plot.end.y - plot.size.y * step / 4.0
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(1, 1, 1, 0.15), 1.0)
		draw_string(font, Vector2(4, y + 6), str(y_max * step / 4), HORIZONTAL_ALIGNMENT_RIGHT, 44, fs, ink)

	var points := PackedVector2Array()
	for i in scores.size():
		var x := plot.get_center().x if scores.size() == 1 else plot.position.x + plot.size.x * i / float(scores.size() - 1)
		points.append(Vector2(x, plot.end.y - plot.size.y * float(scores[i]) / y_max))
	if points.size() > 1:
		draw_polyline(points, Color(0.55, 0.9, 1.0), 3.0, true)
	var best := 0
	for i in scores.size():
		if scores[i] > scores[best]:
			best = i
	for i in points.size():
		draw_circle(points[i], 7.0 if i == best else 5.0, Color(1.0, 0.8, 0.2) if i == best else Color(0.55, 0.9, 1.0))

	draw_string(font, Vector2(points[0].x - 20, size.y - 8), "#%d" % first_game, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
	if points.size() > 1:
		draw_string(font, Vector2(points[-1].x - 60, size.y - 8), "#%d" % (first_game + scores.size() - 1), HORIZONTAL_ALIGNMENT_RIGHT, 80, fs, ink)
