extends Control

const MAP_NODE_VIEW_SCENE = preload("res://Prototyping/Screens/WorldMap/MapNodeView.tscn")

# Map display area within 640x360 viewport
const MAP_MARGIN := Vector2(40, 50)
const MAP_SIZE := Vector2(560, 260)

var _node_views: Dictionary = {}  ## {int: MapNodeView}


func _ready() -> void:
	_build_map()


func _build_map() -> void:
	var map := GameState.map
	if not map:
		return

	# Update region label
	$RegionLabel.text = _get_current_region_name()

	# Gold display
	$GoldLabel.text = "Gold: %d" % GameState.gold

	# Create node views
	for node_id in map.nodes:
		var node: MapNode = map.nodes[node_id]
		if not node.visible:
			continue

		var is_reachable := _is_reachable(node)
		var is_visited := node_id in GameState.visited_nodes

		var view: MapNodeView = MAP_NODE_VIEW_SCENE.instantiate()
		view.position = MAP_MARGIN + node.position * MAP_SIZE
		$Nodes.add_child(view)
		view.setup(node, is_reachable, is_visited)
		view.node_clicked.connect(_on_node_clicked)
		_node_views[node_id] = view

	queue_redraw()


func _get_current_region_name() -> String:
	if GameState.map and not GameState.map.regions.is_empty():
		var idx := clampi(GameState.current_region_index, 0, GameState.map.regions.size() - 1)
		return GameState.map.regions[idx].region_name
	return ""


func _is_reachable(node: MapNode) -> bool:
	if node.id in GameState.visited_nodes:
		return false
	# Start nodes: reachable if no start node visited yet
	if node.id in GameState.map.start_node_ids:
		for sid in GameState.map.start_node_ids:
			if sid in GameState.visited_nodes:
				return false
		return true
	# Regular: reachable if any predecessor visited
	for pred_id in node.predecessors:
		if pred_id in GameState.visited_nodes:
			return true
	return false


func _on_node_clicked(node_id: int) -> void:
	GameState.current_node_id = node_id
	var node: MapNode = GameState.map.get_node(node_id)
	if not node:
		return

	# Update region index
	GameState.current_region_index = node.region_index

	match node.type:
		MapNode.NodeType.COMBAT, MapNode.NodeType.BOSS:
			GameState.save_pre_combat_snapshot()
			SceneTransition.change_scene("res://Prototyping/Screens/Combat/CombatScreen.tscn")
		MapNode.NodeType.VILLAGE:
			GameState.complete_node(node_id)
			GameState.heal_team()
			SceneTransition.change_scene("res://Prototyping/Screens/Village/VillageScreen.tscn")
		MapNode.NodeType.TREASURE:
			_collect_treasure(node)


func _collect_treasure(node: MapNode) -> void:
	GameState.add_gold(node.treasure_gold)
	for item in node.treasure_items:
		GameState.add_item(item)
	GameState.complete_node(node.id)
	# Refresh map
	_clear_map()
	_build_map()


func _clear_map() -> void:
	for child in $Nodes.get_children():
		child.queue_free()
	_node_views.clear()


func _draw() -> void:
	var map := GameState.map
	if not map:
		return
	for node_id in _node_views:
		var node: MapNode = map.nodes[node_id]
		if not node.revealed_edges:
			continue
		var from_view: MapNodeView = _node_views[node_id]
		var from_pos: Vector2 = from_view.position + from_view.size / 2
		for succ_id in node.successors:
			if succ_id in _node_views:
				var to_view: MapNodeView = _node_views[succ_id]
				var to_pos: Vector2 = to_view.position + to_view.size / 2
				draw_line(from_pos, to_pos, Color(0.5, 0.5, 0.5, 0.7), 1.5)
