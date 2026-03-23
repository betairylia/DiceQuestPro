extends Control

## Combat wrapper scene — loads the existing combat scene with data from GameState
## and handles routing on win/lose.

const COMBAT_SCENE = preload("res://Prototyping/Prototype.tscn")

var _combat: Combat
var _defeat_overlay: PanelContainer


func _ready() -> void:
	_combat = COMBAT_SCENE.instantiate()
	add_child(_combat)

	# Wire signals
	_combat.combat_won.connect(_on_combat_won)
	_combat.combat_lost.connect(_on_combat_lost)

	# Get data from GameState
	var node: MapNode = GameState.get_current_node()
	if not node:
		return

	_combat.init(
		GameState.team,
		node.enemies,
		GameState.all_spells,
		GameState.env_die
	)


func _on_combat_won() -> void:
	GameState.complete_node(GameState.current_node_id)
	# Short delay before transition
	await get_tree().create_timer(1.0).timeout

	# Show reward screen (victory is handled in reward screen)
	SceneTransition.change_scene("res://Prototyping/Screens/Reward/RewardScreen.tscn")


func _on_combat_lost() -> void:
	await get_tree().create_timer(1.0).timeout
	_show_defeat_overlay()


func _show_defeat_overlay() -> void:
	_defeat_overlay = PanelContainer.new()
	_defeat_overlay.anchor_left = 0.25
	_defeat_overlay.anchor_right = 0.75
	_defeat_overlay.anchor_top = 0.3
	_defeat_overlay.anchor_bottom = 0.7

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_defeat_overlay.add_child(vbox)

	var title := Label.new()
	title.text = "战败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var retry_btn := Button.new()
	retry_btn.text = "重试"
	retry_btn.pressed.connect(_on_retry)
	vbox.add_child(retry_btn)

	var quit_btn := Button.new()
	quit_btn.text = "放弃"
	quit_btn.pressed.connect(_on_give_up)
	vbox.add_child(quit_btn)

	add_child(_defeat_overlay)


func _on_retry() -> void:
	GameState.restore_pre_combat_snapshot()
	SceneTransition.change_scene("res://Prototyping/Screens/Combat/CombatScreen.tscn")


func _on_give_up() -> void:
	var _summary := GameState.end_run(false)
	SceneTransition.change_scene("res://Prototyping/Screens/GameOver/GameOverScreen.tscn")