extends Control

signal selected(accept: bool)

const UI = preload("res://scripts/votive_ui.gd")
const Pixels = preload("res://scripts/guardian_pixels.gd")
var title := ""
var detail := ""
var rows: Array[String] = []
var cursor := 0
var icon := -1
var serif := UI.display_font()

func _ready() -> void:
	size = Vector2(960, 540)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = MOUSE_FILTER_STOP
	hide()

func present(heading: String, line: String, options: Array[String], start: int, reward_icon := -1) -> void:
	title = heading
	detail = line
	rows.assign(options)
	cursor = start
	icon = reward_icon
	show()
	queue_redraw()

func navigate(key: Key) -> void:
	if key in [KEY_LEFT, KEY_UP, KEY_RIGHT, KEY_DOWN]:
		cursor = 1 - cursor
		queue_redraw()
	elif key in [KEY_E, KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		selected.emit(cursor == 0)
	elif key == KEY_ESCAPE:
		selected.emit(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(rows.size()):
			if option(i).has_point(event.position):
				selected.emit(i == 0)
				accept_event()
				return

func option(index: int) -> Rect2:
	return Rect2(278 + index * 208, 317, 196, 44)

func text_centre(font: Font, x: float, y: float, value: String, px: int, color: Color) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string(font, Vector2(roundf(x - width * 0.5), y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func _draw() -> void:
	if rows.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#100810b7"))
	UI.engraved(self, Rect2(244, 160, 472, 248), Color("#181620"), UI.BRASS)
	UI.engraved(self, Rect2(252, 168, 456, 232), Color.TRANSPARENT, Color("#594046"))
	UI.sun(self, Vector2(480, 188), 13.0, UI.BRASS)
	if icon >= 0:
		Pixels.icon(self, icon, Vector2(464, 173), 32)
	text_centre(serif, 480, 240, title, 38, UI.CREAM)
	text_centre(ThemeDB.fallback_font, 480, 277, detail, 14, UI.CREAM)
	UI.rule(self, Vector2(279, 294), Vector2(682, 294), UI.BRASS)
	for i in range(rows.size()):
		var at := option(i)
		var active := i == cursor
		UI.engraved(self, at, Color("#412831") if active else Color("#1b232b"), UI.BRASS if active else Color("#635052"))
		text_centre(serif, at.get_center().x, at.position.y + 28.0, rows[i], 22, UI.CREAM)
	text_centre(ThemeDB.fallback_font, 480, 386, "Arrows  Select     E  Confirm", 12, UI.PATINA)
