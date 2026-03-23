extends Control

const START_SCENE := "res://Prototyping/Screens/StartScreen/StartScreen.tscn"

@onready var _title_label: RichTextLabel = $MarginContainer/VBox/TitleLabel
@onready var _summary_label: RichTextLabel = $MarginContainer/VBox/SummaryLabel


func _ready() -> void:
	var summary := GameState.last_run_summary
	if summary == null:
		summary = RunSummary.new()

	_title_label.text = "[center]%s[/center]" % ("胜利" if summary.victory else "游戏结束")
	_summary_label.text = (
		"[center]清理节点 %d\n抵达区域 %d\n获得金币 %d\n收集骰面 %d[/center]"
		% [summary.nodes_cleared, summary.regions_reached, summary.gold_earned, summary.items_collected]
	)


func _on_try_again_button_pressed() -> void:
	SceneTransition.change_scene(START_SCENE)
