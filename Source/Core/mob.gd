extends Node2D
class_name Mob

signal dice_rolled(results: Array[DiceResult])

const ROLLABLE_DICE_SCENE = preload("res://Prototyping/Nodes/RollableDice.tscn")
const DICE_Y := 28.0
const DICE_INTERVAL := 30.0

@export var health: int
@export var data: MobData

var _dice: Array[Node] = []


func setup(mob_data: MobData) -> void:
	data = mob_data
	health = mob_data.max_health
	# Remove any previously spawned dice
	for d in _dice:
		d.queue_free()
	_dice.clear()
	# Spawn dice based on MobData
	var count := data.alive_dice.size()
	var start_x := -(count - 1) * DICE_INTERVAL / 2.0
	for i in count:
		var dice_node = ROLLABLE_DICE_SCENE.instantiate()
		dice_node.position = Vector2(start_x + i * DICE_INTERVAL, DICE_Y)
		add_child(dice_node)
		dice_node.setup(data.alive_dice[i])
		_dice.append(dice_node)


func RollAll() -> Array[DiceResult]:
	for d in _dice:
		d.Roll()
	var results: Array[DiceResult] = []
	for d in _dice:
		results.append(await d.roll_finished)
	print(results)
	dice_rolled.emit(results)
	return results
