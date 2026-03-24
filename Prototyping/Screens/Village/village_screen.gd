extends Control

@onready var _shop_panel: Control = $Panels/ShopPanel
@onready var _forge_panel: Control = $Panels/ForgePanel


func _ready() -> void:
	_show_shop()


func _on_shop_button_pressed() -> void:
	_show_shop()


func _on_forge_button_pressed() -> void:
	_show_forge()


func _on_leave_button_pressed() -> void:
	SceneTransition.change_scene("res://Prototyping/Screens/WorldMap/WorldMap.tscn")


func _show_shop() -> void:
	_shop_panel.visible = true
	_forge_panel.visible = false
	_shop_panel.refresh()


func _show_forge() -> void:
	_shop_panel.visible = false
	_forge_panel.visible = true
	_forge_panel.refresh()
