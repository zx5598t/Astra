class_name AstraStoryletScheduler
extends RefCounted

# Small selection layer over authored content. It never creates dialogue.
# It only makes unseen/coherent scenes easier to reach and keeps rare scenes
# from being trapped behind bad RNG forever.
#
# 0.5.7 CLEAR SIGNAL keeps the selector player-safe: focus_context contains
# only things the player has actually seen or explicitly chosen. Hidden truth,
# Null assignment, raw relationship floats and motive assignments never enter
# this API.

const CONTINUATION_INTENTS := [
    "followup", "aftermath", "resolution", "callback", "player_callback",
    "player_memory", "foreknowledge", "micro_arc"
]

static func rare_threshold(scene: Dictionary, pity: Dictionary) -> float:
    var rarity := str(scene.get("rarity","common"))
    if rarity == "rare":
        return minf(0.85, 0.22 + float(pity.get(str(scene.get("id","")),0)) * 0.12)
    if rarity == "uncommon":
        return minf(0.9, 0.50 + float(pity.get(str(scene.get("id","")),0)) * 0.08)
    return 1.0

static func family_key(scene: Dictionary) -> String:
    return str(scene.get("family",scene.get("id","")))

static func salience(scene: Dictionary) -> String:
    var tag := str(scene.get("tag",""))
    var category := str(scene.get("category",""))
    var intent := str(scene.get("intent",tag))
    if bool(scene.get("mandatory",false)) or tag == "awakening" or category in ["MANDATORY","PROGRESSION"]:
        return "MANDATORY"
    if category in ["CONSEQUENCE","INCIDENT_AFTER"] or intent in ["followup","aftermath","resolution","callback","player_callback","foreknowledge"]:
        return "FOLLOWUP"
    if str(scene.get("chain_id","")) != "" or intent == "micro_arc" or category in ["INCIDENT","CANON","MOTIVE","RELATIONSHIP","CONFLICT"]:
        return "FOCUS"
    if tag in ["pair","trio","trust","conflict","suspected","danger","personal","echo","secret"]:
        return "FOCUS"
    if category == "AUTONOMOUS" or tag in ["everyday","work","observation","routine","autonomous","overheard"]:
        return "AMBIENT"
    return "OPTIONAL"

static func direct_pinned_match(scene: Dictionary, pinned_question: Dictionary) -> bool:
    if pinned_question.is_empty():
        return false
    var question_id := str(pinned_question.get("id",""))
    return question_id != "" and question_id in Array(scene.get("question_links",[]))

static func indirect_pinned_match(scene: Dictionary, pinned_question: Dictionary) -> bool:
    if pinned_question.is_empty():
        return false
    var related: Array = pinned_question.get("related",[])
    var speaker := str(scene.get("speaker",""))
    var target := str(scene.get("target",""))
    return speaker in related or target in related

static func is_continuation(scene: Dictionary, focus_context: Dictionary = {}) -> bool:
    if bool(scene.get("continuation",false)):
        return true
    var family := family_key(scene)
    var chain_id := str(scene.get("chain_id",""))
    var intent := str(scene.get("intent",scene.get("tag","")))
    var category := str(scene.get("category",""))
    var requires: Dictionary = scene.get("requires",{})
    var requires_scene := str(requires.get("scene",""))
    var followup_of := str(scene.get("followup_of",""))
    var source_scene := str(scene.get("source_scene",""))
    var source_event := str(scene.get("source_event",""))
    for raw in focus_context.get("loop_focus_events",[]):
        var event: Dictionary = raw
        var event_scene := str(event.get("scene",""))
        var event_family := str(event.get("family",""))
        var event_chain := str(event.get("chain_id",""))
        if chain_id != "" and event_chain != "" and chain_id == event_chain:
            return true
        if requires_scene != "" and requires_scene == event_scene:
            return true
        if followup_of != "" and followup_of == event_scene:
            return true
        if source_scene != "" and source_scene == event_scene:
            return true
        if source_event != "" and source_event in [event_scene,event_family]:
            return true
        if family != "" and family == event_family:
            if intent in CONTINUATION_INTENTS or category in ["CONSEQUENCE","INCIDENT_AFTER"]:
                return true
    return false

static func keep_fresh_candidate(scene: Dictionary, recent_ids: Array, recent_families: Array, focus_context: Dictionary = {}) -> bool:
    if is_continuation(scene,focus_context) or bool(focus_context.get("explicit_topic",false)):
        return true
    var id := str(scene.get("id",""))
    var family := family_key(scene)
    return id not in recent_ids.slice(-6) and family not in recent_families.slice(-5)

static func _focus_budget_multiplier(scene: Dictionary, pinned_question: Dictionary, focus_context: Dictionary) -> float:
    var level := salience(scene)
    if level not in ["FOCUS","FOLLOWUP","MANDATORY"]:
        return 1.0
    var continuation := is_continuation(scene,focus_context)
    var explicit_topic := bool(focus_context.get("explicit_topic",false))
    var direct_pin := direct_pinned_match(scene,pinned_question)
    if level in ["MANDATORY","FOLLOWUP"] or continuation or explicit_topic:
        return 1.0
    var family := family_key(scene)
    var current: Array = focus_context.get("loop_focus_families",[])
    if family in current:
        return 1.0
    var distinct := current.size()
    if distinct < 2:
        return 1.0
    if distinct == 2:
        return 0.90 if direct_pin else 0.72
    return 0.72 if direct_pin else 0.40

static func _speaker_multiplier(scene: Dictionary, pinned_question: Dictionary, focus_context: Dictionary) -> float:
    var who := str(scene.get("speaker",""))
    if who == "":
        return 1.0
    var continuation := is_continuation(scene,focus_context)
    var level := salience(scene)
    if bool(focus_context.get("explicit_topic",false)) or continuation or level in ["MANDATORY","FOLLOWUP"] or direct_pinned_match(scene,pinned_question):
        return 1.0
    var exposure: Dictionary = focus_context.get("speaker_exposure",{})
    var count := int(exposure.get(who,0))
    if count >= 3:
        return 0.62
    if count == 2:
        return 0.85
    return 1.0

static func weight(scene: Dictionary, seen_ever: Dictionary, recent_families: Array, social_theme: String, pinned_question: Dictionary = {}, focus_context: Dictionary = {}) -> float:
    var score := maxf(0.1,float(scene.get("_content_weight",1.0)))
    var id := str(scene.get("id",""))
    var family := family_key(scene)
    var continuation := is_continuation(scene,focus_context)
    if int(seen_ever.get(id,0)) == 0:
        score *= 1.35
    elif int(seen_ever.get(id,0)) >= 3:
        score *= 0.72
    if family in recent_families.slice(maxi(0,recent_families.size()-5)) and not continuation:
        score *= 0.22
    if continuation:
        score *= 1.22
    score *= _focus_budget_multiplier(scene,pinned_question,focus_context)
    score *= _speaker_multiplier(scene,pinned_question,focus_context)
    var target := str(scene.get("target",""))
    var theme_pair := AstraLivingCrew.theme_pair(social_theme)
    if theme_pair.size() >= 2 and target != "":
        var speaker := str(scene.get("speaker",""))
        if speaker in theme_pair and target in theme_pair:
            score *= 1.28
    if bool(scene.get("player_specific",false)):
        score *= 1.08
    # 0.5.4 follow-ups should not disappear under ordinary variety. This is
    # still a weight, never a forced quest.
    if str(scene.get("intent","")) == "micro_arc":
        score *= 1.22
    if str(scene.get("category","")) == "CONSEQUENCE":
        score *= 1.35
    if str(scene.get("routine_relevance","")) != "":
        score *= 1.10
    if direct_pinned_match(scene,pinned_question):
        score *= 1.22
    elif indirect_pinned_match(scene,pinned_question):
        score *= 1.12
    return maxf(0.01,score)

static func pick(candidates: Array, seen_ever: Dictionary, recent_families: Array, social_theme: String, roll: float, pinned_question: Dictionary = {}, focus_context: Dictionary = {}) -> Dictionary:
    if candidates.is_empty():
        return {}
    var weights: Array[float] = []
    var total := 0.0
    for scene in candidates:
        var w := weight(scene,seen_ever,recent_families,social_theme,pinned_question,focus_context)
        weights.append(w)
        total += w
    var cursor := clampf(roll,0.0,0.999999) * total
    for i in range(candidates.size()):
        cursor -= weights[i]
        if cursor <= 0.0:
            return Dictionary(candidates[i]).duplicate(true)
    return Dictionary(candidates.back()).duplicate(true)

static func update_pity(pity: Dictionary, candidates: Array, selected_id: String) -> Dictionary:
    var result := pity.duplicate(true)
    for scene in candidates:
        var id := str(scene.get("id",""))
        if id == "":
            continue
        if id == selected_id:
            result[id] = 0
        elif str(scene.get("rarity","common")) in ["rare","uncommon"]:
            result[id] = mini(6,int(result.get(id,0)) + 1)
    return result

static func visible_signature(theme: String, hook: Dictionary, scene_ids: Array, rare_ids: Array, first_private: String = "") -> String:
    return "%s|%s|%s|%s|%s" % [
        theme,
        str(hook.get("id","")),
        ",".join(PackedStringArray(scene_ids.map(func(x): return str(x)))),
        ",".join(PackedStringArray(rare_ids.map(func(x): return str(x)))),
        first_private
    ]
