extends SceneTree
# 0.8.0 screen captures at 1366x768 and 1920x1080 (run with a window, not
# --headless). Walks a real Stage 1 Day 1 → Day 2 and a Stage 5 night.
var app
var suffix := ""
var only_small := false

func _initialize() -> void:
    for a in OS.get_cmdline_user_args():
        if a == "--small":
            only_small = true
    _run.call_deferred()

func wait_frames(n: int = 5) -> void:
    for i in range(n):
        await process_frame

func capture(id: String, delay: float = 0.6) -> void:
    await create_timer(delay).timeout
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    root.get_texture().get_image().save_png("res://build/qa/080_" + id + suffix + ".png")

func close_modals() -> void:
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(-1)
    await wait_frames()

func view():
    return app._current._view if app._current is AstraGameScreen else null

func _run() -> void:
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://astra_visual080_meta.cfg")
    app.settings = AstraSettings.new("user://astra_visual080_settings.cfg")
    for path in [app.meta.save_path, "user://astra_visual080_settings.cfg"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    root.add_child(app)
    await wait_frames()
    var sizes := [Vector2i(1366, 768)] if only_small else [Vector2i(1366, 768), Vector2i(1920, 1080)]
    for dim in sizes:
        root.size = dim
        DisplayServer.window_set_size(dim)
        await wait_frames(4)
        suffix = "_" + str(dim.x)
        app.show_title()
        await capture("title")
        # 탐사요원 등록 (new campaign)
        app.start_new_campaign(0)
        await wait_frames(4)
        if app._current is AstraPlayerSetup:
            app._current._name_edit.text = "하윤"
            app._current._select("p3")
        await capture("register", 0.8)
        app.show_title()
        await wait_frames(4)
        # opening
        var opening := AstraOpeningView.new()
        app._set_screen(opening)
        opening.setup(app)
        await capture("opening_1")
        opening._advance()
        await capture("opening_2", 1.4)
        # Stage 1
        app.session = AstraGameSession.new()
        var s: AstraGameSession = app.session
        s.setup("CALIBRATION", 4242, "NONE", "STANDARD")
        app.show_session_screen()
        await capture("morning_1", 1.4)
        for i in range(6):
            s.story_next()
        await capture("morning_2", 1.4)
        s.story_skip()
        await wait_frames(6)
        await capture("talk_empty")
        var leads := s.talk_leads()
        var first := str(leads.keys()[0]) if not leads.is_empty() else str(s.living_ids()[0])
        view()._on_person(first)
        await capture("talk_1", 1.2)
        var options := s.question_options(first)
        if not options.is_empty():
            view()._ask(str(options[0]["intent"]), str(options[0].get("ref", "")))
            await capture("talk_2", 1.2)
        app._current.open_notebook()
        await capture("notebook")
        await close_modals()
        app._current.open_glossary()
        await capture("glossary")
        await close_modals()
        s.advance()
        await wait_frames(6)
        view()._reveal_all()
        await capture("meeting_1", 0.8)
        s.meeting_continue()
        view()._reveal_all()
        await capture("meeting_2", 0.8)
        s._finish_meeting()
        view()._reveal_all()
        s.advance()
        await wait_frames(6)
        await capture("vote_choose")
        var target := str(s.eligible_vote_targets()[0])
        view()._choice = target
        view().refresh()
        await capture("vote_selected")
        view()._on_confirm()
        view().consume_advance()
        await capture("vote_result", 1.0)
        var guard := 0
        while s.vote_stage() in ["RUNOFF", "TIEBREAK"] and guard < 4:
            guard += 1
            var pool := s.runoff_candidates()
            if s.vote_stage() == "TIEBREAK":
                s.resolve_tiebreak(str(pool[0]))
            else:
                s.cast_vote(str(pool[0]))
        app._current._on_changed()
        await wait_frames()
        if s.outcome == "":
            s.advance()
            await wait_frames(6)
            await capture("morning_day2", 1.4)
        # Stage 4: the first interlude (walk the relay room, trace the signal)
        app.session = AstraGameSession.new()
        s = app.session
        s.setup("ECHO_WARD", 4747, "NONE", "STANDARD")
        s.set_player_profile({"name": "하윤", "preset": "p3"})
        app.show_session_screen()
        s.story_skip()
        await wait_frames(8)
        var inter = view()._interlude if view() != null and "_interlude" in view() else null
        if inter != null:
            await capture("interlude_room", 1.0)
            inter.consume_advance()
            inter.player.position = inter.actors["vale"].position + Vector2(0, 90)
            await wait_frames(4)
            await capture("interlude_near", 0.6)
            inter._interact("vale")
            inter.consume_advance()
            inter.consume_advance()
            await wait_frames(4)
            await capture("interlude_task", 0.8)
            if inter._task != null:
                inter._task._value = float(inter._task._targets[0])
                inter._task._refresh()
                await capture("interlude_task_match", 0.5)
                inter._task._finish("success")
            await wait_frames(4)
            await capture("interlude_result", 0.8)
        # Stage 5: protocol scene + guardian night
        app.session = AstraGameSession.new()
        s = app.session
        s.setup("SILENT_ORBIT", 777, "NONE", "STANDARD")
        app.show_session_screen()
        guard = 0
        while not s.story_finished() and Array(s.story_scene().get("choices", [])).is_empty() and str(s.story_scene().get("kind", "")) != "protocol" and guard < 40:
            guard += 1
            s.story_next()
        await wait_frames(6)
        await capture("protocol", 1.4)
        s.story_skip()
        await wait_frames(4)
        s.advance()
        await wait_frames(4)
        s.advance()
        s._finish_meeting()
        s.advance()
        s.cast_vote(str(s.eligible_vote_targets()[0]))
        if s.vote_stage() == "RUNOFF":
            s.cast_vote(str(s.runoff_candidates()[0]))
        if s.vote_stage() == "TIEBREAK":
            s.resolve_tiebreak(str(s.runoff_candidates()[0]))
        if s.outcome == "" and s.night_needs_choice():
            s.advance()
            await wait_frames(6)
            await capture("night", 1.0)
        # result screen from a finished bot game
        app.session = AstraGameSession.new()
        s = app.session
        s.setup("CALIBRATION", 99, "NONE", "STANDARD")
        guard = 0
        while s.phase != "RESULT" and guard < 60:
            guard += 1
            match s.phase:
                "BRIEFING":
                    s.story_skip()
                    s.advance()
                "VOTE":
                    s.cast_vote(str(s.eligible_vote_targets()[0]))
                    if s.vote_stage() == "RUNOFF": s.cast_vote(str(s.runoff_candidates()[0]))
                    if s.vote_stage() == "TIEBREAK": s.resolve_tiebreak(str(s.runoff_candidates()[0]))
                    s.advance()
                "NIGHT":
                    s.choose_night_action("skip", "")
                    s.advance()
                _:
                    s.advance()
        app.show_session_screen()
        await capture("result_story", 1.2)
        s.story_skip()
        guard = 0
        while not s.story_finished() and guard < 20:
            guard += 1
            if not Array(s.story_scene().get("choices", [])).is_empty():
                s.story_choose(0)
            else:
                s.story_skip()
        await wait_frames(6)
        await capture("result_summary", 1.0)
    for i in range(app.SLOT_COUNT):
        AstraGameSession.delete_snapshot(app.slot_path(i))
    for path in [app.meta.save_path, "user://astra_visual080_settings.cfg"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("ASTRA VISUAL 080 OK")
    quit()
