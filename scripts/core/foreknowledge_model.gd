class_name AstraForeknowledgeModel
extends RefCounted

const SOURCE_LABELS := {"DIRECT":"직접 확인","RECORD":"기록","TESTIMONY":"진술","RUMOR":"전해 들음"}
# 1.2.0 AFTERIMAGE. These are remembered investigation directions, never truth.
# Eligibility is tied to an authored route or micro-arc choice the player actually
# experienced. No Stage number, hidden role, generator truth or undiscovered
# evidence can unlock an entry.
const PAST_ECHO_OPPORTUNITIES := [
    {"id":"route_after_dead_air","case":"SILENT_ORBIT","requires":["route:DEAD_AIR"],"lead":"eli","observer":"eli",
        "label":"[잔향] 통신 기록보다 실제 이동 경로부터 확인한다.",
        "question":"기록이 맞다는 전제부터 버리자. 그 시간에 실제로 가능한 경로는 어디였을까?",
        "context":"탐사요원은 통신 기록보다 이동 가능한 경로를 먼저 좁혔다. 루칸이 실제 통과 시간과 위험 구간을 기준으로 설명한다."},
    {"id":"voice_before_record","case":"RED_SHIFT","requires":["route:ECHO_WARD"],"lead":"vale","observer":"vale",
        "label":"[잔향] 문장 내용보다 음성의 시간과 간격부터 확인한다.",
        "question":"무슨 말을 했는지보다 언제 만들어진 음성인지 먼저 확인하면 무엇이 달라질까?",
        "context":"탐사요원은 내용보다 생성 시각과 호흡 간격을 먼저 짚었다. 소렌이 신호의 순서를 다시 펼친다."},
    {"id":"dual_original_order","case":"SECOND_WATCH","requires":["route:DEAD_AIR"],"lead":"noa","observer":"noa",
        "label":"[잔향] 어느 문서가 맞는지보다 두 원본이 함께 남은 순서를 본다.",
        "question":"둘 중 하나를 가짜로 정하기 전에, 두 원본이 언제부터 함께 있었는지 확인할 수 있을까?",
        "context":"탐사요원은 문서의 진위보다 두 원본이 함께 존재한 순서를 먼저 요구했다. 노아가 보관 경로를 분리해 읽는다."},
    {"id":"red_shift_provenance","case":"BORROWED_DAYS","requires":["route:RED_SHIFT"],"lead":"noa","observer":"noa",
        "label":"[잔향] 내용보다 누가 언제 이 기록을 만졌는지부터 확인한다.",
        "question":"기록의 문장보다 보관 경로를 먼저 따라가면 누가 무엇을 알았는지 분리할 수 있을까?",
        "context":"탐사요원은 기록 내용 대신 provenance를 먼저 꺼냈다. 노아가 열람 순서와 공개 범위를 나눠 적는다."},
    {"id":"lucan_cost_route","case":"BLIND_DECK","requires_any":["tag:054_eli_stable_route","tag:054_eli_risk_route","tag:054_eli_owns_route"],"lead":"eli","observer":"eli",
        "label":"[잔향] 가장 빠른 길이 아니라 실제로 감당 가능한 길부터 지운다.",
        "question":"그 시간에 가능했던 경로를 시간·산소·진동 비용으로 나누면 어떤 길이 남을까?",
        "context":"탐사요원은 경로를 거리 대신 비용과 위험으로 잘랐다. 루칸이 통과 가능 시간과 우회 비용을 먼저 계산한다."},
    {"id":"echo_route_again","case":"BLIND_DECK","requires":["route:ECHO_WARD"],"lead":"vale","observer":"vale",
        "label":"[잔향] 반복 신호와 현재 기록이 겹치는 시각부터 찾는다.",
        "question":"전에 들었던 반복처럼, 이번에도 내용보다 겹치는 시간대를 먼저 찾을 수 있을까?",
        "context":"탐사요원은 반복되는 말이 아니라 반복되는 시간대를 먼저 찾았다. 소렌이 파형의 공백을 기준으로 다시 듣는다."},
    {"id":"borrowed_habit_route","case":"THREE_MINUTES_DARK","requires":["route:BORROWED_DAYS"],"lead":"eli","observer":"eli",
        "label":"[잔향] 평소 습관 대신 그 행동이 실제로 가능한 동선을 확인한다.",
        "question":"기억나는 습관과 상관없이, 세 구역을 그 시간 안에 실제로 오갈 수 있었을까?",
        "context":"탐사요원은 사람의 습관을 정답처럼 쓰지 않고 실제 이동 가능성을 먼저 검증했다. 루칸이 세 구역의 이동 시간을 겹쳐 놓는다."},
    {"id":"maren_continuity","case":"CONTINUITY","requires_any":["tag:054_lyra_saved_sample","tag:054_lyra_discarded_sample"],"lead":"lyra","observer":"lyra",
        "label":"[잔향] 로그보다 생장·관리 주기가 남긴 물리적 흔적부터 본다.",
        "question":"기록이 바뀌어도 식물의 생장과 관리 주기는 같은 시간을 말하고 있을까?",
        "context":"탐사요원은 로그가 아니라 누적된 생장과 관리 흔적을 먼저 요청했다. 마렌이 물·공기·재배 주기를 한 표에 겹친다."},
    {"id":"three_minutes_source","case":"CONTINUITY","requires":["route:THREE_MINUTES_DARK"],"lead":"noa","observer":"noa",
        "label":"[잔향] 같은 사실도 직접 본 것과 기록으로 본 것을 분리한다.",
        "question":"우리가 아는 것 중 직접 확인한 것과 기록으로만 아는 것을 나누면 무엇이 남을까?",
        "context":"탐사요원은 결론 대신 정보의 출처를 먼저 분리했다. 회의는 같은 사실을 누가 어떻게 알았는지부터 확인한다."},
    {"id":"threshold_feasibility","case":"THRESHOLD","requires":["route:THREE_MINUTES_DARK"],"lead":"eli","observer":"eli",
        "label":"[잔향] 최종 기록을 믿기 전에 실제 수행 가능한 순서인지 검증한다.",
        "question":"이 기록대로 행동했다면 필요한 시간과 경로가 실제로 성립할까?",
        "context":"탐사요원은 최종 기록의 문장보다 수행 가능성을 먼저 검증했다. 루칸이 필요한 시간과 통과 지점을 순서대로 짚는다."}
]

static func _tag_seen(memory: Dictionary, wanted: String) -> bool:
    for raw in memory.get("memory_tags", []):
        var tag := str(raw)
        if tag == wanted or tag.ends_with(":" + wanted):
            return true
    return false

static func _requirement_seen(memory: Dictionary, requirement: String) -> bool:
    if requirement.begins_with("route:"):
        return str(memory.get("route_choices", {}).get(requirement.trim_prefix("route:"), "")) != ""
    if requirement.begins_with("tag:"):
        return _tag_seen(memory, requirement.trim_prefix("tag:"))
    if requirement.begins_with("scene:"):
        return int(memory.get("scene_seen_counts", {}).get(requirement.trim_prefix("scene:"), 0)) > 0
    return false

static func candidate_allowed(candidate: Dictionary, memory: Dictionary) -> bool:
    var required: Array = candidate.get("requires", [])
    for requirement in required:
        if not _requirement_seen(memory, str(requirement)):
            return false
    var any_required: Array = candidate.get("requires_any", [])
    if not any_required.is_empty():
        var found := false
        for requirement in any_required:
            if _requirement_seen(memory, str(requirement)):
                found = true
                break
        if not found:
            return false
    return not required.is_empty() or not any_required.is_empty()

static func past_echo_candidates(case_id: String, memory: Dictionary, used: Array = []) -> Array:
    var result: Array = []
    for raw in PAST_ECHO_OPPORTUNITIES:
        var candidate: Dictionary = raw
        if str(candidate.get("case", "")) != case_id or str(candidate.get("id", "")) in used:
            continue
        if candidate_allowed(candidate, memory):
            result.append(candidate.duplicate(true))
    return result

static func past_echo_by_id(echo_id: String) -> Dictionary:
    for raw in PAST_ECHO_OPPORTUNITIES:
        var candidate: Dictionary = raw
        if str(candidate.get("id", "")) == echo_id:
            return candidate.duplicate(true)
    return {}


static func source_label(source_type: String) -> String:
    return str(SOURCE_LABELS.get(source_type,"직접 확인"))

static func can_use(loop_index: int, incident_id: String, incident_history: Array, used: Array) -> bool:
    if loop_index <= 0 or used.size() >= 2 or incident_id in used:
        return false
    for event in incident_history:
        if str(event.get("id","")) == incident_id and int(event.get("loop",-1)) < loop_index:
            return true
    return false

static func reaction_scene(observer: String, incident_id: String, loop_index: int) -> Dictionary:
    var lines := {
        "sena":"아직 경보도 안 떴는데 왜 거기부터 확인한 거야?",
        "noa":"그 기록이 생길 걸 알고 있었던 것처럼 움직였네요.",
        "mira":"미리 아는 사람처럼 움직였어요. 이유는 나중에라도 말해 줘요.",
        "rho":"잠깐. 고장 나기 전에 그걸 왜 먼저 열었어?",
        "dax":"예측이라면 근거가 있어야 해. 지금은 순서가 반대였어.",
        "vale":"신호가 오기 전에 주파수를 잡았어요. 우연이라고 보기엔 정확했어요.",
        "eli":"문제가 생기기 전에 우회로를 골랐네. 그 이유는 기억해 둘게.",
        "lyra":"아직 변하지 않은 걸 먼저 살피는 건… 이상하긴 해요."}
    return {
        "id":"055_foreknowledge_reaction_%s_%s_%d" % [observer,incident_id,loop_index],
        "speaker":observer,"tag":"reaction","category":"FOREKNOWLEDGE",
        "family":"foreknowledge_" + incident_id,"intent":"player_foreknowledge",
        "action":"당신이 경보보다 먼저 움직인 것을 동료가 놓치지 않았다.",
        "lines":[[observer,str(lines.get(observer,lines["noa"]))]],"choices":[],"compressible":false}

static func can_compress(scene: Dictionary, seen_count: int) -> bool:
    if seen_count < 2 or not bool(scene.get("compressible",false)):
        return false
    if not Array(scene.get("choices",[])).is_empty():
        return false
    if str(scene.get("category","")) in ["CONSEQUENCE","INCIDENT","MOTIVE","FOREKNOWLEDGE","CANON","RELATIONSHIP"]:
        return false
    if scene.has("opinion_change") or scene.has("motive_progress") or scene.has("chain_id"):
        return false
    return true

static func compressed_action(scene: Dictionary) -> String:
    if str(scene.get("speaker","")) == "":
        return "이미 여러 번 확인한 장면이다. 지난 기록과 달라진 점은 없다."
    return "익숙한 장면이 다시 이어졌다. 지난 기록과 달라진 점은 없다."

static func update_momentum(previous: Dictionary, meaningful: bool) -> Dictionary:
    var result: Dictionary = previous.duplicate(true)
    var drought := 0 if meaningful else int(result.get("drought",0))+1
    result["drought"] = mini(2,drought)
    result["force_meaningful"] = drought >= 2
    return result
