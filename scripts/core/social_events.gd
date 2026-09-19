class_name AstraSocialEvents
extends RefCounted

# Small things that happen between people, so a meeting is a room rather than a
# queue of statements.
#
# Every beat here has a TRIGGER that is a fact about the run — who vouched for
# whom, who the player keeps defending, who lost someone last night. None of
# them fire "at random on day 2". If a beat cannot name its reason it does not
# exist, because a beat the player cannot explain afterwards reads as the engine
# shuffling cards rather than as people reacting (§73).
#
# COOLDOWN keeps one trigger from producing the same beat three days running,
# and WEIGHT decides which beat wins when several are eligible, so the same
# situation in two different runs does not always resolve the same way (§93).

const BEATS = [
    {
        "id": "vouch_pair",
        "weight": 3.0,
        "cooldown": 2,
        "needs": "mutual_claim",
        "summary": "%s와 %s가 서로의 알리바이를 보증했다.",
        "line": "{a}와 저는 그 시간 내내 같이 있었어요. 제가 보증합니다."
    },
    {
        "id": "vouch_withdrawn",
        "weight": 4.0,
        "cooldown": 3,
        "needs": "mutual_claim_pressured",
        "summary": "%s가 %s에 대한 보증을 거둬들였다.",
        "line": "…아까 한 말, 정정할게요. 계속 붙어 있었던 건 아니에요. 중간에 자리를 비운 시간이 있어요."
    },
    {
        "id": "pile_on",
        "weight": 2.5,
        "cooldown": 1,
        "needs": "crowd_focus",
        "summary": "두 사람이 동시에 %s를 몰아세웠다.",
        "line": "저도 같은 생각이에요. {target}, 지금 설명해 주세요."
    },
    {
        "id": "stop_pile_on",
        "weight": 3.0,
        "cooldown": 2,
        "needs": "crowd_focus",
        "summary": "%s가 과한 몰아가기를 막았다.",
        "line": "잠깐만요. 지금 근거 하나로 한 사람한테 전부 몰리고 있어요."
    },
    {
        "id": "guard_repaid",
        "weight": 3.5,
        "cooldown": 99,
        "needs": "protected_last_night",
        "summary": "%s가 어젯밤 지켜 준 일을 기억하고 탐사요원을 지지했다.",
        "line": "어젯밤 제 선실 앞을 지켜 준 게 탐사요원이에요. 저는 그쪽 판단을 듣겠어요."
    },
    {
        "id": "grief_turn",
        "weight": 3.0,
        "cooldown": 99,
        "needs": "lost_close_person",
        "summary": "%s는 가까운 사람을 잃은 뒤 태도가 굳어졌다.",
        "line": "어제까지는 저도 신중하자고 했죠. 오늘은 아니에요."
    },
    {
        "id": "silent_witness",
        "weight": 2.0,
        "cooldown": 2,
        "needs": "high_stress",
        "summary": "%s는 이번 회의에서 끝까지 거의 말하지 않았다.",
        "line": ""
    },
    {
        "id": "soft_pedal_partner",
        "weight": 3.0,
        "cooldown": 2,
        "needs": "null_pair_alive",
        "summary": "%s가 %s를 의심하는 척하면서 실제로는 약하게만 짚었다.",
        "line": "{target}도 설명이 필요하긴 해요. 뭐, 그렇게 급한 건 아니지만."
    },
    {
        "id": "player_pattern",
        "weight": 4.0,
        "cooldown": 2,
        "needs": "player_pattern",
        "summary": "%s가 탐사요원의 행동 패턴을 지적했다.",
        "line": ""
    }
]

static func spec(beat_id: String) -> Dictionary:
    for beat in BEATS:
        if str(beat.get("id", "")) == beat_id:
            return beat
    return {}

static func on_cooldown(history: Array, beat_id: String, day: int) -> bool:
    var cooldown := int(spec(beat_id).get("cooldown", 1))
    for entry in history:
        if str(entry.get("id", "")) != beat_id:
            continue
        if day - int(entry.get("day", 0)) < cooldown:
            return true
    return false

# Weighted choice among the beats whose trigger fired, so an identical situation
# does not always produce an identical scene.
static func choose(eligible: Array, roll: float) -> Dictionary:
    if eligible.is_empty():
        return {}
    var total := 0.0
    for item in eligible:
        total += float(spec(str(item.get("id", ""))).get("weight", 1.0))
    var target := clampf(roll, 0.0, 0.999) * total
    for item in eligible:
        target -= float(spec(str(item.get("id", ""))).get("weight", 1.0))
        if target <= 0.0:
            return item
    return eligible[eligible.size() - 1]
