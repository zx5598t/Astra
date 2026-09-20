extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_vote_change_legibility()
    test_authored_opinion_context()
    if failures.is_empty():
        print("ASTRA 0.5.4 DECISION LEGIBILITY TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 DECISION LEGIBILITY TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_vote_change_legibility() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",4201)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    s.day = 2
    var active := s.active_participants()
    check(active.size() >= 4,"decision report seed has a usable active roster")

    # Give each innocent a concrete suspicion so the vote has readable reasons,
    # then fabricate yesterday's public ballot as a different choice.
    for i in range(active.size()):
        var voter := str(active[i])
        var target := str(active[(i + 1) % active.size()])
        if voter != target:
            s.crew[voter].add_suspicion(target,1.5)
    var now := s.vote_intentions()
    var previous := {}
    for i in range(active.size()):
        var voter := str(active[i])
        var alt := str(active[(i + 2) % active.size()])
        if alt == voter:
            alt = ""
        if str(now.get(voter,"")) == alt:
            alt = ""
        previous[voter] = alt
    s.flags["vote_history_052"] = [{"day":1,"intentions":previous,"reasons":{}}]
    s.phase = "VOTE"
    s.vote_cast = false
    var result := s.cast_vote("")
    check(bool(result.get("ok",false)),"seed 4201 vote resolves for legibility report")

    var vote: Dictionary = result.get("result",{})
    var changes: Array = vote.get("vote_changes",[])
    check(not changes.is_empty(),"at least one NPC visibly changes opinion from the prior ballot")
    for change in changes:
        check(not str(change.get("reason","")).is_empty(),"vote change has human-readable reason")
        check(str(change.get("strongest_reason","")) != "random","vote change never cites RNG as its reason")
        check(str(change.get("reason_tag","")) in ["new_evidence","relationship_change","memory_change","uncertainty"],"vote change reason is categorized")

    var opinion: Array = s.voyage.get("opinion_changes",[])
    check(opinion.size() >= changes.size(),"visible vote changes are retained in the opinion-change log")
    for entry in opinion:
        if str(entry.get("source","")) != "vote":
            continue
        check(entry.has("known_facts"),"vote opinion trace records what the NPC could know")
        check(entry.has("relationship_context"),"vote opinion trace records relationship context without exposing a numeric score")

    print("DECISION REPORT · SEED 4201")
    for voter in vote.get("intentions",{}):
        var target := str(vote["intentions"][voter])
        print("  %s voted %s · because: %s" % [
            s.name_of(str(voter)),
            "abstain" if target == "" else s.name_of(target),
            str(vote.get("vote_reasons",{}).get(voter,""))
        ])
    for change in changes:
        var before := str(change.get("before",""))
        var after := str(change.get("after",""))
        print("  CHANGE · %s · %s -> %s · %s / %s" % [
            s.name_of(str(change.get("voter",""))),
            "abstain" if before == "" else s.name_of(before),
            "abstain" if after == "" else s.name_of(after),
            str(change.get("reason_tag","")),
            str(change.get("reason",""))
        ])

func test_authored_opinion_context() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",540059)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    # Opinion-change storylets require at least one observed fact.
    s.voyage["facts"].append("destination")
    var candidate := {}
    for scene in AstraStorylets054.scenes():
        if not Dictionary(scene.get("opinion_change",{})).is_empty():
            candidate = scene
            break
    check(not candidate.is_empty(),"0.5.4 authored opinion-change scenes exist")
    var who := str(candidate.get("speaker",""))
    s._voyage_scene(candidate)
    var entries: Array = s.voyage.get("opinion_changes",[])
    check(not entries.is_empty(),"authored opinion change is visible in state")
    var last: Dictionary = entries[entries.size()-1]
    check(str(last.get("actor","")) == who,"authored opinion trace keeps the actor")
    check(last.has("known_facts"),"authored opinion trace keeps knowledge context")
    check(last.has("relationship_context"),"authored opinion trace keeps relationship context")
