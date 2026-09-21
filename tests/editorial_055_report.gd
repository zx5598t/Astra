extends SceneTree

func _initialize() -> void:
    var scenes := AstraStorylets055.scenes()
    var samples := {"MOTIVE":0,"COOPERATIVE":0,"FOREKNOWLEDGE":0,"CANON":0,"DELEGATION":0}
    print("=== ASTRA 0.5.5 HUMAN-READABLE EDITORIAL REPORT ===")
    for scene in scenes:
        var category := str(scene.get("category",""))
        if not samples.has(category) or int(samples[category]) >= 2:
            continue
        samples[category] = int(samples[category])+1
        print("[%s] %s" % [category,str(scene.get("id",""))])
        print("  ACTION: " + str(scene.get("action","")))
        for line in scene.get("lines",[]):
            print("  %s: %s" % [str(line[0]),str(line[1])])
    print("AUTHORED_055=" + str(scenes.size()))
    print("SPEAKER_COUNTS=" + str(AstraStorylets055.speaker_counts()))
    print("ASTRA 0.5.5 HUMAN EDITING REPORT OK")
    quit(0)
