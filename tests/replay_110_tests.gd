extends SceneTree

# Same seed, same truth; player route changes scene/provenance/context instead.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func _initialize() -> void:
    test_same_seed_routes()
    test_three_minutes_dark()
    if failures.is_empty():
        print("ASTRA REPLAY 110 TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func _choose(s: AstraGameSession, anchor: String, route: String) -> bool:
    if s.voyage.is_empty():
        s.begin_voyage({})
    var queue := s.story_queue()
    for si in range(queue.size()):
        var scene: Dictionary = queue[si]
        var choices: Array = scene.get("choices", [])
        for ci in range(choices.size()):
            if str(choices[ci].get("route_anchor", "")) == anchor and str(choices[ci].get("route_id", "")) == route:
                s.stage_state()["story_index"] = si
                s.stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)
                return s.story_choose(ci)
    return false

func _snapshot(anchor: String, route: String, seed: int) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(anchor, seed)
    var truth := JSON.stringify(s.truth)
    var packet := JSON.stringify(s.current_packet())
    var ok := _choose(s, anchor, route)
    var ids: Array[String] = []
    var text: Array[String] = []
    for scene in s.story_queue():
        var id := str(scene.get("id", ""))
        if id.begins_with("110_"):
            ids.append(id)
            for line in scene.get("lines", []):
                text.append(str(line[1]))
    return {
        "ok":ok, "truth":truth, "packet":packet, "ids":"|".join(PackedStringArray(ids)),
        "text":"|".join(PackedStringArray(text)),
        "provenance":JSON.stringify(s.branch_provenance(anchor)),
        "meeting":AstraStageStory.branch_meeting_context(anchor, route),
        "signature":s.branch_signature(),
        "public_fact":AstraKnowledgeModel.is_public(s.flags, s.branch_fact_id(anchor)) if anchor != "THREE_MINUTES_DARK" else false
    }

func test_same_seed_routes() -> void:
    var route_map := {
        "DEAD_AIR":["PUBLIC","VERIFY_FIRST"],
        "ECHO_WARD":["TELL_SOREN","VERIFY_FIRST"],
        "RED_SHIFT":["REVEAL","WITHHOLD_VERIFY"],
        "BORROWED_DAYS":["TELL","OBSERVE"],
        "THREE_MINUTES_DARK":["POWER","COMMS","SECURITY"]
    }
    var seed := 21001
    for anchor in route_map:
        var rows: Array = []
        for route in route_map[anchor]:
            var row := _snapshot(anchor, str(route), seed)
            check(bool(row["ok"]), "%s/%s route selectable" % [anchor, route])
            rows.append(row)
        for index in range(1, rows.size()):
            check(str(rows[index]["truth"]) == str(rows[0]["truth"]), "%s same seed keeps Null/canon truth" % anchor)
            check(str(rows[index]["packet"]) == str(rows[0]["packet"]), "%s same seed keeps base incident/evidence" % anchor)
            var differences := 0
            if str(rows[index]["ids"]) != str(rows[0]["ids"]): differences += 1
            if str(rows[index]["text"]) != str(rows[0]["text"]): differences += 1
            if str(rows[index]["provenance"]) != str(rows[0]["provenance"]): differences += 1
            if str(rows[index]["meeting"]) != str(rows[0]["meeting"]): differences += 1
            if bool(rows[index]["public_fact"]) != bool(rows[0]["public_fact"]): differences += 1
            check(differences >= 2, "%s routes differ in 2+ player-visible dimensions" % anchor)
        seed += 101

func test_three_minutes_dark() -> void:
    var seed := 31011
    var baseline_truth := ""
    var baseline_packet := ""
    for route in ["POWER","COMMS","SECURITY"]:
        var s := AstraGameSession.new()
        s.setup("THREE_MINUTES_DARK", seed)
        if baseline_truth == "":
            baseline_truth = JSON.stringify(s.truth)
            baseline_packet = JSON.stringify(s.current_packet())
        check(_choose(s, "THREE_MINUTES_DARK", route), "THREE_MINUTES_DARK %s selectable" % route)
        check(JSON.stringify(s.truth) == baseline_truth, "%s keeps actor/Null truth" % route)
        check(JSON.stringify(s.current_packet()) == baseline_packet, "%s keeps incident truth" % route)
        var provenance := s.branch_provenance("THREE_MINUTES_DARK")
        var direct := 0
        for area in ["POWER","COMMS","SECURITY"]:
            if str(provenance.get(area, "")) == "DIRECT":
                direct += 1
        check(direct == 1 and str(provenance.get(route, "")) == "DIRECT", "%s alone is DIRECT" % route)
        var issues := AstraCaseGenerator.validate_day_packet(s.current_packet(), s.roster, Array(s.truth.get("nulls", [])))
        check(issues.is_empty(), "%s retains evidence fairness contract" % route)
