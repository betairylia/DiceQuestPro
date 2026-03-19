extends Sprite2D
class_name DiceIcon

var dice_data: DiceData


func setup(data: DiceData) -> void:
	dice_data = data
	ShowAsType(data.type)


func ShowAsType(type: Consts.DiceType) -> void:
	self.frame = type
