extends SceneTree
# Life in an interlude room, captured at the moments that matter: people at
# work when you walk in, the start when you come close, a nod while talking,
# the reaction when the task works out, and dinner in the lounge.
# Needs a window:  godot --path . --script res://tests/visual_life_080.gd
var app

func wait_frames(n: int = 5) -> void:
    for i in range(n):
        await process_frame

func capture(id: String, delay: float = 0.3) -> void:
    await create_timer(delay).timeout
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    root.get_texture().get_image().save_png("res://build/qa/080_life_" + id + ".png")

func _initialize() -> void:
    _run.call_deferred()

func _open(case_id: String, preset: String):
    app.session = AstraGameSession.new()
    var s: AstraGameSession = app.session
    var stage := AstraCaseCatalog.stage_index(case_id)
    s.setup(case_id, 4242, "GUARDIAN" if stage >= 5 else "NONE", "STANDARD")
    s.set_player_profile(AstraExplorerCatalog.profile_for(preset) if preset in AstraExplorerCatalog.ORDER else {"name": "하윤", "preset": preset})
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
    return view._interlude if view != null and "_interlude" in view else null

# Walk the explorer toward a point the way a click would.
func _walk(inter, to: Vector2, seconds: float) -> void:
    inter._walk_to = to
    inter._walk_target = ""
    await create_timer(seconds).timeout

func _run() -> void:
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://astra_visuallife_meta.cfg")
    app.settings = AstraSettings.new("user://astra_visuallife_settings.cfg")
    root.add_child(app)
    await wait_frames()
    root.size = Vector2i(1366, 768)
    DisplayServer.window_set_size(Vector2i(1366, 768))
    await wait_frames(4)
    var inter = await _open("ECHO_WARD", "serin")
    if inter == null:
        print("NO INTERLUDE")
        quit(1)
        return
    inter.consume_advance()
    await capture("1_walk_in", 0.8)
    var vale = inter.actors["vale"]
    await _walk(inter, vale.position + Vector2(0, 150), 1.2)
    await capture("2_noticed", 0.05)
    inter._interact("vale")
    await capture("3_talking", 0.5)
    inter.consume_advance()
    inter.consume_advance()
    await wait_frames(4)
    if inter._task != null:
        inter._task._finish("success")
    await capture("4_task_done", 0.12)
    await capture("4b_task_done", 0.25)
    inter = await _open("CONTINUITY", "rael")
    if inter != null:
        inter.consume_advance()
        await _walk(inter, inter.actors["mira"].position + Vector2(0, 120), 1.6)
        await capture("5_dinner", 0.4)
        inter._interact("mira")
        await capture("6_dinner_talk", 0.3)
    print("ASTRA VISUAL LIFE OK")
    for path in ["user://astra_visuallife_meta.cfg", "user://astra_visuallife_settings.cfg"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    quit()
