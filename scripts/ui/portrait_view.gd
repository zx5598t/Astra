class_name AstraPortraitView
extends Control

# Character portrait: transparent half-body cast art over the scene backdrop,
# an accent frame, name plate and a status veil (isolated / offline).
#
# 0.4.0: the idle "breathing" scale loop and the per-answer scale pulse were
# removed. A portrait that never stops moving pulls the eye away from the text
# the player is trying to read, and it made every answer look equally dramatic.
# The only motion left is a single cross-fade when the displayed person changes,
# which carries real information ("you are now looking at someone else").

const FADE_TIME := 0.18

var npc_id: String = ""
var _art: TextureRect
var _veil: ColorRect
var _frame: Panel
var _name: Label
var _job: Label
var _mood: Label
var _status: Label
var _accent_bar: ColorRect

func _init() -> void:
    clip_contents = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    var backdrop := AstraUI.thumb(AstraArt.background("lounge"), Vector2.ZERO)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.modulate = Color(0.34, 0.39, 0.47)
    add_child(backdrop)
    add_child(AstraArt.shade())
    _art = TextureRect.new()
    _art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _art.material = AstraUI.defringe_material()
    # FIT, not COVER. The cast art is 3:4 and the stage is wider than it is
    # tall, so covering cropped the head and the hands off — the two parts of a
    # half-body portrait worth showing. Fitting leaves margin instead.
    _art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    _art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_art)
    _veil = ColorRect.new()
    _veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _veil.color = Color(0.02, 0.03, 0.06, 0.62)
    _veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _veil.visible = false
    add_child(_veil)
    var shade := ColorRect.new()
    shade.anchor_top = 0.70
    shade.anchor_bottom = 1.0
    shade.anchor_right = 1.0
    shade.color = Color(0.01, 0.02, 0.05, 0.80)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)
    _frame = Panel.new()
    _frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_frame)
    _accent_bar = ColorRect.new()
    _accent_bar.anchor_top = 1.0
    _accent_bar.anchor_bottom = 1.0
    _accent_bar.anchor_right = 1.0
    _accent_bar.offset_top = -70.0
    _accent_bar.offset_bottom = -67.0
    _accent_bar.offset_left = 12.0
    _accent_bar.offset_right = -12.0
    _accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_accent_bar)
    var plate := VBoxContainer.new()
    plate.anchor_top = 1.0
    plate.anchor_bottom = 1.0
    plate.anchor_right = 1.0
    plate.offset_left = 12.0
    plate.offset_right = -12.0
    plate.offset_top = -60.0
    plate.offset_bottom = -8.0
    plate.add_theme_constant_override("separation", 0)
    plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(plate)
    _name = AstraUI.label("", 24, AstraUI.TEXT)
    plate.add_child(_name)
    _job = AstraUI.label("", 14, AstraUI.MUTED)
    plate.add_child(_job)
    _mood = AstraUI.label("", 13, AstraUI.CYAN)
    _mood.anchor_left = 1.0
    _mood.anchor_right = 1.0
    _mood.offset_left = -150.0
    _mood.offset_right = -12.0
    _mood.offset_top = 10.0
    _mood.offset_bottom = 34.0
    _mood.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    add_child(_mood)
    _status = AstraUI.label("", 22, AstraUI.RED)
    _status.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    _status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _status.grow_horizontal = Control.GROW_DIRECTION_BOTH
    _status.grow_vertical = Control.GROW_DIRECTION_BOTH
    add_child(_status)

func show_member(member: AstraCrewMember, animate: bool = true) -> void:
    if member == null or _art == null:
        return
    var switched := member.id != npc_id
    npc_id = member.id
    _art.texture = AstraUI.texture(AstraCrewCatalog.cast_path(member.id, member.expression))
    _frame.add_theme_stylebox_override("panel", _frame_style(Color(member.accent, 0.55)))
    _accent_bar.color = Color(member.accent, 0.85)
    _name.text = member.display_name
    _name.add_theme_color_override("font_color", member.accent)
    _job.text = member.job
    _mood.text = member.mood_label()
    _mood.add_theme_color_override("font_color", _mood_color(member.expression))
    var alive := member.is_alive()
    _veil.visible = not alive
    _art.modulate = Color(1, 1, 1, 1) if alive else Color(0.55, 0.58, 0.65, 1)
    _status.visible = not alive
    _status.text = "격리됨" if member.status == AstraCrewMember.STATUS_ISOLATED else "신호 끊김"
    _status.add_theme_color_override("font_color", AstraUI.GOLD if member.status == AstraCrewMember.STATUS_ISOLATED else AstraUI.RED)
    # Scale is never touched any more; only opacity, and only on a real switch.
    _art.scale = Vector2.ONE
    if animate and switched and is_inside_tree() and not AstraUI.reduce_motion:
        _art.modulate.a = 0.0
        var tween := create_tween()
        tween.tween_property(_art, "modulate:a", 1.0 if alive else 1.0, FADE_TIME)

# Kept for call-site compatibility. 0.4.0 deliberately does nothing here:
# a bouncing portrait after every answer was noise, not feedback.
func pulse() -> void:
    pass

func _frame_style(accent: Color) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0, 0, 0, 0)
    box.border_color = accent
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
    if npc_id != "" and _art != null and not AstraUI.reduce_motion:
        _art.modulate.a = 0.0
        var tween := create_tween()
        tween.tween_property(_art, "modulate:a", 1.0, FADE_TIME)
