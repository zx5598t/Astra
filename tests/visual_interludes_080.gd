extends SceneTree
# Captures every interlude (room, and its task if it has one) at 1366x768.
# Needs a window:  godot --path . --script res://tests/visual_interludes_080.gd
var app

func wait_frames(n: int = 5) -> void:
    for i in range(n):
        await process_frame

func capture(id: String, delay: float = 0.6) -> void:
    await create_timer(delay).timeout
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    root.get_texture().get_image().save_png("res://build/qa/080_il_" + id + ".png")

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://astra_visualil_meta.cfg")
    app.settings = AstraSettings.new("user://astra_visualil_settings.cfg")
    root.add_child(app)
    await wait_frames()
    root.size = Vector2i(1366, 768)
    DisplayServer.window_set_size(Vector2i(1366, 768))
    await wait_frames(4)
    var shown := 0
    for id in AstraInterludes.all_ids():
        var data := AstraInterludes.data(str(id))
        app.session = AstraGameSession.new()
        var s: AstraGameSession = app.session
        var stage := AstraCaseCatalog.stage_index(str(data["case_id"]))
        s.setup(str(data["case_id"]), 3131, "GUARDIAN" if stage >= 5 else "NONE", "STANDARD")
        s.set_player_profile(AstraExplorerCatalog.profile_for(AstraExplorerCatalog.ORDER[shown % 6]))
        app.show_session_screen()
        var guard := 0
        while str(s.story_scene().get("kind", "")) != "interlude" and not s.story_finished() and guard < 40:
            guard += 1
            if not Array(s.story_scene().get("choices", [])).is_empty():
                s.story_choose(0)
            else:
                s.story_skip()
        await wait_frames(8)
        var view = app._current._view if app._current is AstraGameScreen else null
        var inter = view._interlude if view != null and "_interlude" in view else null
        if inter == null:
            print("NO INTERLUDE VIEW for ", id)
            continue
        inter.consume_advance()
        await capture(str(id) + "_room", 0.8)
        var task := ""
        for target in data.get("targets", []):
            if str(target.get("task", "")) != "":
                task = str(target.get("id", ""))
        if task != "":
            inter._interact(task)
            for i in range(4):
                inter.consume_advance()
            await wait_frames(4)
            await capture(str(id) + "_task", 0.6)
        shown += 1
    print("ASTRA VISUAL INTERLUDES OK · %d" % shown)
    for path in ["user://astra_visualil_meta.cfg", "user://astra_visualil_settings.cfg"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    quit()
