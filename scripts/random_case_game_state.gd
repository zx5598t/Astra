class_name AstraRandomCaseGameState
extends AstraLoopGameState

const RANDOM_VERSION := "0.0.6"
const CASE_IDS := ["DEAD_AIR", "GLASS_GARDEN"]

var preferred_case_id: String = ""
var case_id: String = "DEAD_AIR"
var case_title: String = "INCIDENT ZERO"
var case_subtitle: String = "Dead Air"
var case_theme: String = "통신과 전력 이상"
var hidden_null_ids: Array[String] = []
var decoy_ids: Array[String] = []
var notebook_edges: Array[Dictionary] = []
var claim_register: Array[Dictionary] = []
var contradiction_register: Array[Dictionary] = []

func setup(seed_in: int = 260916) -> void:
    super.setup(seed_in)
    notebook_edges.clear()
    claim_register.clear()
    contradiction_register.clear()
    _assign_random_roles()
    _select_case()
    _configure_case_truth()
    _reset_dynamic_knowledge()
    journal.clear()
    discovered_evidence.clear()
    votes.clear()
    meeting_summary.clear()
    meeting_events.clear()
    day_vote_history.clear()
    conversation_history.clear()
    score = 0
    case_confidence = 0.0
    day = 1
    phase_index = 0
    investigation_actions_left = INVESTIGATION_ACTIONS
    talk_actions_left = TALK_ACTIONS
    game_over = false
    result_title = ""
    ending_text = ""
    day_report_text = ""
    selected_npc_id = _first_living_npc()
    selected_location = str(truth.incident["locations"][0])
    log_event("CASE SHUFFLE · %s / Seed %d" % [case_subtitle, seed_value])
    log_event("승무원 8명 중 Null 2명. 신분은 매 판 다시 배정된다.")
    log_event("사건 · %s — %s" % [case_title, case_theme])
    emit_signal("state_changed")

func _assign_random_roles() -> void:
    hidden_null_ids.clear()
    decoy_ids.clear()
    for npc_id in crew_order:
        var npc: NPCState = npcs[npc_id]
        npc.role = "CREW"
        npc.alive = true

    var pool: Array[String] = crew_order.duplicate()
    for _i in range(2):
        var index := truth.rng.randi_range(0, pool.size() - 1)
        var chosen := pool[index]
        pool.remove_at(index)
        hidden_null_ids.append(chosen)
        npcs[chosen].role = "NULL"

    if pool.size() >= 2:
        var first_index := truth.rng.randi_range(0, pool.size() - 1)
        var first_decoy := pool[first_index]
        pool.remove_at(first_index)
        var second_index := truth.rng.randi_range(0, pool.size() - 1)
        var second_decoy := pool[second_index]
        decoy_ids = [first_decoy, second_decoy]

    truth.incident["null_ids"] = hidden_null_ids.duplicate()

func _select_case() -> void:
    if preferred_case_id in CASE_IDS:
        case_id = preferred_case_id
    else:
        case_id = CASE_IDS[truth.rng.randi_range(0, CASE_IDS.size() - 1)]

    if case_id == "GLASS_GARDEN":
        case_title = "INCIDENT ONE"
        case_subtitle = "Glass Garden"
        case_theme = "수목구역 오염과 생명유지 교란"
    else:
        case_title = "INCIDENT ZERO"
        case_subtitle = "Dead Air"
        case_theme = "통신 두절과 전력 우회"

func _configure_case_truth() -> void:
    if hidden_null_ids.size() < 2 or decoy_ids.size() < 2:
        return

    var n1 := hidden_null_ids[0]
    var n2 := hidden_null_ids[1]
    var d1 := decoy_ids[0]
    var d2 := decoy_ids[1]
    var n1_name: String = npcs[n1].display_name
    var n2_name: String = npcs[n2].display_name
    var d1_name: String = npcs[d1].display_name
    var d2_name: String = npcs[d2].display_name

    if case_id == "GLASS_GARDEN":
        truth.facts = {
            "FACT_001": {"text":"연구원 Orin의 치명적 노출 시각은 19:22~19:26 사이다.", "secret":false, "known_by":crew_order.duplicate()},
            "FACT_002": {"text":"%s의 자격 증명이 19:23 수목구역 영양액 밸브를 강제 개방했다." % n1_name, "secret":true, "known_by":[n1,"dax"]},
            "FACT_003": {"text":"%s의 개인 단말이 같은 시각 정수 계통 안전 인터록을 우회했다." % n2_name, "secret":true, "known_by":[n2,"sena"]},
            "FACT_004": {"text":"%s의 생체 태그는 사고 시각 의료실 내부에 연속 기록되어 있다." % d1_name, "secret":true, "known_by":[d1,"mira"]},
            "FACT_005": {"text":"오염 사고는 영양액 계통과 정수 계통 두 곳이 동시에 조작되어야 성립한다.", "secret":false, "known_by":["dax","lyra","sena"]},
            "FACT_006": {"text":"수목구역 보조 카메라에서 %s와 일치하는 작업복 반사 패턴이 검출됐다." % n1_name, "secret":true, "known_by":["sena"]},
            "FACT_007": {"text":"정수실 유지보수 토큰이 %s의 단말 세션과 겹쳤다." % n2_name, "secret":true, "known_by":["dax"]},
            "FACT_008": {"text":"%s는 사고 직전 보안허브에서 출입 인증을 완료했다." % d2_name, "secret":true, "known_by":[d2,"sena"]}
        }
        truth.evidence = {
            "EV_01": {"name":"오염 시각 생명유지 로그", "fact_ref":"FACT_001", "location":"수목구역", "rarity":"COMMON", "signal":"context", "target_id":""},
            "EV_02": {"name":"영양액 밸브 강제개방 기록", "fact_ref":"FACT_002", "location":"수목구역", "rarity":"KEY", "signal":"implicates", "target_id":n1, "contradicts_alibi":true},
            "EV_03": {"name":"의료실 생체 태그 연속기록", "fact_ref":"FACT_004", "location":"의료실", "rarity":"KEY", "signal":"clears", "target_id":d1},
            "EV_04": {"name":"노출 샘플 분석", "fact_ref":"FACT_005", "location":"의료실", "rarity":"COMMON", "signal":"context", "target_id":""},
            "EV_05": {"name":"정수 인터록 우회 기록", "fact_ref":"FACT_003", "location":"정수실", "rarity":"KEY", "signal":"implicates", "target_id":n2, "contradicts_alibi":true},
            "EV_06": {"name":"유지보수 토큰 세션", "fact_ref":"FACT_007", "location":"정수실", "rarity":"KEY", "signal":"implicates", "target_id":n2, "contradicts_alibi":false},
            "EV_07": {"name":"보조 카메라 반사 패턴", "fact_ref":"FACT_006", "location":"보안허브", "rarity":"COMMON", "signal":"implicates", "target_id":n1, "contradicts_alibi":false},
            "EV_08": {"name":"보안허브 출입 인증", "fact_ref":"FACT_008", "location":"보안허브", "rarity":"COMMON", "signal":"clears", "target_id":d2}
        }
        truth.incident = {
            "title":case_title,
            "subtitle":case_subtitle,
            "victim":"Researcher Orin",
            "locations":["수목구역","의료실","정수실","보안허브"],
            "null_ids":hidden_null_ids.duplicate(),
            "objective":"오염 사고를 만든 두 개의 조작 경로를 추적해 Null 침투자를 격리하라.",
            "theme":case_theme
        }
    else:
        truth.facts = {
            "FACT_001": {"text":"함장 Ives의 사망 시각은 07:36~07:39 사이다.", "secret":false, "known_by":crew_order.duplicate()},
            "FACT_002": {"text":"%s의 자격 증명이 정전 41초 전 전력 우회 패널에 사용됐다." % n1_name, "secret":true, "known_by":[n1,"dax"]},
            "FACT_003": {"text":"%s의 개인 단말이 사망 추정 시각에 암호화 패킷을 외부로 보냈다." % n2_name, "secret":true, "known_by":[n2,"vale"]},
            "FACT_004": {"text":"%s의 바이오 신호는 07:37 의료실에 연속 기록되어 있다." % d1_name, "secret":true, "known_by":[d1,"mira"]},
            "FACT_005": {"text":"통신 로그와 전력 로그를 동시에 변조하려면 서로 다른 두 개의 권한 경로가 필요하다.", "secret":false, "known_by":["sena","dax","vale"]},
            "FACT_006": {"text":"엔진실 보조 센서에서 %s의 작업복 태그가 짧게 기록됐다." % n1_name, "secret":true, "known_by":["rho","dax"]},
            "FACT_007": {"text":"통신 백업 라우터의 세션 키가 %s의 단말 기록과 일치한다." % n2_name, "secret":true, "known_by":["vale"]},
            "FACT_008": {"text":"%s는 07:38 수목구역 내부 출입기에 인증되어 있다." % d2_name, "secret":true, "known_by":[d2,"lyra"]}
        }
        truth.evidence = {
            "EV_01": {"name":"의료실 출입 타임라인", "fact_ref":"FACT_001", "location":"의료실", "rarity":"COMMON", "signal":"context", "target_id":""},
            "EV_02": {"name":"바이오 센서 연속기록", "fact_ref":"FACT_004", "location":"의료실", "rarity":"KEY", "signal":"clears", "target_id":d1},
            "EV_03": {"name":"전력 우회 패널 기록", "fact_ref":"FACT_002", "location":"엔진실", "rarity":"KEY", "signal":"implicates", "target_id":n1, "contradicts_alibi":true},
            "EV_04": {"name":"작업복 태그 센서 흔적", "fact_ref":"FACT_006", "location":"엔진실", "rarity":"COMMON", "signal":"implicates", "target_id":n1, "contradicts_alibi":false},
            "EV_05": {"name":"이중 권한 요구 기록", "fact_ref":"FACT_005", "location":"통신실", "rarity":"COMMON", "signal":"context", "target_id":""},
            "EV_06": {"name":"암호화 패킷 흔적", "fact_ref":"FACT_003", "location":"통신실", "rarity":"KEY", "signal":"implicates", "target_id":n2, "contradicts_alibi":true},
            "EV_07": {"name":"백업 라우터 세션 키", "fact_ref":"FACT_007", "location":"수목구역", "rarity":"KEY", "signal":"implicates", "target_id":n2, "contradicts_alibi":false},
            "EV_08": {"name":"수목구역 출입 인증", "fact_ref":"FACT_008", "location":"수목구역", "rarity":"COMMON", "signal":"clears", "target_id":d2}
        }
        truth.incident = {
            "title":case_title,
            "subtitle":case_subtitle,
            "victim":"Captain Ives",
            "locations":["의료실","엔진실","통신실","수목구역"],
            "null_ids":hidden_null_ids.duplicate(),
            "objective":"통신과 전력의 두 조작 경로를 연결해 Null 침투자를 격리하라.",
            "theme":case_theme
        }

func _reset_dynamic_knowledge() -> void:
    for npc_id in crew_order:
        var npc: NPCState = npcs[npc_id]
        npc.knowledge.clear()

    for fact_id in truth.facts.keys():
        var fact: Dictionary = truth.facts[fact_id]
        for npc_id in fact.get("known_by", []):
            var id := str(npc_id)
            if id in npcs and str(fact_id) not in npcs[id].knowledge:
                npcs[id].knowledge.append(str(fact_id))

func _propagate_evidence(fact_ref: String) -> void:
    var ev_id := _evidence_id_for_fact(fact_ref)
    if ev_id == "":
        return

    var ev: Dictionary = truth.evidence[ev_id]
    var evidence_signal := str(ev.get("signal", "context"))
    var target_id := str(ev.get("target_id", ""))
    var target_name := ""
    if target_id in npcs:
        target_name = npcs[target_id].display_name

    for npc_id in crew_order:
        var observer: NPCState = npcs[npc_id]
        if not observer.alive:
            continue
        if observer.knows_fact(fact_ref):
            observer.adjust_stress(0.025)
        if target_id == "" or target_id == observer.id:
            continue
        if evidence_signal == "implicates":
            observer.set_suspicion(target_id, observer.get_suspicion(target_id) + 0.15)
        elif evidence_signal == "clears":
            observer.set_suspicion(target_id, observer.get_suspicion(target_id) - 0.13)

    if target_id in npcs:
        var target: NPCState = npcs[target_id]
        if evidence_signal == "implicates":
            target.adjust_stress(0.07)
        elif evidence_signal == "clears":
            target.adjust_stress(-0.025)

    _register_notebook_edge(ev_id, evidence_signal, target_id, target_name)
    _scan_all_contradictions()

func _evidence_id_for_fact(fact_ref: String) -> String:
    for ev_id in truth.evidence.keys():
        if str(truth.evidence[ev_id].get("fact_ref", "")) == fact_ref:
            return str(ev_id)
    return ""

func _register_notebook_edge(ev_id: String, evidence_signal: String, target_id: String, target_name: String) -> void:
    for edge in notebook_edges:
        if str(edge.get("evidence_id", "")) == ev_id:
            return

    notebook_edges.append({
        "evidence_id":ev_id,
        "signal":evidence_signal,
        "target_id":target_id,
        "target_name":target_name,
        "name":truth.evidence_name(ev_id),
        "fact_ref":str(truth.evidence[ev_id].get("fact_ref", ""))
    })

func talk_to(npc_id: String, intent: String) -> String:
    var response := super.talk_to(npc_id, intent)
    if npc_id in npcs and intent == "ALIBI" and response != "":
        claim_register.append({"day":day, "npc_id":npc_id, "text":response})
        if claim_register.size() > 24:
            claim_register.pop_front()
        _scan_contradictions_for(npc_id)
    return response

func _generate_rule_based_response(npc: NPCState, intent: String) -> String:
    if intent == "EVIDENCE":
        if discovered_evidence.is_empty():
            return "보여줄 증거가 아직 없어. 기록을 먼저 확보해줘."

        var ev_id := discovered_evidence[-1]
        var ev: Dictionary = truth.evidence.get(ev_id, {})
        var target_id := str(ev.get("target_id", ""))
        var evidence_signal := str(ev.get("signal", "context"))
        var fact_ref := str(ev.get("fact_ref", ""))

        if target_id == npc.id:
            if evidence_signal == "implicates":
                npc.adjust_stress(0.10)
                npc.adjust_trust(-0.035)
                if npc.role == "NULL":
                    return "그 기록이 내 계정이나 장비를 가리키는 건 알아. 하지만 사용자가 나였다는 건 아직 증명되지 않았어."
                return "내 기록이 걸린 건 인정해. 그래도 내가 그 조작을 했다는 결론과는 달라. 시간대를 더 확인해줘."
            if evidence_signal == "clears":
                npc.adjust_trust(0.035)
                return "그 기록이면 적어도 그 시간의 내 위치는 확인되는 거네. 다른 단서와 같이 봐줘."

        if evidence_signal == "context":
            return "그건 사건 구조를 설명하는 기록이야. 누군가를 바로 지목하기보다는 다른 증거와 연결해야 해."
        if npc.knows_fact(fact_ref):
            return "그 기록은 나도 알고 있어. 대상이 누구든 다른 시간대와 같이 확인해야 해."
        return "처음 보는 기록이야. 회의에서 공개하고 반응을 비교하는 게 좋겠어."

    return super._generate_rule_based_response(npc, intent)

func _alibi_for(npc_id: String) -> String:
    match npc_id:
        "mira": return "사고 전후로 의료실 진료대에 있었어. 내 생체 기록과 처치 로그를 확인해."
        "rho": return "기관 구역에서 정비 요청을 처리하고 있었어. 작업 기록이 남아 있을 거야."
        "eli": return "항법실에서 항로 재계산 중이었어. 자동 항법 기록이 시작 시각을 남겼어."
        "sena": return "보안 순찰 경로를 돌고 있었어. 출입 인증을 비교하면 돼."
        "vale": return "통신실에서 외부 신호를 정리하고 있었어. 단말 세션은 남아 있을 거야."
        "noa": return "기록보관실에서 사고 전 로그를 정리하고 있었어. 열람 기록을 확인해."
        "lyra": return "수목구역 생태 점검을 하고 있었어. 관수 기록과 출입기를 봐."
        "dax": return "시스템 진단 패널에서 자동 오류 로그를 검토하고 있었어."
    return "내 동선을 다시 확인해볼게."

func _scan_all_contradictions() -> void:
    for npc_id in crew_order:
        _scan_contradictions_for(npc_id)

func _scan_contradictions_for(npc_id: String) -> void:
    var has_claim := false
    var claim_text := ""
    for i in range(claim_register.size() - 1, -1, -1):
        var claim: Dictionary = claim_register[i]
        if str(claim.get("npc_id", "")) == npc_id:
            has_claim = true
            claim_text = str(claim.get("text", ""))
            break

    if not has_claim:
        return

    for ev_id in discovered_evidence:
        var ev: Dictionary = truth.evidence.get(ev_id, {})
        if str(ev.get("target_id", "")) != npc_id:
            continue
        if str(ev.get("signal", "")) != "implicates" or not bool(ev.get("contradicts_alibi", false)):
            continue

        var key := "%s:%s" % [npc_id, ev_id]
        var exists := false
        for item in contradiction_register:
            if str(item.get("key", "")) == key:
                exists = true
                break

        if not exists:
            contradiction_register.append({
                "key":key,
                "npc_id":npc_id,
                "evidence_id":ev_id,
                "claim":claim_text,
                "evidence":truth.evidence_name(ev_id)
            })
            log_event("NOTEBOOK · %s의 알리바이와 %s 사이 모순 후보" % [npcs[npc_id].display_name, truth.evidence_name(ev_id)])

func notebook_report_bbcode() -> String:
    var out := "[font_size=28][color=#55d6ff]INVESTIGATOR NOTEBOOK[/color][/font_size]\n"
    out += "[color=#8ea5c5]%s · DAY %d · 발견 증거 %d/8[/color]\n\n" % [case_subtitle, day, discovered_evidence.size()]
    out += "[font_size=20][color=#ffd36a]EVIDENCE LINKS[/color][/font_size]\n"

    if notebook_edges.is_empty():
        out += "아직 연결된 증거가 없다.\n"
    else:
        for edge in notebook_edges:
            var evidence_signal := str(edge.get("signal", "context"))
            var arrow := "→ 사건 구조"
            if evidence_signal == "implicates":
                arrow = "→ 의심 강화 → %s" % str(edge.get("target_name", ""))
            elif evidence_signal == "clears":
                arrow = "→ 알리바이 지지 → %s" % str(edge.get("target_name", ""))
            out += "• [b]%s[/b] %s\n" % [str(edge.get("name", "")), arrow]

    out += "\n[font_size=20][color=#ff9ed1]CLAIMS[/color][/font_size]\n"
    if claim_register.is_empty():
        out += "아직 고정된 알리바이 발언이 없다.\n"
    else:
        var start := maxi(0, claim_register.size() - 6)
        for i in range(start, claim_register.size()):
            var claim: Dictionary = claim_register[i]
            var npc_id := str(claim.get("npc_id", ""))
            var display_name := npc_id
            if npc_id in npcs:
                display_name = npcs[npc_id].display_name
            out += "• D%d [b]%s[/b] · %s\n" % [int(claim.get("day", 1)), display_name, _short_quote(str(claim.get("text", "")))]

    out += "\n[font_size=20][color=#ff6f7f]CONTRADICTION CANDIDATES[/color][/font_size]\n"
    if contradiction_register.is_empty():
        out += "현재 자동 표시된 직접 모순 후보가 없다.\n"
    else:
        for item in contradiction_register:
            var npc_id := str(item.get("npc_id", ""))
            var display_name := npc_id
            if npc_id in npcs:
                display_name = npcs[npc_id].display_name
            out += "• [b]%s[/b] 알리바이 ↔ [color=#ffd36a]%s[/color]\n" % [display_name, str(item.get("evidence", ""))]

    out += "\n[color=#8ea5c5]NOTE · 노트북의 연결은 발견한 증거와 실제 발언만 표시하며, 숨겨진 역할 자체는 공개하지 않는다.[/color]"
    return out

func apply_meeting_ai(event_index: int, action: Dictionary) -> void:
    if event_index < 0 or event_index >= meeting_events.size():
        return

    var event: Dictionary = meeting_events[event_index]
    var speaker_id := str(event.get("speaker", ""))
    if speaker_id == "" or speaker_id not in npcs or not npcs[speaker_id].alive:
        return

    var utterance := str(action.get("utterance", ""))
    if utterance == "":
        return

    meeting_events[event_index]["text"] = utterance
    meeting_events[event_index]["ai_performed"] = true
    display_emotions[speaker_id] = str(action.get("display_emotion", expression_for(speaker_id)))
    npcs[speaker_id].remember("Day %d AI meeting performance: %s" % [day, utterance])
    _append_turn(speaker_id, str(event.get("target", "")), "ai_meeting", "MEETING", utterance)

func case_public_summary() -> String:
    return "%s · %s\n피해자: %s\n%s" % [case_title, case_subtitle, str(truth.incident.get("victim", "")), str(truth.incident.get("objective", ""))]

func next_case_id() -> String:
    return "GLASS_GARDEN" if case_id == "DEAD_AIR" else "DEAD_AIR"
