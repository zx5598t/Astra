extends SceneTree
# 0.7.0 character-depth audit (§22, §25, §38): every crew member has a
# complete personal arc chain, the four previously-unexplored pairs now have
# at least one dedicated scene with a real PAIR_CANDIDATES history entry,
# and no character — Soren/Lucan named explicitly by the design brief as a
# neglect risk — falls outside content_audit.gd's already-enforced spread.

var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    test_every_character_has_a_complete_arc()
    test_new_pairs_have_scenes_and_history()
    test_no_character_neglected()
    test_arcs_reach_act2()
    if failures.is_empty():
        print("ASTRA CHARACTER ARC 070 TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func test_every_character_has_a_complete_arc() -> void:
    for npc_id in AstraCrewCatalog.ORDER:
        check(AstraStorylets054.ARC_PACKS.has(npc_id),"%s has an ARC_PACKS entry" % npc_id)
        var stages: Array = AstraStorylets054.ARC_PACKS.get(npc_id,[])
        check(stages.size() == 4,"%s arc has exactly 4 beats" % npc_id)
        var chain_id := ""
        var seen_stages := {}
        for pack in stages:
            var stage := int(pack[0])
            var id := str(pack[3])
            if chain_id == "":
                chain_id = id
            check(id == chain_id,"%s arc beats share one chain_id" % npc_id)
            seen_stages[stage] = true
        for stage in range(1,5):
            check(seen_stages.has(stage),"%s arc has stage %d" % [npc_id,stage])

func test_new_pairs_have_scenes_and_history() -> void:
    var pairs := [["rho","vale"],["sena","noa"],["lyra","vale"],["eli","noa"]]
    var all_scenes := AstraVoyageContent.all_scenes()
    for pair in pairs:
        var a := str(pair[0])
        var b := str(pair[1])
        var found := false
        for scene in all_scenes:
            if str(scene.get("tag","")) != "pair":
                continue
            var speaker := str(scene.get("speaker",""))
            var target := str(scene.get("target",""))
            if (speaker == a and target == b) or (speaker == b and target == a):
                found = true
                break
        check(found,"%s:%s has at least one dedicated pair scene" % [a,b])
        var key := AstraCrewCatalog.pair_key(a,b)
        check(AstraCrewCatalog.PAIR_CANDIDATES.has(key),"%s has a dedicated PAIR_CANDIDATES entry, not the generic default" % key)
        check(AstraCrewCatalog.pair_candidates(a,b) != AstraCrewCatalog.CANDIDATES_DEFAULT,"%s pair history is not the generic fallback" % key)

func test_no_character_neglected() -> void:
    var totals := {}
    for scene in AstraVoyageContent.all_scenes():
        var speaker := str(scene.get("speaker",""))
        totals[speaker] = int(totals.get(speaker,0)) + 1
    var values: Array = []
    for npc_id in AstraCrewCatalog.ORDER:
        check(totals.has(npc_id) and int(totals[npc_id]) > 0,"%s has authored scenes" % npc_id)
        values.append(int(totals.get(npc_id,0)))
    var lowest: int = values.min()
    var highest: int = values.max()
    # content_audit.gd already enforces max-min > 2 as a floor on intentional
    # variety; here we additionally guard the specific neglect risk the
    # design brief names by ID, not just the aggregate spread.
    check(int(totals.get("vale",0)) >= 50,"Soren (vale) scene count is not starved (%d)" % int(totals.get("vale",0)))
    check(int(totals.get("eli",0)) >= 50,"Lucan (eli) scene count is not starved (%d)" % int(totals.get("eli",0)))
    check(highest - lowest > 2,"scene counts show intentional variety, not a mechanical quota")

func test_arcs_reach_act2() -> void:
    # Arc chain_ids are only reachable when a session's active_arcs includes
    # them, which in turn requires the chapter to pass storylets_054.gd's own
    # MID gate. Confirm ACT II days are in that gate (Phase 3 change) so
    # personal arcs begun in ACT I can actually resolve in ACT II instead of
    # going silent after LAST_LIGHT.
    for case_id in ["SECOND_WATCH","BORROWED_DAYS","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY","THRESHOLD"]:
        check(case_id in AstraStorylets054.MID,"%s is in storylets_054's MID gate for personal arcs" % case_id)
        check(case_id in AstraStorylets052.MID_CHAPTERS,"%s is in storylets_052's MID_CHAPTERS gate for pair/trio scenes" % case_id)
