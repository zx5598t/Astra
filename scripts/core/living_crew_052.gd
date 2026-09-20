class_name AstraLivingCrew
extends RefCounted

# ASTRA 0.5.3: stable personality comes first; loop variation is layered on top.
# Hidden roles never replace these profiles. A deviation is only valid when it
# carries a reason that can later be echoed by another authored beat.

const AXES := ["trust", "comfort", "respect", "tension", "protectiveness"]
const REASON_TAGS := [
    "NULL_PRESSURE", "FEAR", "PAIR_HISTORY", "GRIEF_ECHO", "PROTECTION_ECHO",
    "HIDDEN_SECRET", "RECENT_CONFLICT", "MEMORY_MISMATCH", "INJURY", "PLAYER_ACTION"
]
const PLAYER_AXES := [
    "evidence_first", "people_first", "protective", "skeptical",
    "secretive", "confrontational", "patient"
]

const PROFILES := {
    "mira": {
        "baseline": ["아픈 사람을 먼저 본다", "질문보다 상태를 먼저 확인한다", "의료 판단에서는 단호하다", "자기 상태는 뒤늦게 확인한다"],
        "stress_response": "말이 짧아지고 환자 상태부터 다시 확인한다.",
        "lie_style": "핵심을 부정하기보다 불편한 부분을 잠깐 생략한다.",
        "content_weights": {"everyday":1.0,"work":1.25,"observation":1.1,"personal":1.2,"danger":1.2,"pair":1.15,"player":1.55,"reaction":1.45,"echo":1.35,"medical":1.5},
        "share_tendency": {"medical":0.3,"life_risk":1.0,"verified":0.65}
    },
    "rho": {
        "baseline": ["문제는 손으로 먼저 확인한다", "고장을 보면 바로 만져 본다", "평소에는 장난을 친다", "위험해지면 농담을 멈춘다"],
        "stress_response": "농담이 사라지고 문장이 짧아진다.",
        "lie_style": "농담이나 옆 이야기로 핵심 질문을 비껴 간다.",
        "content_weights": {"everyday":1.35,"work":1.55,"observation":1.15,"personal":0.85,"danger":1.5,"pair":1.3},
        "share_tendency": {"work":0.9,"unverified":0.45}
    },
    "dax": {
        "baseline": ["바로 결론내리지 않는다", "계산과 기록을 대조한다", "말이 짧다", "틀렸다면 인정한다"],
        "stress_response": "같은 계산을 다시 하고 다른 사람의 관측을 요구한다.",
        "lie_style": "틀리지 않은 사실만 말하고 결론을 말하지 않는다.",
        "content_weights": {"everyday":0.8,"work":1.55,"observation":1.45,"personal":0.8,"record":1.45,"pair":1.15},
        "share_tendency": {"system":0.78,"unverified":0.35}
    },
    "noa": {
        "baseline": ["모순을 바로 공격하지 않고 기억한다", "나중에 정확한 문장을 다시 꺼낸다", "문장을 정확히 기억한다", "감정이 강해질수록 말이 차가워진다"],
        "stress_response": "더 정확하고 차가운 문장만 고른다.",
        "lie_style": "질문의 범위를 좁혀 정확한 문장만 답한다.",
        "content_weights": {"everyday":0.7,"work":1.25,"observation":1.55,"personal":1.0,"record":1.65,"delayed_reaction":1.5},
        "share_tendency": {"verified":0.82,"unverified":0.18}
    },
    "sena": {
        "baseline": ["위험부터 본다", "말보다 먼저 움직인다", "평소 자신감이 있다", "팀원을 지키려 한다"],
        "stress_response": "설명보다 행동과 안전 확보를 먼저 한다.",
        "lie_style": "짧고 정면으로 부정한 뒤 행동으로 화제를 바꾼다.",
        "content_weights": {"everyday":0.9,"work":1.2,"observation":1.1,"personal":1.0,"danger":1.6,"pair":1.35},
        "share_tendency": {"security":0.25,"life_risk":1.0}
    },
    "vale": {
        "baseline": ["사람보다 신호에 먼저 반응한다", "평소 조용하다", "통신 이야기가 나오면 길게 말한다", "반복되는 소리를 오래 듣는다"],
        "stress_response": "평소보다 더 조용해지지만 신호에 대해서는 길게 설명한다.",
        "lie_style": "대답하기 전에 오래 멈추고 확인되지 않은 부분을 남긴다.",
        "content_weights": {"everyday":0.75,"work":1.35,"observation":1.6,"personal":1.0,"signal":1.8,"pair":1.05},
        "share_tendency": {"signal":0.45,"verified":0.65}
    },
    "eli": {
        "baseline": ["한 지점보다 전체 경로를 본다", "먼저 보고 나중에 말한다", "걱정해도 말보다 행동한다", "출구와 이동 방향을 기억한다"],
        "stress_response": "말이 더 줄고 관찰과 이동 확인이 늘어난다.",
        "lie_style": "필요한 부분만 답하고 나머지는 관측이 끝날 때까지 미룬다.",
        "content_weights": {"everyday":0.8,"work":1.3,"observation":1.55,"personal":0.85,"route":1.6,"pair":1.0},
        "share_tendency": {"route":0.62,"unverified":0.3}
    },
    "lyra": {
        "baseline": ["평소 가장 밝다", "주변 사람과 쉽게 대화한다", "작은 생명도 챙긴다", "생존과 생태 판단에서는 냉정해질 수 있다"],
        "stress_response": "밝은 말투가 사라지고 살릴 것과 포기할 것을 직접 고른다.",
        "lie_style": "다른 사람을 보호하려고 핵심을 돌려 말한다.",
        "content_weights": {"everyday":1.45,"work":1.3,"observation":1.2,"personal":1.35,"crisis":1.3,"pair":1.2},
        "share_tendency": {"survival":0.92,"life_risk":1.0}
    }
}

const SOCIAL_THEMES := [
    "OLD_FRIENDS", "BROKEN_TRUST", "PROTECTIVE", "PROFESSIONAL_CONFLICT",
    "SHARED_FAILURE", "UNKNOWN_PAST", "QUIET_ALLIANCE"
]

const THEME_PAIRS := {
    "OLD_FRIENDS": ["rho","sena"],
    "BROKEN_TRUST": ["dax","noa"],
    "PROTECTIVE": ["sena","mira"],
    "PROFESSIONAL_CONFLICT": ["rho","dax"],
    "SHARED_FAILURE": ["dax","lyra"],
    "UNKNOWN_PAST": ["noa","vale"],
    "QUIET_ALLIANCE": ["vale","eli"]
}

static func profile(npc_id: String) -> Dictionary:
    return PROFILES.get(npc_id, {}).duplicate(true)

static func baseline(npc_id: String) -> Array:
    return Array(PROFILES.get(npc_id, {}).get("baseline", [])).duplicate()

static func content_weight(npc_id: String, tag: String) -> float:
    var weights: Dictionary = PROFILES.get(npc_id, {}).get("content_weights", {})
    return float(weights.get(tag, 1.0))

static func blank_relationship() -> Dictionary:
    return {"trust":0.5, "comfort":0.5, "respect":0.5, "tension":0.15, "protectiveness":0.2, "tags":[]}

static func relationship_from(history: Dictionary, affinity_a: float, affinity_b: float) -> Dictionary:
    var relation := blank_relationship()
    var avg_affinity := (affinity_a + affinity_b) * 0.5
    relation["trust"] = clampf(0.5 + float(history.get("trust_delta", 0.0)) * 2.0 + avg_affinity * 0.18, 0.0, 1.0)
    relation["comfort"] = clampf(0.48 + avg_affinity * 0.55, 0.0, 1.0)
    relation["respect"] = clampf(0.55 + float(history.get("trust_delta", 0.0)) + absf(avg_affinity) * 0.1, 0.0, 1.0)
    var tone := str(history.get("tone", "neutral"))
    var tags: Array = []
    match tone:
        "warm":
            relation["comfort"] = clampf(float(relation["comfort"]) + 0.18, 0.0, 1.0)
            relation["protectiveness"] = 0.42
            tags.append("COMFORTABLE")
        "tense":
            relation["tension"] = 0.58
            relation["comfort"] = clampf(float(relation["comfort"]) - 0.18, 0.0, 1.0)
            tags.append("RESENTS_DECISION")
        "complicated":
            relation["respect"] = 0.68
            relation["tension"] = 0.38
            tags.append("RESPECTS_SKILL")
        "uncanny":
            relation["trust"] = clampf(float(relation["trust"]) - 0.08, 0.0, 1.0)
            relation["tension"] = 0.34
            tags.append("DISTANT")
    var history_type := str(history.get("type", ""))
    if history_type == "saved_each_other":
        relation["protectiveness"] = 0.78
        tags.append("PROTECTIVE")
    elif history_type == "shared_secret":
        tags.append("SHARED_SECRET")
    elif history_type == "professional_conflict":
        relation["respect"] = maxf(float(relation["respect"]), 0.7)
        tags.append("RESPECTS_SKILL")
    elif history_type == "past_failure":
        relation["tension"] = maxf(float(relation["tension"]), 0.62)
    relation["tags"] = tags
    return relation

static func apply_choice(relation: Dictionary, effect: String) -> Dictionary:
    var result := relation.duplicate(true)
    match effect:
        "share", "open_records":
            result["trust"] = clampf(float(result.get("trust",0.5)) + 0.06,0.0,1.0)
        "help", "defend":
            result["protectiveness"] = clampf(float(result.get("protectiveness",0.2)) + 0.07,0.0,1.0)
            result["trust"] = clampf(float(result.get("trust",0.5)) + 0.03,0.0,1.0)
        "comfort", "comfort_light", "wait":
            result["comfort"] = clampf(float(result.get("comfort",0.5)) + 0.06,0.0,1.0)
        "confront", "pressure":
            result["tension"] = clampf(float(result.get("tension",0.15)) + 0.07,0.0,1.0)
            result["respect"] = clampf(float(result.get("respect",0.5)) + 0.02,0.0,1.0)
        "hide", "withhold":
            result["trust"] = clampf(float(result.get("trust",0.5)) - 0.05,0.0,1.0)
            result["tension"] = clampf(float(result.get("tension",0.15)) + 0.04,0.0,1.0)
        "promise":
            result["trust"] = clampf(float(result.get("trust",0.5)) + 0.02,0.0,1.0)
    return result

static func relationship_status(relation: Dictionary) -> String:
    var trust := float(relation.get("trust",0.5))
    var comfort := float(relation.get("comfort",0.5))
    var respect := float(relation.get("respect",0.5))
    var tension := float(relation.get("tension",0.15))
    var protective := float(relation.get("protectiveness",0.2))
    if protective >= 0.68:
        return "위험할 때 서로를 먼저 챙기는 편이다."
    if tension >= 0.55 and respect >= 0.6:
        return "서로 편하진 않지만 업무 판단은 신뢰한다."
    if tension >= 0.55:
        return "말을 고를 때 아직 긴장이 남아 있다."
    if trust >= 0.68 and comfort < 0.48:
        return "편한 사이는 아니지만 판단은 믿는 편이다."
    if comfort >= 0.68:
        return "같은 자리에 있어도 굳이 말을 채우지 않아도 편해 보인다."
    if trust <= 0.35:
        return "아직 서로에게 중요한 정보를 바로 맡기지는 않는다."
    return "서로를 살피며 거리를 재는 중이다."

static func blank_player_profile() -> Dictionary:
    var result := {}
    for axis in PLAYER_AXES:
        result[axis] = 0
    return result

static func register_player_action(profile_state: Dictionary, action: String) -> Dictionary:
    var result := profile_state.duplicate(true)
    for axis in PLAYER_AXES:
        if not result.has(axis):
            result[axis] = 0
    var axis := ""
    match action:
        "record", "keep_copy", "open_records", "read": axis = "evidence_first"
        "comfort", "comfort_light", "help", "wait": axis = "people_first"
        "defend", "protect": axis = "protective"
        "confront", "pressure", "top_suspect": axis = "confrontational"
        "hide", "withhold": axis = "secretive"
        "observe", "witness": axis = "skeptical"
        "promise", "reassure": axis = "patient"
    if axis != "":
        result[axis] = int(result.get(axis,0)) + 1
    return result

static func dominant_player_axis(profile_state: Dictionary) -> String:
    var best := ""
    var score := 0
    for axis in PLAYER_AXES:
        var value := int(profile_state.get(axis,0))
        if value > score:
            score = value
            best = axis
    return best if score >= 2 else ""

static func remember(memory_state: Dictionary, npc_id: String, event: Dictionary, limit: int = 6) -> Dictionary:
    var result := memory_state.duplicate(true)
    var items: Array = Array(result.get(npc_id, [])).duplicate(true)
    items.append(event.duplicate(true))
    while items.size() > limit:
        items.pop_front()
    result[npc_id] = items
    return result

static func deviation(character: String, behavior: String, reason: String, source_event: String, possible_followup: String, loop_index: int) -> Dictionary:
    var reason_tag := reason if reason in REASON_TAGS else "PLAYER_ACTION"
    return {
        "character":character, "behavior":behavior, "reason":reason_tag,
        "source_event":source_event, "possible_followup":possible_followup, "loop":loop_index
    }

static func theme_for(seed_value: int, loop_index: int, roster: Array) -> String:
    var eligible: Array = []
    for theme in SOCIAL_THEMES:
        var pair: Array = THEME_PAIRS[theme]
        if pair[0] in roster and pair[1] in roster:
            eligible.append(theme)
    if eligible.is_empty():
        return "QUIET_ALLIANCE"
    var index: int = abs(hash("astra-theme:%d:%d" % [seed_value,loop_index])) % eligible.size()
    return str(eligible[index])

static func theme_pair(theme: String) -> Array:
    return Array(THEME_PAIRS.get(theme, [])).duplicate()

static func loop_hook(theme: String, roster: Array, loop_index: int) -> Dictionary:
    var pair := theme_pair(theme)
    if pair.size() < 2 or pair[0] not in roster or pair[1] not in roster:
        return {}
    var hooks := {
        "OLD_FRIENDS": {"speaker":"rho","target":"sena","action":"준이 세나의 보안 점검표를 보지도 않고 다음 칸을 먼저 짚는다.","line":"여기 다음에 네가 보는 데 있잖아. 아직도 순서 안 바꿨네."},
        "BROKEN_TRUST": {"speaker":"noa","target":"dax","action":"노아가 다렌의 계산표를 받지만 평소처럼 바로 기록철에 끼우지 않는다.","line":"확인하고 넣을게요. 이번에는 순서가 중요해서요."},
        "PROTECTIVE": {"speaker":"sena","target":"mira","action":"세나가 의료실 문이 닫히기 전에 발을 넣고 안쪽을 한 번 더 확인한다.","line":"괜찮다는 말은 들었어. 그래도 내가 볼 건 볼게."},
        "PROFESSIONAL_CONFLICT": {"speaker":"rho","target":"dax","action":"준이 다렌의 정상 판정 옆에 손으로 들은 진동 시간을 적는다.","line":"평균 말고 이 순간도 남겨. 숫자 밖에서 난 소리야."},
        "SHARED_FAILURE": {"speaker":"dax","target":"lyra","action":"다렌이 마렌의 표본 기록을 넘기기 전에 빈 칸 하나를 그대로 둔다.","line":"모르는 걸 채우지 말자. 지난번엔 그게 문제였어."},
        "UNKNOWN_PAST": {"speaker":"noa","target":"vale","action":"노아가 소렌의 이름이 적힌 오래된 통신 목록에서 날짜 부분만 가린다.","line":"먼저 읽어 봐요. 날짜를 보면 기억이 그쪽으로 끌릴 수 있으니까."},
        "QUIET_ALLIANCE": {"speaker":"vale","target":"eli","action":"소렌이 말없이 이어폰 한쪽을 루칸에게 건네고, 루칸은 별지도 한 구석을 가리킨다.","line":"…같은 지점이죠?"}
    }
    var hook: Dictionary = hooks.get(theme, {})
    if hook.is_empty():
        return {}
    return {
        "id":"052_loop_hook_%s_%d" % [theme.to_lower(),loop_index],
        "speaker":str(hook["speaker"]), "target":str(hook["target"]), "tag":"loop_hook",
        "category":"PAIR", "family":"loop_hook_" + theme.to_lower(), "intent":"relationship",
        "action":str(hook["action"]), "lines":[[str(hook["speaker"]),str(hook["line"])]],
        "choices":[], "theme":theme
    }

static func player_remark(npc_id: String, axis: String) -> String:
    var lines := {
        "noa:evidence_first":"또 기록부터 보네요.",
        "rho:evidence_first":"이번에도 파일부터 까볼 생각이지?",
        "mira:evidence_first":"이번에도 기록부터네요. 저는 사람 쪽을 볼게요.",
        "mira:people_first":"사람 먼저 확인할 줄 알았어요.",
        "mira:protective":"본인도 보호 대상이라는 건 잊지 말아요.",
        "mira:skeptical":"한 번 더 확인하는 건 좋아요. 본인 상태도 그렇게 해요.",
        "mira:secretive":"말하고 싶지 않은 건 알아요. 그런데 상태는 숨기지 마세요.",
        "mira:confrontational":"정면으로 물을 거면, 대답 들을 준비도 해요.",
        "mira:patient":"기다려 주는 쪽을 고르는군요. 그게 필요한 사람도 있어요.",
        "sena:protective":"누굴 빼낼지부터 보는구나.",
        "noa:skeptical":"한 번 들은 말은 바로 믿지 않네요.",
        "rho:confrontational":"또 정면으로 묻네. 너답다.",
        "noa:secretive":"이번에도 먼저 공개하지는 않네요."
    }
    return str(lines.get(npc_id + ":" + axis, ""))


static func relationship_tone_with_player(bond: float, echo: Dictionary) -> String:
    if bond <= -0.15 or float(echo.get("conflict",0.0)) >= 0.30:
        return "STRAINED"
    if bond >= 0.25 or float(echo.get("trust",0.0)) >= 0.32 or float(echo.get("familiarity",0.0)) >= 0.55:
        return "WARM"
    return "PROFESSIONAL"

static func sharing_tendency(npc_id: String, topic: String) -> float:
    var tendency: Dictionary = PROFILES.get(npc_id,{}).get("share_tendency",{})
    return float(tendency.get(topic,tendency.get("unverified",0.4)))
