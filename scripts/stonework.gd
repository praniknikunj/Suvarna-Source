extends RefCounted

const PATH := "res://assets/pilgrimage/masonry/"
static var images: Dictionary = {}

static func art(name: String) -> Texture2D:
	if not images.has(name):
		var path := PATH + name + ".png"
		images[name] = load(path) if ResourceLoader.exists(path) else null
	return images[name]

static func gate(canvas: CanvasItem, foot: Vector2, bars: float, tint: Color, stair := 0) -> void:
	var arch := art("arch")
	var grate := art("grate")
	var width := 112.0 if stair == 0 else 96.0
	var height := 158.0 if stair == 0 else 134.0
	var left := floorf(foot.x - width * 0.5)
	var top := foot.y - height
	var field := Rect2(foot.x - width * 0.202, foot.y - height * 0.59, width * 0.404, height * 0.58)
	canvas.draw_rect(field.grow(2), Color("#111019"))
	if grate != null and bars > 0.005:
		var full := Vector2(grate.get_width(), grate.get_height())
		var visible := Rect2(0, full.y * (1.0 - bars), full.x, full.y * bars)
		canvas.draw_texture_rect_region(grate, Rect2(field.position, Vector2(field.size.x, field.size.y * bars)), visible, tint)
	if arch != null:
		canvas.draw_texture_rect(arch, Rect2(left, top, width, height), false, tint)
	else:
		var edge := tint.lerp(Color("#5b4541"), 0.65)
		for i in range(6):
			var row_width := width - 9.0 * i
			var y := top + 8.0 * (5 - i)
			canvas.draw_rect(Rect2(foot.x - row_width / 2.0, y, row_width, 8), edge.darkened(0.38))
			canvas.draw_rect(Rect2(foot.x - row_width / 2.0 - 2, y + 1, row_width + 4, 2), edge.lightened(0.24))
		for offset in [-1, 1]:
			var pier: float = foot.x + float(offset) * (width * 0.34) - 10.0
			canvas.draw_rect(Rect2(pier, top + 43, 20, height - 43), edge)
			canvas.draw_rect(Rect2(pier + 2, top + 45, 4, height - 45), edge.lightened(0.22))
	if grate == null and bars > 0.005:
		for i in range(8):
			var x := field.position.x + i * field.size.x / 7.0
			canvas.draw_rect(Rect2(x, field.position.y, 3, field.size.y * bars), Color("#544139"))
			canvas.draw_rect(Rect2(x, field.position.y, 1, field.size.y * bars), Color("#967053"))
	if stair != 0:
		for i in range(5):
			var span := 43.0 - 7.0 * i
			canvas.draw_rect(Rect2(foot.x - span / 2.0, foot.y - 4.0 - i * 4.0, span, 2), Color(tint, 0.56 - i * 0.08))

static func wall(canvas: CanvasItem, x: float, baseline: float, tint: Color) -> void:
	var shade := tint.lerp(Color("#221d23"), 0.65)
	canvas.draw_rect(Rect2(x, 89, 27, baseline - 89), shade.darkened(0.43))
	canvas.draw_rect(Rect2(x + 4, 89, 17, baseline - 89), shade)
	for y in range(99, int(baseline) - 5, 19):
		var varied := float((y * 19) % 11) - 5.0
		canvas.draw_rect(Rect2(x + 3, y, 21, 2), shade.darkened(0.53))
		canvas.draw_rect(Rect2(x + 6, y + 2, 13 + varied, 1), shade.lightened(0.21))
		canvas.draw_rect(Rect2(x + 18, y + 3, 2, 12), shade.darkened(0.24))
	canvas.draw_rect(Rect2(x - 3, baseline - 12, 33, 6), shade.lightened(0.16))
	canvas.draw_rect(Rect2(x - 4, baseline - 5, 35, 4), shade.darkened(0.4))

static func pedestal(canvas: CanvasItem, at: Vector2, tint: Color) -> void:
	var relief := art("relief")
	var slab := art("slab")
	var bounds := Rect2(at + Vector2(-37, -27), Vector2(74, 27))
	canvas.draw_rect(bounds, tint.darkened(0.62))
	if relief != null:
		canvas.draw_texture_rect_region(relief, bounds, Rect2(20, 6, 82, 53), tint)
	if slab != null:
		canvas.draw_texture_rect(slab, Rect2(at + Vector2(-45, -33), Vector2(90, 10)), false, tint.lightened(0.22))
	else:
		canvas.draw_rect(Rect2(at + Vector2(-44, -31), Vector2(88, 7)), tint)
