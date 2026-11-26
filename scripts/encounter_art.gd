extends RefCounted

const FRAME_COUNT := 8
const PX_SCALE := 2.0
const BOSS_SCALES := [1.08, 1.25, 1.12, 1.08, 1.10, 1.05, 1.09, 1.10, 1.10, 1.45]
const CLIPS := ["idle", "move", "wake", "windup", "slash", "thrust", "cast", "guard", "recover", "hit", "death", "expose",
	"ready_blade", "ready_lunge", "ready_cast", "ready_slam", "smash", "dive", "bash",
	"recover_blade", "recover_lunge", "recover_cast", "recover_slam", "recover_dive", "recover_bash"]
const FRAME_RATES := [8.0, 12.0, 8.0, 12.0, 18.0, 18.0, 14.0, 8.0, 12.0, 18.0, 9.0, 12.0,
	12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0, 12.0]
const LOOPS := ["idle", "move", "guard"]
const MOB_CELL := Vector2(112, 76)
const MINI_CELL := Vector2(148, 108)
const BOSS_CELL := Vector2(192, 156)
const PATH := "res://assets/encounters"
const FALLBACK = preload("res://assets/enemy_sprites.png")
const Pivots = preload("res://scripts/attack_sockets.gd")
const TerrainArt = preload("res://scripts/realm_art.gd")

static var cached_textures: Dictionary = {}

static func canonical_clip(clip: String) -> String:
	match clip:
		"attack", "sweep", "slam", "waves": return "slash"
		"charge", "jump", "lunge": return "thrust"
		"fan", "pillars", "chain", "rain": return "cast"
		"recovery": return "recover"
		"weak", "vulnerable": return "expose"
		_: return clip if CLIPS.has(clip) else "idle"

static func duration(_kind: String, clip: String) -> float:
	return FRAME_COUNT / FRAME_RATES[CLIPS.find(canonical_clip(clip))]

static func key(kind: String, realm: int) -> String:
	return "intro" if kind == "intro" else "%s_%02d" % [kind, posmod(realm, 10)]

static func cell_size(kind: String) -> Vector2:
	if kind == "boss":
		return BOSS_CELL
	if kind in ["mini", "intro"]:
		return MINI_CELL
	return MOB_CELL

static func texture(kind: String, realm: int) -> Texture2D:
	var id := key(kind, realm)
	if cached_textures.has(id):
		var existing: Texture2D = cached_textures[id]
		cached_textures.erase(id)
		cached_textures[id] = existing
		return existing
	var path := ("res://assets/guardians/duelist_%02d.png" % realm) if kind == "side" else "%s/%s/%s.png" % [PATH, kind, id]
	if not ResourceLoader.exists(path):
		return null
	var sheet: Texture2D = load(path)
	if cached_textures.size() >= 12:
		cached_textures.erase(cached_textures.keys()[0])
	cached_textures[id] = sheet
	return sheet

static func draw(canvas: CanvasItem, kind: String, realm: int, feet: Vector2, direction: int, animation: String, elapsed: float,
		scale_factor := 1.0, tint := Color.WHITE) -> void:
	var clip := canonical_clip(animation)
	var rate: float = FRAME_RATES[CLIPS.find(clip)]
	var tick := maxi(0, floori(elapsed * rate))
	var frame := posmod(tick, FRAME_COUNT) if LOOPS.has(clip) else mini(tick, FRAME_COUNT - 1)
	draw_frame(canvas, kind, realm, feet, direction, clip, frame, scale_factor, tint)

static func draw_frame(canvas: CanvasItem, kind: String, realm: int, feet: Vector2, direction: int, animation: String, frame: int,
		scale_factor := 1.0, tint := Color.WHITE, strip: Texture2D = null) -> void:
	var clip := canonical_clip(animation)
	var sheet := texture(kind, realm) if strip == null else strip
	if sheet == null:
		draw_fallback(canvas, kind, realm, feet, direction, clip, frame, scale_factor, tint)
		return
	var atlas_cell := cell_size(kind)
	var source := Rect2(Vector2(clampi(frame, 0, FRAME_COUNT - 1), 0 if strip != null else CLIPS.find(clip)) * atlas_cell, atlas_cell)
	var scale := PX_SCALE * scale_factor
	var anchor := Vector2(atlas_cell.x / 2.0, atlas_cell.y - 15.0)
	var target := Rect2((feet - anchor * scale).round(), (atlas_cell * scale).round())
	if direction > 0:
		target.size.x *= -1
	canvas.draw_texture_rect_region(sheet, target, source, tint)

static func socket(kind: String, realm: int, feet: Vector2, direction: int, pose: String, frame: int, factor := 1.0) -> Vector2:
	var authored: Dictionary = Pivots.POINTS.get(key(kind, realm), {})
	var points: Array = authored.get(pose, [])
	var offset := Vector2(-14, -28) if points.is_empty() else Vector2(points[clampi(frame, 0, FRAME_COUNT - 1)])
	return (feet + Vector2(offset.x * -direction, offset.y) * PX_SCALE * factor).round()

static func draw_fallback(canvas: CanvasItem, kind: String, realm: int, feet: Vector2, direction: int, clip: String, frame: int,
		scale_factor: float, tint: Color) -> void:
	if kind in ["boss", "mini", "intro"]:
		TerrainArt.boss(canvas, realm, feet, (1.0 if kind == "boss" else 0.65) * scale_factor, direction, tint)
		return
	var row := 0 if kind == "flying" else (2 if kind == "ranged" else 1)
	var column := 0
	if clip.begins_with("ready_") or clip in ["windup", "guard", "wake"]:
		column = 3
	elif clip in ["slash", "thrust", "cast", "smash", "dive", "bash"]:
		column = 4
	elif clip in ["death", "recover", "hit"]:
		column = 5
	elif clip in ["idle", "move"]:
		column = [0, 1, 0, 2][frame / 2]
	var tint_for_type := Color("#c5b282") if kind == "tank" else Color.WHITE
	var scale := (1.35 if kind == "flying" else 1.74) * scale_factor
	var source := Rect2(column * 72, row * 56, 72, 56)
	var target := Rect2((feet - Vector2(36, 51) * scale).round(), Vector2(72, 56) * scale)
	if direction > 0:
		target.size.x *= -1.0
	canvas.draw_texture_rect_region(FALLBACK, target, source, tint * tint_for_type)

static func draw_core(canvas: CanvasItem, realm: int, center: Vector2, elapsed: float, scale_factor := 1.0,
		tint := Color.WHITE) -> void:
	var id := "core_%02d" % realm
	var path := "%s/boss/%s.png" % [PATH, id]
	if not cached_textures.has(id):
		if not ResourceLoader.exists(path):
			canvas.draw_circle(center, 9.0 * scale_factor, tint)
			return
		cached_textures[id] = load(path)
	var sheet: Texture2D = cached_textures[id]
	var source := Rect2(posmod(floori(elapsed * 12.0), 8) * 42, 0, 42, 34)
	var scale := PX_SCALE * scale_factor
	var target := Rect2((center - Vector2(21, 16) * scale).round(), (source.size * scale).round())
	canvas.draw_texture_rect_region(sheet, target, source, tint)
