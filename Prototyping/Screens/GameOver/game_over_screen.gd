extends Control

var _summary: RunSummary


func _ready() -> void:
	if GameState.run_active:
		_summary = GameState.end_run(GameState.is_run_complete())
	_update_display()


func _update_display() -> void:
	var title: Label = $MarginContainer/VBoxContainer/TitleLabel

	if _summary and _summary.victory:
		title.text = "胜利!"
	else:
		title.text = "游戏结束"

	var stats: Label = $MarginContainer/VBoxContainer/StatsLabel
	if _summary:
		stats.text = "节点通过: %d\n到达区域: %d\n获得金币: %d\n收集物品: %d" % [
			_summary.nodes_cleared,
			_summary.regions_reached,
			_summary.gold_earned,
			_summary.items_collected
		]
	else:
		stats.text = ""


func _on_retry_button_pressed() -> void:
	SceneTransition.change_scene("res://Prototyping/Screens/StartScreen/StartScreen.tscn")
