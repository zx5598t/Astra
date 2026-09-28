extends SceneTree

# ASTRA 1.2.3 — CLEAR CURRENT
# Runtime exposure audit for CROSSCURRENT. This drives representative SMART
# Stage/Day flows across multiple deterministic seeds, chooses a real ballot
# reason before each vote, and measures what the player actually sees.
const SEEDS_PER_STAGE := 8

var failures: Array[String] = []
var checks := 0
var metrics := {}
var scopes := {}

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    _reset_metrics()
    for case_id in AstraCaseCatalog.STAGE_ORDER:
        for index in range(SEEDS_PER_STAGE):
            _play_case(case_id, 23000 + index * 37 + AstraCaseCatalog.stage_index(case_id) * 1000)
    check(int(metrics.get("same_pair_category_consecutive", 0)) == 0,
        "CLEAR CURRENT suppresses immediate same-pair/same-category repeats")
    check(int(metrics.get("shown", 0)) + int(metrics.get("suppression", 0)) == int(metrics.get("eligible", 0)),
        "every eligible Crosscurrent is either shown or pacing-suppressed")
    check(not Dictionary(metrics.get("category", {})).is_empty(),
        "exposure audit records category distribution")
    for path in ["stand", "reframe", "verify"]:
        check(int(Dictionary(metrics.get("choice", {})).get(path, 0)) > 0,
            "exposure audit covers " + path)
    _print_summary()
    if failures.is_empty():
        print("ASTRA CROSSCURRENT EXPOSURE 123 OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA CROSSCURRENT EXPOSURE 123 FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _blank_metrics() -> Dictionary:
    return {
        "days": 0,
        "eligible": 0,
        "shown": 0,
        "fallback": 0,
        "suppression": 0,
        "max_streak": 0,
        "two_day_consecutive": 0,
        "three_plus_consecutive": 0,
        "same_pair_consecutive": 0,
        "same_category_consecutive": 0,
        "same_pair_category_consecutive": 0,
        "past_echo_collision": 0,
        "generic_replacement": 0,
        "duplicate_verdict_suppressed": 0,
        "lead": {},
        "partner": {},
        "priority": {},
        "category": {},
        "choice": {"stand": 0, "reframe": 0, "verify": 0}
    }

func _reset_metrics() -> void:
    metrics = _blank_metrics()
    scopes = {
        "CALIBRATION": _blank_metrics(),
        "PART_I": _blank_metrics(),
        "PART_II": _blank_metrics()
    }

func _scope(s: AstraGameSession) -> String:
    if s.case_id == AstraCaseCatalog.CALIBRATION:
        return "CALIBRATION"
    return "PART_I" if s.part() == 1 else "PART_II"

func _inc_dict(book: Dictionary, key: String) -> void:
    book[key] = int(book.get(key, 0)) + 1

func _bump(field: String, amount: int = 1, scope_name: String = "") -> void:
    metrics[field] = int(metrics.get(field, 0)) + amount
    if scope_name != "":
        var scoped: Dictionary = scopes[scope_name]
        scoped[field] = int(scoped.get(field, 0)) + amount
        scopes[scope_name] = scoped

func _bump_named(field: String, key: String, scope_name: String) -> void:
    var all_book: Dictionary = metrics[field]
    _inc_dict(all_book, key)
    metrics[field] = all_book
    var scoped: Dictionary = scopes[scope_name]
    var scoped_book: Dictionary = scoped[field]
    _inc_dict(scoped_book, key)
    scoped[field] = scoped_book
    scopes[scope_name] = scoped

func _set_max(field: String, value: int, scope_name: String) -> void:
    metrics[field] = maxi(int(metrics.get(field, 0)), value)
    var scoped: Dictionary = scopes[scope_name]
    scoped[field] = maxi(int(scoped.get(field, 0)), value)
    scopes[scope_name] = scoped

func _pair_key(lead: String, partner: String) -> String:
    var ids := [lead, partner]
    ids.sort()
    return "%s+%s" % [str(ids[0]), str(ids[1])]

func _candidate(s: AstraGameSession) -> Dictionary:
    if s.day <= 1 or s.case_id == AstraCaseCatalog.CALIBRATION:
        return {}
    var residue := s.verdict_residue(s.day - 1)
    if residue.is_empty():
        return {}
    if str(residue.get("pattern", "")) == "REASON_FOLLOWUP" and not s._verdict_residue_reason_is_public(residue):
        return {}
    var lead := s._verdict_alive_lead(residue)
    var partner := s._crosscurrent_partner(residue)
    if lead == "" or partner == "" or lead == partner or not s.is_alive(lead) or not s.is_alive(partner):
        return {}
    return {
        "lead": lead,
        "partner": partner,
        "pair": _pair_key(lead, partner),
        "category": s._crosscurrent_category(residue, lead, partner)
    }

func _scene_counts(s: AstraGameSession) -> Dictionary:
    var result := {"cross": 0, "fallback": 0, "cross_scene": {}}
    for raw in s.story_queue():
        var scene: Dictionary = raw
        var id := str(scene.get("id", ""))
        if id.begins_with("crosscurrent_") and not id.begins_with("crosscurrent_reaction_"):
            result["cross"] = int(result["cross"]) + 1
            result["cross_scene"] = scene
        elif id.begins_with("verdict_residue_"):
            result["fallback"] = int(result["fallback"]) + 1
    return result

func _choose_ballot_reason(s: AstraGameSession, target: String) -> void:
    var options := s.ballot_reasons(target)
    if options.is_empty():
        return
    var picked := -1
    for i in range(options.size()):
        var reason: Dictionary = options[i]
        if str(reason.get("code", "")) != "instinct" and s._verdict_reason_is_public(reason, s.day):
            picked = i
            break
    if picked < 0:
        picked = options.size() - 1
    check(s.set_ballot_reason(target, picked), "%s Day %d stores a player-visible ballot reason" % [s.case_id, s.day])

func _finish_morning(s: AstraGameSession, seed_value: int) -> Dictionary:
    var chosen := {}
    var guard := 0
    while not s.story_finished() and guard < 240:
        guard += 1
        var scene := s.story_scene()
        if str(scene.get("kind", "")) == "interlude":
            s.finish_interlude(str(scene.get("interlude", "")), "success")
        elif not Array(scene.get("choices", [])).is_empty():
            var index := 0
            if not Dictionary(scene.get("crosscurrent", {})).is_empty():
                index = abs(seed_value + s.day) % 3
                chosen = Dictionary(scene.get("crosscurrent", {})).duplicate(true)
                chosen["path"] = ["stand", "reframe", "verify"][index]
            check(s.story_choose(index), "%s Day %d morning choice is selectable" % [s.case_id, s.day])
        else:
            s.story_next()
    check(guard < 240, "%s Day %d morning queue terminates" % [s.case_id, s.day])
    return chosen

func _smart_interrogation(s: AstraGameSession) -> void:
    var order: Array = s.living_ids().duplicate()
    var leads := s.talk_leads()
    order.sort_custom(func(a, b):
        return s.suspicion_score("player", str(a)) + (1.0 if leads.has(str(a)) else 0.0) > s.suspicion_score("player", str(b)) + (1.0 if leads.has(str(b)) else 0.0)
    )
    for npc_id in order:
        if s.conversations_left() <= 0:
            break
        s.ask(str(npc_id), "STATEMENT")
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

func _audit_role_safety(s: AstraGameSession, candidate: Dictionary) -> void:
    if candidate.is_empty():
        return
    var lead := str(candidate.get("lead", ""))
    var partner := str(candidate.get("partner", ""))
    var before := "%s|%s" % [str(candidate.get("pair", "")), str(candidate.get("category", ""))]
    var old_lead := str(s.crew[lead].role)
    var old_partner := str(s.crew[partner].role)
    s.crew[lead].role = "NULL" if old_lead != "NULL" else "CREW"
    s.crew[partner].role = "NULL" if old_partner != "NULL" else "CREW"
    var changed := _candidate(s)
    var after := "%s|%s" % [str(changed.get("pair", "")), str(changed.get("category", ""))]
    check(before == after, "%s Day %d Crosscurrent exposure/pair/category ignores hidden role" % [s.case_id, s.day])
    s.crew[lead].role = old_lead
    s.crew[partner].role = old_partner

func _play_case(case_name: String, seed_value: int) -> void:
    var s := AstraGameSession.new()
    var stage := AstraCaseCatalog.stage_index(case_name)
    var proto := "GUARDIAN" if stage >= 5 else "NONE"
    s.setup(case_name, seed_value, proto)

    var streak := 0
    var previous_pair := ""
    var previous_category := ""
    var previous_shown := false
    var measured_day := -1
    var current_choice := {}
    var truth_before_morning := ""
    var packet_before_morning := ""
    var scope_name := _scope(s)
    var steps := 0

    while s.phase != "RESULT" and steps < 500:
        steps += 1
        match s.phase:
            "BRIEFING":
                if measured_day != s.day:
                    measured_day = s.day
                    _bump("days", 1, scope_name)
                    var candidate := _candidate(s)
                    if not candidate.is_empty():
                        _bump("eligible", 1, scope_name)
                        _audit_role_safety(s, candidate)
                    var counts := _scene_counts(s)
                    var shown := int(counts["cross"]) > 0
                    var fallback := int(counts["fallback"]) > 0
                    check(int(counts["cross"]) <= 1, "%s Day %d has at most one Crosscurrent scene" % [s.case_id, s.day])
                    check(not (shown and fallback), "%s Day %d never stacks Crosscurrent and generic verdict callback" % [s.case_id, s.day])
                    if shown:
                        _bump("shown", 1, scope_name)
                        if not candidate.is_empty():
                            _bump("generic_replacement", 1, scope_name)
                        var data: Dictionary = Dictionary(Dictionary(counts["cross_scene"]).get("crosscurrent", {}))
                        var pair := _pair_key(str(data.get("lead", "")), str(data.get("partner", "")))
                        var category := str(data.get("category", ""))
                        _bump_named("category", category, scope_name)
                        _bump_named("lead", str(data.get("lead", "")), scope_name)
                        _bump_named("partner", str(data.get("partner", "")), scope_name)
                        if previous_shown:
                            _bump("two_day_consecutive", 1, scope_name)
                            if pair == previous_pair:
                                _bump("same_pair_consecutive", 1, scope_name)
                            if category == previous_category:
                                _bump("same_category_consecutive", 1, scope_name)
                            if pair == previous_pair and category == previous_category:
                                _bump("same_pair_category_consecutive", 1, scope_name)
                        streak += 1
                        if streak >= 3:
                            _bump("three_plus_consecutive", 1, scope_name)
                        _set_max("max_streak", streak, scope_name)
                        previous_pair = pair
                        previous_category = category
                        previous_shown = true
                    else:
                        if fallback:
                            _bump("fallback", 1, scope_name)
                        if not candidate.is_empty():
                            _bump("suppression", 1, scope_name)
                        streak = 0
                        previous_pair = ""
                        previous_category = ""
                        previous_shown = false
                    truth_before_morning = JSON.stringify(s.truth)
                    packet_before_morning = JSON.stringify(s.current_packet())
                    current_choice = _finish_morning(s, seed_value)
                    check(JSON.stringify(s.truth) == truth_before_morning, "%s Day %d Crosscurrent presentation keeps truth invariant" % [s.case_id, s.day])
                    check(JSON.stringify(s.current_packet()) == packet_before_morning, "%s Day %d Crosscurrent presentation keeps Day Packet invariant" % [s.case_id, s.day])
                    if not current_choice.is_empty():
                        var path := str(current_choice.get("path", ""))
                        _bump_named("choice", path, scope_name)
                        var choice_book: Dictionary = s.stage_state().get("crosscurrent_choices", {})
                        var stored: Dictionary = choice_book.get(str(s.day - 1), {})
                        var priority := str(stored.get("priority", ""))
                        _bump_named("priority", priority, scope_name)
                        check(s._verdict_followup_for(priority).is_empty(), "%s Day %d Crosscurrent suppresses duplicate VERDICT follow-up" % [s.case_id, s.day])
                        _bump("duplicate_verdict_suppressed", 1, scope_name)
                s.advance()
            "INTERROGATION":
                _smart_interrogation(s)
                if s._past_echo_meeting_line() != "" and s._crosscurrent_meeting_line() != "":
                    _bump("past_echo_collision", 1, scope_name)
                s.advance()
            "MEETING":
                AstraTestBots._smart_meeting(s)
                s.advance()
            "VOTE":
                var target := AstraTestBots._player_top(s)
                _choose_ballot_reason(s, target)
                AstraTestBots._vote(s, target)
                s.advance()
            "NIGHT":
                AstraTestBots._night(s, true)
                s.advance()
    check(steps < 500 and s.phase == "RESULT", "%s/%d representative exposure run finishes" % [case_name, seed_value])

func _print_summary() -> void:
    print("ASTRA CROSSCURRENT EXPOSURE 123 SUMMARY " + JSON.stringify(metrics))
    for name in ["CALIBRATION", "PART_I", "PART_II"]:
        print("ASTRA CROSSCURRENT EXPOSURE 123 %s %s" % [name, JSON.stringify(scopes[name])])
