class_name AstraVNStage
extends Control

# One beat of a scene, drawn the same way everywhere: the Stage art behind, the
# speaker large enough to read their face, one dialogue box in a fixed place,
# and choices (if any) right above it. Used by the opening, every morning, the
# isolation aftermath and the Stage result. The owner feeds beats and listens
# for `advanced` / `chose`; this node never touches the session.

signal advanced
signal chose(index: int)

const TYPE_SPEED := 55.0 # characters per second

var _bg: TextureRect
var _tint: ColorRect
var _portrait: TextureRect
var _box: PanelContainer
var _name_row: HBoxContainer
var _name: Label
var _job: Label
var _action: Label
var _text: Label
var _more: Label
var _choices: VBoxContainer
var _intro: PanelContainer
var _intro_name: Label
var _intro_job: Label
var _intro_line: Label
var _caption: Label
var _typing: Tween
var _has_choices: bool = false
var _speaker: String = ""
var _art_path: String = ""

func _init() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    clip_contents = true
    _bg = TextureRect.new()
    _bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_bg)
    _tint = ColorRect.new()
    _tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _tint.color = Color(0.01, 0.02, 0.05, 0.45)
    _tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_tint)
    add_child(AstraArt.shade())
    _portrait = TextureRect.new()
    _portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
    _portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _portrait.material = AstraUI.defringe_material()
    add_child(_portrait)

    _intro = AstraUI.reading_panel(AstraUI.VIOLET, 0.9)
    _intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var intro_box := AstraUI.vbox(2)
    _intro.add_child(intro_box)
    var intro_tag := AstraUI.label("새로 깨어난 승무원", AstraUI.T_META, AstraUI.VIOLET)
    intro_box.add_child(intro_tag)
    _intro_name = AstraUI.label("", AstraUI.T_TITLE, AstraUI.TEXT)
    intro_box.add_child(_intro_name)
    _intro_job = AstraUI.label("", AstraUI.T_UI, AstraUI.MUTED)
    intro_box.add_child(_intro_job)
    _intro_line = AstraUI.prose("", AstraUI.T_META, AstraUI.TEXT)
    _intro_line.custom_minimum_size.x = 300
    intro_box.add_child(_intro_line)
    _intro.visible = false
    add_child(_intro)

    _caption = AstraUI.label("", AstraUI.T_META, AstraUI.MUTED)
    _caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_caption)

    _choices = AstraUI.vbox(8)
    _choices.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(_choices)

    _box = AstraUI.reading_panel(AstraUI.CYAN, 0.93)
    _box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_box)
    var inner := AstraUI.vbox(6)
    inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _box.add_child(inner)
    _name_row = AstraUI.hbox(10)
    inner.add_child(_name_row)
    _name = AstraUI.label("", AstraUI.T_HEAD, AstraUI.CYAN)
    _name_row.add_child(_name)
    _job = AstraUI.label("", AstraUI.T_META, AstraUI.MUTED)
    _name_row.add_child(_job)
    _action = AstraUI.prose("", AstraUI.T_META, AstraUI.MUTED)
    inner.add_child(_action)
    _text = AstraUI.prose("", AstraUI.T_BODY + 1, AstraUI.TEXT)
    inner.add_child(_text)
    _more = AstraUI.label("▸", AstraUI.T_UI, AstraUI.CYAN)
    _more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    inner.add_child(_more)
    resized.connect(_layout)

func _ready() -> void:
    _layout()

# beat: {art, dark, speaker, expression, action, text, choices[], intro, caption}
func show_beat(beat: Dictionary) -> void:
    var art := str(beat.get("art", ""))
    if art != "" and art != _art_path:
        _art_path = art
        _bg.texture = AstraUI.texture(art)
    var dark := bool(beat.get("dark", false))
    _tint.color = Color(0.0, 0.01, 0.05, 0.72) if dark else Color(0.01, 0.02, 0.05, 0.42)
    _speaker = str(beat.get("speaker", ""))
    var member_info := AstraCrewCatalog.info(_speaker)
    if _speaker != "" and not member_info.is_empty():
        var accent := AstraCrewCatalog.accent(_speaker)
        _portrait.texture = AstraUI.texture(AstraCrewCatalog.portrait_path(_speaker, str(beat.get("expression", "neutral"))))
        _portrait.visible = _portrait.texture != null
        _name.text = AstraCrewCatalog.display_name(_speaker)
        _name.add_theme_color_override("font_color", accent)
        _job.text = str(member_info.get("job", ""))
        _name_row.visible = true
        _box.add_theme_stylebox_override("panel", _box_style(accent))
    elif _speaker == "player":
        _portrait.visible = false
        _name.text = "당신"
        _name.add_theme_color_override("font_color", AstraUI.GOLD)
        _job.text = "탐사요원"
        _name_row.visible = true
        _box.add_theme_stylebox_override("panel", _box_style(AstraUI.GOLD))
    else:
        _portrait.visible = bool(beat.get("keep_portrait", false)) and _portrait.texture != null
        _name_row.visible = false
        _box.add_theme_stylebox_override("panel", _box_style(AstraUI.MUTED))
    var action := str(beat.get("action", ""))
    _action.text = action
    _action.visible = action != ""
    _set_text(str(beat.get("text", "")))
    var intro := str(beat.get("intro", ""))
    _intro.visible = intro != ""
    if intro != "":
        _intro_name.text = AstraCrewCatalog.display_name(intro)
        _intro_name.add_theme_color_override("font_color", AstraCrewCatalog.accent(intro))
        _intro_job.text = str(AstraCrewCatalog.info(intro).get("job", ""))
        _intro_line.text = AstraCrewCatalog.glimpse_line(intro)
    _caption.text = str(beat.get("caption", ""))
    AstraUI.clear(_choices)
    var choices: Array = beat.get("choices", [])
    _has_choices = not choices.is_empty()
    for index in range(choices.size()):
        var choice = choices[index]
        var label := str(choice.get("label", "")) if choice is Dictionary else str(choice)
        var hint := str(choice.get("hint", "")) if choice is Dictionary else ""
        var button_text := label if hint == "" else (label + "\n  ↳ " + hint)
        var button := AstraUI.choice_button(button_text, AstraUI.GOLD, AstraUI.T_UI, true)
        if hint != "":
            button.custom_minimum_size.y = 58.0
            button.tooltip_text = hint
        button.pressed.connect(func(): chose.emit(index))
        _choices.add_child(button)
    _more.visible = not _has_choices
    _layout()

func _box_style(accent: Color) -> StyleBoxFlat:
    var box := AstraUI.style(Color(0.016, 0.031, 0.062, 0.93), Color(accent, 0.55), 12, 1, 20)
    box.shadow_color = Color(0, 0, 0, 0.55)
    box.shadow_size = 10
    return box

func _set_text(text: String) -> void:
    if _typing != null and _typing.is_valid():
        _typing.kill()
    _text.text = text
    if AstraUI.reduce_motion or text.length() < 2:
        _text.visible_ratio = 1.0
        return
    _text.visible_ratio = 0.0
    _typing = create_tween()
    _typing.tween_property(_text, "visible_ratio", 1.0, clampf(float(text.length()) / TYPE_SPEED, 0.15, 2.2))

func is_typing() -> bool:
    return _typing != null and _typing.is_valid() and _typing.is_running()

func finish_typing() -> void:
    if _typing != null and _typing.is_valid():
        _typing.kill()
    _text.visible_ratio = 1.0

# Space / Enter / click: finish the line first, then move on.
func consume_advance() -> bool:
    if is_typing():
        finish_typing()
        return true
    if _has_choices:
        return true
    advanced.emit()
    return true

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        consume_advance()
        accept_event()

func _layout() -> void:
    var w := size.x
    var h := size.y
    if w <= 0.0 or h <= 0.0:
        return
    var box_h := clampf(h * 0.27, 150.0, 230.0)
    var has_face := _portrait.visible and _portrait.texture != null
    var box_left := w * (0.30 if has_face else 0.12)
    var box_right := w - (w * 0.03 if has_face else w * 0.12)
    # Minimum first: a box that was wider for the previous beat must be
    # allowed to shrink before it is resized.
    _box.custom_minimum_size = Vector2(box_right - box_left, box_h)
    _box.size = Vector2(box_right - box_left, box_h)
    _box.position = Vector2(box_left, h - box_h - 14.0)
    if has_face:
        var tex_size := _portrait.texture.get_size()
        var ph := h * 0.96
        var pw := ph * (tex_size.x / maxf(1.0, tex_size.y))
        if pw > w * 0.42:
            pw = w * 0.42
            ph = pw * (tex_size.y / maxf(1.0, tex_size.x))
        _portrait.size = Vector2(pw, ph)
        _portrait.position = Vector2(w * 0.02, h - ph)
    _caption.position = Vector2(18.0, 12.0)
    _caption.size = Vector2(320.0, 24.0)
    _caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _intro.position = Vector2(w * 0.03, 44.0)
    var choices_w := minf(620.0, box_right - box_left)
    _choices.size = Vector2(choices_w, 0)
    _choices.custom_minimum_size = Vector2(choices_w, 0)
    var choice_count := _choices.get_child_count()
    _choices.position = Vector2(box_right - choices_w, h - box_h - 26.0 - float(choice_count) * 58.0)
