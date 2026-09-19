extends SceneTree
var app
func _initialize() -> void: _run.call_deferred()
func wait_frames() -> void:
    for i in range(8): await process_frame
func capture(id: String) -> void:
    await create_timer(0.4).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/qa/050_"+id+".png")
func _run() -> void:
    app=load("res://scenes/main.tscn").instantiate()
    app.meta=AstraMetaProgress.new("user://astra_050_visual.cfg")
    app.settings=AstraSettings.new("user://astra_050_visual_settings.cfg")
    app.settings.intro_seen=true
    root.add_child(app)
    await wait_frames()
    for dim in [Vector2i(1366,768),Vector2i(1920,1080)]:
        root.size=dim
        app.show_title()
        await capture("title_"+str(dim.x))
        app.start_case("CALIBRATION","ANALYST")
        await wait_frames()
        await capture("first_"+str(dim.x))
        for i in range(3): app.session.voyage_next()
        await wait_frames()
        await capture("room_"+str(dim.x))
        app.session.voyage_visit_person("rho")
        await wait_frames()
        app.session.voyage_next()
        await capture("jun_"+str(dim.x))
        app.meta.calibration_completed=true
        for id in AstraCaseCatalog.CAMPAIGN: app.meta.case_counts[id]=1
        app.start_case("RED_SHIFT","ANALYST")
        await wait_frames()
        app.session.voyage_next()
        await capture("maren_"+str(dim.x))
        app.show_title()
    for i in range(app.SLOT_COUNT): AstraGameSession.delete_snapshot(app.slot_path(i))
    for path in [app.meta.save_path,"user://astra_050_visual_settings.cfg"]:
        if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    root.remove_child(app)
    app.free()
    await wait_frames()
    print("ASTRA VOYAGE VISUAL OK")
    quit()

