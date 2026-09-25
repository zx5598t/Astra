class_name AstraOrderTask
extends AstraShipTask

# EVIDENCE TIMELINE (1.0). Record cards (samples, duty logs, the last
# boundary) lie shuffled. The same thinking as the meeting, done with paper:
#   1. Lay them on the timeline in the order they happened (click a card, or
#      its number; the next free slot takes it; Backspace takes the last back).
#   2. Find the boundary: between which two neighbouring cards does the story
#      stop making sense? (← → then Space, or click the gap)
#   3. Say what it means (one of three readings; only one follows from the
#      cards, the others overreach).
# The card order and the readings are shuffled per seed. A wrong step
# explains itself; after two the helper points. Partial keeps what is placed.

var title_text := ""
var insight := ""
var items: Array = []        # [[text, rank], ...] in display order
var gap_after := 0           # the boundary is after this rank
var _placed: Array = []
var _gap := -1
var _conclusions: Array = []
var _answer := -1
var _misses := 0

func setup(seed_value: int, task: Dictionary, helper: String) -> void:
    title_text = str(task.get("title", "기록"))
    insight = str(task.get("insight", ""))
    gap_after = int(task.get("gap_after", 0))
    items = Array(task.get("items", [])).duplicate(true)
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("timeline|%d|%s" % [seed_value, title_text]))
    for i in range(items.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var tmp = items[i]
        items[i] = items[j]
        items[j] = tmp
    var sorted := true
    for i in range(items.size()):
        sorted = sorted and int(items[i][1]) == i
    if sorted:
        items.reverse()
    _conclusions = Array(task.get("conclusions", [insight, "기록의 순서만으로 누가 사건을 일으켰는지 알 수 있다.", "지금 기억과 다르니 기록 전체를 버려도 된다."])).duplicate()
    for i in range(_conclusions.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var tmp = _conclusions[i]
        _conclusions[i] = _conclusions[j]
        _conclusions[j] = tmp
    build_housing("기록 · " + title_text, helper, AstraUI.VIOLET, ["순서", "경계", "의미"])
    body.draw.connect(_draw_body)
    body.gui_input.connect(_on_body_input)
    reset_task()

func reset_task() -> void:
    _placed.clear()
    _gap = -1
    _answer = -1
    _misses = 0
    set_step(0)
    instruct("카드를 일어난 순서대로 시간축에 놓으세요. (숫자 키 또는 클릭 · Backspace로 하나 되돌리기)")
    say("날짜 칸이 없는 것도 내용을 보면 앞뒤가 보여요.")
    set_action("카드를 모두 놓으세요", false)
    body.queue_redraw()

func place(index: int) -> bool:
    if step != 0 or index < 0 or index >= items.size() or index in _placed:
        return false
    _placed.append(index)
    if _placed.size() == items.size():
        set_action("이 순서로 확인", true)
    body.queue_redraw()
    return true

func handle_key(key: InputEventKey) -> bool:
    var n := key.keycode - KEY_1
    match step:
        0:
            if n >= 0 and n < items.size():
                place(n)
                return true
            if key.keycode == KEY_BACKSPACE and not _placed.is_empty():
                _placed.pop_back()
                set_action("카드를 모두 놓으세요", false)
                body.queue_redraw()
                return true
        1:
            if key.keycode in [KEY_LEFT, KEY_A]:
                _gap = maxi(0, _gap - 1) if _gap >= 0 else 0
                set_action("여기가 맞지 않는다", true)
                body.queue_redraw()
                return true
            if key.keycode in [KEY_RIGHT, KEY_D]:
                _gap = mini(items.size() - 2, _gap + 1)
                set_action("여기가 맞지 않는다", true)
                body.queue_redraw()
                return true
        2:
            if n >= 0 and n < _conclusions.size():
                _answer = n
                set_action("이 뜻이다", true)
                body.queue_redraw()
                return true
    if key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and not _action.disabled:
        primary_action()
        return true
    return false

func primary_action() -> void:
    match step:
        0:
            var wrong := -1
            for slot in range(_placed.size()):
                if int(items[int(_placed[slot])][1]) != slot:
                    wrong = slot
                    break
            if wrong < 0:
                set_step(1)
                instruct("이 순서에서, 나란히 놓일 수 없는 두 카드 사이는 어디인가요? (← → 또는 틈을 클릭)")
                say("순서는 맞아요. …이제 어디가 이상한지 봐요.")
                set_action("틈을 고르세요", false)
            else:
                _misses += 1
                say("%d번째 자리부터 어긋나요." % (wrong + 1) if _misses < 2 else "%d번째에는 ‘%s’가 와야 해요." % [wrong + 1, _card_with_rank(wrong)])
                _placed = _placed.slice(0, wrong)
                set_action("카드를 모두 놓으세요", false)
        1:
            if _gap == gap_after:
                set_step(2)
                instruct("그 틈이 말해 주는 것은? (1–3 또는 클릭)")
                say("…네. 거기예요.")
                set_action("뜻을 고르세요", false)
            else:
                _misses += 1
                say("그 둘은 앞뒤로 이어져요. 이상한 건 다른 곳이에요." if _misses < 3 else "‘%s’ 바로 뒤를 봐요." % _card_with_rank(gap_after))
        2:
            if _answer < 0:
                return
            if str(_conclusions[_answer]) == insight:
                say(insight)
                finish("success")
            else:
                say("그건 카드가 말하는 것보다 많이 나간 얘기예요. …순서와 틈은 확인했어요.")
                finish("partial")

func _card_with_rank(rank: int) -> String:
    for item in items:
        if int(item[1]) == rank:
            return str(item[0])
    return ""

func _on_body_input(event: InputEvent) -> void:
    if not (event is InputEventMouseButton) or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
        return
    var at: Vector2 = (event as InputEventMouseButton).position
    match step:
        0:
            for i in range(items.size()):
                if _card_rect(i).has_point(at):
                    place(i)
        1:
            for g in range(items.size() - 1):
                if _gap_rect(g).has_point(at):
                    _gap = g
                    set_action("여기가 맞지 않는다", true)
                    body.queue_redraw()
        2:
            for c in range(_conclusions.size()):
                if _conclusion_rect(c).has_point(at):
                    _answer = c
                    set_action("이 뜻이다", true)
                    body.queue_redraw()

func _slot_rect(slot: int) -> Rect2:
    var w := (body.size.x - 40.0) / float(items.size())
    return Rect2(20 + slot * w + 8, 20, w - 16, 112)

func _gap_rect(g: int) -> Rect2:
    var a := _slot_rect(g)
    return Rect2(a.end.x - 6, a.position.y - 6, 28, a.size.y + 12)

func _card_rect(i: int) -> Rect2:
    var w := (body.size.x - 40.0) / float(items.size())
    return Rect2(20 + i * w + 8, 190, w - 16, 112)

func _conclusion_rect(c: int) -> Rect2:
    return Rect2(20, 176 + c * 58, body.size.x - 40, 48)

func _draw_body() -> void:
    draw_text(body, Vector2(20, 14), "시간축 →", AstraUI.MUTED, 13)
    for slot in range(items.size()):
        var rect := _slot_rect(slot)
        if slot < _placed.size():
            var item: Array = items[int(_placed[slot])]
            draw_box(body, rect, Color(AstraUI.VIOLET, 0.16), AstraUI.VIOLET, 2.0)
            _wrap_text(rect, str(item[0]))
        else:
            draw_box(body, rect, Color(0.02, 0.04, 0.07), AstraUI.BORDER, 1.0)
            draw_text(body, rect.position + Vector2(10, 26), "%d번째" % (slot + 1), AstraUI.DIM, 14)
    if step >= 1:
        for g in range(items.size() - 1):
            var gap := _gap_rect(g)
            var chosen := g == _gap
            body.draw_rect(gap, Color(AstraUI.GOLD, 0.35) if chosen else Color(AstraUI.GOLD, 0.08))
            if chosen:
                draw_text(body, gap.position + Vector2(-4, gap.size.y + 20), "여기?", AstraUI.GOLD, 14)
    if step == 0:
        draw_text(body, Vector2(20, 176), "놓을 카드", AstraUI.MUTED, 13)
        for i in range(items.size()):
            var rect := _card_rect(i)
            if i in _placed:
                draw_box(body, rect, Color(0.02, 0.03, 0.05), Color(AstraUI.BORDER, 0.5), 1.0)
                continue
            draw_box(body, rect, Color(0.04, 0.06, 0.1), AstraUI.CYAN, 2.0)
            draw_text(body, rect.position + Vector2(8, 20), "%d" % (i + 1), AstraUI.GOLD, 15)
            _wrap_text(Rect2(rect.position + Vector2(0, 14), rect.size - Vector2(0, 14)), str(items[i][0]))
    if step == 2:
        for c in range(_conclusions.size()):
            var rect := _conclusion_rect(c)
            draw_box(body, rect, Color(AstraUI.VIOLET, 0.2) if c == _answer else Color(0.03, 0.05, 0.08), AstraUI.VIOLET if c == _answer else AstraUI.BORDER, 2.0)
            draw_text(body, rect.position + Vector2(12, 31), "%d  %s" % [c + 1, _conclusions[c]], AstraUI.TEXT, 15)

func _wrap_text(rect: Rect2, text: String) -> void:
    var font := body.get_theme_default_font()
    var size := AstraUI.font_size(14)
    var words := text.split(" ")
    var line := ""
    var y := rect.position.y + 26
    for word in words:
        var trial := word if line == "" else line + " " + word
        if font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > rect.size.x - 16 and line != "":
            body.draw_string(font, Vector2(rect.position.x + 8, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, AstraUI.TEXT)
            y += size + 6
            line = word
        else:
            line = trial
    if line != "":
        body.draw_string(font, Vector2(rect.position.x + 8, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, AstraUI.TEXT)
