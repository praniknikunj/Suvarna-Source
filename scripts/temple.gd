extends Node2D

const Dungeon = preload("res://scripts/dungeon.gd")
const Masonry = preload("res://scripts/stonework.gd")
const Art = preload("res://scripts/realm_art.gd")
const VajraTrial = preload("res://scripts/vajra_trial.gd")
const Mist = preload("res://assets/cinema_v2/valley_mist.png")
const FALLBACK = preload("res://assets/temple_depths.png")
const RANGES := [0.22, 0.62, 1.0]

var stone := Color("#735347")
var realm := 0
var camera_x := 0.0
var row := 0
var rooms: Dictionary = {}
var trial: VajraTrial
var trial_room := Vector2i.ZERO
var atmosphere := 0.0

func configure(info: Array, layout: Dictionary, index: int = 0) -> void:
	stone = Color(info[3])
	realm = index
	rooms = layout
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func scroll(x: float, level: int) -> void:
	camera_x = x
	row = level
	queue_redraw()

func _process(dt: float) -> void:
	atmosphere += dt
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#101521"))
	var sky := Art.realm(realm) if not rooms.is_empty() else FALLBACK
	if sky != null:
		var height := 498.0
		var width := ceilf(height * float(sky.get_width()) / float(sky.get_height()) / 2.0) * 2.0
		var drift := floorf(camera_x * RANGES[0] / 2.0) * 2.0
		var first := floori(drift / width)
		var shade := Color.WHITE.lerp(stone.lightened(0.35), 0.13 + abs(row) * 0.07)
		for i in range(first, first + ceili(960.0 / width) + 1):
			var mirror := posmod(i, 2) == 1
			draw_texture_rect(sky, Rect2(i * width - drift, -65.0 + row * 16.0,
				-width if mirror else width, height), false, shade)
	draw_rect(Rect2(0, 0, 960, 540), Color("#11152132"))
	var haze := fposmod(-camera_x * RANGES[1] + atmosphere * 8.0, 1024.0) - 1024.0
	for i in range(2):
		draw_texture_rect(Mist, Rect2(floorf(haze) + i * 1024, 318 + row * 9.0, 1024, 136), false, Color("#bebdb685"))
	for at in rooms:
		if at.y != row or rooms[at].hidden:
			continue
		var x: float = roundf(at.x * Dungeon.SIZE - camera_x)
		if x < -Dungeon.SIZE or x > Dungeon.SIZE:
			continue
		draw_gallery(x, rooms[at], trial != null and trial.active() and at == trial_room)

func draw_gallery(x: float, room: Dictionary, finale := false) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = room.seed
	var lip := stone.lerp(Color("#c6aa8c"), 0.63)
	var darkness := Color("#10121e").lerp(stone, 0.12)
	var falling := finale and trial.phase == VajraTrial.Phase.FALL
	if room.kind in ["intro_boss", "mini_boss", "boss", "side_boss"] and not falling:
		draw_sanctum_frame(x)
	if finale:
		draw_set_transform(Vector2(x, 0))
		trial.hands_background(self, atmosphere)
		draw_set_transform(Vector2.ZERO)
		if falling:
			draw_broken_sanctum(x, trial.age)
	var gap: Vector2 = room.get("gap", Vector2.ZERO)
	if gap == Vector2.ZERO:
		draw_terrain(x, Dungeon.FLOOR, Dungeon.SIZE, 116.0, random, false)
	else:
		draw_rect(Rect2(x + gap.x, Dungeon.FLOOR, gap.y - gap.x, 117), darkness)
		draw_terrain(x, Dungeon.FLOOR, gap.x, 116.0, random, false)
		draw_terrain(x + gap.y, Dungeon.FLOOR, Dungeon.SIZE - gap.y, 116.0, random, false)
		draw_line(Vector2(x + gap.x - 2, Dungeon.FLOOR + 11), Vector2(x + gap.x - 8, 479), lip.darkened(0.56), 3)
		draw_line(Vector2(x + gap.y, Dungeon.FLOOR + 7), Vector2(x + gap.y + 12, 470), lip.darkened(0.63), 3)
		for i in range(9):
			var p := Vector2(x + random.randi_range(int(gap.x) + 8, int(gap.y) - 8),
				445 + fposmod(i * 23.0 - atmosphere * (8 + i), 94.0)).floor()
			draw_rect(Rect2(p, Vector2(2, 2)), Color(lip, 0.20 + i % 2 * 0.24))
	for ledge in room.ledges:
		var slab: Rect2 = ledge
		draw_terrain(x + slab.position.x, slab.position.y, slab.size.x, 24, random, true)
	for slot in [137, 541, 883]:
		var y := random.randi_range(325, 384)
		draw_lamp(Vector2(x + slot, y), lip)
	for i in range(16):
		var p := Vector2(x + random.randi_range(0, 959),
			random.randi_range(162, 397) + sin(atmosphere * 0.42 + i) * 8.0).floor()
		draw_rect(Rect2(p, Vector2(2, 2)), Color(lip, 0.10 + (i % 4) * 0.035))
	if room.kind in ["arrival", "boss", "rest", "teacher"]:
		var p := Vector2(x + 483, 373)
		draw_line(p - Vector2(32, -33), p + Vector2(32, 33), Color(lip, 0.22), 1)
		for i in range(6):
			var bead := p + Vector2((i - 2.5) * 9, 28)
			draw_rect(Rect2(bead, Vector2(3, 4)), Color(lip, 0.47))

func draw_broken_sanctum(x: float, age: float) -> void:
	var arch := Masonry.art("arch")
	var slab := Masonry.art("slab")
	if arch == null or slab == null:
		return
	for side in [-1, 1]:
		for row_index in range(7):
			var away := maxf(0.0, age - 1.18 - row_index * 0.23)
			var y := 44.0 + row_index * 47.0 + away * away * (52.0 + row_index * 5.0)
			var at := Vector2(x + 480.0 + side * (406.0 - away * 43.0) - 21.0, y)
			draw_texture_rect_region(arch, Rect2(at.round(), Vector2(47, 55)),
				Rect2(8 if side < 0 else 81, 54, 25, 46), Color("#6c5456"))
	for index in range(22):
		var away := maxf(0.0, age - 0.94 - fmod(index * 1.23, 3.2))
		var y := -47.0 + fmod(index * 37.0, 99.0) + away * away * (34.0 + (index % 3) * 17.0)
		var at := Vector2(x + 89.0 + fmod(index * 99.0, 790.0) + sin(index * 1.52) * away * 35, y)
		draw_texture_rect_region(slab, Rect2(at.round(), Vector2(30 + index % 14, 18 + index % 5)),
			Rect2(1 + index % 5 * 7, 1, 26, 15), Color("#7c5750"))

func draw_sanctum_frame(x: float) -> void:
	var outer := Masonry.art("arch")
	var relief := Masonry.art("relief")
	if outer == null or relief == null:
		return
	var cool := Color("#38323d").lerp(stone.darkened(0.30), 0.31)
	var mounted := cool.lightened(0.23)
	for side in [0, 1]:
		var pier_x := x + (13.0 if side == 0 else Dungeon.SIZE - 64.0)
		var strip_x := 8.0 if side == 0 else 81.0
		for tier in range(4):
			var top := 95.0 + tier * 81.0
			draw_texture_rect_region(outer, Rect2(pier_x + 10.0, top, 40.0, 82.0), Rect2(strip_x, 54.0, 25.0, 46.0), cool)
			draw_texture_rect_region(relief, Rect2(pier_x + 9.0, top + 10.0, 43.0, 16.0), Rect2(8.0, 1.0, 33.0, 8.0), mounted)
		draw_texture_rect_region(relief, Rect2(pier_x, 400.0, 57.0, 26.0), Rect2(82.0, 45.0, 78.0, 17.0), mounted)
		var edge := pier_x + (50.0 if side == 0 else 10.0)
		draw_line(Vector2(edge, 103), Vector2(edge, 408), Color(mounted, 0.51), 1.0)
		var top_shade := Rect2(pier_x - 4.0, 70, 64.0, 29.0)
		draw_texture_rect_region(relief, top_shade, Rect2(15, 38, 64, 23), mounted)
func draw_terrain(x: float, y: float, span: float, height: float, random: RandomNumberGenerator, ledge: bool) -> void:
	var slab := Masonry.art("slab")
	var relief := Masonry.art("relief")
	if slab == null or relief == null:
		legacy_terrain(x, y, span, height, random, ledge)
		return
	var tint := Color("#b9b6be").lerp(stone.lightened(0.25), 0.34)
	var slab_height := 19.0 if ledge else 34.0
	draw_rect(Rect2(x, y, span, height), Color("#1a1720").lerp(stone, 0.16))
	if not ledge:
		var lower := y + slab_height - 6.0
		var fill := Color("#282730").lerp(stone.darkened(0.53), 0.37)
		var masonry := Art.texture("carved_floor")
		for row_index in range(5):
			var shift := -32.0 if row_index % 2 == 0 else 0.0
			var row_y := lower + row_index * 17.0
			while shift < span:
				var a := maxf(0.0, shift)
				var b := minf(span, shift + 60.0)
				var shade := fill.lightened(random.randf_range(-0.09, 0.13))
				if b > a:
					var block := Rect2(x + a, row_y, b - a, 15.0)
					draw_rect(block, shade.darkened(0.35))
					if masonry != null:
						var section := random.randi_range(0, 3) * 68
						draw_texture_rect_region(masonry, block, Rect2(section + 8, realm * 58 + 24 + row_index % 3 * 8,
							(block.size.x / 2.0), 8), Color("#aa9f9b").lerp(shade, 0.28))
					var seam := minf(block.size.x, float(random.randi_range(18, 55)))
					draw_rect(Rect2(block.position, Vector2(seam, 1)), Color(shade.lightened(0.28), 0.74))
				shift += 62.0
		var number := 2 if span > 580.0 else 1
		var total_piece := minf(span * 0.43, 251.0)
		for i in range(number):
			var left := 15.0 + (span - total_piece - 30.0) * (0.19 if i == 0 else 0.90)
			left = clampf(left + random.randf_range(-20.0, 20.0), 0.0, span - total_piece)
			tiled_stone(relief, Rect2(x + left, lower, total_piece, 75.0), total_piece,
				tint.darkened(0.21 + float(i) * 0.13))
	tiled_stone(slab, Rect2(x, y, span, slab_height), 143.0, tint)
	for i in range(0, int(span), 7):
		var width := minf(span - i, float(random.randi_range(2, 6)))
		if random.randf() > 0.50:
			draw_rect(Rect2(x + i, y, width, 1), Color("#e0bc8c", random.randf_range(0.12, 0.39)))
	if not ledge:
		for i in range(5):
			draw_rect(Rect2(x, y + height - (5 - i) * 7, span, 8), Color("#10101b", 0.06 + i * 0.055))

func tiled_stone(texture: Texture2D, bounds: Rect2, length: float, tint: Color) -> void:
	var offset := 0.0
	var size := Vector2(texture.get_size())
	while offset < bounds.size.x:
		var width := minf(length, bounds.size.x - offset)
		draw_texture_rect_region(texture, Rect2(bounds.position + Vector2(offset, 0), Vector2(width, bounds.size.y)),
			Rect2(0, 0, size.x * width / length, size.y), tint)
		offset += width

func legacy_terrain(x: float, y: float, span: float, height: float, random: RandomNumberGenerator, ledge: bool) -> void:
	var texture := Art.texture("carved_floor")
	var offset := 0.0
	if texture == null:
		draw_rect(Rect2(x, y, span, height), stone.darkened(0.31))
		return
	while offset < span:
		var width := minf(136.0, span - offset)
		var sector := random.randi_range(0, 3)
		var source := Rect2(sector * 68, realm * 58, width / 2.0, height / 2.0)
		draw_texture_rect_region(texture, Rect2(x + offset, y, width, height), source)
		offset += width
	if ledge:
		var seams := Color("#131520b4")
		draw_rect(Rect2(x + 5, y + 20, span - 10, 5), seams)
		for i in range(1, ceili(span / 46.0)):
			var q := Vector2(x + i * 43, y + 23)
			draw_rect(Rect2(q, Vector2(14, 7)), seams)
		draw_rect(Rect2(x + 4, y + 1, span - 8, 2), Color("#ddbb8d43"))

func draw_lamp(at: Vector2, lip: Color) -> void:
	var spark := absf(sin(atmosphere * 12.0 + at.x * 0.1))
	draw_rect(Rect2(at - Vector2(13, -5), Vector2(26, 4)), lip.darkened(0.36))
	draw_rect(Rect2(at - Vector2(9, -9), Vector2(18, 3)), lip.darkened(0.62))
	draw_rect(Rect2(at - Vector2(4, 0), Vector2(8, 5)), Color("#c6714d"))
	draw_rect(Rect2(at - Vector2(2, 7 + floorf(spark * 4)), Vector2(4, 10 + floorf(spark * 3))), Color("#fbc783"))
	draw_rect(Rect2(at + Vector2(-1, -3), Vector2(2, 5)), Color("#fff0b6"))
