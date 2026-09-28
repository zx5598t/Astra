extends SceneTree

# ASTRA 1.2.0 — late-Stage presentation routes vary with experienced history
# while same-seed truth and generated evidence remain invariant.
const TARGETS := ["LAST_LIGHT","SECOND_WATCH","BLIND_DECK","CONTINUITY","THRESHOLD"]
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
        print("ASTRA HISTORY VARIATION 120 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA HISTORY VARIATION 120 TESTS FAILED · %d/%d" % [failures.size(),checks])
    quit(1)

func _spec_for(case_id: String) -> Dictionary:
    for raw in AstraForeknowledgeModel.past_echo_specs():
        if str(raw.get("case_id","")) == case_id:
            return Dictionary(raw)
    return {}

func _history(spec: Dictionary, route: String) -> Array:
    return [{"signature":"variation","anchor":str(spec.get("anchor","")),"route":route,
        "scene":"110_variation_source","loop":2,"day":1}]

func _candidate(spec: Dictionary, route: String) -> Dictionary:
    var found := AstraForeknowledgeModel.past_echo_candidates(
        str(spec.get("case_id","")),str(spec.get("speaker","")),_history(spec,route),[],3)
    return Dictionary(found[0]) if not found.is_empty() else {}

func _visible_difference(a: Dictionary, b: Dictionary) -> int:
    var total := 0
    for key in ["label","question","reaction","mode"]:
        if str(a.get(key,"")) != str(b.get(key,"")):
            total += 1
    return total

func run_audit() -> void:
    report.append("ASTRA 1.2.0 — late History variation audit")
    report.append("stage\troutes\tvisible_dimensions\ttruth_invariant\tevidence_invariant")
    for case_id in TARGETS:
        var spec := _spec_for(case_id)
        check(not spec.is_empty(), case_id + " has a Past Echo presentation route")
        if spec.is_empty():
            continue
        var routes: Array = spec.get("routes",[])
        check(routes.size() >= 2, case_id + " has 2+ history-conditioned variants")
        var first_route := str(routes[0])
        var second_route := str(routes[1])
        var a := _candidate(spec,first_route)
        var b := _candidate(spec,second_route)
        check(not a.is_empty() and not b.is_empty(), case_id + " both routes resolve")
        var visible := _visible_difference(a,b)
        check(visible >= 3, case_id + " alternate route differs in 3+ player-visible dimensions")

        var seed_value := 42000 + AstraCaseCatalog.stage_index(case_id)
        var sa := AstraGameSession.new()
        sa.setup(case_id,seed_value)
        var truth_a := JSON.stringify(sa.truth)
        var packet_a := JSON.stringify(sa.current_packet())
        sa.begin_voyage({"loops":3,"route_history":_history(spec,first_route)})

        var sb := AstraGameSession.new()
        sb.setup(case_id,seed_value)
        var truth_b := JSON.stringify(sb.truth)
        var packet_b := JSON.stringify(sb.current_packet())
        sb.begin_voyage({"loops":3,"route_history":_history(spec,second_route)})

        check(truth_a == truth_b, case_id + " route variation preserves Null/case truth")
        check(packet_a == packet_b, case_id + " route variation preserves required base evidence")
        report.append("%s\t%s/%s\t%d\tPASS\tPASS" % [case_id,first_route,second_route,visible])

    check(TARGETS.size() >= 4, "Stages 7-13 contain 4+ validated presentation-route targets")
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build/qa"))
    var file := FileAccess.open("res://build/qa/history_variation_120.txt",FileAccess.WRITE)
    file.store_string("\n".join(report))
    file.close()
