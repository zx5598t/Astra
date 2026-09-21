extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_budget_and_early_guard()
    test_active_actor_invariant()
    test_runtime_observation()
    if failures.is_empty():
        print("ASTRA 0.5.3 AUTONOMY TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.3 AUTONOMY TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_budget_and_early_guard() -> void:
    var roster := AstraCrewCatalog.ORDER.duplicate()
    var early := AstraCrewActivityModel.schedule(1,0,"DEAD_AIR",roster,roster,[],2)
    check(early.is_empty(),"DEAD AIR adds no autonomous text load")
    for seed_value in range(80):
        var beats := AstraCrewActivityModel.schedule(5000 + seed_value,2,"ECHO_WARD",roster,roster,[],2)
        check(beats.size() <= 2,"autonomous budget never exceeds two per voyage")

func test_active_actor_invariant() -> void:
    var roster := AstraCrewCatalog.ORDER.duplicate()
    var active := roster.duplicate()
    active.erase("mira")
    for beat in AstraCrewActivityModel.BEATS:
        if "mira" in beat.get("actors",[]):
            check(not AstraCrewActivityModel.eligible(beat,"LAST_LIGHT",roster,active,[]),str(beat.get("id","")) + " rejects inactive Mira")
    check(AstraCrewActivityModel.BEATS.size() >= 24,"authored autonomous library covers the whole crew (%d)" % AstraCrewActivityModel.BEATS.size())

func test_runtime_observation() -> void:
    var observed := 0
    for seed_value in range(120):
        var s := AstraGameSession.new()
        s.setup("LAST_LIGHT",600000 + seed_value * 17)
        s.begin_voyage({"loops":3})
        s.voyage["scene"] = {}
        s.voyage["met"] = s.roster.duplicate()
        var queue: Array = s.voyage.get("activity_queue",[])
        if queue.is_empty():
            continue
        var room := str(queue[0].get("room",""))
        s.voyage["room"] = room
        if s._maybe_autonomous_beat(room):
            observed += 1
            check(str(s.voyage.get("scene",{}).get("category","")) == "AUTONOMOUS","observed beat renders as autonomous/overheard storylet")
            check(not Array(s.voyage.get("autonomous_seen_loop",[])).is_empty(),"observed beat enters replay coverage tracking")
    check(observed > 10,"seed sweep actually observes autonomous beats (%d)" % observed)
