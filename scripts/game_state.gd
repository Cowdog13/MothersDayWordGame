class_name GameState
extends RefCounted
## Pure game rules: deck, setup, playing cards, scoring. No UI in here.

const CARD_COUNTS := {
	"A": 8, "B": 3, "C": 3, "D": 3, "E": 8, "F": 3, "G": 3, "H": 3, "I": 8,
	"J": 3, "K": 3, "L": 3, "M": 3, "N": 3, "O": 8, "P": 3, "Q": 3, "R": 3,
	"S": 3, "T": 3, "U": 8, "V": 3, "W": 3, "X": 1, "Y": 3, "Z": 1,
	"NT": 1, "TE": 1, "TH": 1, "IN": 1, "EN": 1, "RE": 1, "ER": 1, "AN": 1,
	"ES": 1, "ON": 1, "AT": 1, "AR": 1, "AL": 1, "ED": 1, "CO": 1, "DE": 1,
	"ST": 1, "SH": 1,
}
const POOL_SIZE := 10
const BACKUP_SIZE := 15
const NUM_WORDS := 3 ## words (starting cards) in play
const DOUBLE_VALUE := 3 ## points a two-letter card is worth (instead of 2)

static var _dictionary: Dictionary = {}

var num_words := 0
var scoring: Array = [] ## per word: card codes in reading order (cards can be added to either end)
var pools: Array = [] ## per word: Array of card codes, last = revealed top card
var backup: Array = [] ## all visible; any card can be played at any time
var score := 0
var words_made: Array = [] ## [{word, points}] for every successful play


static func load_dictionary(path := "res://data/words.txt") -> bool:
	if not _dictionary.is_empty():
		return true
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open word list: " + path)
		return false
	for w in file.get_as_text().split("\n", false):
		var word := w.strip_edges()
		if word.length() >= 2:
			_dictionary[word] = true
	return not _dictionary.is_empty()


static func is_word(text: String) -> bool:
	return text.length() >= 2 and _dictionary.has(text.to_lower())


static func card_value(code: String) -> int:
	return DOUBLE_VALUE if code.length() == 2 else 1


static func stack_value(stack: Array) -> int:
	var total := 0
	for code in stack:
		total += card_value(code)
	return total


static func stack_text(stack: Array) -> String:
	return "".join(PackedStringArray(stack))


static func build_deck() -> Array:
	var deck: Array = []
	for code in CARD_COUNTS:
		for i in CARD_COUNTS[code]:
			deck.append(code)
	deck.shuffle()
	return deck


func new_game(deck: Array = []) -> void:
	if deck.is_empty():
		deck = build_deck()
	num_words = NUM_WORDS
	scoring = []
	pools = []
	backup = []
	score = 0
	words_made = []
	for i in num_words:
		scoring.append([deck.pop_back()])
	for i in num_words:
		var pool: Array = []
		for j in POOL_SIZE:
			pool.append(deck.pop_back())
		pools.append(pool)
	for i in BACKUP_SIZE:
		backup.append(deck.pop_back())


func pool_top(lane: int) -> String:
	return "" if pools[lane].is_empty() else pools[lane].back()


func cards_left() -> int:
	var n: int = backup.size()
	for pool in pools:
		n += pool.size()
	return n


func longest_word() -> String:
	var best := ""
	for made in words_made:
		if made.word.length() > best.length():
			best = made.word
	return best


## Plays a card onto the front or end of a word in play.
## The card is the revealed top of pool `index`, or backup card number `index`.
## Playing a pool card reveals the next one automatically (the new top of that pool).
## Returns {ok, card, word, valid, points}.
func play(from_backup: bool, index: int, target: int, at_front: bool) -> Dictionary:
	if target < 0 or target >= num_words:
		return {"ok": false}
	if from_backup:
		if index < 0 or index >= backup.size():
			return {"ok": false}
	elif index < 0 or index >= num_words or pools[index].is_empty():
		return {"ok": false}
	var source: Array = backup if from_backup else pools[index]
	var card: String
	if from_backup:
		card = source.pop_at(index)
	else:
		card = source.pop_back()
	if at_front:
		scoring[target].push_front(card)
	else:
		scoring[target].append(card)
	var word: String = stack_text(scoring[target])
	var valid := is_word(word)
	var points := stack_value(scoring[target]) if valid else 0
	score += points
	if valid:
		words_made.append({"word": word, "points": points})
	return {"ok": true, "card": card, "word": word, "valid": valid, "points": points}
