class_name AstraOrderTask
extends Control

# ORDER (interlude task: samples, duty logs, the last boundary). Four pieces
# of the record are shuffled; pick them in the order they happened. It is not
# a test: the point is to see, laid out in a row, the two things that should
# not sit next to each other (§13). A wrong pick explains itself; after two,
# the person helping points at the next piece. "나중에" keeps what is placed.

signal finished(result: String)

var helper_name: String = ""
var title_text: String = ""
var insight: String = ""
var items: Array = []      # [[text, rank], ...] in display order
var _placed: Array = []    # indexes into items, in chosen order
var _misses: int = 0
var _cards: VBoxContainer
var _slots: HBoxContainer
var _hint: Label
var _done: bool = false
var _task_data: Dictionary = {}
var _concluding: bool = false
var _conclusions: Array = []

func setup(seed_value: int, task: Dictionary, helper: String) -> void:
    _task_data = task.duplicate(true)
    helper_name = helper
    title_text = str(task.get("title", "순서"))
    insight = str(task.get("insight", ""))
    items = Array(task.get("items", [])).duplicate(true)
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("order|%d|%s" % [seed_value, title_text]))
    _conclusions = Array(task.get("conclusions", [])).duplicate()
    for i in range(_conclusions.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var old = _conclusions[i]
        _conclusions[i] = _conclusions[j]
        _conclusions[j] = old
    for i in range(items.size() - 1, 0, -1):
        var j := rng.randi_range(0, i)
        var tmp = items[i]
        items[i] = items[j]
        items[j] = tmp
    if _already_sorted():
        items.reverse()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.02, 0.05, 0.72)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var panel := AstraUI.reading_panel(AstraUI.VIOLET, 0.97)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -430
    panel.offset_right = 430
    panel.offset_top = -250
    panel.offset_bottom = 250
    add_child(panel)
    var box := AstraUI.vbox(10)
    panel.add_child(box)
    box.add_child(AstraUI.label(title_text, AstraUI.T_HEAD, AstraUI.VIOLET))
    box.add_child(AstraUI.label("먼저 일어난 것부터 차례로 누르세요.", AstraUI.T_META, AstraUI.MUTED))
    _slots = AstraUI.hbox(8)
    box.add_child(_slots)
    _cards = AstraUI.vbox(6)
    box.add_child(_cards)
    _hint = AstraUI.prose("", AstraUI.T_UI, AstraUI.MUTED)
    box.add_child(_hint)
    var row := AstraUI.hbox(10)
    box.add_child(row)
    var later := AstraUI.button("나중에 (여기까지만)", AstraUI.MUTED, AstraUI.T_UI, 44)
    later.pressed.connect(func(): _finish("partial"))
    row.add_child(later)
    _render()

func _already_sorted() -> bool:
    for i in range(items.size()):
        if int(items[i][1]) != i:
            return false
    return true

func consume_advance() -> bool:
    return not _done

func _render() -> void:
    AstraUI.clear(_slots)
    for i in range(items.size()):
        var text := "%d" % (i + 1)
        var color := AstraUI.DIM
        if i < _placed.size():
            text = "%d ✓" % (i + 1)
            color = AstraUI.GREEN
        _slots.add_child(AstraUI.chip(text, color, AstraUI.T_META))
    AstraUI.clear(_cards)
    if _concluding:
        _cards.add_child(AstraUI.label(str(_task_data.get("question", "이 순서에서 확인되는 것은?")), AstraUI.T_UI, AstraUI.CYAN))
        for i in range(_conclusions.size()):
            var conclusion := str(_conclusions[i])
            var confirm := AstraUI.button("%d · %s" % [i+1, conclusion], AstraUI.VIOLET, AstraUI.T_UI, 50)
            confirm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            confirm.pressed.connect(_conclude.bind(i))
            _cards.add_child(confirm)
        return
    var next_rank := _placed.size()
    for index in range(items.size()):
        if index in _placed:
            continue
        var item: Array = items[index]
        var button := AstraUI.button("%d · %s" % [index+1, item[0]], AstraUI.VIOLET, AstraUI.T_UI, 50)
        button.alignment = HORIZONTAL_ALIGNMENT_LEFT
        if _misses >= 2 and int(item[1]) == next_rank:
            button.add_theme_color_override("font_color", AstraUI.GOLD)
            button.text = "▸ " + str(item[0])
        button.pressed.connect(_pick.bind(index))
        _cards.add_child(button)
    var placed_text: Array = []
    for index in _placed:
        placed_text.append(str(items[index][0]))
    if not placed_text.is_empty() and _hint.text == "":
        _hint.text = "  →  ".join(PackedStringArray(placed_text))

func _pick(index: int) -> void:
    if _done or _concluding or index in _placed or index < 0 or index >= items.size():
        return
    var item: Array = items[index]
    if int(item[1]) != _placed.size():
        _misses += 1
        _hint.text = "%s: 그건 아직이에요. 그보다 먼저 일어난 게 있어요." % helper_name
        if _misses >= 2:
            _hint.text += " 이거부터요."
        _render()
        return
    _placed.append(index)
    _hint.text = ""
    if _placed.size() >= items.size():
        _hint.text = insight
        _concluding = not _conclusions.is_empty()
        _render()
        if not _concluding:
            _finish.call_deferred("success")
        return
    _render()

func _conclude(index: int) -> void:
    if _done or not _concluding or index < 0 or index >= _conclusions.size():
        return
    if str(_conclusions[index]) == insight:
        _finish("success")
    else:
        _hint.text = "날짜와 순서가 보여 주는 범위부터 보자. 누가 했는지는 이 기록만으로 결정할 수 없다."

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and not _done:
        var index := int(event.keycode) - KEY_1
        if index >= 0 and index < ( _conclusions.size() if _concluding else items.size() ):
            if _concluding:
                _conclude(index)
            else:
                _pick(index)
            get_viewport().set_input_as_handled()

func _finish(result: String) -> void:
    if _done:
        return
    _done = true
    finished.emit(result)
