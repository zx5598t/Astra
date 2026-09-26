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
    var total := 0
    for case_id in CASES:
        var wins := 0
        for index in range(GAMES):
            var seed_value := 1000 + index * 13
            var report := AstraTestBots.play_passive(case_id, seed_value)
            if str(report.get("outcome", "")) == "WIN":
                wins += 1
        total += wins
        var rate := float(wins) / float(GAMES)
        print("%-18s passive %3d%% (%d/%d)" % [case_id, int(rate * 100.0), wins, GAMES])
        check(rate <= 0.85, "%s passive carry must stay at or below 85%% (%.0f%%)" % [case_id, rate * 100.0])
    var average := float(total) / float(GAMES * CASES.size())
    print("EARLY Stage 2-4 passive %d%%" % int(average * 100.0))
    check(average <= 0.85, "Stage 2-4 passive average stays at or below 85%%")
    if failures.is_empty():
        print("ASTRA EARLY BALANCE 101 OK")
        quit(0)
    else:
        print("ASTRA EARLY BALANCE 101 FAILED · %d" % failures.size())
        quit(1)
