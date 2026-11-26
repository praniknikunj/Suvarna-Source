extends Control

signal opened
signal closed
signal selected(action: String)

const UI = preload("res://scripts/votive_ui.gd")
const ITEMS := [
	["resume", "Resume pilgrimage", "Return to the current gallery."],
	["map", "Gallery chart", "Check discovered corridors and gates."],
	["inventory", "Pilgrim's satchel", "Inspect relics, seals, and your collected ashes."],
	["journal", "Journal of the Votary", "Read memories and check the state of your vows."],
	["controls", "Controls", "Review movement, attacks, and interaction."],
	["restart", "Restart this seed", "Begin the current pilgrimage again."],
	["title", "Return to the title", "Leave this pilgrimage and return to the ledger."]
]
const PANEL := Rect2(161, 66, 638, 406)
const ROW := Vector2(201, 153)
const ROW_HEIGHT := 36

var cursor := 0
var items: Array = ITEMS
var confirmation := ""
var confirmation_cursor := 0
var serif := UI.display_font()
var body: Font

func _ready() -> void:
	size = Vector2(960, 540)
	z_index = 28
	mouse_filter = Control.MOUSE_FILTER_STOP
	body = ThemeDB.fallback_font
	hide()

func open() -> void:
	if visible:
		return
	cursor = 0
	confirmation = ""
	show()
	queue_redraw()
	opened.emit()

func close() -> void:
	if not visible:
		return
	confirmation = ""
	hide()
	closed.emit()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func navigate(key: Key) -> bool:
	if key == KEY_P:
		toggle()
		return true
	if not visible:
		return false
	match key:
		KEY_ESCAPE:
			if confirmation.is_empty():
				close()
			else:
				confirmation = ""
		KEY_UP, KEY_DOWN:
			var step := -1 if key == KEY_UP else 1
			if confirmation.is_empty():
				cursor = posmod(cursor + step, items.size())
			else:
				confirmation_cursor = posmod(confirmation_cursor + step, 2)
		KEY_E, KEY_ENTER, KEY_KP_ENTER:
			activate()
		_:
			return false
	queue_redraw()
	return true

func activate() -> void:
	if not visible:
		return
	if not confirmation.is_empty():
		var action := confirmation
		confirmation = ""
		if confirmation_cursor == 1:
			pick(action)
		return
	var action: String = items[cursor][0]
	if action in ["restart", "title"]:
		confirmation = action
		confirmation_cursor = 0
	else:
		pick(action)

func pick(action: String) -> void:
	close()
	selected.emit(action)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and confirmation.is_empty():
		var idx := row_at(event.position, ROW, items.size())
		if idx >= 0 and idx != cursor:
			cursor = idx
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if confirmation.is_empty():
			var idx := row_at(event.position, ROW, items.size())
			if idx >= 0:
				cursor = idx
				activate()
		else:
			var idx := row_at(event.position, Vector2(278, 265), 2)
			if idx >= 0:
				confirmation_cursor = idx
				activate()
		queue_redraw()
		accept_event()

func row_at(point: Vector2, origin: Vector2, count: int) -> int:
	if not Rect2(origin, Vector2(289, count * ROW_HEIGHT)).has_point(point):
		return -1
	return floori((point.y - origin.y) / ROW_HEIGHT)

func _draw() -> void:
	if body == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#060912c0"))
	UI.engraved(self, PANEL, Color("#151a23"), Color("#9f754f"))
	UI.engraved(self, PANEL.grow(-7), Color.TRANSPARENT, Color("#4d4147"))
	UI.rule(self, Vector2(202, 137), Vector2(755, 137), Color("#aa805e"))
	UI.lotus(self, Vector2(734, 104), 1.4, UI.BRASS)
	draw_string(serif, Vector2(200, 116), "Stillness", HORIZONTAL_ALIGNMENT_LEFT, -1, 33, UI.CREAM)
	if confirmation.is_empty():
		draw_actions()
	else:
		draw_confirmation()
	UI.rule(self, Vector2(202, 420), Vector2(755, 420), Color("#aa805e"))
	draw_string(body, Vector2(202, 449), "UP / DOWN   SELECT      E   CHOOSE      P   RESUME",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UI.PATINA)

func draw_actions() -> void:
	for i in range(items.size()):
		var at := ROW + Vector2(0, i * ROW_HEIGHT)
		var active := cursor == i
		if active:
			UI.engraved(self, Rect2(at, Vector2(289, ROW_HEIGHT - 3)), Color("#45353a"), Color("#b48863"))
		UI.diamond(self, at + Vector2(16, 16), 3.0, UI.BRASS if active else Color("#6c5a51"))
		draw_string(serif, at + Vector2(29, 23), items[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1,
			19, UI.CREAM if active else Color("#b7aa9a"))
	draw_line(Vector2(511, 159), Vector2(511, 406), Color("#55464b"), 1)
	UI.lotus(self, Vector2(643, 206), 2.25, Color("#786047"))
	draw_description(items[cursor][2], Vector2(535, 284), 211)

func draw_confirmation() -> void:
	var question := "Restart this run?" if confirmation == "restart" else "Return to the title?"
	draw_string(serif, Vector2(277, 199), question, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UI.CREAM)
	draw_description("Your current run progress will be lost.", Vector2(277, 230), 400)
	var labels := ["Keep playing", "Restart run" if confirmation == "restart" else "Leave run"]
	for i in range(2):
		var at := Vector2(278, 265 + i * ROW_HEIGHT)
		var active := confirmation_cursor == i
		if active:
			UI.engraved(self, Rect2(at, Vector2(289, ROW_HEIGHT - 3)), Color("#45353a"), Color("#b48863"))
		draw_string(serif, at + Vector2(23, 23), labels[i], HORIZONTAL_ALIGNMENT_LEFT,
			-1, 19, UI.CREAM if active else Color("#b7aa9a"))

func draw_description(text: String, at: Vector2, max_width: float) -> void:
	var line := ""
	var y := at.y
	for word in text.split(" ", false):
		var candidate: String = word if line.is_empty() else line + " " + word
		if serif.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x > max_width and not line.is_empty():
			draw_string(serif, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.CREAM)
			y += 22.0
			line = word
		else:
			line = candidate
	draw_string(serif, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.CREAM)
