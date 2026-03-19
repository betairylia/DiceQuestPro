extends Object
class_name DiceResult

var digit: int
var element: Consts.Elements
var is_extreme: bool
var source: MobData  # set by Mob.RollAll(); null if not from a Mob

func _init(digit: int, elem: Consts.Elements, isex: bool):
	self.digit = digit
	self.element = elem
	self.is_extreme = isex

func _to_string() -> String:
	return "DiceResult(digit=%d, element=%s, is_extreme=%s)" % [digit, Consts.Elements.keys()[element], is_extreme]
