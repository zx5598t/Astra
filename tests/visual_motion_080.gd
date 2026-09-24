extends SceneTree
# Contact sheet of the made-up poses and emotes (pixel_actor.gd) on several
# characters, frozen at the peak of each motion, plus 3x zooms of each row.
# Needs a window:  godot --path . --script res://tests/visual_motion_080.gd

const SCALE := 1.5
const CELL := Vector2(150, 240)

func _initialize() -> void:
    _run.call_deferred()

func _actor(sheet: String, id: String, at: Vector2, dir: String) -> AstraPixelActor:
    var a := AstraPixelActor.new()
    a.setup(sheet, id, "", AstraCrewCatalog.accent(id) if AstraCrewCatalog.CREW.has(id) else AstraUI.GOLD)
    a.set_process(false)
    a.position = at
    a.scale = Vector2(SCALE, SCALE)
    a._breath_shift = 0.0
    a._breath_period = 3.0
    a._t = 0.5
    a.face(dir)
    return a

func _cell(row: int, col: int) -> Vector2:
    return Vector2(80 + col * CELL.x, 40 + row * CELL.y + 200)

func _label(text: String, at: Vector2, layer: Node) -> void:
    var label := Label.new()
    label.text = text
    label.position = at + Vector2(-60, 14)
    label.size = Vector2(120, 20)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 13)
    layer.add_child(label)

func _run() -> void:
    DisplayServer.window_set_size(Vector2i(1366, 768))
    root.size = Vector2i(1366, 768)
    var bg := ColorRect.new()
    bg.color = Color("15202f")
    bg.size = Vector2(1366, 768)
    root.add_child(bg)
    var world := Node2D.new()
    root.add_child(world)
    var ui := CanvasLayer.new()
    root.add_child(ui)
    var crew := func(id: String) -> String: return AstraPixelActor.crew_sheet(id)
    var cells: Array = [
        # row 0: one person (Mira, facing you) through the body motions
        [0, 0, "mira", "down", "서 있음", func(a): a._process(0.0)],
        [0, 1, "mira", "down", "숨 내쉼", func(a): a._t = 2.4; a._process(0.0)],
        [0, 2, "mira", "down", "말하며 끄덕", func(a): a.talking = true; a._nod_next = 0.0; a._process(0.05)],
        [0, 3, "mira", "down", "끄덕임", func(a): a.gesture("nod", true); a._process(0.12)],
        [0, 4, "mira", "down", "고개 숙임", func(a): a.gesture("bow", true); a._process(0.3)],
        [0, 5, "mira", "down", "갸웃", func(a): a.gesture("tilt", true); a._gesture_sign = 1; a._process(0.3)],
        [0, 6, "mira", "down", "놀람(점프)", func(a): a.gesture("startle", true); a._process(0.1)],
        [0, 7, "mira", "down", "한숨", func(a): a.gesture("sigh", true); a._process(0.6)],
        [0, 8, "mira", "left", "옆 · 끄덕", func(a): a.gesture("nod", true); a._process(0.12)],
        # row 1: work, sitting, walking
        [1, 0, "vale", "up", "작업(뒤)", func(a): a.working = true; a._burst_until = 9.0; a._rest_until = 10.0; a._t = 0.0; a._process(0.0)],
        [1, 1, "eli", "right", "작업(옆)", func(a): a.working = true; a._burst_until = 9.0; a._rest_until = 10.0; a._t = 0.0; a._process(0.0)],
        [1, 2, "noa", "down", "읽기", func(a): a.working = true; a._burst_until = 9.0; a._rest_until = 10.0; a._t = 0.0; a._process(0.0)],
        [1, 3, "lyra", "down", "앉음", func(a): a.seated = true; a._process(0.0)],
        [1, 4, "mira", "left", "앉음(옆)", func(a): a.seated = true; a._process(0.0)],
        [1, 5, "rho", "down", "걷기 딛음", func(a): a.set_moving(true); a._sprite.pause(); a._sprite.frame = 0; a._process(0.0)],
        [1, 6, "sena", "left", "걷기 옆", func(a): a.set_moving(true); a._sprite.pause(); a._sprite.frame = 2; a._process(0.0)],
        [1, 7, "dax", "down", "무게 옮김", func(a): a.gesture("shift", true); a._process(0.1)],
        [1, 8, "p3", "down", "탐사요원 p3", func(a): a.gesture("hop", true); a._process(0.12)],
        # row 2: emotes
        [2, 0, "dax", "down", "!", func(a): a.emote("!", 5.0, true); a._process(0.2)],
        [2, 1, "sena", "down", "?", func(a): a.emote("?", 5.0, true); a._process(0.2)],
        [2, 2, "vale", "down", "…", func(a): a.emote("…", 5.0, true); a._process(0.2)],
        [2, 3, "lyra", "down", "♪", func(a): a.emote("♪", 5.0, true); a._process(0.2)],
        [2, 4, "noa", "down", "땀", func(a): a.emote("sweat", 5.0, true); a._process(0.2)],
        [2, 5, "p1", "down", "다가가면 표시", func(a): a.highlight = true; a._process(0.0)],
        [2, 6, "p2", "left", "p2", func(a): a._process(0.0)],
        [2, 7, "p5", "up", "p5", func(a): a._process(0.0)],
        [2, 8, "p6", "right", "p6", func(a): a._process(0.0)],
    ]
    for entry in cells:
        var id := str(entry[2])
        var sheet := AstraPixelActor.player_sheet(id) if id.begins_with("p") and id.length() == 2 else AstraPixelActor.crew_sheet(id)
        var at := _cell(int(entry[0]), int(entry[1]))
        var a := _actor(sheet, id, at, str(entry[3]))
        world.add_child(a)
        # _ready turns processing back on; freeze after entering the tree
        a.set_process(false)
        (entry[5] as Callable).call(a)
        if a.seated:
            # a table edge in front of the legs, as in the lounge
            var table := ColorRect.new()
            table.color = Color("6b4f3a")
            table.position = at + Vector2(-70, -40)
            table.size = Vector2(140, 44)
            world.add_child(table)
        _label(str(entry[4]), at, ui)
    for i in range(6):
        await process_frame
    await RenderingServer.frame_post_draw
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var shot := root.get_texture().get_image()
    shot.save_png("res://build/qa/080_motion.png")
    for row in range(3):
        var top := int(_cell(row, 0).y - 200)
        var strip := shot.get_region(Rect2i(0, top, 1366, 240))
        strip.resize(1366 * 2, 240 * 2, Image.INTERPOLATE_NEAREST)
        strip.get_region(Rect2i(0, 0, 1366, 480)).save_png("res://build/qa/080_motion_row%d_a.png" % row)
        strip.get_region(Rect2i(1366, 0, 1366, 480)).save_png("res://build/qa/080_motion_row%d_b.png" % row)
    print("ASTRA VISUAL MOTION OK")
    quit()
