extends Node2D

const Dungeon = preload("res://scripts/dungeon.gd")
const Lore = preload("res://scripts/realms.gd")
const PrinceFrames = preload("res://scripts/anim_data.gd")
const Sheet = preload("res://assets/indian_prince_sheet.png")
const FLOOR := Dungeon.FLOOR
const ENEMY_SHEET = preload("res://assets/enemy_sprites.png")
const ENEMY_CELL := Vector2(72, 56)
const ENEMY_PIVOT := Vector2(34, 51)
const PRINCE_SCALE := 0.53
const UI = preload("res://scripts/votive_ui.gd")
const Story = preload("res://scripts/opening.gd")
const Survey = preload("res://scripts/survey.gd")
const Controller = preload("res://scripts/esp32_input.gd")
const Run = preload("res://scripts/pilgrimage.gd")
const RealmArrival = preload("res://scripts/realm_arrival.gd")
const RealmArt = preload("res://scripts/realm_art.gd")
const Encounters = preload("res://scripts/encounter_rules.gd")
const Masonry = preload("res://scripts/stonework.gd")
const Sequence = preload("res://scripts/attack_sequence.gd")
const CombatFX = preload("res://scripts/combat_fx.gd")
const RegionalMobs = preload("res://scripts/regional_mobs.gd")
const Animations = preload("res://scripts/encounter_art.gd")
const Pause = preload("res://scripts/pause_menu.gd")
const Patterns = preload("res://scripts/guardian_signatures.gd")
const Actions = preload("res://scripts/guardian_actions.gd")
const Pixels = preload("res://scripts/guardian_pixels.gd")
const Legacy = preload("res://scripts/pilgrimage_legacy.gd")
const VajraTrial = preload("res://scripts/vajra_trial.gd")
const Choice = preload("res://scripts/votive_choice.gd")
const QUEST_DOOR_X := 742.0
const BOSS_GALLERIES := ["intro_boss", "mini_boss", "boss", "side_boss"]
const FOLEY := {
	"slash": preload("res://assets/foley/slash.wav"), "hit": preload("res://assets/foley/hit.wav"),
	"jump": preload("res://assets/foley/jump.wav"), "dodge": preload("res://assets/foley/dodge.wav"),
	"relic": preload("res://assets/foley/relic.wav"), "hurt": preload("res://assets/foley/hurt.wav")
}
const GOLD := Color("#f1c478")
const INK := Color("#110d17")
const WHITE := Color("#f0dfbd")
const SAVE := "user://suvarna_profile.cfg"
const ROOM_NAMES := {
	"arrival": "Pilgrim's Court", "hall": "Pillared Hall", "boss": "Inner Sanctum",
	"exit": "East Gate", "rest": "Shelter", "tutorial": "Cloister of the Last Vow",
	"healing_shrine": "Shrine of Breath", "intro_boss": "The First Gate", "mini_boss": "Guardian's Court",
	"corridor": "Gallery of Approach",
	"shrine": "Seal Shrine", "elite": "Sentinel Court", "secret": "Hidden Recess",
	"vow": "Samskara Shrine", "pilgrim": "Pilgrim's Niche", "mini-boss": "Guardian's Court",
	"teacher": "Abandoned Shrine", "reliquary": "Reliquary", "archive": "Manuscript Hall",
	"rest_shrine": "Shrine of Breath", "quest_passage": "The Sealed Passage", "side_boss": "Court of the Oath"
}

var rng := RandomNumberGenerator.new()
var data: Dictionary
var room: Dictionary
var point := Vector2i.ZERO
var realm := 0
var floor_number := -2
var pending_floor := 0
var last_ending_floor := 0
var best_depth := 0
var awards: Dictionary = {}
var endless := false
var trial := VajraTrial.new()
var choice: Choice
var smile_age := 0.0
var quest := -1
var quest_origin: Dictionary = {}
var cycle := 0
var ashes := 0
var vitality_rank := 0
var run_seed := 0
var max_hp := 100
var hp := 100
var displayed_hp := 100.0
var position_on_floor := Vector2(480, FLOOR)
var vertical_speed := 0.0
var facing := 1
var grounded := true
var animation := "idle"
var anim_time := 0.0
var attack := 0.0
var attack_kind := "slash"
var contact := 0.22
var swing_pending := false
var dropping := 0.0
var drop_y := 0.0
var heal_time := 0.0
var hit_stop := 0.0
var invincible := 0.0
var dodge := 0.0
var dodge_recovery := 0.0
var gate_reveal := 0.0
var stagger := 0.0
var recoil := 0.0
var seal := false
var seal_active := false
var passage := false
var map_open := false
var journal_page := 0
var journal_open := false
var controls_open := false
var inventory_open := false
var inventory_index := 0
var display := UI.display_font()
var items: Dictionary = {}
var vows: Dictionary = {}
var memories: Array[String] = []
var message := ""
var message_time := 0.0
var elapsed := 0.0
var state := "intro"
var ending := ""
var end_text := ""
var platforms: Array[Rect2] = []
var backdrop: Node2D
var seed_menu: Control
var camera_x := 0.0
var gap := Vector2.ZERO
var last_safe_x := 172.0
var players := {}
var opening: Story
var survey: Survey
var controller: Controller
var pending_seed := -1
var seen_opening := false
var controller_up := false
var controller_down := false
var controller_mode := 0
var realm_card: RealmArrival
var pause_menu: Pause
var projectiles: Array[Dictionary] = []
var contact_marks: Array[Dictionary] = []

func _ready() -> void:
	var profile := ConfigFile.new()
	if profile.load(SAVE) == OK:
		ashes = maxi(0, int(profile.get_value("samsara", "ashes", 0)))
		cycle = maxi(0, int(profile.get_value("samsara", "cycles", 0)))
		vitality_rank = clampi(int(profile.get_value("samsara", "vitality_rank", 0)), 0, 6)
		best_depth = maxi(0, int(profile.get_value("pilgrimage", "best_depth", 0)))
		var recorded: Variant = profile.get_value("pilgrimage", "awards", {})
		if recorded is Dictionary:
			for id in recorded:
				if id is String and recorded[id] and not Legacy.award_detail(id).is_empty():
					awards[id] = true
	backdrop = preload("res://scripts/temple.gd").new()
	add_child(backdrop)
	backdrop.z_index = -1
	backdrop.trial = trial
	seed_menu = preload("res://scripts/seed_menu.gd").new()
	add_child(seed_menu)
	seed_menu.started.connect(start_from_ledger)
	seed_menu.replay_requested.connect(watch_opening)
	seed_menu.update_profile(best_depth, awards)
	seed_menu.present("SUVARNA", "THE LAST VOW", "Ash falls over the monastery of the Final Path. Below its ruined gates, a Dharma Seal waits in the old stair galleries.", "Begin pilgrimage")
	opening = Story.new()
	add_child(opening)
	opening.ended.connect(finish_opening)
	realm_card = RealmArrival.new()
	add_child(realm_card)
	realm_card.ended.connect(finish_realm_card)
	pause_menu = Pause.new()
	add_child(pause_menu)
	pause_menu.selected.connect(pause_selected)
	choice = Choice.new()
	add_child(choice)
	choice.selected.connect(choice_selected)
	controller = Controller.new()
	add_child(controller)
	controller.button.connect(controller_button)
	var streams := FOLEY.duplicate()
	for cue in ["guard", "wake", "shrine", "fall", "vajra"]:
		var path := "res://assets/foley/%s.wav" % cue
		if ResourceLoader.exists(path):
			streams[cue] = load(path)
	for cue in streams:
		var player := AudioStreamPlayer.new()
		player.stream = streams[cue]
		player.volume_db = -5.0
		players[cue] = player
		add_child(player)

func sound(cue: String) -> void:
	if players.has(cue):
		players[cue].play()

func start_from_ledger(value: int) -> void:
	if seed_menu.survey_mode:
		state = "survey"
		survey = Survey.new()
		add_child(survey)
		survey.closed.connect(return_to_ledger)
		survey.restart(value)
	elif not seen_opening:
		watch_opening(value)
	else:
		new_run(value)

func watch_opening(value := -1) -> void:
	pending_seed = value
	seen_opening = true
	state = "opening"
	seed_menu.hide()
	opening.begin()

func finish_opening() -> void:
	if pending_seed < 0:
		return_to_ledger()
	else:
		new_run(pending_seed)
	pending_seed = -1

func return_to_ledger() -> void:
	if is_instance_valid(survey):
		survey.queue_free()
		survey = null
	state = "intro"
	choice.hide()
	seed_menu.update_profile(best_depth, awards)
	seed_menu.present("SUVARNA", "THE LAST VOW", "Ash falls over the monastery of the Final Path. Below its ruined gates, a Dharma Seal waits in the old stair galleries.", "Begin pilgrimage")

func controller_button(index: int) -> void:
	if index == 3:
		var new_seed := randi()
		if state == "survey":
			survey.restart(new_seed)
		elif state == "play":
			seed_menu.seed_field.text = str(new_seed)
			new_run(new_seed)
		elif seed_menu.visible:
			seed_menu.roll()
		return
	if state == "survey":
		var survey_key: Key = [KEY_E, KEY_X, KEY_TAB][index]
		if index == 2 and survey.state != "play":
			survey_key = KEY_ENTER
		survey.action(survey_key)
		return
	if state == "opening":
		if index == 2:
			opening.skip()
		return
	if state == "realm_card":
		if index == 2:
			realm_card.skip()
		return
	if choice.visible:
		if index == 0:
			choice.navigate(KEY_E)
		return
	if state == "play":
		var button_key: Key = [KEY_E, KEY_X, KEY_P][index]
		handle_key(button_key)
	elif index == 2 and seed_menu.visible:
		seed_menu.submit()

func update_controller() -> void:
	if state == "survey" and is_instance_valid(survey):
		survey.axis = controller.axis
		survey.attached = controller.connected
	var up := controller.axis.y < -0.55
	if up and not controller_up:
		if choice.visible:
			choice.navigate(KEY_UP)
		elif state == "play":
			handle_key(KEY_UP)
	controller_up = up
	var down := controller.axis.y > 0.55
	if down and not controller_down:
		if choice.visible:
			choice.navigate(KEY_DOWN)
		elif state == "play":
			handle_key(KEY_DOWN)
	controller_down = down
	var side := 0 if absf(controller.axis.x) < 0.57 else (1 if controller.axis.x > 0.0 else -1)
	if seed_menu.visible and side != 0 and side != controller_mode:
		seed_menu.choose_mode(side == 1)
	controller_mode = side

func save_profile() -> void:
	var profile := ConfigFile.new()
	profile.set_value("samsara", "ashes", ashes)
	profile.set_value("samsara", "cycles", cycle)
	profile.set_value("samsara", "vitality_rank", vitality_rank)
	profile.set_value("pilgrimage", "best_depth", best_depth)
	profile.set_value("pilgrimage", "awards", awards)
	profile.save(SAVE)

func award(id: String) -> void:
	if awards.has(id):
		return
	awards[id] = true
	save_profile()
	var detail := Legacy.award_detail(id)
	sound("relic")
	announce("Achievement   /   " + String(detail.title))

func new_run(value: int) -> void:
	seed_menu.hide()
	run_seed = value
	seed_menu.seed_field.text = str(run_seed)
	rng.seed = run_seed
	floor_number = -2
	last_ending_floor = 0
	endless = false
	quest = -1
	quest_origin.clear()
	trial.reset()
	choice.hide()
	realm = 0
	max_hp = 100 + vitality_rank * 10
	hp = ceili(max_hp * 0.5)
	displayed_hp = hp
	items.clear()
	vows.clear()
	memories.assign(["When the world has forgotten suffering, the final sufferer shall return."])
	map_open = false
	journal_open = false
	inventory_open = false
	controls_open = false
	pause_menu.close()
	heal_time = 0.0
	state = "play"
	begin_realm()

func begin_realm() -> void:
	endless = floor_number > 100
	realm = Run.active_realm(run_seed, floor_number)
	rng.seed = Run.floor_seed(run_seed, floor_number)
	var boss_floor := floor_number > 0 and Run.is_boss_floor(floor_number)
	var valid := false
	for attempt in range(4):
		data = Dungeon.generate(rng, floor_number, boss_floor, endless, Run.endless_miniboss(run_seed, floor_number))
		for location in data.rooms:
			populate_room(data.rooms[location], location)
		if Dungeon.is_navigable(data.rooms, int(boss_floor), endless):
			valid = true
			break
	if not valid:
		state = "intro"
		seed_menu.present("SUVARNA", "DUNGEON GENERATION", "Roll another seed to begin.", "Begin pilgrimage")
		return
	seal = false
	seal_active = floor_number == -2 or (endless and data.rooms[data.gate].kind == "exit")
	passage = false
	heal_time = 0.0
	if floor_number > 0 and not endless:
		place_passage_relic()
		refresh_vow_loot()
	backdrop.configure(Lore.REALMS[realm], data.rooms, realm)
	enter_room(Vector2i.ZERO, data.get("spawn_x", 172.0))
	var subtitle := "Learn the steps of the pilgrimage." if floor_number == -2 else (
		"Rest at the shrine before the First Gate." if floor_number == -1 else "The pilgrimage begins beyond this guardian.")
	if floor_number > 0:
		subtitle = dungeon_caption() + "   /   " + Lore.REALMS[realm][0]
	announce(subtitle)

func dungeon_caption() -> String:
	if floor_number < 1:
		return ["The Cloister", "The Shrine", "The First Gate"][floor_number + 2]
	var gallery: String = data.rooms[data.gate].kind
	var kind := "Boss" if gallery == "boss" else ("Guardian" if gallery == "mini_boss" else "Dungeon")
	return "%s %03d" % [kind, floor_number]

func complete_floor() -> void:
	if state != "play" or not seal_active:
		return
	if quest >= 0:
		if passage:
			leave_side_quest()
		return
	if room.kind in BOSS_GALLERIES and not passage:
		return
	var next := floor_number + 1
	if floor_number == 0 or (floor_number > 0 and Run.is_boss_floor(floor_number) and not endless):
		enter_realm_card(next)
	else:
		floor_number = next
		begin_realm()

func enter_realm_card(next: int) -> void:
	state = "realm_card"
	pending_floor = next
	realm_card.begin(Run.active_realm(run_seed, next))

func finish_realm_card() -> void:
	if pending_floor <= floor_number:
		return
	floor_number = pending_floor
	pending_floor = 0
	state = "play"
	begin_realm()

func enter_room(target: Vector2i, arrival_x: float, continuous: bool = false) -> void:
	point = target
	backdrop.trial_room = target
	gate_reveal = 1.0 if seal_active else 0.0
	projectiles.clear()
	contact_marks.clear()
	stagger = 0.0
	recoil = 0.0
	dodge_recovery = 0.0
	room = data.rooms[point]
	room.visited = true
	position_on_floor.x = arrival_x
	platforms.assign(room.ledges)
	gap = room.get("gap", Vector2.ZERO)
	last_safe_x = arrival_x
	if not continuous:
		land_on(FLOOR)
		dropping = 0.0
		attack = 0
		swing_pending = false
		dodge = 0
		invincible = 0.42
		update_camera(0.0, true)

func populate_room(target: Dictionary, location: Vector2i) -> void:
	var local := RandomNumberGenerator.new()
	local.seed = target.seed
	for i in range(target.encounters.size()):
		var role: String = target.encounters[i]
		var x: float = target.spawn_points[i]
		if target.has("gap") and role != "gorgon":
			var chasm: Vector2 = target.gap
			if x > chasm.x - 24.0 and x < chasm.y + 24.0:
				x = minf(900.0, chasm.y + 54.0)
		target.enemies.append(make_enemy(x, role, target))
	target.defeated = []
	if endless or quest >= 0:
		return
	match target.kind:
		"arrival":
			if floor_number > 0 and not items.has("Prayer Wheel"):
				target.loot.append("Prayer Wheel")
		"elite", "mini-boss":
			if target.encounters.is_empty():
				target.enemies.append(make_enemy(635.0, "elite", target))
		"archive", "reliquary":
			var vow: Array = Lore.VOWS[realm / 2]
			var trigger: String = vow[1][0 if target.kind == "reliquary" else 1]
			if not items.has(trigger) and (local.randf() < 0.41 or posmod(floor_number, 5) == (1 if target.kind == "reliquary" else 3)):
				target.loot.append(trigger)
			elif local.randf() < 0.48:
				target.loot.append("Breath Shard")
		"rest":
			target.loot.append("Breath Shard")
		"secret":
			if not target.seal:
				target.loot.append("Ashes of the Sangha")

func place_passage_relic() -> void:
	var relic: String = Legacy.RELICS[realm][0]
	if items.has(relic) or not Legacy.relic_roll(Run.floor_seed(run_seed, floor_number)):
		return
	for kind in ["reliquary", "archive", "rest", "rest_shrine", "arrival"]:
		for gallery in data.rooms.values():
			if gallery.kind == kind and not gallery.hidden and gallery.enemies.is_empty():
				gallery.loot.push_front(relic)
				return

func available_quest() -> int:
	if quest >= 0 or endless or floor_number < 1:
		return -1
	return Legacy.first_ready(items, awards)

func open_side_quest(index: int) -> void:
	if not Legacy.ready(index, items, awards):
		return
	quest_origin = {"data":data, "point":point, "realm":realm, "x":position_on_floor.x,
		"seal":seal, "seal_active":seal_active, "passage":passage, "rng":rng.state}
	quest = index
	realm = int(Legacy.QUESTS[quest].realm)
	data = Dungeon.side_duel(rng)
	for at in data.rooms:
		populate_room(data.rooms[at], at)
	seal = false
	seal_active = false
	passage = false
	backdrop.configure(Lore.REALMS[realm], data.rooms, realm)
	enter_room(Vector2i.ZERO, data.spawn_x)
	announce("The oath of " + String(Legacy.QUESTS[quest].name))

func leave_side_quest() -> void:
	var origin := quest_origin
	quest_origin = {}
	quest = -1
	data = origin.data
	realm = origin.realm
	seal = origin.seal
	seal_active = origin.seal_active
	passage = origin.passage
	rng.state = origin.rng
	backdrop.configure(Lore.REALMS[realm], data.rooms, realm)
	enter_room(origin.point, maxf(100, float(origin.x) - 88.0))
	announce("Returned to the Pilgrimage.")

func choice_selected(accept: bool) -> void:
	choice.hide()
	if state == "ending_choice":
		if accept:
			state = "ending_smile"
			smile_age = 0.0
		else:
			return_to_ledger()
	else:
		state = "play"
		var index := available_quest()
		if accept and index >= 0:
			open_side_quest(index)

func make_enemy(x: float, role: String, gallery: Dictionary) -> Dictionary:
	var kind := guardian_role(role)
	var profile := Encounters.mob(role, maxi(1, floor_number)) if kind.is_empty() else (
		Encounters.side_guardian(quest) if kind == "side" else Encounters.guardian(kind, realm))
	var health: int = profile.hp
	if role == "vowguard":
		health = 3
	elif role == "shield":
		health = 5
	elif not kind.is_empty() and floor_number > 0:
		health += Run.lap_at(floor_number) * 9
	return {"x": x, "home": x, "y": FLOOR if role != "gorgon" else RegionalMobs.FLIGHT[realm][0],
		"hp": health, "max_hp": health, "role": role, "clock": 0.65, "damage": profile.get("damage", 12),
		"windup": 0.0, "windup_span": 0.0, "follow": 0.0, "follow_span": 0.0, "recover": 0.0,
		"released": false, "target": x, "phase": 0, "flash": 0.0, "armored_flash": 0.0,
		"direction": -1, "hit": false, "walk": 0.0, "target_y": 392.0, "guard_turn": 0.0,
		"guarding": role == "shield", "shield_flash": 0.0, "clock_animation": 0.0,
		"wake_x": gallery.get("wake_x", x - (295.0 if role == "boss" else 170.0)),
		"guardian": profile if not kind.is_empty() else {}, "art_realm": realm, "quest_art": quest,
		"rite_clock": 0.0, "rite_hits": 0, "rite_light": 0.0,
		"timeline": Encounters.new_timeline(profile) if not kind.is_empty() else {}
	}

func guardian_role(role: String) -> String:
	return {"boss": "boss", "mini_boss": "mini", "intro_boss": "intro", "side_boss":"side"}.get(role, "")

func encounter_kind(role: String) -> String:
	return {"vowguard": "land", "gorgon": "flying", "caster": "ranged", "shield": "tank",
		"elite": "land", "mini_boss": "mini", "intro_boss": "intro", "boss": "boss", "side_boss":"side"}.get(role, "land")

func refresh_vow_loot() -> void:
	if endless or quest >= 0 or floor_number < 1:
		return
	var candidates: Array = data.rooms.values().filter(func(r): return not r.hidden and r.kind in ["hall", "reliquary", "archive", "teacher", "rest"])
	for index in range(candidates.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var previous: Dictionary = candidates[index]
		candidates[index] = candidates[swap]
		candidates[swap] = previous
	for vow in Lore.VOWS:
		if not vows.has(vow[0]) or vows[vow[0]]:
			continue
		for relic in vow[2]:
			if items.has(relic) or data.rooms.values().any(func(other): return relic in other.loot):
				continue
			if rng.randf() >= 0.62:
				continue
			for target in candidates:
				if target.loot.is_empty():
					target.loot.append(relic)
					break

func receive(item: String) -> void:
	sound("relic")
	match item:
		"Breath Shard":
			hp = mini(max_hp, hp + 32)
		"Ashes of the Sangha":
			ashes += 2
			save_profile()
		_:
			items[item] = true
			if Lore.ITEM_NOTES.has(item):
				memories.append(Lore.ITEM_NOTES[item])
	announce("Recovered   /   " + item)
	for vow in Lore.VOWS:
		if not vows.has(vow[0]) and vow[1].all(func(required): return items.has(required)):
			vows[vow[0]] = false
			announce(vow[0] + " awakened. Its relics can now appear.")
	refresh_vow_loot()

func offer_completed_vow() -> void:
	for vow in Lore.VOWS:
		if vows.has(vow[0]) and not vows[vow[0]] and vow[2].all(func(relic): return items.has(relic)):
			vows[vow[0]] = true
			memories.append(vow[3])
			sound("relic")
			announce(vow[0] + " fulfilled. Memory recorded.")
			return
	announce("The altar waits for the relics of a completed vow.")

func kindle_vitality() -> void:
	if vitality_rank >= 6 or ashes < 3:
		return
	ashes -= 3
	vitality_rank += 1
	max_hp = 100 + vitality_rank * 10
	hp = mini(max_hp, hp + 10)
	save_profile()
	sound("relic")

func announce(line: String) -> void:
	message = line
	message_time = 5.0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if choice.visible:
		choice.navigate(event.keycode)
		return
	if state in ["survey", "ending_smile"]:
		return
	if state == "opening":
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_ESCAPE, KEY_SPACE]:
			opening.skip()
		return
	if state == "realm_card":
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_ESCAPE, KEY_SPACE]:
			realm_card.skip()
		return
	if state != "play":
		if seed_menu.achievements.visible:
			seed_menu.achievements.navigate(event.keycode)
			return
		if seed_menu.settings.visible:
			if event.keycode == KEY_ESCAPE:
				seed_menu.settings.hide()
			return
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_E]:
			seed_menu.submit()
		elif event.physical_keycode == KEY_P:
			watch_opening()
		elif event.physical_keycode == KEY_A:
			seed_menu.achievements.show()
		return
	handle_key(event.physical_keycode)

func handle_key(key: Key) -> void:
	if pause_menu.visible:
		pause_menu.navigate(key)
		return
	if key == KEY_P:
		map_open = false
		journal_open = false
		inventory_open = false
		controls_open = false
		pause_menu.toggle()
		return
	if inventory_open and key in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_U]:
		if key == KEY_U:
			kindle_vitality()
		else:
			var step: int = {KEY_LEFT: -1, KEY_RIGHT: 1, KEY_UP: -5, KEY_DOWN: 5}[key]
			inventory_index = posmod(inventory_index + step, inventory_items().size())
		return
	match key:
		KEY_TAB:
			map_open = not map_open
			journal_open = false
			controls_open = false
			inventory_open = false
		KEY_I:
			journal_open = not journal_open
			journal_page = 0
			map_open = false
			controls_open = false
			inventory_open = false
		KEY_B:
			inventory_open = not inventory_open
			inventory_index = 0
			map_open = false
			journal_open = false
			controls_open = false
		KEY_F1:
			controls_open = not controls_open
			map_open = false
			journal_open = false
			inventory_open = false
		KEY_PAGEUP:
			if journal_open:
				journal_page = maxi(0, journal_page - 1)
		KEY_PAGEDOWN:
			if journal_open:
				journal_page = mini(maxi(0, (memories.size() - 1) / 4), journal_page + 1)
		KEY_ESCAPE:
			map_open = false
			journal_open = false
			controls_open = false
			inventory_open = false
		KEY_C:
			DisplayServer.clipboard_set(str(run_seed))
			announce("Dungeon seed copied.")
	if map_open or journal_open or controls_open or inventory_open or trial.cinematic():
		return
	match key:
		KEY_UP:
			if grounded and stagger <= 0.0 and dodge <= 0.0:
				vertical_speed = -443
				grounded = false
				sound("jump")
		KEY_DOWN:
			if grounded and position_on_floor.y < FLOOR - 3.0:
				drop_y = position_on_floor.y
				dropping = 0.22
				position_on_floor.y += 2.0
				vertical_speed = 90.0
				grounded = false
		KEY_X, KEY_V:
			if attack <= 0.0 and stagger <= 0.0 and dodge <= 0.0:
				strike("thrust" if key == KEY_V else "slash")
		KEY_SHIFT:
			if dodge_recovery <= 0.0 and stagger <= 0.0 and attack <= 0.0:
				dodge = 0.21
				dodge_recovery = 0.64
				invincible = maxf(invincible, 0.37)
				sound("dodge")
		KEY_E, KEY_ENTER, KEY_KP_ENTER:
			interact()
		KEY_Q:
			use_wheel()

func pause_selected(action: String) -> void:
	match action:
		"map":
			handle_key(KEY_TAB)
		"inventory":
			handle_key(KEY_B)
		"journal":
			handle_key(KEY_I)
		"controls":
			handle_key(KEY_F1)
		"restart":
			new_run(run_seed)
		"title":
			return_to_ledger()

func use_wheel() -> void:
	if not items.has("Prayer Wheel"):
		announce("The Prayer Wheel rests on the arrival altar.")
		return
	for direction in room.links:
		var neighbor: Vector2i = point + Dungeon.DIRECTIONS[direction]
		if data.rooms[neighbor].hidden:
			data.rooms[neighbor].hidden = false
			sound("relic")
			backdrop.queue_redraw()
			announce("The Prayer Wheel opens the sealed recess.")
			return
	announce("No sealed passage answers here.")

func nearby_stair() -> int:
	if position_on_floor.y >= FLOOR - 48:
		for direction in room.links:
			if direction in [0, 2] and absf(position_on_floor.x - Dungeon.stair_x(direction)) < 57.0:
				return direction
	return -1

func interact() -> void:
	if trial.active():
		return
	if absf(position_on_floor.x - QUEST_DOOR_X) < 53.0 and position_on_floor.y >= FLOOR - 43.0:
		var index := available_quest()
		if point == Vector2i.ZERO and index >= 0:
			state = "quest_choice"
			choice.present("Enter?", "Beyond this passage awaits " + String(Legacy.QUESTS[index].name) + ".", ["Yes", "No"], 1)
			return
	if room.kind == "quest_passage" and position_on_floor.x < 110.0:
		leave_side_quest()
		return
	var keepsake: Dictionary = room.get("keepsake", {})
	if not keepsake.is_empty() and absf(position_on_floor.x - float(keepsake.x)) < 50.0 and grounded:
		room.erase("keepsake")
		sound("relic")
		announce("Kept forever   /   " + String(keepsake.item))
		return
	var door_x: float = room.get("exit_x", data.get("gate_x", Dungeon.EXIT_X))
	if point == data.gate and absf(position_on_floor.x - door_x) < 62.0 and position_on_floor.y >= FLOOR - 45.0:
		if seal_active:
			complete_floor()
		elif floor_number == -1:
			announce("Kneel at the flame before you carry on.")
		elif room.kind in BOSS_GALLERIES and not passage:
			announce("Defeat the guardian before continuing.")
		else:
			announce("The east gate waits for a consecrated Dharma Seal.")
		return
	var stair := nearby_stair()
	if stair != -1:
		enter_room(point + Dungeon.DIRECTIONS[stair], Dungeon.stair_x((stair + 2) % 4))
		return
	if room.kind in ["healing_shrine", "rest_shrine"] and absf(position_on_floor.x - float(room.get("shrine_x", 480))) < 62.0 and position_on_floor.y >= FLOOR - 13:
		if not room.altar_used:
			room.altar_used = true
			if room.kind == "healing_shrine":
				seal_active = true
			hp = mini(max_hp, hp + ceili(max_hp * 0.5))
			heal_time = 1.8
			attack = 0.0
			swing_pending = false
			sound("shrine")
			announce("The shrine returns half your maximum vitality.")
		return
	if absf(position_on_floor.x - 480.0) > 86.0 or position_on_floor.y < FLOOR - 43.0:
		return
	if not room.loot.is_empty():
		receive(room.loot.pop_front())
		return
	if room.seal and room.enemies.is_empty():
		if room.kind == "vow" and not room.altar_used:
			room.altar_used = true
			announce("You keep the vigil. The shrine answers.")
			return
		room.seal = false
		seal = true
		sound("relic")
		announce("Dharma Seal recovered. Offer it at the east altar.")
		return
	if room.kind == "teacher":
		offer_completed_vow()
	elif room.kind in ["exit", "boss", "mini_boss"] and floor_number > 0:
		if not seal:
			announce("Search the side galleries for this dungeon's Dharma Seal.")
		elif room.kind in ["boss", "mini_boss"] and not passage:
			announce("Defeat the guardian before consecrating the gate.")
		elif not seal_active:
			seal_active = true
			sound("relic")
			announce("The Dharma Seal opens the east passage.")
		else:
			announce("The east passage stands open.")

func strike(kind := "slash") -> void:
	attack_kind = kind
	attack = 0.55 if kind == "thrust" else 0.40
	contact = attack - (0.215 if kind == "thrust" else 0.195)
	swing_pending = true
	sound("slash")
	animation = kind
	anim_time = 0.0

func guard_point(enemy: Dictionary) -> Vector2:
	var profile: Dictionary = enemy.guardian
	var offset: Vector2 = profile.weak_offset
	return Vector2(enemy.x + offset.x * enemy.direction, FLOOR + offset.y)

func resolve_swing() -> void:
	var thrust := attack_kind == "thrust"
	var reach := 105.0 if thrust else 73.0
	var plane := position_on_floor - Vector2(0, 31)
	if trial.active():
		trial.hit_bell(self, plane, reach, facing)
		return
	for i in range(projectiles.size() - 1, -1, -1):
		var bolt: Dictionary = projectiles[i]
		var distance: Vector2 = bolt.at - plane
		if bolt.cuttable and distance.x * facing >= -12 and absf(distance.x) < reach and absf(distance.y) < 28:
			mark_combat("spark", bolt.at, 0.63)
			projectiles.remove_at(i)
	for enemy in room.enemies.duplicate():
		var delta := Vector2(enemy.x, enemy.y - (33.0 if enemy.role == "gorgon" else 36.0)) - plane
		var profile: Dictionary = enemy.guardian
		var radius := 0.0
		if enemy.role == "boss" and realm == 1 and enemy.rite_clock >= 17.7 and enemy.rite_hits < 2:
			var bloom := lotus_focus(enemy) - plane
			if absf(bloom.x) < reach and absf(bloom.y) < 41.0 and bloom.x * facing >= -12.0:
				enemy.rite_hits += 1
				mark_combat("spark", lotus_focus(enemy), 0.76)
				sound("hit")
				if enemy.rite_hits == 2:
					announce("The healing lotus breaks.")
				continue
		if not profile.is_empty():
			if profile.background:
				delta = guard_point(enemy) - plane
				radius = profile.weak_radius * 0.35
			elif enemy.role == "boss" and realm >= 6 and not (realm == 9 and enemy.phase == 4):
				delta.x -= signf(delta.x) * minf(absf(delta.x), 39.0 if realm == 9 else 33.0)
		if absf(delta.y) > (24.0 if thrust else 34.0) + radius or absf(delta.x) > reach + radius or (delta.x * facing < 0 and absf(delta.x) >= 20.0):
			continue
		if not profile.is_empty() and not enemy.timeline.weak:
			if enemy.get("awake", false) and not profile.background:
				enemy.armored_flash = 0.15
				hit_stop = 0.022
				sound("guard")
			continue
		if enemy.role == "shield" and (position_on_floor.x - enemy.x) * enemy.direction >= -8.0:
			enemy.shield_flash = 0.18
			hit_stop = 0.028
			sound("guard")
			continue
		enemy.hp -= 1 if profile.is_empty() else Patterns.percent(enemy.max_hp, thrust, profile)
		enemy.flash = 0.20
		hit_stop = 0.032
		sound("hit")
		if enemy.hp <= 0:
			defeat_enemy(enemy)

func defeat_enemy(enemy: Dictionary) -> void:
	room.enemies.erase(enemy)
	if enemy.role == "boss" and realm == 9 and floor_number > 0 and floor_number % 100 == 0:
		projectiles.clear()
		contact_marks.clear()
		attack = 0.0
		heal_time = 0.0
		dodge = 0.0
		recoil = 0.0
		message_time = 0.0
		facing = 1 if position_on_floor.x < 480.0 else -1
		set_animation("idle")
		trial.begin(position_on_floor.x, endless)
		return
	enemy.dead_at = elapsed
	enemy.death_impact = false
	room.defeated.append(enemy)
	if not enemy.guardian.is_empty():
		projectiles.clear()
	match enemy.role:
		"boss":
			passage = true
			if endless:
				seal_active = true
				announce("The east passage stands open.")
			else:
				memories.append(Lore.REALMS[realm][5])
				ashes += 2
				save_profile()
				announce("Passage Relic and Ashes of the Sangha recovered.")
		"mini_boss":
			passage = true
			if endless:
				seal_active = true
				announce("The east passage stands open.")
			else:
				ashes += 1
				save_profile()
				announce("The guardian has fallen. Offer the Dharma Seal at the gate.")
		"side_boss":
			passage = true
			seal_active = true
			var id: String = Legacy.QUESTS[quest].id
			award(id)
			var keepsake := Legacy.award_detail(id)
			keepsake.x = clampf(enemy.x + 17.0, 130, 790)
			room.keepsake = keepsake
		"intro_boss":
			passage = true
			seal_active = true
			announce("The First Gate stands open.")
		_:
			if room.seal and room.enemies.is_empty():
				announce("The guardian fell. Collect its Dharma Seal at the altar.")

func set_animation(next: String) -> void:
	if animation != next:
		animation = next
		anim_time = 0.0

func _physics_process(dt: float) -> void:
	message_time -= dt
	queue_redraw()
	update_controller()
	if state == "ending_smile":
		smile_age += dt
		if smile_age >= 4.8:
			floor_number = 101
			items.clear()
			vows.clear()
			state = "play"
			begin_realm()
		return
	if state != "play" or pause_menu.visible or map_open or journal_open or controls_open or inventory_open:
		return
	hit_stop -= dt
	elapsed += dt
	displayed_hp = move_toward(displayed_hp, hp, dt * 155.0)
	if hit_stop > 0.0:
		return
	for enemy in room.defeated:
		if not enemy.death_impact and elapsed - enemy.dead_at >= death_impact_time(enemy):
			enemy.death_impact = true
			if enemy.role != "vowguard" and enemy.role != "caster":
				sound("fall")
	anim_time += dt
	dropping -= dt
	heal_time -= dt
	var keys := int(Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT))
	var moving := float(keys) if keys != 0 else controller.axis.x
	if heal_time > 1.16 or trial.cinematic():
		moving = 0.0
	attack -= dt
	invincible -= dt
	dodge -= dt
	dodge_recovery -= dt
	gate_reveal = move_toward(gate_reveal, 1.0 if seal_active else 0.0, dt * 1.54)
	stagger -= dt
	recoil = move_toward(recoil, 0.0, dt * 900.0)
	if moving != 0 and attack <= 0 and dodge <= 0 and stagger <= 0.0:
		facing = 1 if moving > 0.0 else -1
	var delta_x := recoil if stagger > 0.0 else moving * (40.0 if attack > 0.0 else 237.0)
	if attack_kind == "thrust" and attack > 0.23 and attack < 0.39 and grounded:
		delta_x += facing * 150.0
	var next_x := position_on_floor.x + (facing * 470.0 if dodge > 0 else delta_x) * dt
	position_on_floor.x = shield_body_clamp(next_x)
	cross_gallery_edge()
	var previous_y := position_on_floor.y
	vertical_speed += (1550.0 if vertical_speed < 0 and not jump_held() else 1110.0) * dt
	position_on_floor.y += vertical_speed * dt
	grounded = false
	if vertical_speed >= 0:
		for platform in platforms:
			if dropping > 0.0 and absf(platform.position.y - drop_y) < 3.0:
				continue
			if position_on_floor.x > platform.position.x and position_on_floor.x < platform.end.x and previous_y <= platform.position.y + 1 and position_on_floor.y >= platform.position.y:
				land_on(platform.position.y)
				break
		if position_on_floor.y >= FLOOR and previous_y <= FLOOR + 1.0 and not over_gap():
			land_on(FLOOR)
			last_safe_x = position_on_floor.x
	if position_on_floor.y > 553.0:
		position_on_floor.x = last_safe_x
		land_on(FLOOR)
		if floor_number >= 0:
			hurt_player(17)
		if state != "play":
			return
	if swing_pending and attack <= contact:
		swing_pending = false
		resolve_swing()
	if stagger > 0.0:
		set_animation("hurt")
	elif attack <= 0.0:
		set_animation(("jump" if vertical_speed < 0 else "fall") if not grounded else ("run" if moving != 0 or dodge > 0 else "idle"))
	for enemy in room.enemies:
		update_enemy(enemy, dt)
		if state != "play":
			break
	update_projectiles(dt)
	if state == "play" and trial.active():
		trial.step(self, dt)
	update_camera(dt)

func jump_held() -> bool:
	return Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP) or controller.axis.y < -0.55

func shield_body_clamp(next_x: float) -> float:
	if position_on_floor.y < FLOOR - 48.0:
		return next_x
	var current := position_on_floor.x
	for enemy in room.enemies:
		if enemy.role != "shield":
			continue
		var x: float = enemy.x
		if current <= x and next_x > current and next_x > x - 27.0:
			next_x = minf(next_x, x - 27.0)
		elif current > x and next_x < current and next_x < x + 27.0:
			next_x = maxf(next_x, x + 27.0)
	return next_x

func over_gap() -> bool:
	return position_on_floor.x > gap.x and position_on_floor.x < gap.y

func guardian_arena_sealed() -> bool:
	return trial.active() or (room.kind in BOSS_GALLERIES and not room.enemies.is_empty()
		and room.enemies[0].get("awake", false))

func cross_gallery_edge() -> void:
	if room.has("walk_bounds"):
		var bounds: Vector2 = room.walk_bounds
		position_on_floor.x = clampf(position_on_floor.x, bounds.x, bounds.y)
		return
	if guardian_arena_sealed() and position_on_floor.x < 29.0:
		position_on_floor.x = 29.0
		return
	var direction := -1
	if position_on_floor.x < 24.0:
		direction = 3
	elif position_on_floor.x >= Dungeon.SIZE - 24.0:
		direction = 1
	if direction == -1:
		return
	if direction in room.links:
		var neighbor: Vector2i = point + Dungeon.DIRECTIONS[direction]
		if not data.rooms[neighbor].hidden:
			if position_on_floor.x < 0.0 or position_on_floor.x >= Dungeon.SIZE:
				enter_room(neighbor, fposmod(position_on_floor.x, Dungeon.SIZE), true)
			return
	position_on_floor.x = clampf(position_on_floor.x, 24.0, Dungeon.SIZE - 24.0)

func update_camera(dt: float, snap: bool = false) -> void:
	if trial.active():
		var arena_x := point.x * Dungeon.SIZE
		camera_x = lerpf(camera_x, arena_x, 1.0 - exp(-5.0 * dt)) if trial.phase == VajraTrial.Phase.SILENCE else arena_x
		backdrop.scroll(camera_x, point.y)
		return
	var camera_min := point.x
	var camera_max := point.x
	while data.rooms.has(Vector2i(camera_min - 1, point.y)) and not data.rooms[Vector2i(camera_min - 1, point.y)].hidden:
		camera_min -= 1
	while data.rooms.has(Vector2i(camera_max + 1, point.y)) and not data.rooms[Vector2i(camera_max + 1, point.y)].hidden:
		camera_max += 1
	var target := clampf(point.x * Dungeon.SIZE + position_on_floor.x - (480.0 - facing * 55.0),
		camera_min * Dungeon.SIZE, camera_max * Dungeon.SIZE)
	camera_x = target if snap else lerpf(camera_x, target, 1.0 - exp(-8.0 * dt))
	backdrop.scroll(camera_x, point.y)

func land_on(y: float) -> void:
	position_on_floor.y = y
	vertical_speed = 0.0
	grounded = true

func update_enemy(enemy: Dictionary, dt: float) -> void:
	var initial_x: float = enemy.x
	enemy.flash -= dt
	enemy.recover = maxf(0.0, float(enemy.recover) - dt)
	enemy.shield_flash -= dt
	enemy.armored_flash -= dt
	enemy.clock_animation += dt
	match enemy.role:
		"vowguard", "gorgon", "elite":
			update_mob(enemy, dt)
		"shield":
			update_shield(enemy, dt)
		"caster":
			update_caster(enemy, dt)
		_:
			update_boss(enemy, dt)
	enemy.moving = absf(float(enemy.x) - initial_x) > 0.1

func update_boss(enemy: Dictionary, dt: float) -> void:
	if position_on_floor.x < float(enemy.wake_x) and not enemy.get("awake", false):
		return
	enemy.awake = true
	var profile: Dictionary = enemy.guardian
	var timeline: Dictionary = enemy.timeline
	var distance: float = position_on_floor.x - enemy.x
	var hp_fraction := float(enemy.hp) / float(enemy.max_hp)
	var rage := hp_fraction <= (0.52 if profile.major else 0.40)
	if enemy.role == "boss" and realm == 1:
		update_lotus_rite(enemy, dt)
	if timeline.phase == "idle":
		if enemy.role == "boss" and realm == 9:
			var phase := clampi(int(5.0 * (1.0 - hp_fraction)), 0, 4)
			if phase != enemy.phase:
				enemy.phase = phase
				var standard: Array[Dictionary] = Encounters.reflection_rotation() if phase == 4 else profile.standard
				profile.attacks = Patterns.variant(standard, Patterns.VAJRA_FORMS[phase], realm, true, false)
				profile.stride = 192.0 if phase == 4 else 118.0 + phase * 10.0
				timeline.attack_index = -1
				announce("Vajrakala takes the form of " + Lore.PHASES[phase] + ".")
		elif rage and enemy.phase == 0:
			enemy.phase = 1
			timeline.attack_index = -1
			if enemy.role == "boss":
				announce(Patterns.PHASE_NAMES[realm][1])
		if not profile.background:
			if absf(distance) > 1.0:
				enemy.direction = 1 if distance > 0.0 else -1
			if absf(distance) > 86.0:
				var previous: float = enemy.x
				var stride := float(profile.stride) * (1.29 if rage else 1.0)
				var lane := guardian_lane(enemy)
				enemy.x = clampf(move_toward(enemy.x, position_on_floor.x, stride * dt), lane.x, lane.y)
				enemy.walk += absf(enemy.x - previous)
	var current := Encounters.attack(profile, timeline)
	if timeline.phase == "windup" and timeline.elapsed < float(current.windup) * 0.28:
		if current.has("signature") or current.kind in ["chain", "rain", "pillars", "bell_drop"]:
			enemy.target = move_toward(enemy.target, position_on_floor.x, dt * 440.0)
	var events := Encounters.step(timeline, profile, dt * (1.13 if rage and timeline.phase in ["windup", "idle"] else 1.0), true)
	var move := Encounters.attack(profile, timeline)
	for event in events:
		match event:
			"windup":
				enemy.target = position_on_floor.x
				enemy.target_y = position_on_floor.y - 31.0
				enemy.hit = false
				enemy.released = false
				enemy.launch_x = enemy.x
				enemy.bell_landed = false
				if profile.background:
					var exposed_x: float = enemy.x - absf(profile.weak_offset.x)
					enemy.direction = -1 if exposed_x > 80.0 and (realm == 8 or timeline.serial % 2 == 1 or enemy.x > 795.0) else 1
				Actions.prepare(enemy, enemy.direction)
			"wake_finished":
				sound("wake")
			"recover":
				enemy.y = FLOOR
	if timeline.phase != "active":
		return
	var progress := Sequence.ratio(timeline.elapsed, move.active)
	if move.has("signature"):
		Actions.run(self, enemy, move, progress, dt, rage)
		return
	if move.kind != "bell_drop" and not enemy.released and progress >= Sequence.release(move.kind):
		enemy.released = true
		execute_boss_attack(enemy, move, rage)
	if move.kind == "bell_drop":
		advance_bell_drop(enemy, move, progress)
	elif move.kind == "charge":
		var lane := guardian_lane(enemy)
		enemy.x = clampf(enemy.x + enemy.direction * float(move.speed) * dt, lane.x, lane.y)
		if enemy.released and absf(position_on_floor.x - enemy.x) < float(move.reach) and position_on_floor.y > FLOOR - 67.0 and not enemy.hit:
			enemy.hit = true
			hurt_by_guardian(enemy.x)
	elif move.kind == "sweep" and enemy.released and progress <= 0.83:
		var projected: float = (position_on_floor.x - enemy.x) * enemy.direction
		var blade: float = float(move.reach) * minf(1.0, 0.58 + progress * 0.65)
		if projected > -20.0 and projected < blade and position_on_floor.y > FLOOR - 61.0 and not enemy.hit:
			enemy.hit = true
			hurt_by_guardian(enemy.x)

func advance_bell_drop(enemy: Dictionary, move: Dictionary, progress: float) -> void:
	var jump := clampf(progress / Sequence.release("bell_drop"), 0.0, 1.0)
	var landing_x := clampf(float(enemy.target), 104.0, 848.0)
	enemy.x = lerpf(float(enemy.launch_x), landing_x, smoothstep(0.0, 1.0, jump))
	enemy.y = FLOOR - sin(jump * PI) * 149.0
	if jump < 1.0 or enemy.bell_landed:
		return
	enemy.bell_landed = true
	mark_combat("quake", Vector2(landing_x, FLOOR), 1.45)
	sound("fall")
	if absf(position_on_floor.x - landing_x) < float(move.reach) and position_on_floor.y > FLOOR - 49.0:
		hurt_by_guardian(landing_x)
	for side in [-1, 1]:
		add_projectile(Vector2(landing_x + side * 31.0, FLOOR - 12.0), Vector2(side * move.speed, 0.0),
			"wave", 9.0, 0.0, 1.7, move.damage, false, 0.0, true)

func lotus_bloom(enemy: Dictionary) -> Vector2:
	return Vector2(enemy.x - 77.0, FLOOR - 205.0)

func lotus_focus(enemy: Dictionary) -> Vector2:
	return Vector2(enemy.x - 123.0, FLOOR - 62.0)

func update_lotus_rite(enemy: Dictionary, dt: float) -> void:
	var previous: float = enemy.rite_clock
	enemy.rite_clock += dt
	enemy.rite_light = maxf(0.0, float(enemy.rite_light) - dt)
	if previous < 17.7 and enemy.rite_clock >= 17.7:
		enemy.rite_hits = 0
		sound("guard")
		announce("The lotus gathers light. Sever its glowing root.")
	if enemy.rite_clock < 20.0:
		return
	enemy.rite_clock -= 20.0
	if enemy.rite_hits < 2:
		enemy.hp = mini(enemy.max_hp, enemy.hp + roundi(float(enemy.max_hp) * 0.20))
		enemy.rite_light = 1.10
		sound("shrine")
	enemy.rite_hits = 0

func guardian_art_index(enemy: Dictionary) -> int:
	if enemy.role == "boss" and realm == 9:
		return [9, 8, 7, 4, 5][enemy.phase]
	return int(enemy.quest_art) if enemy.role == "side_boss" else int(enemy.art_realm)

func guardian_render_scale(enemy: Dictionary) -> float:
	if enemy.role == "boss":
		return Animations.BOSS_SCALES[guardian_art_index(enemy)]
	return 1.0

func guardian_lane(enemy: Dictionary) -> Vector2:
	if enemy.role == "boss" and realm >= 6 and not (realm == 9 and enemy.phase == 4):
		return Vector2(150, 810)
	return Vector2(72, 885)

func attack_socket(enemy: Dictionary, pose: String, progress: float) -> Vector2:
	var feet := Vector2(enemy.x, enemy.y)
	var profile: Dictionary = enemy.guardian
	if enemy.role == "boss" and realm == 9 and enemy.phase == 4:
		return feet + Vector2(enemy.direction * 26.0, -35.0)
	var factor := guardian_render_scale(enemy)
	if profile.get("background", false):
		feet.y -= 9.0
	return Animations.socket(encounter_kind(enemy.role), guardian_art_index(enemy), feet, enemy.direction,
		pose, Sequence.frame(progress), factor)

func marked_targets(enemy: Dictionary, move: Dictionary, rage: bool) -> Array[float]:
	var count := maxi(1, int(move.projectiles))
	if move.kind == "chain":
		count = 2 if rage and realm == 0 else 1
	return Sequence.remote_origins(move.kind, enemy.target, count)

func bell_staff_strike(enemy: Dictionary) -> bool:
	return enemy.role == "boss" and guardian_art_index(enemy) == 7

func wave_origin_x(enemy: Dictionary) -> float:
	if bell_staff_strike(enemy):
		var staff := attack_socket(enemy, "smash", Sequence.release("waves"))
		return clampf(staff.x, 54.0, 906.0)
	return enemy.x + float(enemy.direction) * 24.0

func guardian_damage(move: Dictionary, rage: bool) -> int:
	return int(move.damage) + (2 if rage else 0)

func execute_boss_attack(enemy: Dictionary, move: Dictionary, rage: bool) -> void:
	var initial_count := projectiles.size()
	var style: String = move.kind
	var pose := Sequence.clip(style, "active")
	var progress: float = Sequence.ratio(enemy.timeline.elapsed, move.active)
	var origin := attack_socket(enemy, pose, progress)
	var target := Vector2(enemy.target, enemy.target_y)
	var damage := guardian_damage(move, rage)
	var count := maxi(1, int(move.projectiles))
	match style:
		"charge":
			mark_combat("dust", Vector2(enemy.x, FLOOR), 0.64)
			sound("dodge")
		"chain":
			mark_combat("spark", origin, 0.82)
			sound("guard")
			for x in marked_targets(enemy, move, rage):
				add_projectile(Vector2(x, FLOOR - Sequence.CHAIN_DROP_HEIGHT), Vector2(0, 490),
					"chain", 12.0, 70.0, 0.67, damage, false)
		"fan":
			mark_combat("spark", origin, 1.08)
			sound("slash")
			var shot_style: String = Run.ROSTERS[realm][3]
			var direction := origin.direction_to(target)
			for i in range(count):
				var spacing := float(i) - (count - 1) * 0.5
				if shot_style == "venom":
					var landing := Vector2(clampf(target.x + spacing * 51.0, 42.0, 918.0), FLOOR - 16.0)
					var crossing := clampf(absf(origin.x - landing.x) / float(move.speed), 0.56, 1.24)
					var velocity := (landing - origin) / crossing - Vector2(0.0, 124.0 * crossing)
					add_projectile(origin, velocity, shot_style, 8.0, 248.0, 1.65, damage)
				else:
					add_projectile(origin, direction.rotated(spacing * 0.20) * float(move.speed), shot_style, 8.0, 0.0, 3.6, damage)
		"pillars":
			mark_combat("spark", origin, 0.82)
			sound("fall")
			for x in marked_targets(enemy, move, rage):
				mark_combat("ground", Vector2(x, FLOOR), 0.74)
				add_projectile(Vector2(x, FLOOR - 5), Vector2(0, -278), "surge", 15.0, 0.0, 0.65, damage, false)
		"waves":
			var foot := Vector2(wave_origin_x(enemy), FLOOR)
			mark_combat("quake", foot, 1.21)
			sound("fall")
			for i in range(count):
				var side := -1.0 if i % 2 == 0 else 1.0
				var rank := floori(float(i) / 2.0)
				var height := 13.0 + rank * 43.0
				var variant := "wave" if rank == 0 else "wave_air"
				var delay := 0.21 * rank if bell_staff_strike(enemy) else 0.0
				add_projectile(foot + Vector2(side * 15.0, -height), Vector2(side * float(move.speed), 0), variant,
					13.0, 0.0, 3.1, damage - (9 if delay > 0.0 else 0), false, delay)
		"rain":
			mark_combat("spark", origin, 0.98)
			var targets := marked_targets(enemy, move, rage)
			for i in range(targets.size()):
				add_projectile(Vector2(targets[i], 112.0 - i * 7.0), Vector2(0.0, float(move.speed)),
					"rain", 8.0, 66.0, 1.42, damage, false)

	for index in range(initial_count, projectiles.size()):
		projectiles[index].guardian = true

func cue_mob_attack(enemy: Dictionary, time: float) -> void:
	enemy.windup_span = time
	enemy.windup = time
	enemy.released = false

func enter_mob_attack(enemy: Dictionary, time: float) -> void:
	enemy.follow_span = time
	enemy.follow = time
	enemy.hit = false
	enemy.released = false

func progress_mob_attack(enemy: Dictionary, dt: float) -> float:
	enemy.follow = maxf(0.0, float(enemy.follow) - dt)
	if enemy.follow == 0.0:
		enemy.recover = 0.18
	return Sequence.ratio(float(enemy.follow_span) - float(enemy.follow), enemy.follow_span)

func ordinary_attack(enemy: Dictionary) -> String:
	match enemy.role:
		"gorgon": return "dive"
		"caster": return "fan"
		"shield": return "bash"
		_: return "charge" if RegionalMobs.MELEE[realm][2] > 0.0 else "sweep"

func update_shield(enemy: Dictionary, dt: float) -> void:
	var stance: Array = RegionalMobs.SHIELD[realm]
	var reach: float = stance[1]
	var delta: float = position_on_floor.x - enemy.x
	if absf(delta) > 354.0:
		return
	if enemy.follow > 0.0:
		var contact := progress_mob_attack(enemy, dt)
		if contact >= Sequence.release("bash") and not enemy.released:
			enemy.released = true
			var tip := attack_socket(enemy, "bash", contact)
			mark_combat("spark", tip, 0.64)
			if delta * enemy.direction > 0.0 and absf(delta) < reach and position_on_floor.y > FLOOR - 58.0:
				hurt_player(enemy.damage, enemy.x)
		enemy.guarding = enemy.follow <= 0.0
		return
	if enemy.windup > 0.0:
		enemy.windup -= dt
		if enemy.windup <= 0.0:
			enemy.guarding = false
			enter_mob_attack(enemy, 0.29)
		return
	if enemy.recover > 0.0:
		return
	enemy.guarding = true
	if delta * enemy.direction < -10.0:
		enemy.guard_turn += dt
		if enemy.guard_turn + 0.0001 < Encounters.SHIELD_TURN_SECONDS:
			return
		enemy.direction *= -1
		enemy.guard_turn = 0.0
	else:
		enemy.guard_turn = 0.0
	enemy.clock -= dt
	if absf(delta) > reach - 5.0:
		var left := 44.0 if gap == Vector2.ZERO else gap.y + 23.0
		var before: float = enemy.x
		enemy.x = clampf(move_toward(enemy.x, position_on_floor.x, stance[0] * dt), left, 910.0)
		enemy.walk += absf(enemy.x - before)
	elif enemy.clock <= 0.0:
		cue_mob_attack(enemy, stance[2])
		enemy.clock = 1.49

func update_caster(enemy: Dictionary, dt: float) -> void:
	var pressure := Run.difficulty(floor_number)
	var distance: float = position_on_floor.x - enemy.x
	if enemy.windup > 0.0:
		enemy.windup -= dt
		if enemy.windup <= 0.0:
			enter_mob_attack(enemy, 0.32)
		return
	if enemy.follow > 0.0:
		var contact := progress_mob_attack(enemy, dt)
		if contact >= Sequence.release("fan") and not enemy.released:
			enemy.released = true
			var source := attack_socket(enemy, "cast", contact)
			mark_combat("spark", source, 0.59)
			launch_shots(source, Vector2(enemy.target, enemy.target_y), Run.ROSTERS[realm][3], false, enemy.damage)
		return
	if absf(distance) > 460.0 or enemy.recover > 0.0:
		return
	enemy.direction = -1 if distance < 0 else 1
	if absf(distance) < RegionalMobs.CASTER_RETREAT[realm]:
		var low := 49.0 if gap == Vector2.ZERO else gap.y + 28.0
		enemy.x = clampf(enemy.x - float(enemy.direction) * 56.0 * dt, low, 904.0)
	enemy.clock -= dt
	if enemy.clock <= 0.0:
		enemy.clock = maxf(1.05, 2.16 - pressure * 0.12)
		cue_mob_attack(enemy, maxf(0.26, 0.56 - pressure * 0.032))
		enemy.target = position_on_floor.x
		enemy.target_y = position_on_floor.y - 33.0

func update_mob(enemy: Dictionary, dt: float) -> void:
	var flying: bool = enemy.role == "gorgon"
	var melee: Array = RegionalMobs.MELEE[realm]
	var flight: Array = RegionalMobs.FLIGHT[realm]
	var low := 44.0 if flying or gap == Vector2.ZERO else gap.y + 21.0
	var pressure := Run.difficulty(floor_number)
	var distance: float = position_on_floor.x - enemy.x
	if enemy.windup > 0:
		enemy.windup -= dt
		if enemy.windup <= 0:
			enter_mob_attack(enemy, 0.72 if flying else 0.28)
		return
	if enemy.follow > 0:
		var contact := progress_mob_attack(enemy, dt)
		var style := ordinary_attack(enemy)
		if flying:
			var dive := sin(contact * PI)
			enemy.x = clampf(enemy.x + enemy.direction * (flight[2] + minf(58.0, pressure * 8.0)) * dt, low, Dungeon.SIZE - 40.0)
			enemy.y = flight[0] + pow(maxf(0.0, dive), flight[4]) * flight[3]
		elif melee[2] > 0.0 and contact >= 0.16:
			enemy.x = clampf(enemy.x + enemy.direction * melee[2] * dt, low, Dungeon.SIZE - 44.0)
		distance = position_on_floor.x - enemy.x
		if contact >= Sequence.release(style) and not enemy.released:
			enemy.released = true
			if not flying and style == "charge":
				mark_combat("dust", Vector2(enemy.x, FLOOR), 0.49)
		var reach: float = 32.0 if flying else melee[1]
		var in_front: bool = flying or distance * enemy.direction > -17.0
		var aligned: bool = absf(enemy.y - position_on_floor.y) < (37.0 if flying else 39.0)
		if enemy.released and contact < 0.86 and not enemy.hit and in_front and aligned and absf(distance) < reach and invincible <= 0:
			enemy.hit = true
			hurt_player(enemy.damage, enemy.x)
		return
	if absf(distance) > 337.0:
		return
	enemy.direction = -1 if distance < 0.0 else 1
	enemy.clock -= dt
	if flying:
		enemy.y = move_toward(enemy.y, flight[0] + cos(elapsed * (2.5 + realm * 0.12) + enemy.home) * 11.0, 115.0 * dt)
	if enemy.flash > 0 or enemy.recover > 0.0:
		return
	var attack_distance: float = 124.0 + flight[2] * 0.14 if flying else melee[1] + melee[2] * 0.18 + 9.0
	if enemy.clock <= 0 and absf(distance) < attack_distance:
		cue_mob_attack(enemy, maxf(0.29, (0.56 if flying else melee[3]) - pressure * 0.027))
		enemy.clock = maxf(0.62, (1.28 if flying else melee[4]) - pressure * 0.06)
		return
	if absf(distance) > attack_distance - (22.0 if flying else 13.0):
		var previous: float = enemy.x
		var speed: float = (flight[1] if flying else melee[0]) + minf(60.0, pressure * 8.0)
		enemy.x = clampf(move_toward(enemy.x, position_on_floor.x, speed * dt), low, Dungeon.SIZE - 44.0)
		enemy.walk += absf(previous - enemy.x)


func launch_shots(origin: Vector2, target: Vector2, style: String, heavy := false, damage := 11) -> void:
	var direction := origin.direction_to(target)
	var speed := 164.0 + minf(128.0, Run.difficulty(floor_number) * 16.0)
	var angles: Array = [0.0]
	match style:
		"petal", "orbit", "wheel":
			angles = [-0.24, 0.0, 0.24]
		"mirror":
			angles = [-0.16, 0.16]
		"script":
			angles = [-0.36, 0.0, 0.36]
		"lance":
			speed *= 1.27
		"venom":
			direction = (direction + Vector2(0, -0.49)).normalized()
		"bell", "echo":
			speed *= 0.78
	if heavy and angles.size() == 1:
		angles = [-0.20, 0.20]
	for angle in angles:
		add_projectile(origin, direction.rotated(angle) * speed, style, 8.0 if heavy else 5.0, 110.0 if style == "venom" else 0.0, 4.2, damage)

func mark_combat(kind: String, at: Vector2, strength: float) -> void:
	var life: float = {"quake": 0.58, "ground": 0.49, "dust": 0.39}.get(kind, 0.27)
	if contact_marks.size() >= 50:
		contact_marks.pop_front()
	contact_marks.append({"kind": kind, "at": at, "born": elapsed, "age": 0.0, "scale": strength, "life": life,
		"tint": Color(Run.ROSTERS[realm][4])})

func add_projectile(origin: Vector2, velocity: Vector2, style: String, radius: float, gravity: float, life: float,
		damage := 12, cuttable := true, delay := 0.0, guardian := false) -> void:
	projectiles.append({
		"at": origin, "velocity": velocity, "style": style, "r": radius, "gravity": gravity,
		"life": life, "age": -delay, "damage": damage, "cuttable": cuttable, "settled": false, "guardian":guardian,
		"anchor_y": origin.y - 10.0, "wake_x": origin.x, "color": Color(Run.ROSTERS[realm][4])
	})

func impact_surface(before: Vector2, after: Vector2, tip: float) -> float:
	var floor_y := FLOOR if not (after.x > gap.x and after.x < gap.y) else INF
	for platform in platforms:
		if after.x >= platform.position.x and after.x <= platform.end.x and before.y + tip <= platform.position.y:
			floor_y = minf(floor_y, platform.position.y)
	if before.y + tip <= floor_y and after.y + tip >= floor_y:
		return floor_y
	return INF

func advance_payload(shot: Dictionary, dt: float) -> bool:
	shot.age += dt
	if shot.age < 0.0:
		return true
	if shot.age > shot.life:
		return false
	if shot.settled or shot.style == "sig_column":
		return true
	var turn: float = shot.get("turn_at", -1.0)
	if turn > 0.0 and (shot.age >= turn or shot.at.x < 51.0 or shot.at.x > 909.0):
		shot.velocity.x *= -1.0
		shot.heading *= -1
		shot.turn_at = -1.0
	var before: Vector2 = shot.at
	shot.velocity.y += shot.gravity * dt
	shot.at += shot.velocity * dt
	var style: String = shot.style
	if style == "surge":
		var rise := smoothstep(0.0, 0.27, float(shot.age))
		var fall := smoothstep(0.40, float(shot.life), float(shot.age))
		shot.at.y = FLOOR - (5.0 + 132.0 * rise) * (1.0 - fall)
	elif style in ["orbit", "echo", "bell"]:
		shot.at.y += sin(shot.age * 10.0) * dt * 42.0
	elif style in ["chain", "rain"] and shot.velocity.y > 0.0:
		var tip := 11.0 if style == "chain" else 5.0
		var contact := impact_surface(before, shot.at, tip)
		if is_finite(contact):
			mark_combat("ground" if style == "chain" else "spark", Vector2(shot.at.x, contact), 0.90 if style == "chain" else 0.59)
			if style != "chain":
				return false
			shot.at.y = contact - tip
			shot.settled = true
			shot.life = float(shot.age) + 0.18
			shot.velocity = Vector2.ZERO
			sound("fall")
	elif style == "wave":
		if shot.at.x > gap.x and shot.at.x < gap.y:
			return false
		if absf(float(shot.at.x) - float(shot.wake_x)) >= 38.0 and absf(float(shot.at.x) - 480.0) < 480.0:
			shot.wake_x = shot.at.x
			mark_combat("dust", Vector2(shot.at.x - signf(shot.velocity.x) * 13.0, FLOOR), 0.39)
	if shot.get("floor_contact", false) and shot.velocity.y > 0.0:
		var floor_y := impact_surface(before, shot.at, 4.0)
		if is_finite(floor_y):
			mark_combat("ground", Vector2(shot.at.x, floor_y), 0.64)
			shot.at.y = floor_y - 7.0
			shot.life = minf(shot.life, float(shot.age) + 0.13)
			shot.settled = true
	var ceiling := 31.0 if style in ["rain", "sig_shot"] else 79.0
	return Rect2(-30.0, ceiling, 1022.0, FLOOR + 4.0 - ceiling).has_point(shot.at)

func payload_overlaps(shot: Dictionary, body: Vector2) -> bool:
	var offset: Vector2 = body - shot.at
	if shot.style == "sig_column":
		return float(shot.age) >= 0.12 and float(shot.age) <= 0.44 and absf(offset.x) < float(shot.r) and body.y > float(shot.top_y) - 12.0
	if shot.style == "surge":
		return shot.at.y < FLOOR - 17.0 and absf(offset.x) < 21.0 and body.y > float(shot.at.y) - 9.0 and body.y < FLOOR
	if shot.style == "wave":
		return absf(offset.x) < 26.0 and body.y > FLOOR - 49.0 and body.y < FLOOR + 2.0
	return Vector2(offset.x * 1.12, offset.y * 0.78).length() < float(shot.r) + 12.0

func update_projectiles(dt: float) -> void:
	if state != "play":
		return
	for i in range(projectiles.size() - 1, -1, -1):
		var shot: Dictionary = projectiles[i]
		if not advance_payload(shot, dt):
			projectiles.remove_at(i)
			continue
		if float(shot.age) < 0.0 or invincible > 0.0 or not payload_overlaps(shot, position_on_floor - Vector2(0, 31)):
			continue
		if shot.cuttable:
			projectiles.remove_at(i)
		if shot.guardian:
			hurt_by_guardian(shot.at.x)
		else:
			hurt_player(shot.damage, shot.at.x)
		if state != "play":
			return
	for i in range(contact_marks.size() - 1, -1, -1):
		var mark: Dictionary = contact_marks[i]
		mark.age = elapsed - float(mark.born)
		if mark.age >= mark.life:
			contact_marks.remove_at(i)

func hurt_by_guardian(origin_x: float) -> void:
	hurt_player(ceili(float(max_hp) / 3.0), origin_x)

func hurt_player(damage: int, origin_x := INF) -> void:
	if invincible > 0:
		return
	hp = maxi(0, hp - damage)
	mark_combat("spark", position_on_floor - Vector2(0, 29), 0.71)
	sound("hurt")
	invincible = 0.64
	stagger = 0.20
	recoil = -facing * 142.0 if not is_finite(origin_x) else signf(position_on_floor.x - origin_x) * 167.0
	attack = 0.0
	swing_pending = false
	dodge = 0.0
	set_animation("hurt")
	if hp == 0:
		cycle += 1
		best_depth = Legacy.best_at_end(best_depth, floor_number)
		trial.reset()
		save_profile()
		state = "dead"
		seed_menu.update_profile(best_depth, awards)
		seed_menu.present("SAMSARA", "ANOTHER CYCLE", "You carry %d Ashes of the Sangha into your next life. Keep this seed to retrace your route, or roll another." % ashes, "Begin another cycle")

func hundred_hands_defeated(rematch: bool) -> void:
	last_ending_floor = floor_number
	passage = true
	seal_active = true
	if rematch:
		award(Legacy.milestone_id(floor_number))
		return
	award(Legacy.VAJRA_ID)
	best_depth = Legacy.best_at_end(best_depth, floor_number)
	save_profile()
	ending = "The Vow" if vows.values().count(true) >= 2 else "The Crown"
	end_text = "The last bell lies broken. The road below still descends."
	state = "ending_choice"
	choice.present(ending, end_text, ["Continue", "Exit"], 0, int(Legacy.award_detail(Legacy.VAJRA_ID).icon))

func label(at: Vector2, value: String, size: int = 18, color: Color = WHITE) -> void:
	draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(at: Vector2, value: String, size: int = 18, color: Color = WHITE) -> void:
	var width := ThemeDB.fallback_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label(at - Vector2(width / 2, 0), value, size, color)

func panel(rect: Rect2) -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#080d148a"))
	UI.engraved(self, rect, Color("#151b22f8"), Color("#937451"))
	UI.engraved(self, rect.grow(-7.0), Color.TRANSPARENT, Color("#514d45"))
	for corner in [rect.position, rect.end, Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y)]:
		var direction: Vector2 = corner.direction_to(rect.get_center())
		UI.sun(self, corner + direction * 13.0, 8.0, Color("#ab815a"))

func sprite(at: Vector2, name: String, time: float, direction: int, scale_factor: float, tint: Color = Color.WHITE) -> void:
	var atlas_key: String = PrinceFrames.AN[name][0] if PrinceFrames.AN.has(name) else "idle"
	var frames: Array = PrinceFrames.FR[atlas_key]
	var frame: Array = frames[PrinceFrames.fidx(name, time)] if PrinceFrames.AN.has(name) else frames[0]
	var region := Rect2(frame[0], frame[1], frame[2], frame[3])
	var width: float = frame[2] * scale_factor
	var height: float = frame[3] * scale_factor
	var x: float = at.x - (frame[4] if direction > 0 else frame[2] - frame[4]) * scale_factor
	var rect := Rect2(x, at.y - frame[5] * scale_factor, width * direction, height)
	draw_texture_rect_region(Sheet, rect, region, tint)

func _draw() -> void:
	if backdrop == null:
		return
	if state == "ending_smile":
		trial.draw_smile(self, smile_age)
		return
	if not room.is_empty():
		var tremor := 0.0
		for mark in contact_marks:
			if mark.kind == "quake" and float(mark.age) < 0.14:
				var age: float = mark.age
				tremor = roundf(float(mark.scale) * 2.4 * (1.0 - age / 0.14) * cos(age * 132.0))
		for location in data.rooms:
			var gallery: Dictionary = data.rooms[location]
			if location.y != point.y or gallery.hidden:
				continue
			var x: float = location.x * Dungeon.SIZE - camera_x
			if x < -Dungeon.SIZE or x > Dungeon.SIZE:
				continue
			draw_set_transform(Vector2(roundf(x), tremor))
			draw_passages(gallery, location)
			if location == Vector2i.ZERO and available_quest() >= 0 and state in ["play", "quest_choice"]:
				draw_quest_door()
			if location == data.gate:
				draw_exit(location == point, gallery.get("exit_x", data.get("gate_x", Dungeon.EXIT_X)))
			if not gallery.lessons.is_empty() and gallery.kind != "healing_shrine":
				draw_lessons(gallery, location == point)
			elif gallery.kind in ["healing_shrine", "rest_shrine"]:
				draw_shrine(float(gallery.get("shrine_x", 480)), gallery.altar_used)
			if location == point:
				draw_altar()
			for enemy in gallery.defeated:
				draw_defeated(enemy)
			for enemy in gallery.enemies:
				draw_enemy(enemy)
			if location == point:
				if gallery.has("keepsake"):
					draw_keepsake(gallery.keepsake)
				draw_projectiles()
				trial.bell_and_tells(self)
				draw_prince()
		draw_set_transform(Vector2.ZERO)
		draw_foreground()
		draw_hud()
	if map_open:
		draw_map()
	if journal_open:
		draw_journal()
	if controls_open:
		draw_controls()
	if inventory_open:
		draw_inventory()

func draw_keepsake(keepsake: Dictionary) -> void:
	var at := Vector2(keepsake.x, FLOOR - 54.0 + roundf(sin(elapsed * 2.6) * 3.0))
	UI.sun(self, at, 19.0, Color("#ae785c"))
	Pixels.icon(self, keepsake.icon, at - Vector2(16, 16), 32)
	if absf(position_on_floor.x - at.x) < 52.0:
		centered(at - Vector2(0, 29), "E   " + String(keepsake.item), 13, GOLD)

func draw_quest_door() -> void:
	var x := QUEST_DOOR_X
	var base := Vector2(x, FLOOR)
	Masonry.gate(self, base, 0.87, Color("#7f596c"))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-31, 0), base + Vector2(-31, -63),
		base + Vector2(-17, -87), base + Vector2(0, -96), base + Vector2(17, -87),
		base + Vector2(31, -63), base + Vector2(31, 0)]), Color("#10091ceb"))
	for i in range(10):
		var rise := fposmod(elapsed * 33 + i * 11.5, 76.0)
		var at := (base + Vector2(posmod(i * 29, 47) - 22, -rise)).round()
		draw_rect(Rect2(at, Vector2(2, 2 + i % 3)), Color("#d092bc", 0.24 + i % 4 * 0.11))
	UI.diamond(self, base + Vector2(0, -96), 5, Color("#d092bc"))
	if point == Vector2i.ZERO and absf(position_on_floor.x - x) < 63.0 and state == "play":
		centered(base + Vector2(0, -115), "E   Enter passage", 13, UI.CREAM)

func draw_passages(gallery: Dictionary, location: Vector2i) -> void:
	if location == point and 3 in gallery.links and guardian_arena_sealed():
		Masonry.gate(self, Vector2(11, FLOOR), 1.0, Color("#7c777c"))
	if not 3 in gallery.links:
		draw_end_wall(0.0)
	if not 1 in gallery.links:
		draw_end_wall(Dungeon.SIZE - 23.0)
	for direction in gallery.links:
		var neighbor: Vector2i = location + Dungeon.DIRECTIONS[direction]
		if data.rooms[neighbor].hidden:
			draw_end_wall(Dungeon.SIZE - 23.0 if direction == 1 else 0.0)
			var side_x := Dungeon.SIZE - 26.0 if direction == 1 else 26.0
			draw_polyline(PackedVector2Array([Vector2(side_x, 316), Vector2(side_x - 10, 337),
				Vector2(side_x + 8, 350), Vector2(side_x - 3, 367), Vector2(side_x + 6, 385)]), Color("#ac795f"), 2)
			if location == point and absf(position_on_floor.x - side_x) < 125.0:
				centered(Vector2(clampf(side_x, 111, 849), 301), "Q   Prayer Wheel", 15, GOLD)
		if direction != 0 and direction != 2:
			continue
		var at := Vector2(Dungeon.stair_x(direction), FLOOR)
		var tint := Color("#d1bbab").lerp(Color(Lore.REALMS[realm][3]), 0.22)
		Masonry.gate(self, at, 0.0, tint, -1 if direction == 0 else 1)
		if location == point and nearby_stair() == direction:
			centered(at + Vector2(0, -140), "E   Upper gallery" if direction == 0 else "E   Lower gallery", 14, UI.CREAM)

func draw_end_wall(x: float) -> void:
	Masonry.wall(self, x, FLOOR, Color(Lore.REALMS[realm][3]).darkened(0.12))

func draw_exit(active: bool, x: float) -> void:
	var at := Vector2(x, FLOOR)
	var tint := Color("#dfc0a4").lerp(Color(Lore.REALMS[realm][3]), 0.27)
	Masonry.gate(self, at, 1.0 - gate_reveal, tint)
	if seal_active:
		UI.flame(self, at + Vector2(0, -81), 0.63 + sin(elapsed * 8) * 0.13, Color("#fad19c"))
	if active and absf(position_on_floor.x - x) < 91.0:
		centered(at + Vector2(-7, -174), "E   East passage" if seal_active else "Sealed passage", 14, UI.CREAM)

func draw_lessons(gallery: Dictionary, active: bool) -> void:
	for lesson in gallery.get("lessons", []):
		var at := Vector2(lesson.x, 258)
		var nearby: bool = active and absf(position_on_floor.x - at.x) < 185.0
		if not nearby:
			UI.diamond(self, at + Vector2(0, 13), 4.0, Color("#ad845b"), true)
			continue
		var width := ThemeDB.fallback_font.get_string_size(lesson.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		width = minf(386.0, width + 37.0)
		var center := clampf(at.x, width / 2.0 + 13.0, 947.0 - width / 2.0)
		UI.engraved(self, Rect2(center - width / 2.0, at.y - 8.0, width, 34.0), Color("#161b24f3"), Color("#9b7757"))
		centered(Vector2(center, at.y + 13.0), lesson.text, 14, UI.CREAM)

func draw_shrine(x: float, blessed: bool) -> void:
	var base := Vector2(x, FLOOR)
	for pier_x in [253.0, 684.0]:
		draw_rect(Rect2(pier_x, 75, 23, FLOOR - 75), Color("#141923dc"))
		draw_line(Vector2(pier_x + 7, 75), Vector2(pier_x + 7, FLOOR - 18), Color("#3e3945"), 4)
		for y in [102, 123, 390, 411]:
			draw_rect(Rect2(pier_x - 6, y, 35, 5), Color("#413a43"))
	for level in range(3):
		var width := 105 - level * 18
		var y := FLOOR - 9.0 - level * 10.0
		draw_rect(Rect2(x - width / 2.0, y, width, 8), Color("#453b43").lightened(level * 0.10))
		draw_line(Vector2(x - width / 2.0, y), Vector2(x + width / 2.0, y), Color("#b6936d"), 1.0)
	var arc := base - Vector2(0, 66)
	draw_circle(arc, 28, Color("#22232c"))
	draw_arc(arc, 28, 0, TAU, 34, Color("#b5895a"), 2)
	UI.lotus(self, arc + Vector2(0, 7), 1.75, GOLD if not blessed else Color("#7c715b"))
	draw_rect(Rect2(x - 12, FLOOR - 38, 24, 6), Color("#8c6045"))
	if not blessed:
		UI.flame(self, base - Vector2(0, 43), 1.1 + sin(elapsed * 6) * 0.24, Color("#efbd7e"))
	if absf(position_on_floor.x - x) < 112.0:
		centered(base - Vector2(0, 108), "E   Rest at the shrine" if not blessed else "The flame is quiet.", 15, GOLD)

func draw_foreground() -> void:
	# Low floor haze gives the masonry depth without occluding the walkable edge.
	for band in range(7):
		var density := float(band + 1) * 0.016
		draw_rect(Rect2(0, 484 + band * 8, 960, 8), Color(0.046, 0.036, 0.069, density))

func draw_altar() -> void:
	var can_collect: bool = not room.loot.is_empty() or (room.seal and room.enemies.is_empty())
	var is_shrine: bool = not endless and (room.kind in ["teacher", "exit"] or (room.kind == "boss" and passage))
	if not can_collect and not is_shrine:
		return
	Masonry.pedestal(self, Vector2(480, FLOOR), Color(Lore.REALMS[realm][3]).lightened(0.42))
	draw_arc(Vector2(480, 376), 10 + sin(elapsed * 3) * 2, 0, TAU, 20, GOLD, 2)
	draw_circle(Vector2(480, 376), 3, GOLD)
	if absf(position_on_floor.x - 480) <= 90 and position_on_floor.y >= FLOOR - 45:
		var prompt := "Offer relics"
		if not room.loot.is_empty():
			prompt = room.loot[0]
		elif can_collect:
			prompt = "Speak to the pilgrim" if room.kind == "pilgrim" else "Dharma Seal"
		elif room.kind in ["exit", "boss"]:
			prompt = "East exit open" if seal_active else "Offer Dharma Seal"
		centered(Vector2(480, 352), "E  " + prompt, 16, GOLD)

func draw_enemy(enemy: Dictionary) -> void:
	var role: String = enemy.role
	var feet := Vector2(roundf(enemy.x), roundf(enemy.y))
	var direction: int = enemy.direction
	var accent := Color(Run.ROSTERS[realm][4])
	var tint := Color("#ffe3b7") if enemy.flash > 0.0 else Color.WHITE
	var kind := encounter_kind(role)
	var profile: Dictionary = enemy.guardian
	if role != "gorgon" and not profile.get("background", false):
		var height := maxf(0.0, FLOOR - feet.y)
		var width := 36.0 if profile.is_empty() else maxf(57.0, profile.radius * 1.45 * guardian_render_scale(enemy))
		CombatFX.shadow(self, Vector2(feet.x, FLOOR), width, clampf(1.0 - height / 195.0, 0.19, 1.0))
	if not profile.is_empty():
		draw_guardian(enemy, feet, kind, tint, accent)
		return
	var clip := "move" if enemy.get("moving", false) else "idle"
	var style := ordinary_attack(enemy)
	var progress := -1.0
	if enemy.windup > 0.0:
		clip = Sequence.clip(style, "windup")
		progress = Sequence.ratio(float(enemy.windup_span) - float(enemy.windup), enemy.windup_span)
	elif enemy.follow > 0.0:
		clip = Sequence.clip(style, "active")
		progress = Sequence.ratio(float(enemy.follow_span) - float(enemy.follow), enemy.follow_span)
	elif enemy.recover > 0.0:
		clip = Sequence.clip(style, "recovery")
		progress = Sequence.ratio(0.18 - float(enemy.recover), 0.18)
	elif role == "shield":
		clip = "guard"
	if enemy.flash > 0.12:
		Animations.draw(self, kind, realm, feet, direction, "hit", 0.20 - enemy.flash, 1.0, tint)
	elif progress >= 0.0:
		Animations.draw_frame(self, kind, realm, feet, direction, clip, Sequence.frame(progress), 1.0, tint)
	else:
		Animations.draw(self, kind, realm, feet, direction, clip, enemy.clock_animation, 1.0, tint)
	if enemy.windup > 0.0 and role == "caster":
		CombatFX.charge_glow(self, attack_socket(enemy, clip, progress), progress, accent)
	elif enemy.follow > 0.0 and enemy.released and enemy.flash <= 0.12 and style in ["sweep", "charge"]:
		var reach: float = RegionalMobs.MELEE[realm][1]
		draw_weapon_trail(enemy, clip, style, progress, reach, accent)
	if enemy.shield_flash > 0.0:
		draw_sparks(feet + Vector2(direction * 28.0, -46), enemy.shield_flash)
	if enemy.flash > 0.0:
		draw_sparks(feet - Vector2(0, 34), minf(enemy.flash, 0.18))
	if enemy.hp < enemy.max_hp or enemy.windup > 0.0:
		var at := feet - Vector2(19, 72 if role == "gorgon" else 93)
		draw_rect(Rect2(at, Vector2(38, 5)), Color("#131921de"))
		if enemy.max_hp <= 5:
			for pip in range(enemy.max_hp):
				UI.diamond(self, at + Vector2(19.0 + (pip - (enemy.max_hp - 1) * 0.5) * 7.0, 2), 2.5,
					accent if pip < enemy.hp else Color("#70504f"), pip >= enemy.hp)
		else:
			draw_rect(Rect2(at + Vector2(1, 1), Vector2(36.0 * enemy.hp / enemy.max_hp, 2)), accent)

func draw_guardian(enemy: Dictionary, feet: Vector2, kind: String, tint: Color, accent: Color) -> void:
	var profile: Dictionary = enemy.guardian
	var timeline: Dictionary = enemy.timeline
	var direction: int = enemy.direction
	var move := Encounters.attack(profile, timeline)
	var style: String = move.kind
	var phase: String = timeline.phase
	var clip := "move" if enemy.get("moving", false) else "idle"
	var progress := -1.0
	match phase:
		"wake":
			if enemy.get("awake", false):
				clip = "wake"
				progress = Sequence.ratio(timeline.elapsed, profile.wake)
		"windup", "active", "recovery":
			clip = Sequence.clip(style, phase)
			progress = Sequence.ratio(timeline.elapsed, move[phase])
			if profile.background and timeline.weak:
				clip = "expose"
	var moving_foot := feet - Vector2(0, 9) if profile.background else feet
	var scale_factor := guardian_render_scale(enemy)
	var shade := tint
	if profile.background:
		var opacity := 0.86
		if phase in ["windup", "active"]:
			opacity += 0.09 * sin(maxf(0.0, progress) * PI * 0.5)
		shade = Color(0.96, 0.89, 0.91, opacity)
	if enemy.role == "boss" and realm == 9 and enemy.phase == 4:
		draw_reflection(enemy, feet, clip, phase, progress, tint)
	elif enemy.flash > 0.105 and not profile.background:
		Animations.draw(self, kind, guardian_art_index(enemy), moving_foot, direction, "hit", 0.20 - enemy.flash, scale_factor, shade)
	elif progress >= 0.0:
		var strip: Texture2D
		if phase == "active" and move.get("signature", "") == "cleaver_throw" and enemy.get("pattern", {}).get("visible", false):
			strip = Pixels.atlas("kaalan-unarmed")
		Animations.draw_frame(self, kind, guardian_art_index(enemy), moving_foot, direction, clip, Sequence.frame(progress), scale_factor, shade, strip)
	else:
		Animations.draw(self, kind, guardian_art_index(enemy), moving_foot, direction, clip, enemy.clock_animation, scale_factor, shade)
	if phase == "windup":
		if move.has("signature"):
			Actions.draw_tell(self, enemy, move, progress, accent)
		else:
			draw_guardian_telegraph(enemy, move, accent)
	elif phase == "active":
		if move.has("signature"):
			Actions.draw_action(self, enemy, move, progress)
		elif enemy.released and style in ["sweep", "charge"]:
			draw_weapon_trail(enemy, clip, style, progress, move.reach, accent)
		elif style == "bell_drop" and not enemy.bell_landed:
			for x in marked_targets(enemy, move, false):
				CombatFX.warning(self, x, FLOOR, 36.0, 0.89, accent)
	if profile.background:
		draw_exposed_part(enemy, accent)
	if enemy.role == "boss" and realm == 1:
		draw_lotus_rite(enemy)
	if enemy.armored_flash > 0.0:
		draw_sparks(feet + Vector2(direction * 24.0, -41.0), enemy.armored_flash)
	if enemy.flash > 0.0:
		draw_sparks(guard_point(enemy) if profile.background else feet - Vector2(0, 64), minf(enemy.flash, 0.18))

func draw_lotus_rite(enemy: Dictionary) -> void:
	var glowing: float = enemy.rite_light
	var signal_on: bool = enemy.rite_clock >= 17.7 and enemy.rite_hits < 2
	if not signal_on and glowing <= 0.0:
		return
	var at := lotus_bloom(enemy).round()
	var tick := floori(elapsed * 16.0)
	var power := sin(clampf(glowing / 1.1, 0.0, 1.0) * PI) if glowing > 0.0 else 0.16
	var focus := lotus_focus(enemy)
	var base := Vector2(enemy.x - 29.0, FLOOR - 22.0) if glowing > 0.0 else focus
	for i in range(8):
		var t := float(i + 1) / 9.0
		var beam := at.lerp(base, t).round()
		Pixels.stamp(self, "healing_ray", tick - i, beam, Vector2(24 + i * 2, 30),
			Color(1, 0.91, 0.57, power * (0.86 if glowing > 0.0 else 0.6)))
	Pixels.stamp(self, "inverted_lotus", tick, at, Vector2(77, 57), Color.WHITE)
	if signal_on:
		Pixels.stamp(self, "lotus_spear", tick, focus, Vector2(44, 52), Color("#ffe5aa"))
		UI.diamond(self, focus - Vector2(0, 19), 3.0, Color("#ffe5aa"))
	if glowing > 0.0:
		CombatFX.impact(self, {"kind":"spark", "age":1.1 - glowing, "life":1.1, "scale":1.3, "at":base, "tint":Color("#f6ce8c")})

func draw_reflection(enemy: Dictionary, feet: Vector2, pose: String, phase: String, progress: float, tint: Color) -> void:
	var animation_name := "run" if enemy.get("moving", false) else "idle"
	var time: float = enemy.clock_animation
	if enemy.flash > 0.10:
		animation_name = "hurt"
		time = 0.19 - enemy.flash
	elif phase == "active":
		animation_name = "thrust" if pose == "thrust" else "slash"
		time = progress * PrinceFrames.total(animation_name)
	elif phase == "windup":
		animation_name = "thrust" if pose == "ready_lunge" else "slash"
		time = 0.05 + progress * 0.085
	elif phase == "recovery":
		if progress < 0.23:
			animation_name = "thrust" if pose == "recover_lunge" else "slash"
			time = PrinceFrames.total(animation_name) * 0.99
		elif progress < 0.79:
			animation_name = "crouch"
			time = (1.0 - progress) * 0.15
		else:
			time = 0.0
	sprite(feet, animation_name, time, enemy.direction, PRINCE_SCALE, tint)

func draw_weapon_trail(enemy: Dictionary, pose: String, style: String, progress: float, reach: float, accent: Color) -> void:
	var source := attack_socket(enemy, pose, progress)
	var width := maxf(22.0, reach - absf(source.x - float(enemy.x)))
	CombatFX.blade(self, source, enemy.direction, width,
		Sequence.strike_progress(style, progress), accent, style == "charge")

func draw_guardian_telegraph(enemy: Dictionary, move: Dictionary, accent: Color) -> void:
	var ratio := Sequence.ratio(enemy.timeline.elapsed, move.windup)
	var style: String = move.kind
	match style:
		"fan", "chain", "pillars", "rain":
			var hand := attack_socket(enemy, Sequence.clip(style, "windup"), ratio)
			CombatFX.charge_glow(self, hand, ratio, accent)
		"waves", "bell_drop":
			if ratio > 0.39:
				var cue_x: float = wave_origin_x(enemy) if style == "waves" else enemy.x
				CombatFX.dust(self, Vector2(cue_x, FLOOR), (ratio - 0.39) * 0.56, accent.darkened(0.48), 0.64)
				if style == "waves" and bell_staff_strike(enemy):
					CombatFX.warning(self, cue_x, FLOOR, 33.0, ratio, accent)
	if style in ["chain", "pillars", "rain", "bell_drop"] and ratio > 0.20:
		var rage: bool = enemy.guardian.major and float(enemy.hp) <= float(enemy.max_hp) * 0.48
		var hand := attack_socket(enemy, Sequence.clip(style, "windup"), ratio)
		for x in marked_targets(enemy, move, rage):
			CombatFX.warning(self, x, FLOOR, 36.0 if style == "bell_drop" else 22.0, ratio, accent)
			if style == "chain" and ratio > 0.46:
				var gate := Vector2(x, FLOOR - Sequence.CHAIN_DROP_HEIGHT - 10.0)
				CombatFX.chain_summon(self, hand, gate, ratio, accent)

func draw_exposed_part(enemy: Dictionary, accent: Color) -> void:
	if not enemy.timeline.weak:
		return
	var at := guard_point(enemy).round()
	var glow := accent.lightened(0.27)
	var shoulder := Vector2(enemy.x, FLOOR - 108)
	if realm == 8:
		var progress := Sequence.ratio(enemy.timeline.elapsed, Encounters.attack(enemy.guardian, enemy.timeline).recovery)
		var hand := attack_socket(enemy, "recover_cast", progress)
		CombatFX.royal_tether(self, hand, at, accent)
	else:
		var joint := shoulder.lerp(at, 0.56) + Vector2(0, 16)
		var silhouette := PackedVector2Array([shoulder, joint, at])
		draw_polyline(silhouette, Color("#1f1720"), 11)
		draw_polyline(silhouette, Color(accent.darkened(0.48), 0.86), 7)
		draw_polyline(PackedVector2Array([shoulder - Vector2(0, 2), joint - Vector2(0, 2), at]), Color(accent.darkened(0.16), 0.68), 2)
	Animations.draw_core(self, realm, at, float(enemy.timeline.elapsed), 1.0,
		Color.WHITE.lerp(Color("#ffe6ca"), minf(1.0, enemy.flash * 5.0)))
	draw_arc(at, 25.0 + sin(elapsed * 13) * 2, 0, TAU, 24, Color(glow, 0.58), 1)

func death_impact_time(enemy: Dictionary) -> float:
	var duration := Animations.duration(encounter_kind(enemy.role), "death")
	return duration * (0.64 if enemy.role == "gorgon" else 0.74)

func draw_defeated(enemy: Dictionary) -> void:
	var time: float = elapsed - enemy.dead_at
	var kind := encounter_kind(enemy.role)
	var duration := Animations.duration(kind, "death")
	var guardian: Dictionary = enemy.guardian
	var hold := 2.1 if guardian.is_empty() else 4.0
	var opacity := 1.0 - smoothstep(duration + hold, duration + hold + 0.65, time)
	if opacity <= 0.0:
		return
	var impact := death_impact_time(enemy)
	var feet := Vector2(enemy.x, enemy.y)
	if enemy.role == "gorgon":
		var fall := clampf(time / impact, 0.0, 1.0)
		feet.y = lerpf(feet.y, FLOOR, fall * fall)
	var shade := Color(1.0, 1.0, 1.0, opacity)
	if guardian.get("background", false):
		shade *= Color("#c6a7ab9e")
		Animations.draw(self, kind, guardian_art_index(enemy), feet - Vector2(0, 9), enemy.direction, "death", time, guardian_render_scale(enemy), shade)
	elif realm == 9 and enemy.role == "boss" and enemy.phase == 4:
		sprite(feet, "die", time, enemy.direction, PRINCE_SCALE, shade * Color("#efce98"))
	else:
		Animations.draw(self, kind, guardian_art_index(enemy), feet, enemy.direction, "death", time, guardian_render_scale(enemy), shade)
	var since_impact := time - impact
	if since_impact >= 0.0 and since_impact < 0.32:
		for i in range(6):
			var drift := Vector2((i - 2.5) * since_impact * 43.0, -5.0 - sin(since_impact * PI / 0.32) * (3 + i % 3 * 3))
			draw_rect(Rect2((feet + drift).round(), Vector2(2, 2)), Color(0.64, 0.54, 0.41, 0.58 * (1.0 - since_impact / 0.32)))

func draw_projectiles() -> void:
	for mark in contact_marks:
		CombatFX.impact(self, mark)
	for bolt in projectiles:
		var time: float = bolt.age
		var art: String = bolt.get("art", "")
		if bolt.style == "sig_column":
			if time < 0.12:
				CombatFX.warning(self, bolt.at.x, FLOOR, bolt.r, clampf((time + 0.48) / 0.6, 0.0, 1.0), bolt.color)
				continue
			var rise := smoothstep(0.12, 0.24, time)
			var light := 1.0 - smoothstep(0.37, 0.52, time)
			var height := lerpf(28.0, FLOOR - float(bolt.top_y), rise)
			var span := Vector2(float(bolt.r) * 2.8, 57)
			for row in range(ceili(height / 32.0)):
				Pixels.stamp(self, art, floori(time * 20.0) - row,
					Vector2(bolt.at.x, FLOOR - 14.0 - row * 30), span,
					Color(1, 1, 1, light * (0.92 if row % 2 == 0 else 0.72)), 1 if row % 2 == 0 else -1)
		elif time >= 0.0 and not art.is_empty():
			var radius: float = bolt.r
			Pixels.stamp(self, art, floori(time * (18.0 + float(bolt.get("spin", 0.0)))),
				bolt.at, Vector2.ONE * maxf(27, radius * 3.2), Color.WHITE, bolt.heading)
		elif time >= 0.0:
			CombatFX.projectile(self, bolt, FLOOR)

func draw_prince() -> void:
	var feet := position_on_floor.round()
	if grounded:
		CombatFX.shadow(self, feet, 34.0, 0.94)
	if heal_time > 0.0:
		draw_healing(feet)
		if heal_time > 1.07:
			sprite(feet, "crouch" if heal_time > 1.28 else "interact", maxf(0.02, 1.8 - heal_time), facing,
				PRINCE_SCALE, Color("#ffdeb4"))
			return
	if dodge > 0:
		var dodge_age := 0.21 - dodge
		sprite(feet, "crouch", dodge_age, facing, PRINCE_SCALE)
		if grounded:
			CombatFX.dust(self, feet - Vector2(facing * 13.0, 0.0), dodge_age, Color("#a58a71"), 0.48)
		return
	var tint := Color(1, 1, 1, 0.55) if invincible > 0 and fmod(elapsed, 0.17) < 0.08 else Color.WHITE
	sprite(feet, animation, anim_time, facing, PRINCE_SCALE, tint)
	if attack <= 0.0:
		return
	var action_age := anim_time - (0.16 if attack_kind == "thrust" else 0.165)
	var moment := action_age / 0.135
	if moment < 0.0 or moment >= 1.0:
		return
	var thrust := attack_kind == "thrust"
	var grip := feet + Vector2(16.0 * facing, -34.0)
	CombatFX.blade(self, grip, facing, 77.0 if thrust else 58.0, moment, Color("#f2c99d"), thrust)

func draw_healing(feet: Vector2) -> void:
	var delta := (1.8 - heal_time) / 1.8
	var power := sin(clampf(delta, 0.0, 1.0) * PI)
	for i in range(23):
		var angle := delta * 6.8 + i * 1.75
		var distance := 25 + (i % 5) * 4.0
		var a := (feet + Vector2(cos(angle) * distance, -8 - fposmod(i * 14.0 + delta * 114.0, 107.0))).round()
		draw_rect(Rect2(a, Vector2(2, 3)), Color("#f5d3a2", power * (0.32 + (i % 4) * 0.15)))
	draw_arc(feet - Vector2(0, 24), 24.0 + delta * 45.0, PI * 0.16, PI * 1.84, 28, Color("#efbf80", power * 0.49), 2)

func draw_sparks(at: Vector2, timer: float) -> void:
	CombatFX.impact(self, {"kind": "spark", "age": maxf(0.0, 0.18 - timer), "life": 0.18,
		"scale": 0.62, "at": at, "tint": Color("#eed19b")})

func draw_hud() -> void:
	if state != "play":
		return
	var border := Color("#a68157")
	var accent := Color(Run.ROSTERS[realm][4])
	draw_rect(Rect2(56, 26, 208, 27), Color("#0d0d15ba"))
	UI.sun(self, Vector2(43, 39), 23.0, border)
	draw_texture_rect_region(Sheet, Rect2(31, 23, 24, 30), Rect2(599, 92, 35, 42), Color("#e4c9a6"))
	UI.sun(self, Vector2(43, 65), 7.0, border, false)
	UI.lacquer_meter(self, Rect2(66, 30, 184, 10), float(hp) / max_hp, displayed_hp / max_hp, border)
	draw_string(display, Vector2(66, 58), ROOM_NAMES.get(room.kind, "Gallery"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.CREAM)
	label(Vector2(220, 55), "%d" % hp, 10, UI.CREAM)
	var area: String = Lore.REALMS[realm][0]
	var ax := 930.0 - display.get_string_size(area, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	draw_rect(Rect2(ax - 12, 23, 943.0 - ax, 45), Color("#100e16a8"))
	draw_string(display, Vector2(ax, 43), area, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UI.CREAM)
	UI.rule(self, Vector2(ax, 48), Vector2(930, 48), border)
	label(Vector2(ax, 63), dungeon_caption(), 12, accent)
	UI.diamond(self, Vector2(905, 59), 4.0, GOLD, not seal)
	UI.diamond(self, Vector2(925, 59), 4.0, UI.PATINA, not passage)
	if controller.connected:
		label(Vector2(ax, 81), "Controller connected", 11, UI.PATINA)
	if trial.active() and trial.phase not in [VajraTrial.Phase.SILENCE, VajraTrial.Phase.FALL]:
		draw_guardian_bar({"hp":trial.hp, "max_hp":VajraTrial.MAX_HP, "flash":0.0,
			"guardian":{"name":"Vajrakala · The Hundred Hands"}, "timeline":{"weak":trial.phase == VajraTrial.Phase.BELL_OPEN}}, accent, border)
	elif room.kind in BOSS_GALLERIES and not room.enemies.is_empty():
		var guardian: Dictionary = room.enemies[0]
		if guardian.get("awake", false):
			draw_guardian_bar(guardian, accent, border)
	var overlay := map_open or journal_open or controls_open or inventory_open or pause_menu.visible
	if message_time > 0 and not overlay:
		var width := ThemeDB.fallback_font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 40.0
		var box := Rect2(480 - width / 2.0, 499, width, 26)
		draw_rect(box, Color("#100d17db"))
		UI.rule(self, box.position, box.position + Vector2(width, 0), border)
		centered(Vector2(480, 517), message, 14, UI.CREAM)

func draw_guardian_bar(guardian: Dictionary, accent: Color, border: Color) -> void:
	var name: String = guardian.guardian.name
	var width := display.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
	var ready: bool = guardian.timeline.weak
	var rim := border.lerp(accent, 0.44) if ready else border
	draw_rect(Rect2(174, 441, 612, 54), Color("#120d17bc"))
	draw_string(display, Vector2(481 - width * 0.5, 465), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("#190f16"))
	draw_string(display, Vector2(480 - width * 0.5, 464), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UI.CREAM)
	var amount: float = float(guardian.hp) / float(guardian.max_hp)
	UI.lacquer_meter(self, Rect2(192, 473, 576, 10), amount, amount + maxf(0.0, guardian.flash) * 0.16, rim)
	for i in range(1, 6):
		draw_rect(Rect2(192 + i * 96, 474, 1, 9), Color("#20142496"))
	UI.sun(self, Vector2(174, 478), 11.0, rim)
	UI.sun(self, Vector2(785, 478), 11.0, rim)
	UI.flame(self, Vector2(174, 478), 0.66, rim)
	UI.flame(self, Vector2(785, 478), 0.66, rim)

func inventory_items() -> Array:
	var relics: Array = items.keys()
	relics.sort()
	relics.push_front("Ashes of the Sangha")
	if seal:
		relics.append("Dharma Seal")
	if passage and not endless and quest < 0:
		relics.append("Passage Relic")
	for id in awards:
		var detail := Legacy.award_detail(id)
		if not String(detail.item).is_empty():
			relics.append(detail.item)
	return relics

func draw_inventory() -> void:
	panel(Rect2(83, 70, 794, 398))
	var relics := inventory_items()
	inventory_index = clampi(inventory_index, 0, relics.size() - 1)
	var chosen: String = relics[inventory_index]
	var first := (inventory_index / 20) * 20
	draw_string(display, Vector2(120, 131), "Relics of the Final Path", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UI.CREAM)
	label(Vector2(123, 103), "PILGRIM'S SATCHEL", 12, UI.PATINA)
	UI.rule(self, Vector2(123, 151), Vector2(838, 151), UI.BRASS)
	for j in range(20):
		var at := Vector2(122 + (j % 5) * 71, 169 + (j / 5) * 53)
		var active := first + j == inventory_index
		UI.engraved(self, Rect2(at, Vector2(63, 45)), Color("#392d36") if active else Color("#182029"),
			GOLD if active else Color("#5e4e4a"))
		if first + j < relics.size():
			draw_relic_icon(relics[first + j], at + Vector2(13, 4), 35.0)
	draw_line(Vector2(492, 174), Vector2(492, 404), Color("#5a4e46"), 1.0)
	draw_relic_icon(chosen, Vector2(526, 170), 83.0)
	draw_string(display, Vector2(524, 276), chosen, HORIZONTAL_ALIGNMENT_LEFT, -1, 25, UI.CREAM)
	var note: String = Lore.ITEM_NOTES.get(chosen, "A relic of the Final Path. Look for its place in the Vows recorded in your journal.")
	var legacy := Legacy.item_detail(chosen)
	if not legacy.is_empty():
		note = legacy.description
	match chosen:
		"Ashes of the Sangha":
			note = "Ashes carried through Samsara. Spend three to permanently add ten vitality."
			label(Vector2(526, 381), "%d ashes  /  %d of 6 rites  /  U  Kindle vitality" % [ashes, vitality_rank], 13, GOLD)
		"Dharma Seal":
			note = "Offer this seal at the east altar to open the next dungeon."
		"Passage Relic":
			note = "Proof that the realm guardian has fallen. Its passage opens at the consecrated gate."
	draw_memory(Vector2(526, 305), note)
	UI.rule(self, Vector2(123, 417), Vector2(838, 417), UI.BRASS)
	label(Vector2(124, 447), "Arrows  Select    U  Kindle vitality    B  Close", 13, UI.PATINA)
	label(Vector2(667, 447), "%d relics held  /  %d of %d" % [items.size(), inventory_index + 1, relics.size()], 13, UI.CREAM)

func draw_relic_icon(item: String, at: Vector2, size_px: float) -> void:
	var legacy := Legacy.item_detail(item)
	if not legacy.is_empty():
		Pixels.icon(self, legacy.icon, at, size_px)
		return
	var atlas := RealmArt.texture("relic_icons_engraved")
	if atlas == null:
		atlas = RealmArt.texture("relic_icons")
	if atlas == null:
		return
	var index: int = {
		"Prayer Wheel": 0, "Japa Mala": 1, "Broken Mala": 1, "Monk's Robe": 2, "Broken Vajra": 3,
		"Torn Sutra": 4, "Ashes of the Sangha": 5, "Dharma Seal": 6, "Passage Relic": 7, "Breath Shard": 8
	}.get(item, 9)
	var tile := float(atlas.get_width()) / 10.0
	draw_texture_rect_region(atlas, Rect2(at, Vector2.ONE * size_px), Rect2(index * tile, 0, tile, tile))

func draw_controls() -> void:
	panel(Rect2(219, 95, 522, 352))
	draw_string(display, Vector2(261, 148), "Pilgrim's controls", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UI.CREAM)
	UI.rule(self, Vector2(263, 164), Vector2(697, 164), UI.BRASS)
	var rows := [
		["Left / Right", "Move"], ["Up / Down", "Jump / drop through a ledge"],
		["X / V", "Slash / thrust"], ["P / Shift", "Pause / dodge"],
		["E", "Interact, collect or take the stairs"], ["Q", "Turn the Prayer Wheel"],
		["Tab / I / B", "Map / journal / inventory"], ["PgUp / PgDn", "Turn journal pages"],
		["C", "Copy the current dungeon seed"]
	]
	for i in range(rows.size()):
		var row := 195 + i * 22
		label(Vector2(266, row), rows[i][0], 14, UI.BRASS)
		label(Vector2(443, row), rows[i][1], 14, UI.CREAM)
	label(Vector2(266, 415), "F1 or Esc to close", 13, UI.PATINA)

func draw_map() -> void:
	panel(Rect2(86, 81, 788, 376))
	draw_string(display, Vector2(119, 147), Lore.REALMS[realm][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 31, UI.CREAM)
	label(Vector2(122, 115), "GALLERY CHART   /   " + dungeon_caption().to_upper(), 12, UI.PATINA)
	UI.lotus(self, Vector2(813, 138), 1.58, UI.BRASS)
	UI.rule(self, Vector2(122, 165), Vector2(838, 165), UI.BRASS)
	var length := 0
	for location in data.rooms:
		length = maxi(length, location.x + 1)
	var spacing := minf(96.0, 649.0 / float(length))
	var chart := Vector2(480.0 - (length - 1) * spacing / 2.0, 279.0)
	var ring := Color("#343c3d")
	for radius in [25, 43, 61, 79]:
		draw_arc(Vector2(782, 300), radius, 0.0, TAU, 48, ring, 1.0, true)
	for i in range(5):
		var tick := float(190 + i * 42)
		draw_line(Vector2(120, tick), Vector2(124, tick), ring, 1.0)
		draw_line(Vector2(835, tick), Vector2(839, tick), ring, 1.0)
	for location in data.rooms:
		var gallery: Dictionary = data.rooms[location]
		if not gallery.visited:
			continue
		var center := chart + Vector2(location) * Vector2(spacing, 75)
		for direction in gallery.links:
			var neighbor: Vector2i = location + Dungeon.DIRECTIONS[direction]
			if data.rooms[neighbor].hidden:
				continue
			var other := chart + Vector2(neighbor) * Vector2(spacing, 75)
			var known: bool = data.rooms[neighbor].visited
			var thread_color := Color("#8a674f") if known else Color("#4e4f4b")
			if direction % 2 == 0:
				draw_line(center - Vector2(3, 0), other - Vector2(3, 0), thread_color, 1.0)
				draw_line(center + Vector2(3, 0), other + Vector2(3, 0), thread_color, 1.0)
				for rung in [-9, 0, 9]:
					var mid := (center + other) / 2.0 + Vector2(0, rung)
					draw_line(mid - Vector2(3, 0), mid + Vector2(3, 0), thread_color, 1.0)
			else:
				draw_line(center, other, thread_color, 3.0)
	for location in data.rooms:
		if not on_map(location):
			continue
		var gallery: Dictionary = data.rooms[location]
		var center := chart + Vector2(location) * Vector2(spacing, 75)
		var shape := Rect2(center - Vector2(spacing * 0.38, 12), Vector2(spacing * 0.76, 24))
		var color := Color("#131920")
		var edge := Color("#5b5d53")
		if gallery.visited:
			color = Color("#664044") if gallery.kind == "boss" else Color("#344746")
			edge = Color("#a88561")
		if location == point:
			color = Color("#69513f")
			edge = UI.BRASS
		UI.engraved(self, shape, color, edge)
		if gallery.visited and (gallery.seal or location == data.gate):
			UI.diamond(self, center, 4.5, UI.BRASS if gallery.seal else Color("#e69a7c"))
		elif location == Vector2i.ZERO:
			UI.lotus(self, center + Vector2(0, 1), 0.55, edge)
		if location == point:
			var cursor := Vector2(lerpf(shape.position.x + 6.0, shape.end.x - 6.0, position_on_floor.x / Dungeon.SIZE), center.y)
			UI.flame(self, cursor + Vector2(0, 3), 0.85, Color("#ffe3a7"))
	UI.rule(self, Vector2(122, 390), Vector2(838, 390), UI.BRASS)
	label(Vector2(122, 425), "Seed %s   ·   C  Copy" % run_seed, 14, UI.CREAM)
	label(Vector2(535, 425), "Flame  You     ◆  Objective     Tab  Close", 13, UI.PATINA)

func on_map(location: Vector2i) -> bool:
	var gallery: Dictionary = data.rooms[location]
	if gallery.hidden:
		return false
	if gallery.visited:
		return true
	for direction in gallery.links:
		if data.rooms[location + Dungeon.DIRECTIONS[direction]].visited:
			return true
	return false

func draw_journal() -> void:
	panel(Rect2(89, 76, 782, 397))
	draw_string(display, Vector2(122, 137), "Journal of the Last Votary", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, UI.CREAM)
	UI.rule(self, Vector2(124, 157), Vector2(836, 157), UI.BRASS)
	label(Vector2(127, 182), "VOWS AND RELICS", 12, UI.PATINA)
	label(Vector2(483, 182), "MEMORIES AND MANUSCRIPTS", 12, UI.PATINA)
	draw_line(Vector2(458, 179), Vector2(458, 404), Color("#4a4540"), 1.0)
	for i in range(Lore.VOWS.size()):
		var vow: Array = Lore.VOWS[i]
		var top := 210 + 40 * i
		var progress := ""
		if not vows.has(vow[0]):
			var missing: Array = vow[1].filter(func(item): return not items.has(item))
			progress = ", ".join(missing)
		else:
			var remaining: Array = vow[2].filter(func(item): return not items.has(item))
			progress = "Fulfilled" if vows[vow[0]] else ("Return to the abandoned shrine" if remaining.is_empty() else "%d / 4 relics recovered" % (4 - remaining.size()))
		UI.diamond(self, Vector2(130, top - 4), 3.0, UI.BRASS if vows.has(vow[0]) else Color("#726052"), not vows.has(vow[0]))
		label(Vector2(143, top), vow[0], 15, UI.CREAM)
		label(Vector2(143, top + 15), progress, 12, UI.PATINA)
	var first := journal_page * 4
	for i in range(first, mini(first + 4, memories.size())):
		var memory_top := 211 + (i - first) * 48
		draw_memory(Vector2(484, memory_top), memories[i])
	label(Vector2(484, 407), "PgUp / PgDn   ·   Page %d of %d" % [journal_page + 1, maxi(1, ceili(memories.size() / 4.0))], 12, UI.PATINA)
	UI.rule(self, Vector2(124, 421), Vector2(836, 421), UI.BRASS)
	label(Vector2(124, 448), "Cycle %d   ·   Ashes %d   ·   Seed %d" % [cycle + 1, ashes, run_seed], 13, UI.CREAM)
	label(Vector2(781, 448), "I  Close", 13, UI.PATINA)

func draw_memory(at: Vector2, entry: String) -> void:
	var line := ""
	var offset := 0.0
	for word in entry.split(" ", false):
		var text := word if line.is_empty() else line + " " + word
		if not line.is_empty() and display.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x > 339.0:
			draw_string(display, at + Vector2(0, offset), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.CREAM)
			line = word
			offset += 17.0
		else:
			line = text
	draw_string(display, at + Vector2(0, offset), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UI.CREAM)
