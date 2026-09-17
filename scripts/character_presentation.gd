class_name AstraCharacterPresentation
extends Control

var portrait_target: TextureRect
var frame: Panel
var name_label: Label
var job_label: Label
var expression_label: Label
var cue_label: Label
var _last_name: String = ""

func attach(target: TextureRect) -> void:
    portrait_target = target
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build_overlay()

func _build_overlay() -> void:
    frame = Panel.new()
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(frame)

    expression_label = Label.new()
    expression_label.anchor_left = 1.0
    expression_label.anchor_right = 1.0
    expression_label.offset_left = -92.0
    expression_label.offset_right = -8.0
    expression_label.offset_top = 8.0
    expression_label.offset_bottom = 34.0
    expression_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    expression_label.add_theme_font_size_override("font_size", 11)
    add_child(expression_label)

    var plate := VBoxContainer.new()
    plate.anchor_left = 0.0
    plate.anchor_right = 1.0
    plate.anchor_top = 1.0
    plate.anchor_bottom = 1.0
    plate.offset_left = 10.0
    plate.offset_right = -10.0
    plate.offset_top = -70.0
    plate.offset_bottom = -8.0
    plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(plate)

    name_label = Label.new()
    name_label.add_theme_font_size_override("font_size", 18)
    plate.add_child(name_label)

    job_label = Label.new()
    job_label.add_theme_font_size_override("font_size", 11)
    job_label.add_theme_color_override("font_color", Color("aebbd0"))
    plate.add_child(job_label)

    cue_label = Label.new()
    cue_label.visible = false
    cue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    cue_label.add_theme_font_size_override("font_size", 11)
    cue_label.add_theme_color_override("font_color", Color("f6fbff"))
    plate.add_child(cue_label)

func present(npc_name: String, job: String, accent: Color, expression: String, animate: bool = true) -> void:
    if frame == null:
        return
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.02, 0.04, 0.08, 0.10)
    style.border_color = Color(accent.r, accent.g, accent.b, 0.82)
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    frame.add_theme_stylebox_override("panel", style)

    name_label.text = npc_name.to_upper()
    name_label.add_theme_color_override("font_color", accent)
    job_label.text = job
    expression_label.text = expression.to_upper()
    expression_label.add_theme_color_override("font_color", _expression_color(expression, accent))

    var changed := npc_name != _last_name
    _last_name = npc_name
    if animate and changed:
        animate_in(accent)
    else:
        pulse(expression)

func animate_in(accent: Color) -> void:
    if portrait_target == null or not is_instance_valid(portrait_target):
        return
    portrait_target.pivot_offset = portrait_target.size * 0.5
    portrait_target.scale = Vector2(0.94, 0.94)
    portrait_target.modulate = Color(accent.r, accent.g, accent.b, 0.18)
    var tween := portrait_target.create_tween()
    tween.set_parallel(true)
    tween.tween_property(portrait_target, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(portrait_target, "modulate", Color.WHITE, 0.18)

func pulse(expression: String = "calm") -> void:
    if portrait_target == null or not is_instance_valid(portrait_target):
        return
    portrait_target.pivot_offset = portrait_target.size * 0.5
    var target_scale := Vector2(1.018, 1.018) if expression in ["tense", "angry", "afraid", "guarded"] else Vector2(1.01, 1.01)
    var tween := portrait_target.create_tween()
    tween.tween_property(portrait_target, "scale", target_scale, 0.07)
    tween.tween_property(portrait_target, "scale", Vector2.ONE, 0.16)

func cue(tag: String, accent: Color) -> void:
    if cue_label == null:
        return
    cue_label.visible = true
    cue_label.text = "▸ " + tag
    cue_label.add_theme_color_override("font_color", accent)
    cue_label.modulate.a = 0.0
    var tween := cue_label.create_tween()
    tween.tween_property(cue_label, "modulate:a", 1.0, 0.08)
    tween.tween_interval(0.65)
    tween.tween_property(cue_label, "modulate:a", 0.0, 0.22)
    tween.tween_callback(func(): cue_label.visible = false)

func _expression_color(expression: String, accent: Color) -> Color:
    match expression.to_lower():
        "warm": return Color("5ee3a0")
        "tense", "angry", "afraid", "guarded", "cold", "uneasy": return Color("ff8b96")
        _:
            return accent
