class_name AstraSignalTrace
extends AstraShipTask

# SIGNAL ANALYSIS (1.0). Three receiver channels. One is only interference —
# its trace never repeats; the other two carry the same repeating signal.
#   1. Find the interference (compare the shapes; 1-3 or click).
#   2. Bring the two real channels onto the reference: frequency and phase
#      (Tab switches channel, ← → frequency, ↑ ↓ phase, Space locks).
#   3. With both locked, the pulses show which antenna heard the signal first:
#      bow, stern, or both at once (inside the ship). Choose the source.
# Success: the source is known. Partial: the signal is real but its source is
# not (or the task is left). Deterministic per seed; no timer, no reflexes.

const SOURCES := ["함수 쪽 바깥", "함미 쪽 바깥", "선내 (두 안테나가 동시에)"]

var tolerance := 0.05
var noise_channel := 0
var freq_targets: Array = []
var phase_targets: Array = []
var freq: Array = [0.5, 0.5, 0.5]
var phase: Array = [0.0, 0.0, 0.0]
var locked: Array = [false, false, false]
var source := 0
var offset_ms := 0
var _active := 0
var _misses := 0
var _answer := -1
var _seed := 0
var _drag_channel := -1
var _drag_kind := ""

func setup(seed_value: int, _pieces: Array = [], tol: float = 0.05, listener: String = "소렌") -> void:
    _seed = seed_value
    tolerance = maxf(0.04, tol)
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("signal_analysis|%d" % seed_value))
    noise_channel = rng.randi_range(0, 2)
    source = rng.randi_range(0, 2)
    offset_ms = [rng.randi_range(18, 40), -rng.randi_range(18, 40), 0][source]
    for i in range(3):
        freq_targets.append(rng.randf_range(0.2, 0.8))
        phase_targets.append(rng.randf_range(0.15, 0.85))
    build_housing("통신 · 신호 분석", listener, AstraUI.CYAN, ["간섭 찾기", "두 채널 정렬", "발신 방향"])
    body.draw.connect(_draw_body)
    body.gui_input.connect(_on_body_input)
    reset_task()

func reset_task() -> void:
    for i in range(3):
        locked[i] = false
        freq[i] = clampf(float(freq_targets[i]) + (0.3 if float(freq_targets[i]) < 0.5 else -0.3), 0.0, 1.0)
        phase[i] = 0.0
    _misses = 0
    _answer = -1
    _active = 1 if noise_channel == 0 else 0
    set_step(0)
    instruct("세 수신 채널 중 하나는 잡음뿐입니다. 모양이 반복되지 않는 채널을 고르세요. (1–3 또는 클릭)")
    say("세 줄이 다 비슷해 보여도, 진짜 신호는 같은 모양이 되풀이돼요.")
    set_action("이 채널이 간섭이다", false)
    body.queue_redraw()

func handle_key(event: InputEventKey) -> bool:
    match step:
        0:
            if event.keycode in [KEY_1, KEY_2, KEY_3]:
                _answer = event.keycode - KEY_1
                _action.text = AstraJosa.i("채널 " + "ABC"[_answer]) + " 간섭이다"
                _action.disabled = false
                body.queue_redraw()
                return true
        1:
            if event.keycode == KEY_TAB:
                _next_channel()
                return true
            if event.keycode in [KEY_LEFT, KEY_A]:
                _nudge(-0.01, 0.0)
                return true
            if event.keycode in [KEY_RIGHT, KEY_D]:
                _nudge(0.01, 0.0)
                return true
            if event.keycode in [KEY_UP, KEY_W]:
                _nudge(0.0, 0.01)
                return true
            if event.keycode in [KEY_DOWN, KEY_S]:
                _nudge(0.0, -0.01)
                return true
        2:
            if event.keycode in [KEY_1, KEY_2, KEY_3]:
                _answer = event.keycode - KEY_1
                set_action("발신: " + str(SOURCES[_answer]), true)
                body.queue_redraw()
                return true
    if event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and not _action.disabled:
        primary_action()
        return true
    return false

func _next_channel() -> void:
    for k in range(1, 3):
        var c := (_active + k) % 3
        if c != noise_channel and not bool(locked[c]):
            _active = c
            break
    body.queue_redraw()

func _nudge(df: float, dp: float) -> void:
    if bool(locked[_active]):
        return
    freq[_active] = clampf(float(freq[_active]) + df, 0.0, 1.0)
    phase[_active] = fposmod(float(phase[_active]) + dp, 1.0)
    _update_lock_button()
    body.queue_redraw()

func _matched(c: int) -> bool:
    var dp := absf(float(phase[c]) - float(phase_targets[c]))
    dp = minf(dp, 1.0 - dp)
    return absf(float(freq[c]) - float(freq_targets[c])) <= tolerance and dp <= tolerance

func _update_lock_button() -> void:
    set_action("채널 %s 고정" % "ABC"[_active], true)

func primary_action() -> void:
    match step:
        0:
            if _answer < 0:
                return
            if _answer == noise_channel:
                set_step(1)
                instruct("남은 두 채널을 흐린 기준 파형에 겹치세요. 오른쪽 주파수/위상 슬라이더를 마우스로 조절하거나 ← → / ↑ ↓로 맞추고, 맞으면 고정하세요.")
                say("좋아요. 그건 그냥 배 안의 잡음이에요. 나머지 둘은 같은 걸 듣고 있어요.")
                _answer = -1
                _update_lock_button()
            else:
                _misses += 1
                say("채널 %s는… 같은 모양이 다시 나와요. 반복되는 건 신호예요." % "ABC"[_answer] if _misses < 2 else
                    "채널 %s를 봐요. 봉우리 간격이 매번 달라요." % "ABC"[noise_channel])
                _answer = -1
                set_action("이 채널이 간섭이다", false)
        1:
            if _matched(_active):
                locked[_active] = true
                say("붙었어요.")
                var remaining := false
                for c in range(3):
                    remaining = remaining or (c != noise_channel and not bool(locked[c]))
                if remaining:
                    _next_channel()
                    _update_lock_button()
                else:
                    set_step(2)
                    instruct("두 안테나(함수·함미)가 같은 펄스를 받은 시각을 보세요. 먼저 들은 쪽이 가깝습니다. 발신 방향을 고르세요. (1–3)")
                    say("펄스 두 개예요. …시간 차이를 봐요.")
                    set_action("방향을 고르세요", false)
            else:
                _misses += 1
                say("아직 어긋나요. 봉우리 간격(주파수)부터 맞추고, 그다음 위치(위상)를 맞춰요." if _misses < 3 else
                    "주파수는 %s, 위상은 %s 쪽이에요." % ["오른쪽" if float(freq_targets[_active]) > float(freq[_active]) else "왼쪽", "위" if float(phase_targets[_active]) > float(phase[_active]) else "아래"])
        2:
            if _answer < 0:
                return
            if _answer == source:
                say("…%s. 그럼 이건 녹음이 아니에요. 지금 누가 보내고 있어요." % str(SOURCES[source]) if source != 2 else "…둘이 동시에 들었어요. 이 신호는 배 안에서 나와요.")
                finish("success")
            else:
                say("그 방향이면 시간 차이가 반대로 나와야 해요. …신호는 확실하지만 방향은 모르겠네요.")
                finish("partial")

func _freq_rect(c: int) -> Rect2:
    var lane_h := body.size.y / 3.0
    return Rect2(body.size.x - 250.0, c * lane_h + lane_h * 0.38, 220.0, 18.0)

func _phase_rect(c: int) -> Rect2:
    var rect := _freq_rect(c)
    rect.position.y += 42.0
    return rect

func _set_slider(kind: String, c: int, x: float) -> void:
    if c == noise_channel or bool(locked[c]):
        return
    _active = c
    var rect := _freq_rect(c) if kind == "freq" else _phase_rect(c)
    var value := clampf((x - rect.position.x) / maxf(1.0, rect.size.x), 0.0, 1.0)
    if kind == "freq":
        freq[c] = value
    else:
        phase[c] = value
    _update_lock_button()
    body.queue_redraw()

func _on_body_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and step == 1 and _drag_channel >= 0 and _drag_kind != "":
        var motion := event as InputEventMouseMotion
        if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
            _set_slider(_drag_kind, _drag_channel, motion.position.x)
        return
    if not (event is InputEventMouseButton) or event.button_index != MOUSE_BUTTON_LEFT:
        return
    var mouse := event as InputEventMouseButton
    if not mouse.pressed:
        _drag_channel = -1
        _drag_kind = ""
        return
    var y: float = mouse.position.y
    var lane := clampi(int(y / (body.size.y / 3.0)), 0, 2)
    match step:
        0:
            _answer = lane
            _action.text = AstraJosa.i("채널 " + "ABC"[_answer]) + " 간섭이다"
            _action.disabled = false
        1:
            if lane != noise_channel and not bool(locked[lane]):
                _active = lane
                if _freq_rect(lane).grow(8.0).has_point(mouse.position):
                    _drag_channel = lane
                    _drag_kind = "freq"
                    _set_slider("freq", lane, mouse.position.x)
                elif _phase_rect(lane).grow(8.0).has_point(mouse.position):
                    _drag_channel = lane
                    _drag_kind = "phase"
                    _set_slider("phase", lane, mouse.position.x)
                else:
                    _update_lock_button()
        2:
            if mouse.position.x > body.size.x * 0.62:
                _answer = clampi(int((y - 40.0) / 70.0), 0, 2)
                set_action("발신: " + str(SOURCES[_answer]), true)
    body.queue_redraw()

func _hiss(c: int, t: float) -> float:
    var rng := RandomNumberGenerator.new()
    rng.seed = absi(hash("hiss|%d|%d|%d" % [_seed, c, int(t * 40.0)]))
    return rng.randf_range(-1.0, 1.0)

# Every channel is noisy. The real ones repeat the same motif under the hiss;
# the interference drifts in pitch and strength, so it never repeats — it has
# to be read, not spotted by cleanliness.
func _wave(c: int, t: float) -> float:
    if c == noise_channel:
        return 0.5 * sin(t * (4.6 + 1.4 * sin(t * 0.37)) + 1.1) * (0.7 + 0.3 * sin(t * 0.61)) + 0.3 * sin(t * 9.3 * (1.0 + 0.12 * sin(t * 0.23))) + 0.3 * _hiss(c, t)
    var f := 3.0 + float(freq[c]) * 6.0
    var p := float(phase[c]) * TAU
    return (sin(t * f + p) * 0.55 + sin(t * f * 2.0 + p) * 0.2) + 0.3 * _hiss(c, t)

func _target_wave(c: int, t: float) -> float:
    var f := 3.0 + float(freq_targets[c]) * 6.0
    var p := float(phase_targets[c]) * TAU
    return sin(t * f + p) * 0.7 + sin(t * f * 2.0 + p) * 0.25

func _draw_body() -> void:
    var w := body.size.x
    var h := body.size.y
    if step < 2:
        var lane_h := h / 3.0
        for c in range(3):
            var top := c * lane_h
            var rect := Rect2(0, top + 4, w, lane_h - 8)
            var chosen := (step == 0 and c == _answer) or (step == 1 and c == _active)
            draw_box(body, rect, Color(0.02, 0.05, 0.08), Color(AstraUI.CYAN, 0.9) if chosen else Color(AstraUI.BORDER, 1.0), 3.0 if chosen else 1.0)
            var status := ""
            if step >= 1 and c == noise_channel:
                status = " · 간섭 (제외)"
            elif bool(locked[c]):
                status = " · 고정됨"
            draw_text(body, Vector2(10, top + 26), "채널 %s%s" % ["ABC"[c], status], AstraUI.TEXT, 15)
            var mid := top + lane_h * 0.55
            if step == 1 and c != noise_channel and not bool(locked[c]):
                var ghost := PackedVector2Array()
                for x in range(90, int(w) - 10, 4):
                    ghost.append(Vector2(x, mid - _target_wave(c, x / 60.0) * lane_h * 0.32))
                body.draw_polyline(ghost, Color(AstraUI.MUTED, 0.45), 3.0)
            var pts := PackedVector2Array()
            var wave_end := int(w) - (280 if step == 1 and c == _active and c != noise_channel and not bool(locked[c]) else 10)
            for x in range(90, wave_end, 3):
                var v := _target_wave(c, x / 60.0) if bool(locked[c]) else _wave(c, x / 60.0)
                pts.append(Vector2(x, mid - v * lane_h * 0.32))
            var ink := AstraUI.GREEN if bool(locked[c]) else (AstraUI.DIM if (step >= 1 and c == noise_channel) else AstraUI.CYAN)
            body.draw_polyline(pts, ink, 2.0)
            if step == 1 and c == _active and c != noise_channel and not bool(locked[c]):
                var fr := _freq_rect(c)
                var pr := _phase_rect(c)
                draw_text(body, Vector2(fr.position.x, fr.position.y - 8), "주파수 %d%%" % int(float(freq[c]) * 100), AstraUI.GOLD, 13)
                draw_text(body, Vector2(pr.position.x, pr.position.y - 8), "위상 %d%%" % int(float(phase[c]) * 100), AstraUI.GOLD, 13)
                body.draw_rect(fr, Color(AstraUI.DIM, 0.35))
                body.draw_rect(pr, Color(AstraUI.DIM, 0.35))
                body.draw_rect(Rect2(fr.position, Vector2(fr.size.x * float(freq[c]), fr.size.y)), Color(AstraUI.CYAN, 0.65))
                body.draw_rect(Rect2(pr.position, Vector2(pr.size.x * float(phase[c]), pr.size.y)), Color(AstraUI.VIOLET, 0.65))
                body.draw_circle(Vector2(fr.position.x + fr.size.x * float(freq[c]), fr.get_center().y), 7.0, AstraUI.GOLD)
                body.draw_circle(Vector2(pr.position.x + pr.size.x * float(phase[c]), pr.get_center().y), 7.0, AstraUI.GOLD)
        return
    # Step 3: two antennas, one pulse each, on a millisecond axis.
    var axis_w := w * 0.58
    for i in range(2):
        var top := 30.0 + i * 120.0
        draw_box(body, Rect2(0, top, axis_w, 96), Color(0.02, 0.05, 0.08), AstraUI.BORDER, 1.0)
        draw_text(body, Vector2(10, top + 22), ["함수 안테나", "함미 안테나"][i], AstraUI.TEXT, 15)
        var at := 0.0
        if i == 0:
            at = -float(offset_ms) * 0.5
        else:
            at = float(offset_ms) * 0.5
        var x := axis_w * 0.5 + at * 4.0
        body.draw_line(Vector2(20, top + 70), Vector2(axis_w - 20, top + 70), AstraUI.DIM, 1.0)
        body.draw_rect(Rect2(x - 3, top + 34, 6, 36), AstraUI.GOLD)
        draw_text(body, Vector2(x - 30, top + 90), "%+d ms" % int(round(at)), AstraUI.GOLD, 13)
    draw_text(body, Vector2(10, 290), "먼저 받은 안테나 = 더 가까운 쪽. 같은 시각이면 두 안테나 사이, 배 안이다.", AstraUI.MUTED, 14)
    for s in range(3):
        var rect := Rect2(w * 0.62, 40 + s * 70, w * 0.36, 58)
        draw_box(body, rect, Color(AstraUI.CYAN, 0.18) if s == _answer else Color(0.02, 0.05, 0.08), AstraUI.CYAN if s == _answer else AstraUI.BORDER, 2.0)
        draw_text(body, rect.position + Vector2(12, 36), "%d  %s" % [s + 1, SOURCES[s]], AstraUI.TEXT, 15)
