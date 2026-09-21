class_name AstraVoyageContent
extends RefCounted

const CHAPTERS := {
    "CALIBRATION": {
        "title": "눈을 뜬 자리",
        "goal": "남은 포드를 열기 전에 전원과 잠금 기록을 확인한다.",
        "fact": "power",
        "discovery": "수면실 잠금이 풀렸다. 실행자 칸은 비어 있다.",
        "outro": "생명유지 전원은 정상이다. 네 동료가 기록 사본을 보관하고 순차 각성을 준비했다. 실행자 칸이 빈 이유는 아직 모른다. 다음에는 보안 담당 포드를 열어 출입 기록을 확인한다.",
        "awake": "",
        "room": "medbay"
    },
    "DEAD_AIR": {
        "title": "마지막 교신",
        "goal": "서로 다른 목적지 기록의 출처를 찾는다.",
        "fact": "destination",
        "discovery": "귀환 승인서와 탐사 명령서가 같은 날 서명됐다. 두 문서 모두 원본이다.",
        "outro": "통신이 잠깐 열린다. 돌아온 것은 당신이 아직 하지 않은 말이다.",
        "awake": "sena",
        "room": "comms"
    },
    "GLASS_GARDEN": {
        "title": "유리 정원",
        "goal": "세나와 함께 잠긴 구역의 안전을 확인한다.",
        "fact": "security",
        "discovery": "세나의 순찰 기록에는 준과 함께 근무한 날이 있다. 준의 배치 기록에는 그날이 없다.",
        "outro": "세나가 열쇠를 돌리기 전에 문이 열린다. 안쪽 손잡이에 누군가의 손자국이 남아 있다.",
        "awake": "vale",
        "room": "security"
    },
    "ECHO_WARD": {
        "title": "메아리 병동",
        "goal": "소렌이 들은 신호를 의료 기록과 대조한다.",
        "fact": "signal",
        "discovery": "수면 중인 소렌의 음성이 통신 기록에 남아 있다. 같은 시간 포드는 닫혀 있었다.",
        "outro": "녹음 속 소렌이 숨을 들이마신다. 옆에 앉은 소렌은 숨을 멈춘다.",
        "awake": "eli",
        "room": "comms"
    },
    "SILENT_ORBIT": {
        "title": "고요한 궤도",
        "goal": "루칸과 항로 기록의 빈 구간을 확인한다.",
        "fact": "arrival",
        "discovery": "ASTRA — 목적지 도착 완료. 기록 날짜는 현재보다 19년 전이다.",
        "outro": "루칸이 창밖을 본다. 항로 화면의 별은 움직이는데, 창밖의 별은 그대로다.",
        "awake": "lyra",
        "room": "navigation"
    },
    "RED_SHIFT": {
        "title": "다른 하늘",
        "goal": "마렌의 시료와 선내 자원 기록을 비교한다.",
        "fact": "sample",
        "discovery": "씨앗의 채집 장소는 ASTRA의 목적지다. 채집일은 출항일보다 이르다.",
        "outro": "마렌이 흙을 봉투에 돌려놓는다. 뿌리에 묻은 작은 이름표는 당신의 필체다.",
        "awake": "",
        "room": "garden"
    },
    "LAST_LIGHT": {
        "title": "남은 불빛",
        "goal": "도착 기록을 누구와 함께 보존할지 결정한다.",
        "fact": "archive",
        "discovery": "복사한 기록의 목적지 칸이 서로 다르다. 도착했다는 문장만 남아 있다.",
        "outro": "다음 신호가 들어온다. 이번에는 아무도 혼자 듣지 않는다. 좌표 칸은 여전히 비어 있다.",
        "awake": "",
        "room": "archive"
    }
}
# How each chapter's loop-reset screen frames itself. Every chapter ending the
# same way ("same wrapper, different outro line") is the fastest way to make a
# seven-chapter game feel like one screen repeated seven times, so the title
# and the small physical detail underneath vary by what just happened.
const RESET_FRAMING := {
    "CALIBRATION": {"title": "같은 목소리", "detail": "손목에는 조금 전 미라가 붙여 준 반창고가 없다."},
    "DEAD_AIR": {"title": "아직 하지 않은 말", "detail": "통신 로그에는 방금 그 문장이 남아 있지 않다."},
    "GLASS_GARDEN": {"title": "안쪽에서 열린 문", "detail": "손잡이에 남은 흔적은 이미 식어 있다."},
    "ECHO_WARD": {"title": "겹쳐진 시간", "detail": "재생 목록에는 방금 들은 구간이 없다."},
    "SILENT_ORBIT": {"title": "움직이지 않는 별", "detail": "항법 화면의 좌표만 다시 흐르기 시작한다."},
    "RED_SHIFT": {"title": "다른 과거", "detail": "근무 기록의 잉크는 이미 말라 있다."},
    "LAST_LIGHT": {"title": "손상된 다음 줄", "detail": "코어의 표시등이 다시 깜빡이기 시작한다."}
}
static func reset_framing(case_id: String) -> Dictionary:
    return RESET_FRAMING.get(case_id, RESET_FRAMING["CALIBRATION"])
const ROOMS := {
    "medbay": {
        "name": "의료실",
        "points": [
            [
                "pod",
                "포드 제어 패널",
                0.24,
                0.52,
                "power",
                "나머지 포드 네 개는 장기수면 중이다. 잠금 해제에 필요한 전력이 다른 곳으로 빠져나간다."
            ],
            [
                "monitor",
                "생체 모니터",
                0.74,
                0.46,
                "signal",
                "깨어나기 직전의 맥박이 두 번 기록됐다. 같은 센서, 같은 시간이다."
            ],
            [
                "cabinet",
                "의료 단말",
                0.55,
                0.7,
                "destination",
                "귀환 후 검진 예약이 남아 있다. 목적지는 지구라고 적혀 있다."
            ]
        ]
    },
    "engine": {
        "name": "기관실",
        "points": [
            [
                "pump",
                "냉각 펌프",
                0.32,
                0.64,
                "power",
                "펌프는 돌아간다. 수면실로 가는 전원선만 누군가 분리했다. 작업자 이름이 없다."
            ],
            [
                "relay",
                "전력 제어기",
                0.7,
                0.42,
                "security",
                "전력 배분을 돌려놓자 보안문에 불이 들어왔다. 문 안쪽에서 금속 소리가 난다."
            ],
            [
                "worklog",
                "정비 로그",
                0.53,
                0.74,
                "destination",
                "장거리 탐사용 연료 배분표. 준의 서명이 있지만, 귀환용 계획은 아니다."
            ]
        ]
    },
    "archive": {
        "name": "기록실",
        "points": [
            [
                "terminal",
                "복구 단말",
                0.28,
                0.5,
                "archive",
                "같은 원본에서 복사한 두 파일의 목적지 칸이 다르다. 손상 표시도 없다."
            ],
            [
                "drawer",
                "보관 서랍",
                0.73,
                0.7,
                "destination",
                "지구 귀환 승인서와 새 거주지 이주 명부가 나란히 놓여 있다."
            ],
            [
                "ledger",
                "오래된 항해 일지",
                0.52,
                0.42,
                "arrival",
                "봉인 안쪽에 도착 완료라는 문장이 있다. 날짜는 현재보다 19년 전이다."
            ]
        ]
    },
    "comms": {
        "name": "통신실",
        "points": [
            [
                "receiver",
                "수신기",
                0.3,
                0.53,
                "signal",
                "소렌의 목소리다. 그런데 송신 시각에 소렌의 수면 포드는 열리지 않았다."
            ],
            [
                "console",
                "송신 콘솔",
                0.73,
                0.68,
                "destination",
                "수신처가 지구와 탐사 기지를 번갈아 표시한다. 발송 완료 표시는 둘 다 같다."
            ],
            [
                "backup",
                "신호 저장 장치",
                0.53,
                0.78,
                "archive",
                "신호를 별도로 저장했다. 원본과 사본의 도착 기록은 같은데 좌표가 다르다."
            ]
        ]
    },
    "security": {
        "name": "보안실",
        "points": [
            [
                "door",
                "보안문",
                0.23,
                0.62,
                "security",
                "내부 수동 해제 흔적. 잠금 기록에는 사용자가 없다."
            ],
            [
                "camera",
                "순찰 화면",
                0.67,
                0.45,
                "signal",
                "아무도 지나가지 않는 통로에서 센서가 이름 하나를 기록했다."
            ],
            [
                "card",
                "출입 카드 보관함",
                0.8,
                0.7,
                "archive",
                "사용되지 않은 카드 뒷면에 당신의 이름이 손으로 적혀 있다."
            ]
        ]
    },
    "navigation": {
        "name": "항법실",
        "points": [
            [
                "route",
                "항로 테이블",
                0.46,
                0.7,
                "arrival",
                "ASTRA — 목적지 도착 완료. 완료 시각은 19년 전이다."
            ],
            [
                "glass",
                "관측창",
                0.79,
                0.4,
                "destination",
                "별의 위치가 항로 화면과 맞지 않는다. 화면에는 정상 항해라고 표시된다."
            ],
            [
                "map",
                "보조 항법 기록",
                0.23,
                0.56,
                "archive",
                "귀환과 탐사, 두 항로 모두 같은 지점에서 끝난다. 좌표 이름은 지워져 있다."
            ]
        ]
    },
    "garden": {
        "name": "생태실",
        "points": [
            [
                "bed",
                "발아 실험대",
                0.27,
                0.7,
                "sample",
                "씨앗의 채집일이 출항일보다 앞선다. 채집 장소는 목적지와 같다."
            ],
            [
                "water",
                "급수 조절기",
                0.72,
                0.65,
                "power",
                "몇 구역의 물을 줄이면 수면실 냉각을 유지할 수 있다. 어느 쪽도 여유롭지 않다."
            ],
            [
                "jar",
                "시료 보관함",
                0.54,
                0.46,
                "archive",
                "봉인된 시료의 기록에 당신의 확인 서명이 있다. 기억에는 없는 일이다."
            ]
        ]
    },
    "lounge": {
        "name": "휴게실",
        "points": [
            [
                "cup",
                "식탁",
                0.48,
                0.7,
                "everyday",
                "식탁 위에 아직 따뜻한 컵이 있다. 손잡이는 당신 쪽을 향한다."
            ],
            [
                "bench",
                "긴 의자",
                0.23,
                0.64,
                "everyday",
                "누군가 얇은 담요를 반으로 접어 두었다."
            ],
            [
                "window",
                "작은 창",
                0.78,
                0.45,
                "everyday",
                "창에 비친 실내등이 잠깐 꺼졌다가 돌아온다. 별은 움직이지 않는다."
            ]
        ]
    }
}
const SCENES := [
    {
        "id": "mira_everyday",
        "speaker": "mira",
        "tag": "everyday",
        "action": "의료실한쪽에서 미라가 빈 컵을 치우다가 당신 앞에 물 한 잔을 둔다.",
        "lines": [
            [
                "mira",
                "찬물은 없어요. 이것부터 조금 마셔요."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_work",
        "speaker": "mira",
        "tag": "work",
        "action": "창가쪽에서 미라는 당신의 손목을 잡고 시계를 본다.",
        "lines": [
            [
                "mira",
                "손이 떨리네요. 잠깐 앉아요. 포드는 제가 볼게요."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "mira_trust",
        "speaker": "mira",
        "tag": "trust",
        "action": "기록대앞에서 미라가 장갑을 벗어 당신에게 맡긴다.",
        "lines": [
            [
                "mira",
                "오늘은 손이 잘 안 들어가네요. 잠깐만 잡아 줄래요?"
            ]
        ],
        "choices": [
            {
                "label": "장갑을 대신 받아 든다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 건넨다.",
                "effect": "share"
            },
            {
                "label": "“이따 다시 와서 마저 볼게요.”",
                "effect": "promise"
            },
            {
                "label": "지금은 아무 말도 하지 않는다.",
                "effect": "withhold"
            }
        ]
    },
    {
        "id": "mira_distant",
        "speaker": "mira",
        "tag": "distant",
        "action": "기록을덮으며 미라는 열린 진료 기록을 덮는다.",
        "lines": [
            [
                "mira",
                "다른 사람 기록이에요. 필요한 부분은 제가 옮겨 드릴게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_conflict",
        "speaker": "mira",
        "tag": "conflict",
        "action": "침상곁에서 미라가 당신과 출입문 사이에 선다.",
        "lines": [
            [
                "mira",
                "지금 그 사람을 움직이면 안 돼요. 질문은 여기서 해요."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_suspected",
        "speaker": "mira",
        "tag": "suspected",
        "action": "한참뒤, 미라는 당신이 내민 기록을 끝까지 읽는다.",
        "lines": [
            [
                "mira",
                "제 이름이네요. 제가 확인할게요. 그동안 포드 전원은 끄지 마세요."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "mira_after",
        "speaker": "mira",
        "tag": "after",
        "action": "조용한틈에 미라가 젖은 소매를 걷는다.",
        "lines": [
            [
                "mira",
                "다친 곳부터 보여 주세요. 얘기는 그 다음에 해도 돼요."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_danger",
        "speaker": "mira",
        "tag": "danger",
        "action": "교대직전에 미라가 당신의 팔을 세게 당긴다.",
        "lines": [
            [
                "mira",
                "뒤로. 지금 문 열지 마요."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "mira_relief",
        "speaker": "mira",
        "tag": "relief",
        "action": "의료실문앞에서 미라는 맥박계를 끄고 벽에 등을 붙인다.",
        "lines": [
            [
                "mira",
                "잡혔어요. 이제 손 놓아도 돼요."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_echo",
        "speaker": "mira",
        "tag": "echo",
        "action": "등불아래에서 미라가 컵을 당신의 왼쪽에 놓았다가 잠깐 멈춘다.",
        "lines": [
            [
                "mira",
                "이쪽이 편하죠?"
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "mira_memory",
        "speaker": "mira",
        "tag": "memory",
        "action": "확인을마치고 미라가 예약표를 손가락으로 짚는다.",
        "lines": [
            [
                "mira",
                "귀환 검진이었어요. 제가 직접 날짜를 잡았는데."
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "mira_personal",
        "speaker": "mira",
        "tag": "personal",
        "action": "잠시뒤, 미라가 이름표 한 장을 새로 쓴다. 처음 쓴 것은 접어 주머니에 넣는다.",
        "lines": [
            [
                "mira",
                "그 이름은 지우지 말아 주세요. 아직 연락할 사람이 있어요."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "mira_night",
        "speaker": "mira",
        "tag": "night",
        "action": "복도끝에서 미라가 의자 두 개를 이어 놓는다.",
        "lines": [
            [
                "mira",
                "침대는 비워 둬야 해서요. 여기서 조금만 잘게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_awakening",
        "speaker": "mira",
        "tag": "awakening",
        "action": "작은숨을고르고 미라가 당신의 눈앞에서 손가락 두 개를 움직인다.",
        "lines": [
            [
                "mira",
                "들리나요? 천천히요. 저는 미라예요. 의무관. 당신은 탐사팀에서 왔죠."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_grief",
        "speaker": "mira",
        "tag": "grief",
        "action": "의료실한쪽에서 미라가 한 사람 몫을 더 꺼냈다가 조용히 돌려놓는다.",
        "lines": [
            [
                "mira",
                "식사는 나중에 할게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_everyday",
        "speaker": "rho",
        "tag": "everyday",
        "action": "기관실한쪽에서 준이 렌치를 마이크처럼 들다가 미라의 시선을 보고 내려놓는다.",
        "lines": [
            [
                "rho",
                "공연 끝. 관객 한 명이 너무 엄격해서."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_work",
        "speaker": "rho",
        "tag": "work",
        "action": "공구함앞에서 준이 바닥에 엎드린 채 손을 내민다.",
        "lines": [
            [
                "rho",
                "그거, 파란 손잡이. 아니, 내 손 말고 공구."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "rho_trust",
        "speaker": "rho",
        "tag": "trust",
        "action": "패널아래에서 준이 덜 잠긴 공구함을 당신 쪽으로 민다.",
        "lines": [
            [
                "rho",
                "필요하면 써. 두 번째 서랍은 열지 말고. 간식 있어."
            ]
        ],
        "choices": [
            {
                "label": "공구함을 받아 챙긴다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 보여 준다.",
                "effect": "share"
            },
            {
                "label": "일단 맡아만 둔다.",
                "effect": "keep_copy"
            },
            {
                "label": "두 번째 서랍부터 궁금해서 물어본다.",
                "effect": "confront"
            }
        ]
    },
    {
        "id": "rho_distant",
        "speaker": "rho",
        "tag": "distant",
        "action": "금속음뒤로, 준이 작업대 위의 서류를 자기 쪽으로 당긴다.",
        "lines": [
            [
                "rho",
                "아직 고치는 중이야. 끝나면 같이 보자."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_conflict",
        "speaker": "rho",
        "tag": "conflict",
        "action": "작업등곁에서 준이 웃다가 다렌의 화면을 보고 입을 다문다.",
        "lines": [
            [
                "rho",
                "그 수치로 돌렸어? 잠깐. 일단 멈춰."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_suspected",
        "speaker": "rho",
        "tag": "suspected",
        "action": "정비를멈추고 준이 두 손을 펴 보인다. 손끝에 검은 기름이 묻었다.",
        "lines": [
            [
                "rho",
                "내가 만진 건 맞아. 그래서 언제 만졌는지부터 보자는 거야."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "rho_after",
        "speaker": "rho",
        "tag": "after",
        "action": "환풍구앞에서 준이 바닥에 떨어진 나사를 하나씩 센다.",
        "lines": [
            [
                "rho",
                "하나 모자라. 잠깐만, 지금 켜지 마."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_danger",
        "speaker": "rho",
        "tag": "danger",
        "action": "렌치를내려놓고 준이 공구를 놓고 차단기를 내린다.",
        "lines": [
            [
                "rho",
                "손 떼. 뒤로 가."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "rho_relief",
        "speaker": "rho",
        "tag": "relief",
        "action": "기계소리사이로 준이 바닥에 주저앉는다.",
        "lines": [
            [
                "rho",
                "이제야 배고프네. 너도?"
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_echo",
        "speaker": "rho",
        "tag": "echo",
        "action": "케이블옆에서 준이 공구를 건네며 예전처럼 손잡이 방향을 바꾼다.",
        "lines": [
            [
                "rho",
                "어. 왜 이렇게 줬지."
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "rho_memory",
        "speaker": "rho",
        "tag": "memory",
        "action": "기관실한쪽에서 준이 정비표 뒤에 그려 둔 작은 행성을 보여 준다.",
        "lines": [
            [
                "rho",
                "새 기지에 도착하면 쉬기로 했거든. 지구? 그 얘긴 못 들었는데."
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "rho_personal",
        "speaker": "rho",
        "tag": "personal",
        "action": "공구함앞에서 준이 같은 나사를 세 번째 풀었다 조인다.",
        "lines": [
            [
                "rho",
                "전에 반대로 끼운 적 있어. 누가 다친 건 아니고. 그래서 자꾸 확인하게 돼."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "rho_night",
        "speaker": "rho",
        "tag": "night",
        "action": "패널아래에서 준이 미라의 빈 컵을 챙긴다.",
        "lines": [
            [
                "rho",
                "아직 안 잔다길래. 뜨거운 거라도 갖다 주려고."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_awakening",
        "speaker": "rho",
        "tag": "awakening",
        "action": "기관실 쪽에서 준이 손을 흔든다. 소매 한쪽이 젖어 있다.",
        "lines": [
            [
                "rho",
                "일어났네! 마침 손이 하나 부족했어. 걷는 건 괜찮아?"
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_grief",
        "speaker": "rho",
        "tag": "grief",
        "action": "금속음뒤로, 준이 농담을 시작하려다가 공구함 뚜껑을 닫는다.",
        "lines": [
            [
                "rho",
                "오늘은 내가 할게. 넌 쉬어."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_everyday",
        "speaker": "dax",
        "tag": "everyday",
        "action": "단말앞에서 다렌이 차가운 음료를 한 모금 마시고 컵을 내려놓는다.",
        "lines": [
            [
                "dax",
                "이건 고쳐도 맛은 그대로겠군."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_work",
        "speaker": "dax",
        "tag": "work",
        "action": "계산을멈추고 다렌이 화면 두 개를 나란히 돌려놓는다.",
        "lines": [
            [
                "dax",
                "하나씩은 맞아. 같이 놓으면 틀리지. 어느 쪽부터 볼까."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "dax_trust",
        "speaker": "dax",
        "tag": "trust",
        "action": "그래프옆에서 다렌이 계산 중인 화면을 당신 쪽으로 돌린다.",
        "lines": [
            [
                "dax",
                "여기부터 자신이 없어. 다른 눈이 필요해."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 같이 짚어 본다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 보여 준다.",
                "effect": "share"
            },
            {
                "label": "계산 결과만 따로 적어 둔다.",
                "effect": "keep_copy"
            },
            {
                "label": "처음부터 다시 짚어 보자고 한다.",
                "effect": "confront"
            }
        ]
    },
    {
        "id": "dax_distant",
        "speaker": "dax",
        "tag": "distant",
        "action": "수치를훑다가 다렌이 손을 멈추고 당신을 본다.",
        "lines": [
            [
                "dax",
                "결론을 정하고 온 거면 오늘은 어렵겠어."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_conflict",
        "speaker": "dax",
        "tag": "conflict",
        "action": "화이트보드앞에서 다렌이 준이 그은 선을 지우지 않고 새 선을 옆에 긋는다.",
        "lines": [
            [
                "dax",
                "그 방법도 가능해. 대신 여기서 문제가 생기면 돌아올 수 없어."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_suspected",
        "speaker": "dax",
        "tag": "suspected",
        "action": "잠시화면을끄고 다렌이 기록의 서명을 확대한다.",
        "lines": [
            [
                "dax",
                "내 승인이다. 기억은 안 나지만 없던 일로 할 수는 없지."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "dax_after",
        "speaker": "dax",
        "tag": "after",
        "action": "표를정리하며 다렌이 이미 끝난 검사를 다시 시작한다.",
        "lines": [
            [
                "dax",
                "한 번 더 볼게. 이번엔 내 설정을 빼고."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_danger",
        "speaker": "dax",
        "tag": "danger",
        "action": "센서기록앞에서 다렌이 연결선을 직접 뽑는다.",
        "lines": [
            [
                "dax",
                "중지해. 계산이 맞지 않아."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "dax_relief",
        "speaker": "dax",
        "tag": "relief",
        "action": "숫자를지우고 다렌이 의자를 당겨 당신에게 내준다.",
        "lines": [
            [
                "dax",
                "앉아. 서서 기다리는 건 여기까지 하자."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_echo",
        "speaker": "dax",
        "tag": "echo",
        "action": "창가에서돌아와 다렌이 당신이 말하기 전에 보조 화면을 켠다.",
        "lines": [
            [
                "dax",
                "이걸 찾을 것 같아서."
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "dax_memory",
        "speaker": "dax",
        "tag": "memory",
        "action": "단말앞에서 다렌이 임무서의 봉인을 확인한다.",
        "lines": [
            [
                "dax",
                "탐사 임무였어. 설계를 의뢰받았을 때부터. 이 귀환 승인은 처음 보는데."
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "dax_personal",
        "speaker": "dax",
        "tag": "personal",
        "action": "계산을멈추고 다렌이 오래된 경고 메시지를 닫지 못한다.",
        "lines": [
            [
                "dax",
                "전에도 정상이라고 나온 적이 있었지. 그 말을 너무 빨리 믿었어."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "dax_night",
        "speaker": "dax",
        "tag": "night",
        "action": "그래프옆에서 다렌이 화면 밝기를 낮춘다.",
        "lines": [
            [
                "dax",
                "내일 봐도 돼. 답이 달라지면 그때 문제가 있는 거고."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_awakening",
        "speaker": "dax",
        "tag": "awakening",
        "action": "수치를훑다가 다렌이 의료실 문을 손으로 받치고 있다.",
        "lines": [
            [
                "dax",
                "자동문은 아직 믿지 마. 걸어 나올 수 있겠어?"
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_grief",
        "speaker": "dax",
        "tag": "grief",
        "action": "화이트보드앞에서 다렌이 빈 의자의 화면을 꺼 준다.",
        "lines": [
            [
                "dax",
                "이 자리는 비워 두자. 당분간."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_everyday",
        "speaker": "noa",
        "tag": "everyday",
        "action": "기록보관실에서 노아가 바닥의 메모를 주워 반듯하게 편다.",
        "lines": [
            [
                "noa",
                "뒷면도 썼네요. 버리면 안 되겠어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_work",
        "speaker": "noa",
        "tag": "work",
        "action": "페이지를넘기다 노아가 두 문장의 끝에 작은 선을 긋는다.",
        "lines": [
            [
                "noa",
                "여기만 달라요. 날짜는 같고요."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "noa_trust",
        "speaker": "noa",
        "tag": "trust",
        "action": "메모끝에서 노아가 아직 저장하지 않은 메모를 보여 준다.",
        "lines": [
            [
                "noa",
                "이건 제 생각이에요. 기록하고는 따로 봐 주세요."
            ]
        ],
        "choices": [
            {
                "label": "메모를 함께 읽는다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 보여 준다.",
                "effect": "share"
            },
            {
                "label": "따로 사본을 남겨 둔다.",
                "effect": "keep_copy"
            },
            {
                "label": "지금은 의견을 말하지 않는다.",
                "effect": "withhold"
            }
        ]
    },
    {
        "id": "noa_distant",
        "speaker": "noa",
        "tag": "distant",
        "action": "시간표앞에서 노아가 단말을 끄지 않은 채 화면을 아래로 돌린다.",
        "lines": [
            [
                "noa",
                "지금은 정리 중이에요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_conflict",
        "speaker": "noa",
        "tag": "conflict",
        "action": "문장을고치다 노아가 다렌의 말을 적다가 멈춘다.",
        "lines": [
            [
                "noa",
                "아까는 확인했다고 했어요. 지금은 추정이라고 했고요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_suspected",
        "speaker": "noa",
        "tag": "suspected",
        "action": "자료실한쪽에서 노아가 빈 줄을 한 칸 남긴다.",
        "lines": [
            [
                "noa",
                "제 말도 그대로 적어 주세요. 빠뜨리지 말고."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "noa_after",
        "speaker": "noa",
        "tag": "after",
        "action": "두기록사이에서 노아가 젖은 종이를 말린다.",
        "lines": [
            [
                "noa",
                "뒤쪽은 남았어요. 다 지워진 건 아니에요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_danger",
        "speaker": "noa",
        "tag": "danger",
        "action": "연필을멈추고 노아가 단말을 품에 안고 문에서 물러난다.",
        "lines": [
            [
                "noa",
                "소리가 두 번 났어요. 안쪽에서도."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "noa_relief",
        "speaker": "noa",
        "tag": "relief",
        "action": "로그를읽다가 노아가 저장 버튼을 누른 뒤에야 숨을 내쉰다.",
        "lines": [
            [
                "noa",
                "됐어요. 사본이 있어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_echo",
        "speaker": "noa",
        "tag": "echo",
        "action": "종이를펴며 노아가 당신이 쓰던 빈 의자를 비워 둔다.",
        "lines": [
            [
                "noa",
                "거기 앉으세요."
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "noa_memory",
        "speaker": "noa",
        "tag": "memory",
        "action": "기록보관실에서 노아가 서로 다른 명부를 나란히 놓는다.",
        "lines": [
            [
                "noa",
                "둘 다 원본이에요. 누구 말이 틀렸다고 적어야 할지 모르겠어요."
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "noa_personal",
        "speaker": "noa",
        "tag": "personal",
        "action": "페이지를넘기다 노아가 문장 하나를 지우려다 손을 멈춘다.",
        "lines": [
            [
                "noa",
                "제가 쓴 말인데, 쓴 기억이 없어요. 지우면 더 모르겠죠."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "noa_night",
        "speaker": "noa",
        "tag": "night",
        "action": "메모끝에서 노아가 글씨가 번진 책갈피를 바꾼다.",
        "lines": [
            [
                "noa",
                "잘 자요. 오늘 날짜는 여기 적어 둘게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_awakening",
        "speaker": "noa",
        "tag": "awakening",
        "action": "시간표앞에서 노아가 당신의 이름 아래에 작은 점을 찍는다.",
        "lines": [
            [
                "noa",
                "한 명 더 깨어났어요. 네, 당신까지 다섯 명."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_grief",
        "speaker": "noa",
        "tag": "grief",
        "action": "문장을고치다 노아가 다음 줄을 비워 두었다.",
        "lines": [
            [
                "noa",
                "마지막 말을 못 들었어요. 빈칸으로 둘게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_everyday",
        "speaker": "sena",
        "tag": "everyday",
        "action": "보안실앞에서 세나가 벽에 등을 대고 준과 손 크기를 비교한다.",
        "lines": [
            [
                "sena",
                "한 번만 더 해. 방금은 네가 먼저 움직였어."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_work",
        "speaker": "sena",
        "tag": "work",
        "action": "순찰을멈추고 세나가 문 안쪽 손잡이를 먼저 당긴다.",
        "lines": [
            [
                "sena",
                "밖에서 잠겨도 안에서는 열려야 해. 이것부터 보자."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "sena_trust",
        "speaker": "sena",
        "tag": "trust",
        "action": "출입문곁에서 세나가 당신에게 여분의 출입 카드를 건넨다.",
        "lines": [
            [
                "sena",
                "내가 늦으면 기다리지 말고 이걸 써."
            ]
        ],
        "choices": [
            {
                "label": "카드를 받아 챙긴다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 보여 준다.",
                "effect": "share"
            },
            {
                "label": "카드는 맡아만 두고 쓰지 않는다.",
                "effect": "keep_copy"
            },
            {
                "label": "왜 늦을 것 같은지 물어본다.",
                "effect": "confront"
            }
        ]
    },
    {
        "id": "sena_distant",
        "speaker": "sena",
        "tag": "distant",
        "action": "카드를확인하다 세나가 막힌 통로 앞에서 고개를 젓는다.",
        "lines": [
            [
                "sena",
                "혼자는 못 보내. 내가 확인하고 올게."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_conflict",
        "speaker": "sena",
        "tag": "conflict",
        "action": "복도끝에서서 세나가 준을 따라 통로로 들어선다.",
        "lines": [
            [
                "sena",
                "고칠 수 있는 건 알아. 나올 길부터 만들자고."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_suspected",
        "speaker": "sena",
        "tag": "suspected",
        "action": "경보등아래에서 세나가 순찰표를 내려놓는다.",
        "lines": [
            [
                "sena",
                "내가 지웠다고? 좋아. 원본이 어디 있는지 같이 가자."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "sena_after",
        "speaker": "sena",
        "tag": "after",
        "action": "순찰지도앞에서 세나가 모든 문을 한 번씩 다시 당겨 본다.",
        "lines": [
            [
                "sena",
                "나가는 쪽은 열어 뒀어. 기억해 둬."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_danger",
        "speaker": "sena",
        "tag": "danger",
        "action": "문을닫으며 세나가 당신을 등 뒤로 밀어 넣는다.",
        "lines": [
            [
                "sena",
                "내 뒤에 있어. 뛰라고 하면 뛰어."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "sena_relief",
        "speaker": "sena",
        "tag": "relief",
        "action": "기록을훑다가 세나가 당신의 어깨를 가볍게 친다.",
        "lines": [
            [
                "sena",
                "잘 따라왔네. 다친 데는?"
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_echo",
        "speaker": "sena",
        "tag": "echo",
        "action": "발소리를멈추고 세나가 당신이 움찔하자 먼저 손을 뻗었다가 거둔다.",
        "lines": [
            [
                "sena",
                "미안. 너무 빨랐지."
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "sena_memory",
        "speaker": "sena",
        "tag": "memory",
        "action": "보안실앞에서 세나가 준을 향해 낡은 순찰표를 펼친다.",
        "lines": [
            [
                "sena",
                "우리 같이 했잖아. 이때도 네가 늦었고. 기억 안 나?"
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "sena_personal",
        "speaker": "sena",
        "tag": "personal",
        "action": "순찰을멈추고 세나가 잠긴 문 너머를 오래 본다.",
        "lines": [
            [
                "sena",
                "그때는 안에 아무도 없다고 했어. 이번엔 직접 볼 거야."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "sena_night",
        "speaker": "sena",
        "tag": "night",
        "action": "출입문곁에서 세나가 의자 대신 출입문 옆에 앉는다.",
        "lines": [
            [
                "sena",
                "거기가 잘 보여. 졸리면 교대해 줘."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_awakening",
        "speaker": "sena",
        "tag": "awakening",
        "action": "포드가 열리자 세나는 눈을 뜨자마자 주변보다 꺼진 보안등을 먼저 본다.",
        "lines": [
            ["mira","천천히 일어나요. 아직 다리에 힘이 안 들어갈 거예요."],
            ["sena","보안등 왜 꺼져 있어?"],
            ["rho","일어나자마자 그거부터 보냐."],
            ["sena","…준. 너 여기 있었네."]
        ],
        "choices": []
    },
    {
        "id": "sena_grief",
        "speaker": "sena",
        "tag": "grief",
        "action": "카드를확인하다 세나가 가져온 물 두 병 중 하나를 내려놓는다.",
        "lines": [
            [
                "sena",
                "한 병 더 챙겼네. 습관이 돼서."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_everyday",
        "speaker": "vale",
        "tag": "everyday",
        "action": "통신실한쪽에서 소렌이 이어폰 한쪽을 빼 책 위에 올려놓는다.",
        "lines": [
            [
                "vale",
                "음악이에요. 오늘은 잡음 말고 다른 게 듣고 싶어서."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_work",
        "speaker": "vale",
        "tag": "work",
        "action": "파형앞에서 소렌이 손을 들어 조용히 해 달라는 표시를 한다.",
        "lines": [
            [
                "vale",
                "한 번만 더. 방금 숨소리가 있었어요."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "vale_trust",
        "speaker": "vale",
        "tag": "trust",
        "action": "이어폰을빼며 소렌이 말없이 이어폰 한쪽을 당신에게 건넨다.",
        "lines": [
            [
                "vale",
                "여기부터 같이 들어요."
            ]
        ],
        "choices": [
            {
                "label": "이어폰을 받아 함께 듣는다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 보여 준다.",
                "effect": "share"
            },
            {
                "label": "들은 구간을 따로 저장해 둔다.",
                "effect": "keep_copy"
            },
            {
                "label": "무슨 소리인지 지금은 묻지 않는다.",
                "effect": "withhold"
            }
        ]
    },
    {
        "id": "vale_distant",
        "speaker": "vale",
        "tag": "distant",
        "action": "신호를되감다 소렌이 녹음을 멈춘다.",
        "lines": [
            [
                "vale",
                "정리가 되면 말할게요. 지금은 잘 모르겠어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_conflict",
        "speaker": "vale",
        "tag": "conflict",
        "action": "잡음사이에서 소렌이 루칸의 항로 화면을 가리킨다.",
        "lines": [
            [
                "vale",
                "그쪽에서 온 게 아니에요. 배 안쪽이에요."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_suspected",
        "speaker": "vale",
        "tag": "suspected",
        "action": "재생을멈추고 소렌이 자기 목소리가 녹음된 구간을 다시 튼다.",
        "lines": [
            [
                "vale",
                "제 목소리예요. 그런데 이 말을 한 적은 없어요."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "vale_after",
        "speaker": "vale",
        "tag": "after",
        "action": "통신단말곁에서 소렌이 케이블을 손가락에 감았다가 푼다.",
        "lines": [
            [
                "vale",
                "다시 들어왔어요. 전원을 끈 뒤에도."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_danger",
        "speaker": "vale",
        "tag": "danger",
        "action": "볼륨을낮추며 소렌이 수신 음량을 내린다.",
        "lines": [
            [
                "vale",
                "대답하지 마요. 아직."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "vale_relief",
        "speaker": "vale",
        "tag": "relief",
        "action": "녹음앞에서 소렌이 이어폰을 벗는다.",
        "lines": [
            [
                "vale",
                "이번 건 바깥 소리예요. 확실해요."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_echo",
        "speaker": "vale",
        "tag": "echo",
        "action": "소리를세다가 소렌이 당신에게 맞춰 이어폰 줄을 한 칸 늘려 둔다.",
        "lines": [
            [
                "vale",
                "짧을 것 같아서요."
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "vale_memory",
        "speaker": "vale",
        "tag": "memory",
        "action": "통신실한쪽에서 소렌이 목적지 호출 부호를 적는다.",
        "lines": [
            [
                "vale",
                "여기로 오라고 했어요. 지구 호출 부호는 아니에요."
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "vale_personal",
        "speaker": "vale",
        "tag": "personal",
        "action": "파형앞에서 소렌이 재생 버튼 위에 손을 올린다.",
        "lines": [
            [
                "vale",
                "그때 들었어요. 아무에게도 말 안 했고요. 이번에는 같이 들어 줘요."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "vale_night",
        "speaker": "vale",
        "tag": "night",
        "action": "이어폰을빼며 소렌이 스피커를 아주 작게 켜 둔다.",
        "lines": [
            [
                "vale",
                "너무 조용하면 잠이 안 와요."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_awakening",
        "speaker": "vale",
        "tag": "awakening",
        "action": "포드가 열리자 소렌은 눈을 뜨기 전에 고개를 통신실 쪽으로 돌린다.",
        "lines": [
            ["mira","소렌, 제 목소리 들려요?"],
            ["vale","네. 그런데 그 전에 다른 소리가 먼저 들렸어요."],
            ["noa","지금 통신 채널은 닫혀 있어요."],
            ["vale","그래서 이상해요. 아직도 들려요."]
        ],
        "choices": []
    },
    {
        "id": "vale_grief",
        "speaker": "vale",
        "tag": "grief",
        "action": "신호를되감다 소렌이 음성 파일을 복사하고 원본을 다시 잠근다.",
        "lines": [
            [
                "vale",
                "목소리는 남겨 둘게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_everyday",
        "speaker": "eli",
        "tag": "everyday",
        "action": "항법실앞에서 루칸이 의자를 창 쪽으로 돌렸다가 통로가 보이게 다시 놓는다.",
        "lines": [
            [
                "eli",
                "거긴 눈부셔. 이쪽이 낫다."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_work",
        "speaker": "eli",
        "tag": "work",
        "action": "별지도곁에서 루칸이 항로 위에 손을 얹는다.",
        "lines": [
            [
                "eli",
                "계기 말고 창밖부터 봐. 같은 별인지."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "eli_trust",
        "speaker": "eli",
        "tag": "trust",
        "action": "좌표를맞추다 루칸이 당신을 관측창 옆으로 부른다.",
        "lines": [
            [
                "eli",
                "이 자리에서 봐 줘. 내 눈만 믿기는 어려워."
            ]
        ],
        "choices": [
            {
                "label": "옆에 서서 같이 본다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 보여 준다.",
                "effect": "share"
            },
            {
                "label": "본 것을 그림으로 남겨 둔다.",
                "effect": "keep_copy"
            },
            {
                "label": "뭐가 이상한지 먼저 물어본다.",
                "effect": "confront"
            }
        ]
    },
    {
        "id": "eli_distant",
        "speaker": "eli",
        "tag": "distant",
        "action": "항법창에서돌아와 루칸이 화면을 축소해 전체 항로를 띄운다.",
        "lines": [
            [
                "eli",
                "그 구간만 보면 안 돼. 끝까지 확인한 다음에 말하자."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_conflict",
        "speaker": "eli",
        "tag": "conflict",
        "action": "항로화면앞에서 루칸이 소렌의 신호 도착 방향에 선을 긋는다.",
        "lines": [
            [
                "eli",
                "그 방향이면 우리가 지나온 곳이야."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_suspected",
        "speaker": "eli",
        "tag": "suspected",
        "action": "보정값을보다 루칸이 항로 수정 기록을 연다.",
        "lines": [
            [
                "eli",
                "내가 바꿨어. 피해야 할 게 있었다."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "eli_after",
        "speaker": "eli",
        "tag": "after",
        "action": "지도를펼치며 루칸이 빈 포드의 번호를 확인한다.",
        "lines": [
            [
                "eli",
                "위치가 달라. 내가 기억하는 배열하고."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_danger",
        "speaker": "eli",
        "tag": "danger",
        "action": "경로를멈추고 루칸이 당신의 발앞을 가리킨다.",
        "lines": [
            [
                "eli",
                "멈춰. 그 너머는 바닥이 없어."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "eli_relief",
        "speaker": "eli",
        "tag": "relief",
        "action": "별빛아래에서 루칸이 손잡이에서 천천히 손을 뗀다.",
        "lines": [
            [
                "eli",
                "통과했어. 이제 돌아갈 수 있다."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_echo",
        "speaker": "eli",
        "tag": "echo",
        "action": "항법로그옆에서 루칸이 좁은 통로에서 당신이 설 자리를 미리 비운다.",
        "lines": [
            [
                "eli",
                "여기 잡아."
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "eli_memory",
        "speaker": "eli",
        "tag": "memory",
        "action": "항법실앞에서 루칸이 도착 기록을 확대한다.",
        "lines": [
            [
                "eli",
                "도착했어. 이 날짜가 맞으면. 그럼 지금 항로는 뭐지."
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "eli_personal",
        "speaker": "eli",
        "tag": "personal",
        "action": "별지도곁에서 루칸이 우회 항로를 지우려다 사본을 만든다.",
        "lines": [
            [
                "eli",
                "다른 길이 있었을까. 그때는 없다고 생각했어."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "eli_night",
        "speaker": "eli",
        "tag": "night",
        "action": "좌표를맞추다 루칸이 아무도 없는 수면실 문을 조금 열어 본다.",
        "lines": [
            [
                "eli",
                "확인만 하고 갈 거야."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_awakening",
        "speaker": "eli",
        "tag": "awakening",
        "action": "포드 문이 완전히 열리기 전에 루칸의 시선이 항법 화면부터 찾는다.",
        "lines": [
            ["mira","루칸, 먼저 상태부터 확인할게요."],
            ["eli","상태는 걷다가 봐. 지금 항로가 어디야?"],
            ["dax","기록상으로는 정상 항해 중이야."],
            ["eli","기록 말고 화면 띄워. 별 위치부터 볼게."]
        ],
        "choices": []
    },
    {
        "id": "eli_grief",
        "speaker": "eli",
        "tag": "grief",
        "action": "항법창에서돌아와 루칸이 항로 화면에서 한 지점을 오래 바라본다.",
        "lines": [
            [
                "eli",
                "여긴 다음에 같이 보기로 했는데."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_everyday",
        "speaker": "lyra",
        "tag": "everyday",
        "action": "온실한쪽에서 마렌이 작은 화분을 당신 쪽으로 돌린다.",
        "lines": [
            [
                "lyra",
                "새 잎이에요! 어제는 없었거든요. 한번 봐요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_work",
        "speaker": "lyra",
        "tag": "work",
        "action": "재배대앞에서 마렌이 급수 밸브를 반쯤 잠근다.",
        "lines": [
            [
                "lyra",
                "이쪽은 줄여야 해요. 포드 냉각에 물이 더 필요해요."
            ]
        ],
        "choices": [
            {
                "label": "옆에서 도구를 잡아 준다.",
                "effect": "help"
            },
            {
                "label": "먼저 기록을 확인한다.",
                "effect": "record"
            }
        ]
    },
    {
        "id": "lyra_trust",
        "speaker": "lyra",
        "tag": "trust",
        "action": "잎사이로 마렌이 발아한 씨앗을 당신 손바닥에 얹는다.",
        "lines": [
            [
                "lyra",
                "꽉 쥐지 말고요. 따뜻한 쪽에 놓아 줄래요?"
            ]
        ],
        "choices": [
            {
                "label": "씨앗을 받아 자리를 찾아 준다.",
                "effect": "help"
            },
            {
                "label": "지금 확인한 기록을 보여 준다.",
                "effect": "share"
            },
            {
                "label": "“이따 상태를 다시 보러 올게요.”",
                "effect": "promise"
            },
            {
                "label": "지금은 손바닥 위에 가만히 둔다.",
                "effect": "withhold"
            }
        ]
    },
    {
        "id": "lyra_distant",
        "speaker": "lyra",
        "tag": "distant",
        "action": "표본을살피다 마렌이 시료 상자를 두 손으로 받친다.",
        "lines": [
            [
                "lyra",
                "가져가려면 어디에 쓸지 먼저 알려 줘요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_conflict",
        "speaker": "lyra",
        "tag": "conflict",
        "action": "물주기를멈추고 마렌이 미라 앞에 급수표를 놓는다.",
        "lines": [
            [
                "lyra",
                "한 구역은 포기해야 해요. 제가 고를게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_suspected",
        "speaker": "lyra",
        "tag": "suspected",
        "action": "습도계옆에서 마렌이 잘라 낸 줄기를 보여 준다.",
        "lines": [
            [
                "lyra",
                "제가 했어요. 병든 부분을 남겨 두면 옆까지 옮아요."
            ]
        ],
        "choices": [
            {
                "label": "“그 시각부터 다시 보자.”",
                "effect": "record"
            },
            {
                "label": "다른 사람 앞에서도 같은 말을 해 준다.",
                "effect": "defend"
            }
        ]
    },
    {
        "id": "lyra_after",
        "speaker": "lyra",
        "tag": "after",
        "action": "흙을털며 마렌이 쓰러진 화분을 세우다 손을 멈춘다.",
        "lines": [
            [
                "lyra",
                "뿌리는 살아 있어요. 아직 버리지 말아요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_danger",
        "speaker": "lyra",
        "tag": "danger",
        "action": "조명아래에서 마렌이 당신의 손에서 뚜껑을 뺏는다.",
        "lines": [
            [
                "lyra",
                "열지 마요. 냄새 맡으면 안 돼요."
            ]
        ],
        "choices": [
            {
                "label": "함께 물러난다.",
                "effect": "help"
            }
        ]
    },
    {
        "id": "lyra_relief",
        "speaker": "lyra",
        "tag": "relief",
        "action": "배양통앞에서 마렌이 마른 흙에 물 한 방울을 떨군다.",
        "lines": [
            [
                "lyra",
                "이만큼이면 돼요. 생각보다 오래 버텨요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_echo",
        "speaker": "lyra",
        "tag": "echo",
        "action": "작은화분곁에서 마렌이 당신 앞에 늘 놓던 작은 화분을 옮겨 둔다.",
        "lines": [
            [
                "lyra",
                "여기가 어울릴 것 같아서요."
            ]
        ],
        "choices": [
            {
                "label": "말없이 자리를 지킨다.",
                "effect": "wait"
            }
        ]
    },
    {
        "id": "lyra_memory",
        "speaker": "lyra",
        "tag": "memory",
        "action": "온실한쪽에서 마렌이 씨앗 봉투의 채집지를 읽는다.",
        "lines": [
            [
                "lyra",
                "여기서 가져왔어요. 가 본 곳이에요. 그런데 아직 가는 중이라고요?"
            ]
        ],
        "choices": [
            {
                "label": "기억과 기록을 나란히 적는다.",
                "effect": "record"
            },
            {
                "label": "다른 사람에게도 보여 준다.",
                "effect": "share"
            },
            {
                "label": "아직 혼자 갖고 있는다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "lyra_personal",
        "speaker": "lyra",
        "tag": "personal",
        "action": "재배대앞에서 마렌이 시든 잎을 떼지 못하고 가위만 닦는다.",
        "lines": [
            [
                "lyra",
                "알아요. 잘라야 하는 거. 조금만 더 보고요."
            ]
        ],
        "choices": [
            {
                "label": "곁에 앉아 기다린다.",
                "effect": "wait"
            },
            {
                "label": "“그때 기록, 같이 볼까요?”",
                "effect": "record"
            }
        ]
    },
    {
        "id": "lyra_night",
        "speaker": "lyra",
        "tag": "night",
        "action": "잎사이로 마렌이 생태실 등을 하나씩 끈다.",
        "lines": [
            [
                "lyra",
                "얘들도 밤이 있어야 해요. 우리도 그렇고요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_awakening",
        "speaker": "lyra",
        "tag": "awakening",
        "action": "마렌은 포드에서 몸을 일으키자 자신의 손보다 먼저 유리 너머 생태 구역을 확인한다.",
        "lines": [
            ["mira","마렌, 어지럽지 않아요?"],
            ["lyra","괜찮아요. 온실 조명은 왜 저래요?"],
            ["noa","몇 번 꺼졌다 켜졌어요. 기록은 남아 있어요."],
            ["lyra","그럼 시료부터 볼게요. 저건 제가 잠들기 전 배치랑 달라요."]
        ],
        "choices": []
    },
    {
        "id": "lyra_grief",
        "speaker": "lyra",
        "tag": "grief",
        "action": "표본을살피다 마렌이 아무 이름도 쓰지 않은 화분을 창가에 둔다.",
        "lines": [
            [
                "lyra",
                "여기 두고 갈게요. 잘 보이는 곳에."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_0",
        "speaker": "rho",
        "target": "mira",
        "tag": "pair",
        "action": "작업등곁에서 준이 미라의 컵을 슬쩍 들어 본다.",
        "lines": [
            [
                "rho",
                "이거 또 다 식었네. 새로 줄까?"
            ],
            [
                "mira",
                "네 것도 식었어요. 둘 다 마시고 일해요."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_1",
        "speaker": "dax",
        "target": "noa",
        "tag": "pair",
        "action": "자료실한쪽에서 노아가 다렌의 단말 옆에 종이를 붙인다.",
        "lines": [
            [
                "dax",
                "종이가 더 믿음직한가?"
            ],
            [
                "noa",
                "지워지면 자국은 남으니까요."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_2",
        "speaker": "sena",
        "target": "rho",
        "tag": "pair",
        "action": "복도끝에서서 세나가 준보다 먼저 공구함을 집어 든다.",
        "lines": [
            [
                "sena",
                "오늘은 내가 먼저야."
            ],
            [
                "rho",
                "무거운 쪽 들고 먼저 가는 건 반칙 아냐?"
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_3",
        "speaker": "vale",
        "target": "eli",
        "tag": "pair",
        "action": "잡음사이에서 소렌이 짧은 신호를 틀자 루칸이 창을 본다.",
        "lines": [
            [
                "vale",
                "배 안에서 왔어요."
            ],
            [
                "eli",
                "그럼 밖을 보던 게 틀렸군. 다시 보자."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_4",
        "speaker": "lyra",
        "target": "mira",
        "tag": "pair",
        "action": "물주기를멈추고 마렌이 의료실에 새 화분을 놓는다.",
        "lines": [
            [
                "lyra",
                "이번 건 물 자주 안 줘도 돼요."
            ],
            [
                "mira",
                "저보다 잘 챙겨 주네요. 고마워요."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_5",
        "speaker": "rho",
        "target": "noa",
        "tag": "pair",
        "action": "정비를멈추고 준이 부품 상자에 서툰 글씨로 이름을 적는다.",
        "lines": [
            [
                "rho",
                "이번엔 읽을 수 있지?"
            ],
            [
                "noa",
                "거꾸로 붙였어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_6",
        "speaker": "dax",
        "target": "rho",
        "tag": "pair",
        "action": "잠시화면을끄고 다렌이 준의 배선 옆에 다른 선을 놓는다.",
        "lines": [
            [
                "dax",
                "이쪽으로 돌리면 네 손이 덜 데겠지."
            ],
            [
                "rho",
                "다음엔 처음부터 말해 줘. 그래도 고마워."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_7",
        "speaker": "noa",
        "target": "mira",
        "tag": "pair",
        "action": "기록대앞에서 미라가 잠든 노아의 손에서 단말을 받는다.",
        "lines": [
            [
                "noa",
                "저장했어요. 조금 자요."
            ],
            [
                "mira",
                "마지막 줄만요. 아니, 됐어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_8",
        "speaker": "sena",
        "target": "dax",
        "tag": "pair",
        "action": "경보등아래에서 세나가 멈춘 자동문을 발로 받친다.",
        "lines": [
            [
                "sena",
                "이 상태로 얼마나 버텨야 해?"
            ],
            [
                "dax",
                "내가 빨리 고칠 만큼은. 발은 다치지 말고."
            ]
        ],
        "choices": []
    },
    {
        "id": "pair_9",
        "speaker": "lyra",
        "target": "eli",
        "tag": "pair",
        "action": "항로화면앞에서 루칸이 화분을 창가에서 옮긴다.",
        "lines": [
            [
                "lyra",
                "빛 때문에 옮긴 거예요?"
            ],
            [
                "eli",
                "항로 화면을 가려서. 이쪽도 빛은 들어와."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_apology",
        "speaker": "mira",
        "tag": "apology",
        "action": "침상곁에서 미라가 구겨진 처방전을 펴 놓는다.",
        "lines": [
            [
                "mira",
                "아까는 제가 먼저 결정했네요. 어디가 불편한지 다시 말해 줄래요?"
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_request",
        "speaker": "mira",
        "tag": "request",
        "action": "조용한틈에 미라가 빈 의자를 발로 당긴다.",
        "lines": [
            [
                "mira",
                "팔을 잠깐 받쳐 줘요. 바늘이 흔들려서요."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "mira_defense",
        "speaker": "mira",
        "tag": "defense",
        "action": "교대직전에 미라가 동료의 손을 펼쳐 보인다.",
        "lines": [
            [
                "mira",
                "이 손으로는 그 밸브를 못 돌려요. 먼저 부상 기록을 봐요."
            ]
        ],
        "choices": []
    },
    {
        "id": "mira_secret",
        "speaker": "mira",
        "tag": "secret",
        "action": "손을씻고나서 미라는 의료 서류 한 장을 따로 접는다.",
        "lines": [
            [
                "mira",
                "진단이 바뀌었어요. 제가 처음 적은 걸 지우지는 않았어요."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "mira_observation",
        "speaker": "mira",
        "tag": "observation",
        "action": "등불아래에서 미라가 당신이 손목을 만지는 것을 보고 멈춘다.",
        "lines": [
            [
                "mira",
                "자국이 남아 있나요? 저는 붙인 기억이 있는데."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_apology",
        "speaker": "rho",
        "tag": "apology",
        "action": "환풍구앞에서 준이 공구 손잡이를 닦아 내민다.",
        "lines": [
            [
                "rho",
                "장난칠 때 아니었지. 미안. 이제 제대로 들을게."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_request",
        "speaker": "rho",
        "tag": "request",
        "action": "렌치를내려놓고 준이 떨어진 나사를 손으로 가리킨다.",
        "lines": [
            [
                "rho",
                "거기 하나만 주워 줘. 지금 손 놓으면 다시 처음부터야."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "rho_defense",
        "speaker": "rho",
        "tag": "defense",
        "action": "기계소리사이로 준이 장갑을 벗어 작업대를 짚는다.",
        "lines": [
            [
                "rho",
                "이 선은 내가 빼 달랬어. 고친 사람한테 뒤집어씌우지 마."
            ]
        ],
        "choices": []
    },
    {
        "id": "rho_secret",
        "speaker": "rho",
        "tag": "secret",
        "action": "케이블옆에서 준이 대장에 빠진 번호를 적는다.",
        "lines": [
            [
                "rho",
                "예비 부품 하나 빌렸어. 돌려놓으면 모를 줄 알았지."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "rho_observation",
        "speaker": "rho",
        "tag": "observation",
        "action": "기관실한쪽에서 준이 발소리를 멈추고 바닥에 귀를 댄다.",
        "lines": [
            [
                "rho",
                "진동이 두 번 와. 펌프는 하나인데."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_apology",
        "speaker": "dax",
        "tag": "apology",
        "action": "표를정리하며 다렌이 계산에 그은 줄을 보여 준다.",
        "lines": [
            [
                "dax",
                "네 쪽이 맞았어. 내가 전제를 잘못 잡았네."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_request",
        "speaker": "dax",
        "tag": "request",
        "action": "센서기록앞에서 다렌이 두 창을 띄워 놓고 뒤로 물러난다.",
        "lines": [
            [
                "dax",
                "먼저 읽어 봐. 내가 설명하면 같은 데서 틀릴 것 같아."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "dax_defense",
        "speaker": "dax",
        "tag": "defense",
        "action": "숫자를지우고 다렌이 승인 목록을 끝까지 내린다.",
        "lines": [
            [
                "dax",
                "이 설정은 내 권한으로 바뀌었어. 그 사람한테 물어도 답은 없어."
            ]
        ],
        "choices": []
    },
    {
        "id": "dax_secret",
        "speaker": "dax",
        "tag": "secret",
        "action": "다렌은 오래된 진단 파일을 닫지 않는다.",
        "lines": [
            [
                "dax",
                "허가 전에 실행했어. 내가 만든 오류인지 먼저 알고 싶었거든."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "dax_observation",
        "speaker": "dax",
        "tag": "observation",
        "action": "창가에서돌아와 다렌이 비어 있는 칸에 손가락을 올린다.",
        "lines": [
            [
                "dax",
                "지워진 게 아니네. 처음부터 값이 없었어."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_apology",
        "speaker": "noa",
        "tag": "apology",
        "action": "두기록사이에서 노아가 잘못 붙인 이름표를 떼어 낸다.",
        "lines": [
            [
                "noa",
                "제가 순서를 바꿔 적었어요. 원래 메모도 남길게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_request",
        "speaker": "noa",
        "tag": "request",
        "action": "연필을멈추고 노아가 녹음을 멈춘다.",
        "lines": [
            [
                "noa",
                "마지막 단어를 다시 말해 줄래요? 추측해서 적고 싶지 않아요."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "noa_defense",
        "speaker": "noa",
        "tag": "defense",
        "action": "로그를읽다가 노아가 앞선 대화의 한 줄을 가리킨다.",
        "lines": [
            [
                "noa",
                "이 사람은 그렇게 말하지 않았어요. 그대로 읽어 볼게요."
            ]
        ],
        "choices": []
    },
    {
        "id": "noa_secret",
        "speaker": "noa",
        "tag": "secret",
        "action": "종이를펴며 노아가 자기 배치 기록을 꺼낸다.",
        "lines": [
            [
                "noa",
                "제 것부터 확인했어요. 다른 사람보다 먼저요."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "noa_observation",
        "speaker": "noa",
        "tag": "observation",
        "action": "노아는 말이 나오기 전에 빈칸을 하나 만들어 둔다.",
        "lines": [
            [
                "noa",
                "여기서 말을 멈출 것 같았어요. 왜인지는 모르겠어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_apology",
        "speaker": "sena",
        "tag": "apology",
        "action": "순찰지도앞에서 세나가 통로를 비켜 선다.",
        "lines": [
            [
                "sena",
                "내가 너무 빨랐어. 같이 보고 결정하자."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_request",
        "speaker": "sena",
        "tag": "request",
        "action": "문을닫으며 세나가 문을 받친 채 손을 뻗는다.",
        "lines": [
            [
                "sena",
                "안쪽 센서만 봐 줘. 문은 내가 잡고 있을게."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "sena_defense",
        "speaker": "sena",
        "tag": "defense",
        "action": "기록을훑다가 세나가 출입 기록을 돌려 보여 준다.",
        "lines": [
            [
                "sena",
                "내가 통과시켰어. 이유는 나한테 물어."
            ]
        ],
        "choices": []
    },
    {
        "id": "sena_secret",
        "speaker": "sena",
        "tag": "secret",
        "action": "세나는 순찰 메모의 빈 줄을 채운다.",
        "lines": [
            [
                "sena",
                "아무것도 없는데 소리가 났어. 잘못 들었다고 말하기 싫었고."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "sena_observation",
        "speaker": "sena",
        "tag": "observation",
        "action": "발소리를멈추고 세나가 당신보다 먼저 모퉁이에서 멈춘다.",
        "lines": [
            [
                "sena",
                "또 왼쪽으로 돌 뻔했네. 이쪽은 처음인데."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_apology",
        "speaker": "vale",
        "tag": "apology",
        "action": "재생을멈추고 소렌이 헤드폰 한쪽을 당신에게 건넨다.",
        "lines": [
            [
                "vale",
                "혼자 듣고 결론을 냈어요. 같이 들어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_request",
        "speaker": "vale",
        "tag": "request",
        "action": "통신단말곁에서 소렌이 재생 표시를 가리킨다.",
        "lines": [
            [
                "vale",
                "제가 손을 들면 멈춰 줘요. 같은 소리가 들리는지 보고 싶어요."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "vale_defense",
        "speaker": "vale",
        "tag": "defense",
        "action": "볼륨을낮추며 소렌이 두 음성을 나란히 재생한다.",
        "lines": [
            [
                "vale",
                "목소리만으로 정하면 안 돼요. 같은 녹음일 수도 있어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "vale_secret",
        "speaker": "vale",
        "tag": "secret",
        "action": "녹음앞에서 소렌이 개인 채널 목록을 연다.",
        "lines": [
            [
                "vale",
                "이 채널은 보고하지 않았어요. 제 이름을 불렀거든요."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "vale_observation",
        "speaker": "vale",
        "tag": "observation",
        "action": "소렌은 헤드폰을 벗은 뒤에도 고개를 든다.",
        "lines": [
            [
                "vale",
                "방금은 스피커에서 난 소리가 아니었어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_apology",
        "speaker": "eli",
        "tag": "apology",
        "action": "보정값을보다 루칸이 접어 둔 지도를 다시 편다.",
        "lines": [
            [
                "eli",
                "혼자 가려던 건 잘못했어. 경로부터 보여 줄게."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_request",
        "speaker": "eli",
        "tag": "request",
        "action": "지도를펼치며 루칸이 항로 화면의 두 점을 짚는다.",
        "lines": [
            [
                "eli",
                "내가 숫자를 읽을게. 너는 창밖을 봐."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "eli_defense",
        "speaker": "eli",
        "tag": "defense",
        "action": "경로를멈추고 루칸이 조종석을 당겨 앉는다.",
        "lines": [
            [
                "eli",
                "그 회전은 내가 지시했어. 기록에도 남겼고."
            ]
        ],
        "choices": []
    },
    {
        "id": "eli_secret",
        "speaker": "eli",
        "tag": "secret",
        "action": "별빛아래에서 루칸이 작은 저장장치를 책상에 놓는다.",
        "lines": [
            [
                "eli",
                "사본을 따로 뒀어. 누가 지우기 전에."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "eli_observation",
        "speaker": "eli",
        "tag": "observation",
        "action": "항법로그옆에서 루칸이 멀리 있는 별을 손으로 가린다.",
        "lines": [
            [
                "eli",
                "움직인 건 저 별이 아니야. 화면 쪽이지."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_apology",
        "speaker": "lyra",
        "tag": "apology",
        "action": "습도계옆에서 마렌이 닫아 둔 상자 뚜껑을 연다.",
        "lines": [
            [
                "lyra",
                "설명도 없이 치웠네요. 같이 보고 골라요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_request",
        "speaker": "lyra",
        "tag": "request",
        "action": "흙을털며 마렌이 화분 밑에 마른 천을 넣는다.",
        "lines": [
            [
                "lyra",
                "이쪽만 잡아 줄래요? 뿌리는 건드리지 말고요."
            ]
        ],
        "choices": [
            {
                "label": "말한 대로 함께한다.",
                "effect": "help"
            },
            {
                "label": "한 번 더 방법을 확인한다.",
                "effect": "observe"
            }
        ]
    },
    {
        "id": "lyra_defense",
        "speaker": "lyra",
        "tag": "defense",
        "action": "조명아래에서 마렌이 급수표의 자기 서명을 가리킨다.",
        "lines": [
            [
                "lyra",
                "물을 더 준 건 저예요. 관리 담당은 시키는 대로 했어요."
            ]
        ],
        "choices": []
    },
    {
        "id": "lyra_secret",
        "speaker": "lyra",
        "tag": "secret",
        "action": "배양통앞에서 마렌이 작은 모종을 조심스럽게 꺼낸다.",
        "lines": [
            [
                "lyra",
                "폐기 목록에 있던 아이예요. 아직 살아 있었어요."
            ]
        ],
        "choices": [
            {
                "label": "“같이 기록해 두자.”",
                "effect": "share"
            },
            {
                "label": "지금은 두 사람만 알고 있기로 한다.",
                "effect": "hide"
            }
        ]
    },
    {
        "id": "lyra_observation",
        "speaker": "lyra",
        "tag": "observation",
        "action": "마렌은 잎 뒷면을 빛 쪽으로 돌린다.",
        "lines": [
            [
                "lyra",
                "광원은 여기인데 잎이 반대로 자라요. 전에 다른 곳에 있었나 봐요."
            ]
        ],
        "choices": []
    },
    {"id":"mira_shift_tea","speaker":"mira","tag":"everyday","action":"확인을마치고 미라가 차를 두 잔 따르고 한 잔은 손도 대지 않은 채 식힌다.","lines":[["mira","뜨거운 건 아직 속이 안 받아요. 냄새만 맡고 있을게요."]],"choices":[]},
    {"id":"mira_glove_size","speaker":"mira","tag":"work","action":"잠시뒤, 미라가 의료 장갑 상자 세 개에 손글씨로 이름을 다시 붙인다.","lines":[["mira","준이 자꾸 큰 걸 가져가서요. 손 크기는 안 바뀌었는데 습관은 안 고쳐지네요."]],"choices":[]},
    {"id":"mira_temp_log","speaker":"mira","tag":"observation","action":"복도끝에서 미라가 의료실 온도를 0.5도 올리고 사람들 표정을 본다.","lines":[["mira","수면 뒤엔 같은 온도도 더 춥게 느껴져요. 누가 떨면 기록보다 먼저 봐요."]],"choices":[]},
    {"id":"mira_empty_bed","speaker":"mira","tag":"personal","action":"작은숨을고르고 미라가 빈 침상에 담요를 펴다가 다시 접는다.","lines":[["mira","비어 있는 자리를 정리하는 건 아직도 익숙해지지 않아요."]],"choices":[]},
    {"id":"mira_food_check","speaker":"mira","tag":"everyday","action":"의료실한쪽에서 미라가 배급식 포장을 뒤집어 유통 시간을 확인한다.","lines":[["mira","맛은 포기해도 배탈은 안 돼요. 지금은 환자 늘릴 때가 아니니까."]],"choices":[]},
    {"id":"mira_no_alarm","speaker":"mira","tag":"observation","action":"기록대앞에서 미라가 경보 기록을 내리고 손목의 맥박 센서를 다시 본다.","lines":[["mira","몸은 놀랐다고 말하는데 시스템은 아무 일도 없었다고 해요."]],"choices":[]},
    {"id":"mira_shoes","speaker":"mira","tag":"everyday","action":"침상곁에서 미라가 의료실 입구의 신발을 가지런히 밀어 넣는다.","lines":[["mira","누가 급하게 나갔는지는 신발만 봐도 티가 나요. 오늘은 다 엉켜 있네요."]],"choices":[]},
    {"id":"mira_sena_bandage","speaker":"mira","tag":"work","action":"조용한틈에 미라가 세나가 두고 간 붕대를 접어 서랍에 넣는다.","lines":[["mira","안 다쳤다면서 꼭 이런 건 하나씩 쓰고 가요. 세나는 늘 그래요."]],"choices":[]},
    {"id":"mira_sleep_count","speaker":"mira","tag":"observation","action":"교대직전에 미라가 수면 포드 숫자를 세다가 처음부터 다시 센다.","lines":[["mira","네 개는 잠들어 있고, 우리는 깨어 있어요. 이 숫자만큼은 바뀌면 안 돼요."]],"choices":[]},
    {"id":"mira_quiet_music","speaker":"mira","tag":"everyday","action":"등불아래에서 미라가 아주 작은 볼륨으로 오래된 피아노 곡을 틀어 둔다.","lines":[["mira","환자 없을 때만 켜요. 의료실이 너무 조용하면 오히려 불안해서."]],"choices":[]},
    {"id":"mira_handwriting","speaker":"mira","tag":"work","action":"확인을마치고 미라가 전자 기록 옆에 종이 메모를 한 장 더 붙인다.","lines":[["mira","화면이 틀릴 수도 있잖아요. 제 글씨까지 같이 틀리면 그때는 정말 곤란하고요."]],"choices":[]},
    {"id":"rho_loose_bolt","speaker":"rho","tag":"work","action":"공구함앞에서 준이 손바닥 위에 서로 다른 볼트 두 개를 올려놓는다.","lines":[["rho","둘 다 들어가긴 해. 그런데 하나는 여기 물건이 아니야."]],"choices":[]},
    {"id":"rho_cold_coffee","speaker":"rho","tag":"everyday","action":"패널아래에서 준이 차갑게 식은 커피를 마시자마자 얼굴을 찌푸린다.","lines":[["rho","와, 이건 Null보다 먼저 격리해야겠다. 누가 내 커피 이렇게 만들었냐."]],"choices":[]},
    {"id":"rho_tool_shadow","speaker":"rho","tag":"observation","action":"금속음뒤로, 준이 벽에 걸린 공구 그림자를 보고 빈 자리를 하나 짚는다.","lines":[["rho","렌치 하나 없네. 빌려 갔으면 말이라도 하지."]],"choices":[]},
    {"id":"rho_sena_history","speaker":"rho","tag":"personal","action":"작업등곁에서 준이 보안실 문 앞에서 한동안 노크하지 않는다.","lines":[["rho","세나는 화났을 때보다 조용할 때가 더 무서워. 예전에도 그랬어."]],"choices":[]},
    {"id":"rho_wire_smell","speaker":"rho","tag":"work","action":"정비를멈추고 준이 패널을 열기 전에 먼저 코를 가까이 댄다.","lines":[["rho","탄 냄새 없어. 전원이 죽은 게 아니라 누가 얌전히 끊은 거야."]],"choices":[]},
    {"id":"rho_floor_mark","speaker":"rho","tag":"observation","action":"환풍구앞에서 준이 기관실 바닥의 얇은 긁힘을 손톱으로 따라간다.","lines":[["rho","이건 카트 바퀴 자국이야. 사람이 끌고 갔으면 방향이 남아."]],"choices":[]},
    {"id":"rho_music_request","speaker":"rho","tag":"everyday","action":"렌치를내려놓고 준이 소렌 쪽을 보며 작업 리듬을 손가락으로 두드린다.","lines":[["rho","야, 너무 우울한 거 말고. 렌치 떨어뜨려도 박자 맞을 만한 걸로."]],"choices":[]},
    {"id":"rho_spare_fuse","speaker":"rho","tag":"work","action":"기계소리사이로 준이 예비 퓨즈를 세어 보고 하나를 주머니에서 다시 꺼낸다.","lines":[["rho","내가 챙긴 거였네. 남 탓하기 전에 주머니부터 봐야겠다."]],"choices":[]},
    {"id":"rho_dax_argument","speaker":"rho","tag":"personal","action":"케이블옆에서 준이 다렌의 계산 메모에 동그라미를 크게 친다.","lines":[["rho","쟤는 숫자부터 보고 난 소리부터 듣지. 둘 다 맞을 때가 제일 짜증 나."]],"choices":[]},
    {"id":"rho_heat","speaker":"rho","tag":"everyday","action":"기관실한쪽에서 준이 작업복 지퍼를 끝까지 내리고 환풍구 앞에 선다.","lines":[["rho","기관실은 원래 덥지만 오늘은 유난하네. 누가 순환기 설정 건드렸나?"]],"choices":[]},
    {"id":"rho_old_scratch","speaker":"rho","tag":"observation","action":"공구함앞에서 준이 패널 옆 오래된 흠집을 새 흠집과 나란히 짚는다.","lines":[["rho","이건 내가 냈고, 이건 아니야. 내 실수는 내가 제일 잘 알아."]],"choices":[]},
    {"id":"rho_mira_warning","speaker":"rho","tag":"work","action":"패널아래에서 준이 미라가 붙여 둔 ‘쉬기’ 메모를 공구함 안쪽에 옮겨 붙인다.","lines":[["rho","버린 건 아니야. 안 보이는 데 둔 거지. 이것도 지킨 거로 쳐 줘."]],"choices":[]},
    {"id":"rho_midnight_snack","speaker":"rho","tag":"everyday","action":"금속음뒤로, 준이 비상식량 포장을 반으로 나눠 당신 쪽으로 민다.","lines":[["rho","맛없어도 같이 먹으면 좀 낫다. 아주 조금."]],"choices":[]},
    {"id":"rho_manual_switch","speaker":"rho","tag":"observation","action":"작업등곁에서 준이 자동 스위치를 쓰지 않고 손으로 차단기를 내렸다 올린다.","lines":[["rho","자동이 이상할 때는 손이 제일 정확해. 대신 누가 했는지가 남지."]],"choices":[]},
    {"id":"noa_margin","speaker":"noa","tag":"everyday","action":"기록보관실에서 노아가 노트 여백을 자로 맞추다가 그냥 손으로 선을 긋는다.","lines":[["noa","오늘은 삐뚤어도 둘게요. 다시 쓰면 처음 생각이 사라질 것 같아서요."]],"choices":[]},
    {"id":"noa_duplicate_time","speaker":"noa","tag":"observation","action":"페이지를넘기다 노아가 같은 시각이 찍힌 두 기록을 번갈아 읽는다.","lines":[["noa","07시 37분이 두 번 있어요. 같은 분인데 문장이 달라요."]],"choices":[]},
    {"id":"noa_pencil","speaker":"noa","tag":"everyday","action":"메모끝에서 노아가 짧아진 연필을 버리지 않고 캡을 끼운다.","lines":[["noa","이 정도면 아직 써요. 새 걸 꺼내면 어디까지 적었는지 헷갈려서."]],"choices":[]},
    {"id":"noa_mira_quote","speaker":"noa","tag":"work","action":"시간표앞에서 노아가 미라의 말을 적었다가 따옴표를 지운다.","lines":[["noa","정확히 같은 말인지 자신 없어서요. 뜻만 남기는 게 나을 것 같아요."]],"choices":[]},
    {"id":"noa_silence","speaker":"noa","tag":"observation","action":"문장을고치다 노아가 회의 녹음의 긴 침묵 구간에 시간을 표시한다.","lines":[["noa","말한 것만 기록하면, 아무도 대답 안 한 순간은 없어져 버려요."]],"choices":[]},
    {"id":"noa_archive_dust","speaker":"noa","tag":"everyday","action":"자료실한쪽에서 노아가 자료실 책등의 먼지를 손가락으로 닦아 작은 줄을 만든다.","lines":[["noa","종이 냄새는 그대로네요. 이런 건 좀 안 바뀌었으면 좋겠어요."]],"choices":[]},
    {"id":"noa_two_titles","speaker":"noa","tag":"work","action":"두기록사이에서 노아가 같은 파일에 붙은 서로 다른 제목 두 개를 나란히 적는다.","lines":[["noa","내용보다 제목이 나중에 바뀐 흔적 같아요. 누가 고쳤는지는 없고요."]],"choices":[]},
    {"id":"noa_food_note","speaker":"noa","tag":"everyday","action":"연필을멈추고 노아가 배급표 구석에 ‘준 두 번’이라고 작게 적는다.","lines":[["noa","한 번 더 먹었대요. 기록보다 본인이 먼저 인정했으니 사건은 아니에요."]],"choices":[]},
    {"id":"noa_memory_order","speaker":"noa","tag":"personal","action":"로그를읽다가 노아가 자신이 깨어난 순서를 적다가 세 번째 줄에서 멈춘다.","lines":[["noa","여기부터는 기억과 로그 순서가 달라요. 어느 쪽을 믿어야 할지 모르겠어요."]],"choices":[]},
    {"id":"noa_folded_page","speaker":"noa","tag":"observation","action":"종이를펴며 노아가 접혀 있던 종이의 자국을 펴 보고 반대쪽 글씨를 읽는다.","lines":[["noa","누군가 이 부분만 안 보이게 접었어요. 우연이면 참 정교하네요."]],"choices":[]},
    {"id":"noa_soren_audio","speaker":"noa","tag":"work","action":"기록보관실에서 노아가 소렌의 음성 파일을 받아 파형 옆에 들은 문장을 적는다.","lines":[["noa","소리는 애매해도, 우리가 들었다고 말한 문장은 비교할 수 있어요."]],"choices":[]},
    {"id":"noa_end_sentence","speaker":"noa","tag":"personal","action":"페이지를넘기다 노아가 마지막 문장을 마침표 없이 끝낸다.","lines":[["noa","끝났다고 쓰기 싫어요. 아직 확인할 게 남아 있으니까."]],"choices":[]},
    {"id":"dax_two_clocks","speaker":"dax","tag":"work","action":"단말앞에서 다렌이 벽시계와 단말 시계를 같은 화면에 비춘다.","lines":[["dax","11초 차이. 작아 보여도 사건 창에서는 충분히 커."]],"choices":[]},
    {"id":"dax_checksum","speaker":"dax","tag":"observation","action":"계산을멈추고 다렌이 파일 이름보다 체크섬부터 확인한다.","lines":[["dax","문장은 같아도 파일이 다르면 누군가 손댄 거야. 반대도 가능하고."]],"choices":[]},
    {"id":"dax_dry_drink","speaker":"dax","tag":"everyday","action":"그래프옆에서 다렌이 너무 진한 음료를 물로 희석한다.","lines":[["dax","준이 만들면 항상 이래. 측정 없이 붓거든."]],"choices":[]},
    {"id":"dax_whiteboard","speaker":"dax","tag":"work","action":"수치를훑다가 다렌이 화이트보드 한쪽을 일부러 비워 둔다.","lines":[["dax","확실하지 않은 건 빈칸으로 두는 게 낫지. 억지로 채우면 그게 답처럼 보여."]],"choices":[]},
    {"id":"dax_noa_order","speaker":"dax","tag":"personal","action":"화이트보드앞에서 다렌이 노아의 기록 순서를 바꾸려다 손을 멈춘다.","lines":[["dax","쟤는 시간순, 나는 원인순으로 봐. 그래서 같은 파일도 다른 얘기가 돼."]],"choices":[]},
    {"id":"dax_sensor_noise","speaker":"dax","tag":"observation","action":"잠시화면을끄고 다렌이 센서 그래프의 작은 흔들림을 확대하지 않고 평균값부터 본다.","lines":[["dax","잡음을 사건으로 만들면 끝이 없어. 반복되는 것만 보자."]],"choices":[]},
    {"id":"dax_screw_count","speaker":"dax","tag":"everyday","action":"표를정리하며 다렌이 준이 늘어놓은 나사를 세고 한 개를 옆으로 밀어 둔다.","lines":[["dax","이건 규격이 달라. 준은 모양부터 보고 난 숫자부터 보네."]],"choices":[]},
    {"id":"dax_route_math","speaker":"dax","tag":"work","action":"센서기록앞에서 다렌이 루칸의 항로 위에 예상 연료 소모선을 겹친다.","lines":[["dax","경로가 맞다면 연료가 안 맞아. 연료가 맞다면 경로가 틀리고."]],"choices":[]},
    {"id":"dax_sleep_debt","speaker":"dax","tag":"personal","action":"숫자를지우고 다렌이 계산 중 같은 숫자를 두 번 입력하고 화면을 끈다.","lines":[["dax","이 정도면 자야 해. 틀렸다는 걸 알아차리는 속도부터 느려졌어."]],"choices":[]},
    {"id":"dax_spare_terminal","speaker":"dax","tag":"observation","action":"창가에서돌아와 다렌이 사용하지 않던 단말의 마지막 로그인 시간을 확인한다.","lines":[["dax","안 쓴 기계가 로그인돼 있으면 사람보다 먼저 물어봐야지."]],"choices":[]},
    {"id":"dax_mira_stats","speaker":"dax","tag":"work","action":"단말앞에서 다렌이 미라의 생체 통계를 받아 값 대신 누락 구간을 표시한다.","lines":[["dax","정상 수치보다 없는 수치가 더 중요할 때가 있어."]],"choices":[]},
    {"id":"dax_window","speaker":"dax","tag":"everyday","action":"계산을멈추고 다렌이 창밖을 10초쯤 보고 다시 단말로 돌아온다.","lines":[["dax","별은 계산 안 해도 그대로 있어서 좋네."]],"choices":[]},
    {"id":"dax_false_precision","speaker":"dax","tag":"personal","action":"그래프옆에서 다렌이 소수점 아래 숫자 세 자리를 지운다.","lines":[["dax","모르는 걸 0.001까지 쓰면 아는 척만 정교해져."]],"choices":[]},
    {"id":"sena_door_count","speaker":"sena","tag":"work","action":"보안실앞에서 세나가 복도를 한 번 지나가며 열린 문 숫자를 센다.","lines":[["sena","세 개. 아까는 두 개였어. 누가 하나 열었네."]],"choices":[]},
    {"id":"sena_boots","speaker":"sena","tag":"everyday","action":"순찰을멈추고 세나가 젖은 부츠를 보안실 문밖에 벗어 둔다.","lines":[["sena","안에서 말리면 준이 또 냄새난다고 난리 쳐."]],"choices":[]},
    {"id":"sena_rho_old","speaker":"sena","tag":"personal","action":"출입문곁에서 세나가 준이 남긴 정비 메모를 접지 않고 그대로 돌려놓는다.","lines":[["sena","글씨는 똑같네. 이것까지 달라졌으면 진짜 화났을 거야."]],"choices":[]},
    {"id":"sena_blind_spot","speaker":"sena","tag":"observation","action":"카드를확인하다 세나가 카메라 두 대 사이의 사각을 직접 걸어 본다.","lines":[["sena","기록에 안 잡힌다고 못 지나가는 건 아니야. 여기 딱 세 걸음."]],"choices":[]},
    {"id":"sena_water","speaker":"sena","tag":"everyday","action":"복도끝에서서 세나가 물병을 한 번에 반쯤 비우고 뚜껑을 꽉 닫는다.","lines":[["sena","수면 뒤엔 갈증부터 와. 준은 꼭 커피부터 찾지만."]],"choices":[]},
    {"id":"sena_keycard","speaker":"sena","tag":"work","action":"경보등아래에서 세나가 출입카드를 빛에 비춰 미세한 긁힘을 본다.","lines":[["sena","복제했으면 모서리부터 티 나. 적어도 이건 원본이야."]],"choices":[]},
    {"id":"sena_mira_rest","speaker":"sena","tag":"personal","action":"순찰지도앞에서 세나가 의료실 앞에서 미라 대신 문을 닫아 준다.","lines":[["sena","미라도 자야 해. 사람 챙기는 사람은 자기가 사람인 걸 자꾸 잊어."]],"choices":[]},
    {"id":"sena_alarm_volume","speaker":"sena","tag":"observation","action":"문을닫으며 세나가 경보음 크기를 한 단계 낮췄다가 바로 되돌린다.","lines":[["sena","안 들리는 것보다 시끄러운 게 낫지. 지금은."]],"choices":[]},
    {"id":"sena_meal_watch","speaker":"sena","tag":"everyday","action":"기록을훑다가 세나가 식사하면서도 출입문 쪽 자리를 고른다.","lines":[["sena","습관이야. 등 뒤로 사람 지나가는 거 싫어."]],"choices":[]},
    {"id":"sena_patrol_map","speaker":"sena","tag":"work","action":"발소리를멈추고 세나가 순찰 지도에 직선 대신 돌아가는 길을 표시한다.","lines":[["sena","빠른 길만 쓰면 패턴이 돼. 보는 쪽도 외우거든."]],"choices":[]},
    {"id":"sena_quiet_apology","speaker":"sena","tag":"personal","action":"보안실앞에서 세나가 준에게 하려던 말을 삼키고 당신에게 먼저 시선을 준다.","lines":[["sena","지금 따지면 또 싸워. 사실부터 보고 나서 할게."]],"choices":[]},
    {"id":"vale_fan_hum","speaker":"vale","tag":"observation","action":"소리를세다가 소렌이 환풍기 소리에 맞춰 손가락을 세 번 움직인다.","lines":[["vale","세 번째 회전마다 낮은 소리가 섞여요. 기계 소리인지 신호인지 아직 모르겠어요."]],"choices":[]},
    {"id":"vale_one_ear","speaker":"vale","tag":"everyday","action":"통신실한쪽에서 소렌이 이어폰 한쪽만 끼고 다른 쪽은 목에 걸어 둔다.","lines":[["vale","둘 다 끼면 누가 부르는 걸 놓쳐요. 요즘은 그게 싫어요."]],"choices":[]},
    {"id":"vale_no_song","speaker":"vale","tag":"personal","action":"파형앞에서 소렌이 재생 목록에서 한 곡을 건너뛴다.","lines":[["vale","이건 지금 못 듣겠어요. 이유는 나중에 말할게요."]],"choices":[]},
    {"id":"vale_wave_gap","speaker":"vale","tag":"work","action":"이어폰을빼며 소렌이 파형의 빈 구간을 확대해 소리 없는 부분을 재생한다.","lines":[["vale","아무 소리도 없는 4초가 반복돼요. 없는 것도 패턴이면 기록해야 해요."]],"choices":[]},
    {"id":"vale_noa_words","speaker":"vale","tag":"personal","action":"신호를되감다 소렌이 노아가 적은 문장을 천천히 소리 내 읽는다.","lines":[["vale","글로 보면 평범한데 소리 내면 어디서 끊겼는지 보여요."]],"choices":[]},
    {"id":"vale_room_tone","speaker":"vale","tag":"observation","action":"잡음사이에서 소렌이 방마다 10초씩 아무 말도 하지 않고 녹음한다.","lines":[["vale","방도 자기 소리가 있어요. 누가 문을 열면 그게 먼저 바뀌어요."]],"choices":[]},
    {"id":"vale_sleep_voice","speaker":"vale","tag":"work","action":"재생을멈추고 소렌이 수면 기록의 자기 목소리를 재생하다 정지한다.","lines":[["vale","제 목소리 맞아요. 그런데 이 숨은 제가 깨어 있을 때보다 느려요."]],"choices":[]},
    {"id":"vale_warm_mug","speaker":"vale","tag":"everyday","action":"통신단말곁에서 소렌이 빈 머그컵을 두 손으로 감싼 채 통신 로그를 듣는다.","lines":[["vale","따뜻한 건 없는데 이렇게 들고 있으면 좀 낫더라고요."]],"choices":[]},
    {"id":"vale_lukan_signal","speaker":"vale","tag":"personal","action":"볼륨을낮추며 소렌이 루칸이 찍어 둔 좌표에 작은 음표를 하나 표시한다.","lines":[["vale","저 좌표를 볼 때만 같은 소리가 나요. 우연이면 좋겠어요."]],"choices":[]},
    {"id":"eli_star_fix","speaker":"eli","tag":"observation","action":"항법실앞에서 루칸이 항법 화면의 별 하나를 고정점으로 잠근다.","lines":[["eli","기록이 바뀌어도 저 별 위치까지 같이 바꾸진 못해."]],"choices":[]},
    {"id":"eli_seat_belt","speaker":"eli","tag":"everyday","action":"별지도곁에서 루칸이 앉지도 않으면서 의자 안전벨트를 반듯하게 정리한다.","lines":[["eli","꼬여 있으면 눈에 거슬려. 쓸 일 없어도."]],"choices":[]},
    {"id":"eli_fuel_route","speaker":"eli","tag":"work","action":"좌표를맞추다 루칸이 항로와 연료 소비 그래프를 겹쳐 본다.","lines":[["eli","둘 중 하나가 거짓말해. 같은 여행이면 같은 연료를 먹어야 하거든."]],"choices":[]},
    {"id":"eli_soren_sound","speaker":"eli","tag":"personal","action":"항법창에서돌아와 루칸이 소렌의 신호 좌표를 지도에 찍고 확대를 멈춘다.","lines":[["eli","소리는 못 믿어도 위치는 볼 수 있어. 적어도 나는 그렇게 해야 해."]],"choices":[]},
    {"id":"eli_window_sleep","speaker":"eli","tag":"everyday","action":"항로화면앞에서 루칸이 창가에 기대 잠깐 눈을 감았다가 바로 뜬다.","lines":[["eli","잠드는 건 괜찮아. 방향 모른 채 깨는 게 싫지."]],"choices":[]},
    {"id":"eli_drift","speaker":"eli","tag":"observation","action":"보정값을보다 루칸이 자동항법이 보정한 작은 편차를 따로 기록한다.","lines":[["eli","한 번이면 바람 같은 거야. 같은 방향으로 세 번이면 누가 민 거고."]],"choices":[]},
    {"id":"eli_old_map","speaker":"eli","tag":"work","action":"지도를펼치며 루칸이 종이 별지도를 펼쳐 화면 옆에 붙인다.","lines":[["eli","업데이트 안 되는 게 장점일 때도 있어. 적어도 어제랑 말이 달라지진 않으니까."]],"choices":[]},
    {"id":"eli_destination_name","speaker":"eli","tag":"personal","action":"경로를멈추고 루칸이 목적지 이름을 읽지 않고 좌표만 확인한다.","lines":[["eli","이름은 사람이 붙여. 좌표부터 맞는지 보자."]],"choices":[]},
    {"id":"lyra_leaf_dust","speaker":"lyra","tag":"everyday","action":"작은화분곁에서 마렌이 잎에 쌓인 먼지를 젖은 천으로 한 장씩 닦는다.","lines":[["lyra","이렇게 하면 숨 쉬는 게 조금 나아져요. 사람도 비슷하면 좋겠네요."]],"choices":[]},
    {"id":"lyra_seed_count","speaker":"lyra","tag":"work","action":"온실한쪽에서 마렌이 씨앗 봉투를 세다가 라벨과 실제 개수가 다른 걸 발견한다.","lines":[["lyra","두 개가 많아요. 없어지는 것보다 더 생기는 게 더 무서울 때도 있어요."]],"choices":[]},
    {"id":"lyra_humidity","speaker":"lyra","tag":"observation","action":"재배대앞에서 마렌이 손등으로 공기를 느끼고 습도계를 확인한다.","lines":[["lyra","숫자 보기 전에 대충 맞혀 보는 습관이 있어요. 오늘은 느낌이 틀렸네요."]],"choices":[]},
    {"id":"lyra_soup","speaker":"lyra","tag":"everyday","action":"잎사이로 마렌이 배급 수프에 말린 허브를 아주 조금 부순다.","lines":[["lyra","맛이 좋아진다기보다 냄새가 사람 사는 곳 같아져요."]],"choices":[]},
    {"id":"lyra_mira_plant","speaker":"lyra","tag":"personal","action":"표본을살피다 마렌이 의료실 창가에 작은 화분을 놓을 자리를 재 본다.","lines":[["lyra","미라한테 하나 주려고요. 저 방은 너무 하얘서."]],"choices":[]},
    {"id":"lyra_root","speaker":"lyra","tag":"work","action":"물주기를멈추고 마렌이 투명 배양통 아래쪽 뿌리를 손전등으로 비춘다.","lines":[["lyra","위는 멀쩡해도 뿌리가 상하면 늦어요. 겉만 보면 안 돼요."]],"choices":[]},
    {"id":"lyra_red_label","speaker":"lyra","tag":"observation","action":"습도계옆에서 마렌이 빨간 라벨 하나를 다른 표본들과 떨어뜨려 놓는다.","lines":[["lyra","이 색은 위험해서가 아니라 ‘다시 확인’이라는 뜻이에요. 자꾸 둘을 같은 걸로 봐요."]],"choices":[]},
    {"id":"lyra_sena_hands","speaker":"lyra","tag":"personal","action":"흙을털며 마렌이 세나 손등의 작은 상처에 연고를 건넨다.","lines":[["lyra","괜찮다고 해도 피부는 아니라고 말하네요."]],"choices":[]},
    {"id":"lyra_dark_cycle","speaker":"lyra","tag":"work","action":"조명아래에서 마렌이 온실 조명을 일부러 20분 일찍 끈다.","lines":[["lyra","계속 밝으면 식물이 망가져요. 깨어 있는 게 항상 좋은 건 아니에요."]],"choices":[]},
    {"id":"lyra_empty_tray","speaker":"lyra","tag":"everyday","action":"배양통앞에서 마렌이 빈 재배 트레이를 씻고도 한참 물기를 닦는다.","lines":[["lyra","다시 심을지 모르겠어요. 그래도 비워 둔 채 더럽게 두긴 싫어요."]],"choices":[]},
    {"id":"lyra_old_sample","speaker":"lyra","tag":"observation","action":"작은화분곁에서 마렌이 오래된 표본의 색을 현재 표본과 비교한다.","lines":[["lyra","같은 종인데 색이 달라요. 환경이 달랐거나, 시간이 달랐거나."]],"choices":[]},
    {"id":"lyra_daren_numbers","speaker":"lyra","tag":"personal","action":"온실한쪽에서 마렌이 다렌의 표를 보다가 숫자 대신 샘플 이름에 밑줄을 긋는다.","lines":[["lyra","수치는 다렌이 볼 거예요. 저는 이게 어떤 생명이었는지 안 잊으려고요."]],"choices":[]},
    {"id":"pair_rho_sena_050_a","speaker":"rho","target":"sena","tag":"pair","action":"정비를멈추고 준이 보안실 문턱에 공구함을 내려놓고 세나가 점검을 끝낼 때까지 기다린다.","lines":[["rho","이거 끝나면 기관실 한 번만 같이 봐 줘."],["sena","왜, 혼자 가기 싫어?"],["rho","아니. 네가 보면 내가 놓친 걸 꼭 찾잖아. 그게 짜증나게 유용해서."]],"choices":[]},
    {"id":"pair_rho_sena_050_b","speaker":"sena","target":"rho","tag":"pair","action":"순찰을멈추고 세나가 준의 작업등 각도를 말없이 바꾼다.","lines":[["rho","야, 내 거 왜 건드려."],["sena","네 그림자 때문에 볼트가 안 보여."],["rho","…그건 인정. 대신 다음엔 말하고."]],"choices":[]},
    {"id":"pair_mira_lyra_050_a","speaker":"mira","target":"lyra","tag":"pair","action":"잠시뒤, 미라가 의료실 창가를 비워 마렌의 작은 화분 하나를 올려 둔다.","lines":[["lyra","여기 둬도 돼요?"],["mira","환자보다 햇빛이 더 필요해 보이니까요."],["lyra","그럼 물은 제가 챙길게요. 미라는 잠을 챙겨요."]],"choices":[]},
    {"id":"pair_mira_lyra_050_b","speaker":"lyra","target":"mira","tag":"pair","action":"재배대앞에서 마렌이 미라의 손등을 보고 흙 묻은 장갑을 벗는다.","lines":[["lyra","손이 차가워요."],["mira","수면 후엔 원래 그래요."],["lyra","남한테는 그렇게 말 안 하잖아요. 잠깐 앉아요."]],"choices":[]},
    {"id":"pair_dax_noa_050_a","speaker":"dax","target":"noa","tag":"pair","action":"다렌과 노아가 같은 로그를 서로 반대 방향으로 정렬해 놓는다.","lines":[["dax","원인순으로 보면 이 줄이 먼저야."],["noa","시간순으로는 이 문장이 먼저예요."],["dax","좋아. 둘 다 지우지 말자. 차이가 정보니까."]],"choices":[]},
    {"id":"pair_dax_noa_050_b","speaker":"noa","target":"dax","tag":"pair","action":"메모끝에서 노아가 다렌의 계산 옆에 작은 물음표 하나만 적는다.","lines":[["dax","틀렸다는 뜻이야?"],["noa","아니요. 제가 아직 못 따라갔다는 뜻이에요."],["dax","그게 더 쓸모 있네. 설명하다 보면 내가 틀린 데가 나오거든."]],"choices":[]},
    {"id":"pair_vale_eli_050_a","speaker":"vale","target":"eli","tag":"pair","action":"녹음앞에서 소렌이 항법실에서 같은 신호를 세 번째로 재생한다.","lines":[["vale","여기서 소리가 바뀌어요."],["eli","그 시각에 경로도 0.3도 꺾였어."],["vale","그럼 소리가 아니라 위치부터 맞춰 볼까요?"]],"choices":[]},
    {"id":"pair_vale_eli_050_b","speaker":"eli","target":"vale","tag":"pair","action":"별빛아래에서 루칸이 소렌의 파형 위에 별 좌표를 겹쳐 표시한다.","lines":[["eli","네가 들은 순간마다 여기야."],["vale","같은 곳인데 같은 시간은 아니에요."],["eli","그래서 더 싫어. 장소가 우리보다 오래 기억하고 있다는 거잖아."]],"choices":[]},
    {"id":"pair_rho_dax_050_a","speaker":"rho","target":"dax","tag":"pair","action":"환풍구앞에서 준이 다렌의 계산표 위에 기름 묻은 손가락을 올리려다 멈춘다.","lines":[["rho","숫자로는 정상이지?"],["dax","평균은."],["rho","그럼 평균 말고 이 소리 좀 들어 봐. 정상 기계는 이렇게 안 울어."]],"choices":[]},
    {"id":"pair_rho_dax_050_b","speaker":"dax","target":"rho","tag":"pair","action":"수치를훑다가 다렌이 준이 표시한 케이블 두 가닥에 번호표를 붙인다.","lines":[["dax","둘 중 어느 쪽이 먼저 뜨거웠어?"],["rho","왼쪽. 확실해."],["dax","좋아. 그 한 문장이 센서 로그보다 먼저였네."]],"choices":[]},
    {"id":"pair_sena_mira_050_a","speaker":"sena","target":"mira","tag":"pair","action":"출입문곁에서 세나가 의료실 출입문을 절반만 열어 두고 안쪽을 확인한다.","lines":[["mira","문은 그냥 닫아도 돼요."],["sena","안 돼. 안에서 무슨 일 생기면 바로 들어와야 해."],["mira","그럼 세나도 보이는 데서 좀 쉬어요."]],"choices":[]},
    {"id":"pair_sena_mira_050_b","speaker":"mira","target":"sena","tag":"pair","action":"복도끝에서 미라가 세나의 손등에 작은 밴드를 붙이는 동안 세나는 문 쪽만 본다.","lines":[["mira","이쪽 좀 봐요. 10초면 돼요."],["sena","보고 있어."],["mira","문 말고 손이요."],["sena","…알았어."]],"choices":[]},
    {"id":"pair_lyra_dax_050_a","speaker":"lyra","target":"dax","tag":"pair","action":"잎사이로 마렌이 표본 성장표를 다렌에게 내밀고 숫자 대신 잎을 보여 준다.","lines":[["dax","성장률은 정상 범위야."],["lyra","이 잎 방향은 정상 아니에요."],["dax","좋아. 숫자가 못 잡는 변수 하나 추가."]],"choices":[]},
    {"id":"pair_lyra_dax_050_b","speaker":"dax","target":"lyra","tag":"pair","action":"화이트보드앞에서 다렌이 생태 구역 센서 그래프의 빈 구간을 가리킨다.","lines":[["dax","여기 18분이 없어."],["lyra","그동안 조명이 꺼졌다면 잎이 기억할 수도 있어요."],["dax","식물을 로그로 쓰자는 말, 오늘 처음 설득력 있네."]],"choices":[]},
    {"id":"pair_noa_vale_050_a","speaker":"noa","target":"vale","tag":"pair","action":"시간표앞에서 노아가 소렌의 녹음에서 들린 문장을 소리 내지 않고 받아 적는다.","lines":[["vale","왜 안 읽어요?"],["noa","제가 먼저 읽으면 그렇게 들릴까 봐요."],["vale","좋아요. 그럼 제가 한 번 더 듣고 먼저 말할게요."]],"choices":[]},
    {"id":"pair_noa_vale_050_b","speaker":"vale","target":"noa","tag":"pair","action":"소리를세다가 소렌이 이어폰 한쪽을 노아에게 건네고 재생 위치를 숨긴다.","lines":[["vale","시간 안 보고 들어 봐요."],["noa","…여기서 누가 숨을 들이마셔요."],["vale","저도 그 부분이었어요. 이제 시간을 봐요."]],"choices":[]},
    {"id":"trio_rho_sena_mira_050","speaker":"rho","tag":"trio","participants":["rho","sena","mira"],"action":"준과 세나가 보안등 원인을 두고 말이 겹치자 미라가 둘 사이에 물병을 하나씩 내려놓는다.","lines":[["rho","배선 문제면 내가 보면 돼."],["sena","누가 끊었는지가 문제라니까."],["mira","둘 다 맞아요. 준은 배선을 보고, 세나는 출입 기록을 봐요. 그리고 둘 다 물부터 마셔요."],["rho","의무관이 제일 무섭네."]],"choices":[]},
    {"id":"trio_dax_noa_eli_050","speaker":"dax","tag":"trio","participants":["dax","noa","eli"],"action":"다렌, 노아, 루칸이 한 화면에 시간표·기록·항로를 세 겹으로 띄운다.","lines":[["noa","문장 기록은 07:37이에요."],["eli","경로 보정은 07:39."],["dax","센서 재시작은 그 사이. 셋 중 하나가 원인이 아니라 순서가 문제네."],["noa","그럼 순서를 바꾸지 말고 그대로 남겨요."]],"choices":[]},
    {"id":"trio_mira_lyra_sena_050","speaker":"lyra","tag":"trio","participants":["mira","lyra","sena"],"action":"표본을살피다 마렌이 시든 잎을 들고 의료실에 오자 세나가 먼저 문을 열어 준다.","lines":[["lyra","이건 물 부족이 아니에요. 공기가 한동안 달랐어요."],["sena","환기 구역 출입 기록 볼게."],["mira","저는 그 시간 사람들 산소포화도 확인할게요."],["lyra","좋아요. 식물만 이상했던 건지 먼저 보죠."]],"choices":[]},
    {"id":"trio_noa_vale_eli_050","speaker":"noa","tag":"trio","participants":["noa","vale","eli"],"action":"문장을고치다 노아가 소렌의 음성 파형과 루칸의 항로 좌표를 한 문서에 나란히 붙인다.","lines":[["noa","같은 시각이라고 쓰진 않을게요. 가까운 시각이라고만."],["vale","좋아요. 제가 들은 건 정확한 시간보다 반복 간격이에요."],["eli","난 위치를 줄게. 셋이 겹치는 지점만 보자."],["noa","그럼 해석은 마지막에 한 줄만 써요."]],"choices":[]}
]
const HOME := {"mira":"medbay", "rho":"engine", "dax":"archive", "noa":"archive", "sena":"security", "vale":"comms", "eli":"navigation", "lyra":"garden"}
const DESTINATIONS := ["지구 귀환", "새 거주지", "외곽 탐사"]
# Beyond help/record/share/wait/observe/defend/hide (§16 of the design
# notes): confront presses a question instead of letting it pass, withhold
# declines to give an opinion (distinct from hide, which conceals evidence),
# keep_copy backs something up on the spot, and promise commits to a later
# action. Each still just feeds the same bond/echo math every other effect
# does — the new vocabulary is in what a scene's choices actually offer, not
# in a special code path.
const RESPONSES := {
    "mira":{"help":0.05,"wait":0.04,"record":0.02,"share":0.01,"hide":-0.03,"defend":0.03,"confront":-0.04,"withhold":0.0,"keep_copy":0.03,"promise":0.05},
    "rho":{"help":0.07,"wait":-0.02,"record":0.03,"share":0.04,"hide":0.01,"defend":0.03,"confront":0.02,"withhold":-0.02,"keep_copy":0.02,"promise":0.04},
    "dax":{"help":0.03,"wait":0.01,"record":0.05,"observe":0.03,"share":0.04,"hide":-0.02,"confront":-0.02,"withhold":0.01,"keep_copy":0.05,"promise":0.02},
    "noa":{"help":0.02,"record":0.06,"share":0.04,"observe":0.03,"hide":-0.05,"confront":0.01,"withhold":0.02,"keep_copy":0.06,"promise":0.02},
    "sena":{"help":0.05,"wait":-0.02,"defend":0.06,"share":0.02,"hide":-0.03,"confront":0.06,"withhold":-0.03,"keep_copy":0.02,"promise":0.03},
    "vale":{"wait":0.06,"observe":0.04,"record":0.03,"help":0.02,"share":0.01,"hide":0.01,"confront":-0.03,"withhold":0.03,"keep_copy":0.04,"promise":0.02},
    "eli":{"record":0.05,"observe":0.04,"help":0.03,"defend":-0.01,"share":0.02,"confront":-0.01,"withhold":0.02,"keep_copy":0.03,"promise":0.01},
    "lyra":{"help":0.06,"wait":0.03,"record":0.02,"share":0.05,"hide":-0.02,"confront":0.0,"withhold":-0.01,"keep_copy":0.03,"promise":0.06}
}

static func chapter(id: String) -> Dictionary:
    return CHAPTERS.get(id, CHAPTERS["DEAD_AIR"]).duplicate(true)

static func all_scenes() -> Array:
    var result: Array = SCENES.duplicate(true)
    result.append_array(AstraStorylets052.scenes())
    result.append_array(AstraStorylets053.scenes())
    result.append_array(AstraStorylets054.scenes())
    result.append_array(AstraStorylets055.scenes())
    return result

static func scene(id: String) -> Dictionary:
    for item in all_scenes():
        if item["id"] == id:
            return item.duplicate(true)
    return {}

static func awake_roster(id: String) -> Array:
    return AstraCrewCatalog.joined_on_day(campaign_day(id))

# The first two chapters are one-to-three rooms on purpose: a new player
# should never have to guess which of several doors leads somewhere useful
# (see the first-play redesign notes at the top of this file). Every room
# listed here must exist as a key in ROOMS above. A roster member whose HOME
# is not in this chapter's list still needs to be reachable, so
# gather_room() below gives them a place to be found instead.
const ROOM_PROFILE := {
    "CALIBRATION": ["medbay"],
    "DEAD_AIR": ["medbay", "comms", "archive"],
    "GLASS_GARDEN": ["medbay", "security", "garden"]
}

static func room_ids(roster: Array, case_id: String = "") -> Array:
    if ROOM_PROFILE.has(case_id):
        return ROOM_PROFILE[case_id].duplicate()
    var result: Array = ["medbay","engine","archive","comms","lounge"]
    for id in roster:
        var room := str(HOME[id])
        if room not in result:
            result.append(room)
    return result

# Where a roster member is found when their real HOME is outside this
# chapter's trimmed room list (e.g. Rho's engine is not one of DEAD_AIR's
# three rooms). Always the first room in the chapter's own list, so it is
# never a room the player cannot reach.
static func gather_room(case_id: String) -> String:
    var rooms: Array = ROOM_PROFILE.get(case_id, [])
    return str(rooms[0]) if not rooms.is_empty() else "medbay"

static func home_room(npc_id: String, case_id: String) -> String:
    var home := str(HOME[npc_id])
    var profile: Array = ROOM_PROFILE.get(case_id, [])
    if profile.is_empty() or home in profile:
        return home
    return gather_room(case_id)

# Calendar contract is authored explicitly, independently of CAMPAIGN indices.
# A case has its own local days; replays return to the chapter's campaign date.
const CAMPAIGN_DATES := {"CALIBRATION":1,"DEAD_AIR":2,"GLASS_GARDEN":3,"ECHO_WARD":4,"SILENT_ORBIT":5,"RED_SHIFT":6,"LAST_LIGHT":7}
static func campaign_day(id: String) -> int:
    return int(CAMPAIGN_DATES.get(id,1))

const FIRST_RECORD := "포드 전원 공급은 정상이다. 장기수면 중인 동료는 네 명이다. 잠금 해제 이력의 실행자 칸이 비어 있다."
const FIRST_CONTRIBUTIONS := {
    "mira":"의무관 미라. 장기수면 후 당신의 상태를 살피고 생명유지 신호의 해석 범위를 설명한다.",
    "rho":"기관 담당 준. 공구를 챙겨 각성 점검을 돕는다. 전원 고장과 정비 가능성을 구분한다.",
    "dax":"시스템 설계자 다렌. 상태 기록과 실행자 기록을 구분하고, 빈칸을 고의 조작으로 단정하지 않는다.",
    "noa":"기록관 노아. 확정된 사실과 아직 확인하지 못한 항목을 나눠 적는다."
}
const FIRST_THREADS := {
    "first_wake": {
        "action":"수면에서 깨어난 당신을 미라가 의료실에서 살핀다. 옆에서 세 동료가 각성 점검을 돕고 있다.",
        "lines":[["mira","저는 의무관 미라예요. 장기수면 뒤에는 여기서 상태를 확인해요. 당신은 ASTRA의 탐사요원이고요."],
            ["rho","기관 담당 준이야. 손은 천천히 움직여. 공구는 내가 들게."],
            ["dax","다렌. 시스템 설계자야. 남은 포드를 열기 전에 전원 상태를 확인해야 해."],
            ["noa","기록관 노아예요. 확인한 것만 적을게요. 먼저 포드 제어 패널을 눌러 주세요."]],"choices":[]},
    "first_panel": {
        "requires_fact":"power","action":"당신이 연 포드 제어 패널을 네 동료가 함께 본다. 전원 표시와 잠금 이력은 서로 다른 칸이다.",
        "lines":[["rho","공급 전원은 정상이야. 지금 포드가 닫혀 있는 걸 정전 탓으로 볼 수는 없어."],
            ["mira","생명유지 신호도 안정적이에요. 그럼 왜 해제 이력에 이름이 없을까요?"],
            ["dax","상태 기록은 무엇이 일어났는지, 실행자 칸은 누가 요청했는지야. 빈칸만으로 고의 조작이라고 할 수는 없어."],
            ["noa","전원 정상, 실행자 칸 공백. 여기까지가 사실이에요. 원인은 아직 빈칸으로 둘게요."]],
        "choices":[{"label":"잠금 이력의 원본과 복사본부터 비교한다 · 공동 확인","effect":"check_source"},
            {"label":"정비 중 남은 기록인지 준에게 묻는다 · 질문","effect":"check_maintenance"}]},
    "first_source": {
        "requires_fact":"power","action":"다렌이 원본 보기와 읽기 전용 사본을 나란히 연다. 노아가 비교 기준을 적는다.",
        "lines":[["dax","지금 볼 수 있는 두 화면에는 같은 빈칸이 있어. 복사 과정만 문제였는지는 이전 백업이 있어야 알 수 있어."],
            ["noa","현재 원본에도 공백. 이전 백업은 미확인. 두 문장을 나눠 남길게요."],
            ["mira","상태 확인은 끝났어요. 오늘은 누구도 격리하지 않고 다음 포드의 각성을 준비해요."]],"choices":[]},
    "first_maintenance": {
        "requires_fact":"power","action":"준이 공구를 내려놓고 패널의 상태 항목을 다시 읽는다.",
        "lines":[["rho","정비 중에도 잠금 상태는 달라질 수 있어. 하지만 누가 어떤 작업을 했는지는 이 화면만으로 몰라."],
            ["dax","맞아. 전원 고장과 작업 이력은 따로 확인하자. 내일 출입 기록을 붙이면 범위를 줄일 수 있어."],
            ["mira","지금 생명유지는 안정적이에요. 오늘은 누구도 격리하지 않고 다음 포드의 각성을 준비해요."]],"choices":[]}
}
const ARRIVALS := {
    "sena": {"action":"전날 확인한 전원으로 보안 담당 포드의 순차 각성이 끝난다. 세나가 일어나 출입문부터 살핀다.",
        "lines":[["sena","보안 책임자 세나야. 문이 열리는 쪽부터 확인할게. 준, 뒤쪽 봐 줘."],["rho","알았어. 잠깐만, 공구부터 챙기고."],
            ["sena","통신실까지 통로는 안전해. 기록을 가져올 수 있어. 잠금 이력은 사용자 칸과 열림 상태를 나눠 봐야 해."],
            ["noa","통로 확인은 세나의 관찰로 남길게요. 빈 서명의 이유는 아직 몰라요."],
            ["sena","이상하네. 준이랑 같이 근무한 기억이 있는데… 그 기록은 일 끝나고 같이 보자."]]},
    "vale": {"action":"확인된 통로를 통해 다음 포드 점검이 끝난다. 소렌은 눈을 뜨자 경보음과 수신음을 따로 줄인다.",
        "lines":[["vale","통신관 소렌이에요. 지금 나는 소리는 경보예요. 누군가 말하는 신호와는 달라요."],
            ["sena","좋아. 보안 구역의 알림이 어디서 오는지 같이 확인하자."],
            ["vale","발신 장치와 재생 장치를 따로 적어 둘게요. 같은 소리라고 같은 출처는 아니니까요."],
            ["noa","오늘 구역 점검 기록에 그 기준을 붙일게요."],
            ["vale","수면 중에 제 이름을 들은 것 같아요. 기억뿐이라, 녹음이 있는지부터 찾아볼게요."]]},
    "eli": {"action":"순차 각성 점검이 항법 담당 포드에 도달한다. 루칸은 난간을 잡고 창과 항로 화면을 번갈아 본다.",
        "lines":[["eli","항법사 루칸이야. 서두르지 마. 화면 시각부터 맞추자."],
            ["vale","신호 기록과 포드 기록을 대조하려고 해요. 시각 기준을 봐 줄래요?"],
            ["eli","두 장치의 시계를 따로 적어. 가까운 시각을 같다고 합치면 없던 모순도 생겨."],
            ["noa","각 장치의 출처도 붙여 둘게요."],
            ["eli","내가 만든 항로 사본이 있을 거야. 원본과 왜 따로 뒀는지는 직접 확인하고 말할게."]]},
    "lyra": {"action":"마지막 순차 각성 포드가 열린다. 마렌이 물컵을 받아 들고 생태 구역 상태표부터 찾는다.",
        "lines":[["lyra","생태학자 마렌이에요. 물은 조금이면 돼요. 시료 보관 상태도 같이 볼까요?"],
            ["mira","먼저 한 모금 마셔요. 상태표는 가져다 드릴게요."],
            ["lyra","고마워요. 오래된 도착 기록을 볼 때 보관 기간도 대조해요. 시료가 지낸 시간은 문장과 별도로 확인할 수 있어요."],
            ["eli","좋아. 오늘 항로 기록 옆에 그 기준을 남기자."],
            ["lyra","폐기 목록에 있던 작은 모종이 마음에 걸려요. 아직 남아 있는지는 가서 봐야겠어요."]]}
}

static func linked_thread(id: String, data: Dictionary, participants: Array, requires_fact: String = "") -> Dictionary:
    var result := data.duplicate(true)
    result.merge({"id":id,"speaker":str(participants[0]),"participants":participants.duplicate(),"category":"MANDATORY","tag":"work","choices":[],"thread":true,"compressible":false},false)
    result["requires_fact"] = str(data.get("requires_fact",requires_fact))
    result["scope"] = "present_participants"
    result["reuse"] = "once_per_case"
    result["location"] = "medbay"
    result["forbids"] = {"absent_participant":true}
    var intentions: Array = {
        "first_wake":["introduce","offer_help","explain_goal","request_action"],
        "first_panel":["observation","source_question","limit_claim","separate_fact_hypothesis"],
        "first_source":["compare_sources","record_uncertainty","safe_next_step"],
        "first_maintenance":["alternative_hypothesis","agree_and_limit","safe_next_step"]
    }.get(id,["introduce","respond","contribute","record","personal_question"])
    var beats: Array = []
    for i in range(result.get("lines",[]).size()):
        beats.append({"id":id+":"+str(i),"speaker":result["lines"][i][0],"response_to":"" if i == 0 else id+":"+str(i-1),
            "intent":str(intentions[mini(i,intentions.size()-1)]),"source":result["requires_fact"] if result["requires_fact"] != "" else "current_observation_or_own_role",
            "requires_fact":result["requires_fact"],"expression":"determined" if i == 0 and id != "first_wake" else "neutral"})
    result["beats"] = beats
    return result

static func first_thread(id: String) -> Dictionary:
    return linked_thread(id,FIRST_THREADS.get(id,{}),AstraCrewCatalog.INITIAL)

static func arrival_thread(who: String) -> Dictionary:
    if not ARRIVALS.has(who): return {}
    var participants: Array = []
    for line in ARRIVALS[who]["lines"]:
        if line[0] not in participants: participants.append(line[0])
    return linked_thread("arrival_"+who,ARRIVALS[who],participants)
