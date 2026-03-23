extends Control

const WORLD_MAP_SCENE := "res://Prototyping/Screens/WorldMap/WorldMap.tscn"
const GAME_OVER_SCENE := "res://Prototyping/Screens/GameOver/GameOverScreen.tscn"
const ROLLABLE_DICE_SCENE := preload("res://Prototyping/Nodes/RollableDice.tscn")

@onready var _title_label: RichTextLabel = $MarginContainer/VBox/TitleLabel
@onready var _subtitle_label: RichTextLabel = $MarginContainer/VBox/SubtitleLabel
@onready var _gold_label: RichTextLabel = $MarginContainer/VBox/GoldLabel
@onready var _roll_preview: Node2D = $RollPreview
@onready var _items_grid: GridContainer = $MarginContainer/VBox/ItemsGrid

var _reward_items: Array[DiceFaceItem] = []


func _ready() -> void:
	await _build_rewards()


func _build_rewards() -> void:
	var node := GameState.get_current_node()
	if node == null:
		SceneTransition.change_scene(WORLD_MAP_SCENE)
		return

	_clear_children(_items_grid)
	_clear_children(_roll_preview)

	_reward_items.clear()
	var awarded_gold := 0

	match node.type:
		MapNode.NodeType.TREASURE:
			if node.id not in GameState.visited_nodes:
				GameState.complete_node(node.id)
			_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_title_label.text = "宝藏"
			_subtitle_label.text = "带走一件战利品"
			_reward_items.assign(node.treasure_items)
			if node.treasure_gold > 0:
				awarded_gold = node.treasure_gold
				GameState.add_gold(node.treasure_gold)
				node.treasure_gold = 0
		_:
			_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_title_label.text = "战利品"
			_subtitle_label.text = "从敌人的骰面中挑选一件"
			_reward_items = await _roll_enemy_rewards(node)

	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.text = "获得金币 %d    当前金币 %d" % [awarded_gold, GameState.gold]

	if _reward_items.is_empty():
		_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_subtitle_label.text = "没有可领取的奖励"

	for item in _reward_items:
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 40)
		button.text = "%s %d" % [Consts.SYMBOLS.get(item.element, "?"), item.digit]
		button.theme = preload("res://Prototyping/HUD/pixelated.tres")
		button.pressed.connect(_on_reward_pressed.bind(item))
		_items_grid.add_child(button)


func _roll_enemy_rewards(node: MapNode) -> Array[DiceFaceItem]:
	var results: Array[DiceFaceItem] = []
	var cursor := 72.0

	for enemy in node.enemies:
		for dice in enemy.alive_dice:
			var dice_node := ROLLABLE_DICE_SCENE.instantiate() as RollableDice
			dice_node.position = Vector2(cursor, 0)
			cursor += 46.0
			_roll_preview.add_child(dice_node)
			dice_node.setup(dice)
			var result := await dice_node.Roll()

			var item := DiceFaceItem.new()
			item.element = result.element
			item.digit = max(1, result.digit - dice.bonus)
			results.append(item)
	return results


func _on_reward_pressed(item: DiceFaceItem) -> void:
	GameState.add_item(item)
	_finish()


func _on_skip_button_pressed() -> void:
	_finish()


func _finish() -> void:
	var node := GameState.get_current_node()
	if node != null and node.type == MapNode.NodeType.BOSS and GameState.is_run_complete():
		GameState.end_run(true)
		SceneTransition.change_scene(GAME_OVER_SCENE)
		return
	SceneTransition.change_scene(WORLD_MAP_SCENE)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
