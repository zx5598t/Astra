class_name AstraShipTask
extends Control

# Common housing for the interlude tasks (1.0): a piece of ship equipment, not
# a quiz window. A title plate, the step you are on (with words, not only
# lights), one line of instruction, the working area, the person helping you,
# and a footer: reset (R), "나중에" (Esc, keeps what is done — a partial result,
# never a dead end), and the one action for this step (Space / Enter).
# Every task is deterministic for a seed and playable with keyboard or mouse.

signal finished(result: String)

var helper_name := ""
var accent: Color = AstraUI.CYAN
var steps: Array = []
var step := 0
var _done := false
var _title: Label
var _lights: HBoxContainer
var _instruction: Label
var _helper: Label
var _action: Button
var _reset: Button
var _later: Button
var body: Control

func build_housing(title_text: String, helper: String, color: Color, step_names: Array) -> void:
    helper_name = helper
    accent = color
    steps = step_names.duplicate()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.02, 0.05, 0.74)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var frame := PanelContainer.new()
    var style := AstraUI.style(Color(0.035, 0.05, 0.075, 0.985), Color(color, 0.7), 10, 2, AstraUI.PANEL_PADDING)
    frame.add_theme_stylebox_override("panel", style)
    frame.anchor_left = 0.5
    frame.anchor_right = 0.5
    frame.anchor_top = 0.5
    frame.anchor_bottom = 0.5
    frame.offset_left = -540
    frame.offset_right = 540
    frame.offset_top = -330
    frame.offset_bottom = 330
    add_child(frame)
    var box := AstraUI.vbox(AstraUI.SPACE_SM)
    frame.add_child(box)
    var head := AstraUI.hbox(AstraUI.SPACE_MD)
    box.add_child(head)
    var plate := AstraUI.chip("SHIP SYSTEM", color, AstraUI.T_META - 3)
    head.add_child(plate)
    _title = AstraUI.label(title_text, AstraUI.T_HEAD, color)
    _title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    head.add_child(_title)
    _lights = AstraUI.hbox(AstraUI.SPACE_XS)
    head.add_child(_lights)
    _instruction = AstraUI.prose("", AstraUI.T_UI, AstraUI.TEXT)
    box.add_child(_instruction)
    body = Control.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.custom_minimum_size = Vector2(1040, 360)
    body.clip_contents = true
    box.add_child(body)
    _helper = AstraUI.prose("", AstraUI.T_META, AstraUI.MUTED)
    box.add_child(_helper)
    var foot := AstraUI.hbox(AstraUI.SPACE_MD)
    box.add_child(foot)
    _reset = AstraUI.button("처음부터 (R)", AstraUI.MUTED, AstraUI.T_META, 42)
    _reset.pressed.connect(func(): reset_task())
    foot.add_child(_reset)
    _later = AstraUI.button("나중에 · 된 만큼만 (Esc)", AstraUI.MUTED, AstraUI.T_META, 42)
    _later.pressed.connect(func(): finish("partial"))
    foot.add_child(_later)
    foot.add_child(AstraUI.spacer())
    _action = AstraUI.primary_button("", color)
    _action.custom_minimum_size = Vector2(320, 50)
    _action.pressed.connect(func(): primary_action())
    foot.add_child(_action)
    _refresh_lights()

func set_step(index: int) -> void:
    step = clampi(index, 0, steps.size() - 1)
    _refresh_lights()
    body.queue_redraw()

func _refresh_lights() -> void:
    if _lights == null:
        return
    AstraUI.clear(_lights)
    for i in range(steps.size()):
        var mark := "●" if i < step else ("◉" if i == step else "○")
        var tone := AstraUI.GREEN if i < step else (accent if i == step else AstraUI.DIM)
        _lights.add_child(AstraUI.label("%s %d %s" % [mark, i + 1, str(steps[i])], AstraUI.T_META - 2, tone))

func instruct(text: String) -> void:
    _instruction.text = text

func say(text: String) -> void:
    _helper.text = ("%s: %s" % [helper_name, text]) if helper_name != "" else text

func set_action(text: String, enabled: bool = true) -> void:
    _action.text = text
    _action.disabled = not enabled

# Overridden by each task.
func primary_action() -> void:
    pass

func reset_task() -> void:
    pass

func handle_key(_event: InputEventKey) -> bool:
    return false

func consume_advance() -> bool:
    if _done:
        return true
    if not _action.disabled:
        primary_action()
    return true

func _input(event: InputEvent) -> void:
    if _done or not (event is InputEventKey) or not event.pressed or event.echo:
        return
    var key := event as InputEventKey
    if key.keycode == KEY_ESCAPE:
        finish("partial")
    elif key.keycode == KEY_R:
        reset_task()
    elif handle_key(key):
        pass
    else:
        return
    get_viewport().set_input_as_handled()

func finish(result: String) -> void:
    if _done:
        return
    _done = true
    finished.emit(result)

func is_done() -> bool:
    return _done

# Shared drawing helpers (whole pixels, readable labels).
func draw_box(canvas: Control, rect: Rect2, fill: Color, line: Color, width: float = 2.0) -> void:
    canvas.draw_rect(rect, fill)
    canvas.draw_rect(rect, line, false, width)

func draw_text(canvas: Control, at: Vector2, text: String, color: Color, size: int = 15) -> void:
    canvas.draw_string(canvas.get_theme_default_font(), at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, AstraUI.font_size(size), color)
