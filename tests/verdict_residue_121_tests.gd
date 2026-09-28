extends SceneTree

# ASTRA 1.2.1 — WEIGHT OF WORDS
# Verdict residue must remember only player-visible commitments/reasons and
# change tomorrow's social context without touching truth, Day Packets or proof.
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
        print("ASTRA VERDICT RESIDUE 121 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA VERDICT RESIDUE 121 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _session(seed_value: int = 12101) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("DEAD_AIR", seed_value)
    s.begin_voyage({})
    return s

func _targets(s: AstraGameSession) -> Array:
    var ids: Array = s.living_ids()
    check(ids.size() >= 2, "test Stage has two living targets")
    return ids

func _reason(s: AstraGameSession, target: String, code: String = "instinct", text: String = "직감", created_index: int = -1, owner: String = "") -> void:
    var reasons: Dictionary = s.stage_state().get("ballot_reasons", {})
    reasons[str(s.day)] = {
        "target": target, "code": code, "text": text,
        "source_ids": ["fact:test"] if code != "instinct" else [],
        "source_type": "LINK" if code == "link" else "EVIDENCE",
        "source_owner": owner, "link_id": "test-link" if code == "link" else "",
        "contradiction_key": "test", "created_index": created_index
    }
    s.stage_state()["ballot_reasons"] = reasons

func _pattern(commitment: String, same_target: bool, evidence_after: bool = false) -> String:
    var s := _session(12200 + checks)
    var ids := _targets(s)
    var subject := str(ids[0])
    var other := str(ids[1])
    var vote_target := subject if same_target else other
    if commitment == "accuse":
        s.stage_state()["public_accusations"].append({"day":1,"speaker":"player","target":subject,"weight":1.0,"meeting_index":2})
    else:
        s.stage_state()["public_defenses"].append({"day":1,"speaker":"player","target":subject,"meeting_index":2})
    if evidence_after:
        var links: Array = s.stage_state().get("links", [])
        links.append({
            "day":1,"statement":"claim:" + subject,"evidence":"fact:test","second":"",
            "result":"CONTRADICTION","family":"test","targets":[subject],"why":"새 공개 근거",
            "meeting_index":5
        })
        s.stage_state()["links"] = links
        _reason(s, vote_target, "link", "새 공개 근거", 5, other)
    else:
        _reason(s, vote_target)
    s._record_verdict_residue(vote_target)
    return str(s.verdict_residue(1).get("pattern",""))

func run_audit() -> void:
    # Public commitment classification.
    check(_pattern("accuse", true) == "FOLLOW_THROUGH", "accuse X then vote X = FOLLOW_THROUGH")
    check(_pattern("defend", false) == "STOOD_BY", "defend X then vote Y = STOOD_BY")
    check(_pattern("defend", true) == "REVERSAL", "defend X then vote X = REVERSAL")
    check(_pattern("accuse", false) == "REVERSAL", "accuse X then vote Y = REVERSAL")
    check(_pattern("defend", true, true) == "EVIDENCE_DRIVEN_REVERSAL",
        "new public Link after defense distinguishes evidence-driven reversal")

    # Ballot reason provenance is machine-readable, saveable, and contains no
    # hidden role/truth fields.
    var p := _session(12301)
    var pids := _targets(p)
    var target := str(pids[0])
    var source_owner := str(pids[1])
    var provenance_links: Array = p.stage_state().get("links", [])
    provenance_links.append({
        "day":1,"statement":"claim:" + source_owner,"evidence":"claim:" + target,"second":"",
        "result":"CONTRADICTION","family":"route","targets":[target],"why":"동선이 맞지 않는다.",
        "meeting_index":7
    })
    p.stage_state()["links"] = provenance_links
    var options := p.ballot_reasons(target)
    var link_index := -1
    for i in range(options.size()):
        if str(options[i].get("code","")) == "link":
            link_index = i
            break
    check(link_index >= 0, "Link is offered as a ballot reason")
    if link_index >= 0:
        var option: Dictionary = options[link_index]
        check(Array(option.get("source_ids",[])).size() >= 2, "Link reason preserves source ids")
        check(str(option.get("source_type","")) == "LINK", "Link reason preserves source type")
        check(str(option.get("link_id","")) != "", "Link reason preserves link id")
        check(str(option.get("contradiction_key","")) == "route", "Link reason preserves contradiction key")
        check(p.set_ballot_reason(target, link_index), "selected Link reason is stored")
        var saved := p.ballot_reason(1)
        check(str(saved.get("target","")) == target, "stored reason preserves target")
        check(saved.has("source_ids") and saved.has("source_owner"), "stored reason preserves provenance")
        check(not saved.has("truth") and not saved.has("nulls") and not saved.has("role"),
            "stored reason contains no hidden truth/role fields")

    # Residue calculation is presentation/social state only.
    var fair := _session(12401)
    var fair_target := str(_targets(fair)[0])
    var truth_before := JSON.stringify(fair.truth)
    var packet_before := JSON.stringify(fair.current_packet())
    fair.stage_state()["public_accusations"].append({"day":1,"speaker":"player","target":fair_target,"weight":1.0,"meeting_index":1})
    _reason(fair, fair_target)
    fair._record_verdict_residue(fair_target)
    check(JSON.stringify(fair.truth) == truth_before, "verdict residue does not change truth/Null assignment")
    check(JSON.stringify(fair.current_packet()) == packet_before, "verdict residue does not change generated Day Packet")

    # One callback per Day, then a contextual conversation follow-up. Neither
    # path discloses a new evidence fragment.
    var next := _session(12501)
    var next_ids := _targets(next)
    var lead := str(next_ids[0])
    var voted := str(next_ids[1])
    _reason(next, voted, "evidence", "어제 확인한 기록", 4, lead)
    next._record_verdict_residue(voted)
    next.day = 2
    next._install_day_packet(2)
    var callback := next._verdict_callback_scene(2)
    check(not callback.is_empty(), "next Day receives one commitment callback")
    check(next._verdict_callback_scene(2).is_empty(), "callback is capped/deduplicated per Day")
    check(str(callback.get("speaker","")) == lead, "callback uses relevant living source/participant")
    var leads := next.talk_leads()
    check(leads.has(lead) and str(leads[lead]) == "어제 투표 근거", "relevant source becomes a next-Day talk lead")
    next.phase = "INTERROGATION"
    var opened := next.open_conversation(lead)
    check(bool(opened.get("ok",false)), "relevant source conversation opens")
    var followup := {}
    for option in next.question_options(lead):
        if str(option.get("intent","")) == "VERDICT":
            followup = option
            break
    check(not followup.is_empty(), "next-Day contextual verdict follow-up is available")
    if not followup.is_empty():
        var asked := next.ask(lead, "VERDICT", "1")
        check(bool(asked.get("ok",false)) and str(asked.get("intent","")) == "VERDICT",
            "verdict follow-up is selectable")
        check(not asked.has("fragment") or Dictionary(asked.get("fragment",{})).is_empty(),
            "verdict follow-up creates no free evidence")

    # Save/load preserves callback dedup state without a save-schema bump.
    next.phase = "BRIEFING"
    var save_path := "user://verdict_residue_121.cfg"
    AstraGameSession.delete_snapshot(save_path)
    check(next.save_snapshot(save_path), "verdict residue snapshot saves")
    var loaded := AstraGameSession.new()
    check(loaded.load_snapshot(save_path), "verdict residue snapshot reloads")
    check(bool(Dictionary(loaded.stage_state().get("verdict_feedback_seen",{})).get("1",false)),
        "callback dedup survives save/load")
    check(loaded._verdict_callback_scene(2).is_empty(), "reload does not duplicate the callback")
    check(AstraGameSession.SNAPSHOT_VERSION == 4, "Snapshot remains v4")
    check(AstraMetaProgress.SAVE_VERSION == 12, "Meta save remains v12")
    AstraGameSession.delete_snapshot(save_path)

    # Same-seed agency probe: different known reasons change at least the
    # briefing callback and the follow-up wording while truth/packet stay fixed.
    var a := _session(12601)
    var b := _session(12601)
    var aid := _targets(a)
    var probe_lead := str(aid[0])
    var probe_target := str(aid[1])
    _reason(a, probe_target, "evidence", "기록 A", 3, probe_lead)
    _reason(b, probe_target, "evidence", "기록 B", 3, probe_lead)
    a._record_verdict_residue(probe_target)
    b._record_verdict_residue(probe_target)
    check(JSON.stringify(a.truth) == JSON.stringify(b.truth), "agency probe keeps same-seed truth identical")
    check(JSON.stringify(a.current_packet()) == JSON.stringify(b.current_packet()), "agency probe keeps base evidence identical")
    var callback_a := a._verdict_callback_text(a.verdict_residue(1))
    var callback_b := b._verdict_callback_text(b.verdict_residue(1))
    check(callback_a != callback_b, "different ballot reasons change next-Day briefing context")
    a.day = 2
    b.day = 2
    a._install_day_packet(2)
    b._install_day_packet(2)
    a.phase = "INTERROGATION"
    b.phase = "INTERROGATION"
    a.open_conversation(probe_lead)
    b.open_conversation(probe_lead)
    var ask_a := a.ask(probe_lead, "VERDICT", "1")
    var ask_b := b.ask(probe_lead, "VERDICT", "1")
    check(JSON.stringify(ask_a.get("lines",[])) != JSON.stringify(ask_b.get("lines",[])),
        "different ballot reasons change next-Day follow-up dialogue")
