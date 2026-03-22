extends Object
class_name DiceResult

const UNROLLED_DIGIT := 0

var digit: int
var element: Consts.Elements
var is_extreme: bool
var source: Mob  # set by Mob.RollAll(); null if not from a Mob
var node: RollableDice


func is_unrolled() -> bool:
	return digit == UNROLLED_DIGIT


static func Unrolled(die: RollableDice, src: Mob) -> DiceResult:
	var r := DiceResult.new(UNROLLED_DIGIT, Consts.Elements.Idle, false)
	r.node = die
	r.source = src
	return r

func _init(digit: int, elem: Consts.Elements, isex: bool):
	self.digit = digit
	self.element = elem
	self.is_extreme = isex

func _to_string() -> String:
	return "DiceResult(digit=%d, element=%s, is_extreme=%s)" % [digit, Consts.Elements.keys()[element], is_extreme]

static func Flatten(arr: Array) -> Array[DiceResult]:
	var _result: Array[DiceResult] = []
	for elem in arr:
		_result.append_array(elem)
	return _result
