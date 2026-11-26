extends RefCounted

const GRID := Vector2i(52, 26)
const CARDINALS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]

static func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ 318621567
	var slots: Array[Vector2i] = [Vector2i(0, rng.randi_range(0, 1))]
	var connections: Array[Vector2i] = []
	var count := rng.randi_range(6, 8)
	while slots.size() < count:
		var frontier: Array[Vector3i] = []
		for i in range(slots.size()):
			for offset in CARDINALS:
				var next: Vector2i = slots[i] + offset
				if Rect2i(0, 0, 4, 2).has_point(next) and not slots.has(next):
					frontier.append(Vector3i(next.x, next.y, i))
		var step := frontier[rng.randi_range(0, frontier.size() - 1)]
		connections.append(Vector2i(step.z, slots.size()))
		slots.append(Vector2i(step.x, step.y))
	if rng.randf() < 0.67:
		var loops: Array[Vector2i] = []
		for a in range(slots.size()):
			for b in range(a + 1, slots.size()):
				var offset := slots[a] - slots[b]
				if abs(offset.x) + abs(offset.y) == 1 and not Vector2i(a, b) in connections:
					loops.append(Vector2i(a, b))
		if not loops.is_empty():
			connections.append(loops[rng.randi_range(0, loops.size() - 1)])

	var rooms: Array[Rect2i] = []
	var floor_tiles := {}
	for slot in slots:
		var center := Vector2i(6 + slot.x * 13, 6 + slot.y * 13)
		center += Vector2i(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
		var dimensions := Vector2i(rng.randi_range(7, 10), rng.randi_range(6, 8))
		var room := Rect2i(center - dimensions / 2, dimensions)
		rooms.append(room)
		for y in range(room.position.y, room.end.y):
			for x in range(room.position.x, room.end.x):
				floor_tiles[Vector2i(x, y)] = true
	for connection in connections:
		carve(floor_tiles, rooms[connection.x].get_center(), rooms[connection.y].get_center())

	var start: Vector2i = rooms[0].get_center()
	var distances := flood(floor_tiles, start)
	var ordered: Array[Vector2i] = []
	for i in range(1, rooms.size()):
		ordered.append(Vector2i(distances[rooms[i].get_center()], i))
	ordered.sort_custom(func(a: Vector2i, b: Vector2i): return a.x > b.x or (a.x == b.x and a.y < b.y))
	var exit_room := rooms[ordered[0].y]
	var exit := Vector2i(exit_room.end.x - 2, exit_room.position.y + 1)
	var key_room := rooms[ordered[rng.randi_range(1, mini(3, ordered.size() - 1))].y]
	var key := key_room.position + Vector2i(2, 2)
	var treasure: Array[Vector2i] = []
	var spawns: Array[Dictionary] = []
	for i in range(1, rooms.size()):
		var room := rooms[i]
		var plinth := Vector2i(room.end.x - 2, room.end.y - 2)
		if treasure.size() < 4:
			treasure.append(plinth)
		if spawns.size() < 3 and room != key_room:
			spawns.append({"room": room, "at": room.get_center(), "flying": spawns.size() == 1})
	return {"tiles": floor_tiles, "rooms": rooms, "start": start, "key": key, "exit": exit,
		"treasure": treasure, "spawns": spawns}

static func carve(tiles: Dictionary, from: Vector2i, to: Vector2i) -> void:
	var at := from
	while at.x != to.x:
		tiles[at] = true
		tiles[at + Vector2i.DOWN] = true
		at.x += signi(to.x - at.x)
	while at.y != to.y:
		tiles[at] = true
		tiles[at + Vector2i.RIGHT] = true
		at.y += signi(to.y - at.y)

static func flood(tiles: Dictionary, start: Vector2i, blocked := Vector2i(-1, -1)) -> Dictionary:
	if not tiles.has(start) or start == blocked:
		return {}
	var reach := {start: 0}
	var pending: Array[Vector2i] = [start]
	var head := 0
	while head < pending.size():
		var at := pending[head]
		head += 1
		for side in CARDINALS:
			var next: Vector2i = at + side
			if next != blocked and tiles.has(next) and not reach.has(next):
				reach[next] = int(reach[at]) + 1
				pending.append(next)
	return reach

static func valid(layout: Dictionary) -> bool:
	var tiles: Dictionary = layout.tiles
	if not (layout.start != layout.key and layout.key != layout.exit and layout.start != layout.exit):
		return false
	if not [layout.start, layout.key, layout.exit].all(func(at): return tiles.has(at)):
		return false
	var reach := flood(tiles, layout.start)
	var before_key := flood(tiles, layout.start, layout.exit)
	if reach.size() != tiles.size() or not before_key.has(layout.key) or not reach.has(layout.exit):
		return false
	for spawn in layout.spawns:
		if not reach.has(spawn.at) or spawn.at in [layout.start, layout.key, layout.exit]:
			return false
	return layout.rooms.size() >= 5 and layout.spawns.size() >= 2
