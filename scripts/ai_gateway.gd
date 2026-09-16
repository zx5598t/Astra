class_name AIGateway
extends RefCounted

# ASTRA 0.0.5 AI contract.
# The model performs expression only. Truth, roles, evidence, votes, score,
# relationship math and win/loss remain authoritative game code.

var enabled: bool = true
var provider_name: String = "openai_backend"
var endpoint: String = "http://127.0.0.1:8787/npc/action"

const CONTRACT_VERSION := "0.0.5"
const ALLOWED_ACTS := ["answer", "deflect", "accuse", "reassure", "interrupt", "challenge", "refuse"]
const ALLOWED_EMOTIONS := ["calm", "uneasy", "angry", "afraid", "guarded", "warm", "cold"]
const ALLOWED_CLAIM_MODES := ["truth", "lie", "speculation", "mistake"]
const MAX_UTTERANCE_CHARS := 360

func is_available() -> bool:
    return enabled and endpoint != ""

func request_npc_action(_context: Dictionary) -> Dictionary:
    return fallback_action("Remote backend is asynchronous. Rule-based performance is active until a validated response arrives.")

func fallback_action(reason: String) -> Dictionary:
    return {
        "ok": false,
        "contract_version": CONTRACT_VERSION,
        "social_act": "answer",
        "target_id": "",
        "claim_refs": [],
        "claim_mode": "truth",
        "display_emotion": "calm",
        "relationship_delta": 0.0,
        "utterance": "",
        "reason": reason
    }

func build_request_payload(context: Dictionary) -> Dictionary:
    return {
        "contract_version": CONTRACT_VERSION,
        "provider": provider_name,
        "npc": context.get("npc", {}),
        "scene": context.get("scene", {}),
        "allowed_fact_refs": context.get("allowed_fact_refs", []),
        "allowed_facts": context.get("allowed_facts", {}),
        "allowed_target_ids": context.get("allowed_target_ids", []),
        "known_evidence": context.get("known_evidence", []),
        "relationships": context.get("relationships", {}),
        "recent_turns": context.get("recent_turns", []),
        "instruction": "Perform this NPC only. Use only supplied canonical facts. Never decide truth, votes, score, role or relationship values."
    }

func validate_action(action: Dictionary, allowed_fact_refs: Array[String], allowed_targets: Array[String]) -> bool:
    if not bool(action.get("ok", false)):
        return false
    if str(action.get("contract_version", "")) != CONTRACT_VERSION:
        return false
    if str(action.get("social_act", "")) not in ALLOWED_ACTS:
        return false
    if str(action.get("display_emotion", "")) not in ALLOWED_EMOTIONS:
        return false
    if str(action.get("claim_mode", "truth")) not in ALLOWED_CLAIM_MODES:
        return false
    var target_id := str(action.get("target_id", ""))
    if target_id != "" and target_id not in allowed_targets:
        return false
    for ref in action.get("claim_refs", []):
        if str(ref) not in allowed_fact_refs:
            return false
    var utterance := str(action.get("utterance", ""))
    if utterance == "" or utterance.length() > MAX_UTTERANCE_CHARS:
        return false
    var rel_delta := float(action.get("relationship_delta", 0.0))
    if rel_delta < -0.12 or rel_delta > 0.12:
        return false
    return true
