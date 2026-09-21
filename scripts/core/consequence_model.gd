class_name AstraConsequenceModel
extends RefCounted

# Follow-ups are small authored consequences, not a reward/punishment meter.
const TIMINGS := ["IMMEDIATE","DELAYED","NEXT_DAY","NEXT_LOOP"]
const MAX_QUEUE := 12

static func from_choice(choice: Dictionary, who: String, source_scene: String, action_index: int, loop_index: int, day: int) -> Array:
    var result: Array = []
    for raw in Array(choice.get("consequences",[])):
        var event: Dictionary = Dictionary(raw).duplicate(true)
        var timing := str(event.get("timing","DELAYED"))
        if timing not in TIMINGS:
            timing = "DELAYED"
        event["timing"] = timing
        event["who"] = str(event.get("who",who))
        event["source_scene"] = source_scene
        event["created_action"] = action_index
        event["created_loop"] = loop_index
        event["created_day"] = day
        match timing:
            "IMMEDIATE":
                event["due_action"] = action_index
                event["expires_action"] = action_index + 1
            "DELAYED":
                var delay := maxi(1,int(event.get("delay",2)))
                event["due_action"] = action_index + delay
                event["expires_action"] = action_index + maxi(delay + 4,int(event.get("expires_after",delay + 4)))
            "NEXT_DAY":
                event["due_day"] = day + 1
                event["expires_day"] = day + maxi(1,int(event.get("expires_after_days",1)))
            "NEXT_LOOP":
                event["due_loop"] = loop_index + 1
                event["expires_loop"] = loop_index + maxi(1,int(event.get("expires_after_loops",2)))
        if str(event.get("id","")) == "":
            event["id"] = "%s:%s:%d" % [source_scene,timing,result.size()]
        result.append(event)
    return result

static func enqueue(queue: Array, events: Array) -> Array:
    var result := queue.duplicate(true)
    for event in events:
        var id := str(event.get("id",""))
        var duplicate := result.any(func(x): return str(x.get("id","")) == id)
        if not duplicate:
            result.append(Dictionary(event).duplicate(true))
    while result.size() > MAX_QUEUE:
        result.pop_front()
    return result

static func is_expired(event: Dictionary, action_index: int, loop_index: int, day: int) -> bool:
    match str(event.get("timing","")):
        "IMMEDIATE","DELAYED":
            return action_index > int(event.get("expires_action",999999))
        "NEXT_DAY":
            return day > int(event.get("expires_day",999999))
        "NEXT_LOOP":
            return loop_index > int(event.get("expires_loop",999999))
    return false

static func is_due(event: Dictionary, action_index: int, loop_index: int, day: int, timing_filter: String = "") -> bool:
    var timing := str(event.get("timing",""))
    if timing_filter != "" and timing != timing_filter:
        return false
    if is_expired(event,action_index,loop_index,day):
        return false
    match timing:
        "IMMEDIATE","DELAYED":
            return action_index >= int(event.get("due_action",999999))
        "NEXT_DAY":
            return day >= int(event.get("due_day",999999))
        "NEXT_LOOP":
            return loop_index >= int(event.get("due_loop",999999))
    return false

static func pop_due(queue: Array, action_index: int, loop_index: int, day: int, timing_filter: String = "") -> Dictionary:
    var kept: Array = []
    var selected: Dictionary = {}
    for raw in queue:
        var event: Dictionary = raw
        if is_expired(event,action_index,loop_index,day):
            continue
        if selected.is_empty() and is_due(event,action_index,loop_index,day,timing_filter):
            selected = event.duplicate(true)
            continue
        kept.append(event.duplicate(true))
    return {"event":selected,"queue":kept}

static func carry_for_next_loop(queue: Array, loop_index: int) -> Array:
    var result: Array = []
    for raw in queue:
        var event: Dictionary = raw
        if str(event.get("timing","")) == "NEXT_LOOP" and not is_expired(event,0,loop_index,1):
            result.append(event.duplicate(true))
    return result

static func timing_counts(scenes: Array) -> Dictionary:
    var result := {"IMMEDIATE":0,"DELAYED":0,"NEXT_DAY":0,"NEXT_LOOP":0}
    for scene in scenes:
        for choice in scene.get("choices",[]):
            for event in choice.get("consequences",[]):
                var timing := str(event.get("timing","DELAYED"))
                result[timing] = int(result.get(timing,0)) + 1
    return result
