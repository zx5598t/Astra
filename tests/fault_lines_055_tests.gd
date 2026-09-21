extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)

func _initialize() -> void:
    test_motives()
    test_incidents()
    test_foreknowledge()
    test_storylets()
    if failures.is_empty():
        print("ASTRA 0.5.5 FAULT LINES TESTS OK · %d checks" % checks)
        quit(0)
    for failure in failures:
        push_error(failure)
    quit(1)

func test_motives() -> void:
    var roster := ["mira","rho","dax","noa","sena","vale","eli","lyra"]
    var active := roster.duplicate()
    for seed in range(1,1001):
        var a := AstraPersonalMotiveModel.assign(seed,seed%5,"ECHO_WARD",roster,active,["mira"])
        var b := AstraPersonalMotiveModel.assign(seed,seed%5,"ECHO_WARD",roster,active,["rho","dax"])
        check(a == b,"motive/null independence seed %d" % seed)
        check(a.size() >= 1 and a.size() <= 3,"motive count seed %d" % seed)
        for who in a:
            check(who in active,"inactive motive " + str(who))
            check(AstraPersonalMotiveModel.is_compatible(str(who),str(a[who]["motive"])),"incompatible motive " + str(who))
    check(AstraPersonalMotiveModel.assign(1,0,"DEAD_AIR",roster,active,[]).is_empty(),"no early motives")
    var state := AstraPersonalMotiveModel.assign(7,1,"ECHO_WARD",roster,active,[])
    var who := str(state.keys()[0])
    state = AstraPersonalMotiveModel.observe(state,who,"direct","saw")
    check(AstraPersonalMotiveModel.progress_for(state,who) == 1,"motive direct progress")
    state = AstraPersonalMotiveModel.observe(state,who,"record","record")
    state = AstraPersonalMotiveModel.observe(state,who,"testimony","talk")
    check(str(state[who]["state"]) == "REVEALED","motive multi-source reveal")

func test_incidents() -> void:
    check(AstraIncidentModel.eligible_types("CALIBRATION").is_empty(),"no calibration incidents")
    check(AstraIncidentModel.eligible_types("DEAD_AIR").is_empty(),"no dead air incidents")
    check(AstraIncidentModel.incident_types() == 8,"eight incident types")
    var active := ["mira","rho","dax","noa","sena","vale","eli","lyra"]
    for seed in range(1,251):
        var a := AstraIncidentModel.select(seed,2,"LAST_LIGHT",[],active)
        var b := AstraIncidentModel.select(seed,2,"LAST_LIGHT",[],active)
        check(a == b,"incident determinism %d" % seed)
        check(str(a.get("actor","")) in active,"incident active actor %d" % seed)
        var sc := AstraIncidentModel.scene(a,2,false)
        check(not Array(sc.get("choices",[])).is_empty(),"incident has choices %d" % seed)
        for choice in sc.get("choices",[]):
            check(str(choice.get("outcome","")) in ["RESOLVED","PARTIAL","COSTLY","UNRESOLVED"],"valid incident outcome")
    check(AstraIncidentModel.should_trigger(3,0,"RED_SHIFT",4,[],{}),"red shift incident pressure")
    check(not AstraIncidentModel.should_trigger(3,0,"RED_SHIFT",4,[{"loop":0,"id":"POWER_RELAY"}],{}),"one incident per loop")

func test_foreknowledge() -> void:
    var history := [{"id":"COMMS_SPIKE","loop":0}]
    check(not AstraForeknowledgeModel.can_use(0,"COMMS_SPIKE",history,[]),"no loop zero foreknowledge")
    check(AstraForeknowledgeModel.can_use(1,"COMMS_SPIKE",history,[]),"seen event enables foreknowledge")
    check(not AstraForeknowledgeModel.can_use(1,"POWER_RELAY",history,[]),"unseen event blocks foreknowledge")
    check(not AstraForeknowledgeModel.can_use(2,"COMMS_SPIKE",history,["A","B"]),"foreknowledge cap")
    check(AstraForeknowledgeModel.source_label("RUMOR") == "전해 들음","source label")
    var scene := {"speaker":"rho","tag":"work","category":"WORK","choices":[],"compressible":true}
    check(AstraForeknowledgeModel.can_compress(scene,2),"pure repeat compresses")
    scene["choices"] = [{"label":"x","effect":"wait"}]
    check(not AstraForeknowledgeModel.can_compress(scene,2),"choice blocks compression")

func test_storylets() -> void:
    var scenes := AstraStorylets055.scenes()
    check(scenes.size() == 71,"055 authored scene count")
    var ids := {}
    for scene in scenes:
        var id := str(scene.get("id",""))
        check(id != "","scene id")
        check(not ids.has(id),"unique scene " + id)
        ids[id] = true
        check(not ("CALIBRATION" in Array(scene.get("chapters",[]))),"first 30 min protected " + id)
        check(not ("DEAD_AIR" in Array(scene.get("chapters",[]))),"dead air protected " + id)
    var coop_a := AstraStorylets055.cooperative_scene("signal","vale")
    var coop_b := AstraStorylets055.cooperative_scene("signal","noa")
    check(str(coop_a.get("action","")) != str(coop_b.get("action","")),"specialist observations differ")
    var counts := AstraStorylets055.speaker_counts()
    check(int(counts.get("mira",0)) <= 10,"Mira expansion cap")
    check(int(counts.get("vale",0)) >= 8,"Soren depth")
    check(int(counts.get("eli",0)) >= 8,"Lucan depth")
