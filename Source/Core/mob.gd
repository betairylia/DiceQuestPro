extends Node2D
class_name Mob

# signal attack_landed(pos: Vector2, dice: DiceResult)
signal being_attacked(info: DamageInfo)
signal health_changed(health: int, max_health: int)
signal died
signal revived

const ROLLABLE_DICE_SCENE = preload("res://Prototyping/Nodes/RollableDice.tscn")
const DICE_Y := 28.0
const DICE_INTERVAL := 30.0

@export var health: int
@export var data: MobData

var _dice: Array[RollableDice] = []
var _is_dead: bool = false


func setup(mob_data: MobData) -> void:
	data = mob_data
	health = mob_data.max_health
	_is_dead = false
	_rebuild_dice(data.alive_dice)
	health_changed.emit(health, data.max_health)


func revive(new_health: int) -> void:
	health = clamp(new_health, 1, data.max_health)
	_is_dead = false
	_rebuild_dice(data.alive_dice)
	health_changed.emit(health, data.max_health)
	revived.emit()


func get_damage_heal(info: DamageInfo) -> void:

	var prev_health = health

	if info.type == Consts.DamageType.Healing:
		health += info.value
	else:
		health -= info.value

	health = clamp(health, 0, data.max_health)

	var resolved_info = DamageInfo.new(
		abs(prev_health - health),
		info.type
	)

	being_attacked.emit(resolved_info)
	health_changed.emit(health, data.max_health)

	if health == 0 and not _is_dead:
		_is_dead = true
		_rebuild_dice(data.dead_dice)
		died.emit()


func is_alive() -> bool:
	return not _is_dead


func get_dice() -> Array[RollableDice]:
	return _dice


func _rebuild_dice(dice_data: Array[DiceData]) -> void:
	for d in _dice:
		d.queue_free()
	_dice.clear()

	var count := dice_data.size()
	var start_x := -(count - 1) * DICE_INTERVAL / 2.0

	for i in count:
		var dice_node = ROLLABLE_DICE_SCENE.instantiate() as RollableDice
		dice_node.position = Vector2(start_x + i * DICE_INTERVAL, DICE_Y)
		add_child(dice_node)
		dice_node.setup(dice_data[i])
		dice_node.source = data
		_dice.append(dice_node)
