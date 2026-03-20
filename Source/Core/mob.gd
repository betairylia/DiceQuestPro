extends Node2D
class_name Mob

signal dice_rolled(results: Array[DiceResult])
signal die_state_changed
signal attack_landed(pos: Vector2, dice: DiceResult)

const ROLLABLE_DICE_SCENE = preload("res://Prototyping/Nodes/RollableDice.tscn")
const DICE_Y := 28.0
const DICE_INTERVAL := 30.0

@export var health: int
@export var data: MobData

var _dice: Array[Node] = []
var last_results: Array[DiceResult] = []


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

	# Register dice
	for i in count:

		var dice_node = ROLLABLE_DICE_SCENE.instantiate() as RollableDice
		dice_node.position = Vector2(start_x + i * DICE_INTERVAL, DICE_Y)
		add_child(dice_node)
		dice_node.setup(data.alive_dice[i])

		# Register events
		dice_node.state_entered.connect(func(_s): die_state_changed.emit())
		dice_node.attack_landed.connect(func(pos, _dicenode, dice_result): attack_landed.emit(pos, dice_result))

		_dice.append(dice_node)


# dice_rolled(results: Array[DiceResult])
func RollDice(indices: Array[int]) -> Array[DiceResult]:
	if indices.is_empty():
		dice_rolled.emit(last_results)
		return last_results
	for idx in indices:
		_dice[idx].Roll()  # start all animations concurrently
	for idx in indices:
		var result: DiceResult = await _dice[idx].roll_finished
		result.source = data
		if idx < last_results.size():
			last_results[idx] = result
		else:
			last_results.append(result)
	dice_rolled.emit(last_results)
	return last_results


# dice_rolled(results: Array[DiceResult])
func RollAll() -> Array[DiceResult]:
	last_results = []
	var indices: Array[int] = []
	for i in _dice.size():
		indices.append(i)
	return await RollDice(indices)


func has_selected_dice() -> bool:
	for die in _dice:
		if die.state == RollableDice.DiceCombatState.Selected:
			return true
	return false


# dice_rolled(results: Array[DiceResult])
func RollSelected() -> Array[DiceResult]:
	var indices: Array[int] = []
	for i in _dice.size():
		if _dice[i].state == RollableDice.DiceCombatState.Selected:
			indices.append(i)
	return await RollDice(indices)
