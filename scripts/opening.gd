extends Control

signal ended

const Art = preload("res://scripts/opening_art.gd")
const SCENE_SECONDS := 4.4
const CHAPTERS := [
	["I / THE BLACK GHATS", ["ASH FELL OVER THE MONASTERY.", "THEN THE LAST BELL FELL SILENT."]],
	["II / THE NAMELESS PRINCE", ["SUVARNA RETURNED WITHOUT HIS CROWN.",
		"AT THE GATE, NO ONE SPOKE HIS NAME."]],
	["III / THE LAST VOW", ["HE LAID DOWN HIS SWORD.", "THE TEMPLE ANSWERED."]]
]
var clock := 0.0
var ambience := AudioStreamPlayer.new()

func _ready() -> void:
	size = Vector2(960, 540)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 30
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ambience)
	ambience.stream = preload("res://assets/cinema_v2/opening_ambience.wav")
	ambience.volume_db = -2.0
	hide()

func begin() -> void:
	clock = 0.0
	show()
	ambience.play()
	queue_redraw()

func skip() -> void:
	if visible:
		ambience.stop()
		hide()
		ended.emit()

func _process(dt: float) -> void:
	if not visible:
		return
	clock += dt
	if clock >= CHAPTERS.size() * SCENE_SECONDS:
		skip()
		return
	queue_redraw()

func _draw() -> void:
	var index := mini(floori(clock / SCENE_SECONDS), CHAPTERS.size() - 1)
	var time := fmod(clock, SCENE_SECONDS)
	Art.opening(self, index, time)
	var strength := smoothstep(0.03, 0.44, time) * smoothstep(0.0, 0.36, SCENE_SECONDS - time)
	draw_rect(Rect2(0, 0, 960, 540), Color("#090c14", 1.0 - strength))
	for band in range(12):
		var alpha := float(band + 1) * 0.064
		draw_rect(Rect2(0, 428 + band * 8, 960, 8), Color("#080c15", alpha))
	for band in range(6):
		draw_rect(Rect2(0, band * 8, 960, 8), Color("#080c15", (6 - band) * 0.10))

	var caption_alpha := smoothstep(0.38, 0.9, time) * smoothstep(0.12, 0.51, SCENE_SECONDS - time)
	Art.type(self, CHAPTERS[index][0], Vector2(40, 22), Color("#edb783", caption_alpha * 0.93))
	for i in range(2):
		var line: String = CHAPTERS[index][1][i]
		var at := Vector2(480.0 - line.length() * 6.0, 460 + i * 20)
		Art.type(self, line, at + Vector2(2, 2), Color("#080b12", caption_alpha))
		Art.type(self, line, at, Color(Art.PAPER, caption_alpha))
	for i in range(CHAPTERS.size()):
		var shade := Color("#c79a72") if i == index else Color("#614b49")
		draw_rect(Rect2(456 + i * 18, 521, 10, 2), shade)
	Art.type(self, "ENTER / ESC SKIP", Vector2(844, 520), Color("#b8a68d"), 1)
