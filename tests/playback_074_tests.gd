extends SceneTree
# ASTRA 0.7.4 PLAYBACK — completion regression.
# This suite stays on the existing scheduler/session/content APIs. It checks
# pacing, continuity, chapter transition, visible aftermath separation, save
# compatibility and the 0.7.1–0.7.3 visual memory points without exposing
# hidden truth, Null assignment, motive assignment or raw relationship values.

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    _run.call_deferred()

func _scene(id: String) -> Dictionary:
    for raw in AstraStorylets054.scenes():
        var scene: Dictionary = raw
        if str(scene.get("id","")) == id:
            return scene.duplicate(true)
    return {}

func _session(seed_value: int = 740074) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT", seed_value, "ANALYST", "STANDARD")
    s.begin_voyage()
    return s

func _record_strong_scene(s: AstraGameSession, scene: Dictionary) -> void:
    s.voyage["scene"] = {}
    s._voyage_scene(scene)
    s.voyage["scene"] = {}

func _make_noa_reachable(s: AstraGameSession) -> void:
    s.voyage["room"] = "archive"
    var met: Array = s.voyage.get("met",[])
    if "noa" not in met:
        met.append("noa")
    s.voyage["met"] = met
    var routine: Dictionary = s.voyage.get("routine_state",{})
    if routine.has("noa"):
        var entry: Dictionary = routine["noa"]
        entry["location"] = "archive"
        routine["noa"] = entry
        s.voyage["routine_state"] = routine

func _run() -> void:
    # P0 — MANDATORY / FOLLOWUP / FOCUS all receive the same one-action space.
    var mandatory := AstraVoyageContent.resolution_thread("LAST_LIGHT",[])
    var followup := _scene("054_dax_failed_model_3")
    var focus := _scene("054_sena_overprotection_2")
    check(not mandatory.is_empty(), "LAST_LIGHT mandatory resolution exists")
    check(not followup.is_empty(), "Daren/Jun follow-up exists")
    check(not focus.is_empty(), "Sena focus scene exists")

    for spec in [
        ["MANDATORY", mandatory],
        ["FOLLOWUP", followup],
        ["FOCUS", focus]
    ]:
        var s := _session(740074 + checks)
        _record_strong_scene(s, Dictionary(spec[1]))
        check(AstraStoryletScheduler.salience(Dictionary(spec[1])) == str(spec[0]), str(spec[0]) + " salience classified")
        check(s._recent_focus_needs_space(), str(spec[0]) + " creates breathing room")
        check(not s._maybe_trigger_incident(), str(spec[0]) + " blocks unrelated immediate incident")
        s.voyage["actions"] = int(s.voyage.get("actions",0)) + 2
        check(not s._recent_focus_needs_space(), str(spec[0]) + " breathing room expires")

    # Player agency is not part of the system-interruption guard.
    var talk_session := _session(740110)
    _make_noa_reachable(talk_session)
    _record_strong_scene(talk_session, focus)
    check(talk_session._recent_focus_needs_space(), "focus guard is active before direct conversation")
    check(talk_session.voyage_talk("noa"), "player-directed conversation remains available during guard")

    var topic_session := _session(740111)
    _make_noa_reachable(topic_session)
    _record_strong_scene(topic_session, focus)
    check(topic_session.voyage_talk("noa","work"), "explicit topic selection remains available during guard")

    # Continuations stay connected to their visible source family.
    var arc2 := _scene("054_dax_failed_model_2")
    var arc3 := _scene("054_dax_failed_model_3")
    var continuation_session := _session(740120)
    _record_strong_scene(continuation_session, arc2)
    check(AstraStoryletScheduler.is_continuation(arc3,continuation_session._focus_context()), "micro-arc stage 3 is recognized as continuation")
    var saturated_context := {
        "loop_focus_families":["a","b","c","d"],
        "loop_focus_events":[],
        "loop_focus_counts":{},
        "recent_focus_families":[],
        "speaker_exposure":{},
        "explicit_topic":false
    }
    check(AstraStoryletScheduler.weight(mandatory,{},[],"",{},saturated_context) > 0.0, "mandatory content cannot starve under focus budget")
    check(AstraStoryletScheduler.weight(focus,{},[],"",{},saturated_context) > 0.0, "new focus content remains soft-weighted, never hard-starved")

    # Choice -> queued consequence -> authored follow-up remains reachable.
    var consequence_session := _session(740130)
    consequence_session._voyage_scene(arc2)
    consequence_session.voyage["line"] = Array(arc2.get("lines",[])).size() - 1
    check(consequence_session.voyage_choose(0), "Daren/Jun handling choice resolves through normal choice pipeline")
    var queued := false
    for raw_event in consequence_session.voyage.get("consequence_queue",[]):
        if str(Dictionary(raw_event).get("followup_scene","")) == "054_dax_failed_model_3":
            queued = true
    check(queued, "Daren/Jun delayed callback is queued")
    consequence_session.voyage["actions"] = int(consequence_session.voyage.get("actions",0)) + 2
    check(consequence_session._deliver_due_consequence("DELAYED"), "delayed callback becomes due")
    check(str(consequence_session.voyage.get("scene",{}).get("id","")) == "054_dax_failed_model_3", "delayed callback reaches authored stage 3")

    # 0.7.3 HUMAN SIGNAL beats must remain authored, meaningful and connected.
    var authored := {}
    for raw in AstraStorylets054.scenes():
        var scene: Dictionary = raw
        authored[str(scene.get("id",""))] = scene
    var human_signal_ids := [
        "054_sena_overprotection_2",
        "054_noa_private_copy_2",
        "054_vale_vale_eli_direction",
        "054_dax_failed_model_3",
        "054_lyra_save_sample_2"
    ]
    for id in human_signal_ids:
        check(authored.has(id), id + " remains authored/reachable content")
        check(AstraArt.storylet_scene(id).begins_with("res://assets/art073/"), id + " keeps HUMAN SIGNAL art")
    check(str(Dictionary(authored["054_vale_vale_eli_direction"]).get("target","")) == "eli", "Soren/Lucan visual keeps Lucan target")
    for id in ["054_sena_overprotection_2","054_noa_private_copy_2","054_lyra_save_sample_2"]:
        var choices: Array = Dictionary(authored[id]).get("choices",[])
        var consequences := 0
        for choice in choices:
            consequences += Array(Dictionary(choice).get("consequences",[])).size()
        check(choices.size() >= 2 and consequences >= 2, id + " keeps player handling and aftermath")
    check(str(Dictionary(authored["054_dax_failed_model_3"]).get("chain_id","")) == "dax_failed_model", "Daren/Jun visual remains a micro-arc callback")

    # ACT I -> ACT II progression uses the existing campaign + slot memory path.
    var campaign: Array = AstraCaseCatalog.CAMPAIGN
    var last_light_index := campaign.find("LAST_LIGHT")
    check(last_light_index >= 0 and last_light_index + 1 < campaign.size() and str(campaign[last_light_index + 1]) == "SECOND_WATCH", "LAST_LIGHT leads directly to SECOND_WATCH")
    check(str(campaign.back()) == "THRESHOLD", "THRESHOLD remains ACT II endpoint")
    var meta := AstraMetaProgress.new()
    meta.set_voyage_memory_for_slot(0,{
        "chapters":["CALIBRATION","DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
    })
    check(meta.recommended_case_id_for_slot(0) == "SECOND_WATCH", "slot progression recommends SECOND_WATCH after LAST_LIGHT")
    meta.set_voyage_memory_for_slot(0,{
        "chapters":["CALIBRATION","DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT",
            "SECOND_WATCH","BORROWED_DAYS","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY"]
    })
    check(meta.recommended_case_id_for_slot(0) == "THRESHOLD", "slot progression reaches THRESHOLD")

    for id in ["LAST_LIGHT","SECOND_WATCH","THRESHOLD"]:
        check(not AstraVoyageContent.resolution_thread(id,[]).is_empty(), id + " resolution is reachable")
        check(not AstraVoyageContent.hook_thread(id).is_empty(), id + " next-question hook is reachable")

    # ACT II used to fall back to CALIBRATION's bandage reset. Every chapter now
    # leaves its own visible residue instead of replaying the tutorial framing.
    var calibration_frame := AstraVoyageContent.reset_framing("CALIBRATION")
    var act2_titles: Array = []
    for id in ["SECOND_WATCH","BORROWED_DAYS","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY","THRESHOLD"]:
        var frame := AstraVoyageContent.reset_framing(id)
        check(str(frame.get("title","")) != "" and str(frame.get("detail","")) != "", id + " has authored reset residue")
        check(frame != calibration_frame, id + " does not fall back to CALIBRATION framing")
        act2_titles.append(str(frame.get("title","")))
    var unique_titles := {}
    for title in act2_titles:
        unique_titles[str(title)] = true
    check(unique_titles.size() == act2_titles.size(), "ACT II reset residues are chapter-distinct")

    # Night and briefing have different jobs: immediate consequence vs durable
    # social interpretation. The same feedback must not be repeated on both.
    var feedback_session := _session(740140)
    var d := feedback_session.day
    feedback_session.voyage["consequence_history"] = [{
        "applied_day":d,"visible_feedback":true,"note":"후속 행동이 남았다.","who":"noa"
    }]
    feedback_session.voyage["relationship_feedback"] = [{
        "day":d,"a":"noa","b":"dax","axis":"trust","direction":"UP","magnitude":0.08,"visible":true,"authored_social":true
    }]
    feedback_session.voyage["opinion_changes"] = [{
        "day":d,"actor":"noa","target":"dax","visible":true,"reason_tag":"new_evidence"
    }]
    var night := feedback_session.night_feedback_summary()
    var briefing := feedback_session.briefing_social_summary(d)
    check(Array(night.get("consequences",[])).size() == 1, "Night keeps immediate consequence")
    check(Array(night.get("relationship_changes",[])).is_empty() and Array(night.get("opinion_changes",[])).is_empty(), "Night does not duplicate durable social interpretation")
    check(Array(briefing.get("consequences",[])).is_empty(), "Briefing does not repeat Night consequence")
    check(Array(briefing.get("relationship_changes",[])).size() >= 1 and Array(briefing.get("opinion_changes",[])).size() >= 1, "Briefing carries durable social change")

    # Selector input remains player-safe and save v11 stays compatible.
    var safe_session := _session(740150)
    var ctx := safe_session._focus_context()
    check(not ctx.has("truth") and not ctx.has("nulls") and not ctx.has("motives") and not ctx.has("relationships"), "selector context remains player-safe")
    check(AstraMetaProgress.SAVE_VERSION == 11, "save schema remains v11")
    var legacy_meta := AstraMetaProgress.new()
    legacy_meta.voyage_memory = {"chapters":["CALIBRATION","DEAD_AIR"],"seen_ever":{"legacy_scene":1}}
    check(Array(legacy_meta.voyage_memory_for_slot(0).get("chapters",[])).has("DEAD_AIR"), "legacy single-slot voyage memory hydrates into slot 0")
    check(legacy_meta.voyage_memory_for_slot(1).is_empty(), "legacy voyage memory does not leak into another slot")

    # Character exposure stays broad; Mira remains an anchor but no authored
    # micro-arc character disappears from the scheduler pool.
    var counts := AstraStorylets054.speaker_counts()
    for who in ["mira","rho","dax","noa","sena","vale","eli","lyra"]:
        check(int(counts.get(who,0)) > 0, who + " retains authored 0.5.4+ exposure")

    # Existing visual passes remain intact.
    for case_id in ["CALIBRATION","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]:
        check(AstraArt.story_scene(case_id).begins_with("res://assets/art072/"), case_id + " keeps ACT I art")
    for case_id in ["SECOND_WATCH","BLIND_DECK","THREE_MINUTES_DARK","CONTINUITY","THRESHOLD"]:
        check(AstraArt.story_scene(case_id).begins_with("res://assets/art071/"), case_id + " keeps ACT II art")

    # FIRST IMPRESSION remains slot-scoped and independent of scene art.
    var glimpse_meta := AstraMetaProgress.new()
    check(not glimpse_meta.has_glimpsed(0,"noa"), "FIRST IMPRESSION starts unseen")
    glimpse_meta.mark_glimpsed(0,"noa")
    check(glimpse_meta.has_glimpsed(0,"noa"), "FIRST IMPRESSION still records independently")

    # No placeholder-style dynamic Korean particles are introduced by PLAYBACK.
    check(not AstraJosa.eun("노아").contains("은(는)"), "AstraJosa dynamic particle path remains active")

    if failures.is_empty():
        print("ASTRA 0.7.4 PLAYBACK TESTS OK · %d checks" % checks)
        quit(0)
    quit(1)
