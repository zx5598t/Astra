class_name AstraStory
extends RefCounted

const MEMENTOS := {
    "DEAD_AIR": ["끊어진 교신", "comms_09", "복구된 음성: ‘응답하지 마라. 그 신호는 지구에서 오지 않았다.’ 누군가 통신을 끊은 것은 구조를 막기 위해서였을까, 우리를 지키기 위해서였을까."],
    "ECHO_WARD": ["깨어난 기억", "medical_15", "동면 장치의 보조 메모리에서 Sael의 열람 흔적이 살아났다. 누군가는 진료 기록을 읽은 뒤 원본을 폐기하려 했다."],
    "GLASS_GARDEN": ["살아 있는 좌표", "botanical_06", "지구에서는 피지 않는 꽃. 씨앗 용기 바닥에는 목적지가 아닌, 이미 방문한 별의 좌표가 새겨져 있다."],
    "SILENT_ORBIT": ["지워진 항로", "tools_08", "우회 회로에서 삭제된 명령을 찾았다. ‘귀환 금지.’ 함장 역시 이 명령을 따르지 않았다."],
    "RED_SHIFT": ["다른 하늘", "archive_10", "보안 단말에는 항로 수정 요청을 묵살한 기록이 남았다. 외부의 오류로 분류됐던 경고가 선내에서 발신됐다."],
    "LAST_LIGHT": ["우리의 다음 항로", "gifts_11", "함장의 봉인 편지: ‘프로토콜은 생존만을 계산한다. 함께 살아갈 이유는 너희가 골라라.’ 이제 항로 결정권은 사람에게 돌아왔다."]
}
const PERSONAL := {
    "mira": ["리라가 매일 의료실에 꽃을 놓아요. 환자가 없어도요. 저도 누군가를 돌보는 사람이라는 걸 잊지 않게 해 줘요.", "이름을 먼저 부르려고 해요. 기록 번호로만 부르기 시작하면, 살리지 못한 사람을 너무 쉽게 잊게 되거든요."],
    "rho": ["세나랑 싸운 건 안전문 때문이야. 잠그면 안전해진다는데, 안에 사람 있을 땐 누가 열어 주냐고.", "고장 난 걸 버리면 편하지. 근데 이 배엔 새 부품도, 새 사람도 없어. 고쳐서 같이 가야지."],
    "eli": ["노아는 내가 농담한 날짜까지 기억해. 가끔은 말이야, 누군가 내 말을 끝까지 듣고 있다는 게 든든해.", "별을 외우면 집에 갈 수 있을 줄 알았어. 요즘은 같이 별을 볼 사람이 남아 있는지부터 세."],
    "sena": ["로우와 절차 문제로 다툰 적이 있습니다. 그러나 사고 때 가장 먼저 문 안으로 들어간 사람도 로우였습니다.", "안전하다고 보장할 수는 없습니다. 다만 마지막 순찰이 끝날 때까지 제 자리를 비우지 않겠습니다."],
    "vale": ["닥스는 제 말에 여백이 많다고 해요. 저는 그 여백이 사람을 살린다고 생각하거든요.", "돌아가면 답하겠다고 남겨 둔 편지가 있어요. 교신이 복구되면 가장 먼저 읽고 싶네요."],
    "noa": ["엘리는 같은 농담을 해요. 불안할 때만요. 웃었다고 괜찮은 건 아니에요.", "누가 무엇을 잊었는지 기록해요. 나중에는, 잊었다는 사실도 잊으니까요."],
    "lyra": ["미라는 자기 몫의 물도 환자에게 줘요. 제가 꽃에 물을 주러 가는 건, 그 사람도 쉬게 하려고요.", "씨앗은 아무도 보지 않을 때 자라요. 사람도 그랬으면 해요. 의심받지 않는 밤이 한 번쯤은 필요하잖아요."],
    "dax": ["베일의 우회적인 화법은 비효율적이다. 그러나 다툼을 멈춘 횟수는 내 설명보다 많다. 계산에 넣어야 할 변수다.", "완벽한 시스템은 없다. 오류를 인정하고 복구할 통로가 있는 시스템만 있다. 사람도 마찬가지다."]
}
static func personal(id: String, variation: int) -> String:
    var lines: Array = PERSONAL.get(id, ["…"])
    return str(lines[posmod(variation, lines.size())])
static func tutorial(phase: String, practiced: bool = false) -> String:
    match phase:
        "BRIEFING": return "미라 · 먼저 사건의 시각과 두 조작을 확인해요. 준비되면 ‘현장으로’ 눌러 주세요."
        "INVESTIGATION": return "노아 · 단서는 조사 노트에 보관돼요. 다른 흔적의 시간·장소를 대조해 보세요." if practiced else "노아 · 장소를 고른 뒤 빛나는 조사 지점을 눌러요. 이동과 노트 열기는 시간을 쓰지 않아요."
        "INTERROGATION": return "미라 · 이름을 눌러 상대를 바꿀 수 있어요. 먼저 사건 시각에 어디 있었는지 물어봐요. 거짓말에도 사정이 있을 수 있어요."
        "MEETING": return "세나 · 모두의 진술을 듣고 단서를 공개하십시오. 노트의 가설을 회의에서 제시할 수도 있습니다."
        "VOTE": return "세나 · 이름을 고르고 투표를 확정하십시오. 최다 득표자를 격리하며, 동률에 조사관의 대상이 있으면 그 대상을 우선합니다."
        "NIGHT": return "미라 · 오늘 밤 할 수 있는 일은 하나예요. 사람을 지킬지, 사라질 기록을 지킬지 선택해요."
    return ""

# One sentence per person for the card shown the first time they appear.
# Not a biography — a line that shows what they do when something goes wrong,
# which is the only thing worth knowing about a stranger on this ship (§21, §22).
const FIRST_LINE := {
    "mira": "살아 있는 사람부터 확인하죠.",
    "rho": "고장 난 건 내가 고쳐. 사람 문제는 니들이 알아서 해.",
    "eli": "다들 표정이 재밌네. 누가 제일 먼저 말을 바꿀까?",
    "sena": "절차대로 하겠습니다. 이의가 있으면 지금 말하십시오.",
    "vale": "같은 말을 다르게 들을 수도 있어요. 조금만 천천히 가요.",
    "noa": "제가 기록할게요. 나중에 누가 뭐라고 했는지 필요할 테니까요.",
    "lyra": "이럴 때일수록 서로한테 함부로 하지 않았으면 좋겠어요.",
    "dax": "감정은 변수다. 기록은 상수다. 상수부터 본다."
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
                return "노아 · 찾은 기록은 노트에 저장돼요. 남은 지점도 마저 살펴봐요."
            return "노아 · 장소를 누르고, 노란 동그라미가 있는 곳을 눌러요. 그게 조사예요."
        "INTERROGATION":
            if practiced:
                return "미라 · 나머지 사람에게도 같은 걸 물어봐요. 네 명 전부요."
            return "미라 · 사람을 누르고 ‘그 시각, 어디에 있었나요?’를 눌러요."
        "MEETING":
            return "세나 · 한 명씩 말합니다. 다 듣고 나면 개입할 수 있습니다."
        "VOTE":
            return "세나 · 기록과 말이 맞지 않은 사람을 고르십시오. 틀려도 괜찮습니다."
    return ""
