extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$RollableDice1/DiceIcon.ShowAsType(Consts.DiceType.D12)
	$RollableDice2/DiceIcon.ShowAsType(Consts.DiceType.D8)
	$RollableDice3/DiceIcon.ShowAsType(Consts.DiceType.D4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
