extends SceneTree

# Headless test suite.
#   godot --headless --path . --script res://tests/run_tests.gd
# Optional: -- --games=200 for longer balance simulations.

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    var games := 60
    for arg in OS.get_cmdline_user_args():
        if str(arg).begins_with("--games="):
            games = int(str(arg).substr(8))
    var sim_only := "--sim-only" in OS.get_cmdline_user_args()
    if sim_only:
        test_simulations(games)
        print("SIM DONE")
        quit(0)
        return
    test_josa()
    test_crew_traits()
    test_generator()
    test_session_flow()
    test_protocols()
    test_meeting_limits()
    test_night_and_endings()
    test_meta_progress()
    test_simulations(games)
    if failures.is_empty():
        print("ASTRA TESTS OK · %d checks" % checks)
        quit(0)
    else:
        for failure in failures:
            printerr("FAIL · " + failure)
        printerr("ASTRA TESTS FAILED · %d of %d checks" % [failures.size(), checks])
        quit(1)

func check(condition: bool, label: String) -> void:
    checks += 1
    if not condition:
        failures.append(label)

func test_josa() -> void:
    check(AstraJosa.eun("Mira") == "Mira는", "josa Mira는")
    check(AstraJosa.eun("소렌") == "소렌은", "josa Vale은")
    check(AstraJosa.i("의료실") == "의료실이", "josa 의료실이")
    check(AstraJosa.ro("의료실") == "의료실로", "josa 의료실로 (ㄹ)")
    check(AstraJosa.ro("엔진실") == "엔진실로", "josa 엔진실로")
    check(AstraJosa.ro("통신 콘솔") == "통신 콘솔로", "josa 콘솔로")
    check(AstraJosa.eul("라운지") == "라운지를", "josa 라운지를")
    check(AstraJosa.wa("다렌") == "다렌과", "josa Dax와")
    check(AstraJosa.fill("{a|eul} 봤어요", {"a": "준"}) == "준을 봤어요", "fill token")
    check(AstraJosa.join_names(["Mira", "Noa", "Daren"]) == "Mira, Noa와 Daren", "join names")

func test_crew_traits() -> void:
    for npc_id in AstraCrewCatalog.ORDER:
        check(not AstraCrewCatalog.identifying_pairs(npc_id).is_empty(), "identifying trait pair for " + npc_id)
        check(AstraDialogue.has_line(npc_id, "m_alibi_alone") and AstraDialogue.has_line(npc_id, "slip"), "dialogue coverage for " + npc_id)
        check(AstraPrivateEvents.has_event(npc_id), "private event for " + npc_id)
    var keys: Array = AstraDialogue.LINES["mira"].keys()
    for npc_id in AstraCrewCatalog.ORDER:
        for key in keys:
            check(AstraDialogue.has_line(npc_id, str(key)), "line %s for %s" % [key, npc_id])

func test_generator() -> void:
    var intersect_ok := 0
    var total := 0
    for case_id in AstraCaseCatalog.CAMPAIGN:
        for seed_value in range(1, 151):
            var t := AstraCaseGenerator.generate(case_id, seed_value)
            total += 1
            var nulls: Array = t["nulls"]
            check(nulls.size() == AstraCaseCatalog.null_count(AstraCaseCatalog.get_case(case_id)) and (nulls.size()==1 or nulls[0]!=nulls[1]), "%s/%d distinct roster-sized influences" % [case_id, seed_value])
            check(str(t["herring"]) not in nulls, "%s/%d herring is innocent" % [case_id, seed_value])
            for npc_id in AstraCaseCatalog.roster(AstraCaseCatalog.get_case(case_id)):
                var claim: Dictionary = t["claims"].get(npc_id, {})
                check(not claim.is_empty(), "%s/%d claim for %s" % [case_id, seed_value, npc_id])
                var honest: bool = npc_id not in nulls and str(npc_id) != str(t["herring"])
                if honest:
                    check(str(claim["position"]) == str(t["positions"][npc_id]), "%s/%d honest claim position %s" % [case_id, seed_value, npc_id])
                    for mate in claim["companions"]:
                        check(str(t["positions"][mate]) == str(t["positions"][npc_id]), "%s/%d honest companion %s" % [case_id, seed_value, npc_id])
                else:
                    check(str(claim["position"]) != str(t["positions"][npc_id]), "%s/%d liar claim differs %s" % [case_id, seed_value, npc_id])
            var solved := 0
            for null_id in nulls:
                var sets: Array = []
                for clue in t["clues"]:
                    if str(clue["kind"]) == "trace" and str(clue["culprit"]) == null_id and not bool(clue["decoy"]):
                        check(null_id in clue["members"], "%s/%d trace includes culprit" % [case_id, seed_value])
                        sets.append(clue["members"])
                if sets.size() == 2:
                    var both: Array = []
                    for member_id in sets[0]:
                        if member_id in sets[1]:
                            both.append(member_id)
                    if both.size() == 1 and both[0] == null_id:
                        solved += 1
            if solved == nulls.size():
                intersect_ok += 1
            for clue in t["clues"]:
                if bool(clue["decoy"]):
                    check(str(clue["culprit"]) not in clue["members"], "%s/%d decoy excludes culprit" % [case_id, seed_value])
                    check(int(clue["minute"]) < int(AstraCaseCatalog.get_case(case_id)["window_start"]), "%s/%d decoy time outside window" % [case_id, seed_value])
                var text := str(clue["text"])
                check(text.find("{") < 0 and text.find("|") < 0, "%s/%d clue text fully formatted: %s" % [case_id, seed_value, text])
    check(intersect_ok == total, "every case solvable by trace intersection (%d/%d)" % [intersect_ok, total])

func test_session_flow() -> void:
    # SILENT_ORBIT still uses the historical 3/3/2 AP baseline this test's
    # hardcoded numbers assume; DEAD_AIR's is deliberately lower now (§8 of
    # the design notes).
    var s := AstraGameSession.new()
    s.setup("SILENT_ORBIT", 4242, "ANALYST")
    check(s.phase == "BRIEFING", "starts in briefing")
    check(s.can_advance(), "briefing can advance")
    s.advance()
    check(s.phase == "INVESTIGATION" and s.investigation_ap == 4, "analyst investigation AP 4")
    var before := s.found_clues().size()
    var clue := s.search_room(str(s.room_ids()[0]))
    check(not clue.is_empty() and s.found_clues().size() == before + 1 and s.investigation_ap == 3, "search consumes AP and finds clue")
    s.advance()
    check(s.phase == "INTERROGATION", "interrogation reached")
    if not s.pending_event.is_empty():
        check(not s.can_advance(), "private event blocks advance")
        var result := s.resolve_private_event(mini(1,s.pending_event.get("choices",[]).size()-1))
        check(bool(result.get("ok", false)) and s.pending_event.is_empty(), "private event resolves")
    var target := str(s.living_ids()[0])
    var ap := s.talk_ap
    var answer := s.ask(target, "ALIBI")
    check(bool(answer.get("ok", false)) and s.talk_ap == ap - 1 and s.known_claims.has(target), "alibi recorded")
    for line in answer.get("lines", []):
        check(str(line.get("text", "")).find("{") < 0 and str(line.get("text", "")).find("|") < 0, "alibi line formatted")
    s.advance()
    check(s.phase == "MEETING" and s.meeting_feed.size() >= 2, "meeting opens with focused statements (%d lines)" % s.meeting_feed.size())
    for entry in s.meeting_feed:
        var text := str(entry.get("text", ""))
        check(text != "" and text.find("{") < 0 and text.find("|") < 0, "meeting line formatted: " + text)
    check(s.known_claims.size() == s.roster.size(), "all claims known after meeting")
    s.advance()
    check(s.phase == "VOTE" and not s.can_advance(), "vote gates advance")
    var vote := s.cast_vote(str(s.living_ids()[1]), [str(s.living_ids()[1]), str(s.living_ids()[2])], 60)
    check(bool(vote.get("ok", false)) and s.vote_cast and s.can_advance(), "vote cast")
    check(not bool(s.cast_vote(str(s.living_ids()[0])).get("ok", false)), "cannot vote twice")
    s.advance()
    if s.outcome == "":
        check(s.phase == "NIGHT" and not s.can_advance(), "night gates advance")
        var options := s.night_options()
        check(not options["protect"].is_empty(), "night protect options")
        s.choose_night_action("protect", str(options["protect"][0]))
        check(s.night_done and s.can_advance(), "night resolved")
        s.advance()
        if s.outcome == "":
            check(s.day == 2 and s.phase == "BRIEFING" and not s.morning_report.is_empty(), "day 2 briefing with morning report")

func test_protocols() -> void:
    for protocol in ["ANALYST", "EMPATH", "AUDITOR"]:
        # SILENT_ORBIT keeps the historical 3/3 investigation/talk baseline
        # this loop's hardcoded numbers assume; GLASS_GARDEN's is lower now
        # (§8 of the design notes).
        var s := AstraGameSession.new()
        s.setup("SILENT_ORBIT", 777, protocol)
        for day_index in range(2):
            while s.phase != "INVESTIGATION":
                _auto_step(s)
                if s.outcome != "":
                    break
            if s.outcome != "":
                break
            check(s.investigation_ap == (4 if protocol == "ANALYST" else 3), "%s investigation AP on day %d" % [protocol, s.day])
            s.advance()
            check(s.talk_ap == (4 if protocol == "EMPATH" else 3), "%s talk AP on day %d" % [protocol, s.day])
            _auto_step(s)
        if protocol == "AUDITOR":
            var t := AstraGameSession.new()
            t.setup("DEAD_AIR", 5, "AUDITOR")
            check(t.found_clues().size() == 1 and str(t.found_clues()[0]["kind"]) == "context", "auditor starts with context clue")

func _auto_step(s: AstraGameSession) -> void:
    match s.phase:
        "INTERROGATION":
            if not s.pending_event.is_empty():
                s.resolve_private_event(0)
            s.advance()
        "VOTE":
            s.cast_vote("")
            s.advance()
        "NIGHT":
            s.choose_night_action("protect", str(s.night_options()["protect"][0]))
            s.advance()
        _:
            s.advance()

func test_meeting_limits() -> void:
    # SILENT_ORBIT keeps the historical 2-meeting-action baseline; DEAD_AIR's
    # is deliberately 1 now (§8 of the design notes).
    var s := AstraGameSession.new()
    s.setup("SILENT_ORBIT", 99, "EMPATH")
    s.advance()
    while s.investigation_ap > 0:
        var searched := false
        for room_id in s.room_ids():
            if not s.search_room(room_id).is_empty():
                searched = true
                break
        if not searched:
            break
    s.advance()
    if not s.pending_event.is_empty():
        s.resolve_private_event(0)
    s.advance()
    check(s.meeting_actions_left == 2, "two meeting actions")
    var target := str(s.living_ids()[0])
    check(bool(s.accuse(target).get("ok", false)), "accuse works")
    check(bool(s.defend(str(s.living_ids()[1])).get("ok", false)), "defend works")
    check(not bool(s.accuse(target).get("ok", false)), "third meeting action refused")
    check(not bool(s.ask(target, "ALIBI").get("ok", false)), "no free interrogation during meeting")

func test_night_and_endings() -> void:
    var wins := 0
    for seed_value in range(1, 11):
        var s := AstraGameSession.new()
        s.setup("DEAD_AIR", seed_value, "ANALYST")
        var nulls: Array = s.truth["nulls"]
        var guard := 0
        while s.phase != "RESULT" and guard < 60:
            guard += 1
            match s.phase:
                "INTERROGATION":
                    if not s.pending_event.is_empty():
                        s.resolve_private_event(0)
                    s.advance()
                "INVESTIGATION":
                    for room_id in s.room_ids():
                        while s.investigation_ap > 0:
                            if s.search_room(room_id).is_empty(): break
                    s.advance()
                "MEETING":
                    for clue in s.found_clues():
                        if clue.get("kind", "") == "trace" and not clue.get("decoy",false):
                            s.present_clue(str(clue["id"]))
                    for null_id in nulls:
                        if s.is_alive(str(null_id)):
                            s.accuse(str(null_id))
                    s.advance()
                "VOTE":
                    var pick := ""
                    for null_id in nulls:
                        if s.is_alive(str(null_id)) and pick == "":
                            pick = str(null_id)
                    s.cast_vote(pick, nulls, 90)
                    s.advance()
                "NIGHT":
                    s.choose_night_action("protect", str(s.night_options()["protect"][0]))
                    s.advance()
                _:
                    s.advance()
        check(s.phase == "RESULT" and not s.final_report.is_empty(), "oracle game %d reaches result" % seed_value)
        if s.outcome == "WIN":
            wins += 1
            check(int(s.final_report["theory"]["matched"]) == s.null_count, "oracle theory matched")
    check(wins >= 8, "oracle voting wins most games (%d/10)" % wins)

func test_meta_progress() -> void:
    var path := "user://astra_test_meta.cfg"
    var meta := AstraMetaProgress.new(path)
    # 0.4.0: the campaign now opens behind the calibration case, so a brand new
    # archive starts with the tutorial rather than with Dead Air. The rest of the
    # unlock chain is unchanged and is still asserted below.
    check(meta.is_case_unlocked("CALIBRATION") and not meta.is_case_unlocked("DEAD_AIR"), "fresh archive starts at calibration")
    check(meta.recommended_case_id() == "CALIBRATION", "fresh archive recommends calibration")
    meta.record_case_result("CALIBRATION", "ANALYST", {"outcome": "WIN", "total": 800, "rank": "B", "theory": {}, "null_isolated": 1, "roster": ["mira", "rho", "noa", "sena"], "nulls": ["rho"]})
    check(meta.calibration_completed, "calibration marks itself complete")
    check(meta.is_case_unlocked("DEAD_AIR") and not meta.is_case_unlocked("GLASS_GARDEN"), "after calibration only Dead Air is open")
    var change := meta.record_case_result("DEAD_AIR", "ANALYST", {"outcome": "LOSE", "total": 900, "rank": "D", "theory": {"suspects": ["mira", "rho"], "matched": 1, "grade": 40, "label": "C"}, "null_isolated": 1})
    check("GLASS_GARDEN" in change.get("unlocked", []), "completing Dead Air unlocks Glass Garden")
    var loaded := AstraMetaProgress.new(path)
    loaded.load_data()
    check(loaded.is_case_unlocked("GLASS_GARDEN") and not loaded.is_case_unlocked("ECHO_WARD"), "save round trip keeps unlocks")
    check(int(loaded.case_best_totals.get("DEAD_AIR", 0)) == 900 and loaded.theories_submitted == 1, "save round trip keeps records")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    var legacy := ConfigFile.new()
    legacy.set_value("meta", "save_version", 4)
    legacy.set_value("progress", "case_counts", {"DEAD_AIR": 2, "GLASS_GARDEN": 1})
    legacy.set_value("progress", "total_insight", 33)
    legacy.save(path)
    var migrated := AstraMetaProgress.new(path)
    migrated.load_data()
    check(migrated.is_case_unlocked("ECHO_WARD") and migrated.total_insight == 33, "v4 archive loads")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_simulations(games: int) -> void:
    var summary := []
    var smart_total_wins := 0
    var random_total_wins := 0
    var passive_total_wins := 0
    var total_games := 0
    for case_id in AstraCaseCatalog.CAMPAIGN:
        for protocol in ["ANALYST", "EMPATH", "AUDITOR"]:
            var smart_wins := 0
            var random_wins := 0
            var passive_wins := 0
            var smart_score := 0
            var days := 0
            var nulls_caught := 0
            var innocents := 0
            var ranks := {"S": 0, "A": 0, "B": 0, "C": 0, "D": 0}
            for game_index in range(games):
                var seed_value := 1000 + game_index * 13
                var report := AstraTestBots.play_smart(case_id, seed_value, protocol)
                check(not report.is_empty(), "smart game finished %s/%s/%d" % [case_id, protocol, seed_value])
                if report.is_empty():
                    continue
                if str(report["outcome"]) == "WIN":
                    smart_wins += 1
                smart_score += int(report["total"])
                days += int(report["day"])
                nulls_caught += int(report["null_isolated"])
                innocents += int(report["innocent_isolated"])
                ranks[str(report["rank"])] = int(ranks[str(report["rank"])]) + 1
                var random_report := AstraTestBots.play_random(case_id, seed_value, protocol)
                check(not random_report.is_empty(), "random game finished %s/%s/%d" % [case_id, protocol, seed_value])
                if not random_report.is_empty() and str(random_report["outcome"]) == "WIN":
                    random_wins += 1
                var passive_report := AstraTestBots.play_passive(case_id, seed_value, protocol)
                check(not passive_report.is_empty(), "passive game finished %s/%s/%d" % [case_id, protocol, seed_value])
                if not passive_report.is_empty() and str(passive_report["outcome"]) == "WIN":
                    passive_wins += 1
            smart_total_wins += smart_wins
            random_total_wins += random_wins
            passive_total_wins += passive_wins
            total_games += games
            summary.append("%-12s %-8s smart %3d%% random %3d%% passive %3d%% | score %5d day %.1f nulls %.2f innocents %.2f | %s" % [case_id, protocol, int(100.0 * smart_wins / games), int(100.0 * random_wins / games), int(100.0 * passive_wins / games), int(smart_score / maxf(1.0, float(games))), float(days) / games, float(nulls_caught) / games, float(innocents) / games, str(ranks)])
    for line in summary:
        print(line)
    var smart_rate := float(smart_total_wins) / float(total_games)
    var random_rate := float(random_total_wins) / float(total_games)
    var passive_rate := float(passive_total_wins) / float(total_games)
    print("TOTAL smart %d%% · random %d%% · passive %d%%" % [int(smart_rate * 100.0), int(random_rate * 100.0), int(passive_rate * 100.0)])
    check(smart_rate > random_rate + 0.3, "deduction beats random play by a wide margin")
    # The passive bot wins when the crowd happens to isolate every Null without
    # the player. It is rare, but every case and protocol is simulated over the
    # *same* seed range, so the eighteen cells are correlated: the effective
    # sample is the seed count, not total_games. A short run can therefore sit
    # several points off. The tight bound is asserted at the seed count the
    # release build uses (40); shorter developer runs get a looser one.
    var strict: bool = games >= 40
    check(passive_rate < (0.2 if strict else 0.3), "the crowd cannot solve cases without the player (%d seeds, %.0f%%)" % [games, passive_rate * 100.0])
