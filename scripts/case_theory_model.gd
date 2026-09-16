extends RefCounted

const MODEL_VERSION := "0.0.9"

var theory_history: Array[Dictionary] = []
var active_theory: Dictionary = {}
var final_result: Dictionary = {}

func reset() -> void:
    theory_history.clear()
    active_theory.clear()
    final_result.clear()

func submit_theory(state, primary_id: String, secondary_id: String, confidence: int) -> Dictionary:
    if state == null or bool(state.game_over) or str(state.phase_name()) != "VOTE":
        return {"ok":false, "message":"가설 제출은 격리 투표 직전에만 가능하다."}
    if primary_id == secondary_id:
        return {"ok":false, "message":"서로 다른 두 명을 선택해야 한다."}
    if primary_id not in state.npcs or secondary_id not in state.npcs:
        return {"ok":false, "message":"유효한 승무원 두 명을 선택해야 한다."}

    var suspects := [primary_id, secondary_id]
    var support := _support_count(state, suspects)
    var questions := _question_count(state, suspects)
    var contradictions := _contradiction_count(state, suspects)
    active_theory = {
        "day":int(state.day),
        "primary_id":primary_id,
        "secondary_id":secondary_id,
        "confidence":clampi(confidence, 0, 100),
        "support":support,
        "questions":questions,
        "contradictions":contradictions
    }
    theory_history.append(active_theory.duplicate(true))
    return {
        "ok":true,
        "message":"CASE THEORY 제출 완료 · 증거 연결 %d · 모순 %d · 미해결 질문 %d" % [support, contradictions, questions]
    }

func theory_ready_for_vote(day: int) -> bool:
    return not active_theory.is_empty() and int(active_theory.get("day", -1)) == day

func theory_summary(state) -> String:
    if active_theory.is_empty():
        return "아직 제출한 가설이 없다."
    var p := str(active_theory.get("primary_id", ""))
    var s := str(active_theory.get("secondary_id", ""))
    var p_name := p
    var s_name := s
    if state != null and p in state.npcs:
        p_name = str(state.npcs[p].display_name)
    if state != null and s in state.npcs:
        s_name = str(state.npcs[s].display_name)
    return "%s + %s · Confidence %d%% · Support %d · Contradictions %d" % [p_name, s_name, int(active_theory.get("confidence", 0)), int(active_theory.get("support", 0)), int(active_theory.get("contradictions", 0))]

func finalize(state) -> Dictionary:
    if not final_result.is_empty():
        return final_result.duplicate(true)
    if state == null or theory_history.is_empty():
        final_result = {"matched":0, "support":0, "contradictions":0, "confidence":0, "grade":0, "label":"NO THEORY", "bonus":0}
        return final_result.duplicate(true)

    var theory: Dictionary = theory_history[-1]
    var picks := [str(theory.get("primary_id", "")), str(theory.get("secondary_id", ""))]
    var matched := 0
    for npc_id in picks:
        if npc_id in state.hidden_null_ids:
            matched += 1

    var support := int(theory.get("support", 0))
    var contradictions := int(theory.get("contradictions", 0))
    var confidence := int(theory.get("confidence", 0))
    var evidence_score := mini(30, support * 6 + contradictions * 8)
    var identity_score := matched * 30
    var calibration_bonus := 0
    if matched == 2 and confidence >= 65:
        calibration_bonus = 10
    elif matched == 0 and confidence >= 80:
        calibration_bonus = -10
    elif matched == 1 and confidence >= 45 and confidence <= 80:
        calibration_bonus = 5

    var grade := clampi(identity_score + evidence_score + calibration_bonus, 0, 100)
    var label := "FRAGMENTED"
    if grade >= 90:
        label = "S-RANK OBSERVATION"
    elif grade >= 75:
        label = "A-RANK THEORY"
    elif grade >= 55:
        label = "B-RANK THEORY"
    elif grade >= 35:
        label = "C-RANK THEORY"

    final_result = {
        "matched":matched,
        "support":support,
        "contradictions":contradictions,
        "confidence":confidence,
        "grade":grade,
        "label":label,
        "primary_id":picks[0],
        "secondary_id":picks[1],
        "bonus":grade * 4
    }
    return final_result.duplicate(true)

func final_theory_bbcode(state) -> String:
    if final_result.is_empty() or state == null:
        return ""
    var primary_id := str(final_result.get("primary_id", ""))
    var secondary_id := str(final_result.get("secondary_id", ""))
    var primary_name := primary_id
    var secondary_name := secondary_id
    if primary_id in state.npcs:
        primary_name = str(state.npcs[primary_id].display_name)
    if secondary_id in state.npcs:
        secondary_name = str(state.npcs[secondary_id].display_name)
    var null_names := PackedStringArray()
    for npc_id in state.hidden_null_ids:
        null_names.append(str(state.npcs[npc_id].display_name) if npc_id in state.npcs else str(npc_id))
    return "[font_size=24][color=#ffd36a]CASE THEORY REVIEW[/color][/font_size]\n[b]%s[/b] · %d / 100\n제출 용의자 · %s + %s\n실제 Null · %s\n적중 · %d / 2     근거 연결 · %d     모순 활용 · %d     확신도 · %d%%" % [str(final_result.get("label", "")), int(final_result.get("grade", 0)), primary_name, secondary_name, ", ".join(null_names), int(final_result.get("matched", 0)), int(final_result.get("support", 0)), int(final_result.get("contradictions", 0)), int(final_result.get("confidence", 0))]

func _support_count(state, suspects: Array) -> int:
    var count := 0
    for link in state.manual_links:
        if str(link.get("kind", "")) == "suspect" and str(link.get("target_id", "")) in suspects:
            count += 1
    return count

func _question_count(state, suspects: Array) -> int:
    var count := 0
    for link in state.manual_links:
        if str(link.get("kind", "")) == "question" and str(link.get("target_id", "")) in suspects:
            count += 1
    return count

func _contradiction_count(state, suspects: Array) -> int:
    var count := 0
    for item in state.contradiction_register:
        if str(item.get("npc_id", "")) in suspects:
            count += 1
    return count
