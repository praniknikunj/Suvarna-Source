extends RefCounted

const BOSS_NAMES := [
	"Kaalan", "Padmavati", "Ashvaka", "Andharishi", "Mrinala",
	"Suvarnabimba", "Vishdhara", "Brhatkala", "Shunyaraja", "Vajrakala"
]

# Name, concept, boss, stone palette, architectural motif, truth fragment.
const REALMS := [
	["The Black Ghats", "Dukkha", "Kaalan, Keeper of the Burning Gate", "7e5b4a", "ghat", "Kaalan kept the funeral fires burning long after the dead stopped dying."],
	["The Lotus Gardens", "Desire", "Padmavati, the Withered Lotus", "69704e", "lotus", "Padmavati wanted enlightenment so fiercely that she tried to force it on others."],
	["The Burning Citadel", "Anger", "Senapati Ashvaka", "9a593e", "citadel", "The last general never accepted that the battle was over."],
	["The Blind Forest", "Ignorance", "Andharishi, the Blind Rishi", "48655b", "forest", "The Rishi shut his eyes. The forest learned to listen for him."],
	["The Royal Catacombs", "Attachment", "Maharani Mrinala", "756580", "tomb", "Suvarna had never left his mother willingly. The Sangha took him away."],
	["The Palace of Mirrors", "Ego", "Suvarnabimba, the Golden Prince", "948053", "mirror", "The prince in the mirror chose the throne over the Sangha."],
	["The Serpent Wells", "Fear", "Vishdhara of the Hollow Well", "4d7373", "well", "Fear gave shape to Vishdhara at the bottom of the well."],
	["The Monastery of Ash", "Memory", "Brhatkala, the Last Abbot", "867165", "monastery", "The Abbot let the monastery fall because he believed Suvarna had to survive."],
	["The Thousandfold City", "Samsara", "Shunyaraja, the Empty King", "9a7052", "city", "The Empty King offered his son a kingdom built from the dead."],
	["Vajrakala's Shrine", "Nirvana", "Vajrakala", "9e8058", "shrine", "Humanity's refusal to accept suffering gave Vajrakala a body."],
]
const VOWS := [
	["Vow of the First Teacher", ["Broken Mala", "Torn Sutra"], ["Teacher's Bell", "Teacher's Staff", "Teacher's Robe", "Teacher's Last Sutra"], "In his final moments, your teacher counted his breaths beside his fallen students."],
	["Vow of the Forgotten Brother", ["Japa Mala", "Monk's Robe"], ["Brother's Token", "Sealed Confession", "Brother's Sandals", "Brother's Letter"], "Your brother opened the gates to Vajrakala. He thought it would spare the novices."],
	["Vow of the Empty Throne", ["Broken Vajra", "Royal Signet"], ["Palace Key", "Guard's Standard", "Royal Edict", "King's Testament"], "Your father ordered your escape before he went to meet the Plundering."],
	["Vow of the Blind Seer", ["Seer's Beads", "Weathered Sutra"], ["Seer's Bowl", "Binding Cloth", "Sounding Stone", "Seer's Prophecy"], "The Seer foresaw Vajrakala's arrival centuries before the first temple was built for him."],
	["Vow of the Last Child", ["Child's Charm", "Sangha Ledger"], ["Tiny Sandal", "Wooden Horse", "Novice's Bowl", "Child's Letter"], "A second child escaped the royal city. The Sangha recorded both names."],
]
const PHASES := ["The God", "The King", "The Teacher", "The Family", "Suvarna"]
const ITEM_NOTES := {
	"Japa Mala": "The polished beads remember a teacher counting his breaths at the burning gate.",
	"Monk's Robe": "A brother's last thought clings to the seam. He hoped the novices had reached the river.",
	"Torn Sutra": "The remaining lines teach that suffering must be understood.",
	"Broken Vajra": "The broken ritual blade bears the old royal seal.",
	"Prayer Wheel": "Turn the salvaged wheel where the masonry has cracked. A sealed recess may answer.",
	"Broken Mala": "A snapped thread and seven beads. The surviving beads still hold their warmth.",
	"Royal Signet": "The signet of the Suryavansha. Its gold has darkened around the old crest."
}
