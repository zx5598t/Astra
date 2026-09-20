extends SceneTree

func _args_loops() -> int:
    var count := 20
    for arg in OS.get_cmdline_user_args():
        if str(arg).begins_with("--loops="):
            count = clampi(int(str(arg).trim_prefix("--loops=")),1,50)
    return count

func _hidden_scene_text(scene: Dictionary) -> String:
    var text := str(scene.get("action",""))
    for line in scene.get("lines",[]):
        if line is Array and line.size() > 1 and str(line[1]) != "":
            text += " / " + str(line[1])
    return text.replace(AstraCrewCatalog.name(str(scene.get("speaker",""))),"[화자]")

func _initialize() -> void:
    var by_speaker := {}
    for npc_id in AstraCrewCatalog.ORDER:
        by_speaker[npc_id] = []
    for scene in AstraVoyageContent.all_scenes():
        var who := str(scene.get("speaker",""))
        if by_speaker.has(who):
            by_speaker[who].append(scene)

    print("=== ASTRA 0.5.4 HUMAN EDITING REPORT ===")
    for npc_id in AstraCrewCatalog.ORDER:
        var pool: Array = by_speaker[npc_id]
        pool.sort_custom(func(a,b): return abs(hash(str(a.get("id","")))) < abs(hash(str(b.get("id","")))))
        var sampled := pool.slice(0,mini(30,pool.size()))
        print("\nSPEAKER HIDDEN SAMPLE · %s · %d/30" % [npc_id,sampled.size()])
        for scene in sampled:
            print("  %s · %s" % [str(scene.get("id","")),_hidden_scene_text(scene)])

    var multi: Array = []
    var long_scenes := 0
    var generic_starts := 0
    var generic := ["기억은","우리는","이 배는","진실은","과거가"]
    for scene in AstraVoyageContent.all_scenes():
        if Array(scene.get("lines",[])).size() >= 2:
            multi.append(scene)
        var content := _hidden_scene_text(scene)
        if content.length() > 420:
            long_scenes += 1
        for phrase in generic:
            if content.strip_edges().begins_with(phrase):
                generic_starts += 1
    multi.sort_custom(func(a,b): return abs(hash("multi:"+str(a.get("id","")))) < abs(hash("multi:"+str(b.get("id","")))))
    print("\nMULTI-LINE EDITORIAL SAMPLE · %d/%d" % [mini(100,multi.size()),multi.size()])
    for scene in multi.slice(0,mini(100,multi.size())):
        print("  %s · lines=%d · %s" % [str(scene.get("id","")),Array(scene.get("lines",[])).size(),_hidden_scene_text(scene)])
    print("\nEDITORIAL METRICS · long_scenes=%d · generic_sci_fi_openers=%d" % [long_scenes,generic_starts])

    var loops := _args_loops()
    print("\n=== HUMAN-READABLE LOOP REPORT · %d LOOPS ===" % loops)
    var roster := AstraCrewCatalog.ORDER.duplicate()
    for run in range(loops):
        var seed_value := 2054000 + run * 113
        var chapter := ["ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"][run % 4]
        var arcs := AstraStorylets054.select_arcs(seed_value,run,chapter,roster,[],3)
        var routine := AstraCrewRoutineModel.build(seed_value,run,chapter,roster,roster,[])
        var deviations: Array[String] = []
        for npc_id in routine:
            var entry: Dictionary = routine[npc_id]
            if bool(entry.get("is_deviation",false)):
                deviations.append("%s@%s(%s)" % [npc_id,str(entry.get("location","")),str(entry.get("deviation_reason",""))])
        print("LOOP %02d · %s · arcs=%s · routine=%s" % [run+1,chapter,str(arcs),str(deviations)])
    print("ASTRA 0.5.4 HUMAN EDITING REPORT OK")
