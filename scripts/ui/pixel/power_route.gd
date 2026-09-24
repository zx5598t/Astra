class_name AstraPowerRoute
extends Control

# SYSTEM ROUTING (interlude task, Stage 3 with Jun). Four hand levers between
# the main bus and three loads. Bring power to the security wing without
# waking the water pump (they share a feed, and both at once trips the bus).
# Click a lever to flip it. No timer; after two wrong tries Jun points at the
# next lever to flip (§65). "나중에" leaves it half-done: partial, never stuck.
#
#   bus ─ L1 ─┬─ L2 ─ 급수 펌프
#             └─ L3 ─┬─ L4 ─ 보안 구역
#                    └────── 비상 조명
# Goal: L1 on, L3 on, L4 on, L2 off.

signal finished(result: String)

const GOAL := [true, false, true, true]
const NAMES := ["주 레버", "펌프 분기", "보안 분기", "보안 구역 레버"]

var helper_name: String = "준"
var levers: Array = [false, true, false, false]
var _tries: int = 0
var _board: Control
var _hint: Label
var _done: bool = false
var _lever_rects: Array = []

func setup(seed_value: int, helper: String) -> void:
    helper_name = helper
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("power_route|%d" % seed_value))
    # a start that is never already solved
    for i in range(4):
        levers[i] = rng.randf() < 0.5
    if levers == GOAL:
        levers[1] = true
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.02, 0.05, 0.72)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var panel := AstraUI.reading_panel(AstraUI.GOLD, 0.97)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -400
    panel.offset_right = 400
    panel.offset_top = -215
    panel.offset_bottom = 215
    add_child(panel)
    var box := AstraUI.vbox(10)
    panel.add_child(box)
    box.add_child(AstraUI.label("분배반 · 보안 구역에 전력을", AstraUI.T_HEAD, AstraUI.GOLD))
    _board = Control.new()
    _board.custom_minimum_size = Vector2(760, 250)
    _board.mouse_filter = Control.MOUSE_FILTER_STOP
    _board.draw.connect(_draw_board)
    _board.gui_input.connect(_on_board_input)
    box.add_child(_board)
    _hint = AstraUI.prose("%s: 레버를 눌러서 올리고 내려. 펌프랑 보안 구역을 같이 살리면 차단기가 떨어져." % helper_name, AstraUI.T_UI, AstraUI.MUTED)
    box.add_child(_hint)
    var row := AstraUI.hbox(10)
    box.add_child(row)
    var later := AstraUI.button("나중에 (지금 상태로 두기)", AstraUI.MUTED, AstraUI.T_UI, 44)
    later.pressed.connect(func(): _finish("partial"))
    row.add_child(later)
    row.add_child(AstraUI.spacer())
    var test := AstraUI.primary_button("전력 넣기  (Space)", AstraUI.GOLD)
    test.pressed.connect(_try)
    row.add_child(test)

func consume_advance() -> bool:
    if _done:
        return false
    _try()
    return true

func _powered() -> Dictionary:
    var j1 := bool(levers[0])
    var pump := j1 and bool(levers[1])
    var j2 := j1 and bool(levers[2])
    var security := j2 and bool(levers[3])
    var lights := j2
    return {"pump": pump, "security": security, "lights": lights, "trip": pump and security}

func _try() -> void:
    if _done:
        return
    var p := _powered()
    if bool(p["security"]) and not bool(p["pump"]):
        _finish("success")
        return
    _tries += 1
    if bool(p["trip"]):
        _hint.text = "%s: 펑! 차단기 떨어졌어. 펌프 분기부터 내려." % helper_name
    elif not bool(levers[0]):
        _hint.text = "%s: 주 레버가 내려가 있어. 전기가 아예 안 들어와." % helper_name
    elif bool(p["pump"]):
        _hint.text = "%s: 펌프만 살았어. 그 분기는 내려야 해." % helper_name
    else:
        _hint.text = "%s: 보안 구역까지 안 닿았어. 선을 따라가 봐." % helper_name
    if _tries >= 2:
        for i in range(4):
            if bool(levers[i]) != bool(GOAL[i]):
                _hint.text += " …%s, 그거 하나 바꿔 봐." % str(NAMES[i])
                break
    _board.queue_redraw()

func _finish(result: String) -> void:
    if _done:
        return
    _done = true
    finished.emit(result)

func _on_board_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
        return
    for i in range(_lever_rects.size()):
        if Rect2(_lever_rects[i]).has_point(event.position):
            levers[i] = not bool(levers[i])
            _board.queue_redraw()
            return

func _unhandled_key_input(event: InputEvent) -> void:
    if _done or not (event is InputEventKey) or not event.pressed or event.echo:
        return
    var index := -1
    match event.keycode:
        KEY_1: index = 0
        KEY_2: index = 1
        KEY_3: index = 2
        KEY_4: index = 3
    if index >= 0:
        levers[index] = not bool(levers[index])
        _board.queue_redraw()
        get_viewport().set_input_as_handled()

func _draw_board() -> void:
    var size := _board.size
    _board.draw_rect(Rect2(Vector2.ZERO, size), Color("0b1520"))
    var p := _powered()
    var live := AstraUI.GOLD
    var dead := Color("2a3a4f")
    var bus := Vector2(40, size.y * 0.5)
    var l1 := Vector2(170, size.y * 0.5)
    var j1 := Vector2(280, size.y * 0.5)
    var l2 := Vector2(400, size.y * 0.22)
    var pump := Vector2(640, size.y * 0.22)
    var l3 := Vector2(400, size.y * 0.66)
    var j2 := Vector2(500, size.y * 0.66)
    var l4 := Vector2(580, size.y * 0.52)
    var sec := Vector2(700, size.y * 0.52)
    var lights := Vector2(700, size.y * 0.86)
    var j1_live := bool(levers[0])
    var j2_live := bool(p["lights"])
    _wire(bus, l1, true, live, dead)
    _wire(l1, j1, j1_live, live, dead)
    _wire(j1, Vector2(j1.x, l2.y), j1_live, live, dead)
    _wire(Vector2(j1.x, l2.y), l2, j1_live, live, dead)
    _wire(l2, pump, bool(p["pump"]), live, dead)
    _wire(j1, Vector2(j1.x, l3.y), j1_live, live, dead)
    _wire(Vector2(j1.x, l3.y), l3, j1_live, live, dead)
    _wire(l3, j2, j2_live, live, dead)
    _wire(j2, Vector2(j2.x, l4.y), j2_live, live, dead)
    _wire(Vector2(j2.x, l4.y), l4, j2_live, live, dead)
    _wire(l4, sec, bool(p["security"]), live, dead)
    _wire(j2, Vector2(j2.x, lights.y), j2_live, live, dead)
    _wire(Vector2(j2.x, lights.y), lights, j2_live, live, dead)
    _board.draw_circle(bus, 14.0, live)
    _node(pump, "급수 펌프", bool(p["pump"]), AstraUI.CYAN)
    _node(sec, "보안 구역", bool(p["security"]), AstraUI.GREEN)
    _node(lights, "비상 조명", j2_live, AstraUI.MUTED)
    _lever_rects.clear()
    for i in range(4):
        var at: Vector2 = [l1, l2, l3, l4][i]
        var rect := Rect2(at - Vector2(26, 30), Vector2(52, 60))
        _lever_rects.append(rect)
        _board.draw_rect(rect, Color("1a2a3d"))
        _board.draw_rect(rect, AstraUI.GOLD if bool(levers[i]) else AstraUI.BORDER_HI, false, 2.0)
        var knob := at + Vector2(0, -14 if bool(levers[i]) else 14)
        _board.draw_line(at, knob, AstraUI.TEXT, 5.0)
        _board.draw_circle(knob, 8.0, AstraUI.GOLD if bool(levers[i]) else AstraUI.DIM)
        _board.draw_string(get_theme_default_font(), at + Vector2(-26, 50), "%d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, 52, 16, AstraUI.MUTED)
    if bool(p["trip"]):
        _board.draw_rect(Rect2(Vector2.ZERO, size), Color(AstraUI.RED, 0.12))

func _wire(a: Vector2, b: Vector2, on: bool, live: Color, dead: Color) -> void:
    _board.draw_line(a, b, live if on else dead, 5.0 if on else 3.0)

func _node(at: Vector2, label: String, on: bool, accent: Color) -> void:
    _board.draw_circle(at, 16.0, accent if on else Color("1a2a3d"))
    _board.draw_arc(at, 16.0, 0.0, TAU, 24, accent, 2.0)
    _board.draw_string(get_theme_default_font(), at + Vector2(-60, 36), label, HORIZONTAL_ALIGNMENT_CENTER, 120, 16, AstraUI.TEXT if on else AstraUI.MUTED)
