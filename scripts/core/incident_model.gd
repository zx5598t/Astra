class_name AstraIncidentModel
extends RefCounted

# Small ship incidents: pressure through existing actions, never a real-time timer.

const INCIDENTS := {
    "COMMS_SPIKE":{
        "chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"actor":"vale",
        "action":"통신 채널이 한꺼번에 겹치며 수신 버퍼가 빠르게 밀린다.",
        "choices":[
            {"label":"소렌과 신호부터 보존한다.","effect":"record","incident_action":"preserve_signal","outcome":"PARTIAL","note":"일부 신호를 보존했지만 통신 안정화가 늦어졌다.","source_type":"RECORD"},
            {"label":"준과 장치를 먼저 안정시킨다.","effect":"help","incident_action":"stabilize","outcome":"RESOLVED","note":"채널은 안정됐지만 겹쳐 들어온 음성 일부가 사라졌다.","source_type":"DIRECT"},
            {"label":"둘에게 맡기고 다른 기록을 본다.","effect":"wait","incident_action":"delegate","outcome":"COSTLY","note":"문제는 정리됐지만 어떤 신호를 버렸는지는 동료 판단에 남았다.","source_type":"TESTIMONY"}]},
    "POWER_RELAY":{
        "chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"actor":"rho",
        "action":"전력 릴레이가 반복해서 우회되며 의료실과 기록실 부하가 서로 밀어낸다.",
        "choices":[
            {"label":"준과 릴레이를 먼저 고정한다.","effect":"help","incident_action":"relay_fix","outcome":"RESOLVED","note":"전력은 안정됐지만 우회 직전의 로그 일부는 덮였다.","source_type":"DIRECT"},
            {"label":"노아와 우회 로그부터 복사한다.","effect":"record","incident_action":"copy_log","outcome":"PARTIAL","note":"우회 로그를 남겼지만 의료 장비의 불안정 시간이 길어졌다.","source_type":"RECORD"}]},
    "DOOR_LOCK":{
        "chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"actor":"sena",
        "action":"보안문 하나가 닫힌 채 인증 응답을 돌려주지 않는다.",
        "choices":[
            {"label":"세나와 수동 해제를 시도한다.","effect":"help","incident_action":"manual_open","outcome":"RESOLVED","note":"문은 열렸지만 잠금 원인을 보여 주는 상태값이 초기화됐다.","source_type":"DIRECT"},
            {"label":"노아가 잠금 기록을 먼저 보게 한다.","effect":"record","incident_action":"preserve_lock","outcome":"PARTIAL","note":"잠금 기록은 남겼지만 우회 통로를 써야 했다.","source_type":"RECORD"}]},
    "NAV_DRIFT":{
        "chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"actor":"eli",
        "action":"항법 좌표가 아주 조금씩 미끄러진다. 즉시 위험한 수치는 아니지만 계속 같은 방향이다.",
        "choices":[
            {"label":"루칸과 좌표를 먼저 되돌린다.","effect":"help","incident_action":"correct_nav","outcome":"RESOLVED","note":"좌표는 복구됐지만 편차가 생긴 순간의 원시값은 일부 사라졌다.","source_type":"DIRECT"},
            {"label":"다렌과 편차 패턴부터 남긴다.","effect":"record","incident_action":"measure_drift","outcome":"PARTIAL","note":"편차 패턴을 확보한 대신 정상 항로 복귀가 늦어졌다.","source_type":"RECORD"}]},
    "OXYGEN_BALANCE":{
        "chapters":["RED_SHIFT","LAST_LIGHT"],"actor":"mira",
        "action":"의료실과 생태 구역이 같은 산소 여유분을 요구한다.",
        "choices":[
            {"label":"미라와 환자 쪽을 먼저 안정시킨다.","effect":"protect","incident_action":"medical_first","outcome":"PARTIAL","note":"의료 쪽은 안정됐고 생태 순환은 임시 제한에 들어갔다.","source_type":"DIRECT"},
            {"label":"마렌과 순환계를 먼저 안정시킨다.","effect":"help","incident_action":"ecology_first","outcome":"PARTIAL","note":"장기 순환은 안정됐고 의료실은 휴대 산소를 사용했다.","source_type":"DIRECT"}]},
    "SAMPLE_CONTAINMENT":{
        "chapters":["RED_SHIFT","LAST_LIGHT"],"actor":"lyra",
        "action":"표본 보관함 온도가 오르며 보존 자원과 격리 안정성을 동시에 요구한다.",
        "choices":[
            {"label":"마렌과 표본 상태를 먼저 보존한다.","effect":"protect","incident_action":"save_sample","outcome":"COSTLY","note":"표본은 남았지만 냉각 자원을 더 사용했다.","source_type":"DIRECT"},
            {"label":"격리를 우선하고 표본 일부를 포기한다.","effect":"procedure","incident_action":"contain","outcome":"RESOLVED","note":"격리는 안정됐지만 표본에서 얻을 수 있던 정보 일부를 포기했다.","source_type":"DIRECT"}]},
    "ARCHIVE_CORRUPTION":{
        "chapters":["SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"actor":"noa",
        "action":"보관 중인 기록 한 묶음에서 해시가 맞지 않는 사본이 동시에 발견된다.",
        "choices":[
            {"label":"노아와 원본 계보부터 고정한다.","effect":"record","incident_action":"preserve_archive","outcome":"PARTIAL","note":"원본 계보를 남겼지만 일부 열람이 잠시 중단됐다.","source_type":"RECORD"},
            {"label":"다렌과 사용 가능한 사본부터 복구한다.","effect":"help","incident_action":"restore_copy","outcome":"RESOLVED","note":"열람은 복구됐지만 어느 사본이 먼저 바뀌었는지는 덜 분명해졌다.","source_type":"RECORD"}]},
    "MEDICAL_SHORTAGE":{
        "chapters":["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"],"actor":"mira",
        "action":"의료 재고가 예상보다 한 회분 부족하다. 당장 생명이 위험한 상황은 아니지만 다음 처치 순서를 정해야 한다.",
        "choices":[
            {"label":"미라가 필요한 사람부터 다시 분류하게 한다.","effect":"protect","incident_action":"triage","outcome":"RESOLVED","note":"필요도 순으로 재배치했지만 여유 재고는 사라졌다.","source_type":"DIRECT"},
            {"label":"노아와 사용 기록부터 대조한다.","effect":"record","incident_action":"audit_med","outcome":"PARTIAL","note":"누락 시점을 좁혔지만 처치 준비가 늦어졌다.","source_type":"RECORD"}]}
}

static func incident_types() -> int:
    return INCIDENTS.size()

static func eligible_types(chapter: String) -> Array:
    var result: Array = []
    for incident_id in INCIDENTS:
        if chapter in Array(INCIDENTS[incident_id].get("chapters",[])):
            result.append(str(incident_id))
    return result

static func _stable(seed_value: int, loop_index: int, key: String) -> int:
    return abs(hash("055:incident:%d:%d:%s" % [seed_value,loop_index,key]))

static func should_trigger(seed_value: int, loop_index: int, chapter: String, action_index: int, history: Array, active_incident: Dictionary) -> bool:
    if not active_incident.is_empty() or chapter in ["CALIBRATION","DEAD_AIR","GLASS_GARDEN"]:
        return false
    for event in history:
        if int(event.get("loop",-1)) == loop_index:
            return false
    if chapter in ["RED_SHIFT","LAST_LIGHT"]:
        return action_index >= 4
    if action_index != 5:
        return false
    return (_stable(seed_value,loop_index,chapter + ":gate") % 100) < 72

static func select(seed_value: int, loop_index: int, chapter: String, history: Array, active_ids: Array) -> Dictionary:
    var candidates := eligible_types(chapter)
    candidates = candidates.filter(func(id):
        return str(INCIDENTS[str(id)].get("actor","")) in active_ids
    )
    if candidates.is_empty():
        return {}
    var recent := ""
    if not history.is_empty():
        recent = str(history.back().get("id",""))
    candidates.sort_custom(func(a,b):
        var ap := 1 if str(a) == recent else 0
        var bp := 1 if str(b) == recent else 0
        if ap != bp:
            return ap < bp
        return _stable(seed_value,loop_index,str(a)) < _stable(seed_value,loop_index,str(b))
    )
    var incident_id := str(candidates[0])
    var result: Dictionary = Dictionary(INCIDENTS[incident_id]).duplicate(true)
    result["id"] = incident_id
    return result

static func scene(incident: Dictionary, loop_index: int, can_foreknow: bool) -> Dictionary:
    if incident.is_empty():
        return {}
    var incident_id := str(incident.get("id",""))
    var choices: Array = Array(incident.get("choices",[])).duplicate(true)
    if can_foreknow:
        choices.append({
            "label":"지난 회차에서 본 징후를 먼저 확인한다.",
            "effect":"record","incident_action":"foreknowledge","outcome":"COSTLY",
            "note":"문제는 더 일찍 막았지만, 원래 생겼을 기록 하나가 남지 않았다.",
            "source_type":"DIRECT","foreknowledge":true})
    return {
        "id":"055_incident_%s_%d" % [incident_id,loop_index],
        "speaker":str(incident.get("actor","")),"tag":"incident","category":"INCIDENT",
        "family":"incident_" + incident_id,"intent":"ship_pressure",
        "action":str(incident.get("action","")),"lines":[],"choices":choices,
        "incident_id":incident_id,"compressible":false}

static func resolve(incident: Dictionary, choice: Dictionary, loop_index: int, action_index: int) -> Dictionary:
    if incident.is_empty():
        return {}
    return {
        "id":str(incident.get("id","")),"loop":loop_index,"action_index":action_index,
        "choice":str(choice.get("incident_action","")),"outcome":str(choice.get("outcome","PARTIAL")),
        "note":str(choice.get("note","")),"source_type":str(choice.get("source_type","DIRECT")),
        "foreknowledge":bool(choice.get("foreknowledge",false))}
