extends Object
class_name Consts

enum DiceType {
	D4  = 0,
	D6  = 1,
	D8  = 2,
	D10 = 3,
	D12 = 4
}

enum Elements {
	Sword   = 0,
	Bow     = 1,
	Defense = 9,
	Fire    = 2,
	Water   = 3,
	Ice		= 11,
	Thunder = 4,
	Radiant	= 12,
	Nature  = 6,
	Forest  = 13,
	Heal	= 14,
	Dark    = 10,
	Poison	= 15,
	Blood	= 16,
	Wind    = 5,
	Idle    = 7,
	Revive  = 8,
}

enum DamageType{
	Regular,
	Special,
	Healing
}

const SYMBOLS = {
	Elements.Sword:   "⚔️",
	Elements.Bow:     "🏹",
	Elements.Defense: "🛡️",
	Elements.Fire:    "🔥",
	Elements.Water:   "💧",
	Elements.Ice:     "❄️",
	Elements.Thunder: "⚡",
	Elements.Radiant: "✨",
	Elements.Nature:  "🌱",
	Elements.Forest:  "🌲",
	Elements.Heal:    "💚",
	Elements.Dark:    "🌑",
	Elements.Poison:  "☠️",
	Elements.Blood:   "🩸",
	Elements.Wind:    "🌪",
	Elements.Idle:    "⌛",
	Elements.Revive:  "👼",
}

const SHORTHANDS = {
	Elements.Sword:   "S",
	Elements.Bow:     "B",
	Elements.Defense: "D",
	Elements.Fire:    "F",
	Elements.Water:   "W",
	Elements.Ice:     "I",
	Elements.Thunder: "T",
	Elements.Radiant: "L",
	Elements.Nature:  "N",
	Elements.Forest:  "G",
	Elements.Heal:    "H",
	Elements.Dark:    "K",
	Elements.Poison:  "P",
	Elements.Blood:   "X",
	Elements.Wind:    "A",
	Elements.Idle:    "_",
	Elements.Revive:  "R",
}

# Category shorthands — each maps to multiple elements it accepts.
# A category char in a pattern means "any element from this list".
const CATEGORIES = {
	"p": [Elements.Sword, Elements.Bow, Elements.Defense],  # Physical and variants, mainly white
	"f": [Elements.Fire],  # Fire and some variants that I currently have no idea yet, red color
	"w": [Elements.Water, Elements.Ice],  # Water and variants, blue color
	"t": [Elements.Thunder, Elements.Radiant],   # Thunder and variants, yellow
	"n": [Elements.Nature, Elements.Forest, Elements.Heal],   # Nature and variants, green
	"d": [Elements.Dark, Elements.Poison, Elements.Blood],   # Dark, near-black violet / crimson / red -ish
	"m": [Elements.Fire, Elements.Water, Elements.Thunder, Elements.Wind, Elements.Nature],  # Magical
}
