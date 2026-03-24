extends Control

const MAX_TEAM_SIZE := 3

var _available: Array[MobData] = []
var _selected: Array[MobData] = []


func _ready() -> void:
	_load_characters()
	_build_grid()
	_update_depart_button()


func _load_characters() -> void:
	var dir := DirAccess.open("res://Prototyping/Data/Players/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var mob = load("res://Prototyping/Data/Players/" + file_name)
			if mob is MobData:
				_available.append(mob)
		file_name = dir.get_next()


func _build_grid() -> void:
	var grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/Grid
	for child in grid.get_children():
		child.queue_free()

	for mob_data in _available:
		var card := _create_card(mob_data)
		grid.add_child(card)


func _create_card(mob_data: MobData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 80)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var name_label := Label.new()
	var display := mob_data.display_name if mob_data.display_name != "" else "???"
	name_label.text = display
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var hp_label := Label.new()
	hp_label.text = "HP: %d" % mob_data.max_health
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hp_label)

	var dice_label := RichTextLabel.new()
	dice_label.bbcode_enabled = true
	dice_label.fit_content = true
	dice_label.scroll_active = false
	if not mob_data.alive_dice.is_empty():
		dice_label.text = Consts.dice_face_preview(mob_data.alive_dice[0])
	vbox.add_child(dice_label)

	panel.gui_input.connect(_on_card_input.bind(mob_data, panel))
	return panel


func _on_card_input(event: InputEvent, mob_data: MobData, panel: PanelContainer) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mob_data in _selected:
			_selected.erase(mob_data)
			_style_card(panel, false)
		elif _selected.size() < MAX_TEAM_SIZE:
			_selected.append(mob_data)
			_style_card(panel, true)
		_update_depart_button()
		_update_team_preview()


func _style_card(panel: PanelContainer, selected: bool) -> void:
	if selected:
		panel.modulate = Color(0.7, 1.0, 0.7)
	else:
		panel.modulate = Color.WHITE


func _update_depart_button() -> void:
	var btn: Button = $MarginContainer/VBoxContainer/DepartButton
	btn.disabled = _selected.is_empty()
	btn.text = "出发 (%d/%d)" % [_selected.size(), MAX_TEAM_SIZE]


func _update_team_preview() -> void:
	var preview: HBoxContainer = $MarginContainer/VBoxContainer/TeamPreview
	for child in preview.get_children():
		child.queue_free()
	for mob_data in _selected:
		var label := Label.new()
		label.text = mob_data.display_name if mob_data.display_name != "" else "???"
		preview.add_child(label)


func _on_depart_button_pressed() -> void:
	if _selected.is_empty():
		return
	GameState.start_run(_selected)
	SceneTransition.change_scene("res://Prototyping/Screens/WorldMap/WorldMap.tscn")
