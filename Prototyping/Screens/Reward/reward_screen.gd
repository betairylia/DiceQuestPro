extends Control

var _items: Array[DiceFaceItem] = []
var _item_buttons: Array[Button] = []


func _ready() -> void:
	_generate_items()
	_display_items()


func _generate_items() -> void:
	var node: MapNode = GameState.get_current_node()
	if not node:
		return

	for enemy_data: MobData in node.enemies:
		for dice: DiceData in enemy_data.alive_dice:
			# Roll once: random face
			var face_idx := randi() % dice.face_count()
			var element: Consts.Elements = Consts.Elements.Idle
			if face_idx < dice.elements.size():
				element = dice.elements[face_idx]

			var item := DiceFaceItem.new()
			item.element = element
			item.digit = face_idx + 1  # 1-indexed raw face position
			_items.append(item)


func _display_items() -> void:
	var grid: GridContainer = $MarginContainer/VBoxContainer/ItemGrid
	for child in grid.get_children():
		child.queue_free()
	_item_buttons.clear()

	for i in _items.size():
		var item := _items[i]
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d" % [symbol, item.digit]
		btn.custom_minimum_size = Vector2(80, 40)
		btn.pressed.connect(_on_item_picked.bind(i))
		grid.add_child(btn)
		_item_buttons.append(btn)


func _on_item_picked(index: int) -> void:
	GameState.add_item(_items[index])
	_go_next()


func _on_skip_pressed() -> void:
	_go_next()


func _go_next() -> void:
	if GameState.is_run_complete():
		var _summary := GameState.end_run(true)
		SceneTransition.change_scene("res://Prototyping/Screens/GameOver/GameOverScreen.tscn")
	else:
		SceneTransition.change_scene("res://Prototyping/Screens/WorldMap/WorldMap.tscn")
