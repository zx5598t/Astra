class_name AstraCaseCatalog
extends RefCounted

# Static incident templates. The generator turns one of these into a concrete,
# seeded case: who the two Nulls are, where everyone really was, and which
# clues exist in which room.

const CALIBRATION := "CALIBRATION"
const CAMPAIGN := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD", "SILENT_ORBIT", "RED_SHIFT", "LAST_LIGHT"]

# The archive reconstructs six incidents using the same eight identity models.
# Roles are regenerated per seed: a past culprit is never evidence in a new case.
const CAMPAIGN_PREMISE := "당신은 ASTRA의 탐사요원이다. 네 명의 동료가 깨어 있고 네 명은 아직 장기수면 중이다. 서로 다른 목적지 기록을 확인하며 잠긴 구역을 연다. 어제의 기억과 오늘의 기록이 조금씩 달라진다."

const CASES := {
    "CALIBRATION": {
        "code": "CALIBRATION",
        "title": "FIRST CONTACT",
        "title_ko": "첫 접속",
        "chapter": "00 · 교정",
        "tier": "calibration",
        "roster": ["mira", "rho", "noa", "sena"],
        "null_count": 1,
        "max_days": 1,
        "story_intro": "아카이브가 처음으로 안정적인 조각을 붙잡았다. 네 사람, 한 시간, 하나의 조작. 여기서 재구성하는 법을 익힌다.",
        "story_outro": "첫 조각이 고정됐다. 사람의 말과 배의 기록은 같은 사건을 다르게 말한다. 이제 더 큰 기록을 열 수 있다.",
        "dispatches": ["네 명뿐이다. 말과 기록을 한 번씩만 맞춰 보면 된다."],
        "mission": {},
        "challenge": {"id": "claims", "label": "네 사람의 진술 확인", "target": 3},
        "theme": "수면 포드 무단 해제",
        "difficulty": 0,
        "accent": "8fbee5",
        "environment": "res://assets/art031/backgrounds/bridge.webp",
        "subject": "수면 중인 승무원",
        "subject_role": "생체 신호 유지 중",
        "window_start": 450,
        "window_end": 460,
        "hook": "04:17, 수면실 포드 한 개의 잠금이 풀렸다. 실행자 칸은 비어 있다. 그 시간에 배에는 네 사람이 깨어 있었다.",
        "card_line": "네 사람. 하나의 빈 서명. 아무도 04:17을 기억하지 못한다.",
        "objective": "기록과 기억이 어긋나는 지점을 확인한다.",
        # These feed the older alibi/trace generator, which runs at setup()
        # regardless of whether CALIBRATION ever visually reaches it, and
        # needs enough distinct positions to place four innocents. It is not
        # the same list as the one-room EXPLORE layout the player actually
        # sees (see AstraVoyageContent.room_ids).
        "rooms": [
            {"id": "medbay", "name": "의료실", "desc": "포드의 마지막 생체 기록이 남은 곳."},
            {"id": "engine", "name": "기관실", "desc": "정비 기록 단말이 벽에 붙어 있다."},
            {"id": "comms", "name": "통신실", "desc": "선내 신호가 오가는 콘솔."}
        ],
        "commons": [
            {"id": "lounge", "name": "중앙 라운지"}
        ],
        # One trace instead of two. With four people a single trace already
        # narrows the field to two, and the access logs finish the job — which
        # is one inference to teach instead of two stacked on each other.
        "trace_steps": 1,
        # get_case() clears variants for CALIBRATION outright (see below), so
        # this entry carries no seed-rotated hooks of its own.
        "variants": [],
        "ops": [
            {"id": "power", "room": "medbay", "name": "포드 잠금 해제", "minute": 457, "second": 20,
                "record_title": "수면 포드 잠금 해제 로그",
                "record_text": "04:17:20, 의료실 포드의 생명유지 잠금이 수동으로 해제됐다. 실행자 서명 칸은 비어 있다."}
        ],
        "context": {
            "room": "medbay", "title": "포드 상태 기록",
            "text": "장기수면 포드의 생체 신호는 정상이다. 잠금 해제는 현장의 콘솔에서 실행됐다. 실행자 기록은 비어 있다."
        },
        "decoy_traces": 0,
        "mutual_alibi_chance": 0.0,
        "tamper_chance": 0.0,
        "sightings": 1
    },
    "DEAD_AIR": {
        "code": "INCIDENT ZERO",
        "title": "DEAD AIR",
        "title_ko": "데드 에어",
        "chapter": "01 · 마지막 교신",
        "story_intro": "장거리 통신이 갑자기 끊겼다. 장비는 멀쩡하다. 누군가 정확한 절차를 밟아 외부 송신 채널을 껐다.",
        "story_outro": "귀환 승인서와 탐사 명령서, 서로 다른 목적지를 적은 두 문서가 같은 날 원본으로 서명됐다. 어느 쪽도 위조가 아니다.",
        "dispatches": ["통신 채널이 닫힌 시각을 먼저 확인하자.", "같은 날짜에 서명된 문서가 두 장 있다. 둘 다 원본이다.", "누구의 기억도 완전히 틀리지 않았다.", "짧게라도 의견을 모아 보자."],
        "mission": {"title": "통신 예비 전원 확보", "description": "통신실의 독립 배터리를 가동합니다. 바로 다음 밤의 기록 손실을 한 번 막습니다.", "room": "comms", "effect": "backup", "reward": "다음 밤 기록 보호 · 임무 점수 +180"},
        "challenge": {"id": "records", "label": "실행 기록과 서명 문서 확보", "target": 1},
        "theme": "통신 차단 · 서명이 겹치는 두 문서",
        "difficulty": 1,
        "accent": "55d6ff",
        "environment": "res://assets/art031/backgrounds/bridge.webp",
        "subject": "수면 중인 승무원",
        "subject_role": "생체 신호 유지 중",
        "window_start": 456,
        "window_end": 459,
        "hook": "07:41, 외부 송신 채널이 절차대로 닫혔다. 사고가 아니다. 같은 날, 서로 다른 목적지를 적은 문서 두 장이 원본으로 남아 있다.",
        "card_line": "채널을 끈 손 하나. 목적지가 두 개로 적힌 문서.",
        "objective": "통신을 끈 실행자와, 두 문서가 함께 원본으로 존재하는 이유를 확인한다.",
        "rooms": [
            {"id": "medbay", "name": "의료실", "desc": "포드와 개인 기록 단말이 있는 곳."},
            {"id": "comms", "name": "통신실", "desc": "외부 송신 채널이 닫힌 콘솔. 백색소음이 끊이지 않는다."},
            {"id": "archive", "name": "기록보관실", "desc": "귀환 승인서와 탐사 명령서 원본이 나란히 보관된 곳."}
        ],
        "commons": [
            {"id": "quarters", "name": "승무원 선실 구역"},
            {"id": "lounge", "name": "중앙 라운지"}
        ],
        "ops": [
            {"id": "signal", "room": "comms", "name": "통신 채널 차단", "minute": 457, "second": 40,
                "record_title": "통신 채널 차단 로그",
                "record_text": "07:37:40, 통신실 콘솔에서 외부 송신 채널이 절차대로 닫혔다. 실행자 서명 칸은 비어 있다."},
            {"id": "records", "room": "archive", "name": "이중 서명 문서 발견", "minute": 457, "second": 12,
                "record_title": "귀환·탐사 명령서 대조 기록",
                "record_text": "07:37:12, 기록보관실에서 귀환 승인서와 탐사 명령서가 함께 확인됐다. 두 문서 모두 같은 날 서명된 원본이다."}
        ],
        "context": {
            "room": "medbay", "title": "동기화 기록",
            "text": "통신 채널 차단과 이중 서명 문서는 같은 시간대에 겹친다. 어느 한쪽이 실수라고 보기 어렵다."
        },
        "decoy_traces": 0,
        "mutual_alibi_chance": 0.25,
        "tamper_chance": 0.45,
        "sightings": 1
    },
    "GLASS_GARDEN": {
        "code": "INCIDENT ONE",
        "title": "GLASS GARDEN",
        "title_ko": "글래스 가든",
        "chapter": "02 · 유리 정원",
        "story_intro": "잠긴 보안 구역의 전력이 나갔다. 세나가 복구를 맡는다. 세나는 준과 함께 과거의 사고를 겪었다고 기억하지만, 준은 그 일을 전혀 모른다.",
        "story_outro": "세나가 열쇠를 돌리기 전에 안쪽에서 문이 열렸다. 안에는 아무도 없었지만, 손잡이에는 방금 쓴 것 같은 흔적이 남아 있다.",
        "dispatches": ["보안 구역 전력부터 복구하자.", "세나의 근무 기록에는 있고, 준의 기록에는 없는 날이 있다.", "짧게 의견을 모아도 된다. 결론은 서두르지 않아도 된다.", "문이 저절로 열렸다. 안쪽 손잡이부터 확인하자."],
        "mission": {"title": "보안 구역 예비 전력 복구", "description": "보안허브의 예비 전력을 살립니다. 다음 밤의 접근 시도 한 번을 자동으로 막습니다.", "room": "security", "effect": "shelter", "reward": "다음 밤 구역 보호 · 임무 점수 +180"},
        "challenge": {"id": "traces", "label": "근무 기록과 현장 흔적 대조", "target": 2},
        "theme": "잠긴 구역의 전력 · 엇갈리는 근무 기록",
        "difficulty": 2,
        "accent": "71e39b",
        "environment": "res://assets/art031/backgrounds/garden.webp",
        "subject": "잠긴 보안 구역",
        "subject_role": "접근 기록 불일치",
        "window_start": 1162,
        "window_end": 1166,
        "hook": "19:31, 잠긴 보안 구역의 전력이 원인 없이 꺼졌다. 세나의 근무 기록에는 준과 함께 이 구역에서 일했던 날이 있다. 준의 기록에는 그날이 없다.",
        "card_line": "한쪽 기록에는 있고, 다른 쪽에는 없는 하루.",
        "objective": "전력을 내린 실행자와, 두 사람의 기록이 서로 다른 이유를 확인한다.",
        "rooms": [
            {"id": "security", "name": "보안허브", "desc": "선내 센서가 모이는 곳. 출입 인증 기록이 남는다."},
            {"id": "garden", "name": "수목구역", "desc": "세나와 준이 함께 일했다는 기록이 남은 구역."},
            {"id": "medbay", "name": "의료실", "desc": "세나의 각성 직후 생체 기록이 남은 곳."}
        ],
        "commons": [
            {"id": "quarters", "name": "승무원 선실 구역"},
            {"id": "galley", "name": "식당"}
        ],
        "ops": [
            {"id": "lockdown", "room": "security", "name": "보안 구역 전력 차단", "minute": 1163, "second": 5,
                "record_title": "보안 구역 전력 차단 로그",
                "record_text": "19:23:05, 보안허브에서 잠긴 구역의 전력이 수동으로 차단됐다. 실행자 서명 칸은 비어 있다."},
            {"id": "roster", "name": "근무 기록 대조", "room": "garden", "minute": 1164, "second": 31,
                "record_title": "근무 배치 기록 대조",
                "record_text": "19:24:31, 수목구역 근무 배치 기록을 대조했다. 세나 쪽 기록에만 두 사람이 함께 일한 날이 남아 있다."}
        ],
        "context": {
            "room": "medbay", "title": "각성 직후 생체 기록",
            "text": "세나의 근무 기록과 준의 근무 기록은 같은 날짜를 서로 다르게 적고 있다. 한쪽이 지워진 흔적은 없다."
        },
        "decoy_traces": 2,
        "mutual_alibi_chance": 0.4,
        "tamper_chance": 0.65,
        "sightings": 1
    },
    "ECHO_WARD": {
        "code": "INCIDENT TWO",
        "title": "ECHO WARD",
        "title_ko": "에코 병동",
        "chapter": "03 · 메아리 병동",
        "story_intro": "통신망에서 약한 반복 신호가 잡힌다. 소렌이 재생 버튼을 누르기도 전에 파형의 한 구간부터 확대한다. 이유는 말하지 않는다.",
        "story_outro": "복구된 신호에는 승무원들의 목소리가 섞여 있다. 일부는 이미 나눈 대화다. 일부는 아직 나눈 적 없는 대화다.",
        "dispatches": ["신호가 어디서 시작됐는지부터 확인하자.", "미러 서버를 복구하면 잃어버린 구간을 되살릴 수 있다.", "누구의 목소리인지보다 언제의 대화인지가 더 이상하다.", "판단은 서두르지 않아도 된다."],
        "mission": {"title": "미러 서버 복원", "description": "기록보관실에서 훼손된 구간 하나를 복원해 확보합니다. 훼손된 구간이 없으면 아직 찾지 못한 신호 기록을 확보합니다.", "room": "archive", "effect": "recover", "reward": "신호 구간 1개 복원·확보 · 임무 점수 +180"},
        "challenge": {"id": "claims", "label": "승무원 알리바이 6명 확인", "target": 6},
        "theme": "반복 신호 · 이미 있었던 대화와 아직 없었던 대화",
        "difficulty": 3,
        "accent": "c79bff",
        "environment": "res://assets/art031/backgrounds/medical.webp",
        "subject": "복구된 통신 신호",
        "subject_role": "출처 미확인",
        "window_start": 191,
        "window_end": 195,
        "hook": "03:20, 통신망에서 약한 반복 신호가 잡혔다. 복구된 구간에는 승무원들의 목소리가 섞여 있다. 일부는 이미 나눈 대화이고, 일부는 아직 나눈 적 없는 대화다.",
        "card_line": "이미 들은 말과, 아직 하지 않은 말이 같은 신호에 섞여 있다.",
        "objective": "신호를 남긴 실행자와, 대화의 시간이 섞인 이유를 확인한다.",
        "rooms": [
            {"id": "medbay", "name": "의료실", "desc": "소렌의 각성 직후 생체 기록이 남은 곳."},
            {"id": "relay", "name": "중계실", "desc": "선내 신호가 모이는 좁은 방. 출입기가 새로 교체됐다."},
            {"id": "archive", "name": "기록보관실", "desc": "미러 서버가 웅웅거린다. 신호 구간 하나가 비어 있다."}
        ],
        "commons": [
            {"id": "quarters", "name": "승무원 선실 구역"},
            {"id": "deck", "name": "관측 데크"}
        ],
        "ops": [
            {"id": "signal", "room": "relay", "name": "반복 신호 기록", "minute": 192, "second": 20,
                "record_title": "반복 신호 수신 로그",
                "record_text": "03:12:20, 중계실에서 정체불명의 반복 신호가 수신됐다. 수신 승인자 칸은 비어 있다."},
            {"id": "records", "room": "archive", "name": "신호 구간 복원", "minute": 193, "second": 48,
                "record_title": "신호 구간 복원 기록",
                "record_text": "03:13:48, 기록보관실에서 신호의 한 구간이 복원됐다. 구간마다 시간대가 서로 어긋난다."}
        ],
        "context": {
            "room": "medbay", "title": "소렌 생체 동기화 기록",
            "text": "소렌의 각성은 03:11에 시작됐다. 반복 신호 수신은 그보다 앞선다. 아무도 그 시각을 설명하지 못한다."
        },
        "decoy_traces": 3,
        "mutual_alibi_chance": 0.6,
        "tamper_chance": 0.85,
        "sightings": 1
    },
    "SILENT_ORBIT": {
        "code": "INCIDENT THREE", "title": "SILENT ORBIT", "title_ko": "침묵의 궤도",
        "chapter": "04 · 고요한 궤도", "theme": "사라진 항법 구간 · 도착 완료 기록", "difficulty": 3,
        "accent": "6aaaff", "environment": "res://assets/art031/backgrounds/engine.webp",
        "subject": "항법 기록 일부", "subject_role": "구간 소실", "window_start": 628, "window_end": 632,
        "hook": "10:36, 항법 데이터의 한 구간이 사라졌다. 화면은 배가 계속 이동 중이라고 표시하지만, 관측창의 별은 며칠째 거의 움직이지 않는다.",
        "card_line": "화면 속 항로는 움직이는데, 창밖의 별은 그대로다.",
        "objective": "구간을 지운 실행자와, 복원된 기록이 가리키는 지점을 확인한다.",
        "story_intro": "루칸이 깨어난다. 그는 목적지보다 출발점부터 다시 확인한다.",
        "story_outro": "복원된 기록에 남은 문장은 하나다. ‘ASTRA — 목적지 도착 완료.’ 기록 날짜는 지금보다 19년 전이다.",
        "dispatches": ["사라진 구간의 경계부터 확인하자.", "중계망을 복구하면 매일 면담 시간을 더 확보할 수 있다.", "출입 기록도 증거다. 있었다는 진술과 대조하자.", "짧게 근거를 모아 보자."],
        "mission": {"title": "관측 중계망 재접속", "description": "중계실의 음성 통신을 복구합니다. 오늘부터 매일 개인 심문 행동력이 1 증가합니다.", "room": "relay", "effect": "talk", "reward": "매일 심문 행동력 +1 · 임무 점수 +180"},
        "challenge": {"id": "presented", "label": "회의에서 단서 3개 공개", "target": 3},
        "rooms": [
            {"id": "navigation", "name": "항법실", "desc": "구간이 비어 있는 항법 기록 화면."},
            {"id": "beacon", "name": "비콘 제어실", "desc": "오래된 도착 신호 하나가 큐에 남아 있다."},
            {"id": "relay", "name": "중계실", "desc": "외부 신호가 저장된 통신 중계기."}
        ],
        "commons": [{"id": "quarters", "name": "승무원 선실 구역"}, {"id": "deck", "name": "관측 데크"}],
        "ops": [
            {"id": "gyro", "room": "navigation", "name": "항법 구간 삭제", "minute": 629, "second": 18, "record_title": "항법 기록 구간 삭제 로그", "record_text": "10:29:18, 항법실에서 기록 구간 하나가 수동으로 삭제됐다. 실행자 서명은 제거됐다."},
            {"id": "beacon", "room": "beacon", "name": "도착 신호 복원", "minute": 630, "second": 2, "record_title": "도착 완료 신호 복원", "record_text": "10:30:02, 비콘 제어실에서 오래된 도착 완료 신호가 복원됐다. 발신 날짜는 19년 전이다."}
        ],
        "context": {"room": "navigation", "title": "항법 구간 대조", "text": "화면상의 항로와 실제 관측 결과가 어긋난다. 삭제된 구간과 복원된 도착 신호는 44초 차이로 겹친다."},
        "decoy_traces": 2, "mutual_alibi_chance": 0.55, "tamper_chance": 0.7, "sightings": 1
    },
    "RED_SHIFT": {
        "code": "INCIDENT FOUR", "title": "RED SHIFT", "title_ko": "붉은 편이",
        "chapter": "05 · 붉은 편이", "theme": "죽어 가는 생태 구역 · 정착용으로 분류된 식물", "difficulty": 4,
        "accent": "ff8a81", "environment": "res://assets/art031/backgrounds/security.webp",
        "subject": "생태 구역 표본", "subject_role": "분류 기록 불일치", "window_start": 1301, "window_end": 1305,
        "hook": "21:50, 생태 구역의 식물 일부가 이유 없이 죽기 시작했다. 남은 표본 중 일부는 기록상 ‘목적지 도착 이후 정착용’으로 분류되어 있다.",
        "card_line": "아직 도착하지 않았는데, 도착 이후를 위한 기록이 있다.",
        "objective": "표본을 재분류한 실행자와, 이번 루프의 관계 기록이 지난번과 달라진 이유를 확인한다.",
        "story_intro": "마렌이 깨어난다. 살릴 수 없는 표본을 냉정하게 골라내면서도, 손이 잠깐 멈춘다.",
        "story_outro": "이번 루프의 근무 기록에는 준과 세나가 이번 항해에서 처음 만났다고 적혀 있다. 지난번에는 분명 오래된 동료였다.",
        "dispatches": ["표본 분류 기록부터 확인하자.", "생태 구역 순환 장치를 복구하면 하루에 근거를 하나 더 제시할 수 있다.", "확신이 있어도 공개하지 않은 근거는 여론을 바꾸지 못한다.", "판단이 필요한 표본이 남아 있다."],
        "mission": {"title": "생태 구역 순환 장치 재가동", "description": "생태 구역의 순환 장치를 되살립니다. 오늘부터 매일 공개 회의 발언권이 1 증가합니다.", "room": "garden", "effect": "meeting", "reward": "매일 회의 발언권 +1 · 임무 점수 +180"},
        "challenge": {"id": "contradictions", "label": "공개 회의에서 모순 2건 검증", "target": 2},
        "rooms": [
            {"id": "garden", "name": "생태 구역", "desc": "죽어 가는 표본과 '정착용' 분류표가 함께 있다."},
            {"id": "archive", "name": "기록보관실", "desc": "근무 기록 원본이 보관된 곳."},
            {"id": "medbay", "name": "의료실", "desc": "마렌의 각성 직후 생체 기록이 남은 곳."}
        ],
        "commons": [{"id": "quarters", "name": "승무원 선실 구역"}, {"id": "galley", "name": "식당"}],
        "ops": [
            {"id": "sample", "room": "garden", "name": "표본 재분류", "minute": 1302, "second": 9, "record_title": "표본 분류 변경 로그", "record_text": "21:42:09, 생태 구역에서 표본 여러 개가 '정착용'으로 재분류됐다. 조작자 서명은 지워져 있다."},
            {"id": "history", "room": "archive", "name": "관계 기록 갱신", "minute": 1303, "second": 16, "record_title": "근무 기록 갱신 로그", "record_text": "21:43:16, 기록보관실에서 두 사람의 근무 이력이 다시 기록됐다. 이전 판본과 내용이 다르다."}
        ],
        "context": {"room": "medbay", "title": "각성 직후 생체 기록", "text": "표본 재분류와 관계 기록 갱신은 같은 시간대에 겹친다. 두 기록 모두 위조 흔적은 없다."},
        "decoy_traces": 3, "mutual_alibi_chance": 0.65, "tamper_chance": 0.8, "sightings": 1
    },
    "LAST_LIGHT": {
        "code": "INCIDENT FIVE", "title": "LAST LIGHT", "title_ko": "마지막 빛",
        "chapter": "06 · 마지막 빛", "theme": "불안정한 전력 계통 · 아주 오래된 기록", "difficulty": 4,
        "accent": "f8d28c", "environment": "res://assets/art031/backgrounds/archive.webp",
        "subject": "선내 전력 계통", "subject_role": "우선순위 미배정", "window_start": 356, "window_end": 360,
        "hook": "06:04, 주요 전력 계통이 불안정해졌다. 모든 시스템을 동시에 살릴 수 없다. 통신·장기수면·항법·생태·기록 보존 중 무엇을 먼저 지킬지 정해야 한다.",
        "card_line": "모두를 살릴 수는 없다. 무엇을 먼저 지킬 것인가.",
        "objective": "전력을 재배분한 실행자를 확인하고, 지금까지의 기록이 만나는 지점을 찾는다.",
        "story_intro": "선택은 단순한 수치가 아니다. 무엇을 지키느냐에 따라 다음에 볼 수 있는 기록이 달라진다.",
        "story_outro": "아주 오래된 기록 한 조각이 복구된다. ‘MISSION STATUS — ARRIVAL COMPLETE.’ 그 아래 승무원 수는 지금과 맞지 않는다. 다음 줄은 손상되어 있다.",
        "dispatches": ["전력 재배분 기록부터 확인하자.", "코어실을 복구하면 다음 날부터 조사 시간이 늘어난다.", "정답을 찾는 일과 무엇을 지킬지 정하는 일, 둘 다 우리의 선택이다.", "마지막 판단을 준비하자."],
        "mission": {"title": "관측 코어 재가동", "description": "코어실의 조사 보조 장치를 가동합니다. 다음 날부터 매일 현장 조사 행동력이 1 증가합니다.", "room": "core", "effect": "investigation", "reward": "다음 날부터 조사 행동력 +1 · 임무 점수 +180"},
        "challenge": {"id": "presented", "label": "마지막 기록을 위해 단서 4개 공개", "target": 4},
        "rooms": [
            {"id": "reactor", "name": "심장로", "desc": "전력 계통이 불안정하게 오르내리는 동력부."},
            {"id": "core", "name": "코어실", "desc": "오래된 기록을 보관한 마지막 관측 코어."},
            {"id": "archive", "name": "기록보관실", "desc": "손상된 기록 조각이 발견된 곳."},
            {"id": "medbay", "name": "의료실", "desc": "현재 생존 승무원의 생체 기록과 출입 로그가 있다."}
        ],
        "commons": [{"id": "quarters", "name": "승무원 선실 구역"}, {"id": "deck", "name": "관측 데크"}],
        "ops": [
            {"id": "power", "room": "reactor", "name": "전력 계통 재배분", "minute": 357, "second": 11, "record_title": "전력 우선순위 변경 로그", "record_text": "05:57:11, 심장로에서 전력 우선순위가 수동으로 재배분됐다. 실행자 서명이 없다."},
            {"id": "archive", "room": "archive", "name": "손상 기록 복구", "minute": 358, "second": 5, "record_title": "손상 기록 복구 로그", "record_text": "05:58:05, 기록보관실에서 오래된 기록 조각이 복구됐다. 복구자 서명은 없다."}
        ],
        "context": {"room": "medbay", "title": "현재 생체·동력 동기화", "text": "전력 재배분과 손상 기록 복구는 54초 간격으로 겹친다. 두 곳은 3분 거리다."},
        "decoy_traces": 3, "mutual_alibi_chance": 0.7, "tamper_chance": 0.85, "sightings": 1
    }
}

static func has_case(case_id: String) -> bool:
    return CASES.has(case_id)

static func get_case(case_id: String) -> Dictionary:
    var data: Dictionary = CASES.get(case_id, {}).duplicate(true)
    if data.is_empty():
        return data
    var story := AstraVoyageContent.chapter(case_id)
    data["roster"] = AstraVoyageContent.awake_roster(case_id)
    data["null_count"] = 1 if data["roster"].size() < 7 else 2
    data["trace_steps"] = 2
    data["max_days"] = 2 if data["roster"].size() < 7 else 4
    data["ops"] = data.get("ops",[]).slice(0,data["null_count"])
    data["title_ko"] = story["title"]
    data["story_intro"] = story["goal"]
    data["story_outro"] = story["outro"]
    data["card_line"] = story["goal"]
    data["hook"] = story["discovery"]
    data["objective"] = "기록과 증언이 어긋나는 이유를 확인한다."
    data["subject"] = "수면 중인 승무원"
    data["subject_role"] = "생체 신호 유지 중"
    data["chapter"] = "첫 각성" if case_id == CALIBRATION else str(data.get("chapter", ""))
    # Keep deterministic evidence templates; replace obsolete murder framing.
    data["dispatches"] = [story["goal"]]
    if case_id == CALIBRATION:
        data["max_days"] = 2
        data["variants"] = []
        data["ops"] = [{"id":"power", "room":"medbay", "name":"포드 잠금 해제", "minute":457, "second":20,
            "record_title":"수면 포드 잠금 해제 로그", "record_text":"04:17:20, 의료실 포드의 생명유지 잠금이 수동으로 해제됐다. 실행자 칸은 비어 있다."}]
        data["context"] = {"room":"medbay", "title":"포드 상태 기록", "text":"장기수면 포드의 생체 신호는 정상이다. 잠금 해제는 현장의 콘솔에서 실행됐다."}
    # Only topology and timestamps are shared with legacy cases. Current prose
    # never exposes the previous campaign's deaths or resolved ending.
    data["chapter"] = story["title"]
    data["theme"] = "기록과 기억의 불일치"
    data["context"] = {"room": data["context"]["room"], "title":"동기화 기록", "text": "이 구간의 기록에 승인자가 빠져 있다. 실행 시각의 흔적과 동료들의 동선을 대조할 수 있다."}
    for room in data["rooms"]:
        room["desc"] = str(room["name"]) + "의 설비와 출입 기록을 확인할 수 있다."
    for op in data["ops"]:
        op["record_text"] = "%s, %s에서 %s 명령이 실행됐다. 승인자 서명이 누락되어 있다." % [format_time(int(op["minute"]),int(op["second"])),room_name(data,str(op["room"])),str(op["name"])]
    data["mission"]["description"] = "동료와 설비를 복구한다. " + str(data["mission"].get("reward",""))
    # "records" targets are counted against ops[], which the null_count slice
    # above may have trimmed; never leave the objective asking for more
    # op-records than can exist in this roster (a real 0.4.0-era mismatch).
    if str(data.get("challenge",{}).get("id","")) == "records":
        data["challenge"]["target"] = maxi(1,mini(int(data["challenge"].get("target",1)),data["ops"].size()))
    return data

static func room_name(case_data: Dictionary, room_id: String) -> String:
    for room in case_data.get("rooms", []):
        if str(room.get("id", "")) == room_id:
            return str(room.get("name", room_id))
    for common in case_data.get("commons", []):
        if str(common.get("id", "")) == room_id:
            return str(common.get("name", room_id))
    return room_id

static func format_time(minutes: int, seconds: int = -1) -> String:
    var m := posmod(minutes, 1440)
    var text := "%02d:%02d" % [int(m / 60.0), m % 60]
    if seconds >= 0:
        text += ":%02d" % seconds
    return text

static func window_text(case_data: Dictionary) -> String:
    return "%s~%s" % [format_time(int(case_data.get("window_start", 0))), format_time(int(case_data.get("window_end", 0)))]

# ---------------------------------------------------------------- 0.4.0 shape

# Cases may run with fewer than the full eight identity models. CALIBRATION
# does; the campaign does not, because its fairness maths (crew minus Nulls
# across four days) was tuned for eight and re-tuning it would change every
# existing record. See docs/WHY_CHANGED.md.
static func roster(case_data: Dictionary) -> Array:
    var ids: Array = case_data.get("roster", [])
    if ids.is_empty():
        return AstraCrewCatalog.ORDER.duplicate()
    var ordered: Array = []
    for npc_id in AstraCrewCatalog.ORDER:
        if npc_id in ids:
            ordered.append(npc_id)
    return ordered

static func null_count(case_data: Dictionary) -> int:
    return clampi(int(case_data.get("null_count", 2)), 1, 2)

static func max_days(case_data: Dictionary) -> int:
    return clampi(int(case_data.get("max_days", 4)), 1, 6)

static func is_calibration(case_id: String) -> bool:
    return str(get_case(case_id).get("tier", "")) == "calibration"

static func op_count(case_data: Dictionary) -> int:
    return case_data.get("ops", []).size()

# Some cases carry `variants`: alternative versions of the same incident, same
# people and same lesson, differing in which room was touched, what was done and
# when. The variant is chosen from the seed, so the case is reproducible but a
# replay does not open on the sentence the player has already read.
#
# Only the keys a variant declares are replaced; everything else — roster, rooms,
# difficulty, the title — stays as written.
static func resolve(case_id: String, seed_value: int) -> Dictionary:
    var data := get_case(case_id)
    var variants: Array = data.get("variants", [])
    if variants.is_empty():
        return data
    var resolved := data.duplicate(true)
    var variant: Dictionary = variants[posmod(seed_value, variants.size())]
    for key in variant:
        resolved[key] = variant[key]
    resolved["variant_index"] = posmod(seed_value, variants.size())
    return resolved

static func variant_count(case_id: String) -> int:
    return maxi(1, get_case(case_id).get("variants", []).size())

# How many traces each Null leaves. Two have to be crossed to name one person;
# the tutorial uses one so there is a single inference to learn.
static func trace_steps(case_data: Dictionary) -> int:
    return clampi(int(case_data.get("trace_steps", 2)), 1, 2)

static func resolve_legacy(case_id: String, seed: int) -> Dictionary:
    var data: Dictionary = CASES.get(case_id,{}).duplicate(true)
    var variants: Array = data.get("variants",[])
    if not variants.is_empty():
        var variant: Dictionary = variants[posmod(seed,variants.size())]
        for key in variant: data[key]=variant[key]
    return data
