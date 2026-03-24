extends Control
class_name ItemConfirmPopup

signal confirmed(item: Item)
signal cancelled

@onready var _panel: PanelContainer = $Panel
@onready var _title_label: RichTextLabel = $Panel/VBox/TitleLabel
@onready var _cost_label: RichTextLabel = $Panel/VBox/CostLabel
@onready var _use_button: Button = $Panel/VBox/Buttons/UseButton
@onready var _cancel_button: Button = $Panel/VBox/Buttons/CancelButton

var _item: Item
var _viewport_margin := Vector2(12, 12)


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func open_for(item: Item, anchor: Rect2, title: String, cost_text: String) -> void:
	_item = item
	_title_label.text = title
	_cost_label.text = cost_text
	visible = true

	await get_tree().process_frame

	var desired := anchor.position + Vector2(anchor.size.x + 6.0, 0.0)
	var viewport_size := get_viewport_rect().size
	var max_pos := viewport_size - _panel.size - _viewport_margin
	max_pos.x = max(max_pos.x, _viewport_margin.x)
	max_pos.y = max(max_pos.y, _viewport_margin.y)
	_panel.position = Vector2(
		clampf(desired.x, _viewport_margin.x, max_pos.x),
		clampf(desired.y, _viewport_margin.y, max_pos.y)
	)


func close_popup() -> void:
	visible = false
	_item = null


func _on_use_button_pressed() -> void:
	confirmed.emit(_item)
	close_popup()


func _on_cancel_button_pressed() -> void:
	cancelled.emit()
	close_popup()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is not InputEventMouseButton:
		return
	if not event.pressed:
		return
	if not _panel.get_global_rect().has_point(get_global_mouse_position()):
		cancelled.emit()
		close_popup()
