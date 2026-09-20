class_name AstraKnowledgeModel
extends RefCounted

# Explicit who-knows-what ledger. A clue may be found by the player, shown to
# one crewmate, or made public. Decisions must never cite a fact the actor
# cannot reach through this ledger.

static func _root(flags: Dictionary) -> Dictionary:
    var root: Dictionary = flags.get("knowledge_052", {})
    if not root.has("facts"):
        root["facts"] = {}
    if not root.has("propagation"):
        root["propagation"] = []
    return root

static func _store(flags: Dictionary, root: Dictionary) -> void:
    flags["knowledge_052"] = root

static func discover_player(flags: Dictionary, fact_id: String, day: int, source: String = "investigation") -> void:
    if fact_id == "":
        return
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    var entry: Dictionary = facts.get(fact_id, {"knowers":[],"public":false,"provenance":[]})
    var knowers: Array = entry.get("knowers", [])
    if "player" not in knowers:
        knowers.append("player")
    entry["knowers"] = knowers
    var provenance: Array = entry.get("provenance", [])
    provenance.append({"from":"world","to":"player","day":day,"reason":source})
    entry["provenance"] = provenance
    facts[fact_id] = entry
    root["facts"] = facts
    _store(flags, root)

static func share_with(flags: Dictionary, fact_id: String, npc_id: String, day: int, source: String = "player") -> void:
    if fact_id == "" or npc_id == "":
        return
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    var entry: Dictionary = facts.get(fact_id, {"knowers":[],"public":false,"provenance":[]})
    var knowers: Array = entry.get("knowers", [])
    if npc_id not in knowers:
        knowers.append(npc_id)
    entry["knowers"] = knowers
    var provenance: Array = entry.get("provenance", [])
    provenance.append({"from":source,"to":npc_id,"day":day,"reason":"shared"})
    entry["provenance"] = provenance
    facts[fact_id] = entry
    root["facts"] = facts
    var propagation: Array = root["propagation"]
    propagation.append({"fact":fact_id,"from":source,"to":npc_id,"day":day})
    while propagation.size() > 80:
        propagation.pop_front()
    root["propagation"] = propagation
    _store(flags, root)

static func make_public(flags: Dictionary, fact_id: String, participants: Array, day: int, source: String = "player") -> void:
    if fact_id == "":
        return
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    var entry: Dictionary = facts.get(fact_id, {"knowers":[],"public":false,"provenance":[]})
    var knowers: Array = entry.get("knowers", [])
    if "player" not in knowers:
        knowers.append("player")
    for npc_id in participants:
        if str(npc_id) not in knowers:
            knowers.append(str(npc_id))
    entry["knowers"] = knowers
    entry["public"] = true
    var provenance: Array = entry.get("provenance", [])
    provenance.append({"from":source,"to":"public","day":day,"reason":"meeting"})
    entry["provenance"] = provenance
    facts[fact_id] = entry
    root["facts"] = facts
    _store(flags, root)

static func knows(flags: Dictionary, npc_id: String, fact_id: String) -> bool:
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    if not facts.has(fact_id):
        return false
    var entry: Dictionary = facts[fact_id]
    return bool(entry.get("public", false)) or npc_id in entry.get("knowers", [])

static func is_public(flags: Dictionary, fact_id: String) -> bool:
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    return bool(Dictionary(facts.get(fact_id, {})).get("public", false))

static func provenance(flags: Dictionary, fact_id: String) -> Array:
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    return Array(Dictionary(facts.get(fact_id, {})).get("provenance", [])).duplicate(true)

static func trace_text(flags: Dictionary, npc_id: String, fact_id: String) -> String:
    for step in provenance(flags, fact_id):
        if str(step.get("to","")) == npc_id:
            var source := str(step.get("from",""))
            if source == "player":
                return "%s knows %s because the player shared it on day %d" % [npc_id,fact_id,int(step.get("day",0))]
            return "%s knows %s from %s on day %d" % [npc_id,fact_id,source,int(step.get("day",0))]
        if str(step.get("to","")) == "public":
            return "%s knows %s because it became public on day %d" % [npc_id,fact_id,int(step.get("day",0))]
    return "%s has no recorded path to %s" % [npc_id,fact_id]


static func share_between(flags: Dictionary, fact_id: String, from_id: String, to_id: String, day: int, reason: String = "crew_share") -> bool:
    if fact_id == "" or from_id == "" or to_id == "" or from_id == to_id:
        return false
    if not knows(flags,from_id,fact_id):
        return false
    if knows(flags,to_id,fact_id):
        return false
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    var entry: Dictionary = facts.get(fact_id,{"knowers":[],"public":false,"provenance":[]})
    var knowers: Array = entry.get("knowers",[])
    if to_id not in knowers:
        knowers.append(to_id)
    entry["knowers"] = knowers
    var provenance_steps: Array = entry.get("provenance",[])
    provenance_steps.append({"from":from_id,"to":to_id,"day":day,"reason":reason})
    entry["provenance"] = provenance_steps
    facts[fact_id] = entry
    root["facts"] = facts
    var propagation: Array = root["propagation"]
    propagation.append({"fact":fact_id,"from":from_id,"to":to_id,"day":day,"reason":reason})
    while propagation.size() > 80:
        propagation.pop_front()
    root["propagation"] = propagation
    _store(flags,root)
    return true

static func known_facts(flags: Dictionary, npc_id: String) -> Array:
    var result: Array = []
    var root := _root(flags)
    for fact_id in Dictionary(root["facts"]).keys():
        if knows(flags,npc_id,str(fact_id)):
            result.append(str(fact_id))
    return result

static func knowers(flags: Dictionary, fact_id: String) -> Array:
    var root := _root(flags)
    var facts: Dictionary = root["facts"]
    var entry: Dictionary = facts.get(fact_id,{})
    return Array(entry.get("knowers",[])).duplicate()
