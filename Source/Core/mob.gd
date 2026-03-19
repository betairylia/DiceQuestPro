extends Node2D
class_name Mob

signal dice_rolled(results: Array[DiceResult])

@export var health: int
@export var data: MobData


func setup(mob_data: MobData) -> void:
	data = mob_data
	health = mob_data.max_health
	$RollableDice1.setup(data.alive_dice[0])
	$RollableDice2.setup(data.alive_dice[1])
	$RollableDice3.setup(data.alive_dice[2])


# Rolls all dice concurrently (animations play in parallel).
# Returns an Array of { value, element, is_extreme } Dictionaries.
func RollAll() -> Array[DiceResult]:
	
	$RollableDice1.Roll()
	$RollableDice2.Roll()
	$RollableDice3.Roll()
	
	var results: Array[DiceResult] = [
		await $RollableDice1.roll_finished,
		await $RollableDice2.roll_finished,
		await $RollableDice3.roll_finished,
	]
	print(results)
	
	dice_rolled.emit(results)
	
	return results
