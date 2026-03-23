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
