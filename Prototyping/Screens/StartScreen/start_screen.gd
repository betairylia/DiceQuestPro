extends Control

const MAX_TEAM_SIZE := 3
const WORLD_MAP_SCENE := "res://Prototyping/Screens/WorldMap/WorldMap.tscn"

@onready var _grid: GridContainer = $MarginContainer/VBox/Scroll/Grid
@onready var _selected_label: RichTextLabel = $MarginContainer/VBox/SelectedLabel
@onready var _status_label: RichTextLabel = $MarginContainer/VBox/StatusLabel
@onready var _depart_button: Button = $MarginContainer/VBox/DepartButton

var _available: Array[MobData] = []
var _selected: Array[MobData] = []
var _cards: Dictionary = {}


func _ready() -> void:
	_load_characters()
	_build_grid()
	_update_selection_ui()


func _load_characters() -> void:
	_available.clear()

	var files: Array[String] = []
	var dir := DirAccess.open("res://Prototyping/Data/Players")
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".tres"):
			files.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()

	files.sort()
	for file_name in files:
		var mob := load("res://Prototyping/Data/Players/%s" % file_name)
		if mob is MobData:
			_available.append(mob)


func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_cards.clear()

	for mob_data in _available:
		var card := _create_card(mob_data)
		_grid.add_child(card)
		_cards[mob_data.resource_path] = card


func _create_card(mob_data: MobData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(170, 110)
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.add_theme_stylebox_override("panel", _make_card_style(false))

	var body := VBoxContainer.new()
	panel.add_child(body)

	var name_label := RichTextLabel.new()
	name_label.bbcode_enabled = true
	name_label.fit_content = true
	name_label.scroll_active = false
	name_label.text = "[center]%s[/center]" % mob_data.resolved_display_name()
	body.add_child(name_label)

	var hp_label := RichTextLabel.new()
	hp_label.fit_content = true
	hp_label.scroll_active = false
	hp_label.text = "[center]HP %d[/center]" % mob_data.max_health
	body.add_child(hp_label)

	var dice_label := RichTextLabel.new()
	dice_label.bbcode_enabled = true
	dice_label.fit_content = true
	dice_label.scroll_active = false
	if not mob_data.alive_dice.is_empty():
		dice_label.text = "[center]%s[/center]" % Consts.dice_face_preview(mob_data.alive_dice[0])
	body.add_child(dice_label)

	panel.gui_input.connect(_on_card_input.bind(mob_data))
	return panel


func _make_card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.10, 0.12, 0.96) if selected else Color(0.05, 0.05, 0.06, 0.90)
	style.border_color = Color(0.92, 0.82, 0.40) if selected else Color(0.35, 0.35, 0.40)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _on_card_input(event: InputEvent, mob_data: MobData) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return

	if mob_data in _selected:
		_selected.erase(mob_data)
	elif _selected.size() < MAX_TEAM_SIZE:
		_selected.append(mob_data)
	else:
		_status_label.text = "[center]队伍已满[/center]"
		return

	_status_label.text = "[center]选择 1-3 名角色出发[/center]"
	_update_selection_ui()


func _update_selection_ui() -> void:
	for mob_data in _available:
		var panel: PanelContainer = _cards.get(mob_data.resource_path)
		if panel != null:
			panel.add_theme_stylebox_override("panel", _make_card_style(mob_data in _selected))

	if _selected.is_empty():
		_selected_label.text = "[center]尚未选择角色[/center]"
	else:
		var names: Array[String] = []
		for mob_data in _selected:
			names.append(mob_data.resolved_display_name())
		_selected_label.text = "[center]%s[/center]" % "  |  ".join(names)

	_depart_button.disabled = _selected.is_empty()


func _on_depart_button_pressed() -> void:
	GameState.start_run(_selected)
	SceneTransition.change_scene(WORLD_MAP_SCENE)
