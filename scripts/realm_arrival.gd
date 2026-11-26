extends Control

signal ended
const Art = preload("res://scripts/realm_art.gd")
const Letter = preload("res://scripts/opening_art.gd")
const Lore = preload("res://scripts/realms.gd")
const Run = preload("res://scripts/pilgrimage.gd")
const LENGTH := 20.0
var realm := 0
var clock := 0.0
var segments: Array[String] = []
var voice := AudioStreamPlayer.new()
var font := preload("res://scripts/votive_ui.gd").display_font()

func _ready() -> void:
	size = Vector2(960, 540)
	z_index = 25
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(voice)
	voice.volume_db = -4.0
	hide()

func begin(index: int) -> void:
	realm = index
	clock = 0.0
	segments.clear()
	for sentence in Run.NARRATION[index][0].split(". ", false):
		segments.append(sentence.trim_suffix(".") + ".")
	var file := "res://assets/pilgrimage/voice/realm_%02d.wav" % index
	voice.stream = load(file) if ResourceLoader.exists(file) else null
	if voice.stream != null:
		voice.play()
	show()
	queue_redraw()

func skip() -> void:
	if visible:
		voice.stop()
		hide()
		ended.emit()

func _process(dt: float) -> void:
	if not visible:
		return
	clock += dt
	if clock >= LENGTH:
		skip()
	else:
		queue_redraw()

func _draw() -> void:
	var background := Art.realm(realm)
	var accent := Color(Run.ROSTERS[realm][4])
	draw_rect(Rect2(0, 0, 960, 540), Color("#0b111a"))
	if background != null:
		draw_texture_rect(background, Rect2(-28 - floorf(clock * 2.0), -10, 1058, 575), false, Color("#a5a2b2"))
	draw_rect(Rect2(0, 0, 960, 540), Color("#070a12a2"))
	for i in range(31):
		var at := Vector2(posmod(i * 113, 960) + sin(clock * 0.7 + i) * 23.0,
			fposmod(i * 71.0 - clock * (9.0 + (i % 7)), 540.0))
		draw_rect(Rect2((at / 2.0).floor() * 2.0, Vector2(2 + 2 * int(i % 4 == 0), 2)), Color(accent, 0.16 + (i % 5) * 0.06))
	var visible_ink := smoothstep(0.25, 2.4, clock)
	var crop := Vector2(478.0 - floorf(clock * 1.6), 427)
	var silhouette_scale := minf(2.35, 405.0 / Art.BOSS_HEIGHTS[realm])
	Art.boss(self, realm, crop + Vector2(-5, -2), silhouette_scale, -1, Color(accent, visible_ink * 0.44))
	Art.boss(self, realm, crop, silhouette_scale, -1, Color("#04070d", visible_ink * 0.98))
	for band in range(6):
		draw_rect(Rect2(0, 404 + band * 12, 960, 12), Color("#070a12", 0.29 + band * 0.08))
	draw_rect(Rect2(0, 476, 960, 64), Color("#080d15"))
	var title: String = Lore.REALMS[realm][0]
	var strength := smoothstep(0.85, 2.8, clock)
	Letter.type(self, "REALM %02d  /  %s" % [realm + 1, Lore.REALMS[realm][1]], Vector2(42, 36), Color(accent, strength))
	draw_caption(title, 284, 50, Color("#ead5ac", strength))
	draw_caption(Run.NARRATION[realm][1], 323, 17, Color("#e1bd91", strength))

	var subtitle := ""
	var span := voice.stream.get_length() if voice.stream != null else 16.5
	if not segments.is_empty():
		var index := mini(floori(clock * segments.size() / maxf(1.0, span)), segments.size() - 1)
		subtitle = segments[index]
	draw_caption(subtitle, 461, 18, Color("#efdebd"))
	Letter.type(self, "ENTER SKIP", Vector2(850, 506), Color("#bb9e81"), 1)
	draw_rect(Rect2(42, 510, 174, 2), Color("#353242"))
	draw_rect(Rect2(42, 510, floorf(174.0 * clock / LENGTH), 2), accent)
	var fade := 1.0 - smoothstep(0.0, 0.65, clock) * smoothstep(0.0, 0.48, LENGTH - clock)
	draw_rect(Rect2(0, 0, 960, 540), Color("#070a12", fade))

func draw_caption(caption: String, y: float, size_px: int, color: Color) -> void:
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	draw_string(font, Vector2(floorf(480.0 - width / 2.0), y), caption,
		HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)
