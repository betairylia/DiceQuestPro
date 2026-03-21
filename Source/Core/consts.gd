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
	Sword,
	Bow,
	Fire,
	Water,
	Thunder,
	Wind,
	Nature,
	Idle,
	Revive,
}

enum DamageType{
	Regular,
	Special,
	Healing
}

const SYMBOLS = {
	Elements.Sword: "⚔️",
	Elements.Bow: "🏹",
	Elements.Fire: "🔥",
	Elements.Water: "💧",
	Elements.Thunder: "⚡",
	Elements.Wind: "🌪",
	Elements.Nature: "🌱",
	Elements.Idle: "⌛",
	Elements.Revive: "👼",
}

const SHORTHANDS = {
	Elements.Sword:   "S",
	Elements.Bow:	  "B",
	Elements.Fire:    "F",
	Elements.Water:   "W",
	Elements.Thunder: "T",
	Elements.Wind:    "A",
	Elements.Nature:  "N",
	Elements.Idle:    "_",
	Elements.Revive:  "R",
}

# Category shorthands — each maps to multiple elements it accepts.
# A category char in a pattern means "any element from this list".
const CATEGORIES = {
	"P": [Elements.Sword, Elements.Bow],  # Physical — add Bow etc. later
	"M": [Elements.Fire, Elements.Water, Elements.Thunder, Elements.Wind, Elements.Nature],  # Magical
}
