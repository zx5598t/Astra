class_name AstraDecisionModel
extends RefCounted

const HUMAN_REASON_TEXT := {
    "public_log_conflict":"공개된 출입 기록과 진술이 맞지 않음",
    "public_statement_conflict":"회의에서 드러난 진술 모순",
    "public_trace":"공개된 현장 흔적이 겹침",
    "public_slip":"공개 발언에서 드러난 실언",
    "victim_suspicion":"신호 두절 승무원이 남긴 의심",
    "meeting_accusation":"회의에서 제기된 구체적 의혹",
    "unexplained_alone":"사건 시각의 단독 행동이 설명되지 않음",
    "relationship_friction":"이전 상호작용과 관계 갈등이 판단에 남음",
    "relationship_support":"이전 상호작용과 현재 관계가 지지 판단에 남음",
    "public_verification":"공개된 기록이 이 사람의 진술을 뒷받침함",
    "statement_response":"바로 앞 사람의 발언과 같은 논점에 반응함",
    "accumulated_behavior":"며칠 동안 쌓인 발언과 행동 정황",
    "insufficient_evidence":"직접 근거가 부족해 기권"
}

static func reason(code: String, weight: float, source: String = "") -> Dictionary:
    return {
        "code":code,
        "weight":weight,
        "source":source,
        "text":str(HUMAN_REASON_TEXT.get(code, HUMAN_REASON_TEXT["accumulated_behavior"]))
    }

static func trace(actor: String, action: String, target: String, reasons: Array, day: int) -> Dictionary:
    var strongest := reason("insufficient_evidence", 0.0)
    for item in reasons:
        if float(item.get("weight",0.0)) > float(strongest.get("weight",0.0)):
            strongest = Dictionary(item).duplicate(true)
    if target == "":
        strongest = reason("insufficient_evidence", 1.0)
    return {
        "actor":actor, "action":action, "target":target, "day":day,
        "reasons":reasons.duplicate(true),
        "strongest_reason":str(strongest.get("code","insufficient_evidence")),
        "explanation":str(strongest.get("text", HUMAN_REASON_TEXT["insufficient_evidence"]))
    }

static func append_trace(flags: Dictionary, entry: Dictionary, limit: int = 120) -> void:
    var traces: Array = Array(flags.get("decision_traces_052", [])).duplicate(true)
    traces.append(entry.duplicate(true))
    while traces.size() > limit:
        traces.pop_front()
    flags["decision_traces_052"] = traces

static func recent(flags: Dictionary, actor: String = "", action: String = "") -> Array:
    var result: Array = []
    for entry in Array(flags.get("decision_traces_052", [])):
        if actor != "" and str(entry.get("actor","")) != actor:
            continue
        if action != "" and str(entry.get("action","")) != action:
            continue
        result.append(Dictionary(entry).duplicate(true))
    return result
