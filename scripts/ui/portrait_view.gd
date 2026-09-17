class_name AstraPortraitView
extends Control

# Character portrait with an accent frame, expression-specific art (calm / warm / tense), name plate,
# status veil (isolated / offline) and a slow idle "breathing" motion.

var npc_id: String = ""
var _art: TextureRect

var _veil: ColorRect
var _frame: Panel
var _name: Label
var _job: Label
var _mood: Label
var _status: Label
var _time: float = 0.0
var _animating: bool = false

func _init() -> void:
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _art = TextureRect.new()
    _art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_art)
    _veil = ColorRect.new()
    _veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _veil.color = Color(0.02, 0.03, 0.06, 0.62)
    _veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _veil.visible = false
    add_child(_veil)
    var shade := ColorRect.new()
    shade.anchor_top = 0.72
    shade.anchor_bottom = 1.0
    shade.anchor_right = 1.0
    shade.color = Color(0.01, 0.02, 0.05, 0.72)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    _frame = Panel.new()
    _frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_frame)
    var plate := VBoxContainer.new()
    plate.anchor_top = 1.0
    plate.anchor_bottom = 1.0
    plate.anchor_right = 1.0
    plate.offset_left = 12.0
    plate.offset_right = -12.0
    plate.offset_top = -62.0
    plate.offset_bottom = -8.0
    plate.add_theme_constant_override("separation", 0)
    plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(plate)
    _name = AstraUI.label("", 22, AstraUI.TEXT)
    plate.add_child(_name)
    _job = AstraUI.label("", 13, AstraUI.MUTED)
    plate.add_child(_job)
    _mood = AstraUI.label("", 12, AstraUI.CYAN)
    _mood.anchor_left = 1.0
    _mood.anchor_right = 1.0
    _mood.offset_left = -120.0
    _mood.offset_right = -10.0
    _mood.offset_top = 8.0
    _mood.offset_bottom = 30.0
    _mood.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    add_child(_mood)
    _status = AstraUI.label("", 20, AstraUI.RED)
    _status.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _status.grow_vertical = Control.GROW_DIRECTION_BOTH
    add_child(_status)

func show_member(member: AstraCrewMember, animate: bool = true) -> void:
    if member == null or _art == null:
        return
    var changed := member.id != npc_id
    npc_id = member.id

    _art.texture = AstraUI.texture(AstraCrewCatalog.portrait_path(member.id, member.expression))
    _frame.add_theme_stylebox_override("panel", _frame_style(member.accent))
    _name.text = member.display_name
    _name.add_theme_color_override("font_color", member.accent)
    _job.text = "%s · %s" % [member.job, str(member.info.get("concept", ""))]
    _mood.text = member.mood_label()
    _mood.add_theme_color_override("font_color", _mood_color(member.expression))
    var alive := member.is_alive()
    _veil.visible = not alive
    _art.modulate = Color(1, 1, 1, 1) if alive else Color(0.55, 0.58, 0.65, 1)
    _status.visible = not alive
    _status.text = "격리됨" if member.status == AstraCrewMember.STATUS_ISOLATED else "신호 끊김"
    _status.add_theme_color_override("font_color", AstraUI.GOLD if member.status == AstraCrewMember.STATUS_ISOLATED else AstraUI.RED)
    if animate and changed and is_inside_tree():
        _animating = true
        _art.pivot_offset = size * 0.5
        _art.scale = Vector2(1.06, 1.06)
        _art.modulate.a = 0.0
        var tween := create_tween()
        tween.set_parallel(true)
        tween.tween_property(_art, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(_art, "modulate:a", 1.0, 0.22)
        tween.chain().tween_callback(func(): _animating = false)

func pulse() -> void:
    if _art == null or not is_inside_tree():
        return
    _animating = true
    _art.pivot_offset = size * 0.5
    var tween := create_tween()
    tween.tween_property(_art, "scale", Vector2(1.025, 1.025), 0.08)
    tween.tween_property(_art, "scale", Vector2.ONE, 0.2)
    tween.tween_callback(func(): _animating = false)

func _process(delta: float) -> void:
    if _art == null or _animating or not is_visible_in_tree():
        return
    _time += delta
    _art.pivot_offset = Vector2(size.x * 0.5, size.y * 0.9)
    var breath := 1.0 + sin(_time * 1.6) * 0.006
    _art.scale = Vector2(breath, breath)

func _frame_style(accent: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0, 0, 0, 0)
    box.border_color = Color(accent, 0.85)
    box.set_border_width_all(2)
    box.set_corner_radius_all(12)
    return box

func _mood_color(expression: String) -> Color:
    match expression:
        "warm": return AstraUI.GREEN
        "tense": return AstraUI.RED
        "uneasy": return AstraUI.GOLD
    return AstraUI.CYAN

func _ready() -> void:
    if npc_id != "" and _art != null:
        _art.modulate.a = 0.0
        var tween := create_tween()
        tween.tween_property(_art, "modulate:a", 1.0, 0.25)
