extends SceneTree
# ASTRA 0.6.1 HUMAN TRACE: canonical facts stay fixed while handling choices,
# one human reaction, provenance, callbacks and repeat compression vary safely.

var checks := 0
var failures: Array[String] = []
const IDS := ["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func close_scene(s: AstraGameSession, choice_index: int = 0) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 50:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage["line"]) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            check(s.voyage_choose(mini(choice_index,scene.get("choices",[]).size()-1)),"choice applies")
        else:
            s.voyage_next()
    check(guard < 50,"mandatory scene chain terminates")

func reach_resolution(s: AstraGameSession) -> Dictionary:
    close_scene(s)
    var fact := str(AstraVoyageContent.chapter(s.case_id).get("fact",""))
    for room_id in s.voyage_rooms():
        if str(s.voyage.get("room","")) != str(room_id):
            s.voyage_move(str(room_id),false)
            close_scene(s)
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
                    var lines: Array = scene.get("lines",[])
                    var choices: Array = scene.get("choices",[])
                    if int(s.voyage.get("line",-1)) >= lines.size()-1 and not choices.is_empty():
                        if not s.voyage_choose(0):
                            break
                    else:
                        s.voyage_next()
                return s.voyage.get("scene",{})
    return {}

func _initialize() -> void:
    test_authored_choices()
    test_choice_progression()
    test_callback_and_compression()
    test_calibration_untouched()
    test_canon_guards()
    if failures.is_empty():
        print("ASTRA 0.6.1 HUMAN TRACE TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA 0.6.1 HUMAN TRACE TESTS FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

func test_authored_choices() -> void:
    var label_sets: Dictionary = {}
    for case_id in IDS:
        var beat := AstraVoyageContent.resolution_thread(case_id)
        var choices: Array = beat.get("choices",[])
        check(choices.size() >= 2 and choices.size() <= 3,"%s: 2-3 authored handling choices" % case_id)
        var labels: Array[String] = []
        for choice in choices:
            labels.append(str(choice.get("label","")))
            check(str(choice.get("effect","")) in ["record","share","withhold","keep_copy","confront"],
                "%s: reuses voyage choice effects" % case_id)
            check(str(choice.get("memory_tag","")) != "","%s: choice leaves a memory tag" % case_id)
        label_sets["|".join(labels)] = true
    check(label_sets.size() == IDS.size(),"chapters do not copy one generic choice set")

func test_choice_progression() -> void:
    for case_index in range(IDS.size()):
        var case_id: String = IDS[case_index]
        var canonical := str(AstraVoyageContent.chapter(case_id).get("resolved",""))
        var authored := AstraVoyageContent.resolution_thread(case_id)
        # One end-to-end discovery path per chapter proves the mandatory local
        # answer is reachable. Individual handling branches are then exercised
        # from that exact authored resolution so random ambient beats cannot
        # make a branch test depend on its seed.
        var path := AstraGameSession.new()
        path.setup(case_id,61000 + case_index)
        path.begin_voyage()
        var reached := reach_resolution(path)
        check(bool(reached.get("story_resolution",false)),"%s: discovery reaches mandatory resolution" % case_id)
        for choice_index in range(authored.get("choices",[]).size()):
            var s := AstraGameSession.new()
            s.setup(case_id,62000 + case_index * 10 + choice_index)
            s.begin_voyage()
            close_scene(s)
            var fact := str(AstraVoyageContent.chapter(case_id).get("fact",""))
            s._voyage_fact(fact,str(AstraVoyageContent.chapter(case_id).get("discovery","")),"DIRECT")
            # Simulate an optional fact being seen immediately before the
            # mandatory resolution. Resolution ownership must still stay on
            # the chapter's canonical fact, never this incidental last_fact.
            s._voyage_fact("optional_decoy","priority/provenance regression probe","RUMOR")
            s._voyage_scene(authored)
            var scene: Dictionary = s.voyage.get("scene",{})
            while int(s.voyage.get("line",-1)) < scene.get("lines",[]).size()-1:
                s.voyage_next()
                scene = s.voyage.get("scene",{})
            var priority_probe := case_id == "DEAD_AIR" and choice_index == 0
            if priority_probe:
                var action_index := int(s.voyage.get("actions",0))
                s.voyage["consequence_queue"] = AstraConsequenceModel.enqueue(
                    s.voyage.get("consequence_queue",[]),[{
                        "id":"human_trace_priority_probe","timing":"IMMEDIATE",
                        "due_action":action_index,"expires_action":action_index + 1,
                        "note":"mandatory chain priority probe","source_scene":"human_trace_test"
                    }]
                )
            check(s.voyage_choose(choice_index),"%s/%d: resolution choice accepted" % [case_id,choice_index])
            check(bool(s.voyage.get("story_resolution_seen",false)),"%s/%d: resolution marked seen" % [case_id,choice_index])
            check(str(s.story_recap().get("resolved","")) == canonical,"%s/%d: canonical resolved fact unchanged" % [case_id,choice_index])
            var after_choice: Dictionary = s.voyage.get("scene",{})
            check(bool(after_choice.get("story_reaction",false)) or bool(after_choice.get("story_hook",false)),
                "%s/%d: choice advances to at most one reaction or hook" % [case_id,choice_index])
            if bool(after_choice.get("story_reaction",false)):
                check(Array(after_choice.get("choices",[])).is_empty(),"%s/%d: reaction has no second decision" % [case_id,choice_index])
            var ownership: Dictionary = s.voyage.get("evidence_ownership",{}).get(fact,{})
            var effect := str(authored.get("choices",[])[choice_index].get("effect",""))
            var source_value = s.voyage.get("information_sources",{}).get(fact,"")
            check(typeof(source_value) == TYPE_STRING and str(source_value) == "DIRECT",
                "%s/%d: resolution handling preserves information source schema" % [case_id,choice_index])
            if effect in ["share","record"]:
                check(not AstraKnowledgeModel.knows(s.flags,str(authored.get("speaker","")),"optional_decoy"),
                    "%s/%d: incidental last_fact is never shared by resolution handling" % [case_id,choice_index])
            if effect == "share" and str(authored.get("choices",[])[choice_index].get("share_scope","public")) != "speaker":
                check(bool(ownership.get("public",false)),"%s/%d: public share updates evidence ownership" % [case_id,choice_index])
            elif effect == "share":
                var resolution_speaker := str(authored.get("speaker",""))
                check(not bool(ownership.get("public",false)),"%s/%d: speaker share does not become public" % [case_id,choice_index])
                check(AstraKnowledgeModel.knows(s.flags,resolution_speaker,fact),
                    "%s/%d: speaker share reaches the intended speaker" % [case_id,choice_index])
            elif effect == "keep_copy":
                check(bool(ownership.get("player_copy",false)),"%s/%d: keep-copy updates evidence ownership" % [case_id,choice_index])
            elif effect == "withhold":
                check(not bool(ownership.get("public",false)),"%s/%d: withhold keeps evidence non-public" % [case_id,choice_index])
            if priority_probe:
                check(Array(s.voyage.get("consequence_queue",[])).any(
                    func(event): return str(event.get("id","")) == "human_trace_priority_probe"
                ),"mandatory reaction/hook keeps an immediate consequence queued")
            close_scene(s)
            if priority_probe:
                check(Array(s.voyage.get("consequence_history",[])).any(
                    func(event): return str(event.get("id","")) == "human_trace_priority_probe"
                ),"deferred immediate consequence survives and applies after the story hook")
            check(bool(s.voyage.get("story_hook_seen",false)),"%s/%d: reaction path reaches story hook" % [case_id,choice_index])
            check(s.voyage_can_finish(),"%s/%d: no EXPLORE soft-lock" % [case_id,choice_index])
            check(str(s.story_recap().get("open_question","")) == str(AstraVoyageContent.chapter(case_id).get("open_question","")),
                "%s/%d: open question survives" % [case_id,choice_index])
            check(str(s.story_recap().get("next_hook","")) == str(AstraVoyageContent.chapter(case_id).get("next_hook","")),
                "%s/%d: next hook survives" % [case_id,choice_index])

func test_callback_and_compression() -> void:
    var first := AstraGameSession.new()
    first.setup("DEAD_AIR",61111)
    first.begin_voyage()
    var scene := reach_resolution(first)
    while int(first.voyage.get("line",-1)) < scene.get("lines",[]).size()-1:
        first.voyage_next()
        scene = first.voyage.get("scene",{})
    check(first.voyage_choose(0),"first DEAD_AIR handling choice accepted")
    close_scene(first)
    var memory := first.voyage_memory()

    var second := AstraGameSession.new()
    second.setup("DEAD_AIR",61112)
    second.begin_voyage(memory)
    var repeated := reach_resolution(second)
    check(bool(repeated.get("compressed",false)),"seen unchanged resolution is safely compressed")
    check(repeated.has("_full_action") and repeated.has("_full_lines"),"compressed resolution retains full-scene expansion payload")
    check(not Array(repeated.get("choices",[])).is_empty(),"compression never hides current handling choices")

    var callback_tags := ["noa:dead_air_public_dual_destination"]
    var callback := AstraVoyageContent.resolution_thread("DEAD_AIR",callback_tags)
    check(bool(callback.get("human_trace_callback",false)),"prior visible choice can author a next-loop callback")
    check(not str(callback.get("action","")).contains("Null"),"callback does not expose hidden Null identity")

func test_calibration_untouched() -> void:
    var s := AstraGameSession.new()
    s.setup("CALIBRATION",61200)
    s.begin_voyage()
    check(AstraVoyageContent.resolution_thread("CALIBRATION").is_empty(),"CALIBRATION gets no new resolution choice layer")
    check(str(s.voyage.get("scene",{}).get("id","")) == "first_wake","CALIBRATION opening remains FIRST CONTACT")

func test_canon_guards() -> void:
    check(AstraMetaProgress.SAVE_VERSION == 11,"save schema remains current v11")
    for case_id in IDS:
        var beat := AstraVoyageContent.resolution_thread(case_id)
        var serialized := JSON.stringify(beat)
        check(not serialized.contains("Player = Null") and not serialized.contains("Player == Null"),
            "%s: Player != Null guard not contradicted" % case_id)
    var last := AstraVoyageContent.chapter("LAST_LIGHT")
    check(str(last.get("resolved","")).contains("서로 다른 기록 사본"),"LAST_LIGHT keeps multiple valid histories")
    check(str(last.get("resolved","")).contains("Null 사건만으로는"),"LAST_LIGHT keeps Null-not-total-cause canon")
