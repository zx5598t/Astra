class_name AstraProgressionGameState
extends AstraRandomCaseGameState

const PROGRESSION_VERSION := "0.0.7"

var relationship_event_log: Array[Dictionary] = []
var _relationship_event_keys: Dictionary = {}

func setup(seed_in: int = 260916) -> void:
    super.setup(seed_in)
    relationship_event_log.clear()
    _relationship_event_keys.clear()

func advance_phase() -> void:
    var previous := phase_name()
    super.advance_phase()
    if game_over or phase_name() == previous:
        return
    if phase_name() in ["INTERROGATION", "MEETING"]:
        _try_relationship_event()

func _try_relationship_event() -> void:
    var best_source := ""
    var best_target := ""
    var best_strength := 0.0
    for source_id in crew_order:
        var source: NPCState = npcs[source_id]
        if not source.alive:
            continue
        for target_id in crew_order:
            if target_id == source_id or not npcs[target_id].alive:
                continue
            var value := affinity(source_id, target_id)
            if absf(value) > absf(best_strength):
                best_strength = value
                best_source = source_id
                best_target = target_id

    if best_source == "" or absf(best_strength) < 0.12:
        return
    var key := "%d:%s:%s:%s" % [day, phase_name(), best_source, best_target]
    if key in _relationship_event_keys:
        return
    _relationship_event_keys[key] = true

    var source: NPCState = npcs[best_source]
    var target: NPCState = npcs[best_target]
    var kind := "bond" if best_strength > 0.0 else "friction"
    var text := ""
    if kind == "bond":
        text = "%s이(가) %s의 설명을 먼저 들어보자며 대화를 중재했다." % [source.display_name, target.display_name]
        target.adjust_trust(0.015)
        source.set_suspicion(target.id, source.get_suspicion(target.id) - 0.035)
    else:
        text = "%s이(가) %s의 설명 방식에 노골적으로 불신을 드러냈다." % [source.display_name, target.display_name]
        source.set_suspicion(target.id, source.get_suspicion(target.id) + 0.055)
        source.adjust_stress(0.025)
        target.adjust_stress(0.025)

    var event := {
        "key": key,
        "day": day,
        "phase": phase_name(),
        "kind": kind,
        "source_id": best_source,
        "target_id": best_target,
        "strength": best_strength,
        "text": text
    }
    relationship_event_log.append(event)
    source.remember("Relationship event: %s" % text)
    target.remember("Relationship event: %s" % text)
    log_event("RELATIONSHIP · %s" % text)
    emit_signal("state_changed")

func latest_relationship_event() -> Dictionary:
    if relationship_event_log.is_empty():
        return {}
    return relationship_event_log[-1]

func environment_asset_path() -> String:
    if case_id == "GLASS_GARDEN":
        return "res://assets/environments/glass_garden.svg"
    return "res://assets/environments/dead_air.svg"

func expression_slot(npc_id: String) -> String:
    var emotion := expression_for(npc_id)
    if emotion in ["warm"]:
        return "warm"
    if emotion in ["angry", "afraid", "guarded", "cold", "uneasy"]:
        return "tense"
    return "calm"

func expression_asset_path(npc_id: String) -> String:
    return str(npcs[npc_id].portrait_path) if npc_id in npcs else ""

func expression_overlay_path(npc_id: String) -> String:
    return "res://assets/expressions/%s_overlay.svg" % expression_slot(npc_id)

func relationship_event_report() -> String:
    if relationship_event_log.is_empty():
        return "아직 특별한 관계 이벤트가 발생하지 않았다."
    var lines: Array[String] = []
    var start := maxi(0, relationship_event_log.size() - 4)
    for i in range(start, relationship_event_log.size()):
        var event: Dictionary = relationship_event_log[i]
        lines.append("D%d · %s" % [int(event.get("day", 1)), str(event.get("text", ""))])
    return "\n".join(lines)
