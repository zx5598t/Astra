class_name NPCState
extends RefCounted

var id: String = ""
var display_name: String = ""
var job: String = ""
var role: String = "CREW"
var alive: bool = true
var accent: Color = Color.WHITE
var personality: Dictionary = {}
var emotion: Dictionary = {"stress": 0.2, "anger": 0.1, "fear": 0.1}
var trust_player: float = 0.5
var suspicion: Dictionary = {}
var knowledge: Array[String] = []
var memories: Array[String] = []
var commitments: Array[String] = []
var notes: Array[String] = []

func _init(data: Dictionary = {}) -> void:
    id = str(data.get("id", "npc"))
    display_name = str(data.get("name", id))
    job = str(data.get("job", "Crew"))
    role = str(data.get("role", "CREW"))
    accent = data.get("accent", Color.WHITE)
    personality = data.get("personality", {}).duplicate(true)
    trust_player = float(data.get("trust_player", 0.5))
    for item in data.get("knowledge", []):
        knowledge.append(str(item))

func remember(text: String) -> void:
    memories.append(text)
    if memories.size() > 16:
        memories.pop_front()

func add_commitment(text: String) -> void:
    if text not in commitments:
        commitments.append(text)
    if commitments.size() > 10:
        commitments.pop_front()

func add_note(text: String) -> void:
    if text not in notes:
        notes.append(text)

func knows_fact(fact_id: String) -> bool:
    return fact_id in knowledge

func adjust_trust(delta: float) -> void:
    trust_player = clampf(trust_player + delta, 0.0, 1.0)

func adjust_stress(delta: float) -> void:
    emotion["stress"] = clampf(float(emotion.get("stress", 0.2)) + delta, 0.0, 1.0)

func set_suspicion(target_id: String, value: float) -> void:
    suspicion[target_id] = clampf(value, 0.0, 1.0)

func get_suspicion(target_id: String) -> float:
    return float(suspicion.get(target_id, 0.5))

func highest_suspicion() -> String:
    var best_id := ""
    var best_score := -1.0
    for target_id in suspicion.keys():
        var score := get_suspicion(str(target_id))
        if score > best_score:
            best_score = score
            best_id = str(target_id)
    return best_id
