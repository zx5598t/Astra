class_name AstraGameSession
extends RefCounted

# Single authoritative game model for one case.
# UI reads state and calls the public methods; it never edits state directly.
#
# Day loop: BRIEFING -> INVESTIGATION -> INTERROGATION -> MEETING -> VOTE -> NIGHT
# The case ends when both Nulls are isolated (WIN), when living Nulls reach
# parity with living crew (LOSE), or after the vote of the last day (TIMEOUT).

signal changed
signal phase_changed(phase: String)
signal notice(kind: String, payload: Dictionary)

const PHASES := ["EXPLORE", "BRIEFING", "INVESTIGATION", "INTERROGATION", "MEETING", "VOTE", "NIGHT", "RESULT"]
const PHASE_LABELS := {
    "EXPLORE": "선내 탐색",
    "BRIEFING": "브리핑", "INVESTIGATION": "현장 조사", "INTERROGATION": "동료 대화",
    "MEETING": "공개 회의", "VOTE": "격리 투표", "NIGHT": "밤", "RESULT": "항해 기록"
}
const MAX_DAYS := 4
const BASE_INVESTIGATION_AP := 3
const BASE_TALK_AP := 3
const MEETING_ACTIONS := 2
const PLAYER_VOTE_WEIGHT := 1
const CONFIDE_TRUST := 0.6
const THEORY_DAY_FACTORS := [1.0, 1.0, 0.92, 0.84, 0.76]
const VOTE_NOISE := 0.04
const SNAPSHOT_PATH := "user://astra_session.cfg"
const SNAPSHOT_VERSION := 3
# 0.3.1 wrote version 1. It is still readable; the fields it never had are
# filled from the case template on load.
const SUPPORTED_SNAPSHOT_VERSIONS := [1, 2, 3]
const FIELDS_ADDED_IN_040 := [
    "roster", "null_count", "max_days", "difficulty",
    "claim_ledger", "retractions", "dialogue_recent", "social_beats", "player_claims"
]
const SNAPSHOT_FIELDS := [
    "voyage",
    "case_id", "seed_value", "protocol", "roster", "null_count", "max_days", "difficulty",
    "claim_ledger", "retractions", "dialogue_recent", "social_beats", "player_claims", "truth", "clues", "day", "phase",
    "investigation_ap", "talk_ap", "meeting_actions_left", "selected_id", "marks",
    "known_claims", "public_claims", "manual_contradictions", "contradictions",
    "public_contradiction_keys", "transcripts", "meeting_feed", "journal", "isolations",
    "casualties", "morning_report", "pending_event", "events_seen", "theories", "vote_cast",
    "last_vote", "night_done", "night_plan", "night_result", "outcome", "stats", "flags",
    "disputes_done", "meeting_pushers", "accused_today", "final_report", "_found_counter"
]
const CREW_SNAPSHOT_FIELDS := [
    "role", "status", "trust", "stress", "suspicion", "affinity", "expression",
    "secret_revealed", "slipped", "audited", "questions_asked", "memories"
]

const PROTOCOLS := {
    "ANALYST": {"name": "분석관", "summary": "현장 흔적을 더 오래 조사한다", "detail": "흔적을 더 많이 모아 교집합으로 범인을 좁히는 플레이."},
    "EMPATH": {"name": "공감관", "summary": "대화를 이어 가고 미묘한 반응을 읽는다", "detail": "대화와 신뢰로 숨긴 사정과 실언을 끌어내는 플레이."},
    "AUDITOR": {"name": "감사관", "summary": "검시 기록으로 시작하고 격리자를 감사한다", "detail": "확정된 정보로 오판을 빠르게 바로잡는 플레이."}
}

const QUESTION_TEXT := {
    "ALIBI": "사건 시각에 어디 있었습니까? 누구와 있었죠?",
    "EVIDENCE": "이 기록을 보세요.",
    "CONTRADICTION": "진술과 기록이 맞지 않습니다. 설명해 주시죠.",
    "SUSPECT": "지금 누가 가장 의심스럽습니까?",
    "REASSURE": "괜찮습니다. 당신을 몰아세우려는 게 아닙니다. 천천히 말해도 됩니다.",
    "PRESSURE": "시간이 없습니다. 숨기는 게 있다면 지금 말하세요.",
    "CONFIDE": "여기서 한 말은 공개하지 않겠습니다. 솔직한 판단을 들려주세요.",
    # 0.4.0. ALIBI used to be the only question a player could usefully ask
    # before they had any evidence, so the first conversation with all eight
    # people was the same sentence eight times.
    "WITNESS": "그 시간에 누구를 봤습니까?",
    "TIMELINE": "그 직전과 직후에는 무엇을 하고 있었죠?",
    "TRUST": "제가 왜 당신 말을 믿어야 하죠?"
}

# Intent -> the dialogue key that answers it, for the questions added in 0.4.0.
const INTENT_LINE_KEY := {
    "WITNESS": "ask_witness",
    "TIMELINE": "ask_timeline",
    "TRUST": "ask_trust"
}

const ISOLATED_LINES := {
    "mira": "…알겠어요. 제 기록이 끝까지 도움이 되길 바라요.",
    "rho": "공구는 문 앞에 둘게. 펌프 소리 달라지면 바로 멈춰.",
    "eli": "항로 사본은 남겼어. 좌표를 다시 확인해.",
    "sena": "알았어. 문은 닫을게. 밖에 있는 사람들 잘 봐 줘.",
    "vale": "탐사요원님… 이게 정말 맞는 선택이길 바라요.",
    "noa": "마지막 기록이에요. ‘나는 끝까지 말을 바꾸지 않았다.’",
    "lyra": "괜찮아요… 다들, 서로를 너무 미워하지는 마요.",
    "dax": "내 판단도 틀릴 수 있어. 그러니까 기록은 지우지 마."
}

var voyage: Dictionary = {}
var case_id: String = ""
var case_data: Dictionary = {}
var seed_value: int = 0
var protocol: String = "ANALYST"
var rng := RandomNumberGenerator.new()
var truth: Dictionary = {}
var crew: Dictionary = {}
var clues: Array = []

# 0.4.0 — roster & difficulty
var roster: Array = []
var null_count: int = 2
var max_days: int = MAX_DAYS
var difficulty: String = "STANDARD"

# Unlocked feature ids, handed in by the app. Empty means "no gating", which is
# what the automated suites want; the running game always passes a real list.
var features: Array = []

# 0.4.0 — social deduction record
var claim_ledger: Array = []
var retractions: Array = []
var dialogue_recent: Array = []
var social_beats: Array = []
var player_claims: Array = []

var day: int = 1
var phase: String = "BRIEFING"
var investigation_ap: int = 0
var talk_ap: int = 0
var meeting_actions_left: int = 0
var selected_id: String = ""
var marks: Dictionary = {}

var known_claims: Dictionary = {}
var public_claims: Dictionary = {}
var manual_contradictions: Array = []
var contradictions: Array = []
var public_contradiction_keys: Dictionary = {}
var transcripts: Dictionary = {}
var meeting_feed: Array = []
var journal: Array = []
var isolations: Array = []
var casualties: Array = []
var morning_report: Array = []
var pending_event: Dictionary = {}
var events_seen: Dictionary = {}
var theories: Array = []
var vote_cast: bool = false
var last_vote: Dictionary = {}
var night_done: bool = false
var night_plan: Dictionary = {}
var night_result: Dictionary = {}
var outcome: String = ""
var stats: Dictionary = {}
var flags: Dictionary = {}
var disputes_done: Dictionary = {}
var meeting_pushers: Dictionary = {}
var accused_today: Dictionary = {}
var final_report: Dictionary = {}
var _found_counter: int = 0

# ---------------------------------------------------------------- setup

func setup(case_id_in: String, seed_in: int, protocol_in: String = "ANALYST", difficulty_in: String = "STANDARD", history: Array = []) -> void:
    voyage.clear()
    case_id = case_id_in if AstraCaseCatalog.has_case(case_id_in) else "DEAD_AIR"
    seed_value = seed_in
    case_data = AstraCaseCatalog.resolve(case_id, seed_in)
    protocol = protocol_in if PROTOCOLS.has(protocol_in) else "ANALYST"
    difficulty = difficulty_in if AstraDifficulty.has_mode(difficulty_in) else "STANDARD"
    roster = AstraCaseCatalog.roster(case_data)
    null_count = AstraCaseCatalog.null_count(case_data)
    max_days = AstraCaseCatalog.max_days(case_data)
    rng.seed = seed_in * 7919 + 17
    # `history` is the archive's record of who has recently been Null. The
    # generator uses it to keep the role from clustering on one face without
    # ever becoming a rotation the player can count.
    truth = AstraCaseGenerator.generate(case_id, seed_in, history, difficulty)
    clues = truth.get("clues", [])
    claim_ledger.clear()
    retractions.clear()
    dialogue_recent.clear()
    social_beats.clear()
    player_claims.clear()

    crew.clear()
    for npc_id in roster:
        var member := AstraCrewMember.new(npc_id)
        member.role = "NULL" if npc_id in truth.get("nulls", []) else "CREW"
        crew[npc_id] = member
    for a in roster:
        for b in roster:
            if a == b:
                continue
            var affinity := clampf(rng.randf_range(-0.2, 0.28) + AstraCrewCatalog.affinity_bias(a, b), -1.0, 1.0)
            crew[a].affinity[b] = affinity
            crew[a].suspicion[b] = clampf(0.24 + rng.randf_range(-0.09, 0.16) - affinity * 0.12, 0.0, 1.0)

    day = 1
    phase = "BRIEFING"
    investigation_ap = 0
    talk_ap = 0
    meeting_actions_left = 0
    selected_id = str(roster[0])
    marks.clear()
    known_claims.clear()
    public_claims.clear()
    manual_contradictions.clear()
    contradictions.clear()
    public_contradiction_keys.clear()
    transcripts.clear()
    meeting_feed.clear()
    journal.clear()
    isolations.clear()
    casualties.clear()
    morning_report.clear()
    pending_event.clear()
    events_seen.clear()
    theories.clear()
    vote_cast = false
    last_vote.clear()
    night_done = false
    night_plan.clear()
    night_result.clear()
    outcome = ""
    flags.clear()
    flags["contact_058"] = {"version":1,"day":AstraVoyageContent.campaign_day(case_id),"joined":roster.duplicate(),"arrivals":[],"introduced":[],"step":"awake","learning":{},"ballot":{"state":"unselected","target":""}}
    flags["knowledge_052"] = {"facts":{}, "propagation":[]}
    flags["decision_traces_052"] = []
    flags["vote_history_052"] = []
    disputes_done.clear()
    meeting_pushers.clear()
    accused_today.clear()
    final_report.clear()
    _found_counter = 0
    stats = {
        "clues_found": 0, "public_contradictions": 0, "slips": 0, "secrets": 0,
        "protects": 0, "destroyed": 0, "accusations": 0, "defenses": 0, "presented": 0
    }
    for npc_id in roster:
        transcripts[npc_id] = []

    if protocol == "EMPATH":
        for member in crew.values():
            member.adjust_trust(0.08)
    if protocol == "AUDITOR":
        for clue in clues:
            if str(clue.get("kind", "")) == "context":
                _discover(clue, false)
                break
    for member in crew.values():
        member.refresh_expression()

    _log("사건 파일 개봉 · %s %s" % [str(case_data.get("code", "")), str(case_data.get("title", ""))])
    _log("조사 방식 · %s — %s" % [protocol_name(), str(PROTOCOLS[protocol]["summary"])])
    changed.emit()

# Snapshots contain only whitelisted scalar/array/dictionary state, never Nodes
# or serialized objects. RNG state is preserved so resuming cannot reroll a vote.
func save_snapshot(path: String = SNAPSHOT_PATH) -> bool:
    if case_id == "" or phase == "RESULT":
        return false
    var cfg := ConfigFile.new()
    cfg.set_value("meta", "version", SNAPSHOT_VERSION)
    cfg.set_value("meta", "saved_at", Time.get_datetime_string_from_system())
    cfg.set_value("session", "rng_state", rng.state)
    for field in SNAPSHOT_FIELDS:
        cfg.set_value("session", field, get(field))
    for npc_id in roster:
        for field in CREW_SNAPSHOT_FIELDS:
            cfg.set_value("crew_" + npc_id, field, crew[npc_id].get(field))
    var temporary := path + ".tmp"
    if cfg.save(temporary) != OK:
        return false
    var absolute := ProjectSettings.globalize_path(path)
    if FileAccess.file_exists(path):
        if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
            return false
        if DirAccess.remove_absolute(absolute) != OK:
            return false
    return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) == OK

static func snapshot_info(path: String = SNAPSHOT_PATH) -> Dictionary:
    for candidate in [path, path + ".bak"]:
        var cfg := ConfigFile.new()
        if cfg.load(candidate) != OK or int(cfg.get_value("meta", "version", 0)) not in SUPPORTED_SNAPSHOT_VERSIONS:
            continue
        var saved_case := str(cfg.get_value("session", "case_id", ""))
        var saved_phase := str(cfg.get_value("session", "phase", ""))
        if not AstraCaseCatalog.has_case(saved_case) or saved_phase not in PHASES or saved_phase == "RESULT":
            continue
        return {"case_id": saved_case, "phase": saved_phase, "day": int(cfg.get_value("session", "day", 1)), "saved_at": str(cfg.get_value("meta", "saved_at", ""))}
    return {}

static func has_snapshot(path: String = SNAPSHOT_PATH) -> bool:
    return not snapshot_info(path).is_empty()

static func delete_snapshot(path: String = SNAPSHOT_PATH) -> void:
    for suffix in ["", ".bak", ".tmp"]:
        if FileAccess.file_exists(path + suffix):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func load_snapshot(path: String = SNAPSHOT_PATH) -> bool:
    for candidate in [path, path + ".bak"]:
        var cfg := ConfigFile.new()
        if cfg.load(candidate) != OK or not _valid_snapshot(cfg):
            continue
        for field in SNAPSHOT_FIELDS:
            if cfg.has_section_key("session", field):
                set(field, cfg.get_value("session", field))
        # Fields added in 0.4.0 are simply absent from a 0.3.1 save. Rather than
        # rejecting the file, fill them from the case template: a resumed 0.3.1
        # case is an eight-person, two-Null, four-day case on STANDARD, which is
        # exactly what those defaults describe (§47).
        case_data = AstraCaseCatalog.resolve_legacy(case_id, seed_value) if int(cfg.get_value("meta","version",1)) < 3 else AstraCaseCatalog.resolve(case_id,seed_value)
        if roster.is_empty():
            roster = AstraCrewCatalog.ORDER.duplicate() if int(cfg.get_value("meta", "version", 1)) == 1 else AstraCaseCatalog.roster(case_data)
        if null_count <= 0:
            null_count = AstraCaseCatalog.null_count(case_data)
        if max_days <= 0:
            max_days = AstraCaseCatalog.max_days(case_data)
        if not AstraDifficulty.has_mode(difficulty):
            difficulty = "STANDARD"
        truth["clues"] = clues
        crew.clear()
        for npc_id in roster:
            var member := AstraCrewMember.new(npc_id)
            for field in CREW_SNAPSHOT_FIELDS:
                if field == "memories":
                    member.memories.assign(cfg.get_value("crew_" + npc_id, field))
                else:
                    member.set(field, cfg.get_value("crew_" + npc_id, field))
            crew[npc_id] = member
        _hydrate_054_voyage_defaults()
        rng.seed = seed_value * 7919 + 17
        rng.state = int(cfg.get_value("session", "rng_state"))
        phase_changed.emit(phase)
        changed.emit()
        return true
    return false


func _hydrate_054_voyage_defaults() -> void:
    if voyage.is_empty():
        return
    if not voyage.has("loop_focus_families"): voyage["loop_focus_families"] = []
    if not voyage.has("loop_focus_events"): voyage["loop_focus_events"] = []
    if not voyage.has("loop_focus_counts"): voyage["loop_focus_counts"] = {}
    if not voyage.has("recent_focus_families"): voyage["recent_focus_families"] = []
    if not voyage.has("speaker_exposure"): voyage["speaker_exposure"] = {}
    if not voyage.has("routine_observed"): voyage["routine_observed"] = []
    if not voyage.has("routine_observations"): voyage["routine_observations"] = []
    if not voyage.has("micro_arc_state"): voyage["micro_arc_state"] = {}
    if not voyage.has("micro_arc_recent"): voyage["micro_arc_recent"] = []
    if not voyage.has("micro_arc_pity"): voyage["micro_arc_pity"] = {}
    if not voyage.has("consequence_queue"): voyage["consequence_queue"] = []
    if not voyage.has("consequence_history"): voyage["consequence_history"] = []
    if not voyage.has("consequence_stats"): voyage["consequence_stats"] = {"IMMEDIATE":0,"DELAYED":0,"NEXT_DAY":0,"NEXT_LOOP":0}
    if not voyage.has("relationship_feedback"): voyage["relationship_feedback"] = []
    if not voyage.has("codex_known"): voyage["codex_known"] = []
    if not voyage.has("codex_unlocks_pending"): voyage["codex_unlocks_pending"] = []
    if not voyage.has("pinned_question"): voyage["pinned_question"] = ""
    if not voyage.has("opinion_changes"): voyage["opinion_changes"] = []
    if not voyage.has("motives"): voyage["motives"] = {}
    if not voyage.has("motive_observations"): voyage["motive_observations"] = []
    if not voyage.has("incident_history"): voyage["incident_history"] = []
    if not voyage.has("active_incident"): voyage["active_incident"] = {}
    if not voyage.has("foreknowledge_used"): voyage["foreknowledge_used"] = []
    if not voyage.has("foreknowledge_reactions"): voyage["foreknowledge_reactions"] = []
    if not voyage.has("scene_seen_counts"): voyage["scene_seen_counts"] = voyage.get("seen_ever",{}).duplicate(true)
    if not voyage.has("momentum_state"): voyage["momentum_state"] = {"drought":0,"force_meaningful":false}
    if not voyage.has("delegation_history"): voyage["delegation_history"] = []
    if not voyage.has("delegation_used"): voyage["delegation_used"] = false
    if not voyage.has("cooperative_history"): voyage["cooperative_history"] = []
    if not voyage.has("information_sources"): voyage["information_sources"] = {}
    if not voyage.has("canon_post_arrival_seen"): voyage["canon_post_arrival_seen"] = []
    if Dictionary(voyage.get("motives",{})).is_empty():
        voyage["motives"] = AstraPersonalMotiveModel.assign(
            seed_value,int(voyage.get("loop",0)),case_id,roster,active_participants(),truth.get("nulls",[])
        )
    if not voyage.has("active_arcs"):
        voyage["active_arcs"] = AstraStorylets054.select_arcs(
            seed_value,int(voyage.get("loop",0)),case_id,roster,Array(voyage.get("micro_arc_recent",[])),3,
            voyage.get("micro_arc_pity",{})
        )
        voyage["micro_arc_pity"] = AstraStorylets054.update_arc_pity(
            voyage.get("micro_arc_pity",{}),roster,voyage.get("active_arcs",[])
        )
    if not voyage.has("routine_state") or Dictionary(voyage.get("routine_state",{})).is_empty():
        voyage["routine_state"] = AstraCrewRoutineModel.build(
            seed_value,int(voyage.get("loop",0)),case_id,roster,active_participants(),truth.get("nulls",[])
        )
        if not voyage.has("activity_queue"): voyage["activity_queue"] = []
        _align_activity_queue_to_routine()

func _valid_snapshot(cfg: ConfigFile) -> bool:
    var version := int(cfg.get_value("meta", "version", 0))
    if version not in SUPPORTED_SNAPSHOT_VERSIONS:
        return false
    for field in SNAPSHOT_FIELDS:
        # Absent is fine only for fields 0.3.1 never wrote; present-but-wrong-type
        # is still a corrupt save and is still rejected.
        if not cfg.has_section_key("session", field):
            if field in FIELDS_ADDED_IN_040 or field == "voyage":
                continue
            return false
        if typeof(cfg.get_value("session", field)) != typeof(get(field)):
            return false
    var saved_case := str(cfg.get_value("session", "case_id"))
    var saved_phase := str(cfg.get_value("session", "phase"))
    if not AstraCaseCatalog.has_case(saved_case) or saved_phase not in PHASES or saved_phase == "RESULT":
        return false
    if str(cfg.get_value("session", "protocol")) not in PROTOCOLS or int(cfg.get_value("session", "day")) not in range(1, MAX_DAYS + 1):
        return false
    if not cfg.has_section_key("session", "rng_state") or typeof(cfg.get_value("session", "rng_state")) != TYPE_INT:
        return false
    if saved_phase == "EXPLORE":
        var saved_voyage: Dictionary = cfg.get_value("session","voyage",{})
        for key in ["room","loop","actions","line","goal_done","scene","facts","notes","met","visits","recent","seen","bonds","echo","memories","past","choices","deferred","inventory","used_items","inspected","companion"]:
            if not saved_voyage.has(key): return false
        if not saved_voyage["scene"] is Dictionary or not saved_voyage["met"] is Array: return false
        if not AstraVoyageContent.ROOMS.has(str(saved_voyage["room"])): return false
    var saved_truth: Dictionary = cfg.get_value("session", "truth")
    for required in ["nulls", "claims", "positions", "null_ops", "trace_pairs"]:
        if not saved_truth.has(required):
            return false
    var saved_case_data := AstraCaseCatalog.get_case(saved_case)
    var expected_nulls := int(cfg.get_value("session", "null_count", 2))
    if not saved_truth["nulls"] is Array or saved_truth["nulls"].size() != expected_nulls:
        return false
    for required in ["claims", "positions", "null_ops", "trace_pairs"]:
        if not saved_truth[required] is Dictionary:
            return false
    # The roster to check against comes from the file when it has one and from
    # the case template otherwise; `self.roster` is still empty at this point.
    var saved_roster: Array = cfg.get_value("session", "roster", [])
    if saved_roster.is_empty():
        saved_roster = AstraCrewCatalog.ORDER.duplicate() if version == 1 else AstraCaseCatalog.roster(saved_case_data)
    for npc_id in saved_roster:
        if not saved_truth["claims"].get(npc_id, null) is Dictionary or not saved_truth["positions"].has(npc_id):
            return false
        var member := AstraCrewMember.new(npc_id)
        for field in CREW_SNAPSHOT_FIELDS:
            if not cfg.has_section_key("crew_" + npc_id, field) or typeof(cfg.get_value("crew_" + npc_id, field)) != typeof(member.get(field)):
                return false
    for clue in cfg.get_value("session", "clues"):
        if not clue is Dictionary or not clue.has("id") or not clue.has("kind"):
            return false
    return true

# ---------------------------------------------------------------- lookups

func protocol_name() -> String:
    return str(PROTOCOLS.get(protocol, {}).get("name", protocol))

func npc_knows_fact(npc_id: String, fact_id: String) -> bool:
    return AstraKnowledgeModel.knows(flags, npc_id, fact_id)

func knowledge_debug_trace(npc_id: String, fact_id: String) -> String:
    return AstraKnowledgeModel.trace_text(flags, npc_id, fact_id)

func decision_trace_for(npc_id: String) -> Array:
    return AstraDecisionModel.recent(flags, npc_id)

func npc(npc_id: String) -> AstraCrewMember:
    return crew.get(npc_id, null)

func name_of(npc_id: String) -> String:
    return AstraCrewCatalog.display_name(npc_id)

func names_of(ids: Array) -> String:
    var names: Array = []
    for npc_id in ids:
        names.append(name_of(str(npc_id)))
    return ", ".join(PackedStringArray(names))

func room_name(room_id: String) -> String:
    return AstraCaseCatalog.room_name(case_data, room_id)

func op_data(op_id: String) -> Dictionary:
    for op in case_data.get("ops", []):
        if str(op.get("id", "")) == op_id:
            return op
    return {}

func op_name(op_id: String) -> String:
    return str(op_data(op_id).get("name", op_id))

func victim_name() -> String:
    return str(case_data.get("subject", ""))

func window_text() -> String:
    return AstraCaseCatalog.window_text(case_data)

func phase_label(phase_id: String = "") -> String:
    return str(PHASE_LABELS.get(phase_id if phase_id != "" else phase, phase))

func is_alive(npc_id: String) -> bool:
    var member := npc(npc_id)
    return member != null and member.is_alive()

func living_ids() -> Array:
    return active_participants()

# 0.5.0 invariant API. "roster" is the awakened roster for this chapter, so an
# active participant must exist in it and still be ACTIVE. All systems that can
# speak, vote, be targeted, or be selected build on this one definition.
func active_participants() -> Array:
    var result: Array = []
    for npc_id in roster:
        if crew.has(npc_id) and crew[npc_id].status == AstraCrewMember.STATUS_ACTIVE:
            result.append(npc_id)
    return result

func eligible_voters() -> Array:
    return active_participants()

func eligible_vote_targets() -> Array:
    return active_participants()

func can_vote_for(voter_id: String, target_id: String) -> bool:
    if voter_id == "" or target_id == "" or voter_id == target_id:
        return false
    return voter_id in eligible_voters() and target_id in eligible_vote_targets()

func _fallback_selected() -> void:
    if selected_id in active_participants():
        return
    var valid := active_participants()
    selected_id = str(valid[0]) if not valid.is_empty() else ""

func living_null_ids() -> Array:
    var result: Array = []
    for npc_id in living_ids():
        if crew[npc_id].is_null():
            result.append(npc_id)
    return result

func living_crew_ids() -> Array:
    var result: Array = []
    for npc_id in living_ids():
        if not crew[npc_id].is_null():
            result.append(npc_id)
    return result

func investigation_ap_max() -> int:
    var base := int(AstraCaseCatalog.ap_profile(case_id, {}).get("investigation", BASE_INVESTIGATION_AP))
    var advanced := case_id in ["ECHO_WARD", "SILENT_ORBIT", "RED_SHIFT", "LAST_LIGHT"]
    var mission_bonus := 1 if advanced and bool(flags.get("mission_investigation", false)) and day > int(flags.get("mission_day", 0)) else 0
    return base + (1 if advanced and protocol == "ANALYST" else 0) + mission_bonus

func talk_ap_max() -> int:
    var base := int(AstraCaseCatalog.ap_profile(case_id, {}).get("talk", BASE_TALK_AP))
    var advanced := case_id in ["ECHO_WARD", "SILENT_ORBIT", "RED_SHIFT", "LAST_LIGHT"]
    var value := base + (1 if advanced and int(flags.get("rested_day", 0)) == day else 0) + (1 if advanced and protocol == "EMPATH" else 0) + (1 if advanced and bool(flags.get("mission_talk", false)) else 0) + (int(AstraDifficulty.number(difficulty, "extra_talk_ap", 0.0)) if advanced else 0)
    # A wrongful isolation has a concrete next-day information cost: shaken
    # crewmates are less willing to spend time in formal questioning.
    if int(flags.get("restricted_info_until_day", 0)) == day:
        value -= 1
    return maxi(1, value)

func meeting_actions_max() -> int:
    var base := int(AstraCaseCatalog.ap_profile(case_id, {}).get("meeting", MEETING_ACTIONS))
    return base + (1 if bool(flags.get("mission_meeting", false)) else 0)

func story_dispatch() -> String:
    var dispatches: Array = case_data.get("dispatches", [])
    return str(dispatches[mini(day - 1, dispatches.size() - 1)]) if not dispatches.is_empty() else ""

# Only visible facts contribute to the live checklist. Hidden roles are never
# counted here, including when an unaudited suspect has been isolated.
func chapter_objective_spec() -> Dictionary:
    var target := int(AstraCaseCatalog.ap_profile(case_id, {}).get("investigation", BASE_INVESTIGATION_AP))
    var description := "사건의 핵심 기록을 확인하세요."
    match case_id:
        AstraCaseCatalog.CALIBRATION:
            target = 1
            description = "포드 전원 기록의 실행자 서명을 확인하세요."
        "DEAD_AIR":
            target = 1
            description = "통신실의 수동 종료 기록을 확인하세요."
        "GLASS_GARDEN":
            target = 2
            description = "보안 흔적과 수목 구역 기록을 두 번 확인하세요."
        "ECHO_WARD":
            target = 3
            description = "신호와 생체 기록을 겹쳐 볼 핵심 기록을 확인하세요."
        "SILENT_ORBIT":
            target = 3
            description = "항법 기록과 오래된 도착 기록을 대조할 단서를 확인하세요."
        "RED_SHIFT":
            target = 3
            description = "서로 충돌하는 기록 세 축을 확인하세요."
        "LAST_LIGHT":
            target = 3
            description = "마지막 항해 기록을 연결할 핵심 단서를 확인하세요."
    return {
        "id": "story_objective",
        "label": description,
        "description": description,
        "current": mini(found_clues().size(), target),
        "target": target,
        "complete": found_clues().size() >= target
    }

func objectives() -> Array:
    var challenge: Dictionary = case_data.get("challenge", {})
    var challenge_id := str(challenge.get("id", "records"))
    var progress := 0
    match challenge_id:
        "records", "traces":
            var kind := "op_record" if challenge_id == "records" else "trace"
            for clue in found_clues():
                if str(clue.get("kind", "")) == kind:
                    progress += 1
        "claims": progress = known_claims.size()
        "presented": progress = int(stats.get("presented", 0))
        "contradictions": progress = int(stats.get("public_contradictions", 0))
    var target := int(challenge.get("target", 2))
    return [
        chapter_objective_spec(),
        {"id": challenge_id, "label": str(challenge.get("label", "두 조작의 실행 로그 확보")), "current": mini(progress, target), "target": target, "complete": progress >= target},
        {"id": "mission", "label": str(case_data.get("mission", {}).get("title", "함선 복구 임무")), "current": 1 if bool(flags.get("mission_complete", false)) else 0, "target": 1, "complete": bool(flags.get("mission_complete", false))}
    ]

func mission_status() -> Dictionary:
    var mission: Dictionary = case_data.get("mission", {})
    if mission.is_empty():
        return {}
    var complete := bool(flags.get("mission_complete", false))
    var available := phase == "INVESTIGATION" and investigation_ap > 0 and outcome == "" and not complete
    if str(mission.get("effect", "")) == "recover" and _recoverable_clues().is_empty():
        available = false
    return {
        "title": str(mission.get("title", "")), "description": str(mission.get("description", "")),
        "room": str(mission.get("room", "")), "room_name": room_name(str(mission.get("room", ""))),
        "complete": complete, "available": available, "cost": 1,
        "action_label": "복구 완료" if complete else "임무 수행 · 조사 행동력 1",
        "reward": str(mission.get("reward", "")), "result": str(flags.get("mission_result", ""))
    }

func _recoverable_clues() -> Array:
    var destroyed: Array = []
    var available: Array = []
    for clue in clues:
        if not _is_searchable(clue) or bool(clue.get("found", false)):
            continue
        if bool(clue.get("destroyed", false)):
            destroyed.append(clue)
        else:
            available.append(clue)
    return destroyed + available

func perform_mission() -> Dictionary:
    if not bool(mission_status().get("available", false)):
        return {"ok": false, "reason": "현장 조사 중 행동력이 남아 있을 때 한 번 수행할 수 있습니다."}
    var mission: Dictionary = case_data.get("mission", {})
    investigation_ap -= 1
    flags["mission_complete"] = true
    flags["mission_day"] = day
    var effect := str(mission.get("effect", ""))
    flags["mission_" + effect] = true
    var result := str(mission.get("reward", ""))
    if effect == "recover":
        var recoverable := _recoverable_clues()
        var clue: Dictionary = recoverable[0]
        clue["destroyed"] = false
        result = "복원·확보한 단서: %s" % str(clue.get("title", ""))
        _discover(clue, true)
    flags["mission_result"] = result
    _log("함선 복구 · %s — %s" % [str(mission.get("title", "")), result])
    changed.emit()
    return {"ok": true, "title": str(mission.get("title", "")), "text": result}

func clue_by_id(clue_id: String) -> Dictionary:
    for clue in clues:
        if str(clue.get("id", "")) == clue_id:
            return clue
    return {}

func found_clues() -> Array:
    var result: Array = []
    for clue in clues:
        if bool(clue.get("found", false)):
            result.append(clue)
    result.sort_custom(func(a, b): return int(a.get("found_order", 0)) < int(b.get("found_order", 0)))
    return result

func room_ids() -> Array:
    var result: Array = []
    for room in case_data.get("rooms", []):
        result.append(str(room.get("id", "")))
    return result

func room_status(room_id: String) -> Dictionary:
    var remaining := 0
    var destroyed := 0
    var found := 0
    for clue in clues:
        if str(clue.get("room", "")) != room_id or not _is_searchable(clue):
            continue
        if bool(clue.get("found", false)):
            found += 1
        elif bool(clue.get("destroyed", false)):
            destroyed += 1
        else:
            remaining += 1
    return {"remaining": remaining, "destroyed": destroyed, "found": found}

func current_claim(npc_id: String) -> Dictionary:
    var member := npc(npc_id)
    if member == null:
        return {}
    if member.secret_revealed:
        return {"position": str(truth["positions"].get(npc_id, "")), "companions": [], "lie": false}
    return truth["claims"].get(npc_id, {})

func crowd_suspicion(target_id: String) -> float:
    var total := 0.0
    var count := 0
    for npc_id in living_ids():
        if npc_id == target_id or crew[npc_id].is_null():
            continue
        total += crew[npc_id].get_suspicion(target_id)
        count += 1
    return total / float(count) if count > 0 else 0.0

func set_mark(npc_id: String, mark: String) -> void:
    if not crew.has(npc_id):
        return
    if mark in ["null", "clear", "unsure"]:
        marks[npc_id] = mark
    else:
        marks.erase(npc_id)
    changed.emit()

func cycle_mark(npc_id: String) -> String:
    var current := str(marks.get(npc_id, ""))
    var next := ""
    match current:
        "": next = "null"
        "null": next = "clear"
        "clear": next = "unsure"
        _: next = ""
    set_mark(npc_id, next)
    return next

func marked_suspects() -> Array:
    var result: Array = []
    for npc_id in roster:
        if str(marks.get(npc_id, "")) == "null":
            result.append(npc_id)
    return result

func select(npc_id: String) -> void:
    if npc_id in active_participants():
        selected_id = npc_id
        changed.emit()
    else:
        _fallback_selected()

# ---------------------------------------------------------------- phase flow

# In the tutorial the "next" button is not an escape hatch. A new player who
# taps past the investigation arrives at the meeting with nothing to say and no
# idea why, and blames the game rather than the click. During calibration the
# phase must actually be finished — every searchable point examined, every
# statement heard — before the button unlocks.
func tutorial_blocked_reason() -> String:
    if not tutorial_active():
        return ""
    match phase:
        "INVESTIGATION":
            var left := 0
            for room_id in room_ids():
                left += int(room_status(room_id).get("remaining", 0))
            if left > 0 and investigation_ap > 0:
                return "아직 살펴보지 않은 조사 지점이 %d곳 남았습니다." % left
        "INTERROGATION":
            if not pending_event.is_empty():
                return "%s|i 먼저 할 말이 있습니다." % name_of(str(pending_event.get("npc_id", "")))
            var required: Array = ["mira"] if case_id == AstraCaseCatalog.CALIBRATION else living_ids()
            var unheard: Array = []
            for npc_id in required:
                if npc_id in active_participants() and not known_claims.has(npc_id):
                    unheard.append(name_of(npc_id))
            if not unheard.is_empty() and talk_ap > 0:
                return "먼저 %s의 말을 확인하세요." % ", ".join(PackedStringArray(unheard))
    # The meeting is deliberately not gated. Speaking there can be the wrong
    # move, and a tutorial that forces the player to accuse somebody teaches the
    # opposite of what this game wants. Investigation and interrogation are
    # gated because skipping those leaves nothing to reason with at all.
    return ""

func _chapter_flow() -> Array:
    return AstraCaseCatalog.phase_flow(case_id)

func _next_story_phase() -> String:
    var flow := _chapter_flow()
    var index := flow.find(phase)
    if index < 0 or index + 1 >= flow.size():
        return ""
    return str(flow[index + 1])

func can_advance() -> bool:
    if tutorial_blocked_reason() != "":
        return false
    if outcome != "" and phase in ["VOTE", "NIGHT"]:
        return true
    match phase:
        "BRIEFING", "INVESTIGATION", "MEETING":
            return true
        "INTERROGATION":
            return pending_event.is_empty()
        "VOTE":
            return vote_cast
        "NIGHT":
            return night_done
    return false

func advance_label() -> String:
    if outcome != "" and phase in ["VOTE", "NIGHT"]:
        return "사건 결과 보기"
    var blocked := tutorial_blocked_reason()
    if blocked != "":
        return _josa_inline(blocked)
    var next := _next_story_phase()
    if phase == "BRIEFING": return "현장으로 이동"
    if phase == "INVESTIGATION": return "동료에게 확인하기"
    if phase == "INTERROGATION":
        if not pending_event.is_empty(): return "개인 면담에 먼저 답하세요"
        return "기록을 함께 확인하기" if next == "RESULT" else "공개 회의로 이동"
    if phase == "MEETING":
        return "사건 정리하기" if next == "RESULT" else "장기수면 격리 투표 시작"
    if phase == "VOTE": return "밤 행동 선택" if vote_cast else "장기수면 격리 대상을 먼저 선택하세요"
    if phase == "NIGHT": return "다음 날 아침으로" if night_done else "밤 행동을 먼저 고르세요"
    return ""

func advance() -> void:
    if not can_advance():
        return
    if outcome != "" and phase in ["VOTE", "NIGHT"]:
        _enter("RESULT")
        return
    var next := _next_story_phase()
    if next == "RESULT":
        # CALIBRATION/DEAD_AIR/GLASS_GARDEN are authored learning chapters.
        # They resolve when their taught systems are completed; no fake vote or
        # night screen is inserted merely to satisfy the old state machine.
        if outcome == "":
            outcome = "WIN"
            _log("사건 정리 · 이번 장의 확인을 마쳤다.")
        _enter("RESULT")
        return
    if phase == "NIGHT":
        _start_next_day()
        return
    if next != "":
        _enter(next)

func phase_hint() -> String:
    if phase == "VOTE" and vote_cast:
        return "투표가 끝났습니다. 결과를 확인하고 아래 버튼으로 이동하세요."
    if phase == "NIGHT" and night_done:
        return "밤이 지나갔습니다. 아침 보고를 확인하세요."
    if phase == "INTERROGATION" and not pending_event.is_empty():
        return AstraJosa.i(name_of(str(pending_event.get("npc_id","")))) + " 따로 이야기하고 싶어 합니다."
    if tutorial_active():
        # "practiced" means different things per phase: a first search, or a
        # first statement heard. Passing one flag for both made the interrogation
        # hint jump straight to its follow-up line.
        var practiced := bool(flags.get("tutorial_examined", false))
        if phase == "INTERROGATION":
            practiced = not known_claims.is_empty()
        var guide := AstraStory.calibration(phase, practiced) if AstraCaseCatalog.is_calibration(case_id) else AstraStory.tutorial(phase, practiced)
        if guide != "":return guide
    match phase:
        "BRIEFING": return "사건의 시각과 장소를 확인하세요. 사건 시간대는 %s입니다." % window_text() if day == 1 else "밤사이 보고가 도착했습니다. 누가 남았고 어떤 기록이 사라졌는지 확인하세요."
        "INVESTIGATION": return "장소와 조사 지점을 고르세요. 기록 시각을 사건 시간대와 대조하는 것이 중요합니다."
        "INTERROGATION": return "이름을 골라 진술을 듣고 확보한 증거와 비교하세요. 모든 거짓말이 범행을 뜻하지는 않습니다."
        "MEETING": return "공개된 말과 기록을 비교하세요. 단서나 나의 가설을 제시해 회의에 개입할 수 있습니다."
        "VOTE": return "한 명을 고른 뒤 투표하세요. 득표는 개표 후 공개됩니다. 동률이면 아무도 격리하지 않습니다."
        "NIGHT": return "밤에 할 수 있는 일은 하나입니다. 보호·감시·기록 백업·휴식 중 선택하세요."
        "RESULT": return "조사가 끝났습니다. 진실과 그날의 선택을 돌아보세요."
    return ""

func _enter(next_phase: String) -> void:
    phase = next_phase
    match phase:
        "INVESTIGATION":
            investigation_ap = investigation_ap_max()
        "INTERROGATION":
            talk_ap = talk_ap_max()
            _maybe_private_event()
        "MEETING":
            meeting_actions_left = meeting_actions_max()
            accused_today.clear()
            _open_meeting()
        "VOTE":
            vote_cast = false
            last_vote.clear()
        "NIGHT":
            night_done = false
            night_plan.clear()
            night_result.clear()
        "RESULT":
            _finalize()
    _log("— DAY %d · %s —" % [day, phase_label()])
    phase_changed.emit(phase)
    changed.emit()

func _start_next_day() -> void:
    # A surviving case that reaches its authored day limit must resolve instead
    # of rolling into an unbounded extra day. Vote-stage WIN/LOSE/TIMEOUT is
    # handled earlier; this covers the no-isolation path after the final night.
    if day >= max_days:
        if outcome == "":
            outcome = "TIMEOUT"
            _log("사건 판정 · TIMEOUT")
        _enter("RESULT")
        return
    day += 1
    _apply_next_day_consequences()
    flags.erase("patrol")
    flags.erase("calm")
    vote_cast = false
    night_done = false
    for npc_id in living_ids():
        crew[npc_id].adjust_stress(0.05)
        crew[npc_id].refresh_expression()
    phase = "BRIEFING"
    _log("— DAY %d · %s —" % [day, phase_label()])
    phase_changed.emit(phase)
    changed.emit()

# ---------------------------------------------------------------- investigation

func _is_searchable(clue: Dictionary) -> bool:
    return str(clue.get("kind", "")) in ["context", "op_record", "access_log", "trace"]

func search_room(room_id: String) -> Dictionary:
    if phase != "INVESTIGATION" or investigation_ap <= 0 or outcome != "":
        return {}
    var candidates: Array = []
    for clue in clues:
        if str(clue.get("room", "")) == room_id and _is_searchable(clue) and not bool(clue.get("found", false)) and not bool(clue.get("destroyed", false)):
            candidates.append(clue)
    if candidates.is_empty():
        return {}
    investigation_ap -= 1
    flags["tutorial_examined"] = true
    var clue: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
    _discover(clue, true)
    return clue

func _discover(clue: Dictionary, announce: bool) -> void:
    if bool(clue.get("found", false)):
        return
    clue["found"] = true
    clue["found_day"] = day
    _found_counter += 1
    clue["found_order"] = _found_counter
    stats["clues_found"] = int(stats.get("clues_found", 0)) + 1
    AstraKnowledgeModel.discover_player(flags, str(clue.get("id","")), day)
    var where := room_name(str(clue.get("room", ""))) if str(clue.get("room", "")) != "" else "진술"
    _log("단서 확보 · [%s] %s" % [where, str(clue.get("title", ""))])
    _recompute_contradictions()
    if announce:
        notice.emit("clue", {"clue": clue})
    changed.emit()

# ---------------------------------------------------------------- interrogation

func question_options(npc_id: String) -> Array:
    var member := npc(npc_id)
    if member == null or not member.is_alive():
        return []
    var enabled := phase == "INTERROGATION" and talk_ap > 0 and pending_event.is_empty() and outcome == ""
    # Each option carries a `hint` saying what it gets you. 0.3.1 labelled the
    # buttons but never said what any of them was for, so a new player pressed
    # them in order and burned the budget finding out.
    var options: Array = []
    if not known_claims.has(npc_id):
        options.append({"intent": "ALIBI", "label": "그 시각, 어디에 있었나요?", "hint": "알리바이를 듣습니다. 출입 기록과 대조할 수 있습니다.", "enabled": enabled, "key": true})
    else:
        options.append({"intent": "ALIBI", "label": "진술을 다시 확인한다", "hint": "같은 질문을 다시 합니다. 말이 바뀌면 기록에 남습니다.", "enabled": enabled})
    options.append({"intent": "WITNESS", "label": "그때 누구를 봤나요?", "hint": "목격 확인", "enabled": enabled})
    if case_id in ["CALIBRATION", "DEAD_AIR"] and day == 1:
        if not found_clues().is_empty():
            options.append({"intent": "EVIDENCE", "label": "이 기록을 본 적 있나요?", "hint": "기록에 대한 반응 확인", "enabled": enabled})
        return options
    options.append({"intent": "TIMELINE", "label": "그 직전엔 무엇을 했죠?", "hint": "앞뒤 행적 확인", "enabled": enabled})
    if not found_clues().is_empty():
        options.append({"intent": "EVIDENCE", "label": "이 기록을 보여 준다", "hint": "기록에 대한 반응 확인", "enabled": enabled})
    if has_contradiction_on(npc_id):
        options.append({"intent": "CONTRADICTION", "label": "말이 달라진 부분을 짚는다", "hint": "모순 확인", "enabled": enabled, "key": true})
    if case_id == "GLASS_GARDEN" and day == 1:
        return options
    options.append({"intent": "SUSPECT", "label": "다른 사람에 대한 생각을 묻는다", "hint": "의심과 이유 확인", "enabled": enabled})
    options.append({"intent": "TRUST", "label": "왜 당신을 믿어야 하죠?", "hint": "스스로를 변호하게 합니다. 성격이 가장 잘 드러납니다.", "enabled": enabled})
    if member.stress >= 0.4 or member.trust < CONFIDE_TRUST:
        options.append({"intent": "REASSURE", "label": "서두르지 말고 기다려 준다", "hint": "신뢰가 오르고 긴장이 내려갑니다.", "enabled": enabled})
    elif not bool(flags.get("personal_%s_%d" % [npc_id, day], false)):
        options.append({"intent": "PERSONAL", "label": "지키고 싶은 것에 대해 묻는다", "hint": "사건과 무관한 개인적인 이야기를 듣습니다. 신뢰가 오릅니다.", "enabled": enabled})
    if known_claims.has(npc_id):
        options.append({"intent": "PRESSURE", "label": "사실만 말하라고 요구한다", "hint": "긴장이 오르고 신뢰가 떨어집니다. 실언을 유도할 수 있습니다.", "enabled": enabled})
    if member.trust >= CONFIDE_TRUST:
        options.append({"intent": "CONFIDE", "label": "둘만의 판단을 부탁한다", "hint": "신뢰가 높을 때만 가능합니다. 솔직한 의견을 듣습니다.", "enabled": enabled})
    return options

func ask(npc_id: String, intent: String, clue_id: String = "") -> Dictionary:
    var member := npc(npc_id)
    if member == null or not member.is_alive() or phase != "INTERROGATION" or talk_ap <= 0 or not pending_event.is_empty() or outcome != "":
        return {"ok": false}
    if intent == "EVIDENCE" and (clue_by_id(clue_id).is_empty() or not bool(clue_by_id(clue_id).get("found", false))):
        return {"ok": false}
    if intent == "CONTRADICTION" and not has_contradiction_on(npc_id):
        return {"ok": false}
    if intent == "CONFIDE" and member.trust < CONFIDE_TRUST:
        return {"ok": false}

    if intent not in QUESTION_TEXT and intent != "PERSONAL":
        return {"ok": false}
    if intent == "PERSONAL" and bool(flags.get("personal_%s_%d" % [npc_id, day], false)):
        return {"ok": false}
    talk_ap -= 1
    member.questions_asked += 1
    selected_id = npc_id
    var result := {"ok": true, "npc_id": npc_id, "intent": intent, "response_family": intent, "lines": []}
    var question := str(QUESTION_TEXT.get(intent, "이 배에서 당신이 지키고 싶은 것은 무엇인가요?"))
    if intent == "EVIDENCE":
        question = "이 기록을 보세요. ‘%s’" % str(clue_by_id(clue_id).get("title", ""))
    _transcript(npc_id, "player", question, intent)

    match intent:
        "PERSONAL":
            flags["personal_%s_%d" % [npc_id, day]] = true
            var line := AstraStory.personal(npc_id, seed_value + day)
            _transcript(npc_id, npc_id, line, intent)
            result["lines"].append({"speaker": npc_id, "text": line})
            member.adjust_trust(0.05)
            member.adjust_stress(-0.04)
        "ALIBI": _ask_alibi(member, result)
        "EVIDENCE":
            var evidence := clue_by_id(clue_id)
            result["clue_topic"] = _clue_topic(evidence)
            result["evidence_members"] = evidence.get("members", []).duplicate()
            _ask_evidence(member, evidence, result)
        "CONTRADICTION": _ask_contradiction(member, result)
        "SUSPECT": _ask_suspect(member, result, false)
        "REASSURE": _ask_reassure(member, result)
        "PRESSURE": _ask_pressure(member, result)
        "CONFIDE": _ask_suspect(member, result, true)
        "WITNESS", "TIMELINE", "TRUST": _ask_open(member, intent, result)

    member.refresh_expression()
    member.remember("DAY %d · 탐사요원 질문 %s" % [day, intent])
    _recompute_contradictions()
    var reaction := _dialogue_reaction(member, intent, result)
    if not reaction.is_empty():
        result["reaction"] = reaction
        _apply_dialogue_reaction_effect(member, intent, result, reaction)
    changed.emit()
    return result

func _reaction_action_text(npc_id: String, code: String) -> String:
    var actions := {
        "mira": {
            "CONVINCED":"미라가 굳어 있던 손을 풀고 기록을 다시 펼친다.",
            "SHAKEN":"미라가 대답 대신 생체 기록을 한 번 더 확인한다.",
            "RESISTED":"미라가 잠시 입을 다물고 시선을 피한다.",
            "UNCERTAIN":"미라가 기록과 당신을 번갈아 본다.",
            "ANGERED":"미라가 의료 단말을 닫고 한 걸음 물러선다."
        },
        "rho": {
            "CONVINCED":"준이 고개를 끄덕이며 공구를 내려놓는다.",
            "SHAKEN":"준이 대답하려다 입을 다물고 패널 쪽을 본다.",
            "RESISTED":"준이 팔짱을 끼고 같은 설명을 되풀이한다.",
            "UNCERTAIN":"준이 턱을 긁으며 기억을 다시 더듬는다.",
            "ANGERED":"준이 짧게 숨을 내쉬고 더는 대꾸하지 않는다."
        },
        "noa": {
            "CONVINCED":"노아가 기록을 다시 내려다보고 문장 하나를 고친다.",
            "SHAKEN":"노아의 손이 같은 시각 위에서 멈춘다.",
            "RESISTED":"노아가 메모를 덮고 답을 미룬다.",
            "UNCERTAIN":"노아가 두 기록을 나란히 놓고 다시 읽는다.",
            "ANGERED":"노아가 노트를 닫고 한동안 말을 하지 않는다."
        },
        "dax": {
            "CONVINCED":"다렌이 계산 한 줄을 지우고 순서를 다시 적는다.",
            "SHAKEN":"다렌이 방금 계산을 지우고 처음부터 다시 본다.",
            "RESISTED":"다렌이 화면을 돌려 놓고 같은 결론을 유지한다.",
            "UNCERTAIN":"다렌이 숫자 두 개 사이에 물음표를 적는다.",
            "ANGERED":"다렌이 단말을 잠그고 대화를 끝낸다."
        },
        "sena": {
            "CONVINCED":"세나가 팔짱을 풀고 출입 기록 쪽으로 몸을 돌린다.",
            "SHAKEN":"세나가 문 쪽을 보다가 다시 당신을 본다.",
            "RESISTED":"세나가 자세를 굳힌 채 답을 바꾸지 않는다.",
            "UNCERTAIN":"세나가 출입카드를 만지작거리며 생각한다.",
            "ANGERED":"세나가 턱을 굳히고 대화를 끊는다."
        },
        "vale": {
            "CONVINCED":"소렌이 이어폰 한쪽을 빼고 기록을 다시 듣는다.",
            "SHAKEN":"소렌이 파형을 멈추고 같은 구간을 되감는다.",
            "RESISTED":"소렌이 볼륨을 낮추고 고개를 젓는다.",
            "UNCERTAIN":"소렌이 소리 없는 구간을 한 번 더 재생한다.",
            "ANGERED":"소렌이 이어폰을 다시 끼고 말을 멈춘다."
        },
        "eli": {
            "CONVINCED":"루칸이 항로 화면을 확대해 당신이 짚은 시각을 표시한다.",
            "SHAKEN":"루칸의 손이 좌표 위에서 잠시 멈춘다.",
            "RESISTED":"루칸이 시선을 창밖으로 돌린 채 결론을 바꾸지 않는다.",
            "UNCERTAIN":"루칸이 별 위치와 기록 시각을 다시 맞춘다.",
            "ANGERED":"루칸이 화면을 닫고 자리에서 일어난다."
        },
        "lyra": {
            "CONVINCED":"마렌이 장갑을 벗고 기록 옆에 새 메모를 놓는다.",
            "SHAKEN":"마렌이 손에 들고 있던 표본을 천천히 내려놓는다.",
            "RESISTED":"마렌이 대답 대신 표본 라벨을 다시 확인한다.",
            "UNCERTAIN":"마렌이 두 표본을 나란히 놓고 비교한다.",
            "ANGERED":"마렌이 작업대를 정리하며 대화를 끝낸다."
        }
    }
    var by_npc: Dictionary = actions.get(npc_id, {})
    return str(by_npc.get(code, "%s|eun 잠시 생각에 잠긴다." % name_of(npc_id)))

func _dialogue_reaction(member: AstraCrewMember, intent: String, result: Dictionary) -> Dictionary:
    var code := ""
    if bool(result.get("slip", false)):
        code = "SHAKEN"
    elif bool(result.get("secret", false)) or intent == "REASSURE":
        code = "CONVINCED"
    elif bool(result.get("deflected", false)):
        code = "RESISTED"
    elif intent == "PRESSURE":
        code = "ANGERED" if member.trust < 0.35 else "SHAKEN"
    elif intent == "CONTRADICTION":
        code = "RESISTED" if member.is_null() else ("SHAKEN" if member.stress >= 0.55 else "UNCERTAIN")
    elif intent == "EVIDENCE":
        code = "SHAKEN" if member.stress >= 0.45 else "UNCERTAIN"
    elif intent == "TRUST":
        code = "RESISTED" if member.trust < 0.25 else "UNCERTAIN"
    if code == "":
        return {}
    return {"code": code, "text": _josa_inline(_reaction_action_text(member.id, code))}

func _apply_dialogue_reaction_effect(member: AstraCrewMember, intent: String, result: Dictionary, reaction: Dictionary) -> void:
    var code := str(reaction.get("code", ""))
    match code:
        "CONVINCED":
            member.adjust_trust(0.02)
            for target in result.get("evidence_members", []):
                var target_id := str(target)
                if target_id != member.id and target_id in active_participants():
                    member.add_suspicion(target_id, 0.04)
        "SHAKEN":
            flags["shaken_%s_%d" % [member.id, day]] = true
        "RESISTED":
            if intent == "PRESSURE":
                flags["pressure_resisted_" + member.id] = int(flags.get("pressure_resisted_" + member.id, 0)) + 1
        "UNCERTAIN":
            var topic := str(result.get("clue_topic", ""))
            if topic != "":
                flags["uncertain_%s_%s" % [member.id, topic]] = day
        "ANGERED":
            member.adjust_trust(-0.03)
            flags["private_block_%s" % member.id] = day


# The open questions added in 0.4.0. They cost the same as any other question
# and never hand over the answer; what they give is a second and third way to
# hear a person talk, and a chance to catch a claim that can be cross-checked.
#
# Under real stress a character deflects instead of answering — in their own
# way, per personality. A deflection is not proof of anything: a frightened
# crew member and a composed Null can produce the same one.
func _ask_open(member: AstraCrewMember, intent: String, result: Dictionary) -> void:
    var key := str(INTENT_LINE_KEY.get(intent, ""))
    if key == "":
        return
    var claim := current_claim(member.id)
    var params := {"pos": room_name(str(claim.get("position", "")))}
    var lying := _is_lying_about_claim(member)
    var deflect_chance := member.stress * 0.5 + (0.18 if lying else 0.0) - member.trust * 0.2
    if AstraDialogue.has_line(member.id, "deflect") and rng.randf() < clampf(deflect_chance, 0.0, 0.5):
        _say(member, "deflect", params, result)
        member.adjust_stress(0.03)
        result["deflected"] = true
        return
    var spoken := _say(member, key, params, result)
    member.adjust_trust(0.02)
    match intent:
        "WITNESS":
            _record_claim(member.id, AstraClaimLedger.KIND_WITNESS, AstraClaimLedger.SCOPE_PRIVATE, spoken, {})
        "TIMELINE":
            _record_claim(member.id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PRIVATE, spoken, {
                "position": str(claim.get("position", "")), "companions": claim.get("companions", [])
            })
        "TRUST":
            _record_claim(member.id, AstraClaimLedger.KIND_DENY, AstraClaimLedger.SCOPE_PRIVATE, spoken, {})
    _maybe_tell(member, lying, result)

func _say(member: AstraCrewMember, key: String, params: Dictionary, result: Dictionary) -> String:
    var text := AstraDialogue.line_fresh(member.id, key, params, dialogue_recent, rng.randf())
    if text == "":
        return ""
    _transcript(member.id, member.id, text, str(result.get("intent", "")))
    result["lines"].append({"speaker": member.id, "text": text, "intent": str(result.get("intent", ""))})
    return text

func _narrate(member: AstraCrewMember, text: String, result: Dictionary) -> void:
    _transcript(member.id, "narration", text, str(result.get("intent", "")))
    result["lines"].append({"speaker": "narration", "text": text, "intent": str(result.get("intent", ""))})

func _maybe_tell(member: AstraCrewMember, lying: bool, result: Dictionary) -> void:
    var chance := 0.0
    if lying:
        chance = 0.7 if protocol == "EMPATH" else 0.35
    elif member.stress >= 0.5:
        chance = 0.06 if protocol == "EMPATH" else 0.15
    if rng.randf() < chance:
        _narrate(member, AstraDialogue.tell(lying, member.display_name, rng.randi_range(0, 9)), result)
        result["tell"] = true

func _is_lying_about_claim(member: AstraCrewMember) -> bool:
    return bool(current_claim(member.id).get("lie", false))

func innocent_discrepancy_reason() -> String:
    return str(truth.get("herring_reason","PERSONAL_SECRET"))

func innocent_discrepancy_text(reason: String = "") -> String:
    var code := reason if reason != "" else innocent_discrepancy_reason()
    return str({
        "EMBARRASSMENT":"창피해서 사실과 다른 말을 했다.",
        "PROTECT_OTHER":"다른 사람을 보호하려고 일부 사실을 숨겼다.",
        "HIDE_MISTAKE":"자기 실수를 감추려고 진술을 바꿨다.",
        "KEEP_PROMISE":"누군가와 한 약속을 지키려고 일부 사실을 숨겼다.",
        "PERSONAL_SECRET":"사건과 무관한 개인 사정을 숨기려고 진술을 바꿨다.",
        "FEAR":"두려움 때문에 사실대로 말하지 못했다.",
        "MISREMEMBERED":"거짓말한 것이 아니라 장소 순서를 잘못 기억하고 있었다."
    }.get(code,"사건과 무관한 사정으로 진술이 어긋났다."))

func _ask_alibi(member: AstraCrewMember, result: Dictionary) -> void:
    var claim := current_claim(member.id)
    var companions: Array = claim.get("companions", [])
    var params := {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(companions))}
    var spoken := _say(member, "alibi_with" if not companions.is_empty() else "alibi_alone", params, result)
    known_claims[member.id] = {"position": str(claim.get("position", "")), "companions": companions.duplicate(), "day": day}
    _record_claim(member.id, AstraClaimLedger.KIND_POSITION, AstraClaimLedger.SCOPE_PRIVATE, spoken, {
        "position": str(claim.get("position", "")), "companions": companions
    })
    _record_claim(member.id, AstraClaimLedger.KIND_COMPANION if not companions.is_empty() else AstraClaimLedger.KIND_ALONE,
        AstraClaimLedger.SCOPE_PRIVATE, spoken, {"position": str(claim.get("position", "")), "companions": companions})
    _log("진술 · %s — %s%s" % [member.display_name, room_name(str(claim.get("position", ""))), (" / 동행 " + names_of(companions)) if not companions.is_empty() else " / 혼자"])
    var lying := _is_lying_about_claim(member)
    if lying:
        member.adjust_stress(0.04)
    _maybe_tell(member, lying, result)

    # A witness who saw someone near a sabotage site mentions it.
    for sighting in truth.get("sightings", []):
        if str(sighting.get("witness", "")) == member.id and not flags.has("sighting_" + member.id):
            flags["sighting_" + member.id] = true
            _say(member, "sighting", {"time": str(sighting.get("time", "")), "room": room_name(str(sighting.get("room", ""))), "group": AstraCrewCatalog.group_label(str(sighting.get("category", "")), str(sighting.get("group", "")))}, result)
            var clue := _add_testimony_clue("sighting", member.id, "목격 증언 · " + member.display_name,
                "%s|i 증언했다: %s쯤 %s 쪽 통로에서 %s 차림의 인물을 봤다. 해당: %s." % [member.display_name, str(sighting.get("time", "")), room_name(str(sighting.get("room", ""))), AstraCrewCatalog.group_label(str(sighting.get("category", "")), str(sighting.get("group", ""))), names_of(sighting.get("members", []))],
                str(sighting.get("category", "")), str(sighting.get("group", "")), str(sighting.get("op", "")), str(sighting.get("culprit", "")), false)
            result["clue"] = clue
    if member.is_null() and not bool(truth.get("mutual_alibi", false)) and not flags.has("fake_sighting_" + member.id) and rng.randf() < 0.45:
        flags["fake_sighting_" + member.id] = true
        var fake := _fabricate_group(member.id)
        if not fake.is_empty():
            var op_id := str(truth["null_ops"].get(member.id, ""))
            var op := op_data(op_id)
            var time_text := AstraCaseCatalog.format_time(int(op.get("minute", 0)) - 1)
            _say(member, "sighting", {"time": time_text, "room": room_name(str(op.get("room", ""))), "group": AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"]))}, result)
            var fake_clue := _add_testimony_clue("sighting", member.id, "목격 증언 · " + member.display_name,
                "%s|i 증언했다: %s쯤 %s 쪽 통로에서 %s 차림의 인물을 봤다. 해당: %s." % [member.display_name, time_text, room_name(str(op.get("room", ""))), AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"])), names_of(AstraCrewCatalog.group_members_in(str(fake["category"]), str(fake["group"]), roster))],
                str(fake["category"]), str(fake["group"]), op_id, member.id, true)
            result["clue"] = fake_clue

func _clue_topic(clue: Dictionary) -> String:
    var kind := str(clue.get("kind", ""))
    var room := str(clue.get("log_room", clue.get("room", "")))
    var title := str(clue.get("title", "")).to_lower()
    if "목적지" in title or "도착" in title:
        return "destination_record" if "목적지" in title else "arrival_log"
    if "수면" in title or "생체" in title:
        return "sleep_signal"
    if room == "comms" or "통신" in title or "신호" in title:
        return "comms_access"
    if room == "security" or "보안" in title or "출입" in title:
        return "security_door"
    if room == "garden" or "시료" in title or "생태" in title:
        return "ecology_sample"
    if kind == "access_log":
        return "access_log"
    return kind if kind != "" else "record"

func _evidence_specialist_note(member: AstraCrewMember, topic: String, clue: Dictionary) -> String:
    match member.id:
        "vale":
            if topic in ["comms_access", "sleep_signal"]:
                return "소렌이 파형의 반복 간격부터 짚는다. “문장보다 신호가 먼저 바뀐 지점을 볼게요.”"
        "noa":
            if topic in ["comms_access", "security_door", "arrival_log", "destination_record", "access_log"]:
                return "노아가 제목보다 작성 시각과 수정 시각을 먼저 비교한다."
        "rho":
            if topic in ["comms_access", "security_door", "access_log"]:
                return "준이 단말 접근 흔적을 훑는다. “직접 접속인지 원격인지부터 보면 돼.”"
        "dax":
            if topic in ["comms_access", "arrival_log", "destination_record", "access_log"]:
                return "다렌이 연결 경로와 시각을 한 줄로 다시 맞춘다."
        "sena":
            if topic in ["security_door", "access_log"]:
                return "세나가 출입 순서와 카드 사용 시각을 다시 대조한다."
        "mira":
            if topic == "sleep_signal":
                return "미라가 수치보다 생체 기록이 끊긴 구간을 먼저 확인한다."
        "eli":
            if topic in ["destination_record", "arrival_log"]:
                return "루칸이 좌표와 기록 시각을 같은 화면에 겹쳐 놓는다."
        "lyra":
            if topic == "ecology_sample":
                return "마렌이 표본의 날짜와 환경 기록을 나란히 놓는다."
    return ""

func _ask_evidence(member: AstraCrewMember, clue: Dictionary, result: Dictionary) -> void:
    AstraKnowledgeModel.share_with(flags, str(clue.get("id","")), member.id, day)
    var kind := str(clue.get("kind", ""))
    var claim := current_claim(member.id)
    var params := {
        "pos": room_name(str(claim.get("position", ""))),
        "room": room_name(str(clue.get("log_room", clue.get("room", "")))),
        "members": names_of(clue.get("members", []))
    }
    match kind:
        "access_log":
            var log_room := str(clue.get("log_room", ""))
            var in_log: bool = member.id in clue.get("log_people", [])
            var claims_room := str(claim.get("position", "")) == log_room
            if in_log and claims_room:
                _say(member, "evidence_log_ok", params, result)
            elif in_log != claims_room:
                member.adjust_stress(0.1)
                _say(member, "evidence_log_bad", params, result)
                _maybe_tell(member, true, result)
            else:
                _say(member, "evidence_log_other", params, result)
        "context", "op_record":
            _say(member, "evidence_context", params, result)
        _:
            var members: Array = clue.get("members", [])
            if member.id in members:
                if member.is_null():
                    member.adjust_stress(0.08)
                    _say(member, "evidence_self_null", params, result)
                    _maybe_tell(member, true, result)
                else:
                    member.adjust_stress(0.03)
                    _say(member, "evidence_self_crew", params, result)
            else:
                _say(member, "evidence_other", params, result)

    var topic := _clue_topic(clue)
    result["clue_topic"] = topic
    var note := _evidence_specialist_note(member, topic, clue)
    if note != "":
        _transcript(member.id, "narration", note, "EVIDENCE")
        result["lines"].append({"speaker":"narration", "text":note, "intent":"EVIDENCE", "topic":topic})

func _ask_contradiction(member: AstraCrewMember, result: Dictionary) -> void:
    var is_herring := str(truth.get("herring", "")) == member.id
    if is_herring and not member.secret_revealed:
        if member.trust >= 0.5 or member.stress >= 0.65:
            var reason := innocent_discrepancy_reason()
            var misremembered := reason == "MISREMEMBERED"
            if misremembered:
                var correction := "잠깐. 일부러 숨긴 게 아니에요. 제가 장소 순서를 잘못 기억했어요."
                _transcript(member.id, member.id, correction, "CONTRADICTION")
                result["lines"].append({"speaker":member.id,"text":correction,"intent":"CONTRADICTION"})
            else:
                _say(member, "contra_confess", {}, result)
                var secret := str(member.info.get("secret", ""))
                _transcript(member.id, member.id, secret)
                result["lines"].append({"speaker": member.id, "text": secret})
                stats["secrets"] = int(stats.get("secrets", 0)) + 1
            member.secret_revealed = true
            member.adjust_trust(0.06)
            member.adjust_stress(-0.12)
            var true_pos := str(truth["positions"].get(member.id, ""))
            known_claims[member.id] = {"position": true_pos, "companions": [], "day": day, "revised": true}
            _log("%s · %s|i 진술을 정정했다: 실제로는 %s에 혼자 있었다." % ["기억 정정" if misremembered else "숨긴 사정", member.display_name, room_name(true_pos)])
            result["secret"] = not misremembered
            result["misremembered"] = misremembered
            result["innocent_reason"] = reason
            notice.emit("secret", {"npc_id": member.id, "reason":reason, "misremembered":misremembered})
        else:
            member.adjust_stress(0.12)
            _say(member, "contra_hold", {}, result)
            _maybe_tell(member, true, result)
        return
    if member.is_null():
        member.adjust_stress(0.15)
        member.adjust_trust(-0.03)
        var slip_chance := 0.4 + (0.2 if protocol == "EMPATH" else 0.0)
        if member.stress >= 0.62 and not member.slipped and rng.randf() < slip_chance:
            _trigger_slip(member, result)
        else:
            _say(member, "contra_deny", {}, result)
            _maybe_tell(member, true, result)
        return
    member.adjust_trust(-0.02)
    member.adjust_stress(0.04)
    _say(member, "contra_honest", {"pos": room_name(str(current_claim(member.id).get("position", "")))}, result)

func _trigger_slip(member: AstraCrewMember, result: Dictionary) -> void:
    var op_id := str(truth["null_ops"].get(member.id, ""))
    var op := op_data(op_id)
    var time_text := AstraCaseCatalog.format_time(int(op.get("minute", 0)), int(op.get("second", 0)))
    _say(member, "slip", {"time": time_text}, result)
    member.slipped = true
    stats["slips"] = int(stats.get("slips", 0)) + 1
    var clue := _add_testimony_clue("slip", member.id, "실언 · " + member.display_name,
        "%s|i 압박 끝에 %s 실행 시각을 초 단위(%s)까지 입에 올렸다. 현장 로그를 직접 본 사람만 알 수 있는 숫자다." % [member.display_name, op_name(op_id), time_text],
        "", "", op_id, member.id, false)
    clue["members"] = [member.id]
    result["clue"] = clue
    result["slip"] = true
    _log("실언 포착 · %s" % member.display_name)
    notice.emit("slip", {"npc_id": member.id})

func _ask_suspect(member: AstraCrewMember, result: Dictionary, confide: bool) -> void:
    if confide and member.trust < CONFIDE_TRUST:
        _say(member, "refuse", {}, result)
        return
    var top := top_suspect_of(member.id)
    var target := str(top.get("target", ""))
    if target == "" or float(top.get("value", 0.0)) < 0.3:
        _say(member, "suspect_none", {}, result)
        return
    var params := {"target": name_of(target), "reason": AstraDialogue.reason_text(str(top.get("reason", "gut")))}
    _say(member, "confide" if confide else "suspect_some", params, result)
    if confide:
        member.adjust_trust(0.02)
    result["target"] = target

func _ask_reassure(member: AstraCrewMember, result: Dictionary) -> void:
    var warm := member.trust >= 0.45 or member.stress >= 0.55
    member.adjust_trust(0.07 if warm else 0.03)
    member.adjust_stress(-0.09)
    _say(member, "reassure_warm" if warm else "reassure_flat", {}, result)

func _ask_pressure(member: AstraCrewMember, result: Dictionary) -> void:
    var repeats := int(flags.get("pressure_count_" + member.id, 0))
    flags["pressure_count_" + member.id] = repeats + 1
    var factor := 1.0 if repeats == 0 else (0.55 if repeats == 1 else 0.3)
    member.adjust_stress(0.17 * factor)
    member.adjust_trust(-0.06 * factor)
    if member.is_null():
        var slip_chance := 0.25 + (0.15 if protocol == "EMPATH" else 0.0)
        if member.stress >= 0.72 and not member.slipped and rng.randf() < slip_chance:
            _trigger_slip(member, result)
            return
        _say(member, "pressure_null", {}, result)
        _maybe_tell(member, true, result)
    else:
        _say(member, "pressure_crew", {}, result)
        _maybe_tell(member, _is_lying_about_claim(member), result)

func top_suspect_of(observer_id: String) -> Dictionary:
    var member := npc(observer_id)
    if member == null:
        return {}
    var target := ""
    var best := -1.0
    if member.is_null():
        target = scapegoat_for(observer_id)
        best = maxf(0.45, crowd_suspicion(target))
    else:
        for other in living_ids():
            if other == observer_id:
                continue
            var value := member.get_suspicion(other) - member.get_affinity(other) * 0.1
            if value > best:
                best = value
                target = other
    return {"target": target, "value": best, "reason": reason_for(observer_id, target)}

func reason_for(_observer_id: String, target_id: String) -> String:
    if target_id == "":
        return "gut"
    for clue in clues:
        if bool(clue.get("public", false)) and str(clue.get("kind", "")) == "slip" and target_id in clue.get("members", []):
            return "slip"
    var log_hit := false
    var disputed := false
    for item in contradictions:
        if not bool(item.get("public", false)) or target_id not in item.get("targets", []):
            continue
        if str(item.get("kind", "")) in ["log", "log_presence", "terminal"]:
            log_hit = true
        else:
            disputed = true
    if log_hit:
        return "log"
    if disputed:
        return "disputed"
    var clue_hits := 0
    for clue in clues:
        if bool(clue.get("public", false)) and target_id in clue.get("members", []) and str(clue.get("kind", "")) != "access_log":
            clue_hits += 1
    if clue_hits >= 2:
        return "clue2"
    if clue_hits == 1:
        return "clue"
    if not casualties.is_empty():
        var last: Dictionary = casualties[casualties.size() - 1]
        var victim := npc(str(last.get("id", "")))
        if victim != null and int(last.get("day", 0)) == day - 1:
            var victim_top := ""
            var victim_best := -1.0
            for other in living_ids():
                if victim.get_suspicion(other) > victim_best:
                    victim_best = victim.get_suspicion(other)
                    victim_top = other
            if victim_top == target_id:
                return "victim"
    if accused_today.has(target_id):
        return "accused"
    if public_claims.has(target_id) and current_claim(target_id).get("companions", []).is_empty():
        return "alone"
    var observer := npc(_observer_id)
    if observer != null and observer.get_affinity(target_id) < -0.12:
        return "friction"
    return "gut"

func scapegoat_for(null_id: String) -> String:
    var best := ""
    var best_value := -1.0
    for other in living_ids():
        if other == null_id or crew[other].is_null():
            continue
        var value := crowd_suspicion(other) + (0.05 if not public_claims.has(other) else 0.0)
        value += _stable_noise(null_id + other) * 0.04
        if value > best_value:
            best_value = value
            best = other
    return best

# ---------------------------------------------------------------- private events

func has_feature(feature: String) -> bool:
    return features.is_empty() or feature in features

func _maybe_private_event() -> void:
    # The calibration case teaches five things and private conversation is not
    # one of them. Dropping a relationship scene into the tutorial buries the one
    # contradiction the player is supposed to find (§6).
    if AstraCaseCatalog.is_calibration(case_id) or not has_feature("private_talk"):
        return
    if not pending_event.is_empty() or outcome != "" or tutorial_active():
        return
    var candidates: Array = []
    var weights: Array = []
    for npc_id in living_ids():
        if not AstraPrivateEvents.has_event(npc_id):
            continue
        var seen_count := int(events_seen.get(npc_id, 0))
        if seen_count >= AstraPrivateEvents.count_for(npc_id):
            continue
        if int(flags.get("private_block_%s" % npc_id, 0)) >= day:
            continue
        candidates.append(npc_id)
        weights.append(0.15 + crew[npc_id].trust)
    if candidates.is_empty():
        return
    if day > 1 and rng.randf() > 0.85:
        return
    var total := 0.0
    for weight in weights:
        total += float(weight)
    var roll := rng.randf() * total
    var chosen := str(candidates[0])
    for index in range(candidates.size()):
        roll -= float(weights[index])
        if roll <= 0.0:
            chosen = str(candidates[index])
            break
    var seen_count := int(events_seen.get(chosen, 0))
    pending_event = AstraPrivateEvents.build(chosen, victim_name(), seen_count, {
        "day": day, "trust": crew[chosen].trust, "stress": crew[chosen].stress,
        "case_id": case_id
    })
    events_seen[chosen] = seen_count + 1
    selected_id = chosen
    _log("개인 면담 요청 · %s" % name_of(chosen))
    notice.emit("private_event", {"npc_id": chosen})

func resolve_private_event(choice_index: int) -> Dictionary:
    if pending_event.is_empty():
        return {"ok": false}
    var choices: Array = pending_event.get("choices", [])
    var passive := choices.is_empty()
    if not passive and (choice_index < 0 or choice_index >= choices.size()):
        return {"ok": false}
    var npc_id := str(pending_event.get("npc_id", ""))
    var member := npc(npc_id)
    if member == null:
        return {"ok": false}
    if passive:
        var passive_result := {
            "ok": true, "npc_id": npc_id, "effect": "observe", "lines": [],
            "text": _josa_inline(str(pending_event.get("resolution", "잠시 말없이 그 장면을 지켜본다.")))
        }
        member.remember("DAY %d · 개인 면담 관찰" % day)
        _transcript(npc_id, "narration", str(passive_result["text"]))
        _log("개인 면담 · %s · 관찰" % member.display_name)
        pending_event.clear()
        changed.emit()
        return passive_result
    var choice: Dictionary = choices[choice_index]
    var effect := str(choice.get("effect", ""))
    var result := {"ok": true, "npc_id": npc_id, "effect": effect, "lines": [], "text": ""}
    _transcript(npc_id, "player", str(choice.get("label", "")))
    var lying := member.is_null() or (_is_lying_about_claim(member) and not member.secret_revealed)

    match effect:
        "comfort":
            member.adjust_trust(0.1)
            member.adjust_stress(-0.1)
            result["text"] = "%s의 어깨에서 힘이 조금 빠진다. 당신을 보는 눈빛이 달라졌다." % member.display_name
        "comfort_light":
            member.adjust_trust(0.04)
            result["text"] = "%s|i 작게 고개를 끄덕인다. 묻어 둔 이야기는 그대로 남았다." % member.display_name
        "cold":
            member.adjust_trust(-0.03)
            result["text"] = "대화는 짧게 끝났다. %s|eun 더 말을 붙이지 않는다." % member.display_name
        "procedure":
            member.adjust_trust(0.05)
            member.adjust_stress(-0.04)
            result["text"] = "“알겠습니다. 절차대로 하겠습니다.” %s의 목소리가 한결 단단해졌다." % member.display_name
        "read":
            member.adjust_trust(-0.01)
            var tell_chance := (0.75 if lying else 0.15) if protocol == "EMPATH" else (0.6 if lying else 0.2)
            if rng.randf() < tell_chance:
                result["text"] = AstraDialogue.tell(lying, member.display_name, rng.randi_range(0, 9))
                result["tell"] = true
            else:
                result["text"] = "%s|eun 담담하게 당신의 시선을 받아낸다. 읽히는 것이 없다." % member.display_name
        "witness":
            result["text"] = _event_witness(member)
        "open_records":
            result["text"] = _event_open_records(member, result)
        "flow":
            result["text"] = _event_flow(member)
        "top_suspect":
            var top := top_suspect_of(npc_id)
            var target := str(top.get("target", ""))
            member.adjust_trust(0.02)
            if target == "":
                result["text"] = "%s|eun 아직 누구도 짚지 못했다고 말한다." % member.display_name
            else:
                result["text"] = "%s의 판단: %s. 이유는 %s." % [member.display_name, name_of(target), AstraDialogue.reason_text(str(top.get("reason", "gut")))]
        "patrol":
            flags["patrol"] = npc_id
            member.adjust_trust(0.03)
            result["text"] = "오늘 밤 %s|i 선내 순찰을 맡는다. 누군가를 추가로 지킬 것이다." % member.display_name
        "vale_record":
            result["text"] = _event_vale_record(member, result)
        "noa_public", "noa_private":
            result["text"] = _event_noa(member, effect == "noa_public", result)
        "calm_meeting":
            flags["calm"] = npc_id
            member.adjust_trust(0.03)
            result["text"] = "%s|i 회의 전에 사람들을 한 명씩 찾아가 이야기를 나누기로 했다." % member.display_name
        "crowd_target":
            var hot := ""
            var hot_value := -1.0
            for other in living_ids():
                if other == npc_id:
                    continue
                if crowd_suspicion(other) > hot_value:
                    hot_value = crowd_suspicion(other)
                    hot = other
            result["text"] = "%s의 대답: 지금 가장 위험하게 몰리는 사람은 %s. 여론 의심도 %d%%." % [member.display_name, name_of(hot), int(hot_value * 100.0)]
        "dax_hint":
            result["text"] = _event_dax_hint(member)

    member.refresh_expression()
    member.remember("DAY %d · 개인 면담 선택 %s" % [day, effect])
    result["text"] = _josa_inline(str(result.get("text", "")))
    _transcript(npc_id, "narration", str(result.get("text", "")))
    _log("개인 면담 · %s · %s" % [member.display_name, str(choice.get("label", ""))])
    pending_event.clear()
    _recompute_contradictions()
    changed.emit()
    return result

func _event_witness(member: AstraCrewMember) -> String:
    for sighting in truth.get("sightings", []):
        if str(sighting.get("witness", "")) == member.id and not flags.has("sighting_" + member.id):
            flags["sighting_" + member.id] = true
            _add_testimony_clue("sighting", member.id, "목격 증언 · " + member.display_name,
                "%s|i 증언했다: %s쯤 %s 쪽 통로에서 %s 차림의 인물을 봤다. 해당: %s." % [member.display_name, str(sighting.get("time", "")), room_name(str(sighting.get("room", ""))), AstraCrewCatalog.group_label(str(sighting.get("category", "")), str(sighting.get("group", ""))), names_of(sighting.get("members", []))],
                str(sighting.get("category", "")), str(sighting.get("group", "")), str(sighting.get("op", "")), str(sighting.get("culprit", "")), false)
            return "%s|i 기억을 더듬는다. 새 목격 증언이 단서 목록에 추가됐다." % member.display_name
    if member.is_null():
        var fake := _fabricate_group(member.id)
        if not fake.is_empty():
            var op_id := str(truth["null_ops"].get(member.id, ""))
            var op := op_data(op_id)
            _add_testimony_clue("sighting", member.id, "목격 증언 · " + member.display_name,
                "%s|i 증언했다: %s쯤 %s 쪽 통로에서 %s 차림의 인물을 봤다. 해당: %s." % [member.display_name, AstraCaseCatalog.format_time(int(op.get("minute", 0)) - 1), room_name(str(op.get("room", ""))), AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"])), names_of(AstraCrewCatalog.group_members_in(str(fake["category"]), str(fake["group"]), roster))],
                str(fake["category"]), str(fake["group"]), op_id, member.id, true)
            return "%s|i 기억을 더듬는다. 새 목격 증언이 단서 목록에 추가됐다." % member.display_name
    var claim := current_claim(member.id)
    known_claims[member.id] = {"position": str(claim.get("position", "")), "companions": claim.get("companions", []).duplicate(), "day": day}
    return "%s|eun 특별히 본 사람은 없었다고 말한다. 대신 자신의 알리바이를 자세히 들려줬다." % member.display_name

func _event_open_records(member: AstraCrewMember, result: Dictionary) -> String:
    var tampered := false
    if member.is_null():
        for clue in clues:
            if str(clue.get("culprit", "")) == member.id and str(clue.get("kind", "")) == "trace" and not bool(clue.get("found", false)) and not bool(clue.get("destroyed", false)) and not bool(clue.get("decoy", false)):
                clue["destroyed"] = true
                stats["destroyed"] = int(stats.get("destroyed", 0)) + 1
                tampered = true
                break
    var candidates: Array = []
    for clue in clues:
        if _is_searchable(clue) and not bool(clue.get("found", false)) and not bool(clue.get("destroyed", false)):
            candidates.append(clue)
    if candidates.is_empty():
        return "함께 기록을 뒤졌지만 새로 나온 것은 없었다."
    var picked: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
    _discover(picked, true)
    result["clue"] = picked
    var text := "%s|wa 기록을 함께 열었다. 단서 ‘%s’를 확보했다." % [member.display_name, str(picked.get("title", ""))]
    if tampered:
        text += " 다만 기록 한쪽이 최근에 손상된 흔적이 있었다."
    return text

func _event_flow(member: AstraCrewMember) -> String:
    var pusher := ""
    var best := 0.0
    for npc_id in meeting_pushers.keys():
        if npc_id == member.id or not is_alive(str(npc_id)):
            continue
        if float(meeting_pushers[npc_id]) > best:
            best = float(meeting_pushers[npc_id])
            pusher = str(npc_id)
    if member.is_null():
        var decoy := scapegoat_for(member.id)
        if decoy != "":
            pusher = decoy
    if pusher == "":
        var top := top_suspect_of(member.id)
        return "“아직 판이 덜 짜였어. 굳이 하나 고르라면 %s.”" % name_of(str(top.get("target", "")))
    member.adjust_trust(0.02)
    return "“회의 흐름을 가장 세게 민 건 %s야. 여론이 그쪽 말대로 움직였지.”" % name_of(pusher)

func _event_vale_record(member: AstraCrewMember, result: Dictionary) -> String:
    if not member.is_null():
        var candidates: Array = []
        for clue in clues:
            if str(clue.get("kind", "")) in ["trace", "op_record"] and not bool(clue.get("found", false)) and not bool(clue.get("destroyed", false)) and not bool(clue.get("decoy", false)):
                candidates.append(clue)
        if not candidates.is_empty():
            var picked: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
            _discover(picked, true)
            result["clue"] = picked
            member.adjust_trust(0.04)
            return "소렌이 보여 준 기록은 공식 로그와 일치했다. 단서 ‘%s’를 확보했다." % str(picked.get("title", ""))
        return "소렌이 기록을 펼쳤지만 이미 확인한 내용뿐이었다."
    var fake := _fabricate_group(member.id)
    if fake.is_empty():
        return "소렌이 기록을 펼쳤지만 의미 있는 내용은 없었다."
    var op_id := str(truth["null_ops"].get(member.id, ""))
    var clue := _add_testimony_clue("planted", member.id, "소렌의 신호 해석",
        "소렌의 해석: %s 직전 외부로 나간 신호에 %s 서명 조각이 섞여 있다. 해당: %s. (출처: 소렌 개인 분석)" % [op_name(op_id), AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"])), names_of(AstraCrewCatalog.group_members_in(str(fake["category"]), str(fake["group"]), roster))],
        str(fake["category"]), str(fake["group"]), op_id, member.id, true)
    result["clue"] = clue
    return "소렌이 자신만의 해석을 담은 기록을 건넸다. 공식 로그로는 확인되지 않는다."

func _event_noa(member: AstraCrewMember, make_public: bool, result: Dictionary) -> String:
    var target := ""
    if member.is_null():
        target = scapegoat_for(member.id)
    else:
        var liars: Array = []
        for npc_id in living_ids():
            if npc_id == member.id:
                continue
            if bool(current_claim(npc_id).get("lie", false)):
                liars.append(npc_id)
        if not liars.is_empty():
            target = str(liars[rng.randi_range(0, liars.size() - 1)])
    if target == "":
        return "노아가 기록을 다시 확인하더니, 착각이었다며 고개를 저었다."
    var claim := current_claim(target)
    var pos := str(claim.get("position", ""))
    known_claims[target] = {"position": pos, "companions": claim.get("companions", []).duplicate(), "day": day}
    var key := "terminal:%s:%d" % [target, day]
    manual_contradictions.append({
        "key": key, "kind": "terminal", "targets": [target], "source": member.id,
        "detail": "노아의 단말 기록: %s의 개인 단말은 사건 시각 %s에 접속한 적이 없다. (출처: 노아)" % [name_of(target), room_name(pos)]
    })
    if make_public:
        flags["noa_public"] = key
    result["target"] = target
    member.adjust_trust(0.03)
    return "노아가 조용히 문장 하나를 가리킨다. %s의 진술과 단말 기록이 어긋난다.%s" % [name_of(target), " 다음 회의에서 공개하기로 했다." if make_public else ""]

func _event_dax_hint(member: AstraCrewMember) -> String:
    var nulls: Array = truth.get("nulls", [])
    var target_null := ""
    for null_id in nulls:
        if is_alive(str(null_id)):
            target_null = str(null_id)
            break
    if target_null == "":
        return "“구조는 이미 드러났다. 더 볼 변수는 없다.”"
    var op_id := str(truth["null_ops"].get(target_null, ""))
    var pair: Array = truth.get("trace_pairs", {}).get(target_null, [])
    if member.is_null():
        var wrong: Array = []
        for category in AstraCrewCatalog.TRAIT_CATEGORIES.keys():
            if category not in pair:
                wrong.append(category)
        pair = [wrong[0], wrong[1]] if wrong.size() >= 2 else pair
    member.adjust_trust(0.05)
    if pair.size() < 2:
        return "“데이터가 부족하다.”"
    return "“%s의 실행자를 가르는 변수는 %s|wa %s다. 두 흔적의 교집합을 구해라.”" % [op_name(op_id), AstraCrewCatalog.category_label(str(pair[0])), AstraCrewCatalog.category_label(str(pair[1]))]

func _fabricate_group(liar_id: String) -> Dictionary:
    var target := scapegoat_for(liar_id)
    if target == "":
        return {}
    var nulls: Array = truth.get("nulls", [])
    var categories: Array = AstraCrewCatalog.TRAIT_CATEGORIES.keys()
    for index in range(categories.size()):
        var category := str(categories[(index + rng.randi_range(0, 4)) % categories.size()])
        var group := AstraCrewCatalog.group_of(target, category)
        var members: Array = AstraCrewCatalog.group_members_in(category, group, roster)
        var clean := true
        for null_id in nulls:
            if null_id in members:
                clean = false
        if clean:
            return {"category": category, "group": group}
    return {}

func _add_testimony_clue(kind: String, source_id: String, title: String, text: String, category: String, group: String, op_id: String, culprit: String, planted: bool) -> Dictionary:
    var members: Array = []
    if category != "" and group != "":
        members = AstraCrewCatalog.group_members_in(category, group, roster)
    var clue := {
        "id": "T%02d" % (clues.size() + 1), "kind": kind, "room": "", "op": op_id,
        "title": title, "text": _josa_inline(text),
        "time": "진술", "category": category, "group": group, "members": members,
        "culprit": culprit, "decoy": false, "planted": planted, "source": source_id,
        "found": false, "destroyed": false, "public": false, "log_people": [], "found_day": 0
    }
    clues.append(clue)
    _discover(clue, true)
    return clue

# Resolves "Name|i" style inline particles in engine-built sentences.
func _josa_inline(text: String) -> String:
    var out := text
    for particle in ["eun", "i", "eul", "wa", "ro"]:
        var marker: String = "|" + str(particle)
        var guard := 0
        while out.find(marker) >= 0 and guard < 40:
            guard += 1
            var at := out.find(marker)
            var start := at
            while start > 0 and out.substr(start - 1, 1) not in [" ", "\n", "(", "“", "‘", ":"]:
                start -= 1
            var word := out.substr(start, at - start)
            out = out.substr(0, start) + AstraJosa.attach(word, str(particle)) + out.substr(at + marker.length())
    return out

func _log(text: String) -> void:
    journal.append({"day": day, "phase": phase, "text": _josa_inline(text)})
    if journal.size() > 400:
        journal.pop_front()

func _transcript(npc_id: String, speaker: String, text: String, intent: String = "") -> void:
    if not transcripts.has(npc_id):
        transcripts[npc_id] = []
    var list: Array = transcripts[npc_id]
    var entry_id := "dialogue_%s_%d_%03d" % [npc_id, day, list.size()]
    var reply_to := ""
    var thread_id := entry_id
    if not list.is_empty():
        var previous: Dictionary = list[list.size() - 1]
        if speaker != "player" and str(previous.get("speaker", "")) == "player":
            reply_to = str(previous.get("entry_id", ""))
            thread_id = str(previous.get("thread_id", reply_to))
        elif speaker == "player":
            thread_id = entry_id
        else:
            thread_id = str(previous.get("thread_id", entry_id))
    list.append({
        "entry_id": entry_id, "thread_id": thread_id, "reply_to": reply_to,
        "speaker": speaker, "text": _josa_inline(text), "day": day,
        "intent": intent, "topic": intent.to_lower()
    })
    if list.size() > 120:
        list.pop_front()

func _names(ids: Array) -> Array:
    var names: Array = []
    for npc_id in ids:
        names.append(name_of(str(npc_id)))
    return names

func _stable_noise(key: String) -> float:
    return float(abs(hash("%d:%d:%s" % [seed_value, day, key])) % 1000) / 1000.0

# ---------------------------------------------------------------- contradictions

func has_contradiction_on(npc_id: String) -> bool:
    for item in contradictions:
        if npc_id in item.get("targets", []):
            return true
    return false

func contradictions_on(npc_id: String) -> Array:
    var result: Array = []
    for item in contradictions:
        if npc_id in item.get("targets", []):
            result.append(item)
    return result

func _recompute_contradictions() -> void:
    var result: Array = []
    for clue in clues:
        if not bool(clue.get("found", false)) or str(clue.get("kind", "")) != "access_log":
            continue
        var log_room := str(clue.get("log_room", ""))
        var people: Array = clue.get("log_people", [])
        for npc_id in known_claims.keys():
            var claim: Dictionary = known_claims[npc_id]
            var pos := str(claim.get("position", ""))
            if pos == log_room and npc_id not in people:
                result.append({"key": "log:%s:%s" % [str(clue.get("id", "")), npc_id], "kind": "log", "targets": [npc_id],
                    "detail": "%s|eun %s에 있었다고 했지만, %s에 이름이 없다." % [name_of(npc_id), room_name(log_room), str(clue.get("title", ""))]})
            elif pos != log_room and npc_id in people:
                result.append({"key": "presence:%s:%s" % [str(clue.get("id", "")), npc_id], "kind": "log_presence", "targets": [npc_id],
                    "detail": "%s|eun %s에 있었다고 했지만, %s에는 %s에 있었던 것으로 찍혀 있다." % [name_of(npc_id), room_name(pos), str(clue.get("title", "")), room_name(log_room)]})
    var ids: Array = known_claims.keys()
    ids.sort()
    for a_index in range(ids.size()):
        for b_index in range(a_index + 1, ids.size()):
            var a := str(ids[a_index])
            var b := str(ids[b_index])
            var claim_a: Dictionary = known_claims[a]
            var claim_b: Dictionary = known_claims[b]
            var a_mates: Array = claim_a.get("companions", [])
            var b_mates: Array = claim_b.get("companions", [])
            var same_place := str(claim_a.get("position", "")) == str(claim_b.get("position", ""))
            if same_place and b not in a_mates and a not in b_mates:
                result.append({"key": "place:%s:%s" % [a, b], "kind": "witness", "targets": [a, b],
                    "detail": "%s|wa %s 모두 %s에 있었다고 했지만, 서로를 보지 못했다고 한다." % [name_of(a), name_of(b), room_name(str(claim_a.get("position", "")))]})
            elif (b in a_mates and a not in b_mates) or (a in b_mates and b not in a_mates) or ((b in a_mates or a in b_mates) and not same_place):
                result.append({"key": "mate:%s:%s" % [a, b], "kind": "companion", "targets": [a, b],
                    "detail": "%s|wa %s의 동행 진술이 서로 맞지 않는다." % [name_of(a), name_of(b)]})
    # Someone changing their own story is a separate kind of problem from their
    # story not matching a log, and 0.3.1 could not see it at all. This reads the
    # ledger rather than the single current claim, so "he said the engine room on
    # day one and the comms room today" becomes a thing the player can point at.
    for npc_id in roster:
        for conflict in AstraClaimLedger.self_conflicts(claim_ledger, npc_id):
            var a: Dictionary = conflict.get("a", {})
            var b: Dictionary = conflict.get("b", {})
            result.append({
                "key": "self:%s:%d:%d" % [npc_id, int(a.get("index", 0)), int(b.get("index", 0))],
                "kind": "changed_story", "targets": [npc_id],
                "detail": "%s|eun %s. DAY %d “%s” / DAY %d “%s”" % [
                    name_of(npc_id), str(conflict.get("reason", "")),
                    int(a.get("day", 1)), str(a.get("text", "")),
                    int(b.get("day", 1)), str(b.get("text", ""))
                ]
            })
    for item in manual_contradictions:
        result.append(item.duplicate(true))
    for item in result:
        item["public"] = public_contradiction_keys.has(str(item.get("key", "")))
        item["detail"] = _josa_inline(str(item.get("detail", "")))
    contradictions = result

# ---------------------------------------------------------------- social beats

# Somebody in the room notices what the investigator keeps doing and says so.
# Only fires when there is a real pattern to name, and the speaker is never the
# person being defended — being told "you always defend me" is not a challenge.
func _maybe_challenge_player(subject_id: String) -> void:
    var observers := living_crew_ids()
    if observers.is_empty() or rng.randf() > 0.55:
        return
    var speaker := ""
    for candidate in observers:
        if candidate == subject_id:
            continue
        # Noa keeps the records and Daren argues from patterns, so they notice
        # first; anyone can, but those two are likelier.
        if candidate in ["noa", "dax"]:
            speaker = candidate
            break
        if speaker == "":
            speaker = candidate
    if speaker == "":
        return
    var remark := player_pattern_remark(speaker)
    if remark.is_empty():
        return
    var key := "challenge_%s_%d" % [str(remark["target"]), day]
    if flags.has(key):
        return
    flags[key] = true
    var target_name := name_of(str(remark["target"]))
    var text := ""
    if str(remark["kind"]) == "defend":
        text = "탐사요원. %s 얘기가 나올 때마다 먼저 끼어드시는군요. 회의 %d번 모두요." % [target_name, int(remark["count"])]
    else:
        text = "탐사요원은 %s|eul %d번 지목했습니다. 다른 이름은 한 번도 나오지 않았습니다." % [target_name, int(remark["count"])]
    _feed_line(speaker, "player", text, "react")
    _record_beat("player_pattern", [speaker], "%s가 탐사요원의 행동 패턴을 지적했다." % name_of(speaker))

func _record_beat(beat_id: String, participants: Array, summary: String) -> void:
    if AstraSocialEvents.on_cooldown(social_beats, beat_id, day):
        return
    social_beats.append({"id": beat_id, "day": day, "who": participants.duplicate(), "summary": summary})

# ---------------------------------------------------------------- claim ledger

func _record_claim(speaker: String, kind: String, scope: String, text: String, data: Dictionary = {}) -> Dictionary:
    if text.strip_edges() == "":
        return {}
    var entry := AstraClaimLedger.make_entry(speaker, kind, day, phase, scope, text, data)
    return AstraClaimLedger.record(claim_ledger, entry)

# The investigator is in the record too. NPCs cite it when they push back on the
# player, which is what stops the meeting from being a one-way interrogation.
func record_player_claim(kind: String, text: String, data: Dictionary = {}) -> void:
    var entry := AstraClaimLedger.make_entry("player", kind, day, phase, AstraClaimLedger.SCOPE_PUBLIC, text, data)
    AstraClaimLedger.record(claim_ledger, entry)
    player_claims.append(entry)

func claim_history(npc_id: String) -> Array:
    return AstraClaimLedger.by_speaker(claim_ledger, npc_id)

func public_claim_history(npc_id: String) -> Array:
    return AstraClaimLedger.by_speaker(claim_ledger, npc_id, AstraClaimLedger.SCOPE_PUBLIC)

func search_claims(needle: String) -> Array:
    return AstraClaimLedger.search(claim_ledger, needle)

func changed_story(npc_id: String) -> Array:
    return AstraClaimLedger.self_conflicts(claim_ledger, npc_id)

# How often the player has publicly backed or attacked one person. An NPC that
# notices "you have defended Sena in all three meetings" is using this (§16).
func player_stance_on(target_id: String) -> Dictionary:
    var defended := 0
    var accused := 0
    for entry in player_claims:
        if str(entry.get("target", "")) != target_id:
            continue
        if str(entry.get("kind", "")) == AstraClaimLedger.KIND_DEFEND:
            defended += 1
        elif str(entry.get("kind", "")) == AstraClaimLedger.KIND_ACCUSE:
            accused += 1
    return {"defended": defended, "accused": accused}

# A one-line reason an NPC can say out loud about the player's behaviour, or ""
# when nothing stands out. NPCs never speak from this unless it is non-empty:
# no reason, no line (§39).
func player_pattern_remark(observer_id: String) -> Dictionary:
    var best_target := ""
    var best_count := 0
    var best_kind := ""
    for target_id in roster:
        var stance := player_stance_on(target_id)
        if int(stance["defended"]) >= 2 and int(stance["defended"]) > best_count:
            best_count = int(stance["defended"])
            best_target = target_id
            best_kind = "defend"
        if int(stance["accused"]) >= 3 and int(stance["accused"]) > best_count:
            best_count = int(stance["accused"])
            best_target = target_id
            best_kind = "accuse"
    if best_target == "" or observer_id == best_target:
        return {}
    return {"target": best_target, "kind": best_kind, "count": best_count}

# ---------------------------------------------------------------- meeting

func _open_meeting() -> void:
    meeting_feed.clear()
    if flags.has("calm"):
        var calmer := npc(str(flags["calm"]))
        if calmer != null and calmer.is_alive():
            _feed_line(calmer.id, "", "다들 잠깐만요. 서로를 몰아붙이기 전에 숨부터 고르고 시작해요.", "calm")
            for observer_id in living_crew_ids():
                for target_id in living_ids():
                    if observer_id == target_id:
                        continue
                    var member: AstraCrewMember = crew[observer_id]
                    var value := member.get_suspicion(target_id)
                    if calmer.is_null():
                        if crew[target_id].is_null():
                            member.add_suspicion(target_id, -0.15)
                    else:
                        member.suspicion[target_id] = lerpf(value, 0.3, 0.3)

    if not casualties.is_empty():
        var last: Dictionary = casualties[casualties.size() - 1]
        if int(last.get("day", 0)) == day - 1:
            var victim_id := str(last.get("id", ""))
            var mourner := ""
            var best := -9.0
            for npc_id in living_ids():
                if crew[npc_id].get_affinity(victim_id) > best:
                    best = crew[npc_id].get_affinity(victim_id)
                    mourner = npc_id
            if mourner != "":
                _feed_npc(mourner, "m_mourn", {"victim": name_of(victim_id)}, "mourn", victim_id)

    # Put every current alibi on the public ledger without forcing everyone to
    # recite it. The visible meeting is made of a few connected arguments; the
    # notebook still retains the complete facts for deduction.
    var speakers := living_ids()
    AstraCaseGenerator._shuffle(speakers,rng)
    for npc_id in speakers:
        if public_claims.has(npc_id):
            continue
        var claim := current_claim(npc_id)
        var companions: Array = claim.get("companions", [])
        var key := "m_alibi_with" if not companions.is_empty() else "m_alibi_alone"
        var params := {"pos":room_name(str(claim.get("position",""))),"mates":AstraJosa.join_names(_names(companions))}
        _record_claim(npc_id,AstraClaimLedger.KIND_POSITION,AstraClaimLedger.SCOPE_PUBLIC,AstraDialogue.line(npc_id,key,params,0),{"position":claim.get("position",""),"companions":companions})
        public_claims[npc_id] = true
        known_claims[npc_id] = {"position": str(claim.get("position", "")), "companions": companions.duplicate(), "day": day}

    var thread_budget := 1 if day <= 1 else 2
    if case_id in ["RED_SHIFT","LAST_LIGHT"] and day >= 2:
        thread_budget = 3
    var dispute_threads := _run_disputes(thread_budget)

    if flags.has("noa_public"):
        var key := str(flags["noa_public"])
        flags.erase("noa_public")
        for item in manual_contradictions:
            if str(item.get("key", "")) == key:
                var noa := npc(str(item.get("source", "")))
                var target := str(item.get("targets", [""])[0])
                if noa != null and noa.is_alive() and is_alive(target):
                    _feed_line(noa.id, target, "기록 하나 공개할게요. %s의 단말은 사건 시각에 진술한 장소에 접속한 적이 없어요." % name_of(target), "record")
                    public_contradiction_keys[key] = true
                    stats["public_contradictions"] = int(stats.get("public_contradictions", 0)) + 1
                    _crowd_shift(target, 0.18, noa.id)

    _recompute_contradictions()
    if dispute_threads < thread_budget:
        _suspicion_round(thread_budget - dispute_threads)
    _log("공개 회의 · 연결 대화 %d건" % meeting_feed.size())

# How many people may contradict each other out loud in one meeting.
#
# 0.3.1 ran every eligible dispute, which on a busy day meant six rebuttals on
# top of eight alibis. The suspicion model still *knows* about the rest — the
# crowd shifts either way — but it does not narrate all of them, because a
# player cannot weigh six arguments that arrived in the same breath (§18).
func _dispute_budget() -> int:
    if AstraCaseCatalog.is_calibration(case_id):
        return 1
    return 2 if day <= 1 else 3

func _run_disputes(thread_budget: int) -> int:
    var positions: Dictionary = truth.get("positions", {})
    var spoken := 0
    var last_speaker := ""
    for witness_id in living_ids():
        var witness: AstraCrewMember = crew[witness_id]
        var honest := not witness.is_null() and not _is_lying_about_claim(witness)
        if not honest:
            continue
        var witness_pos := str(positions.get(witness_id, ""))
        for target_id in living_ids():
            if target_id == witness_id or not public_claims.has(target_id):
                continue
            var claim := current_claim(target_id)
            var really_there := str(positions.get(target_id, "")) == witness_pos
            if really_there:
                continue
            var key := "%s>%s" % [witness_id, target_id]
            if disputes_done.has(key):
                continue
            var heard := str(claim.get("position", "")) == witness_pos
            var vouched: bool = witness_id in claim.get("companions", [])
            if not heard and not vouched:
                continue
            disputes_done[key] = true
            witness.add_suspicion(target_id, 0.2 if heard else 0.22)
            _crowd_shift(target_id, 0.06 if heard else 0.07, witness_id)
            meeting_pushers[witness_id] = float(meeting_pushers.get(witness_id, 0.0)) + 1.0
            # The model resolves every contradiction, but the visible meeting
            # stages only a few. Every staged challenge receives an immediate
            # answer from the person who was challenged.
            if spoken >= thread_budget or witness_id == last_speaker:
                continue
            var topic: String = "movement:" + target_id
            if heard:
                _feed_npc(witness_id, "m_dispute_absent", {"pos": room_name(witness_pos), "target": name_of(target_id)}, "dispute", target_id, "anchor", topic)
            else:
                _feed_npc(witness_id, "m_dispute_companion", {"target": name_of(target_id)}, "dispute", target_id, "anchor", topic)
            _mark_dispute_public(witness_id, target_id)
            var target := npc(target_id)
            if target != null and target.is_alive():
                _feed_npc(target_id, "m_react_accused_null" if target.is_null() else "m_react_accused_crew", {}, "defense", target_id, "response", topic)
                _extend_meeting_thread(witness_id, target_id, topic)
            spoken += 1
            last_speaker = target_id

    # Nulls can create a counter-claim, but it is staged under the same thread
    # budget and the accused crew member answers it immediately.
    for null_id in living_null_ids():
        var null_claim := current_claim(null_id)
        for crew_id in living_crew_ids():
            if not public_claims.has(crew_id):
                continue
            var crew_claim := current_claim(crew_id)
            if str(crew_claim.get("position", "")) != str(null_claim.get("position", "")) or crew_id in null_claim.get("companions", []):
                continue
            var key := "%s>%s" % [null_id, crew_id]
            if disputes_done.has(key):
                continue
            disputes_done[key] = true
            _crowd_shift(crew_id, 0.08, null_id)
            meeting_pushers[null_id] = float(meeting_pushers.get(null_id, 0.0)) + 1.0
            if spoken >= thread_budget or null_id == last_speaker:
                continue
            var topic: String = "movement:" + crew_id
            _feed_npc(null_id, "m_dispute_absent", {"pos": room_name(str(null_claim.get("position", ""))), "target": name_of(crew_id)}, "dispute", crew_id, "anchor", topic)
            _mark_dispute_public(null_id, crew_id)
            var target := npc(crew_id)
            if target != null and target.is_alive():
                _feed_npc(crew_id, "m_react_accused_crew", {}, "defense", crew_id, "response", topic)
                _extend_meeting_thread(null_id, crew_id, topic)
            spoken += 1
            last_speaker = crew_id
    return spoken

func _mark_dispute_public(a: String, b: String) -> void:
    var ids := [a, b]
    ids.sort()
    var first := str(ids[0])
    var second := str(ids[1])
    var claim_a := current_claim(first)
    var claim_b := current_claim(second)
    var same_place := str(claim_a.get("position", "")) == str(claim_b.get("position", ""))
    var listed: bool = second in claim_a.get("companions", []) or first in claim_b.get("companions", [])
    var key := ("mate:" if listed or not same_place else "place:") + first + ":" + second
    if not public_contradiction_keys.has(key):
        public_contradiction_keys[key] = true
        stats["public_contradictions"] = int(stats.get("public_contradictions", 0)) + 1

func _suspicion_round(max_threads: int) -> int:
    var speakers: Array = []
    for npc_id in living_ids():
        var top := top_suspect_of(npc_id)
        if str(top.get("target", "")) == "":
            continue
        speakers.append({"id": npc_id, "target": str(top["target"]), "value": float(top.get("value", 0.0)) + _stable_noise(npc_id) * 0.05, "reason": str(top.get("reason", "gut"))})
    speakers.sort_custom(func(a, b): return float(a["value"]) > float(b["value"]))
    var count := 0
    var last_speaker := _last_feed_speaker()
    for item in speakers:
        if count >= max_threads:
            break
        if float(item["value"]) < 0.34 and count > 0:
            break
        var speaker_id := str(item["id"])
        var target_id := str(item["target"])
        if speaker_id == last_speaker or target_id == "":
            continue
        var topic: String = "suspicion:" + target_id
        _feed_npc(speaker_id, "m_suspect", {"target": name_of(target_id), "reason": AstraDialogue.reason_text(str(item["reason"]))}, "suspect", target_id, "anchor", topic)
        var target := npc(target_id)
        if target != null and target.is_alive():
            _feed_npc(target_id, "m_react_accused_null" if target.is_null() else "m_react_accused_crew", {}, "defense", target_id, "response", topic)
            _extend_meeting_thread(speaker_id, target_id, topic)
        _crowd_shift(target_id, 0.05, speaker_id)
        meeting_pushers[speaker_id] = float(meeting_pushers.get(speaker_id, 0.0)) + 0.6
        last_speaker = target_id
        count += 1
    return count

func _last_feed_speaker() -> String:
    if meeting_feed.is_empty():
        return ""
    return str(meeting_feed[meeting_feed.size() - 1].get("speaker", ""))

func _crowd_shift(target_id: String, amount: float, speaker_id: String) -> void:
    for observer_id in living_ids():
        if observer_id == target_id or observer_id == speaker_id:
            continue
        var observer: AstraCrewMember = crew[observer_id]
        var weight := 1.0 + observer.get_affinity(speaker_id) * 0.6 - observer.get_affinity(target_id) * 0.4
        observer.add_suspicion(target_id, amount * clampf(weight, 0.3, 1.6))

func _feed_npc(npc_id: String, key: String, params: Dictionary, kind: String, target_id: String, thread_role: String = "", topic_override: String = "") -> void:
    var text := AstraDialogue.line_fresh(npc_id, key, params, dialogue_recent, rng.randf())
    if text == "":
        return
    _feed_line(npc_id, target_id, text, kind, thread_role, topic_override)

const FEED_KIND_TO_CLAIM := {
    "alibi": AstraClaimLedger.KIND_POSITION,
    "dispute": AstraClaimLedger.KIND_WITNESS,
    "suspect": AstraClaimLedger.KIND_ACCUSE,
    "defense": AstraClaimLedger.KIND_DENY,
    "calm": AstraClaimLedger.KIND_DEFEND,
    "record": AstraClaimLedger.KIND_WITNESS
}

func can_meeting_speak(speaker_id: String) -> bool:
    return speaker_id == "player" or speaker_id in active_participants()

func _meeting_thread_type(topic: String, kind: String) -> String:
    if kind in ["record","dispute","alibi"] or topic.begins_with("clue:") or topic.begins_with("movement:"):
        return "FACT_THREAD"
    if kind in ["defense","suspect","react","mourn","calm"] or topic.begins_with("suspicion:"):
        return "RELATION_THREAD"
    return "DECISION_THREAD"

func _meeting_topic_label(topic: String, target_id: String, kind: String) -> String:
    if topic.begins_with("movement:"):
        return "%s의 동선" % name_of(topic.trim_prefix("movement:"))
    if topic.begins_with("suspicion:"):
        return "%s에 대한 의혹" % name_of(topic.trim_prefix("suspicion:"))
    if topic.begins_with("clue:"):
        return topic.trim_prefix("clue:")
    if target_id != "" and crew.has(target_id):
        return "%s의 진술" % name_of(target_id)
    match kind:
        "record": return "공개된 기록"
        "dispute": return "엇갈린 진술"
        "suspect": return "의심과 근거"
        _: return "현재 논점"

func _feed_line(speaker_id: String, target_id: String, text: String, kind: String, thread_role: String = "", topic_override: String = "") -> void:
    if not can_meeting_speak(speaker_id):
        push_error("ASTRA invariant: inactive meeting speaker " + speaker_id)
        return
    var entry_id := "meeting_%d_%03d" % [day, meeting_feed.size()]
    var topic: String = topic_override if topic_override != "" else (target_id if target_id != "" else kind)
    var thread_id := entry_id
    var reply_to := ""
    var transition := false
    var reply_context := ""
    if not meeting_feed.is_empty():
        var previous: Dictionary = meeting_feed[meeting_feed.size() - 1]
        var force_reply := thread_role in ["response", "support", "challenge", "clarify", "followup", "close"]
        if thread_role == "anchor":
            transition = true
        elif force_reply or str(previous.get("topic", "")) == topic or (thread_role == "" and kind in ["react", "defense", "dispute", "record"]):
            thread_id = str(previous.get("thread_id", entry_id))
            reply_to = str(previous.get("entry_id", ""))
            topic = str(previous.get("topic", topic)) if force_reply else topic
            var prev_speaker := str(previous.get("speaker", ""))
            reply_context = "탐사요원의 말에" if prev_speaker == "player" else ("%s의 말에" % name_of(prev_speaker))
        else:
            transition = true
    var role := thread_role
    if role == "":
        role = "anchor" if reply_to == "" else ("response" if kind == "defense" else "followup")
    var entry := {
        "entry_id": entry_id, "thread_id": thread_id, "reply_to": reply_to,
        "speaker": speaker_id, "target": target_id, "topic": topic,
        "thread_type": _meeting_thread_type(topic, kind),
        "topic_label": _meeting_topic_label(topic, target_id, kind),
        "topic_transition": transition, "reply_context": reply_context,
        "thread_role": role, "text": _josa_inline(text), "kind": kind, "day": day
    }
    meeting_feed.append(entry)
    if speaker_id != "player" and target_id != "" and kind in ["suspect","defense","dispute","react","record"]:
        var reason_code := "statement_response"
        if kind == "dispute" or kind == "record":
            reason_code = "public_statement_conflict"
        elif kind == "defense":
            reason_code = "public_verification" if public_verification(target_id) >= 0.5 else "relationship_support"
        elif kind == "suspect":
            reason_code = "accumulated_behavior"
        var meeting_trace := AstraDecisionModel.trace(
            speaker_id, "meeting_" + kind, target_id,
            [AstraDecisionModel.reason(reason_code, 0.7, str(entry.get("thread_id","")))], day
        )
        AstraDecisionModel.append_trace(flags, meeting_trace)
        if kind == "defense" and not voyage.is_empty():
            var tags: Array = voyage.get("memory_tags",[])
            var defense_tag := speaker_id + "_defended_" + target_id
            if defense_tag not in tags:
                tags.append(defense_tag)
            voyage["memory_tags"] = tags
    if speaker_id != "player" and FEED_KIND_TO_CLAIM.has(kind):
        var claim := current_claim(speaker_id) if kind == "alibi" else {}
        _record_claim(speaker_id, str(FEED_KIND_TO_CLAIM[kind]), AstraClaimLedger.SCOPE_PUBLIC, str(entry["text"]), {
            "target": target_id,
            "position": str(claim.get("position", "")),
            "companions": claim.get("companions", [])
        })
    notice.emit("meeting_line", entry)

func _thread_context_speaker(anchor_id: String, target_id: String) -> String:
    var claim := current_claim(target_id)
    var room_id := str(claim.get("position", ""))
    var specialists := {
        "engine": ["rho", "dax"],
        "comms": ["vale", "noa", "rho"],
        "security": ["sena", "noa"],
        "medical": ["mira", "lyra"],
        "garden": ["lyra", "mira"],
        "bridge": ["eli", "dax"],
        "archive": ["noa", "dax"],
        "lounge": ["mira", "noa"]
    }
    for candidate in specialists.get(room_id, ["noa", "dax"]):
        if candidate in active_participants() and candidate not in [anchor_id, target_id]:
            return str(candidate)
    for candidate in active_participants():
        if candidate in [anchor_id, target_id]:
            continue
        var observer := npc(str(candidate))
        if observer != null and (observer.get_affinity(anchor_id) >= 0.2 or observer.get_affinity(target_id) >= 0.2):
            return str(candidate)
    return ""

func _thread_context_line(speaker_id: String, target_id: String) -> String:
    var room := room_name(str(current_claim(target_id).get("position", "")))
    match speaker_id:
        "noa": return "기록 순서를 다시 맞춰 봐요. %s의 출입 시각부터 확인하면 됩니다." % name_of(target_id)
        "dax": return "말보다 시각을 먼저 맞추죠. %s 기록과 %s 로그가 같은 순서인지 보면 됩니다." % [name_of(target_id), room]
        "rho": return "그 구역 단말이면 접속 방식부터 보면 돼. 직접 갔는지 원격인지 흔적이 달라."
        "sena": return "출입 기록을 보죠. %s에 실제로 들어갔는지부터 확인하면 돼요." % room
        "mira": return "기억이 흔들릴 수는 있어요. 기록과 어긋난 시각부터 하나씩 확인해요."
        "lyra": return "결론부터 내리지 말고, 그 시간 전후 기록을 같이 봐요."
        "vale": return "신호 시각을 다시 들으면 접속이 먼저였는지 끊김이 먼저였는지 알 수 있어요."
        "eli": return "위치와 시각을 같이 놓죠. 둘 중 하나만 보면 같은 기록도 다르게 보여요."
    return "관련 기록부터 다시 확인하죠."

func _extend_meeting_thread(anchor_id: String, target_id: String, topic: String) -> void:
    var roll := _stable_noise("thread:%s:%s:%s:%d" % [anchor_id, target_id, topic, day])
    if roll < 0.58:
        return
    var helper := _thread_context_speaker(anchor_id, target_id)
    if helper == "":
        return
    _feed_line(helper, target_id, _thread_context_line(helper, target_id), "record", "clarify", topic)
    if roll >= 0.86 and anchor_id in active_participants():
        _feed_line(anchor_id, target_id, "좋아요. 그 기록부터 확인하고 판단하죠.", "react", "close", topic)


func present_clue(clue_id: String) -> Dictionary:
    var clue := clue_by_id(clue_id)
    if phase != "MEETING" or meeting_actions_left <= 0 or clue.is_empty() or not bool(clue.get("found", false)) or bool(clue.get("public", false)) or outcome != "":
        return {"ok": false}
    meeting_actions_left -= 1
    clue["public"] = true
    AstraKnowledgeModel.make_public(flags, clue_id, active_participants(), day)
    stats["presented"] = int(stats.get("presented", 0)) + 1
    var start := meeting_feed.size()
    _feed_line("player", "", "단서를 공개합니다. ‘%s’ — %s" % [str(clue.get("title", "")), str(clue.get("text", ""))], "player")
    var kind := str(clue.get("kind", ""))
    match kind:
        "access_log":
            var log_room := str(clue.get("log_room", ""))
            var people: Array = clue.get("log_people", [])
            for npc_id in living_ids():
                if not public_claims.has(npc_id):
                    continue
                var pos := str(current_claim(npc_id).get("position", ""))
                if pos == log_room and npc_id not in people:
                    _expose_log_lie(npc_id, "log:%s:%s" % [clue_id, npc_id])
                elif pos != log_room and npc_id in people:
                    _expose_log_lie(npc_id, "presence:%s:%s" % [clue_id, npc_id])
                elif pos == log_room and npc_id in people:
                    for observer_id in living_ids():
                        if observer_id != npc_id:
                            crew[observer_id].add_suspicion(npc_id, -0.12)
        "context", "op_record":
            var speaker := _first_living(["dax", "noa", "sena", "mira"])
            if speaker != "":
                _feed_npc(speaker, "evidence_context", {}, "react", "")
        _:
            var members: Array = clue.get("members", [])
            var weight := 1.0 if kind == "slip" else clampf(0.5 / maxf(1.0, float(members.size())) * 2.0, 0.12, 0.5)
            for observer_id in living_ids():
                var observer: AstraCrewMember = crew[observer_id]
                if observer.is_null():
                    continue
                for member_id in members:
                    if str(member_id) != observer_id and is_alive(str(member_id)):
                        observer.add_suspicion(str(member_id), weight * 0.5)
            var reacted := 0
            for member_id in members:
                if reacted >= 2 or not is_alive(str(member_id)):
                    continue
                _feed_npc(str(member_id), "m_clue_self", {}, "react", "")
                reacted += 1
    _recompute_contradictions()
    notice.emit("present", {"clue": clue})
    changed.emit()
    return {"ok": true, "lines": meeting_feed.slice(start)}

func _expose_log_lie(npc_id: String, key: String) -> void:
    if not public_contradiction_keys.has(key):
        public_contradiction_keys[key] = true
        stats["public_contradictions"] = int(stats.get("public_contradictions", 0)) + 1
    _crowd_shift(npc_id, 0.26, "player")
    var member: AstraCrewMember = crew[npc_id]
    member.adjust_stress(0.12)
    if member.is_null():
        _feed_npc(npc_id, "contra_deny", {}, "defense", "")
    else:
        _feed_npc(npc_id, "evidence_log_bad", {}, "defense", "")

func public_support(target_id: String) -> float:
    var total := 0.0
    for item in contradictions:
        if not bool(item.get("public", false)) or target_id not in item.get("targets", []):
            continue
        var kind := str(item.get("kind", ""))
        total += 0.7 if kind in ["log", "log_presence"] else (0.5 if kind == "terminal" else 0.35)
    for clue in clues:
        if not bool(clue.get("public", false)):
            continue
        var members: Array = clue.get("members", [])
        if target_id not in members or str(clue.get("kind", "")) == "access_log":
            continue
        total += 1.2 if str(clue.get("kind", "")) == "slip" else 0.9 / maxf(1.0, float(members.size()))
    return minf(total, 2.0)

func public_verification(target_id: String) -> float:
    var total := 0.0
    for clue in clues:
        if bool(clue.get("public", false)) and str(clue.get("kind", "")) == "access_log" and target_id in clue.get("log_people", []):
            if str(current_claim(target_id).get("position", "")) == str(clue.get("log_room", "")):
                total += 0.6
    var member := npc(target_id)
    if member != null and member.secret_revealed:
        total += 0.8
    return minf(total, 1.5)

func accuse(target_id: String) -> Dictionary:
    if phase != "MEETING" or meeting_actions_left <= 0 or not is_alive(target_id) or outcome != "":
        return {"ok": false}
    meeting_actions_left -= 1
    stats["accusations"] = int(stats.get("accusations", 0)) + 1
    accused_today[target_id] = true
    var start := meeting_feed.size()
    var support := public_support(target_id)
    var basis := "근거는 아직 제 직감뿐입니다."
    var reason := reason_for("", target_id)
    if support >= 0.25:
        basis = "근거는 %s입니다." % AstraDialogue.reason_text(reason)
    _feed_line("player", target_id, "%s, 당신을 지목합니다. %s" % [name_of(target_id), basis], "player")
    record_player_claim(AstraClaimLedger.KIND_ACCUSE, "%s|eul 지목했다. %s" % [name_of(target_id), basis], {"target": target_id})
    var target: AstraCrewMember = crew[target_id]
    _feed_npc(target_id, "m_react_accused_null" if target.is_null() else "m_react_accused_crew", {}, "defense", "")
    _maybe_challenge_player(target_id)
    target.adjust_stress(0.12)
    target.adjust_trust(-0.08)
    for observer_id in living_ids():
        if observer_id == target_id:
            continue
        var observer: AstraCrewMember = crew[observer_id]
        var delta := (0.05 + 0.26 * minf(1.0, support)) * (0.55 + observer.trust * 0.9)
        if observer.get_affinity(target_id) > 0.25:
            delta -= 0.05
        observer.add_suspicion(target_id, delta)
    if support < 0.25:
        for observer_id in living_ids():
            crew[observer_id].adjust_trust(-0.035)
        var doubter := _most_affine(target_id)
        if doubter != "":
            _feed_npc(doubter, "m_doubt", {"target": name_of(target_id)}, "react", target_id)
    else:
        var agreer := _most_suspicious_of(target_id)
        if agreer != "":
            _feed_npc(agreer, "m_agree", {"target": name_of(target_id)}, "react", target_id)
    _recompute_contradictions()
    notice.emit("accuse", {"target": target_id, "support": support})
    changed.emit()
    return {"ok": true, "support": support, "lines": meeting_feed.slice(start)}

func defend(target_id: String) -> Dictionary:
    if phase != "MEETING" or meeting_actions_left <= 0 or not is_alive(target_id) or outcome != "":
        return {"ok": false}
    meeting_actions_left -= 1
    stats["defenses"] = int(stats.get("defenses", 0)) + 1
    var start := meeting_feed.size()
    var target: AstraCrewMember = crew[target_id]
    var verification := public_verification(target_id)
    var against := public_support(target_id)
    if target.secret_revealed and not flags.has("secret_public_" + target_id):
        flags["secret_public_" + target_id] = true
        var true_pos := room_name(str(truth["positions"].get(target_id, "")))
        var reason_text := innocent_discrepancy_text()
        _feed_line("player", target_id, "%s의 진술 차이는 Null의 증거가 아닙니다. %s 실제 위치는 %s였습니다." % [name_of(target_id), reason_text, true_pos], "player")
        _feed_npc(target_id, "m_secret", {}, "defense", "")
        verification = public_verification(target_id)
        for observer_id in living_ids():
            if observer_id != target_id:
                crew[observer_id].add_suspicion(target_id, -0.25)
    elif verification >= 0.5:
        _feed_line("player", target_id, "%s의 알리바이는 기록으로 확인됐습니다. 몰아갈 근거가 없습니다." % name_of(target_id), "player")
    else:
        _feed_line("player", target_id, "%s|eul 몰아가기엔 아직 근거가 부족합니다. 서두르지 맙시다." % name_of(target_id), "player")
    record_player_claim(AstraClaimLedger.KIND_DEFEND, "%s|eul 변호했다." % name_of(target_id), {"target": target_id})
    _maybe_challenge_player(target_id)
    var effect := 1.0
    if against >= 0.8 and verification < 0.8:
        effect = 0.4
        for observer_id in living_ids():
            crew[observer_id].adjust_trust(-0.03)
        var doubter := _most_suspicious_of(target_id)
        if doubter != "":
            _feed_npc(doubter, "m_doubt", {"target": name_of(target_id)}, "react", target_id)
    else:
        var ally := _most_affine(target_id)
        if ally != "":
            _feed_npc(ally, "m_defend_agree", {"target": name_of(target_id)}, "react", target_id)
    for observer_id in living_ids():
        if observer_id == target_id:
            continue
        var observer: AstraCrewMember = crew[observer_id]
        observer.add_suspicion(target_id, -(0.06 + 0.22 * minf(1.0, verification)) * (0.55 + observer.trust * 0.9) * effect)
    target.adjust_trust(0.08)
    target.adjust_stress(-0.08)
    target.refresh_expression()
    _recompute_contradictions()
    notice.emit("defend", {"target": target_id})
    changed.emit()
    return {"ok": true, "lines": meeting_feed.slice(start)}

func _first_living(order: Array) -> String:
    for npc_id in order:
        if is_alive(str(npc_id)):
            return str(npc_id)
    var living := living_ids()
    return str(living[0]) if not living.is_empty() else ""

func _most_affine(target_id: String) -> String:
    var best := ""
    var best_value := -9.0
    for npc_id in living_ids():
        if npc_id == target_id:
            continue
        if crew[npc_id].get_affinity(target_id) > best_value:
            best_value = crew[npc_id].get_affinity(target_id)
            best = npc_id
    return best

func _most_suspicious_of(target_id: String) -> String:
    var best := ""
    var best_value := -9.0
    for npc_id in living_ids():
        if npc_id == target_id:
            continue
        if crew[npc_id].get_suspicion(target_id) > best_value:
            best_value = crew[npc_id].get_suspicion(target_id)
            best = npc_id
    return best

# ---------------------------------------------------------------- vote

func _sanitize_ballot(voter_id: String, target_id: String) -> String:
    if target_id == "":
        return ""
    if can_vote_for(voter_id, target_id):
        return target_id
    push_error("ASTRA invariant: invalid ballot %s -> %s" % [voter_id, target_id])
    var alternatives: Array = []
    for candidate in eligible_vote_targets():
        if can_vote_for(voter_id, str(candidate)):
            alternatives.append(str(candidate))
    if alternatives.is_empty():
        return ""
    alternatives.sort_custom(func(a, b): return crew[voter_id].get_suspicion(a) > crew[voter_id].get_suspicion(b))
    return str(alternatives[0])

func _vote_reason_items(voter_id: String, target_id: String) -> Array:
    if target_id == "":
        return []
    var result: Array = []
    var code := reason_for(voter_id, target_id)
    match code:
        "log":
            result.append(AstraDecisionModel.reason("public_log_conflict", 1.0))
        "disputed":
            result.append(AstraDecisionModel.reason("public_statement_conflict", 0.92))
        "clue2":
            result.append(AstraDecisionModel.reason("public_trace", 0.95))
        "clue":
            result.append(AstraDecisionModel.reason("public_trace", 0.72))
        "slip":
            result.append(AstraDecisionModel.reason("public_slip", 1.0))
        "victim":
            result.append(AstraDecisionModel.reason("victim_suspicion", 0.74))
        "accused":
            result.append(AstraDecisionModel.reason("meeting_accusation", 0.68))
        "alone":
            result.append(AstraDecisionModel.reason("unexplained_alone", 0.6))
        "friction":
            result.append(AstraDecisionModel.reason("relationship_friction", 0.5))
        _:
            result.append(AstraDecisionModel.reason("accumulated_behavior", 0.35))
    # Attach only evidence this voter can actually know. Public clues should
    # always pass this check; a clue shown only to another NPC must not.
    for clue in clues:
        if not bool(clue.get("public", false)) or target_id not in clue.get("members", []):
            continue
        var clue_id := str(clue.get("id",""))
        if clue_id != "" and AstraKnowledgeModel.knows(flags, voter_id, clue_id):
            result.append(AstraDecisionModel.reason("public_trace", 0.76, clue_id))
    return result

func _vote_decision_trace(voter_id: String, target_id: String) -> Dictionary:
    if target_id == "":
        return AstraDecisionModel.trace(voter_id, "vote", target_id, [AstraDecisionModel.reason("no_legal_vote_target", 1.0)], day)
    return AstraDecisionModel.trace(voter_id, "vote", target_id, _vote_reason_items(voter_id, target_id), day)

func _vote_reason(voter_id: String, target_id: String) -> String:
    return str(_vote_decision_trace(voter_id, target_id).get("explanation", "직접 근거가 부족해 기권"))
func vote_intentions() -> Dictionary:
    var result := {}
    var crew_votes := {}
    var voters := eligible_voters()
    var targets := eligible_vote_targets()
    for npc_id in voters:
        var member: AstraCrewMember = crew[npc_id]
        if member.is_null():
            continue
        var target := ""
        var best := -9.0
        for other in targets:
            if not can_vote_for(npc_id, str(other)):
                continue
            var relationship_weight := 0.18 if day <= 1 else (0.28 if day == 2 else 0.36)
            var noise_scale := 0.14 if day <= 1 else (0.08 if day == 2 else VOTE_NOISE)
            var evidence_attention := 0.45 + _stable_noise("evidence_attention:" + npc_id + ":" + str(other)) * 0.35
            var value := member.get_suspicion(other) - member.get_affinity(other) * relationship_weight + (_stable_noise(npc_id + other) - 0.5) * noise_scale + _public_trace_support(other) * evidence_attention
            if value > best:
                best = value
                target = str(other)
        # Low confidence is not an abstention. If a legal candidate exists, the
        # crew member makes the best decision available from their current
        # suspicion, relationship and public-evidence context.
        target = _sanitize_ballot(npc_id, target)
        result[npc_id] = target
        if target != "":
            crew_votes[target] = int(crew_votes.get(target, 0)) + 1
    for npc_id in voters:
        var member: AstraCrewMember = crew[npc_id]
        if not member.is_null():
            continue
        var partner := ""
        for other in living_null_ids():
            if other != npc_id:
                partner = other
        var target := scapegoat_for(npc_id)
        if partner != "" and float(crew_votes.get(partner, 0)) >= float(living_crew_ids().size()) * 0.5 and _stable_noise("bus" + npc_id) < 0.6:
            target = partner
        result[npc_id] = _sanitize_ballot(npc_id, target)
    return result

func vote_tally(include_player_target: String = "") -> Dictionary:
    var tally := {}
    var intentions := vote_intentions()
    for voter in intentions.keys():
        var target := _sanitize_ballot(str(voter), str(intentions[voter]))
        if target != "":
            tally[target] = int(tally.get(target, 0)) + 1
    if include_player_target != "" and include_player_target in eligible_vote_targets():
        tally[include_player_target] = int(tally.get(include_player_target, 0)) + PLAYER_VOTE_WEIGHT
    return tally

func cast_vote(target_id: String, theory_suspects: Array = [], confidence: int = 60) -> Dictionary:
    if phase != "VOTE" or vote_cast or outcome != "":
        return {"ok": false}
    if target_id != "" and target_id not in eligible_vote_targets():
        return {"ok": false}
    var voter_snapshot := eligible_voters().duplicate()
    var target_snapshot := eligible_vote_targets().duplicate()
    var intentions := vote_intentions()
    var errors: Array = []
    for voter in voter_snapshot:
        if not intentions.has(voter): errors.append({"voter":voter,"state":"unselected"})
        elif str(intentions[voter]) != "" and not can_vote_for(str(voter),str(intentions[voter])):
            errors.append({"voter":voter,"state":"error","target":intentions[voter]})
    for voter in intentions:
        if voter not in voter_snapshot: errors.append({"voter":voter,"state":"ineligible"})
    if not errors.is_empty():
        flags["ballot_error_058"] = errors
        notice.emit("hint",{"text":"투표 기록에 입력 오류가 있습니다. 투표는 확정되지 않았습니다."})
        changed.emit()
        return {"ok":false,"reason":"invalid_ballots","errors":errors}
    flags.erase("ballot_error_058")
    if not theory_suspects.is_empty(): submit_theory(theory_suspects,confidence)
    var reasons := {}
    var decision_traces := {}
    for voter in intentions.keys():
        var sanitized := _sanitize_ballot(str(voter), str(intentions[voter]))
        intentions[voter] = sanitized
        var trace := _vote_decision_trace(str(voter), sanitized)
        decision_traces[voter] = trace
        reasons[voter] = str(trace.get("explanation","직접 근거가 부족해 기권"))
        AstraDecisionModel.append_trace(flags, trace)
    var tally := {}
    for voter in intentions.keys():
        var target := str(intentions[voter])
        if target != "":
            tally[target] = int(tally.get(target, 0)) + 1
    if target_id != "":
        tally[target_id] = int(tally.get(target_id, 0)) + PLAYER_VOTE_WEIGHT
    var top := 0
    for candidate in tally.keys():
        top = maxi(top, int(tally[candidate]))
    var leaders: Array = []
    for candidate in tally.keys():
        if int(tally[candidate]) == top:
            leaders.append(str(candidate))
    var isolated := ""
    # NPC ballots are advisory evidence for the explorer's containment
    # decision. They still vote and expose their reasoning, but an explicit
    # player abstention cannot accidentally let the simulation solve the case
    # on the player's behalf. Containment therefore requires a direct player
    # vote plus a unique top tally.
    if target_id != "" and top > 0 and leaders.size() == 1:
        isolated = str(leaders[0])
    vote_cast = true
    last_vote = {
        "tally": tally, "intentions": intentions, "vote_reasons": reasons, "decision_traces": decision_traces,
        "player_target": target_id, "isolated": isolated, "top": top,
        "tie": leaders.size() > 1 and isolated == "",
        "voters":voter_snapshot,"eligible_targets":target_snapshot,
        "result_reason":"unique_highest" if isolated != "" else ("all_abstained" if tally.is_empty() else ("player_abstained" if target_id == "" else "tie")),
        "player_state":"abstain" if target_id == "" else "target","ballots":[]
    }
    for voter in voter_snapshot:
        var ballot_target := str(intentions.get(voter,""))
        var ballot_trace: Dictionary = decision_traces.get(voter,{})
        last_vote["ballots"].append({
            "voter":voter,"target":ballot_target,
            "state":"target" if ballot_target != "" else "abstain",
            "abstain":ballot_target == "","weight":1,
            "reason_code":str(ballot_trace.get("strongest_reason","")),
            "reason":str(reasons.get(voter,"")),
            "decision_trace":ballot_trace.duplicate(true)
        })
    last_vote["ballots"].append({
        "voter":"player","target":target_id,"state":last_vote["player_state"],
        "abstain":target_id == "","weight":PLAYER_VOTE_WEIGHT,
        "reason_code":"player_abstain" if target_id == "" else "player_target",
        "reason":"탐사요원이 직접 확정한 선택"
    })
    guide_completed("vote")
    if target_id == "": guide_completed("abstain")
    var vote_history: Array = Array(flags.get("vote_history_052", [])).duplicate(true)
    var vote_changes: Array = []
    if not vote_history.is_empty():
        var previous: Dictionary = vote_history[vote_history.size() - 1]
        var previous_intentions: Dictionary = previous.get("intentions", {})
        for voter in intentions:
            var before := str(previous_intentions.get(voter, ""))
            var after := str(intentions.get(voter, ""))
            if before != after:
                var trace: Dictionary = decision_traces.get(voter,{})
                var strongest := str(trace.get("strongest_reason","accumulated_behavior"))
                var reason_tag := "new_evidence"
                if strongest in ["relationship_friction","relationship_support"]:
                    reason_tag = "relationship_change"
                elif strongest == "accumulated_behavior":
                    reason_tag = "memory_change"
                elif strongest == "insufficient_evidence":
                    reason_tag = "uncertainty"
                var change := {
                    "voter":str(voter),"before":before,"after":after,
                    "reason":str(reasons.get(voter,"")),"reason_tag":reason_tag,
                    "strongest_reason":strongest
                }
                vote_changes.append(change)
                if not voyage.is_empty():
                    var relation_context := ""
                    if after != "" and crew.has(str(voter)) and crew.has(after):
                        relation_context = relationship_status(str(voter),after)
                    voyage["opinion_changes"].append({
                        "actor":str(voter),"before":before,"after":after,
                        "reason_tag":reason_tag,"reason":str(change["reason"]),
                        "strongest_reason":strongest,
                        "known_facts":AstraKnowledgeModel.known_facts(flags,str(voter)),
                        "relationship_context":relation_context,
                        "source":"vote","day":day
                    })
    last_vote["vote_changes"] = vote_changes
    vote_history.append({"day":day,"intentions":intentions.duplicate(true),"reasons":reasons.duplicate(true)})
    while vote_history.size() > 6:
        vote_history.pop_front()
    flags["vote_history_052"] = vote_history
    if isolated != "":
        var member: AstraCrewMember = crew[isolated]
        member.status = AstraCrewMember.STATUS_ISOLATED
        isolations.append({"day": day, "id": isolated, "votes": top, "role": member.role})
        _log("장기수면 격리 · %s (%d표)" % [member.display_name, top])
        last_vote["isolation_text"] = "보안 절차에 따라 장기수면 포드로 이동합니다. 사건이 끝날 때까지 행동·회의·투표에서 제외됩니다."
        last_vote["last_words"] = str(ISOLATED_LINES.get(isolated, "…"))
        _transcript(isolated, isolated, str(ISOLATED_LINES.get(isolated, "…")))
        _fallback_selected()
        for observer_id in living_ids():
            crew[observer_id].adjust_stress(0.04)
        if member.role != "NULL":
            flags["wrong_isolation_060"] = int(flags.get("wrong_isolation_060",0)) + 1
            flags["restricted_info_until_day"] = day + 1
            for observer_id in living_ids():
                crew[observer_id].adjust_trust(-0.05)
                crew[observer_id].adjust_stress(0.05)
        last_vote["aftermath"] = _build_containment_aftermath(isolated)
    else:
        _log("격리 없음 · " + vote_result_text())
        last_vote["aftermath"] = [{"kind":"decision","text":"표결은 끝났지만 누구도 포드로 이동하지 않았다. 현재 인원으로 다음 판단을 이어 간다."}]
    _check_end("vote")
    var aftermath: Array = last_vote.get("aftermath",[])
    if outcome == "WIN":
        aftermath.append({"kind":"ship","text":"격리 절차가 끝난 뒤, 현재 추적 중이던 조작 경보가 더 이상 이어지지 않는다."})
        if bool(voyage.get("story_resolution_seen",false)):
            aftermath.append({"kind":"mystery","text":"현재 사건은 멈췄다. 하지만 " + str(AstraVoyageContent.chapter(case_id).get("open_question",""))})
    elif isolated != "":
        aftermath.append({"kind":"ship","text":"포드가 잠긴 뒤에도 함선의 경계 상태는 해제되지 않는다. 아직 판단이 끝난 것은 아니다."})
    last_vote["aftermath"] = aftermath
    notice.emit("vote", last_vote)
    changed.emit()
    return {"ok": true, "result": last_vote}

func _check_end(stage: String) -> void:
    if outcome != "":
        return
    var nulls_left := living_null_ids().size()
    var crew_left := living_crew_ids().size()
    if nulls_left == 0:
        outcome = "WIN"
    elif nulls_left >= crew_left:
        outcome = "LOSE"
    elif stage == "vote" and day >= max_days:
        outcome = "TIMEOUT"
    if outcome != "":
        _log("사건 판정 · %s" % outcome)

# ---------------------------------------------------------------- night

func night_options() -> Dictionary:
    var protect: Array = active_participants()
    var secure: Array = []
    # The first night is a two-choice lesson: protect a person or preserve a
    # record. Area surveillance is introduced on the next night, while rest is
    # reserved for the later full social-deduction chapters.
    var secure_unlocked := not (case_id == "ECHO_WARD" and day <= 1)
    if secure_unlocked:
        for room_id in room_ids():
            if int(room_status(room_id).get("remaining", 0)) > 0:
                secure.append(room_id)
    var rest: Array = ["self"] if case_id in ["SILENT_ORBIT", "RED_SHIFT", "LAST_LIGHT"] else []
    return {"protect": protect, "secure": secure, "backup": room_ids(), "rest": rest}

func choose_night_action(kind: String, target: String) -> Dictionary:
    if phase != "NIGHT" or night_done or outcome != "":
        return {"ok": false}
    var options := night_options()
    if kind not in ["protect", "secure", "backup", "rest"] or target not in options.get(kind, []):
        push_error("ASTRA invariant: invalid night action %s -> %s" % [kind, target])
        return {"ok": false}
    night_plan = {"kind": kind, "target": target}
    _resolve_night()
    night_done = true
    notice.emit("night", night_result)
    changed.emit()
    return {"ok": true, "result": night_result}

func _resolve_night() -> void:
    var report: Array = []
    var kind := str(night_plan.get("kind", ""))
    var target := str(night_plan.get("target", ""))
    var result := {"victim": "", "protected": false, "tampered": "", "blocked_tamper": false, "audit": {}, "clues": []}

    if protocol == "AUDITOR":
        for index in range(isolations.size() - 1, -1, -1):
            var audited: AstraCrewMember = crew[str(isolations[index].get("id", ""))]
            if audited.audited:
                continue
            audited.audited = true
            var role_text := "Null이었다" if audited.is_null() else "무고한 승무원이었다"
            report.append(_josa_inline("감사관 생체 감사 · 격리된 %s|eun %s." % [audited.display_name, role_text]))
            result["audit"] = {"id": audited.id, "role": audited.role}
            _log("감사 결과 · %s = %s" % [audited.display_name, audited.role])
            break

    var patrol_guard := ""
    var patrol_is_null := false
    if flags.has("patrol"):
        var sena := npc(str(flags["patrol"]))
        if sena != null and sena.is_alive():
            if sena.is_null():
                patrol_is_null = true
            else:
                var best := -1.0
                for crew_id in living_crew_ids():
                    if crew_id == sena.id:
                        continue
                    if crew[crew_id].trust > best:
                        best = crew[crew_id].trust
                        patrol_guard = crew_id

    var victim := _choose_kill_target()
    if victim != "":
        var shelter := bool(flags.get("mission_shelter", false))
        var guarded := (kind == "protect" and target == victim) or patrol_guard == victim or shelter
        if shelter:
            flags.erase("mission_shelter")
        if guarded:
            var attackers := living_null_ids()
            var attacker := str(attackers[rng.randi_range(0, attackers.size() - 1)])
            stats["protects"] = int(stats.get("protects", 0)) + 1
            result["protected"] = true
            result["victim"] = victim
            var clue := _night_clue(attacker, "보호 기록 · 침입 흔적", "밤사이 누군가 %s의 선실 문을 강제로 열려다 달아났다. 문 패널에 %s 흔적이 남았다. 해당: %s.", victim)
            result["clues"].append(clue)
            if shelter and not (kind == "protect" and target == victim):
                report.append("비상 여과 장치가 습격을 감지해 선실을 봉쇄했다. 복구 임무 덕분에 생명을 지켰다.")
            elif patrol_guard == victim and not (kind == "protect" and target == victim):
                report.append(_josa_inline("순찰 중이던 %s|i %s의 선실 앞에서 침입자를 쫓아냈다." % [name_of(str(flags.get("patrol", ""))), name_of(victim)]))
            else:
                report.append(_josa_inline("누군가 %s의 선실 문을 강제로 열려다 달아났다. 보호가 통했다." % name_of(victim)))
        else:
            var member: AstraCrewMember = crew[victim]
            member.status = AstraCrewMember.STATUS_OFFLINE
            casualties.append({"day": day, "id": victim})
            _fallback_selected()
            result["victim"] = victim
            report.append(_josa_inline("밤사이 %s의 생체 신호가 끊겼다. 선내 의무 시스템은 아무 경보도 울리지 않았다." % member.display_name))
            for observer_id in living_crew_ids():
                for suspect_id in living_ids():
                    if suspect_id != observer_id:
                        crew[observer_id].add_suspicion(suspect_id, maxf(0.0, member.get_suspicion(suspect_id) - 0.3) * 0.2)
            for observer_id in living_ids():
                crew[observer_id].adjust_stress(0.08)
            if kind == "protect":
                report.append(_josa_inline("%s의 곁은 조용했다. Null은 다른 곳을 노렸다." % name_of(target)))

    var tamper_chance := float(case_data.get("tamper_chance", 0.5))
    if patrol_is_null:
        tamper_chance = 1.0
    var candidates: Array = []
    for clue in clues:
        if str(clue.get("kind", "")) == "trace" and not bool(clue.get("found", false)) and not bool(clue.get("destroyed", false)) and not bool(clue.get("decoy", false)) and str(clue.get("culprit", "")) in living_null_ids():
            candidates.append(clue)
    if not candidates.is_empty() and rng.randf() < tamper_chance:
        var clue: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
        var clue_room := str(clue.get("room", ""))
        if bool(flags.get("mission_backup", false)):
            result["blocked_tamper"] = true
            report.append("독립 배터리의 증거 백업이 작동했다. %s의 흔적 인멸을 막았다." % room_name(clue_room))
        elif kind == "backup" and target == clue_room:
            result["blocked_tamper"] = true
            report.append("%s의 원본을 오프라인에 보관했다. 삭제 명령이 들어왔지만 사본은 남았다." % room_name(clue_room))
        elif kind == "secure" and target == clue_room:
            result["blocked_tamper"] = true
            var night_clue := _night_clue(str(clue.get("culprit", "")), "감시 기록 · 접근 시도", "감시 드론이 밤사이 %s에 접근하던 인물을 포착했다. 흐릿한 영상에 %s 표식이 보인다. 해당: %s.", "", clue_room)
            result["clues"].append(night_clue)
            report.append("%s에 접근하려던 누군가가 감시 드론을 보고 물러났다." % room_name(clue_room))
        else:
            clue["destroyed"] = true
            stats["destroyed"] = int(stats.get("destroyed", 0)) + 1
            result["tampered"] = clue_room
            report.append("%s의 흔적 하나가 밤사이 지워졌다." % room_name(clue_room))
    elif kind == "secure":
        report.append("%s|eun 조용했다. 아무도 접근하지 않았다." % room_name(target))
    flags.erase("mission_backup")

    if kind == "backup":
        var recovered := false
        for record in clues:
            if str(record.get("room", "")) == target and str(record.get("kind", "")) in ["access_log", "op_record", "context"] and not bool(record.get("found", false)):
                _discover(record, false)
                result["clues"].append(record)
                report.append("백업 파일을 정리하다 읽지 못했던 기록을 복원했다: " + str(record.get("title", "")))
                recovered = true
                break
        if not recovered:
            report.append("%s의 기록을 봉인했다. 새 정보는 없지만 원본은 보존됐다." % room_name(target))
    elif kind == "rest":
        flags["rested_day"] = day + 1
        report.append("잠깐 눈을 붙였다. 다음 날에는 대화를 조금 더 이어 갈 수 있을 것 같다. 그동안 선실 밖을 지키지는 못했다.")
    morning_report = []
    for line in report:
        morning_report.append(_josa_inline(str(line)))
    result["report"] = morning_report.duplicate()
    night_result = result
    for line in morning_report:
        _log("밤 · " + str(line))
    _check_end("night")

func _choose_kill_target() -> String:
    var nulls := living_null_ids()
    if nulls.is_empty():
        return ""
    # On STORY the first night passes without a death. A new player who loses
    # somebody before they have learned what the night phase even is reads it as
    # the game punishing them for not knowing the rules yet (§24).
    if day <= 1 and AstraDifficulty.flag(difficulty, "first_night_safe"):
        return ""
    var best := ""
    var best_score := -99.0
    for crew_id in living_crew_ids():
        var member: AstraCrewMember = crew[crew_id]
        var threat := 0.0
        for null_id in nulls:
            threat = maxf(threat, member.get_suspicion(null_id))
            if disputes_done.has("%s>%s" % [crew_id, null_id]):
                threat += 0.25
        var score := threat * 1.2 + member.trust * 0.35 + rng.randf() * 0.3
        if score > best_score:
            best_score = score
            best = crew_id
    return best

func _night_clue(culprit: String, title: String, template: String, victim_id: String, room_id: String = "") -> Dictionary:
    var pair: Array = truth.get("trace_pairs", {}).get(culprit, [])
    var options: Array = []
    for category in AstraCrewCatalog.TRAIT_CATEGORIES.keys():
        if category not in pair:
            options.append(category)
    if options.is_empty():
        options = AstraCrewCatalog.TRAIT_CATEGORIES.keys()
    var category := str(options[rng.randi_range(0, options.size() - 1)])
    var group := AstraCrewCatalog.group_of(culprit, category)
    var members: Array = AstraCrewCatalog.group_members_in(category, group, roster)
    var text := ""
    if victim_id != "":
        text = template % [name_of(victim_id), AstraCrewCatalog.group_label(category, group), names_of(members)]
    else:
        text = template % [room_name(room_id), AstraCrewCatalog.group_label(category, group), names_of(members)]
    var clue := {
        "id": "N%02d" % (clues.size() + 1), "kind": "night", "room": room_id, "op": str(truth["null_ops"].get(culprit, "")),
        "title": title, "text": _josa_inline(text), "time": "DAY %d 밤" % day, "category": category, "group": group,
        "members": members.duplicate(), "culprit": culprit, "decoy": false, "planted": false, "source": "",
        "found": false, "destroyed": false, "public": false, "log_people": [], "found_day": 0
    }
    clues.append(clue)
    _discover(clue, false)
    return clue

# ---------------------------------------------------------------- result

func _finalize() -> void:
    var nulls: Array = truth.get("nulls", [])
    var null_isolated := 0
    var innocent_isolated := 0
    for item in isolations:
        if str(item.get("role", "")) == "NULL":
            null_isolated += 1
        else:
            innocent_isolated += 1
    var survivors := living_crew_ids().size()
    var rows: Array = []
    var base := 0
    match outcome:
        "WIN": base = 1500
        "TIMEOUT": base = 400
        _: base = 150
    rows.append(["사건 판정", base])
    rows.append(["Null 격리 ×%d" % null_isolated, null_isolated * 350])
    if innocent_isolated > 0:
        rows.append(["무고한 격리 ×%d" % innocent_isolated, -innocent_isolated * 150])
    rows.append(["생존 승무원 ×%d" % survivors, survivors * 80])
    rows.append(["확보한 단서 ×%d" % int(stats.get("clues_found", 0)), int(stats.get("clues_found", 0)) * 20])
    rows.append(["공개로 드러난 모순 ×%d" % int(stats.get("public_contradictions", 0)), int(stats.get("public_contradictions", 0)) * 40])
    if int(stats.get("slips", 0)) > 0:
        rows.append(["실언 유도 ×%d" % int(stats.get("slips", 0)), int(stats.get("slips", 0)) * 120])
    if int(stats.get("secrets", 0)) > 0:
        rows.append(["숨긴 사정 밝혀냄 ×%d" % int(stats.get("secrets", 0)), int(stats.get("secrets", 0)) * 80])
    if int(stats.get("protects", 0)) > 0:
        rows.append(["습격 저지 ×%d" % int(stats.get("protects", 0)), int(stats.get("protects", 0)) * 120])
    if bool(flags.get("mission_complete", false)):
        rows.append(["함선 복구 임무 완료", 180])
    var objective_rows := objectives()
    if bool(objective_rows[1].get("complete", false)):
        rows.append(["챕터 도전 목표 달성", 120])
    var theory := grade_theory()
    rows.append(["추리 보고서 %d점" % int(theory.get("grade", 0)), int(theory.get("grade", 0)) * 5])
    if outcome == "WIN":
        rows.append(["신속 해결 (DAY %d)" % day, maxi(0, max_days - day) * 150])
    var total := 0
    for row in rows:
        total += int(row[1])
    total = maxi(0, total)
    var rank := "D"
    if total >= 3600:
        rank = "S"
    elif total >= 2900:
        rank = "A"
    elif total >= 2100:
        rank = "B"
    elif total >= 1300:
        rank = "C"
    var truth_rows: Array = []
    for npc_id in roster:
        var claim: Dictionary = truth["claims"].get(npc_id, {})
        var member: AstraCrewMember = crew[npc_id]
        truth_rows.append({
            "id": npc_id, "role": member.role, "status": member.status,
            "true_position": room_name(str(truth["positions"].get(npc_id, ""))),
            "claim_position": room_name(str(claim.get("position", ""))),
            "lie": bool(claim.get("lie", false)), "misremembered": bool(claim.get("misremembered",false)),
            "innocent_reason": str(claim.get("innocent_reason","")),
            "herring": str(truth.get("herring", "")) == npc_id,
            "op": op_name(str(truth["null_ops"].get(npc_id, "")))
        })
    var title := ""
    var subtitle := ""
    match outcome:
        "WIN":
            title = "ASTRA 안정화"
            subtitle = "기록이 가리키는 %d명의 행동을 멈췄다. 그들이 기억하지 못하는 시간은 여전히 비어 있다." % null_count
        "TIMEOUT":
            title = "신호 두절"
            subtitle = "%d일이 지났지만 Null은 아직 선내에 있다. 기록만이 다음 조사로 남는다." % max_days
        _:
            title = "Null 장악"
            subtitle = "남은 승무원이 Null과 같은 수가 됐다. 선내 의사결정권이 무너졌다."
    final_report = {
        "outcome": outcome, "title": title, "subtitle": subtitle, "rows": rows, "total": total, "rank": rank,
        "nulls": nulls.duplicate(), "herring": str(truth.get("herring", "")), "truth": truth_rows,
        "theory": theory, "day": day, "null_isolated": null_isolated, "innocent_isolated": innocent_isolated,
        "survivors": survivors, "stats": stats.duplicate(),
        "mission_complete": bool(flags.get("mission_complete", false)), "mission": mission_status(),
        "objectives": objective_rows, "chapter": str(case_data.get("chapter", "")),
        "roster": roster.duplicate(), "difficulty": difficulty,
        "loop_summary": loop_summary(),
        "post_mortem": post_mortem(),
        "story": str(case_data.get("story_outro", ""))
    }

# What made *this* run different from the last one, in sentences rather than in
# numbers. Two runs of the same case with the same outcome should not produce
# the same paragraph (§92).
func loop_summary() -> Dictionary:
    var lines: Array = []
    for beat in social_beats:
        var text := str(beat.get("summary", ""))
        if text != "" and not (text in lines):
            lines.append(text)
    for npc_id in roster:
        var taken_back := AstraClaimLedger.retraction_count(claim_ledger, npc_id)
        if taken_back > 0:
            lines.append("%s 회의에서 자기 말을 %d번 되돌렸다." % [AstraJosa.eun(name_of(npc_id)), taken_back])
    for item in isolations:
        var isolated_id := str(item.get("id", ""))
        lines.append("%s 격리됐다. 실제 역할은 %s였다." % [AstraJosa.i(name_of(isolated_id)), "Null" if str(item.get("role", "")) == "NULL" else "승무원"])
    for victim in casualties:
        var victim_id := str(victim.get("id", victim)) if victim is Dictionary else str(victim)
        lines.append("%s 밤을 넘기지 못했다." % AstraJosa.eun(name_of(victim_id)))
    while lines.size() > 6:
        lines.remove_at(lines.size() - 1)
    return {
        "case_id": case_id, "day": day, "outcome": outcome, "seed": seed_value,
        "difficulty": difficulty, "lines": lines
    }

# A loss should teach. Rather than printing the answer and stopping, this lists
# the specific things that were true and findable: which lie was innocent, which
# clue was never picked up, which single vote flipped the day (§29).
func post_mortem() -> Dictionary:
    var missed: Array = []
    for clue in clues:
        if bool(clue.get("found", false)) or bool(clue.get("decoy", false)):
            continue
        if str(clue.get("culprit", "")) == "" and str(clue.get("kind", "")) != "access_log":
            continue
        missed.append({"title": str(clue.get("title", "")), "room": room_name(str(clue.get("room", "")))})
    var herring_id := str(truth.get("herring", ""))
    var innocent_lie := ""
    if herring_id != "":
        var reason := innocent_discrepancy_reason()
        innocent_lie = "%s Null이 아니었다. %s" % [AstraJosa.eun(name_of(herring_id)), innocent_discrepancy_text(reason)]
    var decisive := ""
    if not last_vote.is_empty():
        var tally: Dictionary = last_vote.get("tally", {})
        var sorted_ids: Array = tally.keys()
        sorted_ids.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
        if sorted_ids.size() >= 2 and int(tally[sorted_ids[0]]) - int(tally[sorted_ids[1]]) <= PLAYER_VOTE_WEIGHT:
            decisive = "마지막 투표는 %s표 차였다. 탐사요원의 표가 결과를 갈랐다." % str(int(tally[sorted_ids[0]]) - int(tally[sorted_ids[1]]))
    return {"missed_clues": missed.slice(0, 4), "innocent_lie": innocent_lie, "decisive_vote": decisive}

func grade_theory() -> Dictionary:
    if theories.is_empty():
        return {"grade": 0, "label": "보고서 미제출", "matched": 0, "suspects": [], "confidence": 0, "day": 0}
    var theory: Dictionary = theories[theories.size() - 1]
    var nulls: Array = truth.get("nulls", [])
    var suspects: Array = theory.get("suspects", [])
    var matched := 0
    for suspect in suspects:
        if suspect in nulls:
            matched += 1
    var evidence := 0
    for suspect in suspects:
        for clue in clues:
            if bool(clue.get("found", false)) and str(clue.get("culprit", "")) == str(suspect) and not bool(clue.get("decoy", false)) and not bool(clue.get("planted", false)) and suspect in clue.get("members", []):
                evidence += 5
        for item in contradictions:
            if str(suspect) in item.get("targets", []):
                evidence += 3
    evidence = mini(20, evidence) if matched > 0 else mini(8, evidence)
    var confidence := int(theory.get("confidence", 60))
    var calibration := 0
    if matched == null_count and confidence >= 70:
        calibration = 10
    elif matched == 0 and confidence >= 70:
        calibration = -10
    elif matched == 1 and confidence >= 40 and confidence <= 70:
        calibration = 5
    var day_factor: float = float(THEORY_DAY_FACTORS[clampi(int(theory.get("day", 1)), 0, THEORY_DAY_FACTORS.size() - 1)])
    var grade := clampi(int(round((matched * (70.0 / null_count) + evidence + calibration) * day_factor)), 0, 100)
    var label := "단편적 추리"
    if grade >= 90:
        label = "S · 완벽한 관측"
    elif grade >= 75:
        label = "A · 날카로운 추리"
    elif grade >= 55:
        label = "B · 설득력 있는 가설"
    elif grade >= 35:
        label = "C · 절반의 진실"
    return {"grade": grade, "label": label, "matched": matched, "suspects": suspects.duplicate(), "confidence": confidence, "day": int(theory.get("day", 1))}

# ---------------------------------------------------------------- optional AI performance

# Replaces a rule-based line in the transcript with a validated AI performance.
# Only wording changes; no state, clue or relationship value is touched.
func apply_ai_line(npc_id: String, rule_line: String, utterance: String) -> void:
    var clean := utterance.strip_edges()
    if clean == "" or not transcripts.has(npc_id):
        return
    var history: Array = transcripts[npc_id]
    for index in range(history.size() - 1, -1, -1):
        var entry: Dictionary = history[index]
        if str(entry.get("speaker", "")) == npc_id and str(entry.get("text", "")) == _josa_inline(rule_line):
            entry["text"] = clean
            entry["ai"] = true
            changed.emit()
            return

func build_ai_context(npc_id: String, intent: String, rule_line: String) -> Dictionary:
    var member := npc(npc_id)
    if member == null:
        return {}
    var allowed_facts := {}
    var refs: Array[String] = []
    for clue in found_clues():
        refs.append(str(clue.get("id", "")))
        allowed_facts[str(clue.get("id", ""))] = str(clue.get("text", ""))
    var turns: Array = []
    var history: Array = transcripts.get(npc_id, [])
    for index in range(maxi(0, history.size() - 10), history.size()):
        turns.append(history[index].duplicate())
    var relationships := {}
    for other in roster:
        if other != npc_id:
            relationships[other] = member.get_affinity(other)
    return {
        "npc": {
            "id": member.id, "name": member.display_name, "job": member.job,
            "speech_style": str(member.info.get("speech_note", "")),
            "social_goal": str(member.info.get("social_goal", "")),
            "pressure_response": str(member.info.get("pressure_response", "")),
            "emotion": {"stress": member.stress}, "trust_player": member.trust
        },
        "scene": {"phase": phase, "situation": "player_dialogue", "intent": intent, "day": day, "rule_based_line": rule_line},
        "allowed_fact_refs": refs,
        "allowed_facts": allowed_facts,
        "allowed_target_ids": living_ids(),
        "known_evidence": refs.duplicate(),
        "relationships": relationships,
        "recent_turns": turns
    }

# 0.3.1 additions live in the same authoritative model. Optional state resides
# in the existing flags dictionary, so v1 snapshots require no format change.
func set_tutorial(enabled: bool) -> void:
    flags["tutorial"] = enabled
    changed.emit()

func tutorial_active() -> bool:
    return bool(flags.get("tutorial", false)) and day == 1

func time_caption() -> String:
    match phase:
        "INVESTIGATION": return "이동은 무료"
        "INTERROGATION": return "기록을 보여 주거나 말을 듣는다"
        "MEETING": return "같은 증거를 함께 확인한다"
        "VOTE": return "동률이면 격리 보류"
        "NIGHT": return "오늘 밤 한 가지 행동"
        "RESULT": return "다음 항해에 남은 기록"
    return "함께 확인할 기록"

func investigation_points(room_id: String) -> Array:
    var specs := [
        {"id": "records", "label": "제어 단말", "detail": "실행 명령과 사건 기록을 복구한다", "icon": "comms_03", "kinds": ["op_record", "context"]},
        {"id": "traces", "label": "현장 흔적", "detail": "패널과 주변에 남은 물리 흔적을 찾는다", "icon": "tools_01", "kinds": ["trace"]},
        {"id": "access", "label": "출입 기록", "detail": "사건 시각의 동선을 확인한다", "icon": "evidence_11", "kinds": ["access_log"]}
    ]
    var result: Array = []
    for spec in specs:
        var exists := false
        var pending := false
        for clue in clues:
            if str(clue.get("room", "")) == room_id and str(clue.get("kind", "")) in spec["kinds"]:
                exists = true
                pending = pending or (not bool(clue.get("found", false)) and not bool(clue.get("destroyed", false)))
        if exists:
            var point: Dictionary = spec.duplicate(true)
            var room_key: String = AstraArt.ROOM_ART.get(room_id,"bridge")
            var logical_room: String = {"bridge":"comms", "medical":"medbay", "engine":"engine", "security":"security", "archive":"archive", "garden":"garden", "lounge":"lounge", "breach":"security"}.get(room_key,"comms")
            var object_points: Array = AstraVoyageContent.ROOMS[logical_room]["points"]
            var point_index := ["records","traces","access"].find(str(spec["id"]))
            var object: Array = object_points[point_index]
            point["label"] = object[1]
            point["position"] = Vector2(float(object[2]),float(object[3]))
            point["available"] = pending and investigation_ap > 0 and phase == "INVESTIGATION" and outcome == ""
            point["searched"] = not pending
            result.append(point)
    return result

func inspect_point(room_id: String, point_id: String) -> Dictionary:
    for point in investigation_points(room_id):
        if str(point["id"]) != point_id or not bool(point["available"]):
            continue
        var candidates: Array = []
        for clue in clues:
            if str(clue.get("room", "")) == room_id and str(clue.get("kind", "")) in point["kinds"] and not bool(clue.get("found", false)) and not bool(clue.get("destroyed", false)):
                candidates.append(clue)
        if not candidates.is_empty():
            investigation_ap -= 1
            flags["tutorial_examined"] = true
            var clue: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
            _discover(clue, true)
            return clue
    return {}

func hypotheses() -> Array:
    return flags.get("hypotheses", []).duplicate(true)

func link_hypothesis(clue_id: String, npc_id: String, op_id: String, relation: String) -> bool:
    var clue := clue_by_id(clue_id)
    if outcome != "" or clue.is_empty() or not bool(clue.get("found", false)) or not crew.has(npc_id) or op_data(op_id).is_empty() or relation not in ["관련", "모순", "무관"]:
        return false
    var links := hypotheses()
    var link := {"clue": clue_id, "npc": npc_id, "op": op_id, "relation": relation}
    if link in links or links.size() >= 24:
        return false
    links.append(link)
    flags["hypotheses"] = links
    changed.emit()
    return true

func remove_hypothesis(index: int) -> void:
    var links := hypotheses()
    if index >= 0 and index < links.size():
        links.remove_at(index)
        flags["hypotheses"] = links
        changed.emit()

func present_hypothesis(index: int) -> Dictionary:
    var links := hypotheses()
    if phase != "MEETING" or outcome != "" or meeting_actions_left <= 0 or index < 0 or index >= links.size():
        return {"ok": false}
    var link: Dictionary = links[index]
    var target := str(link["npc"])
    var key := "hypothesis_%s_%s_%s_%s" % [str(link["clue"]),target,str(link["op"]),str(link["relation"])]
    if not is_alive(target) or int(flags.get(key,0)) == day:
        return {"ok": false}
    var clue := clue_by_id(str(link["clue"]))
    if not bool(clue.get("found",false)):
        return {"ok": false}
    flags[key] = day
    var start := meeting_feed.size()
    if not bool(clue.get("public",false)):
        present_clue(str(link["clue"]))
    else:
        meeting_actions_left -= 1
    _feed_line("player",target,"‘%s’에 대한 제 해석입니다. %s · %s · %s." % [str(clue.get("title","")),name_of(target),op_name(str(link["op"])),str(link["relation"])],"player")
    var in_window: bool = not clue.has("minute") or (int(clue["minute"]) >= int(case_data["window_start"]) and int(clue["minute"]) <= int(case_data["window_end"]))
    var relevant: bool = target in clue.get("members",[]) and str(clue.get("op","")) == str(link["op"]) and in_window
    if str(link["relation"]) == "모순":
        var claim: Dictionary = known_claims.get(target,{})
        var room := str(clue.get("log_room",""))
        var people: Array = clue.get("log_people",[])
        relevant = str(clue.get("kind","")) == "access_log" and not claim.is_empty() and ((str(claim.get("position","")) != room and target in people) or (str(claim.get("position","")) == room and target not in people))
    elif str(link["relation"]) == "무관":
        relevant = str(clue.get("kind","")) == "trace" and not in_window
    _crowd_shift(target,(0.10 if str(link["relation"]) != "무관" else -0.10) if relevant else 0.0,"player")
    _feed_npc(target,"m_clue_self" if relevant and str(link["relation"]) != "무관" else "evidence_context",{},"react","")
    if not relevant:
        for id in living_ids():
            crew[id].adjust_trust(-0.02)
        var speaker := _first_living(["noa","dax","sena"])
        _feed_npc(speaker,"m_doubt",{"target":name_of(target)},"react",target)
    _log("회의에서 가설 제시 · " + name_of(target))
    changed.emit()
    return {"ok":true,"lines":meeting_feed.slice(start)}

# ---------------------------------------------------------------- 0.4.0 guidance

# One sentence naming the single next useful action, plus the rooms worth
# looking at. During calibration it is an instruction; afterwards it softens to
# a suggestion and the player can ignore it entirely (§11).
func current_objective() -> Dictionary:
    var binding := AstraCaseCatalog.is_calibration(case_id)
    var text := ""
    var action_label := ""
    var action_target := ""
    var rooms: Array = []
    var flow := AstraCaseCatalog.phase_flow(case_id)
    var next_phase := _next_story_phase()
    match phase:
        "BRIEFING":
            text = "사건 시각과 지금 확인할 기록을 먼저 보세요." if day == 1 else "밤사이 무슨 일이 있었는지 확인하세요."
            action_label = advance_label()
        "INVESTIGATION":
            rooms = recommended_rooms()
            var spec := chapter_objective_spec()
            if found_clues().is_empty():
                text = str(spec.get("description", "핵심 기록을 확인하세요."))
                if not rooms.is_empty():
                    action_target = str(rooms[0])
            elif investigation_ap > 0:
                text = str(spec.get("description", "남은 핵심 기록을 확인하세요."))
                if not rooms.is_empty():
                    action_target = str(rooms[0])
            else:
                text = "조사를 마쳤습니다. 이제 동료에게 확인하세요."
                action_label = advance_label()
        "INTERROGATION":
            if not pending_event.is_empty():
                action_target = str(pending_event.get("npc_id", ""))
                text = "%s|i 따로 할 말이 있습니다." % name_of(action_target)
            elif known_claims.is_empty():
                text = "한 사람에게 방금 확인한 기록에 대해 물어보세요."
            else:
                var unheard := ""
                for npc_id in living_ids():
                    if not known_claims.has(npc_id):
                        unheard = npc_id
                        break
                if unheard != "" and talk_ap > 0:
                    action_target = unheard
                    text = "%s에게 확인한 기록에 대해 물어보세요." % name_of(unheard)
                elif not contradictions.is_empty() and talk_ap > 0:
                    action_target = str(contradictions[0].get("targets", [""])[0])
                    text = "%s의 말과 기록이 어긋납니다. 그 지점을 짚어 보세요." % name_of(action_target)
                else:
                    text = "기록과 진술 확인을 마쳤습니다." if next_phase == "RESULT" else ("짧은 공개 확인으로 넘어갈 준비가 됐습니다." if next_phase == "MEETING" else "다음 판단 단계로 넘어갈 준비가 됐습니다.")
                    action_label = advance_label()
        "MEETING":
            if meeting_actions_left > 0:
                text = "현재 논점을 듣고, 필요한 경우에만 증거나 모순으로 개입하세요."
            else:
                text = "공개 확인을 마쳤습니다. 사건을 정리하세요." if next_phase == "RESULT" else "회의 개입을 마쳤습니다. 장기수면 격리 판단으로 넘어가세요."
                action_label = advance_label()
        "VOTE":
            text = "근거가 충분한 대상을 고르거나 아직 격리하지 않음을 선택하세요." if not vote_cast else "개표 결과와 각 승무원의 이유를 확인하세요."
            action_label = "투표 확정" if not vote_cast else advance_label()
        "NIGHT":
            text = "오늘 밤 지킬 사람이나 기록을 하나 선택하세요." if not night_done else "밤 행동을 마쳤습니다. 아침 보고로 넘어가세요."
            action_label = advance_label() if night_done else ""
        "RESULT":
            text = "이번에 알게 된 것과 다음 기록을 확인하세요."
    return {
        "text": _josa_inline(text),
        "description": _josa_inline(text),
        "action_label": action_label,
        "action_target": action_target,
        "rooms": rooms,
        "binding": binding,
        "phase_flow": flow
    }

# Rooms the case actually hinges on. Shown only when the difficulty asks for it
# — the player is never blocked from going anywhere else (§11).
func recommended_rooms() -> Array:
    if not AstraDifficulty.flag(difficulty, "recommend_rooms") and not AstraCaseCatalog.is_calibration(case_id):
        return []
    var wanted: Array = []
    for op in case_data.get("ops", []):
        var room_id := str(op.get("room", ""))
        if int(room_status(room_id).get("remaining", 0)) > 0:
            wanted.append(room_id)
    for room_id in room_ids():
        if wanted.size() >= 2:
            break
        if room_id in wanted:
            continue
        if int(room_status(room_id).get("remaining", 0)) > 0:
            wanted.append(room_id)
    return wanted

func difficulty_name() -> String:
    return AstraDifficulty.mode_name(difficulty)

# Only the people this case actually uses, in catalog order.
func active_roster() -> Array:
    return roster.duplicate()

func status_label(npc_id: String) -> String:
    var member := npc(npc_id)
    if member == null:
        return "알 수 없음"
    match member.status:
        AstraCrewMember.STATUS_ACTIVE: return "정상"
        AstraCrewMember.STATUS_ISOLATED: return "장기수면 격리"
        AstraCrewMember.STATUS_OFFLINE: return "생체 신호 두절"
    return str(member.status)

func status_counts() -> Dictionary:
    var result := {"active":0, "isolated":0, "offline":0}
    for npc_id in roster:
        var member := npc(str(npc_id))
        if member == null: continue
        match member.status:
            AstraCrewMember.STATUS_ACTIVE: result["active"] += 1
            AstraCrewMember.STATUS_ISOLATED: result["isolated"] += 1
            AstraCrewMember.STATUS_OFFLINE: result["offline"] += 1
    return result

func null_total() -> int:
    return null_count

# The two people the room is most likely to isolate each get one last sentence
# before the ballot, and then there is a pause. 0.3.1 went from the meeting
# straight into a tally; the moment where the player thinks "what if I am wrong"
# had nowhere to happen (§19).
func final_statements() -> Array:
    if phase != "VOTE" or vote_cast:
        return []
    var ranked: Array = living_ids().duplicate()
    ranked.sort_custom(func(a, b): return crowd_suspicion(a) > crowd_suspicion(b))
    var statements: Array = []
    for npc_id in ranked.slice(0, 2):
        var member := npc(str(npc_id))
        if member == null:
            continue
        var key := "m_react_accused_null" if member.is_null() else "m_react_accused_crew"
        var text := AstraDialogue.line_fresh(member.id, key, {}, dialogue_recent, _stable_noise("final:%s:%d" % [member.id, day]))
        if text == "":
            text = "할 말은 다 했습니다."
        statements.append({"id": member.id, "name": member.display_name, "text": _josa_inline(text)})
    return statements

# What the player can still spend this phase, for the budget box in the header.
# Empty means this phase has no budget and the box is hidden rather than showing
# a meaningless zero.
func action_budget() -> Dictionary:
    match phase:
        "INVESTIGATION":
            return {"label": "조사", "left": investigation_ap, "max": investigation_ap_max()}
        "INTERROGATION":
            return {"label": "질문", "left": talk_ap, "max": talk_ap_max()}
        "MEETING":
            return {"label": "발언", "left": meeting_actions_left, "max": meeting_actions_max()}
    return {}

# True when there is nothing useful left to do in this phase, so the UI can
# light up the "next" button instead of leaving the player wondering whether
# they have missed something (§ player feedback).
func phase_exhausted() -> bool:
    match phase:
        "INVESTIGATION":
            if investigation_ap > 0:
                for room_id in room_ids():
                    if int(room_status(room_id).get("remaining", 0)) > 0:
                        return false
                var mission := mission_status()
                return not bool(mission.get("available", false))
            return true
        "INTERROGATION":
            if not pending_event.is_empty():
                return false
            return talk_ap <= 0
        "MEETING":
            return meeting_actions_left <= 0
        "VOTE":
            return vote_cast
        "NIGHT":
            return night_done
        "BRIEFING":
            return true
    return false

# A sentence describing the hour and the mood, so the player can tell a quiet
# morning from the last night of the case without reading a number.
func situation_line() -> String:
    var parts: Array = []
    parts.append(time_caption())
    var counts := status_counts()
    parts.append("활동 중 %d명" % int(counts["active"]))
    if max_days > 1:
        var left := max_days - day
        if left <= 0:
            parts.append("오늘이 마지막 날")
        else:
            parts.append("판단할 날 %d일 남음" % (left + 1))
    if int(counts["isolated"]) > 0:
        parts.append("장기수면 격리 %d명" % int(counts["isolated"]))
    if int(counts["offline"]) > 0:
        parts.append("생체 신호 두절 %d명" % int(counts["offline"]))
    return "  ·  ".join(PackedStringArray(parts))

# ---------------------------------------------------------------- who thinks what

# Who this person is watching and who they lean on, with the reason in words.
#
# The suspicion and affinity numbers have always existed; 0.3.1 only ever
# surfaced them as behaviour, which is right for the meeting but useless when
# the player is trying to hold eight relationships in their head at once. This
# turns them into three readable lines and never prints the number itself (§100).
func relations_of(observer_id: String) -> Dictionary:
    var member := npc(observer_id)
    if member == null or not member.is_alive():
        return {}
    var suspects: Array = []
    var trusted: Array = []
    for other in living_ids():
        if other == observer_id:
            continue
        suspects.append({"id": other, "value": member.get_suspicion(other)})
        trusted.append({"id": other, "value": member.get_affinity(other)})
    suspects.sort_custom(func(a, b): return float(a["value"]) > float(b["value"]))
    trusted.sort_custom(func(a, b): return float(a["value"]) > float(b["value"]))

    var watching: Array = []
    for entry in suspects.slice(0, 2):
        # Below this the feeling is too weak to be worth a sentence; saying
        # "약간 의심한다" about everyone would be noise.
        if float(entry["value"]) < 0.3:
            continue
        watching.append({
            "id": str(entry["id"]),
            "strength": _feeling_word(float(entry["value"])),
            "reason": AstraDialogue.reason_text(reason_for(observer_id, str(entry["id"])))
        })
    var leaning: Array = []
    for entry in trusted.slice(0, 1):
        if float(entry["value"]) < 0.2:
            continue
        leaning.append({"id": str(entry["id"]), "reason": _affinity_reason(observer_id, str(entry["id"]))})
    return {
        "id": observer_id,
        "watching": watching,
        "leaning": leaning,
        "mood": member.mood_label(),
        "spoke": public_claim_history(observer_id).size(),
        "retracted": AstraClaimLedger.retraction_count(claim_ledger, observer_id)
    }

func _feeling_word(value: float) -> String:
    if value >= 0.62:
        return "강하게 의심"
    if value >= 0.45:
        return "의심"
    return "마음에 걸려 함"

func _affinity_reason(observer_id: String, target_id: String) -> String:
    var member := npc(observer_id)
    if member == null:
        return ""
    if AstraCrewCatalog.affinity_bias(observer_id, target_id) > 0.1:
        return "전부터 가까운 사이"
    for item in isolations:
        if str(item.get("id", "")) == target_id:
            return "격리 전까지 편을 들어 준 사이"
    var claim: Dictionary = known_claims.get(observer_id, {})
    if target_id in claim.get("companions", []):
        return "그 시각 함께 있었다고 말한 상대"
    return "이번 회의에서 같은 편에 섰다"

# Everyone's current read on one person, for "who is looking at me".
func opinions_about(target_id: String) -> Array:
    var result: Array = []
    for observer_id in living_ids():
        if observer_id == target_id:
            continue
        var member := npc(observer_id)
        var value := member.get_suspicion(target_id)
        if value < 0.3:
            continue
        result.append({
            "id": observer_id,
            "strength": _feeling_word(value),
            "reason": AstraDialogue.reason_text(reason_for(observer_id, target_id))
        })
    result.sort_custom(func(a, b): return str(a["strength"]) > str(b["strength"]))
    return result

# ---------------------------------------------------------------- confrontation

# Put two people's alibis side by side in front of everyone.
#
# 0.3.1 gave the meeting three moves — publish a clue, accuse, defend — and all
# three are about one person. The move a social deduction game actually turns on
# is making two people answer *each other*, and there was no way to do it. The
# player could see in their notes that Jun claimed the lounge while Sena placed
# herself there and did not mention him, but the only way to use that was to
# accuse somebody outright.
#
# A confrontation costs a meeting action and is never free information: if the
# two stories do fit, the pair looks *better* afterwards, and the player has
# spent a turn strengthening someone else's alibi.
func can_confront(a_id: String, b_id: String) -> bool:
    if phase != "MEETING" or meeting_actions_left <= 0 or outcome != "":
        return false
    if a_id == "" or b_id == "" or a_id == b_id:
        return false
    if not is_alive(a_id) or not is_alive(b_id):
        return false
    if not public_claims.has(a_id) or not public_claims.has(b_id):
        return false
    return not disputes_done.has("confront:%s:%s" % [a_id, b_id]) and not disputes_done.has("confront:%s:%s" % [b_id, a_id])

func confront(a_id: String, b_id: String) -> Dictionary:
    if not can_confront(a_id, b_id):
        return {"ok": false}
    meeting_actions_left -= 1
    disputes_done["confront:%s:%s" % [a_id, b_id]] = true
    var start := meeting_feed.size()
    var a := npc(a_id)
    var b := npc(b_id)
    var claim_a := current_claim(a_id)
    var claim_b := current_claim(b_id)

    _feed_line("player", a_id, "%s, %s. 두 사람 다 그 시각의 위치를 다시 말해 주세요." % [name_of(a_id), name_of(b_id)], "player")
    record_player_claim(AstraClaimLedger.KIND_WITNESS,
        "%s|wa %s|eul 대질했다." % [name_of(a_id), name_of(b_id)], {"target": a_id})

    # Both restate. Restating is itself a claim, so a story that has drifted
    # since the first meeting shows up in the ledger as a contradiction.
    for speaker_id in [a_id, b_id]:
        var claim := current_claim(speaker_id)
        var mates: Array = claim.get("companions", [])
        _feed_npc(speaker_id, "m_alibi_with" if not mates.is_empty() else "m_alibi_alone",
            {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(mates))}, "alibi", "")

    var same_room := str(claim_a.get("position", "")) == str(claim_b.get("position", ""))
    var vouches: bool = b_id in claim_a.get("companions", []) or a_id in claim_b.get("companions", [])
    var result := {"ok": true, "a": a_id, "b": b_id, "conflict": false}

    if same_room and not vouches:
        # Same place, neither saw the other. One of them is not where they say.
        result["conflict"] = true
        var key := "confront:%s:%s" % [a_id, b_id]
        manual_contradictions.append({
            "key": key, "kind": "witness", "targets": [a_id, b_id], "source": "player",
            "detail": "%s|wa %s 모두 %s에 있었다고 했지만, 서로를 보지 못했다고 한다." % [name_of(a_id), name_of(b_id), room_name(str(claim_a.get("position", "")))]
        })
        public_contradiction_keys[key] = true
        stats["public_contradictions"] = int(stats.get("public_contradictions", 0)) + 1
        _feed_npc(_most_suspicious_of(a_id) if _most_suspicious_of(a_id) != "" else b_id, "m_doubt", {"target": name_of(a_id)}, "react", a_id)
        _crowd_shift(a_id, 0.11, "player")
        _crowd_shift(b_id, 0.11, "player")
        a.adjust_stress(0.1)
        b.adjust_stress(0.1)
    elif not same_room and vouches:
        # One says they were together, the other names a different room.
        result["conflict"] = true
        var liar := a_id if b_id in claim_a.get("companions", []) else b_id
        var other := b_id if liar == a_id else a_id
        var key2 := "confront:%s:%s" % [a_id, b_id]
        manual_contradictions.append({
            "key": key2, "kind": "companion", "targets": [liar], "source": "player",
            "detail": "%s|eun %s|wa 함께 있었다고 했지만, %s|eun 다른 곳을 말했다." % [name_of(liar), name_of(other), name_of(other)]
        })
        public_contradiction_keys[key2] = true
        stats["public_contradictions"] = int(stats.get("public_contradictions", 0)) + 1
        _feed_npc(other, "m_dispute_companion", {"target": name_of(liar)}, "dispute", liar)
        _crowd_shift(liar, 0.16, other)
        npc(liar).adjust_stress(0.14)
    else:
        # The stories fit. That is a real result, and it costs the player a turn:
        # the pair is now harder for anyone to push, including the player.
        _feed_npc(b_id, "m_defend_agree", {"target": name_of(a_id)}, "calm", a_id)
        for observer_id in living_ids():
            if observer_id in [a_id, b_id]:
                continue
            crew[observer_id].add_suspicion(a_id, -0.07)
            crew[observer_id].add_suspicion(b_id, -0.07)
        a.adjust_trust(0.04)
        b.adjust_trust(0.04)
        _record_beat("vouch_pair", [a_id, b_id], "%s와 %s가 서로의 알리바이를 공개적으로 확인했다." % [name_of(a_id), name_of(b_id)])

    _recompute_contradictions()
    notice.emit("confront", result)
    changed.emit()
    result["lines"] = meeting_feed.slice(start)
    return result

# Who it is worth confronting the selected person with: people who claim the
# same room, or who named each other. Anything else is just two unrelated
# statements read aloud.
func confront_candidates(a_id: String) -> Array:
    var result: Array = []
    if a_id == "" or not public_claims.has(a_id):
        return result
    var claim_a := current_claim(a_id)
    for b_id in living_ids():
        if b_id == a_id or not can_confront(a_id, b_id):
            continue
        var claim_b := current_claim(b_id)
        var same_room := str(claim_a.get("position", "")) == str(claim_b.get("position", ""))
        var linked: bool = b_id in claim_a.get("companions", []) or a_id in claim_b.get("companions", [])
        if not same_room and not linked:
            continue
        result.append({
            "id": b_id,
            "reason": "같은 장소를 말했습니다" if same_room else "서로를 동행으로 언급했습니다"
        })
    return result

# ---------------------------------------------------------------- 0.4.x voyage
# Snapshot-safe state; UI only invokes the public methods below.
func begin_voyage(memory: Dictionary = {}) -> void:
    if not voyage.is_empty():
        return
    var loop_count := int(memory.get("loops", 0))
    if contact_flow():
        flags["contact_058"]["mastered"] = Array(memory.get("mastered_guides",[])).duplicate()
    voyage = {"loop":loop_count, "room":"medbay", "visits":["medbay"], "facts":[], "notes":[],
        "inspected":[], "met":[], "recent":memory.get("recent", []).duplicate(), "seen":{},
        "seen_ever":memory.get("seen_ever",{}).duplicate(true),
        "recent_families":memory.get("recent_families",[]).duplicate(),
        "loop_focus_families":[], "loop_focus_events":[], "loop_focus_counts":{},
        "recent_focus_families":memory.get("recent_focus_families",[]).duplicate(),
        "rare_recent":memory.get("rare_recent",[]).duplicate(),
        "recent_signatures":memory.get("recent_signatures",[]).duplicate(), "replay_signature":"",
        "echo":memory.get("echo", {}).duplicate(true), "bonds":memory.get("bonds", {}).duplicate(true),
        "memories":{}, "past":{}, "changes":[], "actions":0, "choices":{}, "deferred":[],
        "scene":{}, "line":0, "companion":"", "inventory":[], "used_items":[], "goal_done":false,
        "previous_choices":memory.get("choices",{}).duplicate(true),"losses":memory.get("losses",[]).duplicate(),
        "relationships":memory.get("relationships",{}).duplicate(true),
        "dialogue_memory_052":memory.get("dialogue_memory_052",{}).duplicate(true),
        "player_profile":memory.get("player_profile",AstraLivingCrew.blank_player_profile()).duplicate(true),
        "pattern_remarks":[], "deviations":[], "social_theme":"", "loop_hook":{}, "hook_shown":false,
        "questions":memory.get("questions",{}).duplicate(true),
        "evidence_ownership":memory.get("evidence_ownership",{}).duplicate(true), "last_fact":"",
        "storylet_pity":memory.get("storylet_pity",{}).duplicate(true),
        "speaker_exposure":{}, "mira_optional_exposure":0,
        "visible_scene_ids":[], "visible_rare_ids":[],
        "memory_tags":memory.get("memory_tags",[]).duplicate(),
        "promises":{}, "promise_history":memory.get("promise_history",[]).duplicate(),
        "activity_queue":[], "autonomous_seen_loop":[],
        "autonomous_recent":memory.get("autonomous_recent",[]).duplicate(),
        "visible_signatures":memory.get("visible_signatures",[]).duplicate(),
        "routine_state":{}, "routine_observed":[], "routine_observations":[],
        "active_arcs":[], "micro_arc_state":{},
        "micro_arc_recent":memory.get("micro_arc_recent",[]).duplicate(),
        "micro_arc_pity":memory.get("micro_arc_pity",{}).duplicate(true),
        "consequence_queue":memory.get("consequence_carry",[]).duplicate(true),
        "consequence_history":[], "consequence_stats":{"IMMEDIATE":0,"DELAYED":0,"NEXT_DAY":0,"NEXT_LOOP":0},
        "relationship_feedback":[],
        "codex_known":memory.get("codex_entries_unlocked",[]).duplicate(),
        "codex_unlocks_pending":[],
        "pinned_question":str(memory.get("pinned_question","")),
        "opinion_changes":[],
        "motives":{}, "motive_observations":[],
        "incident_history":memory.get("incident_history",[]).duplicate(true), "active_incident":{},
        "foreknowledge_used":[], "foreknowledge_reactions":[],
        "scene_seen_counts":memory.get("scene_seen_counts",memory.get("seen_ever",{})).duplicate(true),
        "momentum_state":memory.get("momentum_state",{"drought":0,"force_meaningful":false}).duplicate(true),
        "delegation_history":memory.get("delegation_history",[]).duplicate(true), "delegation_used":false,
        "cooperative_history":[], "information_sources":{},
        "story_resolution_seen":false, "story_hook_seen":false,
        "canon_post_arrival_seen":memory.get("canon_post_arrival_seen",[]).duplicate()}
    voyage["chapters"] = memory.get("chapters",[]).duplicate()
    voyage["previous_review"] = str(memory.get("first_review",""))
    var previous: Dictionary = memory.get("memories", {})
    var previous_past: Dictionary = memory.get("past", {})
    for id in roster:
        var index := rng.randi_range(0,2)
        var destination := str(AstraVoyageContent.DESTINATIONS[index])
        if loop_count > 0 and previous.get(id, "") == destination:
            destination = str(AstraVoyageContent.DESTINATIONS[(index+1)%3])
        voyage["memories"][id] = destination
        if previous.has(id) and previous[id] != destination:
            voyage["changes"].append("%s의 목적지" % name_of(id) + ": " + str(previous[id]) + " → " + destination)
        var bond := float(voyage["bonds"].get(id, 0.0))
        crew[id].adjust_trust(clampf(bond * 0.2, -0.12, 0.16))
    _roll_pair_histories(previous_past)
    _init_living_relationships()
    voyage["social_theme"] = AstraLivingCrew.theme_for(seed_value, loop_count, roster)
    _avoid_duplicate_loop_signature()
    _apply_social_theme()
    voyage["replay_signature"] = _replay_signature(str(voyage["social_theme"]))
    if case_id != AstraCaseCatalog.CALIBRATION:
        voyage["loop_hook"] = AstraLivingCrew.loop_hook(str(voyage["social_theme"]), roster, loop_count)
    _ensure_curiosity_questions()
    _mark_changed_questions()
    voyage["active_arcs"] = AstraStorylets054.select_arcs(
        seed_value, loop_count, case_id, roster, voyage.get("micro_arc_recent",[]), 3,
        voyage.get("micro_arc_pity",{})
    )
    voyage["micro_arc_pity"] = AstraStorylets054.update_arc_pity(
        voyage.get("micro_arc_pity",{}),roster,voyage.get("active_arcs",[])
    )
    voyage["motives"] = AstraPersonalMotiveModel.assign(
        seed_value,loop_count,case_id,roster,active_participants(),truth.get("nulls",[])
    )
    voyage["routine_state"] = AstraCrewRoutineModel.build(
        seed_value, loop_count, case_id, roster, active_participants(), truth.get("nulls",[])
    )
    voyage["activity_queue"] = AstraCrewActivityModel.schedule(
        seed_value, loop_count, case_id, roster, active_participants(),
        voyage.get("autonomous_recent",[]), 2
    )
    _align_activity_queue_to_routine()
    phase = "EXPLORE"
    if contact_flow():
        if case_id == AstraCaseCatalog.CALIBRATION:
            _voyage_scene(AstraVoyageContent.first_thread("first_wake"))
        else:
            var newcomer := ""
            for id in roster:
                if int(AstraCrewCatalog.JOIN_DAY.get(id,1)) == campaign_day() and campaign_day() > 1:
                    newcomer = str(id)
            if newcomer != "":
                flags["contact_058"]["arrivals"].append({"id":newcomer,"day":campaign_day()})
                _voyage_scene(AstraVoyageContent.arrival_thread(newcomer))
                guide_exposed("arrival")
            else:
                var waking := str(AstraVoyageContent.chapter(case_id)["awake"])
                _voyage_scene(AstraVoyageContent.scene((waking if waking != "" else "mira") + "_awakening"))
        guide_exposed("investigate")
    else:
        var waking := str(AstraVoyageContent.chapter(case_id)["awake"])
        _voyage_scene(AstraVoyageContent.scene((waking if waking != "" else "mira") + "_awakening"))
    phase_changed.emit(phase)
    changed.emit()

# Canonical (order-independent) pair history for the current roster.
#
# Every pair keeps its previous history by default; only a small, chapter-
# scaled budget of pairs are allowed to reroll each loop (§22 of the design
# notes — randomizing all of them every loop leaves nothing for the player to
# actually remember). A pair with no prior history always gets one, since
# "no history yet" is not itself a kind of history.
func _init_living_relationships() -> void:
    var previous: Dictionary = voyage.get("relationships",{}).duplicate(true)
    var current := {}
    for i in range(roster.size()):
        for j in range(i + 1, roster.size()):
            var a := str(roster[i])
            var b := str(roster[j])
            var key := AstraCrewCatalog.pair_key(a,b)
            var history: Dictionary = voyage.get("past",{}).get(key,{})
            var relation := AstraLivingCrew.relationship_from(history, crew[a].get_affinity(b), crew[b].get_affinity(a))
            if previous.has(key):
                var old: Dictionary = previous[key]
                for axis in AstraLivingCrew.AXES:
                    relation[axis] = lerpf(float(relation.get(axis,0.5)),float(old.get(axis,0.5)),0.2)
            current[key] = relation
    voyage["relationships"] = current

func _replay_signature(theme: String) -> String:
    var parts: Array[String] = []
    for key in voyage.get("past",{}).keys():
        var entry: Dictionary = voyage["past"][key]
        parts.append("%s=%s" % [str(key),str(entry.get("type",""))])
    parts.sort()
    return "%s|%s" % [theme,",".join(parts)]

func _avoid_duplicate_loop_signature() -> void:
    var recent: Array = voyage.get("recent_signatures",[])
    if recent.is_empty():
        return
    var current_theme := str(voyage.get("social_theme",""))
    var current_signature := _replay_signature(current_theme)
    if current_signature not in recent.slice(maxi(0,recent.size()-5)):
        return
    var start := AstraLivingCrew.SOCIAL_THEMES.find(current_theme)
    for offset in range(1,AstraLivingCrew.SOCIAL_THEMES.size()+1):
        var candidate := str(AstraLivingCrew.SOCIAL_THEMES[(start + offset) % AstraLivingCrew.SOCIAL_THEMES.size()])
        var pair := AstraLivingCrew.theme_pair(candidate)
        if pair.size() < 2 or pair[0] not in roster or pair[1] not in roster:
            continue
        var signature := _replay_signature(candidate)
        if signature not in recent.slice(maxi(0,recent.size()-5)):
            voyage["social_theme"] = candidate
            return

func _apply_social_theme() -> void:
    var pair := AstraLivingCrew.theme_pair(str(voyage.get("social_theme","")))
    if pair.size() < 2:
        return
    var key := AstraCrewCatalog.pair_key(str(pair[0]),str(pair[1]))
    var relationships: Dictionary = voyage.get("relationships",{})
    if not relationships.has(key):
        return
    var relation: Dictionary = relationships[key]
    match str(voyage.get("social_theme","")):
        "OLD_FRIENDS":
            relation["comfort"] = clampf(float(relation.get("comfort",0.5)) + 0.12,0.0,1.0)
        "BROKEN_TRUST":
            relation["trust"] = clampf(float(relation.get("trust",0.5)) - 0.12,0.0,1.0)
            relation["tension"] = clampf(float(relation.get("tension",0.15)) + 0.12,0.0,1.0)
        "PROTECTIVE":
            relation["protectiveness"] = clampf(float(relation.get("protectiveness",0.2)) + 0.2,0.0,1.0)
        "PROFESSIONAL_CONFLICT":
            relation["respect"] = maxf(float(relation.get("respect",0.5)),0.65)
            relation["tension"] = clampf(float(relation.get("tension",0.15)) + 0.16,0.0,1.0)
        "SHARED_FAILURE":
            relation["tension"] = clampf(float(relation.get("tension",0.15)) + 0.1,0.0,1.0)
        "UNKNOWN_PAST":
            relation["trust"] = clampf(float(relation.get("trust",0.5)) - 0.06,0.0,1.0)
        "QUIET_ALLIANCE":
            relation["trust"] = clampf(float(relation.get("trust",0.5)) + 0.1,0.0,1.0)
    relationships[key] = relation
    voyage["relationships"] = relationships

func _roll_pair_histories(previous_past: Dictionary) -> void:
    var stage := AstraCaseCatalog.CAMPAIGN.find(case_id)
    var reroll_budget := 0 if case_id == AstraCaseCatalog.CALIBRATION else clampi(stage, 0, 3)
    var pair_keys: Array = []
    for i in range(roster.size()):
        for j in range(i + 1, roster.size()):
            pair_keys.append(AstraCrewCatalog.pair_key(str(roster[i]), str(roster[j])))
    var rerollable: Array = pair_keys.duplicate()
    AstraCaseGenerator._shuffle(rerollable, rng)
    var allowed_rerolls := {}
    for i in range(mini(reroll_budget, rerollable.size())):
        allowed_rerolls[rerollable[i]] = true
    for key in pair_keys:
        var names := str(key).split(":")
        var a := str(names[0])
        var b := str(names[1])
        var prior: Variant = previous_past.get(key)
        var prior_type := str(prior.get("type", "")) if prior is Dictionary else ""
        var chosen_type := prior_type
        if prior_type == "" or bool(allowed_rerolls.get(key, false)):
            var candidates := AstraCrewCatalog.pair_candidates(a, b)
            chosen_type = str(candidates[rng.randi_range(0, candidates.size() - 1)])
        var entry: Dictionary = AstraCrewCatalog.pair_history_info(chosen_type).duplicate()
        entry["type"] = chosen_type
        voyage["past"][key] = entry
        var affinity_delta := float(entry.get("affinity_delta", 0.0))
        var trust_delta := float(entry.get("trust_delta", 0.0))
        crew[a].affinity[b] = clampf(AstraCrewCatalog.affinity_bias(a, b) + affinity_delta, -1.0, 1.0)
        crew[b].affinity[a] = clampf(AstraCrewCatalog.affinity_bias(b, a) + affinity_delta, -1.0, 1.0)
        crew[a].adjust_trust(trust_delta * 0.5)
        crew[b].adjust_trust(trust_delta * 0.5)
        if prior_type != "" and prior_type != chosen_type and voyage["changes"].size() < 8:
            var prior_summary := str(AstraCrewCatalog.pair_history_info(prior_type).get("summary", ""))
            voyage["changes"].append("%s / %s: %s → %s" % [name_of(a), name_of(b), prior_summary, str(entry["summary"])])

func _observe_personal_reason(who: String, source_key: String, detail: String = "") -> void:
    var before := AstraPersonalMotiveModel.progress_for(voyage.get("motives",{}),who)
    voyage["motives"] = AstraPersonalMotiveModel.observe(voyage.get("motives",{}),who,source_key,detail)
    var after := AstraPersonalMotiveModel.progress_for(voyage.get("motives",{}),who)
    if after <= before:
        return
    var hint := AstraPersonalMotiveModel.player_hint(voyage.get("motives",{}),who)
    if hint != "":
        var note := "%s · %s" % [name_of(who),hint]
        if note not in voyage["motive_observations"]:
            voyage["motive_observations"].append(note)

func motive_dev_report() -> Array:
    return AstraPersonalMotiveModel.dev_report(voyage.get("motives",{}))

func voyage_rooms() -> Array:
    return AstraVoyageContent.room_ids(roster, case_id)

func routine_state_for(npc_id: String) -> Dictionary:
    return AstraCrewRoutineModel.state_for(voyage.get("routine_state",{}),npc_id)

func room_routine_summary(room: String) -> String:
    var lines: Array[String] = []
    var state: Dictionary = voyage.get("routine_state",{})
    for npc_id in AstraCrewRoutineModel.people_in_room(state,room,active_participants(),str(voyage.get("companion",""))):
        if str(npc_id) not in voyage.get("met",[]):
            continue
        var entry: Dictionary = state.get(str(npc_id),{})
        if entry.is_empty():
            continue
        lines.append("%s · %s" % [name_of(str(npc_id)),str(entry.get("activity",""))])
        if lines.size() >= 2:
            break
    if not lines.is_empty():
        return "  ".join(lines)
    var atmosphere := {
        "medbay":"비어 있는 침상과 차트가 조용히 남아 있다.",
        "engine":"냉각 펌프와 작업등 소리만 이어진다.",
        "archive":"정렬된 기록과 아직 닫히지 않은 파일이 남아 있다.",
        "comms":"빈 채널의 낮은 잡음이 반복된다.",
        "lounge":"식지 않은 컵과 비어 있는 의자가 있다.",
        "security":"출입 표시등이 일정한 간격으로 깜빡인다.",
        "bridge":"항로선과 현재 좌표가 같은 화면에 떠 있다.",
        "garden":"순환 장치 사이로 잎이 아주 조금 흔들린다."
    }
    return str(atmosphere.get(room,"지금은 눈에 띄는 사람이 없다."))

func room_context(room: String) -> String:
    var pinned := pinned_question_entry()
    if not pinned.is_empty():
        var related: Array = pinned.get("related",[])
        if room in related:
            return "집중 중 · " + str(pinned.get("text",""))
        for npc_id in active_participants():
            if str(npc_id) in related and str(routine_state_for(str(npc_id)).get("location","")) == room:
                return "집중 중 · %s에게 물어볼 수 있다." % name_of(str(npc_id))
    var purpose := {
        "medbay":"상태 기록과 의료 흔적을 확인할 수 있다.",
        "engine":"전원·배선·기계 흔적을 직접 볼 수 있다.",
        "archive":"원본 기록과 진술의 시각을 대조할 수 있다.",
        "comms":"신호·녹음·수동 종료 흔적을 확인할 수 있다.",
        "lounge":"업무 밖의 대화와 작은 관계 변화를 보기 쉽다.",
        "security":"출입 기록과 실제 잠금 상태를 비교할 수 있다.",
        "bridge":"좌표·항로·도착 시각을 전체 경로로 확인할 수 있다.",
        "garden":"표본·배급·생태 자원의 변화를 확인할 수 있다."
    }
    return str(purpose.get(room,"현재 단서와 사람을 확인할 수 있다."))

func _observe_routine_room(room: String) -> void:
    if case_id in ["CALIBRATION","DEAD_AIR"]:
        return
    var observed: Array = voyage.get("routine_observed",[])
    var observations: Array = voyage.get("routine_observations",[])
    var state: Dictionary = voyage.get("routine_state",{})
    for npc_id in AstraCrewRoutineModel.people_in_room(state,room,active_participants(),str(voyage.get("companion",""))):
        var entry: Dictionary = state.get(str(npc_id),{})
        if not bool(entry.get("is_deviation",false)):
            continue
        var key := "%s:%s:%s" % [str(npc_id),room,str(entry.get("deviation_reason",""))]
        if key in observed:
            continue
        observed.append(key)
        var home := AstraVoyageContent.home_room(str(npc_id),case_id)
        var home_name := str(AstraVoyageContent.ROOMS.get(home,{}).get("name",home))
        var room_name_now := str(AstraVoyageContent.ROOMS.get(room,{}).get("name",room))
        _observe_personal_reason(str(npc_id),"routine:%s:%s" % [room,str(entry.get("deviation_reason",""))],str(entry.get("deviation_reason","")))
        observations.append("%s · 평소에는 %s에서 자주 보였지만 이번에는 %s에서 %s" % [
            name_of(str(npc_id)),home_name,room_name_now,str(entry.get("activity",""))
        ])
        voyage["deviations"].append(AstraLivingCrew.deviation(
            str(npc_id),"routine",str(entry.get("deviation_reason","INVESTIGATION")),
            "routine:%s:%s" % [str(npc_id),room],"routine_followup",int(voyage.get("loop",0))
        ))
    voyage["routine_observed"] = observed
    voyage["routine_observations"] = observations

func _align_activity_queue_to_routine() -> void:
    var state: Dictionary = voyage.get("routine_state",{})
    var kept: Array = []
    var deviations := 0
    for npc_id in state:
        if bool(state[npc_id].get("is_deviation",false)):
            deviations += 1
    for raw in voyage.get("activity_queue",[]):
        var beat: Dictionary = raw
        var room := str(beat.get("room",""))
        var actors: Array = beat.get("actors",[])
        var needs_move := 0
        var valid := room in voyage_rooms()
        for actor_raw in actors:
            var actor := str(actor_raw)
            if actor not in active_participants() or not state.has(actor):
                valid = false
                break
            if str(state[actor].get("location","")) != room:
                needs_move += 1
        if not valid or deviations + needs_move > 3:
            continue
        for actor_raw in actors:
            var actor := str(actor_raw)
            if str(state[actor].get("location","")) != room:
                state[actor]["location"] = room
                state[actor]["activity"] = str(beat.get("action","자기 일을 하고 있다."))
                state[actor]["routine_reason"] = "AUTONOMOUS_BEAT"
                state[actor]["deviation_reason"] = "RELATIONSHIP_EVENT" if actors.size() > 1 else "INVESTIGATION"
                state[actor]["is_deviation"] = true
                deviations += 1
        kept.append(beat)
    voyage["routine_state"] = state
    voyage["activity_queue"] = kept

func voyage_people() -> Array:
    var room := str(voyage.get("room","medbay"))
    var state: Dictionary = voyage.get("routine_state",{})
    if not state.is_empty():
        return AstraCrewRoutineModel.people_in_room(
            state,room,active_participants(),str(voyage.get("companion",""))
        )
    var ids: Array = []
    for id in roster:
        if AstraVoyageContent.home_room(str(id),case_id) == room:
            ids.append(id)
    return ids

func voyage_move(room: String, greet: bool = true) -> bool:
    if phase != "EXPLORE" or room not in voyage_rooms() or not voyage.get("scene",{}).is_empty():
        return false
    voyage["room"] = room
    if room not in voyage["visits"]:
        voyage["visits"].append(room)
    # FIRST CONTACT is a deliberately bounded tutorial: moving inside the
    # medbay must not spawn autonomous/awakening chatter that can cover the
    # required panel and turn a harmless move into a progression blocker.
    if first_day_flow():
        changed.emit()
        return true
    _voyage_tick(greet)
    _observe_routine_room(room)
    if greet and voyage["scene"].is_empty():
        _maybe_autonomous_beat(room)
    if greet and voyage["scene"].is_empty():
        var waiting: Array = voyage_people()
        for id in waiting:
            if id not in voyage["met"]:
                _voyage_scene(AstraVoyageContent.scene(id + "_awakening"))
                break
        if voyage["scene"].is_empty() and not waiting.is_empty() and int(voyage["actions"]) % 3 == 0:
            voyage_talk(str(waiting[0]))
    changed.emit()
    return true

func voyage_can_delegate(who: String) -> bool:
    if case_id not in ["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"] or phase != "EXPLORE":
        return false
    if bool(voyage.get("delegation_used",false)) or not voyage.get("scene",{}).is_empty():
        return false
    if who not in voyage_people() or who not in active_participants():
        return false
    var room := str(voyage.get("room",""))
    for point in voyage_points():
        var key := room + ":" + str(point[0])
        if key not in voyage.get("inspected",[]):
            return true
    return false

func voyage_delegate(who: String) -> bool:
    if not voyage_can_delegate(who):
        return false
    var room := str(voyage.get("room",""))
    for point in voyage_points():
        var key := room + ":" + str(point[0])
        if key in voyage.get("inspected",[]):
            continue
        voyage["inspected"].append(key)
        var fact_id := str(point[4])
        var note := str(point[5])
        AstraKnowledgeModel.share_with(flags,fact_id,who,day,"delegation")
        _voyage_fact(fact_id,note,"TESTIMONY")
        voyage["delegation_used"] = true
        voyage["delegation_history"].append({"loop":int(voyage.get("loop",0)),"who":who,"fact":fact_id})
        var routine: Dictionary = voyage.get("routine_state",{})
        if routine.has(who):
            routine[who]["activity"] = "당신이 맡긴 조사를 정리하고 있다."
            routine[who]["routine_reason"] = "DELEGATED_INVESTIGATION"
            voyage["routine_state"] = routine
        _observe_personal_reason(who,"delegation:" + fact_id,fact_id)
        _voyage_tick(false)
        _voyage_scene(AstraStorylets055.delegation_scene(who,fact_id,note))
        changed.emit()
        return true
    return false

func voyage_points() -> Array:
    if first_day_flow():
        return [["pod","포드 제어 패널 · 핵심 기록",0.30,0.46,"power",AstraVoyageContent.FIRST_RECORD],
            ["status","생체 모니터 · 선택 확인",0.63,0.70,"vitals","직접 확인: 네 수면 포드의 생명유지 신호는 안정적이다. 잠금 이력의 공백 원인은 이 검사로 알 수 없다."]]
    var points: Array = AstraVoyageContent.ROOMS.get(voyage.get("room","medbay"),{}).get("points",[])
    var result: Array = []
    var stage := AstraCaseCatalog.CAMPAIGN.find(case_id)
    for point in points:
        if str(point[4]) == "arrival" and stage < 3:
            continue
        if str(point[4]) == "sample" and stage < 4:
            continue
        if str(point[4]) == "signal" and stage < 2:
            continue
        if str(point[4]) == "archive" and stage < 3:
            continue
        # CALIBRATION shows exactly one investigation point (the power fact).
        # The destination cabinet belongs to DEAD_AIR's discovery; showing it
        # here would hand the player a second chapter's clue during the first.
        if str(point[4]) == "destination" and stage < 0:
            continue
        var visible: Array = point.duplicate()
        if str(voyage["room"]) == "medbay" and str(point[0]) == "pod":
            visible[5] = "수면 중인 포드는 %d개다. 잠금 해제 이력에는 실행자 서명이 없다." % (8-roster.size())
        result.append(visible)
    return result

func voyage_inspect(point_id: String) -> bool:
    if first_day_flow():
        return _first_inspect(point_id)
    if phase != "EXPLORE" or not voyage.get("scene",{}).is_empty():
        return false
    for point in voyage_points():
        if str(point[0]) != point_id:
            continue
        var key := str(voyage["room"]) + ":" + point_id
        if key in voyage["inspected"]:
            return false
        voyage["inspected"].append(key)
        var fact_id := str(point[4])
        _voyage_fact(fact_id,str(point[5]),"DIRECT")
        var companion := str(voyage.get("companion",""))
        var cooperative_scene: Dictionary = {}
        if companion != "" and companion in active_participants():
            cooperative_scene = AstraStorylets055.cooperative_scene(fact_id,companion)
            if not cooperative_scene.is_empty():
                AstraKnowledgeModel.share_with(flags,fact_id,companion,day,"cooperative_investigation")
                voyage["cooperative_history"].append({"loop":int(voyage.get("loop",0)),"who":companion,"fact":fact_id,"scene":str(cooperative_scene.get("id",""))})
                _observe_personal_reason(companion,"cooperative:" + fact_id,fact_id)
        if key == "engine:worklog" and int(voyage["loop"]) > 0 and "recorder" not in voyage["inventory"]:
            voyage["inventory"].append("recorder")
            voyage["notes"].append("정비 로그 옆에서 휴대 기록기를 챙겼다. 통신실에서 신호를 따로 저장할 수 있다.")
        _voyage_tick()
        if voyage["scene"].is_empty():
            if fact_id == str(AstraVoyageContent.chapter(case_id).get("fact","")) and case_id != AstraCaseCatalog.CALIBRATION:
                var resolution := AstraVoyageContent.resolution_thread(case_id)
                if not resolution.is_empty():
                    _voyage_scene(resolution)
                else:
                    _voyage_scene({"id":"inspect_"+key,"action":str(point[5]),"lines":[],"choices":[],"compressible":true})
            elif case_id == AstraCaseCatalog.CALIBRATION and str(point[4]) == "power":
                # Compatibility for pre-FIRST-CONTACT snapshots.
                _voyage_scene({
                    "id":"calibration_crew_join","speaker":"","tag":"work",
                    "action":"전원 패널을 열자 세 사람이 자연스럽게 주변으로 모인다.",
                    "lines":[["rho","전원은 살아 있어. 이건 정전이 아니야."],["noa","잠금 해제 기록이 하나 있어요. 실행자 칸만 비어 있어요."],["dax","자동 해제라면 서명이 남아야 해. 그런데 없어."]],
                    "choices":[]
                })
            elif not cooperative_scene.is_empty():
                _voyage_scene(cooperative_scene)
            else:
                _voyage_scene({"id":"inspect_"+key,"action":str(point[5]),"lines":[],"choices":[],"compressible":true})
        changed.emit()
        return true
    return false

func _voyage_fact(id: String, note: String, source_type: String = "DIRECT") -> void:
    if id not in voyage["facts"]:
        voyage["facts"].append(id)
    if note not in voyage["notes"]:
        voyage["notes"].append(note)
    voyage["last_fact"] = id
    var source_types: Dictionary = voyage.get("information_sources",{})
    source_types[id] = source_type
    voyage["information_sources"] = source_types
    var ownership: Dictionary = voyage.get("evidence_ownership",{})
    var entry: Dictionary = ownership.get(id,{"found_by":"player","knows":["player"],"public":false})
    var knowers: Array = entry.get("knows",[])
    if "player" not in knowers:
        knowers.append("player")
    entry["knows"] = knowers
    ownership[id] = entry
    voyage["evidence_ownership"] = ownership
    AstraKnowledgeModel.discover_player(flags,id,day,"voyage")
    if id == str(AstraVoyageContent.chapter(case_id)["fact"]):
        voyage["goal_done"] = true
        _advance_curiosity_question(id)
func _focus_context(explicit_topic: bool = false) -> Dictionary:
    # Player-safe selector boundary. Do not add truth/nulls, motive assignments,
    # hidden relationship floats or unseen candidate results here.
    return {
        "loop_focus_families":Array(voyage.get("loop_focus_families",[])).duplicate(),
        "loop_focus_events":Array(voyage.get("loop_focus_events",[])).duplicate(true),
        "loop_focus_counts":Dictionary(voyage.get("loop_focus_counts",{})).duplicate(true),
        "recent_focus_families":Array(voyage.get("recent_focus_families",[])).duplicate(),
        "speaker_exposure":Dictionary(voyage.get("speaker_exposure",{})).duplicate(true),
        "explicit_topic":explicit_topic
    }

func _record_focus_exposure(scene: Dictionary) -> void:
    var level := AstraStoryletScheduler.salience(scene)
    if level not in ["MANDATORY","FOLLOWUP","FOCUS"]:
        return
    var id := str(scene.get("id",""))
    var family := AstraStoryletScheduler.family_key(scene)
    # Decide continuation against the already-visible context before appending
    # this scene. A follow-up may use a different authored family id while still
    # belonging to the same player-visible thread.
    var continuation := AstraStoryletScheduler.is_continuation(scene,_focus_context())
    var event := {
        "scene":id,
        "family":family,
        "chain_id":str(scene.get("chain_id","")),
        "category":str(scene.get("category","")),
        "intent":str(scene.get("intent",scene.get("tag",""))),
        "tag":str(scene.get("tag","")),
        "salience":level,
        "speaker":str(scene.get("speaker","")),
        "continuation":continuation,
        "source":"visible_scene"
    }
    voyage["loop_focus_events"].append(event)
    while voyage["loop_focus_events"].size() > 24:
        voyage["loop_focus_events"].pop_front()
    # Mandatory/progression and authored FOLLOWUP are visible and recorded but
    # do not consume the soft 2-3 *new-thread* budget. A genuine continuation
    # likewise does not open another thread merely because its authored family
    # id differs. Only a genuinely new FOCUS family consumes a slot.
    if level in ["FOLLOWUP","FOCUS"] and family != "":
        if level == "FOCUS" and not continuation and family not in voyage["loop_focus_families"]:
            voyage["loop_focus_families"].append(family)
        var counts: Dictionary = voyage.get("loop_focus_counts",{})
        counts[family] = int(counts.get(family,0)) + 1
        voyage["loop_focus_counts"] = counts

func _voyage_scene(scene: Dictionary) -> void:
    if scene.is_empty():
        return
    var incoming: Dictionary = scene.duplicate(true)
    var incoming_id := str(incoming.get("id",""))
    var seen_counts: Dictionary = voyage.get("scene_seen_counts",{})
    var prior_seen := int(seen_counts.get(incoming_id,0))
    if AstraForeknowledgeModel.can_compress(incoming,prior_seen):
        incoming["_full_action"] = str(incoming.get("action",""))
        incoming["_full_lines"] = Array(incoming.get("lines",[])).duplicate(true)
        incoming["action"] = AstraForeknowledgeModel.compressed_action(incoming)
        incoming["lines"] = []
        incoming["compressed"] = true
    seen_counts[incoming_id] = prior_seen + 1
    voyage["scene_seen_counts"] = seen_counts
    voyage["scene"] = incoming
    voyage["line"] = -1
    scene = incoming
    var who := str(scene.get("speaker",""))
    if who != "" and who not in voyage["met"]:
        voyage["met"].append(who)
    for participant in scene.get("participants", []):
        var participant_id := str(participant)
        if participant_id in roster and participant_id not in voyage["met"]:
            voyage["met"].append(participant_id)
    var id := str(scene.get("id",""))
    voyage["seen"][id] = int(voyage["seen"].get(id,0)) + 1
    var seen_ever: Dictionary = voyage.get("seen_ever",{})
    seen_ever[id] = int(seen_ever.get(id,0)) + 1
    voyage["seen_ever"] = seen_ever
    _unlock_codex_from_scene(id)
    voyage["recent"].append(id)
    while voyage["recent"].size() > 18:
        voyage["recent"].pop_front()
    var family := str(scene.get("family",id))
    if family != "":
        voyage["recent_families"].append(family)
        while voyage["recent_families"].size() > 18:
            voyage["recent_families"].pop_front()
    _record_focus_exposure(scene)
    if str(scene.get("rarity","")) == "rare":
        voyage["rare_recent"].append(id)
        while voyage["rare_recent"].size() > 8:
            voyage["rare_recent"].pop_front()
        if id not in voyage["visible_rare_ids"]:
            voyage["visible_rare_ids"].append(id)
    if (id.begins_with("053_") or id.begins_with("054_") or id.begins_with("055_")) and id not in voyage["visible_scene_ids"]:
        voyage["visible_scene_ids"].append(id)
    if scene.has("motive_progress") and who != "":
        _observe_personal_reason(who,"scene:" + id,str(scene.get("requires_motive","")))
    if bool(scene.get("canon_post_arrival",false)):
        var canon_seen: Array = voyage.get("canon_post_arrival_seen",[])
        if id not in canon_seen:
            canon_seen.append(id)
        voyage["canon_post_arrival_seen"] = canon_seen
        _voyage_fact("post_arrival_activity","도착 이후에도 한동안 평범한 업무 기록이 이어졌다.","RECORD")
    var chain_id := str(scene.get("chain_id",""))
    if chain_id != "":
        var chain_state: Dictionary = voyage.get("micro_arc_state",{})
        chain_state[chain_id] = maxi(int(chain_state.get(chain_id,0)),int(scene.get("sets_stage",0)))
        voyage["micro_arc_state"] = chain_state
    var opinion_change: Dictionary = scene.get("opinion_change",{})
    if not opinion_change.is_empty() and who != "":
        var opinion_target := str(scene.get("target",""))
        var relationship_context := ""
        if opinion_target != "" and crew.has(opinion_target):
            relationship_context = relationship_status(who,opinion_target)
        voyage["opinion_changes"].append({
            "actor":who,"target":opinion_target,
            "reason_tag":str(opinion_change.get("reason","new_evidence")),
            "source_scene":id,"visible":true,"day":day,
            "known_facts":AstraKnowledgeModel.known_facts(flags,who),
            "relationship_context":relationship_context
        })
    if bool(scene.get("optional_exposure",false)) and who != "":
        var exposure: Dictionary = voyage.get("speaker_exposure",{})
        exposure[who] = int(exposure.get(who,0)) + 1
        voyage["speaker_exposure"] = exposure
        if who == "mira":
            voyage["mira_optional_exposure"] = int(voyage.get("mira_optional_exposure",0)) + 1
    var memory_state: Dictionary = voyage.get("dialogue_memory_052",{})
    var memory_event := {
        "type":"scene", "scene":id, "family":family, "intent":str(scene.get("intent",scene.get("tag",""))),
        "loop":int(voyage.get("loop",0)), "action":str(scene.get("action",""))
    }
    if who != "":
        memory_state = AstraLivingCrew.remember(memory_state, who, memory_event)
    var target := str(scene.get("target",""))
    if target != "":
        memory_state = AstraLivingCrew.remember(memory_state, target, memory_event)
        if who != "" and crew.has(who) and crew.has(target):
            var scene_tag := str(scene.get("tag",""))
            var scene_category := str(scene.get("category",""))
            var authored_social := scene_tag in ["pair","trust","relief","conflict","suspected","danger"] or scene_category in ["RELATIONSHIP","CONFLICT"]
            # Keep the 0.5.5 tag effects, but a visibly authored conflict also
            # leaves tension. This is not inferred from the hidden social theme.
            if scene_category == "CONFLICT":
                _adjust_relationship(who,target,"tension",0.035,id,true,true)
            match scene_tag:
                "pair", "trust", "relief":
                    _adjust_relationship(who,target,"comfort",0.02,id,true,authored_social)
                    _adjust_relationship(who,target,"trust",0.015,id,true,authored_social)
                "work":
                    _adjust_relationship(who,target,"respect",0.02,id,true,authored_social)
                "conflict", "suspected":
                    _adjust_relationship(who,target,"tension",0.035,id,true,true)
                "danger":
                    _adjust_relationship(who,target,"protectiveness",0.03,id,true,true)
    voyage["dialogue_memory_052"] = memory_state
    var deviation_reason := str(scene.get("deviation_reason",""))
    if deviation_reason != "" and who != "":
        voyage["deviations"].append(AstraLivingCrew.deviation(
            who, str(scene.get("family",scene.get("tag",""))), deviation_reason,
            str(scene.get("source_event",id)), str(scene.get("possible_followup","")),
            int(voyage.get("loop",0))
        ))
func _echo_entry(who: String) -> Dictionary:
    var raw: Variant = voyage["echo"].get(who)
    if raw is Dictionary:
        var entry: Dictionary = raw.duplicate(true)
        entry["familiarity"] = float(entry.get("familiarity", 0.0))
        entry["trust"] = float(entry.get("trust", 0.0))
        entry["protection"] = float(entry.get("protection", 0.0))
        entry["conflict"] = float(entry.get("conflict", 0.0))
        entry["grief"] = float(entry.get("grief", 0.0))
        entry["tags"] = Array(entry.get("tags", []))
        return entry
    # A pre-0.4.2 save stored a single scalar here; it becomes familiarity,
    # the closest existing dimension to "some residue remains" (§24).
    var legacy := float(raw) if raw != null else 0.0
    return {"familiarity": legacy, "trust": 0.0, "protection": 0.0, "conflict": 0.0, "grief": 0.0, "tags": []}

func echo_strength(entry: Dictionary) -> float:
    var peak := 0.0
    for dim in ["familiarity", "trust", "protection", "conflict", "grief"]:
        peak = maxf(peak, absf(float(entry.get(dim, 0.0))))
    return peak

const ECHO_TAG_THRESHOLDS := {
    "trust": ["trusted_record", 0.32], "protection": ["shielded_player", 0.28],
    "familiarity": ["shared_repair", 0.5], "conflict": ["kept_distance", 0.3]
}

func _adjust_echo(who: String, tag: String, effect: String, delta: float) -> void:
    var entry := _echo_entry(who)
    entry["familiarity"] = clampf(float(entry["familiarity"]) + absf(delta) * 0.4 + 0.01, 0.0, 1.0)
    if tag == "trust" or effect in ["share", "defend"]:
        entry["trust"] = clampf(float(entry["trust"]) + absf(delta) * 0.9, 0.0, 1.0)
    if tag in ["conflict", "suspected", "distant"] or effect == "hide":
        entry["conflict"] = clampf(float(entry["conflict"]) + 0.05, 0.0, 1.0)
    if tag == "danger" and effect in ["help", "defend"]:
        entry["protection"] = clampf(float(entry["protection"]) + 0.10, 0.0, 1.0)
    var tags: Array = entry["tags"]
    for dim in ECHO_TAG_THRESHOLDS:
        var spec: Array = ECHO_TAG_THRESHOLDS[dim]
        if float(entry.get(dim, 0.0)) >= float(spec[1]) and str(spec[0]) not in tags:
            tags.append(str(spec[0]))
    entry["tags"] = tags
    voyage["echo"][who] = entry

func player_relationship_tone(who: String) -> String:
    if voyage.is_empty():
        return "PROFESSIONAL"
    return AstraLivingCrew.relationship_tone_with_player(
        float(voyage.get("bonds",{}).get(who,0.0)), _echo_entry(who)
    )

func _memory_has_tag(who: String, tag: String) -> bool:
    if tag == "":
        return true
    if (who + ":" + tag) in voyage.get("memory_tags",[]) or tag in voyage.get("memory_tags",[]):
        return true
    for event in voyage.get("dialogue_memory_052",{}).get(who,[]):
        if str(event.get("tag","")) == tag or str(event.get("memory_tag","")) == tag:
            return true
    return false

func _memory_action_count(who: String, action: String) -> int:
    var count := 0
    for event in voyage.get("dialogue_memory_052",{}).get(who,[]):
        if str(event.get("type","")) == "player_action" and str(event.get("action","")) == action:
            count += 1
    return count

func _apply_scene_variants(scene: Dictionary, who: String) -> Dictionary:
    var result := scene.duplicate(true)
    var tone := player_relationship_tone(who)
    var tone_lines: Dictionary = result.get("tone_lines",{})
    if tone_lines.has(tone):
        result["lines"] = [[who,str(tone_lines[tone])]]
    var tone_actions: Dictionary = result.get("tone_actions",{})
    if tone_actions.has(tone):
        result["action"] = str(tone_actions[tone])
    var role_lines: Dictionary = result.get("role_lines",{})
    if not role_lines.is_empty() and crew.has(who):
        var role_key := "NULL" if crew[who].is_null() else "CREW"
        if role_lines.has(role_key):
            result["lines"] = [[who,str(role_lines[role_key])]]
    return result

func _scene_eligible_052(scene: Dictionary, who: String) -> bool:
    if scene.has("chapters") and case_id not in Array(scene.get("chapters",[])):
        return false
    if bool(scene.get("cooperative_only",false)) or bool(scene.get("delegation_only",false)):
        return false
    if bool(scene.get("foreknowledge_reaction",false)):
        return false
    var required_motive := str(scene.get("requires_motive",""))
    if required_motive != "":
        if AstraPersonalMotiveModel.motive_for(voyage.get("motives",{}),who) != required_motive:
            return false
        if AstraPersonalMotiveModel.progress_for(voyage.get("motives",{}),who) < int(scene.get("requires_motive_progress",0)):
            return false
    var required_incident := str(scene.get("requires_incident",""))
    if required_incident != "":
        var found_incident := false
        for event in voyage.get("incident_history",[]):
            if str(event.get("id","")) == required_incident:
                found_incident = true
                break
        if not found_incident:
            return false
    if bool(scene.get("canon_post_arrival",false)) and voyage.get("canon_post_arrival_seen",[]).size() >= 2:
        return false
    if crew.has(who) and not crew[who].is_alive():
        return false
    var requires: Dictionary = scene.get("requires",{})
    if int(voyage.get("loop",0)) < int(requires.get("min_loop",0)):
        return false
    var required_fact := str(requires.get("fact",""))
    if required_fact != "" and required_fact not in voyage.get("facts",[]):
        return false
    var required_scene := str(requires.get("scene",""))
    if required_scene != "" and int(voyage.get("seen_ever",{}).get(required_scene,0)) <= 0:
        return false
    var required_axis := str(requires.get("player_axis",""))
    if required_axis != "" and AstraLivingCrew.dominant_player_axis(voyage.get("player_profile",{})) != required_axis:
        return false
    var required_effect := str(requires.get("choice_effect",""))
    if required_effect != "" and int(voyage.get("choices",{}).get(required_effect,0)) < int(requires.get("choice_count_min",1)):
        return false
    var required_memory := str(requires.get("memory_tag",""))
    if required_memory != "" and not _memory_has_tag(who,required_memory):
        return false
    var echo_axis := str(requires.get("echo_axis",""))
    if echo_axis != "" and float(_echo_entry(who).get(echo_axis,0.0)) < float(requires.get("echo_min",0.1)):
        return false
    var required_tone := str(requires.get("tone",""))
    if required_tone != "" and player_relationship_tone(who) != required_tone:
        return false
    var required_role := str(requires.get("role",""))
    if required_role != "" and crew.has(who):
        if required_role == "NULL" and not crew[who].is_null():
            return false
        if required_role == "CREW" and crew[who].is_null():
            return false
    var chain_id := str(scene.get("chain_id",""))
    if chain_id != "":
        if chain_id not in voyage.get("active_arcs",[]):
            return false
        if int(voyage.get("micro_arc_state",{}).get(chain_id,0)) != int(scene.get("requires_stage",0)):
            return false
        # Consequence stages are delivered only by AstraConsequenceModel when
        # their authored delay/day/loop condition becomes due. Normal dialogue
        # selection must never jump ahead of the player's choice.
        if str(scene.get("category","")) == "CONSEQUENCE":
            return false
    var opinion_meta: Dictionary = scene.get("opinion_change",{})
    if str(opinion_meta.get("reason","")) == "new_evidence" and voyage.get("facts",[]).is_empty():
        return false
    var routine_relevance := str(scene.get("routine_relevance",""))
    if routine_relevance != "":
        var routine_entry: Dictionary = voyage.get("routine_state",{}).get(who,{})
        if str(routine_entry.get("deviation_reason","")) != routine_relevance:
            return false
    var forbids: Dictionary = scene.get("forbids",{})
    var forbidden_fact := str(forbids.get("fact",""))
    if forbidden_fact != "" and forbidden_fact in voyage.get("facts",[]):
        return false
    var rarity := str(scene.get("rarity","common"))
    if rarity == "rare":
        if str(scene.get("id","")) in voyage.get("rare_recent",[]):
            return false
        var roll := float(abs(hash("%d:%d:%s" % [seed_value,int(voyage.get("loop",0)),str(scene.get("id",""))])) % 1000) / 1000.0
        if roll > AstraStoryletScheduler.rare_threshold(scene,voyage.get("storylet_pity",{})):
            return false
    elif rarity == "uncommon":
        var uncommon_roll := float(abs(hash("u:%d:%d:%s" % [seed_value,int(voyage.get("loop",0)),str(scene.get("id",""))])) % 1000) / 1000.0
        if uncommon_roll > AstraStoryletScheduler.rare_threshold(scene,voyage.get("storylet_pity",{})):
            return false
    return true

func _pair_scene_context_ok(scene: Dictionary) -> bool:
    var who := str(scene.get("speaker", ""))
    var other := str(scene.get("target", ""))
    if who not in voyage.get("met", []) or other not in voyage.get("met", []):
        return false
    var id := str(scene.get("id", ""))
    var room := str(voyage.get("room", ""))
    var facts: Array = voyage.get("facts", [])
    var stress_high: bool = (crew.has(who) and crew[who].stress >= 0.3) or (crew.has(other) and crew[other].stress >= 0.3)
    if "rho_sena" in id:
        return room in ["engine", "security"] or bool(voyage.get("goal_done", false))
    if "mira_lyra" in id:
        return room in ["medbay", "garden"] or stress_high
    if "dax_noa" in id:
        return not facts.is_empty()
    if "vale_eli" in id:
        return room in ["comms", "bridge"] or "signal" in facts or "arrival" in facts or "destination" in facts
    if "rho_dax" in id:
        return room == "engine" or "power" in facts
    if "sena_mira" in id:
        return room in ["security", "medbay"] or stress_high
    if "lyra_dax" in id:
        return room == "garden" or "sample" in facts
    if "noa_vale" in id:
        return room in ["archive", "comms"] or "signal" in facts
    return true
func voyage_talk(who: String, topic: String = "") -> bool:
    if phase != "EXPLORE" or who not in voyage_people() or who not in voyage.get("met", []) or not voyage["scene"].is_empty():
        return false
    var speaker_exposure_now: Dictionary = voyage.get("speaker_exposure",{})
    var mira_exposure_now := maxi(
        int(voyage.get("mira_optional_exposure",0)),
        int(speaker_exposure_now.get("mira",0))
    )
    if who == "mira" and case_id in ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"] and mira_exposure_now >= 4:
        _voyage_scene({"id":"053_mira_exposure_cap","speaker":"mira","tag":"silence","action":"미라는 하던 검사를 마무리하며 짧게 손을 들어 보인다. 지금은 자기 일에 집중하는 편이 좋아 보인다.","lines":[],"choices":[]})
        _voyage_tick(false)
        changed.emit()
        return true
    var focus_context := _focus_context(topic != "")
    var eligible: Array = []
    var bond := float(voyage["bonds"].get(who,0.0))
    var echo := echo_strength(_echo_entry(who))
    for scene in AstraVoyageContent.all_scenes():
        if scene["speaker"] != who or not _scene_eligible_052(scene, who):
            continue
        var tag := str(scene["tag"])
        if topic != "" and tag != topic:
            continue
        if tag == "awakening": continue
        var choices: Dictionary = voyage["choices"]
        if tag == "conflict" and int(choices.get("hide",0)) == 0: continue
        if tag == "suspected" and int(voyage.get("previous_choices",{}).get("accuse",0)) == 0: continue
        if tag == "after" and int(voyage["loop"]) == 0: continue
        if tag == "danger" and (str(voyage["room"]) not in ["engine","security"] or bool(voyage["goal_done"])): continue
        if tag == "relief" and not bool(voyage["goal_done"]): continue
        if tag == "night" and int(voyage["actions"]) < 10: continue
        if tag == "grief" and voyage.get("losses",[]).is_empty(): continue
        if tag == "apology" and int(choices.get("hide",0)) + int(voyage.get("previous_choices",{}).get("accuse",0)) == 0: continue
        if tag == "defense" and not bool(voyage["goal_done"]): continue
        if tag == "secret" and bond < 0.1: continue
        if tag in ["personal","echo","secret"]:
            if int(voyage["actions"]) < 5 or int(voyage["seen"].get(scene["id"],0)) > 0: continue
        if tag == "pair":
            var pair_target := str(scene.get("target",""))
            if pair_target == "" or pair_target not in voyage.get("met",[]) or not crew.has(pair_target) or not crew[pair_target].is_alive() or not _pair_scene_context_ok(scene):
                continue
        if tag == "trio":
            var trio_ok := true
            for participant in scene.get("participants", []):
                if str(participant) not in roster or str(participant) not in voyage.get("met", []) or not crew.has(str(participant)) or not crew[str(participant)].is_alive():
                    trio_ok = false
                    break
            if not trio_ok:
                continue
        if tag == "trust" and bond < 0.25: continue
        if tag == "distant" and bond > -0.15: continue
        if tag == "echo" and (int(voyage["loop"]) < 1 or absf(echo) < 0.1): continue
        if tag == "personal" and int(voyage["loop"]) < 1: continue
        if not voyage["recent"].is_empty() and scene["id"] == voyage["recent"].back() and topic == "": continue
        var candidate: Dictionary = Dictionary(scene).duplicate(true)
        var weight := AstraLivingCrew.content_weight(who, tag)
        if tag in ["everyday","work","observation"]:
            weight += 0.35
        if bool(voyage.get("momentum_state",{}).get("force_meaningful",false)) and int(voyage.get("seen_ever",{}).get(str(candidate.get("id","")),0)) == 0 and str(candidate.get("category","")) in ["MOTIVE","CANON","INCIDENT_AFTER"]:
            weight += 1.4
            candidate["_meaningful_055"] = true
        candidate["_content_weight"] = maxf(0.25,weight)
        eligible.append(candidate)
    # Explicit topics always remain seekable, but normal conversations never
    # reroll indefinitely searching for an eligible event.
    if eligible.is_empty():
        _voyage_scene({"id":who+"_busy","speaker":who,"action":AstraJosa.eun(name_of(who))+" 하던 일을 마무리한다. 잠시 조용히 곁에 선다.","lines":[],"choices":[]})
    else:
        if bool(voyage.get("momentum_state",{}).get("force_meaningful",false)):
            # CLEAR SIGNAL: drought recovery continues an already visible thread
            # before opening an unrelated hidden-motive thread.
            var continuation_057: Array = eligible.filter(func(item):
                return AstraStoryletScheduler.is_continuation(item,focus_context) and AstraStoryletScheduler.salience(item) in ["MANDATORY","FOLLOWUP","FOCUS"]
            )
            var linked_057: Array = eligible.filter(func(item):
                var family := AstraStoryletScheduler.family_key(item)
                var unseen := int(voyage.get("seen_ever",{}).get(str(item.get("id","")),0)) == 0
                return unseen and AstraStoryletScheduler.salience(item) in ["MANDATORY","FOLLOWUP","FOCUS"] and (
                    family in voyage.get("loop_focus_families",[]) or AstraStoryletScheduler.direct_pinned_match(item,pinned_question_entry())
                )
            )
            var canon_followup_057: Array = eligible.filter(func(item):
                return str(item.get("category","")) == "CANON" or AstraStoryletScheduler.salience(item) == "FOLLOWUP"
            )
            var meaningful_055: Array = eligible.filter(func(item): return bool(item.get("_meaningful_055",false)))
            if not continuation_057.is_empty():
                eligible = continuation_057
            elif not linked_057.is_empty():
                eligible = linked_057
            elif not canon_followup_057.is_empty():
                eligible = canon_followup_057
            elif not meaningful_055.is_empty():
                eligible = meaningful_055
        # Ordinary recent-family repetition is still suppressed, but an actual
        # current-loop continuation and an explicit topic survive this prefilter
        # so the scheduler can make the final weighted decision.
        var recent_families: Array = voyage.get("recent_families",[])
        var recent_ids: Array = voyage.get("recent",[])
        var fresh: Array = eligible.filter(func(item):
            return AstraStoryletScheduler.keep_fresh_candidate(item,recent_ids,recent_families,focus_context)
        )
        if not fresh.is_empty(): eligible = fresh
        var selected: Dictionary = AstraStoryletScheduler.pick(
            eligible, voyage.get("seen_ever",{}), recent_families,
            str(voyage.get("social_theme","")), rng.randf(), pinned_question_entry(), focus_context
        )
        voyage["storylet_pity"] = AstraStoryletScheduler.update_pity(
            voyage.get("storylet_pity",{}), eligible, str(selected.get("id",""))
        )
        selected["optional_exposure"] = true
        selected = _apply_scene_variants(selected,who)
        if str(selected["tag"]) == "memory":
            selected["lines"] = [["", "%s의 기억: %s. 같은 목적지가 적힌 서명 원본도 있다." % [name_of(who),str(voyage["memories"][who])]]]
        if str(selected["tag"]) == "pair":
            var other := str(selected["target"])
            var history: Variant = voyage["past"].get(AstraCrewCatalog.pair_key(who, other))
            var summary := str(history["summary"]) if history is Dictionary else "이번 항해에서 처음 함께 일한다."
            selected["action"] += " 두 사람의 기록: %s" % summary
        _voyage_scene(selected)
    _voyage_tick(false)
    changed.emit()
    return true

func voyage_ask_goal(who: String) -> bool:
    if contact_flow():
        if phase != "EXPLORE" or who not in voyage_people() or not voyage.get("scene",{}).is_empty():
            return false
        # Guidance points at a real object but never awards evidence.
        voyage["hint_requested"] = true
        notice.emit("hint",{"text":str(contact_objective().get("text",""))})
        changed.emit()
        return true
    if phase != "EXPLORE" or who not in voyage_people() or not voyage["scene"].is_empty():
        return false
    var chapter := AstraVoyageContent.chapter(case_id)
    var fact := str(chapter["fact"])
    var directions := {"mira":"포드 상태 기록을 같이 봐요.","rho":"이쪽 배선부터 같이 보자. 손전등 잡아 줘.","dax":"이 파일도 확인해 봐. 나는 다른 쪽을 볼게.","noa":"같은 날짜의 기록이 하나 더 있어요.","sena":"문을 열어 둘게. 같이 확인하자.","vale":"저장해 뒀어요. 여기부터 들어요.","eli":"전체 경로를 띄울게. 끝을 봐.","lyra":"라벨이 남아 있어요. 날짜를 봐요."}
    _voyage_fact(fact,str(chapter["discovery"]))
    var id := "goal_"+who
    _voyage_scene({"id":id,"speaker":who,"tag":"work","action":AstraJosa.wa(name_of(who))+" 함께 기록을 펼친다.","lines":[[who,str(directions[who])],["",str(chapter["discovery"])]],"choices":[{"label":"함께 확인한 내용을 남긴다.","effect":"record"},{"label":"다른 동료에게도 가져간다.","effect":"share"}]})
    _voyage_tick(false)
    changed.emit()
    return true

func voyage_expand_scene() -> bool:
    if phase != "EXPLORE" or voyage.get("scene",{}).is_empty():
        return false
    var current: Dictionary = voyage["scene"]
    if not bool(current.get("compressed",false)):
        return false
    current["action"] = str(current.get("_full_action",""))
    current["lines"] = Array(current.get("_full_lines",[])).duplicate(true)
    current["compressed"] = false
    voyage["scene"] = current
    voyage["line"] = -1
    changed.emit()
    return true

func voyage_next() -> void:
    if phase != "EXPLORE" or voyage["scene"].is_empty(): return
    var scene: Dictionary = voyage["scene"]
    var last: int = scene.get("lines",[]).size()-1
    if int(voyage["line"]) < last:
        voyage["line"] = int(voyage["line"])+1
    elif scene.get("choices",[]).is_empty():
        voyage["scene"] = {}
        _complete_contact_scene(scene)
        if bool(scene.get("story_resolution",false)):
            voyage["story_resolution_seen"] = true
            var hook := AstraVoyageContent.hook_thread(case_id)
            if not hook.is_empty():
                _voyage_scene(hook)
        elif bool(scene.get("story_hook",false)):
            voyage["story_hook_seen"] = true
        # An incidental/autonomous beat can win the race immediately after the
        # goal fact is discovered. Do not let that swallow the mandatory local
        # answer: once the incidental scene closes, enqueue the resolution
        # before any optional loop hook.
        if voyage.get("scene",{}).is_empty() and not first_day_flow() and bool(voyage.get("goal_done",false)) and not bool(voyage.get("story_resolution_seen",false)):
            var pending_resolution := AstraVoyageContent.resolution_thread(case_id)
            if not pending_resolution.is_empty():
                _voyage_scene(pending_resolution)
        if voyage.get("scene",{}).is_empty() and not first_day_flow() and not bool(voyage.get("hook_shown",false)) and not Dictionary(voyage.get("loop_hook",{})).is_empty():
            voyage["hook_shown"] = true
            _voyage_scene(voyage["loop_hook"])
    changed.emit()
func voyage_choose(index: int) -> bool:
    if phase != "EXPLORE" or voyage["scene"].is_empty(): return false
    var scene: Dictionary = voyage["scene"]
    var choices: Array = scene.get("choices",[])
    if int(voyage["line"]) < scene.get("lines",[]).size()-1 or index < 0 or index >= choices.size(): return false
    var choice: Dictionary = choices[index]
    # FIRST CONTACT only owns the authored first_panel decision. Once that
    # panel is resolved, CALIBRATION may still surface ordinary authored
    # choices; those must use the normal voyage choice pipeline.
    if first_day_flow() and str(scene.get("id","")) == "first_panel":
        return _first_choice(str(scene.get("id","")),str(choice.get("effect","")))
    var effect := str(choice["effect"])
    var who := str(scene.get("speaker",""))
    var previous_count := int(voyage["choices"].get(effect,0))
    voyage["choices"][effect] = previous_count + 1
    voyage["player_profile"] = AstraLivingCrew.register_player_action(voyage.get("player_profile",{}), effect)
    var preferences: Dictionary = AstraVoyageContent.RESPONSES.get(who,{})
    var delta := float(preferences.get(effect,0.0))
    var repeat_factor := maxf(0.45, 1.0 - float(previous_count) * 0.18)
    delta *= repeat_factor
    # Privacy makes sharing a personal admission different from sharing a log.
    if str(scene.get("tag","")) == "secret" and effect == "share": delta = -0.02 * repeat_factor
    voyage["bonds"][who] = clampf(float(voyage["bonds"].get(who,0.0))+delta,-1.0,1.0)
    _adjust_echo(who, str(scene.get("tag","")), effect, delta)
    if crew.has(who): crew[who].adjust_trust(delta)
    var memory_state: Dictionary = voyage.get("dialogue_memory_052",{})
    var memory_tag := str(choice.get("memory_tag",""))
    memory_state = AstraLivingCrew.remember(memory_state, who, {
        "type":"player_action","action":effect,"scene":str(scene.get("id","")),
        "memory_tag":memory_tag, "loop":int(voyage.get("loop",0))
    })
    voyage["dialogue_memory_052"] = memory_state
    if memory_tag != "":
        var tags: Array = voyage.get("memory_tags",[])
        var scoped_tag := who + ":" + memory_tag
        if scoped_tag not in tags:
            tags.append(scoped_tag)
        voyage["memory_tags"] = tags
    var promise := str(choice.get("promise",""))
    if promise != "":
        voyage["promises"][who + ":" + promise] = "active"
        voyage["promise_history"].append({"who":who,"promise":promise,"loop":int(voyage.get("loop",0)),"state":"made"})
    if who == "mira" and effect == "withhold" and str(voyage.get("promises",{}).get("mira:tell_injury","")) == "active":
        voyage["promises"]["mira:tell_injury"] = "broken"
        if "mira:promise_broken:tell_injury" not in voyage["memory_tags"]:
            voyage["memory_tags"].append("mira:promise_broken:tell_injury")
        voyage["promise_history"].append({"who":"mira","promise":"tell_injury","loop":int(voyage.get("loop",0)),"state":"broken"})
    var last_fact := str(voyage.get("last_fact",""))
    if last_fact != "" and effect in ["share","record","open_records"]:
        var ownership: Dictionary = voyage.get("evidence_ownership",{})
        var evidence: Dictionary = ownership.get(last_fact,{"found_by":"player","knows":["player"],"public":false})
        var knowers: Array = evidence.get("knows",[])
        if who != "" and who not in knowers:
            knowers.append(who)
        evidence["knows"] = knowers
        ownership[last_fact] = evidence
        voyage["evidence_ownership"] = ownership
        AstraKnowledgeModel.share_with(flags,last_fact,who,day,"player")
    var consequence_events := AstraConsequenceModel.from_choice(
        choice,who,str(scene.get("id","")),int(voyage.get("actions",0)),
        int(voyage.get("loop",0)),day
    )
    if not consequence_events.is_empty():
        voyage["consequence_queue"] = AstraConsequenceModel.enqueue(
            voyage.get("consequence_queue",[]),consequence_events
        )
    elif effect in ["share","hide","help","defend","confront","withhold","keep_copy","promise"]:
        voyage["deferred"].append({"who":who,"effect":effect,"due":int(voyage["actions"])+2})
    var incident_result: Dictionary = {}
    var foreknowledge_reaction: Dictionary = {}
    if str(scene.get("category","")) == "INCIDENT":
        incident_result = AstraIncidentModel.resolve(
            voyage.get("active_incident",{}),choice,int(voyage.get("loop",0)),int(voyage.get("actions",0))
        )
        if not incident_result.is_empty():
            voyage["incident_history"].append(incident_result)
            var incident_fact := "incident_" + str(incident_result.get("id","")).to_lower()
            _voyage_fact(incident_fact,str(incident_result.get("note","")),str(incident_result.get("source_type","DIRECT")))
            var actor := str(scene.get("speaker",""))
            _observe_personal_reason(actor,"incident:" + str(incident_result.get("id","")),str(incident_result.get("outcome","")))
            if bool(incident_result.get("foreknowledge",false)):
                var incident_id := str(incident_result.get("id",""))
                var used: Array = voyage.get("foreknowledge_used",[])
                if incident_id not in used:
                    used.append(incident_id)
                voyage["foreknowledge_used"] = used
                var observer := "noa" if "noa" in active_participants() else actor
                foreknowledge_reaction = AstraForeknowledgeModel.reaction_scene(observer,incident_id,int(voyage.get("loop",0)))
                voyage["foreknowledge_reactions"].append({"loop":int(voyage.get("loop",0)),"observer":observer,"incident":incident_id})
            voyage["active_incident"] = {}
    voyage["scene"] = {}
    # Choice-bearing story beats must advance the same mandatory story chain as
    # choice-free beats. Otherwise selecting a response can silently discard
    # the resolution/hook and leave EXPLORE impossible to finish.
    if bool(scene.get("story_resolution",false)):
        voyage["story_resolution_seen"] = true
        var story_hook := AstraVoyageContent.hook_thread(case_id)
        if not story_hook.is_empty():
            _voyage_scene(story_hook)
    elif bool(scene.get("story_hook",false)):
        voyage["story_hook_seen"] = true
    if voyage.get("scene",{}).is_empty() and not first_day_flow() and bool(voyage.get("goal_done",false)) and not bool(voyage.get("story_resolution_seen",false)):
        var pending_resolution := AstraVoyageContent.resolution_thread(case_id)
        if not pending_resolution.is_empty():
            _voyage_scene(pending_resolution)
    if not foreknowledge_reaction.is_empty():
        _voyage_scene(foreknowledge_reaction)
    elif not incident_result.is_empty():
        var after_scene := AstraStorylets055.incident_after_scene(str(incident_result.get("id","")),str(scene.get("speaker","")))
        if not after_scene.is_empty():
            _voyage_scene(after_scene)
    _deliver_due_consequence("IMMEDIATE")
    changed.emit()
    return true
func voyage_use_recorder() -> bool:
    if phase != "EXPLORE" or not voyage["scene"].is_empty() or voyage["room"] != "comms": return false
    if "recorder" not in voyage["inventory"] or "recorder" in voyage["used_items"]: return false
    voyage["used_items"].append("recorder")
    voyage["notes"].append("휴대 기록기에 별도 사본을 남겼다. 누군가 원본을 지워도 비교할 수 있다.")
    # A small, usable consequence in the subsequent deduction phase.
    flags["voyage_backup"] = true
    _voyage_scene({"id":"portable_copy","speaker":"", "action":"두 개의 재생 바가 같은 위치에서 멈춘다. 사본을 주머니에 넣는다.","lines":[],"choices":[]})
    _voyage_tick(false)
    changed.emit()
    return true

func voyage_follow(who: String) -> bool:
    if phase != "EXPLORE" or who not in voyage_people() or not voyage["scene"].is_empty(): return false
    voyage["companion"] = "" if voyage["companion"] == who else who
    changed.emit()
    return true


func _apply_consequence_memory(event: Dictionary) -> void:
    var tag := str(event.get("memory_tag",""))
    if tag == "":
        return
    var who := str(event.get("who",""))
    var stored := tag if ":" in tag else (who + ":" + tag if who != "" else tag)
    var tags: Array = voyage.get("memory_tags",[])
    if stored not in tags:
        tags.append(stored)
    voyage["memory_tags"] = tags

func _apply_consequence_event(event: Dictionary, allow_scene: bool = true) -> bool:
    if event.is_empty():
        return false
    _apply_consequence_memory(event)
    var timing := str(event.get("timing","DELAYED"))
    var stats_054: Dictionary = voyage.get("consequence_stats",{})
    stats_054[timing] = int(stats_054.get(timing,0)) + 1
    voyage["consequence_stats"] = stats_054
    var history_event: Dictionary = event.duplicate(true)
    history_event["applied_day"] = day
    history_event["visible_feedback"] = str(event.get("note","")) != "" and str(event.get("source_scene","")) != ""
    voyage["consequence_history"].append(history_event)
    var note := str(event.get("note",""))
    if note != "" and note not in voyage.get("notes",[]):
        voyage["notes"].append(note)
    var who := str(event.get("who",""))
    var bond_delta := float(event.get("bond_delta",0.0))
    if who != "" and bond_delta != 0.0:
        voyage["bonds"][who] = clampf(float(voyage["bonds"].get(who,0.0)) + bond_delta,-1.0,1.0)
    if not allow_scene:
        if note != "":
            _log("후속 · " + note)
        return false
    var followup_id := str(event.get("followup_scene",""))
    if followup_id != "":
        var followup := AstraVoyageContent.scene(followup_id)
        if not followup.is_empty():
            _voyage_scene(_apply_scene_variants(followup,str(followup.get("speaker",who))))
            return true
    if note != "" and phase == "EXPLORE":
        _voyage_scene({
            "id":"054_consequence_" + str(event.get("id","event")).replace(":","_"),
            "speaker":who,"tag":"consequence","category":"CONSEQUENCE",
            "family":"consequence_result","intent":"followup",
            "action":note,"lines":[],"choices":[]
        })
        return true
    return false

func _deliver_due_consequence(timing_filter: String = "") -> bool:
    var popped := AstraConsequenceModel.pop_due(
        voyage.get("consequence_queue",[]),int(voyage.get("actions",0)),
        int(voyage.get("loop",0)),day,timing_filter
    )
    voyage["consequence_queue"] = popped.get("queue",[])
    return _apply_consequence_event(popped.get("event",{}),true)

func _apply_next_day_consequences() -> void:
    if voyage.is_empty():
        return
    while true:
        var popped := AstraConsequenceModel.pop_due(
            voyage.get("consequence_queue",[]),int(voyage.get("actions",0)),
            int(voyage.get("loop",0)),day,"NEXT_DAY"
        )
        voyage["consequence_queue"] = popped.get("queue",[])
        var event: Dictionary = popped.get("event",{})
        if event.is_empty():
            break
        _apply_consequence_event(event,false)

func _autonomous_knowledge_share(actors: Array) -> void:
    if actors.size() < 2:
        return
    for source_raw in actors:
        var source := str(source_raw)
        for target_raw in actors:
            var target := str(target_raw)
            if source == target:
                continue
            for fact_id in AstraKnowledgeModel.known_facts(flags,source):
                if AstraKnowledgeModel.knows(flags,target,str(fact_id)) or AstraKnowledgeModel.is_public(flags,str(fact_id)):
                    continue
                var tendency := AstraLivingCrew.sharing_tendency(source,"unverified")
                var roll := _stable_noise("share:%s:%s:%s:%d" % [source,target,str(fact_id),int(voyage.get("actions",0))])
                if roll <= tendency:
                    if AstraKnowledgeModel.share_between(flags,str(fact_id),source,target,day,"autonomous_beat"):
                        AstraDecisionModel.append_trace(flags,AstraDecisionModel.trace(
                            source,"share",target,
                            [AstraDecisionModel.reason("operational_need",0.72,str(fact_id))],day
                        ))
                        var ownership: Dictionary = voyage.get("evidence_ownership",{})
                        if ownership.has(str(fact_id)):
                            var entry: Dictionary = ownership[str(fact_id)]
                            var knowers: Array = entry.get("knows",[])
                            if target not in knowers:
                                knowers.append(target)
                            entry["knows"] = knowers
                            ownership[str(fact_id)] = entry
                            voyage["evidence_ownership"] = ownership
                        return

func _should_defer_second_autonomous() -> bool:
    if voyage.get("autonomous_seen_loop",[]).size() < 1:
        return false
    if voyage.get("loop_focus_families",[]).size() < 2:
        return false
    for raw in voyage.get("loop_focus_events",[]):
        var event: Dictionary = raw
        if str(event.get("category","")) in ["INCIDENT","INCIDENT_AFTER","CONSEQUENCE"] or str(event.get("salience","")) == "FOLLOWUP":
            return true
    return false

func _maybe_autonomous_beat(room: String) -> bool:
    if room == "" or not voyage.get("scene",{}).is_empty():
        return false
    # Keep the queued beat intact. Dense loops merely defer a second ambient
    # opportunity so it can surface later if the loop becomes quiet.
    if _should_defer_second_autonomous():
        return false
    var queue: Array = voyage.get("activity_queue",[])
    var beat := AstraCrewActivityModel.room_beat(queue,room)
    if beat.is_empty():
        return false
    var beat_id := str(beat.get("id",""))
    for queued in queue.duplicate():
        if str(queued.get("id","")) == beat_id:
            queue.erase(queued)
            break
    voyage["activity_queue"] = queue
    voyage["autonomous_seen_loop"].append(beat_id)
    _autonomous_knowledge_share(Array(beat.get("actors",[])))
    var actors: Array = beat.get("actors",[])
    var speaker := str(actors[0]) if not actors.is_empty() else ""
    var tag := "overheard" if bool(beat.get("overheard",false)) else "autonomous"
    var choices: Array = []
    if bool(beat.get("overheard",false)):
        choices = [
            {"label":"끼어든다.","effect":"confront"},
            {"label":"말없이 듣는다.","effect":"wait"},
            {"label":"그냥 지나간다.","effect":"withhold"}
        ]
    _voyage_scene({
        "id":beat_id,"speaker":speaker,"participants":actors,"tag":tag,"category":"AUTONOMOUS",
        "family":"activity_" + beat_id,"intent":"overheard" if tag == "overheard" else "observed",
        "action":str(beat.get("action","")),"lines":Array(beat.get("lines",[])).duplicate(true),
        "line_relations":Array(beat.get("relations",[])).duplicate(),
        "choices":choices
    })
    return true

func _maybe_trigger_incident() -> bool:
    var loop_index := int(voyage.get("loop",0))
    var actions := int(voyage.get("actions",0))
    if not AstraIncidentModel.should_trigger(seed_value,loop_index,case_id,actions,voyage.get("incident_history",[]),voyage.get("active_incident",{})):
        return false
    var incident := AstraIncidentModel.select(seed_value,loop_index,case_id,voyage.get("incident_history",[]),active_participants())
    if incident.is_empty():
        return false
    voyage["active_incident"] = incident
    var incident_id := str(incident.get("id",""))
    var can_foreknow := AstraForeknowledgeModel.can_use(loop_index,incident_id,voyage.get("incident_history",[]),voyage.get("foreknowledge_used",[]))
    _voyage_scene(AstraIncidentModel.scene(incident,loop_index,can_foreknow))
    return true

func _voyage_tick(deliver: bool = true) -> void:
    voyage["actions"] = int(voyage["actions"])+1
    voyage["routine_state"] = AstraCrewRoutineModel.advance(
        voyage.get("routine_state",{}),int(voyage["actions"]),seed_value,case_id,roster,active_participants()
    )
    if not deliver or not voyage["scene"].is_empty(): return
    if _deliver_due_consequence():
        return
    if _maybe_trigger_incident():
        return
    for event in voyage["deferred"]:
        if int(event["due"]) > int(voyage["actions"]): continue
        var who := str(event["who"])
        var reactions := {
            "share":"앞서 건넨 기록 옆에 새로운 메모가 붙어 있다. 혼자서는 놓쳤던 시각이다.",
            "hide":"감춰 둔 사본을 동료가 발견했다. 질문 대신 두 파일을 나란히 놓는다.",
            "help":"동료가 다음 작업의 자리를 미리 비워 둔다. 이번에는 당신의 도움이 필요하다.",
            "defend":"대화가 막히자 동료가 당신 쪽으로 의자를 돌린다. 먼저 말을 끝내도록 기다린다.",
            "confront":"동료가 그때 그 질문을 다시 꺼낸다. 이번에는 더 짧게 답한다.",
            "withhold":"동료가 그 이야기는 꺼내지 않는다. 대신 다른 화제로 먼저 말을 건다.",
            "keep_copy":"동료가 자신도 따로 사본을 남겼다고 조용히 알려 준다.",
            "promise":"동료가 그때 약속한 것을 들고 돌아온다."
        }
        var action_text := str(reactions.get(str(event["effect"]),"동료가 앞선 선택에 반응해 다시 말을 건다."))
        if who == "mira":
            action_text = str({
                "share":"미라가 앞서 본 기록에서 사람 상태와 직접 연결되는 시각만 따로 표시해 둔다.",
                "hide":"미라는 감춘 이유를 캐묻지 않는다. 대신 상태와 관련된 부분만 다시 확인한다.",
                "help":"미라가 다음 검사 자리를 미리 비워 둔다. 당신이 도왔던 일을 기억한 듯하다.",
                "defend":"미라는 고맙다는 말보다 당신이 사용한 근거를 한 번 더 확인한다.",
                "confront":"미라는 그때의 질문을 피하지 않는다. 이번에는 먼저 필요한 기록을 꺼낸다.",
                "withhold":"미라는 더 묻지 않는다. 다만 상태를 숨기지는 말라는 메모만 남긴다.",
                "keep_copy":"미라는 사본 자체보다 누가 보았는지를 의료 차트 여백에 기록한다.",
                "promise":"미라는 약속을 말로 확인하지 않고, 지킬 수 있게 필요한 것을 먼저 준비해 둔다."
            }.get(str(event["effect"]),action_text))
        _voyage_scene({"id":"delayed_"+who+"_"+str(event["effect"]),"speaker":who,"action":action_text,"lines":[],"choices":[]})
        voyage["deferred"].erase(event)
        return
    var axis := AstraLivingCrew.dominant_player_axis(voyage.get("player_profile",{}))
    if axis != "" and axis not in voyage.get("pattern_remarks",[]):
        for observer in voyage_people():
            var observer_id := str(observer)
            var remark := AstraLivingCrew.player_remark(observer_id, axis)
            if remark == "":
                continue
            voyage["pattern_remarks"].append(axis)
            _voyage_scene({
                "id":"052_player_pattern_%s_%s" % [observer_id,axis],
                "speaker":observer_id,"tag":"reaction","category":"RELATIONSHIP",
                "family":"player_pattern_" + axis,"intent":"player_memory",
                "action":AstraJosa.i(name_of(observer_id))+" 당신이 무엇부터 확인하는지 보고 있다.",
                "lines":[[observer_id,remark]],"choices":[]
            })
            return
    if voyage["scene"].is_empty():
        _maybe_autonomous_beat(str(voyage.get("room","")))
        if not voyage["scene"].is_empty():
            return
    # Pity: main information is offered after six actions without the goal.
    if int(voyage["actions"]) >= 6 and not bool(voyage["goal_done"]):
        var chapter := AstraVoyageContent.chapter(case_id)
        _voyage_fact(str(chapter["fact"]),str(chapter["discovery"]))
        _voyage_scene({"id":"record_delivery","speaker":"noa","action":"노아가 복구한 기록을 가져왔다.","lines":[["noa","놓친 파일이 있어요. 같이 봐요."],["",chapter["discovery"]]],"choices":[]})

# Who the story actually needs met before a chapter can close, instead of
# the old one-size-fits-all "meet everyone" rule (§5 of the design notes). A
# chapter not listed here falls through to the general rule below — by
# ECHO_WARD the roster is doing enough that "meet the people who are awake"
# is itself the point, not busywork.
const REQUIRED_PEOPLE := {
    "DEAD_AIR": ["noa"],
    "GLASS_GARDEN": ["sena"]
}

const CURIOSITY_QUESTIONS := {
    "CALIBRATION": ["누가 수면실 잠금을 해제했나?", "실행자 서명은 왜 비어 있나?"],
    "DEAD_AIR": ["미라가 기억하는 지구 귀환 기록은 어디에서 왔나?", "두 목적지 문서가 모두 원본이라면 어느 항해를 기억한 걸까?"],
    "GLASS_GARDEN": ["세나와 준은 정말 예전부터 알던 사이였나?", "둘의 기억과 배치 기록 중 무엇이 먼저 달라졌나?"],
    "ECHO_WARD": ["소렌이 듣는 신호는 언제 녹음됐나?", "깨어 있지 않은 소렌의 목소리는 누구에게 보내진 걸까?"],
    "SILENT_ORBIT": ["ASTRA는 정말 19년 전에 도착했나?", "19년이 맞다면 왜 우리 몸은 그 시간을 지나지 않은 것처럼 보일까?"],
    "RED_SHIFT": ["출항보다 오래된 목적지 시료는 어디에서 왔나?", "마렌의 시료가 기억하는 환경은 어느 항해의 것일까?"],
    "LAST_LIGHT": ["서로 맞지 않는 사본이 모두 진짜일 수 있나?", "ASTRA가 끝까지 보존하려는 것은 항로일까, 사람의 기억일까?"]
}


const CURIOSITY_RELATED := {
    "calibration_question":["medbay","mira","power"],
    "calibration_question_after":["medbay","power"],
    "dead_air_question":["mira","noa","archive","destination"],
    "dead_air_question_after":["noa","archive","destination"],
    "glass_garden_question":["sena","rho","security"],
    "glass_garden_question_after":["sena","rho","security","archive"],
    "echo_ward_question":["vale","comms","signal"],
    "echo_ward_question_after":["vale","noa","comms","signal"],
    "silent_orbit_question":["eli","bridge","arrival"],
    "silent_orbit_question_after":["mira","eli","bridge","medbay"],
    "red_shift_question":["lyra","garden","sample"],
    "red_shift_question_after":["lyra","garden","archive"],
    "last_light_question":["noa","dax","archive"],
    "last_light_question_after":["mira","noa","archive","bridge"]
}

func _mark_changed_questions() -> void:
    if int(voyage.get("loop",0)) <= 0 or voyage.get("changes",[]).is_empty():
        return
    var questions: Dictionary = voyage.get("questions",{})
    var base_id := case_id.to_lower() + "_question"
    if questions.has(base_id):
        var entry: Dictionary = questions[base_id]
        if str(entry.get("status","")) in ["ANSWERED","PARTIAL"]:
            entry["status"] = "CHANGED"
            questions[base_id] = entry
    voyage["questions"] = questions

func _ensure_curiosity_questions() -> void:
    var questions: Dictionary = voyage.get("questions",{})
    var pair: Array = CURIOSITY_QUESTIONS.get(case_id,[])
    if pair.is_empty():
        return
    var base_id := case_id.to_lower() + "_question"
    if not questions.has(base_id):
        questions[base_id] = {"id":base_id,"case_id":case_id,"text":str(pair[0]),"status":"OPEN","related":Array(CURIOSITY_RELATED.get(base_id,[])).duplicate()}
    voyage["questions"] = questions

func _advance_curiosity_question(_fact_id: String) -> void:
    var pair: Array = CURIOSITY_QUESTIONS.get(case_id,[])
    var chapter := AstraVoyageContent.chapter(case_id)
    if pair.is_empty():
        pair = [str(chapter.get("goal","")),str(chapter.get("open_question",""))]
    var questions: Dictionary = voyage.get("questions",{})
    var base_id := case_id.to_lower() + "_question"
    if questions.has(base_id):
        var base: Dictionary = questions[base_id]
        base["status"] = "ANSWERED"
        questions[base_id] = base
    var next_id := base_id + "_after"
    var next_text := str(chapter.get("open_question",pair[1] if pair.size() > 1 else ""))
    if next_text != "" and not questions.has(next_id):
        questions[next_id] = {"id":next_id,"case_id":case_id,"text":next_text,"status":"OPEN","related":Array(CURIOSITY_RELATED.get(next_id,[])).duplicate()}
    if str(voyage.get("pinned_question","")) == base_id and questions.has(next_id):
        voyage["pinned_question"] = next_id
    voyage["questions"] = questions

func pin_question(question_id: String) -> bool:
    if voyage.is_empty():
        return false
    var questions: Dictionary = voyage.get("questions",{})
    if question_id == "":
        voyage["pinned_question"] = ""
        changed.emit()
        return true
    if not questions.has(question_id):
        return false
    var entry: Dictionary = questions[question_id]
    if str(entry.get("status","OPEN")) not in ["OPEN","PARTIAL","CHANGED"]:
        return false
    voyage["pinned_question"] = "" if str(voyage.get("pinned_question","")) == question_id else question_id
    changed.emit()
    return true

func pinned_question_entry() -> Dictionary:
    if voyage.is_empty():
        return {}
    var question_id := str(voyage.get("pinned_question",""))
    if question_id == "":
        return {}
    return Dictionary(voyage.get("questions",{}).get(question_id,{})).duplicate(true)

func current_questions() -> Array:
    if voyage.is_empty():
        return []
    var current: Array = []
    var others: Array = []
    for key in voyage.get("questions",{}):
        var entry: Dictionary = voyage["questions"][key]
        if str(entry.get("status","OPEN")) not in ["OPEN","PARTIAL","CHANGED"]:
            continue
        if str(entry.get("case_id","")) == case_id:
            current.append(entry.duplicate(true))
        else:
            others.append(entry.duplicate(true))
    current.append_array(others)
    var pinned_id := str(voyage.get("pinned_question",""))
    if pinned_id != "":
        current.sort_custom(func(a,b):
            if str(a.get("id","")) == pinned_id: return true
            if str(b.get("id","")) == pinned_id: return false
            return str(a.get("case_id","")) == case_id and str(b.get("case_id","")) != case_id
        )
    return current.slice(0, mini(3,current.size()))

func loop_difference_summary() -> Array:
    if voyage.is_empty():
        return []
    return Array(voyage.get("changes",[])).slice(0, mini(3,Array(voyage.get("changes",[])).size()))

func character_observations(npc_id: String) -> Array:
    var result: Array = []
    if voyage.is_empty() or npc_id not in voyage.get("met",[]):
        return result
    var baseline_limit := 3 if npc_id == "mira" else 2
    for item in AstraLivingCrew.baseline(npc_id).slice(0,baseline_limit):
        result.append(str(item))
    if npc_id == "mira":
        var seen_ever: Dictionary = voyage.get("seen_ever",{})
        if int(seen_ever.get("053_mira_mira_02",0)) > 0:
            result.append("다른 사람 검사를 끝낸 뒤에도 자기 상태 확인은 미루는 편이다.")
        if int(seen_ever.get("053_mira_mira_06",0)) > 0:
            result.append("의료실 음악을 아주 작게 틀어 두는 편이다.")
        if int(seen_ever.get("053_mira_mira_22",0)) > 0:
            result.append("[현재 기록] 위험 상황에서 당신보다 장비를 먼저 포기시킨 적이 있다.")
    var pairs: Array = []
    for other in roster:
        if str(other) == npc_id:
            continue
        var key := AstraCrewCatalog.pair_key(npc_id,str(other))
        if voyage.get("relationships",{}).has(key):
            pairs.append("%s %s" % [AstraJosa.wa(name_of(str(other))), relationship_status(npc_id,str(other))])
    if not pairs.is_empty():
        result.append("[현재 기록] " + str(pairs[0]))
    return result

func character_baseline(npc_id: String) -> Array:
    return AstraLivingCrew.baseline(npc_id)


# ---------------------------------------------------------------- 0.5.6 visible social feedback / observation Codex

func set_known_codex_entries(entry_ids: Array) -> void:
    if voyage.is_empty():
        return
    voyage["codex_known"] = entry_ids.duplicate()

func reconcile_codex_after_resume(entry_ids: Array) -> void:
    if voyage.is_empty():
        return
    voyage["codex_known"] = entry_ids.duplicate()
    var remaining: Array = []
    for raw_id in voyage.get("codex_unlocks_pending",[]):
        var entry_id: String = str(raw_id)
        if entry_id not in entry_ids:
            remaining.append(entry_id)
    voyage["codex_unlocks_pending"] = remaining

func _queue_codex_unlock(entry_id: String) -> void:
    if voyage.is_empty() or entry_id == "":
        return
    var known: Array = voyage.get("codex_known",[])
    var pending: Array = voyage.get("codex_unlocks_pending",[])
    if entry_id in known or entry_id in pending:
        return
    var entry := AstraCodex.character_entry(entry_id)
    if entry.is_empty():
        return
    pending.append(entry_id)
    voyage["codex_unlocks_pending"] = pending
    notice.emit("codex_unlock", {
        "id":entry_id,
        "character":str(entry.get("character","")),
        "scope":str(entry.get("scope","")),
        "title":str(entry.get("title",""))
    })

func _unlock_codex_from_scene(scene_id: String) -> void:
    for entry_id in AstraCodex.unlocks_for_scene(scene_id):
        _queue_codex_unlock(str(entry_id))

func codex_unlock_events() -> Array:
    var result: Array = []
    if voyage.is_empty():
        return result
    for entry_id in voyage.get("codex_unlocks_pending",[]):
        var entry := AstraCodex.character_entry(str(entry_id))
        if entry.is_empty():
            continue
        result.append({
            "id":str(entry.get("id","")),
            "character":str(entry.get("character","")),
            "scope":str(entry.get("scope","")),
            "title":str(entry.get("title",""))
        })
    return result

func _adjust_relationship(a_id: String, b_id: String, axis: String, amount: float, source_id: String, player_visible: bool, authored_social: bool = false) -> void:
    if voyage.is_empty() or a_id == "" or b_id == "" or a_id == b_id or axis not in AstraLivingCrew.AXES:
        return
    var key := AstraCrewCatalog.pair_key(a_id,b_id)
    var relationships: Dictionary = voyage.get("relationships",{})
    var relation: Dictionary = relationships.get(key,AstraLivingCrew.blank_relationship())
    var before := float(relation.get(axis,0.5))
    var after := clampf(before + amount,0.0,1.0)
    if is_equal_approx(before,after):
        return
    relation[axis] = after
    relationships[key] = relation
    voyage["relationships"] = relationships
    if not player_visible:
        return
    var feedback: Array = voyage.get("relationship_feedback",[])
    var direction := "UP" if after > before else "DOWN"
    feedback.append({
        "day":day,"a":a_id,"b":b_id,"axis":axis,"direction":direction,
        "magnitude":absf(after-before),"source":source_id,"visible":true,
        "authored_social":authored_social
    })
    while feedback.size() > 64:
        feedback.pop_front()
    voyage["relationship_feedback"] = feedback
    for entry_id in AstraCodex.relationship_unlocks(a_id,b_id,axis,direction):
        _queue_codex_unlock(str(entry_id))

func _relationship_feedback_text(axis: String, direction: String) -> String:
    match axis:
        "trust":
            return "서로의 판단을 조금 더 믿게 됐다." if direction == "UP" else "서로의 설명을 바로 믿지 못한다."
        "comfort":
            return "함께 있어도 전보다 편해 보인다." if direction == "UP" else "함께 있을 때 전보다 조심스러워 보인다."
        "tension":
            return "대화 뒤에도 긴장이 남았다." if direction == "UP" else "남아 있던 긴장이 조금 누그러졌다."
        "respect":
            return "업무 판단은 서로 인정한 것 같다." if direction == "UP" else "서로의 업무 판단에 의문이 남았다."
        "protectiveness":
            return "위험할 때 서로를 먼저 살피기 시작했다." if direction == "UP" else "서로를 먼저 감싸던 태도가 옅어졌다."
    return "서로를 대하는 태도가 달라졌다."

func _opinion_feedback_text(change: Dictionary) -> String:
    var actor := name_of(str(change.get("actor",change.get("voter",""))))
    var target_id := str(change.get("after",change.get("target","")))
    var target := name_of(target_id) if target_id != "" else ""
    var reason_tag := str(change.get("reason_tag","new_evidence"))
    if str(change.get("reason","")) != "":
        if target != "":
            return "%s · %s에 대한 판단을 바꿨다. %s" % [actor,target,str(change.get("reason",""))]
        return "%s · %s" % [actor,str(change.get("reason",""))]
    match reason_tag:
        "relationship_change":
            return "%s · 관계가 달라진 뒤 판단도 달라졌다." % actor
        "memory_change":
            return "%s · 앞선 행동을 다시 떠올린 뒤 판단을 바꿨다." % actor
        "uncertainty":
            return "%s · 확신이 줄어 판단을 다시 보게 됐다." % actor
        _:
            if target != "":
                return "%s · 새 기록을 본 뒤 %s에 대한 판단을 바꿨다." % [actor,target]
            return "%s · 새 기록을 본 뒤 판단을 바꿨다." % actor

func daily_social_summary(day_index: int = -1) -> Dictionary:
    var target_day := day if day_index < 0 else day_index
    var buckets := {}
    for raw in voyage.get("relationship_feedback",[]):
        var event: Dictionary = raw
        if not bool(event.get("visible",false)) or int(event.get("day",-1)) != target_day:
            continue
        var a := str(event.get("a",""))
        var b := str(event.get("b",""))
        var axis := str(event.get("axis",""))
        var pair_key := AstraCrewCatalog.pair_key(a,b)
        var key := pair_key + "|" + axis
        var bucket: Dictionary = buckets.get(key,{"a":a,"b":b,"axis":axis,"net":0.0,"authored":false})
        var sign := 1.0 if str(event.get("direction","UP")) == "UP" else -1.0
        bucket["net"] = float(bucket.get("net",0.0)) + float(event.get("magnitude",0.0)) * sign
        bucket["authored"] = bool(bucket.get("authored",false)) or bool(event.get("authored_social",false))
        buckets[key] = bucket
    var per_pair := {}
    for key in buckets:
        var bucket: Dictionary = buckets[key]
        var net := float(bucket.get("net",0.0))
        if absf(net) < 0.03 and not bool(bucket.get("authored",false)):
            continue
        var a := str(bucket.get("a",""))
        var b := str(bucket.get("b",""))
        var axis := str(bucket.get("axis",""))
        var direction := "UP" if net >= 0.0 else "DOWN"
        var pair_key := AstraCrewCatalog.pair_key(a,b)
        var score := absf(net) + (0.04 if bool(bucket.get("authored",false)) else 0.0)
        var candidate := {
            "a":a,"b":b,"pair":"%s ↔ %s" % [name_of(a),name_of(b)],
            "kind":axis,"direction":direction,
            "text":_relationship_feedback_text(axis,direction),
            "_score":score
        }
        if not per_pair.has(pair_key) or score > float(per_pair[pair_key].get("_score",0.0)):
            per_pair[pair_key] = candidate
    var relationship_changes: Array = per_pair.values()
    relationship_changes.sort_custom(func(a,b): return float(a.get("_score",0.0)) > float(b.get("_score",0.0)))
    for entry in relationship_changes:
        entry.erase("_score")
    relationship_changes = relationship_changes.slice(0,mini(3,relationship_changes.size()))
    var active_tensions: Array = []
    for entry in relationship_changes:
        if str(entry.get("kind","")) == "tension" and str(entry.get("direction","")) == "UP":
            active_tensions.append(entry.duplicate(true))
    var consequences: Array = []
    for raw in voyage.get("consequence_history",[]):
        var event: Dictionary = raw
        if int(event.get("applied_day",-1)) != target_day or not bool(event.get("visible_feedback",false)):
            continue
        var note := str(event.get("note",""))
        if note == "":
            continue
        var who := str(event.get("who",""))
        consequences.append({"character":name_of(who) if who != "" else "승무원","text":note})
        if consequences.size() >= 2:
            break
    var opinion_changes: Array = []
    for raw in voyage.get("opinion_changes",[]):
        var change: Dictionary = raw
        if int(change.get("day",-1)) != target_day or ("visible" in change and not bool(change.get("visible",true))):
            continue
        opinion_changes.append({"text":_opinion_feedback_text(change)})
        if opinion_changes.size() >= 2:
            break
    return {
        "day":target_day,
        "relationship_changes":relationship_changes,
        "active_tensions":active_tensions,
        "consequences":consequences,
        "opinion_changes":opinion_changes
    }

func night_feedback_summary() -> Dictionary:
    # Night is for immediate authored consequences only. Relationship/opinion
    # changes are deferred to the next briefing so the same sentence is not
    # repeated on two consecutive screens.
    var summary := daily_social_summary(day)
    summary["relationship_changes"] = []
    summary["active_tensions"] = []
    summary["opinion_changes"] = []
    summary["consequences"] = Array(summary.get("consequences",[])).slice(0,mini(2,Array(summary.get("consequences",[])).size()))
    return summary

func briefing_social_summary(day_index: int) -> Dictionary:
    # Briefing carries forward durable social interpretation, not the immediate
    # consequence line the player could already have read at night.
    var summary := daily_social_summary(day_index)
    summary["relationship_changes"] = Array(summary.get("relationship_changes",[])).slice(0,mini(2,Array(summary.get("relationship_changes",[])).size()))
    summary["opinion_changes"] = Array(summary.get("opinion_changes",[])).slice(0,mini(1,Array(summary.get("opinion_changes",[])).size()))
    summary["consequences"] = []
    return summary

func relationship_between(a_id: String, b_id: String) -> Dictionary:
    if voyage.is_empty():
        return AstraLivingCrew.blank_relationship()
    return Dictionary(voyage.get("relationships",{}).get(AstraCrewCatalog.pair_key(a_id,b_id),AstraLivingCrew.blank_relationship())).duplicate(true)

func relationship_status(a_id: String, b_id: String) -> String:
    return AstraLivingCrew.relationship_status(relationship_between(a_id,b_id))

func player_behavior_profile() -> Dictionary:
    return Dictionary(voyage.get("player_profile",AstraLivingCrew.blank_player_profile())).duplicate(true) if not voyage.is_empty() else AstraLivingCrew.blank_player_profile()

func voyage_can_finish() -> bool:
    if contact_flow():
        if phase != "EXPLORE" or not voyage.get("scene",{}).is_empty():
            return false
        if first_day_flow():
            return str(flags["contact_058"]["step"]) == "ready"
        return bool(voyage.get("goal_done",false)) and bool(voyage.get("story_resolution_seen",false)) and bool(voyage.get("story_hook_seen",false))
    if phase != "EXPLORE" or not bool(voyage.get("goal_done",false)) or not voyage.get("scene",{}).is_empty():
        return false
    # CALIBRATION teaches one direct human interaction. Jun/Noa/Daren are
    # introduced automatically after the power-panel inspection, so completion
    # must never require the player to hunt down four separate talk buttons.
    if case_id == AstraCaseCatalog.CALIBRATION:
        return "mira" in voyage.get("met",[])
    if REQUIRED_PEOPLE.has(case_id):
        for who in REQUIRED_PEOPLE[case_id]:
            if str(who) not in voyage.get("met",[]):
                return false
        return voyage.get("visits",[]).size() >= 2
    return voyage.get("visits",[]).size() >= 2 and voyage.get("met",[]).size() >= mini(4,roster.size())

func voyage_summary() -> Array:
    var result: Array = ["당신은 ASTRA의 탐사요원이다.","깨어 있는 동료 %d명 · 장기수면 %d명" % [roster.size(),8-roster.size()]]
    result.append_array(voyage.get("notes",[]).slice(-3))
    return result

func finish_voyage() -> bool:
    if not voyage_can_finish(): return false
    if first_day_flow():
        flags["contact_058"]["step"] = "done"
        voyage["story_resolution_seen"] = true
        voyage["story_hook_seen"] = true
    if case_id == AstraCaseCatalog.CALIBRATION:
        outcome = "CONTINUE"
        phase = "RESULT"
        final_report = {"outcome":"CONTINUE","roster":roster.duplicate(),"nulls":[],"total":0,"rank":"","null_isolated":0,"mission_complete":false,"loop_summary":{"text":str(AstraVoyageContent.chapter(case_id)["outro"])}}
    else:
        phase = "BRIEFING"
        if bool(flags.get("voyage_backup",false)):
            flags["mission_backup"] = true
    phase_changed.emit(phase)
    changed.emit()
    return true

func _updated_recent_signatures() -> Array:
    var result: Array = Array(voyage.get("recent_signatures",[])).duplicate()
    var signature := str(voyage.get("replay_signature",""))
    if signature != "":
        result.append(signature)
    while result.size() > 5:
        result.pop_front()
    return result

func _updated_visible_signatures() -> Array:
    var result: Array = Array(voyage.get("visible_signatures",[])).duplicate()
    var signature := AstraStoryletScheduler.visible_signature(
        str(voyage.get("social_theme","")), voyage.get("loop_hook",{}),
        Array(voyage.get("visible_scene_ids",[])).slice(0,5),
        Array(voyage.get("visible_rare_ids",[])).slice(0,2),
        ",".join(PackedStringArray(voyage.get("active_arcs",[])))
    )
    if signature != "":
        result.append(signature)
    while result.size() > 5:
        result.pop_front()
    return result

func _updated_memory_tags() -> Array:
    var result: Array = Array(voyage.get("memory_tags",[])).duplicate()
    var mira_stance := player_stance_on("mira")
    if int(mira_stance.get("accused",0)) > 0 and "mira:accused_mira" not in result:
        result.append("mira:accused_mira")
    if int(mira_stance.get("defended",0)) > 0 and "mira:defended_mira" not in result:
        result.append("mira:defended_mira")
    while result.size() > 24:
        result.pop_front()
    return result


func _updated_micro_arc_recent() -> Array:
    var result: Array = Array(voyage.get("micro_arc_recent",[])).duplicate()
    for chain_id in voyage.get("active_arcs",[]):
        if int(voyage.get("micro_arc_state",{}).get(str(chain_id),0)) > 0:
            result.append(str(chain_id))
    while result.size() > 6:
        result.pop_front()
    return result

func _updated_recent_focus_families() -> Array:
    var result: Array = Array(voyage.get("recent_focus_families",[])).duplicate()
    for family in voyage.get("loop_focus_families",[]):
        var value := str(family)
        if value == "":
            continue
        result.append(value)
    while result.size() > 8:
        result.pop_front()
    return result

func voyage_memory() -> Dictionary:
    if voyage.is_empty(): return {}
    var meaningful: bool = (not voyage.get("loop_focus_families",[]).is_empty()) or (not voyage.get("motive_observations",[]).is_empty()) or (not voyage.get("foreknowledge_reactions",[]).is_empty()) or (not voyage.get("cooperative_history",[]).is_empty())
    var next_momentum := AstraForeknowledgeModel.update_momentum(voyage.get("momentum_state",{}),meaningful)
    var echo: Dictionary = {}
    var bonds: Dictionary = voyage.get("bonds",{}).duplicate(true)
    for id in roster:
        var stance := player_stance_on(id)
        bonds[id] = clampf(float(bonds.get(id,0.0)) + int(stance.get("defended",0))*0.03 - int(stance.get("accused",0))*0.02,-1.0,1.0)
        var bond_value := float(bonds[id])
        var entry := _echo_entry(str(id))
        entry["familiarity"] = lerpf(float(entry["familiarity"]), clampf(absf(bond_value) + 0.15, 0.0, 1.0), 0.25)
        entry["trust"] = lerpf(float(entry["trust"]), clampf(bond_value, 0.0, 1.0), 0.2)
        entry["conflict"] = lerpf(float(entry["conflict"]), clampf(-bond_value, 0.0, 1.0), 0.2)
        entry["protection"] = float(entry["protection"]) * 0.92
        if not casualties.is_empty():
            entry["grief"] = clampf(float(entry["grief"]) + 0.25, 0.0, 1.0)
        echo[id] = entry
    var choices: Dictionary = voyage.get("choices",{}).duplicate(true)
    choices["accuse"] = int(stats.get("accusations",0))
    var chapters: Array = voyage.get("chapters",[]).duplicate()
    if case_id not in chapters: chapters.append(case_id)
    return {
        "mastered_guides":mastered_guides(),
        "first_review":str(flags.get("contact_058",{}).get("review_choice",voyage.get("previous_review",""))),
        "loops":int(voyage.get("loop",0))+1,
        "echo":echo,
        "bonds":bonds,
        "memories":voyage.get("memories",{}).duplicate(true),
        "past":voyage.get("past",{}).duplicate(true),
        "recent":voyage.get("recent",[]).duplicate(),
        "recent_families":voyage.get("recent_families",[]).duplicate(),
        "recent_focus_families":_updated_recent_focus_families(),
        "rare_recent":voyage.get("rare_recent",[]).duplicate(),
        "recent_signatures":_updated_recent_signatures(),
        "seen_ever":voyage.get("seen_ever",{}).duplicate(true),
        "relationships":voyage.get("relationships",{}).duplicate(true),
        "dialogue_memory_052":voyage.get("dialogue_memory_052",{}).duplicate(true),
        "player_profile":voyage.get("player_profile",{}).duplicate(true),
        "questions":voyage.get("questions",{}).duplicate(true),
        "evidence_ownership":voyage.get("evidence_ownership",{}).duplicate(true),
        "storylet_pity":voyage.get("storylet_pity",{}).duplicate(true),
        "memory_tags":_updated_memory_tags(),
        "promise_history":voyage.get("promise_history",[]).duplicate(),
        "autonomous_recent":(Array(voyage.get("autonomous_recent",[])) + Array(voyage.get("autonomous_seen_loop",[]))).slice(-8),
        "visible_signatures":_updated_visible_signatures(),
        "micro_arc_recent":_updated_micro_arc_recent(),
        "micro_arc_pity":voyage.get("micro_arc_pity",{}).duplicate(true),
        "consequence_carry":AstraConsequenceModel.carry_for_next_loop(
            voyage.get("consequence_queue",[]),int(voyage.get("loop",0))
        ),
        "pinned_question":str(voyage.get("pinned_question","")),
        "incident_history":voyage.get("incident_history",[]).duplicate(true),
        "scene_seen_counts":voyage.get("scene_seen_counts",{}).duplicate(true),
        "momentum_state":next_momentum,
        "delegation_history":voyage.get("delegation_history",[]).duplicate(true),
        "canon_post_arrival_seen":voyage.get("canon_post_arrival_seen",[]).duplicate(),
        "changes":voyage.get("changes",[]).duplicate(),
        "choices":choices,
        "losses":casualties.duplicate(),
        "chapters":chapters
    }
func voyage_visit_person(who: String) -> bool:
    if phase != "EXPLORE" or who not in roster or not voyage["scene"].is_empty(): return false
    # A trimmed-room chapter redirects to wherever that crewmate is actually
    # reachable this chapter (see AstraVoyageContent.home_room); everywhere
    # else this is just their real home room.
    var room := str(routine_state_for(who).get("location",AstraVoyageContent.home_room(who,case_id)))
    if room not in voyage_rooms():
        room = AstraVoyageContent.home_room(who,case_id)
    if not voyage_move(room,false): return false
    if who not in voyage["met"]:
        _voyage_scene(AstraVoyageContent.scene(who+"_awakening"))
        changed.emit()
    elif voyage["scene"].is_empty(): return voyage_talk(who)
    return true

func voyage_memory_talk(who: String) -> bool:
    if phase != "EXPLORE" or who not in voyage_people() or not voyage["scene"].is_empty(): return false
    var destination := str(voyage["memories"][who])
    var notes := {"지구 귀환":"귀환 후 검진 예약", "새 거주지":"새 거주지 배정 명부", "외곽 탐사":"외곽 탐사 임무서"}
    var scene := AstraVoyageContent.scene(who+"_memory")
    # Do not contradict the seed's memory with fixed, destination-specific lines.
    scene["lines"] = [["", "%s의 기억: %s. %s에도 같은 목적지가 적혀 있다." % [name_of(who),destination,str(notes[destination])]]]
    scene["action"] = AstraJosa.i(name_of(who))+" 기억을 뒷받침하는 문서를 가져온다."
    _voyage_scene(scene)
    changed.emit()
    return true


func _public_trace_support(target: String) -> float:
    for op in case_data.get("ops",[]):
        var sets: Array = []
        for clue in clues:
            if not bool(clue.get("public",false)) or str(clue.get("kind","")) != "trace" or str(clue.get("op","")) != str(op["id"]): continue
            var minute := int(clue.get("minute",0))
            if minute < int(case_data["window_start"]) or minute > int(case_data["window_end"]): continue
            sets.append(clue.get("members",[]))
        for a in range(sets.size()):
            for b in range(a+1,sets.size()):
                var intersection: Array = []
                for id in sets[a]:
                    if id in sets[b]: intersection.append(id)
                if intersection.size()==1 and intersection[0]==target: return 0.85
    return 0.0



# ---------------------------------------------------------------- 0.5.8 FIRST CONTACT compatibility
func contact_flow() -> bool:
    return flags.has("contact_058")

func first_day_flow() -> bool:
    return contact_flow() and case_id == AstraCaseCatalog.CALIBRATION

func campaign_day() -> int:
    return int(flags.get("contact_058",{}).get("day",AstraVoyageContent.campaign_day(case_id)))

func calendar_caption() -> String:
    return "항해 Day %d · 사건 %d일차 · 회차 %d" % [campaign_day(),day,int(voyage.get("loop",0))+1]

func crew_state(who: String) -> Dictionary:
    if who not in roster: return {"joined":false,"can_speak":false,"can_vote":false,"name_known":false}
    return {"joined":true,"join_day":int(AstraCrewCatalog.JOIN_DAY.get(who,1)),
        "arrival_processed":int(AstraCrewCatalog.JOIN_DAY.get(who,1)) < campaign_day() or flags.get("contact_058",{}).get("arrivals",[]).any(func(event): return str(event.get("id","")) == who),
        "introduced":who in flags.get("contact_058",{}).get("introduced",voyage.get("met",[])),"status":status_label(who),
        "location":str(routine_state_for(who).get("location",AstraVoyageContent.home_room(who,case_id))),
        "can_speak":who in active_participants(),"can_vote":who in eligible_voters(),"name_known":true}

func crew_count_caption() -> String:
    return "합류 동료 %d명 · 활동 %d명 · 탐사요원 1명" % [roster.size(),active_participants().size()]

func can_play_thread(scene: Dictionary) -> bool:
    var participants: Array = Array(scene.get("participants",[])).duplicate()
    for key in ["speaker","target"]:
        var who := str(scene.get(key,""))
        if who != "" and who not in participants: participants.append(who)
    for line in scene.get("lines",[]):
        if str(line[0]) != "" and str(line[0]) not in participants: participants.append(str(line[0]))
    for who in participants:
        if who not in active_participants(): return false
        var fact := str(scene.get("requires_fact",""))
        if fact != "" and not npc_knows_fact(str(who),fact): return false
    var visible := str(scene.get("action",""))+str(scene.get("lines",[]))+str(scene.get("choices",[]))
    for who in AstraCrewCatalog.ORDER:
        if who not in roster and (AstraCrewCatalog.name_ko(who) in visible or AstraCrewCatalog.latin_name(who) in visible): return false
    var seen_beats: Array = []
    for beat in scene.get("beats",[]):
        if str(beat.get("response_to","")) != "" and str(beat["response_to"]) not in seen_beats: return false
        var fact := str(beat.get("requires_fact",""))
        if fact != "" and not npc_knows_fact(str(beat.get("speaker","")),fact): return false
        seen_beats.append(str(beat.get("id","")))
    return true

func arrival_recap() -> String:
    if not contact_flow(): return ""
    var previous := str(voyage.get("previous_review",""))
    if case_id == "DEAD_AIR" and previous != "":
        var choice := "원본과 사본을 비교했고 이전 백업은 확인하지 못했습니다." if previous == "check_source" else "정비 가능성을 검토했고 작업자는 확인하지 못했습니다."
        return "탐사요원의 지난 기록: "+choice+" 실행자 칸 공백은 미해결입니다. 오늘은 세나가 확인한 통로를 따라 목적지 문서의 출처를 찾습니다."
    if int(voyage.get("loop",0)) > 0:
        return "이 화면의 항해 진행일에서 시작합니다. 지난 기록과 배운 조작은 보존됩니다. 동료의 현장 지식·행동 상태는 이번 사건에서 새로 확인합니다."
    return ""

func _first_inspect(point_id: String) -> bool:
    if phase != "EXPLORE" or not voyage.get("scene",{}).is_empty(): return false
    if str(flags["contact_058"]["step"]) not in ["inspect","ready"]: return false
    if point_id not in ["pod","status"]: return false
    var key := "medbay:"+point_id
    if key in voyage["inspected"]: return false
    voyage["inspected"].append(key)
    if point_id == "status":
        _voyage_fact("vitals",str(voyage_points()[1][5]))
        _voyage_scene({"id":"first_optional","speaker":"mira","action":str(voyage_points()[1][5]),"lines":[["mira","생명유지 상태도 직접 확인했네요. 이 검사는 무료예요. 잠금 이력은 제어 패널에서 따로 봐요."]],"choices":[]})
    else:
        _voyage_fact("power",AstraVoyageContent.FIRST_RECORD)
        AstraKnowledgeModel.make_public(flags,"power",active_participants(),day,"shared_panel")
        voyage["evidence_ownership"]["power"] = {"found_by":"player","knows":["player"]+active_participants(),"public":true}
        flags["contact_058"]["step"] = "discuss"
        guide_completed("investigate")
        guide_exposed("evidence")
        guide_exposed("choice")
        _voyage_scene(AstraVoyageContent.first_thread("first_panel"))
    changed.emit()
    return true

func _first_choice(scene_id: String, effect: String) -> bool:
    if scene_id != "first_panel" or effect not in ["check_source","check_maintenance"]: return false
    if flags["contact_058"].has("review_choice"): return false
    flags["contact_058"]["review_choice"] = effect
    flags["contact_058"]["step"] = "review"
    guide_completed("choice")
    guide_completed("evidence")
    voyage["scene"] = {}
    _voyage_scene(AstraVoyageContent.first_thread("first_source" if effect == "check_source" else "first_maintenance"))
    changed.emit()
    return true

func _complete_contact_scene(scene: Dictionary) -> void:
    if not contact_flow(): return
    var id := str(scene.get("id",""))
    if id == "first_wake":
        flags["contact_058"]["step"] = "inspect"
        flags["contact_058"]["introduced"] = roster.duplicate()
    elif id in ["first_source","first_maintenance"]:
        flags["contact_058"]["step"] = "ready"
        voyage["notes"].append("확인 방향: " + ("원본과 사본의 공백 비교. 이전 백업은 미확인." if id == "first_source" else "정비 가능성 확인. 작업자와 작업 이유는 미확인."))
        voyage["notes"].append("오늘의 결과: 생명유지 상태를 확인하고 다음 포드의 순차 각성을 준비했다. 강제 격리는 하지 않았다.")
    elif id.begins_with("arrival_"):
        guide_completed("arrival")
        flags["contact_058"]["introduced"] = Array(voyage.get("met",[])).duplicate()

func skip_contact_intro() -> bool:
    if not first_day_flow() or str(voyage.get("scene",{}).get("id","")) != "first_wake": return false
    var scene: Dictionary = voyage["scene"]
    voyage["scene"] = {}
    _complete_contact_scene(scene)
    changed.emit()
    return true

func contact_objective() -> Dictionary:
    if first_day_flow():
        match str(flags["contact_058"].get("step","awake")):
            "awake": return {"target":"continue","text":"장기수면 후 상태 점검 중입니다. 네 동료의 도움을 받아 포드 전원을 확인합니다."}
            "inspect": return {"target":"pod","text":"포드 제어 패널을 확인하세요. 남은 포드를 안전하게 열 수 있는지 알아봅니다. 핵심 기록 %d/1 · 이동·대화 무료" % (1 if "medbay:pod" in voyage.get("inspected",[]) else 0)}
            "discuss": return {"target":"choice","text":"확인한 사실과 원인 가설을 구별하세요. 두 질문 중 하나로 확인 방향을 정합니다."}
            "review": return {"target":"continue","text":"선택한 확인 방법의 답을 듣고, 오늘 해결한 것과 남은 질문을 정리합니다."}
            _: return {"target":"finish","text":"생명유지 상태 확인 완료. 실행자 칸 공백은 미해결입니다. 항해 Day 2에 다음 포드를 엽니다."}
    var chapter := AstraVoyageContent.chapter(case_id)
    if bool(voyage.get("goal_done",false)): return {"target":"finish","text":"핵심 기록을 확보했습니다. 함께 검토하거나 선택 대화를 이어 갈 수 있습니다."}
    var fact := str(chapter["fact"])
    for room in voyage_rooms():
        for point in AstraVoyageContent.ROOMS[room].get("points",[]):
            if str(point[4]) == fact:
                return {"target":str(point[0]),"room":room,"text":str(chapter["goal"])+" → "+str(AstraVoyageContent.ROOMS[room]["name"])+" · "+str(point[1])+" 확인 (이동·대화 무료)"}
    return {"target":"","text":str(chapter["goal"])}

func guide_exposed(id: String) -> void:
    if not contact_flow(): return
    var learning: Dictionary = flags["contact_058"]["learning"]
    if not learning.has(id): learning[id] = "exposed"

func guide_completed(id: String) -> void:
    if contact_flow(): flags["contact_058"]["learning"][id] = "completed"

func mastered_guides() -> Array:
    var result: Array = Array(flags.get("contact_058",{}).get("mastered",[])).duplicate()
    for id in flags.get("contact_058",{}).get("learning",{}):
        if flags["contact_058"]["learning"][id] == "completed" and id not in result: result.append(id)
    return result

func ballot_choice() -> Dictionary:
    return flags.get("contact_058",{}).get("ballot",flags.get("ballot_choice",{"state":"unselected","target":""})).duplicate()

func select_ballot(state: String, target: String = "") -> bool:
    if phase != "VOTE" or vote_cast or state not in ["target","abstain"]: return false
    if state == "target" and target not in eligible_vote_targets(): return false
    var choice := {"state":state,"target":target if state == "target" else ""}
    if contact_flow(): flags["contact_058"]["ballot"] = choice
    else: flags["ballot_choice"] = choice
    guide_exposed("abstain" if state == "abstain" else "vote")
    changed.emit()
    return true

func confirm_ballot() -> Dictionary:
    var choice := ballot_choice()
    if str(choice.get("state","")) not in ["target","abstain"]: return {"ok":false,"reason":"미선택"}
    return cast_vote(str(choice.get("target","")))

func submit_theory(suspects: Array, confidence: int = 60) -> bool:
    if phase != "VOTE" or vote_cast or suspects.size() != null_count: return false
    var unique: Array = []
    for id in suspects:
        if id not in roster or id in unique: return false
        unique.append(id)
    if theories.any(func(report): return int(report.get("day",0)) == day): return false
    theories.append({"day":day,"suspects":unique,"confidence":clampi(confidence,0,100),"explicit":true})
    guide_completed("report")
    changed.emit()
    return true

func vote_ballots() -> Array:
    if last_vote.has("ballots"): return Array(last_vote["ballots"]).duplicate(true)
    var rows: Array = []
    # Legacy recovery uses recorded voters, never the post-isolation living roster.
    for voter in last_vote.get("intentions",{}):
        var target := str(last_vote["intentions"][voter])
        rows.append({"voter":voter,"target":target,"state":"abstain" if target == "" else ("target" if target in roster else "error"),"weight":1})
    if vote_cast:
        var target := str(last_vote.get("player_target",""))
        rows.append({"voter":"player","target":target,"state":"abstain" if target == "" else "target","weight":PLAYER_VOTE_WEIGHT})
    return rows

func vote_counts() -> Dictionary:
    var result := {"eligible":0,"submitted":0,"targets":0,"abstained":0,"missing":0,"errors":0,"valid_weight":0}
    for ballot in vote_ballots():
        result["eligible"] += 1
        match str(ballot.get("state","error")):
            "target":
                result["targets"] += 1
                result["submitted"] += 1
                result["valid_weight"] += int(ballot.get("weight",1))
            "abstain":
                result["abstained"] += 1
                result["submitted"] += 1
            "unselected": result["missing"] += 1
            _: result["errors"] += 1
    return result

func vote_result_text() -> String:
    if str(last_vote.get("isolated","")) != "": return "유효한 투표 조건을 충족해 격리되었습니다."
    if last_vote.get("tally",{}).is_empty(): return "전원 기권으로 누구도 격리하지 않았습니다."
    if str(last_vote.get("result_reason","")) == "player_abstained": return "승무원 표는 기록되었지만 탐사요원이 기권해 누구도 격리하지 않았습니다."
    return "최다 득표 동률로 누구도 격리하지 않았습니다."

func _build_containment_aftermath(isolated: String) -> Array:
    var result: Array = []
    if isolated == "" or not crew.has(isolated):
        return result
    var member: AstraCrewMember = crew[isolated]
    result.append({"kind":"containment","speaker":isolated,"text":"%s의 장비가 회수되고 장기수면 포드가 잠긴다." % member.display_name})
    result.append({"kind":"target","speaker":isolated,"text":"“%s”" % str(ISOLATED_LINES.get(isolated,"…"))})
    var observer := ""
    for npc_id in active_participants():
        observer = str(npc_id)
        break
    if observer != "":
        var reactions := {
            "mira":"생체 상태는 제가 볼게요. 판단이 맞았는지는 아직 단정하지 마세요.",
            "rho":"문은 잠겼어. 이제 저 사람 없이 남은 기록이 어떻게 움직이는지 보자.",
            "dax":"한 명을 빼면 조건이 바뀌어. 그 뒤의 변화도 증거로 남겨야 해.",
            "noa":"격리 결정과 사실 확인은 다른 항목으로 기록할게요.",
            "sena":"포드는 잠겼어. 나머지 출입은 다시 확인한다.",
            "vale":"이제 신호가 달라지는지 들어 볼게요.",
            "eli":"사람 하나를 뺐다고 항로까지 맞아지는 건 아니야.",
            "lyra":"격리 뒤에도 상태가 달라지는지 제가 기록할게요."
        }
        var reaction: String = str(reactions.get(observer,"격리 뒤의 변화를 계속 확인하죠."))
        result.append({"kind":"observer","speaker":observer,"text":reaction})
    if member.role != "NULL":
        result.append({"kind":"consequence","text":"결정 직후 분위기가 굳는다. 일부 동료가 기록 공유에 더 조심스러워진다."})
    return result

# ---------------------------------------------------------------- 0.6.0 story recap / loop residue

func story_recap() -> Dictionary:
    var chapter := AstraVoyageContent.chapter(case_id)
    var resolution_seen := bool(voyage.get("story_resolution_seen",false)) if not voyage.is_empty() else false
    var hook_seen := bool(voyage.get("story_hook_seen",false)) if not voyage.is_empty() else false
    if first_day_flow() and str(flags.get("contact_058",{}).get("step","")) in ["ready","done"]:
        resolution_seen = true
        hook_seen = true
    var question := {}
    var qid := case_id.to_lower() + "_question_after"
    if not voyage.is_empty():
        question = Dictionary(voyage.get("questions",{}).get(qid,{})).duplicate(true)
    return {
        "resolution_seen":resolution_seen,
        "hook_seen":hook_seen,
        "resolved":str(chapter.get("resolved","")) if resolution_seen else "",
        "open_question":str(chapter.get("open_question","")) if resolution_seen else "",
        "outro":str(chapter.get("outro","")) if hook_seen else "",
        "next_hook":str(chapter.get("next_hook","")) if hook_seen else "",
        "question":question
    }

func loop_reset_framing() -> Dictionary:
    var framing := AstraVoyageContent.reset_framing(case_id).duplicate(true)
    framing["remembered"] = true
    framing["loop"] = int(voyage.get("loop",0)) + 1 if not voyage.is_empty() else 1
    return framing
