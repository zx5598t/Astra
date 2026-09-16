class_name TruthEngine
extends RefCounted

var seed_value: int = 260916
var rng := RandomNumberGenerator.new()
var facts: Dictionary = {}
var evidence: Dictionary = {}
var incident: Dictionary = {}

func setup(seed_in: int) -> void:
    seed_value = seed_in
    rng.seed = seed_value
    facts = {
        "FACT_001": {"text": "함장 Ives의 사망 시각은 07:36~07:39 사이다.", "secret": false},
        "FACT_002": {"text": "의료실 출입 로그에는 정확히 17초의 공백이 있다.", "secret": false},
        "FACT_003": {"text": "Rho는 정전 41초 전 전력 제어기에 접근했다.", "secret": true},
        "FACT_004": {"text": "Mira의 바이오 신호는 07:37 의료실에서 기록됐다.", "secret": true},
        "FACT_005": {"text": "통신실 로그 변조에는 보안 등급 B 이상이 필요하다.", "secret": true},
        "FACT_006": {"text": "Vale의 단말은 사망 추정 시각에 외부 채널로 암호화 패킷을 보냈다.", "secret": true},
        "FACT_007": {"text": "엔진실 냉각 점검은 정전 당시 자동 모드였으며 수동 점검이 필요하지 않았다.", "secret": true}
    }
    evidence = {
        "EV_01": {"name": "의료실 출입 로그", "fact_ref": "FACT_002", "location": "의료실", "rarity": "COMMON"},
        "EV_02": {"name": "바이오 센서 기록", "fact_ref": "FACT_004", "location": "의료실", "rarity": "KEY"},
        "EV_03": {"name": "전력 제어 기록", "fact_ref": "FACT_003", "location": "엔진실", "rarity": "KEY"},
        "EV_04": {"name": "냉각 계통 자동운전 로그", "fact_ref": "FACT_007", "location": "엔진실", "rarity": "KEY"},
        "EV_05": {"name": "통신실 권한 기록", "fact_ref": "FACT_005", "location": "통신실", "rarity": "COMMON"},
        "EV_06": {"name": "암호화 패킷 흔적", "fact_ref": "FACT_006", "location": "통신실", "rarity": "KEY"}
    }
    incident = {
        "title": "INCIDENT ZERO",
        "subtitle": "Dead Air",
        "victim": "Captain Ives",
        "locations": ["의료실", "엔진실", "통신실"],
        "null_ids": ["rho", "vale"],
        "objective": "증거와 증언을 대조해 Null 침투자 한 명을 격리하라."
    }

func fact_text(fact_id: String) -> String:
    return str(facts.get(fact_id, {}).get("text", "알 수 없는 사실"))

func evidence_name(ev_id: String) -> String:
    return str(evidence.get(ev_id, {}).get("name", ev_id))
