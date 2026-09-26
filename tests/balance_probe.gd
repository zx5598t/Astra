extends SceneTree
# Developer balance probe: win rates per Stage for the three bots.
#   godot --headless --path . --script res://tests/balance_probe.gd -- --games=24
func _initialize() -> void:
    var games := 40
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--games="): games = int(a.substr(8))
    var totals := {"smart":0, "random":0, "passive":0}
    var n := 0
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var w := {"smart":0, "random":0, "passive":0}
        var reasons := {}
        var days := 0.0
        var deaths := 0
        var stage := AstraCaseCatalog.stage_index(case_id)
        var proto := "GUARDIAN" if stage >= 5 else "NONE"
        for seed in range(1, games + 1):
            var r := AstraTestBots.play_smart(case_id, seed * 13 + 1, proto)
            if str(r.get("outcome","")) == "WIN": w["smart"] += 1
            reasons[str(r.get("reason",""))] = int(reasons.get(str(r.get("reason","")),0)) + 1
            days += float(r.get("day", 0))
            if not bool(r.get("player_alive", true)): deaths += 1
            if str(AstraTestBots.play_random(case_id, seed * 13 + 1, proto).get("outcome","")) == "WIN": w["random"] += 1
            if str(AstraTestBots.play_passive(case_id, seed * 13 + 1).get("outcome","")) == "WIN": w["passive"] += 1
        for k in w: totals[k] += w[k]
        n += games
        print("%-18s smart %3d%% random %3d%% passive %3d%% | smart days %.1f deaths %d %s" % [case_id, 100*w["smart"]/games, 100*w["random"]/games, 100*w["passive"]/games, days/games, deaths, str(reasons)])
    print("TOTAL smart %d%% random %d%% passive %d%%" % [100*totals["smart"]/n, 100*totals["random"]/n, 100*totals["passive"]/n])
    print("ASTRA BALANCE PROBE OK · games=%d" % games)
    quit()
