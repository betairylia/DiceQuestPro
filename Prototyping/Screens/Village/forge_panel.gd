extends VBoxContainer

@onready var _gold_label: RichTextLabel = $GoldLabel
@onready var _players_row: HBoxContainer = $PlayersRow
@onready var _bonus_label: RichTextLabel = $BonusLabel
@onready var _upgrade_button: Button = $UpgradeButton
@onready var _selected_item_label: RichTextLabel = $SelectedItemLabel
@onready var _face_grid: GridContainer = $FaceGrid
@onready var _inventory_grid: GridContainer = $InventoryGrid
@onready var _reforge_button: Button = $ReforgeButton

var _selected_player_index: int = 0
var _selected_item: DiceFaceItem
var _selected_face_index: int = -1


func _ready() -> void:
	refresh()


func refresh() -> void:
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.text = "金币 %d" % GameState.gold

	if GameState.team.is_empty():
		_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_bonus_label.text = "没有角色"
		_upgrade_button.disabled = true
		_reforge_button.disabled = true
		return

	_selected_player_index = clampi(_selected_player_index, 0, GameState.team.size() - 1)
	var player := GameState.team[_selected_player_index]

	if _selected_item != null and (_selected_item not in GameState.inventory):
		_selected_item = null
		_selected_face_index = -1

	_build_player_buttons()
	_build_face_grid(player)
	_build_inventory_grid(player)

	var upgrade_cost := GameState.get_upgrade_cost(player)
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bonus_label.text = "%s  强化 +%d" % [player.resolved_display_name(), player.alive_dice[0].bonus]
	_upgrade_button.text = "强化 (%d金)" % upgrade_cost
	_upgrade_button.disabled = GameState.gold < upgrade_cost

	if _selected_item == null:
		_selected_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_selected_item_label.text = "选择一个骰面进行重铸"
	else:
		_selected_item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_selected_item_label.text = "已选 %s %d" % [Consts.SYMBOLS.get(_selected_item.element, "?"), _selected_item.digit]

	_reforge_button.disabled = _selected_item == null or _selected_face_index < 0 or GameState.gold < GameState.REFORGE_COST


func _build_player_buttons() -> void:
	_clear_children(_players_row)

	for idx in GameState.team.size():
		var player := GameState.team[idx]
		var button := Button.new()
		button.theme = preload("res://Prototyping/HUD/pixelated.tres")
		button.text = "%s\nHP %d/%d" % [player.resolved_display_name(), max(player.current_health, 0), player.max_health]
		button.modulate = Color(1.0, 0.9, 0.6) if idx == _selected_player_index else Color.WHITE
		button.pressed.connect(_on_player_pressed.bind(idx))
		_players_row.add_child(button)


func _build_face_grid(player: MobData) -> void:
	_clear_children(_face_grid)

	if player.alive_dice.is_empty():
		return

	for face_idx in player.alive_dice[0].elements.size():
		var button := Button.new()
		button.theme = preload("res://Prototyping/HUD/pixelated.tres")
		button.text = "%s %d" % [
			Consts.SYMBOLS.get(player.alive_dice[0].elements[face_idx], "?"),
			player.alive_dice[0].get_digit(face_idx)
		]
		var valid_reforge := _selected_item != null and _selected_item.digit == face_idx + 1
		button.disabled = _selected_item != null and not valid_reforge
		button.modulate = Color(1.0, 0.86, 0.45) if face_idx == _selected_face_index else Color.WHITE
		button.pressed.connect(_on_face_pressed.bind(face_idx))
		_face_grid.add_child(button)


func _build_inventory_grid(player: MobData) -> void:
	_clear_children(_inventory_grid)

	var dice_items: Array[DiceFaceItem] = []
	for item in GameState.inventory:
		if item is DiceFaceItem:
			dice_items.append(item)

	if dice_items.is_empty():
		var empty_label := RichTextLabel.new()
		empty_label.fit_content = true
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.text = "没有可用骰面"
		_inventory_grid.add_child(empty_label)
		return

	var max_faces := player.alive_dice[0].face_count()
	for item in dice_items:
		var button := Button.new()
		button.theme = preload("res://Prototyping/HUD/pixelated.tres")
		button.text = "%s %d" % [Consts.SYMBOLS.get(item.element, "?"), item.digit]
		button.disabled = item.digit > max_faces
		button.modulate = Color(1.0, 0.86, 0.45) if item == _selected_item else Color.WHITE
		button.pressed.connect(_on_inventory_item_pressed.bind(item))
		_inventory_grid.add_child(button)


func _on_player_pressed(index: int) -> void:
	_selected_player_index = index
	_selected_face_index = -1
	refresh()


func _on_face_pressed(face_index: int) -> void:
	if _selected_item == null or _selected_item.digit != face_index + 1:
		return
	_selected_face_index = face_index
	refresh()


func _on_inventory_item_pressed(item: DiceFaceItem) -> void:
	_selected_item = item
	_selected_face_index = item.digit - 1 if not GameState.team.is_empty() and item.digit <= GameState.team[_selected_player_index].alive_dice[0].face_count() else -1
	refresh()


func _on_upgrade_button_pressed() -> void:
	GameState.apply_upgrade(GameState.team[_selected_player_index])
	refresh()


func _on_reforge_button_pressed() -> void:
	if _selected_item == null or _selected_face_index < 0:
		return
	GameState.apply_reforge(GameState.team[_selected_player_index], _selected_face_index, _selected_item)
	_selected_item = null
	_selected_face_index = -1
	refresh()


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
