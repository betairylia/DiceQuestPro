extends CanvasLayer

const OFFSET := Vector2(8, 8)
const VIEWPORT_SIZE := Vector2(640, 360)

@onready var panel: PanelContainer = $Panel
@onready var content: RichTextLabel = $Panel/MarginContainer/Content

var follow_mouse := true

func _ready() -> void:
	panel.visible = false

func _process(_delta: float) -> void:
	if follow_mouse and panel.visible:
		_clamp_position(panel.get_global_mouse_position() + OFFSET)

func Show(text: String, global_pos: Vector2) -> void:
	content.text = text
	_clamp_position(global_pos)
	panel.visible = true

func ShowAtMouse(text: String) -> void:
	Show(text, panel.get_global_mouse_position() + OFFSET)

func Hide() -> void:
	panel.visible = false

func _clamp_position(pos: Vector2) -> void:
	var size := panel.size
	pos.x = clampf(pos.x, 0, VIEWPORT_SIZE.x - size.x)
	pos.y = clampf(pos.y, 0, VIEWPORT_SIZE.y - size.y)
	panel.position = pos
