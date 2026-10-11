extends SceneTree
## Run: godot --headless --path . --script tests/test_logic.gd

var failures := 0


func check(cond: bool, label: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + label)
	if not cond:
		failures += 1


func _init() -> void:
	check(GameState.load_dictionary(), "dictionary loads")
	check(GameState.is_word("cat") and GameState.is_word("CATS"), "cat / CATS are words")
	check(not GameState.is_word("ca") and not GameState.is_word("xqz"), "ca / xqz are not words")

	var total := 0
	for n in GameState.CARD_COUNTS.values():
		total += n
	check(total == 117, "deck has 117 cards (got %d)" % total)
	check(GameState.max_words_for_deck() == 8, "max words is 8")

	# Setup counts
	var g := GameState.new()
	g.new_game(5)
	check(g.scoring.size() == 5 and g.pools.size() == 5, "5 scoring + 5 pools")
	check(g.pools[0].size() == 10 and g.backup.size() == 15, "pool 10, backup 15")
	check(g.cards_left() == 5 * 10 + 15, "cards_left = 65")
	var g8 := GameState.new()
	g8.new_game(99)
	check(g8.num_words == 8, "word count clamps to 8")

	# Rigged deck (cards are popped from the back): scoring C, pool [.. T, A(top)], backup top S
	var deck: Array = []
	for i in 20:
		deck.append("Z")
	deck.append("S") # backup top (popped last of the backup)
	for i in 14:
		deck.append("Q")
	deck.append("A") # pool top (popped last of the pool)
	deck.append("T")
	for i in 8:
		deck.append("Q")
	deck.append("C") # scoring card (popped first)
	var r := GameState.new()
	r.new_game(1, deck)
	check(r.scoring[0] == ["C"] and r.pool_top(0) == "A" and r.backup_top() == "S", "rigged setup")
	var p1 := r.play(false, 0, 0)
	check(not p1.valid and p1.points == 0 and r.score == 0, "CA scores nothing")
	var p2 := r.play(false, 0, 0)
	check(p2.valid and p2.word == "CAT" and p2.points == 3, "CAT scores 3")
	var p3 := r.play(true, 0, 0)
	check(p3.valid and p3.word == "CATS" and p3.points == 4, "CATS scores 4")
	check(r.score == 7, "total 3 + 4 = 7")

	# Two-letter cards are worth 3
	check(GameState.stack_value(["T", "H", "E"]) == 3, "T,H,E = 3")
	check(GameState.stack_value(["TH", "E"]) == 4, "TH,E = 4 (digraph worth 3)")
	check(GameState.stack_value(["C", "O", "RE"]) == 5, "C,O,RE = 5")

	print("\n%d failure(s)" % failures)
	quit(1 if failures > 0 else 0)
