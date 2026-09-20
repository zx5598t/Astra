class_name AstraStoryletScheduler
extends RefCounted

# Small selection layer over authored content. It never creates dialogue.
# It only makes unseen/coherent scenes easier to reach and keeps rare scenes
# from being trapped behind bad RNG forever.

static func rare_threshold(scene: Dictionary, pity: Dictionary) -> float:
    var rarity := str(scene.get("rarity","common"))
    if rarity == "rare":
        return minf(0.85, 0.22 + float(pity.get(str(scene.get("id","")),0)) * 0.12)
    if rarity == "uncommon":
        return minf(0.9, 0.50 + float(pity.get(str(scene.get("id","")),0)) * 0.08)
    return 1.0

static func weight(scene: Dictionary, seen_ever: Dictionary, recent_families: Array, social_theme: String, pinned_question: Dictionary = {}) -> float:
    var score := maxf(0.1,float(scene.get("_content_weight",1.0)))
    var id := str(scene.get("id",""))
    var family := str(scene.get("family",id))
    if int(seen_ever.get(id,0)) == 0:
        score *= 1.35
    elif int(seen_ever.get(id,0)) >= 3:
        score *= 0.72
    if family in recent_families.slice(maxi(0,recent_families.size()-5)):
        score *= 0.22
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
    if not pinned_question.is_empty():
        var links: Array = scene.get("question_links",[])
        var question_id := str(pinned_question.get("id",""))
        var related: Array = pinned_question.get("related",[])
        if question_id in links:
            score *= 1.22
        else:
            var speaker := str(scene.get("speaker",""))
            var target := str(scene.get("target",""))
            if speaker in related or target in related:
                score *= 1.12
    return maxf(0.01,score)

static func pick(candidates: Array, seen_ever: Dictionary, recent_families: Array, social_theme: String, roll: float, pinned_question: Dictionary = {}) -> Dictionary:
    if candidates.is_empty():
        return {}
    var weights: Array[float] = []
    var total := 0.0
    for scene in candidates:
        var w := weight(scene,seen_ever,recent_families,social_theme,pinned_question)
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
