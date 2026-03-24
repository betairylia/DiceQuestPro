extends Resource
class_name DiceFaceItem

@export var element: Consts.Elements
@export var digit: int  ## Raw face position (1-indexed, ignoring bonus). digit-10 → face_index 9.

var sell_value: int:
	get: return digit
var buy_value: int:
	get: return digit * 3
