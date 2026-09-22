extends SceneTree
# 0.6.2 player-facing aftermath layout smoke at both target resolutions.
# It enters the same canonical resolution -> choice -> reaction -> hook runtime
# path used by HUMAN TRACE, without depending on optional exploration order.

const META_PATH := "user://astra_062_aftermath_ui_meta.cfg"
const SETTINGS_PATH := "user://astra_062_aftermath_ui_settings.cfg"

var app
var failures: Array[String] = []

func _expect(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        printerr("AFTERMATH UI FAIL · " + label)

func _wait(frames: int = 5) -> void:
    for _i in range(frames):
        await process_frame

func _initialize() -> void:
    _run.call_deferred()

func _inside(control: Control, size: Vector2i) -> bool:
    if control == null or not control.is_visible_in_tree():
        return false
    var rect := control.get_global_rect()
    return rect.position.x >= -2.0 and rect.position.y >= -2.0 and rect.end.x <= float(size.x) + 2.0 and rect.end.y <= float(size.y) + 2.0

func _find_text(node: Node, needle: String) -> Control:
    if needle == "":
        return null
    if node is Label and needle in str(node.text):
        return node
    if node is RichTextLabel and needle in str(node.text):
        return node
    for child in node.get_children():
        var found := _find_text(child,needle)
        if found != null:
            return found
    return null

func _find_scroll_parent(node: Node) -> ScrollContainer:
    var cursor := node.get_parent()
    while cursor != null:
        if cursor is ScrollContainer:
            return cursor
        cursor = cursor.get_parent()
    return null

func _close_scene(s: AstraGameSession) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 50:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if not scene.get("choices",[]).is_empty():
            # Opening/ambient setup should not own the resolution probe.
            break
        s.voyage_next()

func _prepare_resolution(case_id: String, seed_value: int, memory_tags: Array = []) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup(case_id,seed_value)
    s.begin_voyage({"loops":1 if not memory_tags.is_empty() else 0,"memory_tags":memory_tags})
    _close_scene(s)
    # Remove any non-choice ambient scene left by setup, then use the exact
    # HUMAN TRACE runtime entry used by its regression suite.
    s.voyage["scene"] = {}
    var chapter := AstraVoyageContent.chapter(case_id)
    var fact := str(chapter.get("fact",""))
    s._voyage_fact(fact,str(chapter.get("discovery","")),"DIRECT")
    s._voyage_scene(AstraVoyageContent.resolution_thread(case_id,memory_tags))
    return s

func _attach_session(s: AstraGameSession) -> void:
    app.session = s
    app.show_session_screen()
    await _wait(6)

func _current_scene_line() -> String:
    var scene: Dictionary = app.session.voyage.get("scene",{})
    var line_index := int(app.session.voyage.get("line",-1))
    var lines: Array = scene.get("lines",[])
    if line_index >= 0 and line_index < lines.size():
        return str(lines[line_index][1])
    return ""

func _check_current_aftermath(size: Vector2i, label: String) -> void:
    root.size = size
    await _wait(6)
    _expect(app._current is AstraVoyageView,label + " uses voyage view")
    if not (app._current is AstraVoyageView):
        return
    var view: AstraVoyageView = app._current
    _expect(_inside(view._root,size),label + " root content stays inside viewport")
    var scene: Dictionary = app.session.voyage.get("scene",{})
    var visible_text := _current_scene_line()
    if visible_text == "":
        visible_text = str(scene.get("action",""))
    var text_control := _find_text(view,visible_text)
    _expect(text_control != null,label + " aftermath text is rendered")
    if text_control != null:
        var scroll := _find_scroll_parent(text_control)
        _expect(scroll != null and _inside(scroll,size),label + " wrapping/scroll surface stays inside viewport")
    var speaker := str(scene.get("speaker",""))
    if speaker != "":
        _expect(speaker in app.session.active_participants(),label + " speaker is active")
        _expect(str(AstraCrewCatalog.cast_path(speaker,"neutral")) != "",label + " speaker portrait asset resolves")
    _expect(_find_text(view,"회의 자동 넘김") == null,label + " meeting AUTO cannot skip voyage aftermath")

func _run() -> void:
    for path in [META_PATH,SETTINGS_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(6)

    # Immediate aftermath: canonical fact -> handling choice -> human reaction.
    var s := _prepare_resolution("DEAD_AIR",906220)
    await _attach_session(s)
    var resolution: Dictionary = s.voyage.get("scene",{})
    _expect(bool(resolution.get("story_resolution",false)),"resolution reached")
    while int(s.voyage.get("line",-1)) < resolution.get("lines",[]).size()-1:
        s.voyage_next()
        resolution = s.voyage.get("scene",{})
    var choices: Array = resolution.get("choices",[])
    var public_index := 0
    for i in range(choices.size()):
        if str(choices[i].get("memory_tag","")) == "dead_air_public_dual_destination":
            public_index = i
            break
    _expect(s.voyage_choose(public_index),"handling choice accepted")
    _expect(bool(s.voyage.get("scene",{}).get("story_reaction",false)),"mandatory human reaction queued")
    s.voyage_next() # reveal the one authored reaction line
    await _wait(4)
    _expect(bool(s.voyage.get("scene",{}).get("story_reaction",false)),"mandatory human reaction visible")
    await _check_current_aftermath(Vector2i(1366,768),"1366x768 reaction")
    await _check_current_aftermath(Vector2i(1920,1080),"1920x1080 reaction")

    # Current-situation/Notebook presentation must not overflow over aftermath.
    if not s.voyage.get("notes",[]).is_empty():
        var view: AstraVoyageView = app._current
        view._notes()
        await _wait(4)
        var visible_modal := false
        for child in app.overlay_root().get_children():
            if child is Control and child.is_visible_in_tree():
                visible_modal = visible_modal or _inside(child,Vector2i(1920,1080))
            if child.has_method("close"):
                child.close(-1)
        _expect(visible_modal,"Notebook/current-situation overlay remains visible after aftermath")
        await _wait(3)

    s.voyage_next() # close reaction; mandatory story hook must take ownership
    await _wait(5)
    _expect(bool(s.voyage.get("scene",{}).get("story_hook",false)),"story hook survives reaction transition")
    await _check_current_aftermath(Vector2i(1366,768),"1366x768 hook")
    await _check_current_aftermath(Vector2i(1920,1080),"1920x1080 hook")

    # Next-loop residue: specifically cover RED_SHIFT, where the visible action
    # is Noa's. The portrait/speaker must therefore also be Noa, not the base
    # resolution participant that used to leak through.
    var residue := _prepare_resolution("RED_SHIFT",906221,["red_shift_hide_handwriting"])
    await _attach_session(residue)
    var callback_scene: Dictionary = residue.voyage.get("scene",{})
    _expect(bool(callback_scene.get("human_trace_callback",false)),"next-loop residue is visible")
    _expect(str(callback_scene.get("speaker","")) == "noa","RED_SHIFT residue portrait/speaker matches Noa action")
    await _check_current_aftermath(Vector2i(1366,768),"1366x768 next-loop residue")
    await _check_current_aftermath(Vector2i(1920,1080),"1920x1080 next-loop residue")

    for i in range(app.SLOT_COUNT):
        AstraGameSession.delete_snapshot(app.slot_path(i))
    for path in [META_PATH,SETTINGS_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    root.remove_child(app)
    app.free()
    await _wait(4)

    if failures.is_empty():
        print("ASTRA 0.6.2 AFTERMATH UI SMOKE OK · 1366x768 + 1920x1080")
        quit(0)
        return
    quit(1)
