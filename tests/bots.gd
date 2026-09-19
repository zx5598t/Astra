class_name AstraTestBots
extends RefCounted

# Automated players used by the test suite.
# The smart bot only reads information a human player can see on screen.

const INFO_EFFECTS := ["witness", "open_records", "noa_private", "noa_public", "dax_hint", "top_suspect", "patrol", "vale_record", "flow", "crowd_target"]

static func deduce(s: AstraGameSession) -> Dictionary:
    # 0.4.0: a case may run with fewer than the eight identity models, so the
    # bot scores the roster it was actually given.
    var scores := {}
    for npc_id in s.active_roster():
        scores[npc_id] = 0.0
    var window_start := int(s.case_data.get("window_start", 0))
    var window_end := int(s.case_data.get("window_end", 0))
    for op in s.case_data.get("ops", []):
        var op_id := str(op.get("id", ""))
        var sets: Array = []
        for clue in s.found_clues():
            if str(clue.get("op", "")) != op_id:
                continue
            var kind := str(clue.get("kind", ""))
            if kind not in ["trace", "sighting", "night", "slip", "planted"]:
                continue
            if kind == "trace":
                var minute := int(clue.get("minute", window_start))
                if minute < window_start - 1 or minute > window_end + 3:
                    continue
            if kind in ["sighting", "planted"] and str(clue.get("source", "")) != "":
                if float(scores.get(str(clue.get("source", "")), 0.0)) > 1.5:
                    continue
            sets.append(clue.get("members", []))
        for members in sets:
            for member_id in members:
                scores[str(member_id)] = float(scores.get(str(member_id), 0.0)) + 1.0 / maxf(1.0, float(members.size()))
        for a_index in range(sets.size()):
            for b_index in range(a_index + 1, sets.size()):
                var both: Array = []
                for member_id in sets[a_index]:
                    if member_id in sets[b_index]:
                        both.append(member_id)
                if both.size() == 1:
                    scores[str(both[0])] = float(scores.get(str(both[0]), 0.0)) + 3.0
    for item in s.contradictions:
        var kind := str(item.get("kind", ""))
        for target in item.get("targets", []):
            if kind in ["log", "log_presence"]:
                scores[str(target)] = float(scores.get(str(target), 0.0)) + 1.8
            elif kind == "terminal":
                scores[str(target)] = float(scores.get(str(target), 0.0)) + 0.9
            else:
                scores[str(target)] = float(scores.get(str(target), 0.0)) + 0.5
    for npc_id in s.active_roster():
        var member := s.npc(npc_id)
        if member == null:
            continue
        if member.secret_revealed:
            scores[npc_id] = float(scores[npc_id]) - 3.0
        if member.audited:
            scores[npc_id] = float(scores[npc_id]) + (10.0 if member.is_null() else -10.0)
        if member.status == AstraCrewMember.STATUS_OFFLINE:
            scores[npc_id] = -20.0
    for clue in s.found_clues():
        if str(clue.get("kind", "")) == "access_log":
            for person in clue.get("log_people", []):
                if s.known_claims.has(str(person)) and str(s.known_claims[str(person)].get("position", "")) == str(clue.get("log_room", "")):
                    scores[str(person)] = float(scores.get(str(person), 0.0)) - 1.0
    return scores

static func ranked(s: AstraGameSession, only_alive: bool) -> Array:
    var scores := deduce(s)
    var ids: Array = []
    for npc_id in s.active_roster():
        if only_alive and not s.is_alive(npc_id):
            continue
        ids.append(npc_id)
    ids.sort_custom(func(a, b): return float(scores.get(a, 0.0)) > float(scores.get(b, 0.0)))
    return ids

static func play_smart(case_id: String, seed_value: int, protocol: String) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, protocol)
    var steps := 0
    while s.phase != "RESULT" and steps < 300:
        steps += 1
        match s.phase:
            "BRIEFING":
                s.advance()
            "INVESTIGATION":
                while s.investigation_ap > 0:
                    var best_room := ""
                    var best_count := 0
                    for room_id in s.room_ids():
                        var remaining := int(s.room_status(room_id).get("remaining", 0))
                        if remaining > best_count:
                            best_count = remaining
                            best_room = room_id
                    if best_room == "":
                        break
                    s.search_room(best_room)
                s.advance()
            "INTERROGATION":
                if not s.pending_event.is_empty():
                    var choice := 0
                    var choices: Array = s.pending_event.get("choices", [])
                    for index in range(choices.size()):
                        if str(choices[index].get("effect", "")) in INFO_EFFECTS:
                            choice = index
                            break
                    s.resolve_private_event(choice)
                var guard := 0
                while s.talk_ap > 0 and guard < 12:
                    guard += 1
                    var order := ranked(s, true)
                    var acted := false
                    for npc_id in order:
                        if s.has_contradiction_on(npc_id) and not s.npc(npc_id).secret_revealed and not s.npc(npc_id).slipped:
                            if s.ask(npc_id, "CONTRADICTION").get("ok", false):
                                acted = true
                                break
                    if acted:
                        continue
                    for npc_id in s.living_ids():
                        if not s.known_claims.has(npc_id):
                            if s.ask(npc_id, "ALIBI").get("ok", false):
                                acted = true
                                break
                    if acted:
                        continue
                    if not order.is_empty():
                        var target := str(order[0])
                        if s.npc(target).stress < 0.7:
                            s.ask(target, "PRESSURE")
                        else:
                            s.ask(target, "REASSURE")
                s.advance()
            "MEETING":
                var guard := 0
                while s.meeting_actions_left > 0 and guard < 6:
                    guard += 1
                    var order := ranked(s, true)
                    var top := str(order[0]) if not order.is_empty() else ""
                    var presented := false
                    for clue in s.found_clues():
                        if bool(clue.get("public", false)):
                            continue
                        var kind := str(clue.get("kind", ""))
                        if kind == "slip" or kind == "access_log" or (top != "" and top in clue.get("members", []) and kind in ["trace", "night"]):
                            if s.present_clue(str(clue.get("id", ""))).get("ok", false):
                                presented = true
                                break
                    if presented:
                        continue
                    if top != "":
                        s.accuse(top)
                    else:
                        break
                s.advance()
            "VOTE":
                var alive_order := ranked(s, true)
                var all_order := ranked(s, false)
                var theory: Array = []
                for npc_id in all_order:
                    if s.npc(npc_id).status != AstraCrewMember.STATUS_OFFLINE and theory.size() < 2:
                        theory.append(npc_id)
                s.cast_vote(str(alive_order[0]) if not alive_order.is_empty() else "", theory, 70)
                s.advance()
            "NIGHT":
                var options := s.night_options()
                var done := false
                if not options.get("audit", []).is_empty():
                    for isolation in s.isolations:
                        if str(isolation.get("id", "")) in options["audit"]:
                            s.choose_night_action("audit", str(isolation.get("id", "")))
                            done = true
                            break
                if not done:
                    var scores := deduce(s)
                    var guard_target := ""
                    var best := 99.0
                    for npc_id in options.get("protect", []):
                        var value := float(scores.get(npc_id, 0.0)) - s.npc(npc_id).trust
                        if value < best:
                            best = value
                            guard_target = str(npc_id)
                    s.choose_night_action("protect", guard_target)
                s.advance()
    return s.final_report

# Never investigates, never speaks, always abstains: measures how much the
# NPC crowd solves on its own. This should stay low.
static func play_passive(case_id: String, seed_value: int, protocol: String) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, protocol)
    var steps := 0
    while s.phase != "RESULT" and steps < 300:
        steps += 1
        match s.phase:
            "INTERROGATION":
                if not s.pending_event.is_empty():
                    s.resolve_private_event(1)
                s.advance()
            "VOTE":
                s.cast_vote("")
                s.advance()
            "NIGHT":
                var protect: Array = s.night_options().get("protect", [])
                s.choose_night_action("protect", str(protect[0]))
                s.advance()
            _:
                s.advance()
    return s.final_report

static func play_random(case_id: String, seed_value: int, protocol: String) -> Dictionary:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value, protocol)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value * 31 + 5
    var steps := 0
    while s.phase != "RESULT" and steps < 300:
        steps += 1
        match s.phase:
            "INVESTIGATION":
                for _i in range(6):
                    var rooms := s.room_ids()
                    s.search_room(str(rooms[rng.randi_range(0, rooms.size() - 1)]))
                s.advance()
            "INTERROGATION":
                if not s.pending_event.is_empty():
                    s.resolve_private_event(rng.randi_range(0, 2))
                for _i in range(8):
                    var living := s.living_ids()
                    var target := str(living[rng.randi_range(0, living.size() - 1)])
                    var intents := ["ALIBI", "SUSPECT", "REASSURE", "PRESSURE", "CONTRADICTION", "CONFIDE"]
                    s.ask(target, str(intents[rng.randi_range(0, intents.size() - 1)]))
                s.advance()
            "MEETING":
                for _i in range(3):
                    var living := s.living_ids()
                    var target := str(living[rng.randi_range(0, living.size() - 1)])
                    if rng.randf() < 0.5:
                        s.accuse(target)
                    else:
                        s.defend(target)
                s.advance()
            "VOTE":
                var living := s.living_ids()
                s.cast_vote(str(living[rng.randi_range(0, living.size() - 1)]))
                s.advance()
            "NIGHT":
                var options := s.night_options()
                var protect: Array = options.get("protect", [])
                s.choose_night_action("protect", str(protect[rng.randi_range(0, protect.size() - 1)]))
                s.advance()
            _:
                s.advance()
    return s.final_report
