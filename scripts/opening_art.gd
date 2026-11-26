extends RefCounted

const PrinceFrames = preload("res://scripts/anim_data.gd")
const PRINCE = preload("res://assets/indian_prince_sheet.png")
const GHATS = preload("res://assets/cinema_v2/black_ghats.png")
const CLOISTER = preload("res://assets/cinema_v2/processional.png")
const VOW = preload("res://assets/cinema_v2/sword_vow.png")
const MIST = preload("res://assets/cinema_v2/valley_mist.png")
const LETTERS = preload("res://assets/cinema_v2/lettering.png")
const WORDMARK = preload("res://assets/cinema_v2/suvarna_provided_wordmark.png")
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,/-' "
const PAPER := Color("#efdbb6")
const INK := Color("#090e17")
const FRAME := Rect2(0, 0, 960, 540)
const SCREEN := Vector2(480, 270)
const GROUND := 230.0

static func plate(canvas: CanvasItem, texture: Texture2D, camera: Vector2, mirror := false, color := Color.WHITE) -> void:
	var target := FRAME
	if mirror:
		target.size.x *= -1.0
	canvas.draw_texture_rect_region(texture, target, Rect2(camera.floor(), SCREEN), color)

static func opening(canvas: CanvasItem, shot: int, time: float) -> void:
	match shot:
		0: black_ghats(canvas, time)
		1: processional(canvas, time)
		2: sword_vow(canvas, time)

static func black_ghats(canvas: CanvasItem, time: float) -> void:
	var camera := Vector2(3 + floorf(time * 5.4), 6 + floorf(time * 0.9))
	plate(canvas, GHATS, camera)
	mist(canvas, time, 185)
	rain(canvas, time, false)
	# Far-off lamp pulses belong to the monastery plate rather than the camera.
	ember(canvas, Vector2(343, 144) - camera, time, 2.4)
	ember(canvas, Vector2(374, 147) - camera, time, 0.8)

static func processional(canvas: CanvasItem, time: float) -> void:
	var camera := Vector2(8 + floorf(time * 4.2), 7)
	plate(canvas, CLOISTER, camera)
	motes(canvas, time, 37, 154, 44, 120, Color("#c7d6de"), 0.29)
	ember(canvas, Vector2(192, 98) - camera, time, 0.4)
	ember(canvas, Vector2(407, 192) - camera, time, 1.6)
	ember(canvas, Vector2(493, 96) - camera, time, 4.9)

	var walk_time := clampf(time - 0.12, 0.0, 3.88)
	var feet := Vector2(103 + 59 * walk_time, GROUND) - camera
	var frame: Array = PrinceFrames.FR.walk[PrinceFrames.fidx("walk", walk_time * 1.04)]
	if time > 4.0:
		frame = PrinceFrames.FR.idle[PrinceFrames.fidx("idle", time - 4.0)]
	var region := Rect2(frame[0], frame[1], frame[2], frame[3])
	var bounds := Rect2((feet - Vector2(frame[4], frame[5]) * 0.57).round() * 2.0,
		(region.size * 0.57).round() * 2.0)
	pixel(canvas, feet - Vector2(15, 1), Vector2(32, 3), Color("#090f1bc1"))
	pixel(canvas, feet - Vector2(10, 0), Vector2(23, 1), Color("#080e17d9"))
	var torch := smoothstep(252.0, 374.0, feet.x)
	var grade := Color("#acb3c5").lerp(Color("#ffe3b9"), torch)
	canvas.draw_texture_rect_region(PRINCE, bounds, region, grade)

static func sword_vow(canvas: CanvasItem, time: float) -> void:
	var camera := Vector2(10 + floorf(time * 3.1), 9 + floorf(time * 0.72))
	plate(canvas, VOW, camera)
	ember(canvas, Vector2(481, 195) - camera, time, 2.57)
	motes(canvas, time, 389, 125, 75, 55, Color("#de994e"), 0.30)
	var sweep := inverse_lerp(0.98, 1.92, time)
	if sweep > 0.0 and sweep < 1.0:
		var at := Vector2(363 + sweep * 108.0, 223) - camera
		var strength := sin(sweep * PI)
		pixel(canvas, at, Vector2(6, 1), Color("#ffe9ba", strength * 0.86))
		pixel(canvas, at + Vector2(2, -1), Vector2(2, 3), Color("#fff2d1", strength * 0.62))

static func title(canvas: CanvasItem, time: float) -> void:
	var camera := Vector2(18 + floorf(sin(time * 0.27) * 12), 8 + floorf(cos(time * 0.32) * 3))
	plate(canvas, GHATS, camera, true, Color("#c3b5bb"))
	mist(canvas, time, 190)
	rain(canvas, time, true)
	canvas.draw_rect(FRAME, Color("#09111b24"))
	# Dither-height strips give the pixel scene a shaded margin for text.
	for x in range(0, 512, 4):
		var strength := 1.0 - smoothstep(48.0, 516.0, float(x))
		canvas.draw_rect(Rect2(x, 0, 4, 540), Color("#0b1019", strength * 0.56))

static func draw_wordmark(canvas: CanvasItem, at: Vector2) -> void:
	var width := 410.0
	var aspect := float(WORDMARK.get_height()) / float(WORDMARK.get_width())
	canvas.draw_texture_rect(WORDMARK, Rect2(at, Vector2(width, roundf(width * aspect))), false)

static func type(canvas: CanvasItem, value: String, at: Vector2, color := PAPER, scale_factor := 2) -> void:
	var word := value.to_upper()
	for i in range(word.length()):
		var glyph := ALPHABET.find(word[i])
		if glyph < 0 or word[i] == " ":
			continue
		var target := Rect2(at + Vector2(i * 6 * scale_factor, 0), Vector2(6, 8) * scale_factor)
		canvas.draw_texture_rect_region(LETTERS, target, Rect2(glyph * 6, 0, 6, 8), color)

static func mist(canvas: CanvasItem, time: float, y: int) -> void:
	var offset := floorf(fposmod(time * 6.0, 512.0)) - 512.0
	for copy in range(2):
		var pos := Vector2(offset + copy * 512.0, y + floorf(sin(time * 0.31) * 4.0))
		canvas.draw_texture_rect(MIST, Rect2(pos * 2.0, MIST.get_size() * 2.0), false)

static func rain(canvas: CanvasItem, time: float, backwards: bool) -> void:
	var side := 1 if backwards else -1
	for i in range(63):
		var speed := 66.0 + posmod(i * 13, 41)
		var at := Vector2(fposmod(i * 137.0 + time * speed * side * 0.21, 481.0),
			fposmod(i * 77.0 + time * speed, 271.0)).floor()
		var tint := Color("#a7b4d1", 0.08 + (i % 5) * 0.025)
		pixel(canvas, at, Vector2(1, 3 + i % 4), tint)
		pixel(canvas, at + Vector2(side, 3 + i % 4), Vector2(1, 3 + i % 4), tint)

static func ember(canvas: CanvasItem, at: Vector2, time: float, phase: float) -> void:
	var flare := 0.21 + (sin(time * 19.0 + phase) + sin(time * 31.0 + phase * 2.0)) * 0.072
	pixel(canvas, at - Vector2(1, 2), Vector2(3, 3), Color("#ffc56b", flare))
	for i in range(4):
		var age := fposmod(time * (0.38 + i * 0.07) + i * 0.26 + phase, 1.0)
		var p := at + Vector2(sin(age * 4.0 + phase + i) * (1 + i), -3.0 - age * (10.0 + i * 3.0))
		pixel(canvas, p, Vector2.ONE, Color("#ffc077", (1.0 - age) * 0.5))

static func motes(canvas: CanvasItem, time: float, x: int, y: int, width: int, height: int, tint: Color, opacity: float) -> void:
	for i in range(24):
		var p := Vector2(x + fposmod(i * 41.0 + time * (2.0 + i % 4), width),
			y + fposmod(i * 69.0 - time * (4.0 + i % 6), height))
		pixel(canvas, p, Vector2.ONE, Color(tint, opacity * (0.45 + 0.46 * sin(time * 1.4 + i))))

static func pixel(canvas: CanvasItem, at: Vector2, dimensions: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(at.round() * 2.0, dimensions * 2.0), color)
