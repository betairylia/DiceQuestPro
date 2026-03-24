extends Control

const WORLD_MAP_SCENE := "res://Prototyping/Screens/WorldMap/WorldMap.tscn"

@onready var _team_list: VBoxContainer = $MarginContainer/VBox/Content/Left/Scroll/TeamList
@onready var _inventory_grid: InventoryGrid = $MarginContainer/VBox/Content/Right/InventoryPanel/InventoryVBox/Scroll/InventoryGrid
@onready var _gold_value: RichTextLabel = $MarginContainer/VBox/Content/Right/StatsPanel/StatsVBox/GoldValue
@onready var _run_value: RichTextLabel = $MarginContainer/VBox/Content/Right/StatsPanel/StatsVBox/RunValue
@onready var _region_value: RichTextLabel = $MarginContainer/VBox/Content/Right/StatsPanel/StatsVBox/RegionValue


func _ready() -> void:
	if not GameState.run_active:
		SceneTransition.change_scene(WORLD_MAP_SCENE)
		return

	_refresh()


func _refresh() -> void:
	_build_team_rows()
	_inventory_grid.interactive = false
	_inventory_grid.refresh()

	var region := GameState.get_current_region()
	_gold_value.text = "金币: %d" % GameState.gold
	_region_value.text = "当前区域: %s" % (region.region_name if region != null else "未知")
	_run_value.text = "已击破节点: %d  |  收集物品: %d  |  赚取金币: %d" % [
		GameState.visited_nodes.size(),
		GameState.total_items_collected,
		GameState.total_gold_earned
	]


func _build_team_rows() -> void:
	_clear_children(_team_list)

	if GameState.team.is_empty():
		var empty := RichTextLabel.new()
		empty.fit_content = true
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.scroll_active = false
		empty.text = "队伍为空"
		_team_list.add_child(empty)
		return

	for mob in GameState.team:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 66)
		row.add_theme_stylebox_override("panel", _row_style())

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		row.add_child(hbox)

		hbox.add_child(_create_avatar(mob))

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)

		var name := RichTextLabel.new()
		name.fit_content = true
		name.scroll_active = false
		name.text = mob.resolved_display_name()
		info.add_child(name)

		var hp := RichTextLabel.new()
		hp.fit_content = true
		hp.scroll_active = false
		hp.text = "HP %d/%d" % [max(mob.current_health, 0), mob.max_health]
		info.add_child(hp)

		var dice := RichTextLabel.new()
		dice.fit_content = true
		dice.scroll_active = false
		dice.bbcode_enabled = true
		dice.text = _dice_summary(mob)
		info.add_child(dice)

		_team_list.add_child(row)


func _dice_summary(mob: MobData) -> String:
	if mob.alive_dice.is_empty():
		return "没有可用骰子"

	var dice := mob.alive_dice[0]
	var bonus := " +%d" % dice.bonus if dice.bonus > 0 else ""
	return "%s%s" % [Consts.dice_face_preview(dice), bonus]


func _create_avatar(mob: MobData) -> Control:
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(44, 44)

	var frame := TextureRect.new()
	frame.custom_minimum_size = Vector2(38, 38)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var animation_names := PackedStringArray()
	if mob.sprite != null:
		animation_names = mob.sprite.get_animation_names()
	if not animation_names.is_empty():
		frame.texture = mob.sprite.get_frame_texture(animation_names[0], 0)

	if frame.texture == null:
		var fallback := ColorRect.new()
		fallback.custom_minimum_size = Vector2(38, 38)
		fallback.color = Color(0.16, 0.16, 0.19, 1.0)
		holder.add_child(fallback)
	else:
		holder.add_child(frame)

	return holder


func _row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.09, 0.95)
	style.border_color = Color(0.30, 0.30, 0.34, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style


func _on_back_button_pressed() -> void:
	SceneTransition.change_scene(WORLD_MAP_SCENE)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
