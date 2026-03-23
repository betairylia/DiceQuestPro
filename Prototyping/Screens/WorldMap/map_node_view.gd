extends Control
class_name MapNodeView

## Visual representation of a single map node.

signal node_clicked(node_id: int)

const TYPE_LABELS := {
	MapNode.NodeType.COMBAT:   "Combat",
	MapNode.NodeType.BOSS:     "BOSS",
	MapNode.NodeType.TREASURE: "Treasure",
	MapNode.NodeType.VILLAGE:  "Village",
}

const TYPE_COLORS := {
	MapNode.NodeType.COMBAT:   Color(0.8, 0.3, 0.3),
	MapNode.NodeType.BOSS:     Color(0.9, 0.1, 0.1),
	MapNode.NodeType.TREASURE: Color(0.9, 0.8, 0.2),
	MapNode.NodeType.VILLAGE:  Color(0.3, 0.8, 0.3),
}

var map_node: MapNode
var reachable: bool = false
var visited: bool = false

@onready var _label: Label = $Label
@onready var _bg: ColorRect = $Background


func setup(node: MapNode, is_reachable: bool, is_visited: bool) -> void:
	map_node = node
	reachable = is_reachable
	visited = is_visited
	_update_visuals()


func _update_visuals() -> void:
	if not map_node:
		return

	_label.text = TYPE_LABELS.get(map_node.type, "?")

	var base_color: Color = TYPE_COLORS.get(map_node.type, Color.GRAY)

	if visited:
		_bg.color = base_color.darkened(0.6)
		_label.modulate = Color(1, 1, 1, 0.4)
	elif reachable:
		_bg.color = base_color
		_label.modulate = Color.WHITE
	else:
		_bg.color = Color(0.3, 0.3, 0.3)
		_label.modulate = Color(1, 1, 1, 0.6)


func _gui_input(event: InputEvent) -> void:
	if reachable and not visited:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			node_clicked.emit(map_node.id)