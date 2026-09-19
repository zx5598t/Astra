class_name AstraPrivateEvents
extends RefCounted

# One private scene per crew member. Choices have real consequences:
# they can hand you a clue, a read on someone's nerves, or — when the person
# confiding in you is secretly a Null — a carefully shaped lie.

const EVENTS := {
    "mira": {
        "scene": "의료실 비상등이 낮게 깜빡인다. 미라는 장갑을 벗지 않은 채 자기 손끝만 내려다본다.",
        "prompt": "“{victim}님 맥박이 멈췄을 때… 제가 조금만 빨리 갔더라면요. 조사관님, 저 지금 제대로 판단하고 있는 걸까요?”",
        "choices": [
            {"label": "“당신 탓이 아닙니다. 지금은 살아 있는 사람을 지킵시다.”", "hint": "신뢰 크게 상승 · 긴장 완화", "effect": "comfort"},
            {"label": "“그때 의무실 근처에서 본 사람이 있었는지 천천히 떠올려 봐요.”", "hint": "목격 정보를 얻는다", "effect": "witness"},
            {"label": "“감정은 나중에요. 지금은 사실만 말해 주세요.”", "hint": "반응을 관찰한다 · 신뢰 소폭 하락", "effect": "read"}
        ]
    },
    "rho": {
        "scene": "엔진 진동이 바닥을 울린다. 로우가 렌치를 작업대에 내려놓고 당신을 똑바로 본다.",
        "prompt": "“계속 날 의심할 거면 기록 전부 까 줄게. 대신 똑바로 봐. 나중에 딴소리하지 말고.”",
        "choices": [
            {"label": "“좋아요. 같이 봅시다.”", "hint": "미확보 단서 하나를 함께 확인한다", "effect": "open_records"},
            {"label": "“기록은 제가 직접 확인하겠습니다.”", "hint": "신뢰 소폭 하락 · 조작 위험 없음", "effect": "cold"},
            {"label": "“왜 하필 지금 그런 제안을 하죠?”", "hint": "반응을 관찰한다", "effect": "read"}
        ]
    },
    "eli": {
        "scene": "항법창 너머로 별빛이 느리게 흐른다. 엘리가 동전을 튕기다가 손바닥으로 탁 덮는다.",
        "prompt": "“누가 회의 흐름을 설계하고 있어. 판 위의 수를 보면 알지. 궁금하지 않아?”",
        "choices": [
            {"label": "“누구 수가 이상했는데?”", "hint": "지난 회의에서 여론을 가장 세게 민 사람을 듣는다", "effect": "flow"},
            {"label": "“비유 말고 증거로 말해.”", "hint": "신뢰 소폭 하락", "effect": "cold"},
            {"label": "“그럼 넌 이번 판을 어떻게 읽고 있지?”", "hint": "엘리의 속마음을 듣는다", "effect": "top_suspect"}
        ]
    },
    "sena": {
        "scene": "보안허브의 감시 화면들이 일제히 당신을 비춘다. 세나가 출입문을 잠그고 돌아선다.",
        "prompt": "“절차대로 가면 범인을 놓칠 수 있습니다. 오늘 밤 제 재량으로 선내 순찰을 강화해도 되겠습니까?”",
        "choices": [
            {"label": "“허가합니다. 오늘 밤 순찰을 맡기죠.”", "hint": "오늘 밤 세나가 한 명을 추가로 보호한다", "effect": "patrol"},
            {"label": "“아니요. 절차를 지킵시다.”", "hint": "신뢰 상승 · 긴장 완화", "effect": "procedure"},
            {"label": "“순찰 대상은 누구로 생각하고 있죠?”", "hint": "세나가 주시하는 사람을 듣는다", "effect": "top_suspect"}
        ]
    },
    "vale": {
        "scene": "통신실 스피커에서 백색소음이 흐른다. 베일이 채널 하나를 손수 끄고 목소리를 낮춘다.",
        "prompt": "“조사관님께만 먼저 보여 드릴게요. 그날 밖으로 나간 신호, 해석이 하나만은 아니거든요.”",
        "choices": [
            {"label": "“보여 주세요.”", "hint": "베일이 해석한 기록을 받는다 · 출처는 베일", "effect": "vale_record"},
            {"label": "“공식 기록으로만 받겠습니다.”", "hint": "신뢰 소폭 하락", "effect": "cold"},
            {"label": "“왜 하필 저에게만 보여 주는 거죠?”", "hint": "반응을 관찰한다", "effect": "read"}
        ]
    },
    "noa": {
        "scene": "기록보관실의 로그가 끝없이 흘러간다. 노아가 문장 하나에서 스크롤을 멈춘다.",
        "prompt": "“누군가의 진술과 단말 접속 기록이 맞지 않아요. 공개해도 될지… 모르겠어요.”",
        "choices": [
            {"label": "“공개하죠. 기록은 거짓말하지 않으니까.”", "hint": "모순을 얻고, 다음 회의에서 모두에게 알린다", "effect": "noa_public"},
            {"label": "“먼저 저에게만 알려 주세요.”", "hint": "모순을 조용히 얻는다", "effect": "noa_private"},
            {"label": "“확실하지 않다면 일단 묻어 둡시다.”", "hint": "신뢰 상승", "effect": "comfort_light"}
        ]
    },
    "lyra": {
        "scene": "수목구역 유리벽에 습기가 맺힌다. 리라가 시든 잎 하나를 조심스럽게 접는다.",
        "prompt": "“다들 서로를 몰아붙이고 있어요. 이러다 무고한 사람이 격리될 거예요. 제가 뭘 하면 좋을까요?”",
        "choices": [
            {"label": "“회의 전에 사람들을 좀 진정시켜 줄래요?”", "hint": "다음 회의의 과열된 의심이 누그러진다", "effect": "calm_meeting"},
            {"label": "“지금 누가 가장 위험하게 몰리고 있죠?”", "hint": "여론의 표적을 듣는다", "effect": "crowd_target"},
            {"label": "“감정보다 증거가 먼저예요.”", "hint": "신뢰 소폭 하락", "effect": "cold"}
        ]
    },
    "dax": {
        "scene": "진단 패널의 그래프가 규칙적으로 뛴다. 닥스가 수치 하나를 손가락으로 짚는다.",
        "prompt": "“사람의 직감과 시스템 로그가 충돌하면, 무엇을 우선하지?”",
        "choices": [
            {"label": "“로그.”", "hint": "닥스가 추리의 핵심 변수를 짚어 준다", "effect": "dax_hint"},
            {"label": "“직감.”", "hint": "신뢰 소폭 하락", "effect": "cold"},
            {"label": "“둘 다 틀릴 수 있어.”", "hint": "닥스의 속마음을 듣는다", "effect": "top_suspect"}
        ]
    }
}

static func has_event(npc_id: String) -> bool:
    return EVENTS.has(npc_id)

static func build(npc_id: String, victim: String) -> Dictionary:
    var source: Dictionary = EVENTS.get(npc_id, {})
    if source.is_empty():
        return {}
    var event := source.duplicate(true)
    event["npc_id"] = npc_id
    event["prompt"] = AstraJosa.fill(str(source.get("prompt", "")), {"victim": victim})
    return event
