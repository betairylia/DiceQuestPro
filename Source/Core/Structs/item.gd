extends Resource
class_name Item

enum ItemType {
	DiceFace,
	Consumable
}


class CombatConsumeContext extends RefCounted:
	var player_results: Array[DiceResult] = []
	var players: Array[Mob] = []
	var combat_node: Node
	var dice_matcher


@export var display_name: String = ""
@export_multiline var description: String = ""
@export var item_type: ItemType = ItemType.Consumable
@export var is_consumable_in_combat: bool = false


func create_icon() -> Control:
	var label := Label.new()
	label.custom_minimum_size = Vector2(24, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = "?"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func consume(_ctx: CombatConsumeContext) -> void:
	pass


static func build_icon_shell(panel_color: Color = Color(0.15, 0.16, 0.18), border_color: Color = Color(0.92, 0.89, 0.72)) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(24, 24)
	root.size = Vector2(24, 24)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_right = 2
	style.corner_radius_bottom_left = 2
	panel.add_theme_stylebox_override("panel", style)

	root.add_child(panel)
	return root


static func build_icon_label(text: String, color: Color, font_size: int = 11) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label
