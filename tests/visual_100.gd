extends SceneTree

# 1.0 human review captures (needs a window):
#   godot --path . --script res://tests/visual_100.gd
# build/qa/100/
#   walk_<sheet>.png        every walk frame, 4 directions, 1x and 3x, plus a
#                           3x crop of the legs only (does each foot move?)
#   sequence_<sheet>.png    idle -> walk start -> a full stride -> stop, a
#                           180-degree turn, idle -> talk -> idle (3x)
#   screen_<name>_<w>.png   selection, conversation (long), meeting, link
#                           picker, vote with reasons, lost Stage with rewind,
#                           the four task families — at 1120x700, 1366x768 and 1920x1080

const OUT := "res://build/qa/100/"
var app

func _initialize() -> void:
    _run.call_deferred()

func _wait(frames: int = 4) -> void:
    for _i in range(frames):
        await process_frame

func _capture(name: String) -> void:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(OUT + name + ".png")

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
    DisplayServer.window_set_size(Vector2i(1920, 1080))
    root.size = Vector2i(1920, 1080)
    var sheets: Array = AstraCrewCatalog.ORDER.duplicate()
    sheets.append_array(AstraExplorerCatalog.ART_IDS)
    for key in sheets:
        await _walk_sheet(str(key))
        await _sequence(str(key))
    for resolution in [Vector2i(1120, 700), Vector2i(1366, 768), Vector2i(1920, 1080)]:
        DisplayServer.window_set_size(resolution)
        root.size = resolution
        await _wait(4)
        await _screens(resolution)
    print("ASTRA VISUAL 100 OK")
    quit()

func _sheet_path(key: String) -> String:
    return AstraPixelActor.crew_sheet(key) if key in AstraCrewCatalog.ORDER else AstraPixelActor.player_sheet(key)

# Straight from the sheet: 1x row, 3x row, and the legs only at 3x.
func _walk_sheet(key: String) -> void:
    var info := AstraPixelManifest.sheet(key)
    var img: Image = load(str(info["walk"])).get_image()
    if img.is_compressed():
        img.decompress()
    var cols := int(info["frames"])
    var order: Array = [0, 1, 2, 1] if cols == 3 else [0, 1, 2, 3]
    var cell := 128
    var out := Image.create(order.size() * cell * 3 + 40, 4 * (cell * 3 + cell + 48 + 40), false, Image.FORMAT_RGBA8)
    out.fill(Color("15202f"))
    for row in range(4):
        var base_y := row * (cell * 3 + cell + 48 + 40)
        for i in range(order.size()):
            var frame := img.get_region(Rect2i(int(order[i]) * cell, row * cell, cell, cell))
            out.blend_rect(frame, Rect2i(0, 0, cell, cell), Vector2i(20 + i * cell, base_y + 10))
            var big := frame.duplicate() as Image
            big.resize(cell * 3, cell * 3, Image.INTERPOLATE_NEAREST)
            out.blend_rect(big, Rect2i(0, 0, cell * 3, cell * 3), Vector2i(20 + i * cell * 3, base_y + cell + 20))
            var legs := frame.get_region(Rect2i(0, 92, cell, 36))
            legs.resize(cell * 3, 36 * 3, Image.INTERPOLATE_NEAREST)
            out.blend_rect(legs, Rect2i(0, 0, cell * 3, 108), Vector2i(20 + i * cell * 3, base_y + cell + 20 + cell * 3 - 108))
        out.fill_rect(Rect2i(0, base_y + cell * 4 + 40, out.get_width(), 2), Color("30425b"))
    out.save_png(OUT + "walk_%s.png" % key)

# The actor itself, frame by frame, at 3x: start, a full stride, stop; a
# 180-degree turn; idle -> talk -> idle.
func _sequence(key: String) -> void:
    var world := Node2D.new()
    root.add_child(world)
    var bg := ColorRect.new()
    bg.color = Color("15202f")
    bg.size = Vector2(1920, 1080)
    world.add_child(bg)
    var shots: Array = []
    var a := AstraPixelActor.new()
    a.setup(_sheet_path(key), key, "", Color.WHITE)
    a.distance_driven = true
    a.face("right")
    a.set_process(false)
    var steps: Array = [["서 있음", func(): a._process(0.1)]]
    steps.append(["출발", func(): a.set_moving(true); a._process(1.0 / 60.0)])
    var stride := a._stride()
    for k in range(1, 9):
        steps.append(["걸음 %d/8" % k, func(): a.position.x += stride / 8.0; a._process(1.0 / 60.0)])
    steps.append(["정지", func(): a.set_moving(false); a._process(0.02)])
    steps.append(["뒤돌기", func(): a.face("left"); a._process(0.01)])
    steps.append(["뒤돈 뒤", func(): a._process(0.12)])
    steps.append(["말하기", func(): a.face("down"); a.talking = true; a._process(0.2)])
    steps.append(["다시 서기", func(): a.talking = false; a._process(0.3)])
    var i := 0
    for pair in steps:
        (pair[1] as Callable).call()
        var copy := AstraPixelActor.new()
        copy.setup(_sheet_path(key), key, "", Color.WHITE)
        copy.set_process(false)
        copy._sprite.sprite_frames = a._sprite.sprite_frames
        copy._sprite.play(a._sprite.animation)
        copy._sprite.pause()
        copy._sprite.frame = a._sprite.frame
        copy._sprite.offset = a._sprite.offset
        copy._sprite.flip_h = a._sprite.flip_h
        copy._sprite.position = Vector2(0, a._sprite.position.y)
        copy._material.set_shader_parameter("head_off", Vector2(a.band_offsets()[0]))
        copy._material.set_shader_parameter("body_off", Vector2(a.band_offsets()[1]))
        copy.scale = Vector2(2, 2)
        copy.position = Vector2(110 + (i % 7) * 260, 330 + (i / 7) * 460)
        world.add_child(copy)
        var label := Label.new()
        label.text = str(pair[0])
        label.position = copy.position + Vector2(-60, 20)
        world.add_child(label)
        i += 1
    a.free()
    await _capture("sequence_%s" % key)
    world.queue_free()
    await _wait(2)

func _screens(resolution: Vector2i) -> void:
    var w := resolution.x
    for id in ["serin", "logan"]:
        var setup := AstraPlayerSetup.new()
        root.add_child(setup)
        setup.setup(AstraExplorerCatalog.profile_for(id))
        await _capture("screen_selection_%s_%d" % [id, w])
        setup.queue_free()
        await _wait(2)
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new("user://astra_visual100_meta.cfg")
    app.settings = AstraSettings.new("user://astra_visual100_settings.cfg")
    root.add_child(app)
    await _wait(4)
    app.session = AstraGameSession.new()
    var s: AstraGameSession = app.session
    s.setup("GLASS_GARDEN", 6161)
    s.set_player_profile(AstraExplorerCatalog.profile_for("serin"))
    app.show_session_screen()
    await _wait(6)
    var guard := 0
    while s.phase == "BRIEFING" and guard < 5:
        guard += 1
        AstraTestBots._finish_morning(s)
        await _wait(4)
        if s.phase == "BRIEFING":
            s.advance()
    await _wait(4)
    var view = app._current._view
    var ids := s.living_ids()
    view._on_person(str(ids[0]))
    await _wait(3)
    for option in s.question_options(str(ids[0])):
        if bool(option.get("enabled", false)) and str(option["intent"]) in ["WITNESS", "RECORD", "SUSPECT"]:
            view._ask(str(option["intent"]), str(option.get("ref", "")))
            await _wait(3)
            break
    await _wait(6)
    await _capture("screen_conversation_%d" % w)
    for npc_id in ids.slice(1):
        if s.conversations_left() > 0:
            s.ask(str(npc_id), "STATEMENT")
    s.advance()
    await _wait(4)
    view = app._current._view
    view._reveal_all()
    await _wait(6)
    await _capture("screen_meeting_%d" % w)
    view._picker = "link_statement"
    view._render_actions()
    await _wait(3)
    await _capture("screen_link_step1_%d" % w)
    var statements := s.link_statements()
    if not statements.is_empty():
        view._link_statement = str(statements[0]["ref"])
        view._picker = "link_evidence"
        view._render_actions()
        await _wait(3)
        await _capture("screen_link_step2_%d" % w)
    view._picker = ""
    var link := AstraTestBots.smart_link(s)
    if link != "":
        view._intervene("link", link)
        await _wait(3)
        view._reveal_all()
        await _wait(6)
        await _capture("screen_meeting_after_link_%d" % w)
    s._finish_meeting()
    view._reveal_all()
    await _wait(6)
    await _capture("screen_meeting_closing_%d" % w)
    s.advance()
    await _wait(5)
    view = app._current._view
    view._choice = str(s.eligible_vote_targets()[0])
    view._reason = 0
    view.refresh()
    await _wait(4)
    await _capture("screen_vote_%d" % w)
    # a lost Stage with its rewind
    s.outcome = "LOSE"
    s.stage_state()["outcome_reason"] = "player_killed"
    s._enter("RESULT")
    await _wait(4)
    var story_guard := 0
    while not s.story_finished() and story_guard < 60:
        story_guard += 1
        s.story_next()
    await _wait(3)
    if app._current._view != null and app._current._view.has_method("refresh"):
        app._current._view.refresh()
    await _wait(6)
    await _capture("screen_result_lose_%d" % w)
    app.queue_free()
    await _wait(3)
    # the four task families
    for pair in [["signal", func(): var t := AstraSignalTrace.new(); root.add_child(t); t.setup(7, [], 0.05, "소렌"); return t],
            ["circuit", func(): var t := AstraPowerRoute.new(); root.add_child(t); t.setup(7, "준"); t.probe(1); return t],
            ["timeline", func(): var t := AstraOrderTask.new(); root.add_child(t); t.setup(7, AstraInterludes.data("second_watch_logs")["task"], "노아"); t.place(0); return t],
            ["route", func(): var t := AstraFieldTask.new(); root.add_child(t); t.setup(7, AstraInterludes.data("blind_deck_door")["task"]); return t]]:
        var task: Node = (pair[1] as Callable).call()
        await _wait(3)
        await _capture("screen_task_%s_%d" % [pair[0], w])
        task.queue_free()
        await _wait(2)
