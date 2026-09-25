extends SceneTree

# 0.9.0 visual capture (needs a window):
#   godot --path . --script res://tests/visual_human_090.gd
# build/qa/explorer090_<id>_<w>.png  the explorer selection, each explorer picked
# build/qa/motion090_<sheet>_<w>.png  one person: every walk frame in the four
#   directions, band motions and transitions, then every drawn pose
# at 1366x768 and 1920x1080. Fails when a card or the start button leaves the
# screen, or a captured frame is blank.

var failures: Array = []

func _initialize() -> void:
    _run.call_deferred()

func _capture(path: String) -> Image:
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image := root.get_texture().get_image()
    image.save_png("res://build/qa/" + path)
    return image

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    for resolution in [Vector2i(1366, 768), Vector2i(1920, 1080)]:
        DisplayServer.window_set_size(resolution)
        root.size = resolution
        AstraUI.reduce_motion = true
        for id in AstraExplorerCatalog.ORDER:
            var setup := AstraPlayerSetup.new()
            root.add_child(setup)
            setup.setup(AstraExplorerCatalog.profile_for(id))
            await _capture("explorer090_%s_%d.png" % [id, resolution.x])
            var screen := Rect2(Vector2.ZERO, Vector2(resolution))
            for card in setup._cards.values():
                if not screen.encloses(card.get_global_rect()):
                    failures.append("card overflow %s %d" % [id, resolution.x])
            var start: Control = setup.find_child("StartButton", true, false)
            if start == null or not screen.encloses(start.get_global_rect()):
                failures.append("start button off screen %d" % resolution.x)
            if setup._figure.texture == null:
                failures.append("no full figure for " + id)
            setup.queue_free()
            await process_frame
        AstraUI.reduce_motion = false
        var sheets: Array = AstraCrewCatalog.ORDER.duplicate()
        sheets.append_array(AstraExplorerCatalog.ART_IDS)
        for key in sheets:
            await _motion_sheet(str(key), resolution)
    if failures.is_empty():
        print("ASTRA VISUAL HUMAN 090 OK")
    else:
        for failure in failures:
            printerr(failure)
    quit(0 if failures.is_empty() else 1)

func _motion_sheet(key: String, resolution: Vector2i) -> void:
    var world := Node2D.new()
    root.add_child(world)
    var bg := ColorRect.new()
    bg.size = Vector2(resolution)
    bg.color = Color("15202f")
    world.add_child(bg)
    var scale := 1.2 if resolution.y < 900 else 1.7
    var step := Vector2(158.0, 176.0) * (scale / 1.2)
    var path := AstraPixelActor.crew_sheet(key) if key in AstraCrewCatalog.ORDER else AstraPixelActor.player_sheet(key)
    var probe := AstraPixelActor.new()
    probe.setup(path, key, "", Color.WHITE)
    var frames := probe.walk_frame_count()
    var poses: Array = probe.pose_names()
    probe.free()
    var cells: Array = []
    for dir in AstraPixelActor.DIRECTIONS:
        for f in range(frames):
            cells.append(["walk", dir, f])
    for motion in ["idle", "talk", "work", "sit", "nod", "shake", "sigh", "walk_stop", "turn", "recover"]:
        cells.append(["motion", motion, 0])
    for name in poses:
        cells.append(["pose", str(name), 0])
    var per_row := int((resolution.x - 40) / step.x)
    for i in range(cells.size()):
        var cell: Array = cells[i]
        var actor := AstraPixelActor.new()
        actor.setup(path, key, "", Color.WHITE)
        actor.position = Vector2(20 + step.x * 0.5 + (i % per_row) * step.x, 20 + step.y * 0.82 + (i / per_row) * step.y)
        actor.scale = Vector2(scale, scale)
        world.add_child(actor)
        actor.set_process(false)
        var label_text := ""
        match str(cell[0]):
            "walk":
                actor.face(str(cell[1]))
                actor.set_moving(true)
                actor._sprite.pause()
                actor._sprite.frame = int(cell[2])
                actor._process(0.1)
                label_text = "%s %d" % [cell[1], int(cell[2])]
            "pose":
                actor.pose(str(cell[1]), 5.0, true)
                actor._process(0.1)
                label_text = str(cell[1])
            _:
                label_text = str(cell[1])
                match str(cell[1]):
                    "talk":
                        actor.talking = true
                    "work":
                        actor.face("up")
                        actor.working = true
                    "sit":
                        actor.seated = true
                    "walk_stop":
                        actor.set_moving(true)
                        actor._process(0.12)
                        actor.set_moving(false)
                        actor._process(0.01)
                    "turn":
                        actor.face("left")
                        actor._process(0.2)
                        actor.face("right")
                        actor._process(0.01)
                    "recover":
                        actor.gesture("startle", true)
                        actor._process(0.88)
                    "idle":
                        pass
                    _:
                        actor.gesture(str(cell[1]), true)
                if str(cell[1]) not in ["walk_stop", "turn", "recover"]:
                    actor._process(0.15)
        if actor.seated:
            var table := ColorRect.new()
            table.position = actor.position + Vector2(-60, -28) * (scale / 1.2)
            table.size = Vector2(120, 34) * (scale / 1.2)
            table.color = Color("30425b")
            world.add_child(table)
        var label := Label.new()
        label.text = label_text
        label.add_theme_font_size_override("font_size", 13)
        label.position = actor.position + Vector2(-step.x * 0.45, 8)
        world.add_child(label)
    var image: Image = await _capture("motion090_%s_%d.png" % [key, resolution.x])
    if image.get_used_rect().size == Vector2i.ZERO:
        failures.append("blank motion capture " + key)
    world.queue_free()
    await process_frame
