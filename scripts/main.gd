extends Control
## UI and input. Tap a card (a pool's revealed card, or any backup card) to select it, then tap
## a "+" at the front or end of a word to play it there. All rules live in GameState.

const CARD_SIZE := Vector2(86, 120)
const TILE_SIZE := Vector2(52, 72)
const BACKUP_CARD_SIZE := Vector2(58, 82)
const FELT := Color(0.09, 0.30, 0.22)
const CHART_GAMES := 30

var state := GameState.new()
var board := Leaderboard.new()
var sel_kind := "" ## "", "pool" or "backup"
var sel_index := -1
var message := ""

var menu_screen: Control
var game_screen: Control
var over_screen: Control
var board_screen: Control
var name_edit: LineEdit
var score_label: Label
var message_label: Label
var lanes_box: VBoxContainer
var backup_title: Label
var backup_flow: HFlowContainer
var over_label: Label
var board_box: VBoxContainer
var confirm_giveup: ConfirmationDialog


func _ready() -> void:
	randomize()
	var ui_theme := Theme.new()
	ui_theme.default_font_size = 26
	theme = ui_theme
	GameState.load_dictionary()

	var bg := ColorRect.new()
	bg.color = FELT
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_build_menu()
	_build_game()
	_build_board()
	_build_over()
	_show_menu()


# ---------- building screens ----------

func _build_menu() -> void:
	menu_screen = CenterContainer.new()
	menu_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(menu_screen)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	menu_screen.add_child(box)

	var title := Label.new()
	title.text = "Mother's Day\nWord Game"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	box.add_child(title)

	var rules := Label.new()
	rules.text = "Build words from the 3 starting cards. Add letters to the front or end.\nEvery valid word scores 1 point per letter (a 2-letter card is worth 3).\nPlay until you give up."
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules.custom_minimum_size.x = 600
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(rules)

	var who := HBoxContainer.new()
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 14)
	box.add_child(who)
	var who_label := Label.new()
	who_label.text = "Player:"
	who.add_child(who_label)
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(300, 60)
	name_edit.max_length = 16
	name_edit.text_submitted.connect(func(_t): _start_game())
	who.add_child(name_edit)

	var start := _button("Start Game", _start_game, Vector2(300, 80))
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(start)
	var scores := _button("Leaderboard", _show_board, Vector2(300, 70))
	scores.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(scores)


func _build_game() -> void:
	game_screen = MarginContainer.new()
	game_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		game_screen.add_theme_constant_override("margin_" + side, 12)
	add_child(game_screen)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	game_screen.add_child(column)

	var top := HBoxContainer.new()
	column.add_child(top)
	score_label = Label.new()
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_label.add_theme_font_size_override("font_size", 36)
	top.add_child(score_label)
	top.add_child(_button("Give Up", func(): confirm_giveup.popup_centered(), Vector2(0, 56)))

	message_label = Label.new()
	message_label.custom_minimum_size.y = 70
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(message_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	lanes_box = VBoxContainer.new()
	lanes_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lanes_box.add_theme_constant_override("separation", 10)
	scroll.add_child(lanes_box)

	var bottom := PanelContainer.new()
	var bottom_style := StyleBoxFlat.new()
	bottom_style.bg_color = Color(0, 0, 0, 0.3)
	bottom_style.set_corner_radius_all(12)
	bottom_style.set_content_margin_all(10)
	bottom.add_theme_stylebox_override("panel", bottom_style)
	column.add_child(bottom)
	var bottom_box := VBoxContainer.new()
	bottom.add_child(bottom_box)
	backup_title = Label.new()
	bottom_box.add_child(backup_title)
	backup_flow = HFlowContainer.new()
	backup_flow.add_theme_constant_override("h_separation", 6)
	backup_flow.add_theme_constant_override("v_separation", 6)
	bottom_box.add_child(backup_flow)

	confirm_giveup = ConfirmationDialog.new()
	confirm_giveup.dialog_text = "Give up and record your score?"
	confirm_giveup.confirmed.connect(_finish)
	add_child(confirm_giveup)


func _build_over() -> void:
	over_screen = ColorRect.new()
	(over_screen as ColorRect).color = Color(0, 0, 0, 0.75)
	over_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(over_screen)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_screen.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	over_label = Label.new()
	over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	over_label.add_theme_font_size_override("font_size", 40)
	box.add_child(over_label)
	for spec in [["Play Again", _start_game], ["Leaderboard", _show_board], ["Main Menu", _show_menu]]:
		var b := _button(spec[0], spec[1], Vector2(300, 70))
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(b)


func _build_board() -> void:
	board_screen = MarginContainer.new()
	board_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		board_screen.add_theme_constant_override("margin_" + side, 16)
	add_child(board_screen)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	board_screen.add_child(column)
	var head := HBoxContainer.new()
	column.add_child(head)
	var title := Label.new()
	title.text = "Leaderboard"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 40)
	head.add_child(title)
	head.add_child(_button("Back", _show_menu, Vector2(0, 56)))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	board_box = VBoxContainer.new()
	board_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_box.add_theme_constant_override("separation", 14)
	scroll.add_child(board_box)


# ---------- screen flow ----------

func _hide_all() -> void:
	for screen in [menu_screen, game_screen, over_screen, board_screen]:
		screen.hide()


func _show_menu() -> void:
	_hide_all()
	name_edit.text = board.player_name
	menu_screen.show()


func _show_board() -> void:
	_hide_all()
	_fill_board()
	board_screen.show()


func _start_game() -> void:
	var entered := name_edit.text.strip_edges()
	board.player_name = entered if entered != "" else "Player"
	state = GameState.new()
	state.new_game()
	sel_kind = ""
	sel_index = -1
	message = "Tap a card, then tap a + at the start or end of a word."
	_hide_all()
	game_screen.show()
	_refresh()


func _finish() -> void:
	var previous_best := board.best_score()
	board.add_game(state.score, state.longest_word(), state.words_made.size())
	over_label.text = "Final score: %d\nWords scored: %d" % [state.score, state.words_made.size()]
	if state.longest_word() != "":
		over_label.text += "\nLongest: " + state.longest_word().to_upper()
	if state.score > previous_best and state.score > 0:
		over_label.text += "\nNew personal best!"
	over_screen.show()


func _fill_board() -> void:
	for child in board_box.get_children():
		board_box.remove_child(child)
		child.queue_free()

	var chart_title := Label.new()
	chart_title.text = "Your scores"
	board_box.add_child(chart_title)
	var chart := ScoreChart.new()
	chart.custom_minimum_size.y = 280
	var all_scores := board.scores()
	var shown := all_scores.slice(maxi(0, all_scores.size() - CHART_GAMES))
	chart.show_scores(shown, all_scores.size() - shown.size() + 1)
	board_box.add_child(chart)

	var top_title := Label.new()
	top_title.text = "Top 10"
	board_box.add_child(top_title)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 6)
	board_box.add_child(grid)
	for head in ["#", "Player", "Score", "Longest", "Date"]:
		var h := Label.new()
		h.text = head
		h.modulate = Color(1, 1, 1, 0.6)
		grid.add_child(h)
	var rank := 1
	for g in board.top(10):
		var cells := [str(rank), g.name, str(int(g.score)), str(g.longest).to_upper(),
				Time.get_date_string_from_unix_time(int(g.time))]
		for cell in cells:
			var l := Label.new()
			l.text = cell
			l.add_theme_font_size_override("font_size", 22)
			grid.add_child(l)
		rank += 1
	if board.games.is_empty():
		var none := Label.new()
		none.text = "No games yet."
		board_box.add_child(none)


# ---------- game drawing ----------

func _refresh() -> void:
	score_label.text = "Score: %d" % state.score
	message_label.text = message

	for lane in lanes_box.get_children():
		lanes_box.remove_child(lane)
		lane.queue_free()
	for i in state.num_words:
		lanes_box.add_child(_make_lane(i))

	backup_title.text = "Backup (%d) - play any of these at any time" % state.backup.size()
	for child in backup_flow.get_children():
		backup_flow.remove_child(child)
		child.queue_free()
	for i in state.backup.size():
		var card := CardView.create(state.backup[i], BACKUP_CARD_SIZE, sel_kind == "backup" and sel_index == i)
		card.pressed.connect(_on_backup_pressed.bind(i))
		backup_flow.add_child(card)


func _make_lane(i: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var pool_card := CardView.create(state.pool_top(i), CARD_SIZE, sel_kind == "pool" and sel_index == i, str(state.pools[i].size()))
	pool_card.pressed.connect(_on_pool_pressed.bind(i))
	row.add_child(pool_card)

	var stack: Array = state.scoring[i]
	var word := GameState.stack_text(stack)
	var valid := GameState.is_word(word)

	var area := PanelContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.custom_minimum_size.y = CARD_SIZE.y
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.28)
	style.set_corner_radius_all(12)
	style.set_border_width_all(3)
	style.border_color = Color(0.4, 0.9, 0.5) if valid else Color(1, 1, 1, 0.15)
	style.set_content_margin_all(8)
	area.add_theme_stylebox_override("panel", style)

	var content := VBoxContainer.new()
	area.add_child(content)
	var tiles := HFlowContainer.new()
	tiles.add_theme_constant_override("h_separation", 4)
	tiles.add_theme_constant_override("v_separation", 4)
	content.add_child(tiles)
	tiles.add_child(_slot_button(i, true))
	for code in stack:
		var tile := CardView.create(code, TILE_SIZE)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tiles.add_child(tile)
	tiles.add_child(_slot_button(i, false))

	var status := Label.new()
	if valid:
		status.text = "%s  =  %d pts" % [word.to_upper(), GameState.stack_value(stack)]
		status.add_theme_color_override("font_color", Color(0.6, 1, 0.65))
	else:
		status.text = word.to_upper() + "  (not a word)" if stack.size() > 1 else "Start of a word"
		status.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	content.add_child(status)

	row.add_child(area)
	return row


func _slot_button(lane: int, at_front: bool) -> Button:
	var b := _button("+", _on_slot_pressed.bind(lane, at_front), TILE_SIZE)
	b.disabled = sel_kind == ""
	b.tooltip_text = "Add to the front" if at_front else "Add to the end"
	return b


# ---------- input ----------

func _on_pool_pressed(lane: int) -> void:
	if state.pool_top(lane) == "":
		return
	_select("pool", lane)


func _on_backup_pressed(index: int) -> void:
	_select("backup", index)


func _select(kind: String, index: int) -> void:
	if sel_kind == kind and sel_index == index:
		sel_kind = ""
		sel_index = -1
		message = "Tap a card, then tap a + at the start or end of a word."
	else:
		sel_kind = kind
		sel_index = index
		message = "Now tap a + at the front or end of a word."
	_refresh()


func _on_slot_pressed(lane: int, at_front: bool) -> void:
	if sel_kind == "":
		return
	var result := state.play(sel_kind == "backup", sel_index, lane, at_front)
	sel_kind = ""
	sel_index = -1
	if not result.ok:
		return
	var word: String = result.word.to_upper()
	if result.valid:
		message = "%s makes %s: +%d points!" % [result.card, word, result.points]
	else:
		message = "%s makes %s: not a word, no points." % [result.card, word]
	if state.cards_left() == 0:
		message += "\nNo cards left - tap Give Up to finish."
	_refresh()


# ---------- helpers ----------

func _button(label: String, on_press: Callable, min_size := Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = min_size
	b.pressed.connect(on_press)
	return b
