extends SceneTree

# ASTRA 0.5.1 stabilization gates.
# Keeps the 0.5.0 systems intact while checking that what the player sees is
# synchronized with the chapter that actually teaches it.

const META_PATH := "user://astra_051_meta_test.cfg"
var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_unlock_consistency()
    test_objective_consistency()
    test_archive_copy_consistency()
    test_onboarding_save_scope()
    test_new_character_ordering()
    test_meeting_coherence()
    test_dialogue_context()
    test_stale_selection()
    if failures.is_empty():
        print("ASTRA 0.5.1 STABILIZATION TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.1 STABILIZATION TESTS FAILED · %d of %d checks" % [failures.size(), checks])
        quit(1)

func test_unlock_consistency() -> void:
    var after_cal := AstraUnlocks.unlocked(true, 0)
    check("marks" in after_cal, "CALIBRATION completion exposes marks")
    check("meeting" not in after_cal and "vote" not in after_cal and "night" not in after_cal, "CALIBRATION does not expose meeting/vote/night")
    var after_dead := AstraUnlocks.unlocked(true, 1)
    check("meeting" in after_dead and "claim_search" in after_dead, "DEAD_AIR completion exposes meeting tools")
    check("vote" not in after_dead and "night" not in after_dead, "DEAD_AIR completion does not expose vote/night")
    var after_glass := AstraUnlocks.unlocked(true, 2)
    check("vote" in after_glass and "night" in after_glass, "GLASS_GARDEN completion exposes vote/night for ECHO_WARD")
    var after_echo := AstraUnlocks.unlocked(true, 3)
    check("private_talk" in after_echo and "theory_report" in after_echo and "night_tactics" in after_echo, "ECHO_WARD completion exposes advanced social/night tools")
    var after_silent := AstraUnlocks.unlocked(true, 4)
    check("hypothesis" in after_silent and "protocols" in after_silent, "SILENT_ORBIT completion exposes hypothesis/protocols")
    var after_red := AstraUnlocks.unlocked(true, 5)
    check("relationship_events" in after_red, "RED_SHIFT completion exposes relationship events")

func test_objective_consistency() -> void:
    for case_id in [AstraCaseCatalog.CALIBRATION] + AstraCaseCatalog.CAMPAIGN:
        var s := AstraGameSession.new()
        s.setup(str(case_id), 5100 + checks)
        var spec := s.chapter_objective_spec()
        var target := int(spec.get("target", 0))
        var ap := int(AstraCaseCatalog.ap_profile(str(case_id), {}).get("investigation", AstraGameSession.BASE_INVESTIGATION_AP))
        if str(case_id) == AstraCaseCatalog.CALIBRATION:
            ap = 1
        check(target > 0 and target <= ap, "%s story objective fits investigation budget (%d/%d)" % [str(case_id), target, ap])
        check("단서 5개" not in str(spec.get("label", "")), "%s has no stale five-clue objective" % str(case_id))
        check(not str(spec.get("description", "")).is_empty(), "%s has a concrete story objective" % str(case_id))

func test_archive_copy_consistency() -> void:
    var archive := AstraArchiveScreen.new()
    var dead := archive._case_goal_line("DEAD_AIR")
    var glass := archive._case_goal_line("GLASS_GARDEN")
    var echo := archive._case_goal_line("ECHO_WARD")
    check("격리" not in dead and "투표" not in dead, "DEAD_AIR archive copy does not ask for a vote")
    check("격리" not in glass and "투표" not in glass, "GLASS_GARDEN archive copy does not ask for a vote")
    check("격리" in echo, "ECHO_WARD archive copy introduces the first isolation decision")
    check("두 Null" not in dead + glass + echo, "archive copy does not hard-code two Nulls")
    archive.free()

func test_onboarding_save_scope() -> void:
    DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))
    var meta := AstraMetaProgress.new(META_PATH)
    check(not meta.intro_seen_for_slot(0) and not meta.intro_seen_for_slot(1), "new slots start with unseen calibration intro")
    meta.mark_intro_seen_for_slot(0)
    meta.mark_help_seen("INVESTIGATION")
    check(meta.save_data(), "0.5.1 onboarding state saves")
    var loaded := AstraMetaProgress.new(META_PATH)
    loaded.load_data()
    check(loaded.intro_seen_for_slot(0), "slot A remembers its intro")
    check(not loaded.intro_seen_for_slot(1), "slot B remains a fresh intro")
    check(loaded.has_seen_help("INVESTIGATION"), "feature help seen-state persists")
    loaded.reset_intro_for_slot(0)
    check(not loaded.intro_seen_for_slot(0), "deleting/resetting a slot clears only its intro state")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(META_PATH))

func _close_voyage_scene(s: AstraGameSession) -> void:
    var guard := 0
    while not s.voyage.get("scene", {}).is_empty() and guard < 30:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        var choices: Array = scene.get("choices", [])
        if int(s.voyage.get("line", -1)) >= scene.get("lines", []).size() - 1 and not choices.is_empty():
            s.voyage_choose(0)
        else:
            s.voyage_next()

func test_new_character_ordering() -> void:
    for case_id in AstraCaseCatalog.CAMPAIGN:
        var chapter := AstraVoyageContent.chapter(str(case_id))
        var waking := str(chapter.get("awake", ""))
        if waking == "":
            continue
        var s := AstraGameSession.new()
        s.setup(str(case_id), 6100 + checks)
        s.begin_voyage()
        var scene: Dictionary = s.voyage.get("scene", {})
        var expected_intro := "arrival_" + waking if s.contact_flow() else waking + "_awakening"
        check(str(scene.get("id", "")) == expected_intro, "%s opens with %s introduction before ordinary dialogue" % [str(case_id), waking])
        check(not s.voyage_talk(waking), "%s cannot enter ordinary dialogue while awakening is on screen" % waking)
        _close_voyage_scene(s)
        check(waking in s.voyage.get("met", []), "%s is marked introduced after awakening" % waking)
        # An introduced person may talk only once the awakening scene has closed.
        check(s.voyage.get("scene", {}).is_empty(), "%s awakening closes before ordinary scene selection" % waking)

func _play_to_meeting(seed_value: int) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD", seed_value, "ANALYST", "STANDARD")
    s.advance()
    for room_id in s.room_ids():
        while s.investigation_ap > 0:
            if s.search_room(str(room_id)).is_empty():
                break
    s.advance()
    if not s.pending_event.is_empty():
        s.resolve_private_event(0)
    for npc_id in s.living_ids():
        if s.talk_ap <= 0:
            break
        s.ask(str(npc_id), "ALIBI")
    if not s.pending_event.is_empty():
        s.resolve_private_event(0)
    s.advance()
    return s

func test_meeting_coherence() -> void:
    var thread_count := 0
    var long_threads := 0
    var four_plus := 0
    for seed_value in range(1, 501):
        var s := _play_to_meeting(80000 + seed_value)
        check(s.phase == "MEETING", "meeting seed %d reaches MEETING" % seed_value)
        var by_thread := {}
        var ids := {}
        var previous_thread := ""
        for entry in s.meeting_feed:
            var entry_id := str(entry.get("entry_id", ""))
            var thread_id := str(entry.get("thread_id", ""))
            check(entry_id != "" and thread_id != "", "meeting entries carry ids")
            ids[entry_id] = entry
            if previous_thread != "" and thread_id != previous_thread:
                check(bool(entry.get("topic_transition", false)), "new thread explicitly marks topic transition")
            var reply_to := str(entry.get("reply_to", ""))
            if reply_to != "":
                check(ids.has(reply_to), "reply points to an earlier visible entry")
                if ids.has(reply_to):
                    check(str(ids[reply_to].get("topic", "")) == str(entry.get("topic", "")), "reply stays on the same topic")
            if not by_thread.has(thread_id):
                by_thread[thread_id] = 0
            by_thread[thread_id] = int(by_thread[thread_id]) + 1
            previous_thread = thread_id
        for tid in by_thread:
            thread_count += 1
            var length := int(by_thread[tid])
            if length >= 3: long_threads += 1
            if length >= 4: four_plus += 1
    var ratio := float(long_threads) / maxf(1.0, float(thread_count))
    check(thread_count >= 500, "500 generated meetings provide enough thread samples (%d)" % thread_count)
    check(ratio >= 0.20, "at least 20%% of meeting threads reach 3+ turns (%.1f%%)" % (ratio * 100.0))
    check(ratio <= 0.75, "not every meeting thread is forced long (%.1f%%)" % (ratio * 100.0))
    check(four_plus > 0, "some important meeting threads reach 4+ turns")
    print("MEETING THREAD STATS · total=%d · 3+ turns=%d · 4+ turns=%d · long ratio=%.1f%%" % [thread_count, long_threads, four_plus, ratio * 100.0])

func _prepare_interrogation(seed_value: int) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD", seed_value, "ANALYST", "STANDARD")
    s.advance()
    for room_id in s.room_ids():
        if s.investigation_ap <= 0:
            break
        s.search_room(str(room_id))
    s.advance()
    if not s.pending_event.is_empty():
        s.resolve_private_event(0)
    return s

func test_dialogue_context() -> void:
    for intent in ["ALIBI", "WITNESS", "TIMELINE"]:
        var s := _prepare_interrogation(91000 + checks)
        var who := str(s.living_ids()[0])
        var result := s.ask(who, intent)
        check(bool(result.get("ok", false)), intent + " question executes")
        check(str(result.get("response_family", "")) == intent, intent + " answer stays in its intent family")
        for line in result.get("lines", []):
            check(str(line.get("intent", intent)) == intent, intent + " generated line carries matching context")

    var evidence_session := _prepare_interrogation(92001)
    var found := evidence_session.found_clues()
    check(not found.is_empty(), "evidence context test has a found clue")
    if not found.is_empty():
        var who2 := str(evidence_session.living_ids()[0])
        var result2 := evidence_session.ask(who2, "EVIDENCE", str(found[0].get("id", "")))
        check(bool(result2.get("ok", false)), "EVIDENCE question executes")
        check(str(result2.get("response_family", "")) == "EVIDENCE", "EVIDENCE answer stays in evidence family")
        check(str(result2.get("clue_topic", "")) != "", "EVIDENCE attaches a clue topic")

    var contradiction_session := _prepare_interrogation(92002)
    var who3 := str(contradiction_session.living_ids()[0])
    contradiction_session.manual_contradictions.append({
        "key":"test-context", "kind":"witness", "targets":[who3], "source":"test",
        "detail":"테스트용 공개 모순", "public":true
    })
    contradiction_session._recompute_contradictions()
    if contradiction_session.has_contradiction_on(who3):
        var result3 := contradiction_session.ask(who3, "CONTRADICTION")
        check(bool(result3.get("ok", false)), "CONTRADICTION question executes")
        check(str(result3.get("response_family", "")) == "CONTRADICTION", "CONTRADICTION answer stays in contradiction family")
    else:
        check(false, "manufactured contradiction becomes queryable")

func test_stale_selection() -> void:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD", 93001)
    var removed := str(s.active_participants()[0])
    s.selected_id = removed
    s.crew[removed].status = AstraCrewMember.STATUS_ISOLATED
    s._fallback_selected()
    check(s.selected_id != removed, "isolated selected NPC falls back immediately")
    check(s.selected_id == "" or s.selected_id in s.active_participants(), "fallback selection is active")
