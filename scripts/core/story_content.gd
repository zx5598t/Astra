class_name AstraStory
extends RefCounted

const MEMENTOS := {
    "DEAD_AIR": [
        "마지막 교신",
        "archive_07",
        "귀환 승인서와 탐사 명령서가 같은 날 서명됐다. 두 문서 모두 원본이다."
    ],
    "GLASS_GARDEN": [
        "유리 정원",
        "archive_07",
        "세나의 순찰 기록에는 준과 함께 근무한 날이 있다. 준의 배치 기록에는 그날이 없다."
    ],
    "ECHO_WARD": [
        "메아리 병동",
        "archive_07",
        "수면 중인 소렌의 음성이 통신 기록에 남아 있다. 같은 시간 포드는 닫혀 있었다."
    ],
    "SILENT_ORBIT": [
        "고요한 궤도",
        "archive_07",
        "ASTRA — 목적지 도착 완료. 기록 날짜는 현재보다 19년 전이다."
    ],
    "RED_SHIFT": [
        "다른 하늘",
        "archive_07",
        "씨앗의 채집 장소는 ASTRA의 목적지다. 채집일은 출항일보다 이르다."
    ],
    "LAST_LIGHT": [
        "남은 불빛",
        "archive_07",
        "복사한 기록의 목적지 칸이 서로 다르다. 도착했다는 문장만 남아 있다."
    ]
}
const PERSONAL := {
    "mira": [
        "찬물은 없어요. 이것부터 조금 마셔요.",
        "손이 떨리네요. 잠깐 앉아요. 포드는 제가 볼게요.",
        "이쪽이 편하죠?",
        "그 이름은 지우지 말아 주세요. 아직 연락할 사람이 있어요.",
        "침대는 비워 둬야 해서요. 여기서 조금만 잘게요."
    ],
    "rho": [
        "공연 끝. 관객 한 명이 너무 엄격해서.",
        "그거, 파란 손잡이. 아니, 내 손 말고 공구.",
        "어. 왜 이렇게 줬지.",
        "전에 반대로 끼운 적 있어. 누가 다친 건 아니고. 그래서 자꾸 확인하게 돼.",
        "아직 안 잔다길래. 뜨거운 거라도 갖다 주려고."
    ],
    "dax": [
        "이건 고쳐도 맛은 그대로겠군.",
        "하나씩은 맞아. 같이 놓으면 틀리지. 어느 쪽부터 볼까.",
        "이걸 찾을 것 같아서.",
        "전에도 정상이라고 나온 적이 있었지. 그 말을 너무 빨리 믿었어.",
        "내일 봐도 돼. 답이 달라지면 그때 문제가 있는 거고."
    ],
    "noa": [
        "뒷면도 썼네요. 버리면 안 되겠어요.",
        "여기만 달라요. 날짜는 같고요.",
        "거기 앉으세요.",
        "제가 쓴 말인데, 쓴 기억이 없어요. 지우면 더 모르겠죠.",
        "잘 자요. 오늘 날짜는 여기 적어 둘게요."
    ],
    "sena": [
        "한 번만 더 해. 방금은 네가 먼저 움직였어.",
        "밖에서 잠겨도 안에서는 열려야 해. 이것부터 보자.",
        "미안. 너무 빨랐지.",
        "그때는 안에 아무도 없다고 했어. 이번엔 직접 볼 거야.",
        "거기가 잘 보여. 졸리면 교대해 줘."
    ],
    "vale": [
        "음악이에요. 오늘은 잡음 말고 다른 게 듣고 싶어서.",
        "한 번만 더. 방금 숨소리가 있었어요.",
        "짧을 것 같아서요.",
        "그때 들었어요. 아무에게도 말 안 했고요. 이번에는 같이 들어 줘요.",
        "너무 조용하면 잠이 안 와요."
    ],
    "eli": [
        "거긴 눈부셔. 이쪽이 낫다.",
        "계기 말고 창밖부터 봐. 같은 별인지.",
        "여기 잡아.",
        "다른 길이 있었을까. 그때는 없다고 생각했어.",
        "확인만 하고 갈 거야."
    ],
    "lyra": [
        "새 잎이에요! 어제는 없었거든요. 한번 봐요.",
        "이쪽은 줄여야 해요. 포드 냉각에 물이 더 필요해요.",
        "여기가 어울릴 것 같아서요.",
        "알아요. 잘라야 하는 거. 조금만 더 보고요.",
        "얘들도 밤이 있어야 해요. 우리도 그렇고요."
    ]
}
static func personal(id: String, variation: int) -> String:
    var lines: Array = PERSONAL.get(id,[""])
    return str(lines[posmod(variation,lines.size())])
static func tutorial(phase: String, practiced: bool = false) -> String:
    match phase:
        "BRIEFING": return "미라 · 먼저 사건의 시각과 조작을 확인해요. 장면이 끝나면 바로 사람들과 대화할 수 있어요."
        "INVESTIGATION": return "노아 · 지금은 별도 조사 단계가 없어요. 사람의 말과 공개된 기록의 시간·출처를 대조해 보세요." if practiced else "노아 · 지금은 별도 조사 단계가 없어요. 먼저 사람에게 사건 시각의 일을 직접 물어보세요."
        "INTERROGATION": return "미라 · 이름을 눌러 상대를 바꿀 수 있어요. 먼저 사건 시각에 어디 있었는지 물어봐요. 거짓말에도 사정이 있을 수 있어요."
        "MEETING": return "세나 · 모두의 진술을 듣고 단서를 공개하십시오. 노트의 가설을 회의에서 제시할 수도 있습니다."
        "VOTE": return "세나 · 이름을 고르고 투표를 확정하십시오. 동률이면 결선 투표, 결선도 동률이면 탐사요원이 결정합니다."
        "NIGHT": return "미라 · 오늘 밤 할 수 있는 일은 하나예요. 사람을 지킬지, 사라질 기록을 지킬지 선택해요."
    return ""

# One sentence per person for the card shown the first time they appear.
# Not a biography — a line that shows what they do when something goes wrong,
# which is the only thing worth knowing about a stranger on this ship (§21, §22).
const FIRST_LINE := {
    "mira": "찬물은 없어요. 이것부터 조금 마셔요.",
    "rho": "공연 끝. 관객 한 명이 너무 엄격해서.",
    "dax": "이건 고쳐도 맛은 그대로겠군.",
    "noa": "뒷면도 썼네요. 버리면 안 되겠어요.",
    "sena": "한 번만 더 해. 방금은 네가 먼저 움직였어.",
    "vale": "음악이에요. 오늘은 잡음 말고 다른 게 듣고 싶어서.",
    "eli": "거긴 눈부셔. 이쪽이 낫다.",
    "lyra": "새 잎이에요! 어제는 없었거든요. 한번 봐요."
}

static func first_line(npc_id: String) -> String:
    return str(FIRST_LINE.get(npc_id, "…"))

# Guidance during the calibration case.
#
# One action per line, in the plainest words available, spoken by whoever on the
# crew would naturally say it. The 0.3.1 strings explained the rule and the
# action in the same breath, which is how a hint bar becomes a paragraph nobody
# reads; the first 0.4.0 pass was shorter but still assumed the player knew what
# "조사 지점" and "진술" meant.
static func calibration(phase: String, practiced: bool = false) -> String:
    match phase:
        "BRIEFING":
            return "미라 · 07:30에서 07:40 사이에 일어난 일이에요. 이 시간만 기억하면 돼요."
        "INVESTIGATION":
            if practiced:
                return "노아 · 별도 조사 단계는 없어요. 지금 가진 말과 기록에서 아직 확인하지 않은 출처를 보세요."
            return "노아 · 별도 조사 단계는 없어요. 사람을 누르고 사건 시각에 무엇을 봤는지부터 물어봐요."
        "INTERROGATION":
            if practiced:
                return "미라 · 나머지 사람에게도 같은 걸 물어봐요. 네 명 전부요."
            return "미라 · 사람을 누르고 ‘그 시각, 어디에 있었나요?’를 눌러요."
        "MEETING":
            return "세나 · 한 명씩 말합니다. 다 듣고 나면 개입할 수 있습니다."
        "VOTE":
            return "세나 · 기록과 말이 맞지 않은 사람을 고르십시오. 틀려도 괜찮습니다."
    return ""
