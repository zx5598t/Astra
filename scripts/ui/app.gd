extends Control

# Application root: background, screen routing, overlays and persistence.

const VERSION_FALLBACK := "0.2.0"

var meta := AstraMetaProgress.new()
var settings := AstraSettings.new()
var ai_gateway := AIGateway.new()
var fx: AstraFeedbackFX
var ai_client: AstraRemoteAIClient
var selected_protocol: String = "ANALYST"
var session: AstraGameSession
var ai_status: String = ""

var _screen_root: Control
var _overlay_layer: CanvasLayer
var _overlay_root: Control
var _current: Control
var _pending_ai: Dictionary = {}
var _ai_serial: int = 0

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    meta.load_data()
    settings.load_data()
    settings.apply_audio()
    settings.apply_display()
    settings.fit_window_to_screen()
    selected_protocol = meta.last_protocol if AstraGameSession.PROTOCOLS.has(meta.last_protocol) else "ANALYST"

    var bg := ColorRect.new()
    bg.color = AstraUI.BG
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    var stars := Starfield.new()
    stars.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(stars)

    _screen_root = Control.new()
    _screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _screen_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_screen_root)

    _overlay_layer = CanvasLayer.new()
    _overlay_layer.layer = 60
    add_child(_overlay_layer)
    _overlay_root = Control.new()
    _overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _overlay_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _overlay_layer.add_child(_overlay_root)

    fx = AstraFeedbackFX.new()
    add_child(fx)

    ai_client = AstraRemoteAIClient.new()
    ai_client.endpoint = settings.ai_endpoint
    add_child(ai_client)
    ai_client.action_received.connect(_on_ai_action)

    show_title()
    if meta.total_cases_completed == 0 and not _first_run_seen():
        _first_run_prompt.call_deferred()

func version_text() -> String:
    var file := FileAccess.open("res://VERSION", FileAccess.READ)
    if file == null:
        return VERSION_FALLBACK
    return file.get_as_text().strip_edges()

func overlay_root() -> Control:
    return _overlay_root

func modal_open() -> bool:
    for child in _overlay_root.get_children():
        if child is AstraModal and not child.is_queued_for_deletion():
            return true
    return false

func _set_screen(node: Control) -> void:
    for child in _overlay_root.get_children():
        child.queue_free()
    if _current != null:
        _screen_root.remove_child(_current)
        _current.queue_free()
    _current = node
    _screen_root.add_child(node)
    AstraUI.fade_in(node, 0.25)

func show_title() -> void:
    session = null
    var title := AstraTitleScreen.new()
    _set_screen(title)
    title.setup(self)

func start_case(case_id: String, protocol: String) -> void:
    if not meta.is_case_unlocked(case_id):
        fx.toast("아직 잠긴 사건입니다. " + meta.unlock_hint(case_id), AstraUI.GOLD)
        return
    selected_protocol = protocol
    session = AstraGameSession.new()
    var seed_value := int(Time.get_unix_time_from_system() * 1000.0) % 2147483
    session.setup(case_id, seed_value, protocol)
    var screen := AstraGameScreen.new()
    _set_screen(screen)
    screen.setup(self, session, fx)

func record_result(finished: AstraGameSession) -> Dictionary:
    return meta.record_case_result(finished.case_id, finished.protocol, finished.final_report, true)

func quit_game() -> void:
    get_tree().quit()

# ---------------------------------------------------------------- overlays

func show_help() -> void:
    var body := AstraUI.rich(16, false)
    body.text = AstraHelp.text()
    body.custom_minimum_size = Vector2(0, 560)
    AstraModal.open(_overlay_root, "플레이 방법", body, [["닫기", AstraUI.CYAN]], Callable(), 900.0)

func show_settings() -> void:
    var box := AstraUI.vbox(14)
    box.add_child(_slider_row("전체 음량", settings.master_volume, 0.0, 1.0, 0.05, func(value: float):
        settings.master_volume = value
        settings.apply_audio()
    ))
    box.add_child(_slider_row("회의 발언 속도", settings.meeting_speed, 0.5, 3.0, 0.25, func(value: float):
        settings.meeting_speed = value
    ))
    box.add_child(_toggle_row("전체 화면 (F11)", settings.fullscreen, func(on: bool):
        settings.fullscreen = on
        settings.apply_display()
    ))
    box.add_child(_toggle_row("단계별 안내 문구 표시", settings.show_hints, func(on: bool):
        settings.show_hints = on
    ))

    var ai_panel := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 10, 12)
    var ai_box := AstraUI.vbox(8)
    ai_panel.add_child(ai_box)
    ai_box.add_child(AstraUI.label("AI 대사 연기 (선택 사항)", 16, AstraUI.CYAN))
    ai_box.add_child(AstraUI.label("backend/README.md의 로컬 서버를 켠 경우에만 사용하세요. 꺼져 있어도 모든 기능이 규칙 기반 대사로 동작합니다. AI는 대사 표현만 바꾸고 사건의 진실·점수에는 관여하지 않습니다.", 12, AstraUI.MUTED, true))
    ai_box.add_child(_toggle_row("AI 연기 사용", settings.ai_enabled, func(on: bool):
        settings.ai_enabled = on
    ))
    var endpoint := LineEdit.new()
    endpoint.text = settings.ai_endpoint
    endpoint.add_theme_font_size_override("font_size", 14)
    endpoint.text_changed.connect(func(text: String):
        settings.ai_endpoint = text
        ai_client.endpoint = text
    )
    ai_box.add_child(endpoint)
    var check_row := AstraUI.hbox(8)
    ai_box.add_child(check_row)
    var status := AstraUI.label(ai_status, 13, AstraUI.MUTED, true)
    var check := AstraUI.button("연결 확인", AstraUI.CYAN, 14, 36)
    check.pressed.connect(func():
        status.text = "확인 중…"
        ai_client.endpoint = settings.ai_endpoint
        ai_client.check_health()
    )
    var on_health := func(ok: bool, detail: String) -> void:
        ai_status = detail
        if is_instance_valid(status):
            status.text = detail
            status.add_theme_color_override("font_color", AstraUI.GREEN if ok else AstraUI.RED)
    ai_client.health_checked.connect(on_health, CONNECT_ONE_SHOT)
    check_row.add_child(check)
    check_row.add_child(status)
    box.add_child(ai_panel)

    var reset := AstraUI.button("조사 기록 초기화…", AstraUI.RED, 14, 38)
    reset.pressed.connect(_confirm_reset)
    box.add_child(reset)
    var on_close := func(_choice: int) -> void:
        settings.save_data()
    AstraModal.open(_overlay_root, "설정", box, [["저장하고 닫기", AstraUI.CYAN]], on_close, 640.0)

func _confirm_reset() -> void:
    var body := AstraUI.label("해금한 사건, 최고 기록, 통찰이 모두 지워집니다. 되돌릴 수 없습니다.", 16, AstraUI.TEXT, true)
    var handler := func(choice: int) -> void:
        if choice == 1:
            meta.reset()
            meta.save_data()
            fx.toast("조사 기록을 초기화했습니다.", AstraUI.RED)
            show_title()
    AstraModal.open(_overlay_root, "기록을 초기화할까요?", body, [["취소", AstraUI.MUTED], ["초기화", AstraUI.RED]], handler, 520.0)

func show_pause_menu() -> void:
    if session == null or modal_open():
        return
    var box := AstraUI.vbox(10)
    var buttons := [
        ["계속하기", AstraUI.CYAN, Callable()],
        ["플레이 방법", AstraUI.MUTED, show_help],
        ["설정", AstraUI.MUTED, show_settings],
        ["이 사건 처음부터 (새 배치)", AstraUI.GOLD, func(): start_case(session.case_id, session.protocol)],
        ["아카이브로 나가기", AstraUI.RED, show_title]
    ]
    var modal_holder := []
    for spec in buttons:
        var button := AstraUI.button(str(spec[0]), spec[1], 17, 50)
        var action: Callable = spec[2]
        button.pressed.connect(func():
            if not modal_holder.is_empty() and is_instance_valid(modal_holder[0]):
                modal_holder[0].close(-1)
            if action.is_valid():
                action.call()
        )
        box.add_child(button)
    box.add_child(AstraUI.label("진행 중인 사건은 저장되지 않습니다. 아카이브에는 끝까지 조사한 사건만 기록됩니다.", 12, AstraUI.DIM, true))
    modal_holder.append(AstraModal.open(_overlay_root, "일시 정지", box, [], Callable(), 420.0))

func _slider_row(title: String, value: float, min_value: float, max_value: float, step: float, on_change: Callable) -> Control:
    var row := AstraUI.hbox(12)
    var name_label := AstraUI.label(title, 15, AstraUI.TEXT)
    name_label.custom_minimum_size = Vector2(170, 0)
    row.add_child(name_label)
    var slider := HSlider.new()
    slider.min_value = min_value
    slider.max_value = max_value
    slider.step = step
    slider.value = value
    slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(slider)
    var value_label := AstraUI.label(_format_value(value, max_value), 14, AstraUI.MUTED)
    value_label.custom_minimum_size = Vector2(56, 0)
    row.add_child(value_label)
    slider.value_changed.connect(func(new_value: float):
        value_label.text = _format_value(new_value, max_value)
        on_change.call(new_value)
    )
    return row

func _format_value(value: float, max_value: float) -> String:
    if max_value <= 1.0:
        return "%d%%" % int(round(value * 100.0))
    return "×%.2f" % value

func _toggle_row(title: String, value: bool, on_change: Callable) -> Control:
    var toggle := CheckButton.new()
    toggle.text = title
    toggle.button_pressed = value
    toggle.focus_mode = Control.FOCUS_NONE
    toggle.add_theme_font_size_override("font_size", 15)
    toggle.toggled.connect(func(on: bool): on_change.call(on))
    return toggle

func _first_run_seen() -> bool:
    return settings.intro_seen

func _first_run_prompt() -> void:
    settings.intro_seen = true
    settings.save_data()
    var body := AstraUI.label("ASTRA는 흔적과 알리바이를 맞춰 숨은 Null 두 명을 찾아내는 추리 게임입니다. 처음이라면 2분만 규칙을 읽어 보세요. 게임 중에도 Esc → 플레이 방법에서 다시 볼 수 있습니다.", 16, AstraUI.TEXT, true)
    var handler := func(choice: int) -> void:
        if choice == 1:
            show_help()
    AstraModal.open(_overlay_root, "관측자 프로그램에 오신 것을 환영합니다", body, [["바로 시작", AstraUI.MUTED], ["플레이 방법 보기", AstraUI.CYAN]], handler, 600.0)

# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    var key := event as InputEventKey
    if key.keycode == KEY_F11:
        settings.fullscreen = not settings.fullscreen
        settings.apply_display()
        settings.save_data()
        get_viewport().set_input_as_handled()
        return
    if modal_open():
        return
    if key.keycode == KEY_ESCAPE:
        if session != null:
            show_pause_menu()
            get_viewport().set_input_as_handled()
        return
    if _current is AstraGameScreen:
        if (_current as AstraGameScreen).handle_hotkey(key):
            get_viewport().set_input_as_handled()

# ---------------------------------------------------------------- optional AI performance

func request_ai_line(game: AstraGameSession, npc_id: String, intent: String, result: Dictionary) -> void:
    if not settings.ai_enabled or ai_client == null or ai_client.busy:
        return
    var lines: Array = result.get("lines", [])
    var rule_line := ""
    for line in lines:
        if str(line.get("speaker", "")) == npc_id:
            rule_line = str(line.get("text", ""))
    if rule_line == "":
        return
    var context := game.build_ai_context(npc_id, intent, rule_line)
    _ai_serial += 1
    var request_id := "%d-%s" % [_ai_serial, npc_id]
    _pending_ai[request_id] = {"session": game, "npc_id": npc_id, "context": context, "rule_line": rule_line}
    if not ai_client.request_action(ai_gateway.build_request_payload(context), request_id):
        _pending_ai.erase(request_id)

func _on_ai_action(request_id: String, action: Dictionary, success: bool, error_message: String) -> void:
    if not _pending_ai.has(request_id):
        return
    var pending: Dictionary = _pending_ai[request_id]
    _pending_ai.erase(request_id)
    var game: AstraGameSession = pending["session"]
    if game != session or not success:
        if error_message != "":
            ai_status = "AI 연결 실패 · " + error_message
        return
    var context: Dictionary = pending["context"]
    var refs: Array[String] = []
    for ref in context.get("allowed_fact_refs", []):
        refs.append(str(ref))
    var targets: Array[String] = []
    for target in context.get("allowed_target_ids", []):
        targets.append(str(target))
    if ai_gateway.validate_action(action, refs, targets):
        game.apply_ai_line(str(pending["npc_id"]), str(pending["rule_line"]), str(action.get("utterance", "")))
        ai_status = "AI 연기 적용됨"
