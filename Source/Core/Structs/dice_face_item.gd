extends Item
class_name DiceFaceItem

@export var element: Consts.Elements = Consts.Elements.Idle:
	set(value):
		element = value
		_sync_metadata()

@export var digit: int = 1:
	set(value):
		digit = max(value, 1)
		_sync_metadata()


func _init() -> void:
	item_type = ItemType.DiceFace
	is_consumable_in_combat = true
	_sync_metadata()


var sell_value: int:
	get:
		return digit


var buy_value: int:
	get:
		return digit * 3


func create_icon() -> Control:
	var root := Item.build_icon_shell(Color(0.18, 0.16, 0.12), Consts.ELEMENT_COLORS.get(element, Color.WHITE))

	var element_label := Item.build_icon_label(Consts.SYMBOLS.get(element, "?"), Consts.ELEMENT_COLORS.get(element, Color.WHITE), 10)
	element_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	element_label.offset_top = -4.0
	root.add_child(element_label)

	var digit_label := Item.build_icon_label(str(digit), Color(1.0, 0.97, 0.88), 9)
	digit_label.position = Vector2(0, 9)
	digit_label.size = Vector2(24, 12)
	root.add_child(digit_label)

	return root


func consume(ctx: Item.CombatConsumeContext) -> void:
	var result := DiceResult.new(digit, element, false)
	result.source = null
	result.node = null
	ctx.player_results.append(result)

	if ctx.combat_node is not Combat:
		return

	var combat := ctx.combat_node as Combat
	var visual := create_icon()
	visual.modulate = Color(1.0, 1.0, 1.0, 0.7)
	visual.position = combat.get_next_virtual_die_position()
	combat.add_child(visual)
	combat.track_virtual_die_node(visual)

	var combined_results := ctx.player_results.duplicate()
	var env_result := combat.get_environment_result()
	if env_result != null:
		combined_results.append(env_result)

	var matcher = ctx.dice_matcher if ctx.dice_matcher != null else DiceMatcher
	var matched_spells: Array[MatchedSpell] = []
	matched_spells.assign(matcher.match_all_spells(combined_results, combat.spells))
	combat.set_player_matched_spells(matched_spells)
	combat.announce_item_use("%s +%d!" % [Consts.SYMBOLS.get(element, "?"), digit], Consts.ELEMENT_COLORS.get(element, Color.WHITE))


func _sync_metadata() -> void:
	display_name = "%s %d" % [Consts.SYMBOLS.get(element, "?"), digit]
	description = "Add a %s %d die face to this turn." % [Consts.SHORTHANDS.get(element, "?"), digit]
