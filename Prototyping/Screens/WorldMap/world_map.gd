extends Control

const START_SCENE := "res://Prototyping/Screens/StartScreen/StartScreen.tscn"
const COMBAT_SCENE := "res://Prototyping/Screens/Combat/CombatScreen.tscn"
const REWARD_SCENE := "res://Prototyping/Screens/Reward/RewardScreen.tscn"
const VILLAGE_SCENE := "res://Prototyping/Screens/Village/VillageScreen.tscn"
const NODE_VIEW_SCRIPT := preload("res://Prototyping/Screens/WorldMap/map_node_view.gd")

@onready var _region_label: RichTextLabel = $MarginContainer/VBox/Header/RegionLabel
@onready var _gold_label: RichTextLabel = $MarginContainer/VBox/Header/GoldLabel
@onready var _map_area: Control = $MarginContainer/VBox/MapFrame/MapArea
@onready var _edges: Node2D = $MarginContainer/VBox/MapFrame/MapArea/Edges
@onready var _nodes_layer: Control = $MarginContainer/VBox/MapFrame/MapArea/NodesLayer
@onready var _hint_label: RichTextLabel = $MarginContainer/VBox/HintLabel


func _ready() -> void:
	if not GameState.run_active or GameState.map == null:
		SceneTransition.change_scene(START_SCENE)
		return

	await get_tree().process_frame
	_refresh()


func _refresh() -> void:
	_update_header()
	_clear_children(_nodes_layer)
	_clear_children(_edges)

	var positions := {}
	var usable_size := _nodes_layer.size
	if usable_size.x <= 0.0 or usable_size.y <= 0.0:
		usable_size = _map_area.size

	for node_value in GameState.map.nodes.values():
		var node := node_value as MapNode
		if node == null or not node.visible:
			continue

		var pos := Vector2(
			20.0 + node.position.x * max(usable_size.x - 40.0, 1.0),
			18.0 + node.position.y * max(usable_size.y - 36.0, 1.0)
		)
		positions[node.id] = pos

		var view := NODE_VIEW_SCRIPT.new() as Button
		view.theme = preload("res://Prototyping/HUD/pixelated.tres")
		view.layout_mode = 0
		view.position = pos - Vector2(21, 15)
		view.configure(node, GameState.is_node_reachable(node.id), node.id in GameState.visited_nodes)
		view.pressed.connect(_on_node_pressed.bind(node.id))
		_nodes_layer.add_child(view)

	for node_value in GameState.map.nodes.values():
		var node := node_value as MapNode
		if node == null or not node.visible or not node.revealed_edges:
			continue
		for successor_id in node.successors:
			var successor := GameState.map.get_node(successor_id)
			if successor == null or not successor.visible:
				continue
			if not positions.has(node.id) or not positions.has(successor_id):
				continue

			var edge := Line2D.new()
			edge.default_color = Color(0.75, 0.75, 0.82, 0.8)
			edge.width = 2.0
			edge.add_point(positions[node.id])
			edge.add_point(positions[successor_id])
			_edges.add_child(edge)


func _update_header() -> void:
	var region := GameState.get_current_region()
	if region == null and not GameState.region_configs.is_empty():
		region = GameState.region_configs[0]

	_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_region_label.text = region.region_name if region != null else "未知地域"
	_gold_label.text = "金币 %d" % GameState.gold
	_hint_label.text = "选择高亮节点继续前进"


func _on_node_pressed(node_id: int) -> void:
	var node := GameState.map.get_node(node_id)
	if node == null or not GameState.is_node_reachable(node_id):
		return

	GameState.set_current_node(node_id)

	match node.type:
		MapNode.NodeType.COMBAT, MapNode.NodeType.BOSS:
			GameState.save_pre_combat_snapshot()
			SceneTransition.change_scene(COMBAT_SCENE)
		MapNode.NodeType.TREASURE:
			SceneTransition.change_scene(REWARD_SCENE)
		MapNode.NodeType.VILLAGE:
			SceneTransition.change_scene(VILLAGE_SCENE)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
