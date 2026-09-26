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
    test_consequence_bridge()
    test_snapshot_dedup()
    if failures.is_empty():
        print("ASTRA CHOICE 110 TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    printerr("ASTRA CHOICE 110 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

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
    var scene := _seek_anchor(s, anchor)
    if scene.is_empty():
        return false
    var choices: Array = scene.get("choices", [])
    for index in range(choices.size()):
        if str(choices[index].get("route_id", "")) == route:
            return s.story_choose(index)
    return false

func _history_count(s: AstraGameSession, event_id: String) -> int:
    var count := 0
    for event in s.voyage.get("consequence_history", []):
        if str(event.get("id", "")) == event_id:
            count += 1
    return count

func test_branch_reachability() -> void:
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

func _install_scene(s: AstraGameSession, scene_id: String) -> bool:
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
    check("sena_protection_conflict_echo" in tags, "NEXT_LOOP residue uses memory tag rather than episodic dialogue")

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
