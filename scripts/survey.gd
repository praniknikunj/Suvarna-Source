extends Node2D

signal closed

const Layout = preload("res://scripts/survey_layout.gd")
const UI = preload("res://scripts/votive_ui.gd")
const Pause = preload("res://scripts/pause_menu.gd")
const PRINCE = preload("res://assets/indian_prince_sheet.png")
const MOB = preload("res://assets/enemy_sprites.png")
const CHIME = preload("res://assets/foley/relic.wav")
const BLADE = preload("res://assets/foley/slash.wav")
const IMPACT = preload("res://assets/foley/hit.wav")
const TILE := 16.0
const ORIGIN := Vector2(64, 84)
const FOG := 6.0
const HEALTH_MAX := 5
const PAUSE_ITEMS := [
	["resume", "Resume survey", "Return to the current gallery."],
	["map", "Survey chart", "Check the tiles you have already discovered."],
	["restart", "Restart this seed", "Begin the current survey again."],
	["title", "Return to the title", "Leave this survey and return to the ledger."]
]

var source: Dictionary
var seen := {}
var items := {}
var guards: Array[Dictionary] = []
var player := Vector2.ZERO
var heading := Vector2.RIGHT
var seed_value := 0
var hp := HEALTH_MAX
var score := 0
var time := 0.0
var cooldown := 0.0
var swing := 0.0
var thrusting := false
var dodge := 0.0
var invincible := 0.0
var collected := false
var unlocked := false
var map_open := false
var state := "play"
var note := ""
var note_time := 0.0
var axis := Vector2.ZERO
var attached := false
var display := UI.display_font()
var sound := AudioStreamPlayer.new()
var pause_menu := Pause.new()

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sound)
	sound.volume_db = -6.0
	pause_menu.items = PAUSE_ITEMS
	add_child(pause_menu)
	pause_menu.selected.connect(select_pause_action)

func restart(value: int) -> void:
	pause_menu.close()
	seed_value = value
	state = "play"
	source = Layout.generate(value)
	if not Layout.valid(source):
		state = "invalid"
		queue_redraw()
		return
	player = center(source.start)
	heading = Vector2.RIGHT
	hp = HEALTH_MAX
	score = 0
	time = 0.0
	cooldown = 0.0
	swing = 0.0
	thrusting = false
	dodge = 0.0
	invincible = 0.0
	collected = false
	unlocked = false
	map_open = false
	seen.clear()
	items.clear()
	guards.clear()
	for treasure in source.treasure:
		items[treasure] = true
	for spawn in source.spawns:
		guards.append({"position": center(spawn.at), "rect": spawn.room, "flying": spawn.flying,
			"home": center(spawn.at), "hp": 2, "phase": float(spawn.at.x), "facing": -1})
	discover()
	notify("Find the Dharma Key and open the east gate.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		action(event.physical_keycode)

func action(key: Key) -> void:
	if key == KEY_P or pause_menu.visible:
		pause_menu.navigate(key)
		return
	if key == KEY_ESCAPE:
		if map_open:
			map_open = false
		else:
			closed.emit()
		return
	if key == KEY_R:
		restart(randi())
		return
	if state != "play":
		if key in [KEY_E, KEY_ENTER, KEY_KP_ENTER]:
			restart(seed_value)
		return
	match key:
		KEY_TAB:
			map_open = not map_open
		KEY_C:
			DisplayServer.clipboard_set(str(seed_value))
			notify("Seed copied.")
		KEY_E, KEY_ENTER, KEY_KP_ENTER:
			if not map_open:
				interact()
		KEY_X, KEY_V:
			if not map_open and cooldown <= 0.0:
				strike(key == KEY_V)
		KEY_SHIFT, KEY_SPACE:
			if not map_open and invincible <= 0.0:
				dodge = 0.16
				invincible = 0.28

func _physics_process(dt: float) -> void:
	queue_redraw()
	if pause_menu.visible:
		return
	note_time -= dt
	if state != "play" or map_open:
		return
	time += dt
	cooldown -= dt
	dodge -= dt
	invincible -= dt
	swing -= dt
	var keyboard := Vector2(
		int(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)),
		int(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)))
	var direction := keyboard.normalized() if keyboard != Vector2.ZERO else axis
	if direction.length() > 0.1 and dodge <= 0.0:
		heading = direction.normalized()
	var delta := (heading * 190.0 if dodge > 0.0 else direction * 99.0) * dt
	advance(Vector2(delta.x, 0))
	advance(Vector2(0, delta.y))
	discover()
	if unlocked and grid_point(player) == source.exit:
		score += maxi(0, 1200 - int(time) * 10)
		state = "won"
		play(CHIME)
		return
	for guard in guards:
		update_guard(guard, dt)

func select_pause_action(selection: String) -> void:
	match selection:
		"resume":
			map_open = false
		"map":
			map_open = true
		"restart":
			restart(seed_value)
		"title":
			closed.emit()

func strike(thrust := false) -> void:
	thrusting = thrust
	cooldown = 0.55 if thrusting else 0.40
	swing = 0.19
	play(BLADE)
	var reach := 46.0 if thrusting else 32.0
	var aperture := 0.89 if thrusting else 0.20
	for guard in guards.duplicate():
		var difference: Vector2 = guard.position - player
		var distance := difference.length()
		if distance >= reach or (distance >= 8.0 and heading.dot(difference.normalized()) <= aperture):
			continue
		if not clear_attack_path(difference):
			continue
		guard.hp -= 1
		play(IMPACT)
		if guard.hp <= 0:
			guards.erase(guard)
			score += 45

func clear_attack_path(difference: Vector2) -> bool:
	var steps := ceili(difference.length() / (TILE * 0.4))
	for step in range(1, steps + 1):
		var tile := grid_point(player + difference * (float(step) / steps))
		if not source.tiles.has(tile) or (tile == source.exit and not unlocked):
			return false
	return true

func interact() -> void:
	if not collected and player.distance_to(center(source.key)) <= 23.0:
		collected = true
		score += 150
		play(CHIME)
		notify("Dharma Key recovered. Return to the gate.")
	elif not unlocked and player.distance_to(center(source.exit)) <= 24.0:
		if collected:
			unlocked = true
			play(CHIME)
			notify("Gate unlocked. Cross the threshold.")
		else:
			notify("The gate bears the mark of the missing Dharma Key.")
	else:
		for treasure in items.keys():
			if player.distance_to(center(treasure)) <= 19.0:
				items.erase(treasure)
				score += 100
				play(CHIME)
				notify("Temple offering recovered. +100")
				return

func advance(delta: Vector2) -> void:
	var next := player + delta
	for corner in [Vector2(4, 4), Vector2(4, -4), Vector2(-4, 4), Vector2(-4, -4)]:
		var tile := grid_point(next + corner)
		if not source.tiles.has(tile) or (tile == source.exit and not unlocked):
			return
	player = next

func update_guard(guard: Dictionary, dt: float) -> void:
	var previous: Vector2 = guard.position
	var distance: Vector2 = player - guard.position
	var bounds := Rect2(ORIGIN + Vector2(guard.rect.position) * TILE, Vector2(guard.rect.size) * TILE).grow(-11.0)
	var target: Vector2 = guard.home + Vector2(cos(time * 1.45 + guard.phase) * 25.0, sin(time * 1.28 + guard.phase) * 17.0)
	if distance.length() < 72.0 and bounds.has_point(player):
		target = player
	guard.position = guard.position.move_toward(target.clamp(bounds.position, bounds.end), (49.0 if guard.flying else 37.0) * dt)
	if absf(guard.position.x - previous.x) > 0.01:
		guard.facing = 1 if guard.position.x > previous.x else -1
	if distance.length() < 14.0 and invincible <= 0.0:
		hp -= 1
		invincible = 0.90
		play(IMPACT)
		if hp <= 0:
			state = "lost"

func play(stream: AudioStream) -> void:
	sound.stream = stream
	sound.play()

func discover() -> void:
	var at := grid_point(player)
	for y in range(at.y - 6, at.y + 7):
		for x in range(at.x - 6, at.x + 7):
			var tile := Vector2i(x, y)
			if source.tiles.has(tile) and Vector2(tile - at).length() <= FOG:
				seen[tile] = true

func grid_point(screen: Vector2) -> Vector2i:
	return Vector2i(((screen - ORIGIN) / TILE).floor())

func center(tile: Vector2i) -> Vector2:
	return ORIGIN + (Vector2(tile) + Vector2(0.5, 0.5)) * TILE

func notify(text: String) -> void:
	note = text
	note_time = 3.7

func text_at(at: Vector2, text: String, size: int, color := UI.CREAM, serif := false) -> void:
	draw_string(display if serif else ThemeDB.fallback_font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#10171e"))
	draw_arc(Vector2(480, 290), 224, 0, TAU, 96, Color("#1b2630"), 2)
	draw_arc(Vector2(480, 290), 205, 0, TAU, 96, Color("#1b2630"), 1)
	UI.engraved(self, Rect2(44, 73, 872, 438), Color("#0e151b"), Color("#585346"))
	if source.is_empty():
		return
	var focus := grid_point(player)
	for tile in seen:
		var at := center(tile) - Vector2(8, 8)
		var close: bool = Vector2(tile - focus).length() < FOG
		var variant: float = float(posmod(tile.x * 23 + tile.y * 83, 7)) * 0.027
		var fill := Color("#2c393c").lightened(variant) if close else Color("#232b30")
		if map_open:
			fill = Color("#487168") if close else Color("#2b4041")
		draw_rect(Rect2(at, Vector2(15, 15)), fill)
		if not source.tiles.has(tile + Vector2i.UP):
			draw_rect(Rect2(at - Vector2(0, 3), Vector2(16, 4)), Color("#a27e55") if close else Color("#62574b"))
		if not source.tiles.has(tile + Vector2i.LEFT):
			draw_rect(Rect2(at, Vector2(1, 15)), Color("#755a45"))
		if close and posmod(tile.x + tile.y * 17, 9) == 0:
			draw_line(at + Vector2(4, 3), at + Vector2(8, 7), Color("#1d272e"))
	var gate_at := center(source.exit)
	if seen.has(source.exit):
		UI.engraved(self, Rect2(gate_at - Vector2(10, 11), Vector2(20, 22)), Color("#271d26"), UI.PATINA if unlocked else Color("#b27d5b"))
		UI.diamond(self, gate_at, 5, UI.PATINA if unlocked else UI.BRASS, not unlocked)
	if not collected and seen.has(source.key):
		UI.lotus(self, center(source.key) + Vector2(0, 2), 0.73, UI.BRASS)
	for item in items:
		if seen.has(item):
			UI.diamond(self, center(item), 3.5, Color("#d6a276"))
	if not map_open:
		for guard in guards:
			var screen: Vector2 = guard.position
			if Vector2(grid_point(screen) - focus).length() < FOG:
				draw_guard(guard)
		draw_circle(player + Vector2(0, 5), 7, Color("#121b25c8"))
		var prince := Rect2(player - Vector2(7, 21), Vector2(14, 29))
		if heading.x < 0.0:
			prince.size.x *= -1.0
		var tint := Color("#ffffff80") if invincible > 0.0 and fmod(time, 0.17) < 0.07 else Color.WHITE
		draw_texture_rect_region(PRINCE, prince, Rect2(579, 93, 72, 155), tint)
		if swing > 0.0:
			var metal := Color("#edc68e", swing / 0.19)
			if thrusting:
				var tip := player + heading * 43.0
				draw_line(player + heading * 12.0, tip, metal, 3.0, true)
				UI.diamond(self, tip, 4.0, metal)
			else:
				draw_arc(player, 26, heading.angle() - 0.97, heading.angle() + 0.97, 20, metal, 3.0, true)
	else:
		UI.flame(self, player, 0.90, UI.BRASS)
	draw_chrome()
	if state != "play":
		draw_result()

func draw_guard(guard: Dictionary) -> void:
	var at: Vector2 = guard.position
	var flying: bool = guard.flying
	var frame := floori(time * 6.0) % 3
	var cell := Rect2(72.0 * frame, 0 if flying else 56, 72, 56)
	var size := 31.0 if flying else 38.0
	var offset := 6.0 + sin(time * 3.0 + guard.phase) * 3.0 if flying else 0.0
	var bounds := Rect2(at - Vector2(size / 2.0, size * 0.69 + offset), Vector2(size, size * 56 / 72))
	if guard.facing > 0:
		bounds.size.x *= -1.0
	draw_texture_rect_region(MOB, bounds, cell)
	if guard.hp < 2:
		UI.diamond(self, at - Vector2(0, 24 + offset), 2.2, UI.BRASS)

func draw_chrome() -> void:
	UI.lotus(self, Vector2(68, 41), 1.2, UI.BRASS)
	text_at(Vector2(91, 47), "The Votary's Survey" if not map_open else "Survey Chart", 24, UI.CREAM, true)
	text_at(Vector2(95, 65), "SEED %d" % seed_value, 11, UI.PATINA)
	UI.engraved(self, Rect2(445, 35, 86, 14), Color("#2e2329"), UI.BRASS)
	draw_rect(Rect2(449, 39, 78.0 * float(hp) / HEALTH_MAX, 6), Color("#ad5e59"))
	text_at(Vector2(552, 47), "KEY HELD" if collected else "SEEK THE KEY", 12, UI.PATINA)
	text_at(Vector2(761, 47), "%04d pts   %02d:%02d" % [score, int(time) / 60, int(time) % 60], 14)
	if attached:
		text_at(Vector2(725, 65), "CONTROLLER CONNECTED", 11, UI.PATINA)
	if note_time > 0.0 and not map_open:
		UI.engraved(self, Rect2(222, 453, 516, 31), Color("#17232ceb"), Color("#826747"))
		text_at(Vector2(239, 475), note, 13)
	text_at(Vector2(69, 528), "Arrows  Move     X  Slash     V  Thrust     E  Interact     P  Pause     Shift  Dodge     Tab  Map     C  Copy     R  New seed", 12, UI.PATINA)

func draw_result() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#0d141bcf"))
	UI.engraved(self, Rect2(254, 168, 452, 216), Color("#172027"), UI.BRASS)
	UI.lotus(self, Vector2(295, 219), 1.48, UI.BRASS)
	var title := "Gate crossed" if state == "won" else ("Samsara" if state == "lost" else "Survey unavailable")
	text_at(Vector2(324, 228), title, 34, UI.CREAM, true)
	text_at(Vector2(293, 272), "Score %d     Seed %d" % [score, seed_value], 18, UI.PATINA)
	UI.rule(self, Vector2(293, 299), Vector2(668, 299), UI.BRASS)
	text_at(Vector2(293, 336), "E  Retry seed     R  New seed     P  Pause", 14, UI.CREAM)

