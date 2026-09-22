extends SceneTree
# 0.6.2 player-facing aftermath layout smoke at both supported target sizes.

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

func _close_scene(s: AstraGameSession, choice_index: int = 0) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 50:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage.get("line",-1)) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            s.voyage_choose(mini(choice_index,scene.get("choices",[]).size()-1))
        else:
            s.voyage_next()

func _reach_resolution(s: AstraGameSession) -> Dictionary:
    _close_scene(s)
    var fact := str(AstraVoyageContent.chapter(s.case_id).get("fact",""))
    for room_id in s.voyage_rooms():
        if str(s.voyage.get("room","")) != str(room_id):
            s.voyage_move(str(room_id),false)
            _close_scene(s)
        for point in s.voyage_points():
            if str(point[4]) == fact and s.voyage_inspect(str(point[0])):
                var guard := 0
                while guard < 50:
                    guard += 1
                    var scene: Dictionary = s.voyage.get("scene",{})
                    if scene.is_empty() or bool(scene.get("story_resolution",false)):
                        return scene
                    if int(s.voyage.get("line",-1)) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
                        s.voyage_choose(0)
                    else:
                        s.voyage_next()
                return s.voyage.get("scene",{})
    return {}

func _check_current_aftermath(size: Vector2i, label: String) -> void:
    root.size = size
    await _wait(6)
    _expect(app._current is AstraVoyageView,label + " uses voyage view")
    if not (app._current is AstraVoyageView):
        return
    var view: AstraVoyageView = app._current
    _expect(_inside(view._root,size),label + " root content stays inside viewport")
    var scene: Dictionary = app.session.voyage.get("scene",{})
    var lines: Array = scene.get("lines",[])
    if not lines.is_empty():
        var line_text := str(lines[0][1])
        var text_control := _find_text(view,line_text)
        _expect(text_control != null,label + " aftermath dialogue is rendered")
        if text_control != null:
            var scroll := _find_scroll_parent(text_control)
            _expect(scroll != null and _inside(scroll,size),label + " dialogue wrapping/scroll surface stays inside viewport")
    var speaker := str(scene.get("speaker",""))
    if speaker != "":
        _expect(speaker in app.session.active_participants(),label + " speaker is active")
        _expect(str(AstraCrewCatalog.cast_path(speaker,"neutral")) != "",label + " speaker portrait asset resolves")
    _expect(_find_text(view,"회의 자동 넘김") == null,label + " no meeting AUTO control can skip voyage aftermath")

func _run() -> void:
    for path in [META_PATH,SETTINGS_PATH]:
        if FileAccess.file_exists(path):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    app = load("res://scenes/main.tscn").instantiate()
    app.meta = AstraMetaProgress.new(META_PATH)
    app.settings = AstraSettings.new(SETTINGS_PATH)
    root.add_child(app)
    await _wait(6)

    app.meta.calibration_completed = true
    app.meta.mark_intro_seen_for_slot(0)
    for id in AstraCaseCatalog.CAMPAIGN:
        app.meta.case_counts[id] = 1
    app.active_slot = 0
    app.meta.save_data()
    app.start_case("DEAD_AIR","ANALYST",0)
    await _wait(6)

    if app._current is AstraOpeningView:
        app._current._finish()
        await _wait(6)
    for child in app.overlay_root().get_children():
        if child.has_method("close"):
            child.close(0)
    await _wait(4)

    var s: AstraGameSession = app.session
    var resolution := _reach_resolution(s)
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
    await _wait(6)
    _expect(bool(s.voyage.get("scene",{}).get("story_reaction",false)),"mandatory human reaction visible")

    await _check_current_aftermath(Vector2i(1366,768),"1366x768 reaction")
    await _check_current_aftermath(Vector2i(1920,1080),"1920x1080 reaction")

    var view: AstraVoyageView = app._current
    if not s.voyage.get("notes",[]).is_empty():
        view._notes()
        await _wait(4)
        var modal_ok := false
        for child in app.overlay_root().get_children():
            if child is Control and child.is_visible_in_tree():
                modal_ok = modal_ok or _inside(child,Vector2i(1920,1080))
            if child.has_method("close"):
                child.close(-1)
        _expect(modal_ok,"Notebook/current-situation overlay remains visible after aftermath")
        await _wait(3)

    s.voyage_next()
    await _wait(6)
    _expect(bool(s.voyage.get("scene",{}).get("story_hook",false)),"story hook survives reaction transition")
    await _check_current_aftermath(Vector2i(1366,768),"1366x768 hook")
    await _check_current_aftermath(Vector2i(1920,1080),"1920x1080 hook")

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
    quit(1)
