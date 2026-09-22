class_name AstraStorylets070
extends RefCounted

# 0.7.0 SECOND WATCH authored library. Unlike storylets_052-055 (gated to
# ECHO_WARD onward via MID_CHAPTERS), these scenes carry an explicit
# "chapters" override naming exactly which day they belong to — Day 1-3
# had zero optional/pair/observation content before this pass, which is the
# core pacing problem the 0.7.0 story-design brief identifies. Act II
# (Day 8-13) content is added to this same file as later phases land.

const ACT1_SCENES := [
    # DEAD_AIR (Day 2): dramatizes the investigate -> cross-check -> verify
    # chain in play instead of jumping straight to RESOLUTION_BEATS' payoff.
    # "dax_noa" in the id reuses _pair_scene_context_ok's existing dax/noa
    # gate (game_session.gd), so it only surfaces once a record has actually
    # been found.
    {"id":"070_pair_dax_noa_crosscheck","speaker":"noa","target":"dax","tag":"pair","category":"PAIR","family":"dax_noa_crosscheck","intent":"work",
        "action":"노아가 두 문서의 승인란을 나란히 확대하고, 다렌이 그 옆에 체크섬 검증 창을 띄운다.",
        "lines":[["noa","승인 번호가 둘 다 정식 형식이에요. 위조라면 형식부터 어긋나야 하는데, 아니에요."],
            ["dax","체크섬도 각자 자기 안에서는 맞아. 어느 한쪽만 손댄 흔적이 없어."],
            ["noa","그럼 하나가 가짜라는 가정부터 접을게요."]],
        "choices":[],"chapters":["DEAD_AIR"]},
    # A short seed for Mira's self-neglect arc (§22): tag "everyday" so it is
    # visible on the first pass through the day, unlike "personal"-tagged
    # content which is gated to loop >= 1 by design elsewhere in this file.
    {"id":"070_mira_dead_air_self_last","speaker":"mira","tag":"everyday","category":"PERSONAL","family":"mira_self_neglect","intent":"personal",
        "action":"미라가 세나의 각성 점검표를 다 채운 뒤에야 자기 몫 칸이 비어 있는 걸 본다.",
        "lines":[["mira","이건 나중에요. 지금은 세나 상태부터 끝까지 봐야 하니까."]],
        "choices":[],"chapters":["DEAD_AIR"]},
    # GLASS_GARDEN (Day 3): the parallel A/B investigation. Both are plain
    # "observation" scenes (no loop gate) so whichever the player reaches
    # first is a genuine secondary-observation choice; the core fact stays
    # reachable through the existing "security" investigation point either
    # way. Both quietly foreshadow the day's ending (the door opens itself
    # from the inside before Sena unlocks it).
    {"id":"070_rho_glass_garden_power","speaker":"rho","tag":"observation","category":"WORK","family":"rho_glass_garden_power","intent":"work",
        "action":"준이 보안 구역 전력반을 열고 차단기 위치를 하나씩 짚어 본다.",
        "lines":[["rho","손으로 내린 자국이야. 자동 차단이었으면 이 레버가 이 각도로 안 남아."]],
        "choices":[],"chapters":["GLASS_GARDEN"]},
    {"id":"070_sena_glass_garden_lock","speaker":"sena","tag":"observation","category":"WORK","family":"sena_glass_garden_lock","intent":"work",
        "action":"세나가 잠긴 구역 문 앞에서 출입 기록보다 손잡이의 긁힌 방향을 먼저 본다.",
        "lines":[["sena","밖에서 긁은 자국이 아니야. 안에서 나가려던 자국이야."]],
        "choices":[],"chapters":["GLASS_GARDEN"]}
]

# BLIND_DECK (Day 10): six companion-specific secondary observations, one per
# specialty the design brief names for this location (§18). The core fact
# stays reachable through the case's own investigation points regardless of
# which companion the player happens to talk to — these only change what
# extra texture they get.
const ACT2_SCENES := [
    {"id":"070_mira_blind_deck_trace","speaker":"mira","tag":"observation","category":"WORK","family":"mira_blind_deck_trace","intent":"work",
        "action":"미라가 정비 구역 구석의 작은 상자에서 오래된 진통제 포장을 발견한다.",
        "lines":[["mira","누군가 여기서 다쳤거나, 다친 사람을 돌봤어요. 응급 처치 흔적이에요."]],
        "choices":[],"chapters":["BLIND_DECK"]},
    {"id":"070_rho_blind_deck_wiring","speaker":"rho","tag":"observation","category":"WORK","family":"rho_blind_deck_wiring","intent":"work",
        "action":"준이 배선함을 열고 새로 이어붙인 자국을 손끝으로 따라간다.",
        "lines":[["rho","이거 최근 작업은 아니야. 근데 솜씨가 꽤 좋네. 나만큼은 아니지만."]],
        "choices":[],"chapters":["BLIND_DECK"]},
    {"id":"070_dax_blind_deck_system","speaker":"dax","tag":"observation","category":"WORK","family":"dax_blind_deck_system","intent":"work",
        "action":"다렌이 정비 구역 제어반의 설정값을 지금 시스템과 비교한다.",
        "lines":[["dax","설정 체계가 지금이랑 같은 세대야. 다른 시대 물건은 아니라는 뜻이지."]],
        "choices":[],"chapters":["BLIND_DECK"]},
    {"id":"070_sena_blind_deck_access","speaker":"sena","tag":"observation","category":"WORK","family":"sena_blind_deck_access","intent":"work",
        "action":"세나가 출입 기록 대신 문틀에 남은 마모 흔적을 손으로 훑는다.",
        "lines":[["sena","이 정도 닳았으면 한두 번 드나든 게 아니야. 꽤 오래, 자주 썼어."]],
        "choices":[],"chapters":["BLIND_DECK"]},
    {"id":"070_vale_blind_deck_static","speaker":"vale","tag":"observation","category":"WORK","family":"vale_blind_deck_static","intent":"work",
        "action":"소렌이 정비 구역 안에서 헤드셋을 낀 채 가만히 서 있는다.",
        "lines":[["vale","여기, 다른 구역보다 잡음이 적어요. 누가 방음을 신경 썼다는 뜻이에요."]],
        "choices":[],"chapters":["BLIND_DECK"]},
    {"id":"070_lyra_blind_deck_ecology","speaker":"lyra","tag":"observation","category":"WORK","family":"lyra_blind_deck_ecology","intent":"work",
        "action":"마렌이 환풍구 앞의 먼지를 손끝으로 문질러 본다.",
        "lines":[["lyra","이 먼지, 식물 포자예요. 생태 구역도 아닌데 여기서 나올 리가 없어요."]],
        "choices":[],"chapters":["BLIND_DECK"]}
]

# Four pairs the design brief names as unexplored (§25): rho-vale, sena-noa,
# lyra-vale, eli-noa had zero dedicated scenes before this pass (confirmed by
# content_audit.gd's pair-distribution report). Broadly available like the
# rest of the shared library, not tied to one specific day. line_relations
# follows storylets_053.gd's pattern so replies actually answer each other.
const PAIR_SCENES := [
    {"id":"070_pair_rho_vale_steady_sound","speaker":"rho","target":"vale","tag":"pair","category":"PAIR","family":"rho_vale_steady_sound","intent":"work",
        "action":"준이 공구 소리를 줄이려고 작업을 미루려 하자 소렌이 손을 젓는다.",
        "lines":[["rho","이 소리 거슬리면 말해. 나중에 할게."],
            ["vale","아니에요, 계속하세요. 일정한 소리는 오히려 구분하기 쉬워요."],
            ["rho","그래? 그럼 이것도 한번 들어 봐 줄래. 이 소리, 이상하지 않아?"]],
        "line_relations":["anchor","reply","proposal"],
        "choices":[],"chapters":AstraStorylets052.MID_CHAPTERS},
    {"id":"070_pair_sena_noa_record_first","speaker":"sena","target":"noa","tag":"pair","category":"CONFLICT","family":"sena_noa_record_first","intent":"conflict",
        "action":"세나가 구역을 바로 막으려 하자 노아가 기록판을 먼저 든다.",
        "lines":[["sena","이 구역부터 막을게."],
            ["noa","이유는 기록해 두고 갈까요?"],
            ["sena","적을 시간 있으면 먼저 막아. 이유는 내가 나중에 불러줄게."],
            ["noa","…그럼 지금 말해요. 걸으면서 적을게요."]],
        "line_relations":["anchor","challenge","reply","proposal"],
        "choices":[],"chapters":AstraStorylets052.MID_CHAPTERS},
    {"id":"070_pair_lyra_vale_quiet_things","speaker":"lyra","target":"vale","tag":"pair","category":"PAIR","family":"lyra_vale_quiet_things","intent":"relationship",
        "action":"마렌이 작은 화분 하나를 통신실 구석에 놓는다.",
        "lines":[["lyra","여기 너무 조용해서 뭐라도 하나 뒀어요."],
            ["vale","…식물 소리는 안 들리는데, 방이 덜 비어 보이네요."],
            ["lyra","그거면 됐어요. 저도 사실 잘 안 들리는 거 좋아해요."]],
        "line_relations":["anchor","reply","agreement"],
        "choices":[],"chapters":AstraStorylets052.MID_CHAPTERS},
    {"id":"070_pair_eli_noa_deviation","speaker":"eli","target":"noa","tag":"pair","category":"MYSTERY","family":"eli_noa_deviation","intent":"record",
        "action":"루칸이 항로 편차 지점을 짚자 노아가 기록판을 편다.",
        "lines":[["eli","이 지점에서만 경로가 살짝 틀어져."],
            ["noa","좌표랑 시각, 둘 다 알려주시겠어요?"],
            ["eli","여기. 그리고 이유는 아직 몰라."],
            ["noa","이유 없이도 적을게요. 나중에 채우면 되니까요."]],
        "line_relations":["anchor","clarify","answer","accept"],
        "choices":[],"chapters":AstraStorylets052.MID_CHAPTERS}
]

static func scenes() -> Array:
    var result: Array = []
    for scene in ACT1_SCENES:
        result.append(Dictionary(scene).duplicate(true))
    for scene in ACT2_SCENES:
        result.append(Dictionary(scene).duplicate(true))
    for scene in PAIR_SCENES:
        result.append(Dictionary(scene).duplicate(true))
    return result
