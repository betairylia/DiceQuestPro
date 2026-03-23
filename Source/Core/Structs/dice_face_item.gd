extends Resource
class_name DiceFaceItem

@export var element: Consts.Elements = Consts.Elements.Idle
@export var digit: int = 1


var sell_value: int:
	get:
		return digit


var buy_value: int:
	get:
		return digit * 3
