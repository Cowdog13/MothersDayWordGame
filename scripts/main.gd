extends Control
## UI and input. Tap a top card (pool stack or backup pile) to select it, then tap a
## scoring row to play it there. All rules live in GameState.

const CARD_SIZE := Vector2(86, 120)
const TILE_SIZE := Vector2(46, 64)
const FELT := Color(0.09, 0.30, 0.22)

var state := GameState.new()
var words_to_play := 4
var select_backup := false
var select_lane := -1 ## pool lane of the selected card, -1 = none
var message := ""

var menu_screen: Control
var game_screen: Control
var over_screen: Control
var count_label: Label
var score_label: Label
var message_label: Label
var lanes_box: VBoxContainer
var backup_holder: VBoxContainer
var over_label: Label
var confirm_end: ConfirmationDialog


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
	_build_over()
	_show_menu()


# ---------- screens ----------

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
	rules.text = "Tap a top card, then tap a word row to play it.\nA valid word scores 1 point per letter\n(a 2-letter card is worth 3).\nEvery play re-checks the word."
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules.custom_minimum_size.x = 600
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(rules)

	var pick := HBoxContainer.new()
	pick.alignment = BoxContainer.ALIGNMENT_CENTER
	pick.add_theme_constant_override("separation", 20)
	box.add_child(pick)
	var caption := Label.new()
	caption.text = "Words:"
	pick.add_child(caption)
	pick.add_child(_button("-", func(): _change_words(-1), Vector2(70, 70)))
	count_label = Label.new()
	count_label.custom_minimum_size.x = 40
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pick.add_child(count_label)
	pick.add_child(_button("+", func(): _change_words(1), Vector2(70, 70)))

	var start := _button("Start Game", _start_game, Vector2(300, 80))
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(start)


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
	top.add_child(_button("End Game", func(): confirm_end.popup_centered(), Vector2(0, 56)))

	message_label = Label.new()
	message_label.custom_minimum_size.y = 36
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
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 16)
	bottom.add_child(bottom_row)
	backup_holder = VBoxContainer.new()
	bottom_row.add_child(backup_holder)
	var tip := Label.new()
	tip.text = "Backup pile:\nplay its top card\nonto any word, any time."
	tip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom_row.add_child(tip)

	confirm_end = ConfirmationDialog.new()
	confirm_end.dialog_text = "End the game now and keep your score?"
	confirm_end.confirmed.connect(_finish)
	add_child(confirm_end)


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
	var again := _button("Play Again", _show_menu, Vector2(300, 80))
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(again)


func _show_menu() -> void:
	menu_screen.show()
	game_screen.hide()
	over_screen.hide()
	_change_words(0)


func _change_words(delta: int) -> void:
	words_to_play = clampi(words_to_play + delta, GameState.MIN_WORDS, GameState.max_words_for_deck())
	count_label.text = str(words_to_play)


func _start_game() -> void:
	state = GameState.new()
	state.new_game(words_to_play)
	select_backup = false
	select_lane = -1
	message = "Select a top card, then tap a word row."
	menu_screen.hide()
	over_screen.hide()
	game_screen.show()
	_refresh()


func _finish() -> void:
	var best := ""
	for made in state.words_made:
		if made.word.length() > best.length():
			best = made.word
	over_label.text = "Game over!\n\nFinal score: %d\nWords scored: %d" % [state.score, state.words_made.size()]
	if best != "":
		over_label.text += "\nLongest: " + best.to_upper()
	over_screen.show()


# ---------- drawing ----------

func _refresh() -> void:
	score_label.text = "Score: %d" % state.score
	message_label.text = message

	for lane in lanes_box.get_children():
		lanes_box.remove_child(lane)
		lane.queue_free()
	for i in state.num_words:
		lanes_box.add_child(_make_lane(i))

	for child in backup_holder.get_children():
		backup_holder.remove_child(child)
		child.queue_free()
	var backup_card := CardView.create(state.backup_top(), CARD_SIZE * 0.85, select_backup, str(state.backup.size()))
	backup_card.pressed.connect(_on_backup_pressed)
	backup_holder.add_child(backup_card)


func _make_lane(i: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var pool_card := CardView.create(state.pool_top(i), CARD_SIZE, select_lane == i, str(state.pools[i].size()))
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
	area.gui_input.connect(_on_area_input.bind(i))

	var content := VBoxContainer.new()
	area.add_child(content)
	var tiles := HFlowContainer.new()
	tiles.add_theme_constant_override("h_separation", 4)
	tiles.add_theme_constant_override("v_separation", 4)
	content.add_child(tiles)
	for code in stack:
		tiles.add_child(CardView.create(code, TILE_SIZE))
	var status := Label.new()
	if valid:
		status.text = "%s  =  %d pts" % [word.to_upper(), GameState.stack_value(stack)]
		status.add_theme_color_override("font_color", Color(0.6, 1, 0.65))
	else:
		status.text = word.to_upper() + "  (not a word)" if stack.size() > 1 else "Start of a word"
		status.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	content.add_child(status)
	_ignore_mouse(content)

	row.add_child(area)
	return row


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)


# ---------- input ----------

func _on_pool_pressed(lane: int) -> void:
	if state.pool_top(lane) == "":
		return
	var already := select_lane == lane and not select_backup
	_select(false, -1 if already else lane)


func _on_backup_pressed() -> void:
	if state.backup_top() == "":
		return
	_select(not select_backup, -1)


func _select(from_backup: bool, lane: int) -> void:
	select_backup = from_backup
	select_lane = lane
	message = "Now tap the word row to play it on." if lane >= 0 or from_backup else "Select a top card, then tap a word row."
	_refresh()


func _on_area_input(event: InputEvent, target: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not select_backup and select_lane < 0:
		message = "Select a card from a pool stack or the backup pile first."
		_refresh()
		return
	var result := state.play(select_backup, select_lane, target)
	select_backup = false
	select_lane = -1
	if not result.ok:
		return
	var word: String = result.word.to_upper()
	if result.valid:
		message = "%s makes %s: +%d points!" % [result.card, word, result.points]
	else:
		message = "%s makes %s: not a word, no points." % [result.card, word]
	_refresh()
	if state.is_over():
		_finish()


# ---------- helpers ----------

func _button(label: String, on_press: Callable, min_size := Vector2.ZERO) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = min_size
	b.pressed.connect(on_press)
	return b
