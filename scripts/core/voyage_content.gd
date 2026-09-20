class_name AstraVoyageContent
extends RefCounted

const CHAPTERS := {
    "CALIBRATION": {
        "title": "눈을 뜬 자리",
        "goal": "수면실 전력이 끊긴 이유를 확인한다.",
        "fact": "power",
        "discovery": "수면실 잠금이 풀렸다. 실행자 칸은 비어 있다.",
        "outro": "노아가 방금 적은 날짜를 가리킨다. 하루 전이다. 미라가 다시 당신의 손목을 잡는다. “들리나요?”",
        "awake": "",
        "room": "medbay"
    },
    "DEAD_AIR": {
        "title": "마지막 교신",
        "goal": "서로 다른 목적지 기록의 출처를 찾는다.",
        "fact": "destination",
        "discovery": "귀환 승인서와 탐사 명령서가 같은 날 서명됐다. 두 문서 모두 원본이다.",
        "outro": "통신이 잠깐 열린다. 돌아온 것은 당신이 아직 하지 않은 말이다.",
        "awake": "",
        "room": "comms"
    },
    "GLASS_GARDEN": {
        "title": "유리 정원",
        "goal": "세나와 함께 잠긴 구역의 안전을 확인한다.",
        "fact": "security",
        "discovery": "세나의 순찰 기록에는 준과 함께 근무한 날이 있다. 준의 배치 기록에는 그날이 없다.",
        "outro": "세나가 열쇠를 돌리기 전에 문이 열린다. 안쪽 손잡이에 누군가의 손자국이 남아 있다.",
        "awake": "sena",
        "room": "security"
    },
    "ECHO_WARD": {
        "title": "메아리 병동",
        "goal": "소렌이 들은 신호를 의료 기록과 대조한다.",
        "fact": "signal",
        "discovery": "수면 중인 소렌의 음성이 통신 기록에 남아 있다. 같은 시간 포드는 닫혀 있었다.",
        "outro": "녹음 속 소렌이 숨을 들이마신다. 옆에 앉은 소렌은 숨을 멈춘다.",
        "awake": "vale",
        "room": "comms"
    },
    "SILENT_ORBIT": {
        "title": "고요한 궤도",
        "goal": "루칸과 항로 기록의 빈 구간을 확인한다.",
        "fact": "arrival",
        "discovery": "ASTRA — 목적지 도착 완료. 기록 날짜는 현재보다 19년 전이다.",
        "outro": "루칸이 창밖을 본다. 항로 화면의 별은 움직이는데, 창밖의 별은 그대로다.",
        "awake": "eli",
        "room": "navigation"
    },
    "RED_SHIFT": {
        "title": "다른 하늘",
        "goal": "마렌의 시료와 선내 자원 기록을 비교한다.",
        "fact": "sample",
        "discovery": "씨앗의 채집 장소는 ASTRA의 목적지다. 채집일은 출항일보다 이르다.",
        "outro": "마렌이 흙을 봉투에 돌려놓는다. 뿌리에 묻은 작은 이름표는 당신의 필체다.",
        "awake": "lyra",
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
        "action": "미라가 빈 컵을 치우다가 당신 앞에 물 한 잔을 둔다.",
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
        "action": "미라는 당신의 손목을 잡고 시계를 본다.",
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
        "action": "미라가 장갑을 벗어 당신에게 맡긴다.",
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
        "action": "미라는 열린 진료 기록을 덮는다.",
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
        "action": "미라가 당신과 출입문 사이에 선다.",
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
        "action": "미라는 당신이 내민 기록을 끝까지 읽는다.",
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
        "action": "미라가 젖은 소매를 걷는다.",
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
        "action": "미라가 당신의 팔을 세게 당긴다.",
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
        "action": "미라는 맥박계를 끄고 벽에 등을 붙인다.",
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
        "action": "미라가 컵을 당신의 왼쪽에 놓았다가 잠깐 멈춘다.",
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
        "action": "미라가 예약표를 손가락으로 짚는다.",
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
        "action": "미라가 이름표 한 장을 새로 쓴다. 처음 쓴 것은 접어 주머니에 넣는다.",
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
        "action": "미라가 의자 두 개를 이어 놓는다.",
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
        "action": "미라가 당신의 눈앞에서 손가락 두 개를 움직인다.",
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
        "action": "미라가 한 사람 몫을 더 꺼냈다가 조용히 돌려놓는다.",
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
        "action": "준이 렌치를 마이크처럼 들다가 미라의 시선을 보고 내려놓는다.",
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
        "action": "준이 바닥에 엎드린 채 손을 내민다.",
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
        "action": "준이 덜 잠긴 공구함을 당신 쪽으로 민다.",
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
        "action": "준이 작업대 위의 서류를 자기 쪽으로 당긴다.",
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
        "action": "준이 웃다가 다렌의 화면을 보고 입을 다문다.",
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
        "action": "준이 두 손을 펴 보인다. 손끝에 검은 기름이 묻었다.",
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
        "action": "준이 바닥에 떨어진 나사를 하나씩 센다.",
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
        "action": "준이 공구를 놓고 차단기를 내린다.",
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
        "action": "준이 바닥에 주저앉는다.",
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
        "action": "준이 공구를 건네며 예전처럼 손잡이 방향을 바꾼다.",
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
        "action": "준이 정비표 뒤에 그려 둔 작은 행성을 보여 준다.",
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
        "action": "준이 같은 나사를 세 번째 풀었다 조인다.",
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
        "action": "준이 미라의 빈 컵을 챙긴다.",
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
        "action": "준이 농담을 시작하려다가 공구함 뚜껑을 닫는다.",
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
        "action": "다렌이 차가운 음료를 한 모금 마시고 컵을 내려놓는다.",
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
        "action": "다렌이 화면 두 개를 나란히 돌려놓는다.",
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
        "action": "다렌이 계산 중인 화면을 당신 쪽으로 돌린다.",
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
        "action": "다렌이 손을 멈추고 당신을 본다.",
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
        "action": "다렌이 준이 그은 선을 지우지 않고 새 선을 옆에 긋는다.",
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
        "action": "다렌이 기록의 서명을 확대한다.",
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
        "action": "다렌이 이미 끝난 검사를 다시 시작한다.",
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
        "action": "다렌이 연결선을 직접 뽑는다.",
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
        "action": "다렌이 의자를 당겨 당신에게 내준다.",
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
        "action": "다렌이 당신이 말하기 전에 보조 화면을 켠다.",
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
        "action": "다렌이 임무서의 봉인을 확인한다.",
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
        "action": "다렌이 오래된 경고 메시지를 닫지 못한다.",
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
        "action": "다렌이 화면 밝기를 낮춘다.",
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
        "action": "다렌이 의료실 문을 손으로 받치고 있다.",
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
        "action": "다렌이 빈 의자의 화면을 꺼 준다.",
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
        "action": "노아가 바닥의 메모를 주워 반듯하게 편다.",
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
        "action": "노아가 두 문장의 끝에 작은 선을 긋는다.",
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
        "action": "노아가 아직 저장하지 않은 메모를 보여 준다.",
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
        "action": "노아가 단말을 끄지 않은 채 화면을 아래로 돌린다.",
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
        "action": "노아가 다렌의 말을 적다가 멈춘다.",
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
        "action": "노아가 빈 줄을 한 칸 남긴다.",
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
        "action": "노아가 젖은 종이를 말린다.",
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
        "action": "노아가 단말을 품에 안고 문에서 물러난다.",
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
        "action": "노아가 저장 버튼을 누른 뒤에야 숨을 내쉰다.",
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
        "action": "노아가 당신이 쓰던 빈 의자를 비워 둔다.",
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
        "action": "노아가 서로 다른 명부를 나란히 놓는다.",
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
        "action": "노아가 문장 하나를 지우려다 손을 멈춘다.",
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
        "action": "노아가 글씨가 번진 책갈피를 바꾼다.",
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
        "action": "노아가 당신의 이름 아래에 작은 점을 찍는다.",
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
        "action": "노아가 다음 줄을 비워 두었다.",
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
        "action": "세나가 벽에 등을 대고 준과 손 크기를 비교한다.",
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
        "action": "세나가 문 안쪽 손잡이를 먼저 당긴다.",
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
        "action": "세나가 당신에게 여분의 출입 카드를 건넨다.",
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
        "action": "세나가 막힌 통로 앞에서 고개를 젓는다.",
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
        "action": "세나가 준을 따라 통로로 들어선다.",
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
        "action": "세나가 순찰표를 내려놓는다.",
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
        "action": "세나가 모든 문을 한 번씩 다시 당겨 본다.",
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
        "action": "세나가 당신을 등 뒤로 밀어 넣는다.",
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
        "action": "세나가 당신의 어깨를 가볍게 친다.",
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
        "action": "세나가 당신이 움찔하자 먼저 손을 뻗었다가 거둔다.",
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
        "action": "세나가 준을 향해 낡은 순찰표를 펼친다.",
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
        "action": "세나가 잠긴 문 너머를 오래 본다.",
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
        "action": "세나가 의자 대신 출입문 옆에 앉는다.",
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
        "action": "세나가 가져온 물 두 병 중 하나를 내려놓는다.",
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
        "action": "소렌이 이어폰 한쪽을 빼 책 위에 올려놓는다.",
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
        "action": "소렌이 손을 들어 조용히 해 달라는 표시를 한다.",
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
        "action": "소렌이 말없이 이어폰 한쪽을 당신에게 건넨다.",
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
        "action": "소렌이 녹음을 멈춘다.",
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
        "action": "소렌이 루칸의 항로 화면을 가리킨다.",
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
        "action": "소렌이 자기 목소리가 녹음된 구간을 다시 튼다.",
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
        "action": "소렌이 케이블을 손가락에 감았다가 푼다.",
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
        "action": "소렌이 수신 음량을 내린다.",
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
        "action": "소렌이 이어폰을 벗는다.",
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
        "action": "소렌이 당신에게 맞춰 이어폰 줄을 한 칸 늘려 둔다.",
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
        "action": "소렌이 목적지 호출 부호를 적는다.",
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
        "action": "소렌이 재생 버튼 위에 손을 올린다.",
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
        "action": "소렌이 스피커를 아주 작게 켜 둔다.",
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
        "action": "소렌이 음성 파일을 복사하고 원본을 다시 잠근다.",
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
        "action": "루칸이 의자를 창 쪽으로 돌렸다가 통로가 보이게 다시 놓는다.",
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
        "action": "루칸이 항로 위에 손을 얹는다.",
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
        "action": "루칸이 당신을 관측창 옆으로 부른다.",
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
        "action": "루칸이 화면을 축소해 전체 항로를 띄운다.",
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
        "action": "루칸이 소렌의 신호 도착 방향에 선을 긋는다.",
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
        "action": "루칸이 항로 수정 기록을 연다.",
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
        "action": "루칸이 빈 포드의 번호를 확인한다.",
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
        "action": "루칸이 당신의 발앞을 가리킨다.",
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
        "action": "루칸이 손잡이에서 천천히 손을 뗀다.",
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
        "action": "루칸이 좁은 통로에서 당신이 설 자리를 미리 비운다.",
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
        "action": "루칸이 도착 기록을 확대한다.",
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
        "action": "루칸이 우회 항로를 지우려다 사본을 만든다.",
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
        "action": "루칸이 아무도 없는 수면실 문을 조금 열어 본다.",
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
        "action": "루칸이 항로 화면에서 한 지점을 오래 바라본다.",
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
        "action": "마렌이 작은 화분을 당신 쪽으로 돌린다.",
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
        "action": "마렌이 급수 밸브를 반쯤 잠근다.",
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
        "action": "마렌이 발아한 씨앗을 당신 손바닥에 얹는다.",
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
        "action": "마렌이 시료 상자를 두 손으로 받친다.",
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
        "action": "마렌이 미라 앞에 급수표를 놓는다.",
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
        "action": "마렌이 잘라 낸 줄기를 보여 준다.",
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
        "action": "마렌이 쓰러진 화분을 세우다 손을 멈춘다.",
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
        "action": "마렌이 당신의 손에서 뚜껑을 뺏는다.",
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
        "action": "마렌이 마른 흙에 물 한 방울을 떨군다.",
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
        "action": "마렌이 당신 앞에 늘 놓던 작은 화분을 옮겨 둔다.",
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
        "action": "마렌이 씨앗 봉투의 채집지를 읽는다.",
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
        "action": "마렌이 시든 잎을 떼지 못하고 가위만 닦는다.",
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
        "action": "마렌이 생태실 등을 하나씩 끈다.",
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
        "action": "마렌이 아무 이름도 쓰지 않은 화분을 창가에 둔다.",
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
        "action": "준이 미라의 컵을 슬쩍 들어 본다.",
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
        "action": "노아가 다렌의 단말 옆에 종이를 붙인다.",
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
        "action": "세나가 준보다 먼저 공구함을 집어 든다.",
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
        "action": "소렌이 짧은 신호를 틀자 루칸이 창을 본다.",
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
        "action": "마렌이 의료실에 새 화분을 놓는다.",
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
        "action": "준이 부품 상자에 서툰 글씨로 이름을 적는다.",
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
        "action": "다렌이 준의 배선 옆에 다른 선을 놓는다.",
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
        "action": "미라가 잠든 노아의 손에서 단말을 받는다.",
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
        "action": "세나가 멈춘 자동문을 발로 받친다.",
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
        "action": "루칸이 화분을 창가에서 옮긴다.",
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
        "action": "미라가 구겨진 처방전을 펴 놓는다.",
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
        "action": "미라가 빈 의자를 발로 당긴다.",
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
        "action": "미라가 동료의 손을 펼쳐 보인다.",
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
        "action": "미라는 의료 서류 한 장을 따로 접는다.",
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
        "action": "미라가 당신이 손목을 만지는 것을 보고 멈춘다.",
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
        "action": "준이 공구 손잡이를 닦아 내민다.",
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
        "action": "준이 떨어진 나사를 손으로 가리킨다.",
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
        "action": "준이 장갑을 벗어 작업대를 짚는다.",
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
        "action": "준이 대장에 빠진 번호를 적는다.",
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
        "action": "준이 발소리를 멈추고 바닥에 귀를 댄다.",
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
        "action": "다렌이 계산에 그은 줄을 보여 준다.",
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
        "action": "다렌이 두 창을 띄워 놓고 뒤로 물러난다.",
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
        "action": "다렌이 승인 목록을 끝까지 내린다.",
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
        "action": "다렌이 비어 있는 칸에 손가락을 올린다.",
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
        "action": "노아가 잘못 붙인 이름표를 떼어 낸다.",
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
        "action": "노아가 녹음을 멈춘다.",
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
        "action": "노아가 앞선 대화의 한 줄을 가리킨다.",
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
        "action": "노아가 자기 배치 기록을 꺼낸다.",
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
        "action": "노아는 당신이 말하기 전에 빈칸을 만든다.",
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
        "action": "세나가 통로를 비켜 선다.",
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
        "action": "세나가 문을 받친 채 손을 뻗는다.",
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
        "action": "세나가 출입 기록을 돌려 보여 준다.",
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
        "action": "세나가 당신보다 먼저 모퉁이에서 멈춘다.",
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
        "action": "소렌이 헤드폰 한쪽을 당신에게 건넨다.",
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
        "action": "소렌이 재생 표시를 가리킨다.",
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
        "action": "소렌이 두 음성을 나란히 재생한다.",
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
        "action": "소렌이 개인 채널 목록을 연다.",
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
        "action": "루칸이 접어 둔 지도를 다시 편다.",
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
        "action": "루칸이 항로 화면의 두 점을 짚는다.",
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
        "action": "루칸이 조종석을 당겨 앉는다.",
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
        "action": "루칸이 작은 저장장치를 책상에 놓는다.",
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
        "action": "루칸이 멀리 있는 별을 손으로 가린다.",
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
        "action": "마렌이 닫아 둔 상자 뚜껑을 연다.",
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
        "action": "마렌이 화분 밑에 마른 천을 넣는다.",
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
        "action": "마렌이 급수표의 자기 서명을 가리킨다.",
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
        "action": "마렌이 작은 모종을 조심스럽게 꺼낸다.",
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
    }
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

static func scene(id: String) -> Dictionary:
    for item in SCENES:
        if item["id"] == id:
            return item.duplicate(true)
    return {}

static func awake_roster(id: String) -> Array:
    var count := maxi(0, AstraCaseCatalog.CAMPAIGN.find(id))
    return AstraCrewCatalog.INITIAL + AstraCrewCatalog.AWAKENING_ORDER.slice(0, mini(count,4))

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
