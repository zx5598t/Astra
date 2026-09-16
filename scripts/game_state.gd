class_name AstraGameState
extends RefCounted

signal state_changed
signal phase_changed

const VERSION := "0.0.2"
const PHASES := ["BRIEFING", "INVESTIGATION", "INTERROGATION", "MEETING", "VOTE", "RESULT"]
const INVESTIGATION_ACTIONS := 3
const TALK_ACTIONS := 3

var truth := TruthEngine.new()
var ai_gateway := AIGateway.new()
var seed_value: int = 260916
var phase_index: int = 0
var day: int = 1
var npcs: Dictionary = {}
var discovered_evidence: Array[String] = []
var journal: Array[String] = []
var selected_npc_id: String = "mira"
var selected_location: String = "의료실"
var votes: Dictionary = {}
var game_over: bool = false
var ending_text: String = ""
var result_title: String = ""
var investigation_actions_left: int = INVESTIGATION_ACTIONS
var talk_actions_left: int = TALK_ACTIONS
var score: int = 0
var case_confidence: float = 0.0
var meeting_summary: Array[String] = []

func setup(seed_in: int = 260916) -> void:
    seed_value = seed_in
    truth.setup(seed_value)
    _create_npcs()
    phase_index = 0
    day = 1
    journal.clear()
    discovered_evidence.clear()
    votes.clear()
    meeting_summary.clear()
    game_over = false
    ending_text = ""
    result_title = ""
    investigation_actions_left = INVESTIGATION_ACTIONS
    talk_actions_left = TALK_ACTIONS
    score = 0
    case_confidence = 0.0
    selected_npc_id = "mira"
    log_event("CASE OPENED · %s / Seed %d" % [truth.incident["subtitle"], seed_value])
    log_event("함장 Ives 사망. 승무원 6명 중 Null 침투자는 2명이다.")
    emit_signal("state_changed")

func _create_npcs() -> void:
    npcs.clear()
    var rows: Array[Dictionary] = [
        {"id":"mira","name":"Mira","job":"의무관","role":"CREW","trust_player":0.62,"accent":Color("63d7ff"),"knowledge":["FACT_001","FACT_002","FACT_004"],"personality":{"calm":0.82,"aggressive":0.18,"social":0.58}},
        {"id":"rho","name":"Rho","job":"기관사","role":"NULL","trust_player":0.44,"accent":Color("ff755f"),"knowledge":["FACT_001","FACT_003","FACT_007"],"personality":{"calm":0.55,"aggressive":0.72,"social":0.48}},
        {"id":"eli","name":"Eli","job":"항법사","role":"CREW","trust_player":0.54,"accent":Color("b88cff"),"knowledge":["FACT_001"],"personality":{"calm":0.62,"aggressive":0.26,"social":0.73}},
        {"id":"sena","name":"Sena","job":"보안관","role":"CREW","trust_player":0.49,"accent":Color("ffd15c"),"knowledge":["FACT_001","FACT_005"],"personality":{"calm":0.71,"aggressive":0.55,"social":0.32}},
        {"id":"vale","name":"Vale","job":"통신관","role":"NULL","trust_player":0.57,"accent":Color("57e5a5"),"knowledge":["FACT_001","FACT_005","FACT_006"],"personality":{"calm":0.78,"aggressive":0.31,"social":0.81}},
        {"id":"noa","name":"Noa","job":"기록관","role":"CREW","trust_player":0.66,"accent":Color("ff9ed1"),"knowledge":["FACT_001","FACT_002"],"personality":{"calm":0.68,"aggressive":0.12,"social":0.44}}
    ]
    for row in rows:
        var npc := NPCState.new(row)
        for other in rows:
            if str(other["id"]) != npc.id:
                npc.set_suspicion(str(other["id"]), 0.22 + truth.rng.randf_range(0.0, 0.34))
        npcs[npc.id] = npc

func phase_name() -> String:
    return PHASES[phase_index]

func phase_display_name() -> String:
    match phase_name():
        "BRIEFING": return "사건 브리핑"
        "INVESTIGATION": return "현장 조사"
        "INTERROGATION": return "개인 심문"
        "MEETING": return "공개 회의"
        "VOTE": return "격리 투표"
        "RESULT": return "사건 결과"
    return phase_name()

func can_advance_phase() -> bool:
    if game_over:
        return false
    if phase_name() == "VOTE":
        return false
    return true

func advance_phase() -> void:
    if not can_advance_phase():
        return
    phase_index = mini(phase_index + 1, PHASES.size() - 1)
    if phase_name() == "INVESTIGATION":
        investigation_actions_left = INVESTIGATION_ACTIONS
    elif phase_name() == "INTERROGATION":
        talk_actions_left = TALK_ACTIONS
    elif phase_name() == "MEETING":
        _run_meeting_reactions()
    log_event("PHASE · %s" % phase_display_name())
    emit_signal("phase_changed")
    emit_signal("state_changed")

func investigate(location: String) -> String:
    if phase_name() != "INVESTIGATION":
        return "지금은 현장 조사 단계가 아니다."
    if investigation_actions_left <= 0:
        return "조사 행동력을 모두 사용했다. 다음 단계로 진행하자."
    investigation_actions_left -= 1
    selected_location = location
    var candidates: Array[String] = []
    for ev_key in truth.evidence.keys():
        var ev_id := str(ev_key)
        if str(truth.evidence[ev_id]["location"]) == location and ev_id not in discovered_evidence:
            candidates.append(ev_id)
    if candidates.is_empty():
        var empty_msg := "%s · 이미 확인한 흔적뿐이다." % location
        log_event(empty_msg)
        emit_signal("state_changed")
        return empty_msg
    var ev_id := candidates[truth.rng.randi_range(0, candidates.size() - 1)]
    discovered_evidence.append(ev_id)
    var ev: Dictionary = truth.evidence[ev_id]
    var fact_ref := str(ev["fact_ref"])
    var msg := "증거 확보 · %s\n%s" % [str(ev["name"]), truth.fact_text(fact_ref)]
    log_event("EVIDENCE · %s — %s" % [str(ev["name"]), truth.fact_text(fact_ref)])
    score += 100 if str(ev.get("rarity", "COMMON")) == "KEY" else 60
    _propagate_evidence(fact_ref)
    _recalculate_confidence()
    emit_signal("state_changed")
    return msg

func _propagate_evidence(fact_ref: String) -> void:
    for npc_value in npcs.values():
        var npc: NPCState = npc_value
        if npc.knows_fact(fact_ref):
            npc.adjust_stress(0.025)
        if fact_ref == "FACT_003" or fact_ref == "FACT_007":
            npc.set_suspicion("rho", npc.get_suspicion("rho") + 0.17)
        elif fact_ref == "FACT_004":
            npc.set_suspicion("mira", npc.get_suspicion("mira") - 0.14)
        elif fact_ref == "FACT_005" or fact_ref == "FACT_006":
            npc.set_suspicion("vale", npc.get_suspicion("vale") + 0.13)

func talk_to(npc_id: String, intent: String) -> String:
    if phase_name() not in ["INTERROGATION", "MEETING"]:
        return "지금은 대화할 수 없다."
    if npc_id not in npcs:
        return "대상을 찾을 수 없다."
    if phase_name() == "INTERROGATION":
        if talk_actions_left <= 0:
            return "개인 심문 행동력을 모두 사용했다."
        talk_actions_left -= 1
    var npc: NPCState = npcs[npc_id]
    selected_npc_id = npc_id
    var response := _generate_rule_based_response(npc, intent)
    npc.remember("Player used %s during %s" % [intent, phase_display_name()])
    log_event("%s · %s" % [npc.display_name, response])
    score += 15
    _recalculate_confidence()
    emit_signal("state_changed")
    return response

func _generate_rule_based_response(npc: NPCState, intent: String) -> String:
    var stress := float(npc.emotion.get("stress", 0.2))
    match intent:
        "ALIBI":
            var alibi := _alibi_for(npc.id)
            npc.add_commitment(alibi)
            if npc.id == "rho": npc.adjust_stress(0.04)
            return alibi
        "EVIDENCE":
            if discovered_evidence.is_empty():
                return "보여줄 증거도 없이 반응을 보려는 거야?"
            var latest := discovered_evidence[-1]
            var fact_ref := str(truth.evidence[latest]["fact_ref"])
            npc.adjust_stress(0.085 if npc.knows_fact(fact_ref) else 0.035)
            if npc.id == "rho" and fact_ref in ["FACT_003", "FACT_007"]:
                npc.adjust_trust(-0.05)
                npc.add_note("엔진실 기록에 강하게 방어적")
                return "점검 기록이 이상한 건 인정해. 하지만 누군가 내 권한을 복제했을 가능성도 있잖아."
            if npc.id == "vale" and fact_ref in ["FACT_005", "FACT_006"]:
                npc.adjust_trust(-0.04)
                npc.add_note("통신 기록을 기술 문제로 돌림")
                return "암호화 패킷은 자동 복구 프로토콜일 수도 있어. 발신자가 곧 범인이라는 뜻은 아니야."
            if npc.knows_fact(fact_ref):
                npc.adjust_trust(0.025)
                return "그 기록은 나도 알고 있어. 다른 증언과 시간대를 같이 봐야 해."
            return "처음 보는 정보야. 회의에서 모두에게 공개하는 편이 좋겠어."
        "REASSURE":
            npc.adjust_stress(-0.05)
            if npc.trust_player >= 0.58:
                npc.adjust_trust(0.035)
                return "좋아. 적어도 넌 결론부터 정해놓고 묻는 것 같진 않네. 내가 아는 건 말해줄게."
            npc.adjust_trust(0.015)
            return "아직 널 완전히 믿진 못하지만… 계속 들어는 볼게."
        "PRESSURE":
            npc.adjust_stress(0.12)
            npc.adjust_trust(-0.045)
            if npc.role == "NULL" and stress > 0.28:
                return "왜 그렇게 나 하나만 몰아붙이지? 진짜 시선을 돌리고 싶은 사람처럼 보이는데."
            if npc.id == "sena":
                return "압박은 수사 방식이 아니야. 근거가 있으면 기록으로 보여줘."
            return "목소리를 높인다고 사실이 바뀌진 않아. 근거를 보여줘."
        "MOTIVE":
            if npc.id == "vale":
                npc.adjust_stress(0.05)
                return "함장과 통신 봉쇄 문제로 다툰 적은 있어. 그게 살해 동기는 아니야."
            if npc.id == "rho":
                return "함장이 엔진 정비 일정을 밀어붙인 건 마음에 안 들었지. 하지만 그건 업무 갈등이야."
            return "함장과 개인적인 원한은 없어. 지금 중요한 건 누가 시스템을 건드렸느냐야."
        _:
            return "질문 의도를 이해하지 못했어."

func _alibi_for(npc_id: String) -> String:
    match npc_id:
        "mira": return "07:40 전까지 의료실에 있었어. 바이오 센서 기록을 확인해도 좋아."
        "rho": return "정전 직전 엔진실에서 냉각 계통을 수동 점검 중이었어."
        "eli": return "항법실에서 항로 재계산 중이었고 Noa가 잠깐 나를 봤어."
        "sena": return "보안 구역 순찰 중이었어. 통신실 접근 기록도 확인했지."
        "vale": return "통신실에서 외부 신호를 복구하고 있었어. 혼자였지."
        "noa": return "기록보관실에 있었어. Eli가 항법실에 있는 건 직접 봤어."
    return "기억이 잘 나지 않아."

func _run_meeting_reactions() -> void:
    meeting_summary.clear()
    for npc_value in npcs.values():
        var npc: NPCState = npc_value
        var target_id := npc.highest_suspicion()
        if target_id != "" and target_id in npcs:
            var target: NPCState = npcs[target_id]
            var line := "%s → %s 의심 (%d%%)" % [npc.display_name, target.display_name, int(npc.get_suspicion(target_id) * 100.0)]
            meeting_summary.append(line)
            log_event("MEETING · %s" % line)

func vote(target_id: String) -> String:
    if phase_name() != "VOTE":
        return "지금은 투표 단계가 아니다."
    if target_id not in npcs:
        return "투표 대상을 찾을 수 없다."
    votes.clear()
    votes["player"] = target_id
    var tally: Dictionary = {target_id: 1}
    for npc_value in npcs.values():
        var npc: NPCState = npc_value
        var choice := _npc_vote(npc)
        votes[npc.id] = choice
        tally[choice] = int(tally.get(choice, 0)) + 1
    var exiled := target_id
    var top := -1
    for candidate in tally.keys():
        var count := int(tally[candidate])
        if count > top or (count == top and str(candidate) == target_id):
            top = count
            exiled = str(candidate)
    var exiled_npc: NPCState = npcs[exiled]
    exiled_npc.alive = false
    log_event("VOTE · %s 격리 (%d표)" % [exiled_npc.display_name, top])
    _finish_game(exiled)
    emit_signal("state_changed")
    return ending_text

func _npc_vote(npc: NPCState) -> String:
    if npc.role == "NULL":
        var crew_candidates: Array[String] = []
        for other_value in npcs.values():
            var other: NPCState = other_value
            if other.id != npc.id and other.role == "CREW" and other.alive:
                crew_candidates.append(other.id)
        if not crew_candidates.is_empty():
            return crew_candidates[truth.rng.randi_range(0, crew_candidates.size() - 1)]
    var choice := "rho"
    var best := -1.0
    for target_key in npc.suspicion.keys():
        var target_id := str(target_key)
        if target_id in npcs and npcs[target_id].alive:
            var value := npc.get_suspicion(target_id)
            if value > best:
                best = value
                choice = target_id
    return choice

func _finish_game(exiled_id: String) -> void:
    game_over = true
    phase_index = PHASES.size() - 1
    var exiled: NPCState = npcs[exiled_id]
    if exiled.role == "NULL":
        result_title = "NULL IDENTIFIED"
        score += 700
        ending_text = "%s은(는) Null이었다. 한 명의 침투자를 찾아냈지만, 선내에는 아직 또 다른 Null이 남아 있다." % exiled.display_name
    else:
        result_title = "FALSE POSITIVE"
        score = maxi(0, score - 250)
        ending_text = "%s은(는) Crew였다. 잘못된 격리다. 확보한 증거와 증언의 모순을 다시 검토해야 한다." % exiled.display_name
    score += discovered_evidence.size() * 35
    log_event("RESULT · %s · SCORE %d" % [result_title, score])

func _recalculate_confidence() -> void:
    var key_count := 0
    for ev_id in discovered_evidence:
        if str(truth.evidence[ev_id].get("rarity", "COMMON")) == "KEY":
            key_count += 1
    case_confidence = clampf((float(discovered_evidence.size()) / 6.0) * 0.65 + (float(key_count) / 4.0) * 0.35, 0.0, 1.0)

func evidence_lines() -> Array[String]:
    var lines: Array[String] = []
    for ev_id in discovered_evidence:
        var ev: Dictionary = truth.evidence[ev_id]
        lines.append("%s · %s" % [str(ev["name"]), truth.fact_text(str(ev["fact_ref"]))])
    return lines

func log_event(text: String) -> void:
    journal.append(text)
    if journal.size() > 120:
        journal.pop_front()
