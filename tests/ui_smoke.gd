extends SceneTree

# Drives the real 0.8.0 UI headlessly: fresh start → opening → Stage 1 morning
# → conversation by clicking a face → meeting moments → vote → isolation
# scene → night → Day 2 → result → next Stage; plus title slots, resume,
# notebook, glossary and the pause menu. Counts the clicks a player needs.
#   godot --headless --path . --script res://tests/ui_smoke.gd

const META_PATH := "user://astra_smoke_meta.cfg"
const SETTINGS_PATH := "user://astra_smoke_settings.cfg"

var app
var failures: Array[String] = []
var clicks: int = 0
var clicks_to_first_choice: int = -1
var clicks_to_first_vote: int = -1

func _initialize() -> void:
    _run.call_deferred()

func _wait(frames: int = 3) -> void:
    for _i in range(frames):
        await process_frame

func _expect(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)
        printerr("UI SMOKE FAIL · " + label)

func _screen() -> AstraGameScreen:
    return app._current as AstraGameScreen

func _view():
    return _screen()._view if _screen() != null else null

func _click() -> void:
    clicks += 1

func _run() -> void:
    for path in [META_PATH, SETTINGS_PATH]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    for slot in range(3):
        AstraGameSession.delete_snapshot(app.meta.save_path + ".session%d" % slot)
    root.add_child(app)
    await _wait(5)
    # 0.8.0: a new campaign starts with 탐사요원 등록 (one confirm).
    _expect(app._current is AstraPlayerSetup, "a fresh profile starts with explorer registration")
    if app._current is AstraPlayerSetup:
        _click()
        app._current.confirmed.emit({"name": "", "preset": "p1"})
        await _wait(5)
    _expect(app._current is AstraOpeningView, "registration leads into the opening scene")
    # Opening: three beats, one click each.
    for i in range(3):
        _click()
        app._current._stage.finish_typing()
        app._current._advance()
        await _wait(2)
    await _wait(3)
    _expect(_screen() != null, "opening leads straight into Stage 1")
    var s: AstraGameSession = app.session
    _expect(s.case_id == "CALIBRATION" and s.day == 1 and s.active_roster().size() == 4, "fresh start is Stage 1 Day 1 with four crew")
    _expect(s.phase == "BRIEFING", "Stage 1 opens on the morning scene")
    # Morning: click through every beat.
    var guard := 0
    while s.phase == "BRIEFING" and guard < 80:
        guard += 1
        _click()
        var view = _view()
        if view != null and view.has_method("consume_advance"):
            view._stage.finish_typing()
            view.consume_advance()
        await _wait(2)
    await _wait(3)
    _expect(s.phase == "INTERROGATION", "morning ends in conversation without a start button")
    clicks_to_first_choice = clicks
    # Conversation: one click on a face starts talking.
    var talk = _view()
    var first := str(s.talk_leads().keys()[0]) if not s.talk_leads().is_empty() else str(s.living_ids()[0])
    _click()
    talk._on_person(first)
    await _wait(3)
    _expect(s.conversation_open(first), "one click on a face opens the conversation")
    var options := s.question_options(first)
    if not options.is_empty():
        _click()
        talk._ask(str(options[0]["intent"]), str(options[0].get("ref", "")))
        await _wait(2)
    for npc_id in s.living_ids():
        if s.conversations_left() <= 0:
            break
        if not s.conversation_open(str(npc_id)):
            _click()
            talk._on_person(str(npc_id))
            await _wait(2)
    _screen().open_notebook()
    await _wait(2)
    _expect(app.modal_open(), "notebook opens")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    await _wait(2)
    _screen().open_glossary()
    await _wait(2)
    _expect(app.modal_open(), "glossary opens")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    await _wait(2)
    _click()
    _screen().advance_phase()
    await _wait(4)
    _expect(s.phase == "MEETING", "conversation → meeting")
    var meeting = _view()
    _click()
    meeting._reveal_all()
    await _wait(2)
    var moment_options := s.meeting_options()
    _expect(moment_options.size() >= 1 and moment_options.size() <= 4, "meeting pauses with a few options")
    guard = 0
    while not s.meeting_over() and guard < 10:
        guard += 1
        _click()
        meeting._continue()
        await _wait(2)
        meeting._reveal_all()
    _click()
    _screen().advance_phase()
    await _wait(4)
    _expect(s.phase == "VOTE", "meeting → vote")
    clicks_to_first_vote = clicks
    var vote = _view()
    var target := str(s.eligible_vote_targets()[0])
    _click()
    vote._choice = target
    vote.refresh()
    _click()
    vote._on_confirm()
    await _wait(2)
    vote.consume_advance()
    await _wait(2)
    guard = 0
    while s.vote_stage() in ["RUNOFF", "TIEBREAK"] and not s.vote_cast and guard < 4:
        guard += 1
        vote._mode = "choose"
        vote._choice = str(s.runoff_candidates()[0])
        vote._on_confirm()
        await _wait(2)
        vote.consume_advance()
        await _wait(2)
    _expect(s.vote_cast, "one vote isolates someone")
    _click()
    _screen().advance_phase()
    await _wait(4)
    _expect(s.phase in ["BRIEFING", "RESULT"], "Part I night resolves on its own into the next morning or the result")
    # Play the rest of Stage 1 through the UI-facing session calls.
    guard = 0
    while s.phase != "RESULT" and guard < 80:
        guard += 1
        match s.phase:
            "BRIEFING":
                s.story_skip()
                await _wait(2)
            "INTERROGATION":
                _screen().advance_phase()
            "MEETING":
                s._finish_meeting()
                _screen().advance_phase()
            "VOTE":
                s.cast_vote(str(s.eligible_vote_targets()[0]))
                if s.vote_stage() == "RUNOFF": s.cast_vote(str(s.runoff_candidates()[0]))
                if s.vote_stage() == "TIEBREAK": s.resolve_tiebreak(str(s.runoff_candidates()[0]))
                _screen().advance_phase()
            "NIGHT":
                s.choose_night_action("skip", "")
                _screen().advance_phase()
        await _wait(2)
    _expect(s.phase == "RESULT", "Stage 1 reaches a result")
    guard = 0
    while not s.story_finished() and guard < 30:
        guard += 1
        if not Array(s.story_scene().get("choices", [])).is_empty():
            s.story_choose(0)
        else:
            s.story_skip()
        await _wait(2)
    await _wait(3)
    _expect(_view() != null and _view()._shown_summary, "result shows containment and story panels after the scenes")

    # Title: slots, resume, delete.
    app.show_title()
    await _wait(3)
    _expect(app._current is AstraTitleScreen, "title screen")
    # Archive uses slot-scoped progress and the core protocol list.
    app.active_slot = 1
    var archive_memory: Dictionary = app.meta.voyage_memory_for_slot(1)
    archive_memory["chapters"] = AstraCaseCatalog.STAGE_ORDER.slice(0, 4)
    app.meta.set_voyage_memory_for_slot(1, archive_memory)
    app.show_archive()
    await _wait(3)
    _expect(app._current is AstraArchiveScreen, "Archive screen instantiates")
    var archive: AstraArchiveScreen = app._current
    archive._select_case("SILENT_ORBIT")
    await _wait(2)
    _expect(app.selected_protocol == "GUARDIAN" and not archive._protocol_row.visible, "Stage 5 auto-selects its single Guardian protocol")
    archive._select_case("RED_SHIFT")
    await _wait(2)
    var stage6_names: Array = []
    for child in archive._protocol_row.get_children():
        stage6_names.append(str(child.name))
    _expect("Protocol_GUARDIAN" in stage6_names and "Protocol_ANALYST" in stage6_names, "Stage 6 offers Guardian and Analyst")
    _expect("Protocol_EMPATH" not in stage6_names and "Protocol_AUDITOR" not in stage6_names, "Stage 6 hides locked and legacy protocols")
    archive._select_case("LAST_LIGHT")
    await _wait(2)
    var stage7_names: Array = []
    for child in archive._protocol_row.get_children():
        stage7_names.append(str(child.name))
    _expect("Protocol_GUARDIAN" in stage7_names and "Protocol_ANALYST" in stage7_names and "Protocol_EMPATH" in stage7_names, "Stage 7+ uses all authoritative protocols")
    _expect("Protocol_AUDITOR" not in stage7_names, "AUDITOR is never player-facing")
    archive._select_case("RED_SHIFT")
    await _wait(2)
    app.selected_protocol = "ANALYST"
    archive._start_selected()
    await _wait(3)
    _expect(app.session != null and app.session.case_id == "RED_SHIFT" and app.session.protocol == "ANALYST", "Archive starts the selected Stage with the selected protocol in the active slot")
    app.show_title()
    await _wait(2)

    # A slot that has cleared Part I opens Stage 5 (slot-scoped progress).
    var memory: Dictionary = app.meta.voyage_memory_for_slot(1)
    memory["chapters"] = AstraCaseCatalog.STAGE_ORDER.slice(0, 4)
    app.meta.set_voyage_memory_for_slot(1, memory)
    _expect(not app.meta.is_case_unlocked_for_slot("SILENT_ORBIT", 2), "another slot does not inherit progress")
    app.start_case("SILENT_ORBIT", "GUARDIAN", 1)
    await _wait(3)
    var s5: AstraGameSession = app.session
    _expect(s5.protocol == "GUARDIAN", "Stage 5 equips Guardian")
    s5.story_skip()
    await _wait(3)
    _expect(s5.phase == "INTERROGATION", "Stage 5 morning plays through")
    app.show_title()
    await _wait(3)
    app.resume_case(1)
    await _wait(3)
    _expect(app.session != null and app.session.case_id == "SILENT_ORBIT" and app.session.phase == "INTERROGATION", "resume restores the Stage and phase")
    app.show_pause_menu()
    await _wait(2)
    _expect(app.modal_open(), "pause menu opens")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    await _wait(2)
    app.show_title()
    await _wait(2)
    for slot in range(3):
        AstraGameSession.delete_snapshot(app.slot_path(slot))
    for path in [META_PATH, SETTINGS_PATH]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("UI CLICKS · first meaningful choice after %d clicks · first vote after %d clicks" % [clicks_to_first_choice, clicks_to_first_vote])
    if failures.is_empty():
        print("ASTRA UI SMOKE OK")
    else:
        printerr("ASTRA UI SMOKE FAILED · %d" % failures.size())
    root.remove_child(app)
    app.free()
    quit(0 if failures.is_empty() else 1)
