class_name AstraPersonalMotiveModel
extends RefCounted

# ASTRA 0.5.5 — FAULT LINES
# A motive explains suspicious behaviour. It is deliberately independent from Null.

const STATES := ["HIDDEN","SUSPECTED","PARTIAL","REVEALED"]
const MOTIVES := [
    "PROTECT_PERSON","HIDE_MISTAKE","KEEP_PRIVACY","PRESERVE_EVIDENCE",
    "PROTECT_REPUTATION","FINISH_DUTY","SAVE_RESOURCE","KEEP_PROMISE",
    "VERIFY_ALONE","AVOID_ISOLATION","FEAR_REPEAT"
]
const COMPATIBLE := {
    "mira":["PROTECT_PERSON","KEEP_PRIVACY","FINISH_DUTY","FEAR_REPEAT"],
    "rho":["HIDE_MISTAKE","FINISH_DUTY","PROTECT_PERSON"],
    "dax":["PROTECT_REPUTATION","VERIFY_ALONE","FINISH_DUTY"],
    "noa":["PRESERVE_EVIDENCE","VERIFY_ALONE","KEEP_PROMISE"],
    "sena":["PROTECT_PERSON","AVOID_ISOLATION","FINISH_DUTY"],
    "vale":["VERIFY_ALONE","KEEP_PRIVACY","FEAR_REPEAT"],
    "eli":["FINISH_DUTY","PROTECT_PERSON","VERIFY_ALONE"],
    "lyra":["SAVE_RESOURCE","PROTECT_PERSON","KEEP_PROMISE"]
}
const ACTIVE_CHAPTERS := ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

static func motive_types() -> int:
    return MOTIVES.size()

static func is_compatible(npc_id: String, motive: String) -> bool:
    return motive in COMPATIBLE.get(npc_id,[])

static func _stable(seed_value: int, loop_index: int, key: String) -> int:
    return abs(hash("055:motive:%d:%d:%s" % [seed_value,loop_index,key]))

static func assign(seed_value: int, loop_index: int, chapter: String, roster: Array, active_ids: Array, null_ids: Array = []) -> Dictionary:
    # null_ids is intentionally not used: motive != Null.
    if chapter not in ACTIVE_CHAPTERS:
        return {}
    var candidates: Array = []
    for raw in roster:
        var npc_id := str(raw)
        if npc_id in active_ids and COMPATIBLE.has(npc_id):
            candidates.append(npc_id)
    candidates.sort_custom(func(a,b):
        return _stable(seed_value,loop_index,str(a)) < _stable(seed_value,loop_index,str(b))
    )
    if candidates.is_empty():
        return {}
    var max_count := mini(3,candidates.size())
    var count := 1 + (_stable(seed_value,loop_index,chapter + ":count") % max_count)
    if count >= candidates.size() and candidates.size() > 1:
        count = candidates.size()-1
    count = maxi(1,mini(3,count))
    var result := {}
    for index in range(count):
        var npc_id := str(candidates[index])
        var pool: Array = COMPATIBLE[npc_id]
        var motive := str(pool[_stable(seed_value,loop_index,npc_id + ":kind") % pool.size()])
        result[npc_id] = {"motive":motive,"state":"HIDDEN","progress":0,"sources":[],"loop":loop_index}
    return result

static func observe(state: Dictionary, npc_id: String, source_key: String, detail: String = "") -> Dictionary:
    var result: Dictionary = state.duplicate(true)
    if not result.has(npc_id):
        return result
    var entry: Dictionary = Dictionary(result[npc_id]).duplicate(true)
    var sources: Array = Array(entry.get("sources",[])).duplicate()
    if source_key == "" or source_key in sources:
        return result
    sources.append(source_key)
    entry["sources"] = sources
    entry["progress"] = mini(3,int(entry.get("progress",0))+1)
    var progress := int(entry["progress"])
    entry["state"] = "SUSPECTED" if progress == 1 else ("PARTIAL" if progress == 2 else "REVEALED")
    if detail != "":
        entry["last_detail"] = detail
    result[npc_id] = entry
    return result

static func motive_for(state: Dictionary, npc_id: String) -> String:
    return str(state.get(npc_id,{}).get("motive",""))

static func progress_for(state: Dictionary, npc_id: String) -> int:
    return int(state.get(npc_id,{}).get("progress",0))

static func player_hint(state: Dictionary, npc_id: String) -> String:
    var progress := progress_for(state,npc_id)
    if progress <= 0:
        return ""
    if progress == 1:
        return "행동에는 사건 자체와 다른 개인적인 이유가 있을지도 모른다."
    if progress == 2:
        return "서로 다른 흔적이 같은 개인적인 이유를 가리킨다. 아직 전부 확인된 것은 아니다."
    return "행동의 개인적인 이유는 확인됐다. 그 이유와 Null 여부는 별개의 문제다."

static func dev_report(state: Dictionary) -> Array:
    var rows: Array = []
    for npc_id in state:
        var e: Dictionary = state[npc_id]
        rows.append({
            "npc":str(npc_id),"motive":str(e.get("motive","")),
            "state":str(e.get("state","HIDDEN")),"progress":int(e.get("progress",0)),
            "sources":Array(e.get("sources",[])).duplicate()
        })
    return rows
