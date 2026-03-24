extends GridContainer
class_name InventoryGrid

signal item_clicked(item: Item)

@export var columns_count: int = 6
@export var cell_size: Vector2 = Vector2(28, 28)

var filter: Callable = Callable()
var interactive: bool = true

var _slot_buttons: Dictionary = {}


func _ready() -> void:
	columns = columns_count
	refresh()


func refresh() -> void:
	columns = columns_count
	_clear_children()
	_slot_buttons.clear()

	var items := _filtered_items()
	visible = not items.is_empty()
	if not visible:
		return

	for item in items:
		var button := _create_cell(item)
		_slot_buttons[item] = button
		add_child(button)


func get_item_global_rect(item: Item) -> Rect2:
	var button: Control = _slot_buttons.get(item)
	if button == null or not is_instance_valid(button):
		return Rect2()
	return button.get_global_rect()


func _filtered_items() -> Array[Item]:
	var items: Array[Item] = []
	for item in GameState.inventory:
		if item == null:
			continue
		if filter.is_valid() and not filter.call(item):
			continue
		items.append(item)
	return items


func _create_cell(item: Item) -> Button:
	var button := Button.new()
	button.custom_minimum_size = cell_size
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.text = ""
	button.disabled = not interactive
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = _tooltip_for(item)
	button.add_theme_stylebox_override("normal", _slot_style(false, button.disabled))
	button.add_theme_stylebox_override("hover", _slot_style(true, button.disabled))
	button.add_theme_stylebox_override("pressed", _slot_style(true, button.disabled))
	button.add_theme_stylebox_override("disabled", _slot_style(false, true))

	var icon := _create_icon(item)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(icon)

	button.pressed.connect(_on_item_pressed.bind(item))
	return button


func _create_icon(item: Item) -> Control:
	if item != null and item.has_method("create_icon"):
		var icon: Control = item.call("create_icon")
		if icon is Control:
			return icon

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 0.0
	label.offset_top = 0.0
	label.offset_right = 0.0
	label.offset_bottom = 0.0
	label.text = item.display_name if item != null else "?"
	return label


func _tooltip_for(item: Item) -> String:
	if item == null:
		return ""
	if not item.description.is_empty():
		return "%s\n%s" % [item.display_name, item.description]
	return item.display_name


func _slot_style(hovered: bool, disabled: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.17, 0.17, 0.20, 0.95) if hovered else Color(0.09, 0.09, 0.11, 0.95)
	if disabled:
		style.bg_color = Color(0.11, 0.11, 0.13, 0.80)
	style.border_color = Color(0.86, 0.77, 0.44, 1.0) if hovered and not disabled else Color(0.32, 0.32, 0.36, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 2
	style.content_margin_top = 2
	style.content_margin_right = 2
	style.content_margin_bottom = 2
	return style


func _on_item_pressed(item: Item) -> void:
	if not interactive:
		return
	item_clicked.emit(item)


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
