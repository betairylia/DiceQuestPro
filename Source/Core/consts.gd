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
	Elements.Sword:   "🗡",
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

const ELEMENT_COLORS = {
	# Physical (white / silver)
	Elements.Sword:   Color(0.67, 0.67, 0.67),
	Elements.Bow:     Color(0.67, 0.67, 0.67),
	Elements.Defense: Color(0.80, 0.80, 0.80),
	# Fire (orange / red)
	Elements.Fire:    Color(1.0,  0.40, 0.13),
	# Water (blue)
	Elements.Water:   Color(0.27, 0.67, 1.0),
	Elements.Ice:     Color(0.53, 0.80, 1.0),
	# Thunder (yellow)
	Elements.Thunder: Color(1.0,  0.87, 0.0),
	Elements.Radiant: Color(1.0,  0.93, 0.47),
	# Nature (green)
	Elements.Nature:  Color(0.27, 0.80, 0.27),
	Elements.Forest:  Color(0.13, 0.60, 0.33),
	Elements.Heal:    Color(0.47, 0.93, 0.47),
	# Dark (violet / crimson)
	Elements.Dark:    Color(0.40, 0.13, 0.53),
	Elements.Poison:  Color(0.60, 0.20, 0.60),
	Elements.Blood:   Color(0.67, 0.13, 0.20),
	# Wind
	Elements.Wind:    Color(0.67, 0.87, 1.0),
	# Special
	Elements.Idle:    Color(0.20, 0.20, 0.20),
	Elements.Revive:  Color(0.47, 0.93, 0.47),
}


static func colored_pattern(pattern_str: String) -> String:
	var char_to_element := {}
	for elem in SHORTHANDS:
		char_to_element[SHORTHANDS[elem]] = elem

	var category_color := {}
	for cat_char in CATEGORIES:
		var first_elem: Elements = CATEGORIES[cat_char][0]
		category_color[cat_char] = ELEMENT_COLORS[first_elem]

	var result := ""
	for i in pattern_str.length():
		var c := pattern_str[i]
		if char_to_element.has(c):
			var col: Color = ELEMENT_COLORS[char_to_element[c]]
			result += "[color=#%s]%s[/color]" % [col.to_html(false), c]
		elif category_color.has(c):
			var col: Color = category_color[c]
			result += "[color=#%s]%s[/color]" % [col.to_html(false), c]
		else:
			result += c
	return result


static func dice_face_preview(dice: DiceData) -> String:
	var face_count := dice.face_count()
	var pattern := ""
	for i in face_count:
		if i < dice.elements.size():
			pattern += SHORTHANDS.get(dice.elements[i], "?")
		else:
			pattern += "?"
	# Line break rules: D4(4)=1 line, D6(6)=1 line, D8+(8,10,12)=2 lines
	if face_count > 6:
		var half := face_count / 2
		pattern = pattern.substr(0, half) + "\n" + pattern.substr(half)
	return colored_pattern(pattern)
