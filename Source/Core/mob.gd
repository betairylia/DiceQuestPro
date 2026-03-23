extends Node2D
class_name Mob

# signal attack_landed(pos: Vector2, dice: DiceResult)
signal being_attacked(info: DamageInfo)
signal health_changed(health: int, max_health: int)
signal died
signal revived
signal dice_changed

const ROLLABLE_DICE_SCENE = preload("res://Prototyping/Nodes/RollableDice.tscn")
const POPUP_TEXT_SCENE = preload("res://Prototyping/Nodes/popup_text.tscn")
const DICE_Y := 28.0
const DICE_INTERVAL := 30.0

const KNOCKBACK_DIST    := 8.0
const KNOCKBACK_DURATION := 0.6
const FLASH_DURATION    := 0.6
const FLASH_COLOR       := Color(1.0, 0.25, 0.25)

@export var health: int
@export var data: MobData
@export var knockback_direction: Vector2 = Vector2(1, 0)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _name_label: RichTextLabel = $AnimatedSprite2D/Name

var _dice: Array[RollableDice] = []
var _is_dead: bool = false
var _origin_pos: Vector2
var _knockback_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	_origin_pos = Vector2(0, 0)


func setup(mob_data: MobData) -> void:
	data = mob_data
	if data.sprite != null:
		_sprite.sprite_frames = data.sprite

	_name_label.text = data.resolved_display_name()
	_name_label.visible = not _name_label.text.is_empty()

	if data.current_health < 0:
		data.current_health = data.max_health

	if data.dead or data.current_health <= 0:
		health = 0
		_is_dead = true
		_rebuild_dice(data.dead_dice)
	else:
		health = clamp(data.current_health, 1, data.max_health)
		_is_dead = false
		_rebuild_dice(data.alive_dice)
	health_changed.emit(health, data.max_health)


func revive(new_health: int) -> void:
	health = clamp(new_health, 1, data.max_health)
	_is_dead = false
	data.dead = false
	data.current_health = health
	_rebuild_dice(data.alive_dice)
	health_changed.emit(health, data.max_health)
	_spawn_popup(DamageInfo.new(
		health,
		Consts.DamageType.Healing
	))
	revived.emit()


func get_damage_heal(info: DamageInfo) -> void:

	if _is_dead:
		return

	var prev_health = health

	if info.type == Consts.DamageType.Healing:
		health += info.value
	else:
		health -= info.value

	health = clamp(health, 0, data.max_health)
	data.current_health = health

	var resolved_info = DamageInfo.new(
		abs(prev_health - health),
		info.type
	)

	being_attacked.emit(resolved_info)
	health_changed.emit(health, data.max_health)

	if resolved_info.value > 0:
		_spawn_popup(resolved_info)
		if info.type != Consts.DamageType.Healing:
			_play_hit_anim()

	if health == 0 and not _is_dead:
		_is_dead = true
		data.dead = true
		_rebuild_dice(data.dead_dice)
		died.emit()
	elif health > 0:
		data.dead = false


func is_alive() -> bool:
	return not _is_dead


func _play_hit_anim() -> void:
	# Knockback: additive — new hits push further from origin
	if _knockback_tween:
		_knockback_tween.kill()
	_sprite.position += knockback_direction * KNOCKBACK_DIST
	_knockback_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_knockback_tween.tween_property(_sprite, "position", _origin_pos, KNOCKBACK_DURATION)

	# Red flash: max — always reset to full red, extend the fade
	if _flash_tween:
		_flash_tween.kill()
	_sprite.modulate = FLASH_COLOR
	_flash_tween = create_tween().set_ease(Tween.EASE_IN)
	_flash_tween.tween_property(_sprite, "modulate", Color.WHITE, FLASH_DURATION)


func _spawn_popup(info: DamageInfo) -> void:
	var popup = POPUP_TEXT_SCENE.instantiate()
	var popup_color: Color
	if info.type == Consts.DamageType.Healing:
		popup_color = popup.COLOR_HEAL
	else:
		popup_color = popup.COLOR_DAMAGE
	popup.setup(str(info.value), knockback_direction.x, popup_color)
	popup.position = lerp(Vector2.ZERO, _sprite.position, 0.3) + Vector2.UP * 20
	add_child(popup)


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
		dice_node.source = self
		_dice.append(dice_node)
	dice_changed.emit()
