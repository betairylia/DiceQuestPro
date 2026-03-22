extends Resource
class_name DiceData

@export var type: Consts.DiceType
@export var bonus: int = 0
@export var elements: Array[Consts.Elements]


## Number of faces for this dice type.
func face_count() -> int:
	return (type + 2) * 2


## The digit on a given face (0-indexed). Base is (index + 1) + bonus.
func get_digit(index: int) -> int:
	return index + 1 + bonus


## All digits as an array, e.g. [1,2,3,4] for a D4 with bonus 0.
func get_digits() -> Array[int]:
	var result: Array[int] = []
	var n := face_count()
	for i in n:
		result.append(get_digit(i))
	return result
