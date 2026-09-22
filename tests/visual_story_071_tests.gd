extends SceneTree
# 0.7.1 VISUAL STORY PASS: five selected ACT II resolution threads have real
# scene art, keep authored resolution content, and leave unselected chapters on
# the existing room/portrait fallback.

const VISUAL_CASES := [
    "SECOND_WATCH",
    "BLIND_DECK",
    "THREE_MINUTES_DARK",
    "CONTINUITY",
    "THRESHOLD"
]

var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    _run.call_deferred()

func _run() -> void:
    check(VISUAL_CASES.size() == 5, "visual pass remains a five-scene patch")
    for case_id in VISUAL_CASES:
        var path := AstraArt.story_scene(case_id)
        check(path != "", "%s has a story-art mapping" % case_id)
        check(FileAccess.file_exists(path), "%s art file exists" % case_id)
        check(ResourceLoader.exists(path), "%s art is importable" % case_id)
        var texture := AstraUI.texture(path)
        check(texture != null, "%s art loads as Texture2D" % case_id)
        if texture != null:
            check(texture.get_width() >= 1200 and texture.get_height() >= 675, "%s art has scene-scale dimensions" % case_id)
        var resolution := AstraVoyageContent.resolution_thread(case_id, [])
        check(str(resolution.get("id","")) == "story_resolution_" + case_id.to_lower(), "%s keeps canonical resolution id" % case_id)
        check(bool(resolution.get("story_resolution",false)), "%s remains a story resolution" % case_id)
        check(str(resolution.get("action","")) != "", "%s resolution has visual action framing" % case_id)
        check(Array(resolution.get("lines",[])).size() >= 3, "%s resolution keeps authored dialogue" % case_id)

    check(AstraArt.story_scene("BORROWED_DAYS") == "", "BORROWED_DAYS stays on the existing fallback")
    check(AstraArt.story_scene("LAST_LIGHT") == "", "ACT I finale stays on the existing fallback")
    check(AstraArt.story_scene("NOT_A_CHAPTER") == "", "unknown chapter safely falls back")

    if failures.is_empty():
        print("ASTRA 0.7.1 VISUAL STORY TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)
