extends RefCounted
class_name SpellContext

var matched: MatchedSpell
var power: int
var casters: Array[Mob]
var targets: Array[Mob]
var allies:  Array[Mob]


func digit_sum() -> int:
	return matched.digit_sum()


func digit_sum_of(element: Consts.Elements) -> int:
	var total := 0
	for r in matched.matched_dice:
		if r.element == element:
			total += r.digit
	return total


func max_digit() -> int:
	var best := 0
	for r in matched.matched_dice:
		best = max(best, r.digit)
	return best


func dice_count() -> int:
	return Arr.unique(matched.matched_dice).size()


func unique_dice() -> Array[DiceResult]:
	var result: Array[DiceResult] = []
	result.assign(Arr.unique(matched.matched_dice))
	return result
