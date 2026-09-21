extends SceneTree

var failures: Array[String] = []
var checks := 0
const PATH := "user://astra_campaign_test.cfg"

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    var meta := AstraMetaProgress.new(PATH)
    # 0.4.0 puts the calibration case in front of the campaign, so the chain
    # starts one step earlier. Everything after that is the same sequence.
    check(meta.is_case_unlocked(AstraCaseCatalog.CALIBRATION), "calibration is open from the start")
    check(not meta.is_case_unlocked("DEAD_AIR"), "campaign waits for calibration")
    meta.calibration_completed = true
    for id in AstraCaseCatalog.CAMPAIGN:
        var s := AstraGameSession.new()
        s.setup(id, 4242)
        check(meta.is_case_unlocked(id), "sequential unlock " + id)
        check(not s.perform_mission().get("ok", false), "briefing rejects mission " + id)
        s.advance()
        var ap := s.investigation_ap
        check(s.perform_mission().get("ok", false), "mission executes " + id)
        check(s.investigation_ap == ap - 1, "mission costs one action " + id)
        check(not s.perform_mission().get("ok", false), "mission cannot repeat " + id)
        check(s.mission_status()["complete"] and s.objectives()[2]["complete"], "objective updates " + id)
        if id == "SILENT_ORBIT":
            check(s.talk_ap_max() == 5, "relay grants one talk action on top of 0.5.0 baseline")
        if id == "RED_SHIFT":
            check(s.meeting_actions_max() == 3, "meeting upgrade")
        if id == "LAST_LIGHT":
            check(s.investigation_ap_max() == 4, "core bonus delayed")
            s.day = 2
            check(s.investigation_ap_max() == 5, "core next day bonus")
        if id == "ECHO_WARD":
            check(s.found_clues().size() == 1, "recovery discovers clue")
        check(s.save_snapshot(PATH), "snapshot save " + id)
        var loaded := AstraGameSession.new()
        check(loaded.load_snapshot(PATH), "snapshot restore " + id)
        check(loaded.rng.state == s.rng.state and loaded.flags == s.flags, "snapshot RNG and mission state " + id)
        var room := str(s.room_ids()[0])
        check(s.search_room(room) == loaded.search_room(room), "resumed search identical " + id)

        # Exercise overwrite + .bak recovery while the chapter is still in a
        # resumable phase. DEAD_AIR and GLASS_GARDEN now legitimately finish
        # before the old VOTE/NIGHT sequence, and RESULT is intentionally not
        # snapshot-able.
        check(s.save_snapshot(PATH), "snapshot overwrite " + id)
        var corrupt := FileAccess.open(PATH, FileAccess.WRITE)
        corrupt.store_string("not a config file")
        corrupt.close()
        var recovered := AstraGameSession.new()
        check(recovered.load_snapshot(PATH), "backup recovers damaged save " + id)
        AstraGameSession.delete_snapshot(PATH)

        s.advance()
        loaded.advance()
        check(s.pending_event == loaded.pending_event, "resumed event identical " + id)
        if not s.pending_event.is_empty():
            s.resolve_private_event(0)
            loaded.resolve_private_event(0)
        s.advance()
        loaded.advance()
        check(s.meeting_feed == loaded.meeting_feed, "resumed meeting identical " + id)
        if s.phase == "MEETING":
            s.advance()
            loaded.advance()
        if s.phase == "VOTE":
            check(s.cast_vote("mira") == loaded.cast_vote("mira"), "resumed vote identical " + id)
        check(not AstraGameSession.has_snapshot(PATH), "snapshot removed " + id)
        var report := {"outcome": "WIN", "total": 3000, "rank": "A", "mission_complete": true, "objectives": s.objectives()}
        meta.record_case_result(id, "ANALYST", report, false)
    check(meta.campaign_complete(), "six chapters complete")
    check(meta.story_archive().size() == 6, "six archive entries")
    check(meta.save_data(), "archive saved")
    var roundtrip := AstraMetaProgress.new(PATH)
    roundtrip.load_data()
    check(roundtrip.mission_badges.size() == 6 and roundtrip.campaign_complete(), "archive progress persists")
    AstraGameSession.delete_snapshot(PATH)
    var recovery := AstraGameSession.new()
    recovery.setup("ECHO_WARD", 21)
    recovery.advance()
    var lost: Dictionary = recovery.clues[3]
    lost["destroyed"] = true
    recovery.perform_mission()
    check(lost["found"] and not lost["destroyed"], "recovery prioritizes destroyed clue")
    if failures.is_empty():
        print("ASTRA CAMPAIGN TESTS OK · %d checks" % checks)
        quit(0)
    else:
        for failure in failures:
            printerr("FAIL · " + failure)
        quit(1)
