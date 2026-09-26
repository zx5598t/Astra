extends SceneTree

# 1.0.1 UI release gate (headless). Drives the real screens at the official
# minimum 1120x700 plus 1280x720, 1366x768, 1600x900, 1920x1080 and
# 2560x1440 with synthetic long Korean lines (test
# fixture only, never saved) and checks what a player would otherwise fight:
#   * the last conversation / meeting line is fully inside its viewport
#     without touching the wheel, with room under it;
#   * a reader scrolled back up is not yanked down (a "새 발언" chip shows);
#   * "끝까지 보기" lands on the last line;
#   * wrapped buttons are tall enough for their text (no clipped 2nd line);
#   * nothing outside a scroll area leaves the window; no zero-height text;
#   * the vote's candidates and confirm button are reachable.
#   godot --headless --path . --script res://tests/ui_layout_100.gd

const META_PATH := "user://astra_layout_meta.cfg"
const SETTINGS_PATH := "user://astra_layout_settings.cfg"
const LONG := "이건 일부러 길게 만든 확인용 문장입니다. 보안문 기록은 21시 14분에 안쪽에서 열렸고, 그 시간에 수목구역에 있었다는 말과 함께 놓으면 두 말은 동시에 맞을 수 없습니다. 괄호(시험용)와 숫자 1366×768, 긴 이름 아스트라탐사요원도 섞어 둡니다."

var app
var failures: Array = []
var checks := 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("FAIL · " + label)

func _initialize() -> void:
    _run.call_deferred()

func _wait(frames: int = 4) -> void:
    for _i in range(frames):
        await process_frame

func _run() -> void:
    for path in [META_PATH, SETTINGS_PATH]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    await _selection_minimum()
    for resolution in [Vector2i(1120, 700), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440)]:
        await _pass(resolution)
    await _minigames_minimum()
    await _resize_roundtrip()
    await _rewind_flow()
    if failures.is_empty():
        print("ASTRA UI LAYOUT 100 OK · %d checks" % checks)
        quit()
    else:
        print("ASTRA UI LAYOUT 100 FAILED · %d/%d" % [failures.size(), checks])
        quit(1)

func _selection_minimum() -> void:
    root.size = Vector2i(1120, 700)
    var setup := AstraPlayerSetup.new()
    root.add_child(setup)
    setup.setup(AstraExplorerCatalog.profile_for("serin"))
    await _wait(5)
    _buttons_fit(setup, "1120x700: explorer selection")
    _inside(setup, Vector2i(1120, 700), "1120x700: explorer selection")
    var start := setup.find_child("StartButton", true, false) as Button
    check(start != null and start.is_visible_in_tree(), "1120x700: explorer confirm visible")
    for tex_node in setup.find_children("*", "TextureRect", true, false):
        var rect := tex_node as TextureRect
        if rect.texture == null:
            continue
        var path := rect.texture.resource_path
        if rect.texture is AtlasTexture:
            path = (rect.texture as AtlasTexture).atlas.resource_path
        check(not path.contains("/pixel") and not path.contains("pixel080"), "1120x700: selection uses no pixel preview")
    setup.queue_free()
    await _wait(3)

func _minigames_minimum() -> void:
    root.size = Vector2i(1120, 700)
    var tasks: Array = []

    var signal := AstraSignalTrace.new()
    root.add_child(signal)
    signal.setup(101, [], 0.05, "소렌")
    tasks.append(["signal", signal])

    var circuit := AstraPowerRoute.new()
    root.add_child(circuit)
    circuit.setup(202, "준")
    circuit.visible = false
    tasks.append(["circuit", circuit])

    var timeline := AstraOrderTask.new()
    root.add_child(timeline)
    timeline.setup(303, AstraInterludes.data("second_watch_logs")["task"], "노아")
    timeline.visible = false
    tasks.append(["timeline", timeline])

    var route := AstraFieldTask.new()
    root.add_child(route)
    route.setup(404, AstraInterludes.data("blind_deck_door")["task"])
    route.visible = false
    tasks.append(["route", route])

    for pair in tasks:
        var name := str(pair[0])
        var task := pair[1] as AstraShipTask
        for other in tasks:
            (other[1] as AstraShipTask).visible = false
        task.visible = true
        await _wait(4)
        _buttons_fit(task, "1120x700: task " + name)
        _inside(task, Vector2i(1120, 700), "1120x700: task " + name)
        check(task._action != null and Rect2(Vector2.ZERO, Vector2(1120, 700)).encloses(task._action.get_global_rect().grow(-1)), "1120x700: task %s confirm visible" % name)
    for pair in tasks:
        (pair[1] as AstraShipTask).queue_free()
    await _wait(3)

func _pass(resolution: Vector2i) -> void:
    root.size = resolution
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(4)
    app.session = AstraGameSession.new()
    var s: AstraGameSession = app.session
    s.setup("GLASS_GARDEN", 6161)
    s.set_player_profile(AstraExplorerCatalog.profile_for("serin"))
    app.show_session_screen()
    await _wait(6)
    var tag := "%dx%d" % [resolution.x, resolution.y]
    var guard := 0
    while s.phase == "BRIEFING" and guard < 5:
        guard += 1
        AstraTestBots._finish_morning(s)
        await _wait(4)
        if s.phase == "BRIEFING":
            s.advance()
    await _wait(4)
    # ---- conversation
    var view = app._current._view
    check(s.phase == "INTERROGATION", tag + ": conversation")
    var npc := str(s.living_ids()[0])
    view._on_person(npc)
    await _wait(3)
    for i in range(3):
        s.transcripts[npc].append({"day": s.day, "speaker": npc, "text": LONG})
    s.transcripts[npc].append({"day": s.day, "speaker": "player", "text": LONG})
    view.refresh()
    await _wait(5)
    _last_visible(view._log_scroll, view._log, tag + ": conversation last line")
    _buttons_fit(app._current, tag + ": conversation")
    _inside(app._current, resolution, tag + ": conversation")
    # ---- meeting
    s.advance()
    await _wait(4)
    view = app._current._view
    check(s.phase == "MEETING", tag + ": meeting")
    for i in range(4):
        s._feed_line(npc, "", LONG, "dispute", "anchor", "layout")
    view._reveal_all()
    await _wait(5)
    _last_visible(view._feed_scroll, view._feed, tag + ": meeting after 끝까지 보기")
    # Reading back: scroll to the top, a new line must not pull the view down.
    view._feed_scroll.scroll_vertical = 0
    await _wait(2)
    var bar: VScrollBar = view._feed_scroll.get_v_scroll_bar()
    bar.value_changed.emit(bar.value)
    s._feed_line(npc, "", LONG, "dispute", "anchor", "layout2")
    view._timer.stop()
    view._reveal_next()
    await _wait(5)
    check(view._feed_scroll.scroll_vertical <= 2, tag + ": reading back is not interrupted")
    check(view._new_chip.visible, tag + ": a '새 발언' chip shows instead")
    view._new_chip.pressed.emit()
    await _wait(5)
    _last_visible(view._feed_scroll, view._feed, tag + ": the chip brings the last line into view")

    # Race regression: start at bottom, append a long line (which queues a
    # two-frame follow), then wheel/read back after the first frame. The queued
    # follow must be cancelled and the unread-line chip must appear.
    s._feed_line(npc, "", LONG + " · race", "dispute", "anchor", "layout-race")
    view._timer.stop()
    view._reveal_next()
    await process_frame
    view._feed_scroll.scroll_vertical = 0
    var race_bar: VScrollBar = view._feed_scroll.get_v_scroll_bar()
    race_bar.value_changed.emit(race_bar.value)
    await _wait(4)
    check(view._feed_scroll.scroll_vertical <= 2, tag + ": mid-await user scroll cancels queued follow")
    check(not AstraUI.is_following(view._feed_scroll), tag + ": mid-await scroll leaves follow disabled")
    check(view._new_chip.visible, tag + ": mid-await scroll shows the new-line chip")
    view._new_chip.pressed.emit()
    await _wait(5)
    _last_visible(view._feed_scroll, view._feed, tag + ": race chip returns to the full last line")
    _buttons_fit(app._current, tag + ": meeting actions")
    _inside(app._current, resolution, tag + ": meeting")
    # the link picker, both steps
    view._picker = "link_statement"
    view._render_actions()
    await _wait(3)
    _buttons_fit(app._current, tag + ": link statement picker")
    _inside(app._current, resolution, tag + ": link statement picker")
    var statements := s.link_statements()
    if not statements.is_empty():
        view._link_statement = str(statements[0]["ref"])
        view._picker = "link_evidence"
        view._render_actions()
        await _wait(3)
        _buttons_fit(app._current, tag + ": link evidence picker")
        _inside(app._current, resolution, tag + ": link evidence picker")
    view._picker = ""
    if resolution == Vector2i(1120, 700):
        app._current.open_glossary()
        await _wait(3)
        check(app.modal_open(), tag + ": glossary opens at minimum size")
        _buttons_fit(app.overlay_root(), tag + ": glossary")
        _inside(app.overlay_root(), resolution, tag + ": glossary")
        for child in app.overlay_root().get_children():
            if child.has_method("close"):
                child.close(-1)
        await _wait(2)
    s._finish_meeting()
    s.advance()
    await _wait(5)
    # ---- vote
    view = app._current._view
    check(s.phase == "VOTE", tag + ": vote")
    var target := str(s.eligible_vote_targets()[0])
    view._choice = target
    view.refresh()
    await _wait(4)
    _buttons_fit(app._current, tag + ": vote reasons")
    var screen := Rect2(Vector2.ZERO, Vector2(resolution))
    check(screen.encloses(view._confirm.get_global_rect().grow(-1)), tag + ": the confirm button is on screen")
    _inside(app._current, resolution, tag + ": vote")
    app.queue_free()
    await _wait(3)

func _resize_roundtrip() -> void:
    root.size = Vector2i(1920, 1080)
    for path in [META_PATH, SETTINGS_PATH]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(5)
    app.session = AstraGameSession.new()
    var s: AstraGameSession = app.session
    s.setup("GLASS_GARDEN", 7711)
    s.set_player_profile(AstraExplorerCatalog.profile_for("serin"))
    app.show_session_screen()
    await _wait(5)
    var guard := 0
    while s.phase == "BRIEFING" and guard < 5:
        guard += 1
        AstraTestBots._finish_morning(s)
        await _wait(3)
        if s.phase == "BRIEFING":
            s.advance()
    await _wait(4)
    check(s.phase == "INTERROGATION", "resize: reached conversation")

    root.size = Vector2i(1120, 700)
    await _wait(8)
    _buttons_fit(app._current, "resize 1920→1120")
    _inside(app._current, Vector2i(1120, 700), "resize 1920→1120")

    root.size = Vector2i(1920, 1080)
    await _wait(8)
    _buttons_fit(app._current, "resize 1120→1920")
    _inside(app._current, Vector2i(1920, 1080), "resize 1120→1920")

    app.queue_free()
    await _wait(3)

# The real app path: a morning is kept, a lost Stage offers the rewind, the
# rewind restores the same truth with the explorer's memory, once.
func _rewind_flow() -> void:
    root.size = Vector2i(1366, 768)
    for path in [META_PATH, SETTINGS_PATH]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(4)
    app.meta.slot_intro_seen["0"] = true
    app.meta.set_player_profile_for_slot(0, AstraExplorerCatalog.profile_for("logan"))
    AstraGameSession.delete_snapshot(app.slot_path(0))
    DirAccess.remove_absolute(ProjectSettings.globalize_path(app.slot_path(0) + ".dawn.key"))
    app.start_case("CALIBRATION", "NONE", 0)
    await _wait(6)
    var s: AstraGameSession = app.session
    check(s != null and s.case_id == "CALIBRATION", "rewind flow: the Stage starts")
    check(FileAccess.file_exists(app.dawn_path()), "rewind flow: the morning is kept aside")
    var truth: Dictionary = s.truth.duplicate(true)
    var guard := 0
    while s.phase == "BRIEFING" and guard < 5:
        guard += 1
        AstraTestBots._finish_morning(s)
        await _wait(4)
        if s.phase == "BRIEFING":
            s.advance()
    for npc_id in s.living_ids():
        if s.conversations_left() > 0:
            s.ask(str(npc_id), "STATEMENT")
    s.outcome = "LOSE"
    s.stage_state()["outcome_reason"] = "player_killed"
    s._enter("RESULT")
    await _wait(4)
    check(app.can_rewind(), "rewind flow: a lost Stage offers the rewind")
    app.rewind_to_dawn()
    await _wait(6)
    var r: AstraGameSession = app.session
    check(r != s and r.phase == "BRIEFING" and r.day == 1, "rewind flow: back to the morning")
    check(r.truth == truth, "rewind flow: the same truth")
    check(r.rewinds_used() == 1 and not r.rewind_notes().is_empty(), "rewind flow: memories carried, rewind counted")
    r.outcome = "LOSE"
    r.stage_state()["outcome_reason"] = "null_control"
    check(not app.can_rewind(), "rewind flow: only once per Stage")
    app.queue_free()
    await _wait(3)

func _last_visible(scroll: ScrollContainer, list: VBoxContainer, label: String) -> void:
    var last: Control = null
    for child in list.get_children():
        if child is Control and (child as Control).visible and str(child.name) != "BottomPad":
            last = child
    check(last != null, label + ": has lines")
    if last == null:
        return
    var view_rect := scroll.get_global_rect()
    var line_rect := last.get_global_rect()
    check(line_rect.end.y <= view_rect.end.y + 1.0, label + ": bottom inside (line %.0f, view %.0f)" % [line_rect.end.y, view_rect.end.y])
    check(line_rect.size.y <= view_rect.size.y or line_rect.position.y <= view_rect.end.y, label + ": visible")
    var pad := list.get_node_or_null("BottomPad")
    check(pad != null and list.get_children().back() == pad, label + ": room under the last line")

func _buttons_fit(node: Node, label: String) -> void:
    for button in node.find_children("*", "Button", true, false):
        var b := button as Button
        if not b.is_visible_in_tree() or not b.has_meta("label"):
            continue
        var text_label := b.get_meta("label") as Label
        var need := text_label.get_minimum_size().y
        check(b.size.y + 0.5 >= need + 8.0, label + ": a wrapped button is tall enough (%.0f for %.0f)" % [b.size.y, need])

func _inside(node: Node, resolution: Vector2i, label: String) -> void:
    var screen := Rect2(Vector2(-1, -1), Vector2(resolution) + Vector2(2, 2))
    for child in node.find_children("*", "Control", true, false):
        var c := child as Control
        if not c.is_visible_in_tree() or _in_scroll(c) or c.get_global_rect().size == Vector2.ZERO:
            continue
        if c is Label or c is Button:
            check(screen.encloses(c.get_global_rect()), label + ": %s inside the window" % c.name)
        if c is Label and (c as Label).text != "":
            check(c.size.y > 0.0, label + ": text has height")

func _in_scroll(c: Node) -> bool:
    var p := c.get_parent()
    while p != null:
        if p is ScrollContainer:
            return true
        p = p.get_parent()
    return false
