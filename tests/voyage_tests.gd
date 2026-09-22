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
            var choices: Array = scene.get("choices",[])
            var pick := 0
            # FIRST CONTACT's first decision is intentionally restricted to
            # the two evidence-review effects; authored ordering may include
            # non-applicable legacy choices, so choose a legal effect.
            if s.first_day_flow() and str(scene.get("id","")) == "first_panel":
                for i in range(choices.size()):
                    if str(choices[i].get("effect","")) in ["check_source","check_maintenance"]:
                        pick = i
                        break
            check(s.voyage_choose(pick),"choice applied")
        else:
            s.voyage_next()
func _initialize() -> void:
    test_exploration_consequences()
    # 0.6.0 authored calendar: one crewmate joins on Days 2-5, then everyone
    # already awake stays at 8 for the rest of the campaign (ACT II included).
    var expected := [4,5,6,7]
    var ids := ["CALIBRATION"] + AstraCaseCatalog.CAMPAIGN
    while expected.size() < ids.size():
        expected.append(8)
    var memory := {}
    for i in range(ids.size()):
        var s := AstraGameSession.new()
        s.setup(ids[i],9143+i)
        s.begin_voyage(memory)
        check(s.roster.size()==expected[i],"progressive roster "+ids[i])
        check(s.null_count==AstraCaseCatalog.null_count(AstraCaseCatalog.get_case(ids[i])),"influence count "+ids[i])
        check(s.roster.slice(0,4)==AstraCrewCatalog.INITIAL,"initial four")
        close_scene(s)
        for who in s.roster:
            s.voyage_visit_person(who)
            close_scene(s)
        if not s.voyage["goal_done"]:
            var fact := str(AstraVoyageContent.chapter(ids[i]).get("fact",""))
            for room_id in s.voyage_rooms():
                if str(s.voyage.get("room","")) != str(room_id):
                    s.voyage_move(str(room_id),false)
                    close_scene(s)
                for point in s.voyage_points():
                    if str(point[4]) == fact and s.voyage_inspect(str(point[0])):
                        close_scene(s)
                        break
                if s.voyage["goal_done"]:
                    break
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
        # DEAD_AIR now wakes Sena. Mira therefore has to be met through the
        # normal visit flow before ordinary dialogue can be sampled.
        check(s.voyage_visit_person("mira"),"seed variety meets mira")
        close_scene(s)
        check(s.voyage_talk("mira"),"seed variety starts mira dialogue")
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
    # DEAD_AIR's room list is trimmed to medbay/comms/archive (§4 of the
    # design notes), so it no longer has "engine" to test the recorder
    # pickup in; ECHO_WARD keeps the full room set.
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD",1234)
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
    if not s.voyage["goal_done"]:
        # FIRST CONTACT/contact-flow guidance no longer grants the chapter fact:
        # finish the real ECHO_WARD investigation by inspecting its authored
        # signal point, exactly as the player must do at runtime.
        var goal_fact := str(AstraVoyageContent.chapter("ECHO_WARD").get("fact",""))
        for room_id in s.voyage_rooms():
            if str(s.voyage.get("room","")) != str(room_id):
                s.voyage_move(str(room_id),false)
                close_scene(s)
            for point in s.voyage_points():
                if str(point[4]) == goal_fact and s.voyage_inspect(str(point[0])):
                    close_scene(s)
                    break
            if s.voyage["goal_done"]:
                break
    check(s.finish_voyage() and s.flags.get("mission_backup",false),"exploration choice enables actual night backup")
    var pity := AstraGameSession.new()
    pity.setup("CALIBRATION",8)
    pity.begin_voyage()
    close_scene(pity)
    # 0.6.0 FIRST CONTACT deliberately requires one direct investigation.
    # Re-entering the room must not auto-complete the core discovery.
    for i in range(12):
        pity.voyage_move("medbay")
        close_scene(pity)
    check(not pity.voyage["goal_done"],"FIRST CONTACT core discovery still requires direct inspection")
    check(pity.voyage_inspect("pod"),"FIRST CONTACT direct panel inspection works")
    close_scene(pity)
    check(pity.voyage["goal_done"],"direct inspection completes the FIRST CONTACT discovery")
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
