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
    "operational_need":"업무나 안전에 직접 필요한 정보라고 판단함",
    "trusted_colleague":"현재 관계에서 이 사람과 공유할 가치가 있다고 판단함",
    "privacy_boundary":"확인되지 않았거나 개인적인 정보라 공유를 제한함",
    "accumulated_behavior":"며칠 동안 쌓인 발언과 행동 정황",
    "insufficient_evidence":"직접 근거가 부족함",
    "no_legal_vote_target":"합법적으로 선택할 수 있는 투표 대상이 없음",
    # 0.8.0 evidence categories. Every one names something the actor actually
    # knows: their own eyes, a record they hold or saw, something said aloud.
    "HARD_RECORD":"확인한 시스템 기록이 이 사람을 가리킴",
    "TIMELINE":"시간과 위치가 진술과 맞지 않음",
    "DIRECT_WITNESS":"누군가 그 시각 이 사람을 직접 봤다고 함",
    "EXPERT_INFERENCE":"장비 구조상 이 사람의 설명이 성립하지 않음",
    "CONTRADICTION":"말이 기록이나 다른 사람의 말과 어긋남",
    "SOCIAL_BEHAVIOR":"회의에서 보인 행동이 마음에 걸림",
    "RELATIONSHIP":"평소 관계에서 쌓인 불신",
    "HEARSAY":"다른 사람에게 전해 들은 말",
    "RISK":"그 시각 혼자였고 증명해 줄 사람이 없음",
    "CHANGED_STORY":"어제와 오늘 말이 달라짐",
    "EXPLAINED":"어긋난 이유를 스스로 설명함",
    "CORROBORATED":"다른 사람이 함께 있었다고 확인해 줌",
    "FALSE_SIGHTING":"다른 사람을 봤다는 말이 사실과 맞지 않음",
    "MEETING_PUSH":"믿는 사람이 회의에서 강하게 지목함",
    "PLAYER_PUSH":"탐사요원의 지목을 믿음",
    "PLAYER_DEFENSE":"탐사요원이 변호함",
    "CONTESTED":"반박이 나와서 아직 확정되지 않음"
}

# The same reasons as a spoken noun phrase ("…한 점"), for dialogue.
const REASON_NOUN := {
    "HARD_RECORD":"기록에 이름이 남은 점", "TIMELINE":"시간과 위치가 말과 맞지 않는 점",
    "DIRECT_WITNESS":"그 시각에 봤다는 사람이 있는 점", "EXPERT_INFERENCE":"장비 구조상 설명이 성립하지 않는 점",
    "CONTRADICTION":"말이 다른 사람의 말과 어긋나는 점", "CHANGED_STORY":"말을 바꾼 점",
    "SOCIAL_BEHAVIOR":"회의에서 보인 태도", "RELATIONSHIP":"평소 쌓인 불신", "HEARSAY":"전해 들은 말",
    "RISK":"그 시각 혼자였다는 점", "FALSE_SIGHTING":"다른 사람을 봤다는 말이 사실과 달랐던 점",
    "accumulated_behavior":"며칠 동안 쌓인 말과 행동",
    "MEETING_PUSH":"회의에서 나온 지목", "PLAYER_PUSH":"탐사요원이 짚은 부분"
}

# The same reason in a particular person's mouth (§29): Noa talks in times and
# logs, Sena in movement and risk, Jun in what a machine can physically do,
# Mira in what is confirmed and what is not. Missing entries fall back to the
# shared noun.
const REASON_VOICE := {
    "noa": {"HARD_RECORD":"기록에 찍힌 인증 시각", "TIMELINE":"진술한 시각과 기록이 어긋나는 점", "CONTRADICTION":"말한 문장이 다른 사람 문장과 맞지 않는 점", "CHANGED_STORY":"같은 질문에 대답이 바뀐 점", "RISK":"그 시간을 확인해 줄 기록이 없는 점", "FALSE_SIGHTING":"봤다는 문장과 기록이 다른 점", "DIRECT_WITNESS":"그 시각의 목격 진술", "EXPERT_INFERENCE":"설명이 장비 기록과 맞지 않는 점"},
    "sena": {"RISK":"그 시간에 혼자 움직인 점", "SOCIAL_BEHAVIOR":"회의에서 계속 말을 돌린 태도", "DIRECT_WITNESS":"그 시간 그 근처에서 봤다는 사람이 있는 점", "FALSE_SIGHTING":"본 적 없는 걸 봤다고 한 점", "HARD_RECORD":"기록에 이름이 찍힌 점", "CHANGED_STORY":"말을 바꾼 점", "EXPERT_INFERENCE":"변명이 안 통한다는 점"},
    "rho": {"EXPERT_INFERENCE":"기계가 그렇게 움직일 수가 없다는 점", "HARD_RECORD":"장비 로그에 이름이 남은 점", "TIMELINE":"그 시간에 거기 있었다는 말이 앞뒤가 안 맞는 점", "FALSE_SIGHTING":"없는 걸 봤다고 우긴 거", "DIRECT_WITNESS":"그 근처에서 봤다는 사람이 있는 거", "CHANGED_STORY":"말을 바꾼 거"},
    "mira": {"CONTRADICTION":"확인된 것들 사이에서 그 사람 설명만 비는 점", "RISK":"그 시간을 증명할 사람이 없다는 점", "HARD_RECORD":"기록에 이름이 남은 점", "SOCIAL_BEHAVIOR":"대답을 피하는 모습", "FALSE_SIGHTING":"봤다는 말이 사실이 아니었던 점", "DIRECT_WITNESS":"그 시각 그쪽에서 봤다는 증언", "CHANGED_STORY":"말이 한 번 바뀐 점"},
    "dax": {"EXPERT_INFERENCE":"시스템 구조상 그 설명이 성립하지 않는 점", "HARD_RECORD":"인증 로그가 가리키는 방향", "CONTRADICTION":"조건을 다 맞춰 봐도 그 사람 진술만 남는 점", "FALSE_SIGHTING":"목격 진술이 사실과 어긋난 점", "DIRECT_WITNESS":"목격 증언이 가리키는 방향", "TIMELINE":"시각과 위치 조건이 안 맞는 점", "CHANGED_STORY":"입력값이 바뀐 점"},
    "vale": {"HEARSAY":"전해진 말이 중간에 바뀐 점", "CONTRADICTION":"말과 말 사이의 간격이 맞지 않는 점", "DIRECT_WITNESS":"그 시간 그쪽에서 봤다는 증언", "FALSE_SIGHTING":"들린 것과 실제가 달랐던 점", "HARD_RECORD":"기록에 남은 인증", "CHANGED_STORY":"같은 목소리로 다른 말을 한 점"},
    "eli": {"TIMELINE":"그 시각에 그 위치에 있을 수 없다는 점", "CONTRADICTION":"동선이 물리적으로 맞지 않는 점", "RISK":"동선을 증명할 사람이 없는 점", "FALSE_SIGHTING":"봤다는 위치가 틀린 점", "HARD_RECORD":"로그에 남은 이름", "DIRECT_WITNESS":"목격된 위치", "CHANGED_STORY":"위치를 바꿔 말한 점"},
    "lyra": {"SOCIAL_BEHAVIOR":"평소와 다른 태도", "RELATIONSHIP":"요즘 달라진 모습", "CHANGED_STORY":"평소라면 하지 않을 말 바꾸기", "RISK":"아무도 모르게 혼자 있었던 점", "FALSE_SIGHTING":"봤다는 말이 사실이 아니었던 것", "DIRECT_WITNESS":"누가 그쪽에서 봤다는 것"}
}

# When the reason is something the speaker saw or holds themselves, they say
# so in the first person instead of "someone saw" (§28).
const OWN_REASON := {
    "DIRECT_WITNESS": ["제가 직접 본 것", "내가 직접 본 것"],
    "HARD_RECORD": ["제 기록에 남은 이름", "내 기록에 남은 이름"],
    "TIMELINE": ["제가 직접 본 것", "내가 직접 본 것"],
    "FALSE_SIGHTING": ["제가 알고 있는 사실과 다른 목격담", "내가 아는 사실과 다른 목격담"]
}
const BANMAL := ["rho", "dax", "sena", "eli"]

static func own_reason(code: String, speaker: String) -> String:
    var pair: Array = OWN_REASON.get(code, [])
    if pair.is_empty():
        return reason_noun(code, speaker)
    return str(pair[1] if speaker in BANMAL else pair[0])

static func reason_noun(code: String, speaker: String = "") -> String:
    var voice: Dictionary = REASON_VOICE.get(speaker, {})
    if voice.has(code):
        return str(voice[code])
    return str(REASON_NOUN.get(code, "설명하기 어려운 위화감"))

# How each person makes up their mind when evidence alone does not (§31).
# Personality, never a UI stat.
#   conviction : how strong their own evidence must be before the room stops
#                mattering to them
#   bandwagon  : how far a public accusation by someone they trust pulls them
#   regard     : how much the explorer's public stance counts, scaled by the
#                trust they have in the explorer
#   risk_bias  : extra weight on "was alone and nobody can vouch" when unsure
#   flaw       : the characteristic way this person gets it wrong (§11)
const JUDGEMENT := {
    "mira": {"conviction":0.62, "bandwagon":0.32, "regard":0.62, "risk_bias":0.0, "flaw":"delay"},
    "rho":  {"conviction":0.4, "bandwagon":0.78, "regard":0.6, "risk_bias":0.05, "flaw":"rush"},
    "dax":  {"conviction":0.52, "bandwagon":0.26, "regard":0.5, "risk_bias":0.0, "flaw":"logic_only"},
    "noa":  {"conviction":0.46, "bandwagon":0.16, "regard":0.5, "risk_bias":0.0, "flaw":"trusts_records"},
    "sena": {"conviction":0.38, "bandwagon":0.34, "regard":0.45, "risk_bias":0.22, "flaw":"overreact"},
    "vale": {"conviction":0.64, "bandwagon":0.52, "regard":0.62, "risk_bias":0.0, "flaw":"silent"},
    "eli":  {"conviction":0.5, "bandwagon":0.24, "regard":0.48, "risk_bias":0.05, "flaw":"physical_only"},
    "lyra": {"conviction":0.54, "bandwagon":0.46, "regard":0.6, "risk_bias":0.0, "flaw":"trusts_the_familiar"}
}

static func judgement(actor: String, key: String, fallback: float = 0.35) -> float:
    return float(Dictionary(JUDGEMENT.get(actor, {})).get(key, fallback))

# How much each kind of evidence moves each person (§27 of the 0.8.0 brief).
# Weak evidence splits the room by personality; two strong independent pieces
# pull almost everyone the same way because every column's HARD_RECORD and
# DIRECT_WITNESS weight is at least 0.7. RNG is never a column here.
const WEIGHTS := {
    "mira": {"HARD_RECORD":1.0, "TIMELINE":0.9, "DIRECT_WITNESS":0.9, "EXPERT_INFERENCE":0.8, "CONTRADICTION":0.8, "CHANGED_STORY":0.8, "SOCIAL_BEHAVIOR":0.3, "RELATIONSHIP":0.45, "HEARSAY":0.3, "RISK":0.35, "FALSE_SIGHTING":1.0},
    "rho": {"HARD_RECORD":0.8, "TIMELINE":0.7, "DIRECT_WITNESS":1.1, "EXPERT_INFERENCE":1.15, "CONTRADICTION":0.8, "CHANGED_STORY":0.7, "SOCIAL_BEHAVIOR":0.6, "RELATIONSHIP":0.6, "HEARSAY":0.55, "RISK":0.5, "FALSE_SIGHTING":1.0},
    "dax": {"HARD_RECORD":1.15, "TIMELINE":0.85, "DIRECT_WITNESS":0.75, "EXPERT_INFERENCE":1.2, "CONTRADICTION":0.85, "CHANGED_STORY":0.8, "SOCIAL_BEHAVIOR":0.3, "RELATIONSHIP":0.3, "HEARSAY":0.3, "RISK":0.45, "FALSE_SIGHTING":1.1},
    "noa": {"HARD_RECORD":1.2, "TIMELINE":1.25, "DIRECT_WITNESS":0.8, "EXPERT_INFERENCE":0.8, "CONTRADICTION":1.15, "CHANGED_STORY":1.3, "SOCIAL_BEHAVIOR":0.3, "RELATIONSHIP":0.3, "HEARSAY":0.2, "RISK":0.4, "FALSE_SIGHTING":1.2},
    "sena": {"HARD_RECORD":0.95, "TIMELINE":0.8, "DIRECT_WITNESS":1.0, "EXPERT_INFERENCE":0.75, "CONTRADICTION":0.95, "CHANGED_STORY":0.9, "SOCIAL_BEHAVIOR":0.9, "RELATIONSHIP":0.45, "HEARSAY":0.5, "RISK":1.15, "FALSE_SIGHTING":1.0},
    "vale": {"HARD_RECORD":1.05, "TIMELINE":0.85, "DIRECT_WITNESS":1.0, "EXPERT_INFERENCE":0.85, "CONTRADICTION":0.85, "CHANGED_STORY":0.85, "SOCIAL_BEHAVIOR":0.3, "RELATIONSHIP":0.4, "HEARSAY":0.1, "RISK":0.45, "FALSE_SIGHTING":1.15},
    "eli": {"HARD_RECORD":0.95, "TIMELINE":1.3, "DIRECT_WITNESS":0.95, "EXPERT_INFERENCE":0.9, "CONTRADICTION":1.0, "CHANGED_STORY":0.95, "SOCIAL_BEHAVIOR":0.3, "RELATIONSHIP":0.3, "HEARSAY":0.3, "RISK":0.6, "FALSE_SIGHTING":1.0},
    "lyra": {"HARD_RECORD":0.8, "TIMELINE":0.75, "DIRECT_WITNESS":0.9, "EXPERT_INFERENCE":0.8, "CONTRADICTION":0.75, "CHANGED_STORY":0.8, "SOCIAL_BEHAVIOR":1.0, "RELATIONSHIP":0.9, "HEARSAY":0.5, "RISK":0.55, "FALSE_SIGHTING":0.95},
    "player": {"HARD_RECORD":1.0, "TIMELINE":1.0, "DIRECT_WITNESS":1.0, "EXPERT_INFERENCE":1.0, "CONTRADICTION":1.0, "CHANGED_STORY":1.0, "SOCIAL_BEHAVIOR":0.4, "RELATIONSHIP":0.0, "HEARSAY":0.4, "RISK":0.4, "FALSE_SIGHTING":1.0}
}

# Mira is wary of pile-ons: with only soft evidence her conviction is damped.
const HERD_CAUTION := {"mira": 0.55, "vale": 0.8, "dax": 0.85}

static func weight(actor: String, category: String) -> float:
    var table: Dictionary = WEIGHTS.get(actor, WEIGHTS["player"])
    return float(table.get(category, 0.5))

static func reason(code: String, weight_value: float, source: String = "") -> Dictionary:
    return {
        "code":code,
        "weight":weight_value,
        "source":source,
        "text":str(HUMAN_REASON_TEXT.get(code, HUMAN_REASON_TEXT["accumulated_behavior"]))
    }

# Sum weighted contributions into one score. `items` are
# {category, strength, source, text?}. Negative strengths exonerate.
# Returns {score, reasons} where reasons are sorted by absolute contribution and
# carry the signed value, so a trace reads "+0.42 보안 위반 / -0.11 기존 신뢰".
static func evaluate(actor: String, items: Array) -> Dictionary:
    var reasons: Array = []
    var total := 0.0
    var hard := 0.0
    for item in items:
        var category := str(item.get("category", "SOCIAL_BEHAVIOR"))
        var value := weight(actor, category) * float(item.get("strength", 0.0))
        if absf(value) < 0.005:
            continue
        total += value
        if category in ["HARD_RECORD", "DIRECT_WITNESS", "TIMELINE", "EXPERT_INFERENCE", "CHANGED_STORY", "FALSE_SIGHTING"] and value > 0.0:
            hard += value
        var entry := reason(category, value, str(item.get("source", "")))
        if str(item.get("text", "")) != "":
            entry["detail"] = str(item.get("text", ""))
        reasons.append(entry)
    if HERD_CAUTION.has(actor) and total > 0.0 and hard < 0.25:
        var damped := total * float(HERD_CAUTION[actor])
        reasons.append(reason("insufficient_evidence", damped - total))
        total = damped
    reasons.sort_custom(func(a, b): return absf(float(a["weight"])) > absf(float(b["weight"])))
    return {"score": total, "reasons": reasons}

static func trace(actor: String, action: String, target: String, reasons: Array, day: int) -> Dictionary:
    var strongest := reason("insufficient_evidence", 0.0)
    for item in reasons:
        if float(item.get("weight",0.0)) > float(strongest.get("weight",0.0)):
            strongest = Dictionary(item).duplicate(true)
    if target == "" and reasons.is_empty():
        strongest = reason("insufficient_evidence", 1.0)
    return {
        "actor":actor, "action":action, "target":target, "day":day,
        "reasons":reasons.duplicate(true),
        "strongest_reason":str(strongest.get("code","insufficient_evidence")),
        "explanation":str(strongest.get("text", HUMAN_REASON_TEXT["insufficient_evidence"]))
    }

# "+0.42 보안 위반 · +0.31 노아 공개 기록 · -0.11 기존 신뢰" for debug/test output.
static func trace_line(entry: Dictionary) -> String:
    var parts: Array = []
    for item in entry.get("reasons", []):
        parts.append("%+.2f %s" % [float(item.get("weight", 0.0)), str(item.get("text", ""))])
    return "%s → %s · %s" % [str(entry.get("actor", "")), str(entry.get("target", "")), " · ".join(PackedStringArray(parts))]

static func append_trace(flags: Dictionary, entry: Dictionary, limit: int = 160) -> void:
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
