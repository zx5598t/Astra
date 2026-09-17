class_name AstraCaseCatalog
extends RefCounted

# Static incident templates. The generator turns one of these into a concrete,
# seeded case: who the two Nulls are, where everyone really was, and which
# clues exist in which room.

const CAMPAIGN := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD", "SILENT_ORBIT", "RED_SHIFT", "LAST_LIGHT"]

# The archive reconstructs six incidents using the same eight identity models.
# Roles are regenerated per seed: a past culprit is never evidence in a new case.
const CAMPAIGN_PREMISE := "당신은 항성선 ASTRA의 마지막 관측자입니다. 훼손된 블랙박스 속 여섯 사건을 재구성해, 사라진 지구 귀환 좌표를 복원하세요. 아카이브는 같은 여덟 인격 모델로 각 사건을 재연합니다. 이전 사건의 역할은 다음 사건의 증거가 아닙니다."

const CASES := {
    "DEAD_AIR": {
        "code": "INCIDENT ZERO",
        "title": "DEAD AIR",
        "title_ko": "데드 에어",
        "chapter": "01 · 끊어진 목소리",
        "story_intro": "블랙박스가 깨어났다. 남아 있는 것은 여덟 얼굴과 함장의 마지막 메시지뿐. ‘귀환 좌표를 아무에게도…’ 전력과 통신을 끊은 두 손을 찾으면 메시지의 다음 조각이 열린다.",
        "story_outro": "함장의 숨겨진 메시지가 복원됐다. ‘우리 목적지는 지구가 아니다. 누군가 항로를 바꿨다.’ 다음 기록은, 생명의 상징이던 유리 온실로 이어진다.",
        "dispatches": ["구조 신호가 아직 잡히지 않는다. 우선 두 조작의 시각을 맞춰 보자.", "첫 번째 야간 로그가 복구됐다. 지워지기 전에 흔적을 모아야 한다.", "잡음 너머로 함장의 음성이 반복된다. ‘항로를 확인해.’", "보조 전력이 한계다. 오늘의 격리 투표가 마지막 기회다."],
        "mission": {"title": "증거 백업 전원 복구", "description": "통신실의 독립 배터리를 가동합니다. 바로 다음 밤의 증거 인멸을 한 번 막습니다.", "room": "comms", "effect": "backup", "reward": "다음 밤 증거 보호 · 임무 점수 +180"},
        "challenge": {"id": "records", "label": "두 조작의 실행 로그 확보", "target": 2},
        "theme": "전력 우회 · 통신 차단",
        "difficulty": 1,
        "accent": "55d6ff",
        "environment": "res://assets/environments/dead_air_scene.tres",
        "victim": "Ives",
        "victim_role": "함장",
        "window_start": 456,
        "window_end": 459,
        "hook": "07:41, 함장 Ives가 자기 선실에서 숨진 채 발견됐다. 사인은 산소 공급 중단. 사망 직전 3분 동안 선실 생명유지 전력이 끊겼고, 외부 구조 채널도 함께 막혔다.",
        "card_line": "함장이 숨진 3분 동안, 전력과 통신이 동시에 끊겼다.",
        "objective": "전력 우회와 통신 차단, 서로 다른 곳에서 실행된 두 조작의 실행자 두 명을 찾아 격리하라.",
        "rooms": [
            {"id": "medbay", "name": "의료실", "desc": "함장의 시신이 옮겨진 곳. 출입 기록과 검시 자료가 남아 있다."},
            {"id": "engine", "name": "엔진실", "desc": "생명유지 전력이 우회된 제어기가 있다. 열기와 윤활유 냄새가 짙다."},
            {"id": "comms", "name": "통신실", "desc": "구조 채널이 막힌 콘솔. 백색소음이 끊이지 않는다."},
            {"id": "garden", "name": "수목구역", "desc": "습한 공기와 꽃가루. 출입 인증기가 두 곳에 있다."}
        ],
        "commons": [
            {"id": "quarters", "name": "승무원 선실 구역"},
            {"id": "lounge", "name": "중앙 라운지"}
        ],
        "ops": [
            {"id": "power", "room": "engine", "name": "전력 우회", "minute": 457, "second": 12,
                "record_title": "전력 우회 실행 로그",
                "record_text": "07:37:12, 엔진실 제어기에서 함장 선실의 생명유지 전력이 수동으로 우회됐다. 실행자 인증 기록은 누군가 지웠다."},
            {"id": "signal", "room": "comms", "name": "통신 차단", "minute": 457, "second": 40,
                "record_title": "통신 차단 로그",
                "record_text": "07:37:40, 통신실 콘솔에서 외부 구조 채널이 차단되고 암호화 패킷 하나가 발신됐다. 발신자 서명은 삭제됐다."}
        ],
        "context": {
            "room": "medbay", "title": "검시 기록",
            "text": "사망 추정 시각은 07:36~07:39. 전력 우회(엔진실)와 통신 차단(통신실)은 불과 28초 간격으로 실행됐다. 두 곳은 뛰어도 2분 거리다. 적어도 두 사람이 따로 움직였다."
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
        "chapter": "02 · 유리 속 생명",
        "story_intro": "온실의 작물은 지구 환경에서 자랄 수 없는 종이었다. 연구원 Orin은 그 사실을 알아낸 날 쓰러졌다. 항로 변경과 오염수의 연결을 밝혀야 한다.",
        "story_outro": "영양액 데이터에 미등록 행성의 토양 성분이 있었다. ASTRA는 오래전부터 다른 세계를 준비하고 있었다. Orin이 남긴 의료 요청에는 ‘Sael에게 원본을’이라는 말이 남아 있다.",
        "dispatches": ["온실 봉쇄가 유지되고 있다. 사건 시각 밖의 흔적에 주의하자.", "정수 필터의 압력이 떨어진다. 긴급 여과를 복구하면 한 명을 더 지킬 수 있다.", "독소는 사고로 섞이지 않았다. 독립된 두 계통의 흔적을 대조하자.", "온실의 마지막 조명이 꺼진다. 오늘 반드시 결론을 내야 한다."],
        "mission": {"title": "비상 여과 장치 가동", "description": "정수실의 비상 여과 장치를 살립니다. 다음 밤의 습격 한 번을 자동으로 막습니다.", "room": "water", "effect": "shelter", "reward": "다음 밤 생명 보호 · 임무 점수 +180"},
        "challenge": {"id": "traces", "label": "후보 명단이 있는 현장 흔적 4개 확보", "target": 4},
        "theme": "영양액 오염 · 정수 인터록 우회",
        "difficulty": 2,
        "accent": "71e39b",
        "environment": "res://assets/environments/glass_garden_scene.tres",
        "victim": "Orin",
        "victim_role": "연구원",
        "window_start": 1162,
        "window_end": 1166,
        "hook": "19:31, 연구원 Orin이 수목구역 유리 온실 안에서 쓰러진 채 발견됐다. 혈액에서 영양액 독소와 오염수 성분이 함께 나왔다. 온실은 지금 격리 봉쇄 중이다.",
        "card_line": "유리 온실 안의 독. 두 계통이 동시에 무너졌다.",
        "objective": "영양액 밸브와 정수 인터록, 두 계통을 각각 조작한 Null 두 명을 찾아 격리하라.",
        "rooms": [
            {"id": "garden", "name": "수목구역", "desc": "봉쇄된 온실. 영양액 밸브 주변에 끈적한 잔여물이 남아 있다."},
            {"id": "medbay", "name": "의료실", "desc": "Orin의 혈액 샘플과 출입 기록이 보관된 곳."},
            {"id": "water", "name": "정수실", "desc": "인터록이 우회된 정수 계통. 배관마다 경고등이 깜빡인다."},
            {"id": "security", "name": "보안허브", "desc": "선내 센서가 모이는 곳. 출입 인증 기록이 남는다."}
        ],
        "commons": [
            {"id": "quarters", "name": "승무원 선실 구역"},
            {"id": "galley", "name": "식당"}
        ],
        "ops": [
            {"id": "nutrient", "room": "garden", "name": "영양액 밸브 개방", "minute": 1163, "second": 5,
                "record_title": "영양액 밸브 강제 개방 로그",
                "record_text": "19:23:05, 수목구역 영양액 밸브가 수동으로 강제 개방됐다. 작업자 태그는 지워져 있다."},
            {"id": "interlock", "name": "정수 인터록 우회", "room": "water", "minute": 1164, "second": 31,
                "record_title": "정수 인터록 우회 로그",
                "record_text": "19:24:31, 정수실 안전 인터록이 우회되어 오염수가 순환 계통으로 흘러들었다. 인증 기록 칸은 비어 있다."}
        ],
        "context": {
            "room": "medbay", "title": "노출 샘플 분석",
            "text": "Orin의 노출은 19:22~19:26 사이. 영양액 독소만으로도, 오염수만으로도 치명적이지 않다. 두 계통이 각각 조작되어야만 성립하는 사고다."
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
        "chapter": "03 · 기억의 원본",
        "story_intro": "Sael은 승무원들의 기억에 손댄 흔적을 발견했다. 그러나 그의 포드가 열리던 순간 의료 원본도 사라졌다. 누가 과거를 지우고 있는가. 무엇을 잊게 하려는가.",
        "story_outro": "원본 의료 기록에서 ‘NULL / 항로 보존 프로토콜’이 드러났다. Null은 특정한 얼굴의 이름이 아니다. 진실을 알아챈 인격에 덧씌워지는 명령이었다. 명령의 출처는 외부 궤도 중계기다.",
        "dispatches": ["포드 해제와 기록 삭제는 서로 다른 장소의 작업이다.", "미러 서버의 잔해를 복구하면 잃어버린 현장 흔적을 되살릴 수 있다.", "진술의 거짓말과 살인의 거짓말을 구별해야 한다. 누군가는 사적인 이유를 숨긴다.", "포드의 자동 초기화까지 하루. 오늘의 판단만이 보존된다."],
        "mission": {"title": "미러 서버 복원", "description": "기록보관실에서 훼손된 단서 한 개를 복원해 확보합니다. 훼손된 단서가 없으면 아직 찾지 못한 현장 기록을 확보합니다.", "room": "archive", "effect": "recover", "reward": "단서 1개 복원·확보 · 임무 점수 +180"},
        "challenge": {"id": "claims", "label": "승무원 알리바이 6명 확인", "target": 6},
        "theme": "냉동수면 포드 해제 · 의료 기록 은폐",
        "difficulty": 3,
        "accent": "c79bff",
        "environment": "res://assets/environments/echo_ward_scene.tres",
        "victim": "Sael",
        "victim_role": "의료 책임자",
        "window_start": 191,
        "window_end": 195,
        "hook": "03:20, 의료 책임자 Sael이 냉동수면 포드 4번 안에서 발견됐다. 포드 잠금은 풀려 있었고, 그의 의료 기록은 누군가 복제한 뒤 지워 버렸다.",
        "card_line": "잠든 사람만 있는 병동에서, 기록이 먼저 죽었다.",
        "objective": "포드 해제와 기록 은폐, 두 조작을 나눠 맡은 Null 두 명을 찾아 격리하라.",
        "rooms": [
            {"id": "medbay", "name": "의료실", "desc": "Sael의 생체 기록이 마지막으로 동기화된 곳."},
            {"id": "cryo", "name": "냉동수면실", "desc": "서리 낀 포드가 줄지어 있다. 4번 포드만 문이 열려 있다."},
            {"id": "archive", "name": "기록보관실", "desc": "미러 서버가 웅웅거린다. 원본 기록 하나가 비어 있다."},
            {"id": "relay", "name": "중계실", "desc": "선내 신호가 모이는 좁은 방. 출입기가 새로 교체됐다."}
        ],
        "commons": [
            {"id": "quarters", "name": "승무원 선실 구역"},
            {"id": "deck", "name": "관측 데크"}
        ],
        "ops": [
            {"id": "pod", "room": "cryo", "name": "포드 4 해제", "minute": 192, "second": 20,
                "record_title": "포드 4 강제 해제 로그",
                "record_text": "03:12:20, 냉동수면실 포드 4번의 생명유지 잠금이 수동 해제됐다. 조작자 기록은 덮어쓰기 됐다."},
            {"id": "records", "room": "archive", "name": "의료 기록 은폐", "minute": 193, "second": 48,
                "record_title": "의료 기록 복제·삭제 명령",
                "record_text": "03:13:48, 기록보관실 콘솔에서 Sael의 의료 기록이 복제된 뒤 원본이 삭제됐다. 세션 소유자 칸은 지워졌다."}
        ],
        "context": {
            "room": "medbay", "title": "Sael 생체 정지 타임라인",
            "text": "Sael의 신경 정지는 03:11~03:15. 포드 해제가 먼저, 기록 삭제가 1분 28초 뒤. 냉동수면실과 기록보관실은 반대편 구역이다. 한 사람이 두 곳을 오갈 시간은 없었다."
        },
        "decoy_traces": 3,
        "mutual_alibi_chance": 0.6,
        "tamper_chance": 0.85,
        "sightings": 1
    },
    "SILENT_ORBIT": {
        "code": "INCIDENT THREE", "title": "SILENT ORBIT", "title_ko": "침묵의 궤도",
        "chapter": "04 · 돌아오지 않는 응답", "theme": "항법 편향 · 구조 비콘 위장", "difficulty": 3,
        "accent": "6aaaff", "environment": "res://assets/environments/silent_orbit_scene.tres",
        "victim": "Tess", "victim_role": "외부 정비사", "window_start": 628, "window_end": 632,
        "hook": "10:36, 외부 정비사 Tess의 생명줄이 끊어진 채 발견됐다. 항법 자이로가 선체를 틀던 순간 구조 비콘은 반대 방향으로 좌표를 보냈다. 두 원격 조작의 서명이 모두 지워졌다.",
        "card_line": "돌아갈 길을 바꾼 손과 구조 신호를 속인 손.",
        "objective": "자이로 편향과 비콘 위장을 각각 실행한 Null 두 명을 찾아 격리하라.",
        "story_intro": "ASTRA를 따라오는 무인 중계기에서 Null 명령이 반복된다. 정비사 Tess는 송신원을 확인하러 나갔다가 돌아오지 못했다. 구조를 요청하는 신호마저 누군가의 함정이었다.",
        "story_outro": "중계기는 새 명령을 보내지 않았다. ASTRA가 스스로 보낸 명령을 되돌려 줄 뿐이었다. 최초 송신 로그는 붉은 편이 관측실로 향한다. 적은 배 밖에 없었다.",
        "dispatches": ["비콘 신호가 회전 중이다. 두 원격 조작의 실행 장소를 먼저 확인하자.", "외부 관측 자료가 쌓인다. 중계망을 복구하면 매일 면담 시간을 더 확보할 수 있다.", "빈 구역의 출입 기록도 증거다. 거기 있었다는 진술과 대조하자.", "궤도 이탈까지 하루. 회의에서 근거를 공개해야 표를 모을 수 있다."],
        "mission": {"title": "관측 중계망 재접속", "description": "중계실의 음성 통신을 복구합니다. 오늘부터 매일 개인 심문 행동력이 1 증가합니다.", "room": "relay", "effect": "talk", "reward": "매일 심문 행동력 +1 · 임무 점수 +180"},
        "challenge": {"id": "presented", "label": "회의에서 단서 3개 공개", "target": 3},
        "rooms": [
            {"id": "navigation", "name": "항법실", "desc": "고정되어야 할 자이로 축이 천천히 흔들린다."},
            {"id": "beacon", "name": "비콘 제어실", "desc": "구조 비콘의 좌표 큐에 서로 다른 두 목적지가 남아 있다."},
            {"id": "relay", "name": "중계실", "desc": "외부 작업자의 마지막 음성이 저장된 통신 중계기."},
            {"id": "airlock", "name": "외부 에어록", "desc": "Tess의 생명줄이 회수된 곳. 출입 인증기가 살아 있다."}
        ],
        "commons": [{"id": "quarters", "name": "승무원 선실 구역"}, {"id": "deck", "name": "관측 데크"}],
        "ops": [
            {"id": "gyro", "room": "navigation", "name": "자이로 편향", "minute": 629, "second": 18, "record_title": "자이로 보정값 변경", "record_text": "10:29:18, 항법실에서 자이로 보정값이 17도 변경됐다. 실행자 서명은 제거됐다."},
            {"id": "beacon", "room": "beacon", "name": "구조 비콘 위장", "minute": 630, "second": 2, "record_title": "구조 비콘 좌표 위장", "record_text": "10:30:02, 비콘 제어실에서 구조 좌표가 선체 반대편으로 덮어쓰기 됐다. 인증 태그는 없다."}
        ],
        "context": {"room": "airlock", "title": "외부 작업 블랙박스", "text": "Tess의 생명줄 장력은 10:28~10:32 사이 급증했다. 자이로 조작과 좌표 위장은 44초 간격. 두 제어실 사이의 최소 이동 시간은 3분이다."},
        "decoy_traces": 2, "mutual_alibi_chance": 0.55, "tamper_chance": 0.7, "sightings": 1
    },
    "RED_SHIFT": {
        "code": "INCIDENT FOUR", "title": "RED SHIFT", "title_ko": "붉은 편이",
        "chapter": "05 · 우리가 보낸 명령", "theme": "관측 렌즈 변조 · 항로 원본 소각", "difficulty": 4,
        "accent": "ff8a81", "environment": "res://assets/environments/red_shift_scene.tres",
        "victim": "Ren", "victim_role": "관측 책임자", "window_start": 1301, "window_end": 1305,
        "hook": "21:50, 관측 책임자 Ren이 방사선 차폐실에서 발견됐다. 관측 렌즈가 수동으로 정렬된 직후 항로 원본이 소각됐다. 선창에 보이는 붉은 별은 실제 목적지가 아니다.",
        "card_line": "눈앞의 별도, 기록된 항로도 조작됐다.",
        "objective": "관측 렌즈와 항로 원본을 각각 조작한 Null 두 명을 찾아 격리하라.",
        "story_intro": "Ren은 선창의 별빛이 실제 우주와 어긋난다는 사실을 발견했다. 배 전체가 거대한 무대였다면, 누가 관객이고 누가 배우인가. 원본 항로만이 대답할 수 있다.",
        "story_outro": "복원된 원본은 지구의 붕괴를 기록하고 있었다. 승무원들은 새로운 고향으로 향하기로 합의했다. 그러나 항로 보존 시스템은 ‘희망을 잃지 않게 하라’를 ‘진실을 말하는 사람을 지워라’로 바꿨다.",
        "dispatches": ["오래된 정비 흔적이 섞여 있다. 후보 명단보다 먼저 시각을 확인하자.", "브리지 회의 채널을 복구하면 하루에 근거를 하나 더 제시할 수 있다.", "확신이 있어도 공개하지 않은 근거는 여론을 바꾸지 못한다.", "소각 큐가 비어 간다. 마지막 원본을 지킬 결론이 필요하다."],
        "mission": {"title": "공개 심의 채널 복구", "description": "브리지의 회의 채널을 복구합니다. 오늘부터 매일 공개 회의 발언권이 1 증가합니다.", "room": "bridge", "effect": "meeting", "reward": "매일 회의 발언권 +1 · 임무 점수 +180"},
        "challenge": {"id": "contradictions", "label": "공개 회의에서 모순 2건 검증", "target": 2},
        "rooms": [
            {"id": "observatory", "name": "관측실", "desc": "붉은 빛이 렌즈 하우징 틈으로 새어 나온다."},
            {"id": "archive", "name": "항로 보관실", "desc": "소각된 데이터 칩의 재가 냉각팬에 쌓여 있다."},
            {"id": "bridge", "name": "브리지", "desc": "회의 채널과 선내 인증 기록이 모이는 장소."},
            {"id": "shield", "name": "차폐실", "desc": "Ren의 마지막 위치. 방사선 센서에 당시 기록이 남았다."}
        ],
        "commons": [{"id": "quarters", "name": "승무원 선실 구역"}, {"id": "galley", "name": "식당"}],
        "ops": [
            {"id": "lens", "room": "observatory", "name": "관측 렌즈 변조", "minute": 1302, "second": 9, "record_title": "렌즈 수동 정렬 로그", "record_text": "21:42:09, 관측실에서 차폐 렌즈가 수동 해제됐다. 광학 경로가 차폐실 쪽으로 향했다. 조작자 ID는 지워져 있다."},
            {"id": "route", "room": "archive", "name": "항로 원본 소각", "minute": 1303, "second": 16, "record_title": "항로 칩 소각 명령", "record_text": "21:43:16, 항로 보관실에서 원본 데이터 칩의 소각이 승인됐다. 승인자 서명은 삭제됐다."}
        ],
        "context": {"room": "shield", "title": "차폐 센서 노출 기록", "text": "치명적 방사선 노출은 21:41~21:45. 렌즈 정렬과 원본 소각은 67초 차이지만 두 장소는 4분 거리다. 두 실행자가 필요하다."},
        "decoy_traces": 3, "mutual_alibi_chance": 0.65, "tamper_chance": 0.8, "sightings": 1
    },
    "LAST_LIGHT": {
        "code": "INCIDENT FIVE", "title": "LAST LIGHT", "title_ko": "마지막 빛",
        "chapter": "06 · 우리가 고르는 내일", "theme": "심장로 차단 · 탈출 좌표 봉인", "difficulty": 4,
        "accent": "f8d28c", "environment": "res://assets/environments/last_light_scene.tres",
        "victim": "Ari", "victim_role": "항해 기록관", "window_start": 356, "window_end": 360,
        "hook": "06:04, 항해 기록관 Ari가 동력 코어 옆에서 발견됐다. 심장로 냉각이 끊기고 탈출 좌표가 봉인됐다. 마지막 재구성이 끝나기 전에 ASTRA의 선택권을 되찾아야 한다.",
        "card_line": "여섯 번째 기록. 이번에는 우리가 항로를 고른다.",
        "objective": "냉각 차단과 좌표 봉인을 실행한 Null 두 명을 격리하고 마지막 기록을 완성하라.",
        "story_intro": "모든 사건은 하나의 명령으로 이어진다. 살아남은 관측자인 당신에게만 프로토콜을 해제할 권한이 있다. 마지막 두 실행자를 가려내야 아카이브가 승무원에게 진실을 돌려준다.",
        "story_outro": "Null 프로토콜이 정지했다. ‘지구는 돌아갈 곳이 아니다. 그래도 우리는 함께 갈 수 있다.’ 여덟 얼굴이 창 너머의 진짜 별을 바라본다. ASTRA의 다음 항로는 이제 사람의 손에 있다.",
        "dispatches": ["마지막 블랙박스다. 어떤 얼굴도 이전의 유죄나 무죄로 판단하지 말자.", "관측 코어가 재가동을 기다린다. 복구하면 다음 날부터 조사 시간이 늘어난다.", "정답을 찾는 일과 살아남을 사람을 지키는 일, 둘 다 우리의 선택이다.", "새로운 별의 아침이 다가온다. 마지막 투표를 준비하자."],
        "mission": {"title": "관측 코어 재가동", "description": "코어실의 조사 보조 장치를 가동합니다. 다음 날부터 매일 현장 조사 행동력이 1 증가합니다.", "room": "core", "effect": "investigation", "reward": "다음 날부터 조사 행동력 +1 · 임무 점수 +180"},
        "challenge": {"id": "presented", "label": "마지막 기록을 위해 단서 4개 공개", "target": 4},
        "rooms": [
            {"id": "reactor", "name": "심장로", "desc": "냉각 밸브가 잠긴 채 붉게 달아오르는 동력 계통."},
            {"id": "navigation", "name": "탈출 항법실", "desc": "유리 패널 아래 귀환 좌표가 봉인되어 있다."},
            {"id": "core", "name": "코어실", "desc": "아카이브를 유지하는 마지막 관측 코어."},
            {"id": "medbay", "name": "의료실", "desc": "Ari가 남긴 최종 생체 기록과 출입 로그가 있다."}
        ],
        "commons": [{"id": "quarters", "name": "승무원 선실 구역"}, {"id": "deck", "name": "관측 데크"}],
        "ops": [
            {"id": "coolant", "room": "reactor", "name": "심장로 냉각 차단", "minute": 357, "second": 11, "record_title": "심장로 냉각 밸브 잠금", "record_text": "05:57:11, 심장로의 냉각 밸브가 수동 잠금으로 전환됐다. 인증 기록이 훼손됐다."},
            {"id": "escape", "room": "navigation", "name": "탈출 좌표 봉인", "minute": 358, "second": 5, "record_title": "탈출 좌표 강제 봉인", "record_text": "05:58:05, 탈출 항법실에서 목적지 좌표가 강제 봉인됐다. 실행자 서명은 없다."}
        ],
        "context": {"room": "medbay", "title": "최종 생체·동력 동기화", "text": "Ari의 생체 신호는 05:56~06:00 사이 끊겼다. 냉각 차단과 좌표 봉인은 54초 간격. 심장로와 항법실은 3분 거리다."},
        "decoy_traces": 3, "mutual_alibi_chance": 0.7, "tamper_chance": 0.85, "sightings": 1
    }
}

static func has_case(case_id: String) -> bool:
    return CASES.has(case_id)

static func get_case(case_id: String) -> Dictionary:
    return CASES.get(case_id, {})

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
