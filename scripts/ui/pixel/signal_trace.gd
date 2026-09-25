class_name AstraSignalTrace
extends Control

# SIGNAL TRACE (interlude task). Three broken pieces of a signal; bring each
# one's frequency onto the faint target wave and lock it. No timer. After two
# wrong locks (or a while on one piece) the listener marks where it sounds
# right, so a slow hand is never stuck (§65). "나중에" gives up with what is
# already joined: a partial result, never a dead end (§16).

signal finished(result: String)

const PIECES_DEFAULT := ["호출음", "목소리", "승인 음"]

var pieces: Array = PIECES_DEFAULT.duplicate()
var tolerance: float = 0.045
var listener_name: String = "소렌"
var _targets: Array = []
var _phase_targets: Array = []
var _alignment: float = 0.0
var _phase_slider: HSlider
var _index: int = 0
var _value: float = 0.5
var _misses: int = 0
var _time_on_piece: float = 0.0
var _phase: float = 0.0
var _wave: Control
var _title: Label
var _hint: Label
var _chips: HBoxContainer
var _slider: HSlider
var _lock: Button
var _later: Button
var _done: bool = false

func setup(seed_value: int, piece_names: Array, tol: float, listener: String) -> void:
    if not piece_names.is_empty():
        pieces = piece_names.duplicate()
    tolerance = tol
    listener_name = listener
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("signal_trace|%d" % seed_value))
    for i in range(pieces.size()):
        _targets.append(rng.randf_range(0.12, 0.88))
        _phase_targets.append(rng.randf_range(0.15, 0.85))
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    var dim := ColorRect.new()
    dim.color = Color(0.01, 0.02, 0.05, 0.72)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var panel := AstraUI.reading_panel(AstraUI.CYAN, 0.97)
    panel.anchor_left = 0.5
    panel.anchor_right = 0.5
    panel.anchor_top = 0.5
    panel.anchor_bottom = 0.5
    panel.offset_left = -390
    panel.offset_right = 390
    panel.offset_top = -270
    panel.offset_bottom = 270
    add_child(panel)
    var box := AstraUI.vbox(10)
    panel.add_child(box)
    _title = AstraUI.label("", AstraUI.T_HEAD, AstraUI.CYAN)
    box.add_child(_title)
    _chips = AstraUI.hbox(8)
    box.add_child(_chips)
    _wave = Control.new()
    _wave.custom_minimum_size = Vector2(740, 170)
    _wave.draw.connect(_draw_wave)
    box.add_child(_wave)
    _slider = HSlider.new()
    _slider.min_value = 0.0
    _slider.max_value = 1.0
    _slider.step = 0.005
    _slider.custom_minimum_size = Vector2(740, 30)
    _slider.value_changed.connect(func(v: float):
        _value = v
        _refresh()
    )
    box.add_child(_slider)
    box.add_child(AstraUI.label("주파수 ← → / A D   ·   시간 정렬 ↑ ↓ / W S   ·   두 파형을 겹쳐 고정", AstraUI.T_META, AstraUI.MUTED))
    _phase_slider = HSlider.new()
    _phase_slider.min_value = 0.0
    _phase_slider.max_value = 1.0
    _phase_slider.step = 0.005
    _phase_slider.custom_minimum_size = Vector2(740, 30)
    _phase_slider.value_changed.connect(func(v: float):
        _alignment = v
        _refresh()
    )
    box.add_child(_phase_slider)
    _hint = AstraUI.prose("", AstraUI.T_UI, AstraUI.MUTED)
    box.add_child(_hint)
    var row := AstraUI.hbox(10)
    box.add_child(row)
    _later = AstraUI.button("나중에 (이어 붙인 만큼만)", AstraUI.MUTED, AstraUI.T_UI, 44)
    _later.pressed.connect(func(): _finish("partial"))
    row.add_child(_later)
    row.add_child(AstraUI.spacer())
    _lock = AstraUI.primary_button("이 주파수로 고정  (Space)", AstraUI.GOLD)
    _lock.pressed.connect(_try_lock)
    row.add_child(_lock)
    _start_piece()

func _start_piece() -> void:
    _time_on_piece = 0.0
    _misses = 0
    # Start clearly off the target, on whichever side has more room.
    var target := float(_targets[_index])
    _value = clampf(target + (0.35 if target < 0.5 else -0.35), 0.0, 1.0)
    _slider.set_value_no_signal(_value)
    _alignment = 0.0
    _phase_slider.set_value_no_signal(_alignment)
    _hint.text = "%s: 들리는 쪽으로 천천히 옮겨 봐요. 흐린 물결과 겹치면 붙어요." % listener_name if _index == 0 else "%s: 다음 조각이에요." % listener_name
    _refresh()

func _matched() -> bool:
    return absf(_value - float(_targets[_index])) <= tolerance and absf(_alignment - float(_phase_targets[_index])) <= tolerance

func _refresh() -> void:
    _title.text = "끊긴 신호 · 조각 %d / %d · %s" % [_index + 1, pieces.size(), str(pieces[_index])]
    AstraUI.clear(_chips)
    for i in range(pieces.size()):
        var color := AstraUI.GREEN if i < _index else (AstraUI.GOLD if i == _index else AstraUI.DIM)
        _chips.add_child(AstraUI.chip(("✓ " if i < _index else "") + str(pieces[i]), color, AstraUI.T_META))
    _lock.modulate = Color.WHITE if _matched() else Color(1, 1, 1, 0.75)
    _wave.queue_redraw()

func _process(delta: float) -> void:
    if _done:
        return
    _time_on_piece += delta
    if not AstraUI.reduce_motion:
        _phase += delta * 1.6
        _wave.queue_redraw()
    if _time_on_piece > 25.0 and _misses < 2:
        _misses = 2
        _hint.text = "%s: 여기쯤이에요. 제가 들리는 곳을 짚어 둘게요." % listener_name
    var step := 0.0
    if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        step -= 1.0
    if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        step += 1.0
    if step != 0.0:
        _value = clampf(_value + step * delta * 0.35, 0.0, 1.0)
        _slider.set_value_no_signal(_value)
        _refresh()
    var phase_step := float(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S))
    if phase_step != 0.0:
        _alignment = clampf(_alignment + phase_step * delta * 0.35, 0.0, 1.0)
        _phase_slider.set_value_no_signal(_alignment)
        _refresh()

func consume_advance() -> bool:
    if _done:
        return false
    _try_lock()
    return true

func _try_lock() -> void:
    if _done:
        return
    if not _matched():
        _misses += 1
        var higher := float(_targets[_index]) > _value
        _hint.text = "%s: 아직이에요. 조금 더 %s요." % [listener_name, "높여" if higher else "낮춰"]
        if _misses >= 2:
            _hint.text += " 여기쯤이에요. 짚어 둘게요."
            _hint.text += " 주파수 %d / 시간 정렬 %d (0–100)" % [roundi(float(_targets[_index]) * 100), roundi(float(_phase_targets[_index]) * 100)]
        elif absf(_value - float(_targets[_index])) <= tolerance:
            _hint.text = "%s: 주파수는 맞아요. 위아래 키로 시작 시각도 맞춰 봐요." % listener_name
        _wave.queue_redraw()
        return
    _index += 1
    if _index >= pieces.size():
        _finish("success")
        return
    _start_piece()

func _finish(result: String) -> void:
    if _done:
        return
    _done = true
    # What is already joined counts: no piece at all is still "partial" —
    # the scene goes on either way.
    finished.emit(result)

func _draw_wave() -> void:
    var size := _wave.size
    _wave.draw_rect(Rect2(Vector2.ZERO, size), Color("08121d"))
    for i in range(1, 8):
        _wave.draw_line(Vector2(size.x * i / 8.0, 0), Vector2(size.x * i / 8.0, size.y), Color("122132"), 1.0)
    _wave.draw_line(Vector2(0, size.y * 0.5), Vector2(size.x, size.y * 0.5), Color("1b2d42"), 1.0)
    if _index >= _targets.size():
        return
    var target := float(_targets[_index])
    var matched := _matched()
    var distance := absf(_value - target)
    var target_points := PackedVector2Array()
    var mine := PackedVector2Array()
    for i in range(0, 181):
        var t := float(i) / 180.0
        var x := t * size.x
        target_points.append(Vector2(x, size.y * 0.5 + sin(t * TAU * (3.0 + target * 8.0) + _phase + float(_phase_targets[_index]) * PI) * size.y * 0.3))
        var noise := sin(t * 91.0 + _phase * 3.0) * distance * size.y * 0.35
        mine.append(Vector2(x, size.y * 0.5 + sin(t * TAU * (3.0 + _value * 8.0) + _phase + _alignment * PI) * size.y * 0.3 + noise))
    _wave.draw_polyline(target_points, Color(AstraUI.CYAN, 0.35), 5.0, true)
    _wave.draw_polyline(mine, AstraUI.GREEN if matched else AstraUI.GOLD, 2.5, true)
    if _misses >= 2:
        # the listener's mark on the dial
        var x := target * size.x
        _wave.draw_line(Vector2(x, size.y - 18), Vector2(x, size.y), AstraUI.PINK, 4.0)
