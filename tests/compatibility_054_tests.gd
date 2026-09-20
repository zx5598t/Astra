extends SceneTree

var checks := 0
var failures: Array[String] = []
const PATH := "user://astra_054_legacy_voyage.session"

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_053_snapshot_hydrates_054_fields()
    AstraGameSession.delete_snapshot(PATH)
    if failures.is_empty():
        print("ASTRA 0.5.4 SAVE COMPATIBILITY TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 SAVE COMPATIBILITY TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_053_snapshot_hydrates_054_fields() -> void:
    var old := AstraGameSession.new()
    old.setup("SILENT_ORBIT",540058)
    old.begin_voyage({"loops":2})
    old.voyage["scene"] = {}
    for key in [
        "routine_state","routine_observed","routine_observations","active_arcs",
        "micro_arc_state","micro_arc_recent","micro_arc_pity",
        "consequence_queue","consequence_history","consequence_stats",
        "pinned_question","opinion_changes"
    ]:
        old.voyage.erase(key)
    check(old.save_snapshot(PATH),"synthetic 0.5.3-style exploration snapshot can be written")

    var restored := AstraGameSession.new()
    check(restored.load_snapshot(PATH),"0.5.3-style exploration snapshot loads in 0.5.4")
    check(restored.phase == "EXPLORE","restored phase is preserved")
    check(restored.voyage.has("routine_state") and not restored.voyage["routine_state"].is_empty(),"routine state is hydrated without save reset")
    check(restored.voyage.has("active_arcs"),"micro-arc selection state is optional and hydrated")
    check(restored.voyage.has("consequence_queue"),"consequence queue defaults safely")
    check(restored.voyage.has("pinned_question"),"curiosity pin defaults safely")
    check(restored.voyage.has("opinion_changes"),"opinion change log defaults safely")

    var again := AstraGameSession.new()
    check(again.load_snapshot(PATH),"same legacy snapshot loads repeatedly")
    check(restored.voyage["routine_state"] == again.voyage["routine_state"],"legacy migration is deterministic")
