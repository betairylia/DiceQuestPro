extends Node2D
class_name RollableDice

signal roll_finished(result: DiceResult)
signal state_entered(state: DiceCombatState)
# signal attack_landed(pos: Vector2, dice: RollableDice, dice_result: DiceResult)

@onready var dice_icon: DiceIcon = $DiceIcon
@onready var number_label: RichTextLabel = $DiceIcon/Number
@onready var element_label: RichTextLabel = $DiceIcon/Element
@onready var background: Sprite2D = $Background

enum DiceCombatState{
	Unselected = 0,
	Selected = 1,
	Determined = 2,
	Attacking = 3,
}

var dice_data: DiceData
var dice_result: DiceResult
var source: Mob
var state: DiceCombatState

# Animation config
const ANIM_STEPS := 14          # total frames of cycling
const ANIM_INTERVAL_START := 0.03  # fast (seconds per step)
const ANIM_INTERVAL_END   := 0.07  # slow (deceleration)


# func _ready():
	# setup(load("res://Prototyping/Data/FighterD12.tres"))
	# _set_state(DiceCombatState.Determined)
	# Attack([])


func setup(data: DiceData) -> void:
	dice_data = data
	dice_icon.setup(data)
	_set_state(DiceCombatState.Unselected)
	_show_face(0)


# Rolls the dice with a slot-machine animation.
# Triggers `roll_finished` event with ("value": int, "element": Consts.Elements, "is_extreme": bool)
# "is_extreme" is true when the last face of the dice is rolled
# (e.g. face index 3 on a d4, face index 5 on a d6).
func Roll() -> DiceResult:
	assert(dice_data != null, "RollableDice: call setup() before Roll()")

	var face_count: int = dice_data.face_count()
	var rolled_index: int = randi() % face_count
	var is_extreme: bool  = rolled_index == face_count - 1

	# Decelerating slot-machine animation
	for i in ANIM_STEPS:
		var t := float(i) / float(ANIM_STEPS - 1)
		var interval := lerpf(ANIM_INTERVAL_START, ANIM_INTERVAL_END, t)
		_show_face(randi() % face_count)
		await get_tree().create_timer(interval).timeout

	# Settle on the final result
	_show_face(rolled_index)
	
	var result: DiceResult = DiceResult.new(
		dice_data.get_digit(rolled_index),
		dice_data.elements[rolled_index],
		is_extreme
	)
	result.source = source
	result.node = self

	dice_result = result
	roll_finished.emit(result)

	return dice_result


func _show_face(index: int) -> void:
	number_label.text  = str(dice_data.get_digit(index))
	var elem_index: int = index % dice_data.elements.size()
	element_label.text  = Consts.SYMBOLS[dice_data.elements[elem_index]]


func SetState(s: DiceCombatState) -> void:
	_set_state(s)

func _set_state(state: DiceCombatState) -> void:
	self.state = state
	background.frame = state
	state_entered.emit(state)


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if state != DiceCombatState.Unselected and state != DiceCombatState.Selected:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if state == DiceCombatState.Unselected:
			_set_state(DiceCombatState.Selected)
		elif state == DiceCombatState.Selected:
			_set_state(DiceCombatState.Unselected)


# ---- Attack logic ----

func _attack(available_targets: Array[Mob], current_target: Mob) -> void:

	var target: Mob = current_target

	# Repick another target if current target is dead
	if not Targeting.validate(dice_result.element, target):
		target = Targeting.pick(dice_result.element, available_targets)
	
	# No valid targets, do nothing
	if target == null:
		return
	
	target.get_damage_heal(DamageInfo.new(
		dice_result.digit,
		Consts.DamageType.Regular
	))

	# Crit!
	if dice_result.is_extreme:
		target.get_damage_heal(DamageInfo.new(
			dice_result.digit,
			Consts.DamageType.Regular
		))

func AnimatedAttack(available_targets: Array[Mob], delay: float = 0) -> void:

	if state != DiceCombatState.Determined:
		return
	
	if len(available_targets) == 0:
		return

	var target = Targeting.pick(dice_result.element, available_targets)
	if target == null:
		return
	var target_pos_global = target.global_position

	_set_state(DiceCombatState.Attacking)

	var t = create_tween()
	var current_pos = dice_icon.global_position
	t.tween_property(dice_icon, "global_position", current_pos + Vector2.DOWN * 10.0, 0.2 + delay).set_ease(Tween.EASE_OUT)
	t.tween_property(dice_icon, "global_position", target_pos_global, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_callback(
		_attack.bind(available_targets, target)
	)
	t.tween_property(dice_icon, "global_position", current_pos, 0.4).set_ease(Tween.EASE_OUT).set_delay(0.05)

	await t.finished

	_set_state(DiceCombatState.Determined)
