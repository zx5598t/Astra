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

func _install_residue_day(s: AstraGameSession, source_day: int, pattern: String, lead: String, subject: String, source_type: String = "LINK") -> void:
    var residues: Dictionary = s.stage_state().get("verdict_residue", {})
    residues[str(source_day)] = {
        "day": source_day,
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
            "link_id": "crosscurrent:test:%d" % source_day,
            "contradiction_key": "crosscurrent",
            "created_index": 5
        },
        "ballot_reason_public": true,
        "lead_npc": lead
    }
    s.stage_state()["verdict_residue"] = residues

func _install_residue(s: AstraGameSession, pattern: String, lead: String, subject: String, source_type: String = "LINK") -> void:
    _install_residue_day(s, 1, pattern, lead, subject, source_type)

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

    # CLEAR CURRENT pacing: an immediately consecutive scene with the exact
    # same unordered pair and category falls back to the existing one-person
    # callback. A different pair/category remains eligible.
    var repeat := _session(12272, "GLASS_GARDEN")
    var repeat_ids := repeat.living_ids()
    var repeat_lead := str(repeat_ids[0])
    var repeat_partner := str(repeat_ids[1])
    _install_residue_day(repeat, 1, "STOOD_BY", repeat_lead, repeat_partner)
    repeat.day = 2
    repeat._install_day_packet(2)
    var repeat_first := repeat._crosscurrent_scene(2)
    check(not repeat_first.is_empty(), "exact-repeat probe shows the first Crosscurrent")
    _install_residue_day(repeat, 2, "STOOD_BY", repeat_lead, repeat_partner)
    repeat.day = 3
    repeat._install_day_packet(3)
    check(repeat._crosscurrent_scene(3).is_empty(), "same pair/category immediate repeat is suppressed")
    var repeat_fallback := repeat._verdict_callback_scene(3)
    check(not repeat_fallback.is_empty(), "suppressed exact repeat uses the existing verdict fallback")
    check(not str(repeat_fallback.get("id", "")).begins_with("crosscurrent_"), "suppression does not create a replacement social scene")

    var varied := _session(12273, "GLASS_GARDEN")
    var varied_ids := varied.living_ids()
    var varied_lead := str(varied_ids[0])
    var varied_partner := str(varied_ids[1])
    var varied_other := str(varied_ids[2])
    _install_residue_day(varied, 1, "STOOD_BY", varied_lead, varied_partner)
    varied.day = 2
    varied._install_day_packet(2)
    check(not varied._crosscurrent_scene(2).is_empty(), "variation probe shows the first Crosscurrent")
    _install_residue_day(varied, 2, "EVIDENCE_DRIVEN_REVERSAL", varied_lead, varied_other)
    varied.day = 3
    varied._install_day_packet(3)
    check(not varied._crosscurrent_scene(3).is_empty(), "different meaningful pair/category is not suppressed")

    # Private ballot provenance may inform the player's own vote, but it must
    # never become an NPC-facing REASON_FOLLOWUP or promote its source owner.
    var private_reason := _session(12275)
    var private_ids := _pair(private_reason)
    var private_owner := str(private_ids[0])
    var private_target := str(private_ids[1])
    private_reason.stage_state()["ballot_reasons"] = {
        "1": {
            "target": private_target,
            "code": "evidence",
            "text": "비공개 표 근거",
            "source_ids": ["private:test"],
            "source_type": "SYSTEM_RECORD",
            "source_owner": private_owner,
            "link_id": "",
            "contradiction_key": "",
            "created_index": -1
        }
    }
    private_reason._record_verdict_residue(private_target)
    check(private_reason.verdict_residue(1).is_empty(), "private ballot reason alone creates no NPC-facing residue")

    # Once a fact was genuinely public, it remains public provenance on later
    # ballot Days. A publication recorded only after that ballot Day must not
    # retroactively legitimize the old reason.
    var historical_public := _session(12277)
    var historical_log: Array = historical_public.stage_state().get("public_log", [])
    historical_log.append({"day": 1, "fact": "public:old", "speaker": "noa"})
    historical_log.append({"day": 3, "fact": "public:future", "speaker": "noa"})
    historical_public.stage_state()["public_log"] = historical_log
    check(historical_public._verdict_reason_source_was_public("public:old", 2),
        "earlier-Day public provenance remains eligible on a later ballot Day")
    check(not historical_public._verdict_reason_source_was_public("public:future", 2),
        "later publication does not retroactively make an earlier ballot reason public")

    # Public conflict provenance is Day-scoped even though the retained
    # public_contradiction_keys set is stage-wide. Yesterday's identical key
    # must not make today's distinct conflict visible to NPCs.
    var conflict_scope := _session(12278, "GLASS_GARDEN")
    var conflict_ids := conflict_scope.living_ids()
    var conflict_target := str(conflict_ids[0])
    var conflict_other := str(conflict_ids[1])
    var conflict_key := "claim:%s:%s" % [conflict_target, conflict_other]
    var conflict_detail := "%s|wa %s의 진술은 동시에 맞을 수 없다." % [conflict_scope.name_of(conflict_target), conflict_scope.name_of(conflict_other)]
    conflict_scope.day = 1
    conflict_scope._mark_public_conflict(conflict_key, [conflict_target, conflict_other], conflict_detail)
    var current_reason := {
        "code": "conflict", "target": conflict_target, "text": conflict_scope._josa_inline(conflict_detail),
        "source_ids": [], "source_type": "CONTRADICTION", "source_owner": "",
        "link_id": "", "contradiction_key": conflict_key, "created_index": -1, "public": true
    }
    check(conflict_scope._verdict_reason_is_public(current_reason, 1),
        "same-Day public conflict is valid ballot provenance")
    check(not conflict_scope._verdict_reason_is_public(current_reason, 2),
        "earlier public conflict key does not leak publicity into the next Day")

    # 1.2.2 Snapshot v4 stored public conflict reasons with a synthetic
    # target|detail key and no public/ballot_reason_public flag. Recover public
    # provenance from the dated manual contradiction record, not from text
    # alone or the stage-wide key set.
    var legacy_public := _session(12279, "GLASS_GARDEN")
    var legacy_public_ids := legacy_public.living_ids()
    var legacy_public_target := str(legacy_public_ids[0])
    var legacy_public_other := str(legacy_public_ids[1])
    var legacy_actual_key := "claim:%s:%s" % [legacy_public_target, legacy_public_other]
    var legacy_detail_raw := "%s|wa %s의 진술은 동시에 맞을 수 없다." % [legacy_public.name_of(legacy_public_target), legacy_public.name_of(legacy_public_other)]
    legacy_public.day = 1
    legacy_public._mark_public_conflict(legacy_actual_key, [legacy_public_target, legacy_public_other], legacy_detail_raw)
    var legacy_detail := legacy_public._josa_inline(legacy_detail_raw)
    var legacy_reason := {
        "code": "conflict", "target": legacy_public_target, "text": legacy_detail,
        "source_ids": [], "source_type": "CONTRADICTION", "source_owner": "",
        "link_id": "", "contradiction_key": "%s|%s" % [legacy_public_target, legacy_detail],
        "created_index": -1
    }
    check(legacy_public._verdict_reason_is_public(legacy_reason, 1),
        "legacy 1.2.2 public conflict provenance is recovered from dated public records")
    check(not legacy_public._verdict_reason_is_public(legacy_reason, 2),
        "legacy conflict compatibility does not make future Days public")
    var legacy_public_residues: Dictionary = legacy_public.stage_state().get("verdict_residue", {})
    legacy_public_residues["1"] = {
        "day": 1, "pattern": "REASON_FOLLOWUP", "subject": legacy_public_target,
        "player_target": legacy_public_target, "commitment_type": "", "commitment_index": -2,
        "ballot_reason": legacy_reason.duplicate(true), "lead_npc": legacy_public_target
    }
    legacy_public.stage_state()["verdict_residue"] = legacy_public_residues
    legacy_public.day = 2
    legacy_public._install_day_packet(2)
    check(legacy_public._verdict_residue_reason_is_public(legacy_public.verdict_residue(1)),
        "legacy public conflict residue remains public after Snapshot v4 hydration")
    check(not legacy_public._crosscurrent_scene(2).is_empty(),
        "legacy public conflict may still produce its normal Crosscurrent continuation")

    # Legacy/in-flight snapshots that already contain such a residue are also
    # safe: the private owner is ignored, Crosscurrent falls back, and the
    # private reason text never appears in the one-person callback.
    var legacy_private := _session(12276)
    var legacy_ids := _pair(legacy_private)
    var legacy_owner := str(legacy_ids[0])
    var legacy_target := str(legacy_ids[1])
    var legacy_residues: Dictionary = legacy_private.stage_state().get("verdict_residue", {})
    legacy_residues["1"] = {
        "day": 1,
        "pattern": "FOLLOW_THROUGH",
        "subject": legacy_target,
        "player_target": legacy_target,
        "commitment_type": "accuse",
        "commitment_index": 2,
        "ballot_reason": {
            "target": legacy_target,
            "code": "evidence",
            "text": "비공개 표 근거",
            "source_ids": ["private:test"],
            "source_type": "SYSTEM_RECORD",
            "source_owner": legacy_owner,
            "link_id": "",
            "contradiction_key": "",
            "created_index": -1
        },
        "ballot_reason_public": false,
        "lead_npc": legacy_owner
    }
    legacy_private.stage_state()["verdict_residue"] = legacy_residues
    _day_two(legacy_private)
    var legacy_residue := legacy_private.verdict_residue(1)
    check(legacy_private._verdict_alive_lead(legacy_residue) == legacy_target, "private source owner is not promoted into NPC callback")
    check(legacy_private._crosscurrent_scene(2).is_empty(), "private provenance does not create a two-person Crosscurrent")
    var private_fallback := legacy_private._verdict_callback_scene(2)
    check(not private_fallback.is_empty(), "public commitment keeps the safe one-person fallback")
    check(str(private_fallback.get("speaker", "")) == legacy_target, "private-provenance fallback uses the public commitment subject")
    check(not JSON.stringify(private_fallback).contains("비공개 표 근거"), "private ballot reason text is absent from NPC-facing fallback")

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
    var old_lead_role: String = str(role_safe.crew[role_lead].role)
    var old_partner_role: String = str(role_safe.crew[role_partner].role)
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

    # Release metadata must match the 1.2.2 package shown by Windows.
    var export_cfg := FileAccess.get_file_as_string("res://export_presets.cfg")
    check(export_cfg.contains("application/file_version=\"1.2.3.0\""), "Windows file version is 1.2.3.0")
    check(export_cfg.contains("application/product_version=\"1.2.3.0\""), "Windows product version is 1.2.3.0")
    check(export_cfg.contains("application/file_description=\"ASTRA — CLEAR CURRENT\""), "Windows description names CLEAR CURRENT")
