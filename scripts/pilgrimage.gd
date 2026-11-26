extends RefCounted

const ROOMS_PER_REALM := 10
const REALM_COUNT := 10
const ROSTERS := [
	["Vratapala", "Bhasmanaga", "Jvaladuta", "ember", "#da824d"],
	["Padmasevaka", "Kumudini", "Kamavisha", "petal", "#da87a8"],
	["Lohayodha", "Angarapaksha", "Agnishara", "lance", "#f2a16d"],
	["Vanaraksha", "Nishapaksha", "Shabdamuni", "echo", "#a0bca0"],
	["Pretadvara", "Chhayarani", "Shokadhari", "orbit", "#be90c3"],
	["Darpanakara", "Mayapaksha", "Svarnashatru", "mirror", "#66bad0"],
	["Nagapala", "Vishanaga", "Vishadhara", "venom", "#a4c66e"],
	["Bhasmabhikshu", "Dhumasakha", "Ghantanada", "bell", "#d0a773"],
	["Chakrayodha", "Yantrapaksha", "Kaladuta", "wheel", "#cc7167"],
	["Vajradhara", "Netrapaksha", "Sutravakta", "script", "#edca80"]
]
const NARRATION := [
	["Suffering stains the steps of the Black Ghats. The dead cannot finish dying here. Follow their lamps through the rain. Kaalan, the old royal executioner, keeps the burning gate and counts the breaths of everyone still alive.", "The lamps still burn for those who cannot die."],
	["In the Lotus Gardens, desire put down roots. A nun named Padmavati wanted every living soul to awaken, whether they wished it or not. Now the pond remembers the faces her petals swallowed. Mind where the blossoms turn.", "Some blossoms still remember their faces."],
	["The Burning Citadel never heard the ceasefire. Under its broken walls, old commands rise from the furnaces. Senapati Ashvaka marches in armour that has become his skin. Let the fire pass before you answer his charge.", "The general never heard the battle end."],
	["The Blind Forest learned to hear through its roots. Andharishi took his own sight, believing that darkness would shelter him from suffering. Here, even a footstep can betray your place. Watch the branches when the forest falls still.", "Here, even the roots are listening."],
	["The Royal Catacombs preserve what the dynasty could not keep. Beyond the curtains, a voice you remember will ask why you left her. The Sangha took you away as a child. Maharani Mrinala has been waiting ever since.", "Something behind the curtains remembers its son."],
	["The Palace of Mirrors offers a throne in every reflection. In one, Suvarna never took his vow. Suvarnabimba, the Golden Prince, wears that other life like armour. Every opening he gives you is one you would have left yourself.", "The prince in the glass never took the vow."],
	["Below the Serpent Wells, fear carved stairs into the dark. The water has carried every whispered warning into the same chamber. Vishdhara coils there beneath the last reflection. Keep moving when the depths begin to answer.", "The deepest water has learned your fears."],
	["In the Monastery of Ash, old prayers rise with the dust. Brhatkala, the last abbot, let Vajrakala through the gates so that one novice might live. Some remembered him as a traitor. Walk among the bells and hear what he remembered.", "The last Abbot opened the gate."],
	["Every street in the Thousandfold City ends at the same ruined throne. Shunyaraja, the Empty King, has kept his crown and forgotten his face. He will offer to rebuild your inheritance from the dead. Listen carefully to what he asks of you.", "An empty crown still commands the dead."],
	["Vajrakala waits beneath the thousand arms of his shrine. Humanity gave him a body when it begged for a world without suffering. He knows every face you have lost. When he wears your own, remember why you kept walking.", "Even a god can wear your grief."]
]

static func realm_at(floor_number: int) -> int:
	return posmod((maxi(1, floor_number) - 1) / ROOMS_PER_REALM, REALM_COUNT)

static func active_realm(run_seed: int, floor_number: int) -> int:
	if floor_number <= 100:
		return realm_at(floor_number)
	if floor_number % 100 == 0:
		return REALM_COUNT - 1
	var local := RandomNumberGenerator.new()
	local.seed = floor_seed(run_seed ^ 0x4b8de3, floor_number)
	return local.randi_range(0, REALM_COUNT - 2 if is_boss_floor(floor_number) else REALM_COUNT - 1)

static func endless_miniboss(run_seed: int, floor_number: int) -> bool:
	if floor_number <= 100 or is_boss_floor(floor_number):
		return false
	var local := RandomNumberGenerator.new()
	local.seed = floor_seed(run_seed ^ 0x76f20b, floor_number)
	return local.randf() < 0.16

static func is_boss_floor(floor_number: int) -> bool:
	return posmod(floor_number, ROOMS_PER_REALM) == 0

static func lap_at(floor_number: int) -> int:
	return (maxi(1, floor_number) - 1) / (ROOMS_PER_REALM * REALM_COUNT)

static func difficulty(floor_number: int) -> float:
	return log(1.0 + (maxi(1, floor_number) - 1) * 0.083) + (maxi(1, floor_number) - 1) * 0.018

static func floor_seed(run_seed: int, floor_number: int) -> int:
	return run_seed ^ (floor_number * 2654435761)
