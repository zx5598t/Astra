class_name AstraCaseCatalog
extends RefCounted

# Static incident templates. The generator turns one of these into a concrete,
# seeded case: who the two Nulls are, where everyone really was, and which
# clues exist in which room.

const CAMPAIGN := ["DEAD_AIR", "GLASS_GARDEN", "ECHO_WARD"]

const CASES := {
    "DEAD_AIR": {
        "code": "INCIDENT ZERO",
        "title": "DEAD AIR",
        "title_ko": "데드 에어",
        "theme": "전력 우회 · 통신 차단",
        "difficulty": 1,
        "accent": "55d6ff",
        "environment": "res://assets/environments/dead_air.svg",
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
        "theme": "영양액 오염 · 정수 인터록 우회",
        "difficulty": 2,
        "accent": "71e39b",
        "environment": "res://assets/environments/glass_garden.svg",
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
        "theme": "냉동수면 포드 해제 · 의료 기록 은폐",
        "difficulty": 3,
        "accent": "c79bff",
        "environment": "res://assets/environments/echo_ward.svg",
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
