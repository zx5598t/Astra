extends SceneTree
# 0.7.2 ACT I VISUAL STORY PASS: four mystery resolutions plus the first-wake
# memory point use the existing stage replacement. ACT II 0.7.1 mappings stay intact.

const VISUAL_CASES := ["CALIBRATION","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const RESOLUTION_CASES := ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const ACT2_071 := ["SECOND_WATCH","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY","THRESHOLD"]

var failures: Array[String] = []
var checks := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: failures.append(label)
func _initialize() -> void:
    _run.call_deferred()
func _run() -> void:
    check(VISUAL_CASES.size() == 5, "ACT I pass has exactly five memory-point images")
    for case_id in VISUAL_CASES:
        var path := AstraArt.story_scene(case_id)
        check(path.begins_with("res://assets/art072/"), "%s maps to art072" % case_id)
        check(FileAccess.file_exists(path), "%s art file exists" % case_id)
        check(ResourceLoader.exists(path), "%s art is importable" % case_id)
        var texture := AstraUI.texture(path)
        check(texture != null, "%s art loads as Texture2D" % case_id)
        if texture != null:
            check(texture.get_width() >= 1200 and texture.get_height() >= 675, "%s is scene-scale" % case_id)
    for case_id in RESOLUTION_CASES:
        var resolution := AstraVoyageContent.resolution_thread(case_id, [])
        check(str(resolution.get("id","")) == "story_resolution_" + case_id.to_lower(), "%s keeps canonical reveal id" % case_id)
        check(bool(resolution.get("story_resolution",false)), "%s stays a story resolution" % case_id)
        check(str(resolution.get("action","")) != "", "%s has authored action framing" % case_id)
        check(Array(resolution.get("lines",[])).size() >= 4, "%s keeps evidence-reaction-meaning dialogue" % case_id)
    for case_id in ACT2_071:
        check(AstraArt.story_scene(case_id).begins_with("res://assets/art071/"), "%s keeps 0.7.1 art" % case_id)
    check(AstraArt.story_scene("DEAD_AIR") == "", "DEAD_AIR stays on fallback to avoid LAST_LIGHT duplication")
    check(AstraArt.story_scene("BORROWED_DAYS") == "", "BORROWED_DAYS stays on fallback")
    check(AstraArt.story_scene("NOT_A_CHAPTER") == "", "unknown chapter safely falls back")
    var wake := AstraVoyageContent.first_thread("first_wake")
    check(str(wake.get("id","")) == "first_wake", "CALIBRATION first-wake reveal id remains stable")
    check(Array(wake.get("lines",[])).size() > 0, "CALIBRATION first-wake remains playable")
    if failures.is_empty():
        print("ASTRA 0.7.2 VISUAL STORY TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures: printerr("FAIL · " + failure)
    quit(1)
