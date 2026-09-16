class_name AIGateway
extends RefCounted

# 0.0.2 keeps AI optional so the game is playable offline.
# Future network implementations must return this restricted schema and must
# never mutate TruthEngine, roles, votes, evidence ownership, or win results.

var enabled: bool = false

const ALLOWED_ACTS := ["answer", "deflect", "accuse", "reassure", "refuse"]
const ALLOWED_EMOTIONS := ["calm", "uneasy", "angry", "afraid", "guarded"]

func is_available() -> bool:
    return enabled

func request_npc_action(_context: Dictionary) -> Dictionary:
    return {
        "ok": false,
        "social_act": "answer",
        "target_id": "",
        "claim_refs": [],
        "claim_mode": "truth",
        "display_emotion": "calm",
        "utterance": "",
        "reason": "AI backend is not configured. Rule-based performance is active."
    }

func validate_action(action: Dictionary, allowed_fact_refs: Array[String]) -> bool:
    if str(action.get("social_act", "")) not in ALLOWED_ACTS:
        return false
    if str(action.get("display_emotion", "")) not in ALLOWED_EMOTIONS:
        return false
    for ref in action.get("claim_refs", []):
        if str(ref) not in allowed_fact_refs:
            return false
    return true
