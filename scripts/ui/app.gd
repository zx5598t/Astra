extends Control

# Application root: background, screen routing, overlays and persistence.

const VERSION_FALLBACK := "0.5.0"

var meta := AstraMetaProgress.new()
var settings := AstraSettings.new()
var ai_gateway := AIGateway.new()
var fx: AstraFeedbackFX
var ai_client: AstraRemoteAIClient
var selected_protocol: String = "ANALYST"
var session: AstraGameSession
var ai_status: String = ""
var active_slot: int = 0

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
    AstraUI.reading_scale = 1.1 if settings.large_text else 1.0
    AstraUI.reduce_motion = settings.reduced_motion
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

    # A brand new install goes straight into the cold open. Everything else —
    # difficulty, protocol, case choice — is asked later or not at all, because
    # none of it means anything to someone who has not seen the ship yet (§8).
    if not settings.intro_seen:
        show_opening()
    else:
        show_title()

func show_opening() -> void:
    var opening := AstraOpeningView.new()
    _set_screen(opening)
    opening.setup(self)
    opening.finished.connect(func():
        settings.intro_seen = true
        settings.save_data()
        start_case(AstraCaseCatalog.CALIBRATION, "ANALYST")
    , CONNECT_ONE_SHOT)

# The only question asked before play, and it has two answers. 0.3.1 opened on a
# screen with difficulty, protocol and six cases on it; none of those are
# answerable by someone who has not played yet (§24).
func _ask_experience() -> void:
    show_title()
    var body := AstraUI.vbox(8)
    body.add_child(AstraUI.prose("진행 속도를 정합니다. 나중에 설정에서 언제든 바꿀 수 있습니다.", AstraUI.T_BODY, AstraUI.TEXT))
    var handler := func(choice: int) -> void:
        meta.difficulty_mode = "STANDARD" if choice == 1 else "STORY"
        meta.save_data()
    AstraModal.open(_overlay_root, "사회추리 게임은 처음이신가요?", body,
        [["처음입니다", AstraUI.CYAN], ["익숙합니다", AstraUI.MUTED]], handler, 560.0)

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
    _save_session()
    session = null
    var title := AstraTitleScreen.new()
    _set_screen(title)
    title.setup(self)

func show_archive() -> void:
    var archive := AstraArchiveScreen.new()
    _set_screen(archive)
    archive.setup(self)

func start_case(case_id: String, protocol: String, slot: int = -1) -> void:
    if not meta.is_case_unlocked(case_id):
        fx.toast("아직 잠긴 사건입니다. " + meta.unlock_hint(case_id), AstraUI.GOLD)
        return
    # A new case takes the slot it was asked for, the first free one, or — when
    # all three are full — whichever the caller already had open.
    if slot >= 0:
        active_slot = clampi(slot, 0, SLOT_COUNT - 1)
    else:
        var free_slot := first_free_slot()
        if free_slot >= 0:
            active_slot = free_slot
    selected_protocol = protocol
    session = AstraGameSession.new()
    var seed_value := int(Time.get_unix_time_from_system() * 1000.0) % 2147483
    # The archive's memory of recent Null assignments goes in, so the role does
    # not settle on one face over a run of cases (§67).
    session.setup(case_id, seed_value, protocol, meta.difficulty_mode, meta.recent_null_history())
    session.features = meta.unlocked_features()
    session.set_tutorial(false)
    session.begin_voyage(meta.voyage_memory)
    _connect_autosave()
    show_session_screen()

func show_session_screen() -> void:
    if session.phase == "EXPLORE":
        var voyage_screen := AstraVoyageView.new()
        _set_screen(voyage_screen)
        voyage_screen.setup(self,session)
    else:
        var screen := AstraGameScreen.new()
        _set_screen(screen)
        screen.setup(self,session,fx)

# Anyone the player has not seen before gets one card before the case starts,
# one at a time. Eight dossiers at once is the thing that made 0.3.1's opening
# unreadable (§21, §64).
func _introduce_new_faces(game: AstraGameSession) -> void:
    var fresh := meta.unseen_people(game.roster)
    if fresh.is_empty():
        return
    _queue_intro_cards(fresh, game)

func _queue_intro_cards(queue: Array, game: AstraGameSession) -> void:
    if queue.is_empty():
        meta.save_data()
        return
    var npc_id := str(queue[0])
    var rest: Array = queue.slice(1)
    meta.meet_person(npc_id)
    var info := AstraCrewCatalog.info(npc_id)
    var card := AstraUI.intro_card(
        npc_id,
        AstraCrewCatalog.display_name(npc_id),
        str(info.get("job", "")),
        AstraStory.first_line(npc_id),
        AstraCrewCatalog.accent(npc_id)
    )
    var label := "다음 사람" if not rest.is_empty() else "시작"
    AstraModal.open(_overlay_root, "", card, [[label, AstraUI.CYAN]], func(_choice: int):
        _queue_intro_cards(rest, game)
    , 760.0)

# ---------------------------------------------------------------- save slots
#
# 0.3.1 had exactly one in-progress save, silently overwritten whenever a new
# case started — which is why the title screen had to warn about it. Three slots
# remove the warning and the fear: a player can leave a case half-finished and
# still try something else.

const SLOT_COUNT := 3
const LEGACY_SLOT_SUFFIX := ".session"

func slot_path(slot: int) -> String:
    return meta.save_path + ".session%d" % clampi(slot, 0, SLOT_COUNT - 1)

func snapshot_path() -> String:
    return slot_path(active_slot)

# One row per slot for the title screen, empty slots included so the player can
# see there are three of them.
func slot_infos() -> Array:
    _migrate_legacy_slot()
    var rows: Array = []
    for slot in range(SLOT_COUNT):
        var info := AstraGameSession.snapshot_info(slot_path(slot))
        rows.append({"slot": slot, "info": info, "empty": info.is_empty()})
    return rows

func first_free_slot() -> int:
    for row in slot_infos():
        if bool(row["empty"]):
            return int(row["slot"])
    return -1

func has_any_save() -> bool:
    for row in slot_infos():
        if not bool(row["empty"]):
            return true
    return false

# A 0.3.1 archive keeps its in-progress case at the old single-file path. It is
# moved into slot 1 the first time the title screen is drawn, so the player does
# not lose a case they were in the middle of.
func _migrate_legacy_slot() -> void:
    var legacy := meta.save_path + LEGACY_SLOT_SUFFIX
    if not FileAccess.file_exists(legacy):
        return
    var target := slot_path(0)
    if AstraGameSession.snapshot_info(legacy).is_empty() or not AstraGameSession.snapshot_info(target).is_empty():
        AstraGameSession.delete_snapshot(legacy)
        return
    DirAccess.copy_absolute(ProjectSettings.globalize_path(legacy), ProjectSettings.globalize_path(target))
    AstraGameSession.delete_snapshot(legacy)

func _connect_autosave() -> void:
    session.changed.connect(_save_session, CONNECT_DEFERRED)
    _save_session()

func _save_session() -> void:
    if session != null and session.phase != "RESULT":
        if not session.save_snapshot(snapshot_path()):
            fx.toast("진행 저장에 실패했습니다. 저장 폴더의 여유 공간을 확인하세요.", AstraUI.RED)

func resume_case(slot: int = -1) -> void:
    if slot >= 0:
        active_slot = clampi(slot, 0, SLOT_COUNT - 1)
    var restored := AstraGameSession.new()
    if not restored.load_snapshot(snapshot_path()):
        fx.toast("진행 기록을 불러올 수 없습니다. 새 사건을 시작하세요.", AstraUI.RED)
        return
    session = restored
    session.features = meta.unlocked_features()
    selected_protocol = session.protocol
    _connect_autosave()
    show_session_screen()

func record_result(finished: AstraGameSession) -> Dictionary:
    var memory := finished.voyage_memory()
    if not memory.is_empty():
        meta.voyage_memory = memory
    var before := meta.unlocked_features()
    var result := meta.record_case_result(finished.case_id, finished.protocol, finished.final_report, true)
    AstraGameSession.delete_snapshot(snapshot_path())
    result["new_features"] = AstraUnlocks.newly_unlocked(before, meta.unlocked_features())
    return result

# Shown after the result screen, one card each. A feature that appears with no
# explanation is a new button the player will not press; a feature that appears
# with only a rule is a chore. Both lines, every time (§35).
func show_unlock_cards(features: Array) -> void:
    if features.is_empty():
        return
    var feature := str(features[0])
    var rest: Array = features.slice(1)
    meta.mark_unlock_announced(feature)
    meta.save_data()
    var body := AstraUI.unlock_card(
        AstraUnlocks.title_of(feature),
        AstraUnlocks.blurb_of(feature),
        AstraUnlocks.flavor_of(feature)
    )
    AstraModal.open(_overlay_root, "새로 열렸습니다", body, [["확인", AstraUI.GOLD]], func(_choice: int):
        show_unlock_cards(rest)
    , 600.0)

func quit_game() -> void:
    _save_session()
    get_tree().quit()

# ---------------------------------------------------------------- overlays

func show_help() -> void:
    var box := AstraUI.vbox(18)
    box.add_child(AstraHelpPanel.codex(meta.unlocked_features()))
    box.add_child(AstraHelpPanel.shortcuts())
    AstraModal.open(_overlay_root, "기록 보관소 · 도움말", box, [["닫기", AstraUI.CYAN]], Callable(), 860.0)

# The [?] in the corner of a game screen: this screen only.
func show_screen_help(phase: String, objective: String) -> void:
    AstraModal.open(_overlay_root, AstraGameSession.PHASE_LABELS.get(phase, phase),
        AstraHelpPanel.screen_help(phase, objective), [["닫기", AstraUI.CYAN]], Callable(), 660.0)

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

    # ---- dialogue pacing -------------------------------------------------
    var pace := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 10, 12)
    var pace_box := AstraUI.vbox(8)
    pace.add_child(pace_box)
    pace_box.add_child(AstraUI.label("대사", AstraUI.T_HEAD, AstraUI.CYAN))
    pace_box.add_child(AstraUI.prose("기본은 직접 넘기기입니다. 자동을 켜도 중요한 대사에서는 멈춥니다.", AstraUI.T_META, AstraUI.MUTED))
    pace_box.add_child(_toggle_row("자동 진행", settings.auto_advance, func(on: bool):
        settings.auto_advance = on
    ))
    pace_box.add_child(_slider_row("자동 대기 시간", settings.auto_delay, 0.5, 3.0, 0.25, func(value: float):
        settings.auto_delay = value
    ))
    pace_box.add_child(_toggle_row("중요한 대사에서 멈추기", settings.pause_on_important, func(on: bool):
        settings.pause_on_important = on
    ))
    pace_box.add_child(_toggle_row("이미 읽은 대사 빠르게 넘기기", settings.skip_read_text, func(on: bool):
        settings.skip_read_text = on
    ))
    box.add_child(pace)

    # ---- difficulty ------------------------------------------------------
    if meta.has_feature("difficulty_select"):
        var mode_panel := AstraUI.panel(AstraUI.PANEL_2, AstraUI.BORDER, 10, 12)
        var mode_box := AstraUI.vbox(8)
        mode_panel.add_child(mode_box)
        mode_box.add_child(AstraUI.label("진행 속도", AstraUI.T_HEAD, AstraUI.CYAN))
        var detail := AstraUI.prose(AstraDifficulty.value(meta.difficulty_mode, "detail", ""), AstraUI.T_META, AstraUI.MUTED)
        var row := AstraUI.hbox(8)
        mode_box.add_child(row)
        for mode in AstraDifficulty.ORDER:
            var chosen: bool = meta.difficulty_mode == mode
            var pick := AstraUI.button(AstraDifficulty.mode_name(mode), AstraUI.GOLD if chosen else AstraUI.MUTED, AstraUI.T_UI, 40, chosen)
            pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            pick.tooltip_text = str(AstraDifficulty.value(mode, "summary", ""))
            pick.pressed.connect(func():
                meta.difficulty_mode = mode
                meta.save_data()
                detail.text = str(AstraDifficulty.value(mode, "detail", ""))
                for other in row.get_children():
                    (other as Button).add_theme_stylebox_override("normal", AstraUI.style(Color(AstraUI.MUTED, 0.12), Color(AstraUI.MUTED, 0.75), 8, 1, 10))
                pick.add_theme_stylebox_override("normal", AstraUI.style(Color(AstraUI.GOLD, 0.34), Color(AstraUI.GOLD, 0.75), 8, 1, 10))
            )
            row.add_child(pick)
        mode_box.add_child(detail)
        mode_box.add_child(AstraUI.prose("바뀐 속도는 다음 사건부터 적용됩니다.", AstraUI.T_META, AstraUI.DIM))
        box.add_child(mode_panel)

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
        AstraUI.reading_scale = 1.1 if settings.large_text else 1.0
        AstraUI.reduce_motion = settings.reduced_motion
    box.add_child(_toggle_row("큰 글자 (다음 화면부터)", settings.large_text, func(on: bool): settings.large_text = on))
    box.add_child(_toggle_row("흔들림·번쩍임 줄이기", settings.reduced_motion, func(on: bool): settings.reduced_motion = on))
    var scroll := AstraUI.scroll(box)
    scroll.custom_minimum_size.y = 490
    AstraModal.open(_overlay_root, "설정", scroll, [["저장하고 닫기", AstraUI.CYAN]], on_close, 680.0)

func _confirm_reset() -> void:
    var body := AstraUI.label("해금한 사건, 최고 기록, 통찰이 모두 지워집니다. 되돌릴 수 없습니다.", 16, AstraUI.TEXT, true)
    var handler := func(choice: int) -> void:
        if choice == 1:
            AstraGameSession.delete_snapshot(snapshot_path())
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
    box.add_child(AstraUI.label("진행 상황은 행동할 때마다 자동 저장됩니다. 타이틀의 ‘계속하기’로 돌아올 수 있습니다.", 12, AstraUI.DIM, true))
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
    var body := AstraUI.label("ASTRA의 탐사요원으로서 동료들과 배를 살펴봅니다. 위쪽의 현재 목표를 따라가거나, 궁금한 사람과 장소부터 확인하세요.", 16, AstraUI.TEXT, true)
    var handler := func(choice: int) -> void:
        if choice == 1:
            show_help()
    AstraModal.open(_overlay_root, "탐사요원 프로그램에 오신 것을 환영합니다", body, [["바로 시작", AstraUI.MUTED], ["플레이 방법 보기", AstraUI.CYAN]], handler, 600.0)

# ---------------------------------------------------------------- input

func _input(event: InputEvent) -> void:
    # Space always advances the case, even after a button was clicked.
    # Enter remains the standard keyboard activation for a focused button.
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
        if _current is AstraGameScreen and not modal_open():
            _current.handle_hotkey(event)
            get_viewport().set_input_as_handled()

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
