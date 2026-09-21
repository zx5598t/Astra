extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    simulate_500_loops()
    if failures.is_empty():
        print("ASTRA 0.5.4 AFTERMATH SIMULATION OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 AFTERMATH SIMULATION FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func _stage_two(chain_id: String) -> Dictionary:
    for scene in AstraStorylets054.scenes():
        if str(scene.get("chain_id","")) == chain_id and int(scene.get("stage",0)) == 2:
            return scene
    return {}

func simulate_500_loops() -> void:
    var roster := AstraCrewCatalog.ORDER.duplicate()
    var arc_hits := {}
    var deviation_reasons := {}
    var consequence_counts := {"IMMEDIATE":0,"DELAYED":0,"NEXT_DAY":0,"NEXT_LOOP":0}
    var visible_signatures := {}
    var consequence_signatures := {}
    var max_deviations := 0
    var summaries: Array[String] = []
    var player_visible_diff := 0

    for run in range(500):
        var seed_value := 1540000 + run * 71
        var loop_index := run % 9
        var chapter: String = str(["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"][run % 4])
        var arcs := AstraStorylets054.select_arcs(seed_value,loop_index,chapter,roster,[],3)
        var routine := AstraCrewRoutineModel.build(seed_value,loop_index,chapter,roster,roster,["rho"] if run % 7 == 0 else [])
        var deviations: Array[String] = []
        for npc_id in routine:
            var entry: Dictionary = routine[npc_id]
            if bool(entry.get("is_deviation",false)):
                var reason := str(entry.get("deviation_reason",""))
                deviations.append(str(npc_id) + ":" + reason)
                deviation_reasons[reason] = int(deviation_reasons.get(reason,0)) + 1
        max_deviations = maxi(max_deviations,deviations.size())

        var consequences: Array[String] = []
        for chain_raw in arcs:
            var chain_id := str(chain_raw)
            arc_hits[chain_id] = int(arc_hits.get(chain_id,0)) + 1
            var stage2 := _stage_two(chain_id)
            var choices: Array = stage2.get("choices",[])
            if choices.is_empty():
                continue
            var choice: Dictionary = choices[posmod(abs(hash("%d:%s" % [seed_value,chain_id])),choices.size())]
            for event in AstraConsequenceModel.from_choice(choice,AstraStorylets054.arc_actor(chain_id),str(stage2.get("id","")),4,loop_index,1):
                var timing := str(event.get("timing","DELAYED"))
                consequence_counts[timing] = int(consequence_counts.get(timing,0)) + 1
                consequences.append(chain_id + ":" + timing)

        var signature := "%s|%s|%s|%s" % [
            chapter,
            ",".join(PackedStringArray(arcs)),
            ",".join(PackedStringArray(deviations)),
            ",".join(PackedStringArray(consequences))
        ]
        visible_signatures[signature] = true
        consequence_signatures[",".join(PackedStringArray(consequences))] = true
        if not deviations.is_empty() or not consequences.is_empty():
            player_visible_diff += 1

        if run < 5:
            summaries.append("LOOP %d · chapter=%s · arcs=%s · routine_deviation=%s · consequences=%s" % [
                run+1,chapter,str(arcs),str(deviations),str(consequences)
            ])

    check(arc_hits.size() == 8,"500 loops reach all eight character micro-arcs (%d)" % arc_hits.size())
    check(deviation_reasons.size() >= 6,"routine simulation exposes several human-readable deviation reasons (%d)" % deviation_reasons.size())
    check(max_deviations <= 3,"player-visible important routine deviations never exceed three (%d)" % max_deviations)
    for timing in AstraConsequenceModel.TIMINGS:
        check(int(consequence_counts.get(timing,0)) > 0,"500 loops exercise " + str(timing) + " consequences")
    check(visible_signatures.size() >= 250,"routine/arc/consequence combinations produce visible replay variety (%d/500)" % visible_signatures.size())
    check(consequence_signatures.size() >= 20,"consequence combinations do not collapse to one formula (%d)" % consequence_signatures.size())
    check(player_visible_diff >= 450,"most simulated loops contain a visible human difference (%d/500)" % player_visible_diff)

    print("AFTERMATH 500 LOOPS · arcs=%s · deviation_reasons=%d · consequence=%s · signatures=%d · consequence_signatures=%d" % [
        str(arc_hits),deviation_reasons.size(),str(consequence_counts),visible_signatures.size(),consequence_signatures.size()
    ])
    print("FIVE LOOP HUMAN-READABLE AFTERMATH SAMPLE")
    for line in summaries:
        print("  " + line)
