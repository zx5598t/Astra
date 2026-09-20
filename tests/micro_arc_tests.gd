extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_arc_shape()
    test_selection_budget()
    test_runtime_stage_progression()
    test_ensemble_balance()
    if failures.is_empty():
        print("ASTRA 0.5.4 MICRO ARC TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 MICRO ARC TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_arc_shape() -> void:
    check(AstraStorylets054.micro_arc_count() == 8,"exactly one representative micro-arc per crew member")
    var actors := {}
    for chain_id in AstraStorylets054.arc_ids():
        var actor := AstraStorylets054.arc_actor(str(chain_id))
        actors[actor] = true
        var stages: Array[int] = []
        for scene in AstraStorylets054.scenes():
            if str(scene.get("chain_id","")) == str(chain_id):
                stages.append(int(scene.get("stage",0)))
                check(str(scene.get("speaker","")) == actor,str(chain_id) + " stages stay attached to their character")
        stages.sort()
        check(stages == [1,2,3,4],str(chain_id) + " has four authored beats")
    check(actors.size() == 8,"all eight characters own a micro-arc")

func test_selection_budget() -> void:
    var roster := AstraCrewCatalog.ORDER.duplicate()
    for chapter in ["CALIBRATION","DEAD_AIR","GLASS_GARDEN"]:
        check(AstraStorylets054.select_arcs(1,0,chapter,roster,[],3).is_empty(),chapter + " does not expose micro-arc systems")
    var seen := {}
    for seed_value in range(120):
        var arcs := AstraStorylets054.select_arcs(7000+seed_value,seed_value%4,"LAST_LIGHT",roster,[],3)
        check(arcs.size() >= 1 and arcs.size() <= 3,"late loop activates only 1-3 micro-arcs")
        for id in arcs:
            seen[str(id)] = true
    check(seen.size() == 8,"seed sweep can reach every character micro-arc")

func test_runtime_stage_progression() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",540054)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    s.voyage["actions"] = 8
    var chain_id := str(s.voyage["active_arcs"][0])
    var actor := AstraStorylets054.arc_actor(chain_id)
    s.voyage["room"] = str(s.routine_state_for(actor).get("location",AstraVoyageContent.home_room(actor,s.case_id)))
    var stage1 := {}
    var stage2 := {}
    for scene in AstraStorylets054.scenes():
        if str(scene.get("chain_id","")) == chain_id and int(scene.get("stage",0)) == 1: stage1 = scene
        if str(scene.get("chain_id","")) == chain_id and int(scene.get("stage",0)) == 2: stage2 = scene
    check(not stage1.is_empty() and not stage2.is_empty(),"selected arc has stage 1 and 2")
    check(s._scene_eligible_052(stage1,actor),"active arc stage 1 is eligible at stage zero")
    check(not s._scene_eligible_052(stage2,actor),"stage 2 is locked before stage 1")
    s._voyage_scene(stage1)
    s.voyage["scene"] = {}
    check(int(s.voyage["micro_arc_state"].get(chain_id,0)) == 1,"showing stage 1 advances chain state")
    check(s._scene_eligible_052(stage2,actor),"stage 2 becomes eligible after stage 1")

func test_ensemble_balance() -> void:
    var counts := AstraStorylets054.speaker_counts()
    check(int(counts.get("mira",0)) <= 15,"Mira does not monopolize 0.5.4 additions (%d)" % int(counts.get("mira",0)))
    check(int(counts.get("vale",0)) > int(counts.get("mira",0)),"Soren receives more 0.5.4 depth than Mira")
    check(int(counts.get("eli",0)) > int(counts.get("mira",0)),"Lucan receives more 0.5.4 depth than Mira")
    var total := 0
    for value in counts.values(): total += int(value)
    check(total >= 55 and total <= 70,"0.5.4 authored addition stays restrained (%d)" % total)
    print("0.5.4 NEW SCENES · " + str(counts) + " · total=" + str(total))
