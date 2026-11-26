extends Control

const Legacy = preload("res://scripts/pilgrimage_legacy.gd")
const Pixels = preload("res://scripts/guardian_pixels.gd")
const UI = preload("res://scripts/votive_ui.gd")
const VISIBLE_ROWS := 5

var unlocked: Dictionary = {}
var entries: Array[String] = []
var cursor := 0
var serif := UI.display_font()

func _ready() -> void:
	size = Vector2(960, 540)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = MOUSE_FILTER_STOP
	hide()

func load_awards(updated: Dictionary) -> void:
	unlocked = updated.duplicate()
	entries.clear()
	for quest in Legacy.QUESTS:
		entries.append(quest.id)
	entries.append(Legacy.VAJRA_ID)
	var depths: Array[int] = []
	for id in unlocked:
		if String(id).begins_with("depth_"):
			depths.append(int(String(id).trim_prefix("depth_")))
	depths.sort()
	for depth in depths:
		entries.append(Legacy.milestone_id(depth))
	var next := 200 if depths.is_empty() else depths[-1] + 100
	entries.append(Legacy.milestone_id(next))
	cursor = clampi(cursor, 0, entries.size() - 1)
	queue_redraw()

func navigate(key: Key) -> void:
	match key:
		KEY_UP:
			cursor = posmod(cursor - 1, entries.size())
		KEY_DOWN:
			cursor = posmod(cursor + 1, entries.size())
		KEY_ESCAPE, KEY_E, KEY_ENTER, KEY_KP_ENTER:
			hide()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			navigate(KEY_UP)
		MOUSE_BUTTON_WHEEL_DOWN:
			navigate(KEY_DOWN)
		MOUSE_BUTTON_LEFT:
			if Rect2(727, 407, 108, 42).has_point(event.position):
				hide()
			else:
				var row := floori((event.position.y - 144.0) / 50.0)
				if row >= 0 and row < VISIBLE_ROWS and event.position.x > 126 and event.position.x < 517:
					cursor = mini(entries.size() - 1, first() + row)
					queue_redraw()
	accept_event()

func first() -> int:
	return clampi(cursor - VISIBLE_ROWS + 1, 0, maxi(0, entries.size() - VISIBLE_ROWS))

func write(at: Vector2, value: String, px: int, color: Color, ornamental := false) -> void:
	draw_string(serif if ornamental else ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)

func _draw() -> void:
	if entries.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0b0712e6"))
	UI.engraved(self, Rect2(101, 68, 758, 402), Color("#1b1922"), UI.BRASS)
	UI.engraved(self, Rect2(109, 76, 742, 386), Color.TRANSPARENT, Color("#5f4752"))
	write(Vector2(128, 121), "Achievements", 34, UI.CREAM, true)
	write(Vector2(565, 115), "%d recorded" % unlocked.size(), 15, UI.PATINA)
	UI.rule(self, Vector2(126, 133), Vector2(832, 133), UI.BRASS)
	for i in range(first(), mini(entries.size(), first() + VISIBLE_ROWS)):
		var top := 144 + (i - first()) * 50
		var info := Legacy.award_detail(entries[i])
		var found := unlocked.has(entries[i])
		UI.engraved(self, Rect2(128, top, 388, 46), Color("#3a2732") if i == cursor else Color("#1c232d"),
			UI.BRASS if i == cursor else Color("#53444e"))
		if found and info.has("depth"):
			Pixels.milestone(self, info.depth, Vector2(138, top + 5), 35)
		else:
			Pixels.icon(self, info.icon, Vector2(138, top + 5), 35, Color.WHITE if found else Color("#6c6070"))
		write(Vector2(184, top + 29), info.title, 18, UI.CREAM if found else Color("#bdacaa"), true)
	var id := entries[cursor]
	var selected := Legacy.award_detail(id)
	var earned := unlocked.has(id)
	UI.sun(self, Vector2(685, 205), 49.0, Color("#5a414d"))
	if earned and selected.has("depth"):
		Pixels.milestone(self, selected.depth, Vector2(647, 166), 76)
	else:
		Pixels.icon(self, selected.icon, Vector2(647, 166), 76, Color.WHITE if earned else Color("#6c6070"))
	write(Vector2(556, 273), "Recorded" if earned else "Undiscovered", 14, UI.PATINA if earned else UI.BRASS)
	var detail: String = selected.description
	if not earned and selected.has("item") and not selected.item.is_empty():
		detail = "Defeat Vajrakala at dungeon 100." if id == Legacy.VAJRA_ID else "Gather the four relics of this passage vow and defeat its keeper."
	var line := ""
	var y := 306
	for word in detail.split(" "):
		if ThemeDB.fallback_font.get_string_size(line + word, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x > 250:
			write(Vector2(556, y), line, 15, UI.CREAM)
			y += 22
			line = ""
		line += word + " "
	write(Vector2(556, y), line, 15, UI.CREAM)
	UI.rule(self, Vector2(126, 399), Vector2(832, 399), UI.BRASS)
	write(Vector2(133, 433), "↑  ↓  Select", 13, UI.PATINA)
	UI.engraved(self, Rect2(727, 407, 108, 42), Color("#30232d"), UI.BRASS)
	write(Vector2(750, 434), "Esc  Close", 14, UI.CREAM)
