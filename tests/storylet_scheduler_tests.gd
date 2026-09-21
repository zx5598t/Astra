extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    test_unseen_priority()
    test_rare_pity()
    test_multiline_coherence_metadata()
    test_player_visible_signature()
    if failures.is_empty():
        print("ASTRA 0.5.3 STORYLET SCHEDULER TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.3 STORYLET SCHEDULER TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func test_unseen_priority() -> void:
    var scene := {"id":"x","family":"f","speaker":"mira"}
    var unseen := AstraStoryletScheduler.weight(scene,{},[],"OLD_FRIENDS")
    var seen := AstraStoryletScheduler.weight(scene,{"x":2},[],"OLD_FRIENDS")
    var recent := AstraStoryletScheduler.weight(scene,{},["f"],"OLD_FRIENDS")
    check(unseen > seen,"unseen authored scene gets a modest priority")
    check(recent < unseen,"recent family penalty overrides novelty")

func test_rare_pity() -> void:
    var scene := {"id":"rare_x","rarity":"rare"}
    var base := AstraStoryletScheduler.rare_threshold(scene,{})
    var later := AstraStoryletScheduler.rare_threshold(scene,{"rare_x":4})
    check(later > base,"rare threshold rises after repeated eligible misses")
    check(later <= 0.85,"rare pity keeps an upper bound")
    var state := AstraStoryletScheduler.update_pity({},[scene],"")
    check(int(state.get("rare_x",0)) == 1,"missed rare scene increments pity")
    state = AstraStoryletScheduler.update_pity(state,[scene],"rare_x")
    check(int(state.get("rare_x",-1)) == 0,"seen rare scene resets pity")

func test_multiline_coherence_metadata() -> void:
    var checked := 0
    for scene in AstraStorylets053.multi_line_scenes():
        var lines: Array = scene.get("lines",[])
        var relations: Array = scene.get("line_relations",[])
        check(relations.size() == lines.size(),str(scene.get("id","")) + " has one coherence relation per line")
        for relation in relations:
            check(str(relation) in ["anchor","reply","clarify","challenge","support","transition","proposal","agreement","accept","followup","inference","mediate","condition","question","answer","deflect","boundary","acknowledge","decision","instruction","resolution","tease","explain"],str(scene.get("id","")) + " uses a meaningful dialogue relation")
        checked += 1
    check(checked >= 20,"0.5.3 audits many authored multi-line scenes (%d)" % checked)

func test_player_visible_signature() -> void:
    var sig_a := AstraStoryletScheduler.visible_signature("OLD_FRIENDS",{"id":"hook_a"},["s1"],["r1"],"")
    var sig_b := AstraStoryletScheduler.visible_signature("OLD_FRIENDS",{"id":"hook_b"},["s1"],["r1"],"")
    check(sig_a != sig_b,"visible replay signature changes when the player-visible hook changes")
