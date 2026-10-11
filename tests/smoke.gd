extends SceneTree
## Run: godot --headless --path . --script tests/smoke.gd
## Plays random moves through the real UI handlers, gives up, and checks the leaderboard saved.

func _init() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Leaderboard.DEFAULT_PATH))
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main._start_game()
	await process_frame
	var plays := 0
	while main.state.cards_left() > 0 and plays < 1000:
		var lane := -1
		for i in 3:
			if main.state.pool_top(i) != "":
				lane = i
				break
		if main.state.backup.size() > 0 and (plays % 2 == 0 or lane < 0):
			main._on_backup_pressed(0)
		else:
			main._on_pool_pressed(lane)
		main._on_slot_pressed(plays % 3, plays % 2 == 0)
		plays += 1
		await process_frame
	var score: int = main.state.score
	main._finish()
	print("plays=%d cards_left=%d score=%d games_saved=%d" % [plays, main.state.cards_left(), score, main.board.games.size()])
	main._show_board()
	await process_frame
	var reloaded := Leaderboard.new()
	var ok: bool = main.state.cards_left() == 0 and reloaded.games.size() == 1 and reloaded.games[0].score == score
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Leaderboard.DEFAULT_PATH))
	print("OK" if ok else "FAILED")
	quit(0 if ok else 1)
