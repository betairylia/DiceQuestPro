extends Node2D
class_name RollableDice
signal roll_finished(result: DiceResult)

@onready var dice_icon: DiceIcon = $DiceIcon
@onready var number_label: RichTextLabel = $Number
@onready var element_label: RichTextLabel = $Element

var dice_data: DiceData

# Animation config
const ANIM_STEPS := 14          # total frames of cycling
const ANIM_INTERVAL_START := 0.04  # fast (seconds per step)
const ANIM_INTERVAL_END   := 0.13  # slow (deceleration)


func setup(data: DiceData) -> void:
	dice_data = data
	dice_icon.setup(data)
	_show_face(0)


# Rolls the dice with a slot-machine animation.
# Triggers `roll_finished` event with ("value": int, "element": Consts.Elements, "is_extreme": bool)
# "is_extreme" is true when the last face of the dice is rolled
# (e.g. face index 3 on a d4, face index 5 on a d6).
func Roll() -> DiceResult:
	assert(dice_data != null, "RollableDice: call setup() before Roll()")

	var face_count: int = dice_data.digits.size()
	var rolled_index: int = randi() % face_count
	var is_extreme: bool  = rolled_index == face_count - 1

	# Decelerating slot-machine animation
	for i in ANIM_STEPS:
		var t := float(i) / float(ANIM_STEPS - 1)
		var interval := lerpf(ANIM_INTERVAL_START, ANIM_INTERVAL_END, t)
		_show_face(randi() % face_count)
		await get_tree().create_timer(interval).timeout

	# Settle on the final result
	_show_face(rolled_index)
	
	var result: DiceResult = DiceResult.new(
		dice_data.digits[rolled_index],
		dice_data.elements[rolled_index],
		is_extreme
	)
	
	roll_finished.emit(
		result
	)
	
	return result


func _show_face(index: int) -> void:
	number_label.text  = str(dice_data.digits[index])
	var elem_index: int = index % dice_data.elements.size()
	element_label.text  = Consts.SYMBOLS[dice_data.elements[elem_index]]
