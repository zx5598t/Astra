extends SceneTree

# HUMAN RHYTHM finale gate: ACTION stays authoritative; RECEPTION changes the
# human beat in visibly different ways without becoming a nine-ending tree.
var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    run_tests()
    if failures.is_empty():
        print("ASTRA FINALE 111 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA FINALE 111 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _session(tally: Dictionary) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("THRESHOLD", 41111)
    s.begin_voyage({})
    s.voyage["campaign_tally_in"] = tally.duplicate(true)
    return s

func _finale_signature(s: AstraGameSession) -> String:
    var parts: PackedStringArray = []
    for scene in s.story_queue():
        var id := str(scene.get("id", ""))
        if not (id.begins_with("epilogue_") or id.begins_with("finale_")):
            continue
        parts.append(id + "|" + str(scene.get("speaker", "")) + "|" + str(scene.get("action", "")))
        for line in scene.get("lines", []):
            parts.append(str(line[0]) + ":" + str(line[1]))
    return "\n".join(parts)

func _reception_scene(s: AstraGameSession) -> Dictionary:
    var wanted := "finale_reception_" + s.finale_reception().to_lower()
    for scene in s.story_queue():
        if str(scene.get("id", "")) == wanted:
            return scene
    return {}

func run_tests() -> void:
    var tallies := {
        "WARM":{"defended":{"mira":2},"saved":{"sena":2},"sent_wrong":{}},
        "CAUTIOUS":{"defended":{"mira":1},"saved":{},"sent_wrong":{"rho":1}},
        "STRAINED":{"defended":{},"saved":{},"sent_wrong":{"mira":2,"rho":2}}
    }
    var by_action := {}
    for action in ["share","wake","keep"]:
        var signatures := {}
        for reception in ["WARM","CAUTIOUS","STRAINED"]:
            var s := _session(Dictionary(tallies[reception]))
            s._queue_finale(action)
            check(s.finale_action() == action, action + " remains the player's final action under " + reception)
            check(s.finale_reception() == reception, action + " reaches " + reception + " from visible history")
            var scene := _reception_scene(s)
            check(not scene.is_empty(), action + "/" + reception + " has a visible reception scene")
            check(Array(scene.get("lines", [])).size() >= 2, action + "/" + reception + " has a human beat, not a label swap")
            signatures[reception] = _finale_signature(s)
        check(str(signatures["WARM"]) != str(signatures["CAUTIOUS"]), action + " warm/cautious transcripts differ")
        check(str(signatures["CAUTIOUS"]) != str(signatures["STRAINED"]), action + " cautious/strained transcripts differ")
        check(str(signatures["WARM"]) != str(signatures["STRAINED"]), action + " warm/strained transcripts differ")
        by_action[action] = str(signatures["CAUTIOUS"])
    check(str(by_action["share"]) != str(by_action["wake"]), "SHARE and WAKE retain different emotional centers")
    check(str(by_action["wake"]) != str(by_action["keep"]), "WAKE and KEEP retain different emotional centers")
    check(str(by_action["share"]) != str(by_action["keep"]), "SHARE and KEEP retain different emotional centers")

    for key in ["OPEN","VERIFY","MIXED"]:
        var scene: Dictionary = AstraStageStory.FINALE_ROUTE_CALLBACKS[key]
        var joined := str(scene.get("action", ""))
        for line in scene.get("lines", []):
            joined += " " + str(line[1])
        check("이상하게" not in joined and "이유는 모르" not in joined and "익숙" not in joined,
            key + " route residue is shown through behavior, not memory-disclaimer prose")

    var source := FileAccess.get_file_as_string("res://scripts/core/game_session.gd")
    var start := source.find("func _finale_reception_from_history")
    var stop := source.find("\nfunc ", start + 6)
    var body := source.substr(start, stop - start)
    check("truth" not in body and "null" not in body.to_lower(), "reception still ignores hidden role/truth")
