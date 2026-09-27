class_name AstraForeknowledgeModel
extends RefCounted

const SOURCE_LABELS := {"DIRECT":"직접 확인","RECORD":"기록","TESTIMONY":"진술","RUMOR":"전해 들음"}

# 1.2.0 AFTERIMAGE
# Past Echo is deliberately data inside the existing foreknowledge model, not a
# second memory/progression manager. Eligibility comes only from route_history:
# a route entry is written by story_choose() after the player actually selected
# it. Stage number, hidden truth, generated Null roles and debug state are never
# accepted as unlock sources.
const PAST_ECHO_OPPORTUNITIES := [
    {
        "id":"echo_growth_before_label","case_id":"RED_SHIFT","speaker":"lyra",
        "anchor":"DEAD_AIR","routes":["PUBLIC","VERIFY_FIRST"],"role":"MAREN_ENVIRONMENT",
        "variants":{
            "PUBLIC":{"mode":"WITNESS","label":"[잔향] 라벨보다 생장 흔적부터 확인한다","question":"문서보다 먼저, 이 표본이 얼마나 오래 이렇게 자랐는지 볼 수 있어요?","reaction":"아직 표본 기록도 다 안 봤는데 왜 생장 시간부터 묻는 거예요?","trust_delta":0.01},
            "VERIFY_FIRST":{"mode":"RECORD","label":"[잔향] 원본 라벨과 생장 주기를 먼저 대조한다","question":"사본 말고 원본 라벨과 실제 생장 주기부터 같이 맞춰 봐요.","reaction":"원본부터 보자는 순서가 너무 정확하네요. 전에 비슷한 걸 본 적 있어요?","trust_delta":0.03}
        }
    },
    {
        "id":"echo_route_before_power","case_id":"LAST_LIGHT","speaker":"eli",
        "anchor":"ECHO_WARD","routes":["TELL_SOREN","VERIFY_FIRST"],"role":"LUCAN_ROUTE",
        "variants":{
            "TELL_SOREN":{"mode":"WITNESS","label":"[잔향] 가장 짧은 길보다 실제 통과 가능한 길을 묻는다","question":"거리 말고, 그 시간에 실제로 열려 있던 통로만 놓고 보면 어디로 움직일 수 있었어요?","reaction":"아직 동선 얘기도 안 나왔는데 왜 막힌 통로부터 빼는 거지?","trust_delta":-0.01},
            "VERIFY_FIRST":{"mode":"RECORD","label":"[잔향] 이동 기록의 원본 시각부터 확인한다","question":"경로 추정 전에 출입 기록 원본 시각부터 맞춰 봐요.","reaction":"순서를 알고 온 사람처럼 말하네. 좋아, 기록부터 보자.","trust_delta":0.02}
        }
    },
    {
        "id":"echo_continuity_duty","case_id":"SECOND_WATCH","speaker":"lyra",
        "anchor":"RED_SHIFT","routes":["REVEAL","WITHHOLD_VERIFY"],"role":"MAREN_ENVIRONMENT",
        "variants":{
            "REVEAL":{"mode":"WITNESS","label":"[잔향] 근무 일지보다 생활 흔적의 누적부터 묻는다","question":"일지 날짜 말고 물, 공기, 재배 관리가 얼마나 이어졌는지부터 볼 수 있어요?","reaction":"근무 일지를 보고도 보통은 날짜부터 묻는데… 왜 관리 주기부터 보죠?","trust_delta":0.01},
            "WITHHOLD_VERIFY":{"mode":"RECORD","label":"[잔향] 관리 주기와 원본 일지를 나란히 놓는다","question":"원본 일지와 환경 관리 주기를 따로 보지 말고 같은 시간축에 놓아 봐요.","reaction":"그 비교를 먼저 하자는 건 이상할 만큼 구체적이네요. 그래도 확인할 가치는 있어요.","trust_delta":0.03}
        }
    },
    {
        "id":"echo_source_order_duty","case_id":"SECOND_WATCH","speaker":"noa",
        "anchor":"DEAD_AIR","routes":["PUBLIC","VERIFY_FIRST"],"role":"PROVENANCE",
        "variants":{
            "PUBLIC":{"mode":"RECORD","label":"[잔향] 누가 읽었는지보다 원본의 공개 순서부터 확인한다","question":"이 일지가 언제 발견됐는지와 언제 모두에게 공개됐는지부터 분리해서 적어 줘요.","reaction":"발견 시각보다 공개 순서를 먼저 묻네요. 그 차이가 중요하다고 이미 생각한 것처럼.","trust_delta":0.01},
            "VERIFY_FIRST":{"mode":"RECORD","label":"[잔향] 사본이 퍼지기 전 원본 열람자를 확인한다","question":"사본 말고, 원본을 처음 열어 본 사람과 시각부터 확인해요.","reaction":"왜 하필 첫 열람자부터죠? …알겠어요. 원본 이력부터 볼게요.","trust_delta":0.02}
        }
    },
    {
        "id":"echo_signal_habit","case_id":"BORROWED_DAYS","speaker":"vale",
        "anchor":"ECHO_WARD","routes":["TELL_SOREN","VERIFY_FIRST"],"role":"SIGNAL_SOURCE",
        "variants":{
            "TELL_SOREN":{"mode":"WITNESS","label":"[잔향] 익숙한 행동의 박자부터 확인한다","question":"무슨 행동이었는지 말고, 그 사람이 망설인 간격이나 반복되는 박자가 있었어요?","reaction":"그걸 왜 소리처럼 묻죠? …그래도 반복되는 간격은 있었어요.","trust_delta":0.02},
            "VERIFY_FIRST":{"mode":"RECORD","label":"[잔향] 행동 기록의 원본 시간 간격을 먼저 본다","question":"설명보다 원본 시간 간격부터 보고 싶어요. 반복되는 구간이 있는지요.","reaction":"이번에도 원본 간격부터 보네요. 이유는 모르겠지만, 그쪽이 더 안전하긴 해요.","trust_delta":0.03}
        }
    },
    {
        "id":"echo_feasible_blind","case_id":"BLIND_DECK","speaker":"eli",
        "anchor":"RED_SHIFT","routes":["REVEAL","WITHHOLD_VERIFY"],"role":"LUCAN_ROUTE",
        "variants":{
            "REVEAL":{"mode":"WITNESS","label":"[잔향] 진술보다 실제 우회 동선이 가능한지 먼저 묻는다","question":"그 말을 믿고 말고 전에, 그 시간에 그 우회로를 실제로 지나갈 수 있었어요?","reaction":"아직 누가 거길 갔다고 말하지도 않았는데 우회로부터 묻네.","trust_delta":-0.01},
            "WITHHOLD_VERIFY":{"mode":"RECORD","label":"[잔향] 이동 가능 시간을 기록과 먼저 맞춘다","question":"사람 말보다 출입 시각과 실제 이동 시간을 먼저 겹쳐 봐요.","reaction":"검증 순서가 너무 빠른데. 그래도 그 방식이면 가능한 동선부터 걸러낼 수 있어.","trust_delta":0.02}
        }
    },
    {
        "id":"echo_route_three_minutes","case_id":"THREE_MINUTES_DARK","speaker":"eli",
        "anchor":"BORROWED_DAYS","routes":["TELL","OBSERVE"],"role":"LUCAN_ROUTE",
        "variants":{
            "TELL":{"mode":"WITNESS","label":"[잔향] 세 구역 사이 실제 이동 시간을 먼저 맞춘다","question":"세 구역을 지도 위 점으로 보지 말고, 문이 열리는 시간까지 포함해서 실제 이동 시간을 재 봐요.","reaction":"왜 문 열리는 시간까지 집어서 말하지? …좋아. 그걸 넣으면 동선이 꽤 달라져.","trust_delta":-0.01},
            "OBSERVE":{"mode":"RECORD","label":"[잔향] 출입 흔적을 건드리기 전 경로부터 복원한다","question":"사람들한테 묻기 전에 출입 기록만으로 가능한 순서를 먼저 복원해 봐요.","reaction":"관찰부터 하자는 거네. 이상하게 준비된 질문이지만, 경로 검증에는 맞아.","trust_delta":0.02}
        }
    },
    {
        "id":"echo_environment_continuity","case_id":"CONTINUITY","speaker":"lyra",
        "anchor":"RED_SHIFT","routes":["REVEAL","WITHHOLD_VERIFY"],"role":"MAREN_ENVIRONMENT",
        "variants":{
            "REVEAL":{"mode":"WITNESS","label":"[잔향] 기록보다 오래 남는 환경 흔적부터 확인한다","question":"로그가 바뀌었다고 가정해도 남는 것들, 물때나 생장량 같은 누적 흔적부터 볼 수 있어요?","reaction":"그 질문… 기록이 달라질 수 있다는 걸 먼저 전제로 두고 있네요.","trust_delta":-0.01},
            "WITHHOLD_VERIFY":{"mode":"RECORD","label":"[잔향] 관리 주기와 원본 기록의 어긋남을 먼저 찾는다","question":"원본 기록과 실제 관리 주기가 어긋나는 지점만 먼저 표시해 줘요.","reaction":"무엇이 어긋날지 이미 아는 사람처럼 들려요. 하지만 이건 제가 확인할 수 있어요.","trust_delta":0.02}
        }
    },
    {
        "id":"echo_interval_continuity","case_id":"CONTINUITY","speaker":"vale",
        "anchor":"ECHO_WARD","routes":["TELL_SOREN","VERIFY_FIRST"],"role":"SIGNAL_SOURCE",
        "variants":{
            "TELL_SOREN":{"mode":"WITNESS","label":"[잔향] 목소리보다 반복 간격부터 듣는다","question":"누구 목소리인지 말고, 반복되는 간격이 같은지부터 들어 봐요.","reaction":"또 간격부터요? …그걸 먼저 듣는 사람은 별로 없는데.","trust_delta":0.01},
            "VERIFY_FIRST":{"mode":"RECORD","label":"[잔향] 재생본보다 손대지 않은 원음을 먼저 연다","question":"분석본 말고 손대지 않은 원음부터 열어 봐요. 시각과 간격만 먼저 볼게요.","reaction":"원음을 먼저 찾는 이유를 아직 설명 안 했죠. 그래도 그게 맞아요.","trust_delta":0.03}
        }
    },
    {
        "id":"echo_threshold_route","case_id":"THRESHOLD","speaker":"eli",
        "anchor":"THREE_MINUTES_DARK","routes":["POWER","COMMS","SECURITY"],"role":"LUCAN_ROUTE",
        "variants":{
            "POWER":{"mode":"WITNESS","label":"[잔향] 동력 구역에서 출발한 실제 수행 순서를 검증한다","question":"동력 구역을 출발점으로 놓고, 실제로 가능한 행동 순서만 다시 짜 봐요.","reaction":"동력을 시작점으로 고정하네. 그걸 왜 먼저 정했는지는 나중에 듣고 싶어.","trust_delta":-0.01},
            "COMMS":{"mode":"RECORD","label":"[잔향] 통신 기록 시각을 기준으로 이동 가능성을 검증한다","question":"통신 기록의 원본 시각을 기준으로, 앞뒤에 실제로 갈 수 있는 곳만 남겨 봐요.","reaction":"통신 시각을 축으로 잡는다고? 너무 정확한 출발인데… 일단 계산해 보자.","trust_delta":-0.01},
            "SECURITY":{"mode":"RECORD","label":"[잔향] 보안 출입 순서를 기준으로 가능한 경로만 남긴다","question":"보안 출입 순서를 기준으로 불가능한 동선을 먼저 지워 봐요.","reaction":"아직 출입 기록을 다 열지도 않았는데 그 순서부터 보자고 하네.","trust_delta":-0.01}
        }
    }
]

static func source_label(source_type: String) -> String:
    return str(SOURCE_LABELS.get(source_type,"직접 확인"))

static func can_use(loop_index: int, incident_id: String, incident_history: Array, used: Array) -> bool:
    if loop_index <= 0 or used.size() >= 2 or incident_id in used:
        return false
    for event in incident_history:
        if str(event.get("id","")) == incident_id and int(event.get("loop",-1)) < loop_index:
            return true
    return false

static func _experienced_route(route_history: Array, anchor: String, allowed_routes: Array, loop_index: int) -> String:
    var best_loop := -1
    var result := ""
    for raw in route_history:
        if not raw is Dictionary:
            continue
        var event: Dictionary = raw
        var route := str(event.get("route",""))
        var event_loop := int(event.get("loop",-1))
        if str(event.get("anchor","")) != anchor or route not in allowed_routes:
            continue
        if event_loop < 0 or event_loop >= loop_index:
            continue
        # route_history is authoritative only when story_choose recorded an
        # actual authored scene. Hand-made/debug route_choices alone do not
        # unlock an Echo.
        if str(event.get("scene","")) == "":
            continue
        if event_loop >= best_loop:
            best_loop = event_loop
            result = route
    return result

static func past_echo_candidates(case_id: String, npc_id: String, route_history: Array, used: Array, loop_index: int) -> Array:
    var result: Array = []
    if loop_index <= 0:
        return result
    for raw in PAST_ECHO_OPPORTUNITIES:
        var spec: Dictionary = raw
        if str(spec.get("case_id","")) != case_id or str(spec.get("speaker","")) != npc_id:
            continue
        var id := str(spec.get("id",""))
        if id == "" or id in used:
            continue
        var route := _experienced_route(route_history, str(spec.get("anchor","")), Array(spec.get("routes",[])), loop_index)
        if route == "":
            continue
        var variants: Dictionary = spec.get("variants",{})
        if not variants.has(route):
            continue
        var candidate: Dictionary = spec.duplicate(true)
        candidate.erase("variants")
        candidate["source_route"] = route
        candidate.merge(Dictionary(variants[route]).duplicate(true), true)
        result.append(candidate)
    return result

static func past_echo_candidate(case_id: String, npc_id: String, echo_id: String, route_history: Array, used: Array, loop_index: int) -> Dictionary:
    for candidate in past_echo_candidates(case_id,npc_id,route_history,used,loop_index):
        if str(candidate.get("id","")) == echo_id:
            return Dictionary(candidate).duplicate(true)
    return {}

static func past_echo_specs() -> Array:
    return PAST_ECHO_OPPORTUNITIES.duplicate(true)

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
