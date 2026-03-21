@tool
extends EditorPlugin

var _button: Button


func _enter_tree() -> void:
	_button = Button.new()
	_button.text = "Sync Spells"
	_button.pressed.connect(_on_sync_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, _button)


func _exit_tree() -> void:
	if _button:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()
		_button = null


func _on_sync_pressed() -> void:
	var loader := SpellCsvLoader.new()
	var count := loader.sync_spells()
	print("[SpellImporter] Synced %d spell(s)." % count)
	# Refresh the filesystem so the editor picks up new/changed .tres files
	EditorInterface.get_resource_filesystem().scan()
