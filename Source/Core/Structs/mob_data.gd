extends Resource
class_name MobData

@export var display_name: String = ""
@export var sprite: SpriteFrames
@export var max_health: int = 1
@export var dead: bool = false
@export var alive_dice: Array[DiceData] = []
@export var dead_dice: Array[DiceData] = []

var current_health: int = -1


func resolved_display_name() -> String:
	if not display_name.is_empty():
		return display_name
	if resource_path.is_empty():
		return "Unknown"
	return resource_path.get_file().get_basename()


func clone() -> MobData:
	var duplicate := MobData.new()
	duplicate.display_name = resolved_display_name()
	duplicate.sprite = sprite
	duplicate.max_health = max_health
	duplicate.dead = dead
	duplicate.current_health = current_health

	for dice in alive_dice:
		duplicate.alive_dice.append(dice.duplicate(true))
	for dice in dead_dice:
		duplicate.dead_dice.append(dice.duplicate(true))

	return duplicate
