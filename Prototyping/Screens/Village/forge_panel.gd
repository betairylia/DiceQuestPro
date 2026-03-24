extends Control

var _selected_player: MobData
var _selected_item: DiceFaceItem


func _ready() -> void:
	pass


func refresh() -> void:
	_selected_item = null
	_build_player_selector()
	if not _selected_player and not GameState.team.is_empty():
		_selected_player = GameState.team[0]
	_update_dice_display()
	_update_upgrade_button()
	_update_inventory_list()
	_update_gold_label()


func _update_gold_label() -> void:
	$GoldLabel.text = "金币: %d" % GameState.gold


func _build_player_selector() -> void:
	var container: HBoxContainer = $PlayerSelector
	for child in container.get_children():
		child.queue_free()

	for mob_data in GameState.team:
		var btn := Button.new()
		btn.text = mob_data.display_name if mob_data.display_name != "" else "???"
		btn.pressed.connect(_on_player_selected.bind(mob_data))
		if mob_data == _selected_player:
			btn.modulate = Color(0.7, 1.0, 0.7)
		container.add_child(btn)


func _on_player_selected(mob_data: MobData) -> void:
	_selected_player = mob_data
	_selected_item = null
	refresh()


func _update_dice_display() -> void:
	var container: GridContainer = $DiceFaces
	for child in container.get_children():
		child.queue_free()

	if not _selected_player or _selected_player.alive_dice.is_empty():
		return

	var dice: DiceData = _selected_player.alive_dice[0]
	for face_idx in dice.face_count():
		var btn := Button.new()
		var element: Consts.Elements = Consts.Elements.Idle
		if face_idx < dice.elements.size():
			element = dice.elements[face_idx]
		var symbol: String = Consts.SYMBOLS.get(element, "?")
		btn.text = "%s %d" % [symbol, face_idx + 1]
		btn.custom_minimum_size = Vector2(50, 30)

		# Highlight valid reforge targets
		if _selected_item and _selected_item.digit == face_idx + 1:
			btn.modulate = Color(1.0, 1.0, 0.5)
			btn.pressed.connect(_on_face_clicked.bind(face_idx))
		else:
			btn.disabled = _selected_item != null

		container.add_child(btn)


func _update_upgrade_button() -> void:
	var btn: Button = $UpgradeButton
	if not _selected_player:
		btn.disabled = true
		btn.text = "强化"
		return
	var cost := GameState.get_upgrade_cost(_selected_player)
	btn.text = "强化 (%d金)" % cost
	btn.disabled = GameState.gold < cost


func _update_inventory_list() -> void:
	var container: VBoxContainer = $ReforgeItems
	for child in container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "重铸 (选择物品, 费用: %d金)" % GameState.REFORGE_COST
	container.add_child(header)

	for item in GameState.inventory:
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d" % [symbol, item.digit]
		btn.disabled = GameState.gold < GameState.REFORGE_COST
		if item == _selected_item:
			btn.modulate = Color(1.0, 1.0, 0.5)
		btn.pressed.connect(_on_item_selected.bind(item))
		container.add_child(btn)


func _on_item_selected(item: DiceFaceItem) -> void:
	if _selected_item == item:
		_selected_item = null  # Deselect
	else:
		_selected_item = item
	_update_dice_display()
	_update_inventory_list()


func _on_face_clicked(face_index: int) -> void:
	if not _selected_item or not _selected_player:
		return
	GameState.apply_reforge(_selected_player, face_index, _selected_item)
	_selected_item = null
	refresh()


func _on_upgrade_button_pressed() -> void:
	if not _selected_player:
		return
	GameState.apply_upgrade(_selected_player)
	refresh()
