extends SceneTree
## Run: godot --headless --path . --script tests/smoke.gd   (plays full games through the real UI code)

func _init() -> void:
	var main: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.words_to_play = 8
	main._start_game()
	await process_frame
	var plays := 0
	while not main.state.is_over() and plays < 500:
		var lane: int = plays % main.state.num_words
		if plays % 3 == 0 and main.state.backup_top() != "":
			main._on_backup_pressed()
		else:
			var src: int = -1
			for i in main.state.num_words:
				if main.state.pool_top(i) != "":
					src = i
					break
			if src < 0:
				main._on_backup_pressed()
			else:
				main._on_pool_pressed(src)
		var ev := InputEventMouseButton.new()
		ev.pressed = true
		ev.button_index = MOUSE_BUTTON_LEFT
		main._on_area_input(ev, lane)
		plays += 1
		await process_frame
	print("plays=%d over=%s score=%d cards_left=%d words=%d" % [plays, main.state.is_over(), main.state.score, main.state.cards_left(), main.state.words_made.size()])
	print("over screen visible: ", main.over_screen.visible)
	quit(0 if main.state.is_over() and main.over_screen.visible else 1)
