extends SceneTree

# ACTION stays the player's decision; RECEPTION is history-sensitive only.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func _initialize() -> void:
    test_actions_and_reception()
    if failures.is_empty():
        print("ASTRA FINALE 110 TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func _session_with_tally(tally: Dictionary) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("THRESHOLD", 41001)
    s.voyage["campaign_tally_in"] = tally.duplicate(true)
    return s

func test_actions_and_reception() -> void:
    var choices: Array = AstraStageStory.FINALE_CHOICE.get("choices", [])
    check(choices.size() == 3, "three final actions remain available")
    var effects: Array[String] = []
    for choice in choices:
        effects.append(str(choice.get("effect", "")))
    check("finale:share" in effects and "finale:wake" in effects and "finale:keep" in effects, "share/wake/keep actions preserved")

    var warm_tally := {"defended":{"mira":2},"saved":{"sena":2},"sent_wrong":{}}
    var strained_tally := {"defended":{},"saved":{},"sent_wrong":{"mira":2,"rho":2}}
    for action in ["share","wake","keep"]:
        var warm := _session_with_tally(warm_tally)
        warm._queue_finale(action)
        check(warm.finale_action() == action, "%s action is not overwritten by history" % action)
        check(warm.finale_reception() == "WARM", "%s can receive warm reception" % action)
        var strained := _session_with_tally(strained_tally)
        strained._queue_finale(action)
        check(strained.finale_action() == action, "%s remains selected under strained history" % action)
        check(strained.finale_reception() == "STRAINED", "%s can receive strained reception" % action)

    var a := _session_with_tally(warm_tally)
    var b := _session_with_tally(warm_tally)
    a._queue_finale("share")
    b._queue_finale("share")
    check(a.finale_reception() == b.finale_reception(), "same visible history + action is deterministic")

    var open_routes := {"DEAD_AIR":"PUBLIC","ECHO_WARD":"TELL_SOREN","RED_SHIFT":"REVEAL","BORROWED_DAYS":"TELL","THREE_MINUTES_DARK":"COMMS"}
    var verify_routes := {"DEAD_AIR":"VERIFY_FIRST","ECHO_WARD":"VERIFY_FIRST","RED_SHIFT":"WITHHOLD_VERIFY","BORROWED_DAYS":"OBSERVE","THREE_MINUTES_DARK":"SECURITY"}
    var open_s := _session_with_tally({})
    open_s.voyage["route_choices"] = open_routes
    open_s._queue_finale("share")
    var verify_s := _session_with_tally({})
    verify_s.voyage["route_choices"] = verify_routes
    verify_s._queue_finale("share")
    var open_ids: Array[String] = []
    var verify_ids: Array[String] = []
    for scene in open_s.story_queue():
        open_ids.append(str(scene.get("id", "")))
    for scene in verify_s.story_queue():
        verify_ids.append(str(scene.get("id", "")))
    check("finale_route_open" in open_ids, "open-handling campaign leaves a finale residue callback")
    check("finale_route_verify" in verify_ids, "verify-first campaign leaves a different finale residue callback")
    check(open_s.finale_action() == verify_s.finale_action(), "route history changes reception texture, not final action")
    var source := FileAccess.get_file_as_string("res://scripts/core/game_session.gd")
    var start := source.find("func _finale_reception_from_history")
    var stop := source.find("\nfunc ", start + 6)
    var body := source.substr(start, stop - start)
    check("truth" not in body and "null" not in body.to_lower(), "reception selector does not read hidden role/truth")
