extends SceneTree

# ASTRA 1.0.1 causal-quality probe.
# 100 same-seed ACTIVE/PASSIVE pairs per Stage 2-4. This is intentionally not
# a "make passive lose" test: it measures whether explicit player reasoning
# changes the public room, NPC stance and outcome quality while preserving more
# than one fair cross-check route across a Stage.

const CASES := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]
const SEEDS := 100

var failures: Array[String] = []

func _initialize() -> void:
    _run.call_deferred()

func check(ok: bool, label: String) -> void:
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _crowd_pick(s: AstraGameSession, pool: Array) -> String:
    var tally := {}
    for voter in s.vote_intentions(pool):
        var target := str(s.vote_intentions(pool).get(voter, ""))
        tally[target] = int(tally.get(target, 0)) + 1
    var best := str(pool[0])
    for target in pool:
        if int(tally.get(str(target), 0)) > int(tally.get(best, 0)):
            best = str(target)
    return best

func _origin(item: Dictionary) -> String:
    var type := str(item.get("type", ""))
    if type == "HEARSAY":
        return "witness:" + str(item.get("via", ""))
    if type in ["DIRECT_WITNESS", "NULL_DECEPTION", "BENIGN_EXPOSURE", "COVER_EXPOSURE"]:
        return "witness:" + str(item.get("owner", ""))
    if type in ["SYSTEM_RECORD", "ALIBI_SUPPORT"]:
        return "record:%s:%s" % [str(item.get("record_type", "")), str(item.get("owner", ""))]
    if type == "EXPERT_INFERENCE":
        return "expert:" + str(item.get("owner", ""))
    return "fact:" + str(item.get("id", ""))

func _packet_route_signatures(s: AstraGameSession) -> Array:
    var packet := s.current_packet()
    var actor := str(packet.get("actor", ""))
    if actor == "":
        return []
    var fragments: Array = []
    for raw in packet.get("fragments", []):
        var item: Dictionary = raw
        if actor in Array(item.get("points_to", [])) and str(item.get("type", "")) in ["DIRECT_WITNESS", "SYSTEM_RECORD", "HEARSAY", "ALIBI_SUPPORT"]:
            fragments.append(item)
    var routes := {}
    for i in range(fragments.size()):
        for j in range(i + 1, fragments.size()):
            var a: Dictionary = fragments[i]
            var b: Dictionary = fragments[j]
            var oa := _origin(a)
            var ob := _origin(b)
            if oa == ob:
                continue
            var left: Array = []
            for id in Array(a.get("points_to", [])):
                if id in Array(b.get("points_to", [])) and s.is_alive(str(id)):
                    left.append(str(id))
            if left.size() == 1 and str(left[0]) == actor:
                var pair := [oa, ob]
                pair.sort()
                routes[str(pair)] = true
    return routes.keys()

func _auto_decisive_public(s: AstraGameSession) -> int:
    var unique := {}
    for raw in s.stage_state().get("public_log", []):
        var row: Dictionary = raw
        if bool(row.get("player_contact", false)) or str(row.get("speaker", "")) == "player":
            continue
        var item := s.fragment(str(row.get("fact", "")))
        if item.is_empty():
            continue
        var people := Array(item.get("points_to", []))
        if bool(item.get("specific", false)) or people.size() == 1:
            unique[str(row.get("fact", ""))] = true
    return unique.size()

func _max_speaker_streak(lines: Array) -> int:
    var best := 0
    var current := 0
    var previous := ""
    for raw in lines:
        var speaker := str(Dictionary(raw).get("speaker", ""))
        if speaker == "" or speaker == "player":
            current = 0
            previous = ""
            continue
        if speaker == previous:
            current += 1
        else:
            current = 1
            previous = speaker
        best = maxi(best, current)
    return best

func _run_route(case_id: String, seed_value: int, active: bool) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value)
    var meaningful := 0
    var continue_only := 0
    var clarifications := 0
    var interventions := 0
    var meeting_clicks := 0
    var meeting_lines := 0
    var max_streak := 0
    var route_signatures := {}
    var guard := 0

    while s.phase != "RESULT" and guard < 500:
        guard += 1
        match s.phase:
            "BRIEFING":
                for signature in _packet_route_signatures(s):
                    route_signatures[str(signature)] = true
                AstraTestBots._finish_morning(s, active)
                s.advance()
            "INTERROGATION":
                if active:
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
                                if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["CONFRONT", "RECORD", "WITNESS"]:
                                    picked = option
                                    break
                            if picked.is_empty():
                                break
                            s.ask(str(npc_id), str(picked.get("intent", "")), str(picked.get("ref", "")))
                s.advance()
            "MEETING":
                var feed_start := s.meeting_feed.size()
                var mguard := 0
                while not s.meeting_over() and mguard < 12:
                    mguard += 1
                    var soft := s.clarification_options()
                    var strong := s.meeting_options()
                    if soft.is_empty() and strong.is_empty():
                        continue_only += 1
                    else:
                        meaningful += 1
                    if active:
                        var link := AstraTestBots.smart_link(s)
                        if s.meeting_actions_left > 0 and link != "":
                            if bool(s.intervene("link", link).get("ok", false)):
                                interventions += 1
                                meeting_clicks += 1
                        elif not soft.is_empty():
                            if bool(s.intervene("clarify", str(soft[0].get("ref", ""))).get("ok", false)):
                                clarifications += 1
                                meeting_clicks += 1
                        elif s.meeting_actions_left > 0:
                            var pick := AstraTestBots._smart_moment_pick(s)
                            if not pick.is_empty() and bool(s.intervene(str(pick.get("kind", "")), str(pick.get("ref", ""))).get("ok", false)):
                                interventions += 1
                                meeting_clicks += 1
                    s.meeting_continue()
                    meeting_clicks += 1
                var day_lines: Array = s.meeting_feed.slice(feed_start)
                meeting_lines += day_lines.size()
                max_streak = maxi(max_streak, _max_speaker_streak(day_lines))
                s.advance()
            "VOTE":
                var pool := s.eligible_vote_targets()
                var target := _crowd_pick(s, pool)
                if active:
                    var best := ""
                    var score := -99.0
                    for candidate in pool:
                        var value := s.suspicion_score("player", str(candidate))
                        if value > score:
                            score = value
                            best = str(candidate)
                    if best != "":
                        target = best
                s.cast_vote(target)
                if s.vote_stage() == "RUNOFF":
                    s.cast_vote(_crowd_pick(s, s.runoff_candidates()))
                if s.vote_stage() == "TIEBREAK":
                    s.resolve_tiebreak(_crowd_pick(s, s.runoff_candidates()))
                s.advance()
            "NIGHT":
                s.choose_night_action("skip", "")
                s.advance()
            _:
                s.advance()

    var innocent := 0
    for row in s.isolations:
        if str(row.get("role", "")) != "NULL":
            innocent += 1
    var metrics := s.agency_metrics()
    var links := int(s.stats.get("links", 0))
    var raised := 0
    for row in s.stage_state().get("links", []):
        if str(row.get("result", "")) == "CONTRADICTION":
            raised += 1
    return {
        "outcome": s.outcome,
        "days": s.day,
        "innocent": innocent,
        "casualties": s.casualties.size(),
        "public": int(metrics.get("player_caused_public_facts", 0)),
        "links": links,
        "meeting": int(metrics.get("player_caused_meeting_changes", 0)),
        "votes": int(metrics.get("player_caused_vote_changes", 0)),
        "raised": raised,
        "auto_decisive": _auto_decisive_public(s),
        "routes": route_signatures.size(),
        "meeting_lines": meeting_lines,
        "meaningful": meaningful,
        "continue_only": continue_only,
        "clarifications": clarifications,
        "interventions": interventions,
        "max_streak": max_streak,
        "meeting_clicks": meeting_clicks
    }

func _sum(dst: Dictionary, row: Dictionary) -> void:
    dst["wins"] += 1 if str(row.get("outcome", "")) == "WIN" else 0
    for key in ["days", "innocent", "casualties", "public", "links", "meeting", "votes", "raised", "auto_decisive",
        "routes", "meeting_lines", "meaningful", "continue_only", "clarifications", "interventions", "meeting_clicks"]:
        dst[key] += int(row.get(key, 0))
    dst["max_streak"] = maxi(int(dst["max_streak"]), int(row.get("max_streak", 0)))

func _bucket() -> Dictionary:
    return {"wins":0, "days":0, "innocent":0, "casualties":0, "public":0, "links":0, "meeting":0, "votes":0,
        "raised":0, "auto_decisive":0, "routes":0, "meeting_lines":0, "meaningful":0, "continue_only":0,
        "clarifications":0, "interventions":0, "max_streak":0, "meeting_clicks":0}

func _run() -> void:
    var global_active := _bucket()
    var global_passive := _bucket()
    for case_id in CASES:
        var active := _bucket()
        var passive := _bucket()
        var route_shortfall := 0
        for index in range(SEEDS):
            var seed_value := 1000 + index * 13
            var a := _run_route(case_id, seed_value, true)
            var p := _run_route(case_id, seed_value, false)
            _sum(active, a)
            _sum(passive, p)
            _sum(global_active, a)
            _sum(global_passive, p)
            if int(a.get("routes", 0)) < int(AstraCaseCatalog.get_case(case_id).get("deduction_profile", {}).get("min_reasonable_routes", 1)):
                route_shortfall += 1
        print("CAUSAL %s · ACTIVE/PASSIVE wins=%d/%d days=%.2f/%.2f innocent=%.2f/%.2f casualties=%.2f/%.2f public=%d/%d links=%d/%d stance=%d/%d votes=%d/%d raised=%d/%d auto_decisive=%d/%d routes_avg=%.2f/%.2f" % [
            case_id, active["wins"], passive["wins"], float(active["days"])/SEEDS, float(passive["days"])/SEEDS,
            float(active["innocent"])/SEEDS, float(passive["innocent"])/SEEDS, float(active["casualties"])/SEEDS,
            float(passive["casualties"])/SEEDS, active["public"], passive["public"], active["links"], passive["links"],
            active["meeting"], passive["meeting"], active["votes"], passive["votes"], active["raised"], passive["raised"],
            active["auto_decisive"], passive["auto_decisive"], float(active["routes"])/SEEDS, float(passive["routes"])/SEEDS])
        print("MEETING %s · lines=%.2f choices=%.2f continue_only=%.2f clarify=%.2f link/intervene=%.2f max_same_speaker=%d clicks_to_vote=%.2f route_shortfall=%d/%d" % [
            case_id, float(active["meeting_lines"])/SEEDS, float(active["meaningful"])/SEEDS, float(active["continue_only"])/SEEDS,
            float(active["clarifications"])/SEEDS, float(active["interventions"])/SEEDS, active["max_streak"],
            float(active["meeting_clicks"])/SEEDS, route_shortfall, SEEDS])
        check(active["public"] > passive["public"], case_id + " active play causes more public facts")
        check(active["meeting"] > passive["meeting"], case_id + " active play causes more stance changes")
        check(active["votes"] > passive["votes"], case_id + " active play changes more vote intentions")
        check(active["links"] > 0, case_id + " active route expresses reasoning through Link")
        check(passive["links"] == 0 and passive["raised"] == 0, case_id + " passive route cannot manufacture player reasoning")
        check(active["innocent"] <= passive["innocent"] + 8, case_id + " active play does not create materially more innocent isolations")
        check(active["casualties"] <= passive["casualties"] + 8, case_id + " active play does not create materially more casualties")
        check(float(active["continue_only"]) <= float(active["meaningful"]) * 1.5 + SEEDS, case_id + " meetings are not dominated by dead space")
    check(global_active["public"] > 0 and global_active["links"] > 0, "paired QA records explicit player reasoning")
    check(global_passive["public"] == 0 and global_passive["links"] == 0, "passive path has no false player attribution")
    if failures.is_empty():
        print("ASTRA CAUSAL 101 TESTS OK · %d paired seeds" % (SEEDS * CASES.size()))
        quit(0)
    print("ASTRA CAUSAL 101 TESTS FAILED · %d" % failures.size())
    quit(1)
