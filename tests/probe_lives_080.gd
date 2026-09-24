extends SceneTree
# What the explorer changes besides the win rate: innocents sent to a pod,
# crew lost at night, and days taken, SMART vs PASSIVE, per Stage.
# Tuning aid, not CI.  godot --headless --path . --script res://tests/probe_lives_080.gd -- --games=24
func _initialize() -> void:
    var games := 24
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--games="):
            games = int(a.substr(8))
    print("%-18s | %-34s | %-34s" % ["Stage", "SMART win · 무고격리 · 사망 · 날", "PASSIVE win · 무고격리 · 사망 · 날"])
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var stage := AstraCaseCatalog.stage_index(case_id)
        var protocol := "GUARDIAN" if stage >= 5 else "NONE"
        var rows := {}
        for bot in ["smart", "passive"]:
            var wins := 0
            var wrong := 0
            var lost := 0
            var days := 0
            for seed in range(1, games + 1):
                var report: Dictionary = AstraTestBots.play_smart(case_id, seed * 2029 + 7, protocol) if bot == "smart" else AstraTestBots.play_passive(case_id, seed * 2029 + 7, protocol)
                if str(report.get("outcome", "")) == "WIN":
                    wins += 1
                wrong += int(report.get("innocent_isolated", 0))
                for victim in report.get("casualties", []):
                    if str(victim.get("id", "")) != "player":
                        lost += 1
                days += int(report.get("day", 0))
            rows[bot] = "%3d%% · %.2f · %.2f · %.1f" % [100 * wins / games, float(wrong) / games, float(lost) / games, float(days) / games]
        print("%-18s | %-34s | %-34s" % [case_id, rows["smart"], rows["passive"]])
    quit()
