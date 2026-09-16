class_name AstraHypothesisGameState
extends AstraProgressionGameState

const HYPOTHESIS_VERSION := "0.0.8"
const CASE_IDS_V008 := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]

var manual_links: Array[Dictionary] = []
var personal_event_history: Array[Dictionary] = []
var pending_personal_event: Dictionary = {}
var _personal_event_days: Dictionary = {}

func setup(seed_in: int = 260916) -> void:
    manual_links.clear()
    personal_event_history.clear()
    pending_personal_event.clear()
    _personal_event_days.clear()
    super.setup(seed_in)

func _select_case() -> void:
    if preferred_case_id in CASE_IDS_V008:
        case_id = preferred_case_id
    else:
        case_id = CASE_IDS_V008[truth.rng.randi_range(0, CASE_IDS_V008.size() - 1)]
    match case_id:
        "GLASS_GARDEN":
            case_title = "INCIDENT ONE"
            case_subtitle = "Glass Garden"
            case_theme = "수목구역 오염과 생명유지 교란"
        "ECHO_WARD":
            case_title = "INCIDENT TWO"
            case_subtitle = "Echo Ward"
            case_theme = "의료 기록 복제와 냉동수면 구역의 시간 공백"
        _:
            case_title = "INCIDENT ZERO"
            case_subtitle = "Dead Air"
            case_theme = "통신 두절과 전력 우회"

func _configure_case_truth() -> void:
    if case_id != "ECHO_WARD":
        super._configure_case_truth()
        return

    var n1 := hidden_null_ids[0]
    var n2 := hidden_null_ids[1]
    var d1 := decoy_ids[0]
    var d2 := decoy_ids[1]
    var n1_name: String = npcs[n1].display_name
    var n2_name: String = npcs[n2].display_name
    var d1_name: String = npcs[d1].display_name
    var d2_name: String = npcs[d2].display_name

    truth.facts = {
        "FACT_001": {"text":"의료 책임자 Sael의 신경 정지 시각은 03:11~03:15 사이다.", "secret":false, "known_by":crew_order.duplicate()},
        "FACT_002": {"text":"%s의 자격 증명이 03:12 냉동수면 포드 4번을 강제 해제했다." % n1_name, "secret":true, "known_by":[n1,"mira","sena"]},
        "FACT_003": {"text":"%s의 개인 단말이 03:13 의료 기록 복제 명령을 실행했다." % n2_name, "secret":true, "known_by":[n2,"noa"]},
        "FACT_004": {"text":"%s의 바이오 태그는 03:10~03:16 중계실 안에서 연속 기록됐다." % d1_name, "secret":true, "known_by":[d1,"vale"]},
        "FACT_005": {"text":"Sael의 사망 은폐에는 포드 해제와 의료 기록 복제가 모두 필요했다.", "secret":false, "known_by":["mira","dax","noa"]},
        "FACT_006": {"text":"냉동수면실 비상 패널에서 %s의 장갑 섬유와 일치하는 흔적이 검출됐다." % n1_name, "secret":true, "known_by":["sena","mira"]},
        "FACT_007": {"text":"기록보관실 미러 서버의 복구 키가 %s의 단말 세션과 일치한다." % n2_name, "secret":true, "known_by":["noa","dax"]},
        "FACT_008": {"text":"%s는 03:14 항법 브리지 출입기에 인증되어 있다." % d2_name, "secret":true, "known_by":[d2,"eli"]}
    }
    truth.evidence = {
        "EV_01": {"name":"Sael 생체 정지 타임라인", "fact_ref":"FACT_001", "location":"의료실", "rarity":"COMMON", "signal":"context", "target_id":""},
        "EV_02": {"name":"의료 기록 복제 명령", "fact_ref":"FACT_003", "location":"의료실", "rarity":"KEY", "signal":"implicates", "target_id":n2, "contradicts_alibi":true},
        "EV_03": {"name":"포드 4 강제 해제 로그", "fact_ref":"FACT_002", "location":"냉동수면실", "rarity":"KEY", "signal":"implicates", "target_id":n1, "contradicts_alibi":true},
        "EV_04": {"name":"비상 패널 장갑 섬유", "fact_ref":"FACT_006", "location":"냉동수면실", "rarity":"COMMON", "signal":"implicates", "target_id":n1, "contradicts_alibi":false},
        "EV_05": {"name":"미러 서버 복구 키", "fact_ref":"FACT_007", "location":"기록보관실", "rarity":"KEY", "signal":"implicates", "target_id":n2, "contradicts_alibi":false},
        "EV_06": {"name":"이중 조작 요구 분석", "fact_ref":"FACT_005", "location":"기록보관실", "rarity":"COMMON", "signal":"context", "target_id":""},
        "EV_07": {"name":"중계실 바이오 태그", "fact_ref":"FACT_004", "location":"중계실", "rarity":"KEY", "signal":"clears", "target_id":d1},
        "EV_08": {"name":"항법 브리지 출입 인증", "fact_ref":"FACT_008", "location":"중계실", "rarity":"COMMON", "signal":"clears", "target_id":d2}
    }
    truth.incident = {
        "title":case_title,
        "subtitle":case_subtitle,
        "victim":"Medical Chief Sael",
        "locations":["의료실","냉동수면실","기록보관실","중계실"],
        "null_ids":hidden_null_ids.duplicate(),
        "objective":"냉동수면 포드와 의료 기록의 두 조작 경로를 연결해 Null 침투자를 격리하라.",
        "theme":case_theme
    }

func next_case_id() -> String:
    var index := CASE_IDS_V008.find(case_id)
    if index < 0:
        return CASE_IDS_V008[0]
    return CASE_IDS_V008[(index + 1) % CASE_IDS_V008.size()]

func environment_asset_path() -> String:
    if case_id == "GLASS_GARDEN":
        return "res://assets/environments/glass_garden.svg"
    if case_id == "ECHO_WARD":
        return "res://assets/environments/echo_ward.svg"
    return "res://assets/environments/dead_air.svg"

func add_manual_link(evidence_id: String, target_id: String, kind: String) -> bool:
    if evidence_id not in discovered_evidence or target_id not in npcs:
        return false
    if kind not in ["suspect", "clear", "question"]:
        return false
    for i in range(manual_links.size() - 1, -1, -1):
        var item: Dictionary = manual_links[i]
        if str(item.get("evidence_id", "")) == evidence_id and str(item.get("target_id", "")) == target_id:
            if str(item.get("kind", "")) == kind:
                manual_links.remove_at(i)
                emit_signal("state_changed")
                return true
            item["kind"] = kind
            manual_links[i] = item
            emit_signal("state_changed")
            return true
    manual_links.append({"evidence_id":evidence_id, "target_id":target_id, "kind":kind})
    log_event("HYPOTHESIS · %s → %s [%s]" % [truth.evidence_name(evidence_id), npcs[target_id].display_name, kind])
    emit_signal("state_changed")
    return true

func remove_manual_link(evidence_id: String, target_id: String) -> bool:
    for i in range(manual_links.size() - 1, -1, -1):
        var item: Dictionary = manual_links[i]
        if str(item.get("evidence_id", "")) == evidence_id and str(item.get("target_id", "")) == target_id:
            manual_links.remove_at(i)
            emit_signal("state_changed")
            return true
    return false

func manual_link_kind(evidence_id: String, target_id: String) -> String:
    for item in manual_links:
        if str(item.get("evidence_id", "")) == evidence_id and str(item.get("target_id", "")) == target_id:
            return str(item.get("kind", ""))
    return ""

func advance_phase() -> void:
    var previous := phase_name()
    super.advance_phase()
    if game_over or phase_name() == previous:
        return
    if phase_name() == "INTERROGATION":
        _try_personal_event()

func _try_personal_event() -> void:
    if not pending_personal_event.is_empty() or bool(_personal_event_days.get(day, false)):
        return
    var candidate := _best_personal_event_candidate()
    if candidate == "":
        return
    pending_personal_event = _personal_event_template(candidate)
    if pending_personal_event.is_empty():
        return
    _personal_event_days[day] = true
    log_event("PERSONAL · %s" % str(pending_personal_event.get("title", "Private Event")))
    emit_signal("state_changed")

func _best_personal_event_candidate() -> String:
    var best_id := ""
    var best_score := -999.0
    for npc_id in crew_order:
        var npc: NPCState = npcs[npc_id]
        if not npc.alive:
            continue
        var score_value := npc.trust_player + float(npc.personality.get("social", 0.5)) * 0.15
        if npc_id == selected_npc_id:
            score_value += 0.12
        if score_value > best_score:
            best_score = score_value
            best_id = npc_id
    return best_id

func _personal_event_template(npc_id: String) -> Dictionary:
    var npc: NPCState = npcs[npc_id]
    var prompt := "%s이(가) 공개 회의 전에 잠깐 시간을 내달라고 한다." % npc.display_name
    var title := "%s · PRIVATE CHANNEL" % npc.display_name.to_upper()
    var choice_a := "솔직한 판단을 공유한다"
    var choice_b := "수사와 사적인 관계를 분리한다"
    match npc_id:
        "mira": prompt = "Mira가 피해자를 살리지 못한 책임감 때문에 판단이 흐려질까 걱정된다고 털어놓는다."
        "rho": prompt = "Rho가 자신을 계속 의심한다면 차라리 엔진 기록을 전부 공개하겠다고 거칠게 말한다."
        "eli": prompt = "Eli가 모두가 긴장한 틈에 누군가 회의의 흐름을 설계하고 있다고 낮은 목소리로 말한다."
        "sena": prompt = "Sena가 절차를 지키다 범인을 놓칠지, 강제 수사를 할지 선택이 필요하다고 묻는다."
        "vale": prompt = "Vale이 통신 기록 일부를 먼저 당신에게만 설명하겠다며 신뢰를 시험한다."
        "noa": prompt = "Noa가 전날 기록에서 말투가 달라진 사람을 발견했지만 아직 공개할지 망설인다."
        "lyra": prompt = "Lyra가 서로를 몰아붙이는 분위기가 더 큰 실수를 만들 수 있다고 걱정한다."
        "dax": prompt = "Dax가 사람의 직감과 시스템 로그가 충돌할 때 무엇을 우선할지 묻는다."
    return {
        "npc_id":npc_id,
        "title":title,
        "prompt":prompt,
        "choices":[
            {"label":choice_a, "trust":0.055, "stress":-0.035, "affinity":0.035, "result":"상대는 당신이 자신을 하나의 용의자가 아니라 사람으로 보고 있다고 느꼈다."},
            {"label":choice_b, "trust":-0.015, "stress":0.015, "affinity":-0.010, "result":"대화는 짧게 끝났지만 수사의 경계는 명확해졌다."}
        ]
    }

func resolve_personal_event(choice_index: int) -> String:
    if pending_personal_event.is_empty():
        return ""
    var choices: Array = pending_personal_event.get("choices", [])
    if choice_index < 0 or choice_index >= choices.size():
        return ""
    var npc_id := str(pending_personal_event.get("npc_id", ""))
    var choice: Dictionary = choices[choice_index]
    if npc_id in npcs:
        var npc: NPCState = npcs[npc_id]
        npc.adjust_trust(float(choice.get("trust", 0.0)))
        npc.adjust_stress(float(choice.get("stress", 0.0)))
    var record := {
        "day":day,
        "case_id":case_id,
        "npc_id":npc_id,
        "choice_index":choice_index,
        "label":str(choice.get("label", "")),
        "result":str(choice.get("result", ""))
    }
    personal_event_history.append(record)
    var result_text := str(choice.get("result", ""))
    log_event("PERSONAL CHOICE · %s · %s" % [npc_id, str(choice.get("label", ""))])
    pending_personal_event.clear()
    score += 10
    emit_signal("state_changed")
    return result_text
