extends SceneTree

# ASTRA 1.1.0 LIVING PATHS — runtime choice/consequence acceptance.
var failures: Array[String] = []
var checks := 0

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func _initialize() -> void:
    test_branch_reachability()
    test_branch_knowledge()
    test_consequence_bridge()
    test_snapshot_dedup()
    test_rewind_boundary()
    test_deep_boundary()
    if failures.is_empty():
        print("ASTRA CHOICE 110 TESTS OK · %d checks" % checks)
        quit(0)
        return
    for failure in failures:
        printerr("FAIL · " + failure)
    printerr("ASTRA CHOICE 110 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _prepare(s: AstraGameSession) -> void:
    if s.voyage.is_empty():
        s.begin_voyage({})

func _seek_anchor(s: AstraGameSession, anchor: String) -> Dictionary:
    var queue := s.story_queue()
    for index in range(queue.size()):
        var scene: Dictionary = queue[index]
        for choice in scene.get("choices", []):
            if str(choice.get("route_anchor", "")) == anchor:
                s.stage_state()["story_index"] = index
                s.stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)
                return scene
    return {}

func _pick_route(s: AstraGameSession, anchor: String, route: String) -> bool:
    _prepare(s)
    var scene := _seek_anchor(s, anchor)
    if scene.is_empty():
        return false
    var choices: Array = scene.get("choices", [])
    for index in range(choices.size()):
        if str(choices[index].get("route_id", "")) == route:
            return s.story_choose(index)
    return false

func _choice_scene_has_consequence(scene: Dictionary) -> bool:
    for choice in scene.get("choices", []):
        if not Array(choice.get("consequences", [])).is_empty():
            return true
    return false

func _choice_scene_expressive_only(scene: Dictionary) -> bool:
    var choices: Array = scene.get("choices", [])
    if choices.is_empty():
        return false
    for choice in choices:
        if not bool(choice.get("expressive_choice", false)):
            return false
    return true

func _micro_runtime_slot(scene: Dictionary) -> bool:
    var speaker := str(scene.get("speaker", ""))
    var chapters: Array = scene.get("chapters", [])
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        if not chapters.is_empty() and case_id not in chapters:
            continue
        if speaker in AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id)):
            return true
    return false

func _write_choice_audit(retired_options: int) -> void:
    var branch_scenes: Array = []
    var branch_two := 0
    var branch_three := 0
    var branch_consequence := 0
    var branch_expressive := 0
    for anchor in AstraStageStory.BRANCH_ANCHORS:
        var scene := {"id":"branch_" + str(anchor), "choices":AstraStageStory.branch_choices(str(anchor))}
        branch_scenes.append(scene)
        var count := Array(scene["choices"]).size()
        if count == 2: branch_two += 1
        if count == 3: branch_three += 1
        if _choice_scene_has_consequence(scene): branch_consequence += 1
        if _choice_scene_expressive_only(scene): branch_expressive += 1

    var micro_scenes: Array = []
    var micro_two := 0
    var micro_three := 0
    var micro_consequence := 0
    var micro_expressive := 0
    var unreachable := 0
    for scene_id in AstraGameSession.LIVING_PATHS_CHOICE_SCENES:
        var scene := AstraVoyageContent.scene(scene_id)
        micro_scenes.append(scene)
        var count := Array(scene.get("choices", [])).size()
        if count == 2: micro_two += 1
        if count == 3: micro_three += 1
        if _choice_scene_has_consequence(scene): micro_consequence += 1
        if _choice_scene_expressive_only(scene): micro_expressive += 1
        if not _micro_runtime_slot(scene):
            unreachable += 1

    var probe := AstraGameSession.new()
    var protocol_scenes := 0
    var protocol_two := 0
    var protocol_three := 0
    for stage in range(1, AstraCaseCatalog.STAGE_ORDER.size() + 1):
        var count := probe.protocols_for_stage(stage).size()
        if count > 1:
            protocol_scenes += 1
            if count == 2: protocol_two += 1
            if count == 3: protocol_three += 1

    var finale_count := Array(AstraStageStory.FINALE_CHOICE.get("choices", [])).size()
    var finale_two := 1 if finale_count == 2 else 0
    var finale_three := 1 if finale_count == 3 else 0

    var choice_scene_count := branch_scenes.size() + micro_scenes.size() + protocol_scenes + 1
    var two_option_count := branch_two + micro_two + protocol_two + finale_two
    var three_option_count := branch_three + micro_three + protocol_three + finale_three
    var consequence_scene_count := branch_consequence + micro_consequence
    var expressive_only_count := branch_expressive + micro_expressive

    var timing_source: Array = branch_scenes.duplicate(true)
    timing_source.append_array(micro_scenes)
    var timings := AstraConsequenceModel.timing_counts(timing_source)

    check(choice_scene_count == 22, "1.1 main-loop choice scene set is 22")
    check(two_option_count == 9, "1.1 main-loop has 9 two-option scenes")
    check(three_option_count == 13, "1.1 main-loop has 13 three-option scenes")
    check(consequence_scene_count == 13, "13 selected 1.1 choice scenes have authored consequences")
    check(unreachable == 0, "selected 1.1 choice scene definitions all have a valid runtime roster/chapter slot")

    var lines: PackedStringArray = [
        "ASTRA 1.1.0 — choice audit",
        "",
        "player_visible_choice_scene_set\t%d" % choice_scene_count,
        "retired_meaningless_resolution_options\t%d" % retired_options,
        "branch_choice_scenes\t%d" % branch_scenes.size(),
        "selected_micro_choice_scenes\t%d" % micro_scenes.size(),
        "protocol_choice_scenes\t%d" % protocol_scenes,
        "finale_choice_scenes\t1",
        "two_option_scenes\t%d" % two_option_count,
        "three_option_scenes\t%d" % three_option_count,
        "consequence_enabled_scenes\t%d" % consequence_scene_count,
        "expressive_only_scenes\t%d" % expressive_only_count,
        "unreachable_selected_choice_scenes\t%d" % unreachable,
        "",
        "consequence_IMMEDIATE\t%d" % int(timings.get("IMMEDIATE", 0)),
        "consequence_DELAYED\t%d" % int(timings.get("DELAYED", 0)),
        "consequence_NEXT_DAY\t%d" % int(timings.get("NEXT_DAY", 0)),
        "consequence_NEXT_LOOP\t%d" % int(timings.get("NEXT_LOOP", 0))
    ]
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/choice_110_report.txt", FileAccess.WRITE)
    file.store_string("\n".join(lines))
    file.close()

func _history_count(s: AstraGameSession, event_id: String) -> int:
    var count := 0
    for event in s.voyage.get("consequence_history", []):
        if str(event.get("id", "")) == event_id:
            count += 1
    return count

func test_branch_reachability() -> void:
    var retired_options := Array(AstraStageStory.CALIBRATION_RESOLUTION.get("choices", [])).size()
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        if case_id == AstraCaseCatalog.CALIBRATION:
            continue
        var authored: Dictionary = AstraVoyageContent.RESOLUTION_BEATS.get(case_id, {})
        retired_options += Array(authored.get("choices", [])).size()
        check(Array(AstraVoyageContent.resolution_thread(case_id).get("choices", [])).is_empty(), "%s redundant resolution choices are not player-visible" % case_id)
    var micro_options := 0
    var micro_two := 0
    var micro_three := 0
    for scene_id in AstraGameSession.LIVING_PATHS_CHOICE_SCENES:
        var count := Array(AstraVoyageContent.scene(scene_id).get("choices", [])).size()
        micro_options += count
        if count == 2: micro_two += 1
        if count == 3: micro_three += 1
    print("CHOICE 110 AUDIT · retired_resolution_options=%d · branch_options=11 · selected_micro_options=%d · micro_2choice=%d · micro_3choice=%d" % [retired_options, micro_options, micro_two, micro_three])
    _write_choice_audit(retired_options)
    check(retired_options >= 30, "30+ shallow resolution buttons retired (%d)" % retired_options)
    var expected := {
        "DEAD_AIR":["PUBLIC","VERIFY_FIRST"],
        "ECHO_WARD":["TELL_SOREN","VERIFY_FIRST"],
        "RED_SHIFT":["REVEAL","WITHHOLD_VERIFY"],
        "BORROWED_DAYS":["TELL","OBSERVE"],
        "THREE_MINUTES_DARK":["POWER","COMMS","SECURITY"]
    }
    var seed := 11001
    for anchor in expected:
        var base := AstraGameSession.new()
        base.setup(anchor, seed)
        var scene := _seek_anchor(base, anchor)
        check(not scene.is_empty(), "%s branch anchor is runtime reachable" % anchor)
        var choices: Array = scene.get("choices", [])
        check(choices.size() == Array(expected[anchor]).size(), "%s has intended route count" % anchor)
        for route in expected[anchor]:
            var s := AstraGameSession.new()
            s.setup(anchor, seed)
            var before_truth := JSON.stringify(s.truth)
            var before_packet := JSON.stringify(s.current_packet())
            check(_pick_route(s, anchor, str(route)), "%s/%s selectable" % [anchor, route])
            check(s.branch_route(anchor) == route, "%s/%s records visible route" % [anchor, route])
            check(JSON.stringify(s.truth) == before_truth, "%s/%s leaves canon truth unchanged" % [anchor, route])
            check(JSON.stringify(s.current_packet()) == before_packet, "%s/%s leaves base incident/evidence unchanged" % [anchor, route])
            var chosen := {}
            for choice in choices:
                if str(choice.get("route_id", "")) == route:
                    chosen = choice
            check(Array(chosen.get("observable_categories", [])).size() >= 2, "%s/%s has 2+ observable consequence categories" % [anchor, route])
            check(not s.branch_provenance(anchor).is_empty(), "%s/%s records provenance" % [anchor, route])
            var immediate := false
            for event in s.voyage.get("consequence_history", []):
                if str(event.get("timing", "")) == "IMMEDIATE" and str(event.get("source_scene", "")) == str(scene.get("id", "")):
                    immediate = true
            check(immediate, "%s/%s immediate consequence actually fires" % [anchor, route])
            AstraTestBots._finish_morning(s)
            check(s.story_finished(), "%s/%s has no story dead end" % [anchor, route])
        seed += 97


func test_branch_knowledge() -> void:
    var public_s := AstraGameSession.new()
    public_s.setup("DEAD_AIR", 11501)
    check(_pick_route(public_s, "DEAD_AIR", "PUBLIC"), "DEAD_AIR public knowledge fixture")
    var dead_fact := public_s.branch_fact_id("DEAD_AIR")
    check(AstraKnowledgeModel.is_public(public_s.flags, dead_fact), "DEAD_AIR PUBLIC becomes actual public knowledge")
    var public_steps := AstraKnowledgeModel.provenance(public_s.flags, dead_fact)
    check(not public_steps.is_empty() and str(public_steps.back().get("reason", "")) == "branch_choice", "public branch provenance records branch_choice")

    var verify_s := AstraGameSession.new()
    verify_s.setup("DEAD_AIR", 11501)
    check(_pick_route(verify_s, "DEAD_AIR", "VERIFY_FIRST"), "DEAD_AIR verify knowledge fixture")
    var verify_fact := verify_s.branch_fact_id("DEAD_AIR")
    check(not AstraKnowledgeModel.is_public(verify_s.flags, verify_fact), "VERIFY_FIRST stays non-public")
    check(AstraKnowledgeModel.knows(verify_s.flags, "player", verify_fact) and AstraKnowledgeModel.knows(verify_s.flags, "noa", verify_fact), "VERIFY_FIRST is initially shared only through the verification route")

    var borrowed := AstraGameSession.new()
    borrowed.setup("BORROWED_DAYS", 11502)
    check(_pick_route(borrowed, "BORROWED_DAYS", "OBSERVE"), "BORROWED_DAYS observe knowledge fixture")
    var habit_fact := borrowed.branch_fact_id("BORROWED_DAYS")
    check(AstraKnowledgeModel.knows(borrowed.flags, "player", habit_fact), "OBSERVE gives the player the observation")
    check(not AstraKnowledgeModel.knows(borrowed.flags, "sena", habit_fact) and not AstraKnowledgeModel.knows(borrowed.flags, "rho", habit_fact), "OBSERVE does not pre-share the observation with Sena/Jun")

    var dark := AstraGameSession.new()
    dark.setup("THREE_MINUTES_DARK", 11503)
    check(_pick_route(dark, "THREE_MINUTES_DARK", "COMMS"), "THREE_MINUTES_DARK provenance fixture")
    for area in ["POWER","COMMS","SECURITY"]:
        var fact_id := dark.branch_fact_id("THREE_MINUTES_DARK", area)
        check(AstraKnowledgeModel.knows(dark.flags, "player", fact_id), "TMD %s remains reachable to player" % area)
        var steps := AstraKnowledgeModel.provenance(dark.flags, fact_id)
        check(not steps.is_empty(), "TMD %s has provenance path" % area)
    check(str(dark.voyage.get("information_sources", {}).get(dark.branch_fact_id("THREE_MINUTES_DARK", "COMMS"), "")) == "DIRECT", "chosen TMD area is actually DIRECT in runtime state")

func test_rewind_boundary() -> void:
    var path := "user://choice_110_dawn.cfg"
    AstraGameSession.delete_snapshot(path)
    var dawn := AstraGameSession.new()
    dawn.setup("ECHO_WARD", 14001)
    dawn.begin_voyage({})
    var inherited: Dictionary = dawn.voyage.get("route_choices", {})
    inherited["DEAD_AIR"] = "PUBLIC"
    dawn.voyage["route_choices"] = inherited
    check(dawn.save_snapshot(path), "rewind fixture dawn snapshot saves")
    check(_pick_route(dawn, "ECHO_WARD", "TELL_SOREN"), "post-dawn route can be chosen")
    check(dawn.branch_route("ECHO_WARD") == "TELL_SOREN", "post-dawn route recorded before rewind")
    var restored := AstraGameSession.new()
    check(restored.load_snapshot(path), "dawn snapshot restores")
    check(restored.branch_route("DEAD_AIR") == "PUBLIC", "pre-dawn prior-Stage route survives rewind")
    check(restored.branch_route("ECHO_WARD") == "", "post-dawn route is rolled back")
    check(_pick_route(restored, "ECHO_WARD", "VERIFY_FIRST"), "rewind lets player choose the branch again")
    AstraGameSession.delete_snapshot(path)

func test_deep_boundary() -> void:
    var deep := AstraGameSession.new()
    deep.setup_deep("ECHO_WARD", 15001, "ANALYST", 9, "SILENT_DECK")
    var branch_choice_seen := false
    for scene in deep.story_queue():
        for choice in scene.get("choices", []):
            branch_choice_seen = branch_choice_seen or str(choice.get("route_anchor", "")) != ""
    check(not branch_choice_seen, "Deep does not expose campaign branch anchors")
    check(deep.branch_signature() == "", "Deep starts without campaign route signature")

func _install_scene(s: AstraGameSession, scene_id: String) -> bool:
    _prepare(s)
    var scene := AstraVoyageContent.scene(scene_id)
    if scene.is_empty():
        return false
    s._set_story_queue([s._scene_entry(scene, "micro_arc")])
    s.stage_state()["story_index"] = 0
    s.stage_state()["story_line"] = maxi(0, Array(scene.get("lines", [])).size() - 1)
    return true

func test_consequence_bridge() -> void:
    var delayed := AstraGameSession.new()
    delayed.setup("BORROWED_DAYS", 12001)
    check(_install_scene(delayed, "054_vale_listening_fatigue_2"), "Soren authored choice fixture exists")
    delayed.story_choose(0)
    check(Array(delayed.voyage.get("consequence_queue", [])).any(func(e): return str(e.get("timing", "")) == "DELAYED"), "DELAYED metadata is enqueued")
    delayed._advance_consequence_clock()
    delayed._advance_consequence_clock()
    check(int(delayed.voyage.get("consequence_stats", {}).get("DELAYED", 0)) >= 1, "DELAYED consequence is delivered")
    check(not Array(delayed.voyage.get("pending_consequence_scenes", [])).is_empty(), "DELAYED authored follow-up becomes visible pending content")

    var next_day := AstraGameSession.new()
    next_day.setup("BORROWED_DAYS", 12002)
    check(_install_scene(next_day, "054_lyra_save_sample_2"), "Maren authored choice fixture exists")
    next_day.story_choose(0)
    next_day.day += 1
    next_day._drain_consequences("NEXT_DAY", false)
    check(int(next_day.voyage.get("consequence_stats", {}).get("NEXT_DAY", 0)) >= 1, "NEXT_DAY consequence is delivered")

    var next_loop := AstraGameSession.new()
    next_loop.setup("BORROWED_DAYS", 12003)
    check(_install_scene(next_loop, "054_sena_overprotection_2"), "Sena authored choice fixture exists")
    next_loop.story_choose(1)
    next_loop.voyage["loop"] = int(next_loop.voyage.get("loop", 0)) + 1
    next_loop._drain_consequences("NEXT_LOOP", false)
    check(int(next_loop.voyage.get("consequence_stats", {}).get("NEXT_LOOP", 0)) >= 1, "NEXT_LOOP consequence is delivered as residue")
    var tags: Array = next_loop.voyage.get("memory_tags", [])
    check("sena:sena_protection_conflict_echo" in tags, "NEXT_LOOP residue stores the authored character-scoped memory tag")
    var loop_event := {}
    for event in next_loop.voyage.get("consequence_history", []):
        if str(event.get("id", "")) == "sena-risk-loop":
            loop_event = event
            break
    check(str(loop_event.get("followup_scene", "")) == "", "NEXT_LOOP residue does not replay an episodic follow-up scene")

func test_snapshot_dedup() -> void:
    var path := "user://choice_110_snapshot.cfg"
    AstraGameSession.delete_snapshot(path)
    var s := AstraGameSession.new()
    s.setup("DEAD_AIR", 13001)
    check(_pick_route(s, "DEAD_AIR", "PUBLIC"), "snapshot fixture branch selected")
    var event := {}
    for raw in s.voyage.get("consequence_history", []):
        if str(raw.get("id", "")) == "110-dead-air-public-now":
            event = Dictionary(raw).duplicate(true)
    check(not event.is_empty(), "snapshot fixture immediate event exists")
    check(_history_count(s, "110-dead-air-public-now") == 1, "event applied exactly once before save")
    check(s.save_snapshot(path), "1.1 route state saves in Snapshot v4")
    var loaded := AstraGameSession.new()
    check(loaded.load_snapshot(path), "1.1 route state loads from Snapshot v4")
    check(loaded.branch_route("DEAD_AIR") == "PUBLIC", "route survives save/load")
    var before := _history_count(loaded, "110-dead-air-public-now")
    loaded._apply_consequence_event(event, true)
    check(_history_count(loaded, "110-dead-air-public-now") == before, "same event id cannot apply twice after load")
    AstraGameSession.delete_snapshot(path)
