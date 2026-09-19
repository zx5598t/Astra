extends SceneTree
var failures: Array[String] = []
var checks := 0
func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok: failures.append(label)
func close_scene(s: AstraGameSession) -> void:
    var guard := 0
    while not s.voyage.get("scene",{}).is_empty() and guard < 20:
        guard += 1
        var scene: Dictionary = s.voyage["scene"]
        if int(s.voyage["line"]) >= scene.get("lines",[]).size()-1 and not scene.get("choices",[]).is_empty():
            check(s.voyage_choose(0),"choice applied")
        else:
            s.voyage_next()
func _initialize() -> void:
    test_exploration_consequences()
    var expected := [4,4,5,6,7,8,8]
    var ids := ["CALIBRATION"] + AstraCaseCatalog.CAMPAIGN
    var memory := {}
    for i in range(ids.size()):
        var s := AstraGameSession.new()
        s.setup(ids[i],9143+i)
        s.begin_voyage(memory)
        check(s.roster.size()==expected[i],"progressive roster "+ids[i])
        check(s.null_count==(1 if expected[i]<7 else 2),"influence count "+ids[i])
        check(s.roster.slice(0,4)==AstraCrewCatalog.INITIAL,"initial four")
        close_scene(s)
        for who in s.roster:
            s.voyage_visit_person(who)
            close_scene(s)
        if not s.voyage["goal_done"]:
            s.voyage_ask_goal(str(s.voyage_people()[0]))
            close_scene(s)
        check(s.voyage_can_finish(),"story never blocked "+ids[i])
        var path := "user://astra_050_test.session"
        check(s.save_snapshot(path),"save "+ids[i])
        var restored := AstraGameSession.new()
        check(restored.load_snapshot(path),"restore "+ids[i])
        check(same_state(restored.voyage,s.voyage) and restored.rng.state==s.rng.state,"exact voyage round trip")
        check(restored.roster==s.roster,"roster survives save")
        AstraGameSession.delete_snapshot(path)
        var before: Dictionary = s.voyage.duplicate(true)
        check(not s.voyage_choose(999),"invalid choice rejected")
        check(s.voyage==before,"invalid choice side-effect free")
        check(s.finish_voyage(),"complete chapter exploration")
        check(s.phase==("RESULT" if i==0 else "BRIEFING"),"route out of exploration")
        memory=s.voyage_memory()
        check(int(memory["loops"])==i+1,"loop increases")
    for id in AstraCrewCatalog.ORDER:
        check(ResourceLoader.exists(AstraCrewCatalog.dot_path(id)),"head "+id)
        check(ResourceLoader.exists(AstraCrewCatalog.cast_path(id)),"portrait "+id)
        check(ResourceLoader.exists(AstraCrewCatalog.cast_path(id,"not-a-mood")),"mood fallback "+id)
        check(AstraCrewCatalog.dot_path(id).contains("art050"),"new art "+id)
    check(AstraGameSession.PLAYER_VOTE_WEIGHT==1,"equal vote")
    var scenes := {}
    var choices := {}
    var per_person := {}
    for scene in AstraVoyageContent.SCENES:
        check(not scenes.has(scene["id"]),"unique scene id")
        scenes[scene["id"]]=true
        choices[scene["choices"].size()]=true
        per_person[scene["speaker"]]=int(per_person.get(scene["speaker"],0))+1
    for id in AstraCrewCatalog.ORDER: check(int(per_person.get(id,0))>=15,"scene coverage "+id)
    check(choices.size()>=4,"irregular choice counts")
    var variants := {}
    for seed in range(1,101):
        var s := AstraGameSession.new()
        s.setup("DEAD_AIR",seed)
        s.begin_voyage(memory)
        close_scene(s)
        s.voyage_talk("mira")
        variants[str(s.voyage["scene"].get("id",""))]=true
    check(variants.size()>=3,"100 seed scene variety")
    var meta := AstraMetaProgress.new("user://astra_050_meta.cfg")
    meta.voyage_memory=memory
    meta.save_data()
    var loaded := AstraMetaProgress.new(meta.save_path)
    loaded.load_data()
    check(same_state(loaded.voyage_memory,memory),"persistent echoes, bonds and memory")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(meta.save_path))
    if failures.is_empty():
        print("ASTRA VOYAGE TESTS OK · %d checks · %d authored scenes" % [checks,scenes.size()])
        quit(0)
    else:
        for failure in failures: printerr("FAIL · "+failure)
        quit(1)

func test_exploration_consequences() -> void:
    var s := AstraGameSession.new()
    s.setup("DEAD_AIR",1234)
    s.begin_voyage({"loops":1})
    close_scene(s)
    s.voyage_move("engine",false)
    check(s.voyage_inspect("worklog"),"recording item is discoverable")
    close_scene(s)
    check("recorder" in s.voyage["inventory"],"item added to inventory")
    check(not s.voyage_use_recorder(),"item cannot be used in wrong room")
    s.voyage_move("comms",false)
    check(s.voyage_use_recorder(),"item can preserve a signal")
    close_scene(s)
    check(not s.voyage_use_recorder(),"item cannot apply twice")
    for who in s.roster:
        s.voyage_visit_person(who)
        close_scene(s)
    check(s.finish_voyage() and s.flags.get("mission_backup",false),"exploration choice enables actual night backup")
    var pity := AstraGameSession.new()
    pity.setup("CALIBRATION",8)
    pity.begin_voyage()
    close_scene(pity)
    # CALIBRATION is one room by design, so the pity clock (which only ticks
    # on a "deliver" action such as a move) is exercised by re-entering the
    # same room rather than room-hopping.
    for i in range(12):
        pity.voyage_move("medbay")
        close_scene(pity)
    check(pity.voyage["goal_done"],"main discovery offered even without inspecting")
    var last := ""
    var variants := {}
    pity.voyage_visit_person("mira")
    close_scene(pity)
    for i in range(15):
        pity.voyage_talk("mira")
        var current := str(pity.voyage["scene"]["id"])
        check(current != last,"ordinary dialogue never immediately repeats")
        variants[current]=true
        last=current
        close_scene(pity)
    check(variants.size()>=4,"one playthrough includes different kinds of scenes")

# ConfigFile prints decimal floats. Compare their numerical value, while keys,
# story data, actions and RNG state must still match exactly.
func same_state(a: Variant,b: Variant) -> bool:
    if typeof(a) != typeof(b): return false
    if a is float: return is_equal_approx(a,b)
    if a is Dictionary:
        if a.size() != b.size(): return false
        for key in a:
            if not b.has(key) or not same_state(a[key],b[key]): return false
        return true
    if a is Array:
        if a.size() != b.size(): return false
        for i in range(a.size()):
            if not same_state(a[i],b[i]): return false
        return true
    return a == b
