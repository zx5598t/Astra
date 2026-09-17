extends SceneTree
# Real-render visual QA; isolated settings and archive, no player saves touched.
var app
func _initialize() -> void:
    _run.call_deferred()
func _wait(frames: int = 12) -> void:
    for i in frames:
        await process_frame
func _capture(file: String) -> void:
    await create_timer(0.6).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/qa/" + file + ".png")
func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://astra_qa_meta.cfg")
    app.settings = AstraSettings.new("user://astra_qa_settings.cfg")
    app.settings.intro_seen = true
    root.add_child(app)
    await _wait()
    await _capture("title")
    app.start_case("DEAD_AIR", "ANALYST")
    await _wait()
    await create_timer(2.0).timeout
    await _capture("briefing")
    app.session.advance()
    await _wait()
    await create_timer(2.0).timeout
    await _capture("investigation")
    app.session.search_room(str(app.session.room_ids()[0]))
    app.session.advance()
    await _wait()
    await create_timer(2.0).timeout
    await _capture("interrogation")
    AstraGameSession.delete_snapshot(app.snapshot_path())
    app.queue_free()
    await _wait(2)
    quit()
