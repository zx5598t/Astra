extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_single_pin()
    test_pin_transfer_and_soft_weight()
    if failures.is_empty():
        print("ASTRA 0.5.4 CURIOSITY PIN TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 CURIOSITY PIN TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_single_pin() -> void:
    var s := AstraGameSession.new()
    s.setup("LAST_LIGHT",540056)
    s.begin_voyage({"loops":3})
    s.voyage["scene"] = {}
    var questions := s.current_questions()
    check(not questions.is_empty(),"current curiosity question exists")
    var first := str(questions[0]["id"])
    check(s.pin_question(first),"question can be focused")
    check(str(s.voyage["pinned_question"]) == first,"only one pinned question is stored")
    var second := ""
    for key in s.voyage["questions"]:
        if str(key) != first and str(s.voyage["questions"][key].get("status","")) in ["OPEN","PARTIAL","CHANGED"]:
            second = str(key)
            break
    if second != "":
        check(s.pin_question(second),"second question can replace focus")
        check(str(s.voyage["pinned_question"]) == second,"pinning another question replaces the prior one")
    check(s.pin_question(str(s.voyage["pinned_question"])),"clicking focused question toggles it")
    check(str(s.voyage["pinned_question"]) == "","question focus can be cleared")

func test_pin_transfer_and_soft_weight() -> void:
    var s := AstraGameSession.new()
    s.setup("DEAD_AIR",540057)
    s.begin_voyage({"loops":1})
    s.voyage["scene"] = {}
    var base := str(s.current_questions()[0]["id"])
    s.pin_question(base)
    s._advance_curiosity_question("destination")
    check(str(s.voyage["pinned_question"]) == base + "_after","answered focused question transfers focus to its follow-up")
    var pinned := s.pinned_question_entry()
    check(not Array(pinned.get("related",[])).is_empty(),"focused question exposes only coarse related people/rooms")
    var ordinary := {"id":"ordinary","speaker":"rho","family":"a"}
    var related := {"id":"related","speaker":"noa","family":"b"}
    var w1 := AstraStoryletScheduler.weight(ordinary,{},[],"OLD_FRIENDS",pinned)
    var w2 := AstraStoryletScheduler.weight(related,{},[],"OLD_FRIENDS",pinned)
    check(w2 > w1,"focused question modestly raises related optional content weight")
    check(w2 < w1 * 1.5,"question focus remains a soft nudge, not a quest gate")
