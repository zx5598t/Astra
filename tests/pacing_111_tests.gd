extends SceneTree

# ASTRA 1.1.1 HUMAN RHYTHM — runtime meeting pacing probe.
# Uses the same 100 seeds as causal_101 but measures the ACTIVE path only.
const CASES := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]
const SEEDS := 100
const BASELINE_LINES := {"DEAD_AIR":25.65, "GLASS_GARDEN":24.93, "ECHO_WARD":28.66}
const BASELINE_STREAK := {"DEAD_AIR":4, "GLASS_GARDEN":3, "ECHO_WARD":3}

var failures: Array[String] = []
var rows: PackedStringArray = []

func _initialize() -> void:
    _run.call_deferred()

func check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _max_streak(lines: Array) -> int:
    var best := 0
    var current := 0
    var previous := ""
    for raw in lines:
        var speaker := str(Dictionary(raw).get("speaker", ""))
        if speaker == "" or speaker == "player":
            current = 0
            previous = ""
        elif speaker == previous:
            current += 1
            best = maxi(best, current)
        else:
            previous = speaker
            current = 1
            best = maxi(best, current)
    return best

func _play(case_id: String, seed_value: int) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value)
    var line_count := 0
    var meaningful := 0
    var continue_only := 0
    var clicks := 0
    var links := 0
    var clarifications := 0
    var max_streak := 0
    var guard := 0
    while s.phase != "RESULT" and guard < 500:
        guard += 1
        match s.phase:
            "BRIEFING":
                AstraTestBots._finish_morning(s, true)
                if s.phase == "BRIEFING":
                    s.advance()
            "INTERROGATION":
                var order: Array = s.living_ids().duplicate()
                var leads := s.talk_leads()
                order.sort_custom(func(a, b):
                    var score_a := s.suspicion_score("player", str(a)) + (1.0 if leads.has(str(a)) else 0.0)
                    var score_b := s.suspicion_score("player", str(b)) + (1.0 if leads.has(str(b)) else 0.0)
                    return score_a > score_b)
                for npc_id in order:
                    if s.conversations_left() <= 0:
                        break
                    s.ask(str(npc_id), "STATEMENT")
                    var qguard := 0
                    while s.followups_left(str(npc_id)) > 0 and qguard < 3:
                        qguard += 1
                        var picked := {}
                        for option in s.question_options(str(npc_id)):
                            if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["CONFRONT","RECORD","WITNESS"]:
                                picked = option
                                break
                        if picked.is_empty():
                            break
                        s.ask(str(npc_id), str(picked.get("intent", "")), str(picked.get("ref", "")))
                s.advance()
            "MEETING":
                var start := s.meeting_feed.size()
                var mguard := 0
                while not s.meeting_over() and mguard < 12:
                    mguard += 1
                    var soft := s.clarification_options()
                    var strong := s.meeting_options()
                    if soft.is_empty() and strong.is_empty():
                        continue_only += 1
                    else:
                        meaningful += 1
                    var link := AstraTestBots.smart_link(s)
                    if s.meeting_actions_left > 0 and link != "":
                        if bool(s.intervene("link", link).get("ok", false)):
                            links += 1
                            clicks += 1
                    elif not soft.is_empty():
                        if bool(s.intervene("clarify", str(soft[0].get("ref", ""))).get("ok", false)):
                            clarifications += 1
                            clicks += 1
                    elif s.meeting_actions_left > 0:
                        var pick := AstraTestBots._smart_moment_pick(s)
                        if not pick.is_empty() and bool(s.intervene(str(pick.get("kind", "")), str(pick.get("ref", ""))).get("ok", false)):
                            clicks += 1
                    s.meeting_continue()
                    clicks += 1
                var day_lines: Array = s.meeting_feed.slice(start)
                line_count += day_lines.size()
                max_streak = maxi(max_streak, _max_streak(day_lines))
                s.advance()
            "VOTE":
                AstraTestBots._vote(s, AstraTestBots._player_top(s))
                s.advance()
            "NIGHT":
                AstraTestBots._night(s, true)
                s.advance()
            _:
                s.advance()
    return {"lines":line_count,"meaningful":meaningful,"continue_only":continue_only,
        "clicks":clicks,"links":links,"clarifications":clarifications,"max_streak":max_streak}

func _run() -> void:
    rows.append("ASTRA 1.1.1 — HUMAN RHYTHM pacing")
    rows.append("stage\tavg_lines\tavg_meaningful\tavg_continue_only\tavg_clicks_to_vote\tavg_links\tavg_clarifications\tmax_same_speaker\tbaseline_lines")
    for case_id in CASES:
        var total := {"lines":0,"meaningful":0,"continue_only":0,"clicks":0,"links":0,"clarifications":0}
        var max_streak := 0
        for index in range(SEEDS):
            var result := _play(case_id, 1000 + index * 13)
            for key in total:
                total[key] = int(total[key]) + int(result.get(key, 0))
            max_streak = maxi(max_streak, int(result.get("max_streak", 0)))
        var avg_lines := float(total["lines"]) / SEEDS
        var avg_meaningful := float(total["meaningful"]) / SEEDS
        var avg_continue := float(total["continue_only"]) / SEEDS
        var avg_clicks := float(total["clicks"]) / SEEDS
        rows.append("%s\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%.2f\t%d\t%.2f" % [
            case_id, avg_lines, avg_meaningful, avg_continue, avg_clicks,
            float(total["links"]) / SEEDS, float(total["clarifications"]) / SEEDS,
            max_streak, float(BASELINE_LINES[case_id])])
        check(avg_continue <= 0.01, case_id + " keeps continue-only windows at zero")
        check(avg_meaningful >= 3.0, case_id + " keeps meaningful decision windows")
        check(int(total["links"]) > 0, case_id + " keeps active Link use")
        check(max_streak <= int(BASELINE_STREAK[case_id]), case_id + " does not worsen same-speaker streak")
        if case_id == "ECHO_WARD":
            check(avg_lines < float(BASELINE_LINES[case_id]), "ECHO_WARD is shorter than 1.1.0")
            check(avg_lines <= 27.5, "ECHO_WARD approaches 24-27 line target")
        else:
            check(avg_lines <= float(BASELINE_LINES[case_id]) + 0.01, case_id + " does not get longer than 1.1.0")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/pacing_111.txt", FileAccess.WRITE)
    file.store_string("\n".join(rows))
    file.close()
    if failures.is_empty():
        print("ASTRA PACING 111 TESTS OK · %d active seeds" % (SEEDS * CASES.size()))
        quit(0)
        return
    printerr("ASTRA PACING 111 TESTS FAILED · %d" % failures.size())
    quit(1)
