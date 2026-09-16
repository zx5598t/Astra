class_name AstraLoopGameState
extends AstraSocialGameState

const LOOP_VERSION := "0.0.5"
const MAX_DAYS := 3
const MAX_CONVERSATION_TURNS := 40

var conversation_history: Array[Dictionary] = []
var display_emotions: Dictionary = {}
var day_report_text: String = ""
var day_vote_history: Array[Dictionary] = []
var last_player_intent: String = ""
var last_spoken_npc_id: String = ""

func setup(seed_in: int = 260916) -> void:
    super.setup(seed_in)
    day = 1
    conversation_history.clear()
    display_emotions.clear()
    day_vote_history.clear()
    day_report_text = ""
    last_player_intent = ""
    last_spoken_npc_id = ""
    for npc_id in crew_order:
        display_emotions[npc_id] = "calm"
    log_event("LOOP · 최대 %d일 생존 조사 시작" % MAX_DAYS)

func talk_to(npc_id: String, intent: String) -> String:
    if npc_id not in npcs or not npcs[npc_id].alive:
        return "격리된 승무원과는 대화할 수 없다."
    last_player_intent = intent
    last_spoken_npc_id = npc_id
    _append_turn("player", npc_id, "question", intent, "")
    var response := super.talk_to(npc_id, intent)
    _append_turn(npc_id, "player", "answer", intent, response)
    _update_engine_emotion(npc_id, intent)
    return response

func _append_turn(speaker_id: String, target_id: String, kind: String, intent: String, text: String) -> void:
    conversation_history.append({
        "day": day,
        "phase": phase_name(),
        "speaker": speaker_id,
        "target": target_id,
        "kind": kind,
        "intent": intent,
        "text": text
    })
    if conversation_history.size() > MAX_CONVERSATION_TURNS:
        conversation_history.pop_front()

func _run_meeting_reactions() -> void:
    super._run_meeting_reactions()
    for event in meeting_events:
        var speaker_id := str(event.get("speaker", ""))
        var target_id := str(event.get("target", ""))
        var text := str(event.get("text", ""))
        var kind := str(event.get("kind", "claim"))
        _append_turn(speaker_id, target_id, kind, "MEETING", text)
        if speaker_id in npcs:
            var npc: NPCState = npcs[speaker_id]
            npc.remember("Day %d meeting: %s" % [day, text])
            if kind == "challenge":
                display_emotions[speaker_id] = "angry" if float(npc.personality.get("aggressive", 0.3)) > 0.5 else "guarded"
            elif kind == "defend":
                display_emotions[speaker_id] = "warm"
    _add_memory_echo()

func _add_memory_echo() -> void:
    if day <= 1 or conversation_history.size() < 4:
        return
    var candidates: Array[Dictionary] = []
    for turn in conversation_history:
        if int(turn.get("day", day)) < day and str(turn.get("speaker", "")) != "player" and str(turn.get("text", "")) != "":
            candidates.append(turn)
    if candidates.is_empty():
        return
    var recalled: Dictionary = candidates[truth.rng.randi_range(0, candidates.size() - 1)]
    var rememberer_id := "noa" if "noa" in npcs and npcs["noa"].alive else str(recalled.get("speaker", ""))
    if rememberer_id == "" or rememberer_id not in npcs or not npcs[rememberer_id].alive:
        return
    var original_speaker := str(recalled.get("speaker", ""))
    var original_name := original_speaker
    if original_speaker in npcs:
        original_name = npcs[original_speaker].display_name
    var text := "%s, 어제는 ‘%s’라고 말했어. 지금 설명과 같은 의미야?" % [original_name, _short_quote(str(recalled.get("text", "")))]
    meeting_events.append({"speaker":rememberer_id, "target":original_speaker, "kind":"memory", "text":text})
    _append_turn(rememberer_id, original_speaker, "memory", "MEETING", text)

func _short_quote(text: String) -> String:
    var clean := text.replace("\n", " ")
    if clean.length() > 42:
        return clean.substr(0, 42) + "…"
    return clean

func question_options(npc_id: String) -> Array[Dictionary]:
    if npc_id not in npcs or not npcs[npc_id].alive:
        return []
    var options := super.question_options(npc_id)
    if day > 1:
        options.push_front({"intent":"YESTERDAY", "label":"어제 발언을 다시 확인한다", "hint":"이전 Day의 기억과 비교"})
    if conversation_history.size() >= 6:
        options.append({"intent":"CHAIN", "label":"방금 회의의 발언을 연결해 추궁한다", "hint":"직전 발언자와 모순 비교"})
    if options.size() > 6:
        options.resize(6)
    return options

func _generate_rule_based_response(npc: NPCState, intent: String) -> String:
    match intent:
        "YESTERDAY":
            var prior := _last_prior_day_turn(npc.id)
            if prior.is_empty():
                return "어제 내가 확정적으로 말한 건 없어. 기록을 다시 확인해봐."
            npc.adjust_stress(0.035)
            return "어제 말한 핵심은 바꾸지 않았어. ‘%s’ 그 부분을 말하는 거지?" % _short_quote(str(prior.get("text", "")))
        "CHAIN":
            var previous := _last_other_npc_turn(npc.id)
            if previous.is_empty():
                return "연결해서 볼 만한 직전 발언이 없어."
            var speaker_id := str(previous.get("speaker", ""))
            var speaker_name := speaker_id
            if speaker_id in npcs:
                speaker_name = npcs[speaker_id].display_name
            npc.adjust_stress(0.045)
            if affinity(npc.id, speaker_id) < -0.12:
                return "%s의 해석에는 동의하지 않아. 사실과 추측을 섞고 있어." % speaker_name
            return "%s의 말은 참고할 만하지만, 그걸로 결론까지 갈 수는 없어." % speaker_name
    return super._generate_rule_based_response(npc, intent)

func _last_prior_day_turn(npc_id: String) -> Dictionary:
    for i in range(conversation_history.size() - 1, -1, -1):
        var turn: Dictionary = conversation_history[i]
        if str(turn.get("speaker", "")) == npc_id and int(turn.get("day", day)) < day and str(turn.get("text", "")) != "":
            return turn
    return {}

func _last_other_npc_turn(npc_id: String) -> Dictionary:
    for i in range(conversation_history.size() - 1, -1, -1):
        var turn: Dictionary = conversation_history[i]
        var speaker_id := str(turn.get("speaker", ""))
        if speaker_id != "" and speaker_id != "player" and speaker_id != npc_id and str(turn.get("text", "")) != "":
            return turn
    return {}

func vote(target_id: String) -> String:
    if phase_name() != "VOTE":
        return "지금은 투표 단계가 아니다."
    if target_id not in npcs or not npcs[target_id].alive:
        return "투표할 수 없는 대상이다."

    votes.clear()
    votes["player"] = target_id
    var tally: Dictionary = {target_id: 1}
    for npc_id in crew_order:
        var npc: NPCState = npcs[npc_id]
        if not npc.alive:
            continue
        var choice := _npc_vote(npc)
        if choice == "" or choice not in npcs or not npcs[choice].alive:
            continue
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
    day_vote_history.append({"day":day, "exiled":exiled, "role":exiled_npc.role, "votes":top})
    log_event("DAY %d VOTE · %s 격리 (%d표)" % [day, exiled_npc.display_name, top])
    for npc_id in crew_order:
        var observer: NPCState = npcs[npc_id]
        if observer.alive:
            observer.remember("Day %d: %s was isolated" % [day, exiled_npc.display_name])

    var nulls_left := _living_role_count("NULL")
    var crew_left := _living_role_count("CREW")
    if nulls_left <= 0:
        _finish_campaign("ASTRA STABILIZED", "두 명의 Null을 모두 격리했다. 승무원들의 기억과 관계는 다음 사건으로 이어진다.", 1200)
    elif crew_left <= nulls_left:
        _finish_campaign("NULL ASCENDANT", "남은 Crew 수가 Null과 같아졌다. 선내 의사결정권이 붕괴했다.", -350)
    elif day >= MAX_DAYS:
        _finish_campaign("SIGNAL LOST", "%d일 동안 모든 Null을 찾아내지 못했다. 사건 기록은 다음 루프의 단서로 남는다." % MAX_DAYS, -120)
    else:
        _begin_next_day(exiled_npc)

    emit_signal("state_changed")
    return day_report_text if not game_over else ending_text

func _begin_next_day(exiled_npc: NPCState) -> void:
    day += 1
    phase_index = 0
    investigation_actions_left = INVESTIGATION_ACTIONS
    talk_actions_left = TALK_ACTIONS
    votes.clear()
    meeting_summary.clear()
    meeting_events.clear()
    selected_npc_id = _first_living_npc()
    day_report_text = "DAY %d 시작 · %s은(는) 격리되었고 정체는 아직 확인되지 않았다. 남은 승무원 %d명. 전날의 발언과 관계 변화가 유지된다." % [day, exiled_npc.display_name, _living_count()]
    log_event(day_report_text)
    _apply_overnight_pressure()

func _apply_overnight_pressure() -> void:
    for npc_id in crew_order:
        var npc: NPCState = npcs[npc_id]
        if not npc.alive:
            continue
        npc.adjust_stress(0.055)
        npc.adjust_trust(-0.005)
        display_emotions[npc_id] = _derive_emotion(npc)

func _finish_campaign(title: String, text: String, score_delta: int) -> void:
    game_over = true
    phase_index = PHASES.size() - 1
    result_title = title
    var correct_isolations := 0
    var false_isolations := 0
    for result in day_vote_history:
        if str(result.get("role", "")) == "NULL":
            correct_isolations += 1
        else:
            false_isolations += 1
    score = maxi(0, score + score_delta + correct_isolations * 450 - false_isolations * 120 + discovered_evidence.size() * 25)
    ending_text = text
    day_report_text = ""
    log_event("CAMPAIGN RESULT · %s · SCORE %d" % [result_title, score])

func _living_count() -> int:
    var count := 0
    for npc_id in crew_order:
        if npcs[npc_id].alive:
            count += 1
    return count

func _living_role_count(role_name: String) -> int:
    var count := 0
    for npc_id in crew_order:
        var npc: NPCState = npcs[npc_id]
        if npc.alive and npc.role == role_name:
            count += 1
    return count

func _first_living_npc() -> String:
    for npc_id in crew_order:
        if npcs[npc_id].alive:
            return npc_id
    return crew_order[0]

func _npc_vote(npc: NPCState) -> String:
    if not npc.alive:
        return ""
    if npc.role == "NULL":
        var crew_candidates: Array[String] = []
        for other_id in crew_order:
            var other: NPCState = npcs[other_id]
            if other.alive and other.id != npc.id and other.role == "CREW":
                crew_candidates.append(other.id)
        if not crew_candidates.is_empty():
            return crew_candidates[truth.rng.randi_range(0, crew_candidates.size() - 1)]
    var choice := ""
    var best := -999.0
    for target_id in crew_order:
        if target_id == npc.id or not npcs[target_id].alive:
            continue
        var score_value := npc.get_suspicion(target_id) - affinity(npc.id, target_id) * 0.12
        if score_value > best:
            best = score_value
            choice = target_id
    return choice

func build_ai_context(npc_id: String, situation: String, intent: String = "") -> Dictionary:
    var context := super.build_ai_context(npc_id, situation, intent)
    if context.is_empty():
        return context
    var allowed_facts: Dictionary = {}
    for fact_id in context.get("allowed_fact_refs", []):
        allowed_facts[str(fact_id)] = truth.fact_text(str(fact_id))
    var allowed_targets: Array[String] = []
    for target_id in crew_order:
        if target_id != npc_id and npcs[target_id].alive:
            allowed_targets.append(target_id)
    context["allowed_facts"] = allowed_facts
    context["allowed_target_ids"] = allowed_targets
    context["recent_turns"] = recent_turns(10)
    context["scene"]["max_days"] = MAX_DAYS
    context["scene"]["living_crew"] = _living_count()
    return context

func recent_turns(limit: int = 10) -> Array[Dictionary]:
    var output: Array[Dictionary] = []
    var start := maxi(0, conversation_history.size() - limit)
    for i in range(start, conversation_history.size()):
        output.append(conversation_history[i].duplicate(true))
    return output

func apply_ai_performance(npc_id: String, action: Dictionary) -> void:
    if npc_id not in npcs:
        return
    var utterance := str(action.get("utterance", ""))
    var emotion := str(action.get("display_emotion", "calm"))
    display_emotions[npc_id] = emotion
    if utterance != "":
        for i in range(conversation_history.size() - 1, -1, -1):
            var turn: Dictionary = conversation_history[i]
            if str(turn.get("speaker", "")) == npc_id and str(turn.get("kind", "")) == "answer":
                turn["text"] = utterance
                turn["ai_performed"] = true
                conversation_history[i] = turn
                break
        npcs[npc_id].remember("AI performance: %s" % utterance)

func expression_for(npc_id: String) -> String:
    if npc_id not in npcs:
        return "calm"
    var stored := str(display_emotions.get(npc_id, ""))
    if stored != "":
        return stored
    return _derive_emotion(npcs[npc_id])

func _derive_emotion(npc: NPCState) -> String:
    var stress := float(npc.emotion.get("stress", 0.2))
    if stress > 0.78:
        return "afraid" if float(npc.personality.get("aggressive", 0.3)) < 0.35 else "angry"
    if stress > 0.52:
        return "uneasy"
    if npc.trust_player > 0.70:
        return "warm"
    if npc.trust_player < 0.38:
        return "cold"
    return "calm"

func _update_engine_emotion(npc_id: String, intent: String) -> void:
    if npc_id not in npcs:
        return
    var npc: NPCState = npcs[npc_id]
    if intent == "PRESSURE" or intent == "CONTRADICTION":
        display_emotions[npc_id] = "angry" if float(npc.personality.get("aggressive", 0.3)) > 0.5 else "guarded"
    elif intent == "REASSURE" or intent == "CONFIDE":
        display_emotions[npc_id] = "warm"
    else:
        display_emotions[npc_id] = _derive_emotion(npc)
