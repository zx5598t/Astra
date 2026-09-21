class_name AstraForeknowledgeModel
extends RefCounted

const SOURCE_LABELS := {"DIRECT":"직접 확인","RECORD":"기록","TESTIMONY":"진술","RUMOR":"전해 들음"}

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
