extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_path_limited_propagation()
    test_session_evidence_ownership()
    if failures.is_empty():
        print("ASTRA 0.5.3 KNOWLEDGE PROPAGATION TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.3 KNOWLEDGE PROPAGATION TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_path_limited_propagation() -> void:
    var flags := {}
    AstraKnowledgeModel.discover_player(flags,"F",1)
    AstraKnowledgeModel.share_with(flags,"F","noa",1)
    check(AstraKnowledgeModel.knows(flags,"noa","F"),"Noa knows player-shared fact")
    check(not AstraKnowledgeModel.knows(flags,"vale","F"),"Soren does not know it before Noa tells him")
    check(not AstraKnowledgeModel.knows(flags,"eli","F"),"Lucan does not receive one-tick gossip")
    check(AstraKnowledgeModel.share_between(flags,"F","noa","vale",2),"Noa can explicitly propagate known fact to Soren")
    check(AstraKnowledgeModel.knows(flags,"vale","F"),"Soren knows fact after explicit Noa→Soren path")
    check(not AstraKnowledgeModel.knows(flags,"eli","F"),"Lucan still does not know fact after Noa→Soren")
    check(AstraKnowledgeModel.share_between(flags,"F","vale","eli",3),"Soren can later propagate to Lucan")
    check("vale" in AstraKnowledgeModel.trace_text(flags,"eli","F"),"knowledge trace records the immediate source")
    AstraKnowledgeModel.make_public(flags,"F",["mira","rho","dax","noa","sena","vale","eli","lyra"],3)
    check(AstraKnowledgeModel.knows(flags,"mira","F"),"public fact reaches active roster")
    check(AstraKnowledgeModel.knowers(flags,"F").size() >= 8,"knowledge ledger retains explicit knowers")

func test_session_evidence_ownership() -> void:
    var s := AstraGameSession.new()
    s.setup("ECHO_WARD",530099)
    s.begin_voyage({"loops":2})
    s.voyage["scene"] = {}
    s._voyage_fact("test_fact","테스트 사실")
    check("player" in s.voyage["evidence_ownership"]["test_fact"]["knows"],"voyage evidence starts player-owned")
    check(not AstraKnowledgeModel.knows(s.flags,"noa","test_fact"),"crew do not magically receive a voyage fact")
