class_name AstraCrewMember
extends RefCounted

# Runtime state of one crew member for a single case.

const STATUS_ACTIVE := "active"
const STATUS_ISOLATED := "isolated"
const STATUS_OFFLINE := "offline"

var id: String = ""
var display_name: String = ""
var job: String = ""
var accent: Color = Color.WHITE
var info: Dictionary = {}
var role: String = "CREW"
var status: String = STATUS_ACTIVE
var trust: float = 0.5
var stress: float = 0.2
var suspicion: Dictionary = {}
var affinity: Dictionary = {}
var expression: String = "calm"
var secret_revealed: bool = false
var slipped: bool = false
var audited: bool = false
var questions_asked: int = 0
var memories: Array[String] = []

func _init(npc_id: String = "") -> void:
    id = npc_id
    info = AstraCrewCatalog.info(npc_id)
    display_name = str(info.get("name", npc_id))
    job = str(info.get("job", ""))
    accent = Color(str(info.get("accent", "ffffff")))
    trust = float(info.get("trust", 0.5))

func is_alive() -> bool:
    return status == STATUS_ACTIVE

func is_null() -> bool:
    return role == "NULL"

func personality(key: String, fallback: float = 0.5) -> float:
    return float(info.get("personality", {}).get(key, fallback))

func adjust_trust(delta: float) -> void:
    trust = clampf(trust + delta, 0.0, 1.0)

func adjust_stress(delta: float) -> void:
    stress = clampf(stress + delta, 0.0, 1.0)

func get_suspicion(target_id: String) -> float:
    return float(suspicion.get(target_id, 0.25))

func add_suspicion(target_id: String, delta: float) -> void:
    if target_id == id:
        return
    suspicion[target_id] = clampf(get_suspicion(target_id) + delta, 0.0, 1.0)

func get_affinity(target_id: String) -> float:
    return float(affinity.get(target_id, 0.0))

func add_affinity(target_id: String, delta: float) -> void:
    if target_id == id:
        return
    affinity[target_id] = clampf(get_affinity(target_id) + delta, -1.0, 1.0)

func remember(text: String) -> void:
    memories.append(text)
    if memories.size() > 24:
        memories.pop_front()

func refresh_expression() -> void:
    if stress >= 0.72:
        expression = "tense"
    elif trust >= 0.68 and stress < 0.45:
        expression = "warm"
    elif stress >= 0.5:
        expression = "uneasy"
    else:
        expression = "calm"

func mood_label() -> String:
    match expression:
        "warm": return "우호적"
        "tense": return "극도로 긴장"
        "uneasy": return "불안"
    return "침착"
