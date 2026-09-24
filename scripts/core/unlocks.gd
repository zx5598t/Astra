class_name AstraUnlocks
extends RefCounted

# Which parts of the game exist yet, from the player's point of view.
#
# 0.3.1 handed over every screen on the first run: protocols, the hypothesis
# board, night tactics, the theory report and six cases, before the player had
# searched a single room. Nothing was hidden, so nothing was learned in order.
#
# A locked feature here is *not shown at all* — no greyed-out row, no "LOCKED"
# label. A menu full of padlocks is still a menu full of things you do not
# understand (§7). The feature appears the moment it unlocks, together with one
# line saying what it is and one line of what it means in the fiction (§35).
#
# Unlocks are derived from the archive, never stored as a separate truth, so a
# 0.3.1 save that already finished three cases arrives with everything open.

const ALWAYS := ["move", "investigate", "interrogate", "notebook_basic"]
# 0.8.0: the core rules of a Day are never locked. Conversation, meeting, vote
# and night exist from Stage 1, Day 1; only Part II protocols wait for their
# Stage (AstraGameSession.protocols_for_stage).
const CORE_080 := ["interrogate", "notebook_basic", "meeting", "vote", "night"]

# What a given save slot has in front of it. Never reads another slot.
static func for_slot_stage(highest_stage_cleared: int) -> Array:
    var result: Array = CORE_080.duplicate()
    if highest_stage_cleared >= 1:
        result.append("difficulty_select")
    if highest_stage_cleared >= 4:
        result.append("case_select")
    for id in ["GUARDIAN", "ANALYST", "EMPATH"]:
        if highest_stage_cleared + 1 >= int(AstraGameSession.PROTOCOLS[id]["stage"]):
            result.append("protocol_" + id.to_lower())
    return result

# `needs_calibration` — the tutorial case must be finished.
# `needs_cases` — this many campaign cases must have been played to the end.
const FEATURES := {
    "move": {"order": 0, "title": "이동", "blurb": "장소를 옮깁니다. 시간을 쓰지 않습니다."},
    "investigate": {"order": 0, "title": "조사", "blurb": "현장에서 기록이나 흔적을 찾습니다."},
    "interrogate": {"order": 0, "title": "심문", "blurb": "승무원에게 특정 상황을 질문합니다."},
    "notebook_basic": {"order": 0, "title": "조사 노트", "blurb": "찾은 단서와 들은 말이 자동으로 정리됩니다."},

    # CALIBRATION never reaches a meeting or a vote (it resolves entirely in
    # EXPLORE), so neither belongs in ALWAYS; both become relevant starting
    # DEAD_AIR, the first chapter that actually uses them.
    "meeting": {
        "order": 2, "needs_cases": 1,
        "title": "회의", "blurb": "모두 앞에서 주장과 증거를 공개합니다.",
        "flavor": "처음으로, 혼자가 아니라 모두 앞에서 말합니다."
    },
    "vote": {
        "order": 3, "needs_cases": 2,
        "title": "투표", "blurb": "한 명을 격리합니다.",
        "flavor": "표는 모두 동등합니다. 당신의 표도 하나입니다."
    },

    "marks": {
        "order": 1, "needs_calibration": true,
        "title": "내 판단 표시",
        "blurb": "이름 옆에 의심·신뢰·보류를 직접 표시합니다.",
        "flavor": "조사 기록에 당신의 판단이 남기 시작합니다."
    },
    "night": {
        "order": 3, "needs_cases": 2,
        "title": "밤",
        "blurb": "투표 뒤 밤이 옵니다. 한 사람을 지키거나 한 곳을 감시할 수 있습니다.",
        "flavor": "조사가 다음 날로 이어집니다. 이제 지키지 못한 것이 생깁니다."
    },
    "claim_search": {
        "order": 2, "needs_cases": 1,
        "title": "발언 검색",
        "blurb": "“누가 이 말을 했지?”를 노트에서 찾습니다.",
        "flavor": "모든 문장이 남습니다. 당신 것도 포함해서."
    },
    "difficulty_select": {
        "order": 2, "needs_cases": 1,
        "title": "속도 선택",
        "blurb": "스토리·표준·전문가 중에서 고릅니다.",
        "flavor": ""
    },

    "case_select": {
        "order": 2, "needs_cases": 1,
        "title": "사건 선택",
        "blurb": "복원한 사건을 다시 열 수 있습니다. 배치는 매번 새로 결정됩니다.",
        "flavor": "같은 기록도 다시 읽으면 다르게 읽힙니다."
    },
    "private_talk": {
        "order": 4, "needs_cases": 3,
        "title": "개인 면담",
        "blurb": "승무원이 따로 이야기를 청합니다. 답에 따라 관계가 달라집니다.",
        "flavor": "사람들이 당신에게 말을 걸기 시작했습니다."
    },
    "theory_report": {
        "order": 4, "needs_cases": 3,
        "title": "추리 보고서",
        "blurb": "실행자로 의심하는 사람을 표시해 두면 투표와 함께 제출되고 채점됩니다.",
        "flavor": ""
    },
    "night_tactics": {
        "order": 4, "needs_cases": 3,
        "title": "야간 행동",
        "blurb": "보호 외에 감시·기록 백업·휴식을 고를 수 있습니다.",
        "flavor": "밤에 할 수 있는 일이 늘었습니다. 여전히 하나뿐이지만."
    },
    "hypothesis": {
        "order": 5, "needs_cases": 4,
        "title": "가설 연결",
        "blurb": "노트에서 단서·인물·조작을 직접 연결하고 회의에서 제시합니다.",
        "flavor": "조각을 잇고 판단을 남기는 일은 이제 당신의 몫입니다."
    },
    "protocols": {
        "order": 5, "needs_cases": 4,
        "title": "조사 방식",
        "blurb": "분석관·공감관·감사관 중에서 시작 방식을 고릅니다.",
        "flavor": "접속 방식을 직접 고를 수 있을 만큼 연결이 안정됐습니다."
    },
    "relationship_events": {
        "order": 6, "needs_cases": 5,
        "title": "관계 사건",
        "blurb": "승무원들 사이의 일이 당신 없이도 벌어집니다.",
        "flavor": "이들은 당신이 보지 않을 때도 서로를 기억합니다."
    }
}

# Order matters for the "what is next" hint on the title screen.
const REVEAL_ORDER := [
    "marks",
    "meeting", "claim_search", "difficulty_select", "case_select",
    "vote", "night",
    "private_talk", "theory_report", "night_tactics",
    "hypothesis", "protocols", "relationship_events"
]

static func unlocked(calibration_done: bool, campaign_cases_played: int) -> Array:
    var result: Array = ALWAYS.duplicate()
    for key in REVEAL_ORDER:
        var spec: Dictionary = FEATURES.get(key, {})
        if bool(spec.get("needs_calibration", false)) and not calibration_done:
            continue
        if campaign_cases_played < int(spec.get("needs_cases", 0)):
            continue
        result.append(key)
    return result

static func has(unlocked_list: Array, feature: String) -> bool:
    return feature in unlocked_list

# What opened between two states, in reveal order, so the popups queue sensibly.
static func newly_unlocked(before: Array, after: Array) -> Array:
    var fresh: Array = []
    for key in REVEAL_ORDER:
        if key in after and not (key in before):
            fresh.append(key)
    return fresh

static func title_of(feature: String) -> String:
    return str(FEATURES.get(feature, {}).get("title", feature))

static func blurb_of(feature: String) -> String:
    return str(FEATURES.get(feature, {}).get("blurb", ""))

static func flavor_of(feature: String) -> String:
    return str(FEATURES.get(feature, {}).get("flavor", ""))

# The next thing that will open, phrased as a reason to keep going rather than
# as a list of things the player cannot have.
static func next_hint(calibration_done: bool, campaign_cases_played: int) -> String:
    if not calibration_done:
        return "첫 각성이 끝나면 다음 기록을 확인할 수 있습니다."
    var open := unlocked(calibration_done, campaign_cases_played)
    for key in REVEAL_ORDER:
        if key in open:
            continue
        var spec: Dictionary = FEATURES.get(key, {})
        var needed := int(spec.get("needs_cases", 0)) - campaign_cases_played
        if needed > 0:
            return "기록 %d건을 더 확인하면 · %s" % [needed, str(spec.get("title", ""))]
    return ""
