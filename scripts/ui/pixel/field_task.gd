class_name AstraFieldTask
extends AstraShipTask

# ROUTE PLANNING (1.0). A small deck map: corridors with an oxygen cost each,
# one of them sealed, a door you must reach and a way back. Build the route
# node by node (click a neighbour, or its number; Backspace steps back) and
# commit it. The route must reach the door and return; the total must fit the
# budget with the reserve you are told to keep. A scan point on the way is
# optional — it costs oxygen and gives a closer look.
# Three seeded layouts; costs and the sealed corridor vary by seed.
# Success: a round trip within budget. Partial: over budget (you turn back
# early) or left. No timer, no reflexes.

const LAYOUTS := [
    {"nodes": [["현재 위치", Vector2(0.08, 0.5)], ["상부 복도", Vector2(0.32, 0.2)], ["하부 복도", Vector2(0.32, 0.8)], ["센서 기둥", Vector2(0.55, 0.2)], ["분기점", Vector2(0.58, 0.62)], ["정비 문", Vector2(0.9, 0.45)]],
        "edges": [[0, 1], [0, 2], [1, 3], [1, 4], [2, 4], [3, 5], [4, 5]], "scan": 3},
    {"nodes": [["현재 위치", Vector2(0.08, 0.3)], ["환기 통로", Vector2(0.3, 0.12)], ["격벽", Vector2(0.3, 0.55)], ["저장고", Vector2(0.52, 0.82)], ["센서 기둥", Vector2(0.58, 0.3)], ["정비 문", Vector2(0.9, 0.55)]],
        "edges": [[0, 1], [0, 2], [1, 4], [2, 4], [2, 3], [3, 5], [4, 5]], "scan": 4},
    {"nodes": [["현재 위치", Vector2(0.08, 0.7)], ["하부 복도", Vector2(0.28, 0.82)], ["계단", Vector2(0.3, 0.4)], ["센서 기둥", Vector2(0.5, 0.18)], ["기계실", Vector2(0.55, 0.62)], ["정비 문", Vector2(0.9, 0.35)]],
        "edges": [[0, 1], [0, 2], [1, 4], [2, 3], [2, 4], [3, 5], [4, 5]], "scan": 3},
]

var task: Dictionary = {}
var nodes: Array = []
var edges: Array = []
var costs: Array = []
var sealed := -1
var scan_node := 3
var target := 5
var budget := 12
var route: Array = [0]
var _layout := 0

func setup(seed_value: int, data: Dictionary) -> void:
    task = data.duplicate(true)
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("route|%d|%s" % [seed_value, str(data.get("title", ""))]))
    _layout = rng.randi_range(0, LAYOUTS.size() - 1)
    var layout: Dictionary = LAYOUTS[_layout]
    nodes = Array(layout["nodes"]).duplicate(true)
    edges = Array(layout["edges"]).duplicate(true)
    scan_node = int(layout["scan"])
    target = nodes.size() - 1
    costs.clear()
    for e in edges:
        costs.append(rng.randi_range(1, 4))
    # One corridor is sealed, never one that would cut the door off entirely.
    var candidates: Array = []
    for i in range(edges.size()):
        if int(edges[i][0]) != 0 and int(edges[i][1]) != target:
            candidates.append(i)
    sealed = int(candidates[rng.randi_range(0, candidates.size() - 1)]) if not candidates.is_empty() else -1
    # Budget: the cheapest round trip plus a small margin, so the choice of
    # corridor matters and the scan is a real trade.
    var best := _cheapest(0, target) * 2
    budget = best + rng.randi_range(1, 3)
    build_housing(str(data.get("title", "경로 · 귀환 계산")), str(data.get("helper", "루칸")), AstraUI.GREEN, ["경로", "확인"])
    body.draw.connect(_draw_body)
    body.gui_input.connect(_on_body_input)
    reset_task()

func _edge_index(a: int, b: int) -> int:
    for i in range(edges.size()):
        if (int(edges[i][0]) == a and int(edges[i][1]) == b) or (int(edges[i][0]) == b and int(edges[i][1]) == a):
            return i
    return -1

func _open(a: int, b: int) -> bool:
    var i := _edge_index(a, b)
    return i >= 0 and i != sealed

func _cheapest(from: int, to: int) -> int:
    var dist := {}
    dist[from] = 0
    var frontier: Array = [from]
    while not frontier.is_empty():
        frontier.sort_custom(func(x, y): return int(dist[x]) < int(dist[y]))
        var here: int = frontier.pop_front()
        for i in range(edges.size()):
            if i == sealed:
                continue
            var e: Array = edges[i]
            var other := -1
            if int(e[0]) == here:
                other = int(e[1])
            elif int(e[1]) == here:
                other = int(e[0])
            if other < 0:
                continue
            var d := int(dist[here]) + int(costs[i])
            if not dist.has(other) or d < int(dist[other]):
                dist[other] = d
                frontier.append(other)
    return int(dist.get(to, 99))

func route_cost() -> int:
    var total := 0
    for i in range(route.size() - 1):
        total += int(costs[_edge_index(int(route[i]), int(route[i + 1]))])
    return total

func reset_task() -> void:
    route = [0]
    set_step(0)
    instruct("‘%s’까지 갔다가 돌아올 길을 이으세요. 산소 %d칸 안에서. 막힌 통로는 지나갈 수 없습니다. (숫자 키 또는 클릭 · Backspace 되돌리기)" % [str(nodes[target][0]), budget])
    say("빠른 길이 늘 안전한 건 아니야. 돌아올 몫부터 세.")
    _update_action()
    body.queue_redraw()

func step_to(node: int) -> bool:
    if step != 0 or node < 0 or node >= nodes.size():
        return false
    if not _open(int(route.back()), node):
        say("거긴 바로 이어지지 않아." if _edge_index(int(route.back()), node) < 0 else "그 통로는 봉쇄됐어.")
        return false
    route.append(node)
    _update_action()
    body.queue_redraw()
    return true

func _update_action() -> void:
    var complete := target in route and int(route.back()) == 0 and route.size() > 1
    set_action(("이 경로로 간다 · 산소 %d/%d" % [route_cost(), budget]) if complete else ("경로 %d/%d칸" % [route_cost(), budget]), complete)

func handle_key(key: InputEventKey) -> bool:
    var n := key.keycode - KEY_1
    if step == 0 and n >= 0 and n < nodes.size():
        step_to(n)
        return true
    if step == 0 and key.keycode == KEY_BACKSPACE and route.size() > 1:
        route.pop_back()
        _update_action()
        body.queue_redraw()
        return true
    if key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and not _action.disabled:
        primary_action()
        return true
    return false

func primary_action() -> void:
    if step != 0:
        return
    set_step(1)
    var total := route_cost()
    var scanned := scan_node in route
    if total <= budget:
        say(("왕복 %d칸. 남는 %d칸이 우리 여유다. %s" % [total, budget - total, "센서 기둥 기록도 봤어. 문은 안에서 잠겼다." if scanned else "문까지 갔다 온다. 그걸로 충분해."]))
        finish("success")
    else:
        say("%d칸이면 돌아오는 길에 산소가 모자라. 문 앞에서 돌아선다. 본 것만 가지고 가자." % total)
        finish("partial")

func _on_body_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
        return
    var at: Vector2 = (event as InputEventMouseButton).position
    for i in range(nodes.size()):
        if _point(i).distance_to(at) < 34.0:
            step_to(i)

func _point(i: int) -> Vector2:
    var rel: Vector2 = nodes[i][1]
    return Vector2(40 + rel.x * (body.size.x - 80), 20 + rel.y * (body.size.y - 60))

func _draw_body() -> void:
    for i in range(edges.size()):
        var a := _point(int(edges[i][0]))
        var b := _point(int(edges[i][1]))
        var used := false
        for k in range(route.size() - 1):
            used = used or _edge_index(int(route[k]), int(route[k + 1])) == i
        if i == sealed:
            body.draw_dashed_line(a, b, AstraUI.RED, 3.0, 10.0)
            draw_text(body, (a + b) * 0.5 + Vector2(-20, -10), "봉쇄", AstraUI.RED, 14)
            continue
        body.draw_line(a, b, AstraUI.GREEN if used else AstraUI.DIM, 6.0 if used else 3.0)
        draw_text(body, (a + b) * 0.5 + Vector2(-16, -10), "산소 %d" % int(costs[i]), AstraUI.GOLD, 14)
    for i in range(nodes.size()):
        var p := _point(i)
        var here := i == int(route.back())
        var fill := Color(AstraUI.GREEN, 0.3) if i in route else Color(0.04, 0.06, 0.1)
        body.draw_circle(p, 22.0, fill)
        body.draw_arc(p, 22.0, 0.0, TAU, 32, AstraUI.GOLD if here else (AstraUI.CYAN if i != target else AstraUI.PINK), 3.0)
        draw_text(body, p + Vector2(-6, 6), str(i + 1), AstraUI.TEXT, 15)
        var name := str(nodes[i][0]) + ("  (선택: 스캔)" if i == scan_node else ("  (목표)" if i == target else ""))
        draw_text(body, p + Vector2(-50, 44), name, AstraUI.TEXT, 13)
    var path_names: Array = []
    for n in route:
        path_names.append(str(nodes[int(n)][0]))
    draw_text(body, Vector2(20, body.size.y - 10), "경로: " + " → ".join(PackedStringArray(path_names)) + "   ·   산소 %d / %d" % [route_cost(), budget], AstraUI.MUTED, 14)
