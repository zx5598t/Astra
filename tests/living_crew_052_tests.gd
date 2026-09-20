extends SceneTree

# ASTRA 0.5.2 living-crew invariant gates.
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_baselines()
    test_storylet_registry()
    test_relationship_axes()
    test_rolling_memory()
    test_knowledge_invariant()
    test_session_living_state()
    test_innocent_discrepancy_types()
    test_vote_explanations()
    test_private_clue_never_becomes_vote_source()
    test_deterministic_living_replay()
    if failures.is_empty():
        print("ASTRA 0.5.2 LIVING CREW TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.2 LIVING CREW TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_baselines() -> void:
    for npc_id in AstraCrewCatalog.ORDER:
        var profile := AstraLivingCrew.profile(npc_id)
        check(profile.has("baseline") and Array(profile["baseline"]).size() >= 4, npc_id + " has a concrete personality baseline")
        check(not str(profile.get("stress_response","")).is_empty(), npc_id + " has a stress response")
        check(not str(profile.get("lie_style","")).is_empty(), npc_id + " has a distinct lie style")
        check(not Dictionary(profile.get("content_weights",{})).is_empty(), npc_id + " has content weights")
    check(AstraLivingCrew.REASON_TAGS.size() >= 10, "baseline deviations have explicit reason vocabulary")

func test_storylet_registry() -> void:
    var added := AstraStorylets052.scenes()
    var all := AstraVoyageContent.all_scenes()
    check(added.size() >= 100, "0.5.2 adds at least 100 authored reactive/social scenes (%d)" % added.size())
    check(all.size() >= 470 and all.size() <= 550, "total authored scene library stays in 0.5.3 470-550 target (%d)" % all.size())
    var ids := {}
    var deviation_count := 0
    var early_leaks := 0
    for scene in added:
        var scene_id := str(scene.get("id",""))
        check(scene_id != "" and not ids.has(scene_id), "storylet id is unique: " + scene_id)
        ids[scene_id] = true
        var chapters: Array = scene.get("chapters",[])
        if "CALIBRATION" in chapters or "DEAD_AIR" in chapters or "GLASS_GARDEN" in chapters:
            early_leaks += 1
        if scene.has("deviation_reason"):
            deviation_count += 1
            check(str(scene.get("deviation_reason","")) in AstraLivingCrew.REASON_TAGS, scene_id + " deviation has allowed reason")
            check(not str(scene.get("source_event","")).is_empty(), scene_id + " deviation has source_event")
            check(not str(scene.get("possible_followup","")).is_empty(), scene_id + " deviation has possible_followup")
    check(early_leaks == 0, "new library does not increase first-30-minute mandatory pool")
    check(deviation_count >= 10, "authored library contains reasoned baseline deviations (%d)" % deviation_count)
    var by_speaker := AstraStorylets052.count_by_speaker()
    var values: Array = by_speaker.values()
    check(int(values.max()) - int(values.min()) >= 6, "character content density is intentionally non-uniform (%d-%d)" % [int(values.min()),int(values.max())])

func test_relationship_axes() -> void:
    var relation := AstraLivingCrew.relationship_from(
        {"type":"professional_conflict","tone":"tense","trust_delta":-0.04},
        0.2,-0.1
    )
    for axis in AstraLivingCrew.AXES:
        check(relation.has(axis), "relationship stores " + axis)
        check(float(relation[axis]) >= 0.0 and float(relation[axis]) <= 1.0, axis + " stays normalized")
    check("RESPECTS_SKILL" in relation.get("tags",[]), "professional conflict can retain skill respect")
    var text := AstraLivingCrew.relationship_status(relation)
    check(not text.is_empty() and not text.contains("%"), "relationship UI is qualitative, not a percentage")

func test_rolling_memory() -> void:
    var memory := {}
    for i in range(12):
        memory = AstraLivingCrew.remember(memory,"noa",{"type":"test","index":i},6)
    check(Array(memory.get("noa",[])).size() == 6, "NPC rolling memory is bounded")
    check(int(Array(memory["noa"])[0].get("index",-1)) == 6, "rolling memory retains recent events, not an infinite log")
    var profile := AstraLivingCrew.blank_player_profile()
    profile = AstraLivingCrew.register_player_action(profile,"record")
    profile = AstraLivingCrew.register_player_action(profile,"keep_copy")
    check(AstraLivingCrew.dominant_player_axis(profile) == "evidence_first", "player behavioral profile is inferred from actions")

func test_knowledge_invariant() -> void:
    var flags := {}
    AstraKnowledgeModel.discover_player(flags,"K1",1)
    check(AstraKnowledgeModel.knows(flags,"player","K1"), "player knows a found fact")
    check(not AstraKnowledgeModel.knows(flags,"noa","K1"), "unshared private fact is unknown to NPC")
    AstraKnowledgeModel.share_with(flags,"K1","noa",2)
    check(AstraKnowledgeModel.knows(flags,"noa","K1"), "specific share grants knowledge only to recipient")
    check(not AstraKnowledgeModel.knows(flags,"rho","K1"), "specific share does not diffuse globally")
    AstraKnowledgeModel.make_public(flags,"K1",["noa","rho","mira"],2)
    check(AstraKnowledgeModel.knows(flags,"rho","K1") and AstraKnowledgeModel.knows(flags,"mira","K1"), "public fact reaches active participants")
    check("because" in AstraKnowledgeModel.trace_text(flags,"noa","K1"), "knowledge provenance is debug-traceable")

func test_session_living_state() -> void:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD",52052)
    s.begin_voyage({"loops":2})
    check(str(s.voyage.get("social_theme","")) in AstraLivingCrew.SOCIAL_THEMES, "loop has one social theme")
    check(not Dictionary(s.voyage.get("relationships",{})).is_empty(), "loop initializes multidimensional relationships")
    check(not s.current_questions().is_empty(), "chapter starts with an open curiosity question")
    check(s.voyage.has("dialogue_memory_052"), "session owns bounded dialogue memory")
    check(s.voyage.has("deviations"), "session records reasoned deviations")
    var first_pair := ""
    for key in s.voyage.get("relationships",{}):
        first_pair = str(key)
        break
    if first_pair != "":
        var parts := first_pair.split(":")
        check(not s.relationship_status(parts[0],parts[1]).is_empty(), "relationship status can be expressed in natural language")

func test_innocent_discrepancy_types() -> void:
    var seen := {}
    var misremembered := 0
    for seed_value in range(350):
        var truth := AstraCaseGenerator.generate("LAST_LIGHT", 750000 + seed_value * 19, [], "STANDARD")
        var reason := str(truth.get("herring_reason",""))
        seen[reason] = true
        var herring := str(truth.get("herring",""))
        var claim: Dictionary = truth.get("claims",{}).get(herring,{})
        if reason == "MISREMEMBERED":
            misremembered += 1
            check(not bool(claim.get("lie",true)), "MISREMEMBERED is not classified as a lie")
            check(bool(claim.get("misremembered",false)), "MISREMEMBERED carries explicit memory flag")
        else:
            check(bool(claim.get("lie",false)), reason + " remains an intentional innocent lie")
    for reason in AstraCaseGenerator.INNOCENT_SECRET_TYPES:
        check(str(reason) in seen, "seed sweep reaches innocent discrepancy type " + str(reason))
    check(misremembered > 0, "seed sweep includes sincere misremembering")

func test_vote_explanations() -> void:
    var non_abstain := 0
    for seed_value in range(80):
        var s := AstraGameSession.new()
        s.setup("ECHO_WARD",60000 + seed_value)
        var active := s.active_participants()
        for i in range(active.size()):
            var voter := str(active[i])
            var target := str(active[(i + 1) % active.size()])
            if voter != target:
                s.crew[voter].add_suspicion(target,1.4)
        var intentions := s.vote_intentions()
        for voter in intentions:
            var target := str(intentions[voter])
            if target == "":
                continue
            non_abstain += 1
            var trace := s._vote_decision_trace(str(voter),target)
            check(not str(trace.get("explanation","")).is_empty(), "non-abstain vote has human-readable reason")
            check(str(trace.get("strongest_reason","")) != "random", "vote reason is never RNG")
            check(not Array(trace.get("reasons",[])).is_empty(), "vote trace keeps at least one understandable reason")
    check(non_abstain >= 100, "vote explanation test samples many non-abstain ballots (%d)" % non_abstain)

func test_private_clue_never_becomes_vote_source() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",70520)
    var clue: Dictionary = s.clues[0]
    s._discover(clue,false)
    var clue_id := str(clue.get("id",""))
    check(not bool(clue.get("public",false)), "test clue remains private")
    for npc_id in s.active_participants():
        check(not s.npc_knows_fact(str(npc_id),clue_id), str(npc_id) + " does not magically know player-only clue")
    var voter := str(s.active_participants()[0])
    var target := str(s.active_participants()[1])
    s.crew[voter].add_suspicion(target,1.5)
    var trace := s._vote_decision_trace(voter,target)
    for reason in trace.get("reasons",[]):
        check(str(reason.get("source","")) != clue_id, "private clue is absent from vote decision trace")

func test_deterministic_living_replay() -> void:
    var memory := {"loops":3}
    var a := AstraGameSession.new()
    var b := AstraGameSession.new()
    a.setup("LAST_LIGHT",313370)
    b.setup("LAST_LIGHT",313370)
    a.begin_voyage(memory)
    b.begin_voyage(memory)
    check(str(a.voyage.get("social_theme","")) == str(b.voyage.get("social_theme","")), "same seed gives same social theme")
    check(str(a.voyage.get("past",{})) == str(b.voyage.get("past",{})), "same seed gives same pair histories")
    check(str(a.voyage.get("loop_hook",{})) == str(b.voyage.get("loop_hook",{})), "same seed gives same loop hook")
