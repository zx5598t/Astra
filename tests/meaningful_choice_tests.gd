extends SceneTree

var checks := 0
var failures: Array[String] = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    audit_choices()
    if failures.is_empty():
        print("ASTRA 0.5.4 MEANINGFUL CHOICE TESTS OK · %d checks" % checks)
        quit(0)
    else:
        print("ASTRA 0.5.4 MEANINGFUL CHOICE TESTS FAILED · %d of %d checks" % [failures.size(),checks])
        quit(1)

func _signature(choice: Dictionary) -> String:
    var consequences: Array = []
    for event in choice.get("consequences",[]):
        consequences.append("%s:%s:%s:%s" % [
            str(event.get("timing","")),str(event.get("followup_scene","")),
            str(event.get("memory_tag","")),str(event.get("note",""))
        ])
    return "%s|%s|%s|%s" % [
        str(choice.get("effect","")),str(choice.get("memory_tag","")),
        str(choice.get("promise","")),",".join(PackedStringArray(consequences))
    ]

func audit_choices() -> void:
    var sampled := 0
    var consequence_choices := 0
    for scene in AstraVoyageContent.all_scenes():
        var choices: Array = scene.get("choices",[])
        if choices.size() < 2:
            continue
        sampled += 1
        var signatures := {}
        for choice in choices:
            if not Array(choice.get("consequences",[])).is_empty():
                consequence_choices += 1
            signatures[_signature(choice)] = true
        var thematic := bool(scene.get("thematic_choice",false))
        check(thematic or signatures.size() > 1,str(scene.get("id","")) + " does not present two identical outcome choices")
    check(sampled >= 30,"meaningless-choice audit covers at least 30 multi-choice scenes (%d)" % sampled)
    check(consequence_choices >= 12,"new consequence choices are materially represented (%d)" % consequence_choices)
    print("MEANINGFUL CHOICE AUDIT · multi_choice_scenes=%d · consequence_choices=%d" % [sampled,consequence_choices])
