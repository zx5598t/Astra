extends SceneTree
# Rendered checks with isolated saves; never changes player data.
var app
var suffix := ""
func _initialize() -> void:
    _run.call_deferred()
func _wait(n: int = 5) -> void:
    for i in n:
        await process_frame
# The 0.4.0 tutorial will not let you leave a phase half-finished, so the capture
# run has to actually play it out before asking for the next screen.
func _finish_phase() -> void:
    var s: AstraGameSession = app.session
    var guard := 0
    while not s.can_advance() and guard < 40:
        guard += 1
        var acted := false
        match s.phase:
            "INVESTIGATION":
                for room_id in s.room_ids():
                    for point in s.investigation_points(room_id):
                        if bool(point.get("available", false)) and not acted:
                            s.inspect_point(room_id, str(point["id"]))
                            acted = true
            "INTERROGATION":
                if not s.pending_event.is_empty():
                    s.resolve_private_event(0)
                    acted = true
                else:
                    for npc_id in s.living_ids():
                        if not s.known_claims.has(npc_id) and s.talk_ap > 0 and not acted:
                            s.ask(npc_id, "ALIBI")
                            acted = true
        if not acted:
            break

func _flush_view() -> void:
    if app._current != null and app._current.get("_view") != null and app._current._view.has_method("_flush"):
        app._current._view._flush()

func _capture(file: String) -> void:
    await create_timer(1.8).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/qa/"+file+suffix+".png")
    print("CAPTURE "+file+suffix)
func _run() -> void:
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://astra_visual_meta.cfg")
    app.settings = AstraSettings.new("user://astra_visual_settings.cfg")
    # Start from a clean archive every time: a leftover file from an aborted run
    # would be re-read by _ready() and silently undo the state set here.
    for stale in ["user://astra_visual_meta.cfg", "user://astra_visual_settings.cfg"]:
        if FileAccess.file_exists(stale):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(stale))
    root.add_child(app)
    await _wait()
    # _ready() has loaded (empty) files by now, so the returning-player state is
    # applied after it. The cold open and the calibration case get their own
    # passes at the end of this script.
    app.settings.intro_seen = true
    app.meta.calibration_completed = true
    for case_id in AstraCaseCatalog.CAMPAIGN:
        app.meta.case_counts[case_id] = 1
    for npc_id in AstraCrewCatalog.ORDER:
        app.meta.meet_person(npc_id)
    await _wait()
    for dimensions in [Vector2i(1366,768),Vector2i(1920,1080)]:
        root.size = dimensions
        suffix = "_"+str(dimensions.x)
        app.show_title()
        await _capture("title")
        app.start_case("DEAD_AIR","ANALYST")
        app.session.setup("DEAD_AIR",73131,"ANALYST","STANDARD")
        app.session.features = app.meta.unlocked_features()
        app.session.set_tutorial(true)
        await _capture("briefing")
        app.session.advance()
        await _capture("investigation")
        app.session.inspect_point("engine","traces")

        app._current.open_notebook()
        app._current._notebook.focus_tab(1)
        await _capture("notebook")
        for child in app.overlay_root().get_children():
            if child.has_method("close"):child.close(-1)
        app.session.advance()
        app._current.select("mira")
        await _capture("interrogation")
        app.session.ask("mira","ALIBI")
        _finish_phase()
        app.session.advance()
        _flush_view()
        await _capture("meeting")
        app.session.advance()
        await _capture("vote")
        app.session.cast_vote("")
        app.session.advance()
        await _capture("night")
        app.session.choose_night_action("rest","self")
        var guard := 0
        while app.session.phase != "RESULT" and guard < 50:
            guard += 1
            var s: AstraGameSession = app.session
            if not s.pending_event.is_empty():s.resolve_private_event(1)
            match s.phase:
                "VOTE": s.cast_vote("")
                "NIGHT": s.choose_night_action("rest","self")
            s.advance()
            await _wait(1)
        await _capture("result")
        app.show_settings()
        await _capture("settings")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):child.close(-1)
    root.size = Vector2i(1366,768)
    suffix = "_large_1366"
    AstraUI.reading_scale = 1.1
    AstraUI.reduce_motion = true
    app.show_archive()
    await _capture("archive")
    app.start_case("DEAD_AIR","ANALYST")
    app.session.setup("DEAD_AIR",73131,"ANALYST","STANDARD")
    app.session.features = app.meta.unlocked_features()
    app.session.advance()
    var clue: Dictionary = app.session.inspect_point("engine","traces")
    app.session.link_hypothesis(str(clue["id"]),"mira","power","관련")
    app._current.open_notebook()
    app._current._notebook.focus_tab(1)
    await _capture("linked_notebook")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):child.close(-1)
    app.session.advance()
    if not app.session.pending_event.is_empty():app.session.resolve_private_event(1)
    app._current.select("noa")
    app.session.ask("noa","ALIBI")
    await _capture("interrogation")
    _finish_phase()
    app.session.advance()
    _flush_view()
    app._current._view._hypothesis()
    await _capture("hypothesis_picker")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):child.close(-1)
    app.session.present_hypothesis(0)
    _flush_view()
    await _capture("hypothesis_reaction")
    # Result narrative also needs the success-only memory path rendered.
    app.session.outcome = "WIN"
    app.session._enter("RESULT")
    await _capture("victory")
    app.show_settings()
    await _capture("settings")
    # ---- 0.4.0 first-run path: cold open, fresh title, calibration ----------
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    root.size = Vector2i(1366, 768)
    suffix = "_1366"
    AstraUI.reading_scale = 1.0
    app.meta.reset()
    app.settings.intro_seen = false
    app.show_opening()
    await _capture("opening_00")
    for step in range(1, 12):
        app._current._advance()
        if step in [3, 6, 7, 10]:
            await _capture("opening_%02d" % step)
    app._current._finish()
    await _wait(6)
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    await _wait(4)
    await _capture("title_first_run")
    app.start_case(AstraCaseCatalog.CALIBRATION, "ANALYST")
    await _wait(4)
    await _capture("calibration_intro_card")
    for pass_index in range(8):
        for child in app.overlay_root().get_children():
            if child.has_method("close"):
                child.close(0)
        await _wait(3)
    await _capture("calibration_briefing")
    _finish_phase()
    app.session.advance()
    await _capture("calibration_investigation")
    for room_id in app.session.room_ids():
        for point in app.session.investigation_points(room_id):
            if bool(point.get("available", false)) and app.session.investigation_ap > 0:
                app.session.inspect_point(room_id, str(point["id"]))
    _finish_phase()
    app.session.advance()
    app._current.select("mira")
    await _capture("calibration_interrogation")
    for npc_id in app.session.living_ids():
        if app.session.talk_ap > 0:
            app.session.ask(npc_id, "ALIBI")
    _finish_phase()
    app.session.advance()
    await _wait(3)
    await _capture("calibration_meeting_step1")
    if app._current._view.has_method("_reveal_next"):
        app._current._view._reveal_next()
        app._current._view._reveal_next()
    await _capture("calibration_meeting_step3")
    app._current.open_notebook()
    app._current._notebook.focus_tab(2)
    await _capture("calibration_notebook_claims")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    app._current._open_screen_help()
    await _capture("screen_help")
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    if app._current._view.has_method("_flush"):
        _flush_view()
    app.session.advance()
    await _capture("calibration_vote")

    AstraGameSession.delete_snapshot(app.snapshot_path())
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://astra_visual_meta.cfg"))
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://astra_visual_settings.cfg"))
    print("ASTRA VISUAL QA OK")
    quit()
