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

const PHASES := ["BRIEFING", "INVESTIGATION", "INTERROGATION", "MEETING", "VOTE", "NIGHT", "RESULT"]
const PHASE_LABELS := {
    "BRIEFING": "브리핑", "INVESTIGATION": "현장 조사", "INTERROGATION": "개인 심문",
    "MEETING": "공개 회의", "VOTE": "격리 투표", "NIGHT": "밤", "RESULT": "사건 종료"
}
const MAX_DAYS := 4
const BASE_INVESTIGATION_AP := 3
const BASE_TALK_AP := 3
const MEETING_ACTIONS := 2
const PLAYER_VOTE_WEIGHT := 2
const CONFIDE_TRUST := 0.6
const THEORY_DAY_FACTORS := [1.0, 1.0, 0.92, 0.84, 0.76]
const VOTE_NOISE := 0.16
const SNAPSHOT_PATH := "user://astra_session.cfg"
const SNAPSHOT_VERSION := 2
# 0.3.1 wrote version 1. It is still readable; the fields it never had are
# filled from the case template on load.
const SUPPORTED_SNAPSHOT_VERSIONS := [1, 2]
const FIELDS_ADDED_IN_040 := [
    "roster", "null_count", "max_days", "difficulty",
    "claim_ledger", "retractions", "dialogue_recent", "social_beats", "player_claims"
]
const SNAPSHOT_FIELDS := [
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
    "rho": "좋아. 가둬. 대신 진짜 범인 놓치면 가만 안 둔다.",
    "eli": "이번 판은 내가 지는 걸로 하지. 다음 수는 잘 둬.",
    "sena": "결정에 따르겠습니다. 선내 보안을 부탁드립니다.",
    "vale": "조사관님… 이게 정말 맞는 선택이길 바라요.",
    "noa": "마지막 기록이에요. ‘나는 끝까지 말을 바꾸지 않았다.’",
    "lyra": "괜찮아요… 다들, 서로를 너무 미워하지는 마요.",
    "dax": "결정 수용. 오류였다면 다음 계산에 반영해라."
}

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
        case_data = AstraCaseCatalog.resolve(case_id, seed_value)
        if roster.is_empty():
            roster = AstraCaseCatalog.roster(case_data)
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
        rng.seed = seed_value * 7919 + 17
        rng.state = int(cfg.get_value("session", "rng_state"))
        phase_changed.emit(phase)
        changed.emit()
        return true
    return false

func _valid_snapshot(cfg: ConfigFile) -> bool:
    var version := int(cfg.get_value("meta", "version", 0))
    if version not in SUPPORTED_SNAPSHOT_VERSIONS:
        return false
    for field in SNAPSHOT_FIELDS:
        # Absent is fine only for fields 0.3.1 never wrote; present-but-wrong-type
        # is still a corrupt save and is still rejected.
        if not cfg.has_section_key("session", field):
            if field in FIELDS_ADDED_IN_040:
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
    var saved_truth: Dictionary = cfg.get_value("session", "truth")
    for required in ["nulls", "claims", "positions", "null_ops", "trace_pairs"]:
        if not saved_truth.has(required):
            return false
    var saved_case_data := AstraCaseCatalog.get_case(saved_case)
    var expected_nulls := AstraCaseCatalog.null_count(saved_case_data)
    if not saved_truth["nulls"] is Array or saved_truth["nulls"].size() != expected_nulls:
        return false
    for required in ["claims", "positions", "null_ops", "trace_pairs"]:
        if not saved_truth[required] is Dictionary:
            return false
    # The roster to check against comes from the file when it has one and from
    # the case template otherwise; `self.roster` is still empty at this point.
    var saved_roster: Array = cfg.get_value("session", "roster", [])
    if saved_roster.is_empty():
        saved_roster = AstraCaseCatalog.roster(saved_case_data)
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
    return str(case_data.get("victim", ""))

func window_text() -> String:
    return AstraCaseCatalog.window_text(case_data)

func phase_label(phase_id: String = "") -> String:
    return str(PHASE_LABELS.get(phase_id if phase_id != "" else phase, phase))

func is_alive(npc_id: String) -> bool:
    var member := npc(npc_id)
    return member != null and member.is_alive()

func living_ids() -> Array:
    var result: Array = []
    for npc_id in roster:
        if crew[npc_id].is_alive():
            result.append(npc_id)
    return result

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
    var mission_bonus := 1 if bool(flags.get("mission_investigation", false)) and day > int(flags.get("mission_day", 0)) else 0
    return BASE_INVESTIGATION_AP + (1 if protocol == "ANALYST" else 0) + mission_bonus

func talk_ap_max() -> int:
    return BASE_TALK_AP + (1 if int(flags.get("rested_day", 0)) == day else 0) + (1 if protocol == "EMPATH" else 0) + (1 if bool(flags.get("mission_talk", false)) else 0) + int(AstraDifficulty.number(difficulty, "extra_talk_ap", 0.0))

func meeting_actions_max() -> int:
    return MEETING_ACTIONS + (1 if bool(flags.get("mission_meeting", false)) else 0)

func story_dispatch() -> String:
    var dispatches: Array = case_data.get("dispatches", [])
    return str(dispatches[mini(day - 1, dispatches.size() - 1)]) if not dispatches.is_empty() else ""

# Only visible facts contribute to the live checklist. Hidden roles are never
# counted here, including when an unaudited suspect has been isolated.
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
        {"id": "evidence", "label": "조사의 실마리 · 단서 5개 확보", "current": mini(found_clues().size(), 5), "target": 5, "complete": found_clues().size() >= 5},
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
    if crew.has(npc_id):
        selected_id = npc_id
        changed.emit()

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
            var unheard: Array = []
            for npc_id in living_ids():
                if not known_claims.has(npc_id):
                    unheard.append(name_of(npc_id))
            if not unheard.is_empty() and talk_ap > 0:
                return "아직 %s의 진술을 듣지 못했습니다." % ", ".join(PackedStringArray(unheard))
    # The meeting is deliberately not gated. Speaking there can be the wrong
    # move, and a tutorial that forces the player to accuse somebody teaches the
    # opposite of what this game wants. Investigation and interrogation are
    # gated because skipping those leaves nothing to reason with at all.
    return ""

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
    match phase:
        "BRIEFING": return "현장으로"
        "INVESTIGATION": return "승무원에게 확인하기"
        "INTERROGATION": return "공개 회의 소집" if pending_event.is_empty() else "개인 면담에 먼저 답하세요"
        "MEETING": return "격리 투표로"
        "VOTE": return "밤으로" if vote_cast else "투표를 먼저 확정하세요"
        "NIGHT": return "다음 날 아침으로" if night_done else "밤 행동을 먼저 고르세요"
    return ""

func advance() -> void:
    if not can_advance():
        return
    match phase:
        "BRIEFING": _enter("INVESTIGATION")
        "INVESTIGATION": _enter("INTERROGATION")
        "INTERROGATION": _enter("MEETING")
        "MEETING": _enter("VOTE")
        "VOTE": _enter("RESULT" if outcome != "" else "NIGHT")
        "NIGHT":
            if outcome != "":
                _enter("RESULT")
            else:
                _start_next_day()

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
        "VOTE": return "한 명을 고른 뒤 투표하세요. 득표는 개표 후 공개됩니다. 동률에 조사관의 대상이 있으면 그 대상을 우선합니다."
        "NIGHT": return "밤에 할 수 있는 일은 하나입니다. 보호·감시·기록 백업·휴식 중 선택하세요."
        "RESULT": return "사건 재구성이 끝났습니다. 진실과 그날의 선택을 돌아보세요."
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
    day += 1
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
    options.append({"intent": "WITNESS", "label": "그때 누구를 봤나요?", "hint": "목격한 사람을 묻습니다. 다른 사람의 알리바이를 무너뜨릴 수 있습니다.", "enabled": enabled})
    options.append({"intent": "TIMELINE", "label": "그 직전엔 무엇을 했죠?", "hint": "앞뒤 행적을 묻습니다. 시간이 비는 구간이 드러납니다.", "enabled": enabled})
    if not found_clues().is_empty():
        options.append({"intent": "EVIDENCE", "label": "증거를 보여 준다…", "hint": "확보한 기록을 보여 주고 반응을 봅니다.", "enabled": enabled})
    if has_contradiction_on(npc_id):
        options.append({"intent": "CONTRADICTION", "label": "기록과 다른 말을 짚는다", "hint": "어긋난 지점을 추궁합니다. 사정이 있으면 털어놓고, 실행자는 실언할 수 있습니다.", "enabled": enabled, "key": true})
    options.append({"intent": "SUSPECT", "label": "다른 사람에 대한 생각을 묻는다", "hint": "누구를 의심하는지와 그 이유를 듣습니다.", "enabled": enabled})
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
    var result := {"ok": true, "npc_id": npc_id, "intent": intent, "lines": []}
    var question := str(QUESTION_TEXT.get(intent, "이 배에서 당신이 지키고 싶은 것은 무엇인가요?"))
    if intent == "EVIDENCE":
        question = "이 기록을 보세요. ‘%s’" % str(clue_by_id(clue_id).get("title", ""))
    _transcript(npc_id, "player", question)

    match intent:
        "PERSONAL":
            flags["personal_%s_%d" % [npc_id, day]] = true
            var line := AstraStory.personal(npc_id, seed_value + day)
            _transcript(npc_id, npc_id, line)
            result["lines"].append({"speaker": npc_id, "text": line})
            member.adjust_trust(0.05)
            member.adjust_stress(-0.04)
        "ALIBI": _ask_alibi(member, result)
        "EVIDENCE": _ask_evidence(member, clue_by_id(clue_id), result)
        "CONTRADICTION": _ask_contradiction(member, result)
        "SUSPECT": _ask_suspect(member, result, false)
        "REASSURE": _ask_reassure(member, result)
        "PRESSURE": _ask_pressure(member, result)
        "CONFIDE": _ask_suspect(member, result, true)
        "WITNESS", "TIMELINE", "TRUST": _ask_open(member, intent, result)

    member.refresh_expression()
    member.remember("DAY %d · 조사관 질문 %s" % [day, intent])
    _recompute_contradictions()
    changed.emit()
    return result

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
    _transcript(member.id, member.id, text)
    result["lines"].append({"speaker": member.id, "text": text})
    return text

func _narrate(member: AstraCrewMember, text: String, result: Dictionary) -> void:
    _transcript(member.id, "narration", text)
    result["lines"].append({"speaker": "narration", "text": text})

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

func _ask_evidence(member: AstraCrewMember, clue: Dictionary, result: Dictionary) -> void:
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

func _ask_contradiction(member: AstraCrewMember, result: Dictionary) -> void:
    var is_herring := str(truth.get("herring", "")) == member.id
    if is_herring and not member.secret_revealed:
        if member.trust >= 0.5 or member.stress >= 0.65:
            _say(member, "contra_confess", {}, result)
            var secret := str(member.info.get("secret", ""))
            _transcript(member.id, member.id, secret)
            result["lines"].append({"speaker": member.id, "text": secret})
            member.secret_revealed = true
            member.adjust_trust(0.06)
            member.adjust_stress(-0.12)
            stats["secrets"] = int(stats.get("secrets", 0)) + 1
            var true_pos := str(truth["positions"].get(member.id, ""))
            known_claims[member.id] = {"position": true_pos, "companions": [], "day": day, "revised": true}
            _log("숨긴 사정 · %s|i 진술을 정정했다: 실제로는 %s에 혼자 있었다." % [member.display_name, room_name(true_pos)])
            result["secret"] = true
            notice.emit("secret", {"npc_id": member.id})
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
    member.adjust_stress(0.17)
    member.adjust_trust(-0.06)
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
        if events_seen.has(npc_id) or not AstraPrivateEvents.has_event(npc_id):
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
    pending_event = AstraPrivateEvents.build(chosen, victim_name())
    events_seen[chosen] = true
    selected_id = chosen
    _log("개인 면담 요청 · %s" % name_of(chosen))
    notice.emit("private_event", {"npc_id": chosen})

func resolve_private_event(choice_index: int) -> Dictionary:
    if pending_event.is_empty():
        return {"ok": false}
    var choices: Array = pending_event.get("choices", [])
    if choice_index < 0 or choice_index >= choices.size():
        return {"ok": false}
    var npc_id := str(pending_event.get("npc_id", ""))
    var member := npc(npc_id)
    var choice: Dictionary = choices[choice_index]
    var effect := str(choice.get("effect", ""))
    var result := {"ok": true, "npc_id": npc_id, "effect": effect, "lines": [], "text": ""}
    _transcript(npc_id, "player", str(choice.get("label", "")))
    var lying := member.is_null() or (str(truth.get("herring", "")) == npc_id and not member.secret_revealed)

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
            return "베일이 보여 준 기록은 공식 로그와 일치했다. 단서 ‘%s’를 확보했다." % str(picked.get("title", ""))
        return "베일이 기록을 펼쳤지만 이미 확인한 내용뿐이었다."
    var fake := _fabricate_group(member.id)
    if fake.is_empty():
        return "베일이 기록을 펼쳤지만 의미 있는 내용은 없었다."
    var op_id := str(truth["null_ops"].get(member.id, ""))
    var clue := _add_testimony_clue("planted", member.id, "베일의 신호 해석",
        "베일의 해석: %s 직전 외부로 나간 신호에 %s 서명 조각이 섞여 있다. 해당: %s. (출처: 베일 개인 분석)" % [op_name(op_id), AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"])), names_of(AstraCrewCatalog.group_members_in(str(fake["category"]), str(fake["group"]), roster))],
        str(fake["category"]), str(fake["group"]), op_id, member.id, true)
    result["clue"] = clue
    return "베일이 자신만의 해석을 담은 기록을 건넸다. 공식 로그로는 확인되지 않는다."

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

func _transcript(npc_id: String, speaker: String, text: String) -> void:
    if not transcripts.has(npc_id):
        transcripts[npc_id] = []
    transcripts[npc_id].append({"speaker": speaker, "text": _josa_inline(text), "day": day})
    if transcripts[npc_id].size() > 120:
        transcripts[npc_id].pop_front()

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
        # Noa keeps the records and Dax argues from patterns, so they notice
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
        text = "조사관. %s 얘기가 나올 때마다 먼저 끼어드시는군요. 회의 %d번 모두요." % [target_name, int(remark["count"])]
    else:
        text = "조사관은 %s|eul %d번 지목했습니다. 다른 이름은 한 번도 나오지 않았습니다." % [target_name, int(remark["count"])]
    _feed_line(speaker, "player", text, "react")
    _record_beat("player_pattern", [speaker], "%s가 조사관의 행동 패턴을 지적했다." % name_of(speaker))

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

    for npc_id in living_ids():
        if public_claims.has(npc_id):
            continue
        var claim := current_claim(npc_id)
        var companions: Array = claim.get("companions", [])
        var key := "m_alibi_with" if not companions.is_empty() else "m_alibi_alone"
        _feed_npc(npc_id, key, {"pos": room_name(str(claim.get("position", ""))), "mates": AstraJosa.join_names(_names(companions))}, "alibi", "")
        public_claims[npc_id] = true
        known_claims[npc_id] = {"position": str(claim.get("position", "")), "companions": companions.duplicate(), "day": day}

    _run_disputes()

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
    _suspicion_round(maxi(2, int(AstraDifficulty.number(difficulty, "meeting_lines", 7.0)) - 4))
    _log("공개 회의 · 발언 %d건" % meeting_feed.size())

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

func _run_disputes() -> void:
    var positions: Dictionary = truth.get("positions", {})
    var spoken := 0
    var budget := _dispute_budget()
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
            # Over budget, or the same voice twice running: the suspicion still
            # moves, it simply is not staged as another speech.
            if spoken >= budget or witness_id == last_speaker:
                continue
            spoken += 1
            last_speaker = witness_id
            if heard:
                _feed_npc(witness_id, "m_dispute_absent", {"pos": room_name(witness_pos), "target": name_of(target_id)}, "dispute", target_id)
            else:
                _feed_npc(witness_id, "m_dispute_companion", {"target": name_of(target_id)}, "dispute", target_id)
            _mark_dispute_public(witness_id, target_id)
    # Nulls who share a claimed place with honest crew push back with the same accusation.
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
            if spoken >= budget + 1 or null_id == last_speaker:
                continue
            spoken += 1
            last_speaker = null_id
            _feed_npc(null_id, "m_dispute_absent", {"pos": room_name(str(null_claim.get("position", ""))), "target": name_of(crew_id)}, "dispute", crew_id)
            _mark_dispute_public(null_id, crew_id)

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

func _suspicion_round(max_speakers: int) -> void:
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
        if count >= max_speakers:
            break
        if float(item["value"]) < 0.34 and count > 0:
            break
        var speaker_id := str(item["id"])
        var target_id := str(item["target"])
        # Nobody follows straight on from themselves. Two consecutive cards with
        # the same face reads as a bug even when the content differs.
        if speaker_id == last_speaker:
            continue
        last_speaker = speaker_id
        _feed_npc(speaker_id, "m_suspect", {"target": name_of(target_id), "reason": AstraDialogue.reason_text(str(item["reason"]))}, "suspect", target_id)
        _crowd_shift(target_id, 0.05, speaker_id)
        meeting_pushers[speaker_id] = float(meeting_pushers.get(speaker_id, 0.0)) + 0.6
        count += 1

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

func _feed_npc(npc_id: String, key: String, params: Dictionary, kind: String, target_id: String) -> void:
    var text := AstraDialogue.line_fresh(npc_id, key, params, dialogue_recent, rng.randf())
    if text == "":
        return
    _feed_line(npc_id, target_id, text, kind)

const FEED_KIND_TO_CLAIM := {
    "alibi": AstraClaimLedger.KIND_POSITION,
    "dispute": AstraClaimLedger.KIND_WITNESS,
    "suspect": AstraClaimLedger.KIND_ACCUSE,
    "defense": AstraClaimLedger.KIND_DENY,
    "calm": AstraClaimLedger.KIND_DEFEND,
    "record": AstraClaimLedger.KIND_WITNESS
}

func _feed_line(speaker_id: String, target_id: String, text: String, kind: String) -> void:
    var entry := {"speaker": speaker_id, "target": target_id, "text": _josa_inline(text), "kind": kind, "day": day}
    meeting_feed.append(entry)
    # Everything said in front of everyone goes on the record. This is what lets
    # a later meeting quote an earlier one instead of starting from nothing.
    if speaker_id != "player" and FEED_KIND_TO_CLAIM.has(kind):
        var claim := current_claim(speaker_id) if kind == "alibi" else {}
        _record_claim(speaker_id, str(FEED_KIND_TO_CLAIM[kind]), AstraClaimLedger.SCOPE_PUBLIC, str(entry["text"]), {
            "target": target_id,
            "position": str(claim.get("position", "")),
            "companions": claim.get("companions", [])
        })
    notice.emit("meeting_line", entry)

func present_clue(clue_id: String) -> Dictionary:
    var clue := clue_by_id(clue_id)
    if phase != "MEETING" or meeting_actions_left <= 0 or clue.is_empty() or not bool(clue.get("found", false)) or bool(clue.get("public", false)) or outcome != "":
        return {"ok": false}
    meeting_actions_left -= 1
    clue["public"] = true
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
        _feed_line("player", target_id, "%s의 거짓 진술에는 사건과 무관한 사정이 있었습니다. 실제로는 %s에 혼자 있었습니다. 제가 직접 확인했습니다." % [name_of(target_id), true_pos], "player")
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

func vote_intentions() -> Dictionary:
    var result := {}
    var crew_votes := {}
    var living := living_ids()
    for npc_id in living:
        var member: AstraCrewMember = crew[npc_id]
        if member.is_null():
            continue
        var target := ""
        var best := -9.0
        for other in living:
            if other == npc_id:
                continue
            var value := member.get_suspicion(other) - member.get_affinity(other) * 0.12 + (_stable_noise(npc_id + other) - 0.5) * VOTE_NOISE
            if value > best:
                best = value
                target = other
        result[npc_id] = target
        crew_votes[target] = int(crew_votes.get(target, 0)) + 1
    for npc_id in living:
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
        result[npc_id] = target
    return result

func vote_tally(include_player_target: String = "") -> Dictionary:
    var tally := {}
    var intentions := vote_intentions()
    for voter in intentions.keys():
        var target := str(intentions[voter])
        if target != "":
            tally[target] = int(tally.get(target, 0)) + 1
    if include_player_target != "" and is_alive(include_player_target):
        tally[include_player_target] = int(tally.get(include_player_target, 0)) + PLAYER_VOTE_WEIGHT
    return tally

func cast_vote(target_id: String, theory_suspects: Array = [], confidence: int = 60) -> Dictionary:
    if phase != "VOTE" or vote_cast or outcome != "":
        return {"ok": false}
    if target_id != "" and not is_alive(target_id):
        return {"ok": false}
    if theory_suspects.size() == 2 and str(theory_suspects[0]) != str(theory_suspects[1]):
        theories.append({"day": day, "suspects": [str(theory_suspects[0]), str(theory_suspects[1])], "confidence": clampi(confidence, 0, 100)})
    var intentions := vote_intentions()
    var tally := vote_tally(target_id)
    var top := 0
    for candidate in tally.keys():
        top = maxi(top, int(tally[candidate]))
    var leaders: Array = []
    for candidate in tally.keys():
        if int(tally[candidate]) == top:
            leaders.append(str(candidate))
    var isolated := ""
    if leaders.size() == 1:
        isolated = str(leaders[0])
    elif target_id in leaders:
        isolated = target_id
    vote_cast = true
    last_vote = {"tally": tally, "intentions": intentions, "player_target": target_id, "isolated": isolated, "top": top, "tie": leaders.size() > 1 and isolated == ""}
    if isolated != "":
        var member: AstraCrewMember = crew[isolated]
        member.status = AstraCrewMember.STATUS_ISOLATED
        isolations.append({"day": day, "id": isolated, "votes": top, "role": member.role})
        _log("격리 · %s (%d표)" % [member.display_name, top])
        last_vote["last_words"] = str(ISOLATED_LINES.get(isolated, "…"))
        _transcript(isolated, isolated, str(ISOLATED_LINES.get(isolated, "…")))
        for observer_id in living_ids():
            crew[observer_id].adjust_stress(0.04)
    else:
        _log("투표 무산 · 동률로 아무도 격리되지 않았다.")
    _check_end("vote")
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
    var protect: Array = living_ids()
    var secure: Array = []
    for room_id in room_ids():
        if int(room_status(room_id).get("remaining", 0)) > 0:
            secure.append(room_id)
    return {"protect": protect, "secure": secure, "backup": room_ids(), "rest": ["self"]}

func choose_night_action(kind: String, target: String) -> Dictionary:
    if phase != "NIGHT" or night_done or outcome != "":
        return {"ok": false}
    var options := night_options()
    if kind not in ["protect", "secure", "backup", "rest"] or target not in options.get(kind, []):
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
            "lie": bool(claim.get("lie", false)), "herring": str(truth.get("herring", "")) == npc_id,
            "op": op_name(str(truth["null_ops"].get(npc_id, "")))
        })
    var title := ""
    var subtitle := ""
    match outcome:
        "WIN":
            title = "ASTRA 안정화"
            subtitle = "두 명의 Null을 모두 격리했다. 선내 신호가 다시 맑아진다."
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
        "story": str(case_data.get("story_outro", "")) if outcome == "WIN" else "재구성이 중단됐다. 확보한 기록과 복구 임무는 아카이브에 남는다. 새로운 시드로 다시 조사하거나 다음 사건에서 여정을 이어갈 수 있다."
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
        innocent_lie = "%s 거짓말했지만 Null이 아니었다. 숨긴 것은 사건과 무관한 사정이었다." % AstraJosa.eun(name_of(herring_id))
    var decisive := ""
    if not last_vote.is_empty():
        var tally: Dictionary = last_vote.get("tally", {})
        var sorted_ids: Array = tally.keys()
        sorted_ids.sort_custom(func(a, b): return int(tally[a]) > int(tally[b]))
        if sorted_ids.size() >= 2 and int(tally[sorted_ids[0]]) - int(tally[sorted_ids[1]]) <= PLAYER_VOTE_WEIGHT:
            decisive = "마지막 투표는 %s표 차였다. 조사관의 표가 결과를 갈랐다." % str(int(tally[sorted_ids[0]]) - int(tally[sorted_ids[1]]))
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
    if matched == 2 and confidence >= 70:
        calibration = 10
    elif matched == 0 and confidence >= 70:
        calibration = -10
    elif matched == 1 and confidence >= 40 and confidence <= 70:
        calibration = 5
    var day_factor: float = float(THEORY_DAY_FACTORS[clampi(int(theory.get("day", 1)), 0, THEORY_DAY_FACTORS.size() - 1)])
    var grade := clampi(int(round((matched * 35 + evidence + calibration) * day_factor)), 0, 100)
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
        "INVESTIGATION": return "%02d:%02d · 선내 탐색" % [12 + (investigation_ap_max() - investigation_ap) / 2, 30 * ((investigation_ap_max() - investigation_ap) % 2)]
        "INTERROGATION": return "늦은 오후 · " + ("대화할 여유가 있다" if talk_ap > 1 else ("회의가 가까워진다" if talk_ap == 1 else "회의 시간이 되었다"))
        "MEETING": return "저녁 회의 · " + ("발언할 기회가 있다" if meeting_actions_left > 0 else "이제 판단할 시간")
        "VOTE": return "21:00 · 격리 판단"
        "NIGHT": return "00:30 · 소등"
        "RESULT": return "사건 재구성 종료"
    return "08:00 · 아침 보고"

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
    var rooms: Array = []
    match phase:
        "BRIEFING":
            text = "사건 시각과 조작이 일어난 장소를 확인하세요." if day == 1 else "밤사이 무슨 일이 있었는지 확인하세요."
        "INVESTIGATION":
            rooms = recommended_rooms()
            if found_clues().is_empty():
                text = ("%s 먼저 살펴보세요." % AstraJosa.eul(room_name(str(rooms[0])))) if not rooms.is_empty() else "장소를 골라 조사 지점을 살펴보세요."
            elif investigation_ap > 0:
                text = "흔적을 하나 더 찾아 명단을 좁히세요." if not rooms.is_empty() else "남은 조사 지점을 살펴보세요."
            else:
                text = "조사 시간이 끝났습니다. 승무원에게 확인하러 가세요."
        "INTERROGATION":
            if not pending_event.is_empty():
                text = "%s|i 따로 할 말이 있습니다." % name_of(str(pending_event.get("npc_id", "")))
            elif known_claims.is_empty():
                text = "먼저 한 사람에게 그 시각 어디에 있었는지 물어보세요."
            else:
                var unheard := ""
                for npc_id in living_ids():
                    if not known_claims.has(npc_id):
                        unheard = npc_id
                        break
                if unheard != "" and talk_ap > 0:
                    text = "%s의 진술을 아직 듣지 못했습니다." % name_of(unheard)
                elif not contradictions.is_empty() and talk_ap > 0:
                    text = "%s의 진술이 기록과 어긋납니다. 짚어 보세요." % name_of(str(contradictions[0].get("targets", [""])[0]))
                else:
                    text = "회의를 소집할 준비가 됐습니다."
        "MEETING":
            if meeting_actions_left > 0:
                text = "확보한 단서를 공개하거나, 한 사람을 지목하거나 변호할 수 있습니다."
            else:
                text = "발언 기회를 다 썼습니다. 투표로 넘어가세요."
        "VOTE":
            text = "이름을 고르고 투표를 확정하세요." if not vote_cast else "개표 결과를 확인하세요."
        "NIGHT":
            text = "오늘 밤 지킬 것을 하나 고르세요." if not night_done else "아침 보고를 확인하세요."
        "RESULT":
            text = "실제로 무슨 일이 있었는지 확인하세요."
    return {"text": _josa_inline(text), "rooms": rooms, "binding": binding}

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
    var alive := living_ids().size()
    parts.append("남은 승무원 %d명" % alive)
    if max_days > 1:
        var left := max_days - day
        if left <= 0:
            parts.append("오늘이 마지막 날")
        else:
            parts.append("판단할 날 %d일 남음" % (left + 1))
    if not casualties.is_empty():
        parts.append("사망·격리 %d명" % (casualties.size() + isolations.size()))
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
# player could see in their notes that Rho claimed the lounge while Sena placed
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
