extends SceneTree
# Advanced screens. First-run and awakening captures live in voyage_visual.gd.
var app
var suffix := ""
func _initialize() -> void: _run.call_deferred()
func wait_frames() -> void:
    for i in range(5): await process_frame
func capture(id: String) -> void:
    await create_timer(1.9).timeout
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://build/qa/050_"+id+suffix+".png")
func close_modals() -> void:
    for child in app.overlay_root().get_children():
        if child.has_method("close"): child.close(-1)
    await wait_frames()
func _run() -> void:
    app=load("res://scenes/main.tscn").instantiate()
    app.meta=AstraMetaProgress.new("user://astra_visual_meta.cfg")
    app.settings=AstraSettings.new("user://astra_visual_settings.cfg")
    for path in [app.meta.save_path,"user://astra_visual_settings.cfg"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    root.add_child(app)
    await wait_frames()
    app.settings.intro_seen=true
    app.meta.calibration_completed=true
    for id in AstraCaseCatalog.CAMPAIGN: app.meta.case_counts[id]=1
    for dim in [Vector2i(1366,768),Vector2i(1920,1080)]:
        root.size=dim
        suffix="_"+str(dim.x)
        app.show_title()
        app.session=AstraGameSession.new()
        var s: AstraGameSession=app.session
        s.setup("LAST_LIGHT",73131,"ANALYST","STANDARD")
        s.features=app.meta.unlocked_features()
        app.show_session_screen()
        await capture("briefing")
        s.advance()
        await capture("investigation")
        for room in s.room_ids():
            while s.investigation_ap > 0:
                if s.search_room(room).is_empty(): break
        app._current.open_notebook()
        await capture("notebook")
        await close_modals()
        s.advance()
        if not s.pending_event.is_empty(): s.resolve_private_event(0)
        s.ask("mira","ALIBI")
        await capture("interrogation")
        if not s.pending_event.is_empty(): s.resolve_private_event(0)
        s.advance()
        await wait_frames()
        app._current._view._reveal_next()
        await capture("meeting")
        app._current._view._flush()
        s.advance()
        await capture("vote")
        s.cast_vote("")
        s.advance()
        await capture("night")
        var guard:=0
        while s.phase != "RESULT" and guard < 60:
            guard+=1
            if not s.pending_event.is_empty(): s.resolve_private_event(0)
            if s.phase=="VOTE": s.cast_vote("")
            if s.phase=="NIGHT": s.choose_night_action("rest","self")
            s.advance()
            await wait_frames()
        await capture("result")
        app.show_settings()
        await capture("settings")
        await close_modals()
    for i in range(app.SLOT_COUNT): AstraGameSession.delete_snapshot(app.slot_path(i))
    for path in [app.meta.save_path,"user://astra_visual_settings.cfg"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    root.remove_child(app)
    app.free()
    await wait_frames()
    print("ASTRA VISUAL QA OK")
    quit()
