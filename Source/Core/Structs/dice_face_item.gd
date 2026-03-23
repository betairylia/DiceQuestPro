extends Resource
class_name DiceFaceItem

## A single dice face that can be stored in inventory, bought, sold, or used to reforge.
## element: The element on this face
## digit: Raw face position (1-indexed, ignoring bonus). digit-10 means face_index 9.
@export var element: Consts.Elements
@export var digit: int

var sell_value: int:
	get: return digit

var buy_value: int:
	get: return digit * 3