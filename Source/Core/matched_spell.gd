extends Object
class_name MatchedSpell

var spell: Spell
var level: int                       # 0-based index into spell.patterns
var matched_dice: Array[DiceResult]  # one entry per token consumed;
									 # extreme die appears twice if it fills 2 tokens


func digit_sum() -> int:
	var total := 0
	for r in matched_dice:
		total += r.digit
	return total


func source_mobs() -> Array:
	var seen := {}
	var unique: Array = []
	for r in matched_dice:
		if r.source != null and not seen.has(r.source):
			seen[r.source] = true
			unique.append(r.source)
	return unique
