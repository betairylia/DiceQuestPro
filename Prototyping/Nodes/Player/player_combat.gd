extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func setup(runtime_mob: Mob) -> void:
	$RollableDice1.setup(runtime_mob.data.alive_dice[0])
	$RollableDice2.setup(runtime_mob.data.alive_dice[1])
	$RollableDice3.setup(runtime_mob.data.alive_dice[2])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
