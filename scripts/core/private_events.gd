class_name AstraPrivateEvents
extends RefCounted

# One private scene per crew member. Choices have real consequences:
# they can hand you a clue, a read on someone's nerves, or — when the person
# confiding in you is secretly a Null — a carefully shaped lie.

const EVENTS := {
    "mira": {
        "scene": "미라가 새 장갑을 꺼내다 손을 멈춘다. 당신이 들어오자 한 쌍을 건넨다.",
        "prompt": "“같이 확인해 줄래요? 제가 자꾸 같은 줄을 놓쳐요.”",
        "choices": [
            {
                "label": "장갑을 끼고 곁에 선다.",
                "hint": "",
                "effect": "comfort"
            },
            {
                "label": "“그때 본 것부터 말해 줘요.”",
                "hint": "",
                "effect": "witness"
            }
        ]
    },
    "rho": {
        "scene": "준이 바닥에 공구를 펼쳐 놓았다. 평소와 달리 농담을 하지 않는다.",
        "prompt": "“내가 만진 데가 있어. 같이 봐 줘. 혼자 확인하면 또 놓칠 것 같아.”",
        "choices": [
            {
                "label": "옆에 앉아 기록을 편다.",
                "hint": "",
                "effect": "open_records"
            }
        ]
    },
    "eli": {
        "scene": "루칸이 항로의 끝을 화면 밖으로 밀어 놓는다.",
        "prompt": "“가까이만 보면 놓치는 게 있어. 사람들이 어디를 보고 있는지.”",
        "choices": [
            {
                "label": "“회의에서 뭘 봤어?”",
                "hint": "",
                "effect": "flow"
            },
            {
                "label": "화면을 전체 보기로 바꾼다.",
                "hint": "",
                "effect": "top_suspect"
            }
        ]
    },
    "sena": {
        "scene": "세나가 문고리를 확인하고 당신 옆에 선다.",
        "prompt": "“오늘은 내가 돌게. 너까지 안 자면 내일 둘 다 늦어.”",
        "choices": [
            {
                "label": "“한 바퀴 돌고 깨워 줘.”",
                "hint": "",
                "effect": "patrol"
            },
            {
                "label": "“같이 확인하고 쉬자.”",
                "hint": "",
                "effect": "procedure"
            }
        ]
    },
    "vale": {
        "scene": "소렌이 이어폰을 두 개 꺼낸다. 재생 버튼 위에서 손이 멈춘다.",
        "prompt": "“그때 혼자 들었어요. 이번에는 같이 들어 줘요.”",
        "choices": [
            {
                "label": "이어폰을 낀다.",
                "hint": "",
                "effect": "vale_record"
            }
        ]
    },
    "noa": {
        "scene": "노아가 지우려던 문장을 그대로 둔 채 단말을 내민다.",
        "prompt": "“읽어 줄래요? 제가 먼저 말하면 그쪽으로 보일 것 같아요.”",
        "choices": [
            {
                "label": "소리 내지 않고 읽는다.",
                "hint": "",
                "effect": "noa_private"
            },
            {
                "label": "“같이 확인할 사람을 부를까?”",
                "hint": "",
                "effect": "noa_public"
            },
            {
                "label": "단말을 돌려주고 기다린다.",
                "hint": "",
                "effect": "comfort_light"
            }
        ]
    },
    "lyra": {
        "scene": "마렌이 시든 가지와 살아 있는 가지를 따로 놓는다.",
        "prompt": "“구할 수 있는 쪽에 물을 줘야 해요. 아는데, 손이 안 움직여요.”",
        "choices": [
            {
                "label": "가위를 건네고 곁에 앉는다.",
                "hint": "",
                "effect": "calm_meeting"
            },
            {
                "label": "“누가 가장 몰리고 있어요?”",
                "hint": "",
                "effect": "crowd_target"
            },
            {
                "label": "작업대를 같이 정리한다.",
                "hint": "",
                "effect": "comfort_light"
            }
        ]
    },
    "dax": {
        "scene": "다렌이 두 계산을 지우지 않고 나란히 남겨 둔다.",
        "prompt": "“내가 틀린 쪽부터 보고 싶어. 어디가 걸리지?”",
        "choices": [
            {
                "label": "“기록하고 다른 곳부터.”",
                "hint": "",
                "effect": "dax_hint"
            },
            {
                "label": "“지금 누구의 말이 걸려?”",
                "hint": "",
                "effect": "top_suspect"
            }
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
