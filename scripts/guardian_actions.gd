extends RefCounted

const Dungeon = preload("res://scripts/dungeon.gd")
const Sequence = preload("res://scripts/attack_sequence.gd")
const Patterns = preload("res://scripts/guardian_signatures.gd")
const Pixels = preload("res://scripts/guardian_pixels.gd")
const FX = preload("res://scripts/combat_fx.gd")
const FLOOR := Dungeon.FLOOR

static func prepare(enemy: Dictionary, side: int) -> void:
	enemy.pattern = {"mask":0, "side": side, "launch":enemy.x, "blade":Vector2.ZERO,
		"embedded":false, "visible":false, "blink_x":enemy.x, "decoy":false, "jump":0.0}

static func pattern(enemy: Dictionary) -> Dictionary:
	if not enemy.has("pattern"):
		prepare(enemy, enemy.direction)
	return enemy.pattern

static func once(p: Dictionary, position: float, threshold: float, key: int) -> bool:
	if position < threshold or (int(p.mask) & (1 << key)) != 0:
		return false
	p.mask = int(p.mask) | (1 << key)
	return true

static func x_limit(x: float) -> float:
	return clampf(x, 82.0, 878.0)

static func focus(enemy: Dictionary) -> float:
	return x_limit(float(enemy.target))

static func target_columns(enemy: Dictionary, style: String, rage: bool) -> Array[float]:
	var target := focus(enemy)
	var x: float = enemy.x
	var side: int = pattern(enemy).side
	var points: Array[float] = []
	match style:
		"lotus_lattice":
			for slot in [-3, -2, -1, 1, 2, 3]:
				points.append(x_limit(target + slot * 106.0))
		"blind_bells":
			points.assign([target, x_limit(target + side * 115.0), x_limit(target - side * 98.0)])
		"lotus_lances":
			points.assign([target, x_limit(target - side * 85), x_limit(target + side * 100)])
		"root_ambush":
			points.assign([x_limit(target - 61.0), x_limit(target + 61.0), target])
		"bone_grid":
			points.assign([x_limit(target - 126), target, x_limit(target + 126)])
		"crown_siege":
			var safe := x_limit(x + enemy.direction * 149.0)
			for slot in range(1, 8):
				var at := 108.0 * slot + 49.0
				if absf(at - safe) > 69.0:
					points.append(at)
			if rage:
				points.reverse()
		"lightning_weave", "vajra_seals":
			var gate := int(round(target / 122.0))
			for slot in range(1, 8):
				if slot != gate and (slot + (int(enemy.timeline.serial) % 2)) % 2 == 0:
					points.append(slot * 122.0)
		"veil_snare":
			points.assign([x_limit(target + side * 114), x_limit(target - side * 148)])
		"forge_gallop":
			points.assign([x_limit(target - side * 125), x_limit(target + side * 108)])
		"false_tell", "oath_pursuit", "reflection_rush":
			points.assign([target, x_limit(target + side * 91)])
		"venom_coils", "shed_skin":
			points.assign([target - 72, target, target + 72])
		"moon_feint":
			points.assign([x_limit(target - side * 40), x_limit(target + side * 79)])
		_:
			points.append(target)
	# Adjacent clamped columns should never stack into one brighter, ambiguous hit.
	var unique: Array[float] = []
	for at in points:
		var clipped := x_limit(at)
		if not unique.any(func(prior: float) -> bool: return absf(prior - clipped) < 24.0):
			unique.append(clipped)
	return unique

static func projectile(game, origin: Vector2, v: Vector2, art: String, opts := {}) -> Dictionary:
	game.add_projectile(origin, v, opts.get("style", "sig_shot"), opts.get("radius", 11.0),
		opts.get("gravity", 0.0), opts.get("life", 2.1), 33, opts.get("cuttable", false), opts.get("delay", 0.0), true)
	var shot: Dictionary = game.projectiles.back()
	shot.art = art
	shot.heading = -1 if v.x < 0 else 1
	shot.turn_at = opts.get("turn_at", -1.0)
	shot.born = origin
	shot.top_y = opts.get("top", 216.0)
	shot.spin = opts.get("spin", 0.0)
	shot.floor_contact = opts.get("floor_contact", false)
	return shot

static func pillar(game, x: float, art: String, delay := 0.0, top := 236.0, radius := 24.0) -> void:
	projectile(game, Vector2(x, FLOOR), Vector2.ZERO, art,
		{"style":"sig_column", "radius":radius, "top":top, "life":0.52, "delay":delay})

static func ground(game, x: float, speed: float, art: String, delay := 0.0) -> void:
	projectile(game, Vector2(x, FLOOR - 12.0), Vector2(speed, 0), art,
		{"style":"wave", "life":2.5, "delay":delay, "radius":14.0})

static func aim_arc(game, origin: Vector2, x: float, flight: float, gravity: float, art: String) -> void:
	var target := Vector2(x_limit(x), FLOOR - 12.0)
	var speed := (target - origin) / flight - Vector2(0.0, gravity * flight * 0.5)
	projectile(game, origin, speed, art, {"gravity":gravity, "life":flight + 0.27, "floor_contact":true})

static func stroke(game, enemy: Dictionary, span: float, air := false) -> void:
	var player: Vector2 = game.position_on_floor
	var dx: float = (player.x - enemy.x) * enemy.direction
	if dx >= -23.0 and dx <= span and absf(player.y - enemy.y) < (78.0 if air else 58.0) and not enemy.hit:
		enemy.hit = true
		game.hurt_by_guardian(enemy.x)

static func sprint(game, enemy: Dictionary, target: float, speed: float, dt: float) -> void:
	var difference: float = target - enemy.x
	if absf(difference) > 2.0:
		enemy.direction = int(signf(difference))
	var limit: Vector2 = game.guardian_lane(enemy)
	enemy.x = move_toward(float(enemy.x), clampf(target, limit.x, limit.y), speed * dt)

static func run(game, enemy: Dictionary, move: Dictionary, moment: float, dt: float, rage: bool) -> void:
	var p := pattern(enemy)
	var key: String = move.signature
	var art: String = move.material
	var x := focus(enemy)
	var strength := 1.19 if rage else 1.0
	var side: float = p.side
	var socket: Vector2 = game.attack_socket(enemy, Sequence.clip(move.kind, "active"), moment)
	var marks := target_columns(enemy, key, rage)
	match key:
		"bell_crater":
			game.advance_bell_drop(enemy, move, clampf(moment * 1.14, 0.0, 0.9999))
			if once(p, moment, 0.86, 0):
				for index in [-1, 1]:
					pillar(game, x_limit(x + index * 135), art, 0.11, 305.0, 22.0)
			return
		"cleaver_throw":
			throw_cleaver(game, enemy, p, moment, socket, x)
			return
		"lotus_lattice":
			if once(p, moment, 0.24, 0):
				for i in range(marks.size()):
					pillar(game, marks[i], art, 0.10 * i, 241.0, 22.0)
			if once(p, moment, 0.59, 1):
				for offset in [-170, -85, 85, 170]:
					aim_arc(game, socket, x + offset, 0.72, 320.0, art)
		"forge_gallop":
			if once(p, moment, 0.18, 0):
				for i in range(marks.size()):
					pillar(game, marks[i], art, i * 0.16, 256.0, 19.0)
			if moment > 0.23 and moment < 0.88:
				sprint(game, enemy, (914.0 if side > 0 else 46.0) if moment < 0.57 else x, 442.0 * strength, dt)
				stroke(game, enemy, 79.0)
		"blind_bells":
			p.decoy = moment < 0.75
			if once(p, moment, 0.20, 0):
				for i in range(marks.size()):
					pillar(game, marks[i], art, 0.22 * i, 177.0, 21.0)
			if once(p, moment, 0.72, 1):
				enemy.x = x_limit(x - side * 120)
				p.blink_x = enemy.x
				p.decoy = false
		"veil_snare":
			if once(p, moment, 0.26, 0):
				projectile(game, Vector2(48, 322), Vector2(315, -7), art, {"radius":22.0})
				projectile(game, Vector2(912, 374), Vector2(-325, 0), art, {"radius":21.0, "delay":0.32})
			if once(p, moment, 0.60, 1):
				for at in marks:
					pillar(game, at, art, 0.07, 290.0, 19.0)
		"mirror_duet", "reflection_rush":
			p.blink_x = x_limit(x + side * 110.0)
			p.decoy = moment < 0.62
			if once(p, moment, 0.18, 0):
				projectile(game, Vector2(p.blink_x, FLOOR - 52.0), Vector2(-side * 430.0, 0), art,
					{"radius":15.0, "life":0.51})
			if moment > 0.51 and moment < 0.91:
				sprint(game, enemy, x + side * 84.0, 550.0 * strength, dt)
				stroke(game, enemy, 78.0, key == "reflection_rush")
		"venom_coils":
			if once(p, moment, 0.19, 0):
				for i in range(marks.size()):
					aim_arc(game, socket, marks[i], 0.68 + i * 0.16, 510.0, art)
			if moment > 0.63 and moment < 0.95:
				sprint(game, enemy, x - side * 20.0, 346.0 * strength, dt)
				stroke(game, enemy, 86.0)
		"bell_cadence":
			if once(p, moment, 0.18, 0):
				var source: float = game.wave_origin_x(enemy)
				for direction in [-1, 1]:
					ground(game, source, direction * 319.0 * strength, art)
			if once(p, moment, 0.57, 1):
				for direction in [-1, 1]:
					projectile(game, Vector2(enemy.x, FLOOR - 91), Vector2(direction * 399.0, 0), art, {"radius":17.0})
				pillar(game, x, art, 0.18, 282.0, 28.0)
		"crown_siege":
			if once(p, moment, 0.16, 0):
				for i in range(marks.size()):
					pillar(game, marks[i], art, i * 0.16, 158.0, 21.0)
			if once(p, moment, 0.63, 1):
				var safe: Vector2 = game.guard_point(enemy)
				projectile(game, Vector2(90, 246), Vector2(510, 0), art, {"radius":16.0})
				game.mark_combat("spark", safe, 1.10)
		"vajra_seals", "lightning_weave":
			if once(p, moment, 0.16, 0):
				for i in range(marks.size()):
					pillar(game, marks[i], art, 0.16 * i, 137.0, 21.0)
			if once(p, moment, 0.63, 1):
				var height := FLOOR - (88.0 if int(enemy.timeline.serial) % 2 == 0 else 30.0)
				projectile(game, Vector2(910 if side < 0 else 50, height), Vector2(side * 524, -9), art, {"radius":20.0, "life":1.6})
		"ash_lanterns":
			for beat in range(3):
				if once(p, moment, 0.15 + 0.24 * beat, beat):
					aim_arc(game, socket, x + side * (beat - 1) * 95.0, 0.64 + beat * 0.09, 430.0, art)
					if beat == 2:
						ground(game, enemy.x, side * 300.0, art)
		"lotus_lances":
			for beat in range(marks.size()):
				if once(p, moment, 0.16 + 0.25 * beat, beat):
					pillar(game, marks[beat], art, 0.06, 265.0, 18.0)
			if moment > 0.69 and moment < 0.92:
				sprint(game, enemy, x - side * 22.0, 305, dt)
				stroke(game, enemy, 67.0)
		"ember_return":
			if once(p, moment, 0.25, 0):
				projectile(game, socket, Vector2(side * 455.0, -45), art, {"turn_at":0.45, "radius":15.0, "life":1.04})
			if moment > 0.60 and moment < 0.90:
				sprint(game, enemy, x - side * 92.0, 331.0, dt)
				stroke(game, enemy, 69.0)
		"root_ambush":
			p.decoy = moment < 0.66
			if once(p, moment, 0.25, 0):
				for i in range(marks.size()):
					pillar(game, marks[i], art, 0.14 * i, 276.0, 20.0)
			if once(p, moment, 0.66, 1):
				enemy.x = x_limit(x + side * 118)
		"bone_grid":
			if once(p, moment, 0.20, 0):
				for i in range(marks.size()):
					projectile(game, Vector2(marks[i], 108), Vector2((i - 1) * 38.0, 360),
						art, {"radius":16.0, "life":1.1, "floor_contact":true})
			if once(p, moment, 0.62, 1):
				ground(game, enemy.x, side * 370.0, art)
		"false_tell":
			p.blink_x = x_limit(x - side * 68.0)
			p.decoy = moment < 0.49
			if once(p, moment, 0.48, 0):
				enemy.x = x_limit(x + side * 107.0)
				enemy.direction = -int(side)
			if moment > 0.62 and moment < 0.86:
				sprint(game, enemy, x + side * 35.0, 315.0, dt)
				stroke(game, enemy, 74.0)
		"shed_skin":
			p.decoy = moment < 0.62
			if once(p, moment, 0.20, 0):
				p.blink_x = enemy.x
				sprint(game, enemy, enemy.x + 115.0 * side, 8000, dt)
			if once(p, moment, 0.48, 1):
				for i in range(marks.size()):
					aim_arc(game, socket, marks[i], 0.58 + 0.13 * i, 590, art)
			if moment > 0.72:
				stroke(game, enemy, 70.0)
		"ash_weather":
			if once(p, moment, 0.23, 0):
				for i in range(6):
					var spawn := Vector2(65.0 + 147.0 * i, 81.0 + 20.0 * (i % 2))
					projectile(game, spawn, Vector2(130.0 * side, 230.0), art,
						{"radius":14.0, "delay":i * 0.10, "floor_contact":true})
		"wheel_relay":
			if once(p, moment, 0.22, 0):
				projectile(game, Vector2(enemy.x, FLOOR - 30.0), Vector2(side * 450, 0), art,
					{"turn_at":0.50, "life":1.45, "radius":21.0, "spin":11.0})
			if once(p, moment, 0.61, 1):
				projectile(game, Vector2(enemy.x, FLOOR - 88.0), Vector2(side * 408, 4), art,
					{"turn_at":0.63, "life":1.40, "radius":17.0, "spin":11.0})
		"oath_pursuit":
			if moment > 0.23 and moment < 0.56:
				sprint(game, enemy, x + side * 97, 497, dt)
				stroke(game, enemy, 63.0)
			if once(p, moment, 0.62, 0):
				enemy.hit = false
				projectile(game, Vector2(enemy.x, FLOOR - 61.0), Vector2(-side * 465, 0),
					art, {"radius":15.0, "life":0.67})
		"counter_chime":
			if once(p, moment, 0.28, 0):
				projectile(game, socket, Vector2(side * 380.0, -110), art,
					{"radius":18.0, "gravity":235.0, "floor_contact":true})
			if once(p, moment, 0.65, 1):
				for direction in [-1, 1]:
					ground(game, enemy.x, direction * 360.0, art)
		"moon_feint":
			enemy.y = FLOOR - 110.0 * sin(clampf(moment * 1.13, 0.0, 1.0) * PI)
			if moment > 0.19 and moment < 0.78:
				sprint(game, enemy, x + side * 114.0, 405, dt)
				stroke(game, enemy, 64.0, true)
			if once(p, moment, 0.70, 0):
				projectile(game, socket, Vector2(-side * 335, 160.0), art,
					{"radius":20.0, "gravity":150.0, "floor_contact":true})
	if p.mask != 0:
		enemy.released = true

static func throw_cleaver(game, enemy: Dictionary, p: Dictionary, moment: float, emitter: Vector2, x: float) -> void:
	if once(p, moment, 0.16, 0):
		p.blade = emitter
		p.weapon_start = emitter
		p.weapon_end = x_limit(x + p.side * 55.0)
		p.visible = true
		enemy.released = true
		game.sound("slash")
	if not p.visible:
		return
	var edge := Vector2(float(p.weapon_end), FLOOR - 15.0)
	if moment < 0.53:
		var t := smoothstep(0.16, 0.53, moment)
		var start: Vector2 = p.weapon_start
		p.blade = start.lerp(edge, t) - Vector2(0, sin(t * PI) * 66.0)
		if (game.position_on_floor - Vector2(0, 36)).distance_to(p.blade) < 39.0:
			game.hurt_by_guardian(p.blade.x)
	elif not p.embedded:
		p.embedded = true
		p.blade = edge
		game.mark_combat("ground", edge + Vector2(0, 15), 0.89)
		game.sound("fall")
	if once(p, moment, 0.57, 1):
		p.dash_start = enemy.x
		enemy.direction = -1 if edge.x < float(enemy.x) else 1
		game.sound("dodge")
	if p.has("dash_start"):
		var lunge := smoothstep(0.57, 0.94, moment)
		enemy.x = lerpf(p.dash_start, edge.x, lunge)
		stroke(game, enemy, 46.0)
		if moment >= 0.94:
			p.visible = false
			game.mark_combat("spark", edge, 0.86)

static func draw_tell(canvas: CanvasItem, enemy: Dictionary, move: Dictionary, ratio: float, realm_tint: Color) -> void:
	var key: String = move.signature
	var art: String = move.material
	if key in ["lotus_lattice", "forge_gallop", "blind_bells", "veil_snare", "crown_siege", "vajra_seals",
			"lotus_lances", "root_ambush", "bone_grid", "lightning_weave", "false_tell", "venom_coils", "shed_skin",
			"reflection_rush", "oath_pursuit", "moon_feint"]:
		for at in target_columns(enemy, key, float(enemy.hp) <= float(enemy.max_hp) * 0.52):
			FX.warning(canvas, at, FLOOR, 24.0, ratio, realm_tint)
			Pixels.stamp(canvas, art, int(ratio * 7.0), Vector2(at, FLOOR - 25.0), Vector2(29, 22),
				Color.WHITE.lerp(realm_tint, 0.35) * Color(1, 1, 1, 0.49 + ratio * 0.40))
	elif key == "cleaver_throw":
		var side: float = pattern(enemy).side
		FX.warning(canvas, x_limit(focus(enemy) + side * 55.0), FLOOR, 35.0, ratio, realm_tint)
		FX.charge_glow(canvas, Vector2(enemy.x + 44.0 * side, FLOOR - 68.0), ratio, realm_tint)
	elif key in ["bell_cadence", "counter_chime"]:
		Pixels.stamp(canvas, "temple_brass", int(ratio * 7.0), Vector2(enemy.x - 24, FLOOR - 100),
			Vector2(67, 67), Color(1, 1, 1, ratio))

static func draw_action(canvas: CanvasItem, enemy: Dictionary, move: Dictionary, moment: float) -> void:
	var p := pattern(enemy)
	if move.signature == "cleaver_throw" and p.visible:
		var frame := 2 if p.embedded else floori(moment * 23.0)
		Pixels.cleaver(canvas, p.blade, frame, p.side)
	if move.signature in ["false_tell", "mirror_duet", "reflection_rush"] and p.decoy:
		Pixels.stamp(canvas, "mirror_edge", floori(moment * 16.0), Vector2(p.blink_x, FLOOR - 58.0),
			Vector2(88, 110), Color("#c8b7e096"), -p.side)
	if move.signature == "shed_skin" and p.decoy:
		Pixels.stamp(canvas, "venom_drop", floori(moment * 9.0), Vector2(p.blink_x, FLOOR - 45.0),
			Vector2(95, 100), Color("#b4bd76a5"))

