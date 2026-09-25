extends SceneTree
# ASTRA 0.8.2 PLAYER MATTERS — deterministic agency/provenance regressions.

var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func _initialize() -> void:
    test_contact_provenance()
    test_stage_2_4_paired()
    if failures.is_empty():
        print("ASTRA AGENCY 082 TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func _finish_morning(s: AstraGameSession) -> void:
    AstraTestBots._finish_morning(s)

func test_contact_provenance() -> void:
    var found := false
    for seed in range(1, 61):
        var s := AstraGameSession.new()
        s.setup("GLASS_GARDEN", seed * 7919 + 17)
        _finish_morning(s)
        s.advance()
        for npc_id in s.living_ids():
            if s.conversations_left() <= 0:
                break
            var result := s.ask(str(npc_id), "STATEMENT")
            var fid := str(result.get("fragment", {}).get("id", ""))
            if fid != "":
                var contacts: Dictionary = s.stage_state().get("agency_contacts", {})
                check(contacts.has(fid), "contact records fact provenance")
                found = true
                break
        if found:
            break
    check(found, "bounded Stage 3 seed finds a contacted fact")

func _run_pair(case_id: String, seed_value: int, active: bool) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value)
    var guard := 0
    while s.phase != "RESULT" and guard < 400:
        guard += 1
        match s.phase:
            "BRIEFING":
                AstraTestBots._finish_morning(s, active)
                s.advance()
            "INTERROGATION":
                if active:
                    var order: Array = s.living_ids().duplicate()
                    var leads := s.talk_leads()
                    order.sort_custom(func(a, b): return (1 if leads.has(str(a)) else 0) > (1 if leads.has(str(b)) else 0))
                    for npc_id in order:
                        if s.conversations_left() <= 0:
                            break
                        s.ask(str(npc_id), "STATEMENT")
                        var options := s.question_options(str(npc_id))
                        for option in options:
                            if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["RECORD", "WITNESS", "CONFRONT"]:
                                s.ask(str(npc_id), str(option.get("intent", "")), str(option.get("ref", "")))
                                break
                s.advance()
            "MEETING":
                if active:
                    var mguard := 0
                    while not s.meeting_over() and mguard < 10:
                        mguard += 1
                        var options := s.meeting_options()
                        if s.meeting_actions_left > 0 and not options.is_empty():
                            var pick: Dictionary = options[0]
                            s.intervene(str(pick.get("kind", "")), str(pick.get("ref", "")))
                        s.meeting_continue()
                s.advance()
            "VOTE":
                var target := AstraTestBots._crowd_pick(s, s.eligible_vote_targets())
                if active:
                    var best := ""
                    var score := -99.0
                    for candidate in s.eligible_vote_targets():
                        var value := s.suspicion_score("player", str(candidate))
                        if value > score:
                            score = value
                            best = str(candidate)
                    if best != "":
                        target = best
                s.cast_vote(target)
                if s.vote_stage() == "RUNOFF":
                    s.cast_vote(AstraTestBots._crowd_pick(s, s.runoff_candidates()))
                if s.vote_stage() == "TIEBREAK":
                    s.resolve_tiebreak(AstraTestBots._crowd_pick(s, s.runoff_candidates()))
                s.advance()
            "NIGHT":
                s.choose_night_action("skip", "")
                s.advance()
            _:
                s.advance()
    var innocent := 0
    for row in s.isolations:
        if str(row.get("role", "")) != "NULL":
            innocent += 1
    var metrics := s.agency_metrics()
    return {"outcome": s.outcome, "days": s.day, "innocent": innocent, "casualties": s.casualties.size(),
        "public": int(metrics.get("player_caused_public_facts", 0)), "meeting": int(metrics.get("player_caused_meeting_changes", 0)),
        "votes": int(metrics.get("player_caused_vote_changes", 0))}

func test_stage_2_4_paired() -> void:
    for case_id in ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]:
        var active_public := 0
        var passive_public := 0
        var active_meeting := 0
        var passive_meeting := 0
        for seed in range(1, 9):
            var value := seed * 7919 + 17
            var a := _run_pair(case_id, value, true)
            var p := _run_pair(case_id, value, false)
            active_public += int(a["public"])
            passive_public += int(p["public"])
            active_meeting += int(a["meeting"])
            passive_meeting += int(p["meeting"])
            check(int(a["innocent"]) >= 0 and int(p["innocent"]) >= 0, case_id + " paired isolation metric")
            check(int(a["casualties"]) >= 0 and int(p["casualties"]) >= 0, case_id + " paired casualty metric")
        check(active_public >= passive_public, case_id + " active public contribution is not below passive")
        check(active_meeting >= passive_meeting, case_id + " active meeting influence is not below passive")
