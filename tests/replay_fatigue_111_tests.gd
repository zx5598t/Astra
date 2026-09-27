extends SceneTree

# HUMAN RHYTHM replay audit. The patch does not auto-skip canon; it verifies
# that alternate routes expose materially different authored residue while a
# same-route replay remains deterministic and canon-safe.
const ROUTES := {
    "DEAD_AIR":["PUBLIC","VERIFY_FIRST"],
    "ECHO_WARD":["TELL_SOREN","VERIFY_FIRST"],
    "RED_SHIFT":["REVEAL","WITHHOLD_VERIFY"],
    "BORROWED_DAYS":["TELL","OBSERVE"],
    "THREE_MINUTES_DARK":["POWER","COMMS","SECURITY"]
}

var failures: Array[String] = []
var checks := 0
var report: PackedStringArray = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    run_audit()
    if failures.is_empty():
        print("ASTRA REPLAY FATIGUE 111 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA REPLAY FATIGUE 111 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _choose(s: AstraGameSession, anchor: String, route: String) -> bool:
    if s.voyage.is_empty():
        s.begin_voyage({})
    for si in range(s.story_queue().size()):
        var scene: Dictionary = s.story_queue()[si]
        var choices: Array = scene.get("choices", [])
        for ci in range(choices.size()):
            if str(choices[ci].get("route_anchor", "")) == anchor and str(choices[ci].get("route_id", "")) == route:
                s.stage_state()["story_index"] = si
                s.stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)
                return s.story_choose(ci)
    return false

func _snapshot(anchor: String, route: String, seed_value: int) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(anchor, seed_value)
    var truth := JSON.stringify(s.truth)
    var packet := JSON.stringify(s.current_packet())
    check(_choose(s, anchor, route), "%s/%s selectable" % [anchor, route])
    var branch_ids: Array[String] = []
    var branch_text: Array[String] = []
    for scene in s.story_queue():
        var id := str(scene.get("id", ""))
        if id.begins_with("110_"):
            branch_ids.append(id)
            for line in scene.get("lines", []):
                branch_text.append(str(line[1]))
    return {
        "truth":truth, "packet":packet,
        "ids":"|".join(PackedStringArray(branch_ids)),
        "text":"|".join(PackedStringArray(branch_text)),
        "meeting":AstraStageStory.branch_meeting_context(anchor, route),
        "provenance":JSON.stringify(s.branch_provenance(anchor)),
        "signature":s.branch_signature()
    }

func _difference_count(a: Dictionary, b: Dictionary) -> int:
    var total := 0
    for key in ["ids","text","meeting","provenance","signature"]:
        if str(a.get(key, "")) != str(b.get(key, "")):
            total += 1
    return total

func run_audit() -> void:
    report.append("ASTRA 1.1.1 — replay fatigue audit")
    report.append("anchor\tsame_route_deterministic\talternate_visible_dimensions\ttruth_invariant")
    var seed_value := 31111
    for anchor in ROUTES:
        var routes: Array = ROUTES[anchor]
        var first := _snapshot(anchor, str(routes[0]), seed_value)
        var same := _snapshot(anchor, str(routes[0]), seed_value)
        check(str(first["truth"]) == str(same["truth"]) and str(first["packet"]) == str(same["packet"]),
            anchor + " same-route replay preserves canon truth")
        check(str(first["text"]) == str(same["text"]) and str(first["meeting"]) == str(same["meeting"]),
            anchor + " same-route authored route content is deterministic")
        var best_diff := 0
        for index in range(1, routes.size()):
            var alt := _snapshot(anchor, str(routes[index]), seed_value)
            check(str(first["truth"]) == str(alt["truth"]), anchor + " alternate route preserves Null/canon truth")
            check(str(first["packet"]) == str(alt["packet"]), anchor + " alternate route preserves base evidence")
            best_diff = maxi(best_diff, _difference_count(first, alt))
            check(_difference_count(first, alt) >= 2, "%s alternate %s differs in 2+ visible dimensions" % [anchor, str(routes[index])])
        report.append("%s\tPASS\t%d\tPASS" % [anchor, best_diff])
        seed_value += 101

    var callback_cases := {
        "GLASS_GARDEN":"DEAD_AIR", "SILENT_ORBIT":"ECHO_WARD", "LAST_LIGHT":"RED_SHIFT",
        "BLIND_DECK":"BORROWED_DAYS", "CONTINUITY":"THREE_MINUTES_DARK"
    }
    for case_id in callback_cases:
        var anchor := str(callback_cases[case_id])
        var routes: Array = ROUTES[anchor]
        var a := AstraStageStory.cross_stage_callback(case_id, {anchor:str(routes[0])})
        var b := AstraStageStory.cross_stage_callback(case_id, {anchor:str(routes[1])})
        check(not a.is_empty() and not b.is_empty(), case_id + " has next-stage visible callback for both routes")
        check(JSON.stringify(a) != JSON.stringify(b), case_id + " callback changes with route")
        var joined := JSON.stringify(a) + JSON.stringify(b)
        check("기억은 없" not in joined and "이유는 모르겠" not in joined,
            case_id + " callback does not explain residue with repeated memory disclaimer")

    report.append("")
    report.append("Repeat compression decision: no automatic mandatory-scene skip was added in 1.1.1.")
    report.append("Reason: current mandatory scenes interleave canon, route and consequence context; silent skipping would risk comprehension.")
    report.append("Existing seen_ever scheduling continues to suppress optional-scene repetition while alternate branch callbacks provide replay novelty.")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/replay_fatigue_111.txt", FileAccess.WRITE)
    file.store_string("\n".join(report))
    file.close()
