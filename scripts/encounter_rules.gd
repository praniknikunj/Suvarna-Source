extends RefCounted

const Run = preload("res://scripts/pilgrimage.gd")
const Patterns = preload("res://scripts/guardian_signatures.gd")
const Legacy = preload("res://scripts/pilgrimage_legacy.gd")
const SHIELD_TURN_SECONDS := 2.0
const MIN_WINDUP := 0.43
const IMPACT_WEIGHT := {
	"rain": -4.0, "fan": -3.0, "waves": -1.0, "pillars": 1.0,
	"sweep": 2.0, "chain": 3.0, "charge": 4.0
}
const INTRO_NAME := "Pretaghanta"
const BOSS_NAMES := preload("res://scripts/realms.gd").BOSS_NAMES
const MINI_NAMES := [
	"Dhumraketu", "Pankajapala", "Angaravega", "Vanyanetra", "Asthipala",
	"Mayaketu", "Vishavega", "Bhasmapala", "Chakraketu", "Vajrapala"
]
const SHIELD_NAMES := [
	"Kavachin", "Padmakavachin", "Agnikavachin", "Vanakavachin", "Asthikavachin",
	"Darpanakavachin", "Nagakavachin", "Bhasmakavachin", "Chakrakavachin", "Vajrakavachin"
]

# Each row specifies kind, anticipation, commitment, recovery, damage, reach,
# motion speed, and projectile count. The optional pair opens a weak point
# during recovery, measured from the start of that phase.
const INTRO_ATTACKS := [
	["sweep", 0.80, 0.28, 0.83, 15, 107, 0, 0],
	["bell_drop", 0.96, 0.82, 1.02, 18, 76, 196, 2],
	["charge", 0.74, 0.51, 0.79, 15, 60, 246, 0]
]
const MINI_ATTACKS := [
	[["sweep", 0.67, 0.23, 0.69, 13, 90, 0, 0], ["waves", 0.77, 0.29, 0.75, 14, 180, 245, 2], ["charge", 0.63, 0.44, 0.65, 14, 53, 231, 0]],
	[["fan", 0.63, 0.25, 0.72, 12, 160, 181, 3], ["sweep", 0.58, 0.23, 0.69, 15, 97, 0, 0], ["pillars", 0.80, 0.38, 0.89, 16, 41, 0, 2]],
	[["charge", 0.57, 0.58, 0.70, 15, 54, 285, 0], ["chain", 0.76, 0.29, 0.83, 17, 121, 0, 0], ["waves", 0.65, 0.27, 0.72, 15, 185, 264, 2]],
	[["rain", 0.70, 0.38, 0.78, 13, 39, 231, 4], ["fan", 0.58, 0.24, 0.66, 13, 162, 219, 3], ["sweep", 0.62, 0.22, 0.70, 15, 89, 0, 0]],
	[["chain", 0.77, 0.31, 0.80, 18, 157, 0, 0], ["pillars", 0.72, 0.42, 0.79, 16, 42, 0, 3], ["waves", 0.67, 0.28, 0.69, 15, 183, 227, 2]],
	[["sweep", 0.52, 0.24, 0.57, 16, 111, 0, 0], ["charge", 0.55, 0.50, 0.68, 16, 52, 314, 0], ["fan", 0.58, 0.22, 0.68, 14, 176, 242, 3]],
	[["fan", 0.59, 0.29, 0.64, 15, 181, 218, 5], ["charge", 0.54, 0.51, 0.76, 18, 58, 273, 0], ["pillars", 0.67, 0.39, 0.77, 17, 42, 0, 3]],
	[["waves", 0.63, 0.33, 0.77, 16, 190, 283, 2], ["rain", 0.63, 0.42, 0.76, 16, 40, 252, 5], ["chain", 0.74, 0.29, 0.83, 18, 143, 0, 0]],
	[["pillars", 0.64, 0.42, 0.81, 17, 42, 0, 3], ["charge", 0.52, 0.54, 0.69, 18, 62, 301, 0], ["waves", 0.62, 0.35, 0.77, 18, 197, 274, 3]],
	[["rain", 0.62, 0.41, 0.82, 17, 37, 269, 6], ["fan", 0.56, 0.23, 0.72, 16, 185, 263, 5], ["chain", 0.69, 0.31, 0.81, 20, 157, 0, 0]]
]
const BOSS_ATTACKS := [
	[["chain", 0.83, 0.34, 0.95, 19, 141, 0, 0], ["waves", 0.75, 0.32, 0.85, 17, 225, 262, 2], ["sweep", 0.67, 0.29, 0.83, 19, 132, 0, 0], ["charge", 0.69, 0.58, 0.99, 20, 68, 280, 0]],
	[["pillars", 0.91, 0.58, 1.50, 19, 54, 0, 3, 0.12, 1.22], ["fan", 0.68, 0.38, 1.37, 17, 205, 213, 5, 0.14, 1.02], ["rain", 0.76, 0.45, 1.54, 18, 48, 239, 6, 0.18, 1.19]],
	[["charge", 0.61, 0.72, 1.02, 23, 76, 339, 0], ["sweep", 0.61, 0.28, 0.84, 20, 152, 0, 0], ["waves", 0.70, 0.31, 0.91, 20, 241, 289, 2], ["chain", 0.73, 0.35, 0.94, 24, 172, 0, 0]],
	[["rain", 0.75, 0.43, 0.93, 18, 49, 275, 6], ["pillars", 0.78, 0.50, 1.01, 20, 47, 0, 4], ["fan", 0.63, 0.27, 0.79, 18, 209, 246, 5]],
	[["fan", 0.67, 0.31, 0.90, 19, 220, 210, 7], ["chain", 0.80, 0.34, 1.02, 24, 193, 0, 0], ["pillars", 0.76, 0.51, 0.97, 22, 52, 0, 4], ["rain", 0.74, 0.40, 0.93, 19, 51, 268, 5]],
	[["sweep", 0.50, 0.25, 0.68, 20, 128, 0, 0], ["charge", 0.52, 0.58, 0.73, 22, 62, 361, 0], ["chain", 0.65, 0.29, 0.82, 24, 152, 0, 0], ["charge", 0.59, 0.44, 0.85, 21, 72, 316, 0]],
	[["fan", 0.62, 0.35, 0.82, 20, 211, 249, 7], ["charge", 0.54, 0.61, 0.91, 24, 68, 324, 0], ["pillars", 0.69, 0.47, 0.89, 22, 53, 0, 4], ["sweep", 0.59, 0.30, 0.77, 22, 163, 0, 0]],
	[["waves", 0.65, 0.43, 0.99, 22, 232, 313, 4], ["chain", 0.71, 0.31, 0.87, 24, 178, 0, 0], ["rain", 0.67, 0.47, 0.93, 20, 51, 282, 7], ["waves", 0.56, 0.38, 0.88, 23, 240, 342, 3]],
	[["rain", 0.72, 0.53, 1.50, 22, 52, 296, 8, 0.14, 1.20], ["waves", 0.69, 0.37, 1.38, 24, 253, 298, 4, 0.12, 1.13], ["pillars", 0.76, 0.53, 1.55, 25, 54, 0, 5, 0.16, 1.22], ["fan", 0.58, 0.30, 1.36, 22, 245, 285, 7, 0.10, 1.14]],
	[["fan", 0.57, 0.38, 0.92, 24, 245, 284, 9], ["pillars", 0.71, 0.54, 0.98, 26, 57, 0, 5], ["waves", 0.64, 0.41, 0.91, 24, 260, 337, 4], ["rain", 0.69, 0.47, 0.94, 24, 56, 308, 8], ["charge", 0.56, 0.67, 0.95, 27, 74, 367, 0], ["chain", 0.73, 0.32, 1.04, 28, 197, 0, 0]]
]

static func guardian(role: String, realm: int) -> Dictionary:
	var index := clampi(realm, 0, BOSS_NAMES.size() - 1)
	var selected: Array
	var name: String
	var hp: int
	var wake: float
	var background := false
	var radius := 58.0
	if role == "intro":
		selected = INTRO_ATTACKS
		name = INTRO_NAME
		hp = 82
		wake = 1.45
	elif role == "mini":
		selected = MINI_ATTACKS[index]
		name = MINI_NAMES[index]
		hp = 86 + index * 5
		wake = 1.28
		radius = 49.0
	else:
		selected = BOSS_ATTACKS[index]
		name = BOSS_NAMES[index]
		hp = Patterns.BOSS_HP[index]
		wake = 1.78
		background = index == 1 or index == 8
		radius = 65.0 if index != 5 else 43.0
	var attacks: Array[Dictionary] = []
	for row in selected:
		attacks.append(_attack_from_row(row))
	var major := role == "boss"
	if role != "intro":
		_tune_rotation(attacks, index, major, background)
	var signature: String = "bell_crater" if role == "intro" else (Patterns.BOSSES[index] if major else Patterns.MINIS[index])
	var standard := attacks
	attacks = Patterns.variant(standard, signature, index, major, background)
	var idle: float = Patterns.BOSS_IDLE[index] if major else maxf(0.10, 0.27 - index * 0.019)
	var stride: float = Patterns.BOSS_STRIDE[index] if major else 83.0 + index * 7.0
	var averages := _rotation_averages(attacks)
	var period := idle + averages.x + averages.y + averages.z
	return {
		"name": name, "hp": hp, "wake": wake,
		"background": background, "radius": radius, "major": role == "boss", "realm": index,
		"weak_offset": Vector2(124.0, -54.0) if index == 1 else Vector2(151.0, -44.0),
		"weak_radius": 28.0 if index == 1 else 31.0,
		"idle": idle, "period": period, "pressure": averages.w / period,
		"attacks": attacks, "standard": standard, "signature":signature, "stride": stride,
		"blade_fraction": (0.043 if role == "intro" else (0.037 - index * 0.0015 if major else 0.042 - index * 0.0018))
	}

static func side_guardian(index: int) -> Dictionary:
	var entry: Dictionary = Legacy.QUESTS[index]
	var profile := guardian("mini", entry.realm)
	profile.name = entry.name
	profile.hp = [126, 140, 154][index]
	profile.wake = 0.95
	profile.idle = [0.09, 0.14, 0.08][index]
	profile.stride = [171.0, 113.0, 194.0][index]
	profile.attacks = Patterns.variant(profile.standard, entry.signature, 5, true, false)
	profile.signature = entry.signature
	profile.blade_fraction = [0.034, 0.031, 0.028][index]
	profile.major = true
	return profile

static func _tune_rotation(attacks: Array[Dictionary], index: int, major: bool, background: bool) -> float:
	var original := _rotation_averages(attacks)
	var period := (2.66 - index * 0.09) if major else (2.78 - index * 0.088)
	var windup := (0.72 - index * 0.023) if major else (0.76 - index * 0.024)
	var active := (0.33 + index * 0.003) if major else (0.32 + index * 0.002)
	var recovery := (0.89 - index * 0.022) if major else (0.86 - index * 0.016)
	if background:
		# Keep a usable opening for the exposed target and take that budget from idle time.
		windup = 0.69 - index * 0.021
		active = 0.28 - index * 0.005
		recovery = 1.24 - index * 0.030
	var mean_weight := 0.0
	for move in attacks:
		mean_weight += IMPACT_WEIGHT[move.kind]
	mean_weight /= attacks.size()
	for move in attacks:
		var heavy: bool = move.damage >= original.w
		move.windup = maxf(MIN_WINDUP, float(move.windup) * windup / original.x)
		move.active = clampf(float(move.active) * active / original.y, 0.17, 0.67)
		move.recovery = float(move.recovery) * recovery / original.z
		var weight: float = IMPACT_WEIGHT[move.kind] - mean_weight
		move.damage = (20 if major else 14) + index + int(heavy) + roundi(weight * (1.0 if major else 0.64))
		move.speed = minf(417.0, float(move.speed) * (1.04 + index * (0.020 if major else 0.016)))
		move.reach = minf(282.0, float(move.reach) * (1.02 + index * 0.011))
		if major and index == 7 and move.kind == "waves":
			move.windup += 0.07
			move.recovery += 0.19
		if background:
			move.open_delay = minf(0.15, float(move.open_delay))
			move.open_time = maxf(0.0, float(move.recovery) - float(move.open_delay) - 0.09)
	var adjusted := _rotation_averages(attacks)
	return maxf(0.13, period - adjusted.x - adjusted.y - adjusted.z)

static func _rotation_averages(attacks: Array[Dictionary]) -> Vector4:
	var totals := Vector4.ZERO
	for move in attacks:
		totals += Vector4(move.windup, move.active, move.recovery, move.damage)
	return totals / float(attacks.size())

static func reflection_rotation() -> Array[Dictionary]:
	return [
		_attack_from_row(["charge", 0.56, 0.49, 0.94, 28, 57, 347, 0]),
		_attack_from_row(["sweep", 0.51, 0.31, 0.85, 27, 122, 0, 0]),
		_attack_from_row(["fan", 0.62, 0.31, 0.93, 26, 188, 265, 3])
	]

static func _attack_from_row(row: Array) -> Dictionary:
	var opens := row.size() >= 10
	return {
		"kind": row[0],
		"windup": float(row[1]), "active": float(row[2]), "recovery": float(row[3]),
		"damage": int(row[4]), "reach": float(row[5]), "speed": float(row[6]),
		"projectiles": int(row[7]),
		"open_delay": float(row[8]) if opens else 0.0,
		"open_time": float(row[9]) if opens else 0.0
	}

static func mob(role: String, floor_number: int) -> Dictionary:
	var realm := Run.realm_at(maxi(1, floor_number))
	var pressure := clampf(float(maxi(1, floor_number) - 1) * 0.026, 0.0, 2.2)
	if role == "tank" or role == "shield":
		return {"name": SHIELD_NAMES[realm], "hp": 5, "damage": 13 + floori(pressure * 2.4),
			"windup": 0.54, "cooldown": 1.22, "speed": 50.0 + pressure * 9.0,
			"shield_turn": SHIELD_TURN_SECONDS}
	if role == "gorgon" or role == "flying" or role == "flyer":
		return {"name": Run.ROSTERS[realm][1], "hp": 2, "damage": 9 + floori(pressure * 2.7),
			"windup": maxf(0.31, 0.57 - pressure * 0.07), "cooldown": maxf(0.71, 1.25 - pressure * 0.17),
			"speed": 82.0 + pressure * 14.0, "shield_turn": 0.0}
	if role == "caster" or role == "ranged":
		return {"name": Run.ROSTERS[realm][2], "hp": 3, "damage": 9 + floori(pressure * 2.8),
			"windup": maxf(0.39, 0.67 - pressure * 0.08), "cooldown": maxf(0.95, 1.85 - pressure * 0.31),
			"speed": 58.0 + pressure * 6.0, "shield_turn": 0.0}
	return {"name": Run.ROSTERS[realm][0], "hp": 3, "damage": 10 + floori(pressure * 2.9),
		"windup": maxf(0.29, 0.53 - pressure * 0.071), "cooldown": maxf(0.59, 1.02 - pressure * 0.13),
		"speed": 80.0 + pressure * 17.0, "shield_turn": 0.0}

static func new_timeline(profile: Dictionary) -> Dictionary:
	var phase := "wake" if float(profile.wake) > 0.0 else "idle"
	return {"phase": phase, "elapsed": 0.0, "attack_index": -1, "serial": 0,
		"weak": weak_open(profile, {}, phase, 0.0), "remaining": float(profile.wake) if phase == "wake" else float(profile.idle)}

static func attack(profile: Dictionary, timeline: Dictionary) -> Dictionary:
	var attacks: Array = profile.attacks
	return attacks[maxi(0, int(timeline.attack_index)) % attacks.size()]

static func weak_open(_profile: Dictionary, move: Dictionary, phase: String, elapsed: float) -> bool:
	if phase != "recovery":
		return false
	var delay: float = move.get("open_delay", 0.0)
	var period: float = move.get("open_time", 0.0)
	return elapsed >= delay and elapsed < delay + period

static func step(timeline: Dictionary, profile: Dictionary, dt: float, enabled := true) -> Array[String]:
	var events: Array[String] = []
	var left := maxf(0.0, dt)
	while left > 0.000001:
		var phase: String = timeline.phase
		if not enabled and phase in ["wake", "idle"]:
			break
		var move := attack(profile, timeline)
		var duration := _duration(phase, profile, move)
		var segment := minf(left, maxf(0.0, duration - float(timeline.elapsed)))
		if phase == "recovery":
			var delay: float = move.open_delay
			var closes: float = delay + float(move.open_time)
			var now: float = timeline.elapsed
			if delay > now + 0.000001:
				segment = minf(segment, delay - now)
			if closes > now + 0.000001:
				segment = minf(segment, closes - now)
		timeline.elapsed = minf(duration, float(timeline.elapsed) + segment)
		left = maxf(0.0, left - segment)
		_refresh_weak(timeline, profile, move, events)
		if float(timeline.elapsed) + 0.000001 < duration:
			timeline.remaining = duration - float(timeline.elapsed)
			continue
		_advance(timeline, profile, phase, events)
	return events

static func _duration(phase: String, profile: Dictionary, move: Dictionary) -> float:
	if phase in ["wake", "idle"]:
		return float(profile[phase])
	return float(move[phase])

static func _advance(timeline: Dictionary, profile: Dictionary, phase: String, events: Array[String]) -> void:
	match phase:
		"wake":
			timeline.phase = "idle"
			events.append("wake_finished")
		"idle":
			timeline.attack_index = int(timeline.get("queued_attack", posmod(int(timeline.attack_index) + 1, profile.attacks.size())))
			timeline.erase("queued_attack")
			timeline.serial += 1
			timeline.phase = "windup"
			events.append("windup")
		"windup":
			timeline.phase = "active"
			events.append("strike")
		"active":
			timeline.phase = "recovery"
			events.append("recover")
		_:
			timeline.phase = "idle"
			events.append("finished")
	timeline.elapsed = 0.0
	var move := attack(profile, timeline)
	timeline.remaining = _duration(timeline.phase, profile, move)
	_refresh_weak(timeline, profile, move, events)

static func _refresh_weak(timeline: Dictionary, profile: Dictionary, move: Dictionary, events: Array[String]) -> void:
	var next := weak_open(profile, move, timeline.phase, timeline.elapsed)
	if next != bool(timeline.weak):
		timeline.weak = next
		if bool(profile.background):
			events.append("weak_open" if next else "weak_closed")
