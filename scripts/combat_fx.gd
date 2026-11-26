extends RefCounted

const SHEET = preload("res://assets/encounters/attack-effects.png")
const CELL := Vector2(64, 48)
const ROW := {
	"cut": 0, "pierce": 1, "impact": 2, "dust": 3, "crack": 4, "wave": 5,
	"wave_air": 6, "pillar": 7, "link": 8, "weight": 9, "halo": 10, "burst": 11,
	"ember": 12, "petal": 13, "lance": 14, "echo": 15, "orbit": 16, "mirror": 17,
	"venom": 18, "bell": 19, "wheel": 20, "script": 21, "rain": 22, "read": 23
}
const CENTER := Vector2(32, 24)
const SOLE := Vector2(32, 42)

static func cel(canvas: CanvasItem, strip: String, step: int, at: Vector2, anchor: Vector2,
		scale_px: Vector2, tint: Color, face := 1, transpose := false, upside_down := false) -> void:
	var source := Rect2(Vector2(clampi(step, 0, 7), ROW[strip]) * CELL, CELL)
	var size := CELL * scale_px
	var pivot := anchor * scale_px
	if transpose:
		size = Vector2(size.y, size.x)
		pivot = Vector2(pivot.y, pivot.x)
	if face < 0:
		pivot.x = size.x - pivot.x
	if upside_down:
		pivot.y = size.y - pivot.y
	var target := Rect2((at - pivot).round(), size.round())
	if face < 0:
		target.size.x *= -1.0
	if upside_down:
		target.size.y *= -1.0
	canvas.draw_texture_rect_region(SHEET, target, source, tint, transpose)

static func shadow(canvas: CanvasItem, feet: Vector2, width: float, strength := 1.0) -> void:
	for i in range(3):
		var span := roundf(width * (1.0 - 0.20 * absf(i - 1)))
		canvas.draw_rect(Rect2((feet + Vector2(-span / 2.0, i * 2 - 2)).round(), Vector2(span, 2)),
			Color("#110d18", 0.18 * strength + (0.27 * strength if i == 1 else 0.0)))

static func blade(canvas: CanvasItem, from: Vector2, direction: int, reach: float,
		progress: float, accent: Color, thrust := false) -> void:
	if progress < 0.0 or progress >= 1.0:
		return
	var width := clampf(reach / 43.0, 0.63, 3.05)
	var height := (0.71 if thrust else clampf(width * 0.79, 0.79, 1.89))
	var tint := Color.WHITE.lerp(accent, 0.33)
	cel(canvas, "pierce" if thrust else "cut", floori(progress * 8.0), from,
		Vector2(12, 26), Vector2(width, height), tint, direction)

static func dust(canvas: CanvasItem, at: Vector2, age: float, color: Color, spread: float) -> void:
	if age < 0.0 or age >= 0.51:
		return
	cel(canvas, "dust", floori(age * 8.0 / 0.51), at, SOLE,
		Vector2(1.5 * spread, 1.03 * sqrt(spread)), Color.WHITE.lerp(color, 0.44))

static func impact(canvas: CanvasItem, mark: Dictionary) -> void:
	var age: float = mark.age
	var type: String = mark.kind
	var status := clampf(age / float(mark.life), 0.0, 0.999)
	var index := floori(status * 8.0)
	var scale: float = mark.scale
	var tint: Color = Color.WHITE.lerp(mark.tint, 0.31)
	var at: Vector2 = mark.at
	match type:
		"quake":
			if status < 0.72:
				cel(canvas, "impact", floori(status * 10.5), at, SOLE,
					Vector2(1.88, 1.53) * scale, Color.WHITE.lerp(mark.tint, 0.18))
			if status > 0.09:
				cel(canvas, "dust", index, at, SOLE, Vector2(2.18, 0.82) * scale, Color(tint, 0.76))
			cel(canvas, "crack", index, at, SOLE, Vector2(1.88, 1.05) * scale, tint)
		"ground":
			if status < 0.64:
				cel(canvas, "impact", floori(status * 11.0), at, SOLE,
					Vector2(1.49, 1.31) * scale, tint)
			cel(canvas, "crack", index, at, SOLE, Vector2(1.50, 1.07) * scale, tint)
		"dust":
			cel(canvas, "dust", index, at, SOLE, Vector2(1.18, 1.04) * scale, tint)
		_:
			cel(canvas, "burst", index, at, CENTER, Vector2.ONE * scale, tint)

static func warning(canvas: CanvasItem, x: float, floor_y: float, size: float, ratio: float, tint: Color) -> void:
	var cast := Color(Color.WHITE.lerp(tint, 0.53), 0.82)
	cel(canvas, "read", floori(clampf(ratio, 0.0, 0.999) * 8.0), Vector2(x, floor_y),
		SOLE, Vector2(maxf(0.4, size / 18.0), 1.10), cast)

static func charge_glow(canvas: CanvasItem, at: Vector2, ratio: float, accent: Color) -> void:
	if ratio < 0.35:
		return
	var size := lerpf(0.21, 0.66, (ratio - 0.35) / 0.65)
	cel(canvas, "halo", floori(ratio * 7.0), at, CENTER,
		Vector2.ONE * size, Color(Color.WHITE.lerp(accent, 0.52), lerpf(0.19, 0.78, ratio)))

static func royal_tether(canvas: CanvasItem, hand: Vector2, crown: Vector2, accent: Color) -> void:
	var segments := maxi(4, ceili(hand.distance_to(crown) / 9.0))
	for i in range(segments):
		var t := float(i) / segments
		var point := hand.lerp(crown, t) + Vector2(0, sin(PI * t) * 15.0)
		var color := Color.WHITE.lerp(accent, 0.62).darkened(0.18 + 0.08 * (i % 2))
		cel(canvas, "link", i % 2, point, CENTER, Vector2(0.64, 0.64), color)

static func chain_summon(canvas: CanvasItem, hand: Vector2, gate: Vector2, ratio: float, metal: Color) -> void:
	var pulse := smoothstep(0.46, 0.96, ratio)
	for index in range(3):
		var step := pulse - float(index) * 0.17
		if step > 0.0 and step < 1.0:
			var point := hand.lerp(gate, step) - Vector2(0.0, sin(step * PI) * 21.0)
			var tint := Color(Color.WHITE.lerp(metal, 0.44), (0.74 - index * 0.17) * sin(step * PI))
			cel(canvas, "burst", 1 + index, point, CENTER, Vector2.ONE * (0.30 - index * 0.05), tint)
	if pulse > 0.55:
		var tint := Color(Color.WHITE.lerp(metal, 0.52), smoothstep(0.55, 1.0, pulse) * 0.68)
		cel(canvas, "halo", 4, gate, CENTER, Vector2(0.70, 0.29), tint)

static func projectile(canvas: CanvasItem, shot: Dictionary, floor_y: float) -> void:
	var p: Vector2 = shot.at
	var motion: Vector2 = shot.velocity
	var color: Color = Color.WHITE.lerp(shot.color, 0.42)
	var age: float = shot.age
	var style: String = shot.style
	var phase := floori(age * 17.0)
	var frame := posmod(phase, 8)
	match style:
		"chain":
			var top: float = shot.get("anchor_y", 111.0)
			var links := maxi(0, floori((p.y - top - 4.0) / 12.0))
			cel(canvas, "halo", frame, Vector2(p.x, top), CENTER, Vector2(0.70, 0.29), Color(color, 0.48))
			for i in range(links):
				var dot := Vector2(p.x + 3.0 * sin(i * 0.35 + age * 6.0), p.y - i * 12.0 - 13.0)
				cel(canvas, "link", (i + phase) % 2, dot, CENTER, Vector2(0.94, 1.0), color)
			var lift := 1.14 if not shot.get("settled", false) else 1.00
			cel(canvas, "weight", frame, p, Vector2(31, 34), Vector2(1.19, lift), color)
		"surge":
			var rise := maxf(4.0, floor_y - p.y)
			cel(canvas, "pillar", frame, Vector2(p.x, floor_y), SOLE,
				Vector2(1.27, rise / 39.0), color)
			if age < 0.24:
				cel(canvas, "burst", floori(age * 28.0), p + Vector2(0.0, 3.0), CENTER,
					Vector2(0.85, 0.74), Color(color, 0.88))
		"wave":
			cel(canvas, "wave", frame, Vector2(p.x, floor_y), SOLE, Vector2(1.20, 1.10),
				color, -1 if motion.x < 0.0 else 1)
		"wave_air":
			cel(canvas, "wave_air", frame, p, CENTER, Vector2(1.0, 0.89),
				color, -1 if motion.x < 0.0 else 1)
		_:
			var vertical := absf(motion.y) > absf(motion.x) * 1.23 and style in ["rain", "lance", "mirror", "petal"]
			var size := maxf(0.57, float(shot.r) / 8.0)
			var c := style if ROW.has(style) else "ember"
			cel(canvas, c, frame, p, CENTER, Vector2.ONE * size, color,
				-1 if not vertical and motion.x < 0.0 else 1, vertical, vertical and motion.y < 0.0)
