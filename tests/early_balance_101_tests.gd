extends SceneTree

# Fast 1.0.1 stabilization signal. The full run_tests.gd simulation remains
# authoritative; this isolates the Stage 2-4 passive-carry guard so tuning does
# not wait behind every retained suite.
const GAMES := 40
const CASES := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]

var failures: Array[String] = []

func _initialize() -> void:
    _run.call_deferred()

func check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _run() -> void:
    var passive_total := 0
    var smart_total := 0
    for case_id in CASES:
        var passive_wins := 0
        var smart_wins := 0
        for index in range(GAMES):
            var seed_value := 1000 + index * 13
            var passive_report := AstraTestBots.play_passive(case_id, seed_value)
            if str(passive_report.get("outcome", "")) == "WIN":
                passive_wins += 1
            var smart_report := AstraTestBots.play_smart(case_id, seed_value, "NONE")
            if str(smart_report.get("outcome", "")) == "WIN":
                smart_wins += 1
        passive_total += passive_wins
        smart_total += smart_wins
        var passive_rate := float(passive_wins) / float(GAMES)
        var smart_rate := float(smart_wins) / float(GAMES)
        print("%-18s smart %3d%% passive %3d%% (%d/%d · %d/%d)" % [case_id, int(smart_rate * 100.0), int(passive_rate * 100.0), smart_wins, GAMES, passive_wins, GAMES])
        # 85% is only a regression ceiling, not the release-quality target.
        # Causal/fairness gates judge whether active reasoning actually matters.
        check(passive_rate <= 0.85, "%s passive carry must stay at or below the 85%% regression ceiling (%.0f%%)" % [case_id, passive_rate * 100.0])
        if case_id == "ECHO_WARD":
            check(passive_rate < 0.80, "ECHO_WARD passive carry must stay below 80%% (%.0f%%)" % (passive_rate * 100.0))
        check(smart_rate >= 0.80, "%s smart play must remain viable (%.0f%%)" % [case_id, smart_rate * 100.0])
    var passive_average := float(passive_total) / float(GAMES * CASES.size())
    var smart_average := float(smart_total) / float(GAMES * CASES.size())
    print("EARLY Stage 2-4 smart/passive %d%%/%d%%" % [int(smart_average * 100.0), int(passive_average * 100.0)])
    check(passive_average <= 0.85, "Stage 2-4 passive average stays at or below the regression ceiling")
    check(smart_average >= 0.80, "Stage 2-4 smart average stays viable")
    if failures.is_empty():
        print("ASTRA EARLY BALANCE 101 OK")
        quit(0)
    else:
        print("ASTRA EARLY BALANCE 101 FAILED · %d" % failures.size())
        quit(1)
