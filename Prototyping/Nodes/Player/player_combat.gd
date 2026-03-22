extends Mob

@onready var _dice_preview: RichTextLabel = $DicePreview


func _ready() -> void:
	dice_changed.connect(_on_dice_changed)


func _on_dice_changed() -> void:
	var dice := get_dice()
	if dice.is_empty():
		_dice_preview.text = ""
		return
	_dice_preview.text = Consts.dice_face_preview(dice[0].dice_data)
