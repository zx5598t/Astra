extends SceneTree

var app
var output := "res://build/qa/058"
var captures := 0

func _initialize() -> void: _run.call_deferred()

func settle() -> void:
    for i in range(8): await process_frame

func close_modals() -> void:
    for child in app.overlay_root().get_children():
        if child.has_method("close"): child.close(-1)
    await settle()

func capture(label: String) -> void:
    await settle()
    await create_timer(0.18).timeout
    await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    picture.save_jpg(output+"/"+label+".jpg",0.88)
    captures += 1

func _run() -> void:
    if "--qa-output" in OS.get_cmdline_user_args():
        var args := OS.get_cmdline_user_args()
        output = args[args.find("--qa-output")+1]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://contact_visual_meta.cfg")
    app.settings = AstraSettings.new("user://contact_visual_settings.cfg")
    app.settings.show_hints = false
    root.add_child(app)
    await settle()
    app.meta.calibration_completed = true
    for id in AstraCaseCatalog.CAMPAIGN: app.meta.case_counts[id] = 1
    for dim in [Vector2i(1366,768),Vector2i(1120,700),Vector2i(1920,1080)]:
        root.size = dim
        app.settings.large_text = dim.x == 1120
        app.settings.reduced_motion = dim.x == 1120
        AstraUI.reading_scale = 1.1 if app.settings.large_text else 1.0
        AstraUI.reduce_motion = app.settings.reduced_motion
        app.start_new_campaign(0)
        await settle()
        await capture("00_opening_"+str(dim.x))
        app._current._finish()
        await settle()
        app.session.voyage_next()
        await capture("01_introduction_"+str(dim.x))
        app.session.skip_contact_intro()
        await capture("02_required_action_"+str(dim.x))
        app.session.voyage_inspect("pod")
        app.session.voyage_next()
        await capture("03_joint_record_"+str(dim.x))
        for i in range(3): app.session.voyage_next()
        await capture("04_questions_"+str(dim.x))
        app.session.voyage_choose(1)
        app.session.voyage_next()
        await capture("05_choice_response_"+str(dim.x))
        preload("res://tests/voyage_driver.gd").close_scene(app.session)
        await capture("06_ready_"+str(dim.x))
        app._current._help()
        await capture("07_help_"+str(dim.x))
        await close_modals()
        app.session.finish_voyage()
        await capture("08_result_"+str(dim.x))
        app.start_case("DEAD_AIR","ANALYST",0)
        await settle()
        app.session.voyage_next()
        await capture("09_day2_arrival_"+str(dim.x))
        app.start_case("ECHO_WARD","ANALYST",0)
        preload("res://tests/voyage_driver.gd").inspect_goal(app.session)
        app.session.finish_voyage()
        while app.session.phase != "VOTE":
            if not app.session.pending_event.is_empty(): app.session.resolve_private_event(0)
            app.session.advance()
        app.show_session_screen()
        await settle()
        await close_modals()
        await capture("10_unselected_vote_"+str(dim.x))
        app.session.select_ballot("abstain")
        await capture("11_abstain_selected_"+str(dim.x))
        app.session.confirm_ballot()
        await capture("12_tally_"+str(dim.x))
        app.start_case("SILENT_ORBIT","ANALYST",0)
        await settle()
        app.session.voyage_next()
        await capture("13_day5_arrival_"+str(dim.x))
    app.show_title()
    root.remove_child(app)
    app.free()
    await settle()
    print("ASTRA 0.5.8 VISUAL CAPTURE OK · %d captures" % captures)
    quit()
