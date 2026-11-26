extends RefCounted

const Pixels = preload("res://scripts/guardian_pixels.gd")
const FX = preload("res://scripts/combat_fx.gd")
const FLOOR := 424.0
const MAX_HP := 100
const HANDS_PER_ROUND := 20
const STRIKE_TIME := 2.0
const BELL_TIME := 5.0
const BELL_HITS := 5
const CENTRE := Vector2(480, 302)
const GOLD := Color("#edbf68")
const SHADOW := Color("#2e1b21")

enum Phase {NONE, SILENCE, RISE, HANDS, BELL_DROP, BELL_OPEN, BELL_BREAK, FALL}

var phase := Phase.NONE
var age := 0.0
var hp := MAX_HP
var slams := 0
var hits := 0
var round_index := 0
var target := 480.0
var locked := false
var impacted := false
var rematch := false

func active() -> bool:
	return phase != Phase.NONE

func cinematic() -> bool:
	return phase in [Phase.SILENCE, Phase.RISE, Phase.FALL]

func reset() -> void:
	phase = Phase.NONE
	age = 0.0

func enter(next: Phase) -> void:
	phase = next
	age = 0.0
	locked = false
	impacted = false

func begin(x: float, repeat: bool) -> void:
	rematch = repeat
	hp = MAX_HP
	slams = 0
	hits = 0
	round_index = 0
	target = x
	enter(Phase.SILENCE)

func hand_index() -> int:
	return posmod((round_index * HANDS_PER_ROUND + slams) * 17, 100)

func step(game, dt: float) -> void:
	age += dt
	match phase:
		Phase.SILENCE:
			if age >= 2.55:
				enter(Phase.RISE)
				game.sound("fall")
		Phase.RISE:
			if age >= 3.75:
				enter(Phase.HANDS)
				game.sound("wake")
				game.announce("Vajrakala   /   The Hundred Hands")
		Phase.HANDS:
			if not locked:
				target = clampf(game.position_on_floor.x, 88.0, 872.0)
				if age >= 0.88:
					locked = true
					game.sound("guard")
			if age >= 1.40 and not impacted:
				impacted = true
				game.sound("fall")
				game.mark_combat("quake", Vector2(target, FLOOR), 1.30)
				if absf(game.position_on_floor.x - target) <= 48.0 and game.position_on_floor.y > FLOOR - 57.0:
					game.hurt_by_guardian(target)
			if age >= STRIKE_TIME and game.state == "play":
				slams += 1
				if slams == HANDS_PER_ROUND:
					enter(Phase.BELL_DROP)
					game.sound("guard")
				else:
					enter(Phase.HANDS)
		Phase.BELL_DROP:
			if not locked:
				target = clampf(game.position_on_floor.x, 135.0, 825.0)
				locked = age >= 0.40
			if age >= 1.25:
				game.mark_combat("quake", Vector2(target, FLOOR), 1.6)
				game.sound("vajra")
				if absf(game.position_on_floor.x - target) <= 62.0 and game.position_on_floor.y > FLOOR - 130.0:
					game.hurt_by_guardian(target)
				hits = 0
				enter(Phase.BELL_OPEN)
				game.announce("Break the bell's five seals before it rises.")
		Phase.BELL_OPEN:
			if age >= BELL_TIME:
				if hits >= BELL_HITS:
					hp = maxi(0, hp - floori(MAX_HP / 10.0))
					game.sound("vajra")
				if hp <= 0:
					if rematch:
						reset()
						game.hundred_hands_defeated(true)
					else:
						enter(Phase.FALL)
				else:
					enter(Phase.BELL_BREAK)
		Phase.BELL_BREAK:
			if age >= 1.05:
				slams = 0
				round_index += 1
				enter(Phase.HANDS)
		Phase.FALL:
			if age >= 6.4:
				reset()
				game.hundred_hands_defeated(false)

func hit_bell(game, plane: Vector2, reach: float, direction: int) -> void:
	if phase != Phase.BELL_OPEN or hits >= BELL_HITS:
		return
	var dx := target - plane.x
	if absf(dx) > reach + 32.0 or dx * direction < -38.0 or plane.y < FLOOR - 122.0:
		return
	hits += 1
	game.sound("hit")
	game.mark_combat("spark", Vector2(target + 22 * (hits % 3 - 1), FLOOR - 44 - hits * 5), 0.91)

func height_offset() -> float:
	if phase == Phase.RISE:
		return (1.0 - smoothstep(0.0, 1.0, age / 3.65)) * 405.0
	if phase == Phase.FALL:
		return smoothstep(0.85, 5.9, age) * 350.0
	return 0.0

# Each arc is staggered against its neighbours, with its own apparent depth.
func perch(index: int, time: float) -> Vector2:
	var ring := floori(index / 20.0)
	var slot := index % 20
	var spacing := (slot + (0.36 if ring % 2 != 0 else 0.0)) / 19.36
	var angle := lerpf(-PI - 0.24, 0.24, spacing) + sin(index * 1.31) * 0.029
	var radius := Vector2(221.0 + ring * 48.0, 128.0 + ring * 34.5)
	var at := Vector2(CENTRE.x, 331.0) + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
	at.y += height_offset() + sin(time * 1.42 + index * 0.82) * (4.0 + ring * 1.45)
	at.x += cos(time * 1.11 + index * 0.53) * (2.0 + ring * 1.12)
	if phase == Phase.FALL:
		at.x += (at.x - CENTRE.x) * smoothstep(0.75, 5.4, age) * 0.24
	return at.round()

func hand_span(index: int) -> float:
	var depth := floori(index / 20.0)
	var silhouette: float = [0.96, 1.13, 1.02, 1.21, 0.94][index % 5]
	return (48.0 + depth * 16.0) * silhouette

func idle_pose(index: int) -> int:
	return [0, 1, 3, 1, 2, 0, 1, 2][posmod(index * 3 + floori(index / 20.0), 8)]

func draw_asset(canvas: CanvasItem, key: String, at: Vector2, size: Vector2, tint := Color.WHITE, flip := false, cel := 0, columns := 1) -> void:
	var tex := Pixels.atlas(key)
	if tex == null:
		return
	var cell := tex.get_size() / Vector2(columns, 1)
	var box := Rect2(at.round(), size.round())
	if flip:
		box.size.x *= -1.0
	canvas.draw_texture_rect_region(tex, box, Rect2(Vector2(cel * cell.x, 0), cell), tint)

func front_hand(start: Vector2) -> Vector2:
	var destination := Vector2(target, FLOOR - 87.0)
	if age < 0.88:
		return start - Vector2(0, sin(age / 0.88 * PI * 0.5) * 23.0)
	if age < 1.40:
		var t := smoothstep(0.88, 1.40, age)
		return (start - Vector2(0, 23)).lerp(destination, t) - Vector2(0, sin(t * PI) * 52.0)
	return destination.lerp(start, smoothstep(1.50, STRIKE_TIME, age))

func hovering_palms(canvas: CanvasItem, time: float, first: int, last: int, pull: int, fade: float) -> void:
	for index in range(first, last):
		if index == pull:
			continue
		var ring := floori(index / 20.0)
		var span := hand_span(index)
		var pos := perch(index, time)
		var light := 0.34 + ring * 0.12 + sin(time * 1.32 + index * 0.53) * 0.08
		draw_asset(canvas, "floating-palms", pos - Vector2.ONE * span * 0.5, Vector2.ONE * span,
			Color(light, light * 0.86, light * 0.76, fade * (0.73 + ring * 0.067)),
			index % 20 < 10, idle_pose(index), 6)

func hands_background(canvas: CanvasItem, time: float) -> void:
	if not active() or phase == Phase.SILENCE:
		return
	var offset := height_offset()
	var fade := 1.0 - (smoothstep(4.0, 6.4, age) * 0.72 if phase == Phase.FALL else 0.0)
	canvas.draw_rect(Rect2(0, 0, 960, FLOOR), Color(0.03, 0.014, 0.028, 0.63))
	var pull := -1 if phase != Phase.HANDS else hand_index()
	hovering_palms(canvas, time, 0, 60, pull, fade)
	var head_bob := roundf(sin(time * 1.81) * 3.0)
	var frame: int = [0, 1, 0, 2, 1, 3, 2, 0][posmod(floori(time * 5.6), 8)]
	draw_asset(canvas, "vajra-obscured", Vector2(239, 106.0 + offset + head_bob), Vector2(482, 326),
		Color(0.92, 0.80, 0.72, fade), false, frame, 4)
	hovering_palms(canvas, time, 60, 100, pull, fade)
	if pull >= 0:
		var start := perch(pull, time)
		var hit := front_hand(start).round()
		var extend := smoothstep(0.88, 1.39, age) * (1.0 - smoothstep(1.52, 2.0, age))
		var width := lerpf(hand_span(pull) * 1.06, 205.0, extend)
		var sz := Vector2.ONE * width
		var pose := idle_pose(pull)
		if age >= 0.88 and age < 1.69:
			pose = 4 if age >= 1.23 else 5
		draw_asset(canvas, "floating-palms", hit - sz * 0.5, sz,
			Color(1.0, 0.94, 0.81, fade), pull % 20 < 10, pose, 6)
	for band in range(9):
		var y := FLOOR - 90.0 + 10.0 * band
		canvas.draw_rect(Rect2(0, y, 960, 10), Color(0.034, 0.02, 0.041, 0.055 + band * 0.047))
	if phase == Phase.FALL:
		for i in range(43):
			var x := float(posmod(i * 233, 971))
			var start := fmod(i * 0.397, 4.45)
			var drift := maxf(0.0, age - start)
			var y := fmod(i * 33.14, 144.0) - 100.0 + drift * drift * (34.0 + i % 7)
			if drift > 0.0 and y < 540.0:
				draw_asset(canvas, "vajra-fragments", Vector2(x, y), Vector2(21 + i % 15, 17 + i % 11),
					Color(0.70, 0.46, 0.35, maxf(0.2, fade)), i % 2 == 0)

func bell_and_tells(canvas: CanvasItem) -> void:
	if phase == Phase.HANDS and age >= 0.45 and age < 1.60:
		FX.warning(canvas, target, FLOOR, 53, clampf((age - 0.42) / 0.96, 0.0, 1.0), GOLD)
	if phase == Phase.BELL_DROP:
		FX.warning(canvas, target, FLOOR, 62, age / 1.25, GOLD)
		var y := lerpf(-153.0, FLOOR - 136.0, smoothstep(0.42, 1.25, age))
		draw_asset(canvas, "vajra-bell", Vector2(target - 61.0, y), Vector2(122, 136))
	elif phase == Phase.BELL_OPEN:
		draw_asset(canvas, "vajra-bell", Vector2(target - 61, FLOOR - 136), Vector2(122, 136))
		for i in range(BELL_HITS):
			var color := GOLD if i >= hits else Color("#50303c")
			Pixels.stamp(canvas, "vajra_seal", i, Vector2(target + (i - 2) * 15, FLOOR - 82), Vector2(14, 14), color)
		canvas.draw_rect(Rect2(target - 40.0, FLOOR - 149.0, 80.0, 3.0), SHADOW)
		canvas.draw_rect(Rect2(target - 40.0, FLOOR - 149.0, 80.0 * maxf(0.0, 1.0 - age / BELL_TIME), 2.0), GOLD)
	elif phase in [Phase.BELL_BREAK, Phase.FALL]:
		for i in range(7):
			var drift := age * (1.0 + i % 3)
			var pos := Vector2(target + (i - 3) * (16.0 + drift * 14), FLOOR - 96.0 + drift * drift * 15)
			draw_asset(canvas, "vajra-fragments", pos, Vector2(37, 29), Color(1, 0.82, 0.56, maxf(0.0, 1.0 - age * 0.65)), i % 2 == 0)

func draw_smile(canvas: CanvasItem, time: float) -> void:
	canvas.draw_rect(Rect2(0, 0, 960, 540), Color("#09070d"))
	var light := smoothstep(0.55, 2.35, time) * (1.0 - smoothstep(3.6, 4.6, time))
	draw_asset(canvas, "vajra-smile", Vector2(265, 64), Vector2(430, 406), Color(0.58, 0.40, 0.36, light),
		false, clampi(floori((time - 0.9) * 1.60), 0, 3), 4)

