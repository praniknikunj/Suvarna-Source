extends RefCounted

const CHAIN_DROP_HEIGHT := 236.0

const WINDUP := {
	"sweep": "ready_blade", "charge": "ready_lunge", "fan": "ready_cast",
	"chain": "ready_slam", "pillars": "ready_cast", "waves": "ready_slam",
	"rain": "ready_cast", "bell_drop": "ready_slam", "dive": "ready_lunge",
	"bash": "ready_lunge"
}
const ATTACK := {
	"sweep": "slash", "charge": "thrust", "fan": "cast", "chain": "smash",
	"pillars": "cast", "waves": "smash", "rain": "cast", "bell_drop": "smash",
	"dive": "dive", "bash": "bash"
}
const RECOVERY := {
	"sweep": "recover_blade", "charge": "recover_lunge", "fan": "recover_cast",
	"chain": "recover_slam", "pillars": "recover_cast", "waves": "recover_slam",
	"rain": "recover_cast", "bell_drop": "recover_slam", "dive": "recover_dive",
	"bash": "recover_bash"
}
const RELEASE := {
	"sweep": 0.25, "charge": 0.25, "fan": 0.43, "chain": 0.41, "pillars": 0.46,
	"waves": 0.55, "rain": 0.49, "bell_drop": 0.73, "dive": 0.25, "bash": 0.37
}

static func clip(kind: String, phase: String) -> String:
	match phase:
		"windup": return WINDUP.get(kind, "ready_blade")
		"active": return ATTACK.get(kind, "slash")
		"recovery": return RECOVERY.get(kind, "recover")
		_: return phase

static func ratio(elapsed: float, span: float) -> float:
	return clampf(elapsed / maxf(0.001, span), 0.0, 0.9999)

static func frame(progress: float) -> int:
	return clampi(floori(progress * 8.0), 0, 7)

static func release(kind: String) -> float:
	return RELEASE.get(kind, 0.25)

static func strike_progress(kind: String, progress: float) -> float:
	var onset := release(kind)
	return clampf((progress - onset + 0.12) / maxf(0.07, 1.05 - onset), 0.0, 0.9999)

static func remote_origins(kind: String, target: float, count: int) -> Array[float]:
	var marks: Array[float] = []
	var spacing := 86.0 if kind == "chain" else (104.0 if kind == "rain" else 72.0)
	var left := 47.0 if kind == "chain" else 62.0
	var right := 914.0 if kind == "chain" else 908.0
	if kind == "bell_drop":
		marks.append(clampf(target, 104.0, 848.0))
		return marks
	for index in range(maxi(1, count)):
		marks.append(clampf(target + (index - (count - 1) * 0.5) * spacing, left, right))
	return marks
