class_name AstraTestBots
extends RefCounted

# Automated players used by the test suite (0.8.0 rules).
#
# SMART  : talks to people, follows contextual follow-ups, puts what it learned
#          on the table in the meeting, votes by the explorer's own judgement
#          (AstraGameSession.suspicion_breakdown("player", ...)) — which reads
#          only facts the explorer actually holds or heard in public.
# RANDOM : uses legal information at random: random people, random follow-ups,
#          random intervention, random legal vote.
# PASSIVE: talks to nobody, never intervenes, and votes with the room (there is
#          no abstention): whoever most of the crew is already voting for.
#          Measures how far the crew carries a player who does nothing.
# None of them reads truth["nulls"] or a crew member's role.

# `engaged`: a player who plays the short walking scenes (SMART) finishes them;
# the others read past them, which counts as skipped.
static func _finish_morning(s: AstraGameSession, engaged: bool = false) -> void:
    var guard := 0
    while not s.story_finished() and guard < 200:
        guard += 1
        var scene := s.story_scene()
        if engaged and str(scene.get("kind", "")) == "interlude":
            s.finish_interlude(str(scene.get("interlude", "")), "success")
        elif not Array(scene.get("choices", [])).is_empty():
            s.story_choose(0)
        else:
            s.story_next()

static func _night(s: AstraGameSession, pick_best: bool, rng: RandomNumberGenerator = null) -> void:
    var options: Array = s.night_options().get("protect", [])
    if options.is_empty():
        s.choose_night_action("skip", "")
        return
    var target := str(options[0])
    if pick_best:
        # Shield whoever has spoken up most against the explorer's top suspect,
        # or the explorer themself when they pushed hardest.
        target = "player" if "player" in options else str(options[0])
    elif rng != null:
        target = str(options[rng.randi_range(0, options.size() - 1)])
    s.choose_night_action("protect", target)

static func _vote(s: AstraGameSession, target: String) -> void:
    s.cast_vote(target)
    if s.vote_stage() == "RUNOFF":
        var best := ""
        var best_value := -99.0
        for candidate in s.runoff_candidates():
            var value := s.suspicion_score("player", str(candidate))
            if value > best_value:
                best_value = value
                best = str(candidate)
        s.cast_vote(best)
    if s.vote_stage() == "TIEBREAK":
        var best := str(s.runoff_candidates()[0])
        var best_value := -99.0
        for candidate in s.runoff_candidates():
            var value := s.suspicion_score("player", str(candidate))
            if value > best_value:
                best_value = value
                best = str(candidate)
        s.resolve_tiebreak(best)

static func _player_top(s: AstraGameSession) -> String:
    var best := ""
    var best_value := -99.0
    for target in s.eligible_vote_targets():
        var value := s.suspicion_score("player", str(target))
        if value > best_value:
            best_value = value
            best = str(target)
    return best

# A thinking player in the meeting: listens, and spends the one intervention
# where it changes something they can justify from what they know.
static func _smart_meeting(s: AstraGameSession) -> void:
    var guard := 0
    while not s.meeting_over() and guard < 10:
        guard += 1
        if s.meeting_actions_left > 0:
            var link := smart_link(s)
            if link != "":
                s.intervene("link", link)
        if s.meeting_actions_left > 0:
            var pick := _smart_moment_pick(s)
            if not pick.is_empty():
                s.intervene(str(pick["kind"]), str(pick["ref"]))
        s.meeting_continue()
    if s.meeting_actions_left > 0:
        var pick := _smart_moment_pick(s, true)
        if not pick.is_empty():
            s.intervene(str(pick["kind"]), str(pick["ref"]))
        else:
            var top := _player_top(s)
            if top != "" and s.suspicion_score("player", top) >= 0.25:
                s.intervene("accuse", top)

# The explorer's own reasoning: a statement and one or two things it knows
# that show it cannot be true. Only links the judgement accepts as a
# contradiction or a narrowing to two, never the same link twice.
static func smart_link(s: AstraGameSession) -> String:
    var done := {}
    var shown := {}
    for entry in s.stage_state().get("links", []):
        if int(entry.get("day", 0)) == s.day:
            done[str(entry.get("statement", "")) + "|" + str(entry.get("evidence", ""))] = true
            var t: Array = Array(entry.get("targets", [])).duplicate()
            t.sort()
            shown[str(t)] = true
    var best := ""
    var best_value := 0.0
    var top := _player_top(s)
    for statement in s.link_statements():
        var sref := str(statement["ref"])
        var evidence := s.link_evidence(sref)
        for ev in evidence:
            var eref := str(ev["ref"])
            if done.has(sref + "|" + eref):
                continue
            var verdict := s.judge_link(sref, eref)
            var value := 0.0
            if str(verdict["result"]) == "CONTRADICTION":
                var t2: Array = Array(verdict.get("targets", [])).duplicate()
                t2.sort()
                if shown.has(str(t2)):
                    continue
                value = 1.0 + (0.5 if top in Array(verdict.get("targets", [])) else 0.0)
            elif str(verdict["result"]) == "NARROWS" and str(ev.get("kind", "")) == "fragment":
                for ev2 in evidence:
                    var eref2 := str(ev2["ref"])
                    if eref2 == eref or str(ev2.get("kind", "")) != "fragment":
                        continue
                    var pair := s.judge_link(sref, eref, eref2)
                    if str(pair["result"]) == "CONTRADICTION" and 1.2 > value:
                        value = 1.2
                        if value > best_value:
                            best_value = value
                            best = "%s|%s|%s" % [sref, eref, eref2]
                continue
            if value > best_value:
                best_value = value
                best = "%s|%s" % [sref, eref]
    return best

static func _smart_moment_pick(s: AstraGameSession, last_chance: bool = false) -> Dictionary:
    var top := _player_top(s)
    for option in s.meeting_options():
        var kind := str(option["kind"])
        var ref := str(option["ref"])
        match kind:
            "settle":
                return option
            "source":
                # A retold sighting: hear it from the person who saw it.
                return option
            "present":
                var item := s.fragment(ref)
                var type := str(item.get("type", ""))
                if type in ["ALIBI_SUPPORT", "EXPERT_INFERENCE"] or top in Array(item.get("points_to", [])) or last_chance:
                    return option
            "press_frame":
                var frame := s.fragment(s._frame_id_for(ref))
                var scapegoat := str(frame.get("subject", ""))
                if s.suspicion_score("player", ref) >= s.suspicion_score("player", scapegoat):
                    return option
            "defend":
                if ref != top:
                    return option
            "coax":
                if ref != top:
                    return option
            "basis":
                if ref == top:
                    return option
            "group", "press":
                if top != "" and (ref == top or top in Array(s.fragment(ref).get("points_to", []))):
                    return option
    return {}

static func play_smart(case_id: String, seed_value: int, protocol: String = "NONE", difficulty: String = "STANDARD") -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, protocol, difficulty)
    var steps := 0
    while s.phase != "RESULT" and steps < 400:
        steps += 1
        match s.phase:
            "BRIEFING":
                _finish_morning(s, true)
                s.advance()
            "INTERROGATION":
                # Prefer people who hold something (hinted), then whoever the
                # explorer already suspects, then anyone not yet heard.
                var order: Array = s.living_ids().duplicate()
                var leads := s.talk_leads()
                order.sort_custom(func(a, b): return s.suspicion_score("player", str(a)) + (1.0 if leads.has(str(a)) else 0.0) > s.suspicion_score("player", str(b)) + (1.0 if leads.has(str(b)) else 0.0))
                var talked := 0
                for npc_id in order:
                    if s.conversations_left() <= 0:
                        break
                    s.ask(str(npc_id), "STATEMENT")
                    talked += 1
                    var guard := 0
                    while s.followups_left(str(npc_id)) > 0 and guard < 4:
                        guard += 1
                        var options := s.question_options(str(npc_id))
                        var picked := {}
                        for option in options:
                            if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["CONFRONT", "RECORD"]:
                                picked = option
                                break
                        if picked.is_empty():
                            for option in options:
                                if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["WITNESS", "REASSURE", "YESTERDAY"]:
                                    picked = option
                                    break
                        if picked.is_empty():
                            break
                        s.ask(str(npc_id), str(picked["intent"]), str(picked.get("ref", "")))
                s.advance()
            "MEETING":
                _smart_meeting(s)
                s.advance()
            "VOTE":
                _vote(s, _player_top(s))
                s.advance()
            "NIGHT":
                _night(s, true)
                s.advance()
    return s.final_report

static func _crowd_pick(s: AstraGameSession, pool: Array) -> String:
    var tally := {}
    var intentions := s.vote_intentions(pool)
    for voter in intentions:
        var target := str(intentions[voter])
        tally[target] = int(tally.get(target, 0)) + 1
    var best := str(pool[0])
    for target in pool:
        if int(tally.get(str(target), 0)) > int(tally.get(best, 0)):
            best = str(target)
    return best

static func play_passive(case_id: String, seed_value: int, protocol: String = "NONE", difficulty: String = "STANDARD") -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, protocol, difficulty)
    var steps := 0
    while s.phase != "RESULT" and steps < 400:
        steps += 1
        match s.phase:
            "BRIEFING":
                _finish_morning(s)
                s.advance()
            "VOTE":
                # Carried by the room: votes where the crew is already going.
                s.cast_vote(_crowd_pick(s, s.eligible_vote_targets()))
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
    return s.final_report

static func play_random(case_id: String, seed_value: int, protocol: String = "NONE", difficulty: String = "STANDARD") -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, protocol, difficulty)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value * 31 + 5
    var steps := 0
    while s.phase != "RESULT" and steps < 400:
        steps += 1
        match s.phase:
            "BRIEFING":
                _finish_morning(s)
                s.advance()
            "INTERROGATION":
                for _i in range(4):
                    var living := s.living_ids()
                    var who := str(living[rng.randi_range(0, living.size() - 1)])
                    s.ask(who, "STATEMENT")
                    var options := s.question_options(who)
                    if not options.is_empty():
                        var option: Dictionary = options[rng.randi_range(0, options.size() - 1)]
                        s.ask(who, str(option["intent"]), str(option.get("ref", "")))
                s.advance()
            "MEETING":
                # Random moment, random option: legal information used blindly.
                var guard := 0
                while not s.meeting_over() and guard < 8:
                    guard += 1
                    var options := s.meeting_options()
                    if not options.is_empty() and rng.randf() < 0.35:
                        var option: Dictionary = options[rng.randi_range(0, options.size() - 1)]
                        var ref := str(option["ref"])
                        if str(option["kind"]) == "accuse":
                            var living := s.living_ids()
                            ref = str(living[rng.randi_range(0, living.size() - 1)])
                        elif str(option["kind"]) == "link":
                            var statements := s.link_statements()
                            var statement := str(statements[rng.randi_range(0, statements.size() - 1)]["ref"])
                            var evidence := s.link_evidence(statement)
                            if evidence.is_empty():
                                continue
                            ref = "%s|%s" % [statement, str(evidence[rng.randi_range(0, evidence.size() - 1)]["ref"])]
                        s.intervene(str(option["kind"]), ref)
                    s.meeting_continue()
                s.advance()
            "VOTE":
                var targets := s.eligible_vote_targets()
                s.cast_vote(str(targets[rng.randi_range(0, targets.size() - 1)]))
                if s.vote_stage() == "RUNOFF":
                    var c := s.runoff_candidates()
                    s.cast_vote(str(c[rng.randi_range(0, c.size() - 1)]))
                if s.vote_stage() == "TIEBREAK":
                    var c := s.runoff_candidates()
                    s.resolve_tiebreak(str(c[rng.randi_range(0, c.size() - 1)]))
                s.advance()
            "NIGHT":
                _night(s, false, rng)
                s.advance()
    return s.final_report
