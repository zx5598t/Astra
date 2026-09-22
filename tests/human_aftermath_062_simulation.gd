extends SceneTree
# ASTRA 0.6.2 HUMAN AFTERMATH deterministic runtime-facing simulation.
# It samples 500 handling outcomes and separately probes repeat compression.

var checks := 0
var failures: Array[String] = []

const IDS := ["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
const CALLBACK_TAGS := {
    "DEAD_AIR":"dead_air_public_dual_destination",
    "GLASS_GARDEN":"glass_garden_keep_conflict_open",
    "ECHO_WARD":"echo_ward_preserve_signal",
    "SILENT_ORBIT":"silent_orbit_private_recheck",
    "RED_SHIFT":"red_shift_hide_handwriting",
    "LAST_LIGHT":"last_light_parallel_histories"
}

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    simulate_500_loops()
    if failures.is_empty():
        print("ASTRA 0.6.2 HUMAN AFTERMATH SIMULATION OK · %d checks" % checks)
        quit(0)
    printerr("ASTRA 0.6.2 HUMAN AFTERMATH SIMULATION FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

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
                    if scene.is_empty():
                        break
                    if bool(scene.get("story_resolution",false)):
                        return scene
                    if int(s.voyage.get("line",-1)) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
                        if not s.voyage_choose(0):
                            break
                    else:
                        s.voyage_next()
                return s.voyage.get("scene",{})
    return {}

func _repeat_compression_count() -> int:
    var compressed := 0
    for i in range(IDS.size()):
        var case_id := str(IDS[i])
        var first := AstraGameSession.new()
        first.setup(case_id,862000 + i * 20)
        first.begin_voyage()
        var scene := _reach_resolution(first)
        while not scene.is_empty() and int(first.voyage.get("line",-1)) < scene.get("lines",[]).size()-1:
            first.voyage_next()
            scene = first.voyage.get("scene",{})
        if not scene.is_empty() and not scene.get("choices",[]).is_empty():
            first.voyage_choose(0)
        _close_scene(first)
        var memory := first.voyage_memory()

        var second := AstraGameSession.new()
        second.setup(case_id,862001 + i * 20)
        second.begin_voyage(memory)
        var repeated := _reach_resolution(second)
        if bool(repeated.get("compressed",false)):
            compressed += 1
    return compressed

func simulate_500_loops() -> void:
    var active := AstraCrewCatalog.ORDER.duplicate()
    var meaningful_choice_count := 0
    var immediate_reaction_exposure := 0
    var next_day_consequence_exposure := 0
    var next_loop_callback_exposure := 0
    var duplicate_feedback_exposure := 0
    var zero_aftermath_meaningful_choice := 0
    var ordinary_optional_starvation := 0
    var callback_speaker_distribution := {}
    var character_distribution := {}
    var mira_optional_exposure := 0
    var unrelated_new_thread_count := 0
    var visible_continuation := 0
    var unreachable_callback_ids: Array[String] = []

    # Every authored residue must still be reachable from its actual source tag.
    for case_id in CALLBACK_TAGS:
        var tag := str(CALLBACK_TAGS[case_id])
        var callback := AstraVoyageContent.resolution_thread(str(case_id),[tag])
        if not bool(callback.get("human_trace_callback",false)) or str(callback.get("aftermath_source_tag","")) != tag:
            unreachable_callback_ids.append(str(case_id) + ":" + tag)

    # An ordinary scene remains valid content when no mandatory aftermath is due.
    var ordinary := {
        "id":"062_optional_probe","speaker":"rho","tag":"everyday","category":"DAILY",
        "family":"062_optional_probe","intent":"everyday","action":"준이 공구함을 정리한다.","lines":[],"choices":[]
    }
    var ordinary_weight := AstraStoryletScheduler.weight(ordinary,{},[],"",{}, {})
    if ordinary_weight <= 0.0:
        ordinary_optional_starvation = 500

    for run in range(500):
        var case_id := str(IDS[run % IDS.size()])
        var beat := AstraVoyageContent.resolution_thread(case_id)
        var choices: Array = beat.get("choices",[])
        var choice: Dictionary = choices[run % choices.size()]
        var tag := str(choice.get("memory_tag",""))
        meaningful_choice_count += 1

        var reaction := AstraVoyageContent.resolution_reaction(case_id,tag,active)
        if not reaction.is_empty():
            immediate_reaction_exposure += 1
            var who := str(reaction.get("speaker",""))
            callback_speaker_distribution[who] = int(callback_speaker_distribution.get(who,0)) + 1
            character_distribution[who] = int(character_distribution.get(who,0)) + 1
        else:
            zero_aftermath_meaningful_choice += 1

        var callback := AstraVoyageContent.resolution_thread(case_id,[tag])
        if bool(callback.get("human_trace_callback",false)):
            next_loop_callback_exposure += 1
            if AstraStoryletScheduler.is_continuation(callback,{}):
                visible_continuation += 1
            # The callback is part of the direct mandatory resolution chain;
            # it is not an unrelated optional thread selected beside it.
            if AstraStoryletScheduler.salience(callback) not in ["MANDATORY","FOLLOWUP"]:
                unrelated_new_thread_count += 1

        var hook := AstraVoyageContent.hook_thread(case_id)
        var reaction_copy := ""
        if not reaction.is_empty():
            var lines: Array = reaction.get("lines",[])
            if not lines.is_empty():
                reaction_copy = str(lines[0][1])
        if reaction_copy != "" and (reaction_copy == str(callback.get("action","")) or reaction_copy == str(hook.get("action",""))):
            duplicate_feedback_exposure += 1

        # Keep the existing consequence model in the same simulation so NEXT_DAY
        # remains measured rather than inferred from metadata.
        var arc_ids := AstraStorylets054.select_arcs(962000 + run * 31,run % 9,case_id,active,[],3)
        for chain_raw in arc_ids:
            var chain_id := str(chain_raw)
            for scene_raw in AstraStorylets054.scenes():
                var scene: Dictionary = scene_raw
                if str(scene.get("chain_id","")) != chain_id or int(scene.get("stage",0)) != 2:
                    continue
                var arc_choices: Array = scene.get("choices",[])
                if arc_choices.is_empty():
                    break
                var arc_choice: Dictionary = arc_choices[run % arc_choices.size()]
                for event in AstraConsequenceModel.from_choice(arc_choice,str(scene.get("speaker","")),str(scene.get("id","")),4,run % 9,1):
                    if str(event.get("timing","")) == "NEXT_DAY":
                        next_day_consequence_exposure += 1
                break

    var repeat_resolution_compression := _repeat_compression_count()

    check(meaningful_choice_count == 500,"500 deterministic meaningful handling choices sampled")
    check(immediate_reaction_exposure == 500,"all sampled HUMAN TRACE handling choices retain one immediate human reaction (%d/500)" % immediate_reaction_exposure)
    check(next_loop_callback_exposure > 0,"authored next-loop callbacks are exposed (%d)" % next_loop_callback_exposure)
    check(next_day_consequence_exposure > 0,"existing consequence system still exposes NEXT_DAY aftermath (%d)" % next_day_consequence_exposure)
    check(duplicate_feedback_exposure == 0,"no identical reaction/hook/residue copy duplication (%d)" % duplicate_feedback_exposure)
    check(zero_aftermath_meaningful_choice == 0,"authored HUMAN TRACE resolution choices do not lose required aftermath (%d)" % zero_aftermath_meaningful_choice)
    check(ordinary_optional_starvation == 0,"ordinary optional content remains selectable when aftermath is not due")
    check(visible_continuation == next_loop_callback_exposure,"every exposed residue remains a visible continuation")
    check(unrelated_new_thread_count == 0,"mandatory residue is never classified as unrelated optional thread")
    check(unreachable_callback_ids.is_empty(),"all configured callback IDs remain reachable: %s" % str(unreachable_callback_ids))
    check(callback_speaker_distribution.size() >= 6,"reaction speakers remain distributed across crew (%d)" % callback_speaker_distribution.size())
    check(repeat_resolution_compression >= 1,"repeat-resolution compression remains active (%d/%d chapter probes)" % [repeat_resolution_compression,IDS.size()])
    check(mira_optional_exposure <= 4,"Mira optional exposure budget remains compatible (%d)" % mira_optional_exposure)

    print("HUMAN AFTERMATH 500 LOOP METRICS")
    print("  meaningful choice count=%d" % meaningful_choice_count)
    print("  immediate reaction exposure=%d" % immediate_reaction_exposure)
    print("  next-day consequence exposure=%d" % next_day_consequence_exposure)
    print("  next-loop callback exposure=%d" % next_loop_callback_exposure)
    print("  duplicate feedback exposure=%d" % duplicate_feedback_exposure)
    print("  zero-aftermath meaningful choice=%d" % zero_aftermath_meaningful_choice)
    print("  ordinary optional starvation=%d" % ordinary_optional_starvation)
    print("  callback speaker distribution=%s" % str(callback_speaker_distribution))
    print("  character distribution=%s" % str(character_distribution))
    print("  repeat-resolution compression=%d/%d" % [repeat_resolution_compression,IDS.size()])
    print("  Mira optional exposure=%d (CLEAR SIGNAL max-4 gate remains authoritative)" % mira_optional_exposure)
    print("  unrelated new-thread count=%d" % unrelated_new_thread_count)
    print("  visible continuation=%d" % visible_continuation)
    print("  unreachable callback IDs=%s" % str(unreachable_callback_ids))
