extends SceneTree
## Run: godot --headless --path . --script tests/test_logic.gd

var failures := 0


func check(cond: bool, label: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + label)
	if not cond:
		failures += 1


## Builds a deck whose deal is known. `pool_tops` = [lane0 top, lane0 next, ...] given as arrays
## ordered top-first; `backup` is the backup pile in order.
func rigged(starts: Array, pools: Array, backup: Array) -> Array:
	var pop_order: Array = []
	pop_order.append_array(starts)
	for pool in pools:
		var filled: Array = pool.duplicate()
		filled.reverse() # popped bottom-first, so the top card is popped last
		while filled.size() < GameState.POOL_SIZE:
			filled.push_front("Z") # bottom of the stack
		pop_order.append_array(filled)
	var b: Array = backup.duplicate()
	while b.size() < GameState.BACKUP_SIZE:
		b.append("Q")
	pop_order.append_array(b)
	pop_order.reverse()
	return pop_order


func _init() -> void:
	check(GameState.load_dictionary(), "dictionary loads")
	check(GameState.is_word("cat") and GameState.is_word("CATS"), "cat / CATS are words")
	check(not GameState.is_word("ca") and not GameState.is_word("a"), "ca / single letters are not words")

	var total := 0
	for n in GameState.CARD_COUNTS.values():
		total += n
	check(total == 117, "deck has 117 cards (got %d)" % total)

	var g := GameState.new()
	g.new_game()
	check(g.scoring.size() == 3 and g.pools.size() == 3, "3 words + 3 pools")
	check(g.pools[0].size() == 10 and g.backup.size() == 15, "pool 10, backup 15")
	check(g.cards_left() == 45, "cards_left = 45")

	# Rigged game: words start C, T, E.
	# Pool 0 (top first): A, T.  Backup: [S, A, C, TH, ...]
	var r := GameState.new()
	r.new_game(rigged(["C", "T", "E"], [["A", "T"], [], []], ["S", "A", "C", "TH"]))
	check(r.scoring[0] == ["C"] and r.pool_top(0) == "A" and r.backup[0] == "S", "rigged setup")

	var p1 := r.play(false, 0, 0, false)
	check(not p1.valid and p1.points == 0 and r.score == 0, "C + A at end = CA, no points")
	check(r.pool_top(0) == "T" and r.pools[0].size() == 9, "pool reveals the next card")
	var p2 := r.play(false, 0, 0, false)
	check(p2.valid and p2.word == "CAT" and p2.points == 3, "CAT scores 3")
	var p3 := r.play(true, 0, 0, false)
	check(p3.valid and p3.word == "CATS" and p3.points == 4 and r.backup.size() == 14, "CATS scores 4 (backup S)")
	check(r.score == 7, "score 7 so far")

	# Front plays + any backup index. Backup is now [A, C, TH, Q...]
	var p4 := r.play(true, 0, 1, true) # A at front of T
	check(p4.valid and p4.word == "AT" and p4.points == 2, "A at front of T = AT, 2 pts")
	var p5 := r.play(true, 0, 1, true) # C (index 0 now) at front
	check(p5.valid and p5.word == "CAT" and p5.points == 3, "C at front = CAT, 3 pts")
	var p6 := r.play(true, 0, 2, true) # TH at front of E
	check(p6.valid and p6.word == "THE" and p6.points == 4, "TH + E = THE, 4 pts (digraph worth 3)")
	check(r.score == 7 + 2 + 3 + 4, "score 16")
	check(r.longest_word() == "CATS", "longest word is CATS")
	check(not r.play(true, 99, 0, false).ok, "bad backup index rejected")

	# Regression: every lane can play every card in its pool, including the last ones
	var d := GameState.new()
	d.new_game()
	var played := 0
	for lane in 3:
		while d.pool_top(lane) != "":
			if d.play(false, lane, 0, false).ok:
				played += 1
	check(played == 30 and d.cards_left() == 15, "all 30 pool cards playable from lanes 0-2")
	check(not d.play(false, 1, 0, false).ok, "empty pool cannot be played")

	# Leaderboard
	var path := "user://test_leaderboard.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var lb := Leaderboard.new(path)
	lb.player_name = "Mom"
	lb.add_game(10, "cat", 3)
	lb.add_game(25, "cats", 5)
	lb.add_game(15, "at", 2)
	var again := Leaderboard.new(path)
	check(again.games.size() == 3 and again.player_name == "Mom", "leaderboard persists to disk")
	check(again.top(2)[0].score == 25 and again.top(2)[1].score == 15, "top() sorted best first")
	check(again.scores() == [10, 25, 15], "scores() in play order")
	check(again.best_score() == 25, "best_score")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
