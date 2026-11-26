extends RefCounted

# Pose family, anticipation, active time, recovery, open delay, open time, material.
const MOVES := {
	"bell_crater": ["bell_drop", 0.80, 1.04, 0.78, 0.08, 0.59, "temple_brass"],
	"cleaver_throw": ["charge", 0.66, 1.34, 0.64, 0.10, 0.43, "cleaver"],
	"lotus_lattice": ["pillars", 0.58, 1.31, 0.79, 0.19, 0.53, "lotus_petals"],
	"forge_gallop": ["charge", 0.56, 1.27, 0.48, 0.08, 0.33, "forge_lance"],
	"blind_bells": ["rain", 0.68, 1.42, 0.47, 0.07, 0.34, "blind_echo"],
	"veil_snare": ["rain", 0.68, 1.48, 0.59, 0.08, 0.42, "silk_veil"],
	"mirror_duet": ["sweep", 0.37, 0.94, 0.42, 0.05, 0.31, "mirror_edge"],
	"venom_coils": ["fan", 0.65, 1.45, 0.58, 0.11, 0.39, "venom_drop"],
	"bell_cadence": ["waves", 0.67, 1.52, 0.73, 0.16, 0.47, "temple_brass"],
	"crown_siege": ["pillars", 0.66, 1.76, 0.79, 0.17, 0.53, "crown_tooth"],
	"vajra_seals": ["fan", 0.46, 1.67, 0.57, 0.12, 0.37, "vajra_seal"],
	"reflection_rush": ["charge", 0.39, 1.10, 0.43, 0.06, 0.30, "mirror_edge"],
	"ash_lanterns": ["fan", 0.55, 1.05, 0.57, 0.10, 0.39, "ash_lantern"],
	"lotus_lances": ["charge", 0.52, 1.12, 0.54, 0.10, 0.36, "lotus_spear"],
	"ember_return": ["sweep", 0.45, 1.05, 0.48, 0.07, 0.34, "forge_lance"],
	"root_ambush": ["pillars", 0.48, 1.10, 0.48, 0.07, 0.34, "root_hook"],
	"bone_grid": ["waves", 0.64, 1.12, 0.56, 0.10, 0.38, "bone_idol"],
	"false_tell": ["charge", 0.43, 0.95, 0.45, 0.07, 0.31, "mirror_edge"],
	"shed_skin": ["sweep", 0.53, 1.28, 0.48, 0.08, 0.33, "venom_drop"],
	"ash_weather": ["rain", 0.55, 1.36, 0.49, 0.08, 0.33, "ash_lantern"],
	"wheel_relay": ["charge", 0.44, 1.28, 0.46, 0.06, 0.33, "spoked_wheel"],
	"lightning_weave": ["pillars", 0.45, 1.34, 0.48, 0.07, 0.34, "vajra_seal"],
	"oath_pursuit": ["charge", 0.42, 1.02, 0.47, 0.06, 0.34, "oath_steel"],
	"counter_chime": ["waves", 0.59, 1.25, 0.51, 0.09, 0.35, "temple_brass"],
	"moon_feint": ["sweep", 0.47, 1.20, 0.49, 0.08, 0.34, "moon_glaive"]
}
const BOSSES := ["cleaver_throw", "lotus_lattice", "forge_gallop", "blind_bells", "veil_snare",
	"mirror_duet", "venom_coils", "bell_cadence", "crown_siege", "vajra_seals"]
const MINIS := ["ash_lanterns", "lotus_lances", "ember_return", "root_ambush", "bone_grid",
	"false_tell", "shed_skin", "ash_weather", "wheel_relay", "lightning_weave"]
const PHASE_NAMES := [
	["The Executioner", "Blade Unbound"], ["The Withered Lotus", "The Roots Awaken"],
	["The Last General", "The Cinder Charge"], ["The Blind Rishi", "All Sound Falls"],
	["The Mourning Queen", "The Veil Draws Shut"], ["The Golden Prince", "The Broken Reflection"],
	["The Coil Below", "The Venom Rises"], ["The Last Abbot", "The Final Peal"],
	["The Empty King", "The Crown Descends"]
]
const BOSS_IDLE := [0.17, 0.14, 0.10, 0.15, 0.16, 0.07, 0.15, 0.20, 0.12, 0.08]
const BOSS_HP := [120, 116, 134, 112, 138, 104, 152, 160, 168, 184]
const BOSS_STRIDE := [115, 0, 158, 85, 96, 204, 106, 77, 0, 138]
const VAJRA_FORMS := ["vajra_seals", "crown_siege", "bell_cadence", "veil_snare", "reflection_rush"]

static func move(key: String) -> Dictionary:
	var row: Array = MOVES[key]
	return {"kind":row[0], "signature":key, "windup":row[1], "active":row[2],
		"recovery":row[3], "damage":33, "reach":96.0, "speed":300.0, "projectiles":0,
		"open_delay":row[4], "open_time":row[5], "material":row[6]}

static func variant(base: Array[Dictionary], key: String, tier: int, major: bool, distant: bool) -> Array[Dictionary]:
	var rotation: Array[Dictionary] = [move(key)]
	for index in range(base.size()):
		var attack: Dictionary = base[index].duplicate()
		if attack.kind == "bell_drop" and key == "bell_crater":
			continue
		attack.windup = maxf(0.36, float(attack.windup) * (0.87 if major else 0.96))
		attack.recovery = clampf(float(attack.recovery) * (0.83 if major else 0.87), 0.46 if not distant else 0.60, 0.89)
		attack.open_delay = 0.09 if not distant else 0.15
		attack.open_time = maxf(0.31, float(attack.recovery) - float(attack.open_delay) - 0.09)
		rotation.append(attack)
		if index == 1 and tier >= 3:
			rotation.append(move(key))
	return rotation

static func percent(maximum: int, thrust: bool, guardian: Dictionary) -> int:
	var fraction := float(guardian.get("blade_fraction", 0.032))
	if thrust:
		fraction += 0.008
	return clampi(roundi(maximum * fraction), maxi(1, ceili(maximum * 0.01)), maxi(1, floori(maximum * 0.05)))

