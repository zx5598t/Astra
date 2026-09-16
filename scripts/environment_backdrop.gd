class_name AstraEnvironmentBackdrop
extends TextureRect

func set_case(case_id: String) -> void:
    var path := "res://assets/environments/dead_air.svg"
    if case_id == "GLASS_GARDEN":
        path = "res://assets/environments/glass_garden.svg"
    texture = load(path)
    expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    modulate = Color(1, 1, 1, 0.42)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
