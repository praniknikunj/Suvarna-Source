extends RefCounted

const POSE_COLS := 8
const CELL := Vector2(48, 48)
const MATERIALS := ["cleaver", "lotus_petals", "forge_lance", "blind_echo", "silk_veil", "mirror_edge",
	"venom_drop", "temple_brass", "crown_tooth", "vajra_seal", "ash_lantern", "lotus_spear",
	"root_hook", "bone_idol", "spoked_wheel", "oath_steel", "moon_glaive", "inverted_lotus",
	"healing_ray", "seal_stone", "royal_spark"]
static var sprites: Dictionary = {}

static func atlas(name: String) -> Texture2D:
	if not sprites.has(name):
		var path := "res://assets/guardians/" + name + ".png"
		if ResourceLoader.exists(path):
			sprites[name] = load(path)
	return sprites.get(name)

static func stamp(canvas: CanvasItem, style: String, frame: int, centre: Vector2, size_px: Vector2, tint := Color.WHITE, facing := 1) -> void:
	var texture := atlas("signature-effects")
	var row := MATERIALS.find(style)
	if texture == null or row < 0:
		return
	var destination := Rect2((centre - size_px * 0.5).round(), size_px.round())
	if facing < 0:
		destination.size.x *= -1.0
	var source := Rect2(Vector2(posmod(frame, POSE_COLS), row) * CELL, CELL)
	canvas.draw_texture_rect_region(texture, destination, source, tint)

static func cleaver(canvas: CanvasItem, at: Vector2, frame: int, direction: int) -> void:
	var texture := atlas("kaalan-cleaver")
	if texture == null:
		stamp(canvas, "cleaver", frame, at, Vector2(82, 78), Color.WHITE, direction)
		return
	var area := Rect2((at - Vector2(42, 41)).round(), Vector2(84, 82))
	if direction > 0:
		area.size.x *= -1.0
	canvas.draw_texture_rect_region(texture, area, Rect2(Vector2(posmod(frame, 8) * 48, 0), Vector2(48, 48)))

static func icon(canvas: CanvasItem, index: int, at: Vector2, size_px: float, tint := Color.WHITE) -> void:
	var texture := atlas("passage-icons")
	if texture == null:
		return
	var source := Rect2(Vector2(posmod(index, 5), floori(index / 5.0)) * 32, Vector2(32, 32))
	canvas.draw_texture_rect_region(texture, Rect2(at.round(), Vector2.ONE * size_px), source, tint)

static func milestone(canvas: CanvasItem, depth: int, at: Vector2, size_px: float) -> void:
	var hue := fposmod(float(depth / 100) * 0.1375, 1.0)
	icon(canvas, 14, at, size_px, Color.from_hsv(hue, 0.52, 1.0))

