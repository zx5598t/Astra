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
            if fid == "":
                var options := s.question_options(str(npc_id))
                for option in options:
                    if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["RECORD", "WITNESS"]:
                        result = s.ask(str(npc_id), str(option.get("intent", "")), str(option.get("ref", "")))
                        fid = str(result.get("fragment", {}).get("id", ""))
                        if fid != "":
                            break
            if fid != "":
                var contacts: Dictionary = s.stage_state().get("agency_contacts", {})
                check(contacts.has(fid), "contact records fact provenance")
                var contact: Dictionary = contacts.get(fid, {})
                check(str(contact.get("fact", "")) == fid, "contact provenance retains exact fact id")
                check(str(contact.get("npc", "")) == str(npc_id), "contact provenance retains source NPC")
                check(str(contact.get("action", "")) != "", "contact provenance retains player action")
                check(int(contact.get("day", 0)) == s.day, "contact provenance retains current day")
                found = true
                break
        if found:
            break
    check(found, "bounded Stage 3 seed finds a contacted fact")

func _crowd_pick(s: AstraGameSession, pool: Array) -> String:
    var tally := {}
    var intentions := s.vote_intentions(pool)
    for voter in intentions:
        var target := str(intentions[voter])
        tally[target] = int(tally.get(target, 0)) + 1
    var best := str(pool[0])
    for target in pool:
        if int(tally.get(str(target), 0)) > int(tally.get(best, 0)):
            best = str(target)
    return best

func _run_pair(case_id: String, seed_value: int, active: bool) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value)
    var guard := 0
    while s.phase != "RESULT" and guard < 400:
        guard += 1
        match s.phase:
            "BRIEFING":
                var sg := 0
                while not s.story_finished() and sg < 200:
                    sg += 1
                    var scene := s.story_scene()
                    if active and str(scene.get("kind", "")) == "interlude":
                        s.finish_interlude(str(scene.get("interlude", "")), "success")
                    elif not Array(scene.get("choices", [])).is_empty():
                        s.story_choose(0)
                    else:
                        s.story_next()
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
                var target := _crowd_pick(s, s.eligible_vote_targets())
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
                    s.cast_vote(_crowd_pick(s, s.runoff_candidates()))
                if s.vote_stage() == "TIEBREAK":
                    s.resolve_tiebreak(_crowd_pick(s, s.runoff_candidates()))
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
    var total_active_public := 0
    var total_passive_public := 0
    var total_active_meeting := 0
    var total_passive_meeting := 0
    var total_active_votes := 0
    var total_passive_votes := 0
    for case_id in ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]:
        var active_public := 0
        var passive_public := 0
        var active_meeting := 0
        var passive_meeting := 0
        var active_votes := 0
        var passive_votes := 0
        var active_totals := [0, 0, 0, 0]
        var passive_totals := [0, 0, 0, 0]
        for seed in range(1, 9):
            var value := seed * 7919 + 17
            var a := _run_pair(case_id, value, true)
            var p := _run_pair(case_id, value, false)
            for pair in [[a, active_totals], [p, passive_totals]]:
                pair[1][0] += 1 if str(pair[0]["outcome"]) == "WIN" else 0
                pair[1][1] += int(pair[0]["days"])
                pair[1][2] += int(pair[0]["innocent"])
                pair[1][3] += int(pair[0]["casualties"])
            active_public += int(a["public"])
            passive_public += int(p["public"])
            active_meeting += int(a["meeting"])
            passive_meeting += int(p["meeting"])
            active_votes += int(a["votes"])
            passive_votes += int(p["votes"])
            check(str(a["outcome"]) != "" and str(p["outcome"]) != "", case_id + " paired routes reach a result")
            check(int(a["days"]) >= 1 and int(p["days"]) >= 1, case_id + " paired routes record elapsed days")
        total_active_public += active_public
        print("AGENCY STAGE %s · ACTIVE/PASSIVE wins=%d/%d days=%d/%d innocent=%d/%d casualties=%d/%d public=%d/%d meeting=%d/%d votes=%d/%d (8 paired seeds)" % [case_id, active_totals[0], passive_totals[0], active_totals[1], passive_totals[1], active_totals[2], passive_totals[2], active_totals[3], passive_totals[3], active_public, passive_public, active_meeting, passive_meeting, active_votes, passive_votes])
        total_passive_public += passive_public
        total_active_meeting += active_meeting
        total_passive_meeting += passive_meeting
        total_active_votes += active_votes
        total_passive_votes += passive_votes
        # Passive play performs no conversation or meeting intervention, so it
        # must never manufacture player-caused provenance.
        check(passive_public == 0, case_id + " passive route creates no player-caused public fact")
        check(passive_meeting == 0, case_id + " passive route creates no player-caused meeting shift")
        check(passive_votes == 0, case_id + " passive route creates no player-caused vote change")
    print("AGENCY 082 PAIRED · public %d/%d · meeting %d/%d · votes %d/%d" % [
        total_active_public, total_passive_public, total_active_meeting, total_passive_meeting,
        total_active_votes, total_passive_votes])
    # Across the bounded Stage 2–4 fixtures, active play must exercise every
    # attribution path at least once. These are regression gates, not balance
    # targets; they prevent a future refactor from leaving telemetry wired but inert.
    check(total_active_public > 0, "active route causes at least one public fact")
    check(total_active_meeting > 0, "active route causes at least one meeting opinion shift")
    check(total_active_votes > 0, "active route causes at least one NPC vote-intention change")
