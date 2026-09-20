class_name AstraCrewRoutineModel
extends RefCounted

# ASTRA 0.5.4 — ROUTINES & CONSEQUENCES
# A small spatial baseline, not a life-sim timetable. Players learn where a
# person usually spends time; only a few important deviations happen per loop.

const DEVIATION_REASONS := [
    "CHECKING_CREW","MEDICAL_EMERGENCY","PRIVATE_SIGNAL","RELATIONSHIP_EVENT",
    "NULL_ACTIVITY","ECHO","PLAYER_REQUEST","RESOURCE_CONFLICT",
    "INVESTIGATION","RECOVERY"
]

const ROUTINES := {
    "mira":{
        "primary":[["medbay","환자 차트를 확인하고 있다."],["medbay","약품 서랍의 봉인을 맞춰 보고 있다."],["medbay","비어 있는 침상을 다음 검사에 맞게 정리한다."]],
        "secondary":[["lounge","식지 않은 물 한 잔을 앞에 두고 잠깐 쉬고 있다."],["garden","마렌과 산소 사용량을 확인하고 있다."]]
    },
    "rho":{
        "primary":[["engine","열린 패널 아래에서 배선을 점검하고 있다."],["engine","공구를 작업 순서대로 바닥에 놓고 있다."],["engine","냉각 펌프 소리를 듣고 진동을 확인한다."]],
        "secondary":[["comms","통신 장비의 접점과 전원선을 보고 있다."],["lounge","식은 커피 옆에서 공구 손잡이를 다시 감고 있다."]]
    },
    "dax":{
        "primary":[["bridge","항해 수치와 시스템 계산을 나란히 비교한다."],["archive","같은 로그를 다른 순서로 다시 계산한다."]],
        "secondary":[["engine","준이 읽은 기계 수치를 계산표와 맞춘다."],["lounge","화면을 끄고 종이에 중간값만 적고 있다."]]
    },
    "noa":{
        "primary":[["archive","기록의 시각과 문장을 한 줄씩 대조한다."],["archive","원문을 지우지 않고 여백에 확인 표시만 남긴다."]],
        "secondary":[["comms","신호 기록과 공식 로그의 시각을 비교한다."],["lounge","개인 메모를 접어 두고 다른 기록을 읽는다."]]
    },
    "sena":{
        "primary":[["security","출입 기록과 실제 문 잠금 상태를 맞춘다."],["security","사람이 있는 구역을 지나는 순찰 경로를 확인한다."]],
        "secondary":[["engine","위험 구역의 차단 상태를 확인하고 있다."],["medbay","치료가 끝난 사람의 이동 가능 여부를 묻는다."]]
    },
    "vale":{
        "primary":[["comms","빈 채널의 반복 간격을 듣고 있다."],["comms","녹음 파일 둘을 번갈아 재생한다."],["comms","헤드셋을 벗어 둔 채 파형만 보고 있다."]],
        "secondary":[["bridge","루칸의 좌표와 신호 방향을 맞춘다."],["lounge","아무 소리도 틀지 않은 채 잠깐 귀를 쉬고 있다."]]
    },
    "eli":{
        "primary":[["bridge","한 지점보다 전체 항로가 보이게 화면을 줄여 놓았다."],["bridge","현재 좌표와 비상 우회 경로를 함께 띄워 놓았다."]],
        "secondary":[["security","비상구 두 곳의 이동 경로를 직접 확인한다."],["comms","소렌이 짚은 방향을 항법 지도에 겹쳐 보고 있다."]]
    },
    "lyra":{
        "primary":[["garden","식물 상태와 산소 순환 수치를 함께 확인한다."],["garden","표본의 날짜와 보관 환경을 다시 적고 있다."],["garden","배급량과 생태 장치 소비량을 맞춘다."]],
        "secondary":[["medbay","의료용 산소와 생태 구역 사용량을 미라와 맞춘다."],["lounge","남은 식사를 사람 수에 맞게 나누고 있다."]]
    }
}

const DEVIATIONS := {
    "mira":[
        ["comms","CHECKING_CREW","소렌의 청각 피로와 수면 기록을 확인하러 왔다."],
        ["garden","RESOURCE_CONFLICT","의료용 산소와 생태 순환량을 직접 맞추고 있다."],
        ["lounge","RECOVERY","자기 검사를 미룬 뒤 혼자 잠깐 앉아 있다."],
        ["engine","MEDICAL_EMERGENCY","작업 중 다친 사람이 있다는 호출을 받고 응급 키트를 들고 와 있다."]
    ],
    "rho":[
        ["comms","INVESTIGATION","통신 장치가 실제로 손상됐는지 접점을 보고 있다."],
        ["security","RELATIONSHIP_EVENT","세나가 표시한 출입 흔적을 직접 확인하러 왔다."],
        ["lounge","RECOVERY","작업을 멈추고 손목의 작은 상처를 다시 감고 있다."],
        ["archive","NULL_ACTIVITY","작업 로그 한 장을 따로 펼쳐 놓고 누가 들어오는지 먼저 확인한다."]
    ],
    "dax":[
        ["engine","INVESTIGATION","계산과 실제 기계 수치가 왜 다른지 현장에서 다시 잰다."],
        ["garden","RESOURCE_CONFLICT","생존 계산에 생태 장치의 실제 변수를 넣고 있다."],
        ["comms","INVESTIGATION","신호 시각을 시스템 시계와 직접 비교한다."]
    ],
    "noa":[
        ["comms","PRIVATE_SIGNAL","공식 기록에 없는 신호 시각을 혼자 대조한다."],
        ["bridge","INVESTIGATION","항법 로그 원문과 보관본의 문장을 비교하러 왔다."],
        ["lounge","RELATIONSHIP_EVENT","공개하지 않은 개인 메모를 다시 읽고 있다."]
    ],
    "sena":[
        ["medbay","CHECKING_CREW","부상자 이동 가능 여부를 직접 확인하러 왔다."],
        ["engine","INVESTIGATION","차단선을 누가 만졌는지 현장을 먼저 보고 있다."],
        ["comms","PLAYER_REQUEST","통신실 출입을 잠시 지켜 달라는 부탁을 받아 와 있다."]
    ],
    "vale":[
        ["bridge","INVESTIGATION","신호가 가리키는 방향을 루칸의 지도에서 확인한다."],
        ["medbay","RECOVERY","미라가 청각 피로 검사를 하라고 보내 잠깐 와 있다."],
        ["lounge","RECOVERY","헤드셋을 두고 아무 소리도 듣지 않는 시간을 갖고 있다."],
        ["archive","ECHO","처음 보는 녹음 시각을 이미 찾고 있었던 사람처럼 곧바로 같은 날짜의 기록을 펼친다."]
    ],
    "eli":[
        ["comms","PRIVATE_SIGNAL","좌표보다 먼저 들린 방향 정보를 확인하러 왔다."],
        ["security","INVESTIGATION","짧은 경로가 실제로 안전한지 직접 걸어 보고 있다."],
        ["medbay","CHECKING_CREW","환자를 옮길 때 덜 흔들리는 우회 경로를 설명한다."]
    ],
    "lyra":[
        ["medbay","RESOURCE_CONFLICT","산소 배분이 환자 상태에 미치는 영향을 확인한다."],
        ["archive","INVESTIGATION","표본 날짜와 항해 기록의 출발 시각을 대조한다."],
        ["lounge","RELATIONSHIP_EVENT","남겨 둔 표본 때문에 줄어든 배급량을 다시 계산한다."]
    ]
}

static func routine_types() -> int:
    var total := 0
    for profile in ROUTINES.values():
        total += Array(profile.get("primary",[])).size()
        total += Array(profile.get("secondary",[])).size()
    return total

static func _allowed_entry(entries: Array, allowed: Array, fallback_room: String) -> Array:
    var result: Array = []
    for raw in entries:
        var entry: Array = raw
        if str(entry[0]) in allowed:
            result.append(entry)
    if result.is_empty():
        result.append([fallback_room,"자기 일을 조용히 이어 가고 있다."])
    return result

static func _stable_index(seed_value: int, key: String, size: int) -> int:
    if size <= 0:
        return 0
    return posmod(abs(hash("%d:%s" % [seed_value,key])),size)

static func build(seed_value: int, loop_index: int, chapter: String, roster: Array, active_ids: Array, null_ids: Array = []) -> Dictionary:
    var result := {}
    var allowed := AstraVoyageContent.room_ids(roster,chapter)
    for raw_id in roster:
        var npc_id := str(raw_id)
        if npc_id not in active_ids:
            continue
        var fallback := AstraVoyageContent.home_room(npc_id,chapter)
        var profile: Dictionary = ROUTINES.get(npc_id,{})
        var normal_pool := _allowed_entry(Array(profile.get("primary",[])),allowed,fallback)
        var normal: Array = normal_pool[_stable_index(seed_value + loop_index * 101,npc_id + ":normal",normal_pool.size())]
        result[npc_id] = {
            "location":str(normal[0]),"activity":str(normal[1]),
            "routine_reason":"NORMAL_ROUTINE","deviation_reason":"",
            "is_deviation":false,"companions":[]
        }
    var budget := 0
    match chapter:
        "CALIBRATION","DEAD_AIR": budget = 0
        "GLASS_GARDEN": budget = 1
        _: budget = 1 + _stable_index(seed_value + loop_index * 313,"deviation-budget",3)
    var candidates: Array = active_ids.duplicate()
    candidates.sort_custom(func(a,b):
        return _stable_index(seed_value + loop_index * 719,str(a)+":dev-order",100000) < _stable_index(seed_value + loop_index * 719,str(b)+":dev-order",100000)
    )
    for raw_id in candidates:
        if budget <= 0:
            break
        var npc_id := str(raw_id)
        var options: Array = []
        for raw in Array(DEVIATIONS.get(npc_id,[])):
            var dev: Array = raw
            if str(dev[0]) not in allowed or str(dev[0]) == str(result.get(npc_id,{}).get("location","")):
                continue
            if str(dev[1]) == "NULL_ACTIVITY" and npc_id not in null_ids:
                continue
            if str(dev[1]) == "ECHO" and loop_index <= 0:
                continue
            options.append(dev)
        if options.is_empty():
            continue
        var selected: Array = options[_stable_index(seed_value + loop_index * 997,npc_id + ":deviation",options.size())]
        result[npc_id] = {
            "location":str(selected[0]),"activity":str(selected[2]),
            "routine_reason":"ROUTINE_DEVIATION","deviation_reason":str(selected[1]),
            "is_deviation":true,"companions":[]
        }
        budget -= 1
    _link_companions(result)
    return result

static func _link_companions(state: Dictionary) -> void:
    for npc_id in state:
        var companions: Array = []
        var room := str(state[npc_id].get("location",""))
        for other in state:
            if str(other) != str(npc_id) and str(state[other].get("location","")) == room:
                companions.append(str(other))
        state[npc_id]["companions"] = companions

static func advance(state: Dictionary, action_index: int, seed_value: int, chapter: String, roster: Array, active_ids: Array) -> Dictionary:
    var result := state.duplicate(true)
    if action_index <= 0 or action_index % 4 != 0 or chapter in ["CALIBRATION","DEAD_AIR"]:
        return result
    var movable: Array = []
    for npc_id in active_ids:
        if result.has(str(npc_id)) and not bool(result[str(npc_id)].get("is_deviation",false)):
            movable.append(str(npc_id))
    if movable.is_empty():
        return result
    var who := str(movable[_stable_index(seed_value + action_index * 149,"routine-advance",movable.size())])
    var allowed := AstraVoyageContent.room_ids(roster,chapter)
    var fallback := AstraVoyageContent.home_room(who,chapter)
    var profile: Dictionary = ROUTINES.get(who,{})
    var pool := _allowed_entry(Array(profile.get("primary",[])) + Array(profile.get("secondary",[])),allowed,fallback)
    var next: Array = pool[_stable_index(seed_value + action_index * 181,who + ":advance",pool.size())]
    result[who]["location"] = str(next[0])
    result[who]["activity"] = str(next[1])
    result[who]["routine_reason"] = "NORMAL_ROUTINE"
    _link_companions(result)
    return result

static func people_in_room(state: Dictionary, room: String, active_ids: Array, companion: String = "") -> Array:
    var result: Array = []
    for raw_id in active_ids:
        var npc_id := str(raw_id)
        if state.has(npc_id) and str(state[npc_id].get("location","")) == room:
            result.append(npc_id)
    if companion != "" and companion in active_ids and companion not in result:
        result.append(companion)
    return result

static func state_for(state: Dictionary, npc_id: String) -> Dictionary:
    return Dictionary(state.get(npc_id,{})).duplicate(true)

static func deviation_reason_count() -> int:
    return DEVIATION_REASONS.size()
