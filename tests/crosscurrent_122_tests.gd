extends SceneTree

# ASTRA 1.2.2 — CROSSCURRENT
# Yesterday's visible verdict residue may become one bounded two-person social
# continuation. The feature must change presentation/agency while preserving
# truth, generated evidence, action counts, save versions and role fairness.
var failures: Array[String] = []
var checks := 0

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    run_audit()
    if failures.is_empty():
        print("ASTRA CROSSCURRENT 122 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA CROSSCURRENT 122 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _session(seed_value: int = 12201, case_name: String = "DEAD_AIR") -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup(case_name, seed_value)
    s.begin_voyage({})
    return s

func _pair(s: AstraGameSession) -> Array:
    var ids := s.living_ids()
    check(ids.size() >= 2, "test Stage has at least two living crew")
    return [str(ids[0]), str(ids[1])]

func _install_residue(s: AstraGameSession, pattern: String, lead: String, subject: String, source_type: String = "LINK") -> void:
    var residues: Dictionary = s.stage_state().get("verdict_residue", {})
    residues["1"] = {
        "day": 1,
        "pattern": pattern,
        "subject": subject,
        "player_target": subject,
        "commitment_type": "defend" if pattern in ["STOOD_BY", "REVERSAL", "EVIDENCE_DRIVEN_REVERSAL"] else "accuse",
        "commitment_index": 2,
        "ballot_reason": {
            "target": subject,
            "code": "link" if source_type == "LINK" else "evidence",
            "text": "어제 공개된 근거",
            "source_ids": [],
            "source_type": source_type,
            "source_owner": lead,
            "link_id": "crosscurrent:test",
            "contradiction_key": "crosscurrent",
            "created_index": 5
        },
        "lead_npc": lead
    }
    s.stage_state()["verdict_residue"] = residues

func _day_two(s: AstraGameSession) -> void:
    s.day = 2
    s._install_day_packet(2)
    s.phase = "BRIEFING"

func _choice_session(index: int, seed_value: int) -> Dictionary:
    var s := _session(seed_value)
    var ids := _pair(s)
    var lead := str(ids[0])
    var partner := str(ids[1])
    _install_residue(s, "EVIDENCE_DRIVEN_REVERSAL", lead, partner)
    _day_two(s)
    var scene := s._crosscurrent_scene(2)
    check(not scene.is_empty(), "choice probe has a Crosscurrent scene")
    s.stage_state()["story_queue"] = [scene]
    s.stage_state()["story_index"] = 0
    s.stage_state()["story_line"] = 0
    var known_before := s.known_fragments().size()
    check(s.story_choose(index), "Crosscurrent option %d is selectable" % index)
    check(s.known_fragments().size() == known_before, "Crosscurrent option %d grants no free fragment" % index)
    var choices: Dictionary = s.stage_state().get("crosscurrent_choices", {})
    var picked: Dictionary = choices.get("1", {})
    return {
        "session": s,
        "lead": lead,
        "partner": partner,
        "priority": str(picked.get("priority", "")),
        "opener": str(picked.get("meeting_opener", "")),
        "lead_expression": s.crew[lead].expression,
        "partner_expression": s.crew[partner].expression
    }

func _dimension_diff(a: Dictionary, b: Dictionary) -> int:
    var result := 0
    for key in ["priority", "opener", "lead_expression", "partner_expression"]:
        if str(a.get(key, "")) != str(b.get(key, "")):
            result += 1
    return result

func run_audit() -> void:
    # All 1.2.1 residue patterns can feed the continuation when two relevant
    # living participants exist. CALIBRATION remains protected.
    for pattern in ["FOLLOW_THROUGH", "STOOD_BY", "REVERSAL", "EVIDENCE_DRIVEN_REVERSAL", "REASON_FOLLOWUP"]:
        var s := _session(12210 + checks)
        var ids := _pair(s)
        _install_residue(s, pattern, str(ids[0]), str(ids[1]))
        _day_two(s)
        var scene := s._crosscurrent_scene(2)
        check(not scene.is_empty(), pattern + " can produce a Crosscurrent continuation")
        if not scene.is_empty():
            var speakers := {}
            for line in scene.get("lines", []):
                var who := str(line[0])
                if who != "":
                    speakers[who] = true
            check(speakers.size() == 2, pattern + " continuation uses two distinct people")
            check(Array(scene.get("choices", [])).size() == 3, pattern + " continuation offers three bounded interventions")
            var data: Dictionary = scene.get("crosscurrent", {})
            check(not data.has("truth") and not data.has("nulls") and not data.has("role"), pattern + " metadata contains no hidden role/truth")

    var calibration := _session(12260, "CALIBRATION")
    var calibration_ids := _pair(calibration)
    _install_residue(calibration, "STOOD_BY", str(calibration_ids[0]), str(calibration_ids[1]))
    _day_two(calibration)
    check(calibration._crosscurrent_scene(2).is_empty(), "CALIBRATION does not force Crosscurrent")

    # Scene selection is capped once per source Day and replaces, rather than
    # stacks with, the generic 1.2.1 morning callback.
    var replace := _session(12270)
    var replace_ids := _pair(replace)
    _install_residue(replace, "STOOD_BY", str(replace_ids[0]), str(replace_ids[1]))
    _day_two(replace)
    var truth_before := JSON.stringify(replace.truth)
    var packet_before := JSON.stringify(replace.current_packet())
    replace.morning_report = ["밤은 조용했다."]
    replace._queue_morning(2)
    var cross_count := 0
    var generic_count := 0
    for scene in replace.story_queue():
        var id := str(scene.get("id", ""))
        if id.begins_with("crosscurrent_"):
            cross_count += 1
        if id.begins_with("verdict_residue_"):
            generic_count += 1
    check(cross_count == 1, "morning queue contains at most one Crosscurrent")
    check(generic_count == 0, "Crosscurrent replaces generic verdict callback")
    check(replace._crosscurrent_scene(2).is_empty(), "same source Day cannot queue Crosscurrent twice")
    check(JSON.stringify(replace.truth) == truth_before, "Crosscurrent scene does not change truth/Null assignment")
    check(JSON.stringify(replace.current_packet()) == packet_before, "Crosscurrent scene does not change Day Packet/base evidence")

    # If a natural second person is unavailable, the old single-person callback
    # remains a safe fallback and inactive people never speak.
    var fallback := _session(12280)
    var fallback_ids := _pair(fallback)
    var dead_lead := str(fallback_ids[0])
    var dead_subject := str(fallback_ids[1])
    _install_residue(fallback, "STOOD_BY", dead_lead, dead_subject, "INSTINCT")
    fallback.crew[dead_lead].status = AstraCrewMember.STATUS_ISOLATED
    fallback.crew[dead_subject].status = AstraCrewMember.STATUS_ISOLATED
    _day_two(fallback)
    check(fallback._crosscurrent_scene(2).is_empty(), "invalid/dead pair does not force a Crosscurrent")
    var one_person := fallback._verdict_callback_scene(2)
    check(one_person.is_empty() or fallback.is_alive(str(one_person.get("speaker", ""))), "fallback never makes an inactive NPC speak")

    # Three interventions differ in multiple player-visible dimensions and do
    # not alter truth/evidence. Their selected lead is fed into today's talk
    # priority and the meeting opener.
    var a := _choice_session(0, 12301)
    var b := _choice_session(1, 12301)
    var c := _choice_session(2, 12301)
    check(_dimension_diff(a, b) >= 2, "stand vs reframe differs in at least two visible dimensions")
    check(_dimension_diff(a, c) >= 2, "stand vs verify differs in at least two visible dimensions")
    check(_dimension_diff(b, c) >= 2, "reframe vs verify differs in at least two visible dimensions")
    for probe in [a, b, c]:
        var s: AstraGameSession = probe["session"]
        var leads := s.talk_leads()
        check(leads.has(str(probe["priority"])), "selected Crosscurrent priority becomes a talk lead")
        check(leads.size() <= 4, "Crosscurrent preserves the four-lead cap")
        check(str(probe["opener"]) != "", "Crosscurrent choice stores a same-Day meeting opener")
        check(s._verdict_followup_for(str(probe["priority"])).is_empty(), "generic VERDICT follow-up is suppressed after Crosscurrent choice")
        var before_truth := JSON.stringify(s.truth)
        var before_packet := JSON.stringify(s.current_packet())
        s.phase = "MEETING"
        s._open_meeting()
        check(JSON.stringify(s.truth) == before_truth, "meeting payoff does not change truth")
        check(JSON.stringify(s.current_packet()) == before_packet, "meeting payoff does not change Day Packet")

    # Category/pair logic must not inspect the hidden role. Changing only role
    # labels leaves the public continuation category unchanged.
    var role_safe := _session(12320)
    var role_ids := _pair(role_safe)
    var role_lead := str(role_ids[0])
    var role_partner := str(role_ids[1])
    _install_residue(role_safe, "STOOD_BY", role_lead, role_partner)
    var residue := role_safe.verdict_residue(1)
    var cat_before := role_safe._crosscurrent_category(residue, role_lead, role_partner)
    var old_lead_role := role_safe.crew[role_lead].role
    var old_partner_role := role_safe.crew[role_partner].role
    role_safe.crew[role_lead].role = "NULL" if old_lead_role != "NULL" else "CREW"
    role_safe.crew[role_partner].role = "NULL" if old_partner_role != "NULL" else "CREW"
    var cat_after := role_safe._crosscurrent_category(residue, role_lead, role_partner)
    check(cat_before == cat_after, "Crosscurrent category has no role tell")
    role_safe.crew[role_lead].role = old_lead_role
    role_safe.crew[role_partner].role = old_partner_role

    # Snapshot v4 carries optional stage state and dedup safely; no schema bump.
    var save := _session(12330)
    var save_ids := _pair(save)
    _install_residue(save, "STOOD_BY", str(save_ids[0]), str(save_ids[1]))
    _day_two(save)
    check(not save._crosscurrent_scene(2).is_empty(), "save probe queues Crosscurrent")
    var save_path := "user://crosscurrent_122.cfg"
    AstraGameSession.delete_snapshot(save_path)
    check(save.save_snapshot(save_path), "Crosscurrent snapshot saves")
    var loaded := AstraGameSession.new()
    check(loaded.load_snapshot(save_path), "Crosscurrent snapshot reloads")
    check(loaded._crosscurrent_scene(2).is_empty(), "reload does not duplicate an already queued Crosscurrent")
    check(AstraGameSession.SNAPSHOT_VERSION == 4, "Snapshot remains v4")
    check(AstraMetaProgress.SAVE_VERSION == 12, "Meta save remains v12")
    AstraGameSession.delete_snapshot(save_path)

    # The feature remains bounded: no new reputation/morality/credibility state,
    # no extra phase and no action-count mutation.
    var bounded := _session(12340)
    var bounded_ids := _pair(bounded)
    _install_residue(bounded, "STOOD_BY", str(bounded_ids[0]), str(bounded_ids[1]))
    _day_two(bounded)
    var actions_before := int(bounded.voyage.get("actions", 0))
    var bounded_scene := bounded._crosscurrent_scene(2)
    bounded.stage_state()["story_queue"] = [bounded_scene]
    bounded.stage_state()["story_index"] = 0
    check(bounded.story_choose(0), "bounded probe selects Crosscurrent")
    check(int(bounded.voyage.get("actions", 0)) == actions_before, "Crosscurrent choice grants no extra action")
    for forbidden in ["reputation", "morality", "credibility", "social_points", "suspicion_meter"]:
        check(not bounded.stage_state().has(forbidden), "no new " + forbidden + " state")
    check("MEETING" in AstraGameSession.PHASES and AstraGameSession.PHASES.size() == 8, "Crosscurrent adds no new phase")
