extends RefCounted

const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const SIZE := 960.0
const FLOOR := 424.0
const STAIR_X := 725.0
const EXIT_X := 890.0
const STAGES_PER_REALM := 10
const MINIBOSS_STAGE := 9
const BOSS_STAGE := 10
const MINIBOSS_WAKE_X := 699.0
const NO_SEAL := Vector2i(-1, -1)
const SEAL_SOURCES := ["shrine", "vow", "pilgrim", "secret"]
const GATE_KINDS := ["exit", "healing_shrine", "intro_boss", "mini_boss", "boss", "side_boss"]
const BASIC_ENCOUNTERS := ["vowguard", "gorgon"]

static func realm_stage(floor_number: int) -> int:
	return posmod(floor_number - 1, STAGES_PER_REALM) + 1

static func generate(rng: RandomNumberGenerator, floor_number := 1, _boss_floor := false, endless := false, roaming_mini := false) -> Dictionary:
	if floor_number <= 0:
		return intro_layout(floor_number)
	var stage := realm_stage(floor_number)
	var boss_floor := stage == BOSS_STAGE
	var mini_floor := roaming_mini if endless else stage == MINIBOSS_STAGE
	var rooms := {}
	var length := rng.randi_range(4, 5 if mini_floor else 6) + int(boss_floor)
	for x in range(length):
		add_room(rooms, Vector2i(x, 0), rng)
		if x > 0:
			connect_rooms(rooms, Vector2i(x - 1, 0), 1)
	rooms[Vector2i.ZERO].kind = "arrival"
	var gate := Vector2i(length - 1, 0)
	if mini_floor:
		var approach := Vector2i(length, 0)
		add_room(rooms, approach, rng)
		connect_rooms(rooms, gate, 1)
		rooms[approach].kind = "corridor"
		rooms[approach].ledges = []
		gate = Vector2i(length + 1, 0)
		add_room(rooms, gate, rng)
		connect_rooms(rooms, approach, 1)
		rooms[gate].kind = "mini_boss"
		rooms[gate].wake_x = MINIBOSS_WAKE_X
		add_encounter(rooms[gate], "mini_boss", 775.0)
	elif boss_floor:
		rooms[gate].kind = "boss"
		rooms[gate].wake_x = 354.0
		add_encounter(rooms[gate], "boss", 685.0)
	else:
		rooms[gate].kind = "exit"
	rooms[gate].ledges = []
	rooms[gate].exit_x = EXIT_X

	var junction := rng.randi_range(1, length - 3)
	var return_x := mini(junction + rng.randi_range(1, 2), length - 2)
	var lower_x := rng.randi_range(1, length - 2)
	var upper_start := Vector2i(junction, -1)
	var upper_end := Vector2i(return_x, -1)
	for x in range(junction, return_x + 1):
		add_room(rooms, Vector2i(x, -1), rng)
		if x > junction:
			connect_rooms(rooms, Vector2i(x - 1, -1), 1)
	connect_rooms(rooms, Vector2i(junction, 0), 0)
	connect_rooms(rooms, Vector2i(return_x, 0), 0)
	var lower := Vector2i(lower_x, 1)
	add_room(rooms, lower, rng)
	connect_rooms(rooms, Vector2i(lower_x, 0), 2)
	var lower_turn := -1 if lower_x > 1 and rng.randf() < 0.5 else 1
	var annex := lower + Vector2i(lower_turn, 0)
	add_room(rooms, annex, rng)
	connect_rooms(rooms, lower, 3 if lower_turn < 0 else 1)

	var recess := upper_end + Vector2i.RIGHT
	add_room(rooms, recess, rng)
	connect_rooms(rooms, upper_end, 1)
	rooms[recess].kind = "secret"
	rooms[recess].hidden = not endless

	rooms[upper_start].kind = "archive"
	rooms[upper_end].kind = "reliquary"
	rooms[lower].kind = "teacher" if posmod(floor_number, 3) == 0 or boss_floor else "rest"
	rooms[annex].kind = "shrine"
	var seal_type: String = SEAL_SOURCES[rng.randi_range(0, SEAL_SOURCES.size() - 1)]
	if floor_number == 1:
		seal_type = "shrine"
	elif stage in [7, 8, BOSS_STAGE] and rng.randf() < 0.28:
		seal_type = "elite"
	var seal_room: Vector2i = recess if seal_type == "secret" else [upper_start, annex][rng.randi_range(0, 1)]
	rooms[seal_room].kind = seal_type
	rooms[seal_room].seal = true
	if seal_room == upper_start:
		rooms[annex].kind = "archive"
	if seal_type == "elite":
		add_encounter(rooms[seal_room], "shield", 716.0)
		add_encounter(rooms[seal_room], "gorgon", 390.0)

	if endless:
		rooms[seal_room].seal = false
		seal_room = NO_SEAL
	if boss_floor or stage == 5:
		var haven: Vector2i = gate + Vector2i.LEFT if boss_floor else Vector2i(length - 2, 0)
		rooms[haven].kind = "rest_shrine"
		rooms[haven].ledges = []
		rooms[haven].erase("gap")
		# Put the altar on the side opposite the stair entrance.
		rooms[haven].shrine_x = 462.0
	for at: Vector2i in rooms:
		if rooms[at].kind == "hall":
			assign_floor_encounters(rooms[at], at, (maxi(stage, 6) if endless else stage))
	return {
		"rooms": rooms, "gate": gate, "seal_room": seal_room, "intro": "",
		"spawn_x": 172.0, "gate_x": EXIT_X, "stage": stage
	}

static func side_duel(rng: RandomNumberGenerator) -> Dictionary:
	var rooms := {}
	add_room(rooms, Vector2i.ZERO, rng)
	add_room(rooms, Vector2i.RIGHT, rng)
	connect_rooms(rooms, Vector2i.ZERO, 1)
	var entry: Dictionary = rooms[Vector2i.ZERO]
	entry.kind = "quest_passage"
	entry.ledges = []
	entry.erase("gap")
	var arena: Dictionary = rooms[Vector2i.RIGHT]
	arena.kind = "side_boss"
	arena.ledges = []
	arena.erase("gap")
	arena.exit_x = EXIT_X
	arena.wake_x = 326.0
	add_encounter(arena, "side_boss", 668.0)
	return {"rooms":rooms, "gate":Vector2i.RIGHT, "seal_room":NO_SEAL, "spawn_x":172.0, "gate_x":EXIT_X}

static func intro_layout(floor_number: int) -> Dictionary:
	var rooms := {}
	var start := Vector2i.ZERO
	var gate := start
	var spawn_x := 172.0
	var gate_x := EXIT_X
	var section := ""
	match floor_number:
		-2:
			section = "tutorial"
			gate = Vector2i.RIGHT
			rooms[start] = make_room("tutorial", 2919, [Rect2(619, 359, 152, 13)], 0)
			rooms[start].gap = Vector2(485, 601)
			rooms[start].lessons = [
				{"x": 172.0, "text": "LEFT / RIGHT  Move"},
				{"x": 419.0, "text": "UP  Jump the break"},
				{"x": 689.0, "text": "UP onto the ledge   /   DOWN to drop"}
			]
			rooms[gate] = make_room("exit", 2920, [Rect2(530, 362, 138, 13)], 1)
			rooms[gate].lessons = [
				{"x": 184.0, "text": "X  Slash    V  Thrust    Shift  Dodge"},
				{"x": 435.0, "text": "P  Pause   /   UP or DOWN to select"},
				{"x": 817.0, "text": "E  Enter"}
			]
			connect_rooms(rooms, start, 1)
		-1:
			section = "shrine"
			spawn_x = 345.0
			gate_x = 620.0
			rooms[start] = make_room("healing_shrine", 2921, [], 3)
			rooms[start].shrine_x = 480.0
			rooms[start].walk_bounds = Vector2(280, 682)
			rooms[start].lessons = [{"x": 480.0, "text": "E  Rest at the shrine"}]
		_:
			section = "guardian"
			rooms[start] = make_room("intro_boss", 2922, [Rect2(323, 363, 106, 12)], 2)
			rooms[start].wake_x = 425.0
			add_encounter(rooms[start], "intro_boss", 706.0)
	rooms[start].intro_stage = section
	rooms[gate].exit_x = gate_x
	return {
		"rooms": rooms, "gate": gate, "seal_room": NO_SEAL, "intro": section,
		"spawn_x": spawn_x, "gate_x": gate_x, "stage": floor_number
	}

static func assign_floor_encounters(room: Dictionary, at: Vector2i, stage: int) -> void:
	var local := RandomNumberGenerator.new()
	local.seed = room.seed
	var first_hall := at == Vector2i.RIGHT
	var can_shield := stage >= 6 and stage != MINIBOSS_STAGE
	var can_cast := stage in [7, 8, BOSS_STAGE]
	var ground_start := float(local.randi_range(657, 702))
	var fly_start := float(local.randi_range(310, 424))
	if first_hall or local.randf() < 0.54 + stage * 0.041:
		add_encounter(room, "vowguard", ground_start)
	if first_hall or at == Vector2i(2, 0) or local.randf() < 0.23 + stage * 0.06:
		add_encounter(room, "gorgon", fly_start)
	var shield_here := can_shield and (first_hall or local.randf() < 0.19 + stage * 0.027)
	if shield_here:
		add_encounter(room, "shield", float(local.randi_range(746, 780)))
		if room.ledges.is_empty():
			room.ledges = [Rect2(654, 355, 146, 14)]
	if can_cast and (first_hall or local.randf() < 0.40):
		add_encounter(room, "caster", float(local.randi_range(850, 884)))
	if not shield_here and not can_cast and stage >= 4 and local.randf() < 0.55:
		add_encounter(room, "vowguard", float(local.randi_range(785, 843)))
	if room.encounters.is_empty():
		add_encounter(room, "vowguard", ground_start)

static func stair_x(direction: int) -> float:
	return 214.0 if direction == 0 else STAIR_X

static func add_room(rooms: Dictionary, at: Vector2i, rng: RandomNumberGenerator) -> void:
	var layout := rng.randi_range(0, 3)
	var base_x := rng.randi_range(272, 318)
	var ledges: Array = []
	match layout:
		0:
			ledges = [Rect2(base_x, 361, 112, 13), Rect2(base_x + 110, 299, 124, 14)]
		1:
			ledges = [Rect2(base_x, 359, 104, 13), Rect2(base_x + 126, 351, 138, 14), Rect2(768, 339, 113, 14)]
		2:
			ledges = [Rect2(base_x, 355, 166, 14), Rect2(base_x + 160, 295, 113, 14)]
	rooms[at] = make_room("hall", rng.randi(), ledges, layout)

static func make_room(kind: String, room_seed: int, ledges: Array, layout: int) -> Dictionary:
	return {
		"kind": kind, "hidden": false, "seal": false, "visited": false, "enemies": [], "loot": [],
		"altar_used": false, "links": [], "seed": room_seed, "ledges": ledges, "layout": layout,
		"encounters": [], "spawn_points": [], "lessons": []
	}

static func add_encounter(room: Dictionary, role: String, x: float) -> void:
	room.encounters.append(role)
	room.spawn_points.append(x)

static func connect_rooms(rooms: Dictionary, at: Vector2i, direction: int) -> void:
	rooms[at].links.append(direction)
	rooms[at + DIRECTIONS[direction]].links.append((direction + 2) % 4)

static func is_navigable(rooms: Dictionary, check_boss := -1, endless := false) -> bool:
	if not rooms.has(Vector2i.ZERO):
		return false
	var first_room: Dictionary = rooms[Vector2i.ZERO]
	var intro: String = first_room.get("intro_stage", "")
	if intro.is_empty() and first_room.kind != "arrival":
		return false
	var reached := {Vector2i.ZERO: true}
	var pending: Array[Vector2i] = [Vector2i.ZERO]
	var gates := 0
	var bosses := 0
	var seals := 0
	while not pending.is_empty():
		var at: Vector2i = pending.pop_back()
		var gallery: Dictionary = rooms[at]
		seals += int(gallery.seal)
		gates += int(gallery.kind in GATE_KINDS)
		bosses += int(gallery.kind == "boss")
		var gap: Vector2 = gallery.get("gap", Vector2.ZERO)
		if gap != Vector2.ZERO and (gap.x < 422.0 or gap.y > 643.0 or gap.y - gap.x > 147.0):
			return false
		if gallery.encounters.size() != gallery.spawn_points.size():
			return false
		for index in range(gallery.encounters.size()):
			if not safe_spawn(gallery.spawn_points[index], gallery.encounters[index], gap):
				return false
		for enemy: Dictionary in gallery.enemies:
			if not safe_spawn(enemy.x, enemy.role, gap):
				return false
		for direction in gallery.links:
			var next: Vector2i = at + DIRECTIONS[direction]
			if not rooms.has(next) or not (direction + 2) % 4 in rooms[next].links:
				return false
			if not reached.has(next):
				reached[next] = true
				pending.append(next)
	if reached.size() != rooms.size() or gates != 1:
		return false
	if not intro.is_empty():
		return seals == 0 and bosses == 0
	return seals == int(not endless) and (check_boss < 0 or bosses == check_boss)

static func safe_spawn(x: float, role: String, gap: Vector2) -> bool:
	return x >= 36.0 and x <= SIZE - 36.0 and (role == "gorgon" or x <= gap.x or x >= gap.y)
