extends SceneTree
# Captures the 0.6.2 player-facing aftermath surfaces at both target resolutions.

const META_PATH := "user://astra_062_visual_meta.cfg"
const SETTINGS_PATH := "user://astra_062_visual_settings.cfg"
const OUT_DIR := "res://build/qa/aftermath_062"

var app

func _initialize() -> void:
    _run.call_deferred()

func _wait(frames: int = 6) -> void:
    for _i in range(frames):
        await process_frame

func _capture(name: String, size: Vector2i) -> void:
    root.size = size
    await _wait(8)
    await RenderingServer.frame_post_draw
    var dir_abs := ProjectSettings.globalize_path(OUT_DIR)
    DirAccess.make_dir_recursive_absolute(dir_abs)
    root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [OUT_DIR,name,size.x,size.y])

func _close_scene(s: AstraGameSession) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 50:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if not scene.get("choices",[]).is_empty():
            break
        s.voyage_next()

func _prepare_resolution(case_id: String, seed_value: int, memory_tags: Array = []) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup(case_id,seed_value)
    s.begin_voyage({"loops":1 if not memory_tags.is_empty() else 0,"memory_tags":memory_tags})
    _close_scene(s)
    s.voyage["scene"] = {}
    var chapter := AstraVoyageContent.chapter(case_id)
    var fact := str(chapter.get("fact",""))
    s._voyage_fact(fact,str(chapter.get("discovery","")),"DIRECT")
    s._voyage_scene(AstraVoyageContent.resolution_thread(case_id,memory_tags))
    return s

func _attach(s: AstraGameSession) -> void:
    app.session = s
    app.show_session_screen()
    await _wait(8)

func _run() -> void:
    for path in [META_PATH,SETTINGS_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(8)

    var sizes := [Vector2i(1366,768),Vector2i(1920,1080)]

    var s := _prepare_resolution("DEAD_AIR",906230)
    await _attach(s)
    var resolution: Dictionary = s.voyage.get("scene",{})
    while int(s.voyage.get("line",-1)) < resolution.get("lines",[]).size()-1:
        s.voyage_next()
        resolution = s.voyage.get("scene",{})
    var choices: Array = resolution.get("choices",[])
    var public_index := 0
    for i in range(choices.size()):
        if str(choices[i].get("memory_tag","")) == "dead_air_public_dual_destination":
            public_index = i
            break
    s.voyage_choose(public_index)
    s.voyage_next()
    await _wait(6)
    for size in sizes:
        await _capture("reaction_dead_air",size)

    s.voyage_next()
    await _wait(6)
    for size in sizes:
        await _capture("story_hook_dead_air",size)

    var residue := _prepare_resolution("RED_SHIFT",906231,["red_shift_hide_handwriting"])
    await _attach(residue)
    for size in sizes:
        await _capture("residue_red_shift_noa",size)

    for i in range(app.SLOT_COUNT):
        AstraGameSession.delete_snapshot(app.slot_path(i))
    for path in [META_PATH,SETTINGS_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    root.remove_child(app)
    app.free()
    await _wait(4)
    print("ASTRA 0.6.2 AFTERMATH VISUAL CAPTURE OK")
    quit(0)
