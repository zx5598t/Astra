extends SceneTree

# ASTRA 1.2.0 AFTERIMAGE — Past Echo eligibility, leak prevention, runtime,
# save/load and character-role coverage.
var failures: Array[String] = []
var checks := 0
var report: PackedStringArray = []

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    run_audit()
    if failures.is_empty():
        print("ASTRA PAST ECHO 120 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA PAST ECHO 120 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _history(anchor: String, route: String, loop_index: int = 2, with_scene: bool = true) -> Array:
    return [{
        "signature":"%s:%s:%d:1" % [anchor,route,loop_index],
        "anchor":anchor,"route":route,
        "scene":"110_test_source" if with_scene else "",
        "loop":loop_index,"day":1
    }]

func _find_echo(options: Array, echo_id: String) -> Dictionary:
    for option in options:
        if str(option.get("intent","")) == "ECHO" and str(option.get("ref","")) == echo_id:
            return option
    return {}

func run_audit() -> void:
    var specs := AstraForeknowledgeModel.past_echo_specs()
    check(specs.size() >= 8 and specs.size() <= 12, "8-12 authored Past Echo opportunities")
    var ids := {}
    var cases := {}
    var maren := 0
    var lucan := 0
    report.append("ASTRA 1.2.0 — PAST ECHO audit")
    report.append("echo_id\tcase\tspeaker\tanchor\troutes\truntime\tsave_load")

    for raw in specs:
        var spec: Dictionary = raw
        var id := str(spec.get("id",""))
        var case_id := str(spec.get("case_id",""))
        var speaker := str(spec.get("speaker",""))
        var anchor := str(spec.get("anchor",""))
        var routes: Array = spec.get("routes",[])
        check(id != "" and not ids.has(id), id + " unique id")
        ids[id] = true
        cases[case_id] = true
        check(AstraCaseCatalog.stage_index(anchor) < AstraCaseCatalog.stage_index(case_id),
            id + " source anchor is from an earlier Stage")
        check(routes.size() >= 2, id + " reacts to alternate experienced routes")
        if str(spec.get("role","")) == "MAREN_ENVIRONMENT":
            maren += 1
        if str(spec.get("role","")) == "LUCAN_ROUTE":
            lucan += 1

        var route := str(routes[0])
        var memory := {"loops":3,"route_history":_history(anchor,route,2)}
        var candidates := AstraForeknowledgeModel.past_echo_candidates(case_id,speaker,memory["route_history"],[],3)
        check(candidates.any(func(x): return str(x.get("id","")) == id), id + " unlocks from experienced route")

        # Stage number / route_choices alone is never sufficient.
        check(AstraForeknowledgeModel.past_echo_candidates(case_id,speaker,[],[],8).is_empty(),
            id + " does not unlock from Stage number alone")
        check(AstraForeknowledgeModel.past_echo_candidates(case_id,speaker,_history(anchor,route,3),[],3).is_empty(),
            id + " rejects current-History route")
        check(AstraForeknowledgeModel.past_echo_candidates(case_id,speaker,_history(anchor,route,2,false),[],3).is_empty(),
            id + " rejects route record without an experienced scene")

        var s := AstraGameSession.new()
        s.setup(case_id,12000 + checks)
        s.begin_voyage(memory)
        check(speaker in s.roster, id + " speaker is present in target Stage")
        s.phase = "INTERROGATION"
        var opened := s.open_conversation(speaker)
        check(bool(opened.get("ok",false)), id + " conversation opens")
        var echo_option := _find_echo(s.question_options(speaker),id)
        check(not echo_option.is_empty(), id + " appears as a real [잔향] question")
        var used := s.ask(speaker,"ECHO",id)
        check(bool(used.get("ok",false)) and str(used.get("intent","")) == "ECHO", id + " is selectable")
        check(Array(s.voyage.get("past_echo_used",[])).has(id), id + " marks current-History use")
        var echo_history: Array = s.voyage.get("past_echo_history",[])
        check(not echo_history.is_empty() and str(echo_history.back().get("id","")) == id, id + " records provenance history")
        check(str(echo_history.back().get("source_route","")) == route, id + " records experienced source route")
        check(_find_echo(s.question_options(speaker),id).is_empty(), id + " cannot be reused in the same History")

        var save_path := "user://past_echo_120_%s.cfg" % id
        AstraGameSession.delete_snapshot(save_path)
        check(s.save_snapshot(save_path), id + " snapshot saves")
        var loaded := AstraGameSession.new()
        check(loaded.load_snapshot(save_path), id + " snapshot reloads")
        check(Array(loaded.voyage.get("past_echo_history",[])).size() == echo_history.size(), id + " history survives save/load")
        check(Array(loaded.voyage.get("past_echo_used",[])).has(id), id + " used state survives mid-Stage save")
        AstraGameSession.delete_snapshot(save_path)

        report.append("%s\t%s\t%s\t%s\t%s\tPASS\tPASS" % [
            id,case_id,speaker,anchor,",".join(PackedStringArray(routes))
        ])

    check(cases.size() >= 5, "Past Echo spans at least five Stages")
    check(maren >= 3, "Maren has 3+ environmental-continuity Echo opportunities")
    check(lucan >= 4, "Lucan has 4+ feasibility/route Echo opportunities")

    # 1.1.1 save hydration: missing new voyage keys defaults safely without a
    # save version bump or destructive migration.
    var old := AstraGameSession.new()
    old.setup("CONTINUITY",12999)
    old.begin_voyage({"loops":2})
    old.voyage.erase("past_echo_used")
    old.voyage.erase("past_echo_history")
    old._hydrate_054_voyage_defaults()
    check(old.voyage.has("past_echo_used") and old.voyage.has("past_echo_history"),
        "1.1.1 voyage state hydrates new Echo fields safely")
    check(AstraGameSession.SNAPSHOT_VERSION == 4, "Snapshot remains v4")
    check(AstraMetaProgress.SAVE_VERSION == 12, "Meta save remains v12")

    report.append("")
    report.append("opportunities\t%d" % specs.size())
    report.append("target_stages\t%d" % cases.size())
    report.append("maren_role_callbacks\t%d" % maren)
    report.append("lucan_role_callbacks\t%d" % lucan)
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/past_echo_120.txt",FileAccess.WRITE)
    file.store_string("\n".join(report))
    file.close()
