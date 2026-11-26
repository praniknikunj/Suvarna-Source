extends Control

signal started(seed_value: int)
signal replay_requested

const UI = preload("res://scripts/votive_ui.gd")
const Art = preload("res://scripts/opening_art.gd")
const Achievements = preload("res://scripts/pilgrimage_achievements.gd")
const MAX_SEED := "9223372036854775807"

var seed_field: LineEdit
var title_label: Label
var subtitle_label: Label
var story_label: Label
var status_label: Label
var start_button: Button
var generator := RandomNumberGenerator.new()
var display := UI.display_font()
var clock := 0.0
var survey_mode := false
var pilgrimage_button: Button
var survey_button: Button
var settings: Panel
var achievements: Achievements
var record_label: Label

func _ready() -> void:
	generator.randomize()
	size = Vector2(960, 540)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_PASS
	title_label = add_label(Rect2(83, 176, 422, 80), 63, UI.CREAM, display)
	subtitle_label = add_label(Rect2(89, 257, 380, 28), 16, UI.BRASS)
	story_label = add_label(Rect2(88, 304, 360, 100), 19, UI.CREAM, display)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	var desk := add_label(Rect2(540, 153, 309, 33), 26, UI.CREAM, display)
	desk.text = "Pilgrimage ledger"
	pilgrimage_button = add_button(Rect2(540, 187, 148, 27), "Pilgrimage", start_random)
	survey_button = add_button(Rect2(701, 187, 148, 27), "Dungeon Survey", func(): choose_mode(true))
	var caption := add_label(Rect2(540, 217, 309, 21), 11, UI.BRASS)
	caption.text = "DUNGEON SEED"
	seed_field = LineEdit.new()
	seed_field.position = Vector2(540, 239)
	seed_field.size = Vector2(309, 39)
	seed_field.placeholder_text = "Leave blank to roll a seed"
	seed_field.max_length = 28
	seed_field.add_theme_stylebox_override("normal", box("#11171c", "#655646"))
	seed_field.add_theme_stylebox_override("focus", box("#00000000", "#cbaa72"))
	seed_field.add_theme_color_override("font_color", UI.CREAM)
	seed_field.add_theme_font_size_override("font_size", 17)
	seed_field.text_submitted.connect(func(_value: String): submit())
	seed_field.text_changed.connect(func(_value: String): status_label.text = "")
	add_child(seed_field)
	add_button(Rect2(540, 291, 147, 34), "Roll seed", roll)
	add_button(Rect2(701, 291, 148, 34), "Copy seed", copy_seed)
	status_label = add_label(Rect2(540, 331, 309, 40), 13, UI.PATINA)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_button = add_button(Rect2(540, 386, 309, 44), "Begin with this seed", submit)
	start_button.add_theme_font_override("font", display)
	start_button.add_theme_font_size_override("font_size", 19)
	start_button.add_theme_stylebox_override("normal", box("#542c34", "#ad7658"))
	start_button.add_theme_stylebox_override("hover", box("#713944", "#d8ad70"))
	add_button(Rect2(87, 411, 170, 33), "Watch opening", func(): replay_requested.emit())
	add_button(Rect2(270, 411, 125, 33), "Settings", show_settings)
	var award_button := add_button(Rect2(540, 446, 147, 33), "Achievements", func(): achievements.show())
	award_button.tooltip_text = "A   Achievements"
	record_label = add_label(Rect2(702, 439, 149, 43), 12, UI.CREAM)
	record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	build_settings()
	achievements = Achievements.new()
	add_child(achievements)
	choose_mode(false)
	roll()

func _process(dt: float) -> void:
	if visible:
		clock += dt
		queue_redraw()

func _draw() -> void:
	Art.title(self, clock)
	draw_rect(Rect2(0, 0, 960, 12), Color("#090e16"))
	draw_rect(Rect2(0, 528, 960, 12), Color("#090e16"))
	draw_rect(Rect2(65, 158, 426, 297), Color("#0b0d17a0"))
	draw_rect(Rect2(76, 167, 398, 5), Color("#0c0f1ab0"))
	UI.rule(self, Vector2(89, 161), Vector2(471, 161), Color("#997451"))
	UI.rule(self, Vector2(89, 287), Vector2(471, 287), Color("#997451"))
	if title_label.text == "SUVARNA":
		Art.draw_wordmark(self, Vector2(75, 177))
	draw_rect(Rect2(504, 124, 382, 373), Color("#04070dc6"))
	UI.engraved(self, Rect2(508, 115, 368, 376), Color("#101722f5"), Color("#9e775a"))
	UI.engraved(self, Rect2(515, 122, 354, 362), Color.TRANSPARENT, Color("#463e44"))
	for x in [528, 850]:
		draw_rect(Rect2(x, 123, 8, 2), Color("#d1a781"))
		draw_rect(Rect2(x, 480, 8, 2), Color("#b58b69"))

func update_profile(best: int, unlocked: Dictionary) -> void:
	record_label.text = "BEST DUNGEON LEVEL\n" + ("%03d" % best if best > 0 else "—")
	achievements.load_awards(unlocked)

func choose_mode(survey: bool) -> void:
	survey_mode = survey
	pilgrimage_button.modulate = Color.WHITE if not survey else Color("#9a9ba5")
	survey_button.modulate = Color.WHITE if survey else Color("#9a9ba5")
	start_button.text = "Begin survey" if survey else "Begin with this seed"

func start_random() -> void:
	choose_mode(false)
	roll()
	submit()

func show_settings() -> void:
	settings.show()

func build_settings() -> void:
	settings = Panel.new()
	settings.position = Vector2(504, 115)
	settings.size = Vector2(376, 337)
	settings.z_index = 4
	settings.mouse_filter = Control.MOUSE_FILTER_STOP
	settings.add_theme_stylebox_override("panel", box("#101722", "#b88e66"))
	add_child(settings)
	var heading := Label.new()
	heading.text = "Settings"
	heading.position = Vector2(35, 28)
	heading.add_theme_font_override("font", display)
	heading.add_theme_font_size_override("font_size", 28)
	settings.add_child(heading)
	var caption := Label.new()
	caption.text = "Master volume"
	caption.position = Vector2(37, 92)
	settings.add_child(caption)
	var volume := HSlider.new()
	volume.position = Vector2(39, 128)
	volume.size = Vector2(284, 28)
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = clampf(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.0, 1.0)
	volume.value_changed.connect(func(value: float): AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, value))))
	settings.add_child(volume)
	var mode := CheckButton.new()
	mode.text = "Fullscreen"
	mode.position = Vector2(37, 177)
	mode.button_pressed = get_window().mode == Window.MODE_FULLSCREEN
	mode.toggled.connect(func(value: bool): get_window().mode = Window.MODE_FULLSCREEN if value else Window.MODE_WINDOWED)
	settings.add_child(mode)
	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(38, 239)
	back.size = Vector2(283, 42)
	back.add_theme_stylebox_override("normal", box("#29303a", "#876348"))
	back.pressed.connect(func(): settings.hide())
	settings.add_child(back)
	settings.hide()

func present(heading: String, subtitle: String, story: String, action: String) -> void:
	title_label.text = heading
	title_label.visible = heading != "SUVARNA"
	title_label.add_theme_font_size_override("font_size", 48 if heading.length() > 9 else 63)
	subtitle_label.text = subtitle
	story_label.text = story
	start_button.text = "Begin with this seed" if action == "Begin pilgrimage" else action
	survey_mode = false
	pilgrimage_button.modulate = Color.WHITE
	survey_button.modulate = Color("#9a9ba5")
	status_label.text = "Same seed, same dungeon."
	settings.hide()
	show()

func roll() -> void:
	var value := generator.randi()
	seed_field.text = str(value)
	status_label.text = "New seed rolled. Edit or copy it."

func copy_seed() -> void:
	if seed_field.text.strip_edges().is_empty():
		roll()
	DisplayServer.clipboard_set(seed_field.text.strip_edges())
	status_label.text = "Seed copied."

func submit() -> void:
	if achievements.visible or settings.visible:
		return
	var value := seed_field.text.strip_edges()
	if value.is_empty():
		roll()
		value = seed_field.text
	if not value.is_valid_int() or value.begins_with("-"):
		status_label.text = "Enter a whole number from 0 to 9223372036854775807."
		return
	if value.begins_with("+"):
		value = value.substr(1)
	while value.length() > 1 and value.begins_with("0"):
		value = value.substr(1)
	if value.length() > MAX_SEED.length() or (value.length() == MAX_SEED.length() and value > MAX_SEED):
		status_label.text = "Enter a whole number from 0 to 9223372036854775807."
		return
	seed_field.text = value
	seed_field.release_focus()
	hide()
	started.emit(value.to_int())

func add_label(rect: Rect2, font_size: int, color: Color, font: Font = null) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font != null:
		label.add_theme_font_override("font", font)
	add_child(label)
	return label

func add_button(rect: Rect2, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = caption
	button.add_theme_stylebox_override("normal", box("#252c31", "#665347"))
	button.add_theme_stylebox_override("hover", box("#34403f", "#af8b65"))
	button.add_theme_stylebox_override("pressed", box("#493744", "#c59869"))
	button.add_theme_stylebox_override("focus", box("#00000000", "#d4ac72"))
	button.add_theme_color_override("font_color", UI.CREAM)
	button.pressed.connect(action)
	add_child(button)
	return button

func box(fill: String, border: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(fill)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style
