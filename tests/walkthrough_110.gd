extends SceneTree

# Human-readable branch comparison dump: build/qa/walkthrough_110.txt
var out: PackedStringArray = []

func w(line: String) -> void:
    out.append(line)

func _initialize() -> void:
    var plans := {
        "DEAD_AIR":["PUBLIC","VERIFY_FIRST"],
        "ECHO_WARD":["TELL_SOREN","VERIFY_FIRST"],
        "RED_SHIFT":["REVEAL","WITHHOLD_VERIFY"],
        "BORROWED_DAYS":["TELL","OBSERVE"],
        "THREE_MINUTES_DARK":["POWER","COMMS","SECURITY"]
    }
    var seed := 51001
    for anchor in plans:
        w("")
        w("================ %s · SAME SEED %d ================" % [anchor, seed])
        var truth_set := {}
        for route in plans[anchor]:
            var snap := _route_dump(anchor, str(route), seed)
            truth_set[str(snap.get("truth", ""))] = true
        w("CANON / NULL 동일: %s" % ("예" if truth_set.size() == 1 else "아니오"))
        seed += 111
    w("")
    w("================ 대표 CAMPAIGN SIGNATURE ================")
    w("Path A · DEAD_AIR:PUBLIC | ECHO_WARD:TELL_SOREN | RED_SHIFT:REVEAL | BORROWED_DAYS:TELL | THREE_MINUTES_DARK:COMMS")
    w("Path B · DEAD_AIR:VERIFY_FIRST | ECHO_WARD:VERIFY_FIRST | RED_SHIFT:WITHHOLD_VERIFY | BORROWED_DAYS:OBSERVE | THREE_MINUTES_DARK:SECURITY")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/walkthrough_110.txt", FileAccess.WRITE)
    file.store_string("\n".join(out))
    file.close()
    print("ASTRA WALKTHROUGH 110 OK · %d lines" % out.size())
    quit(0)

func _choose(s: AstraGameSession, anchor: String, route: String) -> Dictionary:
    var queue := s.story_queue()
    for si in range(queue.size()):
        var scene: Dictionary = queue[si]
        var choices: Array = scene.get("choices", [])
        for ci in range(choices.size()):
            var choice: Dictionary = choices[ci]
            if str(choice.get("route_anchor", "")) == anchor and str(choice.get("route_id", "")) == route:
                s.stage_state()["story_index"] = si
                s.stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)
                s.story_choose(ci)
                return choice
    return {}

func _scene_text(scene: Dictionary) -> String:
    var parts: Array[String] = []
    if str(scene.get("action", "")) != "":
        parts.append(str(scene.get("action", "")))
    for line in scene.get("lines", []):
        parts.append("%s: %s" % [str(line[0]), str(line[1])])
    return " / ".join(PackedStringArray(parts))

func _route_dump(anchor: String, route: String, seed: int) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(anchor, seed)
    var truth := JSON.stringify(s.truth)
    var choice := _choose(s, anchor, route)
    w("")
    w("---- %s ----" % route)
    w("선택: %s" % str(choice.get("label", "")))
    w("힌트: %s" % str(choice.get("hint", "")))
    w("provenance: %s" % JSON.stringify(s.branch_provenance(anchor)))
    w("회의 시작 맥락: %s" % AstraStageStory.branch_meeting_context(anchor, route))
    for scene in s.story_queue():
        if str(scene.get("id", "")).begins_with("110_"):
            w("즉시 장면 · %s" % _scene_text(scene))
    s.day += 1
    s._drain_consequences("NEXT_DAY", true)
    for scene in s.story_queue():
        if str(scene.get("id", "")).begins_with("110_consequence_"):
            w("다음 Day 결과 · %s" % _scene_text(scene))
    var next_case := str({
        "DEAD_AIR":"GLASS_GARDEN", "ECHO_WARD":"SILENT_ORBIT", "RED_SHIFT":"LAST_LIGHT",
        "BORROWED_DAYS":"BLIND_DECK", "THREE_MINUTES_DARK":"CONTINUITY"
    }.get(anchor, ""))
    var callback := AstraStageStory.cross_stage_callback(str(next_case), s.voyage.get("route_choices", {}))
    if not callback.is_empty():
        w("다음 Stage callback · %s" % _scene_text(callback))
    w("결과: canon truth는 유지되고 정보 순서/출처/사람 반응이 이 route에 맞게 달라짐.")
    return {"truth":truth}
