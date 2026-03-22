extends Label


@export var acc: Vector2 = Vector2(0, 600)
@export var fade_start: float = 0.6
@export var fade_end: float = 0.75
var velocity: Vector2 = Vector2(0, 0)
var lifespan: float = 0
var base_color: Color = Color.WHITE

const BASE_SPEED_Y := -200.0
const BASE_SPEED_X := 80.0
const RANDOM_X := 40.0

const COLOR_DAMAGE := Color(1, 0.3, 0.3, 1)
const COLOR_HEAL := Color(0.5, 1, 0.3, 1)


func setup(s: String, direction: float, color: Color) -> void:
	text = s
	var random_x := randf_range(-RANDOM_X, RANDOM_X)
	velocity = Vector2(direction * BASE_SPEED_X + random_x, BASE_SPEED_Y)
	base_color = color
	add_theme_color_override("font_color", base_color)


func _ready() -> void:
	lifespan = 0


func _process(delta: float) -> void:
	velocity += acc * delta
	set_position(position + velocity * delta)

	lifespan += delta
	if lifespan >= fade_start:
		var alpha: float = clamp((fade_end - lifespan) / (fade_end - fade_start), 0.0, 1.0)
		add_theme_color_override("font_color", Color(base_color.r, base_color.g, base_color.b, alpha))
	if lifespan >= fade_end:
		queue_free()
