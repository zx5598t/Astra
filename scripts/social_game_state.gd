class_name AstraSocialGameState
extends AstraGameState

const SOCIAL_VERSION := "0.0.4"

var relationships: Dictionary = {}
var meeting_events: Array[Dictionary] = []

func setup(seed_in: int = 260916) -> void:
    super.setup(seed_in)
    meeting_events.clear()
    _initialize_relationships()

func _initialize_relationships() -> void:
    relationships.clear()
    for source_id in crew_order:
        relationships[source_id] = {}
        for target_id in crew_order:
            if target_id == source_id:
                continue
            var affinity := truth.rng.randf_range(-0.22, 0.30)
            if source_id == "mira" and target_id == "lyra": affinity += 0.18
            if source_id == "lyra" and target_id == "mira": affinity += 0.14
            if source_id == "noa" and target_id == "eli": affinity += 0.12
            if source_id == "sena" and target_id == "rho": affinity -= 0.10
            relationships[source_id][target_id] = clampf(affinity, -1.0, 1.0)

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

func affinity(source_id: String, target_id: String) -> float:
    return float(relationships.get(source_id, {}).get(target_id, 0.0))

func adjust_affinity(source_id: String, target_id: String, delta: float) -> void:
    if source_id not in relationships:
        relationships[source_id] = {}
    relationships[source_id][target_id] = clampf(affinity(source_id, target_id) + delta, -1.0, 1.0)

func relationship_lines(npc_id: String) -> Array[String]:
    var result: Array[String] = []
    if npc_id not in npcs:
        return result
    var ranked: Array[Dictionary] = []
    for target_id in crew_order:
        if target_id == npc_id:
            continue
        ranked.append({"id":target_id, "value":affinity(npc_id, target_id)})
    ranked.sort_custom(_relationship_sort)
    var count := mini(3, ranked.size())
    for i in range(count):
        var item: Dictionary = ranked[i]
        var value := float(item["value"])
        var tag := "호감" if value > 0.10 else "마찰" if value < -0.10 else "중립"
        var target: NPCState = npcs[str(item["id"])]
        result.append("%s · %s %+.0f" % [target.display_name, tag, value * 100.0])
    return result

func _relationship_sort(a: Dictionary, b: Dictionary) -> bool:
    return absf(float(a.get("value", 0.0))) > absf(float(b.get("value", 0.0)))

func question_options(npc_id: String) -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    if npc_id not in npcs:
        return options
    var npc: NPCState = npcs[npc_id]
    options.append({"intent":"ALIBI", "label":"알리바이를 재구성한다", "hint":"시간대 주장을 고정"})
    options.append({"intent":"MOTIVE", "label":"함장과의 관계를 묻는다", "hint":"감정적 동기 확인"})
    if not discovered_evidence.is_empty():
        options.append({"intent":"EVIDENCE", "label":"최근 증거를 제시한다", "hint":"즉각적인 반응 확인"})
    var suspect_id := npc.highest_suspicion()
    if suspect_id != "" and suspect_id in npcs:
        options.append({"intent":"ASK_SUSPECT", "label":"%s을(를) 왜 의심하는지 묻는다" % npcs[suspect_id].display_name, "hint":"현재 믿음 구조 확인"})
    if npc.commitments.size() > 0 and discovered_evidence.size() >= 2:
        options.append({"intent":"CONTRADICTION", "label":"이전 주장과 기록의 모순을 짚는다", "hint":"고정 발언을 압박"})
    if npc.trust_player >= 0.58:
        options.append({"intent":"CONFIDE", "label":"둘만 아는 판단을 요청한다", "hint":"높은 신뢰에서 등장"})
    elif float(npc.emotion.get("stress", 0.2)) >= 0.48:
        options.append({"intent":"REASSURE", "label":"진정시키고 다시 묻는다", "hint":"스트레스를 낮춤"})
    else:
        options.append({"intent":"PRESSURE", "label":"답을 재촉하며 압박한다", "hint":"신뢰 하락 위험"})
    if options.size() > 6:
        options.resize(6)
    return options

func _generate_rule_based_response(npc: NPCState, intent: String) -> String:
    match intent:
        "ASK_SUSPECT":
            var target_id := npc.highest_suspicion()
            if target_id == "" or target_id not in npcs:
                return "아직 누구 하나로 좁히진 못했어."
            var target: NPCState = npcs[target_id]
            return "%s의 말과 행동이 가장 맞지 않아 보여. 지금 내 의심은 %d%% 정도야." % [target.display_name, int(npc.get_suspicion(target_id) * 100.0)]
        "CONTRADICTION":
            npc.adjust_stress(0.10)
            npc.adjust_trust(-0.025)
            if npc.role == "NULL":
                return "그 두 기록이 정말 같은 사건을 가리킨다는 보장은 없잖아. 연결부터 증명해."
            return "좋아. 내가 전에 한 말과 기록이 어긋난다면 정확히 어느 지점인지 같이 보자."
        "CONFIDE":
            npc.adjust_trust(0.025)
            var suspect_id := npc.highest_suspicion()
            if suspect_id in npcs:
                return "공개적으로는 말 안 했지만, 난 %s 쪽을 더 보고 있어. 내 판단을 그대로 믿진 마." % npcs[suspect_id].display_name
            return "아직 확신은 없어. 기록을 더 모으면 같이 맞춰볼 수 있어."
    return super._generate_rule_based_response(npc, intent)

func _run_meeting_reactions() -> void:
    meeting_summary.clear()
    meeting_events.clear()
    for npc_id in crew_order:
        var npc: NPCState = npcs[npc_id]
        var target_id := npc.highest_suspicion()
        if target_id == "" or target_id not in npcs:
            continue
        var target: NPCState = npcs[target_id]
        meeting_summary.append("%s → %s 의심 (%d%%)" % [npc.display_name, target.display_name, int(npc.get_suspicion(target_id) * 100.0)])
        meeting_events.append({"speaker":npc.id, "target":target.id, "kind":"claim", "text":_meeting_statement(npc, target)})
        _try_interruption(npc, target)
    log_event("MEETING · %d개의 발언/반박 발생" % meeting_events.size())

func _meeting_statement(npc: NPCState, target: NPCState) -> String:
    match npc.id:
        "noa": return "%s은(는) 앞에서 한 표현과 지금의 설명이 조금 달라." % target.display_name
        "dax": return "%s의 동선에는 시스템 기록으로 설명되지 않는 공백이 있어." % target.display_name
        "lyra": return "%s, 네가 긴장한 건 이해해. 그래도 시간대는 다시 말해줘." % target.display_name
        "sena": return "%s. 감정 말고 기록으로 답해. 네 동선을 확인하겠다." % target.display_name
        "eli": return "지금 가장 이상한 수는 %s 쪽이야. 물론 틀릴 수도 있고." % target.display_name
        "vale": return "%s만 보고 결론 내리는 건 위험해. 그래도 설명은 필요하지." % target.display_name
        "rho": return "%s, 돌려 말하지 말고 어디 있었는지 똑바로 말해." % target.display_name
        "mira": return "%s을(를) 단정하진 않겠어. 다만 기록과 말이 맞는지는 확인해야 해." % target.display_name
    return "%s을(를) 의심하고 있어." % target.display_name

func _try_interruption(speaker: NPCState, target: NPCState) -> void:
    var candidates: Array[String] = []
    for other_id in crew_order:
        if other_id == speaker.id or other_id == target.id:
            continue
        var other: NPCState = npcs[other_id]
        var social := float(other.personality.get("social", 0.5))
        var aggressive := float(other.personality.get("aggressive", 0.3))
        var protect_target := affinity(other_id, target.id) > 0.18
        var dislike_speaker := affinity(other_id, speaker.id) < -0.12
        var trigger := social * 0.35 + aggressive * 0.30
        if protect_target: trigger += 0.24
        if dislike_speaker: trigger += 0.18
        if truth.rng.randf() < trigger * 0.38:
            candidates.append(other_id)
    if candidates.is_empty():
        return
    var interrupter_id := candidates[truth.rng.randi_range(0, candidates.size() - 1)]
    var interrupter: NPCState = npcs[interrupter_id]
    var defend := affinity(interrupter_id, target.id) > 0.12
    var text := "%s, 그 주장에는 근거가 부족해. 네 해석을 사실처럼 말하지 마." % speaker.display_name
    var kind := "challenge"
    if defend:
        text = "잠깐. %s의 말만으로 %s을(를) 몰아가면 안 돼." % [speaker.display_name, target.display_name]
        kind = "defend"
        adjust_affinity(interrupter_id, target.id, 0.025)
    meeting_events.append({"speaker":interrupter.id, "target":speaker.id, "kind":kind, "text":text})
    adjust_affinity(interrupter.id, speaker.id, -0.035)
    adjust_affinity(speaker.id, interrupter.id, -0.025)

func _npc_vote(npc: NPCState) -> String:
    if npc.role == "NULL":
        return super._npc_vote(npc)
    var choice := crew_order[0]
    var best := -1.0
    for target_key in npc.suspicion.keys():
        var target_id := str(target_key)
        if target_id in npcs and npcs[target_id].alive:
            var score := npc.get_suspicion(target_id) - affinity(npc.id, target_id) * 0.12
            if score > best:
                best = score
                choice = target_id
    return choice

func build_ai_context(npc_id: String, situation: String, intent: String = "") -> Dictionary:
    if npc_id not in npcs:
        return {}
    var npc: NPCState = npcs[npc_id]
    var allowed_refs: Array[String] = []
    for fact_id in npc.knowledge:
        allowed_refs.append(fact_id)
    for ev_id in discovered_evidence:
        var fact_ref := str(truth.evidence[ev_id]["fact_ref"])
        if fact_ref not in allowed_refs:
            allowed_refs.append(fact_ref)
    return {
        "npc": {
            "id":npc.id, "name":npc.display_name, "job":npc.job,
            "speech_style":npc.speech_style, "social_goal":npc.social_goal,
            "pressure_response":npc.pressure_response, "emotion":npc.emotion,
            "trust_player":npc.trust_player
        },
        "scene": {"phase":phase_name(), "situation":situation, "intent":intent, "day":day},
        "allowed_fact_refs":allowed_refs,
        "known_evidence":discovered_evidence.duplicate(),
        "relationships":relationships.get(npc_id, {}).duplicate(true)
    }
