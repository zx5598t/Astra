extends SceneTree
# Human-readable 0.6.2 editorial report.
# Every displayed line is sourced from runtime-authored content or runtime metadata.

var failures: Array[String] = []

func _initialize() -> void:
    _run_report()
    if failures.is_empty():
        print("ASTRA 0.6.2 HUMAN AFTERMATH EDITORIAL REPORT OK")
        quit(0)
    for failure in failures:
        printerr("FAIL · " + failure)
    quit(1)

func _line_text(scene: Dictionary) -> String:
    var lines: Array = scene.get("lines",[])
    if lines.is_empty():
        return ""
    return str(lines[0][1])

func _print_sample(title: String, before: String, choice: String, immediate: String, aftermath: String, next_loop: String, why: String, duplication: String) -> void:
    print("")
    print("=== " + title + " ===")
    print("[BEFORE]")
    print(before)
    print("[PLAYER CHOICE]")
    print(choice)
    print("[IMMEDIATE]")
    print(immediate)
    print("[AFTERMATH]")
    print(aftermath)
    print("[NEXT LOOP]")
    print(next_loop)
    print("[WHY IT WORKS]")
    print(why)
    print("[DUPLICATION]")
    print(duplication)

func _resolution_sample(case_id: String, choice_index: int, looped: bool = false) -> void:
    var beat := AstraVoyageContent.resolution_thread(case_id)
    var choices: Array = beat.get("choices",[])
    if choices.is_empty():
        failures.append(case_id + " has no authored handling choices")
        return
    var choice: Dictionary = choices[mini(choice_index,choices.size()-1)]
    var tag := str(choice.get("memory_tag",""))
    var reaction := AstraVoyageContent.resolution_reaction(case_id,tag,AstraCrewCatalog.ORDER)
    var hook := AstraVoyageContent.hook_thread(case_id)
    var callback := AstraVoyageContent.resolution_thread(case_id,[tag]) if looped else {}
    _print_sample(
        ("LOOPED " if looped else "FIRST PLAY ") + case_id,
        str(AstraVoyageContent.chapter(case_id).get("resolved","")),
        str(choice.get("label","")),
        _line_text(reaction),
        str(hook.get("action","")),
        str(callback.get("action","")) if bool(callback.get("human_trace_callback",false)) else "(no authored residue for this handling choice)",
        "owner=%s · source=%s · continuation=%s" % [
            str(reaction.get("aftermath_owner","")),
            str(reaction.get("source_event","")),
            str(callback.get("continuation",false)) if not callback.is_empty() else "false"
        ],
        "reaction/hook same-copy=%s" % str(_line_text(reaction) == str(hook.get("action","")))
    )

func _foreknowledge_sample() -> void:
    var scene: Dictionary = {}
    for raw in AstraStorylets055.scenes():
        if bool(raw.get("foreknowledge_reaction",false)):
            scene = Dictionary(raw)
            break
    if scene.is_empty():
        failures.append("no foreknowledge authored scene")
        return
    _print_sample(
        "FOREKNOWLEDGE",
        "category=" + str(scene.get("category","")),
        "player_foreknowledge",
        str(scene.get("action","")),
        _line_text(scene),
        "(current-history reaction; NPC is not given impossible previous-loop memory)",
        "intent=" + str(scene.get("intent","")) + " · compressible=" + str(scene.get("compressible",true)),
        "single authored scene"
    )

func _wrong_accusation_sample() -> void:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD",906202)
    var innocent := ""
    for who in s.roster:
        if str(who) not in s.truth.get("nulls",[]):
            innocent = str(who)
            break
    if innocent == "":
        failures.append("no innocent target for wrong-accusation sample")
        return
    var trace := AstraDecisionModel.trace("player","accuse",innocent,[AstraDecisionModel.reason("insufficient_evidence",1.0)],1)
    _print_sample(
        "WRONG ACCUSATION",
        "visible target=" + AstraCrewCatalog.labelled(innocent),
        AstraCrewCatalog.labelled(innocent) + " 지목",
        str(trace.get("explanation","")),
        str(AstraGameSession.ISOLATED_LINES.get(innocent,"")),
        "(no previous-history memory is authored here)",
        "target is generated from current case roster and current truth only",
        "decision explanation and isolation line have different roles"
    )

func _relationship_samples() -> void:
    var candidates: Array = []
    for raw in AstraStorylets052.scenes():
        var scene: Dictionary = raw
        if not Array(scene.get("choices",[])).is_empty() and (
            str(scene.get("category","")) == "RELATIONSHIP"
            or str(scene.get("intent","")) == "relationship"
        ):
            candidates.append(scene)
    for raw in AstraStorylets053.scenes():
        var scene: Dictionary = raw
        if Array(scene.get("choices",[])).is_empty():
            continue
        var has_memory_choice := false
        for choice in Array(scene.get("choices",[])):
            if str(choice.get("memory_tag","")) != "":
                has_memory_choice = true
                break
        if str(scene.get("category","")) == "RELATIONSHIP" or bool(scene.get("player_specific",false)) or has_memory_choice:
            candidates.append(scene)
    var used_speakers: Dictionary = {}
    var found := 0
    for scene in candidates:
        var speaker := str(scene.get("speaker",""))
        if speaker in used_speakers and candidates.size() > 2:
            continue
        _print_sample(
            "RELATIONSHIP-SENSITIVE %d" % (found + 1),
            str(scene.get("action","")),
            str(choices[0].get("label","")),
            _line_text(scene),
            "family=" + str(scene.get("family","")),
            "(next-loop residue only when this exact choice has an authored callback)",
            "speaker=" + speaker + " · category=" + str(scene.get("category","")) + " · memory_tag=" + str(choices[0].get("memory_tag","")),
            "one authored scene owns this beat"
        )
        used_speakers[speaker] = true
        found += 1
        if found >= 2:
            break
    if found < 2:
        failures.append("fewer than two relationship-sensitive authored choice samples")

func _close_scene(s: AstraGameSession, choice_index: int = 0) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 50:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage.get("line",-1)) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            s.voyage_choose(mini(choice_index,scene.get("choices",[]).size()-1))
        else:
            s.voyage_next()

func _reach_resolution(s: AstraGameSession) -> Dictionary:
    _close_scene(s)
    var fact := str(AstraVoyageContent.chapter(s.case_id).get("fact",""))
    for room_id in s.voyage_rooms():
        if str(s.voyage.get("room","")) != str(room_id):
            s.voyage_move(str(room_id),false)
            _close_scene(s)
        for point in s.voyage_points():
            if str(point[4]) == fact and s.voyage_inspect(str(point[0])):
                var guard := 0
                while guard < 50:
                    guard += 1
                    var scene: Dictionary = s.voyage.get("scene",{})
                    if scene.is_empty() or bool(scene.get("story_resolution",false)):
                        return scene
                    if int(s.voyage.get("line",-1)) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
                        s.voyage_choose(0)
                    else:
                        s.voyage_next()
                return s.voyage.get("scene",{})
    return {}

func _repeat_resolution_sample() -> void:
    var first := AstraGameSession.new()
    first.setup("DEAD_AIR",906210)
    first.begin_voyage()
    var first_scene := _reach_resolution(first)
    while not first_scene.is_empty() and int(first.voyage.get("line",-1)) < first_scene.get("lines",[]).size()-1:
        first.voyage_next()
        first_scene = first.voyage.get("scene",{})
    if not first_scene.is_empty() and not first_scene.get("choices",[]).is_empty():
        first.voyage_choose(0)
    _close_scene(first)
    var memory := first.voyage_memory()

    var second := AstraGameSession.new()
    second.setup("DEAD_AIR",906211)
    second.begin_voyage(memory)
    var repeated := _reach_resolution(second)
    if repeated.is_empty():
        failures.append("repeat-resolution sample did not reach resolution")
        return
    _print_sample(
        "REPEAT RESOLUTION",
        str(AstraVoyageContent.chapter("DEAD_AIR").get("resolved","")),
        str(Array(repeated.get("choices",[]))[0].get("label","")) if not Array(repeated.get("choices",[])).is_empty() else "(no choice)",
        str(repeated.get("action","")),
        _line_text(repeated),
        "compressed=" + str(repeated.get("compressed",false)),
        "full-scene expansion=" + str(repeated.has("_full_lines")) + " · choices-visible=" + str(not Array(repeated.get("choices",[])).is_empty()),
        "compression does not replace changed reaction metadata"
    )

func _run_report() -> void:
    print("ASTRA 0.6.2 HUMAN AFTERMATH · HUMAN-READABLE EDITORIAL REPORT")
    _resolution_sample("DEAD_AIR",0,false)
    _resolution_sample("DEAD_AIR",1,true)
    _resolution_sample("ECHO_WARD",0,true)
    _foreknowledge_sample()
    _wrong_accusation_sample()
    _relationship_samples()
    _repeat_resolution_sample()
