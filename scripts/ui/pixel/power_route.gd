class_name AstraPowerRoute
extends AstraShipTask

# CIRCUIT DIAGNOSIS (1.0). A feed runs from the reactor bus through sections
# of modules to the security load. One module has failed open.
#   1. Measure: up to three test points (the feed after each section). A
#      point reads 정상 (full), 약함 (a parallel pair lost one side) or 없음.
#   2. Name the failed module from the readings.
#   3. Bypass: pick a jumper that spans the failed section and can carry the
#      load (capacity in A, shown on each jumper).
# Three seeded layouts (plain chain, a parallel pair, a long chain); the
# failed module, the load and jumper capacities come from the seed. Nothing
# is timed. Success: the right module and a safe bypass. Partial: power
# restored without knowing why, or the task left.

const LAYOUTS := [
    [["A"], ["B"], ["C"], ["D"]],
    [["A"], ["B", "C"], ["D"], ["E"]],
    [["A"], ["B"], ["C", "D"], ["E"], ["F"]],
]

var sections: Array = []
var failed := ""
var load_amps := 30
var jumpers: Array = []        # {from, to, cap}
var probes_left := 3
var readings := {}             # test point index -> text
var _selected_module := ""
var _selected_jumper := -1
var _misses := 0
var _layout := 0

func setup(seed_value: int, helper: String = "준") -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("circuit|%d" % seed_value))
    _layout = rng.randi_range(0, LAYOUTS.size() - 1)
    sections = LAYOUTS[_layout].duplicate(true)
    var modules: Array = []
    for section in sections:
        for m in section:
            modules.append(str(m))
    # the first module is the bus breaker everyone checks: never the fault
    failed = str(modules[rng.randi_range(1, modules.size() - 1)])
    load_amps = int([20, 30, 40][rng.randi_range(0, 2)])
    var fault_section := _section_of(failed)
    jumpers.clear()
    var spans: Array = []
    for a in range(sections.size()):
        for b in range(a + 1, mini(sections.size(), a + 3) + 1):
            spans.append([a, b])
    for i in range(spans.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var tmp = spans[i]
        spans[i] = spans[j]
        spans[j] = tmp
    var good_made := false
    for span in spans:
        if jumpers.size() >= 3:
            break
        var covers := int(span[0]) <= fault_section and fault_section < int(span[1])
        var cap: int = [10, 20, 30, 40, 50][rng.randi_range(0, 4)]
        if covers and not good_made:
            cap = maxi(cap, load_amps)
            good_made = true
        elif covers:
            cap = mini(cap, load_amps - 10)
        jumpers.append({"from": int(span[0]), "to": int(span[1]), "cap": cap})
    if not good_made:
        jumpers[0] = {"from": fault_section, "to": fault_section + 1, "cap": load_amps + 10}
    build_housing("배전 · 회로 진단", helper, AstraUI.GOLD, ["측정", "고장 찾기", "우회"])
    body.draw.connect(_draw_body)
    body.gui_input.connect(_on_body_input)
    reset_task()

func _section_of(module: String) -> int:
    for i in range(sections.size()):
        if module in Array(sections[i]):
            return i
    return -1

# What a test point after `section` reads with `failed` open.
func reading_at(section: int) -> String:
    var fault_section := _section_of(failed)
    if section < fault_section:
        return "정상"
    return "약함" if Array(sections[fault_section]).size() > 1 else "없음"

func reset_task() -> void:
    probes_left = 3
    readings.clear()
    _selected_module = ""
    _selected_jumper = -1
    _misses = 0
    set_step(0)
    instruct("측정점(1–%d)에서 전원을 재 보세요. 둘로 갈라진 구간은 모듈 글자(A–F)로 갈래 하나를 잴 수 있습니다. 세 번까지. 다 쟀으면 Space." % sections.size())
    say("차단기부터 부하까지 한 줄이야. 어디서 끊겼는지는 재 보면 나와.")
    set_action("측정 끝 · 고장 찾기로", false)
    body.queue_redraw()

func probe(section: int) -> bool:
    if step != 0 or probes_left <= 0 or section < 0 or section >= sections.size() or readings.has(section):
        return false
    readings[section] = reading_at(section)
    probes_left -= 1
    set_action("측정 끝 · 고장 찾기로", true)
    if probes_left == 0:
        say("측정은 여기까지. 읽은 걸로 판단하자.")
    body.queue_redraw()
    return true

# One side of a split pair (costs a measurement): current through it or not.
func probe_branch(module: String) -> bool:
    var s := _section_of(module)
    if step != 0 or probes_left <= 0 or s < 0 or Array(sections[s]).size() < 2 or readings.has("m:" + module):
        return false
    readings["m:" + module] = "없음" if module == failed else "정상"
    probes_left -= 1
    set_action("측정 끝 · 고장 찾기로", true)
    body.queue_redraw()
    return true

func choose_module(module: String) -> void:
    if step != 1:
        return
    _selected_module = module
    set_action("%s 모듈이 고장이다" % module, true)
    body.queue_redraw()

func choose_jumper(index: int) -> void:
    if step != 2 or index < 0 or index >= jumpers.size():
        return
    _selected_jumper = index
    set_action("우회선 %d 연결" % (index + 1), true)
    body.queue_redraw()

func handle_key(key: InputEventKey) -> bool:
    var n := key.keycode - KEY_1
    if n >= 0 and n <= 8:
        match step:
            0: probe(n)
            2: choose_jumper(n)
        return true
    # Module letters: measure one side of a split pair, or name the fault.
    var letter := key.keycode - KEY_A
    if letter >= 0 and letter < 6:
        var module := "ABCDEF"[letter]
        if module in _modules():
            if step == 0:
                probe_branch(module)
            elif step == 1:
                choose_module(module)
            return true
    if key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and not _action.disabled:
        primary_action()
        return true
    return false

func _modules() -> Array:
    var all: Array = []
    for section in sections:
        for m in section:
            all.append(str(m))
    return all

func primary_action() -> void:
    match step:
        0:
            if readings.is_empty():
                return
            set_step(1)
            instruct("측정값으로 고장 난 모듈을 고르세요. (모듈 글자 A–F 또는 클릭)")
            say("‘약함’은 둘로 갈라진 구간에서 한쪽만 죽었을 때야. ‘없음’은 한 줄짜리가 끊긴 거고.")
            set_action("모듈을 고르세요", false)
        1:
            if _selected_module == "":
                return
            if _selected_module == failed:
                set_step(2)
                instruct("우회선을 고르세요. 고장 구간을 건너뛰고, 부하 %dA를 견딜 수 있어야 합니다. (1–%d)" % [load_amps, jumpers.size()])
                say("맞아, 거기야. 이제 돌아가는 길. 용량 모자라면 또 탈 거야.")
                set_action("우회선을 고르세요", false)
            else:
                _misses += 1
                if _misses >= 2:
                    say("…%s가 아니면 측정값이 설명이 안 돼. 일단 전원만 살리자." % _selected_module)
                    finish("partial")
                    return
                say("%s가 끊겼다면 측정값이 달라야 해. 다시 봐." % _selected_module)
                _selected_module = ""
                set_action("모듈을 고르세요", false)
        2:
            if _selected_jumper < 0:
                return
            var j: Dictionary = jumpers[_selected_jumper]
            var fault_section := _section_of(failed)
            var covers := int(j["from"]) <= fault_section and fault_section < int(j["to"])
            if covers and int(j["cap"]) >= load_amps:
                say("들어온다. …이 모듈, 누가 손으로 뺀 흔적이 있어. 저절로 나간 게 아니야.")
                finish("success")
            elif not covers:
                say("그 선은 고장 구간을 안 건너. 전원은 그대로 죽어 있어.")
                _selected_jumper = -1
                set_action("우회선을 고르세요", false)
            else:
                say("용량이 %dA뿐이야. 켜자마자 또 탈 거야. 일단 여기까지만 하자." % int(j["cap"]))
                finish("partial")

func _on_body_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
        return
    var at: Vector2 = (event as InputEventMouseButton).position
    match step:
        0:
            for i in range(sections.size()):
                if _tp_rect(i).grow(10).has_point(at):
                    probe(i)
            for m in _modules():
                if _module_rect(str(m)).has_point(at):
                    probe_branch(str(m))
        1:
            for m in _modules():
                if _module_rect(str(m)).has_point(at):
                    choose_module(str(m))
        2:
            for i in range(jumpers.size()):
                if _jumper_rect(i).has_point(at):
                    choose_jumper(i)

func _section_x(i: int) -> float:
    var w := body.size.x
    return 120.0 + (w - 260.0) * (float(i) + 0.5) / float(sections.size())

func _module_rect(module: String) -> Rect2:
    var s := _section_of(module)
    var index := Array(sections[s]).find(module)
    var count := Array(sections[s]).size()
    var y := 110.0 + (float(index) - (count - 1) * 0.5) * 70.0
    return Rect2(_section_x(s) - 44, y - 26, 88, 52)

func _tp_rect(i: int) -> Rect2:
    var x := (_section_x(i) + (_section_x(i + 1) if i + 1 < sections.size() else body.size.x - 90.0)) * 0.5
    return Rect2(x - 14, 96, 28, 28)

func _jumper_rect(i: int) -> Rect2:
    return Rect2(40 + i * ((body.size.x - 80) / 3.0), 270, (body.size.x - 80) / 3.0 - 16, 70)

func _draw_body() -> void:
    var w := body.size.x
    var line_y := 110.0
    body.draw_line(Vector2(40, line_y), Vector2(w - 40, line_y), AstraUI.DIM, 4.0)
    draw_box(body, Rect2(10, line_y - 30, 70, 60), Color(0.05, 0.08, 0.1), AstraUI.GOLD)
    draw_text(body, Vector2(18, line_y + 6), "버스", AstraUI.GOLD, 15)
    draw_box(body, Rect2(w - 90, line_y - 30, 80, 60), Color(0.05, 0.08, 0.1), AstraUI.GOLD)
    draw_text(body, Vector2(w - 84, line_y - 4), "보안부하", AstraUI.GOLD, 13)
    draw_text(body, Vector2(w - 84, line_y + 18), "%dA" % load_amps, AstraUI.GOLD, 13)
    for m in _modules():
        var rect := _module_rect(str(m))
        var picked := step >= 1 and str(m) == _selected_module
        if Array(sections[_section_of(str(m))]).size() > 1:
            body.draw_line(Vector2(rect.position.x - 20, line_y), Vector2(rect.position.x, rect.get_center().y), AstraUI.DIM, 3.0)
            body.draw_line(Vector2(rect.end.x, rect.get_center().y), Vector2(rect.end.x + 20, line_y), AstraUI.DIM, 3.0)
        draw_box(body, rect, Color(AstraUI.GOLD, 0.22) if picked else Color(0.05, 0.08, 0.1), AstraUI.GOLD if picked else AstraUI.BORDER, 3.0 if picked else 2.0)

        draw_text(body, rect.position + Vector2(10, 32), str(m), AstraUI.TEXT, 16)
        var branch := str(readings.get("m:" + str(m), ""))
        if branch != "":
            draw_text(body, rect.position + Vector2(36, 32), "· " + branch, AstraUI.GREEN if branch == "정상" else AstraUI.RED, 13)
    for i in range(sections.size()):
        var tp := _tp_rect(i)
        var read := str(readings.get(i, ""))
        body.draw_circle(tp.get_center(), 11.0, AstraUI.CYAN if read == "" else (AstraUI.GREEN if read == "정상" else (AstraUI.GOLD if read == "약함" else AstraUI.RED)))
        draw_text(body, tp.position + Vector2(-6, -12), "측정 %d" % (i + 1), AstraUI.MUTED, 13)
        if read != "":
            draw_text(body, tp.position + Vector2(-6, 52), read, AstraUI.TEXT, 15)
    draw_text(body, Vector2(40, 236), "측정 남음 %d" % probes_left if step == 0 else "측정값: 정상 = 전원 있음 · 약함 = 갈래 하나만 · 없음 = 끊김", AstraUI.MUTED, 14)
    for i in range(jumpers.size()):
        var j: Dictionary = jumpers[i]
        var rect := _jumper_rect(i)
        var picked := step == 2 and i == _selected_jumper
        draw_box(body, rect, Color(AstraUI.CYAN, 0.2) if picked else Color(0.03, 0.05, 0.08), AstraUI.CYAN if picked else AstraUI.BORDER, 2.0)
        var from_label := "버스" if int(j["from"]) == 0 else "측정 %d" % int(j["from"])
        var to_label := "부하" if int(j["to"]) >= sections.size() else "측정 %d" % int(j["to"])
        draw_text(body, rect.position + Vector2(12, 28), "우회선 %d · %s → %s" % [i + 1, from_label, to_label], AstraUI.TEXT, 15)
        draw_text(body, rect.position + Vector2(12, 54), "용량 %dA" % int(j["cap"]), AstraUI.GOLD, 15)
