extends SceneTree
# Where does the room's accuracy come from when the explorer does nothing?
# For PASSIVE play, per Stage and per Day: how often the isolated person is a
# Null, how the honest crew's votes for a Null were made (own evidence /
# following someone / unsure), and how many public facts pointed at the
# acting Null by vote time. Tuning aid, not part of CI.
#   godot --headless --path . --script res://tests/probe_agency_080.gd -- --games=30
func _initialize() -> void:
    var games := 30
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--games="):
            games = int(a.substr(8))
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        var wins := 0
        var by_day := {}
        for seed in range(1, games + 1):
            var s := AstraGameSession.new()
            var stage := AstraCaseCatalog.stage_index(case_id)
            s.setup(case_id, seed * 7919 + 17, "GUARDIAN" if stage >= 5 else "NONE")
            var guard := 0
            while s.phase != "RESULT" and guard < 400:
                guard += 1
                match s.phase:
                    "BRIEFING":
                        AstraTestBots._finish_morning(s)
                        s.advance()
                    "VOTE":
                        var d := s.day
                        var row: Dictionary = by_day.get(d, {"n": 0, "hit": 0, "evidence": 0, "follow": 0, "unsure": 0, "npc_null_votes": 0, "npc_votes": 0, "public": 0})
                        row["n"] = int(row["n"]) + 1
                        var nulls := s.living_null_ids()
                        var actor := str(s.current_packet().get("actor", ""))
                        for item in s.current_packet().get("fragments", []):
                            if AstraKnowledgeModel.is_public(s.flags, str(item.get("id", ""))) and actor in Array(item.get("points_to", [])) and not bool(item.get("false", false)):
                                row["public"] = int(row["public"]) + 1
                        for voter in s.eligible_voters():
                            if s.crew[voter].is_null():
                                continue
                            var dec := s._vote_target_for(str(voter), s.eligible_vote_targets())
                            row["npc_votes"] = int(row["npc_votes"]) + 1
                            if str(dec.get("target", "")) in nulls:
                                row["npc_null_votes"] = int(row["npc_null_votes"]) + 1
                                var mode := str(dec.get("mode", "evidence"))
                                if mode == "evidence":
                                    var codes: Dictionary = row.get("codes", {})
                                    var top_code := ""
                                    var top_w := 0.0
                                    for reason in Dictionary(dec.get("trace", {})).get("reasons", []):
                                        if float(reason.get("weight", 0.0)) > top_w:
                                            top_w = float(reason.get("weight", 0.0))
                                            top_code = str(reason.get("code", ""))
                                    var src := ""
                                    var view := s.suspicion_breakdown(str(voter), str(dec.get("target", "")))
                                    for item in view.get("reasons", []):
                                        if str(item.get("code", "")) == top_code:
                                            var f := s.fragment(str(item.get("source", "")))
                                            src = str(f.get("type", str(item.get("source", "")).split(":")[0]))
                                            if not f.is_empty():
                                                src += ("/own" if str(f.get("owner", "")) == str(voter) else ("/pub" if AstraKnowledgeModel.is_public(s.flags, str(f.get("id", ""))) else "/heard"))
                                                src += "/spec" if bool(f.get("specific", false)) else "/grp"
                                            break
                                    var key := top_code + ":" + src
                                    codes[key] = int(codes.get(key, 0)) + 1
                                    row["codes"] = codes
                                if mode == "player":
                                    mode = "follow"
                                row[mode] = int(row.get(mode, 0)) + 1
                        s.cast_vote(AstraTestBots._crowd_pick(s, s.eligible_vote_targets()))
                        if s.vote_stage() == "RUNOFF":
                            s.cast_vote(AstraTestBots._crowd_pick(s, s.runoff_candidates()))
                        if s.vote_stage() == "TIEBREAK":
                            s.resolve_tiebreak(AstraTestBots._crowd_pick(s, s.runoff_candidates()))
                        var rounds: Array = s.stage_state().get("vote_rounds", [])
                        if not rounds.is_empty() and str(rounds[rounds.size() - 1].get("isolated", "")) in nulls:
                            row["hit"] = int(row["hit"]) + 1
                        by_day[d] = row
                        s.advance()
                    "NIGHT":
                        s.choose_night_action("skip", "")
                        s.advance()
                    _:
                        s.advance()
            if str(s.final_report.get("outcome", s.outcome)) in ["SUCCESS", "WIN", "CONTAINED", "success"] or s.outcome == "SUCCESS":
                wins += 1
        var parts: Array = []
        for d in by_day.keys():
            var r: Dictionary = by_day[d]
            var nv := maxi(1, int(r["npc_null_votes"]))
            parts.append("D%d n%d hit%d%% nullvotes%d%% (ev%d%% fol%d%% uns%d%%) pub%.1f" % [d, int(r["n"]), 100 * int(r["hit"]) / maxi(1, int(r["n"])),
                100 * int(r["npc_null_votes"]) / maxi(1, int(r["npc_votes"])), 100 * int(r["evidence"]) / nv, 100 * int(r["follow"]) / nv, 100 * int(r["unsure"]) / nv,
                float(r["public"]) / maxf(1.0, float(r["n"]))])
        print("%-18s passive win %d%% | %s" % [case_id, 100 * wins / games, " | ".join(PackedStringArray(parts))])
        for d in by_day.keys():
            var codes: Dictionary = Dictionary(by_day[d]).get("codes", {})
            var ranked: Array = codes.keys()
            ranked.sort_custom(func(x, y): return int(codes[x]) > int(codes[y]))
            var top: Array = []
            for i in range(mini(5, ranked.size())):
                top.append("%s×%d" % [ranked[i], int(codes[ranked[i]])])
            print("    D%d evidence reasons: %s" % [d, ", ".join(PackedStringArray(top))])
    quit()
