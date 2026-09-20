extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_profiles()
    test_early_game_guard()
    test_determinism()
    test_1000_simulated_days()
    if failures.is_empty():
        print("ASTRA 0.5.4 ROUTINE MODEL TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 ROUTINE MODEL TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_profiles() -> void:
    check(AstraCrewRoutineModel.ROUTINES.size() == 8,"all eight crew have routine profiles")
    check(AstraCrewRoutineModel.routine_types() >= 32,"routine library has multiple normal activities (%d)" % AstraCrewRoutineModel.routine_types())
    check(AstraCrewRoutineModel.deviation_reason_count() >= 10,"routine deviation vocabulary stays explicit (%d)" % AstraCrewRoutineModel.deviation_reason_count())
    for npc_id in AstraCrewCatalog.ORDER:
        var profile: Dictionary = AstraCrewRoutineModel.ROUTINES.get(npc_id,{})
        check(not Array(profile.get("primary",[])).is_empty(),str(npc_id) + " has a primary spatial baseline")
        check(not Array(AstraCrewRoutineModel.DEVIATIONS.get(npc_id,[])).is_empty(),str(npc_id) + " has authored non-random deviations")

func test_early_game_guard() -> void:
    var roster := AstraCrewCatalog.ORDER.duplicate()
    var active := roster.duplicate()
    for chapter in ["CALIBRATION","DEAD_AIR"]:
        var state := AstraCrewRoutineModel.build(100,0,chapter,roster,active,[])
        var deviations := 0
        for npc_id in state:
            deviations += 1 if bool(state[npc_id].get("is_deviation",false)) else 0
        check(deviations == 0,chapter + " has no routine-deviation complexity")
    var glass := AstraCrewRoutineModel.build(101,0,"GLASS_GARDEN",roster,active,[])
    var glass_devs := 0
    for npc_id in glass:
        glass_devs += 1 if bool(glass[npc_id].get("is_deviation",false)) else 0
    check(glass_devs <= 1,"GLASS GARDEN has at most one visible routine deviation")

func test_determinism() -> void:
    var roster := AstraCrewCatalog.ORDER.duplicate()
    var a := AstraCrewRoutineModel.build(4312,3,"LAST_LIGHT",roster,roster,["rho"])
    var b := AstraCrewRoutineModel.build(4312,3,"LAST_LIGHT",roster,roster,["rho"])
    check(a == b,"same seed + loop builds identical routine state")
    var advanced_a := AstraCrewRoutineModel.advance(a,4,4312,"LAST_LIGHT",roster,roster)
    var advanced_b := AstraCrewRoutineModel.advance(b,4,4312,"LAST_LIGHT",roster,roster)
    check(advanced_a == advanced_b,"same action index advances routines deterministically")

func test_1000_simulated_days() -> void:
    var roster := AstraCrewCatalog.ORDER.duplicate()
    var chapters := ["CALIBRATION","DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT","RED_SHIFT","LAST_LIGHT"]
    var deviation_count := 0
    var max_deviations := 0
    var rooms_seen := {}
    for sim in range(1000):
        var chapter := str(chapters[sim % chapters.size()])
        var active := roster.duplicate()
        if sim % 9 == 0:
            active.erase("mira")
        if sim % 11 == 0:
            active.erase("vale")
        var state := AstraCrewRoutineModel.build(900000 + sim * 37,sim % 7,chapter,roster,active,["rho"] if sim % 5 == 0 else [])
        var allowed := AstraVoyageContent.room_ids(roster,chapter)
        var loop_devs := 0
        for npc_id in state:
            check(str(npc_id) in active,"routine never schedules inactive crew")
            var entry: Dictionary = state[npc_id]
            check(str(entry.get("location","")) in allowed,"routine room is reachable in chapter")
            rooms_seen[str(entry.get("location",""))] = true
            if bool(entry.get("is_deviation",false)):
                loop_devs += 1
                deviation_count += 1
                check(str(entry.get("deviation_reason","")) in AstraCrewRoutineModel.DEVIATION_REASONS,"important deviation always has a reason")
        max_deviations = maxi(max_deviations,loop_devs)
        check(loop_devs <= 3,"no simulated day has more than three important deviations")
    check(deviation_count > 100,"1000 simulated days actually exercise routine deviations (%d)" % deviation_count)
    check(max_deviations <= 3,"routine deviation cap remains 3")
    print("ROUTINE 1000 DAYS · deviations=%d · max_per_day=%d · rooms=%d" % [deviation_count,max_deviations,rooms_seen.size()])
