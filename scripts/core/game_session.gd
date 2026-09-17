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

const PROTOCOLS := {
    "ANALYST": {"name": "분석관", "summary": "매일 현장 조사 행동력 +1", "detail": "흔적을 더 많이 모아 교집합으로 범인을 좁히는 플레이."},
    "EMPATH": {"name": "공감관", "summary": "매일 심문 행동력 +1 · 초기 신뢰 상승 · 거짓말 징후를 더 잘 읽음", "detail": "대화와 신뢰로 숨긴 사정과 실언을 끌어내는 플레이."},
    "AUDITOR": {"name": "감사관", "summary": "검시 기록을 들고 시작 · 매일 밤 격리된 사람의 정체를 자동으로 감사", "detail": "확정된 정보로 오판을 빠르게 바로잡는 플레이."}
}

const QUESTION_TEXT := {
    "ALIBI": "사건 시각에 어디 있었습니까? 누구와 있었죠?",
    "EVIDENCE": "이 기록을 보세요.",
    "CONTRADICTION": "진술과 기록이 맞지 않습니다. 설명해 주시죠.",
    "SUSPECT": "지금 누가 가장 의심스럽습니까?",
    "REASSURE": "괜찮습니다. 당신을 몰아세우려는 게 아닙니다. 천천히 말해도 됩니다.",
    "PRESSURE": "시간이 없습니다. 숨기는 게 있다면 지금 말하세요.",
    "CONFIDE": "여기서 한 말은 공개하지 않겠습니다. 솔직한 판단을 들려주세요."
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

func setup(case_id_in: String, seed_in: int, protocol_in: String = "ANALYST") -> void:
    case_id = case_id_in if AstraCaseCatalog.has_case(case_id_in) else "DEAD_AIR"
    case_data = AstraCaseCatalog.get_case(case_id)
    seed_value = seed_in
    protocol = protocol_in if PROTOCOLS.has(protocol_in) else "ANALYST"
    rng.seed = seed_in * 7919 + 17
    truth = AstraCaseGenerator.generate(case_id, seed_in)
    clues = truth.get("clues", [])

    crew.clear()
    for npc_id in AstraCrewCatalog.ORDER:
        var member := AstraCrewMember.new(npc_id)
        member.role = "NULL" if npc_id in truth.get("nulls", []) else "CREW"
        crew[npc_id] = member
    for a in AstraCrewCatalog.ORDER:
        for b in AstraCrewCatalog.ORDER:
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
    selected_id = str(AstraCrewCatalog.ORDER[0])
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
    for npc_id in AstraCrewCatalog.ORDER:
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
    for npc_id in AstraCrewCatalog.ORDER:
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
    return BASE_INVESTIGATION_AP + (1 if protocol == "ANALYST" else 0)

func talk_ap_max() -> int:
    return BASE_TALK_AP + (1 if protocol == "EMPATH" else 0)

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
    for npc_id in AstraCrewCatalog.ORDER:
        if str(marks.get(npc_id, "")) == "null":
            result.append(npc_id)
    return result

func select(npc_id: String) -> void:
    if crew.has(npc_id):
        selected_id = npc_id
        changed.emit()

# ---------------------------------------------------------------- phase flow

func can_advance() -> bool:
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
    match phase:
        "BRIEFING": return "현장 조사 시작"
        "INVESTIGATION": return "개인 심문으로"
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
    return _josa_inline(_phase_hint_raw())

func _phase_hint_raw() -> String:
    match phase:
        "BRIEFING":
            if day == 1:
                return "사건 개요를 읽고 두 조작의 시각과 장소를 기억하세요. 사건 시간대는 %s입니다." % window_text()
            return "밤사이 일어난 일을 확인하세요. 오늘은 DAY %d / %d입니다." % [day, MAX_DAYS]
        "INVESTIGATION":
            return "구역을 조사해 단서를 모으세요. 흔적 두 개의 명단이 겹치는 사람이 그 조작의 실행자입니다. (행동력 %d)" % investigation_ap
        "INTERROGATION":
            if not pending_event.is_empty():
                return "%s|i 따로 이야기하고 싶어 합니다. 선택에 따라 단서나 관계가 달라집니다." % name_of(str(pending_event.get("npc_id", "")))
            return "승무원을 골라 질문하세요. 알리바이를 모으면 출입 기록과 대조할 수 있습니다. (행동력 %d)" % talk_ap
        "MEETING":
            return "발언권 %d회. 단서 공개·지목·변호로 여론을 움직이세요. 오른쪽 목록에 투표 의향이 실시간으로 표시됩니다." % meeting_actions_left
        "VOTE":
            if vote_cast:
                return "투표가 끝났습니다. 결과를 확인하고 밤으로 넘어가세요."
            return "격리할 사람을 고르세요. 조사관의 표는 %d표로 계산됩니다. Null 의심 표시를 2명 하면 추리 보고서가 함께 제출됩니다." % PLAYER_VOTE_WEIGHT
        "NIGHT":
            if night_done:
                return "밤이 지나갔습니다. 아침 보고를 확인하세요."
            return "Null은 밤마다 한 명을 노리고, 흔적을 지우려 합니다. 한 명을 보호하거나 한 구역을 감시하세요."
        "RESULT":
            return "사건이 종료됐습니다. 진실과 평가를 확인하세요."
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
            meeting_actions_left = MEETING_ACTIONS
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
    var can_ask := phase == "INTERROGATION" and talk_ap > 0 and pending_event.is_empty() and outcome == ""
    var has_clues := not found_clues().is_empty()
    var options: Array = [
        {"intent": "ALIBI", "label": "알리바이를 묻는다", "hint": "사건 시각의 위치·동행 · 노트에 기록", "enabled": can_ask},
        {"intent": "EVIDENCE", "label": "단서를 보여 준다", "hint": "확보한 단서 중 하나를 고른다" if has_clues else "먼저 단서를 확보하세요", "enabled": can_ask and has_clues, "needs_clue": true},
        {"intent": "CONTRADICTION", "label": "모순을 추궁한다", "hint": "숨긴 사정이나 실언을 끌어낼 수 있다" if has_contradiction_on(npc_id) else "관련 모순을 아직 찾지 못했다", "enabled": can_ask and has_contradiction_on(npc_id)},
        {"intent": "SUSPECT", "label": "의심하는 사람을 묻는다", "hint": "이 사람이 보는 사건 구도", "enabled": can_ask},
        {"intent": "REASSURE", "label": "긴장을 풀어 준다", "hint": "신뢰 ↑ · 긴장 ↓", "enabled": can_ask},
        {"intent": "PRESSURE", "label": "강하게 압박한다", "hint": "긴장 ↑ · 신뢰 ↓ · 실언 유도", "enabled": can_ask},
        {"intent": "CONFIDE", "label": "속마음을 묻는다", "hint": "둘만 아는 판단을 듣는다" if member.trust >= CONFIDE_TRUST else "신뢰 %d%% 이상 필요" % int(CONFIDE_TRUST * 100.0), "enabled": can_ask and member.trust >= CONFIDE_TRUST}
    ]
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

    talk_ap -= 1
    member.questions_asked += 1
    selected_id = npc_id
    var result := {"ok": true, "npc_id": npc_id, "intent": intent, "lines": []}
    var question := str(QUESTION_TEXT.get(intent, ""))
    if intent == "EVIDENCE":
        question = "이 기록을 보세요. ‘%s’" % str(clue_by_id(clue_id).get("title", ""))
    _transcript(npc_id, "player", question)

    match intent:
        "ALIBI": _ask_alibi(member, result)
        "EVIDENCE": _ask_evidence(member, clue_by_id(clue_id), result)
        "CONTRADICTION": _ask_contradiction(member, result)
        "SUSPECT": _ask_suspect(member, result, false)
        "REASSURE": _ask_reassure(member, result)
        "PRESSURE": _ask_pressure(member, result)
        "CONFIDE": _ask_suspect(member, result, true)

    member.refresh_expression()
    member.remember("DAY %d · 조사관 질문 %s" % [day, intent])
    _recompute_contradictions()
    changed.emit()
    return result

func _say(member: AstraCrewMember, key: String, params: Dictionary, result: Dictionary) -> String:
    var text := AstraDialogue.line(member.id, key, params, rng.randi_range(0, 9))
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
    _say(member, "alibi_with" if not companions.is_empty() else "alibi_alone", params, result)
    known_claims[member.id] = {"position": str(claim.get("position", "")), "companions": companions.duplicate(), "day": day}
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
                "%s|i 증언했다: %s쯤 %s 쪽 통로에서 %s 차림의 인물을 봤다. 해당: %s." % [member.display_name, time_text, room_name(str(op.get("room", ""))), AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"])), names_of(AstraCrewCatalog.group_members(str(fake["category"]), str(fake["group"])))],
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

func _maybe_private_event() -> void:
    if not pending_event.is_empty() or outcome != "":
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
                "%s|i 증언했다: %s쯤 %s 쪽 통로에서 %s 차림의 인물을 봤다. 해당: %s." % [member.display_name, AstraCaseCatalog.format_time(int(op.get("minute", 0)) - 1), room_name(str(op.get("room", ""))), AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"])), names_of(AstraCrewCatalog.group_members(str(fake["category"]), str(fake["group"])))],
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
            return "Vale이 보여 준 기록은 공식 로그와 일치했다. 단서 ‘%s’를 확보했다." % str(picked.get("title", ""))
        return "Vale이 기록을 펼쳤지만 이미 확인한 내용뿐이었다."
    var fake := _fabricate_group(member.id)
    if fake.is_empty():
        return "Vale이 기록을 펼쳤지만 의미 있는 내용은 없었다."
    var op_id := str(truth["null_ops"].get(member.id, ""))
    var clue := _add_testimony_clue("planted", member.id, "Vale의 신호 해석",
        "Vale의 해석: %s 직전 외부로 나간 신호에 %s 서명 조각이 섞여 있다. 해당: %s. (출처: Vale 개인 분석)" % [op_name(op_id), AstraCrewCatalog.group_label(str(fake["category"]), str(fake["group"])), names_of(AstraCrewCatalog.group_members(str(fake["category"]), str(fake["group"])))],
        str(fake["category"]), str(fake["group"]), op_id, member.id, true)
    result["clue"] = clue
    return "Vale이 자신만의 해석을 담은 기록을 건넸다. 공식 로그로는 확인되지 않는다."

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
        return "Noa가 기록을 다시 확인하더니, 착각이었다며 고개를 저었다."
    var claim := current_claim(target)
    var pos := str(claim.get("position", ""))
    known_claims[target] = {"position": pos, "companions": claim.get("companions", []).duplicate(), "day": day}
    var key := "terminal:%s:%d" % [target, day]
    manual_contradictions.append({
        "key": key, "kind": "terminal", "targets": [target], "source": member.id,
        "detail": "Noa의 단말 기록: %s의 개인 단말은 사건 시각 %s에 접속한 적이 없다. (출처: Noa)" % [name_of(target), room_name(pos)]
    })
    if make_public:
        flags["noa_public"] = key
    result["target"] = target
    member.adjust_trust(0.03)
    return "Noa가 조용히 문장 하나를 가리킨다. %s의 진술과 단말 기록이 어긋난다.%s" % [name_of(target), " 다음 회의에서 공개하기로 했다." if make_public else ""]

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
        var members: Array = AstraCrewCatalog.group_members(category, group)
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
        members = AstraCrewCatalog.group_members(category, group).duplicate()
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
    for item in manual_contradictions:
        result.append(item.duplicate(true))
    for item in result:
        item["public"] = public_contradiction_keys.has(str(item.get("key", "")))
        item["detail"] = _josa_inline(str(item.get("detail", "")))
    contradictions = result

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
    _suspicion_round(3)
    _log("공개 회의 · 발언 %d건" % meeting_feed.size())

func _run_disputes() -> void:
    var positions: Dictionary = truth.get("positions", {})
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
            if str(claim.get("position", "")) == witness_pos:
                disputes_done[key] = true
                _feed_npc(witness_id, "m_dispute_absent", {"pos": room_name(witness_pos), "target": name_of(target_id)}, "dispute", target_id)
                _mark_dispute_public(witness_id, target_id)
                _crowd_shift(target_id, 0.06, witness_id)
                witness.add_suspicion(target_id, 0.2)
                meeting_pushers[witness_id] = float(meeting_pushers.get(witness_id, 0.0)) + 1.0
            elif witness_id in claim.get("companions", []):
                disputes_done[key] = true
                _feed_npc(witness_id, "m_dispute_companion", {"target": name_of(target_id)}, "dispute", target_id)
                _mark_dispute_public(witness_id, target_id)
                _crowd_shift(target_id, 0.07, witness_id)
                witness.add_suspicion(target_id, 0.22)
                meeting_pushers[witness_id] = float(meeting_pushers.get(witness_id, 0.0)) + 1.0
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
            _feed_npc(null_id, "m_dispute_absent", {"pos": room_name(str(null_claim.get("position", ""))), "target": name_of(crew_id)}, "dispute", crew_id)
            _mark_dispute_public(null_id, crew_id)
            _crowd_shift(crew_id, 0.08, null_id)
            meeting_pushers[null_id] = float(meeting_pushers.get(null_id, 0.0)) + 1.0

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
    for item in speakers:
        if count >= max_speakers:
            break
        if float(item["value"]) < 0.34 and count > 0:
            break
        var speaker_id := str(item["id"])
        var target_id := str(item["target"])
        _feed_npc(speaker_id, "m_suspect", {"target": name_of(target_id), "reason": AstraDialogue.reason_text(str(item["reason"]))}, "suspect", target_id)
        _crowd_shift(target_id, 0.05, speaker_id)
        meeting_pushers[speaker_id] = float(meeting_pushers.get(speaker_id, 0.0)) + 0.6
        count += 1

func _crowd_shift(target_id: String, amount: float, speaker_id: String) -> void:
    for observer_id in living_ids():
        if observer_id == target_id or observer_id == speaker_id:
            continue
        var observer: AstraCrewMember = crew[observer_id]
        var weight := 1.0 + observer.get_affinity(speaker_id) * 0.6 - observer.get_affinity(target_id) * 0.4
        observer.add_suspicion(target_id, amount * clampf(weight, 0.3, 1.6))

func _feed_npc(npc_id: String, key: String, params: Dictionary, kind: String, target_id: String) -> void:
    var text := AstraDialogue.line(npc_id, key, params, rng.randi_range(0, 9))
    if text == "":
        return
    _feed_line(npc_id, target_id, text, kind)

func _feed_line(speaker_id: String, target_id: String, text: String, kind: String) -> void:
    var entry := {"speaker": speaker_id, "target": target_id, "text": _josa_inline(text), "kind": kind, "day": day}
    meeting_feed.append(entry)
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
    var target: AstraCrewMember = crew[target_id]
    _feed_npc(target_id, "m_react_accused_null" if target.is_null() else "m_react_accused_crew", {}, "defense", "")
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
    elif stage == "vote" and day >= MAX_DAYS:
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
    return {"protect": protect, "secure": secure}

func choose_night_action(kind: String, target: String) -> Dictionary:
    if phase != "NIGHT" or night_done or outcome != "":
        return {"ok": false}
    var options := night_options()
    if kind not in ["protect", "secure"] or target not in options.get(kind, []):
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
        var guarded := (kind == "protect" and target == victim) or patrol_guard == victim
        if guarded:
            var attackers := living_null_ids()
            var attacker := str(attackers[rng.randi_range(0, attackers.size() - 1)])
            stats["protects"] = int(stats.get("protects", 0)) + 1
            result["protected"] = true
            result["victim"] = victim
            var clue := _night_clue(attacker, "보호 기록 · 침입 흔적", "밤사이 누군가 %s의 선실 문을 강제로 열려다 달아났다. 문 패널에 %s 흔적이 남았다. 해당: %s.", victim)
            result["clues"].append(clue)
            if patrol_guard == victim and not (kind == "protect" and target == victim):
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
        if kind == "secure" and target == clue_room:
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
    var members: Array = AstraCrewCatalog.group_members(category, group)
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
    var theory := grade_theory()
    rows.append(["추리 보고서 %d점" % int(theory.get("grade", 0)), int(theory.get("grade", 0)) * 5])
    if outcome == "WIN":
        rows.append(["신속 해결 (DAY %d)" % day, maxi(0, MAX_DAYS - day) * 150])
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
    for npc_id in AstraCrewCatalog.ORDER:
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
            subtitle = "%d일이 지났지만 Null은 아직 선내에 있다. 기록만이 다음 조사로 남는다." % MAX_DAYS
        _:
            title = "Null 장악"
            subtitle = "남은 승무원이 Null과 같은 수가 됐다. 선내 의사결정권이 무너졌다."
    final_report = {
        "outcome": outcome, "title": title, "subtitle": subtitle, "rows": rows, "total": total, "rank": rank,
        "nulls": nulls.duplicate(), "herring": str(truth.get("herring", "")), "truth": truth_rows,
        "theory": theory, "day": day, "null_isolated": null_isolated, "innocent_isolated": innocent_isolated,
        "survivors": survivors, "stats": stats.duplicate()
    }

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
    for other in AstraCrewCatalog.ORDER:
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
