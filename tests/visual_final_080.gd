extends SceneTree
# Captures the campaign ending and DEEP RECONSTRUCTION screens at 1366x768
# (and 1920x1080 unless --small). Needs a window:
#   godot --path . --script res://tests/visual_final_080.gd
var app
var suffix := ""

func wait_frames(n: int = 5) -> void:
    for i in range(n):
        await process_frame

func capture(id: String, delay: float = 0.7) -> void:
    await create_timer(delay).timeout
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    root.get_texture().get_image().save_png("res://build/qa/080_final_" + id + suffix + ".png")

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    var small := "--small" in OS.get_cmdline_user_args()
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://astra_visualfinal_meta.cfg")
    app.settings = AstraSettings.new("user://astra_visualfinal_settings.cfg")
    for path in [app.meta.save_path, "user://astra_visualfinal_settings.cfg", AstraDeepRun.RUN_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    root.add_child(app)
    await wait_frames()
    var sizes := [Vector2i(1366, 768)] if small else [Vector2i(1366, 768), Vector2i(1920, 1080)]
    for dim in sizes:
        root.size = dim
        DisplayServer.window_set_size(dim)
        await wait_frames(4)
        suffix = "_" + str(dim.x)
        app.meta.campaign_completed = false
        app.meta.calibration_completed = true
        app.show_title()
        await capture("title_locked")
        # the finale
        app.session = AstraGameSession.new()
        var s: AstraGameSession = app.session
        s.setup("THRESHOLD", 4040, "GUARDIAN")
        s.set_player_profile({"name": "하윤", "preset": "p3"})
        s.begin_voyage({"campaign_tally": {"defended": {"noa": 3}, "sent_wrong": {"rho": 1}, "saved": {"sena": 2}, "deaths": {}}})
        for id in s.living_null_ids():
            s.crew[id].status = AstraCrewMember.STATUS_ISOLATED
        s._check_end("vote")
        s.phase = "RESULT"
        s._finalize()
        s._queue_result_story()
        app.show_session_screen()
        var guard := 0
        while str(s.story_scene().get("id", "")) != "finale_choice" and not s.story_finished() and guard < 40:
            guard += 1
            if not Array(s.story_scene().get("choices", [])).is_empty():
                s.story_choose(0)
            else:
                s.story_next()
        s.stage_state()["story_line"] = Array(s.story_scene().get("lines", [])).size() - 1
        s.changed.emit()
        await wait_frames(6)
        await capture("finale_choice", 1.2)
        s.story_choose(2)
        await wait_frames(6)
        await capture("epilogue", 1.2)
        guard = 0
        while not s.story_finished() and guard < 20:
            guard += 1
            s.story_next()
        await wait_frames(8)
        await capture("credits", 5.0)
        var view = app._current._view if app._current is AstraGameScreen else null
        if view != null and view._credits != null:
            view._credits.consume_advance()
        await capture("unlocked", 1.2)
        # DEEP RECONSTRUCTION
        app.meta.campaign_completed = true
        app.show_title()
        await capture("title_open")
        app.show_deep()
        await capture("deep_entry")
        app.deep_start("GUARDIAN")
        await wait_frames(6)
        await capture("deep_depth1", 1.2)
        s = app.session
        for id in s.living_null_ids():
            s.crew[id].status = AstraCrewMember.STATUS_ISOLATED
        s._check_end("vote")
        s.phase = "RESULT"
        s._finalize()
        s._queue_result_story()
        s.story_skip()
        app.show_session_screen()
        guard = 0
        while not s.story_finished() and guard < 10:
            guard += 1
            s.story_next()
        await wait_frames(8)
        await capture("deep_result_win", 1.0)
        app.deep_next_depth()
        await capture("deep_between", 1.0)
        app.deep_continue()
        await wait_frames(4)
        s = app.session
        s.stage_state()["player_threat"] = {}
        for id in s.living_null_ids():
            s.stage_state()["player_threat"][id] = 99.0
        s._resolve_night()
        app._save_session()
        app.show_deep("summary")
        await capture("deep_summary", 1.0)
        for path in [AstraDeepRun.RUN_PATH]:
            if FileAccess.file_exists(path):
                DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
        AstraGameSession.delete_snapshot(AstraDeepRun.SESSION_PATH)
    for path in [app.meta.save_path, "user://astra_visualfinal_settings.cfg"]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("ASTRA VISUAL FINAL 080 OK")
    quit()
