class_name Leaderboard
extends RefCounted
## Saves finished games to user://leaderboard.json (persists on desktop, mobile and web).

const DEFAULT_PATH := "user://leaderboard.json"
const MAX_GAMES := 500

var path: String
var player_name := "Player"
var games: Array = [] ## oldest first: {name, score, longest, words, time}


func _init(p_path := DEFAULT_PATH) -> void:
	path = p_path
	load_file()


func load_file() -> void:
	games = []
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		player_name = str(data.get("name", player_name))
		for g in data.get("games", []):
			if g is Dictionary and g.has("score"):
				games.append(g)


func save_file() -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not save leaderboard to " + path)
		return
	file.store_string(JSON.stringify({"name": player_name, "games": games}))


func add_game(score: int, longest: String, words: int) -> void:
	games.append({
		"name": player_name, "score": score, "longest": longest,
		"words": words, "time": int(Time.get_unix_time_from_system()),
	})
	if games.size() > MAX_GAMES:
		games = games.slice(games.size() - MAX_GAMES)
	save_file()


func best_score() -> int:
	var best := 0
	for g in games:
		best = maxi(best, int(g.score))
	return best


## Best scores first; ties keep the earlier game first.
func top(count: int) -> Array:
	var sorted := games.duplicate()
	sorted.sort_custom(func(a, b): return a.score > b.score)
	return sorted.slice(0, count)


func scores() -> Array:
	return games.map(func(g): return int(g.score))
