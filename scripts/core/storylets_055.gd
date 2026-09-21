class_name AstraStorylets055
extends RefCounted

# ASTRA 0.5.5 — FAULT LINES
# 71 authored/reactive scenes. Required action count per loop does not increase.

const LATE := ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

const MOTIVE_LINES := {
    "mira":{
        "PROTECT_PERSON":["미라는 한 사람의 차트를 다른 기록 아래로 밀어 둔다.","지금 필요한 건 공개가 아니라 처치예요. 그 사람부터 볼게요."],
        "KEEP_PRIVACY":["미라는 의료 기록 한 장만 화면에서 닫는다.","그 기록을 안 보여준 건 맞아요. 제가 함부로 공개할 수는 없으니까."],
        "FINISH_DUTY":["미라는 자기 검사표를 뒤로 미루고 다음 환자 기록을 연다.","제 건 끝나고 해도 돼요. 먼저 남은 사람부터요."],
        "FEAR_REPEAT":["미라는 이미 확인한 생체 신호를 한 번 더 대조한다.","지난번처럼 놓치고 싶진 않아요. 한 번만 더 볼게요."]},
    "rho":{
        "HIDE_MISTAKE":["준은 작업 기록의 한 줄을 손가락으로 가린 채 커넥터부터 본다.","커넥터 잘못 끼운 건 나야. 그거랑 채널 끈 건 별개고."],
        "FINISH_DUTY":["준은 설명보다 열린 패널부터 닫는다.","이거 끝내고 말할게. 지금 멈추면 다른 데까지 나가."],
        "PROTECT_PERSON":["준은 다른 사람 이름이 적힌 공구 대여칸을 먼저 접는다.","그 사람부터 몰지 마. 이건 내가 같이 쓴 공구야."]},
    "dax":{
        "PROTECT_REPUTATION":["다렌은 틀린 계산을 지우지 않지만 공개본에는 아직 붙이지 않는다.","틀린 건 맞아. 다만 왜 틀렸는지 확인하고 내놓을 거야."],
        "VERIFY_ALONE":["다렌은 같은 값을 다른 식으로 다시 계산한다.","한 번은 혼자 풀어 봐야 어디서 섞였는지 보여."],
        "FINISH_DUTY":["다렌은 대화를 끊고 마지막 검산 줄을 채운다.","여기까지만 끝내자. 중간값으로 넘기면 더 헷갈려."]},
    "noa":{
        "PRESERVE_EVIDENCE":["노아는 공식 보관함과 다른 곳에 사본을 한 장 남긴다.","숨긴 게 아니라 복사한 거예요. 원본이 바뀌기 전에."],
        "VERIFY_ALONE":["노아는 진술을 받기 전에 파일 생성 시각부터 적는다.","먼저 혼자 맞춰 볼게요. 설명을 들으면 순서를 바꿔 기억할 수 있으니까."],
        "KEEP_PROMISE":["노아는 한 기록의 이름 칸만 가린 채 나머지를 보여 준다.","내용은 보여 줄 수 있어요. 이름은 아직 약속이 있어서 안 돼요."]},
    "sena":{
        "PROTECT_PERSON":["세나는 위험 구역 앞에서 한 사람만 뒤로 보낸다.","지금 저 사람은 여기 들어오면 안 돼. 이유는 내가 설명할게."],
        "AVOID_ISOLATION":["세나는 혼자 순찰하던 사람에게 두 번째 출입카드를 건넨다.","오늘은 혼자 돌지 마. 같이 확인해."],
        "FINISH_DUTY":["세나는 질문을 듣고도 열린 보안문부터 잠근다.","문 닫고 얘기해. 열린 채로 둘 문제는 아니야."]},
    "vale":{
        "VERIFY_ALONE":["소렌은 같은 신호를 헤드셋으로 한 번 더 듣는다.","제가 잘못 들은 건지 먼저 확인하고 말할게요."],
        "KEEP_PRIVACY":["소렌은 녹음 파일의 한 구간만 재생하지 않는다.","그 부분은 다른 사람 얘기예요. 신호와 직접 관계없으면 빼고 싶어요."],
        "FEAR_REPEAT":["소렌은 잡음이 시작되기 전 빈 구간부터 다시 듣는다.","지난번엔 여기서 놓쳤어요. 이번엔 앞에서부터 들을게요."]},
    "eli":{
        "FINISH_DUTY":["루칸은 대화보다 닫히지 않은 우회로 표시부터 고친다.","경로부터 닫고. 사람 얘기는 그 다음에 해."],
        "PROTECT_PERSON":["루칸은 빠른 길 대신 진동이 적은 길에 표시한다.","지금은 짧은 길보다 덜 흔들리는 쪽이 맞아."],
        "VERIFY_ALONE":["루칸은 항법 화면을 끄고 창밖 기준점만 다시 잡는다.","화면 말고 실제 위치부터 한 번 볼게."]},
    "lyra":{
        "SAVE_RESOURCE":["마렌은 버릴 표본을 바로 폐기하지 않고 냉각 사용량부터 적는다.","살릴 수 있어도 계속 살리는 게 맞는지는 봐야 해요."],
        "PROTECT_PERSON":["마렌은 배급표보다 아픈 사람 수를 먼저 다시 센다.","오늘은 균등하게 나누는 것보다 필요한 사람부터 봐야 해요."],
        "KEEP_PROMISE":["마렌은 따로 표시된 작은 화분 하나를 건드리지 않는다.","이건 하루만 더 두기로 했어요. 그 약속까진 지킬게요."]}
}

# 18 cooperative observations. Soren/Lucan receive one extra each.
const COOP_PACKS := {
    "mira":[
        ["medical","미라는 장비 상태보다 사용 흔적을 먼저 본다.","이건 고장보다 누가 언제 썼는지가 먼저예요."],
        ["oxygen","미라는 수치 옆에 사람 상태 변화를 같이 표시한다.","숫자가 같아도 사람 반응은 달라요. 같이 봐요."]],
    "rho":[
        ["power","준은 탄 흔적보다 커넥터 방향을 먼저 짚는다.","전원은 살아 있었어. 이쪽은 연결 순서가 문제야."],
        ["signal","준은 수신 로그 옆의 전원 흔적을 가리킨다.","신호보다 1분 먼저 전원이 흔들렸어. 같이 봐야 돼."]],
    "dax":[
        ["power","다렌은 사건 전후 값을 같은 표에 놓는다.","한 점보다 변화 순서가 중요해. 여기서 먼저 갈렸어."],
        ["arrival","다렌은 도착 시각 뒤의 작업 호출을 연속해서 본다.","도착 직후 정지한 기록이라면 이 호출 순서는 설명이 안 돼."]],
    "noa":[
        ["archive","노아는 내용보다 파일 생성 시각과 수정 시각을 나란히 둔다.","문장보다 시간이 먼저 어긋났어요."],
        ["signal","노아는 녹음 시각과 단말 접속 시각을 겹쳐 본다.","파일은 접속보다 먼저 생겼어요. 단말 기록만 보면 안 돼요."]],
    "sena":[
        ["security","세나는 로그보다 실제 잠금 상태를 먼저 확인한다.","기록이 열림이어도 문이 닫혀 있었으면 그 차이가 남아."],
        ["medical","세나는 출입 동선부터 지운다.","여길 지난 사람과 실제로 들어온 사람은 나눠 봐야 해."]],
    "vale":[
        ["signal","소렌은 음성 내용보다 반복 간격을 표시한다.","말은 달라도 간격이 같아요. 같은 장치에서 나온 걸 수도 있어요."],
        ["archive","소렌은 기록 음성의 무음 구간을 짚는다.","잘린 문장보다 이 침묵 길이가 더 일정해요."],
        ["arrival","소렌은 도착 뒤 통신 잡음의 규칙을 찾는다.","도착 후에도 정기 송신 간격이 남아 있어요. 완전히 멈춘 건 아니에요."]],
    "eli":[
        ["arrival","루칸은 도착 좌표 뒤의 이동 벡터를 다시 그린다.","도착했다면 끝이어야 하는데 그 뒤에도 짧은 이동이 있어."],
        ["security","루칸은 잠긴 문보다 우회 가능한 복도를 먼저 본다.","이 문이 닫혀도 저쪽으로는 갈 수 있었어."],
        ["signal","루칸은 신호 방향과 함선 방향을 겹친다.","같은 방향에서 온 게 아니야. 시간만 보면 하나처럼 보여."]],
    "lyra":[
        ["sample","마렌은 표본 상태와 냉각 소비를 같은 줄에 적는다.","이 변화가 자연스러운 건지 자원을 더 써서 버틴 건지 나눠 봐야 해요."],
        ["oxygen","마렌은 의료 사용량과 생태 순환량을 함께 본다.","한쪽 기록만 보면 부족해 보여요. 둘이 같은 산소를 쓰고 있었어요."]]
}

const FORE_PACKS := {
    "mira":["미라는 당신이 경보 전에 의료함을 연 것을 본다.","아직 요청도 없었는데 준비했네요. 이유는 나중에라도 말해 줘요."],
    "rho":["준은 당신이 먼저 릴레이 커버를 연 것을 본다.","고장 나기 전에 그걸 왜 먼저 열었어?"],
    "dax":["다렌은 당신이 결과가 나오기 전에 검산 순서를 바꾼 것을 본다.","예측이라면 근거가 있어야 해. 지금은 순서가 반대였어."],
    "noa":["노아는 아직 생성되지 않은 기록 위치를 당신이 먼저 확인한 것을 적는다.","그 파일이 생길 걸 알고 있었던 것처럼 움직였네요."],
    "sena":["세나는 경보 전에 당신이 우회문 앞에 선 것을 본다.","아직 아무것도 안 떴는데 왜 거기부터 간 거야?"],
    "vale":["소렌은 신호 전에 당신이 주파수를 맞춘 것을 본다.","아직 안 들렸는데 먼저 맞췄어요. 그건 기억해 둘게요."],
    "eli":["루칸은 편차가 뜨기 전에 당신이 우회 항로를 펼친 것을 본다.","문제 생기기 전에 길을 골랐네. 이유가 있겠지."],
    "lyra":["마렌은 경보 전에 냉각 자원을 옮긴 당신을 본다.","아직 변하지 않았는데 먼저 준비했어요. 이상하긴 해요."]
}

# Four mundane post-arrival records; runtime caps player-visible discoveries at two.
const POST_ARRIVAL := {
    "mira":["ARRIVAL + 17 DAYS · MEDICAL INVENTORY · SIGNED: MIRA","제 서명 형식은 맞아요. 저는 쓴 기억이 없지만."],
    "rho":["ARRIVAL + 9 DAYS · COOLANT PUMP MAINTENANCE · SIGNED: JUN","이 정비 방식, 내가 쓰는 거 맞아. 근데 난 한 기억이 없어."],
    "noa":["ARRIVAL + 31 DAYS · ARCHIVE REVISION INDEX · SIGNED: NOA","형식도 제 거예요. 문제는 도착하고 한 달 뒤라는 거죠."],
    "lyra":["ARRIVAL + 26 DAYS · ECOLOGY SAMPLE CYCLE · SIGNED: MAREN","이 주기 기록은 정상이에요. 그래서 날짜가 더 이상해요."]
}

const INCIDENT_AFTER := {
    "mira":["MEDICAL_SHORTAGE","미라는 부족했던 재고표 옆에 실제 처치 순서를 새로 적는다.","다음엔 부족하다는 숫자보다 누구에게 먼저 필요한지 같이 남길게요."],
    "rho":["POWER_RELAY","준은 교체한 릴레이를 버리지 않고 시간표 옆에 둔다.","고친 부품도 증거야. 멀쩡해졌다고 없애면 안 돼."],
    "dax":["NAV_DRIFT","다렌은 편차값을 정상값 옆에 그대로 남긴다.","복구됐다는 건 원인이 사라졌다는 뜻은 아니야."],
    "noa":["ARCHIVE_CORRUPTION","노아는 복구본과 손상본을 같은 번호 아래 따로 봉인한다.","읽을 수 있는 것과 원본인 건 다른 문제예요."],
    "sena":["DOOR_LOCK","세나는 수동 해제한 문에 임시 표식을 남긴다.","열렸다고 끝난 거 아냐. 왜 잠겼는지는 아직 남았어."],
    "vale":["COMMS_SPIKE","소렌은 보존한 신호와 사라진 구간 길이를 함께 기록한다.","남은 소리만 들으면 놓친 쪽이 없었던 것처럼 보여요."],
    "eli":["NAV_DRIFT","루칸은 복구한 항로 옆에 원래 편차 방향을 지우지 않는다.","돌아왔어도 어디로 밀렸는지는 남겨 둬야 해."],
    "lyra":["SAMPLE_CONTAINMENT","마렌은 살린 표본 옆에 사용한 냉각량도 같이 적는다.","보존했다는 결과만 적으면 비용이 사라져 보여요."]
}

const DELEGATION := {
    "mira":["미라는 조사한 기록에서 사람 상태와 직접 관계 있는 부분만 먼저 골라 온다.","확인된 것만 말할게요. 나머지는 제가 더 볼게요."],
    "rho":["준은 장치 흔적과 실제로 손댄 위치만 짧게 그려 온다.","여기까진 확실해. 나머진 뜯어 봐야 알아."],
    "dax":["다렌은 결론보다 입력값과 제외한 가정을 먼저 적어 온다.","이 조건 안에서는 맞아. 밖의 조건은 아직 몰라."],
    "noa":["노아는 파일 시각과 수정 계보만 정리해 온다.","내용 해석은 빼고, 확인된 순서만 가져왔어요."],
    "sena":["세나는 이동 가능 경로와 실제 잠금 상태만 보고한다.","갈 수 있었던 길과 실제로 간 건 다르니까 여기까지만."],
    "vale":["소렌은 들린 구간과 들리지 않은 구간을 분리해 온다.","내용보다 먼저, 어디까지 확실히 들렸는지 표시했어요."],
    "eli":["루칸은 가능한 경로와 불가능한 경로를 먼저 지운다.","누가 갔는지는 몰라. 갈 수 있었는지는 여기까지야."],
    "lyra":["마렌은 표본 변화와 사용 자원을 한 장에 묶어 온다.","살아남은 것만 보면 이유를 놓쳐요. 쓴 자원도 같이 봐야 해요."]
}

static func _motive_scenes() -> Array:
    var result: Array = []
    for who in MOTIVE_LINES:
        for motive in MOTIVE_LINES[who]:
            var pack: Array = MOTIVE_LINES[who][motive]
            result.append({
                "id":"055_motive_%s_%s" % [who,str(motive).to_lower()],
                "speaker":str(who),"tag":"personal","category":"MOTIVE",
                "family":"motive_%s" % who,"intent":"motive_reveal",
                "action":str(pack[0]),"lines":[[str(who),str(pack[1])]],"choices":[],
                "chapters":LATE.duplicate(),"requires_motive":str(motive),
                "requires_motive_progress":0,"motive_progress":1,"compressible":false})
    return result

static func _coop_scenes() -> Array:
    var result: Array = []
    for who in COOP_PACKS:
        var index := 0
        for pack in COOP_PACKS[who]:
            result.append({
                "id":"055_coop_%s_%s_%d" % [who,str(pack[0]),index],
                "speaker":str(who),"tag":"work","category":"COOPERATIVE",
                "family":"coop_%s_%s" % [who,str(pack[0])],"intent":"cooperative_investigation",
                "action":str(pack[1]),"lines":[[str(who),str(pack[2])]],"choices":[],
                "chapters":LATE.duplicate(),"cooperative_only":true,
                "cooperative_fact":str(pack[0]),"compressible":false})
            index += 1
    return result

static func _fore_scenes() -> Array:
    var result: Array = []
    for who in FORE_PACKS:
        var pack: Array = FORE_PACKS[who]
        result.append({
            "id":"055_foreknowledge_%s" % who,"speaker":str(who),
            "tag":"reaction","category":"FOREKNOWLEDGE","family":"foreknowledge_%s" % who,
            "intent":"player_foreknowledge","action":str(pack[0]),
            "lines":[[str(who),str(pack[1])]],"choices":[],"chapters":LATE.duplicate(),
            "foreknowledge_reaction":true,"compressible":false})
    return result

static func _post_arrival_scenes() -> Array:
    var result: Array = []
    for who in POST_ARRIVAL:
        var pack: Array = POST_ARRIVAL[who]
        result.append({
            "id":"055_post_arrival_%s" % who,"speaker":str(who),
            "tag":"mystery","category":"CANON","family":"post_arrival_record","intent":"canon_hook",
            "action":"복구된 평범한 업무 기록 한 줄이 도착 이후 날짜를 가리킨다. " + str(pack[0]),
            "lines":[[str(who),str(pack[1])]],"choices":[],
            "chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],
            "requires":{"fact":"arrival"},"canon_post_arrival":true,"compressible":false})
    return result

static func _incident_after_scenes() -> Array:
    var result: Array = []
    for who in INCIDENT_AFTER:
        var pack: Array = INCIDENT_AFTER[who]
        result.append({
            "id":"055_incident_after_%s_%s" % [who,str(pack[0]).to_lower()],
            "speaker":str(who),"tag":"after","category":"INCIDENT_AFTER",
            "family":"incident_after_" + str(pack[0]),"intent":"incident_followup",
            "action":str(pack[1]),"lines":[[str(who),str(pack[2])]],"choices":[],
            "chapters":LATE.duplicate(),"requires_incident":str(pack[0]),"compressible":false})
    return result

static func _delegation_scenes() -> Array:
    var result: Array = []
    for who in DELEGATION:
        var pack: Array = DELEGATION[who]
        result.append({
            "id":"055_delegation_%s" % who,"speaker":str(who),
            "tag":"work","category":"DELEGATION","family":"delegation_%s" % who,
            "intent":"delegated_report","action":str(pack[0]),
            "lines":[[str(who),str(pack[1])]],"choices":[],
            "chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],
            "delegation_only":true,"compressible":false})
    return result

static func scenes() -> Array:
    var result: Array = []
    result.append_array(_motive_scenes())
    result.append_array(_coop_scenes())
    result.append_array(_fore_scenes())
    result.append_array(_post_arrival_scenes())
    result.append_array(_incident_after_scenes())
    result.append_array(_delegation_scenes())
    return result

static func authored_scene_count() -> int:
    return scenes().size()

static func speaker_counts() -> Dictionary:
    var result := {}
    for scene in scenes():
        var who := str(scene.get("speaker",""))
        result[who] = int(result.get(who,0))+1
    return result

static func cooperative_scene(fact_id: String, who: String) -> Dictionary:
    var actor_scenes: Array = _coop_scenes().filter(func(scene): return str(scene.get("speaker","")) == who)
    if actor_scenes.is_empty():
        return {}
    for scene in actor_scenes:
        if str(scene.get("cooperative_fact","")) == fact_id:
            return Dictionary(scene).duplicate(true)
    var index := abs(hash("055:coop:%s:%s" % [who,fact_id])) % actor_scenes.size()
    return Dictionary(actor_scenes[index]).duplicate(true)

static func delegation_scene(who: String, fact_id: String, fact_note: String) -> Dictionary:
    for scene in _delegation_scenes():
        if str(scene.get("speaker","")) != who:
            continue
        var result: Dictionary = Dictionary(scene).duplicate(true)
        result["id"] = str(result["id"]) + "_" + fact_id
        result["action"] = str(result["action"]) + " 확인한 핵심: " + fact_note
        return result
    return {}

static func incident_after_scene(incident_id: String, actor: String) -> Dictionary:
    for scene in _incident_after_scenes():
        if str(scene.get("speaker","")) == actor and str(scene.get("requires_incident","")) == incident_id:
            return Dictionary(scene).duplicate(true)
    for scene in _incident_after_scenes():
        if str(scene.get("requires_incident","")) == incident_id:
            return Dictionary(scene).duplicate(true)
    return {}
