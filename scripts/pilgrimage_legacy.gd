extends RefCounted

const RELICS := [
	["Pyre Seal", "A blackened signet salvaged from the burning steps."],
	["First Lotus Seed", "An ivory seed still warm from a closed blossom."],
	["Banner Clasp", "The clasp of a standard thought lost in the citadel."],
	["Listening Bead", "A cedar bead that holds the sound of falling rain."],
	["Mourning Comb", "The queen’s last ornament, cut from smoke-dark horn."],
	["Unclouded Glass", "A shard with no reflection until the vow is spoken."],
	["Pearl of the Deep", "A green pearl from beneath the guardian’s coils."],
	["Ash Sutra", "A narrow leaf inscribed before the monastery burned."],
	["Throne Thread", "One gold thread pulled from the seat of the empty king."],
	["Broken Thunder Seal", "A fractured shrine tablet shaped by lightning."]
]
const QUESTS := [
	{"id":"first_oath", "name":"Sthiravrata", "realm":3, "need":[0,1,2,3],
		"title":"The Oath That Would Not Burn", "trophy":"Sthiravrata’s Sword Knot",
		"desc":"The silk knot that held the oathkeeper’s blade. Its four twists recall the four relics of the old border.",
		"signature":"oath_pursuit"},
	{"id":"silent_bell", "name":"Karnika", "realm":7, "need":[4,5,6,7],
		"title":"Keeper of the Unstruck Bell", "trophy":"Karnika’s Bell Tongue",
		"desc":"A torn bronze clapper. Its soft edge bears the final stroke of the bell duelist.",
		"signature":"counter_chime"},
	{"id":"hollow_moon", "name":"Virachandra", "realm":8, "need":[6,7,8,9],
		"title":"The Moon Behind the Mask", "trophy":"Virachandra’s Split Mask",
		"desc":"Half an ivory theatre mask, struck clean at the brow. The other half stayed in the dark.",
		"signature":"moon_feint"}
]
const VAJRA_ID := "hundred_hands"
const VAJRA_TROPHY := "Clapper of the Hundred Hands"
const RELIC_CHANCE := 0.05

static func relic_roll(floor_seed: int) -> bool:
	var draw := RandomNumberGenerator.new()
	draw.seed = floor_seed ^ 22109670403
	return draw.randf() < RELIC_CHANCE

static func ready(quest_id: int, collected: Dictionary, unlocked: Dictionary) -> bool:
	var quest: Dictionary = QUESTS[quest_id]
	if unlocked.has(quest.id):
		return false
	for index in quest.need:
		if not collected.has(RELICS[index][0]):
			return false
	return true

static func first_ready(collected: Dictionary, unlocked: Dictionary) -> int:
	for i in range(QUESTS.size()):
		if ready(i, collected, unlocked):
			return i
	return -1

static func quest_item(item: String) -> bool:
	return RELICS.any(func(relic: Array) -> bool: return relic[0] == item)

static func milestone_id(floor_number: int) -> String:
	return "depth_%d" % floor_number

static func best_at_end(best: int, latest: int) -> int:
	return maxi(best, maxi(0, latest))

static func award_detail(id: String) -> Dictionary:
	for index in range(QUESTS.size()):
		var quest: Dictionary = QUESTS[index]
		if id == quest.id:
			return {"title":quest.title, "item":quest.trophy, "description":quest.desc, "icon":10 + index}
	if id == VAJRA_ID:
		return {"title":"The Silence After Thunder", "item":VAJRA_TROPHY,
			"description":"The golden clapper of the bell that brought the Hundred Hands down.", "icon":13}
	if id.begins_with("depth_"):
		var depth := int(id.trim_prefix("depth_"))
		return {"title":"The Unending Path · %d" % depth, "item":"",
			"description":"Defeat Vajrakala on dungeon %d of the endless Pilgrimage." % depth, "icon":14, "depth":depth}
	return {}

static func item_detail(item: String) -> Dictionary:
	for index in range(RELICS.size()):
		var relic: Array = RELICS[index]
		if relic[0] == item:
			return {"description":relic[1] + " Part of a passage vow.", "icon":index}
	for quest in QUESTS:
		if quest.trophy == item:
			return award_detail(quest.id)
	return award_detail(VAJRA_ID) if item == VAJRA_TROPHY else {}

