extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_all_timing_classes()
    test_bounded_queue_and_expiry()
    test_runtime_choice_to_followup()
    if failures.is_empty():
        print("ASTRA 0.5.4 CONSEQUENCE CHAIN TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 CONSEQUENCE CHAIN TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func _choice_with_timing(timing: String) -> Dictionary:
    return {"effect":"wait","consequences":[{"id":"test_"+timing,"timing":timing,"note":"후속 " + timing,"delay":2}]}

func test_all_timing_classes() -> void:
    for timing in AstraConsequenceModel.TIMINGS:
        var events := AstraConsequenceModel.from_choice(_choice_with_timing(str(timing)),"mira","test_scene",5,2,1)
        check(events.size() == 1,str(timing) + " consequence is constructed")
        check(str(events[0].get("timing","")) == str(timing),str(timing) + " keeps its timing")
    var scenes := AstraStorylets054.scenes()
    var counts := AstraConsequenceModel.timing_counts(scenes)
    for timing in AstraConsequenceModel.TIMINGS:
        check(int(counts.get(timing,0)) > 0,"authored 0.5.4 content uses " + str(timing))
    print("CONSEQUENCE TIMINGS · " + str(counts))

func test_bounded_queue_and_expiry() -> void:
    var queue: Array = []
    for i in range(30):
        queue = AstraConsequenceModel.enqueue(queue,[{"id":"q"+str(i),"timing":"DELAYED","due_action":i,"expires_action":i+4}])
    check(queue.size() == AstraConsequenceModel.MAX_QUEUE,"consequence queue has a hard upper bound")
    var event := {"timing":"DELAYED","due_action":3,"expires_action":6}
    check(not AstraConsequenceModel.is_due(event,2,0,1),"delayed consequence waits")
    check(AstraConsequenceModel.is_due(event,3,0,1),"delayed consequence fires when due")
    check(AstraConsequenceModel.is_expired(event,7,0,1),"small follow-up expires instead of living forever")

func test_runtime_choice_to_followup() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",540055)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    s.voyage["met"] = s.roster.duplicate()
    s.voyage["actions"] = 8
    var test_scene := {
        "id":"054_runtime_consequence_test","speaker":"mira","tag":"player","lines":[],
        "choices":[{"label":"기록한다","effect":"record","consequences":[{"id":"runtime-immediate","timing":"IMMEDIATE","note":"선택 직후 기록 방식이 달라졌다."}]}]
    }
    s._voyage_scene(test_scene)
    s.voyage["line"] = -1
    check(s.voyage_choose(0),"runtime consequence choice resolves")
    check(int(s.voyage["consequence_stats"].get("IMMEDIATE",0)) == 1,"immediate consequence actually fires")
    check(not s.voyage["consequence_history"].is_empty(),"consequence history records what happened")
    check(str(s.voyage["scene"].get("category","")) == "CONSEQUENCE","player sees consequence through scene rather than a +trust popup")
