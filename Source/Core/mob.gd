extends Object
class_name Mob

@export var health: int
@export var data: MobData

func _init(mob_data: MobData) -> void:
	data = mob_data
	health = mob_data.max_health
