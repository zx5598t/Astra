class_name AstraDeductionGameState
extends "res://scripts/hypothesis_game_state.gd"

const DEDUCTION_VERSION := "0.0.9"

var theory_history: Array[Dictionary] = []
var active_theory: Dictionary = {}
var final_theory_result: Dictionary = {}
var _theory_days: Dictionary = {}

func setup(seed_in: int = 260916) -> void:
    theory_history.clear()
    active_theory.clear()
    final_theory_result.clear()
    _theory_days.clear()
    super.setup(seed_in)

func submit_theory(primary_id: String, secondary_id: String, confidence: int) -> Dictionary:
    if phase_name() != "VOTE" or game_over:
        return {"ok":false, "message":"가설 제출은 격리 투표 직전에만 가능하다."}
    if primary_id == secondary_id:
        return {"ok":false, "message":"서로 다른 두 명을 선택해야 한다."}
    if primary_id not in npcs or secondary_id not in npcs:
        return {"ok":false, "message":"유효한 승무원 두 명을 선택해야 한다."}

    var suspects: Array = [primary_id, secondary_id]
    var support: int = _theory_support_count(suspects)
    var questions: int = _theory_question_count(suspects)
    var contradictions: int = _theory_contradiction_count(suspects)
    active_theory = {
        "day":day,
        "primary_id":primary_id,
        "secondary_id":secondary_id,
        "confidence":clampi(confidence, 0, 100),
        "support":support,
        "questions":questions,
        "contradictions":contradictions
    }
    theory_history.append(active_theory.duplicate(true))
    _theory_days[day] = true
    log_event("THEORY · D%d · %s + %s · confidence %d%%" % [day, npcs[primary_id].display_name, npcs[secondary_id].display_name, int(active_theory["confidence"])])
    emit_signal("state_changed")
    return {"ok":true, "message":"CASE THEORY 제출 완료 · 증거 연결 %d · 모순 %d · 미해결 질문 %d" % [support, contradictions, questions]}

func theory_ready_for_vote() -> bool:
    return not active_theory.is_empty() and int(active_theory.get("day", -1)) == day

func theory_summary() -> String:
    if active_theory.is_empty():
        return "아직 제출한 가설이 없다."
    var p: String = str(active_theory.get("primary_id", ""))
    var s: String = str(active_theory.get("secondary_id", ""))
    var p_name: String = p if p not in npcs else str(npcs[p].display_name)
    var s_name: String = s if s not in npcs else str(npcs[s].display_name)
    return "%s + %s · Confidence %d%% · Support %d · Contradictions %d" % [p_name, s_name, int(active_theory.get("confidence", 0)), int(active_theory.get("support", 0)), int(active_theory.get("contradictions", 0))]

func _theory_support_count(suspects: Array) -> int:
    var count: int = 0
    for link in manual_links:
        if str(link.get("kind", "")) == "suspect" and str(link.get("target_id", "")) in suspects:
            count += 1
    return count

func _theory_question_count(suspects: Array) -> int:
    var count: int = 0
    for link in manual_links:
        if str(link.get("kind", "")) == "question" and str(link.get("target_id", "")) in suspects:
            count += 1
    return count

func _theory_contradiction_count(suspects: Array) -> int:
    var count: int = 0
    for item in contradiction_register:
        if str(item.get("npc_id", "")) in suspects:
            count += 1
    return count

func vote(target_id: String) -> String:
    if not theory_ready_for_vote():
        return "먼저 이번 Day의 CASE THEORY를 제출해야 한다."
    return super.vote(target_id)

func _finish_campaign(title: String, text: String, score_delta: int) -> void:
    super._finish_campaign(title, text, score_delta)
    _grade_final_theory()

func _grade_final_theory() -> void:
    if theory_history.is_empty():
        final_theory_result = {"matched":0, "support":0, "contradictions":0, "grade":0, "label":"NO THEORY"}
        return
    var theory: Dictionary = theory_history[-1]
    var picks: Array = [str(theory.get("primary_id", "")), str(theory.get("secondary_id", ""))]
    var matched: int = 0
    for npc_id in picks:
        if str(npc_id) in hidden_null_ids:
            matched += 1
    var support: int = int(theory.get("support", 0))
    var contradictions: int = int(theory.get("contradictions", 0))
    var confidence: int = int(theory.get("confidence", 0))
    var evidence_score: int = mini(30, support * 6 + contradictions * 8)
    var identity_score: int = matched * 30
    var calibration_bonus: int = 0
    if matched == 2 and confidence >= 65:
        calibration_bonus = 10
    elif matched == 0 and confidence >= 80:
        calibration_bonus = -10
    elif matched == 1 and confidence >= 45 and confidence <= 80:
        calibration_bonus = 5
    var grade: int = clampi(identity_score + evidence_score + calibration_bonus, 0, 100)
    var label: String = "FRAGMENTED"
    if grade >= 90:
        label = "S-RANK OBSERVATION"
    elif grade >= 75:
        label = "A-RANK THEORY"
    elif grade >= 55:
        label = "B-RANK THEORY"
    elif grade >= 35:
        label = "C-RANK THEORY"
    final_theory_result = {"matched":matched, "support":support, "contradictions":contradictions, "confidence":confidence, "grade":grade, "label":label, "primary_id":str(picks[0]), "secondary_id":str(picks[1])}
    score += grade * 4
    ending_text += "\n\nCASE THEORY · %s · %d/100 · Null identification %d/2" % [label, grade, matched]
    log_event("THEORY RESULT · %s · %d/100 · matched %d/2" % [label, grade, matched])

func final_theory_bbcode() -> String:
    if final_theory_result.is_empty():
        return ""
    var primary_id: String = str(final_theory_result.get("primary_id", ""))
    var secondary_id: String = str(final_theory_result.get("secondary_id", ""))
    var primary_name: String = primary_id if primary_id not in npcs else str(npcs[primary_id].display_name)
    var secondary_name: String = secondary_id if secondary_id not in npcs else str(npcs[secondary_id].display_name)
    var null_names := PackedStringArray()
    for npc_id in hidden_null_ids:
        null_names.append(str(npcs[npc_id].display_name) if npc_id in npcs else str(npc_id))
    return "[font_size=24][color=#ffd36a]CASE THEORY REVIEW[/color][/font_size]\n[b]%s[/b] · %d / 100\n제출 용의자 · %s + %s\n실제 Null · %s\n적중 · %d / 2     근거 연결 · %d     모순 활용 · %d     확신도 · %d%%" % [str(final_theory_result.get("label", "")), int(final_theory_result.get("grade", 0)), primary_name, secondary_name, ", ".join(null_names), int(final_theory_result.get("matched", 0)), int(final_theory_result.get("support", 0)), int(final_theory_result.get("contradictions", 0)), int(final_theory_result.get("confidence", 0))]

func _personal_event_template(npc_id: String) -> Dictionary:
    var event: Dictionary = super._personal_event_template(npc_id)
    if event.is_empty():
        return event
    var npc = npcs[npc_id]
    var choices: Array = event.get("choices", [])
    choices.append({"label":"한 사람을 특정하지 말고 관찰 가능한 사실만 다시 말해달라고 한다", "trust":0.02, "stress":-0.01, "affinity":0.0, "result":"%s은(는) 잠시 감정을 누르고 자신이 직접 본 것과 추측을 구분해서 다시 설명했다." % str(npc.display_name)})
    event["choices"] = choices
    event["scene_beat"] = _personal_scene_beat(npc_id)
    return event

func _personal_scene_beat(npc_id: String) -> String:
    match npc_id:
        "mira": return "의료실 비상등이 낮게 깜빡인다. Mira는 장갑을 벗지 않은 채 손끝을 바라본다."
        "rho": return "엔진 진동이 바닥을 울린다. Rho는 렌치를 작업대에 내려놓고 당신을 정면으로 본다."
        "eli": return "항법창 너머 별빛이 천천히 흐른다. Eli는 일부러 화면을 끄고 목소리를 낮춘다."
        "sena": return "보안허브의 감시 화면들이 동시에 당신을 비춘다. Sena는 출입문을 잠근다."
        "vale": return "통신실 스피커에서 백색소음이 흐른다. Vale은 채널 하나를 수동으로 끈다."
        "noa": return "기록보관실의 텍스트 로그가 무수히 스크롤된다. Noa는 한 문장을 멈춰 세운다."
        "lyra": return "수목구역의 습기가 유리벽에 맺힌다. Lyra는 죽은 잎 하나를 조심스럽게 접는다."
        "dax": return "진단 패널의 그래프가 규칙적으로 뛰고 있다. Dax는 수치 하나를 손가락으로 가리킨다."
    return "둘만 남은 짧은 순간, 공개 회의와는 다른 표정이 드러난다."
