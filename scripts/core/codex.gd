class_name AstraCodex
extends RefCounted

# The three layers of help (§10).
#
#   1. TOOLTIPS   — one sentence on the button itself, always available
#   2. SCREEN     — the [?] in the corner, answering only "what is this screen
#                   for and what can I do here", for the screen in front of you
#   3. TOPICS     — the archive the player opens on purpose
#
# A topic only exists once the thing it describes has appeared in play. Reading
# about night tactics before the first night is not help, it is homework, and
# the words in it ("Null", "프로토콜", "재구성") mean nothing yet (§26).

const TOOLTIPS = {
    "investigate": "현장에서 기록이나 흔적을 찾습니다. 조사 행동 1회를 사용합니다.",
    "move": "장소를 옮깁니다. 시간을 쓰지 않습니다.",
    "notebook": "찾은 단서와 들은 말을 모아 둡니다. 여는 데 시간이 들지 않습니다.",
    "ask_alibi": "사건 시각에 어디 있었는지 묻습니다. 출입 기록과 대조할 수 있습니다.",
    "ask_evidence": "확보한 단서를 보여 줍니다. 명단에 든 사람과 아닌 사람의 반응이 다릅니다.",
    "ask_contradiction": "진술과 기록이 어긋난 지점을 짚습니다. 사정이 있는 사람은 털어놓고, 실행자는 실언할 수 있습니다.",
    "ask_suspect": "지금 누구를 의심하는지 묻습니다. 대답에는 보통 이유가 붙습니다.",
    "ask_pressure": "사실만 말하라고 요구합니다. 신뢰가 떨어지지만 긴장을 끌어올립니다.",
    "ask_reassure": "재촉하지 않고 기다립니다. 신뢰가 오르고 긴장이 내려갑니다.",
    "mark": "이름 옆에 나의 판단을 표시합니다. 게임의 판정이 아니라 나의 메모입니다.",
    "present": "확보한 단서를 모두에게 공개합니다. 공개된 근거만 여론을 움직입니다.",
    "accuse": "공개적으로 지목합니다. 근거가 없으면 탐사요원의 신뢰가 떨어집니다.",
    "defend": "공개적으로 변호합니다. 확인된 사람일수록 효과가 큽니다.",
    "confront": "두 사람에게 그 시각의 위치를 다시 말하게 합니다. 말이 맞지 않으면 모두 앞에서 드러나고, 맞으면 두 사람 다 의심에서 멀어집니다.",
    "vote": "한 명을 격리합니다. 탐사요원의 표는 1표로 계산됩니다.",
    "night_protect": "한 사람의 선실을 지킵니다.",
    "night_secure": "한 구역을 감시해 그날 밤의 증거 인멸을 막습니다.",
    "night_backup": "그 구역의 기록을 복사해 둡니다. 지워져도 남습니다.",
    "night_rest": "쉽니다. 다음 날 대화 여유가 늘지만 아무도 지키지 못합니다.",
    "auto": "대사를 자동으로 넘깁니다. 중요한 대사에서는 멈춥니다.",
    "log": "지금까지 나온 대사를 처음부터 다시 봅니다."
}

# Per phase: what this screen is for, then what you can do here. Nothing else.
const SCREEN_HELP = {
    "EXPLORE": {"purpose":"깨어 있는 동료와 배를 살펴봅니다.","points":["위쪽에 지금 할 일이 표시됩니다.","장소나 인물의 이름을 누르면 이동합니다.","대화는 계속 버튼을 누를 때만 진행됩니다."]},
    "BRIEFING": {
        "purpose": "무슨 일이 있었는지 확인합니다.",
        "points": [
            "사건 시각을 기억해 두세요. 이 시간대 밖의 기록은 사건과 무관합니다.",
            "조작이 일어난 장소가 곧 첫 조사 후보입니다."
        ]
    },
    "INVESTIGATION": {
        "purpose": "무엇을 조사할지 고릅니다.",
        "points": [
            "장소 이동은 무료입니다. 조사 지점을 누를 때만 조사 행동 1회를 사용합니다.",
            "흔적은 범인의 이름이 아니라 후보 명단을 줍니다.",
            "같은 조작에서 나온 흔적 두 개가 겹치는 한 사람이 실행자입니다."
        ]
    },
    "INTERROGATION": {
        "purpose": "무엇을 물을지 고릅니다.",
        "points": [
            "이름을 눌러 상대를 바꿉니다. 숫자키도 됩니다.",
            "알리바이를 먼저 듣고 출입 기록과 맞춰 보세요.",
            "거짓말하는 사람이 모두 실행자는 아닙니다. 사정이 있는 사람이 섞여 있습니다."
        ]
    },
    "MEETING": {
        "purpose": "누구의 말을 믿을지 정합니다.",
        "points": [
            "발언은 하나씩 나옵니다. 화면을 누르면 다음 발언으로 넘어갑니다.",
            "공개하지 않은 단서는 여론을 움직이지 못합니다.",
            "이전 발언과 다른 말이 나오면 그 자리에서 짚을 수 있습니다."
        ]
    },
    "VOTE": {
        "purpose": "누구에게 책임을 물을지 정합니다.",
        "points": [
            "탐사요원의 표는 1표입니다.",
            "표는 한 장씩 공개됩니다. 개표 전에는 아무도 결과를 모릅니다.",
            "격리된 사람의 정체는 사건이 끝날 때까지 공개되지 않습니다."
        ]
    },
    "NIGHT": {
        "purpose": "무엇을 지킬지 정합니다.",
        "points": [
            "밤에 할 수 있는 일은 하나입니다.",
            "밤에 습격당한 사람은 실행자가 아닙니다. 그 사람이 누구를 의심했는지 떠올려 보세요."
        ]
    },
    "RESULT": {
        "purpose": "실제로 무슨 일이 있었는지 확인합니다.",
        "points": [
            "누가 거짓말했고, 그 거짓말이 무엇을 숨긴 것이었는지 함께 나옵니다.",
            "졌더라도 같은 장을 다시 시작할 수 있습니다. 배치는 새로 결정됩니다."
        ]
    }
}

# Archive topics. `needs` is the unlock that has to be open first; "" is always.
const TOPICS = [
    {"id": "goal", "needs": "", "title": "이 게임의 목표", "body": "승무원 중 일부는 Null입니다. Null은 사건 당시 각자 다른 곳에서 조작을 하나씩 실행했습니다. 정해진 날짜 안에 Null을 모두 격리하면 이깁니다. 살아남은 승무원 수가 Null과 같아지면 집니다."},
    {"id": "clue", "needs": "", "title": "흔적은 이름이 아니다", "body": "현장 흔적은 ‘내열 섬유 — 준, 다렌’처럼 후보 명단을 줍니다. 한 명을 특정하려면 같은 조작에서 나온 흔적 두 개의 명단을 겹쳐야 합니다. 기록 시각이 사건 시간대 밖이면 그 흔적은 사건과 무관합니다."},
    {"id": "alibi", "needs": "", "title": "알리바이와 모순", "body": "‘어디에, 누구와’를 모아 출입 기록과 대조합니다. 같은 곳에 있었다면서 서로를 못 봤다는 두 사람도 모순입니다."},
    {"id": "lying", "needs": "", "title": "거짓말한다고 범인은 아니다", "body": "사건마다 사건과 무관한 이유로 거짓말하는 무고한 승무원이 있습니다. 규정 위반, 개인 사정, 창피함. 거짓말을 찾았다면 그 다음 질문은 ‘무엇을 숨기려고?’입니다."},
    {"id": "meeting", "needs": "", "title": "회의", "body": "공개된 근거만 여론을 움직입니다. 확보했지만 공개하지 않은 단서는 다른 승무원의 판단에 영향을 주지 않습니다. 근거 없는 지목은 탐사요원의 신뢰를 떨어뜨립니다."},
    {"id": "vote", "needs": "", "title": "투표", "body": "탐사요원의 표는 1표로 계산됩니다. 최다 득표자를 격리하며, 동률이면 아무도 격리되지 않습니다."},
    {"id": "claims", "needs": "claim_search", "title": "발언 기록", "body": "승무원이 공개적으로 한 말은 전부 남습니다. 같은 사람이 같은 시간대에 대해 다른 말을 하면 노트에서 찾을 수 있습니다. 게임은 그것을 ‘거짓말’이라고 판정하지 않습니다. 판단은 당신이 합니다."},
    {"id": "night", "needs": "night", "title": "밤", "body": "Null은 밤마다 한 명을 노리고, 자신을 가리키는 흔적을 지우려 합니다. 밤에 습격당한 사람은 Null이 아닙니다."},
    {"id": "night_tactics", "needs": "night_tactics", "title": "야간 행동", "body": "보호는 한 사람을 지킵니다. 감시는 한 구역의 증거 인멸을 막습니다. 기록 백업은 지워질 기록을 미리 복사합니다. 휴식은 다음 날 대화 여유를 줍니다."},
    {"id": "hypothesis", "needs": "hypothesis", "title": "가설", "body": "노트에서 단서·인물·조작을 연결해 가설을 만들고 회의에서 제시할 수 있습니다. 게임은 가설의 정답 여부를 미리 알려 주지 않습니다."},
    {"id": "protocol", "needs": "protocols", "title": "조사 방식", "body": "분석관은 현장을 더 오래 봅니다. 공감관은 대화 여유가 많습니다. 감사관은 검시 기록으로 시작하고 격리자의 정체를 밤마다 확인합니다."},
    {"id": "difficulty", "needs": "difficulty_select", "title": "속도", "body": "스토리는 첫날 밤에 아무도 잃지 않고 추천 장소를 표시합니다. 표준은 기본 균형입니다. 전문가는 서로를 보증하는 알리바이가 늘고 거짓말이 더 자연스러워집니다. 쓸모없는 단서를 늘려 어렵게 만들지는 않습니다."},
    {"id": "loop", "needs": "case_select", "title": "왜 같은 사람들이 다시 나오는가", "body": "다시 눈을 뜨면 동료의 목적지 기억과 과거 관계가 달라집니다. 낯익은 감정이 남기도 합니다. 그 이유는 아직 밝혀지지 않았습니다. 이전 회차의 의심은 이번 사건의 증거가 아닙니다."}
]

static func tooltip(key: String) -> String:
    return str(TOOLTIPS.get(key, ""))

static func screen(phase: String) -> Dictionary:
    return SCREEN_HELP.get(phase, {"purpose": "", "points": []})

static func topics(unlocked_list: Array) -> Array:
    var result: Array = []
    for topic in TOPICS:
        var needs := str(topic.get("needs", ""))
        if needs != "" and not (needs in unlocked_list):
            continue
        result.append(topic)
    return result
