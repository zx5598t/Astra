class_name AstraCrewActivityModel
extends RefCounted

# Off-screen life in small doses. These beats are authored and deterministic;
# entering the relevant room may reveal one, otherwise the player can simply
# miss it. No main-story progress depends on them.

const BEATS := [
    {"id":"053_auto_mira_sena_bandage","actors":["mira","sena"],"room":"medbay","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"미라가 세나의 붕대를 새로 감는 동안 세나는 출입문 쪽만 보고 있다.","lines":[["mira","이번 건 갈아야 해요."],["sena","5분이면 돼?"],["mira","앉아 있으면요."]],"relations":["anchor","question","answer"]},
    {"id":"053_auto_mira_selfcheck","actors":["mira"],"room":"medbay","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"모두의 검사표는 채워져 있는데 미라의 자기 검사 칸만 비어 있다.","lines":[]},
    {"id":"053_auto_mira_lyra_oxygen","actors":["mira","lyra"],"room":"garden","chapters":["RED_SHIFT","LAST_LIGHT"],"action":"미라와 마렌이 산소 배분 시간을 한 칸씩 번갈아 고치고 있다.","lines":[["lyra","두 시간이면 돼요."],["mira","환자 상태 바뀌면 바로 다시 조정해요."]],"relations":["proposal","condition"]},
    {"id":"053_auto_mira_vale_sleep","actors":["mira","vale"],"room":"comms","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"미라는 소렌의 헤드셋 옆에 수면 시간을 적은 메모를 놓고 먼저 나간다.","lines":[]},
    {"id":"053_auto_mira_chart","actors":["mira"],"room":"medbay","chapters":["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"미라는 말없이 비어 있는 침상 시트를 펴고 다음 차트를 준비한다.","lines":[]},
    {"id":"053_auto_mira_rho_device","actors":["mira","rho"],"room":"medbay","chapters":["GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"준이 의료 센서를 고치는 동안 미라는 예비 센서로 검사를 계속한다.","lines":[["rho","이거 금방 끝나."],["mira","그 말 믿고 예비기도 켰어요."]],"relations":["anchor","reply"]},

    {"id":"053_auto_rho_repair","actors":["rho"],"room":"engine","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"준은 플레이어가 없어도 열린 패널 앞에서 조립 순서를 바닥에 늘어놓고 있다.","lines":[]},
    {"id":"053_auto_rho_sena_argue","actors":["rho","sena"],"room":"security","chapters":["GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"문 너머에서 준과 세나가 짧게 언성을 높이다 동시에 말을 멈춘다.","lines":[["rho","내가 거기 없었다니까."],["sena","그럼 왜 네 공구가 있었는데?"],["rho","그걸 나도 묻는 거야."]],"relations":["anchor","challenge","reply"],"overheard":true},
    {"id":"053_auto_rho_dax_check","actors":["rho","dax"],"room":"engine","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"준은 진동을 듣고 다렌은 수치를 적는다. 둘 다 상대가 끝날 때까지 끼어들지 않는다.","lines":[]},

    {"id":"053_auto_noa_dax_compare","actors":["noa","dax"],"room":"archive","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"노아와 다렌이 같은 기록을 시간순과 원인순으로 각각 정렬해 놓았다.","lines":[["noa","여기서 순서가 갈려요."],["dax","순서를 바꿔도 남는 줄만 보자."]],"relations":["anchor","proposal"]},
    {"id":"053_auto_noa_copy","actors":["noa"],"room":"archive","chapters":["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"노아는 원문을 지우지 않고 여백에만 수정 이유를 적는다.","lines":[]},
    {"id":"053_auto_noa_vale","actors":["noa","vale"],"room":"comms","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"노아는 예상 문장을 가린 채 소렌의 신호를 먼저 듣고 있다.","lines":[["vale","날짜도 가렸어요?"],["noa","제가 먼저 아는 게 들리는 걸 바꿀까 봐요."]],"relations":["question","reply"]},

    {"id":"053_auto_sena_patrol","actors":["sena"],"room":"security","chapters":["GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"세나는 가장 짧은 순찰로 대신 사람이 있는 구역을 지나는 경로를 표시한다.","lines":[]},
    {"id":"053_auto_sena_door","actors":["sena"],"room":"medbay","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"세나는 의료실 안으로 들어오지 않고 문이 닫히는 속도만 한 번 확인한다.","lines":[]},
    {"id":"053_auto_sena_rho_light","actors":["sena","rho"],"room":"engine","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"세나가 작업등 각도를 바꾸자 준은 아무 말 없이 다음 볼트를 푼다.","lines":[]},

    {"id":"053_auto_dax_recalc","actors":["dax"],"room":"bridge","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"다렌은 이미 맞은 계산을 종이에 한 번 더 적고 중간값만 비교한다.","lines":[]},
    {"id":"053_auto_dax_lyra","actors":["dax","lyra"],"room":"garden","chapters":["RED_SHIFT","LAST_LIGHT"],"action":"다렌의 생존 표 옆에 마렌이 실제 잎 하나를 올려놓는다.","lines":[["dax","수치는 정상인데."],["lyra","잎은 아니에요."],["dax","그럼 변수가 하나 빠졌네."]],"relations":["anchor","challenge","inference"]},
    {"id":"053_auto_dax_eli","actors":["dax","eli"],"room":"bridge","chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"다렌과 루칸은 항로와 연료 소비선이 갈리는 한 지점만 확대해 놓았다.","lines":[]},

    {"id":"053_auto_vale_listen","actors":["vale"],"room":"comms","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"소렌은 빈 채널의 침묵 구간을 세 번 반복해 듣고 있다.","lines":[]},
    {"id":"053_auto_vale_eli","actors":["vale","eli"],"room":"bridge","chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"소렌이 이어폰 한쪽을 건네자 루칸은 말없이 지도 한 점을 짚는다.","lines":[["vale","같은 지점이죠?"],["eli","같은 방향이야. 지점은 아직."]],"relations":["question","clarify"]},
    {"id":"053_auto_vale_rest","actors":["vale"],"room":"lounge","chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"소렌은 헤드셋 없이 앉아 있다. 손은 습관처럼 재생 버튼 위치를 찾다가 멈춘다.","lines":[]},

    {"id":"053_auto_eli_route","actors":["eli"],"room":"bridge","chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"루칸은 현재 좌표가 아니라 전체 항로가 한눈에 보이도록 화면을 줄여 놓았다.","lines":[]},
    {"id":"053_auto_eli_exit","actors":["eli"],"room":"security","chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"루칸은 대화에 끼지 않고 비상구 두 곳의 잠금 상태만 확인하고 지나간다.","lines":[]},
    {"id":"053_auto_eli_mira_route","actors":["eli","mira"],"room":"medbay","chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"action":"루칸은 환자를 옮길 때 덜 흔들리는 우회 경로를 미라에게 보여 준다.","lines":[["eli","멀지만 이쪽이 덜 흔들려."],["mira","응급 경로에 추가할게요."]],"relations":["proposal","accept"]},

    {"id":"053_auto_lyra_sample","actors":["lyra"],"room":"garden","chapters":["RED_SHIFT","LAST_LIGHT"],"action":"마렌은 폐기 표본 하나를 버리지 않고 따로 밀봉해 날짜만 적는다.","lines":[]},
    {"id":"053_auto_lyra_food","actors":["lyra"],"room":"lounge","chapters":["RED_SHIFT","LAST_LIGHT"],"action":"마렌은 사람 수와 배급량을 다시 맞춘 뒤 남은 한 끼를 냉장 칸에 넣는다.","lines":[]},
    {"id":"053_auto_lyra_mira_plant","actors":["lyra"],"room":"garden","chapters":["RED_SHIFT","LAST_LIGHT"],"action":"마렌은 의료실로 보낼 작은 화분에서 마른 잎만 골라 떼어 낸다.","lines":[]}
]

static func eligible(beat: Dictionary, chapter: String, roster: Array, active_ids: Array, recent: Array) -> bool:
    if chapter not in beat.get("chapters",[]):
        return false
    if str(beat.get("id","")) in recent:
        return false
    for actor in beat.get("actors",[]):
        if str(actor) not in roster or str(actor) not in active_ids:
            return false
    return true

static func schedule(seed_value: int, loop_index: int, chapter: String, roster: Array, active_ids: Array, recent: Array, max_count: int = 2) -> Array:
    var candidates: Array = []
    for raw in BEATS:
        var beat: Dictionary = raw
        if eligible(beat,chapter,roster,active_ids,recent):
            candidates.append(beat)
    var result: Array = []
    var local := RandomNumberGenerator.new()
    local.seed = seed_value ^ (loop_index * 7919) ^ hash(chapter + ":activity")
    AstraCaseGenerator._shuffle(candidates,local)
    var wanted := 0 if chapter in ["CALIBRATION","DEAD_AIR"] else local.randi_range(0,max_count)
    if chapter == "GLASS_GARDEN":
        wanted = mini(1,wanted)
    for i in range(mini(wanted,candidates.size())):
        result.append(Dictionary(candidates[i]).duplicate(true))
    return result

static func room_beat(queue: Array, room: String) -> Dictionary:
    for beat in queue:
        if str(beat.get("room","")) == room:
            return Dictionary(beat).duplicate(true)
    return {}
