extends CanvasLayer

## Fade transition overlay for scene changes.
const FADE_DURATION := 0.3

@onready var _overlay: ColorRect = $Overlay
var _transitioning := false


func _ready() -> void:
	# Ensure overlay starts transparent
	_overlay.color = Color(0, 0, 0, 0)
	layer = 100


func change_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true

	# Fade to black
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	# Swap scene
	get_tree().change_scene_to_file(path)

	# Wait one frame for new scene to initialize
	await get_tree().process_frame

	# Fade in
	var tween2 := create_tween()
	tween2.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
	await tween2.finished

	_transitioning = false