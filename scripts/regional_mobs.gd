extends RefCounted

# Melee rows: walk speed, reach, lunge speed, tell length, attack interval.
const MELEE := [
	[79.0, 64.0, 0.0, 0.52, 1.05],     # Black Ghats cleaver
	[71.0, 78.0, 0.0, 0.64, 1.18],     # Lotus sickle
	[83.0, 63.0, 172.0, 0.52, 1.14],   # Citadel thrust
	[104.0, 55.0, 64.0, 0.40, 0.89],   # Forest ambush
	[63.0, 87.0, 0.0, 0.69, 1.15],     # Catacomb sweep
	[96.0, 64.0, 143.0, 0.46, 0.98],   # Mirror feint
	[76.0, 72.0, 111.0, 0.57, 1.06],   # Well pounce
	[86.0, 69.0, 0.0, 0.53, 0.86],     # Monastery staff
	[94.0, 67.0, 166.0, 0.55, 1.01],   # Clockwork rush
	[105.0, 79.0, 190.0, 0.47, 0.98]   # Lightning shrine spear
]

# Flight rows: hover height, travel speed, dive speed, dive depth, dive curve.
const FLIGHT := [
	[365.0, 68.0, 220.0, 58.0, 1.2],
	[357.0, 63.0, 180.0, 65.0, 0.55],
	[352.0, 79.0, 272.0, 74.0, 1.8],
	[358.0, 87.0, 212.0, 65.0, 0.78],
	[362.0, 64.0, 167.0, 60.0, 0.55],
	[354.0, 79.0, 242.0, 70.0, 0.9],
	[348.0, 74.0, 260.0, 76.0, 1.5],
	[366.0, 75.0, 191.0, 55.0, 0.58],
	[356.0, 91.0, 267.0, 69.0, 1.25],
	[351.0, 98.0, 284.0, 74.0, 1.0]
]

# Shield rows: approach speed, counter reach, counter tell. The turn delay is shared.
const SHIELD := [
	[51.0, 76.0, 0.49], [49.0, 80.0, 0.55], [63.0, 85.0, 0.56], [66.0, 66.0, 0.40],
	[43.0, 91.0, 0.64], [67.0, 75.0, 0.44], [55.0, 83.0, 0.51], [60.0, 69.0, 0.45],
	[70.0, 81.0, 0.49], [76.0, 88.0, 0.46]
]

# Casters share the realm's projectile style and choose when to give up their ground.
const CASTER_RETREAT := [110.0, 142.0, 145.0, 86.0, 123.0, 155.0, 82.0, 99.0, 130.0, 154.0]
