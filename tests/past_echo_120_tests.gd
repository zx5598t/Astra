extends SceneTree

# ASTRA 1.2.0 AFTERIMAGE — Past Echo eligibility, fairness and runtime wiring.
var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_catalog_scope()
    test_requires_real_experience()
    test_runtime_direction_not_truth()
    test_maren_lucan_roles()
    test_snapshot_roundtrip()
    if failures.is_empty():
        print("ASTRA PAST ECHO 120 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA PAST ECHO 120 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _memory_for_route(anchor: String, route: String = "TEST_ROUTE") -> Dictionary:
    return {
        "route_choices":{anchor:route},
        "route_history":[{"anchor":anchor,"route":route,"loop":0,"day":1}],
        "memory_tags":[],
        "scene_seen_counts":{},
        "loops":1
    }

func _find_echo_scene(s: AstraGameSession) -> Dictionary:
    for scene in s.story_queue():
        if str(scene.get("id", "")).begins_with("120_past_echo_"):
            return scene
    return {}

func _choose_echo(s: AstraGameSession) -> bool:
    var queue := s.story_queue()
    for index in range(queue.size()):
        var scene: Dictionary = queue[index]
        if not str(scene.get("id", "")).begins_with("120_past_echo_"):
            continue
        s.stage_state()["story_index"] = index
        s.stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)
        return s.story_choose(0)
    return false

func test_catalog_scope() -> void:
    var catalog: Array = AstraForeknowledgeModel.PAST_ECHO_OPPORTUNITIES
    check(catalog.size() >= 8 and catalog.size() <= 12, "Past Echo catalog stays within 8-12 focused opportunities")
    var stages := {}
    var ids := {}
    for raw in catalog:
        var row: Dictionary = raw
        stages[str(row.get("case", ""))] = true
        var id := str(row.get("id", ""))
        check(id != "" and not ids.has(id), "Past Echo id is unique: " + id)
        ids[id] = true
        check(not Array(row.get("requires", [])).is_empty() or not Array(row.get("requires_any", [])).is_empty(), id + " has direct-experience eligibility")
        var visible := str(row.get("label", "")) + str(row.get("question", "")) + str(row.get("context", ""))
        check(not "Null이다" in visible and not "정답" in visible, id + " never states hidden truth")
    check(stages.size() >= 5, "Past Echo opportunities are distributed across 5+ Stages")

func test_requires_real_experience() -> void:
    var empty_memory := {"chapters":["DEAD_AIR","GLASS_GARDEN","ECHO_WARD"],"loops":5}
    check(AstraForeknowledgeModel.past_echo_candidates("SILENT_ORBIT", empty_memory).is_empty(), "Stage number/completion alone cannot unlock an Echo")
    var earned := _memory_for_route("DEAD_AIR", "PUBLIC")
    var candidates := AstraForeknowledgeModel.past_echo_candidates("SILENT_ORBIT", earned)
    check(candidates.size() == 1, "actually experienced DEAD_AIR route unlocks SILENT_ORBIT Echo")
    var forged := AstraGameSession.new()
    forged.setup("SILENT_ORBIT", 12001)
    forged.begin_voyage(empty_memory)
    forged._apply_past_echo("route_after_dead_air")
    check(str(forged.stage_state().get("past_echo_used", "")) == "", "runtime re-check rejects an unearned crafted Echo")

func test_runtime_direction_not_truth() -> void:
    var memory := _memory_for_route("DEAD_AIR", "VERIFY_FIRST")
    var s := AstraGameSession.new()
    s.setup("SILENT_ORBIT", 12021)
    var truth_before := JSON.stringify(s.truth)
    var packet_before := JSON.stringify(s.current_packet())
    s.begin_voyage(memory)
    var scene := _find_echo_scene(s)
    check(not scene.is_empty(), "earned Echo is inserted into existing story choice UI")
    check(Array(scene.get("choices", [])).size() == 2, "Echo remains optional")
    check(str(Array(scene.get("choices", []))[0].get("label", "")).begins_with("[잔향]"), "player-facing Echo has a small existing-choice indicator")
    check(_choose_echo(s), "Echo choice is selectable")
    check(JSON.stringify(s.truth) == truth_before, "Echo cannot change Null/current truth")
    check(JSON.stringify(s.current_packet()) == packet_before, "Echo cannot replace required evidence packet")
    check(str(s.stage_state().get("past_echo_question", "")) != "", "Echo changes the investigation question")
    check(s.talk_leads().has("eli"), "Echo changes investigation priority toward the relevant expert")
    check(str(s.stage_state().get("past_echo_context", "")) != "", "Echo carries concise context into meeting")
    check(Array(s.voyage.get("foreknowledge_reactions", [])).size() == 1, "an available NPC notices the too-precise direction")

    var same := AstraGameSession.new()
    same.setup("SILENT_ORBIT", 12021)
    same.begin_voyage(memory)
    check(str(_find_echo_scene(same).get("id", "")) == str(scene.get("id", "")), "same seed and same experience keep Echo deterministic")

func test_maren_lucan_roles() -> void:
    var lucan_memory := {"memory_tags":["eli:054_eli_stable_route"],"route_choices":{},"scene_seen_counts":{},"loops":2}
    var lucan := AstraForeknowledgeModel.past_echo_candidates("BLIND_DECK", lucan_memory)
    check(not lucan.is_empty() and str(lucan[0].get("lead", "")) == "eli", "Lucan feasibility/risk/route memory creates gameplay priority")
    check("시간" in str(lucan[0].get("question", "")) or "경로" in str(lucan[0].get("question", "")), "Lucan Echo asks about actual route feasibility")

    var maren_memory := {"memory_tags":["lyra:054_lyra_saved_sample"],"route_choices":{},"scene_seen_counts":{},"loops":2}
    var maren := AstraForeknowledgeModel.past_echo_candidates("CONTINUITY", maren_memory)
    check(not maren.is_empty() and str(maren[0].get("lead", "")) == "lyra", "Maren environmental continuity memory creates gameplay priority")
    check("생장" in str(maren[0].get("question", "")) and "관리" in str(maren[0].get("question", "")), "Maren Echo reads physical continuity rather than mutable logs")

func test_snapshot_roundtrip() -> void:
    var s := AstraGameSession.new()
    s.setup("SILENT_ORBIT", 12041)
    s.begin_voyage(_memory_for_route("DEAD_AIR", "PUBLIC"))
    check(_choose_echo(s), "snapshot fixture activates Echo")
    var save_path := "user://past_echo_120.cfg"
    AstraGameSession.delete_snapshot(save_path)
    check(s.save_snapshot(save_path), "Echo state snapshot saves")
    var loaded := AstraGameSession.new()
    check(loaded.load_snapshot(save_path), "Echo state snapshot reloads")
    check(str(loaded.stage_state().get("past_echo_used", "")) == "route_after_dead_air", "Echo use survives mid-Stage save/load")
    check(str(loaded.stage_state().get("past_echo_question", "")) == str(s.stage_state().get("past_echo_question", "")), "Echo investigation direction survives save/load")
    check(Array(loaded.voyage.get("foreknowledge_used", [])).has("route_after_dead_air"), "Echo use ledger survives save/load")
    AstraGameSession.delete_snapshot(save_path)
