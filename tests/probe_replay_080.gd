extends SceneTree
# Replayability and meta-formula probe (§11, §12 of the final pass). Plays
# many seeds of every Stage with a crowd-following explorer and reports:
#   distributions: Null identity, Null pair, Null style, first public accuser
#   (by person), first isolated, night victims, witness owner, record owner,
#   harmless liar, first meeting argument kind
#   formulas: how often the Null is the one whose company is denied / who
#   claims company, the first accuser, quiet on Day 1, holds no clue on Day 1
# Tuning aid, not CI.   godot --headless --path . --script res://tests/probe_replay_080.gd -- --seeds=40
func _initialize() -> void:
    var seeds := 40
    for a in OS.get_cmdline_user_args():
        if a.begins_with("--seeds="):
            seeds = int(a.substr(8))
    var dist := {"null": {}, "pair": {}, "style": {}, "first_accuser": {}, "first_isolated": {}, "victim": {}, "witness": {}, "record": {}, "benign": {}, "opener": {}}
    var f := {"denied_null": 0, "denied_total": 0, "claimer_null": 0, "claimer_total": 0, "first_acc_null": 0, "first_acc_total": 0,
        "quiet_null": 0, "quiet_total": 0, "noclue_null": 0, "noclue_total": 0, "nulls_total": 0, "people_total": 0, "day2_decides": 0, "stages": 0,
        "attacked_top": 0, "attacks": 0}
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        for seed in range(1, seeds + 1):
            var s := AstraGameSession.new()
            var stage := AstraCaseCatalog.stage_index(case_id)
            s.setup(case_id, seed * 6151 + 29, "GUARDIAN" if stage >= 5 else "NONE")
            var nulls: Array = Array(s.truth.get("nulls", [])).duplicate()
            nulls.sort()
            for id in nulls:
                _inc(dist["null"], str(id))
                _inc(dist["style"], s.null_style(str(id)))
            if nulls.size() == 2:
                _inc(dist["pair"], "%s+%s" % [nulls[0], nulls[1]])
            f["stages"] += 1
            var guard := 0
            var first_isolation_done := false
            while s.phase != "RESULT" and guard < 400:
                guard += 1
                match s.phase:
                    "BRIEFING":
                        AstraTestBots._finish_morning(s)
                        s.advance()
                    "INTERROGATION":
                        if s.day == 1:
                            var packet := s.current_packet()
                            var holders := {}
                            for item in packet.get("fragments", []):
                                holders[str(item.get("owner", ""))] = true
                                match str(item.get("type", "")):
                                    "DIRECT_WITNESS": _inc(dist["witness"], str(item.get("owner", "")))
                                    "SYSTEM_RECORD": _inc(dist["record"], str(item.get("owner", "")))
                            var benign := str(Dictionary(packet.get("benign", {})).get("npc", ""))
                            if benign != "":
                                _inc(dist["benign"], benign)
                            var claims: Dictionary = packet.get("claims", {})
                            for a in claims:
                                for b in claims:
                                    if a == b:
                                        continue
                                    var ca: Dictionary = claims[a]
                                    var cb: Dictionary = claims[b]
                                    # a says it was with b; b does not say it was with a
                                    if b in Array(ca.get("companions", [])) and a not in Array(cb.get("companions", [])):
                                        f["claimer_total"] += 1
                                        if a in s.truth.get("nulls", []):
                                            f["claimer_null"] += 1
                                    # b says it was with a; a denies (claims elsewhere or alone)
                                    if a in Array(cb.get("companions", [])) and b not in Array(ca.get("companions", [])):
                                        f["denied_total"] += 1
                                        if a in s.truth.get("nulls", []):
                                            f["denied_null"] += 1
                            for id in s.living_ids():
                                f["people_total"] += 1
                                if not holders.has(str(id)):
                                    f["noclue_total"] += 1
                                    if str(id) in s.truth.get("nulls", []):
                                        f["noclue_null"] += 1
                        s.advance()
                    "MEETING":
                        var plan: Array = s.stage_state().get("meeting_plan", [])
                        s._finish_meeting()
                        var first := ""
                        var spoke := {}
                        for entry in s.meeting_feed:
                            var topic := str(entry.get("topic", ""))
                            if first == "" and str(entry.get("thread_role", "")) == "anchor" and str(entry.get("speaker", "")) != "":
                                first = topic.split(":")[0]
                            spoke[str(entry.get("speaker", ""))] = true
                        if first != "":
                            _inc(dist["opener"], first)
                        var accusations: Array = s.stage_state().get("public_accusations", [])
                        for entry in accusations:
                            if int(entry.get("day", 0)) == s.day and str(entry.get("speaker", "")) != "player":
                                _inc(dist["first_accuser"], str(entry.get("speaker", "")))
                                f["first_acc_total"] += 1
                                if str(entry.get("speaker", "")) in s.living_null_ids():
                                    f["first_acc_null"] += 1
                                break
                        if s.day == 1:
                            var accusers := {}
                            for entry in accusations:
                                accusers[str(entry.get("speaker", ""))] = true
                            for id in s.living_ids():
                                if not accusers.has(str(id)):
                                    f["quiet_total"] += 1
                                    if str(id) in s.living_null_ids():
                                        f["quiet_null"] += 1
                        s.advance()
                    "VOTE":
                        s.cast_vote(AstraTestBots._crowd_pick(s, s.eligible_vote_targets()))
                        if s.vote_stage() == "RUNOFF":
                            s.cast_vote(AstraTestBots._crowd_pick(s, s.runoff_candidates()))
                        if s.vote_stage() == "TIEBREAK":
                            s.resolve_tiebreak(AstraTestBots._crowd_pick(s, s.runoff_candidates()))
                        if not first_isolation_done and not s.isolations.is_empty():
                            first_isolation_done = true
                            _inc(dist["first_isolated"], str(s.isolations[0].get("id", "")))
                        s.advance()
                    "NIGHT":
                        var threats := s.night_threats()
                        var top := ""
                        var top_v := -99.0
                        for id in threats:
                            if float(threats[id]) > top_v:
                                top_v = float(threats[id])
                                top = str(id)
                        s.choose_night_action("skip", "")
                        var attacked := str(s.night_result.get("attacked", ""))
                        if attacked != "":
                            f["attacks"] += 1
                            if attacked == top:
                                f["attacked_top"] += 1
                            _inc(dist["victim"], attacked)
                        s.advance()
                    _:
                        s.advance()
            if s.outcome == "WIN" and s.day == 2:
                f["day2_decides"] += 1
    for key in dist:
        var d: Dictionary = dist[key]
        var total := 0
        for k in d:
            total += int(d[k])
        var keys: Array = d.keys()
        keys.sort_custom(func(x, y): return int(d[x]) > int(d[y]))
        var parts: Array = []
        for k in keys.slice(0, 10):
            parts.append("%s %d%%" % [k, 100 * int(d[k]) / maxi(1, total)])
        print("%-15s n%-5d %s" % [key, total, ", ".join(PackedStringArray(parts))])
    print("FORMULA company denied → that person is a Null: %d%% of %d" % [100 * f["denied_null"] / maxi(1, f["denied_total"]), f["denied_total"]])
    print("FORMULA claims company the other denies → Null: %d%% of %d" % [100 * f["claimer_null"] / maxi(1, f["claimer_total"]), f["claimer_total"]])
    print("FORMULA first NPC accuser of a Day is a Null: %d%% of %d" % [100 * f["first_acc_null"] / maxi(1, f["first_acc_total"]), f["first_acc_total"]])
    print("FORMULA quiet on Day 1 (accused nobody) is a Null: %d%% of %d" % [100 * f["quiet_null"] / maxi(1, f["quiet_total"]), f["quiet_total"]])
    print("FORMULA holds no clue on Day 1 is a Null: %d%% of %d (base rate %d%%)" % [100 * f["noclue_null"] / maxi(1, f["noclue_total"]), f["noclue_total"], 100 * 1 / 6])
    print("FORMULA night attack goes to the top threat: %d%% of %d" % [100 * f["attacked_top"] / maxi(1, f["attacks"]), f["attacks"]])
    print("wins decided on Day 2 (crowd): %d%% of %d Stages" % [100 * f["day2_decides"] / maxi(1, f["stages"]), f["stages"]])
    quit()

func _inc(d: Dictionary, key: String) -> void:
    d[key] = int(d.get(key, 0)) + 1
