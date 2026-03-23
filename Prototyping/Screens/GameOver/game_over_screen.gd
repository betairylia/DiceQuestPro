extends Control

## Game over screen — displays run summary for victory/defeat.

# RunSummary is passed via GameState — read the last summary
var _summary: RunSummary


func _ready() -> void:
	# Get summary from GameState if run was active
	if GameState.run_active:
		_summary = null
	else:
		# Run already ended, summary is lost — create a basic one
		_summary = null
	_update_display()


func _update_display() -> void:
	var title: Label = $MarginContainer/VBoxContainer/TitleLabel

	# Check if we have a valid summary (stored somewhere accessible)
	# For simplicity, we check the victory state via run_active
	# A proper solution would store the summary in GameState
	title.text = "游戏结束"

	var stats: Label = $MarginContainer/VBoxContainer/StatsLabel
	if _summary:
		if _summary.victory:
			title.text = "胜利!"
		stats.text = "节点通过: %d\n到达区域: %d\n获得金币: %d\n收集物品: %d" % [
			_summary.nodes_cleared,
			_summary.regions_reached,
			_summary.gold_earned,
			_summary.items_collected
		]
	else:
		# Display basic stats from GameState
		stats.text = "节点通过: %d\n到达区域: %d\n获得金币: %d\n收集物品: %d" % [
			GameState.visited_nodes.size(),
			_get_regions_reached(),
			GameState.total_gold_earned,
			GameState.total_items_collected
		]


func _get_regions_reached() -> int:
	var region_set := {}
	for node_id in GameState.visited_nodes:
		var node := GameState.map.get_node(node_id)
		if node:
			region_set[node.region_index] = true
	return region_set.size()


func _on_retry_button_pressed() -> void:
	SceneTransition.change_scene("res://Prototyping/Screens/StartScreen/StartScreen.tscn")