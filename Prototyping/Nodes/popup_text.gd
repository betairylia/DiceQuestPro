extends Label


@export var acc: Vector2 = Vector2(0, 600)
@export var fade_start: float = 0.6
@export var fade_end: float = 0.75
var velocity: Vector2 = Vector2(0, 0)
var lifespan: float = 0

const LEFT: Vector2 = Vector2(-80, -200)
const RIGHT: Vector2 = Vector2(80, -200)

func setup(s: String, v: Vector2) -> void:
	text = s
	velocity = v


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# velocity = Vector2(80, -200)
	lifespan = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity += acc * delta
	set_position(position + velocity * delta)

	lifespan += delta
	if lifespan >= fade_start:
		add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, clamp((fade_end - lifespan) / (fade_end - fade_start), 0.0, 1.0)))
	if lifespan >= fade_end:
		queue_free()
