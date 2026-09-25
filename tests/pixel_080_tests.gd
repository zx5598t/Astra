extends SceneTree

# Pixel characters (§78): every normalised sheet loads, has four directions of
# three frames with something drawn in each, keeps its feet on the frame's
# bottom edge, and builds walk / idle animations. Also every interlude's cast
# has a sheet and every interlude's room keeps its spawn point walkable.
# Motion: breathing, gestures, emotes, walking dips, work poses, noticing the
# explorer and going back to work, sitting, drawn action sheets, line cues,
# and one interlude played through to its exit walk.
#   godot --headless --path . --script res://tests/pixel_080_tests.gd

var checks := 0
var failures: Array = []

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)
        print("FAIL · " + label)

func _initialize() -> void:
    var sheets: Array = []
    for id in AstraCrewCatalog.ORDER:
        sheets.append(AstraPixelActor.crew_sheet(str(id)))
    for preset in AstraPlayerSetup.PRESETS + AstraExplorerCatalog.ART_IDS:
        sheets.append(AstraPixelActor.player_sheet(str(preset)))
        check(ResourceLoader.exists("res://assets/pixel080/player/%s_face.png" % preset), "face icon for " + str(preset))
    for path in sheets:
        check(ResourceLoader.exists(str(path)), "sheet exists: " + str(path))
        var tex: Texture2D = load(str(path)) if ResourceLoader.exists(str(path)) else null
        if tex == null:
            continue
        var image := tex.get_image()
        if image.is_compressed():
            image.decompress()
        var info := AstraPixelManifest.sheet(str(path).get_file().get_basename())
        var cols := int(info.get("frames", 0))
        check(cols in [3, 4], "manifest knows the sheet: " + str(path))
        check(image.get_width() == AstraPixelActor.FRAME.x * cols and image.get_height() == AstraPixelActor.FRAME.y * 4, "sheet is frames x 4: " + str(path))
        for row in range(4):
            for column in range(cols):
                var frame := image.get_region(Rect2i(column * AstraPixelActor.FRAME.x, row * AstraPixelActor.FRAME.y, AstraPixelActor.FRAME.x, AstraPixelActor.FRAME.y))
                var used := frame.get_used_rect()
                check(used.size.x > 20 and used.size.y > 60, "frame %d,%d drawn: %s" % [row, column, path])
                check(used.end.y >= AstraPixelActor.FRAME.y - 6, "feet on the frame floor %d,%d: %s" % [row, column, path])
        var actor := AstraPixelActor.new()
        actor.setup(str(path), "test", "", Color.WHITE)
        var frames: SpriteFrames = actor._sprite.sprite_frames
        for dir in AstraPixelActor.DIRECTIONS:
            check(frames.has_animation("walk_" + dir) and frames.get_frame_count("walk_" + dir) == 4, "walk animation " + dir)
            check(frames.has_animation("idle_" + dir) and frames.get_frame_count("idle_" + dir) == 1, "idle frame " + dir)
        actor.free()
    for id in AstraInterludes.all_ids():
        var data := AstraInterludes.data(str(id))
        for actor_entry in data.get("actors", []):
            check(ResourceLoader.exists(AstraPixelActor.crew_sheet(str(actor_entry.get("id", "")))), "interlude cast has a sheet: %s" % id)
        var room := AstraDeckRoom.new()
        room.setup(data)
        check(not room.blocked(room.tile_to_px(data.get("spawn", [7.5, 8.0]))), "spawn is walkable: %s" % id)
        for actor_entry in data.get("actors", []):
            var at: Vector2 = room.tile_to_px(actor_entry.get("at", [1, 1]))
            var who := "%s/%s" % [id, actor_entry.get("id", "")]
            var idle := str(actor_entry.get("idle", "watch"))
            check(idle in ["watch", "work", "sit", "alert", "pace"], "known idle style: " + who)
            if idle == "sit":
                check(not room.front_prop_at(at).is_empty(), "a seated person has a table in front: " + who)
            else:
                check(not room.blocked(at), "actor stands on the floor: " + who)
            if idle == "pace":
                var pace: Array = actor_entry.get("pace", [0, 0])
                var end := at + Vector2(float(pace[0]), float(pace[1])) * AstraInterludes.TILE
                check(end.distance_to(at) > 32.0, "a pacing person has somewhere to go: " + who)
                for k in range(11):
                    check(not room.blocked(at.lerp(end, k / 10.0)), "pace path is floor: " + who)
        room.free()
    _motion_tests()
    _life_tests()
    _pose_tests()
    _cue_tests()
    _interlude_flow_test()
    _finish()

func _motion_tests() -> void:
    for name in AstraPixelActor.GESTURES:
        var track: Array = AstraPixelActor.GESTURES[name]
        check(not track.is_empty(), "gesture has steps: " + name)
        for step in track:
            check(step.size() == 7 and float(step[0]) > 0.0, "gesture step shape: " + name)
            check(absi(int(step[1])) <= 3 and absi(int(step[2])) <= 6 and absi(int(step[3])) <= 2 and absi(int(step[4])) <= 3, "gesture bands stay small: " + name)
            check(int(step[5]) >= 0 and int(step[5]) <= 8 and int(step[6]) >= -1 and int(step[6]) <= 3, "gesture hop and frame in range: " + name)
    for kind in AstraPixelActor.EMOTE_GLYPHS:
        check(AstraPixelActor.EMOTE_COLORS.has(kind), "emote has a colour: " + str(kind))
    check(AstraPixelActor.motion_shader().code.contains("head_off"), "motion shader built")
    var a := AstraPixelActor.new()
    a.setup(AstraPixelActor.crew_sheet("mira"), "mira", "미라", Color.WHITE)
    var seen := {}
    for i in range(90):
        a._process(0.05)
        seen[a.band_offsets()[1].y] = true
    check(seen.has(0) and seen.has(1) and seen.size() == 2, "breathing moves the upper body by one pixel")
    a.gesture("nod", true)
    var peak := 0
    for i in range(10):
        a._process(0.05)
        peak = maxi(peak, a.band_offsets()[0].y)
    check(peak >= 3, "a nod lowers the head")
    check(a.gesture_active() == "", "a nod ends by itself")
    # a person without a drawn cheer hops with the bands
    var legacy := AstraPixelActor.new()
    legacy.setup(AstraPixelActor.player_sheet("p1"), "player", "", Color.WHITE)
    legacy.gesture("hop", true)
    var hop := 0
    for i in range(10):
        legacy._process(0.03)
        hop = maxi(hop, int(legacy.band_offsets()[2]))
    check(hop >= 6, "a hop leaves the floor")
    legacy.free()
    a.gesture("shift", true)
    a._process(0.05)
    check(a._sprite.animation == &"walk_down" and a._sprite.frame == 0, "a weight shift shows a step frame")
    for i in range(10):
        a._process(0.05)
    check(a._sprite.animation == &"idle_down", "after the shift they stand again")
    a.emote("!", 0.5, true)
    check(a.emote_active() == "!", "an emote shows")
    for i in range(12):
        a._process(0.05)
    check(a.emote_active() == "", "an emote goes away")
    # 1.0: walking is carried by the drawn frames; no band moves the upper
    # body against the legs. The whole figure rises a pixel on passing frames.
    a.set_moving(true)
    a._sprite.pause()
    a._sprite.frame = 0
    a._process(0.0)
    check(a.band_offsets()[1] == Vector2i.ZERO and int(a.band_offsets()[2]) == 0, "a walk contact frame: body on the legs, figure down")
    a._sprite.frame = 1
    a._process(0.0)
    check(a.band_offsets()[1] == Vector2i.ZERO and int(a.band_offsets()[2]) == 1, "a walk passing frame: the whole figure rises one pixel")
    a.set_moving(false)
    a.face("up")
    a.working = true
    var bent := 0
    var sway := false
    for i in range(40):
        a._process(0.05)
        bent = maxi(bent, a.band_offsets()[0].y)
        sway = sway or a.band_offsets()[1].x != 0
    check(bent >= 2 and sway, "working bends over the console and moves the hands")
    a.working = false
    a.face("down")
    a.talking = true
    var talk := 0
    for i in range(40):
        a._process(0.05)
        talk = maxi(talk, a.band_offsets()[0].y)
    check(talk >= 2, "talking comes with small nods")
    a.talking = false
    a.seated = true
    a._process(0.0)
    check(a._sprite.position.y == float(AstraPixelActor.SIT_DROP_DRAWN) and a.current_animation().begins_with("pose_sit_"), "sitting uses the drawn sitting pose behind the table")
    AstraUI.reduce_motion = true
    a.seated = false
    a.gesture("hop", true)
    a._process(0.12)
    check(int(a.band_offsets()[2]) == 0 and a.band_offsets()[0] == Vector2i.ZERO, "reduced motion: no hops, no bands")
    AstraUI.reduce_motion = false
    a.free()

func _life_tests() -> void:
    var w := AstraPixelActor.new()
    w.setup(AstraPixelActor.crew_sheet("vale"), "vale", "소렌", Color.WHITE)
    w.position = Vector2(400, 150)
    w.home = w.position
    w.home_facing = "up"
    w.style = "work"
    w.face("up")
    w.working = true
    w.think(0.1, Vector2(400, 600), false)
    check(w.facing == "up" and w.working, "a worker keeps working while you are far")
    w.think(0.1, Vector2(400, 260), false)
    check(w.facing == "down" and not w.working and w.emote_active() == "!", "a worker notices you: turns, stops, a start")
    for i in range(40):
        w._process(0.05)
        w.think(0.05, Vector2(400, 700), false)
    check(w.facing == "up" and w.working, "a worker goes back to work when you leave")
    w.think(0.1, Vector2(400, 260), false)
    check(w.emote_active() != "!" or w._t - w._emote_start > 1.0, "the start happens once, not every visit")
    w.free()
    var p := AstraPixelActor.new()
    p.setup(AstraPixelActor.crew_sheet("sena"), "sena", "세나", Color.WHITE)
    p.position = Vector2(200, 200)
    p.home = p.position
    p.style = "pace"
    p.pace_offset = Vector2(100, 0)
    var free_floor := func(point: Vector2) -> bool: return true
    var far := Vector2(900, 900)
    var moved := 0.0
    for i in range(160):
        p._process(0.05)
        var before := p.position
        p.think(0.05, far, false, free_floor)
        moved += before.distance_to(p.position)
    check(moved > 150.0 and p.position.x >= 199.0 and p.position.x <= 301.0, "a pacing person walks the stretch and stays on it")
    var near := p.position + Vector2(0, 40)
    p.think(0.05, near, false, free_floor)
    var held := p.position
    for i in range(10):
        p._process(0.05)
        p.think(0.05, near, false, free_floor)
    check(p.position == held and not p.moving, "a pacing person stops for you")
    p.free()

# Drawn poses (0.9.0): every person has a pose sheet with no blank cell, poses
# play with a dip in and out, turning round passes through a side frame, a walk
# settles when it stops, explorers walk on four drawn frames, and reduced
# motion keeps the poses but drops the dips.
func _pose_tests() -> void:
    var keys: Array = AstraCrewCatalog.ORDER.duplicate()
    keys.append_array(AstraExplorerCatalog.ART_IDS)
    for key in keys:
        var info := AstraPixelManifest.sheet(str(key))
        var poses: Dictionary = info.get("poses", {})
        check(poses.size() >= 6, "several drawn poses: %s" % key)
        for name in ["greet", "surprised", "cheer"]:
            check(poses.has(name), "%s has %s" % [key, name])
        var tex: Texture2D = load(str(info.get("poses_sheet", ""))) if ResourceLoader.exists(str(info.get("poses_sheet", ""))) else null
        check(tex != null, "pose sheet loads: %s" % key)
        if tex == null:
            continue
        var image := tex.get_image()
        if image.is_compressed():
            image.decompress()
        var cols := int(info.get("pose_cols", 8))
        var seen := {}
        for name in poses:
            for cell in poses[name]:
                if seen.has(cell):
                    continue
                seen[cell] = true
                var frame := image.get_region(Rect2i((int(cell) % cols) * AstraPixelActor.POSE_FRAME.x, (int(cell) / cols) * AstraPixelActor.POSE_FRAME.y, AstraPixelActor.POSE_FRAME.x, AstraPixelActor.POSE_FRAME.y))
                var used := frame.get_used_rect()
                check(used.size.y > 50 and used.size.x > 30, "pose %s/%s drawn" % [key, name])
                check(used.end.y >= AstraPixelActor.POSE_FRAME.y - 6, "pose %s/%s stands on the floor" % [key, name])
                # the same person at the same size: a standing pose is never
                # much taller than the walking figure
                check(used.size.y <= 132, "pose %s/%s keeps the figure's size" % [key, name])
    for art in AstraExplorerCatalog.ART_IDS:
        var e := AstraPixelActor.new()
        e.setup(AstraPixelActor.player_sheet(str(art)), "player", "", Color.WHITE)
        check(e.walk_frame_count() == 4, "explorers walk on four drawn frames: " + str(art))
        var fr: SpriteFrames = e._sprite.sprite_frames
        for dir in AstraPixelActor.DIRECTIONS:
            check(fr.get_frame_count("walk_" + dir) == 4 and fr.get_frame_count("carry_walk_" + dir) == 4, "walk and carry walk %s: %s" % [dir, art])
        e.carrying = true
        check(e.current_animation() == "carry_idle_down", "carrying their tool: " + str(art))
        e.free()
    var d := AstraPixelActor.new()
    d.setup(AstraPixelActor.crew_sheet("noa"), "noa", "노아", Color.WHITE)
    check(d.has_action_sheet() and d.has_pose("cheer"), "drawn poses are picked up")
    d.face("down")
    d.gesture("startle", true)
    check(d.pose_active() == "surprised" and d.current_animation() == "idle_down", "a drawn start begins with a dip on the standing frame")
    d._process(0.04)
    check(d.band_offsets()[1].y == 1, "anticipation: the body dips before the pose")
    d._process(0.06)
    check(str(d._sprite.animation).begins_with("pose_surprised_") and d._sprite.offset.y == -AstraPixelActor.POSE_FRAME.y + 4.0, "then the drawn pose, anchored at the feet")
    for i in range(24):
        d._process(0.05)
    check(d.pose_active() == "" and d._sprite.animation == &"idle_down", "back to standing after a drawn reaction")
    d.face("left")
    d.gesture("tilt", true)
    check(d.pose_active() == "" and d.gesture_active() == "tilt", "a small front pose does not turn a side-facing person: band tilt instead")
    for i in range(20):
        d._process(0.05)
    d.face("right")
    check(d.current_animation() == "idle_down", "turning round passes through the front")
    d._process(0.1)
    check(d.current_animation() == "idle_right", "and ends facing the new way")
    d.set_moving(true)
    d._process(0.2)
    d.set_moving(false)
    d._process(0.02)
    check(d.current_animation() == "idle_right" and d._sprite.sprite_frames.get_frame_texture(d._sprite.animation, d._sprite.frame) != null, "a walk stops on the standing frame")
    d.talking = true
    var talked := false
    d.face("down")
    for i in range(80):
        d._process(0.05)
        talked = talked or str(d._sprite.animation).begins_with("pose_talk_")
    check(talked, "a long line comes with a drawn talking gesture")
    d.talking = false
    for i in range(30):
        d._process(0.05)
    AstraUI.reduce_motion = true
    d.gesture("hop", true)
    d._process(0.01)
    check(str(d._sprite.animation).begins_with("pose_cheer_") and d.band_offsets()[1].y == 0, "reduced motion: the pose without the dip")
    AstraUI.reduce_motion = false
    d.free()

func _cue_tests() -> void:
    var view := AstraInterludeView.new()
    var m := AstraPixelActor.new()
    m.setup(AstraPixelActor.crew_sheet("mira"), "mira", "미라", Color.WHITE)
    view.actors = {"mira": m}
    check(view._line_cue("mira", "…그래요.", "") in ["…", "sigh"], "a trailing line gets a pause")
    check(view._line_cue("mira", "잠깐만요!", "") == "!", "an exclamation gets a start")
    check(view._line_cue("mira", "뭐라고 했어요?", "") in ["?", "tilt"], "a question gets a tilt")
    check(view._line_cue("", "방이 조용하다.", "") == "", "narration has no cue")
    check(view._line_cue("mira", "아무 말.", "bow") == "bow", "an explicit cue wins")
    check(view._line_cue("mira", "같은 말.", "") == view._line_cue("mira", "같은 말.", ""), "cues are stable per line")
    m.free()
    view.free()

# The lounge (people sitting at dinner): walk in, read the wall roster, and
# leave; the scene reports success after a short walk toward the door.
func _interlude_flow_test() -> void:
    var s := AstraGameSession.new()
    s.setup("CONTINUITY", 3131, "GUARDIAN", "STANDARD")
    var view := AstraInterludeView.new()
    root.add_child(view)
    view.setup(s, "continuity_evening", "serin_a")
    var got := {"result": ""}
    view.done.connect(func(r: String): got["result"] = r)
    check(view.actors["lyra"].seated and view.actors["mira"].seated and not view.actors["rho"].seated, "the lounge seats two at dinner")
    check(view.room._fronts.size() == 1, "the dinner table is drawn in front of the people behind it")
    view.consume_advance()
    for i in range(5):
        view._process(0.05)
    view.player.position = view._target_pos("meal_table") + Vector2(0, 10)
    view._interact("meal_table")
    check(view.player.working and view.player.facing == "up", "reading the wall roster: facing it, bent over it")
    var guard := 0
    while got["result"] == "" and guard < 60:
        guard += 1
        view.consume_advance()
        view._process(0.1)
    check(got["result"] == "success", "the lounge scene ends in success after the exit walk (%s)" % got["result"])
    check(view.player.emote_active() != "" or view.player._t > 1.0, "the explorer reacted to the roster")
    view.queue_free()

func _finish() -> void:
    if failures.is_empty():
        print("ASTRA PIXEL 080 TESTS OK · %d checks" % checks)
        quit()
    else:
        print("ASTRA PIXEL 080 TESTS FAILED · %d/%d" % [failures.size(), checks])
        quit(1)
