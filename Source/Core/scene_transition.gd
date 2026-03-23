extends CanvasLayer

const FADE_DURATION := 0.3

@onready var _overlay: ColorRect = $Overlay

var _transitioning: bool = false


func change_scene(path: String) -> void:
	if _transitioning:
		return

	var next_scene := load(path) as PackedScene
	if next_scene == null:
		return

	_transitioning = true

	var fade_out := create_tween()
	fade_out.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	await fade_out.finished

	get_tree().change_scene_to_packed(next_scene)
	await get_tree().process_frame

	var fade_in := create_tween()
	fade_in.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
	await fade_in.finished

	_transitioning = false
