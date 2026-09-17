class_name Starfield
extends Control

var stars: Array[Dictionary] = []
var drift: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var rng := RandomNumberGenerator.new()
    rng.seed = 424242
    for i in range(95):
        stars.append({
            "x": rng.randf(),
            "y": rng.randf(),
            "r": rng.randf_range(0.6, 2.0),
            "a": rng.randf_range(0.22, 0.82)
        })
    set_process(true)
    queue_redraw()

func _process(delta: float) -> void:
    drift += delta * 3.0
    if drift > 1000.0:
        drift = 0.0
    queue_redraw()

func _draw() -> void:
    var s := size
    for star in stars:
        var y := fmod(float(star["y"]) * s.y + drift, maxf(s.y, 1.0))
        var pos := Vector2(float(star["x"]) * s.x, y)
        draw_circle(pos, float(star["r"]), Color(0.68, 0.82, 1.0, float(star["a"])))
    draw_circle(Vector2(s.x * 0.82, s.y * 0.17), 120.0, Color(0.12, 0.27, 0.48, 0.11))
    draw_circle(Vector2(s.x * 0.16, s.y * 0.78), 170.0, Color(0.22, 0.10, 0.38, 0.08))
