extends RefCounted

const PIER = "res://assets/pilgrimage/pier.png"
const FLOOR_CELL := Vector2(68, 58)
const BOSS_HEIGHTS := [174.0, 182.0, 166.0, 154.0, 162.0, 110.0, 252.0, 254.0, 268.0, 224.0]
static var cache: Dictionary = {}

static func texture(file: String) -> Texture2D:
	if not cache.has(file):
		cache[file] = load("res://assets/pilgrimage/" + file + ".png")
	return cache[file]

static func realm(index: int) -> Texture2D:
	return texture("realm_%02d" % index)

static func boss(canvas: CanvasItem, index: int, feet: Vector2, factor: float, direction: int, tint := Color.WHITE) -> void:
	var image := texture("guardian_%02d" % index)
	if image == null:
		return
	var size := image.get_size()
	var target: Vector2 = (size * (BOSS_HEIGHTS[index] * factor / size.y)).round()
	var frame := Rect2((feet - Vector2(target.x / 2.0, target.y)).round(), target)
	if direction > 0:
		frame.size.x *= -1.0
	canvas.draw_texture_rect(image, frame, false, tint)

static func regional_mob(canvas: CanvasItem, index: int, feet: Vector2, height: float, direction: int, tint := Color.WHITE) -> void:
	var image := texture("retainer_%02d" % index)
	if image == null:
		return
	var size := image.get_size()
	var target: Vector2 = (size * height / size.y).round()
	var frame := Rect2((feet - Vector2(target.x / 2.0, target.y)).round(), target)
	if direction > 0:
		frame.size.x *= -1.0
	canvas.draw_texture_rect(image, frame, false, tint)
