class_name AstraFieldTask
extends Control

# Two short authored activities hosted by the existing interlude view. This
# control reports a result only; the session owns story/provenance changes.
signal finished(result: String)
var kind := ""
var task: Dictionary = {}
var route: Array = [0]
var costs: Array = []
var selected: Array = []
var inspected: Array = []
var _cards: VBoxContainer
var _hint: Label
var _board: Control
var _done := false
var _tries := 0
var _order: Array = [0, 1, 2, 3]
const POINTS := [Vector2(60,100), Vector2(245,45), Vector2(245,155), Vector2(425,100), Vector2(610,100)]
const EDGES := [[0,1], [0,2], [1,3], [2,3], [3,4]]

func setup(seed_value: int, data: Dictionary) -> void:
    task = data.duplicate(true)
    kind = str(task["kind"])
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("field090|%d|%s" % [seed_value, kind]))
    var short_edge := rng.randi_range(0, 1)
    costs = [2 if short_edge == 0 else 4, 4 if short_edge == 0 else 2, 2, 2, 2]
    for i in range(_order.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var temp = _order[i]
        _order[i] = _order[j]
        _order[j] = temp
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.02, 0.05, 0.85)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var panel := AstraUI.reading_panel(AstraUI.CYAN, 0.98)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -440
    panel.offset_right = 440
    panel.offset_top = -315
    panel.offset_bottom = 315
    add_child(panel)
    var box := AstraUI.vbox(10)
    panel.add_child(box)
    box.add_child(AstraUI.label(str(task["title"]), AstraUI.T_HEAD, AstraUI.CYAN))
    box.add_child(AstraUI.prose(str(task["instruction"]), AstraUI.T_UI, AstraUI.TEXT))
    _board = Control.new()
    _board.custom_minimum_size = Vector2(680, 200)
    _board.draw.connect(_draw_board)
    box.add_child(_board)
    _cards = AstraUI.vbox(6)
    box.add_child(_cards)
    _hint = AstraUI.prose("", AstraUI.T_UI, AstraUI.GOLD)
    box.add_child(_hint)
    var row := AstraUI.hbox(10)
    box.add_child(row)
    var partial := AstraUI.button("여기까지 확인하고 돌아간다", AstraUI.MUTED, AstraUI.T_UI, 42)
    partial.pressed.connect(func(): _finish("partial"))
    row.add_child(partial)
    var reset := AstraUI.button("다시 짚기", AstraUI.CYAN, AstraUI.T_UI, 42)
    reset.pressed.connect(func():
        route = [0]
        selected.clear()
        _hint.text = ""
        _render()
    )
    row.add_child(reset)
    var go := AstraUI.primary_button("확인  (Space)", AstraUI.GREEN)
    go.pressed.connect(_check)
    row.add_child(go)
    _render()

func route_cost() -> int:
    var total := 0
    for i in range(1, route.size()):
        for e in range(EDGES.size()):
            if route[i-1] in EDGES[e] and route[i] in EDGES[e]:
                total += int(costs[e])
    return total

func choices() -> Array:
    if kind == "sample_scan":
        return _order.duplicate()
    var out: Array = []
    for edge in EDGES:
        if int(edge[0]) == int(route.back()):
            out.append(int(edge[1]))
    return out

func choose(index: int) -> void:
    if _done or index not in choices():
        return
    if kind == "safe_route":
        route.append(index)
        _hint.text = "편도 %d칸 / 왕복 %d칸 · 산소 예산 12칸" % [route_cost(), route_cost()*2]
    else:
        if index not in inspected:
            inspected.append(index)
        if index in selected:
            selected.erase(index)
        elif selected.size() < 2:
            selected.append(index)
        else:
            selected.pop_front()
            selected.append(index)
        _hint.text = str(task["samples"][index]["observation"])
    _render()

func _render() -> void:
    AstraUI.clear(_cards)
    var options := choices()
    for i in range(options.size()):
        var index := int(options[i])
        var label: String = str(task["samples"][index]["label"]) if kind == "sample_scan" else str(task["nodes"][index])
        var prefix := "✓ " if index in selected else ""
        var button := AstraUI.button("%d · %s%s" % [i+1, prefix, label], AstraUI.CYAN, AstraUI.T_UI, 38)
        button.pressed.connect(choose.bind(index))
        _cards.add_child(button)
    _board.queue_redraw()

func _check() -> void:
    if _done:
        return
    if kind == "safe_route":
        if int(route.back()) == 4 and route_cost()*2 <= 12:
            _finish("success")
            return
        _hint.text = "귀환에 쓸 산소도 남겨야 한다. 분기점으로 돌아가 더 짧은 길을 확인하자."
    elif selected.size() == 2 and 0 in selected and 1 in selected:
        _finish("success")
        return
    else:
        _hint.text = "출항 전 검역 시료와 목적지 시료. 둘의 채집 날짜를 나란히 확인해 보자."
    _tries += 1

func consume_advance() -> bool:
    if _done:
        return false
    _check()
    return true

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and not _done:
        var index := int(event.keycode) - KEY_1
        var options := choices()
        if index >= 0 and index < options.size():
            choose(int(options[index]))
            get_viewport().set_input_as_handled()

func _finish(result: String) -> void:
    if _done:
        return
    _done = true
    finished.emit(result)

func _draw_board() -> void:
    _board.draw_rect(Rect2(Vector2.ZERO, _board.size), Color("08121d"))
    var font := get_theme_default_font()
    if kind == "safe_route":
        for e in range(EDGES.size()):
            var a: Vector2 = POINTS[int(EDGES[e][0])]
            var b: Vector2 = POINTS[int(EDGES[e][1])]
            _board.draw_line(a, b, AstraUI.CYAN, 3)
            _board.draw_string(font, (a+b)*0.5 + Vector2(0,-8), "%d칸" % costs[e], HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
        for i in range(POINTS.size()):
            _board.draw_circle(POINTS[i], 13, AstraUI.GOLD if i in route else AstraUI.MUTED)
            _board.draw_string(font, POINTS[i]+Vector2(-45,32), str(task["nodes"][i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
    else:
        for i in range(4):
            var at := Vector2(70+i*165,100)
            _board.draw_rect(Rect2(at-Vector2(35,55), Vector2(70,110)), AstraUI.GREEN if i in selected else AstraUI.BORDER, false, 3)
            var rings := 3+i
            for ring in range(rings):
                _board.draw_arc(at, 5+ring*4, 0, TAU, 24, AstraUI.GOLD, 2)
            _board.draw_string(font, at+Vector2(-55,78), str(task["samples"][i]["tag"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
