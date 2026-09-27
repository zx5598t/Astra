extends SceneTree

# HUMAN RHYTHM: Link friction may be reduced by visible-context ordering, never
# by hiding evidence or grading the answer for the player.
var failures: Array[String] = []
var checks := 0
var sampled_lists := 0
var saw_direct := false
var saw_record := false
var saw_hearsay := false
var saw_irrelevant := false
var saw_usable := false

func check(ok: bool, label: String) -> void:
    checks += 1
    if not ok:
        failures.append(label)
        printerr("FAIL · " + label)

func _initialize() -> void:
    run_samples()
    if failures.is_empty():
        print("ASTRA LINK FRICTION 111 TESTS OK · %d checks" % checks)
        quit(0)
        return
    printerr("ASTRA LINK FRICTION 111 TESTS FAILED · %d/%d" % [failures.size(), checks])
    quit(1)

func _to_meeting(case_id: String, seed_value: int) -> AstraGameSession:
    var s := AstraGameSession.new()
    s.setup(case_id, seed_value)
    AstraTestBots._finish_morning(s, true)
    if s.phase == "BRIEFING":
        s.advance()
    if s.phase == "INTERROGATION":
        for npc_id in s.living_ids():
            if s.conversations_left() <= 0:
                break
            s.ask(str(npc_id), "STATEMENT")
            var options := s.question_options(str(npc_id))
            for option in options:
                if bool(option.get("enabled", false)) and str(option.get("intent", "")) in ["RECORD","WITNESS"]:
                    s.ask(str(npc_id), str(option.get("intent", "")), str(option.get("ref", "")))
                    break
        s.advance()
    return s

func run_samples() -> void:
    for case_id in ["DEAD_AIR","GLASS_GARDEN","ECHO_WARD","SILENT_ORBIT"]:
        for offset in range(10):
            var s := _to_meeting(case_id, 18111 + offset * 71 + AstraCaseCatalog.stage_index(case_id) * 1000)
            if s.phase != "MEETING":
                continue
            var statements := s.link_statements()
            for statement in statements:
                var statement_ref := str(statement.get("ref", ""))
                var evidence := s.link_evidence(statement_ref)
                if evidence.is_empty():
                    continue
                sampled_lists += 1
                var refs := {}
                var first_pass: Array[String] = []
                for row in evidence:
                    var ref := str(row.get("ref", ""))
                    check(ref != "", "Link candidate ref is non-empty")
                    check(not refs.has(ref), "Link candidate list never duplicates a ref")
                    refs[ref] = true
                    first_pass.append(ref)
                    var label := str(row.get("label", ""))
                    if "[직접 목격" in label:
                        saw_direct = true
                    if "[기록" in label:
                        saw_record = true
                    if "[전언" in label:
                        saw_hearsay = true
                    var verdict := s.judge_link(statement_ref, ref)
                    var result := str(verdict.get("result", "INVALID"))
                    if result == "IRRELEVANT":
                        saw_irrelevant = true
                    elif result != "INVALID":
                        saw_usable = true
                var second_pass: Array[String] = []
                for row in s.link_evidence(statement_ref):
                    second_pass.append(str(row.get("ref", "")))
                check(first_pass == second_pass, "visible-context Link ordering is deterministic")
                # The picker may reorder but it must expose every ref it just
                # declared legal to judge_link.
                for ref in first_pass:
                    check(str(s.judge_link(statement_ref, ref).get("result", "")) != "INVALID",
                        "every shown Link candidate remains legally judgeable")
    check(sampled_lists > 0, "runtime Link candidate lists were sampled")
    check(saw_usable, "picker retains usable evidence")
    check(saw_irrelevant, "picker retains wrong/irrelevant evidence instead of becoming a hint")
    check(saw_direct, "direct-witness provenance remains visible")
    check(saw_record, "record provenance remains visible")
    check(saw_hearsay, "hearsay provenance remains visible")
    var source := FileAccess.get_file_as_string("res://scripts/core/game_session.gd")
    var start := source.find("func link_evidence")
    var stop := source.find("\nfunc _link_provenance_label", start)
    var body := source.substr(start, stop - start)
    check("_day_role" not in body and "living_null" not in body and "truth" not in body,
        "Link relevance ordering does not read hidden verdict/role/truth")
