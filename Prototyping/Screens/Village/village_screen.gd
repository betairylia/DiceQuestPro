extends Control

const WORLD_MAP_SCENE := "res://Prototyping/Screens/WorldMap/WorldMap.tscn"

@onready var _region_label: RichTextLabel = $MarginContainer/VBox/Header/RegionLabel
@onready var _gold_label: RichTextLabel = $MarginContainer/VBox/Header/GoldLabel
@onready var _shop_panel: VBoxContainer = $MarginContainer/VBox/Tabs/Shop
@onready var _forge_panel: VBoxContainer = $MarginContainer/VBox/Tabs/Forge


func _ready() -> void:
	if not GameState.run_active or GameState.get_current_node() == null:
		SceneTransition.change_scene(WORLD_MAP_SCENE)
		return

	GameState.heal_team()
	_update_header()
	if _shop_panel.has_method("refresh"):
		_shop_panel.call("refresh")
	if _forge_panel.has_method("refresh"):
		_forge_panel.call("refresh")


func _process(_delta: float) -> void:
	_update_header()


func _update_header() -> void:
	var region := GameState.get_current_region()
	_region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_region_label.text = "%s 村庄" % (region.region_name if region != null else "村庄")
	_gold_label.text = "金币 %d" % GameState.gold


func _on_tabs_tab_changed(_tab: int) -> void:
	if _shop_panel.has_method("refresh"):
		_shop_panel.call("refresh")
	if _forge_panel.has_method("refresh"):
		_forge_panel.call("refresh")


func _on_leave_button_pressed() -> void:
	var node := GameState.get_current_node()
	if node != null:
		GameState.complete_node(node.id)
	SceneTransition.change_scene(WORLD_MAP_SCENE)
