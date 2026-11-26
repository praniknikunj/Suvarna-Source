extends RefCounted

const BRASS := Color("#ceac73")
const PATINA := Color("#7aa79d")
const SHADOW := Color("#10131b")
const CREAM := Color("#ece0be")

static func display_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = ["Georgia", "Noto Serif", "serif"]
	return font

static func diamond(canvas: CanvasItem, point: Vector2, radius: float, color: Color, outline := false) -> void:
	var shape := PackedVector2Array([point + Vector2(0, -radius), point + Vector2(radius, 0),
		point + Vector2(0, radius), point - Vector2(radius, 0)])
	if outline:
		shape.append(shape[0])
		canvas.draw_polyline(shape, color, 1.0, true)
	else:
		canvas.draw_colored_polygon(shape, color)

static func flame(canvas: CanvasItem, point: Vector2, scale: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([point + Vector2(0, -8) * scale,
		point + Vector2(2, -3) * scale, point + Vector2(4, 0) * scale, point + Vector2(2, 3) * scale,
		point + Vector2(-2, 3) * scale, point + Vector2(-4, 0) * scale,
		point + Vector2(-2, -2) * scale]), color)

static func lotus(canvas: CanvasItem, point: Vector2, scale: float, color: Color) -> void:
	var leaf := PackedVector2Array([Vector2(0, 1), Vector2(-3, -4), Vector2(0, -12),
		Vector2(3, -4), Vector2(0, 1)])
	for angle in [-0.98, -0.48, 0.0, 0.48, 0.98]:
		var petal := PackedVector2Array()
		for vertex in leaf:
			petal.append(point + vertex.rotated(angle) * scale)
		canvas.draw_polyline(petal, color, 1.0, true)
	canvas.draw_line(point + Vector2(-8, 5) * scale, point + Vector2(8, 5) * scale, color, 1.0, true)
	diamond(canvas, point + Vector2(0, 8) * scale, 1.8 * scale, color)

static func engraved(canvas: CanvasItem, rect: Rect2, fill: Color = SHADOW, edge: Color = BRASS) -> void:
	var a := rect.position
	var b := rect.end
	var bevel := minf(12.0, rect.size.y * 0.23)
	var shape := PackedVector2Array([a + Vector2(bevel, 0), Vector2(b.x - bevel, a.y),
		Vector2(b.x, a.y + bevel), b - Vector2(0, bevel), b - Vector2(bevel, 0),
		Vector2(a.x + bevel, b.y), Vector2(a.x, b.y - bevel), a + Vector2(0, bevel)])
	canvas.draw_colored_polygon(shape, fill)
	shape.append(shape[0])
	canvas.draw_polyline(shape, edge, 1.0, true)

static func rule(canvas: CanvasItem, a: Vector2, b: Vector2, color: Color) -> void:
	canvas.draw_line(a, b, Color(color, color.a * 0.62), 1.0, true)
	diamond(canvas, a, 2.0, color)
	diamond(canvas, b, 2.0, color)

static func pin(canvas: CanvasItem, at: Vector2, shade: Color) -> void:
	canvas.draw_rect(Rect2(at - Vector2(3, 2), Vector2(6, 4)), shade.darkened(0.48))
	canvas.draw_rect(Rect2(at - Vector2(2, 3), Vector2(4, 6)), shade)
	canvas.draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), shade.lightened(0.37))

static func sun(canvas: CanvasItem, at: Vector2, radius: float, shade: Color, filled := true) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var distance := radius if i % 2 == 0 else radius * 0.78
		points.append((at + Vector2.from_angle(TAU * i / 24.0) * distance).round())
	canvas.draw_colored_polygon(points, shade.darkened(0.54))
	points.append(points[0])
	canvas.draw_polyline(points, shade, 1.0)
	canvas.draw_circle(at, radius * 0.62, Color("#120e17") if filled else shade.darkened(0.62))

static func lacquer_meter(canvas: CanvasItem, rect: Rect2, current: float, delayed: float, rim: Color) -> void:
	var p := rect.position
	var length := rect.size.x
	var height := rect.size.y
	canvas.draw_rect(rect.grow(2), Color("#100e17ee"))
	canvas.draw_rect(rect.grow(1), rim.darkened(0.43))
	canvas.draw_rect(rect, Color("#35242b"))
	canvas.draw_rect(Rect2(p, Vector2(floorf(length * clampf(delayed, 0.0, 1.0)), height)), Color("#b8785c"))
	var filled := floorf(length * clampf(current, 0.0, 1.0))
	if filled > 0.0:
		canvas.draw_rect(Rect2(p, Vector2(filled, height)), Color("#a02e3d"))
		canvas.draw_rect(Rect2(p, Vector2(filled, 2)), Color("#d57e63"))
		canvas.draw_rect(Rect2(p + Vector2(0, height - 2), Vector2(filled, 2)), Color("#63213a"))
	canvas.draw_line(p - Vector2(0, 2), p + Vector2(length, -2), rim, 1.0)
	pin(canvas, p + Vector2(length + 3, floorf(height / 2.0)), rim)
