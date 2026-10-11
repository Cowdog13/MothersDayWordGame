class_name CardView
extends PanelContainer
## One card. Draws a box with the letter(s), unless res://assets/cards/<CODE>.png exists,
## in which case that image is used instead (e.g. assets/cards/TH.png, assets/cards/A.png).

signal pressed

const IMAGE_DIR := "res://assets/cards/"

var code := "" ## "" draws an empty slot
var card_size := Vector2(86, 120)
var selected := false
var badge := ""


static func create(p_code: String, p_size: Vector2, p_selected := false, p_badge := "") -> CardView:
	var card := CardView.new()
	card.code = p_code
	card.card_size = p_size
	card.selected = p_selected
	card.badge = p_badge
	return card


func _ready() -> void:
	custom_minimum_size = card_size
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(int(card_size.x * 0.12))
	if code == "":
		box.bg_color = Color(0, 0, 0, 0.18)
		box.set_border_width_all(2)
		box.border_color = Color(1, 1, 1, 0.25)
	else:
		box.bg_color = Color(1.0, 0.97, 0.88)
		box.set_border_width_all(6 if selected else 3)
		box.border_color = Color(1.0, 0.75, 0.1) if selected else Color(0.35, 0.24, 0.12)
	add_theme_stylebox_override("panel", box)
	if code == "":
		return

	var image_path := IMAGE_DIR + code + ".png"
	if ResourceLoader.exists(image_path):
		var pic := TextureRect.new()
		pic.texture = load(image_path)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(pic)
	else:
		var letters := Label.new()
		letters.text = code
		letters.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letters.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var scale := 0.4 if code.length() == 1 else 0.36
		letters.add_theme_font_size_override("font_size", int(card_size.y * scale))
		letters.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
		add_child(letters)

	if badge != "":
		var count := Label.new()
		count.text = badge
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.add_theme_font_size_override("font_size", maxi(14, int(card_size.y * 0.16)))
		count.add_theme_color_override("font_color", Color(0.45, 0.3, 0.15))
		add_child(count)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()
		accept_event()
